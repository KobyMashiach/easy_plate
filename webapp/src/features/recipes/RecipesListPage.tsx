// /recipes — MyRecipesPage on a wide screen: the account's recipes, live,
// as a photo-card grid. "Mine" / "Saved" like the app's segments; search on
// the title and the topic chips (every chosen topic must match) exactly as
// MyRecipesBloc filters, plus the web's extra narrowing: allergens the
// recipe must be free of, shared-with-me, source, and the sort order.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useCollection } from "../../lib/cloud";
import { useTranslatedList } from "../../lib/contentTranslation";
import { useI18n } from "../../lib/i18n";
import { deleteRecipe } from "../../lib/recipesStore";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { ClayButton, ClayCard, ClayIconButton, EmptyState, LoadingSpinner, SegmentedControl } from "../../components/clay";
import { FloatingHeaderView } from "../../components/FloatingHeaderView";
import { useIsPhone } from "../../components/useIsPhone";
import { useAccess } from "../../lib/flags";
import { CHANNELS, normalizeRecipe, type Allergen, type DietaryPreference, type IngestionChannel, type Recipe } from "../../models/recipe";
import { AllergenChips, DietaryChips } from "./components/Chips";
import { ConfirmDialog, Toast } from "./components/Modal";
import { RecipeImage } from "./components/RecipeImage";
import { DIET_TONE, durationLabel, isMine, kcalNumber, roleLabel, totalMinutes } from "./lib/format";
import { DIET_ICON, PHONE_DIET_TONE, PhoneDietaryChips, PhoneTag, SearchPill } from "./components/phone";

type Sort = "newest" | "az";
const PAGE = 24;

