// forum_posts/{id} with replies/{id} beneath, each with a like counter and
// one like document per liker. Field for field ForumFirestoreDataSource:
// live streams for the threads (newest 50) and a thread's replies (newest
// 200, shown oldest first), the viewer's likes resolved once per row.
import { firestore, newId, withFirestore } from "../../../lib/cloud";
import { getPublicProfiles, myAuthor } from "../../sharing/data/profiles";
import { tsMs, validDocId } from "../../sharing/data/types";

export interface ForumPost {
  id: string;
  title: string;
  body: string;
  authorUid: string;
  authorName: string;
  authorPhotoUrl: string | null;
  createdAtMs: number;
  replyCount: number;
  likeCount: number;
  likedByMe: boolean;
}

export interface ForumReply {
  id: string;
  body: string;
  authorUid: string;
  authorName: string;
  authorPhotoUrl: string | null;
  createdAtMs: number;
  sharedRecipeId: string | null;
  sharedRecipeTitle: string | null;
  likeCount: number;
  likedByMe: boolean;
  /** The viewer's own reply drawn before the server acknowledged it. */
  pending: boolean;
}

/** Keyed by the like document's path (which carries the viewer's uid). */
const viewerLikes = new Map<string, boolean>();

type Doc = { id: string; ref: { path: string }; metadata: { hasPendingWrites: boolean }; data: () => Record<string, unknown> };

async function likedByViewer(docs: Doc[], uid: string, refresh: boolean): Promise<boolean[]> {
  const { fs, db } = await firestore();
  return Promise.all(
    docs.map(async (d) => {
      const key = `${d.ref.path}/likes/${uid}`;
      const cached = viewerLikes.get(key);
      if (cached !== undefined && !refresh) return cached;
      // The viewer's own fresh write: nobody can have liked it yet.
      if (d.metadata.hasPendingWrites) return false;
      try {
        const like = await fs.getDoc(fs.doc(db, `${d.ref.path}/likes/${uid}`));
        viewerLikes.set(key, like.exists());
        return like.exists();
      } catch (_) {
        return false;
      }
    }),
  );
}

const str = (v: unknown) => (typeof v === "string" ? v : null);
const int = (v: unknown) => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : 0);

function postFrom(d: Doc, liked: boolean): ForumPost {
  const data = d.data() ?? {};
  return {
    id: d.id,
    title: str(data.title) ?? "",
    body: str(data.body) ?? "",
    authorUid: str(data.authorUid) ?? "",
    authorName: str(data.authorName) ?? "",
    authorPhotoUrl: str(data.authorPhotoUrl),
    createdAtMs: tsMs(data.createdAt) ?? Date.now(),
    replyCount: int(data.replyCount),
    // Threads from before likes carry no counter: zero.
    likeCount: int(data.likeCount),
    likedByMe: liked,
  };
}

function replyFrom(d: Doc, liked: boolean): ForumReply {
  const data = d.data() ?? {};
  return {
    id: d.id,
    body: str(data.body) ?? "",
    authorUid: str(data.authorUid) ?? "",
    authorName: str(data.authorName) ?? "",
    authorPhotoUrl: str(data.authorPhotoUrl),
    createdAtMs: tsMs(data.createdAt) ?? Date.now(),
    sharedRecipeId: str(data.sharedRecipeId),
    sharedRecipeTitle: str(data.sharedRecipeTitle),
    likeCount: int(data.likeCount),
    likedByMe: liked,
    pending: d.metadata.hasPendingWrites,
  };
}

async function withAuthors<T extends { authorUid: string; authorName: string; authorPhotoUrl: string | null }>(rows: T[]): Promise<T[]> {
  if (!rows.length) return rows;
  try {
    const profiles = await getPublicProfiles(rows.map((r) => r.authorUid));
    return rows.map((r) => {
      const p = profiles.get(r.authorUid);
      return p ? { ...r, authorName: p.fullName, authorPhotoUrl: p.photoUrl } : r;
    });
  } catch (_) {
    return rows;
  }
}

/** The newest threads, live. Each emission resolves likes only for rows not seen before. */
export function watchPosts(uid: string, onPosts: (posts: ForumPost[]) => void, onError: () => void, limit = 50): () => void {
  let seq = 0;
  const stop = withFirestore(
    (fs, db) =>
      fs.onSnapshot(
        fs.query(fs.collection(db, "forum_posts"), fs.orderBy("createdAt", "desc"), fs.limit(limit)),
        { includeMetadataChanges: false },
        async (snap) => {
          const mine = ++seq;
          const docs = snap.docs as unknown as Doc[];
          const liked = await likedByViewer(docs, uid, false);
          const posts = await withAuthors(docs.map((d, i) => postFrom(d, liked[i])));
          if (mine === seq) onPosts(posts);
        },
        onError,
      ),
    onError,
  );
  // An emission still resolving likes/authors when the page lets go must not land.
  return () => {
    seq++;
    stop();
  };
}

/** A thread's newest 200 replies, oldest first, live. */
export function watchReplies(postId: string, uid: string, onReplies: (replies: ForumReply[]) => void, onError: () => void): () => void {
  if (!validDocId(postId)) {
    onReplies([]);
    return () => {};
  }
  let seq = 0;
  const stop = withFirestore(
    (fs, db) =>
      fs.onSnapshot(
        fs.query(fs.collection(db, "forum_posts", postId, "replies"), fs.orderBy("createdAt", "desc"), fs.limit(200)),
        { includeMetadataChanges: true },
        async (snap) => {
          const mine = ++seq;
          const docs = [...(snap.docs as unknown as Doc[])].reverse();
          const liked = await likedByViewer(docs, uid, false);
          const replies = await withAuthors(docs.map((d, i) => replyFrom(d, liked[i])));
          if (mine === seq) onReplies(replies);
        },
        onError,
      ),
    onError,
  );
  // An emission still resolving likes/authors when the page lets go must not land.
  return () => {
    seq++;
    stop();
  };
}

