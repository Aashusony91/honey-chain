import Link from "next/link";
import { ArrowRight, Hexagon, ShieldCheck, Leaf, Activity, QrCode } from "lucide-react";

export default function HomePage() {
  return (
    <div className="relative min-h-screen overflow-hidden bg-stone-50 selection:bg-amber-200">
      
      {/* ── Beautiful Background Gradients & Patterns ── */}
      <div className="absolute top-0 -left-1/4 w-[150%] h-[800px] bg-gradient-to-b from-amber-100/50 via-amber-50/20 to-transparent -rotate-6 transform-gpu pointer-events-none" />
      <div className="absolute -top-40 -right-40 w-96 h-96 rounded-full bg-amber-400/20 blur-[100px] pointer-events-none" />
      <div className="absolute top-40 -left-20 w-72 h-72 rounded-full bg-emerald-400/10 blur-[80px] pointer-events-none" />

      {/* ── Navigation Bar (Glassmorphic) ── */}
      <nav className="fixed top-0 w-full z-50 bg-white/60 backdrop-blur-md border-b border-white/20 shadow-sm">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-2">
            <Hexagon className="h-8 w-8 text-amber-500 fill-amber-500/20" strokeWidth={1.5} />
            <span className="text-xl font-bold tracking-tight text-stone-900">
              Honey<span className="text-amber-500">Chain</span>
            </span>
          </div>
          <div className="flex items-center gap-4">
            <Link href="/harvest" className="text-sm font-medium text-stone-600 hover:text-amber-600 transition-colors">
              Farmer Portal
            </Link>
            <Link href="/trace" className="btn-primary !px-5 !py-2 !rounded-full !text-sm shadow-amber-500/20 hover:shadow-amber-500/40">
              Trace Honey
            </Link>
          </div>
        </div>
      </nav>

      <main className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 mx-auto max-w-6xl px-6">
        
        {/* ── Hero Section ── */}
        <div className="text-center max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-amber-100/50 border border-amber-200/50 text-amber-800 text-sm font-medium mb-8 animate-fade-in-up">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-amber-500"></span>
            </span>
            SIH 2025 • Problem Statement 26021
          </div>
          
          <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight text-stone-900 mb-6 leading-[1.1]">
            Pure Honey. <br className="md:hidden" />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-amber-500 to-orange-500">
              Proven on the Blockchain.
            </span>
          </h1>
          
          <p className="text-lg md:text-xl text-stone-600 mb-10 max-w-2xl mx-auto leading-relaxed">
            Experience the future of agricultural traceability. From the apiary to your breakfast table, every drop is verified by AI and cryptographically secured.
          </p>
          
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link href="/trace" className="w-full sm:w-auto btn-primary !px-8 !py-4 !rounded-full text-base group">
              <QrCode className="w-5 h-5 mr-2 opacity-80" />
              Trace a Batch
              <ArrowRight className="w-4 h-4 ml-2 opacity-70 group-hover:translate-x-1 transition-transform" />
            </Link>
            <Link href="/login" className="w-full sm:w-auto btn-secondary !px-8 !py-4 !rounded-full text-base bg-white/80 backdrop-blur hover:bg-white">
              <Leaf className="w-5 h-5 mr-2 text-emerald-600" />
              Farmer Login
            </Link>
          </div>
        </div>

        {/* ── Glassmorphic Feature Cards ── */}
        <div className="grid md:grid-cols-3 gap-6 mt-32">
          {[
            {
              icon: <Activity className="w-8 h-8 text-rose-500" />,
              title: "AI Fraud Detection",
              desc: "IoT telemetry and AI analyze hive yields to prevent sugar syrup adulteration before it enters the supply chain.",
              bg: "bg-rose-50/50",
              border: "border-rose-100"
            },
            {
              icon: <ShieldCheck className="w-8 h-8 text-emerald-500" />,
              title: "Immutable Ledger",
              desc: "Every lab test and harvest log is anchored to the Polygon network using unalterable SHA-256 cryptography.",
              bg: "bg-emerald-50/50",
              border: "border-emerald-100"
            },
            {
              icon: <Hexagon className="w-8 h-8 text-amber-500" />,
              title: "Farm to Spoon",
              desc: "Consumers simply scan a QR code to see the exact origin flora, farmer details, and verified lab certificates.",
              bg: "bg-amber-50/50",
              border: "border-amber-100"
            }
          ].map((feature, idx) => (
            <div 
              key={idx} 
              className={`p-8 rounded-3xl backdrop-blur-xl bg-white/60 border ${feature.border} shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:-translate-y-1 hover:shadow-[0_8px_30px_rgb(245,158,11,0.1)] transition-all duration-300`}
            >
              <div className={`w-16 h-16 rounded-2xl ${feature.bg} flex items-center justify-center mb-6`}>
                {feature.icon}
              </div>
              <h3 className="text-xl font-bold text-stone-900 mb-3">{feature.title}</h3>
              <p className="text-stone-600 leading-relaxed">{feature.desc}</p>
            </div>
          ))}
        </div>

      </main>
    </div>
  );
}
