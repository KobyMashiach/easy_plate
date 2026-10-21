// /recipes/:id — RecipeDetailsPage on a wide screen, inside the live-view
// protection (watermark with the viewer, no copy/print, blur off focus).
// What the account may do follows the app: a viewer on a shared recipe only
// reads; editing, the photo, the AI estimate and the deferred analysis are
// for everyone else; delete is for recipes this account owns (a copy saved
// from the community is "removed from saved" instead); cooking, shopping,
// books and plans are open to every recipe.
import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { useAccess } from "../../lib/flags";
import { useI18n } from "../../lib/i18n";
import { deleteRecipe } from "../../lib/recipesStore";
import { deleteOwnImage } from "../../lib/storage";
import { FeatureGate } from "../../components/FeatureGate";
import { Protected } from "../../components/Protected";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { ClayButton, ClayCard, ClayIconButton, LoadingSpinner, PageHeader } from "../../components/clay";
import { ShefiPill } from "../../components/FloatingActions";
import { PhoneBar } from "../../components/PhoneBar";
import { usePhoneNavigate } from "../../components/pageTransition";
import { useIsPhone } from "../../components/useIsPhone";
import { DIET_ICON, PHONE_DIET_TONE, PhoneTag, SectionHeader, StatTile } from "./components/phone";
import { canEditRecipe, type Recipe } from "../../models/recipe";
import { AllergenNotice, DietTag } from "./components/Chips";
import { ImagePicker } from "./components/ImagePicker";
import { ConfirmDialog, Toast } from "./components/Modal";
import { NutritionCard, PhoneNutritionCard } from "./components/NutritionCard";
import { RecipeImage } from "./components/RecipeImage";
import { ScaleStepper } from "./components/ScaleStepper";
import { aiErrorMessage, analyzePending, estimateNutrition, recipeImagePrompt } from "./lib/ai";
import { ingredientLine, isMine, kcalNumber, optionalDuration, roleLabel } from "./lib/format";
import { patchRecipe, syncCollab } from "./lib/persist";
import { safeHref } from "./lib/safeHref";
import { fileNameOf, useRecipe } from "./lib/useRecipe";
import { AskShefiLink } from "../assistant/AskShefiLink";
import { useTranslated } from "../../lib/contentTranslation";

