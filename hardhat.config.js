require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  networks: {
    testnet: {
      url: "https://data-seed-prebsc-1-s1.bnbchain.org:8545",
      chainId: 97,
      blockGasLimit: 5000000,
      accounts: [process.env.PRIVATE_KEY],
    },
  },

  etherscan: {
    apiKey: process.env.API_KEY,
  },
};
