// A community recipe on a phone, drawn as the app opens one: the read-only
// RecipeDetailsPage (spec 3.2) — the 260 px hero with its glass tags, the
// title, four stat tiles, the nutrition card, the ingredients and the steps.
// Read-only: no edit; "start cooking" above the ingredients and "create a
// shopping list" inside them, as the app offers both on a read-only recipe
// (each behind its flag; the page supplies what they do).
import { useEffect, useState } from "react";
import { useI18n } from "../../../lib/i18n";
import { storageUrl } from "../../../lib/firebase";
import { Icon } from "../../../components/icons";
import { ClayButton, ClayTag } from "../../../components/clay";
import { FeatureGate } from "../../../components/FeatureGate";
import type { DietaryPreference, Nutrition, Recipe } from "../../../models/recipe";
import { useIngredientLine } from "./common";

const TAG_ICON: Record<DietaryPreference, string> = {
  meat: "set_meal",
  dairy: "egg_alt",
  vegetarian: "eco",
  vegan: "spa",
  kosher: "verified",
  glutenFree: "block",
  allergy: "warning_amber",
};
const TAG_COLOURS: Record<DietaryPreference, string> = {
  meat: "bg-error-container text-on-error-container",
  dairy: "bg-info-container text-on-info-container",
  vegetarian: "bg-secondary-container text-on-secondary-container",
  vegan: "bg-[rgb(var(--c-secondary-fixed-dim))] text-on-secondary-fixed",
  kosher: "bg-tertiary-fixed text-[rgb(var(--c-on-tertiary-fixed-variant))]",
  glutenFree: "bg-primary-fixed text-on-primary-fixed-variant",
  allergy: "bg-surface-highest text-on-surface-variant",
};

function useUrl(path: string | null): string | null {
  const [url, setUrl] = useState<string | null>(null);
  useEffect(() => {
    let live = true;
    setUrl(null);
    if (path) storageUrl(path).then((u) => live && setUrl(u));
    return () => {
      live = false;
    };
  }, [path]);
  return url;
}

