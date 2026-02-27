require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const pk = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000001";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.24",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000,
            },
            viaIR: true,
        },
    },

    networks: {
        // ---- Local ----
        hardhat: {
            forking: {
                // Fork mainnet locally for realistic testing
                url: process.env.ETHEREUM_RPC_URL || "https://eth-mainnet.g.alchemy.com/v2/demo",
                blockNumber: 21800000, // pin for reproducibility
                enabled: process.env.FORKING === "true",
            },
            chainId: 1337,
        },

        // ---- Mainnets ----
        ethereum: {
            url: process.env.ETHEREUM_RPC_URL || "",
            accounts: [pk],
            chainId: 1,
            gasPrice: "auto",
        },
        arbitrum: {
            url: process.env.ARBITRUM_RPC_URL || "",
            accounts: [pk],
            chainId: 42161,
            gasPrice: "auto",
        },
        base: {
            url: process.env.BASE_RPC_URL || "",
            accounts: [pk],
            chainId: 8453,
            gasPrice: "auto",
        },
        polygon: {
            url: process.env.POLYGON_RPC_URL || "",
            accounts: [pk],
            chainId: 137,
            gasPrice: "auto",
        },

        // ---- Testnets ----
        sepolia: {
            url: process.env.SEPOLIA_RPC_URL || "",
            accounts: [pk],
            chainId: 11155111,
        },
        arbSepolia: {
            url: process.env.ARB_SEPOLIA_RPC_URL || "",
            accounts: [pk],
            chainId: 421614,
        },
        baseSepolia: {
            url: process.env.BASE_SEPOLIA_RPC_URL || "",
            accounts: [pk],
            chainId: 84532,
        },
    },

    etherscan: {
        apiKey: {
            mainnet: process.env.ETHERSCAN_API_KEY || "",
            arbitrumOne: process.env.ARBISCAN_API_KEY || "",
            base: process.env.BASESCAN_API_KEY || "",
            polygon: process.env.POLYGONSCAN_API_KEY || "",
            sepolia: process.env.ETHERSCAN_API_KEY || "",
            arbitrumSepolia: process.env.ARBISCAN_API_KEY || "",
            baseSepolia: process.env.BASESCAN_API_KEY || "",
        },
    },

    gasReporter: {
        enabled: process.env.REPORT_GAS === "true",
        currency: "USD",
        coinmarketcap: process.env.CMC_API_KEY,
    },

    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
};
