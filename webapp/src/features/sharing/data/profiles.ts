// Public profiles (`public_profiles/{uid}`: fullName, photoUrl), the way the
// app resolves every author, member and inviter at read time — so a rename
// shows on old posts. Kept for the session: each uid is read once unless a
// pull asks again.
import { useEffect, useMemo, useState } from "react";
import { firestore } from "../../../lib/cloud";
import { auth } from "../../../lib/firebase";

export interface PublicProfile {
  uid: string;
  fullName: string;
  photoUrl: string | null;
}

const cache = new Map<string, PublicProfile | null>();
const inflight = new Map<string, Promise<void>>();
const CHUNK = 30; // `in` takes at most 30 values

export async function getPublicProfiles(uids: Iterable<string>, { refresh = false } = {}): Promise<Map<string, PublicProfile>> {
  const wanted = [...new Set([...uids].filter(Boolean))];
  const missing = wanted.filter((u) => refresh || (!cache.has(u) && !inflight.has(u)));
  if (missing.length) {
    const { fs, db } = await firestore();
    const work: Promise<void>[] = [];
    for (let i = 0; i < missing.length; i += CHUNK) {
      const chunk = missing.slice(i, i + CHUNK);
      const p = fs
        .getDocs(fs.query(fs.collection(db, "public_profiles"), fs.where(fs.documentId(), "in", chunk), fs.limit(CHUNK)))
        .then((snap) => {
          for (const u of chunk) cache.set(u, null);
          for (const d of snap.docs) {
            const data = d.data();
            cache.set(d.id, {
              uid: d.id,
              fullName: typeof data.fullName === "string" ? data.fullName : "",
              photoUrl: typeof data.photoUrl === "string" ? data.photoUrl : null,
            });
          }
        })
        .finally(() => chunk.forEach((u) => inflight.delete(u)));
      chunk.forEach((u) => inflight.set(u, p));
      work.push(p);
    }
    await Promise.all(work);
  }
  // Ones another call is still reading.
  await Promise.all(wanted.map((u) => inflight.get(u)).filter(Boolean));
  const out = new Map<string, PublicProfile>();
  for (const u of wanted) {
    const p = cache.get(u);
    if (p) out.set(u, p);
  }
  return out;
}

/** Profiles for a set of uids, re-read when the set changes. Failures leave the map as it was. */
export function useProfiles(uids: string[]): Map<string, PublicProfile> {
  const key = useMemo(() => [...new Set(uids)].sort().join(","), [uids]);
  const [map, setMap] = useState<Map<string, PublicProfile>>(() => new Map());
  useEffect(() => {
    if (!key) return;
    let live = true;
    getPublicProfiles(key.split(","))
      .then((m) => live && setMap(m))
      .catch(() => {});
    return () => {
      live = false;
    };
  }, [key]);
  return map;
}

/** The signed-in account's name and photo, as the app signs a post with them. */
export async function myAuthor(): Promise<{ uid: string; name: string; photoUrl: string | null }> {
  const user = auth().currentUser;
  if (!user) throw new Error("Not signed in");
  let profile: PublicProfile | undefined;
  try {
    profile = (await getPublicProfiles([user.uid])).get(user.uid);
  } catch (_) {
    profile = undefined;
  }
  return {
    uid: user.uid,
    name: profile?.fullName?.trim() || user.displayName || "",
    photoUrl: profile?.photoUrl ?? user.photoURL ?? null,
  };
}
