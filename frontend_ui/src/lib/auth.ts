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

  const idUpper = farmerId.toUpperCase();
  
  // Create a dynamic name based on the ID length/characters for the demo
  const names = ["Shivam Singh", "Rakesh Anand", "Sachine Thakur"];
  const nameIndex = idUpper.length % names.length;
  
  // Dynamic region based on ID prefix
  let region = "Maharashtra, India";
  if (idUpper.includes("-GJ-")) region = "Gujarat, India";
  if (idUpper.includes("-KA-")) region = "Karnataka, India";
  if (idUpper.includes("-UP-")) region = "Uttar Pradesh, India";

  const session: UserSession = {
    farmerId: idUpper,
    name: names[nameIndex],
    region: region,
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
