"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { getStoredHarvests, type HarvestEntry } from "@/lib/offlineStore";

export default function TraceLandingPage() {
  const [batchId, setBatchId] = useState("");
  const [recentHarvests, setRecentHarvests] = useState<HarvestEntry[]>([]);
  const router = useRouter();

  useEffect(() => {
    setRecentHarvests(getStoredHarvests());
  }, []);

  function handleTrace(e: React.FormEvent) {
    e.preventDefault();
    if (batchId.trim()) {
      router.push(`/trace/${encodeURIComponent(batchId.trim())}`);
    }
  }

  return (
    <div className="mx-auto max-w-xl px-4 py-16 text-center">
      <div className="text-5xl mb-6">🔍</div>
      <h1 className="text-3xl font-bold text-stone-900">
        Trace Your Honey
      </h1>
      <p className="mt-3 text-stone-500">
        Enter a Batch ID or scan the QR code on your honey jar to trace its
        full journey from hive to shelf.
      </p>

      <form onSubmit={handleTrace} className="mt-8 flex gap-3">
        <input
          type="text"
          value={batchId}
          onChange={(e) => setBatchId(e.target.value)}
          placeholder="Enter Batch ID (e.g. HC-MUHE8K2E-HLOT)"
          className="input-field flex-1"
          required
        />
        <button type="submit" className="btn-primary shrink-0">
          Trace →
        </button>
      </form>

      {/* Real submitted harvests */}
      {recentHarvests.length > 0 && (
        <div className="mt-8 rounded-xl bg-amber-50 border border-amber-200 p-4 text-left">
          <p className="text-xs font-bold uppercase tracking-wider text-amber-900 mb-2">
            Your Logged Batches (Click to Trace Live):
          </p>
          <div className="flex flex-col gap-2">
            {[...recentHarvests].reverse().slice(0, 4).map((h) => (
              <button
                key={h.id}
                type="button"
                onClick={() => router.push(`/trace/${h.batch_id}`)}
                className="flex items-center justify-between rounded-lg bg-white p-2.5 text-xs border border-amber-200 hover:border-amber-400 hover:bg-amber-100/50 transition text-left"
              >
                <div>
                  <span className="font-mono font-bold text-stone-900">{h.batch_id}</span>
                  <span className="text-stone-500 ml-2">({h.flora_source} · {h.harvest_weight_kg} kg)</span>
                </div>
                <span className="text-honey-600 font-semibold">Inspect Lineage →</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Demo links */}
      <div className="mt-6 text-sm text-stone-400">
        <p className="text-xs">Or try a demo batch:</p>
        <div className="mt-2 flex flex-wrap justify-center gap-2">
          {["HC-DEMO-001", "HC-LITCHI-042", "HC-MUSTARD-099"].map((id) => (
            <button
              key={id}
              onClick={() => router.push(`/trace/${id}`)}
              className="rounded-lg bg-stone-100 px-3 py-1.5 text-xs font-medium text-stone-600 transition hover:bg-honey-100 hover:text-honey-700"
            >
              {id}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
