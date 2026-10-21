// A recipe book exactly as the app stores it in users/{uid}/books/{id}
// (RecipeBookModel.toJson in lib/features/recipe_books/data/models/
// recipe_book_model.g.dart). Read through `normalizeBook`, write only what
// `bookToDart` returns — every key present, nulls included.
// webapp/contract-fixtures/books/ holds samples the Dart contract test parses.
//
// Books point at recipes by local id (`recipeRefs[].recipeId`) with a dense
// 0..n-1 `order`; the helpers below keep that invariant the way the app's
// BookViewerBloc does.

export const BOOK_SPINES = ["violet", "indigo", "teal", "mint", "amber", "coral", "rose", "plum", "forest", "slate"] as const;
export type BookSpine = (typeof BOOK_SPINES)[number];

export type BookCollabRole = "owner" | "editor" | "viewer";
/** AccessRole names (collaborators map values). */
export type BookAccessRole = "owner" | "editor" | "viewer";

export interface BookRecipeRef {
  recipeId: string;
  order: number;
}

export interface RecipeBook {
  id: string;
  title: string;
  recipeRefs: BookRecipeRef[];
  /** uid → AccessRole name. Legacy; the app keeps it but no longer fills it. */
  collaborators: Record<string, string>;
  /** ISO-8601, as DateTime.toIso8601String(). */
  createdAt: string;
  /** A file on the device that picked the cover; always null from the web. */
  coverImageFileName: string | null;
  /** Firebase Storage path of the cover (recipe_images/{uid}/…). */
  coverImageStoragePath: string | null;
  spine: BookSpine | null;
  collabId: string | null;
  collabRole: BookCollabRole | null;
  contentLang: string | null;
  contentVersion: number;
}

const str = (v: unknown): string | null => (typeof v === "string" ? v : null);
const int = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : null);
const oneOf = <T extends string>(v: unknown, all: readonly T[]): T | null => (typeof v === "string" && (all as readonly string[]).includes(v) ? (v as T) : null);
const ROLES = ["owner", "editor", "viewer"] as const;

/** Any stored document → a complete RecipeBook (the app's defaults). */
export function normalizeBook(raw: unknown): RecipeBook {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const refs = Array.isArray(r.recipeRefs) ? r.recipeRefs : [];
  const collaborators: Record<string, string> = {};
  if (r.collaborators && typeof r.collaborators === "object" && !Array.isArray(r.collaborators)) {
    for (const [k, v] of Object.entries(r.collaborators as Record<string, unknown>)) if (typeof v === "string") collaborators[k] = v;
  }
  return {
    id: String(r.id ?? ""),
    title: String(r.title ?? ""),
    recipeRefs: refs
      .map((x, i) => {
        const o = (x && typeof x === "object" ? x : {}) as Record<string, unknown>;
        return { recipeId: String(o.recipeId ?? ""), order: int(o.order) ?? i };
      })
      .filter((ref) => ref.recipeId !== ""),
    collaborators,
    createdAt: str(r.createdAt) ?? new Date(0).toISOString(),
    coverImageFileName: str(r.coverImageFileName),
    coverImageStoragePath: str(r.coverImageStoragePath),
    // Stored by name; an unknown name (a newer build's colour) reads as unset.
    spine: oneOf(r.spine, BOOK_SPINES),
    collabId: str(r.collabId),
    collabRole: oneOf(r.collabRole, ROLES),
    contentLang: str(r.contentLang),
    contentVersion: int(r.contentVersion) ?? 0,
  };
}

/** The exact document the app writes (key order mirrors RecipeBookModel.toJson). */
export function bookToDart(b: RecipeBook): Record<string, unknown> {
  return {
    id: b.id,
    title: b.title,
    recipeRefs: b.recipeRefs.map((r) => ({ recipeId: r.recipeId, order: Math.trunc(r.order) })),
    collaborators: { ...b.collaborators },
    createdAt: b.createdAt,
    coverImageFileName: b.coverImageFileName,
    coverImageStoragePath: b.coverImageStoragePath,
    spine: b.spine,
    collabId: b.collabId,
    collabRole: b.collabRole,
    contentLang: b.contentLang,
    contentVersion: Math.trunc(b.contentVersion),
  };
}

/** A new, empty book (LibraryBloc._createBook). */
export function newBook(id: string, title: string, spine: BookSpine | null = null): RecipeBook {
  return normalizeBook({ id, title, recipeRefs: [], createdAt: new Date().toISOString(), spine });
}

/** RecipeBookEntity.canEdit: everything but a viewer's copy. */
export function canEditBook(b: RecipeBook): boolean {
  return b.collabRole !== "viewer";
}

/** RecipeBookEntity.isMine: never shared, or shared by this account. */
export function isBookMine(b: RecipeBook): boolean {
  return b.collabRole === null || b.collabRole === "owner";
}

export function isBookShared(b: RecipeBook): boolean {
  return b.collabId !== null;
}

/** RecipeBookEntity.orderedRefs. */
export function orderedRefs(b: RecipeBook): BookRecipeRef[] {
  return [...b.recipeRefs].sort((a, c) => a.order - c.order);
}

