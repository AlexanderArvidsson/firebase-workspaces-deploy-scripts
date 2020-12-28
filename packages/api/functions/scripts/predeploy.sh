#!/usr/bin/env node

// Paths are relative to the functions directory, point to
// your desired workspace root. These also need to be defined
// in postdeploy.
const workspaces = {
  'shared': '../../shared'
};

/**
 * You should not need to modify anything below this line
 * ------------------------------------------------------
 */

const readline = require('readline');
const detectIndent = require('detect-indent');
const path = require('path');
const fs = require('fs-extra');
const Diff = require('diff');
const chalk = require('chalk');
const packlist = require('npm-packlist');

const deployUtils = require('./deploy-utils');
const logger = require('./logger')('predeploy');

const [rootIn] = process.argv.slice(2);

if (!rootIn) {
  logger.info('Usage:');
  logger.info('  predeploy.sh ./package-root/');
  process.exit();
}

const root = path.join(process.cwd(), rootIn);

const packagePath = path.join(root, 'package.json');
const backupPath = path.join(root, 'package.predeploy-backup.json');

const package = require(packagePath);

const packageStr = fs.readFileSync(packagePath).toString();
const indent = detectIndent(packageStr);

(async () => {
  const backupExists = await fs.promises
    .access(backupPath, fs.constants.F_OK)
    .then(() => true)
    .catch(() => false);

  if (backupExists) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    {
      const answer = await new Promise((resolve) => {
        rl.question(
          chalk.cyan(`i predeploy: `) + 'Backup file exists, do you want to restore it first? Yn: ',
          (answer) => resolve(answer)
        );
      });

      if (answer !== 'Y' && answer !== 'y' && answer !== 'yes' && answer !== '') {
        logger.error(
          'Refusing to continue when backup still exists, aborting. Please examine the backup file and restore manually if necessary.'
        );
        process.exit();
      }
    }

    rl.close();

    logger.info('Restoring backup before continuing...');

    const success = await deployUtils.restore(root, workspaces, logger);

    if (!success) {
      logger.error('Failed to restore backup');
      process.exit();
    }

    logger.success('Finished restoring backup');
  }

  logger.info('Backing up package.json');
  fs.writeFileSync(backupPath, packageStr);

  const workspaceMap = {};

  try {
    for (const [workspaceName, workspacePath] of Object.entries(workspaces)) {
      logger.info('Packing and copying workspace', chalk.bold(workspaceName), '...');

      const res = await packlist({ path: path.join(root, workspacePath) });
      await fs.mkdirp('dist/');

      const promises = res.map((file) => {
        const from = path.join(workspacePath, file);
        const to = path.join('dist', workspaceName, file);

        logger.info(from, '->', to);
        return fs.copy(path.join(root, from), path.join(root, to));
      });

      await Promise.all(promises);

      logger.info('Done copying workspace', chalk.bold(workspaceName));
      workspaceMap[workspaceName] = path.join('dist', workspaceName);
    }

    logger.info('Done copying workspaces');
  } catch (e) {
    logger.error('Failed to copy packed shared workspaces', e);
    process.exit();
  }

  try {
    logger.info('Creating modified package.json...');

    const newPackage = {
      dependencies: {},
      ...package
    };

    Object.entries(workspaceMap).forEach(([name, path]) => {
      newPackage.dependencies[name] = 'file:' + path;
      logger.info('Added dependency', chalk.bold(`${name}: file:${path}`), 'to package.json');
    });

    logger.info('Stringifying modified package.json...');
    const out = JSON.stringify(newPackage, null, indent.amount) + '\n';

    logger.info('Creating patch...');
    const diff = Diff.structuredPatch('package.json', 'package.json', packageStr, out);
    diff.hunks.forEach((hunk) => {
      hunk.lines.forEach((line) => {
        const color = line.startsWith('+')
          ? chalk.green
          : line.startsWith('-')
          ? chalk.red
          : chalk.grey;

        console.log(color(line));
      });
    });

    // Overwrite package.json
    logger.info('Writing modified package.json...');
    fs.writeFileSync(packagePath, out);

    logger.success('Finished predeploy');
  } catch (e) {
    logger.error('Failed processing package.json', e, e.stack);

    logger.error('There were errors during the process, please check them above');
  }
})();
