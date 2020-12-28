const path = require('path');
const fs = require('fs-extra');
const chalk = require('chalk');

const defaultLogger = require('./logger')('deploy-utils');

// Restore original
module.exports = {
  restore: async (root, workspaces, logger = defaultLogger) => {
    const packagePath = path.join(root, 'package.json');
    const backupPath = path.join(root, 'package.predeploy-backup.json');

    const backupExists = await fs.promises
      .access(backupPath, fs.constants.F_OK)
      .then(() => true)
      .catch(() => false);

    if (!backupExists) {
      logger.error('Failed to restore original package.json, backup missing)');
      return false;
    }

    try {
      logger.info('Removing packed workspaces');

      for (const [workspaceName] of Object.entries(workspaces)) {
        logger.info('Removing packed workspace', chalk.bold(workspaceName));

        await fs.remove(path.join('dist', workspaceName));
      }

      logger.info('Done removing packed workspaces');
    } catch (e) {
      logger.error('Failed to remove packed workspaces', e);
      return false;
    }

    try {
      logger.info('Restoring original package.json');
      await fs.promises.rename(backupPath, packagePath);
    } catch (e) {
      logger.error('Failed', e);

      logger.error('There were errors during the process, please check them above');
      return false;
    }

    return true;
  }
};
