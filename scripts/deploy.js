const hre = require("hardhat");
const { ethers } = hre;

// ============================================================
//  Deploy FlashArbitrage to the specified network
// ============================================================

// Addresses per network
const NETWORK_ADDRESSES = {
    ethereum: {
        aavePool: "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    arbitrum: {
        aavePool: "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    base: {
        aavePool: "0xA238Dd80C259a72e81d7e4664a9801593F98d1c5",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    polygon: {
        aavePool: "0x794a61358D6845594F94dc1DB02A252b5b4814aD",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    // testnets
    sepolia: {
        aavePool: "0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    arbSepolia: {
        aavePool: "0xBfC91D59fdAA134A4ED45f7B584cAf96D7792Eff",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    baseSepolia: {
        aavePool: "0x07eA79F68B2B3df564D0A34F8e19D9B1e339814b",
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
    hardhat: {
        aavePool: "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2", // mainnet fork
        balancerVault: "0xBA12222222228d8Ba445958a75a0704d566BF2C8",
    },
};

async function main() {
    const networkName = hre.network.name;
    console.log(`\n🚀 Deploying FlashArbitrage to: ${networkName}`);

    const addrs = NETWORK_ADDRESSES[networkName];
    if (!addrs) {
        throw new Error(`No addresses configured for network: ${networkName}`);
    }

    const [deployer] = await ethers.getSigners();
    console.log(`📬 Deployer: ${deployer.address}`);

    const balance = await ethers.provider.getBalance(deployer.address);
    console.log(`💰 Balance:  ${ethers.formatEther(balance)} ETH`);

    if (balance === 0n) {
        throw new Error("Deployer has no ETH — fund your wallet first!");
    }

    console.log(`\n📋 Using addresses:`);
    console.log(`   Aave V3 Pool:     ${addrs.aavePool}`);
    console.log(`   Balancer Vault:   ${addrs.balancerVault}`);

    // Deploy
    const FlashArbitrage = await ethers.getContractFactory("FlashArbitrage");
    console.log("\n⏳ Deploying contract...");

    const contract = await FlashArbitrage.deploy(
        addrs.aavePool,
        addrs.balancerVault
    );

    await contract.waitForDeployment();
    const address = await contract.getAddress();

    console.log(`\n✅ FlashArbitrage deployed to: ${address}`);
    console.log(`   Tx hash: ${contract.deploymentTransaction()?.hash}`);

    // Save address to .env
    const env = require("fs").readFileSync(".env", { encoding: "utf8", flag: "a+" });
    const envKey = `ARBITRAGE_CONTRACT_${networkName.toUpperCase()}`;
    if (!env.includes(envKey)) {
        require("fs").appendFileSync(".env", `\n${envKey}=${address}\n`);
        console.log(`\n📝 Saved to .env: ${envKey}=${address}`);
    }

    // Verify on block explorer (skip for local)
    if (networkName !== "hardhat" && networkName !== "localhost") {
        console.log("\n🔍 Waiting 5 blocks for Etherscan indexing...");
        // Wait for confirmations
        await new Promise(r => setTimeout(r, 30000));

        try {
            await hre.run("verify:verify", {
                address: address,
                constructorArguments: [addrs.aavePool, addrs.balancerVault],
            });
            console.log("✅ Contract verified on block explorer!");
        } catch (e) {
            console.log(`⚠️  Verification failed (can retry manually): ${e.message}`);
        }
    }

    console.log("\n🏁 Deployment complete!\n");
    console.log("Next steps:");
    console.log(`  1. Add this to .env: ${envKey}=${address}`);
    console.log("  2. Run the bot: npm run bot");
    console.log("  3. Monitor profits in the dashboard: npm run dashboard");
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error("❌ Deployment failed:", err);
        process.exit(1);
    });
