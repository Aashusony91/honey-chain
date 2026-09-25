"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { getCurrentUser, type UserSession } from "@/lib/auth";
import {
  saveHarvest,
  getStoredHarvests,
  getPendingHarvests,
  markSynced,
  isOnline,
  generateId,
  getFlagRecord,
  incrementFlagCount,
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

const MAX_STRIKES = 3;

export default function HarvestPage() {
  const router = useRouter();

  // ── Form State ──────────────────────────────────────────
  const [floraSource, setFloraSource]   = useState("");
  const [weightKg, setWeightKg]         = useState("");
  const [hiveCount, setHiveCount]       = useState("");
  const [gpsCoords, setGpsCoords]       = useState("");
  const [imageFile, setImageFile]       = useState<File | null>(null);

  // ── App State ───────────────────────────────────────────
  const [user, setUser]                 = useState<UserSession | null>(null);
  const [online, setOnline]             = useState(true);
  const [backendUp, setBackendUp]       = useState<boolean | null>(null);
  const [allHarvests, setAllHarvests]   = useState<HarvestEntry[]>([]);
  const [syncing, setSyncing]           = useState(false);
  const [submitting, setSubmitting]     = useState(false);
  const [gpsLoading, setGpsLoading]     = useState(false);
  const [imgValidating, setImgValidating] = useState(false);

  // ── Result & Error State ────────────────────────────────
  const [lastResult, setLastResult]         = useState<ReportSubmissionResponse | null>(null);
  const [submissionError, setSubmissionError] = useState<string | null>(null);
  const [imgResult, setImgResult]           = useState<ImageValidationResult | null>(null);
  const [toast, setToast]                   = useState<{ msg: string; type: "success" | "error" | "info" } | null>(null);
  const [farmerFlags, setFarmerFlags]       = useState<{ totalFlags: number; lastFlaggedAt: string | null }>({ totalFlags: 0, lastFlaggedAt: null });

  const refresh = useCallback(() => setAllHarvests(getStoredHarvests()), []);

  // ── Auth & Connectivity setup ───────────────────────────
  useEffect(() => {
    const session = getCurrentUser();
    if (!session) {
      router.push("/login");
      return;
    }
    setUser(session);
    setOnline(isOnline());
    refresh();

    // Load persistent flag strikes for this farmer
    const record = getFlagRecord(session.farmerId);
    setFarmerFlags(record);

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
  }, [refresh, router]);

  function showToast(msg: string, type: "success" | "error" | "info") {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 5000);
  }

  function handleResetStrikes() {
    if (!user) return;
    localStorage.removeItem("honeychain_flag_counts");
    setFarmerFlags({ totalFlags: 0, lastFlaggedAt: null });
    setLastResult(null);
    setSubmissionError(null);
    showToast("Strikes reset for demo testing.", "info");
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
    setSubmissionError(null);
    try {
      const result = await submitReport(batch);
      setLastResult(result);

      if (result.verification.status === "VERIFIED") {
        showToast(`✅ Verified! Confidence: ${(result.verification.confidence * 100).toFixed(0)}%`, "success");
        return true;
      } else {
        // Flagged by AI or Gateway validation!
        const flagCountToAdd = result.verification.flags.length > 0 ? 1 : 1;
        const updated = incrementFlagCount(batch.farmer_id, flagCountToAdd);
        setFarmerFlags(updated);
        showToast(`⚠️ Harvest Flagged by AI: ${result.verification.flags[0] || "Compliance anomaly"}`, "error");
        return false; // Keep form intact so farmer can inspect & fix
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Failed to reach verification gateway";
      setSubmissionError(msg);
      showToast(`Submission Error: ${msg}`, "error");
      return false;
    } finally {
      setSubmitting(false);
    }
  }

  // ── Main Form Submit ────────────────────────────────────
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!floraSource || !weightKg || !hiveCount || !user) {
      showToast("Please fill all required fields.", "error");
      return;
    }

    if (farmerFlags.totalFlags >= MAX_STRIKES) {
      showToast("⛔ Account Suspended: Maximum fraud flags reached. Contact Registry.", "error");
      return;
    }

    const batch: HoneyBatchPayload = {
      batch_id: generateId(),
      parent_batch_id: null,
      child_batch_ids: [],
      farmer_id: user.farmerId,
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
      const ok = await handleDirectSubmit(batch);
      if (ok) {
        // Only clear and save locally when successfully verified!
        const entry = saveHarvest({
          batch_id: batch.batch_id,
          farmer_id: user.farmerId,
          flora_source: floraSource,
          harvest_weight_kg: parseFloat(weightKg),
          hive_count: parseInt(hiveCount),
          gps_coordinates: gpsCoords || "0.0,0.0",
          harvest_timestamp: batch.harvest_timestamp,
        });
        markSynced([entry.id]);
        refresh();

        // Clear form only on success
        setFloraSource("");
        setWeightKg("");
        setHiveCount("");
        setGpsCoords("");
        setImageFile(null);
      }
    } else {
      // Save offline
      saveHarvest({
        batch_id: batch.batch_id,
        farmer_id: user.farmerId,
        flora_source: floraSource,
        harvest_weight_kg: parseFloat(weightKg),
        hive_count: parseInt(hiveCount),
        gps_coordinates: gpsCoords || "0.0,0.0",
        harvest_timestamp: batch.harvest_timestamp,
      });
      refresh();
      showToast(`Saved offline — ${batch.batch_id}. Sync when connected.`, "info");
      setFloraSource("");
      setWeightKg("");
      setHiveCount("");
      setGpsCoords("");
      setImageFile(null);
    }
  }

  // ── Sync pending offline entries ────────────────────────
  async function handleSync() {
    const pending = getPendingHarvests();
    if (!pending.length) { showToast("Nothing to sync!", "info"); return; }
    if (!online || !backendUp) { showToast("Backend unreachable.", "error"); return; }

    setSyncing(true);
    try {
      const payloads: HoneyBatchPayload[] = pending.map((h) => ({
        batch_id: h.batch_id,
        parent_batch_id: null,
        child_batch_ids: [],
        farmer_id: h.farmer_id,
        harvest_weight_kg: h.harvest_weight_kg,
        flora_source: h.flora_source,
        gps_coordinates: h.gps_coordinates,
        harvest_timestamp: h.harvest_timestamp,
        status: "RAW" as const,
        telemetry: {
          internal_temp_c: 34.0,
          internal_humidity_pct: 60.0,
          hive_weight_kg: h.harvest_weight_kg * 1.5,
          registered_hive_count: h.hive_count,
        },
        lab_results: null,
        blockchain_tx_hash: null,
        anomaly_flags: [],
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
  const isSuspended  = farmerFlags.totalFlags >= MAX_STRIKES;

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* Offline banner */}
      {!online && (
        <div className="offline-banner mb-6 flex items-center gap-3 rounded-xl bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
          <span className="text-lg">📡</span>
          <span><strong>Offline Mode</strong> — Harvests stored locally until connected.</span>
        </div>
      )}

      {/* Header */}
      <div className="mb-6">
        <div className="mb-4">
          <a href="/dashboard" className="text-sm text-amber-600 hover:text-amber-700 font-medium">
            ← Back to Dashboard
          </a>
        </div>
        <h1 className="text-2xl font-bold text-stone-900">🐝 Log Harvest</h1>
        <p className="mt-1 text-sm text-stone-500">
          Submit harvest telemetry for real-time AI fraud detection and blockchain anchoring.
        </p>
      </div>

      {/* ── Farmer Account Security & Strike Tracker ── */}
      <div className={`mb-6 rounded-xl border p-4 transition-all ${
        isSuspended
          ? "border-red-300 bg-red-50 text-red-900"
          : farmerFlags.totalFlags > 0
          ? "border-amber-300 bg-amber-50 text-amber-900"
          : "border-stone-200 bg-white"
      }`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-2xl">{isSuspended ? "🚫" : farmerFlags.totalFlags > 0 ? "⚠️" : "🛡️"}</span>
            <div>
              <p className="font-semibold text-sm">
                Farmer Identity: <span className="font-mono text-xs font-bold bg-stone-100 px-2 py-0.5 rounded border border-stone-200">{user?.farmerId}</span>
              </p>
              <p className="text-xs mt-0.5">
                {isSuspended ? (
                  <strong className="text-red-700">ACCOUNT SUSPENDED: 3/3 Fraud Strikes Accumulation.</strong>
                ) : farmerFlags.totalFlags > 0 ? (
                  <span className="text-amber-800">
                    <strong>Warning:</strong> {farmerFlags.totalFlags} of {MAX_STRIKES} fraud strikes logged. 3 strikes will suspend account.
                  </span>
                ) : (
                  <span className="text-emerald-700 font-medium">Account Standing: Excellent (0 Active Fraud Strikes)</span>
                )}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {/* Strike indicator pips */}
            <div className="flex gap-1.5" title={`${farmerFlags.totalFlags} of ${MAX_STRIKES} strikes`}>
              {[1, 2, 3].map((num) => (
                <span
                  key={num}
                  className={`inline-block h-3 w-3 rounded-full border ${
                    num <= farmerFlags.totalFlags
                      ? "bg-red-600 border-red-700 animate-pulse"
                      : "bg-stone-200 border-stone-300"
                  }`}
                />
              ))}
            </div>
            {farmerFlags.totalFlags > 0 && (
              <button
                type="button"
                onClick={handleResetStrikes}
                className="ml-2 text-[10px] text-stone-500 hover:text-stone-800 underline"
                title="Reset strikes for demo re-testing"
              >
                Reset Demo
              </button>
            )}
          </div>
        </div>
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

      {/* Submission Failure or Network Error Banner */}
      {submissionError && (
        <div className="mb-6 rounded-xl border border-red-300 bg-red-50 p-4 text-sm text-red-800">
          <p className="font-bold flex items-center gap-2">
            <span>❌ Submission Rejected by Gateway:</span>
          </p>
          <p className="mt-1 font-mono text-xs bg-white p-2 rounded border border-red-200">{submissionError}</p>
          <p className="mt-2 text-xs text-red-600">Please review the values entered below and try submitting again.</p>
        </div>
      )}

      {/* ── Active Verification Flagging Details ── */}
      {lastResult && lastResult.verification.status !== "VERIFIED" && (
        <div className="mb-6 rounded-xl border-2 border-red-500 bg-red-50 p-5 shadow-sm">
          <div className="flex items-start gap-3">
            <span className="text-3xl">🚨</span>
            <div className="w-full">
              <div className="flex items-center justify-between">
                <h3 className="text-base font-bold text-red-900">
                  SUBMISSION FLAGGED FOR AUDIT (Report #{lastResult.report_id})
                </h3>
                <span className="rounded-full bg-red-200 px-2.5 py-0.5 text-xs font-bold text-red-900">
                  Confidence: {(lastResult.verification.confidence * 100).toFixed(0)}%
                </span>
              </div>

              {/* Exact reasons list */}
              <div className="mt-3">
                <p className="text-xs font-bold uppercase tracking-wider text-red-700">
                  Exact Reason(s) Flagged by AI Fraud Engine:
                </p>
                <div className="mt-2 space-y-2">
                  {lastResult.verification.flags.map((flag, idx) => (
                    <div key={idx} className="rounded-lg bg-white border border-red-200 p-2.5 text-xs">
                      <p className="font-semibold text-red-800 flex items-center gap-1.5">
                        <span>⚠️ Flag {idx + 1}:</span>
                        <span>{flag}</span>
                      </p>
                      <p className="text-stone-500 mt-1 pl-4">
                        {flag.includes("STATISTICAL_YIELD_ANOMALY") &&
                          "Biophysical Violation: Honey produced per hive exceeds theoretical limit (max 35 kg/hive). System detected impossible production density."}
                        {flag.includes("GEOFENCE") &&
                          "Geographic Mismatch: Coordinates fall outside the 100-meter geo-fence of your registered apiary land boundary."}
                        {flag.includes("PHOTO_GPS_METADATA_MISSING") &&
                          "Metadata Warning: Uploaded image lacks EXIF GPS tags. System fallback verified device coordinates, but logged a transparency note."}
                        {flag.includes("DUPLICATE") &&
                          "Image Recycling: Perceptual hash matches an image previously submitted in the national ledger."}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Strict Policy Warning */}
              <div className="mt-4 rounded-lg bg-red-900 p-3 text-xs text-white">
                <p className="font-bold flex items-center gap-1.5">
                  <span>⚠️ STRICT REGISTRY WARNING:</span>
                </p>
                <p className="mt-1 leading-relaxed text-red-100">
                  The details provided violate validation integrity standards. Submitting falsified harvest figures, false GPS, or duplicate photos will lead to <strong>permanent blocking of your Farmer ID ({user?.farmerId})</strong> and suspension from the HoneyChain National Registry.
                </p>
                <p className="mt-2 text-[11px] font-mono text-red-200">
                  Active Strikes: {farmerFlags.totalFlags} / {MAX_STRIKES} (Reaching {MAX_STRIKES} locks all future submissions)
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── Successful Verification Result ── */}
      {lastResult && lastResult.verification.status === "VERIFIED" && (
        <div className="mb-6 rounded-xl border-2 border-emerald-500 bg-emerald-50 p-5 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-2xl">✅</span>
              <div>
                <h3 className="font-bold text-emerald-950">Harvest Approved & Verified!</h3>
                <p className="text-xs text-emerald-700">Batch #{lastResult.report_id} passed all mathematical and EXIF checks.</p>
              </div>
            </div>
            <span className="rounded-full bg-emerald-200 px-3 py-1 text-xs font-bold text-emerald-900">
              Confidence: {(lastResult.verification.confidence * 100).toFixed(0)}%
            </span>
          </div>

          {lastResult.report_hash && (
            <div className="mt-4 rounded-lg bg-white p-3 border border-emerald-200 text-xs">
              <span className="text-stone-500 font-medium">Cryptographic SHA-256 Hash:</span>
              <p className="font-mono text-stone-800 break-all mt-0.5">{lastResult.report_hash}</p>
              <a
                href={`/verify/${lastResult.report_hash}`}
                className="mt-2 inline-flex items-center gap-1 text-honey-600 hover:text-honey-700 font-semibold"
              >
                🔍 View Public On-Chain Proof →
              </a>
            </div>
          )}
        </div>
      )}

      {/* ── Harvest Form ── */}
      <form onSubmit={handleSubmit} className="card space-y-5">
        <div>
          <label className="label">Flora Source *</label>
          <select
            value={floraSource}
            onChange={(e) => setFloraSource(e.target.value)}
            className="input-field"
            required
            disabled={isSuspended}
          >
            <option value="">Select flora source…</option>
            {FLORA_OPTIONS.map((f) => <option key={f} value={f}>{f}</option>)}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="label">Weight (kg) *</label>
            <input
              type="number"
              step="0.1"
              min="0.1"
              value={weightKg}
              onChange={(e) => setWeightKg(e.target.value)}
              placeholder="e.g. 25.5"
              className="input-field"
              required
              disabled={isSuspended}
            />
            <p className="text-[11px] text-stone-400 mt-1">Normal yield: 15–30 kg per hive</p>
          </div>
          <div>
            <label className="label">Hive Count *</label>
            <input
              type="number"
              min="1"
              value={hiveCount}
              onChange={(e) => setHiveCount(e.target.value)}
              placeholder="e.g. 12"
              className="input-field"
              required
              disabled={isSuspended}
            />
            <p className="text-[11px] text-stone-400 mt-1">Registered apiary hives</p>
          </div>
        </div>

        <div>
          <label className="label">GPS Coordinates</label>
          <div className="flex gap-2">
            <input
              type="text"
              value={gpsCoords}
              onChange={(e) => setGpsCoords(e.target.value)}
              placeholder="lat,lon (e.g. 19.076,72.877)"
              className="input-field"
              disabled={isSuspended}
            />
            <button
              type="button"
              onClick={detectGps}
              disabled={gpsLoading || isSuspended}
              className="btn-secondary shrink-0 !px-3 !py-2 text-xs"
            >
              {gpsLoading ? "⏳" : "📍 Detect"}
            </button>
          </div>
        </div>

        {/* Image Upload */}
        <div>
          <label className="label">Harvest Photo {backendUp ? "(EXIF + GPS validated)" : ""}</label>
          <input
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            disabled={isSuspended}
            className="w-full text-sm text-stone-500 file:mr-4 file:rounded-lg file:border-0 file:bg-honey-50 file:px-4 file:py-2 file:text-sm file:font-medium file:text-honey-700 hover:file:bg-honey-100 cursor-pointer disabled:opacity-50"
          />
          {imgValidating && <p className="mt-1 text-xs text-stone-400">🔍 Validating image metadata…</p>}
          {imgResult && (
            <div className={`mt-2 rounded-lg px-3 py-2 text-xs ${
              imgResult.valid && !imgResult.duplicate ? "bg-emerald-50 text-emerald-700" : "bg-red-50 text-red-700"
            }`}>
              {imgResult.duplicate
                ? "⚠️ Duplicate image — this photo hash was already registered on-chain."
                : imgResult.valid
                ? "✅ Image validated. EXIF & GPS match registered farm."
                : `⚠️ Flags: ${imgResult.flags.join(", ")}`}
              {imgResult.gps_distance_meters != null && (
                <span className="ml-2 font-mono">Distance: {imgResult.gps_distance_meters.toFixed(0)}m</span>
              )}
            </div>
          )}
        </div>

        <button
          type="submit"
          disabled={submitting || imgValidating || isSuspended}
          className={`w-full py-3 rounded-xl font-bold text-sm transition-all shadow-md ${
            isSuspended
              ? "bg-stone-300 text-stone-500 cursor-not-allowed"
              : "bg-amber-500 hover:bg-amber-600 text-white"
          }`}
        >
          {submitting
            ? "⏳ Verifying with AI Engine…"
            : isSuspended
            ? "⛔ Account Suspended (3/3 Strikes)"
            : backendUp
            ? "🍯 Submit for AI Verification"
            : "💾 Save Offline"}
        </button>
      </form>

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

      {/* Toast Notification */}
      {toast && (
        <div className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 rounded-xl px-5 py-3 text-sm font-medium shadow-lg transition-all ${
          toast.type === "success" ? "bg-emerald-600 text-white" :
          toast.type === "error"   ? "bg-red-600 text-white" :
          "bg-stone-800 text-white"
        }`}>
          {toast.msg}
        </div>
      )}
    </div>
  );
}