export function PhoneRecipeView({ recipe: r, onCook, onShop }: { recipe: Recipe; onCook: () => void; onShop: () => void }) {
  const { t, locale } = useI18n();
  const line = useIngredientLine();
  const url = useUrl(r.imageStoragePath);
  const tags = r.dietaryTags;
  const num = new Intl.NumberFormat(locale);
  const dash = "—";

  return (
    <article className="w-full pb-24">
      {/* Hero: 260 tall, radius 32, a bottom shade, up to two glass tags at the bottom start. */}
      <div className="relative h-[260px] overflow-hidden rounded-lg bg-primary-fixed">
        {url ? (
          <img src={url} alt="" className="h-full w-full object-cover" />
        ) : (
          <span className="grid h-full w-full place-items-center text-primary" aria-hidden="true">
            <Icon name="restaurant_menu" size={64} />
          </span>
        )}
        <span aria-hidden="true" className="absolute inset-0" style={{ background: "linear-gradient(to bottom, transparent 50%, rgb(0 0 0 / .45))" }} />
        {tags.length ? (
          <ul className="absolute bottom-4 start-4 flex gap-2">
            {tags.slice(0, 2).map((d) => (
              <li key={d} className="inline-flex items-center gap-1 rounded-full bg-white/[.88] px-3 py-1.5 text-label-sm text-[#181445]">
                <Icon name={TAG_ICON[d]} size={14} className="text-primary" />
                {t(`community.diet.${d}`)}
              </li>
            ))}
          </ul>
        ) : null}
      </div>

      <h1 dir="auto" className="mt-4 break-words text-headline-lg-mobile text-on-surface">
        {r.title}
      </h1>

      {/* Four stat tiles, 8 apart. */}
      <div className="mt-4 grid grid-cols-4 gap-2">
        <StatTile icon="timer" tone="primary" value={r.prepTimeMinutes !== null ? t("community.ui.minutes", { n: r.prepTimeMinutes }) : dash} caption={t("community.ui.prepTime")} />
        <StatTile icon="local_fire_department" tone="secondary" value={r.cookTimeMinutes !== null ? t("community.ui.minutes", { n: r.cookTimeMinutes }) : dash} caption={t("community.ui.cookTime")} />
        <StatTile icon="group" tone="tertiary" value={r.servings !== null ? num.format(r.servings) : dash} caption={t("community.ui.servingsLabel")} />
        <StatTile icon="bolt" tone="warm" value={r.nutrition ? num.format(r.nutrition.calories) : dash} unit={r.nutrition ? t("community.ui.kcal") : undefined} caption={t("community.ui.caloriesLabel")} />
      </div>

      {tags.length > 2 ? (
        <ul className="mt-4 flex flex-wrap gap-2">
          {tags.slice(2).map((d) => (
            <li key={d}>
              <ClayTag icon={TAG_ICON[d]} className={TAG_COLOURS[d]}>
                {t(`community.diet.${d}`)}
              </ClayTag>
            </li>
          ))}
        </ul>
      ) : null}

      {r.nutrition ? <NutritionCard nutrition={r.nutrition} servings={r.servings} /> : null}

      {/* Spec 3.2 item 8: full width, 24 under the nutrition card (32 under the stats without one), 24 to the ingredients. */}
      {r.steps.length ? (
        <FeatureGate flag="ff_cook_mode">
          <ClayButton icon="local_fire_department" expanded className={r.nutrition ? "mt-6" : "mt-8"} onClick={onCook}>
            {t("recipes.cook.start")}
          </ClayButton>
        </FeatureGate>
      ) : null}

      <section className="clay-card mt-6 p-6" style={{ borderRadius: 24 }} aria-labelledby="ing-h">
        <SectionHeader id="ing-h">{t("recipe.ingredients")}</SectionHeader>
        <ul className="mt-3">
          {r.ingredients.map((i, n) => (
            <li key={n} className="flex items-start gap-3 py-1 text-body-md">
              <span aria-hidden="true" className="mt-[9px] h-1.5 w-1.5 shrink-0 rounded-full bg-primary" />
              <span dir="auto" className="min-w-0 break-words">
                {line(i)}
              </span>
            </li>
          ))}
        </ul>
        {r.ingredients.length ? (
          <FeatureGate flag="ff_grocery_from_recipe">
            <ClayButton icon="shopping_cart" expanded className="mt-6" onClick={onShop}>
              {t("groceries.createFromRecipe")}
            </ClayButton>
          </FeatureGate>
        ) : null}
      </section>

      {r.steps.length ? (
        <section className="clay-card mt-6 p-6" style={{ borderRadius: 24 }} aria-labelledby="steps-h">
          <SectionHeader id="steps-h">{t("recipe.steps")}</SectionHeader>
          <ol className="mt-1">
            {r.steps.map((s, n) => (
              <li key={n} className="flex items-start gap-3 py-2 text-body-md">
                <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-primary-fixed text-label-sm text-primary" dir="ltr">
                  {n + 1}
                </span>
                <span dir="auto" className="min-w-0 flex-1 whitespace-pre-wrap break-words pt-0.5">
                  {s}
                </span>
              </li>
            ))}
          </ol>
        </section>
      ) : null}
    </article>
  );
}

/** ClaySectionHeader with the underline: headlineMd, 8 px, a 1 px surfaceVariant rule. */
function SectionHeader({ id, children }: { id: string; children: string }) {
  return (
    <h2 id={id} className="border-b border-[rgb(var(--c-surface-variant))] pb-2 text-headline-md">
      {children}
    </h2>
  );
}

const TONE: Record<"primary" | "secondary" | "tertiary" | "warm", string> = {
  primary: "bg-primary/[.14] text-primary",
  secondary: "bg-secondary/[.14] text-secondary",
  tertiary: "bg-tertiary/[.14] text-tertiary",
  warm: "bg-warm-accent/[.14] text-warm-accent",
};

function StatTile({ icon, tone, value, unit, caption }: { icon: string; tone: keyof typeof TONE; value: string; unit?: string; caption: string }) {
  return (
    <div className="flex min-w-0 flex-col items-center rounded-std border border-surface-highest bg-surface-lowest px-1 py-3 text-center">
      <span className={`grid h-9 w-9 place-items-center rounded-full ${TONE[tone]}`} aria-hidden="true">
        <Icon name={icon} size={18} />
      </span>
      <span className="mt-2 max-w-full truncate text-body-lg font-extrabold text-on-surface">
        {value}
        {unit ? <span className="ms-0.5 text-label-sm font-bold text-on-surface-variant">{unit}</span> : null}
      </span>
      <span className="max-w-full truncate text-label-sm text-on-surface-variant">{caption}</span>
    </div>
  );
}

const MACRO = [
  { key: "protein", colour: "rgb(var(--c-secondary))", per: 4 },
  { key: "carbs", colour: "rgb(var(--c-tertiary))", per: 4 },
  { key: "fat", colour: "rgb(var(--c-warm-accent))", per: 9 },
] as const;

