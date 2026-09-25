"""
blockchain_helper.py
Connects the FastAPI backend gateway to the HoneyTraceability smart contract.

Works on:
  - Local Hardhat node (http://127.0.0.1:8545)
  - Sepolia testnet    (https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY)

Environment variables (set in backend_gateway/.env):
  BLOCKCHAIN_RPC_URL  — Alchemy/Infura URL or local node
  CONTRACT_ADDRESS    — Deployed contract address (from deploy.js output)
  PRIVATE_KEY         — Beekeeper/Admin wallet private key

Usage (in traceability.py after db.commit()):
  from ..blockchain_helper import register_harvest_on_chain
  tx_hash = register_harvest_on_chain(weight_kg=25.5, ipfs_hash="HC-BATCH-3A9F1C")
"""

import json
import os
from pathlib import Path

from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware

# ── Load environment variables ────────────────────────────────────
RPC_URL          = os.getenv("BLOCKCHAIN_RPC_URL", "http://127.0.0.1:8545")
CONTRACT_ADDRESS = os.getenv("CONTRACT_ADDRESS",   "0x5FbDB2315678afecb367f032d93F642f64180aa3")
PRIVATE_KEY      = os.getenv("PRIVATE_KEY",        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")

# ── Connect to Web3 ───────────────────────────────────────────────
web3 = Web3(Web3.HTTPProvider(RPC_URL))

# Required for Sepolia (Proof-of-Authority middleware)
# This fixes "ValueError: There was a problem" errors on Sepolia
web3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)

# ── ABI Path ──────────────────────────────────────────────────────
# Resolves to: honey-chain/smart_contracts/artifacts/contracts/HoneyTraceability.sol/HoneyTraceability.json
_ABI_PATH = (
    Path(__file__).parent.parent
    / "smart_contracts"
    / "artifacts"
    / "contracts"
    / "HoneyTraceability.sol"
    / "HoneyTraceability.json"
)


def _load_abi() -> list:
    """Load ABI from Hardhat compile artifacts."""
    if not _ABI_PATH.exists():
        raise FileNotFoundError(
            f"ABI not found at {_ABI_PATH}.\n"
            "Fix: Run `npx hardhat compile` inside the smart_contracts/ folder first."
        )
    with open(_ABI_PATH, "r") as f:
        return json.load(f)["abi"]


def _get_contract():
    """Returns a web3 contract instance."""
    return web3.eth.contract(
        address=Web3.to_checksum_address(CONTRACT_ADDRESS),
        abi=_load_abi(),
    )


def is_blockchain_connected() -> bool:
    """Returns True if the blockchain node (local or Sepolia) is reachable."""
    try:
        return web3.is_connected()
    except Exception:
        return False


def register_harvest_on_chain(weight_kg: float, ipfs_hash: str) -> str | None:
    """
    Anchors a honey harvest batch to the blockchain.

    Args:
        weight_kg : Batch weight in kg (from your BatchCreateRequest schema).
        ipfs_hash : Your backend batch_id (e.g. "HC-BATCH-3A9F1C") used as on-chain reference.

    Returns:
        Transaction hash (str) on success, or None if blockchain is unreachable.
        The API will still return 200 even if blockchain is down — non-blocking.
    """
    if not is_blockchain_connected():
        print(f"[blockchain] Node unreachable at {RPC_URL}. Skipping anchor.")
        return None

    try:
        contract = _get_contract()
        account  = web3.eth.account.from_key(PRIVATE_KEY)

        # Convert kg → grams (uint256 on-chain does not support decimals)
        weight_grams = int(weight_kg * 1000)

        # Estimate gas dynamically (works for both local and Sepolia)
        gas_estimate = contract.functions.registerBatch(
            weight_grams, ipfs_hash
        ).estimate_gas({"from": account.address})

        tx = contract.functions.registerBatch(
            weight_grams, ipfs_hash
        ).build_transaction({
            "from":     account.address,
            "nonce":    web3.eth.get_transaction_count(account.address),
            "gas":      int(gas_estimate * 1.2),   # 20% buffer
            "gasPrice": web3.eth.gas_price,         # Auto gas price (works on Sepolia)
        })

        signed  = web3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
        tx_hash = web3.eth.send_raw_transaction(signed.raw_transaction)
        receipt = web3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)

        tx_hex = receipt.transactionHash.hex()
        print(f"[blockchain] ✅ Anchored on {'Sepolia' if '8545' not in RPC_URL else 'localhost'}: {tx_hex}")
        return tx_hex

    except Exception as e:
        # Non-blocking — never crashes the main API
        print(f"[blockchain] ⚠️ Could not anchor to chain: {e}")
        return None
