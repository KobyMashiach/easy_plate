// /recipes/new and /recipes/:id/edit — RecipeEditorPage: the same structured
// fields as the app (title, times, servings and per-serving nutrition,
// topics with the allergen detail under "allergy", ingredient rows, steps),
// plus the recipe's picture. Saving asks the app's question first: as typed,
// or with the AI pass (spelling, and the times written in the steps when a
// time changed — ff_save_with_ai). Blank rows are dropped, not validated.
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../lib/auth";
import { getRecord, newId, nowIso } from "../../lib/cloud";
import { useI18n } from "../../lib/i18n";
import { FeatureGate } from "../../components/FeatureGate";
import { Icon } from "../../components/icons";
import { Spinner } from "../../components/ui";
import { ClayButton, ClayIconButton, RoundCheckbox } from "../../components/clay";
import { PhoneBar } from "../../components/PhoneBar";
import { useIsPhone } from "../../components/useIsPhone";
import { PhoneDietaryChips } from "./components/phone";
import { blankRecipe, canEditRecipe, MEASUREMENT_UNITS, normalizeRecipe, type Allergen, type DietaryPreference, type MeasurementUnit, type Recipe } from "../../models/recipe";
import { AllergenChips, DietaryChips } from "./components/Chips";
import { ImagePicker } from "./components/ImagePicker";
import { ConfirmDialog, Modal, Toast } from "./components/Modal";
import { RecipeImage } from "./components/RecipeImage";
import { aiErrorMessage, recipeImagePrompt, refineRecipe } from "./lib/ai";
import { formatAmount, isMine, unitPickerLabel } from "./lib/format";
import { saveRecipe } from "../../lib/recipesStore";
import { mergeEdited, persistRecipe, ViewerCannotEdit } from "./lib/persist";
import { useLinkLeaveGuard } from "../../lib/leaveGuard";
import { deleteOwnImage } from "../../lib/storage";
import { fileNameOf, useRecipe } from "./lib/useRecipe";

export function RecipeNewPage() {
  // A fresh id per visit; the record exists only once it is saved.
  const base = useMemo(() => ({ ...blankRecipe(newId()), createdAt: nowIso() }), []);
  return <Editor base={base} isNew />;
}

export function RecipeEditPage() {
  const { id } = useParams();
  const { t } = useI18n();
  const { recipe, error } = useRecipe(id);
  // The editor keeps the record as it was when it opened; later changes from
  // elsewhere are merged on save (mergeEdited), not poured into the fields.
  const [base, setBase] = useState<Recipe | null>(null);
  useEffect(() => {
    if (recipe && (!base || base.id !== recipe.id)) setBase(recipe);
  }, [recipe, base]);

  if (base) return <Editor key={base.id} base={base} isNew={false} />;
  if (recipe === undefined && !error)
    return (
      <div className="py-16 text-center">
        <Spinner label={t("common.loading")} />
      </div>
    );
  return (
    <div className="clay mx-auto mt-6 max-w-md space-y-4 p-8 text-center" role={error ? "alert" : undefined}>
      <p>{error ? t("recipes.loadFailed") : t("recipes.notFound")}</p>
      <Link to="/recipes" className="clay-btn-tonal">
        {t("recipes.backToRecipes")}
      </Link>
    </div>
  );
}

interface IngRow {
  key: string;
  name: string;
  amount: string;
  unit: MeasurementUnit;
}
interface StepRow {
  key: string;
  text: string;
}

const intOrNull = (s: string): number | null => (/^\d+$/.test(s.trim()) ? parseInt(s.trim(), 10) : null);
const numOrNull = (s: string): number | null => {
  const v = s.trim().replace(",", ".");
  return /^(\d+\.?\d*|\.\d+)$/.test(v) ? parseFloat(v) : null;
};
const gramsText = (v: number | undefined): string => (v === undefined ? "" : v === Math.round(v) ? String(Math.round(v)) : v.toFixed(1));
const key = () => crypto.randomUUID();