export function RecipeDetailsPage() {
  const { id } = useParams();
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();
  const { recipe, error } = useRecipe(id);
  // The words in the language on screen, for display only: every save below
  // is made from `recipe`, the stored words.
  const translated = useTranslated("recipe", recipe);

  const [scale, setScale] = useState(1);
  const [estimating, setEstimating] = useState(false);
  const [analyzing, setAnalyzing] = useState(false);
  const [photoOpen, setPhotoOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  // A word from the editor (the community copy's outcome) arrives with the navigation.
  const location = useLocation();
  const [toast, setToast] = useState<{ text: string; kind: "success" | "error" | "info" } | null>(() => {
    const n = (location.state as { notice?: { text?: unknown; kind?: unknown } } | null)?.notice;
    return n && typeof n.text === "string" && (n.kind === "success" || n.kind === "error" || n.kind === "info") ? { text: n.text, kind: n.kind } : null;
  });
  const clearToast = useCallback(() => setToast(null), []);
  const busyRef = useRef(false);

  const shareAccess = useAccess("ff_share_recipes");
  const phone = useIsPhone();
  const go = usePhoneNavigate();
  const assistantAccess = useAccess("ff_assistant");
  const scopedAccess = useAccess("ff_assistant_scoped");
  const scopedShefi = assistantAccess === "enabled" && scopedAccess === "enabled";

  // A shared recipe's copy is a cache; refresh it from the shared document
  // once per visit (SyncCollabRecipeUseCase). On failure the copy stands.
  const synced = useRef<string | null>(null);
  useEffect(() => {
    if (!recipe || !user || !recipe.collabId || synced.current === recipe.id) return;
    synced.current = recipe.id;
    syncCollab(recipe, user.uid, lang).catch(() => setToast({ text: t("recipes.syncFailed"), kind: "info" }));
  }, [recipe, user, lang, t]);

  useEffect(() => setScale(1), [id]);

  // Shown once: a reload or Back must not repeat it.
  useEffect(() => {
    if ((location.state as { notice?: unknown } | null)?.notice) navigate(location.pathname, { replace: true, state: null });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (!user) return null;
  const who = user.email || user.phoneNumber || user.uid;

  if (recipe === undefined && !error && phone) return <LoadingSpinner label={t("common.loading")} />;
  if (recipe === undefined && !error)
    return (
      <div className="py-16 text-center">
        <Spinner label={t("common.loading")} />
      </div>
    );
  if (!recipe)
    return (
      <div className="clay mx-auto mt-6 max-w-md space-y-4 p-8 text-center" role={error ? "alert" : undefined}>
        <p className="text-body-md">{error ? t("recipes.loadFailed") : t("recipes.notFound")}</p>
        <Link to="/recipes" className="clay-btn-tonal">
          {t("recipes.backToRecipes")}
        </Link>
      </div>
    );

  const view = translated ?? recipe;
  const editable = canEditRecipe(recipe);
  const owned = recipe.collabRole === null || recipe.collabRole === "owner";
  const savedCopy = recipe.savedFromSharedId !== null;
  const role = roleLabel(t, recipe.collabRole);

  /**
   * The change goes onto the record as stored now (patchRecipe), not onto
   * this render's snapshot: an AI call takes seconds, and a photo or an edit
   * saved meanwhile must not be written back over. The live listener redraws.
   */
  const persist = (change: (fresh: Recipe) => Recipe) => patchRecipe(recipe.id, user.uid, lang, change);

  const onEstimate = async () => {
    if (busyRef.current) return;
    busyRef.current = true;
    setEstimating(true);
    try {
      const updated = await estimateNutrition(recipe);
      const stored = await persist((fresh) => ({ ...fresh, servings: fresh.servings ?? updated.servings, nutrition: updated.nutrition }));
      setToast(stored ? { text: t("recipes.nut.estimated"), kind: "success" } : { text: t("recipes.goneElsewhere"), kind: "error" });
    } catch (e) {
      setToast({ text: aiErrorMessage(t, e, "recipes.nut.estimateFailed"), kind: "error" });
    } finally {
      busyRef.current = false;
      setEstimating(false);
    }
  };

  const onAnalyze = async () => {
    if (busyRef.current) return;
    busyRef.current = true;
    setAnalyzing(true);
    try {
      const parsed = await analyzePending(recipe);
      // Only the analysed words and numbers; photo, sharing and origin stay as stored.
      await persist((fresh) =>
        fresh.pendingAnalysis
          ? {
              ...fresh,
              title: parsed.title,
              prepTimeMinutes: parsed.prepTimeMinutes,
              cookTimeMinutes: parsed.cookTimeMinutes,
              ingredients: parsed.ingredients,
              steps: parsed.steps,
              dietaryTags: parsed.dietaryTags,
              allergens: parsed.allergens,
              mayContain: parsed.mayContain,
              servings: parsed.servings,
              nutrition: parsed.nutrition,
              pendingAnalysis: false,
            }
          : fresh,
      );
    } catch (e) {
      setToast({ text: aiErrorMessage(t, e, "recipes.analyzeFailed"), kind: "error" });
    } finally {
      busyRef.current = false;
      setAnalyzing(false);
    }
  };

  const onPhoto = async (path: string | null) => {
    setPhotoOpen(false);
    try {
      const seen: { previous: string | null } = { previous: null };
      const stored = await persist((fresh) => {
        seen.previous = fresh.imageStoragePath;
        return { ...fresh, imageStoragePath: path, imageFileName: fileNameOf(path) };
      });
      // The replaced upload goes too, as in the app's _changePhoto — unless
      // the recipe is published: every saved copy in the community still
      // points at that path. deleteOwnImage never touches another account's.
      if (stored && seen.previous && seen.previous !== path && stored.sharedRecipeId === null) void deleteOwnImage(seen.previous);
      // The recipe was deleted elsewhere while the picker was open: nothing
      // points at the new upload, so it goes rather than be billed forever.
      if (!stored && path) void deleteOwnImage(path);
    } catch (_) {
      setToast({ text: t("recipes.error"), kind: "error" });
    }
  };

  const onDelete = async () => {
    if (deleting) return;
    setDeleting(true);
    try {
      await deleteRecipe(recipe);
      navigate("/recipes", { replace: true });
    } catch (_) {
      setDeleting(false);
      setConfirmDelete(false);
      setToast({ text: t("recipes.error"), kind: "error" });
    }
  };

  const hasImage = recipe.imageStoragePath !== null;
  const stats: [string, string, string | null][] = [
    [t("recipes.prepTime"), optionalDuration(t, recipe.prepTimeMinutes), null],
    [t("recipes.cookTime"), optionalDuration(t, recipe.cookTimeMinutes), null],
    [t("recipes.nut.servings"), recipe.servings !== null ? String(recipe.servings) : t("recipes.missingInfo"), null],
    [t("recipes.nut.calories"), recipe.nutrition ? kcalNumber(recipe.nutrition.calories) : t("recipes.missingInfo"), recipe.nutrition ? t("recipes.nut.kcal") : null],
  ];

  const phoneStats: { icon: string; value: string; unit: string | null; caption: string; accent: string }[] = [
    { icon: "timer", value: optionalDuration(t, recipe.prepTimeMinutes), unit: null, caption: t("recipes.prepTime"), accent: "--c-primary" },
    { icon: "local_fire_department", value: optionalDuration(t, recipe.cookTimeMinutes), unit: null, caption: t("recipes.cookTime"), accent: "--c-secondary" },
    { icon: "group", value: recipe.servings !== null ? String(recipe.servings) : t("recipes.missingInfo"), unit: null, caption: t("recipes.nut.servings"), accent: "--c-tertiary" },
    { icon: "bolt", value: recipe.nutrition ? kcalNumber(recipe.nutrition.calories) : t("recipes.missingInfo"), unit: recipe.nutrition ? t("recipes.nut.kcal") : null, caption: t("recipes.nut.calories"), accent: "--c-warm-accent" },
  ];

  const actionCls = "inline-flex items-center gap-2 rounded-full bg-surface-lowest px-4 py-2 text-label-md text-primary shadow-control hover:bg-primary-fixed";

  const glass = "inline-flex items-center gap-1 rounded-full bg-surface-lowest/[.88] px-3 py-1.5 text-label-sm text-on-surface";
  const phoneView = (
    <Protected who={who}>
      <PhoneBar
        title="Easy Plate"
        back="/recipes"
        trailing={editable ? <ClayIconButton icon="edit" label={t("recipes.edit")} to={`/recipes/${recipe.id}/edit`} /> : undefined}
      />
      {scopedShefi ? <ShefiPill light to={`/assistant?scope=recipe&id=${encodeURIComponent(recipe.id)}`} /> : null}
      <div className="pb-32">
        <div className="relative h-[260px] overflow-hidden rounded-lg">
          {hasImage || !editable ? (
            <RecipeImage path={recipe.imageStoragePath} eager iconSize={64} alt={view.title} className="h-full w-full" fallbackIcon="restaurant_menu" fallbackClassName="bg-primary-fixed text-primary" />
          ) : (
            <button type="button" onClick={() => setPhotoOpen(true)} className="block h-full w-full" aria-label={t("recipes.image.add")}>
              <RecipeImage path={null} iconSize={64} className="h-full w-full" fallbackIcon="restaurant_menu" fallbackClassName="bg-primary-fixed text-primary" />
            </button>
          )}
          {hasImage ? <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-transparent from-50% to-black/45" aria-hidden="true" /> : null}
          <div className="pointer-events-none absolute bottom-3 start-3 flex flex-wrap gap-2">
            {role ? (
              <span className={glass}>
                <Icon name="group" size={14} className="text-primary" />
                {role}
              </span>
            ) : null}
            {recipe.dietaryTags.slice(0, 2).map((tag) => (
              <span key={tag} className={glass}>
                <Icon name={DIET_ICON[tag]} size={14} className="text-primary" />
                {t(`recipes.diet.${tag}`)}
              </span>
            ))}
          </div>
          {editable ? (
            <button
              type="button"
              onClick={() => setPhotoOpen(true)}
              className="press-icon absolute bottom-3 end-3 z-[5] grid h-9 w-9 place-items-center rounded-full bg-surface-lowest text-primary"
              aria-label={hasImage ? t("recipes.image.change") : t("recipes.image.add")}
              title={hasImage ? t("recipes.image.change") : t("recipes.image.add")}
            >
              <Icon name={hasImage ? "edit" : "add_a_photo"} size={20} />
            </button>
          ) : null}
        </div>

        <PageHeader title={view.title} className="mt-4" />

        <dl className="mt-4 flex gap-2">
          {phoneStats.map((s) => (
            <div key={s.caption} className="flex min-w-0 flex-1">
              <dt className="sr-only">{s.caption}</dt>
              <dd className="flex min-w-0 flex-1">
                <StatTile icon={s.icon} value={s.value} unit={s.unit} caption={s.caption} accent={s.accent} />
              </dd>
            </div>
          ))}
        </dl>

        {recipe.dietaryTags.length > 2 ? (
          <div className="mt-4 flex flex-wrap gap-2">
            {recipe.dietaryTags.slice(2).map((tag) => (
              <PhoneTag key={tag} icon={DIET_ICON[tag]} className={PHONE_DIET_TONE[tag]}>
                {t(`recipes.diet.${tag}`)}
              </PhoneTag>
            ))}
          </div>
        ) : null}
        <AllergenNotice allergens={recipe.allergens} mayContain={recipe.mayContain} />

        <div className="mt-8 space-y-6">
          <FeatureGate flag="ff_nutrition">
            <PhoneNutritionCard nutrition={recipe.nutrition} servings={recipe.servings} estimating={estimating} onEstimate={!editable || recipe.ingredients.length === 0 ? null : () => void onEstimate()} />
          </FeatureGate>

          {recipe.pendingAnalysis ? (
            <ClayCard radius={24} padding={24} as="section" className="!bg-secondary-container text-on-secondary-container">
              <h2 className="flex items-center gap-3 text-body-lg">
                <Icon name="hourglass_top" size={20} />
                {t("recipes.pendingAnalysis")}
              </h2>
              <p className="mt-1 text-label-md">{t("recipes.pendingAnalysisHint")}</p>
              <ClayButton icon="auto_awesome" expanded className="mt-6" disabled={analyzing || !editable} busy={analyzing} onClick={() => void onAnalyze()}>
                {analyzing ? t("recipes.analyzing") : t("recipes.analyzeNow")}
              </ClayButton>
            </ClayCard>
          ) : null}

          {recipe.steps.length ? (
            <FeatureGate flag="ff_cook_mode">
              <ClayButton icon="local_fire_department" expanded onClick={() => go(`/cook/${recipe.id}`)}>
                {t("recipes.cook.start")}
              </ClayButton>
            </FeatureGate>
          ) : null}

          <ClayCard radius={24} padding={24} as="section" aria-labelledby="ing-h">
            <SectionHeader id="ing-h" title={t("recipes.ingredients")} />
            <ul className="mt-3">
              {view.ingredients.map((ing, i) => (
                <li key={i} className="flex items-start gap-3 py-1">
                  <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary" aria-hidden="true" />
                  <span className="min-w-0 flex-1 text-body-md">{ingredientLine(t, ing)}</span>
                </li>
              ))}
            </ul>
            {recipe.ingredients.length ? (
              <FeatureGate flag="ff_grocery_from_recipe">
                <ClayButton icon="shopping_cart" expanded className="mt-6" onClick={() => go(`/groceries?fromRecipe=${encodeURIComponent(recipe.id)}`)}>
                  {t("recipes.groceryFromRecipe")}
                </ClayButton>
              </FeatureGate>
            ) : null}
          </ClayCard>

          <ClayCard radius={24} padding={24} as="section" aria-labelledby="steps-h">
            <SectionHeader id="steps-h" title={t("recipes.instructions")} />
            <ol className="mt-3">
              {view.steps.map((s, i) => (
                <li key={i} className="flex items-start gap-3 py-2">
                  <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary" aria-hidden="true">
                    {i + 1}
                  </span>
                  <p className="min-w-0 flex-1 text-body-md">{s}</p>
                </li>
              ))}
            </ol>
          </ClayCard>

          {owned ? (
            <div className="flex justify-center">
              <button type="button" onClick={() => setConfirmDelete(true)} className="press inline-flex min-h-11 items-center gap-2 rounded-full px-4 text-label-md text-error">
                <Icon name={savedCopy ? "bookmark_remove" : "delete_outline"} size={18} />
                {savedCopy ? t("recipes.removeSaved") : t("recipes.deleteRecipe")}
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </Protected>
  );

  return (
    <>
      {phone ? phoneView : (
      <>
      <nav className="mb-4 flex flex-wrap items-center gap-3" aria-label={t("recipes.actions")}>
        <Link to="/recipes" className="inline-flex items-center gap-1 text-label-md text-primary">
          <Icon name="back" size={18} className="rtl:rotate-180" />
          {t("recipes.backToRecipes")}
        </Link>
        <div className="ms-auto flex flex-wrap gap-2">
          {editable ? (
            <Link to={`/recipes/${recipe.id}/edit`} className={actionCls}>
              <Icon name="edit" size={18} />
              {t("recipes.edit")}
            </Link>
          ) : null}
          <FeatureGate flag="ff_books">
            <Link to={`/library?addRecipe=${encodeURIComponent(recipe.id)}`} className={actionCls}>
              <Icon name="library" size={18} />
              {t("recipes.addToBook")}
            </Link>
          </FeatureGate>
          <FeatureGate flag="ff_meal_plans">
            <Link to={`/plans?addRecipe=${encodeURIComponent(recipe.id)}`} className={actionCls}>
              <Icon name="plans" size={18} />
              {t("recipes.addToPlan")}
            </Link>
          </FeatureGate>
          {isMine(recipe) && shareAccess !== "hidden" ? (
            <FeatureGate flag="ff_share_recipes">
              <Link to={`/sharing/share?kind=recipe&id=${encodeURIComponent(recipe.id)}`} className={actionCls}>
                <Icon name="share" size={18} />
                {t("recipes.share")}
              </Link>
            </FeatureGate>
          ) : null}
          {owned ? (
            <button type="button" onClick={() => setConfirmDelete(true)} className={`${actionCls} text-error hover:bg-error-container`}>
              <Icon name="trash" size={18} />
              {savedCopy ? t("recipes.removeSaved") : t("recipes.deleteRecipe")}
            </button>
          ) : null}
        </div>
      </nav>

      {!editable ? (
        <p className="mb-4 rounded-std bg-info-container px-4 py-3 text-body-md text-on-info-container" role="note">
          {t("recipes.readOnly")}
        </p>
      ) : null}

      <Protected who={who}>
        <div className="grid gap-6 lg:grid-cols-[minmax(0,5fr)_minmax(0,7fr)] 2xl:grid-cols-[minmax(0,4fr)_minmax(0,8fr)]">
          <div className="space-y-5">
            <div className="relative overflow-hidden rounded-lg">
              <RecipeImage path={recipe.imageStoragePath} eager iconSize={64} className="aspect-[4/3] w-full" />
              {hasImage ? <div className="pointer-events-none absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black/45" aria-hidden="true" /> : null}
              <div className="absolute bottom-3 start-3 flex flex-wrap gap-2">
                {role ? <span className="pill bg-surface-lowest/90 text-on-surface">{role}</span> : null}
                {recipe.dietaryTags.slice(0, 2).map((tag) => (
                  <span key={tag} className="pill bg-surface-lowest/90 text-on-surface">
                    {t(`recipes.diet.${tag}`)}
                  </span>
                ))}
              </div>
              {editable ? (
                <button type="button" onClick={() => setPhotoOpen(true)} className="absolute bottom-3 end-3 z-[5] grid h-11 w-11 place-items-center rounded-full bg-surface-lowest text-primary shadow-control" aria-label={hasImage ? t("recipes.image.change") : t("recipes.image.add")} title={hasImage ? t("recipes.image.change") : t("recipes.image.add")}>
                  <Icon name={hasImage ? "edit" : "image"} size={20} />
                </button>
              ) : null}
            </div>

            <div>
              <h1 className="text-headline-lg">{view.title}</h1>
              {safeHref(recipe.sourceUrl) ? (
                <a href={safeHref(recipe.sourceUrl)!} target="_blank" rel="noopener noreferrer nofollow" className="mt-2 inline-flex items-center gap-1 text-label-md text-primary">
                  <Icon name="external" size={16} />
                  {t("recipes.sourceLink")}
                </a>
              ) : null}
              <div className="mt-3">
                <AskShefiLink kind="recipe" id={recipe.id} />
              </div>
            </div>

            <dl className="grid grid-cols-2 gap-3 sm:grid-cols-4 lg:grid-cols-2 xl:grid-cols-4">
              {stats.map(([caption, value, unit]) => (
                <div key={caption} className="clay p-3 text-center">
                  <dt className="text-label-sm text-on-surface-variant">{caption}</dt>
                  <dd className="mt-1 text-body-lg font-extrabold">
                    {value}
                    {unit ? <span className="ms-1 text-label-sm text-on-surface-variant">{unit}</span> : null}
                  </dd>
                </div>
              ))}
            </dl>

            {recipe.dietaryTags.length > 2 ? (
              <div className="flex flex-wrap gap-2">
                {recipe.dietaryTags.slice(2).map((tag) => (
                  <DietTag key={tag} tag={tag} />
                ))}
              </div>
            ) : null}
            <AllergenNotice allergens={recipe.allergens} mayContain={recipe.mayContain} />

            {recipe.pendingAnalysis ? (
              <section className="space-y-3 rounded-md bg-secondary-container p-5 text-on-secondary-container">
                <h2 className="text-body-lg font-bold">{t("recipes.pendingAnalysis")}</h2>
                <p className="text-label-md">{t("recipes.pendingAnalysisHint")}</p>
                <button type="button" className="clay-btn-primary w-full" disabled={analyzing || !editable} aria-busy={analyzing || undefined} onClick={() => void onAnalyze()}>
                  <Icon name="assistant" size={18} />
                  {analyzing ? t("recipes.analyzing") : t("recipes.analyzeNow")}
                </button>
              </section>
            ) : null}

            {recipe.steps.length ? (
              <FeatureGate flag="ff_cook_mode">
                <Link to={`/cook/${recipe.id}`} className="clay-btn-primary w-full">
                  <Icon name="cook" size={20} />
                  {t("recipes.cook.start")}
                </Link>
              </FeatureGate>
            ) : null}

            <FeatureGate flag="ff_nutrition">
              <NutritionCard nutrition={recipe.nutrition} servings={recipe.servings} estimating={estimating} onEstimate={!editable || recipe.ingredients.length === 0 ? null : () => void onEstimate()} />
            </FeatureGate>
          </div>

          <div className="space-y-5 2xl:grid 2xl:grid-cols-[minmax(0,2fr)_minmax(0,3fr)] 2xl:items-start 2xl:gap-5 2xl:space-y-0">
            <section className="clay space-y-4 p-5 2xl:sticky 2xl:top-24" aria-labelledby="ing-h">
              <h2 id="ing-h" className="text-headline-md">
                {t("recipes.ingredients")}
              </h2>
              {recipe.ingredients.length ? <ScaleStepper scale={scale} baseServings={recipe.servings} onChange={setScale} /> : null}
              <ul className="divide-y divide-outline-variant/40">
                {view.ingredients.map((ing, i) => (
                  <li key={i} className="flex items-start gap-3 py-2">
                    <span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-primary" aria-hidden="true" />
                    <span className="text-body-md">{ingredientLine(t, ing, scale)}</span>
                  </li>
                ))}
              </ul>
              {recipe.ingredients.length ? (
                <FeatureGate flag="ff_grocery_from_recipe">
                  <Link to={`/groceries?fromRecipe=${encodeURIComponent(recipe.id)}${scale !== 1 ? `&scale=${scale}` : ""}`} className="clay-btn-tonal w-full">
                    <Icon name="groceries" size={18} />
                    {t("recipes.groceryFromRecipe")}
                  </Link>
                </FeatureGate>
              ) : null}
            </section>

            <section className="clay p-5" aria-labelledby="steps-h">
              <h2 id="steps-h" className="text-headline-md">
                {t("recipes.instructions")}
              </h2>
              <ol className="mt-3 space-y-4">
                {view.steps.map((s, i) => (
                  <li key={i} className="flex gap-3">
                    <span className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-md text-primary" aria-hidden="true">
                      {i + 1}
                    </span>
                    <p className="pt-1 text-body-md">{s}</p>
                  </li>
                ))}
              </ol>
            </section>
          </div>
        </div>
      </Protected>

      </>
      )}
      {editable ? (
        <ImagePicker open={photoOpen} onClose={() => setPhotoOpen(false)} onPicked={(p) => void onPhoto(p)} hasImage={hasImage} searchQuery={recipe.title} aiPrompt={recipeImagePrompt(recipe)} />
      ) : null}
      <ConfirmDialog
        open={confirmDelete}
        title={savedCopy ? t("recipes.removeSaved") : t("recipes.deleteRecipe")}
        message={savedCopy ? t("recipes.removeSavedConfirm") : t("recipes.deleteConfirm", { title: view.title })}
        confirmLabel={t("recipes.delete")}
        destructive
        busy={deleting}
        onConfirm={() => void onDelete()}
        onCancel={() => setConfirmDelete(false)}
      />
      <Toast message={toast?.text ?? null} kind={toast?.kind} onDone={clearToast} />
    </>
  );
}
