# How the HoneyChain "App" Works (Technical Breakdown)

This document explains the code already running in your project that makes the website function like a native mobile app for farmers.

---

### 1. Offline Storage (How it works without internet)
When a farmer is in the field with no internet, they click "Save Offline". We use the browser's native `localStorage` to save the data directly onto the phone's memory.

**Where it is in your code (`frontend_ui/src/lib/offlineStore.ts`):**
```typescript
// This function saves the harvest to the phone's local memory
export function saveHarvest(entry: Omit<HarvestEntry, "id" | "synced">) {
  // 1. Get existing saved data from the phone's browser storage
  const existing = localStorage.getItem("hc_harvests");
  const harvests = existing ? JSON.parse(existing) : [];

  // 2. Add the new harvest and mark it as NOT synced yet
  const newEntry: HarvestEntry = {
    ...entry,
    id: crypto.randomUUID(),
    synced: false, 
  };

  harvests.push(newEntry);
  
  // 3. Save it back into the phone's memory
  localStorage.setItem("hc_harvests", JSON.stringify(harvests));
}
```
**What to tell judges:** *"We use HTML5 `localStorage` as an offline database. Data is cached locally on the device until the background sync detects an internet connection."*

---

### 2. GPS Location (How it grabs coordinates from the phone)
Instead of typing their location, the farmer clicks "📍 Detect". We use the browser's `navigator.geolocation` API, which hooks directly into the smartphone's GPS chip.

**Where it is in your code (`frontend_ui/src/app/harvest/page.tsx`):**
```typescript
function detectGps() {
  setGpsLoading(true);
  
  // Connects to the smartphone's native GPS API
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      // Success: Grab the Latitude and Longitude
      const lat = pos.coords.latitude.toFixed(6);
      const lon = pos.coords.longitude.toFixed(6);
      setGpsCoords(`${lat},${lon}`);
      setGpsLoading(false);
    },
    (err) => {
      // Error handling if GPS is off
      alert("GPS Error: " + err.message);
      setGpsLoading(false);
    }
  );
}
```
**What to tell judges:** *"We use the standard Web Geolocation API. When the user taps 'Detect', the browser requests permission to access the phone's hardware GPS chip to get highly accurate coordinates."*

---

### 3. Mobile Responsiveness (How it fits on small screens)
Your app uses **Tailwind CSS**. Notice how your CSS class names often have prefixes like `md:` or `sm:`? This means "Mobile First". The layout stacks vertically on a phone, but expands to a grid on a laptop.

**Where it is in your code (Example from the Homepage):**
```html
<!-- flex-col makes it stack vertically on mobile -->
<!-- md:flex-row makes it sit side-by-side on laptops -->
<div className="flex flex-col md:flex-row items-center gap-4">
  
  <!-- Buttons take up full width (w-full) on mobile so they are easy to tap -->
  <!-- sm:w-auto makes them normal sized on bigger screens -->
  <Link href="/trace" className="w-full sm:w-auto btn-primary">
    Trace a Batch
  </Link>
  
</div>
```
**What to tell judges:** *"Our frontend is built with Next.js and Tailwind CSS using a mobile-first approach. Flexbox and CSS Grid automatically restructure the UI elements so they are thumb-friendly on touch screens and utilize the full width of the mobile device."*
