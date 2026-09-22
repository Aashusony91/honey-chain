# Honey Chain — SIH PS 26021

Blockchain-backed honey supply-chain traceability platform.

## Project Structure

```
honey-chain/
├── shared/              # Immutable data contracts (Pydantic v2 schemas)
│   ├── __init__.py
│   └── schemas.py
├── requirements.txt
└── test_schemas.py      # Smoke tests
```

## Shared Schemas

The `shared/schemas.py` module defines the canonical data models consumed by all microservices:

| Model | Purpose |
|-------|---------|
| `BatchStatus` | Enum: RAW → LAB_TESTING → COMPLIANT → BOTTLED (or SUSPENDED) |
| `AgentType` | Enum: ORCHESTRATOR, WEB3_LEDGER, IOT_FRAUD_ENGINE, GATEWAY |
| `HiveTelemetry` | IoT sensor readings from the hive |
| `LabMetrics` | Certified lab-test results |
| `HoneyBatchPayload` | Core batch object moving through the supply chain |
| `AgentRequest` / `AgentResponse` | Inter-agent messaging envelopes |
| `BatchSplitRequest` | Split a parent batch into children (with mass-conservation validation) |

## Quick Start

```bash
pip install -r requirements.txt
python test_schemas.py
```
