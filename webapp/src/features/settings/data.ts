// Settings data: the preferences record (live, with the app's optimistic
// "show at once, persist after, put back on refusal" behaviour) and the
// profile documents the app's ProfileSetupPage writes.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { getApps } from "firebase/app";
import { firestore, useRecord, withFirestore } from "../../lib/cloud";
import { auth } from "../../lib/firebase";
import { toJpeg } from "../../lib/storage";
import { normalizePreferences, defaultPreferences, PREFERENCES_ID, updatePreferences, type AppLanguage, type Preferences } from "../../models/preferences";

export interface PreferencesState {
  /** Null while the first snapshot is on its way. */
  prefs: Preferences | null;
  error: Error | null;
  /** Keys whose write is in flight (the control shows busy, not a second tap). */
  busy: Set<string>;
  /** Bumped by every refused save, so the page can say so. */
  failures: number;
  /** Applies `change` to the stored record; `key` names the control. */
  change: (key: string, change: (p: Preferences) => Preferences) => Promise<Preferences | null>;
}

export function usePreferences(uid: string | null | undefined, fallbackLanguage: AppLanguage): PreferencesState {
  const { item, error } = useRecord<unknown>("preferences", uid, PREFERENCES_ID);
  const [overlay, setOverlay] = useState<Preferences | null>(null);
  const [busy, setBusy] = useState<Set<string>>(() => new Set());
  const [failures, setFailures] = useState(0);
  const inFlight = useRef(0);

  const stored = useMemo(() => (item === undefined ? null : item === null ? defaultPreferences(fallbackLanguage) : normalizePreferences(item)), [item, fallbackLanguage]);
  const prefs = overlay ?? stored;
  const latest = useRef(prefs);
  latest.current = prefs;

  const change = useCallback(
    async (key: string, fn: (p: Preferences) => Preferences) => {
      const shown = latest.current;
      if (!shown) return null;
      inFlight.current += 1;
      setOverlay(fn(shown));
      setBusy((b) => new Set(b).add(key));
      try {
        return await updatePreferences(fn, fallbackLanguage);
      } catch (_) {
        setFailures((n) => n + 1);
        return null;
      } finally {
        inFlight.current -= 1;
        // The live record already carries the write (latency compensation);
        // the overlay goes once nothing else is pending.
        if (inFlight.current === 0) setOverlay(null);
        setBusy((b) => {
          const next = new Set(b);
          next.delete(key);
          return next;
        });
      }
    },
    [fallbackLanguage],
  );

  return { prefs, error, busy, failures, change };
}

// ---------------------------------------------------------------------------
// users/{uid}: the private profile. Only the fields the app's saveProfile
// writes; `permission` is never touched (the rules refuse it).

export interface ProfileDoc {
  fullName: string;
  photoUrl: string | null;
  email: string | null;
  /** The stored Timestamp, written back as is. */
  createdAt: unknown;
}

export function useProfileDoc(uid: string | null | undefined): { profile: ProfileDoc | null | undefined; error: Error | null } {
  const [state, setState] = useState<{ profile: ProfileDoc | null | undefined; error: Error | null }>({ profile: undefined, error: null });
  useEffect(() => {
    if (!uid) return;
    setState({ profile: undefined, error: null });
    return withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.doc(db, "users", uid),
          (snap) => {
            if (!snap.exists()) return setState({ profile: null, error: null });
            const d = snap.data() as Record<string, unknown>;
            setState({
              profile: {
                fullName: typeof d.fullName === "string" ? d.fullName : "",
                photoUrl: typeof d.photoUrl === "string" && d.photoUrl ? d.photoUrl : null,
                email: typeof d.email === "string" ? d.email : null,
                createdAt: d.createdAt ?? null,
              },
              error: null,
            });
          },
          (e) => setState({ profile: null, error: e as Error }),
        ),
      (e) => setState({ profile: null, error: e }),
    );
  }, [uid]);
  return state;
}

async function sha256Hex(text: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** profile_photos/{uid}.jpg — a fixed path, so a new photo overwrites the old. Returns the download URL. */
export async function uploadProfilePhoto(uid: string, file: Blob): Promise<string> {
  const jpeg = await toJpeg(file, 1024, 0.85);
  const st = await import("../../lib/firestoreSdk");
  const storage = st.getStorage(getApps()[0]);
  const ref = st.ref(storage, `profile_photos/${uid}.jpg`);
  await st.uploadBytes(ref, jpeg, { contentType: "image/jpeg" });
  return st.getDownloadURL(ref);
}

export interface AuthIdentity {
  uid: string;
  email: string | null;
  emailVerified: boolean;
  phoneNumber: string | null;
}

/**
 * The app's saveProfile: users/{uid} and public_profiles/{uid} merged in one
 * batch, plus the user_directory entries for the token's own phone and its
 * verified email (sha256 of the normalised contact → {uid}).
 */
async function tokenContacts(who: AuthIdentity): Promise<{ email: string | null; emailVerified: boolean; phoneNumber: string | null }> {
  const user = auth().currentUser;
  if (!user || user.uid !== who.uid) return { email: null, emailVerified: false, phoneNumber: null };
  try {
    const { claims } = await user.getIdTokenResult();
    return {
      email: typeof claims.email === "string" ? claims.email : null,
      emailVerified: claims.email_verified === true,
      phoneNumber: typeof claims.phone_number === "string" ? claims.phone_number : null,
    };
  } catch {
    // No token to read: no directory entries rather than a refused save.
    return { email: null, emailVerified: false, phoneNumber: null };
  }
}

export async function saveProfile(who: AuthIdentity, fields: { fullName: string; photoUrl: string | null; createdAt: unknown }): Promise<void> {
  const { fs, db } = await firestore();
  const batch = fs.writeBatch(db);
  batch.set(
    fs.doc(db, "users", who.uid),
    {
      fullName: fields.fullName,
      email: who.email,
      phoneNumber: who.phoneNumber,
      photoUrl: fields.photoUrl,
      createdAt: fields.createdAt instanceof fs.Timestamp ? fields.createdAt : fs.Timestamp.now(),
      updatedAt: fs.serverTimestamp(),
    },
    { merge: true },
  );
  batch.set(fs.doc(db, "public_profiles", who.uid), { fullName: fields.fullName, photoUrl: fields.photoUrl, updatedAt: fs.serverTimestamp() }, { merge: true });
  // The rules hash the ID token's own claims, so the contacts come from the
  // token too: a User object that already says "verified" while the token
  // was minted before the verification would get the whole batch refused —
  // the profile save included.
  const claims = await tokenContacts(who);
  const contacts: string[] = [];
  if (claims.emailVerified && claims.email && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(claims.email.trim())) contacts.push(claims.email.trim().toLowerCase());
  if (claims.phoneNumber && claims.phoneNumber.startsWith("+")) contacts.push(claims.phoneNumber);
  for (const c of contacts) batch.set(fs.doc(db, "user_directory", await sha256Hex(c)), { uid: who.uid });
  await batch.commit();
}
