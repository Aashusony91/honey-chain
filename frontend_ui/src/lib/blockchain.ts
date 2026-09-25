/**
 * blockchain.ts
 * Reads honey batch history from the HoneyTraceability smart contract.
 *
 * Works on:
 *   - Local Hardhat node (http://127.0.0.1:8545)
 *   - Sepolia testnet   (https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY)
 *
 * Environment variables (set in frontend_ui/.env.local):
 *   NEXT_PUBLIC_RPC_URL            — Alchemy Sepolia URL or local node
 *   NEXT_PUBLIC_CONTRACT_ADDRESS   — Deployed contract address
 *
 * Usage example (in your verify/[hash]/page.tsx or trace/[batchId]/page.tsx):
 *   import { getChainHistory, isBlockchainReachable } from "@/lib/blockchain";
 *   const chainData = await getChainHistory(1);
 */

import { ethers } from "ethers";

// ── Config (from .env.local for Sepolia, or defaults for localhost) ──
const CONTRACT_ADDRESS =
  process.env.NEXT_PUBLIC_CONTRACT_ADDRESS ||
  "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // local default

const RPC_URL =
  process.env.NEXT_PUBLIC_RPC_URL ||
  "http://127.0.0.1:8545"; // local default

// ── Inline ABI (no JSON file import needed — works in Next.js without config changes) ──
const HONEY_ABI = [
  // registerBatch — called by backend, not frontend (write function)
  "function registerBatch(uint256 weight, string ipfsMetadataHash) returns (uint256)",

  // getBatchHistory — called by frontend to show consumers full supply chain trail
  "function getBatchHistory(uint256 batchId) view returns (" +
    "tuple(uint256 batchId, address beekeeper, address currentOwner, uint8 state, uint256 weight, string ipfsMetadataHash, uint256 timestamp)," +
    "tuple(uint8 state, address actor, uint256 timestamp, string ipfsMetadataHash)[]" +
  ")",

  // getTotalBatches — used for health check
  "function getTotalBatches() view returns (uint256)",

  // Events — used if you want to listen to live blockchain events in future
  "event BatchStateUpdated(uint256 indexed batchId, uint8 state, address actor, string ipfsHash)",
];

// ── State label map (matches your BatchState enum in Solidity) ──
const STATE_LABELS: Record<number, string> = {
  0: "Harvested",
  1: "Processed",
  2: "Packaged",
  3: "In Retail",
  4: "Sold",
};

// ── Types (compatible with your existing HoneyBatchPayload in api.ts) ──
export interface ChainBatch {
  batchId: string;
  beekeeper: string;
  currentOwner: string;
  state: number;
  stateLabel: string;
  weightKg: number;     // Converted from grams → kg to match your backend's weight_kg
  ipfsHash: string;     // Your HC-BATCH-XXXXX reference stored on-chain
  timestamp: string;    // ISO 8601 string
}

export interface ChainCheckpoint {
  state: number;
  stateLabel: string;
  actor: string;
  ipfsHash: string;
  timestamp: string;
}

export interface ChainHistory {
  batch: ChainBatch;
  history: ChainCheckpoint[];
  network: "sepolia" | "localhost" | "unknown";
}

/** Returns a connected read-only provider for the configured RPC URL. */
function getProvider(): ethers.JsonRpcProvider {
  return new ethers.JsonRpcProvider(RPC_URL);
}

/**
 * Checks if the blockchain node (Sepolia or local) is reachable.
 * Use this to show/hide the blockchain section in your UI.
 */
export async function isBlockchainReachable(): Promise<boolean> {
  try {
    const provider = getProvider();
    await provider.getBlockNumber();
    return true;
  } catch {
    return false;
  }
}

/**
 * Returns the current network name: "sepolia", "localhost", or "unknown".
 * Used to display the correct Etherscan link in the UI.
 */
export async function getNetworkName(): Promise<"sepolia" | "localhost" | "unknown"> {
  try {
    const provider = getProvider();
    const network  = await provider.getNetwork();
    const chainId  = Number(network.chainId);
    if (chainId === 11155111) return "sepolia";
    if (chainId === 31337)    return "localhost";
    return "unknown";
  } catch {
    return "unknown";
  }
}

/**
 * Returns the Etherscan URL for a transaction hash.
 * On localhost it returns null (no Etherscan for local).
 */
export function getEtherscanTxUrl(txHash: string): string | null {
  if (RPC_URL.includes("sepolia") || RPC_URL.includes("11155111")) {
    return `https://sepolia.etherscan.io/tx/${txHash}`;
  }
  return null;
}

/**
 * Fetches a batch's complete on-chain supply chain history.
 *
 * @param blockchainBatchId  The uint256 ID returned by registerBatch()
 *                           (stored as blockchain_tx_hash in your api.ts HoneyBatchPayload)
 * @returns ChainHistory or null if node is unreachable or batch not found
 */
export async function getChainHistory(
  blockchainBatchId: number
): Promise<ChainHistory | null> {
  try {
    const provider = getProvider();
    const contract = new ethers.Contract(CONTRACT_ADDRESS, HONEY_ABI, provider);
    const network  = await getNetworkName();

    const [batch, checkpoints] = await contract.getBatchHistory(blockchainBatchId);

    return {
      network,
      batch: {
        batchId:      batch.batchId.toString(),
        beekeeper:    batch.beekeeper,
        currentOwner: batch.currentOwner,
        state:        Number(batch.state),
        stateLabel:   STATE_LABELS[Number(batch.state)] ?? "Unknown",
        weightKg:     Number(batch.weight) / 1000,   // grams → kg
        ipfsHash:     batch.ipfsMetadataHash,
        timestamp:    new Date(Number(batch.timestamp) * 1000).toISOString(),
      },
      history: checkpoints.map((cp: any) => ({
        state:      Number(cp.state),
        stateLabel: STATE_LABELS[Number(cp.state)] ?? "Unknown",
        actor:      cp.actor,
        ipfsHash:   cp.ipfsMetadataHash,
        timestamp:  new Date(Number(cp.timestamp) * 1000).toISOString(),
      })),
    };
  } catch (err) {
    console.warn("[blockchain] Could not fetch chain history:", err);
    return null;
  }
}