/** NutritionFactsCard: per serving / whole recipe, the macro ring and three bars. */
function NutritionCard({ nutrition, servings }: { nutrition: Nutrition; servings: number | null }) {
  const { t, locale } = useI18n();
  const [whole, setWhole] = useState(false);
  const canScale = servings !== null && servings > 1;
  const f = whole && canScale ? (servings as number) : 1;
  const grams = { protein: nutrition.proteinGrams * f, carbs: nutrition.carbsGrams * f, fat: nutrition.fatGrams * f };
  const kcal = Math.round(nutrition.calories * f);
  const energy = MACRO.map((m) => grams[m.key] * m.per);
  const total = energy.reduce((a, b) => a + b, 0);
  const share = energy.map((e) => (total ? e / total : 0));
  const num = new Intl.NumberFormat(locale, { maximumFractionDigits: 0 });

  // Ring 120 / stroke 12, arcs from 12 o'clock with 0.06 rad gaps.
  const R = 54;
  const C = 2 * Math.PI * R;
  const gap = 0.06 * R;
  let offset = 0;
  const arcs = MACRO.map((m, i) => {
    const len = Math.max(0, share[i] * C - (share[i] > 0 ? gap : 0));
    const arc = { colour: m.colour, len, offset };
    offset += share[i] * C;
    return arc;
  });

  return (
    <section className="clay-card mt-8 p-6" style={{ borderRadius: 24 }} aria-labelledby="nut-h">
      <SectionHeader id="nut-h">{t("community.ui.nutritionTitle")}</SectionHeader>
      {canScale ? (
        <div className="mt-4 flex gap-2" role="group" aria-label={t("community.ui.nutritionTitle")}>
          {[false, true].map((w) => (
            <button
              key={String(w)}
              type="button"
              aria-pressed={whole === w}
              onClick={() => setWhole(w)}
              className={`press flex-1 rounded-full border py-2 text-label-md transition-colors duration-[180ms] ${whole === w ? "border-primary bg-primary text-on-primary" : "border-outline-variant bg-surface-low text-tertiary"}`}
            >
              {w ? t("community.ui.perRecipe") : t("community.ui.perServing")}
            </button>
          ))}
        </div>
      ) : null}
      <div className="mt-4 flex items-center gap-4">
        <div className="relative h-[120px] w-[120px] shrink-0">
          <svg viewBox="0 0 120 120" width="120" height="120" aria-hidden="true" style={{ transform: "rotate(-90deg)" }}>
            <circle cx="60" cy="60" r={R} fill="none" stroke="rgb(var(--c-surface-container-high))" strokeWidth="12" />
            {arcs.map((a, i) =>
              a.len > 0 ? (
                <circle key={i} cx="60" cy="60" r={R} fill="none" stroke={a.colour} strokeWidth="12" strokeLinecap="round" strokeDasharray={`${a.len} ${C}`} strokeDashoffset={-a.offset} />
              ) : null,
            )}
          </svg>
          <span className="absolute inset-0 grid place-items-center text-center">
            <span>
              <span className="block text-headline-md font-extrabold leading-none" dir="ltr">
                {num.format(kcal)}
              </span>
              <span className="text-label-sm text-on-surface-variant">{t("community.ui.kcal")}</span>
            </span>
          </span>
        </div>
        <dl className="min-w-0 flex-1 space-y-3">
          {MACRO.map((m, i) => (
            <div key={m.key}>
              <div className="flex items-center text-label-md">
                <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: m.colour }} aria-hidden="true" />
                <dt className="ms-2 min-w-0 flex-[3] truncate">{t(`community.ui.${m.key}`)}</dt>
                <dd className="flex-[2] text-end font-extrabold">
                  {num.format(grams[m.key])} {t("community.ui.gramsShort")}
                </dd>
                <span className="ms-2 w-[34px] shrink-0 text-end text-label-sm text-on-surface-variant" dir="ltr">
                  {Math.round(share[i] * 100)}%
                </span>
              </div>
              <div className="mt-1 h-2.5 overflow-hidden rounded-full bg-surface-high" aria-hidden="true">
                <div className="h-full rounded-full" style={{ width: `${share[i] * 100}%`, background: m.colour, transition: "width 500ms cubic-bezier(.33,1,.68,1)" }} />
              </div>
            </div>
          ))}
        </dl>
      </div>
    </section>
  );
}
