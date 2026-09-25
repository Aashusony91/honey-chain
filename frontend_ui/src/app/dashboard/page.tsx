"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { getCurrentUser, logout, type UserSession } from "@/lib/auth";
import { getStoredHarvests, getPendingHarvests, type HarvestEntry } from "@/lib/offlineStore";
import { LogOut, Plus, Droplets, MapPin, CheckCircle, Clock } from "lucide-react";

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<UserSession | null>(null);
  const [harvests, setHarvests] = useState<HarvestEntry[]>([]);

  useEffect(() => {
    const session = getCurrentUser();
    if (!session) {
      router.push("/login");
    } else {
      setUser(session);
      // Filter harvests so they only see their own data
      const allHarvests = getStoredHarvests();
      setHarvests(allHarvests.filter(h => h.farmer_id === session.farmerId));
    }
  }, [router]);

  if (!user) return null; // Prevents flash before redirect

  const totalKg = harvests.reduce((acc, h) => acc + h.harvest_weight_kg, 0);
  const syncedCount = harvests.filter((h) => h.synced).length;
  const pendingCount = getPendingHarvests().length;

  function handleLogout() {
    logout();
    router.push("/");
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-8">
      
      {/* ── Dashboard Header ── */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-10 border-b border-stone-200 pb-6">
        <div>
          <h1 className="text-3xl font-bold text-stone-900 tracking-tight flex items-center gap-3">
            Welcome back, <span className="text-amber-600">{user.name}</span>
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200 text-sm font-medium text-emerald-700 mt-1 md:mt-0">
              <CheckCircle className="w-4 h-4" />
              Gov Registry Verified
            </span>
          </h1>
          <p className="text-stone-500 mt-2 flex items-center gap-2">
            <MapPin className="w-4 h-4" /> {user.region} &nbsp;|&nbsp; ID: <strong className="font-mono">{user.farmerId}</strong>
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link href="/harvest" className="btn-primary !px-5 !py-2.5 !rounded-xl shadow-amber-500/20">
            <Plus className="w-4 h-4 mr-1.5" /> Log New Harvest
          </Link>
          <button onClick={handleLogout} className="btn-secondary !px-4 !py-2.5 !rounded-xl text-stone-500 hover:text-red-600 hover:border-red-200 hover:bg-red-50">
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* ── Stats Grid ── */}
      <div className="grid sm:grid-cols-3 gap-6 mb-12">
        <div className="p-6 rounded-3xl bg-amber-50 border border-amber-100 shadow-sm flex items-start gap-4">
          <div className="p-3 bg-amber-200/50 rounded-2xl text-amber-700"><Droplets className="w-6 h-6" /></div>
          <div>
            <p className="text-sm font-medium text-amber-800">Total Yield</p>
            <p className="text-3xl font-bold text-amber-900 mt-1">{totalKg.toFixed(1)} <span className="text-lg font-normal opacity-70">kg</span></p>
          </div>
        </div>

        <div className="p-6 rounded-3xl bg-emerald-50 border border-emerald-100 shadow-sm flex items-start gap-4">
          <div className="p-3 bg-emerald-200/50 rounded-2xl text-emerald-700"><CheckCircle className="w-6 h-6" /></div>
          <div>
            <p className="text-sm font-medium text-emerald-800">Verified Batches</p>
            <p className="text-3xl font-bold text-emerald-900 mt-1">{syncedCount}</p>
          </div>
        </div>

        <div className="p-6 rounded-3xl bg-stone-50 border border-stone-200 shadow-sm flex items-start gap-4">
          <div className="p-3 bg-stone-200/50 rounded-2xl text-stone-600"><Clock className="w-6 h-6" /></div>
          <div>
            <p className="text-sm font-medium text-stone-700">Pending Sync</p>
            <p className="text-3xl font-bold text-stone-900 mt-1">{pendingCount}</p>
          </div>
        </div>
      </div>

      {/* ── Recent Activity ── */}
      <div>
        <h2 className="text-xl font-bold text-stone-900 mb-6">Recent Harvest History</h2>
        
        {harvests.length === 0 ? (
          <div className="text-center py-16 bg-stone-50 border border-dashed border-stone-300 rounded-3xl">
            <div className="text-4xl mb-3">🌱</div>
            <h3 className="text-lg font-semibold text-stone-700">No harvests yet</h3>
            <p className="text-stone-500 mt-1 max-w-sm mx-auto">Start logging your honey production to build your blockchain history.</p>
            <Link href="/harvest" className="btn-secondary mt-6">Log First Harvest</Link>
          </div>
        ) : (
          <div className="bg-white border border-stone-200 rounded-3xl overflow-hidden shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-stone-50 border-b border-stone-200 text-stone-500">
                  <tr>
                    <th className="px-6 py-4 font-medium">Batch ID</th>
                    <th className="px-6 py-4 font-medium">Date</th>
                    <th className="px-6 py-4 font-medium">Flora Source</th>
                    <th className="px-6 py-4 font-medium">Weight</th>
                    <th className="px-6 py-4 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-stone-100">
                  {[...harvests].reverse().map((h) => (
                    <tr key={h.id} className="hover:bg-stone-50/50 transition-colors">
                      <td className="px-6 py-4 font-mono font-medium text-amber-700">{h.batch_id}</td>
                      <td className="px-6 py-4 text-stone-600">{new Date(h.harvest_timestamp * 1000).toLocaleDateString()}</td>
                      <td className="px-6 py-4 text-stone-900">{h.flora_source}</td>
                      <td className="px-6 py-4 font-medium text-stone-900">{h.harvest_weight_kg} kg</td>
                      <td className="px-6 py-4">
                        <span className={h.synced ? "badge-verified" : "badge-pending"}>
                          {h.synced ? "✅ Verified" : "⏳ Pending"}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

    </div>
  );
}
