// share_invites/{collabId}_{targetUid}: the offer to join a shared recipe,
// book, plan or list. The owner writes it (with the target's inbox item, in
// one batch); only the target may move it, and only its status.
import { firestore } from "../../../lib/cloud";
import { fsCode, inviteIdFor, kindFrom, roleFrom, tsMs, type CollabRole, type InviteStatus, type ShareInvite } from "./types";

export function inviteFrom(id: string, data: Record<string, unknown>): ShareInvite {
  const status = data.status === "accepted" || data.status === "declined" ? data.status : "pending";
  return {
    id,
    collabId: typeof data.collabId === "string" ? data.collabId : "",
    recipeTitle: typeof data.recipeTitle === "string" ? data.recipeTitle : "",
    ownerUid: typeof data.ownerUid === "string" ? data.ownerUid : "",
    targetUid: typeof data.targetUid === "string" ? data.targetUid : "",
    role: roleFrom(data.role) ?? "viewer",
    status,
    createdAtMs: tsMs(data.createdAt) ?? Date.now(),
    kind: kindFrom(data.kind),
    via: typeof data.via === "string" ? data.via : null,
  };
}

/**
 * The invite with this id, or null when there is none. The rules answer a
 * read of a missing invite with "permission denied" on older deploys, which
 * for a deterministic id means the same as "not written yet"
 * (RecipeSharingFirestoreDataSource.readInvite).
 */
export async function readInvite(id: string): Promise<ShareInvite | null> {
  const { fs, db } = await firestore();
  try {
    const snap = await fs.getDoc(fs.doc(db, "share_invites", id));
    return snap.exists() ? inviteFrom(snap.id, snap.data()) : null;
  } catch (e) {
    if (fsCode(e) === "permission-denied") return null;
    throw e;
  }
}

/**
 * An answered invite whose target is no longer on the roster of the
 * document it was for (inviteIsDead). Pending invites are never dead.
 */
export async function inviteIsDead(invite: ShareInvite, collection: "collab_recipes" | "collab_containers"): Promise<boolean> {
  if (invite.status === "pending") return false;
  if (!invite.targetUid) return true;
  const { fs, db } = await firestore();
  const snap = await fs.getDoc(fs.doc(db, collection, invite.collabId));
  const memberUids = (snap.exists() ? snap.get("memberUids") : null) as unknown;
  return !(Array.isArray(memberUids) && memberUids.includes(invite.targetUid));
}

/** Pending invites to this account, newest first; recipe invites that came with a container are answered with it. */
export async function incomingInvites(uid: string): Promise<ShareInvite[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(
    fs.query(fs.collection(db, "share_invites"), fs.where("targetUid", "==", uid), fs.where("status", "==", "pending")),
  );
  return snap.docs
    .map((d) => inviteFrom(d.id, d.data()))
    .filter((i) => i.via === null)
    .sort((a, b) => b.createdAtMs - a.createdAtMs);
}

export async function setInviteStatus(id: string, status: Exclude<InviteStatus, "pending">): Promise<void> {
  const { fs, db } = await firestore();
  await fs.updateDoc(fs.doc(db, "share_invites", id), { status, respondedAt: fs.serverTimestamp() });
}

/** The fields an invite document carries (inviteFields in both datasources and the shareCodes function). */
export function inviteFields(
  fs: Awaited<ReturnType<typeof firestore>>["fs"],
  f: { collabId: string; title: string; ownerUid: string; targetUid: string; role: CollabRole; kind: string | null; via?: string | null },
): Record<string, unknown> {
  return {
    collabId: f.collabId,
    recipeTitle: f.title,
    ownerUid: f.ownerUid,
    targetUid: f.targetUid,
    role: f.role,
    status: "pending",
    // A recipe invite from the recipe flow carries no kind (older invites
    // are recipes); the container flow names its kind.
    ...(f.kind ? { kind: f.kind } : {}),
    ...(f.via ? { via: f.via } : {}),
    createdAt: fs.Timestamp.now(),
  };
}

export { inviteIdFor };
