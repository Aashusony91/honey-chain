"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { fetchTrace, getMockTrace, type TraceNode, type HoneyBatchPayload } from "@/lib/api";
import {
  getChainHistory,
  isBlockchainReachable,
  getEtherscanTxUrl,
  type ChainHistory,
} from "@/lib/blockchain";

/* ── Helper: format unix timestamp ─────────────────────── */
function formatDate(ts: number): string {
  return new Date(ts * 1000).toLocaleDateString("en-IN", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

/* ── Helper: short tx hash ─────────────────────────────── */
function shortHash(hash: string): string {
  return `${hash.slice(0, 10)}…${hash.slice(-8)}`;
}

/* ── Lab Check Component ───────────────────────────────── */
function LabCheck({
  label,
  value,
  unit,
  pass,
}: {
  label: string;
  value: number;
  unit: string;
  pass: boolean;
}) {
  return (
    <div className="flex items-center justify-between rounded-lg bg-stone-50 px-3 py-2">
      <span className="text-sm text-stone-600">{label}</span>
      <span className="flex items-center gap-2 text-sm font-medium">
        {value} {unit}
        <span
          className={`flex h-5 w-5 items-center justify-center rounded-full text-xs ${
            pass
              ? "bg-emerald-100 text-emerald-600"
              : "bg-red-100 text-red-600"
          }`}
        >
          {pass ? "✓" : "✗"}
        </span>
      </span>
    </div>
  );
}

/* ── Status Badge ──────────────────────────────────────── */
function StatusBadge({ status }: { status: string }) {
  const map: Record<string, { class: string; label: string }> = {
    RAW: { class: "badge-pending", label: "🟡 Raw" },
    LAB_TESTING: { class: "badge-pending", label: "🔬 Lab Testing" },
    COMPLIANT: { class: "badge-verified", label: "✅ Compliant" },
    SUSPENDED: { class: "badge-flagged", label: "🚫 Suspended" },
    BOTTLED: { class: "badge-verified", label: "🍯 Bottled" },
  };
  const s = map[status] || { class: "badge-pending", label: status };
  return <span className={s.class}>{s.label}</span>;
}

/* ── Batch Timeline Card ───────────────────────────────── */
function BatchCard({
  batch,
  isRoot,
  chainHistory,
  chainLoading,
  blockchainUp,
}: {
  batch: HoneyBatchPayload;
  isRoot: boolean;
  chainHistory: ChainHistory | null;
  chainLoading: boolean;
  blockchainUp: boolean;
}) {
  const lab = batch.lab_results;

  return (
    <div className="card relative ml-12">
      {/* Timeline dot */}
      <div
        className={`absolute -left-[2.15rem] top-6 h-4 w-4 rounded-full border-[3px] border-white shadow ${
          isRoot ? "bg-honey-500" : "bg-emerald-400"
        }`}
      />

      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div>
          <h3 className="text-lg font-bold text-stone-900">{batch.batch_id}</h3>
          <p className="text-xs text-stone-400">
            {isRoot ? "🌿 Origin Harvest" : "📦 Split Batch"} ·{" "}
            {formatDate(batch.harvest_timestamp)}
          </p>
        </div>
        <StatusBadge status={batch.status} />
      </div>

      {/* ── Section 1: Origin Farm ─────────────────────── */}
      {isRoot && (
        <div className="mt-4 rounded-xl bg-honey-50 p-4">
          <h4 className="text-sm font-semibold text-honey-800 mb-2">
            🏡 Origin Farm
          </h4>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <span className="text-stone-500">Farmer:</span>{" "}
              <span className="font-medium">{batch.farmer_id}</span>
            </div>
            <div>
              <span className="text-stone-500">Flora:</span>{" "}
              <span className="font-medium">{batch.flora_source}</span>
            </div>
            <div>
              <span className="text-stone-500">Weight:</span>{" "}
              <span className="font-medium">{batch.harvest_weight_kg} kg</span>
            </div>
            <div>
              <span className="text-stone-500">GPS:</span>{" "}
              <span className="font-mono text-xs">{batch.gps_coordinates}</span>
            </div>
          </div>
          {batch.telemetry && (
            <div className="mt-3 grid grid-cols-2 gap-2 text-sm border-t border-honey-200 pt-3">
              <div>
                <span className="text-stone-500">Hive Temp:</span>{" "}
                <span className="font-medium">{batch.telemetry.internal_temp_c}°C</span>
              </div>
              <div>
                <span className="text-stone-500">Humidity:</span>{" "}
                <span className="font-medium">{batch.telemetry.internal_humidity_pct}%</span>
              </div>
              <div>
                <span className="text-stone-500">Hive Weight:</span>{" "}
                <span className="font-medium">{batch.telemetry.hive_weight_kg} kg</span>
              </div>
              <div>
                <span className="text-stone-500">Hives:</span>{" "}
                <span className="font-medium">{batch.telemetry.registered_hive_count}</span>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ── Section 2: Lab Results ─────────────────────── */}
      {lab && (
        <div className="mt-4">
          <h4 className="text-sm font-semibold text-stone-700 mb-2">
            🔬 Lab Test Results
            {lab.lab_cert_id && (
              <span className="ml-2 text-xs font-normal text-stone-400">
                ({lab.lab_cert_id})
              </span>
            )}
          </h4>
          <div className="space-y-1.5">
            <LabCheck
              label="Moisture"
              value={lab.moisture_percentage}
              unit="%"
              pass={lab.moisture_percentage <= 20}
            />
            <LabCheck
              label="HMF Content"
              value={lab.hmf_content_mg_kg}
              unit="mg/kg"
              pass={lab.hmf_content_mg_kg <= 40}
            />
            <LabCheck
              label="Sucrose"
              value={lab.sucrose_percentage}
              unit="%"
              pass={lab.sucrose_percentage <= 5}
            />
            <div className="flex items-center justify-between rounded-lg bg-stone-50 px-3 py-2">
              <span className="text-sm text-stone-600">C3/C4 Sugar Adulteration</span>
              <span
                className={`flex h-5 w-5 items-center justify-center rounded-full text-xs ${
                  !lab.c3_c4_sugar_adulteration
                    ? "bg-emerald-100 text-emerald-600"
                    : "bg-red-100 text-red-600"
                }`}
              >
                {!lab.c3_c4_sugar_adulteration ? "✓" : "✗"}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* ── Section 3: Blockchain (Live from Sepolia/Localhost) ── */}
      {batch.blockchain_tx_hash && (
        <div className="mt-4 rounded-xl bg-indigo-50 p-4">
          <h4 className="text-sm font-semibold text-indigo-800 mb-1">
            ⛓️ Blockchain Record
          </h4>

          {chainLoading && (
            <p className="text-xs text-indigo-400 animate-pulse">Fetching on-chain data…</p>
          )}

          {chainHistory && !chainLoading && (
            <>
              <div className="mb-2 flex items-center gap-2">
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700">
                  ✅ {chainHistory.network === "sepolia" ? "Sepolia Testnet" : "Local Node"}
                </span>
                <span className="text-xs text-indigo-600">
                  State: <strong>{chainHistory.batch.stateLabel}</strong> · {chainHistory.batch.weightKg} kg
                </span>
              </div>
              <div className="space-y-1 mb-3">
                {chainHistory.history.map((cp, i) => (
                  <div key={i} className="flex items-center gap-2 text-xs text-indigo-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-indigo-400" />
                    <span className="font-medium">{cp.stateLabel}</span>
                    <span className="text-indigo-400">·</span>
                    <span className="font-mono text-indigo-500">
                      {cp.actor.slice(0, 8)}…{cp.actor.slice(-6)}
                    </span>
                    <span className="text-indigo-400">·</span>
                    <span>{new Date(cp.timestamp).toLocaleDateString("en-IN")}</span>
                  </div>
                ))}
              </div>
            </>
          )}

          <a
            href={
              getEtherscanTxUrl(batch.blockchain_tx_hash) ??
              `#${batch.blockchain_tx_hash}`
            }
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 rounded-lg bg-indigo-100 px-3 py-1.5 font-mono text-xs text-indigo-700 transition hover:bg-indigo-200"
          >
            🔗 {shortHash(batch.blockchain_tx_hash)}
            <span className="text-indigo-400">↗</span>
          </a>

          {!blockchainUp && !chainLoading && (
            <p className="mt-2 text-xs text-indigo-400">
              ℹ️ Blockchain node offline — fill .env.local to connect Sepolia.
            </p>
          )}
        </div>
      )}


      {/* ── Anomaly Flags ──────────────────────────────── */}
      {batch.anomaly_flags.length > 0 && (
        <div className="mt-4 rounded-xl bg-red-50 p-4">
          <h4 className="text-sm font-semibold text-red-800 mb-2">
            ⚠️ Anomaly Flags
          </h4>
          <ul className="space-y-1">
            {batch.anomaly_flags.map((flag, i) => (
              <li key={i} className="text-sm text-red-700">
                • {flag}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

/* ── Main Page ─────────────────────────────────────────── */
export default function TraceDetailPage() {
  const params = useParams();
  const batchId = decodeURIComponent(params.batchId as string);

  const [trace, setTrace]           = useState<TraceNode | null>(null);
  const [loading, setLoading]       = useState(true);
  const [error, setError]           = useState<string | null>(null);
  const [usingMock, setUsingMock]   = useState(false);

  // ── Blockchain state ─────────────────────────────────────
  const [chainHistory, setChainHistory] = useState<ChainHistory | null>(null);
  const [chainLoading, setChainLoading] = useState(false);
  const [blockchainUp, setBlockchainUp] = useState(false);

  useEffect(() => {
    async function load() {
      setLoading(true);
      setError(null);

      // 1. Fetch backend trace (existing logic unchanged)
      try {
        const data = await fetchTrace(batchId);
        setTrace(data);
        setUsingMock(false);
      } catch {
        setTrace(getMockTrace(batchId));
        setUsingMock(true);
      } finally {
        setLoading(false);
      }

      // 2. Fetch blockchain data in parallel (non-blocking)
      const chainReachable = await isBlockchainReachable();
      setBlockchainUp(chainReachable);
      if (chainReachable) {
        setChainLoading(true);
        try {
          // The blockchain batch ID is numeric — extract from batch string ID if present
          // e.g. "HC-BATCH-3A9F1C" → try batchId param as number for demo, default to 1
          const numericId = parseInt(batchId) || 1;
          const history = await getChainHistory(numericId);
          setChainHistory(history);
        } catch {
          setChainHistory(null);
        } finally {
          setChainLoading(false);
        }
      }
    }
    load();
  }, [batchId]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-32">
        <div className="text-center">
          <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-honey-200 border-t-honey-500" />
          <p className="text-sm text-stone-500">
            Tracing batch <strong>{batchId}</strong>…
          </p>
        </div>
      </div>
    );
  }

  if (error && !trace) {
    return (
      <div className="mx-auto max-w-xl px-4 py-16 text-center">
        <div className="text-5xl mb-4">❌</div>
        <h2 className="text-xl font-bold text-stone-900">Batch Not Found</h2>
        <p className="mt-2 text-stone-500">{error}</p>
      </div>
    );
  }

  if (!trace) return null;

  // Flatten the tree for timeline rendering
  function flattenNodes(node: TraceNode): TraceNode[] {
    return [node, ...node.children.flatMap(flattenNodes)];
  }
  const allNodes = flattenNodes(trace);

  return (
    <div className="mx-auto max-w-2xl px-4 py-8">
      {/* ── Header ──────────────────────────────────────── */}
      <div className="mb-2">
        <a
          href="/trace"
          className="text-sm text-honey-600 hover:text-honey-700"
        >
          ← Back to Trace
        </a>
      </div>

      <div className="mb-8 flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-stone-900">
            🔍 Batch Lineage
          </h1>
          <p className="mt-1 font-mono text-sm text-stone-500">{batchId}</p>
        </div>
        {trace.batch.anomaly_flags.length === 0 ? (
          <div className="flex flex-col items-center gap-1 rounded-xl bg-emerald-50 border border-emerald-200 px-4 py-3">
            <span className="text-2xl">✅</span>
            <span className="text-xs font-bold text-emerald-700">VERIFIED</span>
          </div>
        ) : (
          <div className="flex flex-col items-center gap-1 rounded-xl bg-red-50 border border-red-200 px-4 py-3">
            <span className="text-2xl">🚩</span>
            <span className="text-xs font-bold text-red-700">FLAGGED</span>
          </div>
        )}
      </div>

      {usingMock && (
        <div className="mb-6 rounded-xl bg-blue-50 border border-blue-200 px-4 py-3 text-sm text-blue-700">
          ℹ️ <strong>Demo Mode</strong> — Showing mock data. Connect the
          Backend Gateway (port 8000) for live tracing.
        </div>
      )}

      {/* ── Timeline ────────────────────────────────────── */}
      <div className="relative">
        {/* Vertical line */}
        {allNodes.length > 1 && <div className="timeline-line" />}

        <div className="space-y-6">
          {allNodes.map((node, idx) => (
            <BatchCard
              key={node.batch.batch_id}
              batch={node.batch}
              isRoot={idx === 0}
              chainHistory={chainHistory}
              chainLoading={chainLoading}
              blockchainUp={blockchainUp}
            />
          ))}
        </div>
      </div>

      {/* ── Summary Footer ──────────────────────────────── */}
      <div className="mt-10 card text-center">
        <p className="text-sm text-stone-500">
          This batch has{" "}
          <strong className="text-stone-900">{allNodes.length}</strong> node(s)
          in its lineage tree, tracing from the original harvest to retail.
        </p>
        <p className="mt-2 text-xs text-stone-400">
          All records are cryptographically anchored on the Polygon blockchain.
        </p>
      </div>
    </div>
  );
}
