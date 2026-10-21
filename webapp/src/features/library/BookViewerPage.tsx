// One book, open (book_viewer_page.dart + open_book_shell.dart): the table of
// contents with the cover, then a page per recipe. From `lg` up it lies open
// as a two-page spread (spread s = pages 2s and 2s+1, an odd last page faces a
// blank), turned with the buttons or the arrow keys; on a phone it is one page
// at a time. An editor adds recipes (multi-select picker), removes and
// reorders them; a viewer's or shared copy reads only.
import { useCallback, useEffect, useMemo, useRef, useState, type DragEvent, type ReactNode } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ShareLink } from "../../components/ShareLink";
import { useAuth } from "../../lib/auth";
import { useI18n } from "../../lib/i18n";
import { useRecord } from "../../lib/cloud";
import { useTranslated, useTranslatedList } from "../../lib/contentTranslation";
import { Icon } from "../../components/icons";
import { Notice, Pill, Spinner } from "../../components/ui";
import { Protected } from "../../components/Protected";
import { isBookMine, isBookShared, normalizeBook, orderedRefs, withRecipeAdded, withRecipeMoved, withRecipeRemoved, type RecipeBook } from "../../models/book";
import type { Recipe } from "../../models/recipe";
import { setBookCover, updateBook, useFollowBook, webCanEditBook } from "./booksStore";
import { bookSpineColor } from "./spine";
import { BookOptions } from "./LibraryPage";
import { ConfirmDialog, ErrorState, LoadingState, RecipePicker, RecipeThumb, RoleTag, StorageImage, useToast } from "./shared/components";
import { useBusy, useMediaQuery, useReducedMotion, useRecipes } from "./shared/hooks";
import { saveErrorKey, saveOrGone } from "./shared/store";
import { useIsPhone } from "../../components/useIsPhone";
import { usePhoneNavigate } from "../../components/pageTransition";
import { ImagePicker } from "../recipes/components/ImagePicker";
import { PhoneBookViewer } from "./PhoneBookViewer";

