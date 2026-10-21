// One community recipe, read-only (the app opens RecipeDetailsPage with
// readOnly for someone else's post): the dish, its author, likes, and saving
// it to my recipes. The free tier's daily count is applied on the way in.
import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../../lib/auth";
import { useI18n } from "../../../lib/i18n";
import { useFlags } from "../../../lib/flags";
import { useCollection } from "../../../lib/cloud";
import { normalizeRecipe } from "../../../models/recipe";
import { FeatureGate } from "../../../components/FeatureGate";
import { Icon } from "../../../components/icons";
import { useNotices } from "../../sharing/ui/dialogs";
import { ErrorState, Loading, StorageImage } from "../../sharing/ui/bits";
import { getSharedPost, importShared, toggleLike, type SharedPost } from "../data/sharedRecipes";
import { openSharedAllowed } from "../data/usage";
import { AuthorRow, LikeButton, useIngredientLine } from "../components/common";
import { PhoneRecipeView } from "../components/PhoneRecipeView";
import { useCommunityRecipeActions } from "../components/RecipeActions";
import { useIsPhone } from "../../../components/useIsPhone";
import { PhoneBar } from "../../../components/PhoneBar";
import { ShefiPill } from "../../../components/FloatingActions";
import { ClayButton } from "../../../components/clay";
import { usePhoneNavigate } from "../../../components/pageTransition";

export function SharedRecipePage() {
  const { id = "" } = useParams();
  return (
    <FeatureGate flag="ff_community" page>
      <FeatureGate flag="ff_shared_recipes" page>
        {/* Keyed: another recipe starts clean (no last one's dish, quota block or busy state). */}
        <SharedRecipe key={id} />
      </FeatureGate>
    </FeatureGate>
  );
}

