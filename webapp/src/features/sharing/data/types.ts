// The sharing vocabulary, as the app names it (lib/core/constants/app_enums.dart):
// enum values travel by their Dart names.

export type CollabRole = "owner" | "editor" | "viewer";
/** What a shared document, an invite or a share code is about. */
export type CollabKind = "recipe" | "book" | "mealPlan" | "groceryList" | "household";
export type ContainerKind = "book" | "mealPlan" | "groceryList";
export type InviteStatus = "pending" | "accepted" | "declined";

export const CONTAINER_KINDS: readonly ContainerKind[] = ["book", "mealPlan", "groceryList"];

/** CollabKind.fromName: an unknown or missing kind is a recipe. */
export function kindFrom(raw: unknown): CollabKind {
  return raw === "book" || raw === "mealPlan" || raw === "groceryList" || raw === "household" ? raw : "recipe";
}

export function roleFrom(raw: unknown): CollabRole | null {
  return raw === "owner" || raw === "editor" || raw === "viewer" ? raw : null;
}

/** An offer to join a shared recipe, book, plan or list (`share_invites/{collabId}_{targetUid}`). */
export interface ShareInvite {
  id: string;
  collabId: string;
  /** The shared item's title (named "recipeTitle" for every kind, as the app stores it). */
  recipeTitle: string;
  ownerUid: string;
  targetUid: string;
  role: CollabRole;
  status: InviteStatus;
  createdAtMs: number;
  kind: CollabKind;
  /** The container a silent recipe invite came with: answered with it, never on its own. */
  via: string | null;
}

/** ShareInviteEntity.idFor */
export function inviteIdFor(collabId: string, targetUid: string): string {
  return `${collabId}_${targetUid}`;
}

/** A Firestore Timestamp (or anything with toMillis) → ms; null otherwise. */
export function tsMs(v: unknown): number | null {
  if (v && typeof (v as { toMillis?: unknown }).toMillis === "function") return (v as { toMillis: () => number }).toMillis();
  if (typeof v === "number") return v;
  if (typeof v === "string") {
    const n = Date.parse(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

/** The Firestore error code of a failed call ("permission-denied", "not-found"…), or "". */
export function fsCode(e: unknown): string {
  return e && typeof (e as { code?: unknown }).code === "string" ? String((e as { code: string }).code) : "";
}

/** Why sharing with a contact could not go ahead (ShareFailure). */
export class ShareFailure extends Error {
  constructor(public readonly reason: "notFound" | "self" | "invalid" | "directoryUnavailable") {
    super(reason);
  }
}

/**
 * Whether an id (from the address bar or from a document someone else wrote)
 * may name one Firestore document: not empty, no "/" (which would reach
 * another path), not "." / ".." or a reserved __name__ (cloud.ts validId).
 */
export function validDocId(id: unknown): id is string {
  return typeof id === "string" && id.length > 0 && id.length <= 1500 && !id.includes("/") && id !== "." && id !== ".." && !/^__.*__$/.test(id);
}

/** The item was deleted (here or on another device) while it was being shared: nothing is written back. */
export class ItemGone extends Error {
  constructor() {
    super("item-gone");
  }
}

/** The owner deleted the shared thing between the invite and the answer. */
export class CollabMissing extends Error {
  constructor() {
    super("collab-missing");
  }
}