export function BookViewerPage() {
  const { t, lang, dir } = useI18n();
  const { user } = useAuth();
  const { id = "" } = useParams();
  const { item, error } = useRecord<unknown>("books", user?.uid, id);
  const book = useMemo<RecipeBook | null | undefined>(() => (item === undefined ? undefined : item === null ? null : normalizeBook(item)), [item]);
  const recipes = useRecipes(user?.uid);
  // Display only: the title and the recipe names in the language on screen.
  const titled = useTranslated("book", book);
  // A shared book follows its document while it is open (ContainerCollab.sync).
  useFollowBook(id, book?.collabId ?? null, user?.uid, lang);
  const wide = useMediaQuery("(min-width: 1024px)");
  const reduced = useReducedMotion();
  const [page, setPage] = useState(0);
  const [editing, setEditing] = useState(false);
  const [picking, setPicking] = useState(false);
  const [options, setOptions] = useState(false);
  const [removing, setRemoving] = useState<Recipe | null>(null);
  const [toast, show] = useToast();
  const busy = useBusy();
  const spreadRef = useRef<HTMLDivElement>(null);
  const lastPage = useRef(0);
  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const navigate = useNavigate();
  const [coverPicking, setCoverPicking] = useState(false);

  // Only the recipes this account has are pages; a ref to a deleted or not
  // yet accepted recipe is skipped, as in BookViewerBloc._loadAndEmit.
  const stored = useMemo(() => (book ? orderedRefs(book).map((r) => recipes.byId.get(r.recipeId)).filter((r): r is Recipe => !!r) : []), [book, recipes.byId]);
  const shown = useTranslatedList("recipe", stored) ?? stored;
  const pageCount = shown.length + 1;
  const step = wide ? 2 : 1;
  const first = wide ? page - (page % 2) : page;
  const canBack = first > 0;
  const canForward = first + step < pageCount;

  useEffect(() => {
    if (page > pageCount - 1) setPage(Math.max(0, pageCount - 1));
  }, [page, pageCount]);

  const goTo = useCallback((p: number) => setPage(Math.max(0, Math.min(pageCount - 1, p))), [pageCount]);
  const forward = useCallback(() => canForward && goTo(first + step), [canForward, first, step, goTo]);
  const back = useCallback(() => canBack && goTo(first - step), [canBack, first, step, goTo]);

  // The page turn: a short slide in the reading direction (none when reduced).
  useEffect(() => {
    const el = spreadRef.current;
    const from = lastPage.current;
    lastPage.current = first;
    if (!el || reduced || from === first || typeof el.animate !== "function") return;
    const ahead = first > from ? 1 : -1;
    const sign = (dir === "rtl" ? -1 : 1) * ahead;
    el.animate([{ opacity: 0.2, transform: `translateX(${sign * 24}px)` }, { opacity: 1, transform: "translateX(0)" }], { duration: 240, easing: "cubic-bezier(.2,.8,.2,1)" });
  }, [first, dir, reduced]);

  // Arrow keys turn pages in the reading direction; Home/End jump.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey) return;
      const target = e.target as HTMLElement | null;
      if (target && (target.closest("input, textarea, select, [contenteditable=true]") || target.closest('[role="dialog"]'))) return;
      const next = dir === "rtl" ? "ArrowLeft" : "ArrowRight";
      const prev = dir === "rtl" ? "ArrowRight" : "ArrowLeft";
      if (e.key === next || e.key === "PageDown") forward();
      else if (e.key === prev || e.key === "PageUp") back();
      else if (e.key === "Home") goTo(0);
      else if (e.key === "End") goTo(pageCount - 1);
      else return;
      e.preventDefault();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [dir, forward, back, goTo, pageCount]);

  if (error && !book) return <ErrorState />;
  if (book === undefined) return <LoadingState />;
  if (book === null)
    return (
      <div className="mx-auto max-w-md space-y-3 py-8 text-center">
        <Notice kind="warn">{t("library.notFound")}</Notice>
        <Link to="/library" className="clay-btn-secondary">
          {t("library.backToLibrary")}
        </Link>
      </div>
    );

  const editable = webCanEditBook(book);
  const who = user?.email || user?.phoneNumber || user?.uid || "";
  // Against the stored book; one deleted or made read-only meanwhile says so.
  const store = (edit: (b: RecipeBook) => RecipeBook) => saveOrGone<RecipeBook>((e) => updateBook(book.id, e, lang), edit);
  const save = (key: string, edit: (b: RecipeBook) => RecipeBook) =>
    busy.run(key, async () => {
      try {
        await store(edit);
      } catch (e) {
        show(t(saveErrorKey(e)), "error");
      }
    });

  // By id, against the stored book: a recipe a co-editor took out meanwhile
  // must not come back with this move.
  const move = (from: number, to: number) => {
    const movedId = shown[from]?.id;
    const targetId = shown[to]?.id;
    if (!movedId || !targetId) return;
    void save("move", (b) => {
      const ids = orderedRefs(b).map((r) => r.recipeId).filter((rid) => recipes.byId.has(rid));
      const at = ids.indexOf(targetId);
      return at === -1 ? b : withRecipeMoved(b, ids, ids.indexOf(movedId), at);
    });
  };
  const picker = picking ? (
    <RecipePicker
      title={t("library.addRecipes")}
      recipes={recipes.list}
      failed={!!recipes.error}
      multi
      selectedIds={new Set(book.recipeRefs.map((r) => r.recipeId))}
      onToggle={async (r, selected) => {
        await store((b) => (selected ? withRecipeAdded(b, r.id) : withRecipeRemoved(b, r.id)));
      }}
      onClose={() => setPicking(false)}
    />
  ) : null;

  // Below lg: the app's OpenBookShell, full screen over the frame.
  if (phone)
    return (
      <>
        <PhoneBookViewer
          book={titled ?? book}
          recipes={shown}
          who={who}
          page={Math.min(page, pageCount - 1)}
          onPage={goTo}
          actions={{
            onBack: () => {
              const idx = (window.history.state as { idx?: number } | null)?.idx ?? 0;
              if (idx > 0) go(-1);
              else navigate("/library", { replace: true });
            },
            onAdd: editable ? () => setPicking(true) : null,
            onCover: editable ? () => setCoverPicking(true) : null,
            onMove: editable ? move : null,
          }}
        />
        {picker}
        {coverPicking ? (
          <ImagePicker
            open
            onClose={() => setCoverPicking(false)}
            hasImage={!!book.coverImageStoragePath}
            searchQuery={book.title}
            aiPrompt={`Cookbook cover illustration for a recipe book titled "${book.title.trim().slice(0, 120)}": a warm, inviting food still life. Soft light, tasteful composition, the food is the hero. No text, no letters, no people.`}
            onPicked={(path) => {
              setCoverPicking(false);
              void busy.run("cover", async () => {
                try {
                  await setBookCover(book.id, path, lang);
                } catch {
                  show(t("library.coverFailed"), "error");
                }
              });
            }}
          />
        ) : null}
        {toast}
      </>
    );

  const pages: ReactNode[] = [
    <ContentsPage key="toc" book={titled ?? book} recipes={shown} onOpen={(i) => goTo(i + 1)} onCover={editable ? () => setOptions(true) : undefined} />,
    ...shown.map((r, i) => <RecipePage key={r.id} recipe={r} number={i + 2} />),
  ];
  const visible = wide ? [first, first + 1] : [first];

  return (
    <>
      <nav className="mb-3" aria-label={t("nav.breadcrumb")}>
        <Link to="/library" className="inline-flex items-center gap-1 text-label-md text-primary">
          <Icon name="back" size={16} className="rtl:rotate-180" />
          {t("library.title")}
        </Link>
      </nav>

      <header className="mb-4 flex flex-wrap items-center gap-3">
        <span className="h-10 w-2 rounded-full" style={{ background: bookSpineColor(book) }} aria-hidden="true" />
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-headline-lg">{(titled ?? book).title || t("library.ui.untitled")}</h1>
          <p className="text-label-md text-on-surface-variant">{t("library.recipesCount", { n: shown.length })}</p>
        </div>
        {isBookShared(book) ? <RoleTag role={book.collabRole} /> : null}
        <div className="flex flex-wrap gap-2">
          {editable ? (
            <>
              <button type="button" className="clay-btn-primary" onClick={() => setPicking(true)}>
                <Icon name="add" size={18} />
                {t("library.addRecipes")}
              </button>
              <button type="button" className={editing ? "clay-btn-tonal" : "clay-btn-secondary"} aria-pressed={editing} onClick={() => setEditing((v) => !v)}>
                <Icon name="edit" size={18} />
                {t("library.editContents")}
              </button>
            </>
          ) : null}
          <ShareLink kind="book" id={book.id} mine={isBookMine(book)} />
          <button type="button" className="clay-btn-ghost" onClick={() => setOptions(true)} aria-label={t("library.options", { book: book.title })}>
            <Icon name="more" size={20} />
          </button>
        </div>
      </header>

      {!editable ? (
        <div className="mb-4">
          <Notice kind="info">{t("library.viewerOnly")}</Notice>
        </div>
      ) : null}

      <div className={editing ? "grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px]" : ""}>
        <div className="min-w-0">
          <Protected who={who}>
            <div ref={spreadRef} className={wide ? "grid grid-cols-2 overflow-hidden rounded-lg bg-surface-lowest shadow-card" : ""}>
              {visible.map((p, i) => (
                <div
                  key={p}
                  className={
                    wide
                      ? `relative h-[min(78vh,860px)] overflow-y-auto p-8 ${i === 0 ? "border-e border-outline-variant/60 shadow-[inset_-12px_0_18px_-18px_rgb(var(--c-on-surface)/0.5)] rtl:shadow-[inset_12px_0_18px_-18px_rgb(var(--c-on-surface)/0.5)]" : ""}`
                      : "clay overflow-hidden p-5"
                  }
                >
                  {pages[p] ?? <BlankPage />}
                </div>
              ))}
            </div>
          </Protected>

          <div className="mt-4 flex items-center justify-between gap-3">
            <button type="button" className="clay-btn-secondary" onClick={back} disabled={!canBack} aria-label={t("library.prevPage")}>
              <Icon name="back" size={20} className="rtl:rotate-180" />
              <span className="hidden sm:inline">{t("library.prevPage")}</span>
            </button>
            <div className="flex flex-col items-center gap-1">
              <span className="text-label-md text-on-surface-variant" aria-live="polite">
                {wide && first + 1 < pageCount ? t("library.pagesOf", { a: first + 1, b: first + 2, n: pageCount }) : t("library.pageOf", { a: first + 1, n: pageCount })}
              </span>
              {first > 0 ? (
                <button type="button" className="text-label-sm text-primary underline-offset-2 hover:underline" onClick={() => goTo(0)}>
                  {t("library.contents")}
                </button>
              ) : null}
            </div>
            <button type="button" className="clay-btn-secondary" onClick={forward} disabled={!canForward} aria-label={t("library.nextPage")}>
              <span className="hidden sm:inline">{t("library.nextPage")}</span>
              <Icon name="chevron" size={20} className="rtl:rotate-180" />
            </button>
          </div>
          {wide ? <p className="mt-2 text-center text-label-sm text-on-surface-variant">{t("library.keysHint")}</p> : null}
        </div>

        {editing && editable ? (
          <EditPanel
            recipes={shown}
            busy={busy.any}
            onMove={(from, to) => {
              // By id, against the stored book: a recipe a co-editor took out
              // meanwhile must not come back with this move.
              const movedId = shown[from]?.id;
              const targetId = shown[to]?.id;
              if (!movedId || !targetId) return;
              void save("move", (b) => {
                const ids = orderedRefs(b).map((r) => r.recipeId).filter((rid) => recipes.byId.has(rid));
                const at = ids.indexOf(targetId);
                return at === -1 ? b : withRecipeMoved(b, ids, ids.indexOf(movedId), at);
              });
            }}
            onRemove={setRemoving}
            onAdd={() => setPicking(true)}
          />
        ) : null}
      </div>

      {picking ? (
        <RecipePicker
          title={t("library.addRecipes")}
          recipes={recipes.list}
          failed={!!recipes.error}
          multi
          selectedIds={new Set(book.recipeRefs.map((r) => r.recipeId))}
          onToggle={async (r, selected) => {
            await store((b) => (selected ? withRecipeAdded(b, r.id) : withRecipeRemoved(b, r.id)));
          }}
          onClose={() => setPicking(false)}
        />
      ) : null}
      {removing ? (
        <ConfirmDialog
          title={t("library.removeRecipe")}
          message={t("library.removeRecipeConfirm", { title: removing.title, book: book.title })}
          confirmLabel={t("library.remove")}
          onClose={() => setRemoving(null)}
          onConfirm={async () => {
            await store((b) => withRecipeRemoved(b, removing.id));
          }}
        />
      ) : null}
      {options ? <BookOptions book={book} onClose={() => setOptions(false)} /> : null}
      {toast}
    </>
  );
}

