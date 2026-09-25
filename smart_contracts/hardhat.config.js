require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const PRIVATE_KEY     = process.env.PRIVATE_KEY     || "";
const ETHERSCAN_KEY   = process.env.ETHERSCAN_API_KEY || "";

// Safety check — warn clearly if env vars are missing
if (!SEPOLIA_RPC_URL) {
  console.warn("⚠️  SEPOLIA_RPC_URL not set in .env — Sepolia deployment will fail.");
}
if (!PRIVATE_KEY) {
  console.warn("⚠️  PRIVATE_KEY not set in .env — Sepolia deployment will fail.");
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },

  networks: {
    // Built-in local network — used for `npx hardhat test`
    hardhat: {
      chainId: 31337,
    },

    // Local running node — used for `npx hardhat node` + deploy:local
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },

    // Sepolia public testnet — used for hackathon live demo
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111,
      // Sepolia can be slow — wait up to 120 seconds per transaction
      timeout: 120000,
    },
  },

  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_KEY,
    },
  },
};
