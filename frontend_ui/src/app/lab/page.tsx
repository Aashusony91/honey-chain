"use client";

import { useState } from "react";
import { submitLabResults } from "@/lib/api";

export default function LabPage() {
  // Login State
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [labId, setLabId] = useState("");
  const [pin, setPin] = useState("");
  const [loginError, setLoginError] = useState("");

  // Dashboard State
  const [batchId, setBatchId] = useState("");
  const [hmf, setHmf] = useState("");
  const [moisture, setMoisture] = useState("");
  const [sucrose, setSucrose] = useState("");
  const [adulteration, setAdulteration] = useState(false);
  const [certId, setCertId] = useState("");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (labId.trim().toUpperCase() === "LAB-101" && pin === "4321") {
      setIsLoggedIn(true);
      setLoginError("");
    } else {
      setLoginError("Invalid Lab ID or PIN. Please try again.");
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setStatus("Submitting...");
    try {
      await submitLabResults(batchId, {
        hmf_content_mg_kg: parseFloat(hmf),
        moisture_percentage: parseFloat(moisture),
        sucrose_percentage: parseFloat(sucrose),
        c3_c4_sugar_adulteration: adulteration,
        lab_cert_id: certId || "LAB-" + Math.floor(Math.random() * 10000)
      } as any);
      setStatus("✅ Lab results successfully attached to batch!");
      setBatchId(""); setHmf(""); setMoisture(""); setSucrose(""); setAdulteration(false); setCertId("");
    } catch (err: any) {
      setStatus("❌ Error: " + err.message);
    }
    setLoading(false);
  };

  if (!isLoggedIn) {
    return (
      <main className="min-h-screen bg-stone-50 flex items-center justify-center p-6 font-sans text-stone-900">
        <div className="w-full max-w-md bg-white p-8 rounded-2xl shadow-sm border border-stone-200">
          <div className="text-center mb-8">
            <h1 className="text-2xl font-bold">🔬 Lab Authentication</h1>
            <p className="text-sm text-stone-500 mt-2">Sign in to access the testing portal</p>
          </div>
          
          <form onSubmit={handleLogin} className="space-y-5">
            {loginError && (
              <div className="p-3 text-sm text-red-700 bg-red-50 border border-red-200 rounded-xl">
                {loginError}
              </div>
            )}
            <div>
              <label className="block text-sm font-semibold text-stone-700 mb-1.5 ml-1">Lab Assistant ID</label>
              <input
                type="text"
                required
                value={labId}
                onChange={e => setLabId(e.target.value)}
                placeholder="e.g. LAB-101"
                className="w-full px-4 py-3 bg-white border-2 border-stone-200 rounded-xl uppercase"
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-stone-700 mb-1.5 ml-1">Security PIN</label>
              <input
                type="password"
                required
                value={pin}
                onChange={e => setPin(e.target.value)}
                placeholder="Enter 4-digit PIN"
                className="w-full px-4 py-3 bg-white border-2 border-stone-200 rounded-xl"
              />
              <p className="text-xs text-stone-400 ml-1 mt-2">Hint: Use ID <strong>LAB-101</strong> and PIN <strong>4321</strong></p>
            </div>
            <button type="submit" className="w-full bg-honey-600 text-white font-bold py-3.5 rounded-xl hover:bg-honey-700 transition-colors">
              Access Dashboard
            </button>
          </form>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-stone-50 p-6 pt-24 font-sans text-stone-900">
      <div className="mx-auto max-w-lg">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-2xl font-bold">🔬 Certified Lab Portal</h1>
          <button onClick={() => setIsLoggedIn(false)} className="text-sm text-stone-500 hover:text-stone-700">Logout</button>
        </div>
        
        <form onSubmit={handleSubmit} className="bg-white p-6 rounded-xl shadow-sm border border-stone-200 space-y-4">
          <div>
            <label className="block text-sm font-semibold mb-1">Batch ID (or Report ID)</label>
            <input type="text" required value={batchId} onChange={e => setBatchId(e.target.value)} className="w-full p-2 border rounded bg-stone-50" placeholder="e.g. HC-ABCD123" />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold mb-1">HMF Content (mg/kg)</label>
              <input type="number" step="0.1" required value={hmf} onChange={e => setHmf(e.target.value)} className="w-full p-2 border rounded bg-stone-50" placeholder="e.g. 16.8" />
            </div>
            <div>
              <label className="block text-sm font-semibold mb-1">Moisture (%)</label>
              <input type="number" step="0.1" required value={moisture} onChange={e => setMoisture(e.target.value)} className="w-full p-2 border rounded bg-stone-50" placeholder="e.g. 17.5" />
            </div>
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold mb-1">Sucrose (%)</label>
              <input type="number" step="0.1" required value={sucrose} onChange={e => setSucrose(e.target.value)} className="w-full p-2 border rounded bg-stone-50" placeholder="e.g. 3.2" />
            </div>
            <div>
              <label className="block text-sm font-semibold mb-1">Certificate ID</label>
              <input type="text" value={certId} onChange={e => setCertId(e.target.value)} className="w-full p-2 border rounded bg-stone-50" placeholder="Auto-generated if empty" />
            </div>
          </div>
          
          <div className="flex items-center gap-2 mt-2">
            <input type="checkbox" id="adulteration" checked={adulteration} onChange={e => setAdulteration(e.target.checked)} className="w-4 h-4" />
            <label htmlFor="adulteration" className="text-sm font-semibold text-red-700">Flag: C3/C4 Sugar Adulteration Detected</label>
          </div>
          
          <button type="submit" disabled={loading} className="w-full bg-honey-600 text-white font-bold py-3 rounded-lg hover:bg-honey-700 mt-4 disabled:opacity-50">
            {loading ? "Submitting..." : "Submit Lab Results"}
          </button>
          
          {status && <div className="mt-4 p-3 rounded bg-stone-100 text-sm font-semibold">{status}</div>}
        </form>
      </div>
    </main>
  );
}