function Editor({ base, isNew }: { base: Recipe; isNew: boolean }) {
  const { t, lang } = useI18n();
  const { user } = useAuth();
  const navigate = useNavigate();

  const [title, setTitle] = useState(base.title);
  const [titleError, setTitleError] = useState<string | null>(null);
  const [prep, setPrep] = useState(base.prepTimeMinutes?.toString() ?? "");
  const [cook, setCook] = useState(base.cookTimeMinutes?.toString() ?? "");
  const [servings, setServings] = useState(base.servings?.toString() ?? "");
  const [calories, setCalories] = useState(base.nutrition?.calories.toString() ?? "");
  const [protein, setProtein] = useState(gramsText(base.nutrition?.proteinGrams));
  const [carbs, setCarbs] = useState(gramsText(base.nutrition?.carbsGrams));
  const [fat, setFat] = useState(gramsText(base.nutrition?.fatGrams));
  const [ings, setIngs] = useState<IngRow[]>(() => base.ingredients.map((i) => ({ key: key(), name: i.name, amount: formatAmount(i.amount), unit: i.unit })));
  const [steps, setSteps] = useState<StepRow[]>(() => base.steps.map((s) => ({ key: key(), text: s })));
  const [topics, setTopics] = useState<DietaryPreference[]>(base.dietaryTags);
  const [allergens, setAllergens] = useState<Allergen[]>(base.allergens);
  const [mayContain, setMayContain] = useState<Allergen[]>(base.mayContain);
  const [showAllergens, setShowAllergens] = useState(base.allergens.length > 0 || base.mayContain.length > 0);
  const [showMayContain, setShowMayContain] = useState(base.mayContain.length > 0);
  const [image, setImage] = useState<string | null>(base.imageStoragePath);
  // Pictures uploaded while this editor is open. One replaced by a later
  // pick, or left behind by a discard, is deleted rather than orphaned.
  const uploads = useRef(new Set<string>());
  const [photoOpen, setPhotoOpen] = useState(false);

  const [busy, setBusy] = useState<string | null>(null);
  const busyRef = useRef(false);
  const [askSave, setAskSave] = useState(false);
  const [askDiscard, setAskDiscard] = useState(false);
  const [toast, setToast] = useState<{ text: string; kind: "success" | "error" | "info" } | null>(null);
  const clearToast = useCallback(() => setToast(null), []);
  const saved = useRef(false);
  const [community, setCommunity] = useState<Recipe | null>(null);
  const [communityBusy, setCommunityBusy] = useState(false);

  const hasAllergy = topics.includes("allergy");
  const backTo = isNew ? "/recipes" : `/recipes/${base.id}`;

  const collect = useCallback((): Recipe => {
    const cal = intOrNull(calories);
    const g = (s: string) => numOrNull(s) ?? 0;
    return {
      ...base,
      title: title.trim(),
      prepTimeMinutes: intOrNull(prep),
      cookTimeMinutes: intOrNull(cook),
      ingredients: ings.map((r) => ({ name: r.name.trim(), amount: numOrNull(r.amount), unit: r.unit })).filter((i) => i.name !== ""),
      steps: steps.map((s) => s.text.trim()).filter((s) => s !== ""),
      dietaryTags: topics,
      servings: intOrNull(servings),
      nutrition: cal === null ? null : { calories: cal, proteinGrams: g(protein), carbsGrams: g(carbs), fatGrams: g(fat) },
      allergens: hasAllergy ? allergens : [],
      mayContain: hasAllergy ? mayContain : [],
      imageStoragePath: image,
      imageFileName: image === base.imageStoragePath ? base.imageFileName : fileNameOf(image),
      pendingAnalysis: false,
    };
  }, [base, title, prep, cook, ings, steps, topics, servings, calories, protein, carbs, fat, hasAllergy, allergens, mayContain, image]);

  // Compared with what the fields held when the editor opened (amounts are
  // shown rounded, like the app's editor), so an untouched form is not "dirty".
  const initial = useRef<string | null>(null);
  if (initial.current === null) initial.current = JSON.stringify(collect());
  const dirty = useMemo(() => JSON.stringify(collect()) !== initial.current, [collect]);

  useLinkLeaveGuard(dirty && !saved.current, `${t("recipes.editor.discardTitle")}\n${t("recipes.editor.discardBody")}`);
  useEffect(() => {
    if (!dirty) return;
    const onLeave = (e: BeforeUnloadEvent) => {
      if (saved.current) return;
      e.preventDefault();
      e.returnValue = "";
    };
    window.addEventListener("beforeunload", onLeave);
    return () => window.removeEventListener("beforeunload", onLeave);
  }, [dirty]);
  // Left without saving: this session's uploads go too.
  useEffect(
    () => () => {
      if (saved.current) return;
      for (const p of uploads.current) void deleteOwnImage(p);
      uploads.current.clear();
    },
    [],
  );

  if (!canEditRecipe(base)) {
    return (
      <div className="clay mx-auto mt-6 max-w-md space-y-4 p-8 text-center" role="alert">
        <p>{t("recipes.editor.viewerLocked")}</p>
        <Link to={backTo} className="clay-btn-tonal">
          {t("recipes.back")}
        </Link>
      </div>
    );
  }

  const validate = () => {
    const missing = title.trim() === "";
    setTitleError(missing ? t("recipes.editor.titleRequired") : null);
    if (missing) document.getElementById("ed-title")?.focus();
    return !missing;
  };

  /** Reloads the corrected words into the filled rows only (blank rows were not sent). */
  const applyRefined = (refined: Recipe) => {
    setTitle(refined.title);
    setIngs((rows) => {
      let i = 0;
      return rows.map((r) => (r.name.trim() !== "" && i < refined.ingredients.length ? { ...r, name: refined.ingredients[i++].name } : r));
    });
    setSteps((rows) => {
      let i = 0;
      return rows.map((r) => (r.text.trim() !== "" && i < refined.steps.length ? { ...r, text: refined.steps[i++] } : r));
    });
  };

  const sameText = (a: Recipe, b: Recipe) =>
    a.title === b.title && a.steps.length === b.steps.length && a.ingredients.length === b.ingredients.length && a.steps.every((s, i) => s === b.steps[i]) && a.ingredients.every((x, i) => x.name === b.ingredients[i].name);

  const timesChanged = () => intOrNull(prep) !== base.prepTimeMinutes || intOrNull(cook) !== base.cookTimeMinutes;

  const refine = async (withTimes: boolean): Promise<Recipe | null> => {
    try {
      return await refineRecipe(collect(), withTimes);
    } catch (e) {
      setToast({ text: aiErrorMessage(t, e, "recipes.editor.refineError"), kind: "error" });
      return null;
    }
  };

  const fixSpelling = async () => {
    if (busyRef.current || !validate()) return;
    busyRef.current = true;
    setBusy(t("recipes.editor.refining"));
    const before = collect();
    const refined = await refine(false);
    busyRef.current = false;
    setBusy(null);
    if (!refined) return;
    applyRefined(refined);
    setToast(sameText(before, refined) ? { text: t("recipes.editor.noChanges"), kind: "info" } : { text: t("recipes.editor.spellingFixed"), kind: "success" });
  };

  const save = async (withAi: boolean) => {
    if (busyRef.current || !user) return;
    busyRef.current = true;
    setAskSave(false);
    let result = collect();
    try {
      if (withAi) {
        setBusy(t("recipes.editor.refining"));
        const changed = timesChanged();
        const refined = await refine(changed);
        // A failed correction is not a failed save: the edits go as typed.
        if (refined) result = refined;
      }
      setBusy(t("recipes.editor.saving"));
      if (!isNew) {
        const freshRaw = await getRecord<unknown>("recipes", base.id);
        // Deleted on another device (or tab) while this was open: writing
        // the whole record now would bring it back. Stop and say so.
        if (!freshRaw) {
          setToast({ text: t("recipes.goneElsewhere"), kind: "error" });
          return;
        }
        const fresh = normalizeRecipe(freshRaw);
        // The picture is this editor's to decide when it was changed here.
        const merged = mergeEdited(result, base, fresh);
        result = image !== base.imageStoragePath ? { ...merged, imageStoragePath: result.imageStoragePath, imageFileName: result.imageFileName } : merged;
      }
      const stored = await persistRecipe(result, lang, user.uid);
      saved.current = true;
      for (const p of uploads.current) if (p !== stored.imageStoragePath) void deleteOwnImage(p);
      uploads.current.clear();
      // The picture this one replaced, unless a community post may still show it (as the details page).
      if (base.imageStoragePath && stored.imageStoragePath !== base.imageStoragePath && stored.sharedRecipeId === null) void deleteOwnImage(base.imageStoragePath);
      // Published to the community: the app asks, every time, whether the
      // post should follow (RecipeDetailsPage._persist).
      if (stored.sharedRecipeId && isMine(stored)) setCommunity(stored);
      else navigate(`/recipes/${stored.id}`, { replace: true });
    } catch (e) {
      setToast({ text: e instanceof ViewerCannotEdit ? t("recipes.editor.viewerLocked") : t("recipes.editor.saveFailed"), kind: "error" });
    } finally {
      busyRef.current = false;
      setBusy(null);
    }
  };

  /** "Community too": the post gets the saved words; a post taken down meanwhile is unlinked. */
  const updateCommunity = async (stored: Recipe) => {
    if (communityBusy || !stored.sharedRecipeId) return;
    setCommunityBusy(true);
    let notice: { text: string; kind: "success" | "error" | "info" };
    try {
      const { updateShared } = await import("../community/data/sharedRecipes");
      await updateShared(stored.sharedRecipeId, stored);
      notice = { text: t("recipes.communityUpdated"), kind: "success" };
    } catch (e) {
      if ((e as { code?: string })?.code !== "not-found") notice = { text: t("recipes.communityUpdateFailed"), kind: "info" };
      else {
        notice = { text: t("recipes.communityGone"), kind: "info" };
        try {
          const raw = await getRecord<unknown>("recipes", stored.id);
          const cur = raw ? normalizeRecipe(raw) : null;
          if (cur && cur.sharedRecipeId === stored.sharedRecipeId) await saveRecipe({ ...cur, sharedRecipeId: null }, lang);
        } catch (_) {
          /* the link is cleared on the next save */
        }
      }
    }
    navigate(`/recipes/${stored.id}`, { replace: true, state: { notice } });
  };

  const onSaveClick = () => {
    if (!validate()) return;
    setAskSave(true);
  };

  const cancel = () => (dirty ? setAskDiscard(true) : navigate(backTo));
  const phone = useIsPhone();

  const toggleTopic = (d: DietaryPreference) => {
    if (topics.includes(d)) {
      setTopics(topics.filter((x) => x !== d));
      // Dropping the allergy topic says "no allergens here"; the detail goes with it.
      if (d === "allergy") {
        setAllergens([]);
        setMayContain([]);
        setShowAllergens(false);
        setShowMayContain(false);
      }
    } else setTopics([...topics, d]);
  };
  const toggleIn = (list: Allergen[], set: (l: Allergen[]) => void, a: Allergen) => set(list.includes(a) ? list.filter((x) => x !== a) : [...list, a]);

  const move = <X,>(list: X[], from: number, to: number): X[] => {
    if (to < 0 || to >= list.length) return list;
    const next = [...list];
    const [item] = next.splice(from, 1);
    next.splice(to, 0, item);
    return next;
  };

  const focusLater = (id: string) => requestAnimationFrame(() => document.getElementById(id)?.focus());

  // Below lg: the app's cards (r24 p24) with an underlined section header (12 under it).
  const card = phone ? "clay-card space-y-3 rounded-md p-6" : "clay space-y-4 p-5";
  const h2 = phone ? "border-b border-[rgb(var(--c-surface-variant))] pb-2 text-headline-md" : "text-headline-md";
  const iconBtn = "grid h-10 w-10 shrink-0 place-items-center rounded-full text-tertiary hover:bg-primary/10 disabled:opacity-30";
  const removeBtn = "press-icon grid h-10 w-10 shrink-0 place-items-center rounded-full text-error";

  const content = (
    <>
      {phone ? (
        <PhoneBar
          title={isNew ? t("recipes.editor.newTitle") : t("recipes.editor.title")}
          back={backTo}
          trailing={<ClayIconButton icon="auto_fix_high" label={t("recipes.editor.fixSpelling")} onClick={() => void fixSpelling()} disabled={!!busy} />}
        />
      ) : null}
      {phone ? <h1 className="sr-only">{isNew ? t("recipes.editor.newTitle") : t("recipes.editor.title")}</h1> : (
      <header className="mb-6 flex flex-wrap items-center gap-3">
        <button type="button" onClick={cancel} className="grid h-11 w-11 place-items-center rounded-full bg-surface-lowest shadow-control" aria-label={t("recipes.cancel")}>
          <Icon name="close" />
        </button>
        <h1 className="min-w-0 flex-1 text-headline-lg">{isNew ? t("recipes.editor.newTitle") : t("recipes.editor.title")}</h1>
        <button type="button" className="clay-btn-ghost" onClick={() => void fixSpelling()} disabled={!!busy}>
          <Icon name="check" size={18} />
          {t("recipes.editor.fixSpelling")}
        </button>
        <button type="button" className="clay-btn-primary" onClick={onSaveClick} disabled={!!busy} aria-busy={!!busy || undefined}>
          <Icon name="check" size={18} />
          {t("recipes.save")}
        </button>
      </header>
      )}

      {busy ? (
        <div className="fixed inset-0 z-40 grid place-items-center bg-surface/70" role="status" aria-live="polite">
          <p className="clay flex items-center gap-3 px-6 py-4 text-body-md">
            <span className="h-6 w-6 animate-spin rounded-full border-[3px] border-primary border-t-transparent" aria-hidden="true" />
            {busy}
          </p>
        </div>
      ) : null}

      <div className={phone ? "grid gap-6 pb-28" : "grid gap-6 lg:grid-cols-[minmax(0,5fr)_minmax(0,7fr)]"}>
        <div className="space-y-6">
          <section className={card} aria-labelledby="ed-title-h">
            <h2 id="ed-title-h" className={h2}>
              {t("recipes.editor.recipeTitle")}
            </h2>
            <div className="space-y-1.5">
              <label htmlFor="ed-title" className="sr-only">
                {t("recipes.editor.recipeTitle")}
              </label>
              <input
                id="ed-title"
                className="clay-input text-body-lg"
                value={title}
                placeholder={t("recipes.editor.titleHint")}
                aria-invalid={titleError ? "true" : undefined}
                aria-describedby={titleError ? "ed-title-err" : undefined}
                onChange={(e) => {
                  setTitle(e.target.value);
                  if (titleError) setTitleError(null);
                }}
              />
              {titleError ? (
                <p id="ed-title-err" role="alert" className="text-label-sm text-error">
                  {titleError}
                </p>
              ) : null}
            </div>
          </section>

          {phone && !isNew ? null : (
          <section className={card} aria-labelledby="ed-photo-h">
            <h2 id="ed-photo-h" className={h2}>
              {t("recipes.photo")}
            </h2>
            <button type="button" onClick={() => setPhotoOpen(true)} className="group relative block w-full overflow-hidden rounded-md" aria-label={image ? t("recipes.image.change") : t("recipes.image.add")}>
              <RecipeImage path={image} className="aspect-[4/3] w-full" iconSize={56} {...(phone ? { fallbackIcon: "restaurant_menu", fallbackClassName: "bg-primary-fixed text-primary" } : null)} />
              <span className="absolute bottom-3 end-3 inline-flex items-center gap-2 rounded-full bg-surface-lowest px-4 py-2 text-label-md text-primary shadow-control">
                <Icon name={image ? "edit" : "image"} size={18} />
                {image ? t("recipes.image.change") : t("recipes.image.add")}
              </span>
            </button>
          </section>
          )}

          <section className={card} aria-labelledby="ed-times-h">
            <h2 id="ed-times-h" className={h2}>
              {t("recipes.prepTime")}
            </h2>
            <div className="grid grid-cols-2 gap-3">
              <NumField id="ed-prep" label={t("recipes.editor.prepMinutes")} value={prep} onChange={setPrep} />
              <NumField id="ed-cook" label={t("recipes.editor.cookMinutes")} value={cook} onChange={setCook} />
            </div>
          </section>

          <section className={card} aria-labelledby="ed-nut-h">
            <h2 id="ed-nut-h" className={h2}>
              {t("recipes.nut.title")}
            </h2>
            <NumField id="ed-serv" label={t("recipes.nut.editorServings")} value={servings} onChange={setServings} />
            <div className="grid grid-cols-2 gap-3">
              <NumField id="ed-cal" label={t("recipes.nut.editorCalories")} value={calories} onChange={setCalories} />
              <NumField id="ed-pro" label={t("recipes.nut.editorProtein")} value={protein} onChange={setProtein} decimal />
              <NumField id="ed-carb" label={t("recipes.nut.editorCarbs")} value={carbs} onChange={setCarbs} decimal />
              <NumField id="ed-fat" label={t("recipes.nut.editorFat")} value={fat} onChange={setFat} decimal />
            </div>
            <p className="text-label-md text-outline">{t("recipes.nut.perServingHint")}</p>
          </section>

          <section className={card} aria-labelledby="ed-topics-h">
            <h2 id="ed-topics-h" className={h2}>
              {t("recipes.topics")}
            </h2>
            {phone ? <PhoneDietaryChips selected={topics} onToggle={toggleTopic} label={t("recipes.topics")} /> : <DietaryChips selected={topics} onToggle={toggleTopic} label={t("recipes.topics")} />}
            {hasAllergy && phone ? (
              <div className="space-y-3 pt-3">
                <div className="flex items-center gap-3">
                  <RoundCheckbox checked={showAllergens} onChange={setShowAllergens} label={t("recipes.allergen.pick")} />
                  <span className="text-label-md" aria-hidden="true" onClick={() => setShowAllergens(!showAllergens)}>
                    {t("recipes.allergen.pick")}
                  </span>
                </div>
                {showAllergens ? (
                  <>
                    <p className="text-label-sm text-on-surface-variant">{t("recipes.allergen.contains")}</p>
                    <AllergenChips selected={allergens} onToggle={(a) => toggleIn(allergens, setAllergens, a)} label={t("recipes.allergen.contains")} />
                    <div className="flex items-center gap-3 pt-3">
                      <RoundCheckbox checked={showMayContain} onChange={setShowMayContain} label={t("recipes.allergen.mayContain")} />
                      <span className="text-label-md" aria-hidden="true" onClick={() => setShowMayContain(!showMayContain)}>
                        {t("recipes.allergen.mayContain")}
                      </span>
                    </div>
                    {showMayContain ? <AllergenChips selected={mayContain} onToggle={(a) => toggleIn(mayContain, setMayContain, a)} label={t("recipes.allergen.mayContain")} /> : null}
                  </>
                ) : null}
              </div>
            ) : hasAllergy ? (
              <div className="space-y-3 border-t border-outline-variant/40 pt-4">
                <label className="flex items-center gap-3 text-label-md">
                  <input type="checkbox" className="h-5 w-5 accent-[rgb(var(--c-primary))]" checked={showAllergens} onChange={(e) => setShowAllergens(e.target.checked)} />
                  {t("recipes.allergen.pick")}
                </label>
                {showAllergens ? (
                  <>
                    <p className="text-label-sm text-on-surface-variant">{t("recipes.allergen.contains")}</p>
                    <AllergenChips selected={allergens} onToggle={(a) => toggleIn(allergens, setAllergens, a)} label={t("recipes.allergen.contains")} />
                    <label className="flex items-center gap-3 pt-2 text-label-md">
                      <input type="checkbox" className="h-5 w-5 accent-[rgb(var(--c-primary))]" checked={showMayContain} onChange={(e) => setShowMayContain(e.target.checked)} />
                      {t("recipes.allergen.mayContain")}
                    </label>
                    {showMayContain ? <AllergenChips selected={mayContain} onToggle={(a) => toggleIn(mayContain, setMayContain, a)} label={t("recipes.allergen.mayContain")} /> : null}
                  </>
                ) : null}
              </div>
            ) : null}
          </section>
        </div>

        <div className="space-y-6">
          <section className={card} aria-labelledby="ed-ing-h">
            <h2 id="ed-ing-h" className={h2}>
              {t("recipes.ingredients")}
            </h2>
            <ol className="space-y-2">
              {ings.map((row, i) => (
                <li key={row.key} className={phone ? "flex items-end gap-1 py-1 [content-visibility:auto] [contain-intrinsic-size:auto_56px]" : "flex flex-wrap items-end gap-2 [content-visibility:auto] [contain-intrinsic-size:auto_60px] sm:flex-nowrap"} aria-label={t("recipes.editor.ingredientRow", { n: i + 1 })}>
                  <div className={phone ? "w-16 shrink-0" : "w-20 shrink-0"}>
                    <label htmlFor={`ing-a-${row.key}`} className="sr-only">
                      {t("recipes.editor.amount")}
                    </label>
                    <input id={`ing-a-${row.key}`} className="clay-input px-3" inputMode="decimal" dir="ltr" placeholder={t("recipes.editor.amount")} value={row.amount} onChange={(e) => setIngs(ings.map((r) => (r.key === row.key ? { ...r, amount: e.target.value.replace(/[^0-9.,]/g, "") } : r)))} />
                  </div>
                  <div className={phone ? "w-24 shrink-0" : "w-28 shrink-0"}>
                    <label htmlFor={`ing-u-${row.key}`} className="sr-only">
                      {t("recipes.editor.unit")}
                    </label>
                    <select id={`ing-u-${row.key}`} className="clay-input px-2" value={row.unit} onChange={(e) => setIngs(ings.map((r) => (r.key === row.key ? { ...r, unit: e.target.value as MeasurementUnit } : r)))}>
                      {MEASUREMENT_UNITS.map((u) => (
                        <option key={u} value={u}>
                          {unitPickerLabel(t, u)}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className={phone ? "min-w-0 flex-1" : "min-w-[8rem] flex-1"}>
                    <label htmlFor={`ing-n-${row.key}`} className="sr-only">
                      {t("recipes.editor.ingredientName")}
                    </label>
                    <input id={`ing-n-${row.key}`} className="clay-input" placeholder={t("recipes.editor.ingredientName")} value={row.name} onChange={(e) => setIngs(ings.map((r) => (r.key === row.key ? { ...r, name: e.target.value } : r)))} />
                  </div>
                  {phone ? (
                    <button type="button" className={removeBtn} onClick={() => setIngs(ings.filter((r) => r.key !== row.key))} aria-label={`${t("recipes.editor.removeIngredient")} · ${t("recipes.editor.ingredientRow", { n: i + 1 })}`}>
                      <Icon name="remove_circle_outline" size={24} />
                    </button>
                  ) : (
                  <div className="flex">
                    <button type="button" className={iconBtn} disabled={i === 0} onClick={() => setIngs(move(ings, i, i - 1))} aria-label={`${t("recipes.editor.moveUp")} · ${t("recipes.editor.ingredientRow", { n: i + 1 })}`}>
                      <Icon name="chevron" size={18} className="-rotate-90" />
                    </button>
                    <button type="button" className={iconBtn} disabled={i === ings.length - 1} onClick={() => setIngs(move(ings, i, i + 1))} aria-label={`${t("recipes.editor.moveDown")} · ${t("recipes.editor.ingredientRow", { n: i + 1 })}`}>
                      <Icon name="chevron" size={18} className="rotate-90" />
                    </button>
                    <button type="button" className={`${iconBtn} text-error`} onClick={() => setIngs(ings.filter((r) => r.key !== row.key))} aria-label={`${t("recipes.editor.removeIngredient")} · ${t("recipes.editor.ingredientRow", { n: i + 1 })}`}>
                      <Icon name="trash" size={18} />
                    </button>
                  </div>
                  )}
                </li>
              ))}
            </ol>
            <button
              type="button"
              className={phone ? "clay-btn-primary" : "clay-btn-tonal"}
              onClick={() => {
                const row = { key: key(), name: "", amount: "", unit: "unspecified" as MeasurementUnit };
                setIngs([...ings, row]);
                focusLater(`ing-a-${row.key}`);
              }}
            >
              <Icon name="add" size={18} />
              {t("recipes.editor.addIngredient")}
            </button>
          </section>

          <section className={card} aria-labelledby="ed-steps-h">
            <h2 id="ed-steps-h" className={h2}>
              {t("recipes.instructions")}
            </h2>
            <ol className="space-y-3">
              {steps.map((row, i) => (
                <li key={row.key} className={phone ? "flex items-start gap-1 py-2 [content-visibility:auto] [contain-intrinsic-size:auto_96px]" : "flex items-start gap-2 [content-visibility:auto] [contain-intrinsic-size:auto_96px]"}>
                  <span className={phone ? "me-2 mt-3 grid h-[26px] w-[26px] shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary" : "mt-3 grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary"} aria-hidden="true">
                    {i + 1}
                  </span>
                  <label htmlFor={`step-${row.key}`} className="sr-only">
                    {t("recipes.editor.stepRow", { n: i + 1 })}
                  </label>
                  <textarea
                    id={`step-${row.key}`}
                    rows={phone ? 3 : 2}
                    className={phone ? "clay-input min-h-[52px] min-w-0 flex-1 resize-none py-3 [field-sizing:content]" : "clay-input min-h-[52px] flex-1 resize-y py-3"}
                    placeholder={t("recipes.editor.stepHint")}
                    value={row.text}
                    onChange={(e) => setSteps(steps.map((s) => (s.key === row.key ? { ...s, text: e.target.value } : s)))}
                  />
                  <div className={phone ? "mt-1 flex flex-col [&>button]:h-6 [&>button]:w-6" : "flex flex-col"}>
                    <button type="button" className={iconBtn} disabled={i === 0} onClick={() => setSteps(move(steps, i, i - 1))} aria-label={`${t("recipes.editor.moveUp")} · ${t("recipes.editor.stepRow", { n: i + 1 })}`}>
                      <Icon name="chevron" size={18} className="-rotate-90" />
                    </button>
                    <button type="button" className={iconBtn} disabled={i === steps.length - 1} onClick={() => setSteps(move(steps, i, i + 1))} aria-label={`${t("recipes.editor.moveDown")} · ${t("recipes.editor.stepRow", { n: i + 1 })}`}>
                      <Icon name="chevron" size={18} className="rotate-90" />
                    </button>
                  </div>
                  <button type="button" className={phone ? `${removeBtn} mt-1` : `${iconBtn} mt-1 text-error`} onClick={() => setSteps(steps.filter((s) => s.key !== row.key))} aria-label={`${t("recipes.editor.removeStep")} · ${t("recipes.editor.stepRow", { n: i + 1 })}`}>
                    <Icon name={phone ? "remove_circle_outline" : "trash"} size={phone ? 24 : 18} />
                  </button>
                </li>
              ))}
            </ol>
            <button
              type="button"
              className={phone ? "clay-btn-primary" : "clay-btn-tonal"}
              onClick={() => {
                const row = { key: key(), text: "" };
                setSteps([...steps, row]);
                focusLater(`step-${row.key}`);
              }}
            >
              <Icon name="add" size={18} />
              {t("recipes.editor.addStep")}
            </button>
          </section>

          {phone ? (
            <div className="fixed inset-x-0 bottom-0 z-30 bg-background px-5 pb-[calc(20px+env(safe-area-inset-bottom))] pt-3">
              <ClayButton icon="check" expanded onClick={onSaveClick} disabled={!!busy}>
                {t("recipes.save")}
              </ClayButton>
            </div>
          ) : (
          <div className="flex gap-3">
            <button type="button" className="clay-btn-ghost flex-1" onClick={cancel} disabled={!!busy}>
              {t("recipes.cancel")}
            </button>
            <button type="button" className="clay-btn-primary flex-[2]" onClick={onSaveClick} disabled={!!busy}>
              <Icon name="check" size={18} />
              {t("recipes.save")}
            </button>
          </div>
          )}
        </div>
      </div>

      <Modal open={askSave} onClose={() => setAskSave(false)} title={t("recipes.editor.saveOptionsTitle")}>
        <div className="space-y-3">
          <SaveOption icon="check" title={t("recipes.save")} hint={t("recipes.editor.savePlainHint")} onClick={() => void save(false)} disabled={!!busy} />
          <FeatureGate flag="ff_save_with_ai">
            <SaveOption icon="assistant" title={t("recipes.editor.saveWithAi")} hint={t("recipes.editor.saveWithAiHint")} onClick={() => void save(true)} disabled={!!busy} />
          </FeatureGate>
        </div>
      </Modal>
      <ConfirmDialog
        open={askDiscard}
        title={t("recipes.editor.discardTitle")}
        message={t("recipes.editor.discardBody")}
        confirmLabel={t("recipes.editor.discard")}
        destructive
        onConfirm={() => {
          saved.current = true;
          navigate(backTo);
        }}
        onCancel={() => setAskDiscard(false)}
      />
      <ConfirmDialog
        open={community !== null}
        title={t("recipes.communityUpdateTitle")}
        message={t("recipes.communityUpdateBody")}
        confirmLabel={t("recipes.communityUpdateBoth")}
        cancelLabel={t("recipes.communityUpdateLocal")}
        busy={communityBusy}
        onConfirm={() => community && void updateCommunity(community)}
        onCancel={() => community && navigate(`/recipes/${community.id}`, { replace: true })}
      />
      <ImagePicker
        open={photoOpen}
        onClose={() => setPhotoOpen(false)}
        onPicked={(p) => {
          // The previous pick of this session is replaced: not kept in Storage.
          if (image && image !== p && uploads.current.has(image)) {
            uploads.current.delete(image);
            void deleteOwnImage(image);
          }
          if (p && p !== base.imageStoragePath) uploads.current.add(p);
          setImage(p);
          setPhotoOpen(false);
        }}
        hasImage={image !== null}
        searchQuery={title.trim()}
        aiPrompt={recipeImagePrompt({ title: title.trim(), ingredients: collect().ingredients })}
      />
      <Toast message={toast?.text ?? null} kind={toast?.kind} onDone={clearToast} />
    </>
  );
  return phone ? <div className={PHONE_FIELDS}>{content}</div> : content;
}

/** The theme's text field below lg: 1 px outlineVariant rim on the low fill, 2 px primary on focus. */
const PHONE_FIELDS =
  "[&_.clay-input]:min-h-[48px] [&_.clay-input]:border [&_.clay-input]:border-outline-variant [&_.clay-input]:shadow-none [&_.clay-input]:text-body-md [&_.clay-input:focus]:border-primary [&_.clay-input:focus]:shadow-[inset_0_0_0_1px_rgb(var(--c-primary))] [&_.clay-input[aria-invalid=true]]:border-error";

function NumField({ id, label, value, onChange, decimal = false }: { id: string; label: string; value: string; onChange: (v: string) => void; decimal?: boolean }) {
  return (
    <div className="space-y-1.5">
      <label htmlFor={id} className="block text-label-md text-on-surface-variant">
        {label}
      </label>
      <input id={id} className="clay-input" dir="ltr" inputMode={decimal ? "decimal" : "numeric"} value={value} onChange={(e) => onChange(e.target.value.replace(decimal ? /[^0-9.,]/g : /[^0-9]/g, ""))} />
    </div>
  );
}

function SaveOption({ icon, title, hint, onClick, disabled }: { icon: string; title: string; hint: string; onClick: () => void; disabled: boolean }) {
  return (
    <button type="button" onClick={onClick} disabled={disabled} className="clay flex w-full items-center gap-3 p-4 text-start hover:bg-primary/5 disabled:opacity-60">
      <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary-fixed text-primary" aria-hidden="true">
        <Icon name={icon} size={20} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-body-lg">{title}</span>
        <span className="block text-label-sm text-on-surface-variant">{hint}</span>
      </span>
      <Icon name="chevron" size={18} className="text-tertiary rtl:rotate-180" />
    </button>
  );
}
