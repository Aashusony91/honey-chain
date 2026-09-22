"""Quick smoke-test for shared.schemas"""
import sys
sys.path.insert(0, ".")

from shared.schemas import (
    BatchStatus, AgentType,
    HiveTelemetry, LabMetrics,
    HoneyBatchPayload, AgentRequest, AgentResponse,
    BatchSplitRequest,
)

print("All schemas imported successfully")

# Enum members
print(f"  BatchStatus: {[s.value for s in BatchStatus]}")
print(f"  AgentType:   {[a.value for a in AgentType]}")

# Valid batch
b = HoneyBatchPayload(
    batch_id="TEST-001", farmer_id="F-42",
    harvest_weight_kg=10.0, flora_source="Litchi",
    gps_coordinates="28.6,77.2", harvest_timestamp=1695300000,
)
print(f"  Sample batch: {b.batch_id}, status={b.status.value}, weight={b.harvest_weight_kg}kg")

# Valid split
sr = BatchSplitRequest(
    parent_batch_id="TEST-001", parent_weight_kg=10.0,
    child_allocations=[{"CHILD-A": 4.0}, {"CHILD-B": 6.0}],
)
print(f"  Valid split: parent={sr.parent_batch_id}, children={sr.child_allocations}")

# Mass conservation violation
try:
    BatchSplitRequest(
        parent_batch_id="X", parent_weight_kg=5.0,
        child_allocations=[{"A": 3.0}, {"B": 3.0}],
    )
    print("  FAIL - Mass conservation NOT enforced!")
except Exception as e:
    print(f"  Mass conservation enforced: {type(e).__name__}")

print("\nAll checks passed!")
