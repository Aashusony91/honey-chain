const hre = require("hardhat");
require("dotenv").config();

// Helper to wait N milliseconds (for Etherscan indexer lag)
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const signers = await hre.ethers.getSigners();
  if (!signers || signers.length === 0) {
    throw new Error("❌ No deployer account found. Check PRIVATE_KEY in your .env file.");
  }
  const deployer = signers[0];

  console.log("====================================================");
  console.log("🍯 Honey Chain — Smart Contract Deployment");
  console.log(`Network:          ${hre.network.name}`);
  console.log(`Deployer Address: ${deployer.address}`);

  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`Deployer Balance: ${hre.ethers.formatEther(balance)} ETH`);

  if (hre.network.name === "sepolia" && balance === 0n) {
    throw new Error(
      "❌ Deployer has 0 ETH on Sepolia. Get free test ETH from https://sepoliafaucet.com"
    );
  }
  console.log("====================================================");

  // 1. Deploy the contract
  console.log("\nDeploying HoneyTraceability...");
  const Factory  = await hre.ethers.getContractFactory("HoneyTraceability");
  const contract = await Factory.deploy(deployer.address);
  await contract.waitForDeployment();

  const contractAddress = await contract.getAddress();
  console.log(`✅ HoneyTraceability deployed to: ${contractAddress}`);

  // 2. Print role hashes — needed to grant roles from admin panel or backend
  const BEEKEEPER_ROLE = await contract.BEEKEEPER_ROLE();
  const PROCESSOR_ROLE = await contract.PROCESSOR_ROLE();
  const RETAILER_ROLE  = await contract.RETAILER_ROLE();
  console.log("\n📋 Role Hashes (save these for your admin panel):");
  console.log(`  BEEKEEPER_ROLE: ${BEEKEEPER_ROLE}`);
  console.log(`  PROCESSOR_ROLE: ${PROCESSOR_ROLE}`);
  console.log(`  RETAILER_ROLE:  ${RETAILER_ROLE}`);

  // 3. Auto-verify on Etherscan if deploying to Sepolia
  if (hre.network.name === "sepolia" && process.env.ETHERSCAN_API_KEY) {
    const deployTx = contract.deploymentTransaction();
    if (deployTx) {
      console.log("\nWaiting for 6 block confirmations before Etherscan verification...");
      await deployTx.wait(6);
    }
    // Extra wait for Etherscan indexer
    console.log("Waiting 15s for Etherscan to index the contract...");
    await sleep(15000);

    console.log("Verifying contract on Etherscan...");
    try {
      await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: [deployer.address],
      });
      console.log("✅ Contract verified on Etherscan!");
    } catch (err) {
      if (err.message.toLowerCase().includes("already verified")) {
        console.log("Already verified.");
      } else {
        console.warn("⚠️  Etherscan verification warning:", err.message);
      }
    }
  }

  // 4. Print the env variable to add to .env files
  console.log("\n====================================================");
  console.log("✅ Deployment Complete! Add these to your .env files:");
  console.log(`\n  backend_gateway/.env:`);
  console.log(`  CONTRACT_ADDRESS="${contractAddress}"`);
  console.log(`  BLOCKCHAIN_RPC_URL="${process.env.SEPOLIA_RPC_URL || "http://127.0.0.1:8545"}"`);
  console.log(`\n  frontend_ui/.env.local:`);
  console.log(`  NEXT_PUBLIC_CONTRACT_ADDRESS="${contractAddress}"`);
  console.log(`  NEXT_PUBLIC_RPC_URL="${process.env.SEPOLIA_RPC_URL || "http://127.0.0.1:8545"}"`);
  console.log("====================================================");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error.message);
  process.exitCode = 1;
});
