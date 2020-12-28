#!/usr/bin/env node

// Paths are relative to the functions directory, point to
// your desired workspace root. These also need to be defined
// in predeploy.
const workspaces = {
  'shared': '../../shared'
};

/**
 * You should not need to modify anything below this line
 * ------------------------------------------------------
 */
const path = require('path');

const deployUtils = require('./deploy-utils');
const logger = require('./logger')('postdeploy');

const [rootIn] = process.argv.slice(2);

if (!rootIn) {
  logger.info('Usage:');
  logger.info('  postdeploy.sh ./package-root/');
  process.exit();
}

const root = path.join(process.cwd(), rootIn);

deployUtils.restore(root, workspaces, logger);

logger.success('Finished postdeploy');
