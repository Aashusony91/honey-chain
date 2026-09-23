import Link from "next/link";

export default function HomePage() {
  return (
    <div className="mx-auto max-w-6xl px-4 py-16">
      {/* ── Hero ──────────────────────────────────────── */}
      <section className="text-center">
        <div className="mb-6 text-6xl">🍯</div>
        <h1 className="text-4xl font-extrabold tracking-tight text-stone-900 sm:text-5xl">
          From <span className="text-honey-500">Hive</span> to{" "}
          <span className="text-honey-500">Shelf</span>,{" "}
          <br className="hidden sm:block" />
          Verified on <span className="text-honey-500">Blockchain</span>
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-lg text-stone-500">
          HoneyChain uses AI-powered IoT fraud detection and Polygon blockchain
          anchoring to guarantee every jar of honey is 100% authentic — from
          the beekeeper&apos;s apiary to your kitchen table.
        </p>
        <div className="mt-8 flex flex-wrap items-center justify-center gap-4">
          <Link href="/harvest" className="btn-primary text-base !px-8 !py-4">
            🐝 Log a Harvest
          </Link>
          <Link href="/trace" className="btn-secondary text-base !px-8 !py-4">
            🔍 Trace a Batch
          </Link>
        </div>
      </section>

      {/* ── Features ──────────────────────────────────── */}
      <section className="mt-24 grid gap-8 sm:grid-cols-3">
        {[
          {
            icon: "📡",
            title: "IoT Fraud Detection",
            desc: "Real-time hive telemetry catches impossible yields, dead hives, and adulteration before they enter the supply chain.",
          },
          {
            icon: "⛓️",
            title: "Blockchain Anchored",
            desc: "Every batch is minted on Polygon with an immutable transaction hash. Lab certs are pinned to IPFS.",
          },
          {
            icon: "📱",
            title: "Offline-First PWA",
            desc: "Beekeepers in remote areas log harvests offline. Data syncs automatically when connectivity returns.",
          },
        ].map((f) => (
          <div key={f.title} className="card text-center">
            <div className="mb-3 text-4xl">{f.icon}</div>
            <h3 className="text-lg font-bold text-stone-900">{f.title}</h3>
            <p className="mt-2 text-sm text-stone-500">{f.desc}</p>
          </div>
        ))}
      </section>

      {/* ── How It Works ──────────────────────────────── */}
      <section className="mt-24">
        <h2 className="text-center text-2xl font-bold text-stone-900">
          How It Works
        </h2>
        <div className="mt-10 grid gap-6 sm:grid-cols-4">
          {[
            { step: "1", label: "Harvest Logged", detail: "Beekeeper logs weight, flora, hive count via mobile app." },
            { step: "2", label: "IoT + Lab Verified", detail: "Sensor data + lab metrics checked by AI fraud engine." },
            { step: "3", label: "Anchored On-Chain", detail: "Verified batch minted on Polygon with IPFS lab cert." },
            { step: "4", label: "Consumer Scans QR", detail: "Retail jar QR code traces full lineage back to the hive." },
          ].map((s) => (
            <div key={s.step} className="text-center">
              <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-honey-100 text-lg font-bold text-honey-700">
                {s.step}
              </div>
              <h4 className="mt-3 font-semibold text-stone-900">{s.label}</h4>
              <p className="mt-1 text-xs text-stone-500">{s.detail}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
