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
import { syncBatches, type HoneyBatchPayload } from "@/lib/api";

const FLORA_OPTIONS = [
  "Litchi",
  "Mustard",
  "Sunflower",
  "Eucalyptus",
  "Multiflora",
  "Acacia",
  "Jamun",
  "Ajwain",
  "Coriander",
  "Other",
];

export default function HarvestPage() {
  // ── Form State ──────────────────────────────────────────
  const [floraSource, setFloraSource] = useState("");
  const [weightKg, setWeightKg] = useState("");
  const [hiveCount, setHiveCount] = useState("");
  const [farmerId, setFarmerId] = useState("");
  const [gpsCoords, setGpsCoords] = useState("");

  // ── App State ───────────────────────────────────────────
  const [online, setOnline] = useState(true);
  const [allHarvests, setAllHarvests] = useState<HarvestEntry[]>([]);
  const [syncing, setSyncing] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: "success" | "error" | "info" } | null>(null);
  const [gpsLoading, setGpsLoading] = useState(false);

  // ── Refresh stored list ─────────────────────────────────
  const refresh = useCallback(() => {
    setAllHarvests(getStoredHarvests());
  }, []);

  // ── Online/offline listener ─────────────────────────────
  useEffect(() => {
    setOnline(isOnline());
    refresh();

    const goOnline = () => { setOnline(true); showToast("You're back online! You can sync now.", "info"); };
    const goOffline = () => { setOnline(false); showToast("You're offline. Harvests will be saved locally.", "info"); };

    window.addEventListener("online", goOnline);
    window.addEventListener("offline", goOffline);
    return () => {
      window.removeEventListener("online", goOnline);
      window.removeEventListener("offline", goOffline);
    };
  }, [refresh]);

  // ── Toast Helper ────────────────────────────────────────
  function showToast(msg: string, type: "success" | "error" | "info") {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  }

  // ── Auto-detect GPS ─────────────────────────────────────
  function detectGps() {
    if (!navigator.geolocation) {
      showToast("Geolocation not supported by your browser.", "error");
      return;
    }
    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setGpsCoords(`${pos.coords.latitude.toFixed(6)},${pos.coords.longitude.toFixed(6)}`);
        setGpsLoading(false);
        showToast("GPS coordinates detected!", "success");
      },
      () => {
        setGpsLoading(false);
        showToast("Could not get GPS. Please enter manually.", "error");
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }

  // ── Submit Harvest ──────────────────────────────────────
  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();

    if (!floraSource || !weightKg || !hiveCount || !farmerId) {
      showToast("Please fill all required fields.", "error");
      return;
    }

    const entry = saveHarvest({
      batch_id: generateId(),
      farmer_id: farmerId,
      flora_source: floraSource,
      harvest_weight_kg: parseFloat(weightKg),
      hive_count: parseInt(hiveCount),
      gps_coordinates: gpsCoords || "0.0,0.0",
      harvest_timestamp: Math.floor(Date.now() / 1000),
    });

    refresh();
    showToast(
      online
        ? `Harvest ${entry.batch_id} saved! Hit "Sync Now" to push.`
        : `Harvest ${entry.batch_id} saved offline. Will sync when online.`,
      "success"
    );

    // Reset form
    setFloraSource("");
    setWeightKg("");
    setHiveCount("");
    setGpsCoords("");
  }

  // ── Sync to Backend ─────────────────────────────────────
  async function handleSync() {
    const pending = getPendingHarvests();
    if (pending.length === 0) {
      showToast("Nothing to sync — all harvests are up to date!", "info");
      return;
    }
    if (!online) {
      showToast("You're offline. Connect to internet first.", "error");
      return;
    }

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

      await syncBatches(payloads);
      markSynced(pending.map((p) => p.id));
      refresh();
      showToast(`✅ ${pending.length} harvest(s) synced successfully!`, "success");
    } catch (err) {
      console.error("Sync error:", err);
      showToast("Sync failed. Backend may be offline. Will retry later.", "error");
    } finally {
      setSyncing(false);
    }
  }

  const pendingCount = allHarvests.filter((h) => !h.synced).length;
  const syncedCount = allHarvests.filter((h) => h.synced).length;

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* ── Offline Banner ──────────────────────────────── */}
      {!online && (
        <div className="offline-banner mb-6 flex items-center gap-3 rounded-xl bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-800">
          <span className="text-lg">📡</span>
          <span>
            <strong>Offline Mode</strong> — Harvests are stored locally and will
            sync when internet returns.
          </span>
        </div>
      )}

      {/* ── Header ──────────────────────────────────────── */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-stone-900">🐝 Log Harvest</h1>
        <p className="mt-1 text-sm text-stone-500">
          Record a new honey harvest. Works offline — syncs when connected.
        </p>
      </div>

      {/* ── Sync Status Bar ─────────────────────────────── */}
      <div className="card mb-6 flex items-center justify-between !p-4">
        <div className="flex items-center gap-4 text-sm">
          <span className="flex items-center gap-1.5">
            <span className={`h-2.5 w-2.5 rounded-full ${online ? "bg-emerald-400" : "bg-red-400"}`} />
            {online ? "Online" : "Offline"}
          </span>
          <span className="text-stone-400">|</span>
          <span className="text-stone-600">
            📦 {pendingCount} pending · ✅ {syncedCount} synced
          </span>
        </div>
        <button
          onClick={handleSync}
          disabled={syncing || pendingCount === 0 || !online}
          className="btn-primary !px-4 !py-2 text-xs"
        >
          {syncing ? "⏳ Syncing…" : `🔄 Sync Now (${pendingCount})`}
        </button>
      </div>

      {/* ── Harvest Form ────────────────────────────────── */}
      <form onSubmit={handleSubmit} className="card space-y-5">
        <div>
          <label className="label">Farmer / Beekeeper ID *</label>
          <input
            type="text"
            value={farmerId}
            onChange={(e) => setFarmerId(e.target.value)}
            placeholder="e.g. FARMER-MH-042"
            className="input-field"
            required
          />
        </div>

        <div>
          <label className="label">Flora Source *</label>
          <select
            value={floraSource}
            onChange={(e) => setFloraSource(e.target.value)}
            className="input-field"
            required
          >
            <option value="">Select flora source…</option>
            {FLORA_OPTIONS.map((f) => (
              <option key={f} value={f}>
                {f}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="label">Harvest Weight (kg) *</label>
            <input
              type="number"
              step="0.1"
              min="0.1"
              value={weightKg}
              onChange={(e) => setWeightKg(e.target.value)}
              placeholder="e.g. 25.5"
              className="input-field"
              required
            />
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
            />
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
            />
            <button
              type="button"
              onClick={detectGps}
              disabled={gpsLoading}
              className="btn-secondary shrink-0 !px-3 !py-2 text-xs"
            >
              {gpsLoading ? "⏳" : "📍 Detect"}
            </button>
          </div>
        </div>

        <button type="submit" className="btn-primary w-full">
          🍯 Save Harvest
        </button>
      </form>

      {/* ── Recent Harvests ─────────────────────────────── */}
      {allHarvests.length > 0 && (
        <div className="mt-8">
          <h2 className="mb-4 text-lg font-bold text-stone-900">
            Recent Harvests
          </h2>
          <div className="space-y-3">
            {[...allHarvests].reverse().slice(0, 10).map((h) => (
              <div
                key={h.id}
                className="card flex items-center justify-between !p-4"
              >
                <div>
                  <p className="text-sm font-semibold text-stone-900">
                    {h.batch_id}
                  </p>
                  <p className="text-xs text-stone-500">
                    {h.flora_source} · {h.harvest_weight_kg} kg · {h.hive_count}{" "}
                    hives
                  </p>
                </div>
                <span className={h.synced ? "badge-verified" : "badge-pending"}>
                  {h.synced ? "✅ Synced" : "⏳ Pending"}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Toast ───────────────────────────────────────── */}
      {toast && (
        <div
          className={`fixed bottom-6 left-1/2 -translate-x-1/2 z-50 rounded-xl px-5 py-3 text-sm font-medium shadow-lg transition-all ${
            toast.type === "success"
              ? "bg-emerald-600 text-white"
              : toast.type === "error"
              ? "bg-red-600 text-white"
              : "bg-stone-800 text-white"
          }`}
        >
          {toast.msg}
        </div>
      )}
    </div>
  );
}
