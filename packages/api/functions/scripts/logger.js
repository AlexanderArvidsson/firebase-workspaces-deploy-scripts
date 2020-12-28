const chalk = require('chalk');

const logger = (prefix) => ({
  success: (...args) => console.log(chalk.green(`✔ ${prefix}: `) + chalk.white(...args)),
  info: (...args) => console.log(chalk.cyan(`i ${prefix}: `) + chalk.white(...args)),
  error: (...args) => console.error(chalk.red(`✗ ${prefix}: `) + chalk.white(...args))
});

module.exports = logger;