/** BookViewerBloc._addRecipe: appended with the next order; a duplicate is a no-op. */
export function withRecipeAdded(b: RecipeBook, recipeId: string): RecipeBook {
  if (b.recipeRefs.some((r) => r.recipeId === recipeId)) return b;
  return { ...b, recipeRefs: [...b.recipeRefs, { recipeId, order: b.recipeRefs.length }] };
}

/** BookViewerBloc._removeRecipe. */
export function withRecipeRemoved(b: RecipeBook, recipeId: string): RecipeBook {
  return { ...b, recipeRefs: b.recipeRefs.filter((r) => r.recipeId !== recipeId) };
}

/**
 * BookViewerBloc._reorderRecipes: the move is made on the ids shown (recipes
 * this account has), refs to missing recipes keep their place at the end, and
 * `order` is renumbered 0..n-1.
 */
export function withRecipeMoved(b: RecipeBook, shownIds: string[], from: number, to: number): RecipeBook {
  const shown = [...shownIds];
  if (from < 0 || from >= shown.length) return b;
  const target = Math.max(0, Math.min(to, shown.length - 1));
  if (target === from) return b;
  shown.splice(target, 0, shown.splice(from, 1)[0]);
  const visible = new Set(shown);
  const ids = [...shown, ...orderedRefs(b).map((r) => r.recipeId).filter((id) => !visible.has(id))];
  return { ...b, recipeRefs: ids.map((recipeId, order) => ({ recipeId, order })) };
}

/**
 * The app's save rule (RecipeBooksRepositoryImpl._stamped): a book's words are
 * its title. The language is stamped when the title changed or was never
 * stamped; contentVersion moves on only when an existing title changed.
 */
export function stampBook(next: RecipeBook, previous: RecipeBook | null, lang: string): RecipeBook {
  const edited = previous === null || previous.title !== next.title;
  if (!edited && next.contentLang !== null) return next;
  return {
    ...next,
    contentLang: lang,
    contentVersion: edited && previous !== null ? previous.contentVersion + 1 : next.contentVersion,
  };
}

// ---------------------------------------------------------------------------
// The shared copy: collab_containers/{collabId} with kind "book"
// (BookContainerAdapter in lib/features/collab_containers/domain/
// container_adapter.dart). Recipes travel by their collab id, never by the
// local id, which means nothing on another account.

/** The `content` map of a shared book. A recipe with no collab id is left out. */
export function bookContainerContent(b: RecipeBook, collabIdByRecipeId: Map<string, string>): Record<string, unknown> {
  const recipes: { collabId: string; order: number }[] = [];
  for (const ref of orderedRefs(b)) {
    const collabId = collabIdByRecipeId.get(ref.recipeId);
    if (collabId) recipes.push({ collabId, order: Math.trunc(ref.order) });
  }
  return {
    coverImageFileName: b.coverImageFileName,
    coverImageStoragePath: b.coverImageStoragePath,
    spine: b.spine,
    recipes,
  };
}

/**
 * The shared document laid over this account's copy (BookContainerAdapter.
 * decode). `recipeIdByCollabId` covers every local recipe with a collab id;
 * a local ref missing from its values was never in the document, so it is
 * kept. The copy's own translation stamp survives.
 */
export function bookFromContainer(
  container: { id: string; title: string; content: unknown },
  local: RecipeBook | null,
  recipeIdByCollabId: Map<string, string>,
  role: BookCollabRole,
  makeId: () => string,
): RecipeBook {
  const content = (container.content && typeof container.content === "object" ? container.content : {}) as Record<string, unknown>;
  const remotePath = str(content.coverImageStoragePath);
  const linked = new Set(recipeIdByCollabId.values());
  const refs: BookRecipeRef[] = (local?.recipeRefs ?? []).filter((r) => !linked.has(r.recipeId));
  for (const raw of Array.isArray(content.recipes) ? content.recipes : []) {
    if (!raw || typeof raw !== "object") continue;
    const o = raw as Record<string, unknown>;
    const localId = typeof o.collabId === "string" ? recipeIdByCollabId.get(o.collabId) : undefined;
    if (!localId) continue;
    refs.push({ recipeId: localId, order: int(o.order) ?? refs.length });
  }
  return {
    id: local?.id ?? makeId(),
    title: container.title,
    recipeRefs: refs,
    collaborators: local?.collaborators ?? {},
    createdAt: local?.createdAt ?? new Date().toISOString(),
    coverImageFileName: remotePath !== null ? str(content.coverImageFileName) : local?.coverImageFileName ?? null,
    coverImageStoragePath: remotePath ?? local?.coverImageStoragePath ?? null,
    spine: oneOf(content.spine, BOOK_SPINES) ?? local?.spine ?? null,
    collabId: container.id,
    collabRole: role,
    contentLang: local?.contentLang ?? null,
    contentVersion: local?.contentVersion ?? 0,
  };
}

/** The recipe ids a shared book carries across (ContainerAdapter.recipeIdsOf). */
export function bookRecipeIds(b: RecipeBook): string[] {
  return orderedRefs(b).map((r) => r.recipeId);
}