/** One thread, live (its counters move as people reply and like). Null when deleted. */
export function watchPost(postId: string, uid: string, onPost: (post: ForumPost | null) => void, onError: () => void): () => void {
  // A link with a malformed id names no thread (and must not reach another path).
  if (!validDocId(postId)) {
    onPost(null);
    return () => {};
  }
  let seq = 0;
  const stop = withFirestore(
    (fs, db) =>
      fs.onSnapshot(
        fs.doc(db, "forum_posts", postId),
        async (snap) => {
          const mine = ++seq;
          if (!snap.exists()) {
            onPost(null);
            return;
          }
          const d = snap as unknown as Doc;
          const [liked] = await likedByViewer([d], uid, false);
          const [post] = await withAuthors([postFrom(d, liked)]);
          if (mine === seq) onPost(post);
        },
        onError,
      ),
    onError,
  );
  // An emission still resolving likes/authors when the page lets go must not land.
  return () => {
    seq++;
    stop();
  };
}

/** One reply by id, for a deep link to a reply older than the window. Null when gone. */
export async function getReply(postId: string, replyId: string, uid: string): Promise<ForumReply | null> {
  if (!validDocId(postId) || !validDocId(replyId)) return null;
  const { fs, db } = await firestore();
  const snap = await fs.getDoc(fs.doc(db, "forum_posts", postId, "replies", replyId));
  if (!snap.exists()) return null;
  const d = snap as unknown as Doc;
  const [liked] = await likedByViewer([d], uid, true);
  const [reply] = await withAuthors([replyFrom(d, liked)]);
  return reply;
}

export async function createPost(title: string, body: string): Promise<void> {
  const me = await myAuthor();
  const { fs, db } = await firestore();
  await fs.setDoc(fs.doc(db, "forum_posts", newId()), {
    title,
    body,
    authorUid: me.uid,
    authorName: me.name,
    authorPhotoUrl: me.photoUrl,
    replyCount: 0,
    likeCount: 0,
    createdAt: fs.Timestamp.now(),
  });
}

/** The reply and the thread's counter in one batch, so the count cannot drift. */
export async function addReply(postId: string, body: string, recipe: { id: string; title: string } | null): Promise<string> {
  if (!validDocId(postId)) throw new Error("Invalid thread id");
  const me = await myAuthor();
  const { fs, db } = await firestore();
  const id = newId();
  const batch = fs.writeBatch(db);
  batch.set(fs.doc(db, "forum_posts", postId, "replies", id), {
    body,
    authorUid: me.uid,
    authorName: me.name,
    authorPhotoUrl: me.photoUrl,
    sharedRecipeId: recipe?.id ?? null,
    sharedRecipeTitle: recipe?.title ?? null,
    likeCount: 0,
    createdAt: fs.Timestamp.now(),
  });
  batch.update(fs.doc(db, "forum_posts", postId), { replyCount: fs.increment(1) });
  await batch.commit();
  return id;
}

/** Thread or reply like: the like document and the counter together. Resolves with the new state. */
export async function toggleLike(path: string, uid: string): Promise<boolean> {
  const { fs, db } = await firestore();
  const target = fs.doc(db, path);
  const like = fs.doc(db, `${path}/likes/${uid}`);
  const key = `${path}/likes/${uid}`;
  // Flipped before the write: the counter reaches the live stream first.
  const before = viewerLikes.get(key);
  viewerLikes.set(key, !(before ?? false));
  try {
    const liked = await fs.runTransaction(db, async (tx) => {
      const existing = await tx.get(like);
      if (existing.exists()) {
        tx.delete(like);
        tx.update(target, { likeCount: fs.increment(-1) });
        return false;
      }
      tx.set(like, { createdAt: fs.Timestamp.now() });
      tx.update(target, { likeCount: fs.increment(1) });
      return true;
    });
    viewerLikes.set(key, liked);
    return liked;
  } catch (e) {
    if (before === undefined) viewerLikes.delete(key);
    else viewerLikes.set(key, before);
    throw e;
  }
}

/** Replies, likes under the thread and under each reply, then the thread — in batches, the thread last. */
export async function deletePost(postId: string): Promise<void> {
  const { fs, db } = await firestore();
  const post = fs.doc(db, "forum_posts", postId);
  const [replies, postLikes] = await Promise.all([fs.getDocs(fs.collection(db, "forum_posts", postId, "replies")), fs.getDocs(fs.collection(db, "forum_posts", postId, "likes"))]);
  const replyLikes = await Promise.all(replies.docs.map((r) => fs.getDocs(fs.collection(db, r.ref.path, "likes"))));
  const refs = [...postLikes.docs.map((d) => d.ref), ...replyLikes.flatMap((s) => s.docs.map((d) => d.ref)), ...replies.docs.map((d) => d.ref), post];
  for (let i = 0; i < refs.length; i += 450) {
    const batch = fs.writeBatch(db);
    for (const ref of refs.slice(i, i + 450)) batch.delete(ref);
    await batch.commit();
  }
}
