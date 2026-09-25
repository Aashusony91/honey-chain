/**
 * lib/auth.ts — Simple client-side auth for Hackathon purposes
 * Stores the logged-in farmer session in localStorage.
 */

export interface UserSession {
  farmerId: string;
  name: string;
  region: string;
  loginTime: number;
}

const AUTH_KEY = "honeychain_farmer_session";

const GOV_DATABASE: Record<string, { name: string; region: string }> = {
  "FARMER-MH-1001": { name: "Shivam Singh", region: "Maharashtra, India" },
  "FARMER-UP-2002": { name: "Rakesh Anand", region: "Uttar Pradesh, India" },
  "FARMER-GJ-3003": { name: "Sachine Thakur", region: "Gujarat, India" },
  "FARMER-KA-4004": { name: "Tridas Khanna", region: "Karnataka, India" },
  "FARMER-PB-5005": { name: "Aashish", region: "Punjab, India" },
  "FARMER-RJ-6006": { name: "Mithi", region: "Rajasthan, India" }
};

export function login(farmerId: string, pin: string): UserSession {
  // In a real app, this calls the backend. For the hackathon, we mock the login.
  if (pin !== "1234") {
    throw new Error("Invalid PIN. Use '1234' for demo.");
  }

  const idUpper = farmerId.toUpperCase().trim();

  // 1. Check if ID exists in our "Government Database"
  const farmerData = GOV_DATABASE[idUpper];
  
  if (!farmerData) {
    throw new Error("ID Not Found: This Farmer ID is not registered in the Government Database.");
  }

  const session: UserSession = {
    farmerId: idUpper,
    name: farmerData.name,
    region: farmerData.region,
    loginTime: Date.now(),
  };

  localStorage.setItem(AUTH_KEY, JSON.stringify(session));
  return session;
}

export function logout(): void {
  localStorage.removeItem(AUTH_KEY);
}

export function getCurrentUser(): UserSession | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}
