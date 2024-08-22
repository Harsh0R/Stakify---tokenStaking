require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    amoy: {
      url: "https://rpc-amoy.polygon.technology",
      accounts: [
        "1908fcfd6a15f4d574d203e47fd1dabec53e01ec39c434f36ac8c28df22e4688",
      ],
      chainId: 80002,
    },
  },
};
