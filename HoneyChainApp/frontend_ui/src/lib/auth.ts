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

export function login(farmerId: string, pin: string): UserSession {
  // In a real app, this calls the backend. For the hackathon, we mock the login.
  if (pin !== "1234") {
    throw new Error("Invalid PIN. Use '1234' for demo.");
  }

  const session: UserSession = {
    farmerId: farmerId.toUpperCase(),
    name: "Rajesh Kumar", // Mock name
    region: "Maharashtra, India",
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