export function RecipesListPage() {
  const { t, locale } = useI18n();
  const { user } = useAuth();
  const live = useCollection<unknown>("recipes", user?.uid);
  const stored = useMemo(() => (live.items ? live.items.map(normalizeRecipe).filter((r) => r.id) : null), [live.items]);
  // Shown (and searched) in the language on screen; only a delete is done from here.
  const all = useTranslatedList("recipe", stored);

  const [savedTab, setSavedTab] = useState(false);
  const [query, setQuery] = useState("");
  const [diet, setDiet] = useState<DietaryPreference[]>([]);
  const [freeOf, setFreeOf] = useState<Allergen[]>([]);
  const [sharedOnly, setSharedOnly] = useState(false);
  const [source, setSource] = useState<IngestionChannel | "">("");
  const [sort, setSort] = useState<Sort>("newest");
  const [showFilters, setShowFilters] = useState(false);
  const [limit, setLimit] = useState(PAGE);
  const [removing, setRemoving] = useState<Recipe | null>(null);
  const [busy, setBusy] = useState(false);
  const [toast, setToast] = useState<{ text: string; kind: "success" | "error" } | null>(null);

  const phone = useIsPhone();
  const collator = useMemo(() => new Intl.Collator(locale, { sensitivity: "base", numeric: true }), [locale]);

  const visible = useMemo(() => {
    if (!all) return null;
    const q = query.trim().toLowerCase();
    const list = all.filter((r) => {
      if ((r.savedFromSharedId !== null) !== savedTab) return false;
      if (q && !r.title.toLowerCase().includes(q)) return false;
      if (diet.length && !diet.every((d) => r.dietaryTags.includes(d))) return false;
      if (freeOf.length && freeOf.some((a) => r.allergens.includes(a) || r.mayContain.includes(a))) return false;
      if (sharedOnly && !(r.collabRole === "editor" || r.collabRole === "viewer")) return false;
      if (source && r.sourceChannel !== source) return false;
      return true;
    });
    list.sort(sort === "az" ? (a, b) => collator.compare(a.title, b.title) : (a, b) => b.createdAt.localeCompare(a.createdAt));
    return list;
  }, [all, savedTab, query, diet, freeOf, sharedOnly, source, sort, collator]);

  // A new search or filter starts from the top of the list again.
  useEffect(() => setLimit(PAGE), [savedTab, query, diet, freeOf, sharedOnly, source, sort]);

  // Cards are added a page at a time as the end of the grid comes into view.
  const sentinel = useRef<HTMLDivElement>(null);
  const total = visible?.length ?? 0;
  useEffect(() => {
    const el = sentinel.current;
    if (!el || limit >= total) return;
    const io = new IntersectionObserver((entries) => {
      if (entries.some((e) => e.isIntersecting)) setLimit((n) => n + PAGE);
    }, { rootMargin: "600px" });
    io.observe(el);
    return () => io.disconnect();
  }, [limit, total]);

  const filterCount = diet.length + freeOf.length + (sharedOnly ? 1 : 0) + (source ? 1 : 0);
  const clearFilters = () => {
    setDiet([]);
    setFreeOf([]);
    setSharedOnly(false);
    setSource("");
  };
  const toggle = <X,>(list: X[], x: X) => (list.includes(x) ? list.filter((y) => y !== x) : [...list, x]);

  const confirmRemove = async () => {
    if (!removing || busy) return;
    setBusy(true);
    try {
      await deleteRecipe(removing);
      setRemoving(null);
    } catch (_) {
      setToast({ text: t("recipes.error"), kind: "error" });
    } finally {
      setBusy(false);
    }
  };
  const clearToast = useCallback(() => setToast(null), []);
  const navigate = useNavigate();
  const shareAccess = useAccess("ff_share_recipes");

  const desktopHeader = (
      <header className="mb-6 flex flex-wrap items-end gap-4 animate-rise">
        <div className="min-w-0 flex-1">
          <h1 className="text-headline-lg">{t("recipes.pageTitle")}</h1>
          <p className="mt-1 text-body-md text-on-surface-variant">{t("recipes.subtitle")}</p>
        </div>
        <div className="flex gap-2">
          <Link to="/recipes/new" className="clay-btn-tonal">
            <Icon name="edit" size={18} />
            {t("recipes.ch.manual")}
          </Link>
          <Link to="/add" className="clay-btn-primary">
            <Icon name="assistant" size={18} />
            {t("recipes.addRecipe")}
          </Link>
        </div>
      </header>
  );

  const empty = visible !== null && visible.length === 0;
  const anyInTab = !!all && all.some((r) => (r.savedFromSharedId !== null) === savedTab);

  return (
    <FloatingHeaderView
      title={t("recipes.pageTitle")}
      subtitle={t("recipes.subtitle")}
      actions={<ClayIconButton size={48} filled icon="auto_awesome" label={t("recipes.addRecipe")} to="/add" />}
      actionCount={1}
      desktopHeader={desktopHeader}
    >
      {phone ? (
        <>
          <SegmentedControl
            label={t("recipes.pageTitle")}
            value={savedTab ? "saved" : "mine"}
            onChange={(v) => setSavedTab(v === "saved")}
            segments={[
              { value: "mine", label: t("recipes.mine"), icon: "edit_note" },
              { value: "saved", label: t("recipes.saved"), icon: "bookmark" },
            ]}
          />
          <ClayCard radius={24} padding={16} as="section" className="mt-8" aria-label={t("recipes.filters")}>
            <SearchPill id="rq" value={query} onChange={setQuery} placeholder={t("recipes.search")} />
            <p className="mt-4 text-label-sm text-on-surface-variant">{t("recipes.topics")}</p>
            <div className="mt-2">
              <PhoneDietaryChips selected={diet} onToggle={(d) => setDiet((l) => toggle(l, d))} label={t("recipes.topics")} />
            </div>
          </ClayCard>
          <div className="h-8" />
        </>
      ) : null}
      {phone ? null : (
      <>
      <div role="group" aria-label={t("recipes.pageTitle")} className="mb-4 inline-flex rounded-full bg-surface-low p-1 shadow-control">
        {[false, true].map((saved) => (
          <button
            key={String(saved)}
            type="button"
            aria-pressed={savedTab === saved}
            onClick={() => setSavedTab(saved)}
            className={`inline-flex items-center gap-2 rounded-full px-5 py-2 text-label-md transition-colors ${savedTab === saved ? "bg-primary text-on-primary" : "text-tertiary hover:bg-primary/10"}`}
          >
            <Icon name={saved ? "heart" : "recipes"} size={18} />
            {saved ? t("recipes.saved") : t("recipes.mine")}
          </button>
        ))}
      </div>

      <section className="clay mb-6 space-y-4 p-4" aria-label={t("recipes.filters")}>
        <div className="flex flex-wrap gap-3">
          <div className="relative min-w-[14rem] flex-1">
            <label htmlFor="rq" className="sr-only">
              {t("recipes.search")}
            </label>
            <span className="pointer-events-none absolute inset-y-0 start-4 grid place-items-center text-outline" aria-hidden="true">
              <Icon name="search" size={20} />
            </span>
            <input id="rq" type="search" className="clay-input ps-12" placeholder={t("recipes.search")} value={query} onChange={(e) => setQuery(e.target.value)} />
          </div>
          <div className="flex items-center gap-2">
            <label htmlFor="rsort" className="text-label-md text-on-surface-variant">
              {t("recipes.sort")}
            </label>
            <select id="rsort" className="clay-input w-auto" value={sort} onChange={(e) => setSort(e.target.value as Sort)}>
              <option value="newest">{t("recipes.sortNewest")}</option>
              <option value="az">{t("recipes.sortAz")}</option>
            </select>
          </div>
          <button type="button" className="clay-btn-ghost" aria-expanded={showFilters} aria-controls="rfilters" onClick={() => setShowFilters((v) => !v)}>
            <Icon name="filter" size={18} />
            {t("recipes.filters")}
            {filterCount ? <span className="rounded-full bg-primary px-2 text-label-sm text-on-primary">{filterCount}</span> : null}
          </button>
        </div>
        <div>
          <p className="mb-2 text-label-sm text-on-surface-variant">{t("recipes.topics")}</p>
          <DietaryChips selected={diet} onToggle={(d) => setDiet((l) => toggle(l, d))} label={t("recipes.topics")} />
        </div>
        {showFilters ? (
          <div id="rfilters" className="grid gap-4 border-t border-outline-variant/40 pt-4 lg:grid-cols-[2fr_1fr]">
            <div>
              <p className="mb-2 text-label-sm text-on-surface-variant">{t("recipes.freeOf")}</p>
              <AllergenChips selected={freeOf} onToggle={(a) => setFreeOf((l) => toggle(l, a))} label={t("recipes.freeOf")} />
            </div>
            <div className="space-y-3">
              <label className="flex items-center gap-3 text-body-md">
                <input type="checkbox" className="h-5 w-5 accent-[rgb(var(--c-primary))]" checked={sharedOnly} onChange={(e) => setSharedOnly(e.target.checked)} />
                {t("recipes.sharedWithMe")}
              </label>
              <div className="space-y-1.5">
                <label htmlFor="rsrc" className="block text-label-sm text-on-surface-variant">
                  {t("recipes.source")}
                </label>
                <select id="rsrc" className="clay-input" value={source} onChange={(e) => setSource(e.target.value as IngestionChannel | "")}>
                  <option value="">{t("recipes.sourceAny")}</option>
                  {CHANNELS.map((c) => (
                    <option key={c} value={c}>
                      {t(`recipes.ch.${c}`)}
                    </option>
                  ))}
                </select>
              </div>
              {filterCount ? (
                <button type="button" className="clay-btn-ghost w-full" onClick={clearFilters}>
                  {t("recipes.clearFilters")}
                </button>
              ) : null}
            </div>
          </div>
        ) : null}
      </section>
      </>
      )}

      {phone && live.error && !all ? (
        <ClayCard radius={24} padding={24} className="m-6 flex flex-col items-center text-center" role="alert">
          <span className="grid h-16 w-16 place-items-center rounded-full bg-error-container text-on-error-container" aria-hidden="true">
            <Icon name="error_outline" size={32} />
          </span>
          <p className="mt-4 text-label-md text-on-surface-variant">{t("recipes.loadFailed")}</p>
          <ClayButton icon="refresh" className="mt-4" onClick={() => location.reload()}>
            {t("recipes.retry")}
          </ClayButton>
        </ClayCard>
      ) : phone && visible === null ? (
        <LoadingSpinner label={t("common.loading")} />
      ) : phone && empty ? (
        <EmptyState
          icon={anyInTab ? "search_off" : savedTab ? "bookmark_border" : "restaurant_menu"}
          message={anyInTab ? t("recipes.noMatches") : savedTab ? t("recipes.noneSaved") : t("recipes.noneMine")}
          action={
            anyInTab ? (
              <ClayButton
                icon="refresh"
                onClick={() => {
                  clearFilters();
                  setQuery("");
                }}
              >
                {t("recipes.clearFilters")}
              </ClayButton>
            ) : savedTab ? undefined : (
              <ClayButton icon="add" onClick={() => navigate("/add")}>
                {t("recipes.addRecipe")}
              </ClayButton>
            )
          }
        />
      ) : phone && visible ? (
        <>
          <p className="sr-only" aria-live="polite">
            {t("recipes.total", { n: visible.length })}
          </p>
          <ul className="grid grid-cols-2 gap-3">
            {visible.slice(0, limit).map((r) => (
              <li key={r.id}>
                <PhoneRecipeCard
                  recipe={r}
                  onRemove={r.savedFromSharedId !== null ? () => setRemoving(r) : null}
                  onShare={isMine(r) && shareAccess === "enabled" ? () => navigate(`/sharing/share?kind=recipe&id=${encodeURIComponent(r.id)}`) : null}
                />
              </li>
            ))}
          </ul>
          <div ref={sentinel} aria-hidden="true" className="h-4" />
        </>
      ) : live.error && !all ? (
        <div className="clay p-6 text-center" role="alert">
          <p className="text-body-md">{t("recipes.loadFailed")}</p>
          <button type="button" className="clay-btn-tonal mt-4" onClick={() => location.reload()}>
            {t("recipes.retry")}
          </button>
        </div>
      ) : visible === null ? (
        <div className="py-16 text-center">
          <Spinner label={t("common.loading")} />
        </div>
      ) : visible.length === 0 ? (
        <div className="clay mx-auto max-w-lg space-y-4 p-10 text-center">
          <span className="mx-auto grid h-16 w-16 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed-variant" aria-hidden="true">
            <Icon name={savedTab ? "heart" : "cook"} size={30} />
          </span>
          {all && all.some((r) => (r.savedFromSharedId !== null) === savedTab) ? (
            <>
              <p className="text-body-md">{t("recipes.noMatches")}</p>
              <button
                type="button"
                className="clay-btn-tonal"
                onClick={() => {
                  clearFilters();
                  setQuery("");
                }}
              >
                {t("recipes.clearFilters")}
              </button>
            </>
          ) : (
            <>
              <p className="text-body-md">{savedTab ? t("recipes.noneSaved") : t("recipes.noneMine")}</p>
              {savedTab ? null : (
                <Link to="/add" className="clay-btn-primary">
                  <Icon name="add" size={18} />
                  {t("recipes.addRecipe")}
                </Link>
              )}
            </>
          )}
        </div>
      ) : (
        <>
          <p className="sr-only" aria-live="polite">
            {t("recipes.total", { n: visible.length })}
          </p>
          <ul className="grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
            {visible.slice(0, limit).map((r) => (
              <li key={r.id}>
                <RecipeCard recipe={r} onRemove={r.savedFromSharedId !== null ? () => setRemoving(r) : null} />
              </li>
            ))}
          </ul>
          <div ref={sentinel} aria-hidden="true" className="h-4" />
        </>
      )}

      <ConfirmDialog
        open={removing !== null}
        title={t("recipes.removeSaved")}
        message={t("recipes.removeSavedConfirm")}
        confirmLabel={t("recipes.delete")}
        icon="bookmark_remove"
        destructive
        busy={busy}
        onConfirm={() => void confirmRemove()}
        onCancel={() => setRemoving(null)}
      />
      <Toast message={toast?.text ?? null} kind={toast?.kind} onDone={clearToast} />
    </FloatingHeaderView>
  );
}

