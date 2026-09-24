/**
 * lib/api.ts — API Client for Honey Chain Backend Gateway (port 8000)
 * ====================================================================
 * Connected to Member 4's real backend (commit 8ed52f8).
 *
 * Real endpoints:
 *   POST /api/reports/submit          — Submit a HoneyBatchPayload for verification
 *   GET  /api/reports/{id}/status     — Get report verification status
 *   GET  /api/public/verify/{hash}    — Public SHA-256 proof verification
 *   POST /api/reports/validate-image  — EXIF + GPS + duplicate image validation
 */

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

// ── Types mirroring shared/schemas.py ────────────────────────

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

export type BatchStatus =
  | "RAW"
  | "LAB_TESTING"
  | "COMPLIANT"
  | "SUSPENDED"
  | "BOTTLED";

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

// ── Backend Gateway specific types ───────────────────────────

export interface FarmerReportPayload {
  batch: HoneyBatchPayload;
  additional_data?: Record<string, unknown>;
}

export interface VerificationResult {
  status: "VERIFIED" | "FLAGGED_FOR_REVIEW" | "REJECTED" | string;
  confidence: number;
  flags: string[];
}

export interface ReportSubmissionResponse {
  report_id: number;
  report_hash: string | null;
  verification: VerificationResult;
}

export interface ReportStatusResponse {
  found: boolean;
  report_id: number;
  status?: string;
  confidence?: number;
  report_hash?: string;
  created_at?: string;
}

export interface PublicVerificationProof {
  verified: boolean;
  report_hash: string;
  verification: VerificationResult | null;
}

export interface ImageValidationResult {
  filename: string;
  content_type: string;
  valid: boolean;
  flags: string[];
  duplicate: boolean;
  phash?: string;
  gps_distance_meters?: number | null;
  exif_timestamp?: string | null;
}

// ── API Calls ─────────────────────────────────────────────────

/**
 * Submit a farmer harvest report for verification.
 * Wraps HoneyBatchPayload in the FarmerReportPayload envelope.
 */
export async function submitReport(
  batch: HoneyBatchPayload
): Promise<ReportSubmissionResponse> {
  const payload: FarmerReportPayload = { batch };
  const res = await fetch(`${API_BASE}/api/reports/submit`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Submit failed (${res.status}): ${err}`);
  }
  return res.json();
}

/**
 * Get the current verification status of a submitted report by ID.
 */
export async function getReportStatus(
  reportId: number
): Promise<ReportStatusResponse> {
  const res = await fetch(`${API_BASE}/api/reports/${reportId}/status`);
  if (!res.ok) throw new Error(`Status check failed: ${res.status}`);
  return res.json();
}

/**
 * Publicly verify a report using its SHA-256 hash.
 * Used by the public transparency portal (/verify/[hash]).
 */
export async function verifyReportHash(
  reportHash: string
): Promise<PublicVerificationProof> {
  const res = await fetch(`${API_BASE}/api/public/verify/${reportHash}`);
  if (!res.ok) throw new Error(`Verification failed: ${res.status}`);
  return res.json();
}

/**
 * Upload and validate a harvest image (EXIF GPS, 100m geofence, duplicate check).
 */
export async function validateImage(
  imageFile: File,
  registeredLatitude?: number,
  registeredLongitude?: number
): Promise<ImageValidationResult> {
  const form = new FormData();
  form.append("image", imageFile);
  if (registeredLatitude != null)
    form.append("registered_latitude", String(registeredLatitude));
  if (registeredLongitude != null)
    form.append("registered_longitude", String(registeredLongitude));

  const res = await fetch(`${API_BASE}/api/reports/validate-image`, {
    method: "POST",
    body: form,
  });
  if (!res.ok) throw new Error(`Image validation failed: ${res.status}`);
  return res.json();
}

/**
 * Health check — confirm backend is reachable.
 */
export async function checkHealth(): Promise<boolean> {
  try {
    const res = await fetch(`${API_BASE}/health`, { cache: "no-store" });
    return res.ok;
  } catch {
    return false;
  }
}

// ── Batch Lineage Trace ───────────────────────────────────────

export interface TraceNode {
  batch: HoneyBatchPayload;
  children: TraceNode[];
}

export async function fetchTrace(batchId: string): Promise<TraceNode> {
  const res = await fetch(`${API_BASE}/api/public/trace/${batchId}`);
  if (!res.ok) throw new Error(`Trace failed: ${res.status}`);
  return res.json();
}

export function getMockTrace(batchId: string): TraceNode {
  return {
    batch: {
      batch_id: batchId, parent_batch_id: null,
      child_batch_ids: [`${batchId}-B1`, `${batchId}-B2`],
      farmer_id: "FARMER-MH-042", harvest_weight_kg: 25.5,
      flora_source: "Litchi", gps_coordinates: "19.0760,72.8777",
      harvest_timestamp: 1695300000, status: "COMPLIANT",
      telemetry: { internal_temp_c: 34.5, internal_humidity_pct: 62.0, hive_weight_kg: 38.2, registered_hive_count: 12 },
      lab_results: { hmf_content_mg_kg: 18.5, moisture_percentage: 17.2, sucrose_percentage: 3.1, c3_c4_sugar_adulteration: false, lab_cert_id: "LAB-CERT-2025-08192" },
      blockchain_tx_hash: "0x7a3b9e1f4c2d8a6b5e0f1c3d7a9b2e4f6c8d0a1b3e5f7c9d1a3b5e7f9a2c4d",
      anomaly_flags: [],
    },
    children: [
      { batch: { batch_id: `${batchId}-B1`, parent_batch_id: batchId, child_batch_ids: [], farmer_id: "FARMER-MH-042", harvest_weight_kg: 15.0, flora_source: "Litchi", gps_coordinates: "19.0760,72.8777", harvest_timestamp: 1695400000, status: "BOTTLED", telemetry: null, lab_results: { hmf_content_mg_kg: 18.5, moisture_percentage: 17.2, sucrose_percentage: 3.1, c3_c4_sugar_adulteration: false, lab_cert_id: "LAB-CERT-2025-08192" }, blockchain_tx_hash: "0xb4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4", anomaly_flags: [] }, children: [] },
      { batch: { batch_id: `${batchId}-B2`, parent_batch_id: batchId, child_batch_ids: [], farmer_id: "FARMER-MH-042", harvest_weight_kg: 10.5, flora_source: "Litchi", gps_coordinates: "19.0760,72.8777", harvest_timestamp: 1695400000, status: "BOTTLED", telemetry: null, lab_results: { hmf_content_mg_kg: 19.0, moisture_percentage: 17.8, sucrose_percentage: 3.3, c3_c4_sugar_adulteration: false, lab_cert_id: "LAB-CERT-2025-08193" }, blockchain_tx_hash: "0xc5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5", anomaly_flags: [] }, children: [] },
    ],
  };
}

// ── Offline sync (kept for backward compat with offlineStore) ─

export async function syncBatches(
  batches: HoneyBatchPayload[]
): Promise<{ status: string; synced_count: number; batch_ids: string[] }> {
  // Member 4's real backend uses /api/reports/submit (one at a time).
  // We loop and submit each, collecting results.
  const results: string[] = [];
  for (const batch of batches) {
    try {
      const resp = await submitReport(batch);
      results.push(batch.batch_id);
      console.log(`Synced ${batch.batch_id} → report_id=${resp.report_id}`);
    } catch (e) {
      console.error(`Failed to sync ${batch.batch_id}:`, e);
    }
  }
  return {
    status: results.length > 0 ? "success" : "failed",
    synced_count: results.length,
    batch_ids: results,
  };
}
