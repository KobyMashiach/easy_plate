// A tool's card drawn the way the app draws the same thing (AssistantCardView):
// a recipe tile, a live grocery checklist, a planned meal, web results, a
// status line, lines of information — each one a way to the real screen.
import { useState } from "react";
import { Link } from "react-router-dom";
import { Icon } from "../../components/icons";
import { useI18n } from "../../lib/i18n";
import { totalAmount, type GroceryItem } from "../../models/groceryList";
import type { Recipe } from "../../models/recipe";
import { isWebUrl } from "../ingest/channels";
import { formatAmount, kcalNumber, unitLabel } from "../recipes/lib/format";
import type { AssistantCard } from "./models";

const recipePath = (id: string) => `/recipes/${encodeURIComponent(id)}`;

const STATUS_ICON: Record<string, string> = {
  delete: "trash",
  book: "library",
  calendar: "plans",
  flame: "cook",
  timer: "timer",
  scale: "nutrition",
};

export function CardView({ card, onToggle, onSend, busy }: { card: AssistantCard; onToggle: (listId: string, itemId: string) => void; onSend: (text: string) => void; busy: boolean }) {
  switch (card.kind) {
    case "recipe":
      return <RecipeTile recipe={card.recipe} caption={card.caption} />;
    case "recipeList":
      return <RecipeList title={card.title} recipes={card.recipes} />;
    case "grocery":
      return <GroceryChecklist listId={card.listId} listName={card.listName} items={card.items} onToggle={onToggle} />;
    case "planned":
      return <PlannedMeal card={card} />;
    case "web":
      return <WebResults results={card.results} onSend={onSend} busy={busy} />;
    case "status":
      return <Status text={card.text} icon={card.icon} to={card.to} />;
    case "lines":
      return <Lines title={card.title} lines={card.lines} />;
    case "premium":
      return <PremiumCard />;
  }
}

function RecipeTile({ recipe, caption }: { recipe: Recipe; caption?: string }) {
  const { t } = useI18n();
  const meta = [
    recipe.servings !== null ? `${recipe.servings} ${t("assistant.servings").toLowerCase()}` : null,
    recipe.prepTimeMinutes !== null ? t("assistant.minutes", { count: recipe.prepTimeMinutes }) : null,
    recipe.nutrition ? `${kcalNumber(recipe.nutrition.calories)} ${t("assistant.kcal")}` : null,
  ]
    .filter(Boolean)
    .join(" · ");
  return (
    <Link to={recipePath(recipe.id)} className="clay flex items-center gap-3 p-4 transition-transform hover:-translate-y-0.5 active:scale-[.99]">
      <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-primary" aria-hidden="true">
        <Icon name="recipes" />
      </span>
      <span className="min-w-0 flex-1">
        {caption ? <span className="block text-label-sm text-secondary">{caption}</span> : null}
        <span className="line-clamp-2 block text-body-lg">{recipe.title}</span>
        {meta ? <span className="block text-label-md text-on-surface-variant">{meta}</span> : null}
      </span>
      <Icon name="chevron" className="shrink-0 text-outline rtl:rotate-180" />
    </Link>
  );
}

