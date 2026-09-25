"use client";

import { useState } from "react";
import { submitLabResults } from "@/lib/api";

export default function LabPage() {
  const [batchId, setBatchId] = useState("");
  const [hmf, setHmf] = useState("");
  const [moisture, setMoisture] = useState("");
  const [sucrose, setSucrose] = useState("");
  const [adulteration, setAdulteration] = useState(false);
  const [certId, setCertId] = useState("");
  const [status, setStatus] = useState("");
  const [loading, setLoading] = useState(false);

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

  return (
    <main className="min-h-screen bg-stone-50 p-6 pt-24 font-sans text-stone-900">
      <div className="mx-auto max-w-lg">
        <h1 className="text-2xl font-bold mb-6">🔬 Certified Lab Portal</h1>
        
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