// ---------------------------------------------------------------------------
// Pages

function ContentsPage({ book, recipes, onOpen, onCover }: { book: RecipeBook; recipes: Recipe[]; onOpen: (index: number) => void; onCover?: () => void }) {
  const { t } = useI18n();
  const cover = (
    <StorageImage
      path={book.coverImageStoragePath}
      className="h-44 w-full rounded-md object-cover lg:h-56"
      fallback={
        <span className="grid h-44 w-full place-items-center rounded-md bg-gradient-to-br from-primary-fixed to-secondary-fixed text-on-primary-fixed-variant lg:h-56">
          <Icon name="image" size={32} />
          {onCover ? <span className="text-label-md">{t("library.uploadCover")}</span> : null}
        </span>
      }
    />
  );
  return (
    <section aria-labelledby="toc-h" className="space-y-5">
      {onCover ? (
        <button type="button" className="block w-full rounded-md" onClick={onCover} aria-label={t("library.coverImage")}>
          {cover}
        </button>
      ) : (
        cover
      )}
      <div>
        <p className="text-label-sm uppercase tracking-wide text-on-surface-variant">{book.title}</p>
        <h2 id="toc-h" className="text-headline-md">
          {t("library.contents")}
        </h2>
      </div>
      {recipes.length === 0 ? (
        <p className="text-body-md text-on-surface-variant">{t("library.emptyBook")}</p>
      ) : (
        <ol className="divide-y divide-outline-variant/50">
          {recipes.map((r, i) => (
            <li key={r.id}>
              <button type="button" className="flex w-full items-center gap-3 py-2.5 text-start hover:text-primary" onClick={() => onOpen(i)}>
                <span className="min-w-0 flex-1 truncate text-body-md">{r.title || t("library.ui.untitled")}</span>
                <span className="flex-none border-b border-dotted border-outline-variant" aria-hidden="true" />
                <span className="text-label-md text-on-surface-variant" dir="ltr">
                  {i + 2}
                </span>
              </button>
            </li>
          ))}
        </ol>
      )}
      <PageNumber n={1} />
    </section>
  );
}

