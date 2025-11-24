import "@nomicfoundation/hardhat-toolbox";

module.exports = {
  solidity: "0.8.28",
  networks: {
    stagenet: {
      url: "https://rpc.contract.dev/35dea51a2cdf0e4e822993aeb4871ed3",
      accounts: [
        "0x9451b6e3e12610844be5ebd9163bcace4de089d61b401e05af6e503f419632ba", // 0x3e36fBeb3B9AFc2544E0347DF7f6c3435dCEeBc8
      ],
    },
  },
};
