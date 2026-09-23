/**
 * lib/offlineStore.ts — Offline-First Local Storage for Harvest Submissions
 * ==========================================================================
 * Stores pending harvest submissions in localStorage when offline.
 * Syncs to backend when connectivity returns.
 */

export interface HarvestEntry {
  /** Client-generated unique ID */
  id: string;
  batch_id: string;
  farmer_id: string;
  flora_source: string;
  harvest_weight_kg: number;
  hive_count: number;
  gps_coordinates: string;
  harvest_timestamp: number;
  /** Whether this entry has been synced to the backend */
  synced: boolean;
  /** ISO date string of creation */
  created_at: string;
}

const STORAGE_KEY = "honeychain_pending_harvests";

/** Generate a short unique ID */
export function generateId(): string {
  return `HC-${Date.now().toString(36).toUpperCase()}-${Math.random()
    .toString(36)
    .substring(2, 6)
    .toUpperCase()}`;
}

/** Get all stored entries */
export function getStoredHarvests(): HarvestEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

/** Get only un-synced entries */
export function getPendingHarvests(): HarvestEntry[] {
  return getStoredHarvests().filter((h) => !h.synced);
}

/** Save a new harvest entry (initially unsynced) */
export function saveHarvest(entry: Omit<HarvestEntry, "id" | "synced" | "created_at">): HarvestEntry {
  const newEntry: HarvestEntry = {
    ...entry,
    id: generateId(),
    synced: false,
    created_at: new Date().toISOString(),
  };
  const all = getStoredHarvests();
  all.push(newEntry);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
  return newEntry;
}

/** Mark entries as synced by their IDs */
export function markSynced(ids: string[]): void {
  const all = getStoredHarvests();
  for (const entry of all) {
    if (ids.includes(entry.id)) {
      entry.synced = true;
    }
  }
  localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
}

/** Clear all synced entries (housekeeping) */
export function clearSyncedEntries(): void {
  const pending = getPendingHarvests();
  localStorage.setItem(STORAGE_KEY, JSON.stringify(pending));
}

/** Check if browser is online */
export function isOnline(): boolean {
  if (typeof navigator === "undefined") return true;
  return navigator.onLine;
}
