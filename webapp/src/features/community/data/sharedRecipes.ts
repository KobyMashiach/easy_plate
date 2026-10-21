// shared_recipes/{id}: recipes published to the community feed, each a copy
// of the recipe (not a reference), with a like counter and one like document
// per liker. Field for field SharedRecipesFirestoreDataSource, plus the
// local-recipe side of the bloc (sharedRecipeId on the author's recipe,
// savedFromSharedId on a saved copy).
import { firestore, getRecord, listRecords, newId } from "../../../lib/cloud";
import { saveRecipe } from "../../../lib/recipesStore";
import { normalizeRecipe, type Recipe } from "../../../models/recipe";
import { recipeFields } from "../../sharing/data/collabRecipes";
import { getPublicProfiles, myAuthor } from "../../sharing/data/profiles";
import { tsMs, validDocId } from "../../sharing/data/types";

export interface SharedPost {
  id: string;
  recipe: Recipe;
  authorUid: string;
  authorName: string;
  authorPhotoUrl: string | null;
  createdAtMs: number;
  likeCount: number;
  likedByMe: boolean;
}

const LIKES = "likes";
/** Whether the viewer liked a post, by `postId/uid`, looked up once per session. */
const viewerLikes = new Map<string, boolean>();

type Snap = { id: string; data: () => Record<string, unknown> };

function postFrom(doc: Snap, likedByMe: boolean): SharedPost {
  const data = doc.data() ?? {};
  const createdAtMs = tsMs(data.createdAt) ?? Date.now();
  return {
    id: doc.id,
    // The feed id doubles as the recipe id; saving re-keys it.
    recipe: normalizeRecipe({ ...data, id: doc.id, createdAt: new Date(createdAtMs).toISOString(), sourceChannel: null, collabId: null, collabRole: null, savedFromSharedId: null, sharedRecipeId: null }),
    authorUid: typeof data.authorUid === "string" ? data.authorUid : "",
    authorName: typeof data.authorName === "string" ? data.authorName : "",
    authorPhotoUrl: typeof data.authorPhotoUrl === "string" ? data.authorPhotoUrl : null,
    createdAtMs,
    likeCount: typeof data.likeCount === "number" ? Math.trunc(data.likeCount) : 0,
    likedByMe,
  };
}

async function withLikes(docs: Snap[], uid: string, refresh: boolean): Promise<SharedPost[]> {
  const { fs, db } = await firestore();
  const liked = await Promise.all(
    docs.map(async (d) => {
      const key = `${d.id}/${uid}`;
      const known = viewerLikes.get(key);
      if (known !== undefined && !refresh) return known;
      try {
        const like = await fs.getDoc(fs.doc(db, "shared_recipes", d.id, LIKES, uid));
        viewerLikes.set(key, like.exists());
        return like.exists();
      } catch (_) {
        // One row failing must not fail the feed.
        return viewerLikes.get(key) ?? false;
      }
    }),
  );
  return docs.map((d, i) => postFrom(d, liked[i]));
}

/** The author's live name and photo over what the post was published with. */
async function withLiveAuthors(posts: SharedPost[], refresh: boolean): Promise<SharedPost[]> {
  if (!posts.length) return posts;
  try {
    const profiles = await getPublicProfiles(
      posts.map((p) => p.authorUid),
      { refresh },
    );
    return posts.map((p) => {
      const prof = profiles.get(p.authorUid);
      return prof ? { ...p, authorName: prof.fullName, authorPhotoUrl: prof.photoUrl } : p;
    });
  } catch (_) {
    return posts;
  }
}

export async function getFeed(uid: string, refresh = false, limit = 50): Promise<SharedPost[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "shared_recipes"), fs.orderBy("createdAt", "desc"), fs.limit(limit)));
  return withLiveAuthors(await withLikes(snap.docs, uid, refresh), refresh);
}

/** The viewer's own posts — the "mine" scope reaches past the newest window. */
export async function getMine(uid: string, refresh = false): Promise<SharedPost[]> {
  const { fs, db } = await firestore();
  const snap = await fs.getDocs(fs.query(fs.collection(db, "shared_recipes"), fs.where("authorUid", "==", uid), fs.limit(200)));
  return withLiveAuthors(await withLikes(snap.docs, uid, refresh), refresh);
}

/** The posts among ids that still exist (30 to a query) — the "saved" scope past the window. */
export async function getByIds(ids: string[], uid: string, refresh = false): Promise<SharedPost[]> {
  if (!ids.length) return [];
  const { fs, db } = await firestore();
  const snaps = await Promise.all(
    Array.from({ length: Math.ceil(ids.length / 30) }, (_, i) =>
      fs.getDocs(fs.query(fs.collection(db, "shared_recipes"), fs.where(fs.documentId(), "in", ids.slice(i * 30, i * 30 + 30)))),
    ),
  );
  return withLiveAuthors(await withLikes(snaps.flatMap((s) => s.docs), uid, refresh), refresh);
}

