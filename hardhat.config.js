/** @type import('hardhat/config').HardhatUserConfig */
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
