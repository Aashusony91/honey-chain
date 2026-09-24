import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "HoneyChain — Transparent Honey Supply Chain",
  description:
    "SIH PS 26021: Blockchain-backed honey traceability from hive to retail shelf.",
  manifest: "/manifest.json",
};

export const viewport: Viewport = {
  themeColor: "#f59e0b",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="min-h-screen font-sans">
        {/* ── Navbar ────────────────────────────────────── */}
        <nav className="sticky top-0 z-50 border-b border-stone-200 bg-white/80 backdrop-blur-lg">
          <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-3">
            <a href="/" className="flex items-center gap-2">
              <span className="text-2xl">🍯</span>
              <span className="text-lg font-bold text-stone-900">
                Honey<span className="text-honey-500">Chain</span>
              </span>
            </a>
            <div className="flex items-center gap-3">
              <a href="/dashboard" className="btn-secondary text-xs !px-4 !py-2">
                👨‍🌾 Dashboard
              </a>
              <a href="/trace" className="btn-primary text-xs !px-4 !py-2">
                🔍 Trace Batch
              </a>
            </div>
          </div>
        </nav>

        {/* ── Main Content ──────────────────────────────── */}
        <main>{children}</main>

        {/* ── Footer ────────────────────────────────────── */}
        <footer className="mt-20 border-t border-stone-200 bg-white py-8">
          <div className="mx-auto max-w-6xl px-4 text-center text-sm text-stone-500">
            <p>
              🍯 <strong>HoneyChain</strong> — SIH 2025 PS 26021 &middot;
              Blockchain-Backed Honey Supply Chain Traceability
            </p>
            <p className="mt-1 text-xs text-stone-400">
              Built with Next.js &middot; Tailwind CSS &middot; Polygon
              Blockchain
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}
