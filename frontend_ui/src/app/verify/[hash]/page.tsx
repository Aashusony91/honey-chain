"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { verifyReportHash, type PublicVerificationProof } from "@/lib/api";

export default function PublicVerifyPage() {
  const params = useParams();
  const reportHash = decodeURIComponent(params.hash as string);

  const [proof, setProof]     = useState<PublicVerificationProof | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError]     = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const data = await verifyReportHash(reportHash);
        setProof(data);
      } catch (e) {
        setError("Could not reach the backend. Check your connection.");
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [reportHash]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-32">
        <div className="text-center">
          <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-honey-200 border-t-honey-500" />
          <p className="text-sm text-stone-500">Verifying report hash…</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="mx-auto max-w-lg px-4 py-16 text-center">
        <div className="text-5xl mb-4">⚠️</div>
        <h2 className="text-xl font-bold text-stone-900">Backend Unreachable</h2>
        <p className="mt-2 text-stone-500">{error}</p>
        <p className="mt-1 text-xs text-stone-400">
          Make sure the backend gateway is running on port 8000.
        </p>
      </div>
    );
  }

  if (!proof) return null;

  const isVerified = proof.verified;
  const confidence = proof.verification?.confidence;
  const status     = proof.verification?.status ?? "UNKNOWN";
  const flags      = proof.verification?.flags ?? [];

  return (
    <div className="mx-auto max-w-xl px-4 py-12">
      <div className="mb-4">
        <a href="/" className="text-sm text-honey-600 hover:text-honey-700">
          ← Back to Home
        </a>
      </div>

      {/* ── Verification Badge ──────────────────────────── */}
      <div className={`rounded-2xl border-2 p-8 text-center mb-6 ${
        isVerified
          ? "border-emerald-300 bg-emerald-50"
          : "border-red-300 bg-red-50"
      }`}>
        <div className="text-6xl mb-4">
          {isVerified ? "✅" : "🚫"}
        </div>
        <h1 className={`text-3xl font-extrabold ${isVerified ? "text-emerald-700" : "text-red-700"}`}>
          {isVerified ? "VERIFIED" : "NOT VERIFIED"}
        </h1>
        <p className={`mt-2 text-sm font-medium ${isVerified ? "text-emerald-600" : "text-red-600"}`}>
          {isVerified
            ? "This report's integrity is confirmed. The data has not been tampered with."
            : "This report hash could not be verified. Data may be invalid or tampered."}
        </p>
      </div>

      {/* ── Report Details ──────────────────────────────── */}
      <div className="card space-y-4">
        <h2 className="font-bold text-stone-900">📋 Report Details</h2>

        <div className="space-y-3">
          {/* Hash */}
          <div>
            <p className="text-xs font-medium text-stone-500 mb-1">SHA-256 Report Hash</p>
            <p className="break-all rounded-lg bg-stone-50 border border-stone-200 p-3 font-mono text-xs text-stone-700">
              {reportHash}
            </p>
          </div>

          {/* Status */}
          {proof.verification && (
            <>
              <div className="flex items-center justify-between rounded-lg bg-stone-50 border border-stone-200 px-4 py-3">
                <span className="text-sm text-stone-600">Verification Status</span>
                <span className={`text-sm font-bold ${
                  status === "VERIFIED" ? "text-emerald-600" :
                  status === "FLAGGED_FOR_REVIEW" ? "text-amber-600" :
                  "text-red-600"
                }`}>
                  {status}
                </span>
              </div>

              <div className="flex items-center justify-between rounded-lg bg-stone-50 border border-stone-200 px-4 py-3">
                <span className="text-sm text-stone-600">Confidence Score</span>
                <div className="flex items-center gap-3">
                  <div className="h-2 w-24 rounded-full bg-stone-200">
                    <div
                      className={`h-2 rounded-full ${
                        (confidence ?? 0) >= 0.8 ? "bg-emerald-500" :
                        (confidence ?? 0) >= 0.5 ? "bg-amber-500" : "bg-red-500"
                      }`}
                      style={{ width: `${((confidence ?? 0) * 100).toFixed(0)}%` }}
                    />
                  </div>
                  <span className="text-sm font-bold text-stone-900">
                    {((confidence ?? 0) * 100).toFixed(1)}%
                  </span>
                </div>
              </div>

              {/* Flags */}
              {flags.length > 0 && (
                <div className="rounded-lg bg-red-50 border border-red-200 px-4 py-3">
                  <p className="text-sm font-medium text-red-700 mb-2">⚠️ Anomaly Flags</p>
                  <ul className="space-y-1">
                    {flags.map((f, i) => (
                      <li key={i} className="text-xs text-red-600">• {f}</li>
                    ))}
                  </ul>
                </div>
              )}
            </>
          )}

          {!proof.verification && (
            <div className="rounded-lg bg-stone-50 border border-stone-200 px-4 py-3 text-sm text-stone-500 text-center">
              No verification data found for this hash.
            </div>
          )}
        </div>
      </div>

      {/* ── Info Footer ─────────────────────────────────── */}
      <p className="mt-6 text-center text-xs text-stone-400">
        This verification is powered by HoneyChain — SIH PS 26021.
        Report integrity is checked via SHA-256 cryptographic hashing.
      </p>
    </div>
  );
}