function SharedRecipe() {
  const { id = "" } = useParams();
  const { t, lang } = useI18n();
  const { user, premium } = useAuth();
  const flags = useFlags();
  const uid = user?.uid ?? "";
  const navigate = useNavigate();
  const location = useLocation();
  const passed = (location.state as { post?: SharedPost } | null)?.post;
  const line = useIngredientLine();
  const [post, setPost] = useState<SharedPost | null | undefined>(passed && passed.id === id ? passed : undefined);
  const [failed, setFailed] = useState(false);
  const [blocked, setBlocked] = useState(false);
  const [busy, setBusy] = useState(false);
  const [attempt, setAttempt] = useState(0);
  const liking = useRef(false);
  const { ui: noticeUi, notify, alert } = useNotices();
  // Start cooking and a shopping list, as the app offers them on a read-only recipe.
  const actions = useCommunityRecipeActions(post, alert);
  const { items: rawRecipes } = useCollection<unknown>("recipes", uid);
  const saved = useMemo(() => (rawRecipes ?? []).map(normalizeRecipe).some((r) => r.savedFromSharedId === id), [rawRecipes, id]);

  useEffect(() => {
    if (!uid) return;
    let live = true;
    setFailed(false);
    (async () => {
      try {
        const fresh = await getSharedPost(id, uid);
        if (!live) return;
        // Reached by a link (a forum reply, the address bar): the day's count applies here too.
        if (fresh && !passed) {
          const ok = await openSharedAllowed(fresh.id, fresh.authorUid, uid, { premium, number: flags.number, string: flags.string }).catch(() => true);
          if (!live) return;
          if (!ok) {
            setBlocked(true);
            return;
          }
        }
        setPost(fresh);
      } catch (_) {
        if (live) setFailed(true);
      }
    })();
    return () => {
      live = false;
    };
    // The count is asked once per open, not on every flag refresh.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, uid, attempt]);

  // One like in flight at a time: a second tap waits for nothing and is dropped.
  const like = async () => {
    if (!post || liking.current) return;
    liking.current = true;
    const original = post;
    setPost({ ...post, likedByMe: !post.likedByMe, likeCount: post.likeCount + (post.likedByMe ? -1 : 1) });
    try {
      await toggleLike(post.id, uid);
    } catch (_) {
      setPost((p) => (p && p.likedByMe !== original.likedByMe ? { ...p, likedByMe: original.likedByMe, likeCount: p.likeCount + (p.likedByMe ? -1 : 1) } : p));
    } finally {
      liking.current = false;
    }
  };

  const save = async () => {
    if (!post || busy) return;
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

  const back = (
    <button type="button" onClick={() => (window.history.length > 1 ? navigate(-1) : navigate("/community"))} className="mb-3 inline-flex items-center gap-1 text-label-md text-primary">
      <Icon name="back" size={18} className="rtl:rotate-180" /> {t("common.back")}
    </button>
  );

  const phone = useIsPhone();
  const go = usePhoneNavigate();
  if (phone) {
    // Recipe details (read-only) under the bar's back arrow and "Easy Plate"; the light Shefi pill.
    const bar = <PhoneBar title={t("shell.appName")} back="/community" />;
    if (blocked) {
      return (
        <>
          {bar}
          <ErrorState message={t("community.ui.quotaReached")} />
          <div className="mx-6">
            <ClayButton icon="workspace_premium" expanded onClick={() => go("/pricing")}>
              {t("sharing.code.upgrade")}
            </ClayButton>
          </div>
        </>
      );
    }
    if (failed && post === undefined) return <>{bar}<ErrorState message={t("community.loadFailed")} onRetry={() => setAttempt((a) => a + 1)} /></>;
    if (post === undefined) return <>{bar}<Loading /></>;
    if (post === null) return <>{bar}<ErrorState message={t("community.recipeUnavailable")} /></>;
    return (
      <>
        {bar}
        <PhoneRecipeView recipe={post.recipe} onCook={actions.cook} onShop={actions.shop} />
        <ShefiPill light />
        {actions.elements}
        {noticeUi}
      </>
    );
  }

  if (blocked) {
    return (
      <div className="mx-auto max-w-md">
        {back}
        <ErrorState message={t("community.ui.quotaReached")} />
        <Link to="/pricing" className="clay-btn-primary mt-4 w-full">
          <Icon name="premium" size={18} /> {t("sharing.code.upgrade")}
        </Link>
      </div>
    );
  }
  if (failed && post === undefined) return <ErrorState message={t("community.loadFailed")} onRetry={() => setAttempt((a) => a + 1)} />;
  if (post === undefined) return <Loading />;
  if (post === null) {
    return (
      <div className="mx-auto max-w-md">
        {back}
        <ErrorState message={t("community.recipeUnavailable")} />
      </div>
    );
  }

  const r = post.recipe;
  const mine = post.authorUid === uid;
  const facts = [r.servings ? t("recipe.servings", { n: r.servings }) : null, r.prepTimeMinutes ? t("recipe.prep", { n: r.prepTimeMinutes }) : null, r.cookTimeMinutes ? t("recipe.cook", { n: r.cookTimeMinutes }) : null].filter(Boolean);

  return (
    <article className="w-full">
      {back}
      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_320px] 2xl:grid-cols-[minmax(0,1fr)_400px]">
        <div className="space-y-5 xl:grid xl:grid-cols-[minmax(0,2fr)_minmax(0,3fr)] xl:items-start xl:gap-5 xl:space-y-0">
          <header className="space-y-3 xl:col-span-2">
            <h1 dir="auto" className="break-words text-headline-lg">{r.title}</h1>
            <AuthorRow name={post.authorName} photoUrl={post.authorPhotoUrl} createdAtMs={post.createdAtMs} />
            {facts.length ? <p className="text-label-md text-on-surface-variant">{facts.join(" · ")}</p> : null}
            {r.dietaryTags.length ? (
              <ul className="flex flex-wrap gap-2">
                {r.dietaryTags.map((d) => (
                  <li key={d} className="pill-lavender">
                    {t(`community.diet.${d}`)}
                  </li>
                ))}
              </ul>
            ) : null}
          </header>
          <section className="clay p-5">
            <h2 className="mb-3 text-body-lg font-bold">{t("recipe.ingredients")}</h2>
            <ul className="space-y-1.5">
              {r.ingredients.map((i, n) => (
                <li key={n} className="flex gap-2 text-body-md">
                  <span aria-hidden="true" className="text-primary">•</span>
                  <span dir="auto" className="min-w-0 break-words">{line(i)}</span>
                </li>
              ))}
            </ul>
          </section>
          <section className="clay p-5">
            <h2 className="mb-3 text-body-lg font-bold">{t("recipe.steps")}</h2>
            <ol className="space-y-3">
              {r.steps.map((s, n) => (
                <li key={n} className="flex gap-3 text-body-md">
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-md font-bold text-on-primary-fixed-variant">{n + 1}</span>
                  <span dir="auto" className="min-w-0 flex-1 whitespace-pre-wrap break-words">{s}</span>
                </li>
              ))}
            </ol>
          </section>
        </div>
        <aside className="space-y-4 lg:sticky lg:top-24 lg:self-start">
          {r.imageStoragePath ? <StorageImage path={r.imageStoragePath} fluid className="shadow-card" /> : null}
          <div className="clay flex items-center gap-2 p-4">
            <LikeButton liked={post.likedByMe} count={post.likeCount} onToggle={() => void like()} />
            <span className="flex-1" />
            {saved ? (
              <span className="pill-mint inline-flex items-center gap-1">
                <Icon name="check" size={14} /> {t("community.savedTag")}
              </span>
            ) : mine ? null : (
              <button type="button" className="clay-btn-primary" disabled={busy} onClick={() => void save()}>
                <Icon name="add" size={16} /> {t("community.saveToMyRecipes")}
              </button>
            )}
          </div>
          {r.steps.length ? (
            <FeatureGate flag="ff_cook_mode">
              <button type="button" className="clay-btn-primary w-full" onClick={actions.cook}>
                <Icon name="cook" size={20} /> {t("recipes.cook.start")}
              </button>
            </FeatureGate>
          ) : null}
          {r.ingredients.length ? (
            <FeatureGate flag="ff_grocery_from_recipe">
              <button type="button" className="clay-btn-tonal w-full" onClick={actions.shop}>
                <Icon name="groceries" size={18} /> {t("groceries.createFromRecipe")}
              </button>
            </FeatureGate>
          ) : null}
        </aside>
      </div>
      {actions.elements}
      {noticeUi}
    </article>
  );
}
