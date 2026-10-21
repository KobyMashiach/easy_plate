// The open book below lg, as the app draws it (open_book_shell.dart,
// quick_jump_capsule.dart, book_page_surface.dart, table_of_contents_page.dart,
// recipe_book_page.dart, quick_nav_sheet.dart): full screen over the frame (no
// bar, no dock), a lavender desk, the frosted capsule of jump actions at the
// top, and one page at a time, turned with a swipe in the reading direction.
import { useEffect, useRef, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { useI18n } from "../../lib/i18n";
import { Icon } from "../../components/icons";
import { BottomSheet } from "../../components/BottomSheet";
import { ClayTag } from "../../components/clay";
import { Protected } from "../../components/Protected";
import type { Recipe } from "../../models/recipe";
import type { RecipeBook } from "../../models/book";
import { DIET_ICON, PHONE_DIET_TONE } from "../recipes/components/phone";
import { StorageImage } from "./shared/components";
import { useReducedMotion } from "./shared/hooks";

export interface PhoneBookActions {
  onBack: () => void;
  /** Null for a read-only copy (no "add to book"). */
  onAdd: (() => void) | null;
  /** Null for a read-only copy (no cover affordance). */
  onCover: (() => void) | null;
  /** Null for a read-only copy (no drag handles in quick nav). */
  onMove: ((from: number, to: number) => void) | null;
}

export function PhoneBookViewer({ book, recipes, who, page, onPage, actions }: { book: RecipeBook; recipes: Recipe[]; who: string; page: number; onPage: (p: number) => void; actions: PhoneBookActions }) {
  const { t, dir } = useI18n();
  const reduced = useReducedMotion();
  const [nav, setNav] = useState(false);
  const leaf = useRef<HTMLDivElement>(null);
  const last = useRef(page);
  const drag = useRef<{ x: number; y: number; dx: number; locked: boolean | null } | null>(null);
  const count = recipes.length + 1;

  // The page turn: the new leaf slides in from the side it was turned from (300 ms).
  useEffect(() => {
    const from = last.current;
    last.current = page;
    const el = leaf.current;
    if (!el || reduced || from === page || typeof el.animate !== "function") return;
    el.scrollTop = 0;
    const ahead = page > from ? 1 : -1;
    // RTL books turn to the right (isRightSwipe): the next page comes in from the left.
    const sign = (dir === "rtl" ? -1 : 1) * ahead;
    el.animate([{ transform: `translateX(${sign * 100}%)`, opacity: 0.4 }, { transform: "translateX(0)", opacity: 1 }], { duration: 300, easing: "cubic-bezier(.23,1,.32,1)" });
  }, [page, dir, reduced]);

  const turn = (forward: boolean) => {
    const next = page + (forward ? 1 : -1);
    if (next >= 0 && next < count) onPage(next);
  };

  // A horizontal swipe turns the page: toward the reading end = forward.
  const onPointerDown = (e: React.PointerEvent) => {
    if (e.pointerType === "mouse" && e.button !== 0) return;
    drag.current = { x: e.clientX, y: e.clientY, dx: 0, locked: null };
  };
  const onPointerMove = (e: React.PointerEvent) => {
    const d = drag.current;
    if (!d) return;
    const dx = e.clientX - d.x;
    const dy = e.clientY - d.y;
    if (d.locked === null && Math.hypot(dx, dy) > 10) d.locked = Math.abs(dx) > Math.abs(dy) * 1.2;
    d.dx = dx;
  };
  const onPointerUp = () => {
    const d = drag.current;
    drag.current = null;
    if (!d || !d.locked || Math.abs(d.dx) < 48) return;
    const towardEnd = dir === "rtl" ? d.dx > 0 : d.dx < 0;
    turn(towardEnd);
  };

  const pageNode: ReactNode =
    page === 0 ? <ContentsLeaf book={book} recipes={recipes} onOpen={(i) => onPage(i + 1)} onCover={actions.onCover} /> : recipes[page - 1] ? <RecipeLeaf recipe={recipes[page - 1]} number={page + 1} /> : null;

  return (
    <div className="fixed inset-0 z-[45] overflow-hidden bg-surface-low lg:hidden" style={{ background: "linear-gradient(to bottom right, rgb(var(--c-surface-container)), rgb(var(--c-surface-dim)))" }}>
      <div className="absolute inset-0" style={{ paddingTop: "env(safe-area-inset-top)", paddingBottom: "env(safe-area-inset-bottom)" }}>
        <div className="relative h-full">
          {/* The book: inset 16, below the capsule's 72 + 8, clipped to 16. */}
          <div className="absolute inset-x-4 bottom-4 top-20 overflow-hidden rounded-std bg-surface-bright" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onPointerCancel={() => (drag.current = null)} style={{ touchAction: "pan-y" }}>
            {/* BookPageSurface: the binding's shade on the start edge, padding 24 / 48 top. */}
            <span className="pointer-events-none absolute inset-y-0 start-0 z-[3] w-6 ltr:bg-gradient-to-r rtl:bg-gradient-to-l from-on-surface/[.06] to-transparent" aria-hidden="true" />
            <div ref={leaf} className="absolute inset-0 overflow-y-auto overscroll-contain" aria-live="polite">
              <Protected who={who}>
                <div className="flex min-h-[calc(100dvh-96px-env(safe-area-inset-top)-env(safe-area-inset-bottom))] flex-col px-6 pb-6 pt-12">{pageNode}</div>
              </Protected>
            </div>
          </div>

          {/* QuickJumpCapsule: frosted stadium at top 12, centred. */}
          <nav aria-label={t("library.contents")} className="absolute inset-x-0 top-3 flex justify-center px-4">
            <div className="flex items-center rounded-full border border-outline-variant/30 bg-surface/80 px-4 py-2 shadow-card backdrop-blur-md">
              <CapsuleButton icon="arrow_back" label={t("common.back")} onClick={actions.onBack} mirrored />
              <CapsuleButton icon="auto_stories" label={t("library.contents")} onClick={() => onPage(0)} divider />
              {actions.onAdd ? <CapsuleButton icon="add" label={t("library.addToBook")} onClick={actions.onAdd} divider /> : null}
              <CapsuleButton icon="grid_view" label={t("library.quickNav")} onClick={() => setNav(true)} divider />
            </div>
          </nav>
        </div>
      </div>

      <QuickNavSheet
        open={nav}
        recipes={recipes}
        onClose={() => setNav(false)}
        onPick={(i) => {
          setNav(false);
          onPage(i + 1);
        }}
        onMove={actions.onMove}
      />
    </div>
  );
}

function CapsuleButton({ icon, label, onClick, divider = false, mirrored = false }: { icon: string; label: string; onClick: () => void; divider?: boolean; mirrored?: boolean }) {
  return (
    <>
      {divider ? <span className="mx-3 h-6 w-px bg-outline-variant/50" aria-hidden="true" /> : null}
      <button type="button" onClick={onClick} className="press flex flex-col items-center gap-1 text-on-surface-variant">
        <Icon name={icon} size={20} className={mirrored ? "rtl:-scale-x-100" : ""} />
        <span className="whitespace-nowrap text-label-sm">{label}</span>
      </button>
    </>
  );
}

/** TableOfContentsPage: cover 140 r24, the title, the heading, dotted-leader rows. */
function ContentsLeaf({ book, recipes, onOpen, onCover }: { book: RecipeBook; recipes: Recipe[]; onOpen: (index: number) => void; onCover: (() => void) | null }) {
  const { t } = useI18n();
  const cover = (
    <span className="relative block h-[140px] w-full overflow-hidden rounded-md">
      <StorageImage
        path={book.coverImageStoragePath}
        className="h-full w-full object-cover"
        fallback={
          <span className="grid h-full w-full place-items-center bg-primary-fixed text-primary" aria-hidden="true">
            <Icon name="restaurant_menu" size={56} />
          </span>
        }
      />
      {onCover ? (
        <span className="absolute bottom-2 end-2 grid h-[34px] w-[34px] place-items-center rounded-full bg-surface-lowest text-primary" aria-hidden="true">
          <Icon name={book.coverImageStoragePath ? "edit" : "add_a_photo"} size={18} />
        </span>
      ) : null}
    </span>
  );
  return (
    <section aria-labelledby="toc-h">
      {onCover ? (
        <button type="button" className="press block w-full" onClick={onCover} aria-label={t("library.coverImage")}>
          {cover}
        </button>
      ) : (
        cover
      )}
      <h1 className="mt-6 text-headline-lg text-on-surface">{book.title || t("library.ui.untitled")}</h1>
      <PageHeading id="toc-h" className="mt-8">
        {t("library.contents")}
      </PageHeading>
      <div className="mt-6">
        {recipes.length === 0 ? (
          <p className="py-8 text-center text-body-md text-on-surface-variant">{t("library.emptyBook")}</p>
        ) : (
          <ol className="space-y-3">
            {recipes.map((r, i) => (
              <li key={r.id}>
                <button type="button" onClick={() => onOpen(i)} className="flex w-full items-end py-1 text-start">
                  <span className="min-w-0 shrink truncate text-body-md text-on-surface">{r.title || t("library.ui.untitled")}</span>
                  <span className="mx-2 mb-[9px] h-0.5 min-w-4 flex-1" style={{ backgroundImage: "radial-gradient(circle, rgb(var(--c-outline-variant)) 1px, transparent 1.2px)", backgroundSize: "6px 2px", backgroundRepeat: "repeat-x" }} aria-hidden="true" />
                  <span className="text-label-md text-primary" dir="ltr">
                    {i + 2}
                  </span>
                </button>
              </li>
            ))}
          </ol>
        )}
      </div>
    </section>
  );
}

function PageHeading({ id, className = "", children }: { id?: string; className?: string; children: ReactNode }) {
  return (
    <h2 id={id} className={`border-b-2 border-primary-fixed pb-2 text-headline-md text-primary ${className}`}>
      {children}
    </h2>
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

/** RecipeBookPage: photo 160 r24, title, topics, the two time tags, ingredients, steps, the page number. */
function RecipeLeaf({ recipe, number }: { recipe: Recipe; number: number }) {
  const { t } = useI18n();
  const duration = (m: number | null) => {
    if (m === null) return t("library.missingInfo");
    if (m < 60) return t("library.minutes", { n: m });
    const h = Math.floor(m / 60);
    return m % 60 === 0 ? t("library.hours", { n: h }) : t("library.hoursMinutes", { h, m: m % 60 });
  };
  const h = `rp-${recipe.id}`;
  return (
    <article aria-labelledby={h} className="flex min-h-full flex-1 flex-col">
      <div className="flex-1">
        {recipe.imageStoragePath ? (
          <StorageImage path={recipe.imageStoragePath} className="mb-4 h-40 w-full rounded-md object-cover" fallback={<span className="mb-4 block h-40 w-full rounded-md bg-primary-fixed" aria-hidden="true" />} />
        ) : null}
        <h1 id={h} className="text-headline-lg-mobile text-on-surface">
          <Link to={`/recipes/${recipe.id}`}>{recipe.title || t("library.ui.untitled")}</Link>
        </h1>
        {recipe.dietaryTags.length ? (
          <div className="mt-3 flex flex-wrap gap-2">
            {recipe.dietaryTags.map((tag) => (
              <ClayTag key={tag} icon={DIET_ICON[tag]} className={PHONE_DIET_TONE[tag]}>
                {t(`recipes.diet.${tag}`)}
              </ClayTag>
            ))}
          </div>
        ) : null}
        <div className="mt-3 flex flex-wrap gap-2">
          <ClayTag icon="timer">{`${t("library.prepTime")} · ${duration(recipe.prepTimeMinutes)}`}</ClayTag>
          <ClayTag icon="local_fire_department" className="bg-secondary-container text-on-secondary-container">
            {`${t("library.cookTime")} · ${duration(recipe.cookTimeMinutes)}`}
          </ClayTag>
        </div>
        <PageHeading className="mt-6">{t("library.ingredients")}</PageHeading>
        <ul className="mt-2">
          {recipe.ingredients.map((ing, i) => (
            <li key={i} className="flex items-start gap-3 py-1 text-body-md text-on-surface">
              <span className="mt-[9px] h-1.5 w-1.5 shrink-0 rounded-full bg-primary" aria-hidden="true" />
              <span>{[ing.amount === null ? t("library.missingInfo") : amount(ing.amount), ing.unit === "unspecified" ? "" : t(`unit.${ing.unit}`), ing.name].filter(Boolean).join(" ")}</span>
            </li>
          ))}
        </ul>
        <PageHeading className="mt-6">{t("library.instructions")}</PageHeading>
        <ol className="mt-2">
          {recipe.steps.map((s, i) => (
            <li key={i} className="flex items-start gap-3 py-2 text-body-md text-on-surface">
              <span className="grid h-[26px] w-[26px] shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary" aria-hidden="true">
                {i + 1}
              </span>
              <p className="min-w-0 flex-1">{s}</p>
            </li>
          ))}
        </ol>
      </div>
      <p className="pt-4 text-center text-label-sm text-outline" dir="ltr" aria-hidden="true">
        {number}
      </p>
    </article>
  );
}

/** QuickNavSheet: numbered rows (32 px page disc), a tap jumps, a drag handle reorders. */
function QuickNavSheet({ open, recipes, onClose, onPick, onMove }: { open: boolean; recipes: Recipe[]; onClose: () => void; onPick: (index: number) => void; onMove: ((from: number, to: number) => void) | null }) {
  const { t } = useI18n();
  const [dragging, setDragging] = useState<{ from: number; dy: number; y: number; h: number } | null>(null);
  const target = dragging ? Math.max(0, Math.min(recipes.length - 1, dragging.from + Math.round(dragging.dy / dragging.h))) : null;
  return (
    <BottomSheet open={open} onClose={onClose} title={t("library.quickNav")}>
      {onMove ? <p className="mb-4 text-label-md text-outline">{t("library.dragHint")}</p> : null}
      <ol className="space-y-2">
        {recipes.map((r, i) => {
          const lifted = dragging?.from === i;
          const shift = dragging && !lifted && target !== null ? (dragging.from < i && i <= target ? -dragging.h : target <= i && i < dragging.from ? dragging.h : 0) : 0;
          return (
            <li key={r.id} style={{ transform: lifted ? `translateY(${dragging!.dy}px)` : shift ? `translateY(${shift}px)` : undefined, transition: lifted ? "none" : "transform 180ms cubic-bezier(.23,1,.32,1)", position: "relative", zIndex: lifted ? 1 : undefined }}>
              <div className="clay-card flex items-center gap-3 p-3" style={{ borderRadius: 16 }}>
                <button type="button" onClick={() => onPick(i)} className="press flex min-w-0 flex-1 items-center gap-3 text-start">
                  <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary" dir="ltr">
                    {i + 2}
                  </span>
                  <span className="min-w-0 flex-1 truncate text-body-md">{r.title || t("library.ui.untitled")}</span>
                </button>
                {onMove ? (
                  <span
                    role="button"
                    tabIndex={0}
                    aria-label={t("library.moveDown", { title: r.title })}
                    className="cursor-grab touch-none p-1 text-outline"
                    onKeyDown={(e) => {
                      if (e.key === "ArrowDown" && i < recipes.length - 1) onMove(i, i + 1);
                      if (e.key === "ArrowUp" && i > 0) onMove(i, i - 1);
                    }}
                    onPointerDown={(e) => {
                      (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
                      const row = (e.currentTarget as HTMLElement).closest("li");
                      setDragging({ from: i, dy: 0, y: e.clientY, h: (row?.offsetHeight ?? 56) + 8 });
                    }}
                    onPointerMove={(e) => setDragging((d) => (d ? { ...d, dy: e.clientY - d.y } : d))}
                    onPointerUp={() => {
                      if (dragging && target !== null && target !== dragging.from) onMove(dragging.from, target);
                      setDragging(null);
                    }}
                    onPointerCancel={() => setDragging(null)}
                  >
                    <Icon name="drag_handle" size={24} />
                  </span>
                ) : null}
              </div>
            </li>
          );
        })}
      </ol>
    </BottomSheet>
  );
}
