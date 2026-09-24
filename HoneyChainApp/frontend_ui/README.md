# HoneyChain Frontend UI — Member 5

Offline-first Farmer PWA + Consumer QR Traceability Portal for SIH PS 26021 (Honey Chain).

## Quick Start

```bash
cd frontend_ui
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Pages

| Route | Description |
|-------|-------------|
| `/` | Landing page with hero, features, and how-it-works |
| `/harvest` | **Farmer App** — Offline-first harvest logging form |
| `/trace` | **Consumer Portal** — Enter batch ID or scan QR |
| `/trace/[batchId]` | **Lineage Timeline** — Full hive-to-shelf trace |

## Offline Support

- Harvests are saved to `localStorage` when offline
- A sync status bar shows pending vs synced count
- Clicking **Sync Now** pushes to `POST /api/batch/sync` on the Backend Gateway
- Falls back to mock trace data when backend is unavailable

## Backend Integration

Expects Backend Gateway on `http://localhost:8000`. Override via env:

```
NEXT_PUBLIC_API_URL=http://your-gateway:8000
```
