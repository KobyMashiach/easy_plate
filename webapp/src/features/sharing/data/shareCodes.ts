// Share codes: `share_codes/{CODE}` written by the owner (the rules check
// they own what it opens), redeemed through the `shareCodes` function,
// which writes the same invite a contact share would — and this side then
// accepts it, so the copy lands like any other (ShareCodeService).
import { firestore } from "../../../lib/cloud";
import { callFunction } from "../../../lib/functions";
import { ApiError } from "../../../lib/api";
import { acceptRecipeInvite } from "./collabRecipes";
import { acceptContainerInvite } from "./containers";
import { fsCode, inviteIdFor, kindFrom, tsMs, type CollabKind, type CollabRole, type ShareInvite } from "./types";

/** No 0/O or 1/I: a code is read out loud and typed back. */
export const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const CODE_LENGTH = 8;
export const CODE_VALID_MS = 30 * 24 * 60 * 60 * 1000;
export const CODE_HOST = "aieasyplate.app";

export interface ShareCode {
  code: string;
  kind: CollabKind;
  targetId: string;
  ownerUid: string;
  role: CollabRole;
  title: string;
  createdAtMs: number;
  expiresAtMs: number;
  uses: number;
  revoked: boolean;
}

export const codeLink = (code: string) => `https://${CODE_HOST}/s/${code}`;
/** The display form older builds sent; still accepted by parse. */
export const codeDisplay = (code: string) => `EP-${code.slice(0, 4)}-${code.slice(4)}`;

/** A fresh body. One starting with EP is drawn again (it would lose its first two letters to the prefix stripping). */
export function generateCode(): string {
  const bytes = new Uint8Array(CODE_LENGTH);
  for (;;) {
    crypto.getRandomValues(bytes);
    // 256 is a multiple of 32: no modulo bias.
    const code = [...bytes].map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join("");
    if (!code.startsWith("EP")) return code;
  }
}

const BODY = new RegExp(`^[${CODE_ALPHABET}]{${CODE_LENGTH}}$`);
const IN_LINK = new RegExp(`/S/([${CODE_ALPHABET}]{${CODE_LENGTH}})(?![A-Z0-9])`);

/** The body behind whatever was typed, pasted or scanned: a link, EP-XXXX-XXXX, or the letters. */
export function parseCode(raw: string): string | null {
  const upper = raw.trim().toUpperCase();
  const fromLink = IN_LINK.exec(upper)?.[1];
  if (fromLink) return fromLink;
  let letters = upper.replace(/[^A-Z0-9]/g, "");
  if (letters.length === CODE_LENGTH + 2 && letters.startsWith("EP")) letters = letters.substring(2);
  return BODY.test(letters) ? letters : null;
}

function codeFrom(id: string, data: Record<string, unknown>): ShareCode | null {
  const expires = tsMs(data.expiresAt);
  if (expires === null) return null;
  return {
    code: id,
    kind: kindFrom(data.kind),
    targetId: typeof data.targetId === "string" ? data.targetId : "",
    ownerUid: typeof data.ownerUid === "string" ? data.ownerUid : "",
    role: data.role === "editor" ? "editor" : "viewer",
    title: typeof data.title === "string" ? data.title : "",
    createdAtMs: tsMs(data.createdAt) ?? expires,
    expiresAtMs: expires,
    uses: typeof data.uses === "number" ? Math.trunc(data.uses) : 0,
    revoked: data.revoked === true,
  };
}

/**
 * Writes a new code. No read first (the rules let only the owner read a
 * code, so a get on a fresh id is denied); a taken id is an update the
 * rules refuse, and the next draw is tried.
 */
