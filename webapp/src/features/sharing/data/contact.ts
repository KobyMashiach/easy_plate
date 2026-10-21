// How one account finds another without anyone's contact details being
// readable: `user_directory/{sha256(contact)}` → { uid }. Byte for byte the
// app's contact_hash.dart — an email trimmed and lower-cased, a phone in
// E.164 (a local Israeli 05… upgraded to +972), sha256 as lowercase hex.
import { firestore } from "../../../lib/cloud";

export interface NormalizedContact {
  value: string;
  isEmail: boolean;
}

export function normalizeContact(raw: string): NormalizedContact | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;
  if (trimmed.includes("@")) {
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(trimmed)) return null;
    return { value: trimmed.toLowerCase(), isEmail: true };
  }
  const digits = trimmed.replace(/[\s\-()]/g, "");
  if (!/^\+?\d{7,15}$/.test(digits)) return null;
  const e164 = digits.startsWith("+") ? digits : digits.startsWith("0") ? `+972${digits.substring(1)}` : `+${digits}`;
  return { value: e164, isEmail: false };
}

export async function contactHash(normalized: string): Promise<string> {
  const bytes = new TextEncoder().encode(normalized);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** The uid behind an email or phone, or null when nobody published it. */
export async function findUidByContact(contact: string): Promise<string | null> {
  const normalized = normalizeContact(contact);
  if (!normalized) return null;
  const hash = await contactHash(normalized.value);
  const { fs, db } = await firestore();
  const snap = await fs.getDoc(fs.doc(db, "user_directory", hash));
  const uid = snap.exists() ? snap.get("uid") : null;
  return typeof uid === "string" ? uid : null;
}

/** Whether any of the sender's own contacts resolve — "they never published" vs "the directory is empty". */
export async function anyResolves(contacts: string[]): Promise<boolean> {
  for (const c of contacts) {
    try {
      if (await findUidByContact(c)) return true;
    } catch (_) {
      /* keep looking */
    }
  }
  return false;
}

/**
 * Publishes this account's own contacts to the directory, as the app does on
 * every profile save (UserProfileFirestoreDataSource: the token's phone in
 * E.164, and its email once verified) — so an account that only ever used
 * the website can still be found by the people sharing with it. Once per
 * session; a refusal (rules not deployed) is not the page's problem.
 */
let published: string | null = null;
export async function publishOwnDirectoryEntries(user: { uid: string; phoneNumber: string | null; email: string | null; emailVerified: boolean }): Promise<void> {
  if (published === user.uid) return;
  published = user.uid;
  const contacts: string[] = [];
  if (user.emailVerified && user.email) {
    const n = normalizeContact(user.email);
    if (n?.isEmail) contacts.push(n.value);
  }
  if (user.phoneNumber && user.phoneNumber.startsWith("+")) contacts.push(user.phoneNumber);
  if (!contacts.length) return;
  // One write per contact: the rules check each hash against the ID token,
  // and a token minted before an email was verified must not also sink the
  // phone entry (one batch would be refused whole).
  let failed = false;
  try {
    const { fs, db } = await firestore();
    for (const c of contacts) {
      try {
        await fs.setDoc(fs.doc(db, "user_directory", await contactHash(c)), { uid: user.uid });
      } catch (_) {
        failed = true;
      }
    }
  } catch (_) {
    failed = true;
  }
  if (failed && published === user.uid) published = null;
}
