// The community feed of shared recipes (the app's SharedRecipesPage + its
// bloc): the newest fifty, with "mine" and "saved" reaching past them;
// search, sort and filters applied locally (SharedFeedQuery); like, save to
// my recipes, publish one of mine, update or remove my own post.
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { useFlags } from "../../../lib/flags";
import { useCollection } from "../../../lib/cloud";
import { DIETARY, normalizeRecipe, type DietaryPreference, type Recipe } from "../../../models/recipe";
import { Icon } from "../../../components/icons";
import { isMine } from "../../sharing/data/collabRecipes";
import { useConfirm, useNotices, Modal } from "../../sharing/ui/dialogs";
import { Empty, ErrorState, Glyph, Loading, StorageImage } from "../../sharing/ui/bits";
import { getByIds, getFeed, getMine, importShared, publishRecipe, toggleLike, unshare, updateShared, type SharedPost } from "../data/sharedRecipes";
import { freeViewsLeft, openSharedAllowed } from "../data/usage";
import { AuthorRow, LikeButton, RecipePickerModal, useIngredientLine } from "./common";
import { InCommunityHeader } from "./headerSlot";
import { useIsPhone } from "../../../components/useIsPhone";
import { usePullToRefresh } from "../../../components/PullToRefresh";
import { PageFab } from "../../../components/FloatingActions";
import { usePhoneNavigate } from "../../../components/pageTransition";
import { BottomSheet } from "../../../components/BottomSheet";
import { ClayButton, ClayTag, Chip as ClayChip } from "../../../components/clay";

type Scope = "all" | "mine" | "saved";
type Sort = "newest" | "oldest" | "mostLiked";
type Bucket = "any" | "upTo30" | "upTo60" | "upTo120" | "over120";
const BUCKETS: Bucket[] = ["any", "upTo30", "upTo60", "upTo120", "over120"];
const LIKE_STEPS = [0, 10, 20, 30, 50, 100];

interface Filters {
  sort: Sort;
  topics: DietaryPreference[];
  minLikes: number;
  totalTime: Bucket;
}
const NO_FILTERS: Filters = { sort: "newest", topics: [], minLikes: 0, totalTime: "any" };

/** TimeBucket.matches: a recipe that states no time is excluded by every bucket but "any". */
function bucketMatches(b: Bucket, minutes: number | null): boolean {
  if (b === "any") return true;
  if (minutes === null) return false;
  return b === "upTo30" ? minutes <= 30 : b === "upTo60" ? minutes <= 60 : b === "upTo120" ? minutes <= 120 : minutes > 120;
}

