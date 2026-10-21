// The library (lib/features/recipe_books/presentation/pages/library_page.dart):
// the account's recipe books as covers on a shelf. Create, rename, recolour,
// set or remove a cover photo, delete (asks first). With ?addRecipe=<id> the
// shelf becomes a picker: tap a book to put that recipe in it.
import { useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { newId } from "../../lib/cloud";
import { Icon } from "../../components/icons";
import { ShareLink } from "../../components/ShareLink";
import { Notice, PageTitle, Spinner } from "../../components/ui";
import { ImagePicker } from "../recipes/components/ImagePicker";
import { BOOK_SPINES, isBookMine, isBookShared, newBook, withRecipeAdded, type BookSpine, type RecipeBook } from "../../models/book";
import { useTranslatedList } from "../../lib/contentTranslation";
import { createBook, deleteBook, setBookCover, updateBook, useBooks, webCanEditBook } from "./booksStore";
import { bookSpineColor, spineColor } from "./spine";
import { ConfirmDialog, EmptyState, ErrorState, LoadingState, Modal, PromptDialog, RoleTag, StorageImage, useToast } from "./shared/components";
import { useBusy, useRecipes } from "./shared/hooks";
import { saveErrorKey, saveOrGone } from "./shared/store";
import { useIsPhone } from "../../components/useIsPhone";
import { FloatingHeaderView } from "../../components/FloatingHeaderView";
import { ClayButton, ClayIconButton } from "../../components/clay";
import { usePhoneNavigate } from "../../components/pageTransition";
import { PhoneBookCover, PhoneBookOptions, PhoneCreateBook } from "./PhoneLibrary";

/**
 * GenerateImageUseCase.bookCoverPrompt with neither a mood nor a subject (the
 * picker's AI tab lets the user rewrite it): English, the title capped at 120.
 */
function bookCoverPrompt(title: string): string {
  return (
    `Cookbook cover illustration for a recipe book titled "${title.trim().slice(0, 120)}": a warm, inviting food still life. ` +
    "Soft light, tasteful composition, the food is the hero. No text, no letters, no people."
  );
}

export function LibraryPage() {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const addRecipeId = params.get("addRecipe");
  const { books, error } = useBooks(user?.uid);
  // Titles in the language on screen; every action below uses the stored book.
  const shownBooks = useTranslatedList("book", books);
  const recipes = useRecipes(addRecipeId ? user?.uid : null);
  const [creating, setCreating] = useState(false);
  const [options, setOptions] = useState<RecipeBook | null>(null);
  const [toast, show] = useToast();
  const busy = useBusy();
  const phone = useIsPhone();
  const go = usePhoneNavigate();

  const addRecipe = addRecipeId ? recipes.byId.get(addRecipeId) ?? null : null;
  const recipeMissing = addRecipeId !== null && recipes.list !== null && addRecipe === null;
  const stopAdding = () => {
    params.delete("addRecipe");
    setParams(params, { replace: true });
  };

  const addTo = (book: RecipeBook) =>
    busy.run(`add-${book.id}`, async () => {
      if (!addRecipeId) return;
      try {
        // A book deleted (or made read-only) on another device says so.
        await saveOrGone<RecipeBook>((edit) => updateBook(book.id, edit, lang), (b) => withRecipeAdded(b, addRecipeId));
        show(t("library.added", { book: book.title }));
        stopAdding();
      } catch (e) {
        show(t(saveErrorKey(e)), "error");
      }
    });

  const create = async (title: string, spine: BookSpine | null) => {
    let book = newBook(newId(), title, spine);
    if (addRecipeId && addRecipe) book = withRecipeAdded(book, addRecipeId);
    await createBook(book, lang);
    if (addRecipeId && addRecipe) {
      show(t("library.added", { book: title }));
      stopAdding();
    } else navigate(`/library/${book.id}`);
  };

  const newButton = (
    <button type="button" className="clay-btn-primary w-full sm:w-auto" onClick={() => setCreating(true)}>
      <Icon name="add" size={20} />
      {t("library.newBook")}
    </button>
  );

  const banner = addRecipeId ? (
    <div className="mb-5">
      <Notice kind={recipeMissing ? "warn" : "info"}>
        <span className="flex flex-wrap items-center justify-between gap-3">
          <span>{recipeMissing ? t("library.addRecipeMissing") : addRecipe ? t("library.addRecipeBanner", { title: addRecipe.title }) : recipes.error ? t("library.ui.loadFailed") : t("common.loading")}</span>
          <button type="button" className="clay-btn-ghost min-h-0 px-3 py-1" onClick={stopAdding}>
            {t("library.ui.cancel")}
          </button>
        </span>
      </Notice>
    </div>
  ) : null;

  // Below lg: the app's shelf (library_page.dart). No header over an empty
  // shelf, only the empty state with its "new book" button.
  if (phone) {
    const newPhoneButton = (
      <ClayButton icon="add" onClick={() => setCreating(true)}>
        {t("library.newBook")}
      </ClayButton>
    );
    return (
      <>
        {error && !books ? (
          <ErrorState />
        ) : books === null ? (
          <LoadingState />
        ) : books.length === 0 ? (
          <>
            {banner}
            <EmptyState icon="library" phoneIcon="auto_stories" message={t("library.empty")} action={newPhoneButton} />
          </>
        ) : (
          <FloatingHeaderView
            title={t("library.title")}
            subtitle={t("library.subtitle")}
            bottomGap={32}
            actionCount={1}
            actions={<ClayIconButton icon="add" size={48} filled label={t("library.newBook")} onClick={() => setCreating(true)} />}
          >
            {banner}
            <ul className="grid grid-cols-2 gap-x-4 gap-y-8" aria-label={t("library.title")}>
              {books.map((book, i) => (
                <li key={book.id} className="aspect-[0.72]">
                  <PhoneBookCover
                    book={shownBooks?.[i] ?? book}
                    picking={addRecipe !== null}
                    contains={addRecipeId !== null && book.recipeRefs.some((r) => r.recipeId === addRecipeId)}
                    busy={busy.is(`add-${book.id}`)}
                    onOpen={() => go(`/library/${book.id}`)}
                    onPick={() => addTo(book)}
                    onOptions={() => setOptions(book)}
                  />
                </li>
              ))}
            </ul>
          </FloatingHeaderView>
        )}
        {creating ? <PhoneCreateBook onClose={() => setCreating(false)} onCreate={create} /> : null}
        {options ? <PhoneBookOptions book={books?.find((b) => b.id === options.id) ?? options} onClose={() => setOptions(null)} onDeleted={() => show(t("library.deleted"))} /> : null}
        {toast}
      </>
    );
  }

  return (
    <>
      <div className="flex flex-wrap items-start justify-between gap-4">
        <PageTitle title={t("library.title")} lead={t("library.subtitle")} />
        {books && books.length > 0 ? <div className="w-full sm:w-auto">{newButton}</div> : null}
      </div>

      {addRecipeId ? (
        <div className="mb-5">
          <Notice kind={recipeMissing ? "warn" : "info"}>
            <span className="flex flex-wrap items-center justify-between gap-3">
              <span>{recipeMissing ? t("library.addRecipeMissing") : addRecipe ? t("library.addRecipeBanner", { title: addRecipe.title }) : recipes.error ? t("library.ui.loadFailed") : t("common.loading")}</span>
              <button type="button" className="clay-btn-ghost min-h-0 px-3 py-1" onClick={stopAdding}>
                {t("library.ui.cancel")}
              </button>
            </span>
          </Notice>
        </div>
      ) : null}

      {error && !books ? (
        <ErrorState />
      ) : books === null ? (
        <LoadingState />
      ) : books.length === 0 ? (
        <EmptyState icon="library" message={t("library.empty")} action={newButton} />
      ) : (
        <ul className="grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-3 lg:grid-cols-4 2xl:grid-cols-5" aria-label={t("library.title")}>
          {books.map((book, i) => (
            <li key={book.id} className="animate-rise">
              <BookCover
                book={shownBooks?.[i] ?? book}
                picking={addRecipe !== null}
                contains={addRecipeId !== null && book.recipeRefs.some((r) => r.recipeId === addRecipeId)}
                busy={busy.is(`add-${book.id}`)}
                onPick={() => addTo(book)}
                onOptions={() => setOptions(book)}
              />
            </li>
          ))}
        </ul>
      )}

      {creating ? <CreateBookDialog onClose={() => setCreating(false)} onCreate={create} /> : null}
      {options ? <BookOptions book={books?.find((b) => b.id === options.id) ?? options} onClose={() => setOptions(null)} onDeleted={() => show(t("library.deleted"))} /> : null}
      {toast}
    </>
  );
}

// ---------------------------------------------------------------------------

function BookCover({ book, picking, contains, busy, onPick, onOptions }: { book: RecipeBook; picking: boolean; contains: boolean; busy: boolean; onPick: () => void; onOptions: () => void }) {
  const { t } = useI18n();
  const editable = webCanEditBook(book);
  const face = (
    <>
      <span className="absolute inset-y-0 start-0 w-3 rounded-s-md" style={{ background: bookSpineColor(book) }} aria-hidden="true" />
      <StorageImage
        path={book.coverImageStoragePath}
        className="absolute inset-0 h-full w-full rounded-md object-cover"
        fallback={<span className="absolute inset-0 rounded-md bg-gradient-to-br from-primary-fixed via-surface-low to-secondary-fixed" aria-hidden="true" />}
      />
      <span className="absolute inset-x-0 bottom-0 rounded-b-md bg-gradient-to-t from-on-surface/80 via-on-surface/40 to-transparent p-3 pt-10 ps-5 text-start">
        <span className="block text-label-sm uppercase tracking-wide text-surface/80">{t("library.collection")}</span>
        <span className="line-clamp-2 block text-body-lg font-bold text-surface">{book.title || t("library.ui.untitled")}</span>
        <span className="block text-label-sm text-surface/85">{t("library.recipesCount", { n: book.recipeRefs.length })}</span>
      </span>
      {isBookShared(book) ? (
        <span className="absolute end-2 top-2">
          <RoleTag role={book.collabRole} />
        </span>
      ) : null}
    </>
  );
  const shape = "relative block aspect-[0.72] w-full overflow-hidden rounded-md shadow-card transition-transform hover:-translate-y-0.5 focus-visible:-translate-y-0.5";

  return (
    <div className="relative">
      {picking ? (
        <button type="button" className={`${shape} disabled:opacity-60`} onClick={onPick} disabled={!editable || contains || busy} aria-label={t("library.addToThis", { book: book.title })}>
          {face}
          <span className="absolute inset-0 grid place-items-center">
            <span className="grid h-14 w-14 place-items-center rounded-full bg-primary text-on-primary shadow-button">{busy ? <Spinner small /> : <Icon name={contains ? "check" : "add"} size={26} />}</span>
          </span>
        </button>
      ) : (
        <Link to={`/library/${book.id}`} className={shape}>
          {face}
        </Link>
      )}
      {!picking ? (
        <button type="button" onClick={onOptions} className="absolute start-4 top-2 grid h-10 w-10 place-items-center rounded-full bg-surface-lowest/90 text-on-surface shadow-control hover:bg-surface-lowest" aria-label={t("library.options", { book: book.title })}>
          <Icon name="more" size={20} />
        </button>
      ) : null}
      {picking && contains ? <p className="mt-1 text-center text-label-sm text-on-surface-variant">{t("library.alreadyIn")}</p> : null}
    </div>
  );
}

export function SpinePicker({ value, onChange, disabled = false }: { value: BookSpine | null; onChange: (s: BookSpine) => void; disabled?: boolean }) {
  const { t } = useI18n();
  return (
    <fieldset>
      <legend className="mb-2 text-label-md text-on-surface-variant">{t("library.spineColor")}</legend>
      <div className="flex flex-wrap gap-2">
        {BOOK_SPINES.map((s) => (
          <button
            key={s}
            type="button"
            disabled={disabled}
            onClick={() => onChange(s)}
            aria-pressed={value === s}
            aria-label={t(`library.spine.${s}`)}
            title={t(`library.spine.${s}`)}
            className={`grid h-9 w-9 place-items-center rounded-full ring-offset-2 ring-offset-surface-lowest transition-shadow ${value === s ? "ring-2 ring-primary" : ""}`}
            style={{ background: spineColor(s) }}
          >
            {value === s ? <Icon name="check" size={16} className="text-surface" /> : null}
          </button>
        ))}
      </div>
    </fieldset>
  );
}

function CreateBookDialog({ onClose, onCreate }: { onClose: () => void; onCreate: (title: string, spine: BookSpine | null) => Promise<void> }) {
  const { t } = useI18n();
  const [spine, setSpine] = useState<BookSpine | null>(null);
  return (
    <PromptDialog title={t("library.newBook")} label={t("library.bookName")} confirmLabel={t("library.create")} onClose={onClose} onSubmit={(title) => onCreate(title, spine)}>
      <SpinePicker value={spine} onChange={setSpine} />
    </PromptDialog>
  );
}

/** The app's long-press sheet: cover photo, spine colour, rename, delete. */
export function BookOptions({ book, onClose, onDeleted }: { book: RecipeBook; onClose: () => void; onDeleted?: () => void }) {
  const { t, lang } = useI18n();
  const navigate = useNavigate();
  const editable = webCanEditBook(book);
  // A member does not delete a shared book; they leave it.
  const leaves = isBookShared(book) && !isBookMine(book);
  const busy = useBusy();
  const [error, setError] = useState<string | null>(null);
  const [renaming, setRenaming] = useState(false);
  const [deleting, setDeleting] = useState(false);
  // The app's image source sheet: upload, web image search or an AI cover.
  const [picking, setPicking] = useState(false);

  const guard = (key: string, fn: () => Promise<unknown>) =>
    busy.run(key, async () => {
      setError(null);
      try {
        await fn();
      } catch (e) {
        setError(t(key === "cover" && saveErrorKey(e) !== "library.ui.gone" ? "library.coverFailed" : saveErrorKey(e)));
      }
    });
  const edit = (change: (b: RecipeBook) => RecipeBook) => saveOrGone<RecipeBook>((e) => updateBook(book.id, e, lang), change);

  if (picking)
    return (
      <ImagePicker
        open
        onClose={() => setPicking(false)}
        hasImage={!!book.coverImageStoragePath}
        searchQuery={book.title}
        aiPrompt={bookCoverPrompt(book.title)}
        onPicked={(path) => {
          setPicking(false);
          void guard(path ? "cover" : "uncover", () => setBookCover(book.id, path, lang));
        }}
      />
    );

  if (renaming)
    return (
      <PromptDialog
        title={t("library.rename")}
        label={t("library.bookName")}
        initial={book.title}
        confirmLabel={t("library.ui.save")}
        onClose={onClose}
        onSubmit={async (title) => {
          await edit((b) => ({ ...b, title }));
        }}
      />
    );
  if (deleting)
    return (
      <ConfirmDialog
        title={leaves ? t("library.leave") : t("library.delete")}
        message={t(leaves ? "library.leaveConfirm" : isBookShared(book) ? "library.deleteSharedConfirm" : "library.deleteConfirm", { title: book.title })}
        confirmLabel={leaves ? t("library.leave") : t("library.delete")}
        onClose={onClose}
        onConfirm={async () => {
          await deleteBook(book);
          onDeleted?.();
          navigate("/library", { replace: true });
        }}
      />
    );

  return (
    <Modal title={book.title || t("library.ui.untitled")} onClose={onClose} busy={busy.any}>
      <div className="space-y-5">
        {!editable ? <Notice kind="info">{t("library.viewerOnly")}</Notice> : null}
        {error ? <Notice kind="error">{error}</Notice> : null}

        <section aria-labelledby="cover-h" className="space-y-2">
          <h3 id="cover-h" className="text-label-md text-on-surface-variant">
            {t("library.coverImage")}
          </h3>
          <div className="flex items-center gap-3">
            <StorageImage
              path={book.coverImageStoragePath}
              className="h-24 w-[4.3rem] rounded-std object-cover shadow-control"
              fallback={<span className="grid h-24 w-[4.3rem] place-items-center rounded-std bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true"><Icon name="image" /></span>}
            />
            <div className="flex flex-1 flex-wrap gap-2">
              <button type="button" className="clay-btn-secondary" disabled={!editable || busy.any} aria-busy={busy.is("cover") || undefined} onClick={() => setPicking(true)}>
                {busy.is("cover") ? <Spinner small /> : <Icon name="upload" size={18} />}
                {book.coverImageStoragePath ? t("library.changeCover") : t("library.uploadCover")}
              </button>
              {book.coverImageStoragePath ? (
                <button type="button" className="clay-btn-ghost" disabled={!editable || busy.any} onClick={() => guard("uncover", () => setBookCover(book.id, null, lang))}>
                  {busy.is("uncover") ? <Spinner small /> : <Icon name="trash" size={18} />}
                  {t("library.removeCover")}
                </button>
              ) : null}
            </div>
          </div>
        </section>

        <SpinePicker value={book.spine} disabled={!editable || busy.any} onChange={(s) => guard("spine", () => edit((b) => ({ ...b, spine: s })))} />

        {/* Only the owner hands a book on (ShareLink hides itself otherwise). */}
        <ShareLink kind="book" id={book.id} mine={isBookMine(book)} />

        <div className="grid gap-2 sm:grid-cols-2">
          <button type="button" className="clay-btn-secondary" disabled={!editable || busy.any} onClick={() => setRenaming(true)}>
            <Icon name="edit" size={18} />
            {t("library.rename")}
          </button>
          <button type="button" className="clay-btn-danger" disabled={busy.any} onClick={() => setDeleting(true)}>
            <Icon name={leaves ? "logout" : "trash"} size={18} />
            {leaves ? t("library.leave") : t("library.delete")}
          </button>
        </div>
      </div>
    </Modal>
  );
}
