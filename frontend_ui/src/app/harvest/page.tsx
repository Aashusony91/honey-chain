"use client";

import { useState, useEffect, useCallback } from "react";
import {
  saveHarvest,
  getStoredHarvests,
  getPendingHarvests,
  markSynced,
  isOnline,
  generateId,
  type HarvestEntry,
} from "@/lib/offlineStore";
import {
  syncBatches,
  submitReport,
  validateImage,
  checkHealth,
  type HoneyBatchPayload,
  type ReportSubmissionResponse,
  type ImageValidationResult,
} from "@/lib/api";

const FLORA_OPTIONS = [
  "Litchi", "Mustard", "Sunflower", "Eucalyptus",
  "Multiflora", "Acacia", "Jamun", "Ajwain", "Coriander", "Other",
];

export default function HarvestPage() {
  // ── Form State ──────────────────────────────────────────
  const [floraSource, setFloraSource]   = useState("");
  const [weightKg, setWeightKg]         = useState("");
  const [hiveCount, setHiveCount]       = useState("");
  const [farmerId, setFarmerId]         = useState("");
  const [gpsCoords, setGpsCoords]       = useState("");
  const [imageFile, setImageFile]       = useState<File | null>(null);

  // ── App State ───────────────────────────────────────────
  const [online, setOnline]             = useState(true);
  const [backendUp, setBackendUp]       = useState<boolean | null>(null);
  const [allHarvests, setAllHarvests]   = useState<HarvestEntry[]>([]);
  const [syncing, setSyncing]           = useState(false);
  const [submitting, setSubmitting]     = useState(false);
  const [gpsLoading, setGpsLoading]     = useState(false);
  const [imgValidating, setImgValidating] = useState(false);

  // ── Result State ────────────────────────────────────────
  const [lastResult, setLastResult]     = useState<ReportSubmissionResponse | null>(null);
  const [imgResult, setImgResult]       = useState<ImageValidationResult | null>(null);
  const [toast, setToast]               = useState<{ msg: string; type: "success" | "error" | "info" } | null>(null);

  const refresh = useCallback(() => setAllHarvests(getStoredHarvests()), []);

  // ── Connectivity setup ──────────────────────────────────
  useEffect(() => {
    setOnline(isOnline());
    refresh();

    checkHealth().then(setBackendUp);

    const goOnline = () => {
      setOnline(true);
      checkHealth().then(setBackendUp);
      showToast("You're back online!", "info");
    };
    const goOffline = () => {
      setOnline(false);
      setBackendUp(false);
      showToast("Offline — harvests saved locally.", "info");
    };

    window.addEventListener("online", goOnline);
    window.addEventListener("offline", goOffline);
    return () => {
      window.removeEventListener("online", goOnline);
      window.removeEventListener("offline", goOffline);
    };
  }, [refresh]);

  function showToast(msg: string, type: "success" | "error" | "info") {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 5000);
  }

  // ── Auto GPS ────────────────────────────────────────────
  function detectGps() {
    if (!navigator.geolocation) { showToast("Geolocation not supported.", "error"); return; }
    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setGpsCoords(`${pos.coords.latitude.toFixed(6)},${pos.coords.longitude.toFixed(6)}`);
        setGpsLoading(false);
        showToast("GPS detected!", "success");
      },
      () => { setGpsLoading(false); showToast("GPS failed — enter manually.", "error"); },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }

  // ── Image Validation ────────────────────────────────────
  async function handleImageChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] || null;
    setImageFile(file);
    setImgResult(null);
    if (!file || !backendUp) return;

    setImgValidating(true);
    try {
      const [lat, lon] = gpsCoords.split(",").map(Number);
      const result = await validateImage(
        file,
        isNaN(lat) ? undefined : lat,
        isNaN(lon) ? undefined : lon
      );
      setImgResult(result);
      if (result.duplicate) showToast("⚠️ Duplicate image detected!", "error");
      else if (!result.valid) showToast("⚠️ Image validation flagged issues.", "error");
      else showToast("✅ Image validated successfully.", "success");
    } catch {
      showToast("Image validation unavailable — will submit without it.", "info");
    } finally {
      setImgValidating(false);
    }
  }

  // ── Submit directly to backend ──────────────────────────
  async function handleDirectSubmit(batch: HoneyBatchPayload) {
    setSubmitting(true);
    try {
      const result = await submitReport(batch);
      setLastResult(result);
      showToast(
        result.verification.status === "VERIFIED"
          ? `✅ Verified! Confidence: ${(result.verification.confidence * 100).toFixed(0)}%`
          : `⚠️ Flagged for review. Check anomalies below.`,
        result.verification.status === "VERIFIED" ? "success" : "error"
      );
      return true;
    } catch {
      return false;
    } finally {
      setSubmitting(false);
    }
  }

  // ── Main Form Submit ────────────────────────────────────
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!floraSource || !weightKg || !hiveCount || !farmerId) {
      showToast("Please fill all required fields.", "error"); return;
    }

    const batch: HoneyBatchPayload = {
      batch_id: generateId(),
      parent_batch_id: null,
      child_batch_ids: [],
      farmer_id: farmerId,
      harvest_weight_kg: parseFloat(weightKg),
      flora_source: floraSource,
      gps_coordinates: gpsCoords || "0.0,0.0",
      harvest_timestamp: Math.floor(Date.now() / 1000),
      status: "RAW",
      telemetry: {
        internal_temp_c: 34.0,
        internal_humidity_pct: 60.0,
        hive_weight_kg: parseFloat(weightKg) * 1.5,
        registered_hive_count: parseInt(hiveCount),
      },
      lab_results: null,
      blockchain_tx_hash: null,
      anomaly_flags: [],
    };

    if (backendUp && online) {
      // Submit directly to backend
      const ok = await handleDirectSubmit(batch);
      if (ok) {
        // Also save locally as synced
        const entry = saveHarvest({
          batch_id: batch.batch_id, farmer_id: farmerId,
          flora_source: floraSource, harvest_weight_kg: parseFloat(weightKg),
          hive_count: parseInt(hiveCount), gps_coordinates: gpsCoords || "0.0,0.0",
          harvest_timestamp: batch.harvest_timestamp,
        });
        markSynced([entry.id]);
        refresh();
      }
    } else {
      // Save offline
      saveHarvest({
        batch_id: batch.batch_id, farmer_id: farmerId,
        flora_source: floraSource, harvest_weight_kg: parseFloat(weightKg),
        hive_count: parseInt(hiveCount), gps_coordinates: gpsCoords || "0.0,0.0",
        harvest_timestamp: batch.harvest_timestamp,
      });
      refresh();
      showToast(`Saved offline — ${batch.batch_id}. Sync when connected.`, "info");
    }

    // Reset form
    setFloraSource(""); setWeightKg(""); setHiveCount("");
    setGpsCoords(""); setImageFile(null);
  }

  // ── Sync pending offline entries ────────────────────────
  async function handleSync() {
    const pending = getPendingHarvests();
    if (!pending.length) { showToast("Nothing to sync!", "info"); return; }
    if (!online || !backendUp) { showToast("Backend unreachable.", "error"); return; }

    setSyncing(true);
    try {
      const payloads: HoneyBatchPayload[] = pending.map((h) => ({
        batch_id: h.batch_id, parent_batch_id: null, child_batch_ids: [],
        farmer_id: h.farmer_id, harvest_weight_kg: h.harvest_weight_kg,
        flora_source: h.flora_source, gps_coordinates: h.gps_coordinates,
        harvest_timestamp: h.harvest_timestamp, status: "RAW" as const,
        telemetry: {
          internal_temp_c: 34.0, internal_humidity_pct: 60.0,
          hive_weight_kg: h.harvest_weight_kg * 1.5,
          registered_hive_count: h.hive_count,
        },
        lab_results: null, blockchain_tx_hash: null, anomaly_flags: [],
      }));

      const result = await syncBatches(payloads);
      markSynced(pending.filter((_, i) => i < result.synced_count).map((p) => p.id));
      refresh();
      showToast(`✅ ${result.synced_count}/${pending.length} synced!`, "success");
    } catch {
      showToast("Sync failed. Try again later.", "error");
    } finally {
      setSyncing(false);
    }
  }

  const pendingCount = allHarvests.filter((h) => !h.synced).length;
  const syncedCount  = allHarvests.filter((h) => h.synced).length;

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* Offline banner */}
      {!online && (
        <div className="offline-banner mb-6 flex items-center gap-3 rounded-xl bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
          <span className="text-lg">📡</span>
          <span><strong>Offline Mode</strong> — Harvests stored locally until connected.</span>
        </div>
      )}

      <div className="mb-8">
        <h1 className="text-2xl font-bold text-stone-900">🐝 Log Harvest</h1>
        <p className="mt-1 text-sm text-stone-500">
          Submit a honey harvest for AI verification and blockchain anchoring.
        </p>
      </div>

      {/* Status Bar */}
      <div className="card mb-6 flex flex-wrap items-center justify-between gap-3 !p-4">
        <div className="flex items-center gap-4 text-sm flex-wrap">
          <span className="flex items-center gap-1.5">
            <span className={`h-2.5 w-2.5 rounded-full ${online ? "bg-emerald-400" : "bg-red-400"}`} />
            {online ? "Online" : "Offline"}
          </span>
          <span className="text-stone-400">|</span>
          <span className="flex items-center gap-1.5">
            <span className={`h-2.5 w-2.5 rounded-full ${backendUp ? "bg-emerald-400" : backendUp === null ? "bg-amber-400" : "bg-red-400"}`} />
            Backend {backendUp ? "Connected" : backendUp === null ? "Checking…" : "Offline"}
          </span>
          <span className="text-stone-400">|</span>
          <span className="text-stone-600">📦 {pendingCount} pending · ✅ {syncedCount} synced</span>
        </div>
        <button
          onClick={handleSync}
          disabled={syncing || pendingCount === 0 || !online || !backendUp}
          className="btn-primary !px-4 !py-2 text-xs"
        >
          {syncing ? "⏳ Syncing…" : `🔄 Sync (${pendingCount})`}
        </button>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit} className="card space-y-5">
        <div>
          <label className="label">Farmer / Beekeeper ID *</label>
          <input type="text" value={farmerId} onChange={(e) => setFarmerId(e.target.value)}
            placeholder="e.g. FARMER-MH-042" className="input-field" required />
        </div>

        <div>
          <label className="label">Flora Source *</label>
          <select value={floraSource} onChange={(e) => setFloraSource(e.target.value)}
            className="input-field" required>
            <option value="">Select flora source…</option>
            {FLORA_OPTIONS.map((f) => <option key={f} value={f}>{f}</option>)}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="label">Weight (kg) *</label>
            <input type="number" step="0.1" min="0.1" value={weightKg}
              onChange={(e) => setWeightKg(e.target.value)} placeholder="25.5"
              className="input-field" required />
          </div>
          <div>
            <label className="label">Hive Count *</label>
            <input type="number" min="1" value={hiveCount}
              onChange={(e) => setHiveCount(e.target.value)} placeholder="12"
              className="input-field" required />
          </div>
        </div>

        <div>
          <label className="label">GPS Coordinates</label>
          <div className="flex gap-2">
            <input type="text" value={gpsCoords} onChange={(e) => setGpsCoords(e.target.value)}
              placeholder="lat,lon (e.g. 19.076,72.877)" className="input-field" />
            <button type="button" onClick={detectGps} disabled={gpsLoading}
              className="btn-secondary shrink-0 !px-3 !py-2 text-xs">
              {gpsLoading ? "⏳" : "📍 Detect"}
            </button>
          </div>
        </div>

        {/* Image Upload */}
        <div>
          <label className="label">Harvest Photo {backendUp ? "(EXIF + GPS validated)" : ""}</label>
          <input type="file" accept="image/*" onChange={handleImageChange}
            className="w-full text-sm text-stone-500 file:mr-4 file:rounded-lg file:border-0 file:bg-honey-50 file:px-4 file:py-2 file:text-sm file:font-medium file:text-honey-700 hover:file:bg-honey-100 cursor-pointer" />
          {imgValidating && <p className="mt-1 text-xs text-stone-400">🔍 Validating image…</p>}
          {imgResult && (
            <div className={`mt-2 rounded-lg px-3 py-2 text-xs ${imgResult.valid && !imgResult.duplicate ? "bg-emerald-50 text-emerald-700" : "bg-red-50 text-red-700"}`}>
              {imgResult.duplicate
                ? "⚠️ Duplicate image — this photo was used before."
                : imgResult.valid
                  ? "✅ Image validated. EXIF & GPS OK."
                  : `⚠️ Flags: ${imgResult.flags.join(", ")}`}
              {imgResult.gps_distance_meters != null &&
                <span className="ml-2">GPS dist: {imgResult.gps_distance_meters.toFixed(0)}m</span>}
            </div>
          )}
        </div>

        <button type="submit" disabled={submitting || imgValidating} className="btn-primary w-full">
          {submitting ? "⏳ Submitting…" : backendUp ? "🍯 Submit for Verification" : "💾 Save Offline"}
        </button>
      </form>

      {/* Verification Result */}
      {lastResult && (
        <div className={`mt-6 card ${lastResult.verification.status === "VERIFIED" ? "border-emerald-200 bg-emerald-50" : "border-amber-200 bg-amber-50"}`}>
          <h3 className="font-bold text-stone-900 mb-3">
            {lastResult.verification.status === "VERIFIED" ? "✅ Verified!" : "⚠️ Flagged for Review"}
          </h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-stone-600">Report ID:</span>
              <span className="font-mono font-medium">#{lastResult.report_id}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-stone-600">Confidence:</span>
              <span className="font-semibold">{(lastResult.verification.confidence * 100).toFixed(1)}%</span>
            </div>
            {lastResult.report_hash && (
              <div>
                <span className="text-stone-600">SHA-256 Hash:</span>
                <p className="mt-1 break-all font-mono text-xs bg-white rounded-lg p-2 border border-stone-200">
                  {lastResult.report_hash}
                </p>
                <a href={`/verify/${lastResult.report_hash}`}
                  className="mt-1 inline-flex items-center gap-1 text-xs text-honey-600 hover:text-honey-700">
                  🔍 View public proof →
                </a>
              </div>
            )}
            {lastResult.verification.flags.length > 0 && (
              <div>
                <span className="text-stone-600">Flags:</span>
                <ul className="mt-1 space-y-1">
                  {lastResult.verification.flags.map((f, i) => (
                    <li key={i} className="text-xs text-red-700">• {f}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Recent Harvests */}
      {allHarvests.length > 0 && (
        <div className="mt-8">
          <h2 className="mb-4 text-lg font-bold text-stone-900">Recent Harvests</h2>
          <div className="space-y-3">
            {[...allHarvests].reverse().slice(0, 8).map((h) => (
              <div key={h.id} className="card flex items-center justify-between !p-4">
                <div>
                  <p className="text-sm font-semibold text-stone-900">{h.batch_id}</p>
                  <p className="text-xs text-stone-500">{h.flora_source} · {h.harvest_weight_kg}kg · {h.hive_count} hives</p>
                </div>
                <span className={h.synced ? "badge-verified" : "badge-pending"}>
                  {h.synced ? "✅ Synced" : "⏳ Pending"}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Toast */}
      {toast && (
        <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 rounded-xl px-5 py-3 text-sm font-medium shadow-lg ${
          toast.type === "success" ? "bg-emerald-600 text-white" :
          toast.type === "error"   ? "bg-red-600 text-white" :
          "bg-stone-800 text-white"}`}>
          {toast.msg}
        </div>
      )}
    </div>
  );
}