export function SharedFeed() {
  const { t, lang } = useI18n();
  const { user, premium } = useAuth();
  const flags = useFlags();
  const uid = user?.uid ?? "";
  const navigate = usePhoneNavigate();
  const line = useIngredientLine();
  const { items: rawRecipes } = useCollection<unknown>("recipes", uid);
  const myRecipes = useMemo(() => (rawRecipes ? rawRecipes.map(normalizeRecipe) : null), [rawRecipes]);
  const savedIds = useMemo(() => new Set((myRecipes ?? []).map((r) => r.savedFromSharedId).filter((x): x is string => x !== null)), [myRecipes]);

  const [feed, setFeed] = useState<SharedPost[] | null>(null);
  const [older, setOlder] = useState<SharedPost[]>([]);
  const [failed, setFailed] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [scope, setScope] = useState<Scope>("all");
  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState<Filters>(NO_FILTERS);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [freeLeft, setFreeLeft] = useState<number | null>(null);
  const [confirmUi, confirm] = useConfirm();
  const { ui: noticeUi, notify, alert } = useNotices();

  const mineFetched = useRef(false);
  const askedSaved = useRef(new Set<string>());
  const feedRef = useRef<SharedPost[]>([]);
  const olderRef = useRef<SharedPost[]>([]);
  feedRef.current = feed ?? [];
  olderRef.current = older;

  const quotaCfg = useMemo(() => ({ premium, number: flags.number, string: flags.string }), [premium, flags]);
  useEffect(() => {
    let live = true;
    freeViewsLeft(uid, quotaCfg)
      .then((n) => live && setFreeLeft(n))
      .catch(() => live && setFreeLeft(null));
    return () => {
      live = false;
    };
  }, [uid, quotaCfg]);

  /** The viewer's posts for "mine" (once per load), the saved posts past the window for "saved". */
  const fetchOlder = useCallback(
    async (which: Scope, refresh = false) => {
      if (!uid || which === "all") return;
      const shown = new Set([...feedRef.current, ...olderRef.current].map((p) => p.id));
      // A reload (or another account) meanwhile resets what was fetched:
      // this answer then belongs to the old load and is dropped.
      const seq = loadSeq.current;
      try {
        let fetched: SharedPost[] = [];
        if (which === "mine") {
          if (mineFetched.current) return;
          mineFetched.current = true;
          fetched = await getMine(uid, refresh);
        } else {
          const missing = [...savedIds].filter((id) => !shown.has(id) && !askedSaved.current.has(id));
          missing.forEach((id) => askedSaved.current.add(id));
          if (!missing.length) return;
          fetched = await getByIds(missing, uid, refresh);
        }
        if (seq !== loadSeq.current) return;
        setOlder((prev) => {
          const now = new Set([...feedRef.current, ...prev].map((p) => p.id));
          const added = fetched.filter((p) => !now.has(p.id));
          return added.length ? [...prev, ...added] : prev;
        });
      } catch (_) {
        if (which === "mine" && seq === loadSeq.current) mineFetched.current = false;
      }
    },
    [uid, savedIds],
  );

  // Newer loads win, and nothing lands after the page is gone (or another account signed in).
  const loadSeq = useRef(0);
  useEffect(
    () => () => {
      loadSeq.current++;
    },
    [uid],
  );
  const load = useCallback(
    async (refresh = false) => {
      if (!uid) return;
      const mine = ++loadSeq.current;
      setRefreshing(true);
      try {
        const next = await getFeed(uid, refresh);
        if (mine !== loadSeq.current) return;
        feedRef.current = next;
        olderRef.current = [];
        mineFetched.current = false;
        askedSaved.current.clear();
        setFeed(next);
        setOlder([]);
        setFailed(false);
      } catch (_) {
        if (mine !== loadSeq.current) return;
        setFailed(true);
        if (feedRef.current.length) notify(t("community.loadFailed"), "error");
      } finally {
        if (mine === loadSeq.current) setRefreshing(false);
      }
    },
    [uid, notify, t],
  );

  useEffect(() => {
    void load();
  }, [load]);

  // The open scope's posts, after each load and whenever the saved set moves.
  useEffect(() => {
    if (feed) void fetchOlder(scope);
  }, [feed, scope, fetchOlder]);

  const replace = (id: string, change: (p: SharedPost) => SharedPost) => {
    setFeed((f) => (f ? f.map((p) => (p.id === id ? change(p) : p)) : f));
    setOlder((o) => o.map((p) => (p.id === id ? change(p) : p)));
  };

  // One like at a time: two quick taps must not both read the row before either write lands.
  const likeChain = useRef<Promise<void>>(Promise.resolve());
  const like = (post: SharedPost) => {
    likeChain.current = likeChain.current.then(async () => {
      const original = [...feedRef.current, ...olderRef.current].find((p) => p.id === post.id);
      if (!original) return;
      replace(post.id, () => ({ ...original, likedByMe: !original.likedByMe, likeCount: original.likeCount + (original.likedByMe ? -1 : 1) }));
      try {
        await toggleLike(post.id, uid);
      } catch (_) {
        // Only the like is undone, on the row as it is now (an update in between stays).
        replace(post.id, (row) => (row.likedByMe === original.likedByMe ? row : { ...row, likedByMe: original.likedByMe, likeCount: row.likeCount + (row.likedByMe ? -1 : 1) }));
      }
    });
  };

  const save = async (post: SharedPost) => {
    if (busy) return;
    setBusy(true);
    try {
      const outcome = await importShared(post, lang);
      notify(outcome === "saved" ? t("community.savedToMyRecipes") : t("community.alreadySaved"));
    } catch (_) {
      alert(t("community.importFailed"));
    } finally {
      setBusy(false);
    }
  };

  // A second tap while the day's count is being written would open (and count) twice.
  const opening = useRef(false);
  const open = async (post: SharedPost) => {
    if (opening.current) return;
    opening.current = true;
    try {
      const allowed = await openSharedAllowed(post.id, post.authorUid, uid, quotaCfg);
      if (!allowed) {
        alert(t("community.ui.quotaReached"));
        return;
      }
    } catch (_) {
      // The count could not be read: the recipe opens rather than being refused for our failure.
    } finally {
      opening.current = false;
    }
    navigate(`/community/recipe/${encodeURIComponent(post.id)}`, { state: { post } });
  };

  const publish = async (recipe: Recipe) => {
    if (busy) return;
    setBusy(true);
    try {
      await publishRecipe(recipe, lang);
      setPickerOpen(false);
      notify(t("community.ui.published"));
      await load();
    } catch (_) {
      alert(t("community.shareFailed"));
    } finally {
      setBusy(false);
    }
  };

  const remove = async (post: SharedPost) => {
    const ok = await confirm({ title: t("community.unshare"), body: t("community.unshareConfirm"), confirmLabel: t("sharing.ui.delete"), destructive: true });
    if (!ok) return;
    setBusy(true);
    try {
      await unshare(post.id, lang);
      setFeed((f) => (f ? f.filter((p) => p.id !== post.id) : f));
      setOlder((o) => o.filter((p) => p.id !== post.id));
    } catch (_) {
      alert(t("community.unshareFailed"));
    } finally {
      setBusy(false);
    }
  };

  /** The app's "update both": my recipe's current version over the post. */
  const updateFromMine = async (post: SharedPost) => {
    const local = (myRecipes ?? []).find((r) => r.sharedRecipeId === post.id);
    if (!local) {
      alert(t("community.ui.noLocalCopy"));
      return;
    }
    const ok = await confirm({ title: t("community.editShared"), body: t("community.ui.updateFromMineBody", { title: local.title }), confirmLabel: t("community.ui.updateFromMine") });
    if (!ok) return;
    setBusy(true);
    try {
      await updateShared(post.id, local);
      replace(post.id, (p) => ({ ...p, recipe: { ...local, id: p.id } }));
      notify(t("community.sharedUpdated"));
    } catch (_) {
      alert(t("community.updateFailed"));
    } finally {
      setBusy(false);
    }
  };

  const visible = useMemo(() => {
    const all = scope === "all" ? feed ?? [] : [...(feed ?? []), ...older];
    const needle = search.trim().toLowerCase();
    const out = all.filter((p) => {
      if (scope === "mine" && p.authorUid !== uid) return false;
      if (scope === "saved" && !savedIds.has(p.id)) return false;
      if (needle && !p.recipe.title.toLowerCase().includes(needle) && !p.authorName.toLowerCase().includes(needle)) return false;
      if (!filters.topics.every((tag) => p.recipe.dietaryTags.includes(tag))) return false;
      if (p.likeCount < filters.minLikes) return false;
      const prep = p.recipe.prepTimeMinutes;
      const cook = p.recipe.cookTimeMinutes;
      const total = prep === null && cook === null ? null : (prep ?? 0) + (cook ?? 0);
      return bucketMatches(filters.totalTime, total);
    });
    out.sort((a, b) =>
      filters.sort === "oldest" ? a.createdAtMs - b.createdAtMs : filters.sort === "mostLiked" ? b.likeCount - a.likeCount || b.createdAtMs - a.createdAtMs : b.createdAtMs - a.createdAtMs,
    );
    return out;
  }, [scope, feed, older, search, filters, uid, savedIds]);

  const narrowed = filters.topics.length > 0 || filters.minLikes > 0 || filters.totalTime !== "any";
  const filtering = narrowed || search.trim() !== "";
  const shareable = useMemo(() => (myRecipes ? myRecipes.filter(isMine) : null), [myRecipes]);
  const phone = useIsPhone();
  const pull = usePullToRefresh(() => load(true), { enabled: phone });

  const pickers = (
    <>
      <FiltersModal open={filtersOpen} value={filters} onClose={() => setFiltersOpen(false)} onApply={(f) => (setFilters(f), setFiltersOpen(false))} />
      <RecipePickerModal
        open={pickerOpen}
        onClose={() => setPickerOpen(false)}
        recipes={shareable}
        onPick={(r) => void publish(r)}
        title={t("community.pickRecipeToShare")}
        busy={busy}
        note={(r) => (r.sharedRecipeId ? t("community.ui.alreadyPublished") : null)}
      />
      {confirmUi}
      {noticeUi}
    </>
  );

  if (phone) {
    const scopes = [
      ["all", t("community.allRecipes")],
      ["mine", t("community.myRecipes")],
      ["saved", t("community.savedOnly")],
    ] as const;
    return (
      <section aria-labelledby="feed-title">
        {pull.indicator}
        <h2 id="feed-title" className="sr-only">
          {t("community.sharedRecipes")}
        </h2>
        <InCommunityHeader>
          <div className="pb-3">
            {freeLeft !== null ? (
              // SharedQuotaBanner: stadium, 8/12, icon 16 + 8 + labelSm.
              <p className={`mb-3 flex items-center gap-2 rounded-full px-3 py-2 text-label-sm ${freeLeft > 0 ? "bg-primary-fixed text-primary" : "bg-surface-highest text-on-surface-variant"}`}>
                <Icon name={freeLeft > 0 ? "lock_open" : "lock_clock"} size={16} />
                <span className="min-w-0 flex-1">{freeLeft > 0 ? t("community.ui.freeViewsLeft", { count: freeLeft }) : t("community.ui.quotaReached")}</span>
              </p>
            ) : null}
            <div className="flex items-center gap-3">
              <div className="search-inset flex h-14 min-w-0 flex-1 items-center gap-3 rounded-full border border-surface-highest px-4" style={{ background: "linear-gradient(to bottom, rgb(var(--c-surface-container-highest)), rgb(var(--c-surface-container-low)) 45%)" }}>
                <Icon name="search" size={24} className="shrink-0 text-outline" />
                <label htmlFor="feed-search" className="sr-only">
                  {t("community.search")}
                </label>
                <input
                  id="feed-search"
                  className="h-full min-w-0 flex-1 bg-transparent text-body-md text-on-surface outline-none placeholder:text-outline"
                  placeholder={t("community.searchHint")}
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
                {search ? (
                  <button type="button" onClick={() => setSearch("")} className="grid shrink-0 place-items-center text-outline" aria-label={t("community.ui.clearSearch")}>
                    <Icon name="close" size={24} />
                  </button>
                ) : null}
              </div>
              <button type="button" onClick={() => setFiltersOpen(true)} aria-label={t("community.sortAndFilter")} className="press relative grid h-[54px] w-[54px] shrink-0 place-items-center rounded-full border border-outline-variant bg-surface-low text-tertiary">
                <Icon name="tune" size={20} />
                {narrowed || filters.sort !== "newest" ? <span className="absolute -end-0.5 -top-0.5 h-3 w-3 rounded-full border-2 border-background bg-error" aria-hidden="true" /> : null}
              </button>
            </div>
            <div role="radiogroup" aria-label={t("community.ui.scope")} className="mt-3 flex gap-1">
              {scopes.map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  role="radio"
                  aria-checked={scope === value}
                  onClick={() => setScope(value)}
                  className={`min-w-0 flex-1 truncate rounded-full border py-2 text-center text-label-sm transition-colors duration-[180ms] ${scope === value ? "border-primary bg-primary-fixed text-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        </InCommunityHeader>

        {feed === null && failed ? (
          <ErrorState message={t("community.loadFailed")} onRetry={() => void load()} />
        ) : feed === null ? (
          <Loading />
        ) : visible.length === 0 ? (
          <Empty icon={filtering ? "search" : "globe"} phoneIcon={filtering ? "search_off" : "public"}>
            {filtering ? t("community.noResults") : scope === "mine" ? t("community.noneOfMine") : t("community.noSharedRecipes")}
          </Empty>
        ) : (
          <ul className="space-y-3">
            {visible.map((post) => {
              const mine = post.authorUid === uid;
              const saved = savedIds.has(post.id);
              return (
                <li key={post.id} className="clay-card press cursor-pointer p-6" style={{ borderRadius: 24 }} onClick={() => void open(post)}>
                  <AuthorRow
                    name={post.authorName}
                    photoUrl={post.authorPhotoUrl}
                    createdAtMs={post.createdAtMs}
                    trailing={
                      mine ? (
                        <span className="flex" onClick={(e) => e.stopPropagation()}>
                          <button type="button" className="press-icon grid h-12 w-12 place-items-center rounded-full text-primary" onClick={() => void updateFromMine(post)} disabled={busy} aria-label={t("community.editShared")} title={t("community.editShared")}>
                            <Icon name="edit" size={20} />
                          </button>
                          <button type="button" className="press-icon grid h-12 w-12 place-items-center rounded-full text-error" onClick={() => void remove(post)} disabled={busy} aria-label={t("community.unshare")} title={t("community.unshare")}>
                            <Icon name="delete_outline" size={20} />
                          </button>
                        </span>
                      ) : null
                    }
                  />
                  <div className="mt-3 flex items-start">
                    <button type="button" onClick={(e) => (e.stopPropagation(), void open(post))} className="min-w-0 flex-1 text-start">
                      <span dir="auto" className="line-clamp-2 block text-body-lg">{post.recipe.title}</span>
                      <span className="mt-1 line-clamp-2 block text-label-md text-on-surface-variant">{post.recipe.ingredients.slice(0, 4).map(line).join(" · ")}</span>
                    </button>
                    {post.recipe.imageStoragePath ? <StorageImage path={post.recipe.imageStoragePath} size={64} className="ms-3" /> : null}
                  </div>
                  <div className="mt-3 flex items-center" onClick={(e) => e.stopPropagation()}>
                    <LikeButton liked={post.likedByMe} count={post.likeCount} onToggle={() => like(post)} />
                    <span className="flex-1" />
                    {saved ? (
                      <ClayTag icon="bookmark_added" className="bg-secondary-container text-on-secondary-container">
                        {t("community.savedTag")}
                      </ClayTag>
                    ) : mine ? null : (
                      <ClayButton icon="bookmark_add" disabled={busy} onClick={() => void save(post)}>
                        {t("community.saveToMyRecipes")}
                      </ClayButton>
                    )}
                  </div>
                </li>
              );
            })}
          </ul>
        )}
        <PageFab icon="ios_share" label={t("community.shareRecipe")} onClick={() => setPickerOpen(true)} />
        {pickers}
      </section>
    );
  }

  return (
    <section aria-labelledby="feed-title">
      <h2 id="feed-title" className="sr-only">
        {t("community.sharedRecipes")}
      </h2>
      {freeLeft !== null ? <p className="mb-3 rounded-std bg-info-container px-4 py-2 text-label-md text-on-info-container">{freeLeft > 0 ? t("community.ui.freeViewsLeft", { count: freeLeft }) : t("community.ui.quotaReached")}</p> : null}
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <div className="relative min-w-[200px] flex-1">
          <label htmlFor="feed-search" className="sr-only">
            {t("community.search")}
          </label>
          <Icon name="search" size={18} className="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-outline" />
          <input id="feed-search" className="clay-input ps-10" placeholder={t("community.searchHint")} value={search} onChange={(e) => setSearch(e.target.value)} />
        </div>
        <button type="button" className="clay-btn-secondary relative" onClick={() => setFiltersOpen(true)} aria-label={t("community.sortAndFilter")}>
          <Icon name="filter" size={18} />
          <span className="hidden sm:inline">{t("community.sortAndFilter")}</span>
          {narrowed || filters.sort !== "newest" ? <span className="absolute -end-1 -top-1 h-3 w-3 rounded-full border-2 border-background bg-error" aria-hidden="true" /> : null}
        </button>
        <button type="button" className="clay-btn-ghost" onClick={() => void load(true)} disabled={refreshing} aria-label={t("community.ui.refresh")}>
          <Icon name="refresh" size={18} className={refreshing ? "animate-spin" : ""} />
        </button>
        <button type="button" className="clay-btn-primary" onClick={() => setPickerOpen(true)}>
          <Icon name="share" size={18} /> {t("community.shareRecipe")}
        </button>
      </div>
      <div role="radiogroup" aria-label={t("community.ui.scope")} className="mb-4 grid grid-cols-3 gap-2 sm:max-w-lg">
        {(
          [
            ["all", t("community.allRecipes")],
            ["mine", t("community.myRecipes")],
            ["saved", t("community.savedOnly")],
          ] as const
        ).map(([value, label]) => (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={scope === value}
            onClick={() => setScope(value)}
            className={`truncate rounded-full border px-3 py-2 text-label-sm transition-colors ${scope === value ? "border-primary bg-primary-fixed text-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
          >
            {label}
          </button>
        ))}
      </div>

      {feed === null && failed ? (
        <ErrorState message={t("community.loadFailed")} onRetry={() => void load()} />
      ) : feed === null ? (
        <Loading />
      ) : visible.length === 0 ? (
        <Empty icon={filtering ? "search" : "globe"}>{filtering ? t("community.noResults") : scope === "mine" ? t("community.noneOfMine") : t("community.noSharedRecipes")}</Empty>
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 3xl:grid-cols-5">
          {visible.map((post) => {
            const mine = post.authorUid === uid;
            const saved = savedIds.has(post.id);
            return (
              <li key={post.id} className="clay flex flex-col gap-3 p-4 animate-rise">
                <AuthorRow
                  name={post.authorName}
                  photoUrl={post.authorPhotoUrl}
                  createdAtMs={post.createdAtMs}
                  trailing={
                    mine ? (
                      <span className="flex">
                        <button type="button" className="grid h-9 w-9 place-items-center rounded-full text-primary hover:bg-primary/10" onClick={() => void updateFromMine(post)} disabled={busy} aria-label={t("community.editShared")} title={t("community.editShared")}>
                          <Icon name="refresh" size={18} />
                        </button>
                        <button type="button" className="grid h-9 w-9 place-items-center rounded-full text-error hover:bg-error/10" onClick={() => void remove(post)} disabled={busy} aria-label={t("community.unshare")} title={t("community.unshare")}>
                          <Icon name="trash" size={18} />
                        </button>
                      </span>
                    ) : null
                  }
                />
                <button type="button" onClick={() => void open(post)} className="flex items-start gap-3 text-start">
                  <span className="min-w-0 flex-1">
                    <span dir="auto" className="line-clamp-2 block text-body-lg font-bold">{post.recipe.title}</span>
                    <span className="mt-1 line-clamp-2 block text-label-md text-on-surface-variant">{post.recipe.ingredients.slice(0, 4).map(line).join(" · ")}</span>
                  </span>
                  {post.recipe.imageStoragePath ? <StorageImage path={post.recipe.imageStoragePath} size={64} /> : null}
                </button>
                <div className="mt-auto flex items-center gap-2">
                  <LikeButton liked={post.likedByMe} count={post.likeCount} onToggle={() => like(post)} />
                  <span className="flex-1" />
                  {saved ? (
                    <span className="pill-mint inline-flex items-center gap-1">
                      <Icon name="check" size={14} /> {t("community.savedTag")}
                    </span>
                  ) : mine ? null : (
                    <button type="button" className="clay-btn-tonal" disabled={busy} onClick={() => void save(post)}>
                      <Icon name="add" size={16} /> {t("community.saveToMyRecipes")}
                    </button>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}

      {pickers}
    </section>
  );
}

function FiltersModal({ open, value, onClose, onApply }: { open: boolean; value: Filters; onClose: () => void; onApply: (f: Filters) => void }) {
  const { t } = useI18n();
  const [draft, setDraft] = useState(value);
  useEffect(() => {
    if (open) setDraft(value);
  }, [open, value]);
  const bucketLabel = (b: Bucket) =>
    b === "any" ? t("community.anyTime") : b === "over120" ? t("community.durationPlus", { duration: t("community.ui.hours", { n: 2 }) }) : t("community.upTo", { duration: b === "upTo30" ? t("community.ui.minutes", { n: 30 }) : t("community.ui.hours", { n: b === "upTo60" ? 1 : 2 }) });
  const phone = useIsPhone();
  if (phone) {
    // SharedFeedFilterSheet: underlined section headers, chips 8 apart, clear + apply ClayButtons.
    const head = (text: string) => <h3 className="mb-3 border-b border-[rgb(var(--c-surface-variant))] pb-2 text-headline-md">{text}</h3>;
    const SORT_ICON = { newest: "schedule", oldest: "history", mostLiked: "favorite" } as const;
    return (
      <BottomSheet
        open={open}
        onClose={onClose}
        title={t("community.sortAndFilter")}
        footer={
          <div className="flex gap-3 !w-full">
            <ClayButton icon="filter_alt_off" onClick={() => setDraft({ ...NO_FILTERS, sort: draft.sort })}>
              {t("community.clearFilters")}
            </ClayButton>
            <ClayButton icon="check" className="flex-1" onClick={() => onApply(draft)}>
              {t("community.applyFilters")}
            </ClayButton>
          </div>
        }
      >
        {open ? (
          <div className="space-y-8 pt-2">
            <section>
              {head(t("community.sort"))}
              <div className="flex flex-wrap gap-2">
                {(["newest", "oldest", "mostLiked"] as const).map((s) => (
                  <ClayChip key={s} kind="plan" selected={draft.sort === s} onClick={() => setDraft({ ...draft, sort: s })}>
                    <Glyph name={SORT_ICON[s]} size={16} />
                    {s === "newest" ? t("community.sortNewest") : s === "oldest" ? t("community.sortOldest") : t("community.sortMostLiked")}
                  </ClayChip>
                ))}
              </div>
            </section>
            <section>
              {head(t("community.topics"))}
              <div className="flex flex-wrap gap-2">
                {DIETARY.map((d) => (
                  <ClayChip key={d} kind="filter" selected={draft.topics.includes(d)} onClick={() => setDraft({ ...draft, topics: draft.topics.includes(d) ? draft.topics.filter((x) => x !== d) : [...draft.topics, d] })}>
                    {t(`community.diet.${d}`)}
                  </ClayChip>
                ))}
              </div>
            </section>
            <section>
              {head(t("community.likes"))}
              <div className="flex flex-wrap gap-2">
                {LIKE_STEPS.map((n) => (
                  <ClayChip key={n} kind="plan" selected={draft.minLikes === n} onClick={() => setDraft({ ...draft, minLikes: n })}>
                    {n === 0 ? t("community.anyLikes") : t("community.atLeastLikes", { count: n })}
                  </ClayChip>
                ))}
              </div>
            </section>
            <section>
              {head(t("community.totalTime"))}
              <div className="flex flex-wrap gap-2">
                {BUCKETS.map((b) => (
                  <ClayChip key={b} kind="plan" selected={draft.totalTime === b} onClick={() => setDraft({ ...draft, totalTime: b })}>
                    {bucketLabel(b)}
                  </ClayChip>
                ))}
              </div>
            </section>
          </div>
        ) : null}
      </BottomSheet>
    );
  }
  return (
    <Modal open={open} onClose={onClose} title={t("community.sortAndFilter")}>
      <div className="space-y-5">
        <fieldset>
          <legend className="mb-2 text-label-md font-bold">{t("community.sort")}</legend>
          <div className="flex flex-wrap gap-2">
            {(["newest", "oldest", "mostLiked"] as const).map((s) => (
              <Chip key={s} on={draft.sort === s} onClick={() => setDraft({ ...draft, sort: s })} radio>
                {s === "newest" ? t("community.sortNewest") : s === "oldest" ? t("community.sortOldest") : t("community.sortMostLiked")}
              </Chip>
            ))}
          </div>
        </fieldset>
        <fieldset>
          <legend className="mb-2 text-label-md font-bold">{t("community.topics")}</legend>
          <div className="flex flex-wrap gap-2">
            {DIETARY.map((d) => (
              <Chip key={d} on={draft.topics.includes(d)} onClick={() => setDraft({ ...draft, topics: draft.topics.includes(d) ? draft.topics.filter((x) => x !== d) : [...draft.topics, d] })}>
                {t(`community.diet.${d}`)}
              </Chip>
            ))}
          </div>
        </fieldset>
        <fieldset>
          <legend className="mb-2 text-label-md font-bold">{t("community.likes")}</legend>
          <div className="flex flex-wrap gap-2">
            {LIKE_STEPS.map((n) => (
              <Chip key={n} on={draft.minLikes === n} onClick={() => setDraft({ ...draft, minLikes: n })} radio>
                {n === 0 ? t("community.anyLikes") : t("community.atLeastLikes", { count: n })}
              </Chip>
            ))}
          </div>
        </fieldset>
        <fieldset>
          <legend className="mb-2 text-label-md font-bold">{t("community.totalTime")}</legend>
          <div className="flex flex-wrap gap-2">
            {BUCKETS.map((b) => (
              <Chip key={b} on={draft.totalTime === b} onClick={() => setDraft({ ...draft, totalTime: b })} radio>
                {bucketLabel(b)}
              </Chip>
            ))}
          </div>
        </fieldset>
        <div className="flex flex-wrap justify-end gap-2 pt-2">
          <button type="button" className="clay-btn-ghost" onClick={() => setDraft({ ...NO_FILTERS, sort: draft.sort })}>
            {t("community.clearFilters")}
          </button>
          <button type="button" className="clay-btn-primary" onClick={() => onApply(draft)}>
            {t("community.applyFilters")}
          </button>
        </div>
      </div>
    </Modal>
  );
}

function Chip({ on, onClick, children, radio = false }: { on: boolean; onClick: () => void; children: ReactNode; radio?: boolean }) {
  return (
    <button
      type="button"
      role={radio ? "radio" : "checkbox"}
      aria-checked={on}
      onClick={onClick}
      className={`rounded-full border px-3 py-1.5 text-label-md transition-colors ${on ? "border-primary bg-primary-fixed text-primary" : "border-outline-variant bg-surface-low text-on-surface-variant"}`}
    >
      {children}
    </button>
  );
}