function amount(n: number | null): string {
  if (n === null) return "";
  if (Number.isInteger(n)) return String(n);
  const fractions: Record<string, string> = { "0.25": "¼", "0.50": "½", "0.75": "¾", "0.33": "⅓", "0.67": "⅔" };
  const whole = Math.floor(n);
  const f = fractions[(n - whole).toFixed(2)];
  return f ? `${whole || ""}${f}` : n.toFixed(1).replace(/\.0$/, "");
}

function RecipePage({ recipe, number }: { recipe: Recipe; number: number }) {
  const { t } = useI18n();
  const meta = [
    recipe.servings ? t("recipe.servings", { n: recipe.servings }) : null,
    recipe.prepTimeMinutes ? t("recipe.prep", { n: recipe.prepTimeMinutes }) : null,
    recipe.cookTimeMinutes ? t("recipe.cook", { n: recipe.cookTimeMinutes }) : null,
  ].filter((m): m is string => !!m);
  const h = `rp-${recipe.id}`;
  return (
    <article aria-labelledby={h} className="space-y-4">
      <StorageImage path={recipe.imageStoragePath} className="h-44 w-full rounded-md object-cover lg:h-52" />
      <h2 id={h} className="text-headline-md">
        <Link to={`/recipes/${recipe.id}`} className="hover:text-primary">
          {recipe.title || t("library.ui.untitled")}
        </Link>
      </h2>
      {meta.length ? (
        <div className="flex flex-wrap gap-2">
          {meta.map((m) => (
            <Pill key={m} tone="lavender">
              {m}
            </Pill>
          ))}
        </div>
      ) : null}
      {recipe.ingredients.length ? (
        <section aria-label={t("recipe.ingredients")}>
          <h3 className="mb-2 text-label-md font-bold text-primary">{t("recipe.ingredients")}</h3>
          <ul className="space-y-1.5">
            {recipe.ingredients.map((ing, i) => (
              <li key={i} className="flex gap-3 border-b border-outline-variant/40 pb-1.5 text-body-md">
                <span className="min-w-14 text-on-surface-variant" dir="ltr">
                  {[amount(ing.amount), t(`unit.${ing.unit}`)].filter(Boolean).join(" ")}
                </span>
                <span>{ing.name}</span>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
      {recipe.steps.length ? (
        <section aria-label={t("recipe.steps")}>
          <h3 className="mb-2 text-label-md font-bold text-primary">{t("recipe.steps")}</h3>
          <ol className="space-y-2.5">
            {recipe.steps.map((s, i) => (
              <li key={i} className="flex gap-3 text-body-md">
                <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary text-label-sm text-on-primary" aria-hidden="true">
                  {i + 1}
                </span>
                <p className="pt-0.5">{s}</p>
              </li>
            ))}
          </ol>
        </section>
      ) : null}
      <PageNumber n={number} />
    </article>
  );
}

function BlankPage() {
  return <div className="h-full" aria-hidden="true" />;
}

function PageNumber({ n }: { n: number }) {
  return (
    <p className="pt-4 text-center text-label-sm text-on-surface-variant" dir="ltr" aria-hidden="true">
      — {n} —
    </p>
  );
}

// ---------------------------------------------------------------------------
// Edit panel: reorder (drag, or the up/down buttons), remove, add.

function EditPanel({ recipes, busy, onMove, onRemove, onAdd }: { recipes: Recipe[]; busy: boolean; onMove: (from: number, to: number) => void; onRemove: (r: Recipe) => void; onAdd: () => void }) {
  const { t } = useI18n();
  const [dragging, setDragging] = useState<number | null>(null);
  const [over, setOver] = useState<number | null>(null);
  const drop = (e: DragEvent, to: number) => {
    e.preventDefault();
    if (dragging !== null && dragging !== to) onMove(dragging, to);
    setDragging(null);
    setOver(null);
  };
  return (
    <aside className="clay h-fit space-y-3 p-4" aria-labelledby="edit-h">
      <div className="flex items-center justify-between gap-2">
        <h2 id="edit-h" className="text-body-lg font-bold">
          {t("library.editContents")}
        </h2>
        {busy ? <Spinner small /> : null}
      </div>
      <p className="text-label-sm text-on-surface-variant">{t("library.reorderHint")}</p>
      {recipes.length === 0 ? (
        <p className="text-body-md text-on-surface-variant">{t("library.emptyBook")}</p>
      ) : (
        <ol className="space-y-2">
          {recipes.map((r, i) => (
            <li
              key={r.id}
              draggable={!busy}
              onDragStart={(e) => {
                setDragging(i);
                e.dataTransfer.effectAllowed = "move";
              }}
              onDragOver={(e) => {
                e.preventDefault();
                setOver(i);
              }}
              onDragLeave={() => setOver((o) => (o === i ? null : o))}
              onDrop={(e) => drop(e, i)}
              onDragEnd={() => {
                setDragging(null);
                setOver(null);
              }}
              className={`flex items-center gap-2 rounded-md border bg-surface-low p-2 ${over === i && dragging !== i ? "border-primary" : "border-outline-variant/60"} ${dragging === i ? "opacity-50" : ""}`}
            >
              <span className="cursor-grab text-on-surface-variant" aria-hidden="true">
                <Icon name="menu" size={18} />
              </span>
              <RecipeThumb recipe={r} size="h-9 w-9" />
              <span className="min-w-0 flex-1 truncate text-body-md">{r.title || t("library.ui.untitled")}</span>
              <button type="button" className="grid h-9 w-9 place-items-center rounded-full hover:bg-surface-high disabled:opacity-40" disabled={busy || i === 0} onClick={() => onMove(i, i - 1)} aria-label={t("library.moveUp", { title: r.title })}>
                <Icon name="chevron" size={18} className="-rotate-90" />
              </button>
              <button type="button" className="grid h-9 w-9 place-items-center rounded-full hover:bg-surface-high disabled:opacity-40" disabled={busy || i === recipes.length - 1} onClick={() => onMove(i, i + 1)} aria-label={t("library.moveDown", { title: r.title })}>
                <Icon name="chevron" size={18} className="rotate-90" />
              </button>
              <button type="button" className="grid h-9 w-9 place-items-center rounded-full text-error hover:bg-error-container disabled:opacity-40" disabled={busy} onClick={() => onRemove(r)} aria-label={t("library.removeNamed", { title: r.title })}>
                <Icon name="trash" size={18} />
              </button>
            </li>
          ))}
        </ol>
      )}
      <button type="button" className="clay-btn-tonal w-full" onClick={onAdd}>
        <Icon name="add" size={18} />
        {t("library.addRecipes")}
      </button>
    </aside>
  );
}
