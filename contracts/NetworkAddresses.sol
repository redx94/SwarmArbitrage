// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ============================================================
//  SwarmArbitrage — NetworkAddresses.sol
//  ============================================================
//  Central registry for all DEX and lending protocol addresses
//  on each supported network. Used by deployment scripts.
// ============================================================

library NetworkAddresses {

    // ================================================================
    //  ETHEREUM MAINNET
    // ================================================================
    struct Addresses {
        // Flash loan providers
        address aaveV3Pool;
        address balancerVault;

        // DEX Routers
        address uniswapV2Router;
        address uniswapV3Router;
        address uniswapV3Quoter;
        address sushiswapV2Router;

        // Tokens
        address WETH;
        address USDC;
        address USDT;
        address DAI;
        address WBTC;

        // Curve pools (commonly used)
        address curve3Pool; // DAI/USDC/USDT
        address curveTricrypto; // USDT/WBTC/WETH
    }

    function ethereum() internal pure returns (Addresses memory) {
        return Addresses({
            aaveV3Pool:          0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2,
            balancerVault:       0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            uniswapV2Router:     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            uniswapV3Router:     0xE592427A0AEce92De3Edee1F18E0157C05861564,
            uniswapV3Quoter:     0x61fFE014bA17989E743c5F6cB21bF9697530B21e,
            sushiswapV2Router:   0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F,
            WETH:                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            USDC:                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            USDT:                0xdAC17F958D2ee523a2206206994597C13D831ec7,
            DAI:                 0x6B175474E89094C44Da98b954EedeAC495271d0F,
            WBTC:                0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,
            curve3Pool:          0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,
            curveTricrypto:      0xD51a44d3FaE010294C616388b506AcdA1bfAAE46
        });
    }

    // ================================================================
    //  ARBITRUM ONE
    // ================================================================
    function arbitrum() internal pure returns (Addresses memory) {
        return Addresses({
            aaveV3Pool:          0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            balancerVault:       0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            uniswapV2Router:     0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            uniswapV3Router:     0xE592427A0AEce92De3Edee1F18E0157C05861564,
            uniswapV3Quoter:     0x61fFE014bA17989E743c5F6cB21bF9697530B21e,
            sushiswapV2Router:   0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,
            WETH:                0x82aF49447D8a07e3bd95BD0d56f35241523fBab1,
            USDC:                0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            USDT:                0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
            DAI:                 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1,
            WBTC:                0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f,
            curve3Pool:          0x7f90122BF0700F9E7e1F688fe926940E8839F353,
            curveTricrypto:      0x960ea3e3C7FB317332d990873d354E18d7645590
        });
    }

    // ================================================================
    //  BASE
    // ================================================================
    function base() internal pure returns (Addresses memory) {
        return Addresses({
            aaveV3Pool:          0xA238Dd80C259a72e81d7e4664a9801593F98d1c5,
            balancerVault:       0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            uniswapV2Router:     0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24,
            uniswapV3Router:     0x2626664c2603336E57B271c5C0b26F421741e481,
            uniswapV3Quoter:     0x3d4e44Eb1374240CE5F1B136Aa268B21b3A3ABeD,
            sushiswapV2Router:   0x6BDED42c6DA8FBf0d2bA55B2fa120C5e0c8D7891,
            WETH:                0x4200000000000000000000000000000000000006,
            USDC:                0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
            USDT:                0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2,
            DAI:                 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb,
            WBTC:                0x0000000000000000000000000000000000000000, // not native on Base
            curve3Pool:          0x0000000000000000000000000000000000000000,
            curveTricrypto:      0x0000000000000000000000000000000000000000
        });
    }

    // ================================================================
    //  POLYGON
    // ================================================================
    function polygon() internal pure returns (Addresses memory) {
        return Addresses({
            aaveV3Pool:          0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            balancerVault:       0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            uniswapV2Router:     0xedf6066a2b290C185783862C7F4776A2C8077AD1,
            uniswapV3Router:     0xE592427A0AEce92De3Edee1F18E0157C05861564,
            uniswapV3Quoter:     0x61fFE014bA17989E743c5F6cB21bF9697530B21e,
            sushiswapV2Router:   0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,
            WETH:                0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619,
            USDC:                0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359,
            USDT:                0xc2132D05D31c914a87C6611C10748AEb04B58e8F,
            DAI:                 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            WBTC:                0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6,
            curve3Pool:          0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171,
            curveTricrypto:      0x1d8b86e3D88cDb2d34688e87E72F388Cb541B7C8
        });
    }
}
