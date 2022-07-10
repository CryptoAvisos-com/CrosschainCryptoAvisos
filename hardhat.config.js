require("@nomicfoundation/hardhat-toolbox");
require('hardhat-contract-sizer');

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.11",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ],
  },
  contractSizer: {
    only: ['Brain.sol', 'Arm.sol'],
  }
};