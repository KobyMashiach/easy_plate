// Support conversations (`feedback/{id}`) and the "what's new" releases,
// the same documents and writes as the app's FeedbackFirestoreDataSource
// and FirestoreWhatsNewRepository. Rules: the author creates with
// authorUid = self, adds follow-ups (never removes one, at most 200) and
// marks an answer seen; a closed conversation takes only the seen mark.
import { useEffect, useState } from "react";
import { firestore, newId, validId, withFirestore } from "../../lib/cloud";

export const FEEDBACK_TYPES = ["bug", "suggestion", "account", "billing", "sharing", "recipes", "other"] as const;
export type FeedbackType = (typeof FEEDBACK_TYPES)[number];
export const MAX_FOLLOW_UPS = 200;
export const MAX_MESSAGE = 4000;

export const FEEDBACK_ICONS: Record<FeedbackType, string> = {
  bug: "support",
  suggestion: "star",
  account: "account",
  billing: "premium",
  sharing: "users",
  recipes: "assistant",
  other: "inbox",
};

export interface Line {
  text: string;
  at: number;
  fromAdmin: boolean;
}

export interface Conversation {
  id: string;
  type: FeedbackType;
  message: string;
  createdAt: number;
  updatedAt: number;
  followUps: Line[];
  replies: Line[];
  userUnread: boolean;
  closed: boolean;
  viaShefi: boolean;
}

const ms = (v: unknown): number | null => {
  if (v && typeof v === "object" && typeof (v as { toMillis?: unknown }).toMillis === "function") return (v as { toMillis: () => number }).toMillis();
  return null;
};

function lines(raw: unknown, fromAdmin: boolean): Line[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((r): r is Record<string, unknown> => !!r && typeof r === "object")
    .map((r) => ({ text: typeof r.text === "string" ? r.text : "", at: ms(r.at) ?? 0, fromAdmin }));
}

/**
 * A stored document → a Conversation. A reason this site does not know (a
 * newer client's) files under "other", as the app's fromData does, rather
 * than hiding the conversation, answers and all.
 */
export function toConversation(id: string, d: Record<string, unknown>): Conversation | null {
  const type: FeedbackType = (FEEDBACK_TYPES as readonly string[]).includes(d.type as string) ? (d.type as FeedbackType) : "other";
  // A pending server timestamp reads as null for a moment: now, as the app does.
  const createdAt = ms(d.createdAt) ?? Date.now();
  return {
    id,
    type,
    message: typeof d.message === "string" ? d.message : "",
    createdAt,
    updatedAt: ms(d.updatedAt) ?? createdAt,
    followUps: lines(d.followUps, false),
    replies: lines(d.replies, true),
    userUnread: d.userUnread === true,
    closed: d.status === "closed",
    viaShefi: d.source === "shefi",
  };
}

/** The whole conversation in the order it was written. */
export function threadOf(c: Conversation): Line[] {
  return [{ text: c.message, at: c.createdAt, fromAdmin: false }, ...c.followUps, ...c.replies].sort((a, b) => a.at - b.at);
}

export function excerpt(text: string): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length <= 80 ? flat : `${flat.slice(0, 77)}…`;
}

/** The account's own conversations, live, newest activity first. */
export function useMyConversations(uid: string | null | undefined, enabled = true): { items: Conversation[] | null; error: Error | null } {
  const [state, setState] = useState<{ items: Conversation[] | null; error: Error | null }>({ items: null, error: null });
  useEffect(() => {
    if (!uid || !enabled) return;
    setState({ items: null, error: null });
    // One equality filter and the order done here: no composite index.
    return withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.query(fs.collection(db, "feedback"), fs.where("authorUid", "==", uid), fs.limit(100)),
          (snap) =>
            setState({
              items: snap.docs
                .map((d) => toConversation(d.id, d.data() as Record<string, unknown>))
                .filter((c): c is Conversation => c !== null)
                .sort((a, b) => b.updatedAt - a.updatedAt),
              error: null,
            }),
          (e) => setState((s) => ({ items: s.items, error: e as Error })),
        ),
      (e) => setState((s) => ({ items: s.items, error: e })),
    );
  }, [uid, enabled]);
  return state;
}

/** One conversation, live. `undefined` while loading, `null` when it is gone (or not ours). */
export function useConversation(id: string | undefined): { item: Conversation | null | undefined; error: Error | null } {
  const [state, setState] = useState<{ item: Conversation | null | undefined; error: Error | null }>({ item: undefined, error: null });
  useEffect(() => {
    if (!id) return;
    // An id from the address bar: one with a '/' (or "..", "__x__") would
    // name another path or be refused by Firestore.
    if (!validId(id) || !id.trim()) {
      setState({ item: null, error: null });
      return;
    }
    setState({ item: undefined, error: null });
    return withFirestore(
      (fs, db) =>
        fs.onSnapshot(
          fs.doc(db, "feedback", id),
          (snap) => setState({ item: snap.exists() ? toConversation(snap.id, snap.data() as Record<string, unknown>) : null, error: null }),
          (e) => {
            const code = (e as { code?: string }).code;
            // Someone else's id reads as "not there", the honest answer.
            setState({ item: code === "permission-denied" ? null : undefined, error: code === "permission-denied" ? null : (e as Error) });
          },
        ),
      (e) => setState({ item: undefined, error: e }),
    );
  }, [id]);
  return state;
}

export interface NewFeedback {
  type: FeedbackType;
  message: string;
  authorUid: string;
  authorName: string;
  authorEmail: string | null;
  details: Record<string, string>;
  /** FeedbackSource name: "app" for the form, "shefi" when the assistant sends it. */
  source?: "app" | "shefi";
}

