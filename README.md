# 🍯 Honey Chain — SIH PS 26021

Blockchain-backed honey supply-chain traceability platform.  
**From Hive to Shelf, Verified on Blockchain.**

## Architecture

| Service | Member | Port | Directory |
|---------|--------|------|-----------|
| Backend Gateway API | Member 4 | 8000 | `backend_gateway/` |
| Supply Chain Orchestrator | Member 1 | 8001 | `agent_1_orchestrator/` |
| Web3 Ledger Agent | Member 2 | 8002 | `agent_2_ledger/` |
| IoT Fraud Engine | Member 3 | 8003 | `agent_3_fraud/` |
| Frontend UI (PWA) | Member 5 | 3000 | `frontend_ui/` |

All services import from `shared/schemas.py` — the **immutable** data contract.

## Shared Schemas

| Model | Purpose |
|-------|---------|
| `BatchStatus` | Enum: RAW → LAB_TESTING → COMPLIANT → BOTTLED (or SUSPENDED) |
| `AgentType` | Enum: ORCHESTRATOR, WEB3_LEDGER, IOT_FRAUD_ENGINE, GATEWAY |
| `HiveTelemetry` | IoT sensor readings from the hive |
| `LabMetrics` | Certified lab-test results |
| `HoneyBatchPayload` | Core batch object moving through the supply chain |
| `AgentRequest` / `AgentResponse` | Inter-agent messaging envelopes |
| `BatchSplitRequest` | Split a parent batch into children (mass-conservation validated) |
| `BaseAgent` | Abstract agent class with `process()` and `get_capabilities()` |

## Quick Start

```bash
# Shared schemas (Python)
pip install -r requirements.txt
python test_schemas.py

# Frontend UI (Node.js)
cd frontend_ui
npm install
npm run dev    # → http://localhost:3000
```

## Team Branching Strategy

Each member works on their own branch to avoid conflicts:

| Member | Branch | Directory |
|--------|--------|-----------|
| Member 1 | `feat/orchestrator-agent` | `agent_1_orchestrator/` |
| Member 2 | `feat/web3-ledger` | `agent_2_ledger/` |
| Member 3 | `feat/iot-fraud-engine` | `agent_3_fraud/` |
| Member 4 | `feat/backend-gateway` | `backend_gateway/` |
| Member 5 | `feat/frontend-ui` | `frontend_ui/` |