function RecipeList({ title, recipes }: { title: string; recipes: Recipe[] }) {
  return (
    <div className="clay p-4">
      <p className="text-label-md text-on-surface-variant">{title}</p>
      <ul className="mt-1">
        {recipes.slice(0, 8).map((r) => (
          <li key={r.id}>
            <Link to={recipePath(r.id)} className="flex items-center gap-3 rounded-std px-1 py-2 hover:bg-primary/5">
              <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-primary" aria-hidden="true" />
              <span className="min-w-0 flex-1 truncate text-body-md">{r.title}</span>
              <Icon name="chevron" size={18} className="shrink-0 text-outline rtl:rotate-180" />
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function itemLine(t: (k: string, v?: Record<string, string | number>) => string, item: GroceryItem): string {
  const amount = totalAmount(item);
  return [amount > 0 ? formatAmount(amount) : "", unitLabel(t, item.unit), item.name].filter((s) => s !== "").join(" ");
}

function GroceryChecklist({ listId, listName, items, onToggle }: { listId: string; listName: string; items: GroceryItem[]; onToggle: (listId: string, itemId: string) => void }) {
  const { t } = useI18n();
  const bought = items.filter((i) => i.isChecked).length;
  const shown = items.slice(0, 12);
  return (
    <div className="clay p-4">
      <div className="flex items-center gap-2">
        <Icon name="groceries" size={18} className="text-primary" />
        <p className="min-w-0 flex-1 truncate text-body-lg">{listName}</p>
        <span className="text-label-md text-on-surface-variant" aria-label={t("assistant.boughtOf", { bought, total: items.length })}>
          {bought}/{items.length}
        </span>
      </div>
      {shown.length ? (
        <ul className="mt-2">
          {shown.map((item) => {
            // The input sits inside its label: no id, since the same list can have several cards in one chat.
            return (
              <li key={item.id}>
                <label className="flex cursor-pointer items-center gap-3 rounded-std px-1 py-1.5 hover:bg-primary/5">
                  <input type="checkbox" checked={item.isChecked} onChange={() => onToggle(listId, item.id)} className="h-5 w-5 shrink-0 accent-primary" />
                  <span className={`min-w-0 flex-1 text-body-md ${item.isChecked ? "text-outline line-through" : ""}`}>{itemLine(t, item)}</span>
                </label>
              </li>
            );
          })}
        </ul>
      ) : null}
      <div className="mt-2 flex items-center justify-between gap-2">
        {items.length > 12 ? <span className="text-label-md text-outline">{t("assistant.more", { n: items.length - 12 })}</span> : <span />}
        <Link to={`/groceries/${encodeURIComponent(listId)}`} className="inline-flex items-center gap-1 text-label-md text-primary">
          {t("assistant.openList")}
          <Icon name="chevron" size={16} className="rtl:rotate-180" />
        </Link>
      </div>
    </div>
  );
}

function PlannedMeal({ card }: { card: Extract<AssistantCard, { kind: "planned" }> }) {
  const body = (
    <>
      <span className="grid h-11 w-11 shrink-0 place-items-center rounded-std bg-primary-fixed text-primary" aria-hidden="true">
        <Icon name="plans" />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-label-md text-on-surface-variant">
          {card.dayLabel} · {card.mealName}
        </span>
        <span className="block text-body-lg">{card.title}</span>
        <span className="block text-label-sm text-outline">{card.planName}</span>
      </span>
    </>
  );
  // The app opens the recipe; a free-text dish has nowhere to go but its plan.
  const to = card.recipe ? recipePath(card.recipe.id) : `/plans/${encodeURIComponent(card.planId)}`;
  return (
    <Link to={to} className="clay flex items-center gap-3 p-4 transition-transform hover:-translate-y-0.5">
      {body}
      <Icon name="chevron" className="shrink-0 text-outline rtl:rotate-180" />
    </Link>
  );
}

function WebResults({ results, onSend, busy }: { results: { title: string; url: string; snippet: string }[]; onSend: (text: string) => void; busy: boolean }) {
  const { t } = useI18n();
  return (
    <div className="clay divide-y divide-outline-variant/40 p-4">
      {results.filter((r) => isWebUrl(r.url)).map((r, i) => (
        <div key={`${i}:${r.url}`} className="py-2 first:pt-0 last:pb-0">
          <a href={r.url} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-body-md font-bold hover:underline">
            {r.title}
            <Icon name="external" size={14} />
            <span className="sr-only">({t("assistant.newTab")})</span>
          </a>
          {r.snippet ? <p className="line-clamp-2 text-label-md text-on-surface-variant">{r.snippet}</p> : null}
          <button type="button" disabled={busy} onClick={() => onSend(`${t("assistant.urlScrape")}: ${r.url}`)} className="pill-lavender mt-1.5 disabled:opacity-50">
            <Icon name="assistant" size={14} />
            {t("assistant.parse")}
          </button>
        </div>
      ))}
    </div>
  );
}

function Status({ text, icon, to }: { text: string; icon: string; to?: string }) {
  const inner = (
    <>
      <Icon name={STATUS_ICON[icon] ?? "check"} size={20} />
      <span className="min-w-0 flex-1 text-body-md">{text}</span>
      {to ? <Icon name="chevron" size={18} className="shrink-0 rtl:rotate-180" /> : null}
    </>
  );
  const cls = "flex items-center gap-3 rounded-md bg-secondary-container px-4 py-3 text-on-secondary-container";
  return to ? (
    <Link to={to} className={`${cls} hover:brightness-95`}>
      {inner}
    </Link>
  ) : (
    <div className={cls}>{inner}</div>
  );
}

function Lines({ title, lines }: { title: string; lines: string[] }) {
  const [all, setAll] = useState(false);
  const { t } = useI18n();
  const shown = all ? lines : lines.slice(0, 14);
  return (
    <div className="clay p-4">
      <p className="text-label-md text-on-surface-variant">{title}</p>
      <ul className="mt-1 space-y-0.5">
        {shown.map((line, i) => (
          <li key={i} className="text-body-md">
            {line}
          </li>
        ))}
      </ul>
      {!all && lines.length > 14 ? (
        <button type="button" onClick={() => setAll(true)} className="mt-1 text-label-md text-primary">
          {t("assistant.more", { n: lines.length - 14 })}
        </button>
      ) : null}
    </div>
  );
}

function PremiumCard() {
  const { t } = useI18n();
  return (
    <div className="flex flex-wrap items-center gap-3 rounded-md bg-primary-fixed px-4 py-3 text-on-primary-fixed">
      <Icon name="premium" size={20} />
      <span className="min-w-0 flex-1 text-body-md">{t("assistant.needsPremium")}</span>
      <Link to="/pricing" className="clay-btn-primary !min-h-[40px] px-4 text-label-md">
        {t("assistant.unlock")}
      </Link>
    </div>
  );
}