/** Opens a conversation (the app's send) and returns its id. */
export async function sendFeedback(f: NewFeedback): Promise<string> {
  const text = f.message.trim();
  if (!text) throw new Error("empty");
  const id = newId();
  const { fs, db } = await firestore();
  const now = fs.Timestamp.now();
  await fs.setDoc(fs.doc(db, "feedback", id), {
    type: f.type,
    message: text.slice(0, MAX_MESSAGE),
    authorUid: f.authorUid,
    authorName: f.authorName,
    authorEmail: f.authorEmail,
    // No store build on the web: the site names itself.
    appVersion: "web",
    details: f.details,
    source: f.source ?? "app",
    followUps: [],
    userUnread: false,
    read: false,
    createdAt: now,
    updatedAt: now,
  });
  return id;
}

/** The user's follow-up; puts the conversation back among the unread. */
export async function addFollowUp(id: string, text: string): Promise<void> {
  const trimmed = text.trim();
  if (!trimmed) throw new Error("empty");
  const { fs, db } = await firestore();
  // arrayUnion cannot hold a server timestamp, hence the client clock.
  await fs.updateDoc(fs.doc(db, "feedback", id), {
    followUps: fs.arrayUnion({ text: trimmed.slice(0, MAX_MESSAGE), at: fs.Timestamp.now() }),
    updatedAt: fs.serverTimestamp(),
    read: false,
    userUnread: false,
  });
}

export async function markSeen(id: string): Promise<void> {
  const { fs, db } = await firestore();
  await fs.updateDoc(fs.doc(db, "feedback", id), { userUnread: false });
}

// ---------------------------------------------------------------------------
// What's new

export interface WhatsNewFeature {
  featureKey: string;
  title: Record<string, string>;
  description: Record<string, string>;
  imageUrl: string;
  iconName: string;
  targetRoute: string;
  sortOrder: number;
}

export interface WhatsNewRelease {
  version: string;
  versionCode: number;
  isPublished: boolean;
  features: WhatsNewFeature[];
}

const texts = (raw: unknown): Record<string, string> => {
  if (typeof raw === "string") return { en: raw, he: raw };
  if (!raw || typeof raw !== "object") return {};
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(raw)) if (typeof v === "string") out[k] = v;
  return out;
};

/** The reader's language, then English, then Hebrew, then anything. */
export function pick(t: Record<string, string>, lang: string): string {
  for (const k of [lang, "en", "he"]) {
    const v = t[k]?.trim();
    if (v) return v;
  }
  for (const v of Object.values(t)) if (v.trim()) return v.trim();
  return "";
}

export function toRelease(id: string, d: Record<string, unknown>): WhatsNewRelease {
  const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");
  return {
    version: str(d.version),
    versionCode: typeof d.versionCode === "number" ? Math.trunc(d.versionCode) : Number.parseInt(id, 10) || 0,
    isPublished: d.isPublished === true,
    features: Array.isArray(d.features)
      ? d.features
          .filter((f): f is Record<string, unknown> => !!f && typeof f === "object")
          .map((f) => ({
            featureKey: str(f.featureKey),
            title: texts(f.title),
            description: texts(f.description),
            imageUrl: str(f.imageUrl),
            iconName: str(f.iconName),
            targetRoute: str(f.targetRoute),
            sortOrder: typeof f.sortOrder === "number" ? Math.trunc(f.sortOrder) : 0,
          }))
      : [],
  };
}

/**
 * The newest published release with pages — what the app's support screen
 * replays. The web has no build of its own, so it is the newest overall.
 */
export async function latestRelease(): Promise<WhatsNewRelease | null> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "whats_new_releases"), fs.orderBy("versionCode", "desc"), fs.limit(50)));
  for (const d of snap.docs) {
    const r = toRelease(d.id, d.data() as Record<string, unknown>);
    if (r.isPublished && r.features.length > 0) return r;
  }
  return null;
}

/** WhatsNewTargets → a page of the site, or null where the web has none. */
export function webTarget(target: string): string | null {
  const map: Record<string, string> = {
    "tab:recipes": "/recipes",
    "tab:library": "/library",
    "tab:mealPlan": "/plans",
    "tab:groceries": "/groceries",
    "tab:community": "/community",
    ingestion: "/add",
    assistant: "/assistant",
    price_book: "/prices",
    settings: "/settings",
    preferences: "/settings#preferences",
    notification_settings: "/settings#notifications",
    account_menu: "/account",
    notifications: "/inbox",
    profile_edit: "/settings#profile",
    sharing: "/sharing",
    household: "/household",
    support: "/support",
    help: "/support",
    premium: "/pricing",
  };
  // Own keys only: "constructor" from the console would return a function.
  return Object.prototype.hasOwnProperty.call(map, target) ? map[target] : null;
}

/** The console's icon names → the site's icon set. */
export function webIcon(name: string): string {
  const map: Record<string, string> = {
    restaurant_menu: "recipes",
    menu_book: "library",
    library_books: "library",
    calendar_today: "plans",
    shopping_cart: "groceries",
    groups: "community",
    forum: "community",
    favorite: "heart",
    timer: "timer",
    local_fire_department: "cook",
    monitor_heart: "nutrition",
    image: "image",
    image_search: "search",
    share: "share",
    qr_code: "link",
    family_restroom: "household",
    receipt_long: "file",
    price_check: "prices",
    notifications: "inbox",
    workspace_premium: "premium",
    translate: "globe",
    palette: "sun",
    school: "library",
    feedback: "support",
    devices: "settings",
    auto_awesome: "assistant",
  };
  return Object.prototype.hasOwnProperty.call(map, name) ? map[name] : "star";
}
