"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { login, getCurrentUser } from "@/lib/auth";
import { Lock, User, ArrowRight } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const [farmerId, setFarmerId] = useState("");
  const [pin, setPin] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // Redirect if already logged in
  useEffect(() => {
    if (getCurrentUser()) {
      router.push("/dashboard");
    }
  }, [router]);

  function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    setTimeout(() => {
      try {
        login(farmerId, pin);
        router.push("/dashboard");
      } catch (err: any) {
        setError(err.message);
        setLoading(false);
      }
    }, 800); // Simulate network delay
  }

  return (
    <div className="relative min-h-[80vh] flex items-center justify-center overflow-hidden bg-stone-50">
      {/* Background elements */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-amber-400/20 blur-[120px] rounded-full pointer-events-none" />
      
      <div className="relative z-10 w-full max-w-md p-8 rounded-3xl backdrop-blur-xl bg-white/70 border border-white/40 shadow-2xl shadow-amber-900/5">
        <div className="text-center mb-8">
          <div className="mx-auto w-16 h-16 bg-amber-100 rounded-2xl flex items-center justify-center mb-4 text-3xl shadow-inner border border-amber-200">
            🐝
          </div>
          <h1 className="text-2xl font-bold text-stone-900">Farmer Login</h1>
          <p className="text-stone-500 text-sm mt-2">Secure access to HoneyChain network.</p>
        </div>

        <form onSubmit={handleLogin} className="space-y-5">
          {error && (
            <div className="p-3 text-sm text-red-700 bg-red-50 border border-red-200 rounded-xl">
              {error}
            </div>
          )}

          <div>
            <label className="block text-sm font-semibold text-stone-700 mb-1.5 ml-1">Farmer ID</label>
            <div className="relative">
              <User className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-stone-400" />
              <input
                type="text"
                required
                value={farmerId}
                onChange={(e) => setFarmerId(e.target.value)}
                placeholder="e.g. FARMER-MH-042"
                className="w-full pl-11 pr-4 py-3 bg-white border-2 border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-amber-400 focus:ring-4 focus:ring-amber-400/10 transition-all uppercase"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-stone-700 mb-1.5 ml-1">Security PIN</label>
            <div className="relative">
              <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 w-5 h-5 text-stone-400" />
              <input
                type="password"
                required
                value={pin}
                onChange={(e) => setPin(e.target.value)}
                placeholder="Enter your 4-digit PIN"
                className="w-full pl-11 pr-4 py-3 bg-white border-2 border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-amber-400 focus:ring-4 focus:ring-amber-400/10 transition-all"
              />
            </div>
            <p className="text-xs text-stone-400 ml-1 mt-2">Hint: For demo purposes, use PIN <strong>1234</strong></p>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full btn-primary !py-3.5 !rounded-xl group flex items-center justify-center text-base"
          >
            {loading ? "Authenticating..." : "Login to Dashboard"}
            {!loading && <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />}
          </button>
        </form>
      </div>
    </div>
  );
}
