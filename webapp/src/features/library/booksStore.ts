// Saving and deleting books like RecipeBooksRepositoryImpl + LibraryBloc /
// BookViewerBloc. A shared book (collabId set) is a cache of its
// collab_containers document: every save by the owner or an editor is
// published to it (ContainerCollab.publish), a delete by the owner takes it
// down and a member's delete leaves it (retire), and an open book follows
// the document live (useFollowBook). A viewer's copy is read-only.
import { useEffect, useMemo } from "react";
import { getRecord, putRecord, useCollection, withFirestore } from "../../lib/cloud";
import { deleteOwnImage } from "../../lib/storage";
import { bookContainerContent, bookFromContainer, bookRecipeIds, bookToDart, canEditBook, isBookMine, isBookShared, normalizeBook, stampBook, type RecipeBook } from "../../models/book";
import { createRecord, GoneError, removeRecord, serial, updateRecord, type RecordCodec } from "./shared/store";
import { containerFrom, containerRecipeCollabIds, materializeRecipes, publishContainer, retireContainer, roleIn, safeId } from "./shared/collab";

const BOOKS: RecordCodec<RecipeBook> = { collection: "books", normalize: normalizeBook, toDart: bookToDart, stamp: stampBook };

/** What this account may change here: everything but a viewer's copy. */
export function webCanEditBook(b: RecipeBook): boolean {
  return canEditBook(b);
}

export function useBooks(uid: string | null | undefined): { books: RecipeBook[] | null; error: Error | null } {
  const { items, error } = useCollection<unknown>("books", uid);
  const books = useMemo(
    () => (items ? items.map(normalizeBook).filter((b) => b.id).sort((a, b) => a.createdAt.localeCompare(b.createdAt)) : null),
    [items],
  );
  return { books, error };
}

export function createBook(book: RecipeBook, lang: string): Promise<RecipeBook> {
  return createRecord(BOOKS, book, lang);
}

function publishBook(book: RecipeBook, lang: string): Promise<void> {
  return publishContainer({
    collabId: book.collabId,
    role: book.collabRole,
    title: book.title,
    recipeIds: bookRecipeIds(book),
    encode: (linked) => bookContainerContent(book, linked.byRecipeId),
    lang,
  });
}

/**
 * Edits the stored book and, when it is shared, publishes it — inside the
 * book's queue, so two publishes never land out of order. Null when the
 * book is gone or read-only here.
 */
export function updateBook(id: string, edit: (b: RecipeBook) => RecipeBook | null, lang: string): Promise<RecipeBook | null> {
  return updateRecord(BOOKS, id, (b) => (webCanEditBook(b) ? edit(b) : null), lang, (saved) => publishBook(saved, lang));
}

/**
 * A new cover: the previous upload goes with it (LibraryBloc._setCoverImage),
 * unless the book is shared and members still point at it.
 */
export async function setBookCover(id: string, storagePath: string | null, lang: string): Promise<RecipeBook | null> {
  const seen: { previous: string | null; shared: boolean } = { previous: null, shared: false };
  const saved = await updateBook(
    id,
    (b) => {
      seen.previous = b.coverImageStoragePath;
      seen.shared = isBookShared(b);
      return { ...b, coverImageFileName: null, coverImageStoragePath: storagePath };
    },
    lang,
  );
  if (!saved) {
    // Deleted (or made read-only) on another device: the new upload has no home.
    if (storagePath) void deleteOwnImage(storagePath);
    throw new GoneError();
  }
  if (seen.previous && seen.previous !== storagePath && !seen.shared) void deleteOwnImage(seen.previous);
  return saved;
}

/**
 * The owner takes the shared document down with it, a member only leaves;
 * then the record and its uploaded cover go (RecipeBooksRepositoryImpl).
 */
export async function deleteBook(book: RecipeBook): Promise<void> {
  if (isBookShared(book)) await retireContainer(book.collabId, isBookMine(book));
  await removeRecord("books", book.id);
  void deleteOwnImage(book.coverImageStoragePath);
}

/**
 * An open shared book follows its document (ContainerCollab.sync): every
 * change is laid over this copy, with the recipes it points at let in
 * first; a document that is gone, or no longer readable, leaves an
 * ordinary private book behind.
 */
export function useFollowBook(id: string, collabId: string | null, uid: string | null | undefined, lang: string): void {
  useEffect(() => {
    if (!uid || !safeId(collabId)) return;
    const apply = (next: (local: RecipeBook) => Promise<RecipeBook | null>) =>
      serial(`books/${id}`, async () => {
        const raw = await getRecord<unknown>("books", id);
        if (!raw) return;
        const local = normalizeBook(raw);
        if (local.collabId !== collabId) return;
        const updated = await next(local);
        if (!updated || JSON.stringify(bookToDart(updated)) === JSON.stringify(bookToDart(local))) return;
        // adapter.save → saveBook, stamped like any save.
        const stamped = stampBook(updated, local, lang);
        await putRecord("books", id, bookToDart(stamped));
      }).catch(() => {});
    const orphan = () => apply(async (local) => ({ ...local, collabId: null, collabRole: null }));
    return withFirestore((fs, db) =>
      fs.onSnapshot(
        fs.doc(db, "collab_containers", collabId),
        (snap) => {
          if (snap.metadata.hasPendingWrites) return;
          if (!snap.exists()) {
            // A cache miss proves nothing; only the server can say it is gone.
            if (!snap.metadata.fromCache) void orphan();
            return;
          }
          const doc = containerFrom(snap.id, snap.data());
          void apply(async (local) => {
            const byCollabId = await materializeRecipes(containerRecipeCollabIds(doc.content), uid, lang);
            return bookFromContainer(doc, local, byCollabId, roleIn(doc, uid), () => crypto.randomUUID());
          });
        },
        (e) => {
          if ((e as { code?: string }).code === "permission-denied") void orphan();
        },
      ),
    );
  }, [id, collabId, uid, lang]);
}
