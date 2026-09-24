"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

export default function TraceLandingPage() {
  const [batchId, setBatchId] = useState("");
  const router = useRouter();

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
          placeholder="Enter Batch ID (e.g. HC-M1ABCD-X2YZ)"
          className="input-field flex-1"
          required
        />
        <button type="submit" className="btn-primary shrink-0">
          Trace →
        </button>
      </form>

      {/* Demo links */}
      <div className="mt-8 text-sm text-stone-400">
        <p>Try a demo batch:</p>
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
