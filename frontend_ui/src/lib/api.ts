/**
 * lib/api.ts — API Client for Honey Chain Backend Gateway (port 8000)
 * ====================================================================
 */

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

/** ── Types mirroring shared/schemas.py ─────────────────── */

export interface HiveTelemetry {
  internal_temp_c: number;
  internal_humidity_pct: number;
  hive_weight_kg: number;
  registered_hive_count: number;
}

export interface LabMetrics {
  hmf_content_mg_kg: number;
  moisture_percentage: number;
  sucrose_percentage: number;
  c3_c4_sugar_adulteration: boolean;
  lab_cert_id: string | null;
}

export type BatchStatus = "RAW" | "LAB_TESTING" | "COMPLIANT" | "SUSPENDED" | "BOTTLED";

export interface HoneyBatchPayload {
  batch_id: string;
  parent_batch_id: string | null;
  child_batch_ids: string[];
  farmer_id: string;
  harvest_weight_kg: number;
  flora_source: string;
  gps_coordinates: string;
  harvest_timestamp: number;
  status: BatchStatus;
  telemetry: HiveTelemetry | null;
  lab_results: LabMetrics | null;
  blockchain_tx_hash: string | null;
  anomaly_flags: string[];
}

export interface TraceNode {
  batch: HoneyBatchPayload;
  children: TraceNode[];
}

/** ── API Calls ─────────────────────────────────────────── */

/**
 * Sync an array of batch payloads to the backend.
 * Used by the offline-first harvest form.
 */
export async function syncBatches(
  batches: HoneyBatchPayload[]
): Promise<{ status: string; synced_count: number }> {
  const res = await fetch(`${API_BASE}/api/batch/sync`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(batches),
  });
  if (!res.ok) throw new Error(`Sync failed: ${res.status}`);
  return res.json();
}

/**
 * Fetch the full lineage tree for a batch.
 * Used by the consumer traceability portal.
 */
export async function fetchTrace(batchId: string): Promise<TraceNode> {
  const res = await fetch(`${API_BASE}/api/public/trace/${batchId}`);
  if (!res.ok) throw new Error(`Trace failed: ${res.status}`);
  return res.json();
}

/**
 * Generate a mock trace tree for demo / offline fallback purposes.
 * This lets the UI team work independently of the backend.
 */
export function getMockTrace(batchId: string): TraceNode {
  return {
    batch: {
      batch_id: batchId,
      parent_batch_id: null,
      child_batch_ids: [`${batchId}-B1`, `${batchId}-B2`],
      farmer_id: "FARMER-MH-042",
      harvest_weight_kg: 25.5,
      flora_source: "Litchi",
      gps_coordinates: "19.0760,72.8777",
      harvest_timestamp: 1695300000,
      status: "COMPLIANT",
      telemetry: {
        internal_temp_c: 34.5,
        internal_humidity_pct: 62.0,
        hive_weight_kg: 38.2,
        registered_hive_count: 12,
      },
      lab_results: {
        hmf_content_mg_kg: 18.5,
        moisture_percentage: 17.2,
        sucrose_percentage: 3.1,
        c3_c4_sugar_adulteration: false,
        lab_cert_id: "LAB-CERT-2025-08192",
      },
      blockchain_tx_hash:
        "0x7a3b9e1f4c2d8a6b5e0f1c3d7a9b2e4f6c8d0a1b3e5f7c9d1a3b5e7f9a2c4d",
      anomaly_flags: [],
    },
    children: [
      {
        batch: {
          batch_id: `${batchId}-B1`,
          parent_batch_id: batchId,
          child_batch_ids: [],
          farmer_id: "FARMER-MH-042",
          harvest_weight_kg: 15.0,
          flora_source: "Litchi",
          gps_coordinates: "19.0760,72.8777",
          harvest_timestamp: 1695400000,
          status: "BOTTLED",
          telemetry: null,
          lab_results: {
            hmf_content_mg_kg: 18.5,
            moisture_percentage: 17.2,
            sucrose_percentage: 3.1,
            c3_c4_sugar_adulteration: false,
            lab_cert_id: "LAB-CERT-2025-08192",
          },
          blockchain_tx_hash:
            "0xb4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4",
          anomaly_flags: [],
        },
        children: [],
      },
      {
        batch: {
          batch_id: `${batchId}-B2`,
          parent_batch_id: batchId,
          child_batch_ids: [],
          farmer_id: "FARMER-MH-042",
          harvest_weight_kg: 10.5,
          flora_source: "Litchi",
          gps_coordinates: "19.0760,72.8777",
          harvest_timestamp: 1695400000,
          status: "BOTTLED",
          telemetry: null,
          lab_results: {
            hmf_content_mg_kg: 19.0,
            moisture_percentage: 17.8,
            sucrose_percentage: 3.3,
            c3_c4_sugar_adulteration: false,
            lab_cert_id: "LAB-CERT-2025-08193",
          },
          blockchain_tx_hash:
            "0xc5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5",
          anomaly_flags: [],
        },
        children: [],
      },
    ],
  };
}
