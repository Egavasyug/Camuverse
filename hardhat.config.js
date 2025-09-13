/** @type import('hardhat/config').HardhatUserConfig */
require('@openzeppelin/hardhat-upgrades');
module.exports = {
  solidity: {
    compilers: [
      { version: '0.8.20', settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: '0.8.30', settings: { optimizer: { enabled: false, runs: 200 } } }
    ],
    overrides: {
      'contracts/legacy/CammunityDAO_v1_flat.sol': {
        version: '0.8.30',
        settings: { optimizer: { enabled: false, runs: 200 } }
      }
    }
  },
  paths: { sources: 'contracts' }
};


/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  solidity: {
    compilers: [
      { version: '0.8.20', settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: '0.8.30', settings: { optimizer: { enabled: false, runs: 200 } } }
    ],
    overrides: {
      'contracts/legacy/CammunityDAO_v1_flat.sol': {
        version: '0.8.30',
        settings: { optimizer: { enabled: false, runs: 200 } }
      }
    }
  },
  paths: { sources: 'contracts' },
  networks: {
    base: {
      url: process.env.BASE_RPC_URL || '',
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
};