function RecipeCard({ recipe, onRemove }: { recipe: Recipe; onRemove: (() => void) | null }) {
  const { t } = useI18n();
  const minutes = totalMinutes(recipe);
  const kcal = recipe.nutrition?.calories;
  const role = roleLabel(t, recipe.collabRole);
  const chips: { label: string; cls: string }[] = [];
  if (recipe.pendingAnalysis) chips.push({ label: t("recipes.pendingAnalysis"), cls: "bg-secondary-container text-on-secondary-container" });
  else if (role) chips.push({ label: role, cls: "bg-secondary-container text-on-secondary-container" });
  for (const tag of recipe.dietaryTags) {
    if (chips.length >= 2) break;
    chips.push({ label: t(`recipes.diet.${tag}`), cls: DIET_TONE[tag] });
  }
  if (!chips.length) chips.push({ label: t("recipes.ingredientsCount", { count: recipe.ingredients.length }), cls: "bg-surface-low text-tertiary" });

  return (
    <article className="clay group relative flex h-full flex-col p-2 transition-transform hover:-translate-y-0.5">
      <div className="relative aspect-[4/3] overflow-hidden rounded-std">
        <RecipeImage path={recipe.imageStoragePath} className="h-full w-full transition-transform duration-300 group-hover:scale-[1.03]" />
        {kcal !== undefined ? (
          <span className="absolute end-2 top-2 rounded-full bg-warm-accent px-2 py-0.5 text-label-sm text-on-warm-accent" dir="ltr">
            {kcalNumber(kcal)} {t("recipes.nut.kcal")}
          </span>
        ) : null}
        {minutes > 0 ? (
          <span className="absolute bottom-2 start-2 inline-flex items-center gap-1 rounded-full bg-surface-lowest/90 px-2 py-0.5 text-label-sm text-on-surface">
            <Icon name="timer" size={14} />
            {durationLabel(t, minutes)}
          </span>
        ) : null}
      </div>
      <h2 className="mt-2 line-clamp-2 px-1 text-body-md font-bold leading-tight">
        <Link to={`/recipes/${recipe.id}`} className="after:absolute after:inset-0 after:rounded-md focus-visible:outline-none focus-visible:after:ring-4 focus-visible:after:ring-primary" aria-label={t("recipes.openRecipe", { title: recipe.title })}>
          {recipe.title}
        </Link>
      </h2>
      <div className="mt-auto flex flex-wrap gap-1 overflow-hidden px-1 pb-1 pt-2" style={{ maxHeight: "2.25rem" }}>
        {chips.map((c) => (
          <span key={c.label} className={`pill whitespace-nowrap ${c.cls}`}>
            {c.label}
          </span>
        ))}
      </div>
      {onRemove ? (
        <button type="button" onClick={onRemove} className="absolute start-3 top-3 z-10 grid h-9 w-9 place-items-center rounded-full bg-surface-lowest/90 text-error shadow-control" aria-label={t("recipes.removeSaved")} title={t("recipes.removeSaved")}>
          <Icon name="trash" size={16} />
        </button>
      ) : null}
    </article>
  );
}