export async function createShareCode(p: { kind: CollabKind; targetId: string; ownerUid: string; role: Exclude<CollabRole, "owner">; title: string }): Promise<ShareCode> {
  const { fs, db } = await firestore();
  const now = Date.now();
  let denied: unknown = null;
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generateCode();
    try {
      await fs.setDoc(fs.doc(db, "share_codes", code), {
        kind: p.kind,
        targetId: p.targetId,
        ownerUid: p.ownerUid,
        role: p.role,
        title: p.title,
        createdAt: fs.Timestamp.fromMillis(now),
        expiresAt: fs.Timestamp.fromMillis(now + CODE_VALID_MS),
        uses: 0,
        revoked: false,
      });
      return { code, kind: p.kind, targetId: p.targetId, ownerUid: p.ownerUid, role: p.role, title: p.title, createdAtMs: now, expiresAtMs: now + CODE_VALID_MS, uses: 0, revoked: false };
    } catch (e) {
      if (fsCode(e) !== "permission-denied") throw e;
      denied = e;
    }
  }
  throw denied ?? new Error("Could not find a free share code");
}

export async function revokeShareCode(code: string): Promise<void> {
  const { fs, db } = await firestore();
  await fs.updateDoc(fs.doc(db, "share_codes", code), { revoked: true });
}

/** The owner's live codes for one target, newest first. */
export async function activeCodesFor(targetId: string | null, ownerUid: string): Promise<ShareCode[]> {
  if (!targetId) return [];
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(
    fs.query(fs.collection(db, "share_codes"), fs.where("ownerUid", "==", ownerUid), fs.where("targetId", "==", targetId), fs.where("revoked", "==", false)),
  );
  const now = Date.now();
  return snap.docs
    .map((d) => codeFrom(d.id, d.data()))
    .filter((c): c is ShareCode => c !== null && !c.revoked && c.expiresAtMs > now)
    .sort((a, b) => b.createdAtMs - a.createdAtMs);
}

/** The server's refusals (ShareCodeRefused.known), plus "invalid" for what never parsed. */
export const REFUSALS = ["invalid", "not_found", "expired", "revoked", "used_up", "self", "gone", "full", "in_household", "not_eligible", "too_many_recipes"] as const;
export type Refusal = (typeof REFUSALS)[number];

export class ShareCodeRefused extends Error {
  constructor(public readonly reason: Refusal) {
    super(reason);
  }
}

export interface JoinResult {
  title: string;
  kind: CollabKind;
  alreadyMember: boolean;
  /** Where the joined copy lives, for opening it. */
  localId: string | null;
}

type RedeemBody = {
  already?: boolean;
  household?: { title?: string };
  invite?: { id?: string; collabId?: string; title?: string; ownerUid?: string; targetUid?: string; role?: string; kind?: string };
};

/** Redeems whatever was typed, pasted or scanned and accepts the invite (ShareCodeService.join). */
export async function joinWithCode(raw: string, uid: string, lang: string): Promise<JoinResult> {
  const code = parseCode(raw);
  if (!code) throw new ShareCodeRefused("invalid");
  let body: RedeemBody;
  try {
    body = (await callFunction<RedeemBody>("shareCodes", { action: "redeem", code })) ?? {};
  } catch (e) {
    if (e instanceof ApiError && (REFUSALS as readonly string[]).includes(e.code)) throw new ShareCodeRefused(e.code as Refusal);
    throw e;
  }
  if (body.household) return { title: body.household.title ?? "", kind: "household", alreadyMember: body.already === true, localId: null };
  if (body.already === true || !body.invite) return { title: "", kind: "recipe", alreadyMember: true, localId: null };
  const json = body.invite;
  const collabId = json.collabId ?? "";
  const targetUid = json.targetUid ?? uid;
  const invite: ShareInvite = {
    id: json.id ?? inviteIdFor(collabId, targetUid),
    collabId,
    recipeTitle: json.title ?? "",
    ownerUid: json.ownerUid ?? "",
    targetUid,
    role: json.role === "editor" ? "editor" : "viewer",
    status: "pending",
    createdAtMs: Date.now(),
    kind: kindFrom(json.kind),
    via: null,
  };
  if (invite.kind === "recipe") {
    const local = await acceptRecipeInvite(invite, lang);
    return { title: local.title, kind: "recipe", alreadyMember: false, localId: local.id };
  }
  if (invite.kind === "household") throw new ShareCodeRefused("invalid");
  const local = await acceptContainerInvite(invite, uid, lang);
  return { title: invite.recipeTitle, kind: invite.kind, alreadyMember: false, localId: local.id };
}
