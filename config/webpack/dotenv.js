const dotenv = require('dotenv');

const dotenvFiles = [
  `.env.${process.env.NODE_ENV}.local`,
  '.env.local',
  `.env.${process.env.NODE_ENV}`,
  '.env'
];

function loadEnv() {
  dotenvFiles.forEach((dotenvFile) => {
    dotenv.config({ path: dotenvFile, silent: true });
  });
}

module.exports = { loadEnv };