/** Null when the recipe has been unshared since the link to it was posted. */
export async function getSharedPost(id: string, uid: string): Promise<SharedPost | null> {
  // A malformed id (a link, a forum reply, an inbox item) names no post.
  if (!validDocId(id)) return null;
  const { fs, db } = await firestore();
  const doc = await fs.getDoc(fs.doc(db, "shared_recipes", id));
  if (!doc.exists()) return null;
  const [post] = await withLikes([doc as unknown as Snap], uid, true);
  return (await withLiveAuthors([post], false))[0];
}

/** Publishes one of this account's recipes and remembers the post on it. Resolves with the post id. */
export async function publishRecipe(recipe: Recipe, lang: string): Promise<string> {
  const me = await myAuthor();
  const { fs, db } = await firestore();
  const id = newId();
  await fs.setDoc(fs.doc(db, "shared_recipes", id), {
    sourceRecipeId: recipe.id,
    ...recipeFields(recipe),
    authorUid: me.uid,
    authorName: me.name,
    authorPhotoUrl: me.photoUrl,
    likeCount: 0,
    createdAt: fs.Timestamp.now(),
  });
  // So a later edit of the recipe can offer to update the post too. Read
  // again rather than writing the picked snapshot back: the recipe may have
  // been edited (here or on the phone) while the post was being written.
  const current = await getRecord<unknown>("recipes", recipe.id);
  if (current) await saveRecipe({ ...normalizeRecipe(current), sharedRecipeId: id }, lang);
  return id;
}

/** Only the recipe's own fields move: the rules refuse a write touching the author or the likes. */
export async function updateShared(postId: string, recipe: Recipe): Promise<void> {
  const { fs, db } = await firestore();
  await fs.updateDoc(fs.doc(db, "shared_recipes", postId), { ...recipeFields(recipe), updatedAt: fs.serverTimestamp() });
}

/** Deletes the post with its like documents (no cascade), the post in the last batch; clears the mark on local recipes. */
export async function unshare(postId: string, lang: string): Promise<void> {
  const { fs, db } = await firestore();
  const post = fs.doc(db, "shared_recipes", postId);
  const likes = await fs.getDocs(fs.collection(db, "shared_recipes", postId, LIKES));
  const refs = [...likes.docs.map((d) => d.ref), post];
  for (let i = 0; i < refs.length; i += 450) {
    const batch = fs.writeBatch(db);
    for (const ref of refs.slice(i, i + 450)) batch.delete(ref);
    await batch.commit();
  }
  for (const listed of (await listRecords<unknown>("recipes")).map(normalizeRecipe)) {
    if (listed.sharedRecipeId !== postId) continue;
    // Re-read right before the write: an edit since the listing stays, and a
    // recipe deleted meanwhile (here or on the phone) is not written back.
    const raw = await getRecord<unknown>("recipes", listed.id);
    if (!raw) continue;
    const local = normalizeRecipe(raw);
    if (local.sharedRecipeId === postId) await saveRecipe({ ...local, sharedRecipeId: null }, lang);
  }
}

/** The like document and the counter move together, in one transaction. Resolves with the new state. */
export async function toggleLike(postId: string, uid: string): Promise<boolean> {
  const { fs, db } = await firestore();
  const post = fs.doc(db, "shared_recipes", postId);
  const like = fs.doc(db, "shared_recipes", postId, LIKES, uid);
  const liked = await fs.runTransaction(db, async (tx) => {
    const existing = await tx.get(like);
    if (existing.exists()) {
      tx.delete(like);
      tx.update(post, { likeCount: fs.increment(-1) });
      return false;
    }
    tx.set(like, { createdAt: fs.Timestamp.now() });
    tx.update(post, { likeCount: fs.increment(1) });
    return true;
  });
  viewerLikes.set(`${postId}/${uid}`, liked);
  return liked;
}

export type ImportOutcome = "saved" | "alreadySaved";

/** ImportSharedRecipeUseCase: the community recipe as this account's own copy — once. */
export async function importShared(post: SharedPost, lang: string): Promise<ImportOutcome> {
  const existing = (await listRecords<unknown>("recipes")).map(normalizeRecipe);
  if (existing.some((r) => r.savedFromSharedId === post.id)) return "alreadySaved";
  const src = post.recipe;
  await saveRecipe(
    normalizeRecipe({
      id: newId(),
      title: src.title,
      prepTimeMinutes: src.prepTimeMinutes,
      cookTimeMinutes: src.cookTimeMinutes,
      ingredients: src.ingredients,
      steps: src.steps,
      dietaryTags: src.dietaryTags,
      allergens: src.allergens,
      mayContain: src.mayContain,
      // The author's Storage path, not a copy: the post is a snapshot.
      imageFileName: src.imageFileName,
      imageStoragePath: src.imageStoragePath,
      servings: src.servings,
      nutrition: src.nutrition,
      savedFromSharedId: post.id,
      createdAt: new Date().toISOString(),
    }),
    lang,
  );
  return "saved";
}