/**
 * RecipeCard below lg: ClayCard r24 p8, fixed 248 tall; a 136 photo (r16)
 * with the kcal pill (top-end) and the time pill (bottom-start), the title
 * (bodyMd w700, two lines), and one 26 px row of tags. Long-press shares
 * (own recipes); a saved copy carries the remove button.
 */
function PhoneRecipeCard({ recipe, onRemove, onShare }: { recipe: Recipe; onRemove: (() => void) | null; onShare: (() => void) | null }) {
  const { t } = useI18n();
  const minutes = totalMinutes(recipe);
  const kcal = recipe.nutrition?.calories;
  const role = roleLabel(t, recipe.collabRole);
  const press = useRef<{ timer: number; fired: boolean } | null>(null);

  const chips: { label: string; cls: string; icon: string }[] = [];
  if (recipe.pendingAnalysis) chips.push({ label: t("recipes.pendingAnalysis"), cls: "bg-secondary-container text-on-secondary-container", icon: "hourglass_top" });
  else if (role) chips.push({ label: role, cls: "bg-secondary-container text-on-secondary-container", icon: "group" });
  for (const tag of recipe.dietaryTags) {
    if (chips.length >= 2) break;
    chips.push({ label: t(`recipes.diet.${tag}`), cls: PHONE_DIET_TONE[tag], icon: DIET_ICON[tag] });
  }
  if (!chips.length) chips.push({ label: t("recipes.ingredientsCount", { count: recipe.ingredients.length }), cls: "bg-surface-low text-tertiary", icon: "list_alt" });

  const startPress = () => {
    if (!onShare) return;
    const p = { timer: 0, fired: false };
    p.timer = window.setTimeout(() => {
      p.fired = true;
      navigator.vibrate?.(10);
      onShare();
    }, 500);
    press.current = p;
  };
  const endPress = () => {
    if (press.current) window.clearTimeout(press.current.timer);
  };

  const badge = "inline-flex items-center gap-[3px] rounded-full px-2 py-1 text-label-sm font-extrabold";
  return (
    <article
      className="clay-card press relative flex h-[248px] flex-col"
      style={{ borderRadius: 24, padding: 8 }}
      onPointerDown={startPress}
      onPointerUp={endPress}
      onPointerLeave={endPress}
      onPointerCancel={endPress}
      onContextMenu={onShare ? (e) => e.preventDefault() : undefined}
      onClickCapture={(e) => {
        if (press.current?.fired) {
          e.preventDefault();
          e.stopPropagation();
          press.current = null;
        }
      }}
    >
      <div className="relative h-[136px] shrink-0 overflow-hidden rounded-std">
        <RecipeImage path={recipe.imageStoragePath} className="h-full w-full" iconSize={40} fallbackIcon="restaurant_menu" fallbackClassName="bg-primary-fixed text-primary" />
        {kcal !== undefined ? (
          <span className={`absolute end-2 top-2 bg-warm-accent text-on-warm-accent ${badge}`}>
            <Icon name="bolt" size={13} />
            <span dir="ltr">{kcalNumber(kcal)}</span> {t("recipes.nut.kcal")}
          </span>
        ) : null}
        {minutes > 0 ? (
          <span className={`absolute bottom-2 start-2 bg-surface-lowest/90 text-on-surface ${badge}`}>
            <Icon name="timer" size={13} />
            {durationLabel(t, minutes)}
          </span>
        ) : null}
      </div>
      <h2 className="mt-3 line-clamp-2 min-h-0 flex-1 text-body-md font-bold leading-[1.25]">
        <Link
          to={`/recipes/${recipe.id}`}
          draggable={false}
          className="select-none after:absolute after:inset-0 after:rounded-md focus-visible:outline-none focus-visible:after:ring-4 focus-visible:after:ring-primary [-webkit-touch-callout:none]"
          aria-label={t("recipes.openRecipe", { title: recipe.title })}
        >
          {recipe.title}
        </Link>
      </h2>
      <div className="mt-2 flex h-[26px] shrink-0 items-center gap-1 overflow-hidden">
        {chips.map((c) => (
          <PhoneTag key={c.label} icon={c.icon} className={c.cls}>
            {c.label}
          </PhoneTag>
        ))}
      </div>
      {onRemove ? (
        <button
          type="button"
          onClick={onRemove}
          className="press-icon absolute start-3 top-3 z-10 grid h-10 w-10 place-items-center rounded-full bg-surface-lowest/90 text-error"
          aria-label={t("recipes.removeSaved")}
          title={t("recipes.removeSaved")}
        >
          <Icon name="bookmark_remove" size={18} />
        </button>
      ) : null}
    </article>
  );
}
