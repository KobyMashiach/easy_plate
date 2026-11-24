// A user's content item read as text (צפייה) and a recipe edited as a form
// (עריכה) — the JSON editor stays behind an "advanced" button. Recipes are
// stored as the app writes them (RecipeModel): title, prepTimeMinutes,
// cookTimeMinutes, servings, ingredients [{name, amount, unit, section}],
// steps [string], allergens, mayContain, nutrition, sourceUrl,
// contentVersion.
import { h, button, busy, input, textarea, select, field, modal, toast, toastError } from "../ui.js";
import { t, fmtDate } from "../i18n.js";

export const UNITS = ["gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch", "unspecified"];

const isTs = (v) => v && (typeof v.toDate === "function" || typeof v.toMillis === "function");
const asDate = (v) => (typeof v.toDate === "function" ? v.toDate() : new Date(v.toMillis()));

function unitLabel(unit) {
  if (!unit || unit === "unspecified") return "";
  const key = `content.units.${unit}`;
  const label = t(key);
  return label === key ? unit : label;
}

function amountText(n) {
  if (typeof n !== "number" || !Number.isFinite(n)) return "";
  return Number.isInteger(n) ? String(n) : String(Math.round(n * 100) / 100);
}

/// "2 כוסות קמח" — one ingredient line, pure.
export function ingredientLine(i) {
  if (!i || typeof i !== "object") return "";
  return [amountText(i.amount), unitLabel(i.unit), String(i.name || "").trim()].filter(Boolean).join(" ");
}

/// The ingredients grouped under their section headings, in order.
export function ingredientGroups(ingredients) {
  const groups = [];
  for (const i of Array.isArray(ingredients) ? ingredients : []) {
    const section = String((i && i.section) || "").trim();
    const last = groups[groups.length - 1];
    if (last && last.section === section) last.items.push(i);
    else groups.push({ section, items: [i] });
  }
  return groups;
}

const PLATFORMS = [["tiktok", "TikTok"], ["instagram", "Instagram"], ["youtu", "YouTube"], ["facebook", "Facebook"], ["fb.watch", "Facebook"], ["pinterest", "Pinterest"], ["x.com", "X"], ["twitter", "X"]];
const FILE_ACTIONS = { recipe_photo: "photo", recipe_pdf: "pdf", recipe_audio: "audio" };
const millis = (v) => (!v ? null : typeof v.toMillis === "function" ? v.toMillis() : typeof v.toDate === "function" ? v.toDate().getTime() : typeof v === "number" ? v : Date.parse(v) || null);

/// How a recipe came in, as a source key: the chip it was made with
/// (sourceChannel), refined where the recipe alone cannot tell — a file is
/// a photo, a PDF or a recording by the AI call that read it (the closest
/// one in the 15 minutes before it was created), a video names its
/// platform. Pure; `calls` are the account's ai_calls rows.
export function recipeSource(d, calls = []) {
  if (!d || typeof d !== "object") return { key: "unknown" };
  if (d.savedFromSharedId) return { key: "community" };
  if (d.collabId && d.collabRole && d.collabRole !== "owner") return { key: "sharedWithMe" };
  const ch = String(d.sourceChannel || "");
  if (ch === "socialVideo") {
    const url = String(d.sourceUrl || "").toLowerCase();
    const hit = PLATFORMS.find(([needle]) => url.includes(needle));
    return { key: "socialVideo", platform: hit ? hit[1] : null };
  }
  if (ch === "file") {
    const at = millis(d.createdAt);
    let best = null;
    for (const c of calls) {
      const kind = FILE_ACTIONS[c.action];
      const t0 = millis(c.at);
      if (!kind || at === null || t0 === null || t0 > at + 60000 || at - t0 > 15 * 60000) continue;
      if (!best || t0 > best.t0) best = { kind, t0 };
    }
    return { key: best ? best.kind : "file" };
  }
  const known = ["rawText", "webSearch", "urlScrape", "aiRequest", "manual"];
  return { key: known.includes(ch) ? ch : ch ? "other" : "unknown" };
}

export function sourceLabel(src) {
  const label = t(`content.source.${src.key}`);
  return src.platform ? `${label} · ${src.platform}` : label;
}

export function isRecipe(col, d) {
  return col === "recipes" && d && typeof d === "object" && (Array.isArray(d.ingredients) || Array.isArray(d.steps));
}

function recipeView(d, calls) {
  const facts = [
    d.prepTimeMinutes ? `${t("content.prep")}: ${d.prepTimeMinutes} ${t("content.minutes")}` : null,
    d.cookTimeMinutes ? `${t("content.cook")}: ${d.cookTimeMinutes} ${t("content.minutes")}` : null,
    d.servings ? `${t("content.servings")}: ${d.servings}` : null,
  ].filter(Boolean);
  const n = d.nutrition;
  return h("div.stack.recipe-view",
    h("h2", d.title || t("common.unnamed")),
    h("p.muted", `${t("content.sourceCol")}: ${sourceLabel(recipeSource(d, calls))}`, facts.length ? ` · ${facts.join(" · ")}` : ""),
    h("h3", t("content.ingredients")),
    ...ingredientGroups(d.ingredients).map((g) => h("div",
      g.section ? h("h4", g.section) : null,
      h("ul", ...g.items.map((i) => h("li", ingredientLine(i)))),
    )),
    h("h3", t("content.steps")),
    h("ol", ...(Array.isArray(d.steps) ? d.steps : []).map((s) => h("li", String(s)))),
    n && typeof n === "object" ? h("p.small.muted", `${t("content.nutrition")}: ${n.calories ?? "—"} kcal · ${t("content.protein")} ${n.proteinGrams ?? 0}g · ${t("content.carbs")} ${n.carbsGrams ?? 0}g · ${t("content.fat")} ${n.fatGrams ?? 0}g`) : null,
    Array.isArray(d.allergens) && d.allergens.length ? h("p.small.muted", `${t("content.allergens")}: ${d.allergens.join(", ")}`) : null,
    d.sourceUrl ? h("p.small", h("a", { href: d.sourceUrl, target: "_blank", rel: "noopener noreferrer" }, d.sourceUrl)) : null,
  );
}

// Any other item: its fields as plain lines — lists as bullets, nested
// objects indented — never JSON.
function valueNode(v) {
  if (v === null || v === undefined || v === "") return h("span.muted", "—");
  if (isTs(v)) return h("span", fmtDate(asDate(v)));
  if (Array.isArray(v)) {
    if (!v.length) return h("span.muted", "—");
    return h("ul", ...v.map((x) => h("li", x && typeof x === "object" && !isTs(x) ? (x.name || x.title ? ingredientLine(x) || x.title : valueNode(x)) : valueNode(x))));
  }
  if (typeof v === "object") return h("dl.kv", ...Object.entries(v).flatMap(([k, x]) => [h("dt", k), h("dd", valueNode(x))]));
  if (typeof v === "boolean") return h("span", v ? t("common.yes") : t("common.no"));
  return h("span", String(v));
}

function genericView(d) {
  const { id, ...rest } = d;
  return h("dl.kv", ...Object.entries(rest).sort(([a], [b]) => a.localeCompare(b)).flatMap(([k, v]) => [h("dt", k), h("dd", valueNode(v))]));
}

/// The read-only text view of one item.
export function viewDoc(col, d, title, calls = []) {
  modal({ title: `${t("content.view")}: ${title}`, wide: true, body: isRecipe(col, d) ? recipeView(d, calls) : genericView(d), actions: [(c) => button(t("common.close"), { onclick: c })] });
}

/// The recipe from the form's values, onto the stored document. The words
/// changing bumps contentVersion so a stored translation is not reused.
export function applyRecipeForm(d, form) {
  const ingredients = form.ingredients
    .map((i) => ({ name: String(i.name || "").trim(), amount: i.amount === "" || i.amount === null || i.amount === undefined ? null : Number(i.amount), unit: UNITS.includes(i.unit) ? i.unit : "unspecified", ...(String(i.section || "").trim() ? { section: String(i.section).trim() } : {}) }))
    .filter((i) => i.name)
    .map((i) => ({ ...i, amount: Number.isFinite(i.amount) ? i.amount : null }));
  const steps = form.steps.map((s) => String(s || "").trim()).filter(Boolean);
  const num = (v) => (v === "" || v === null || v === undefined || !Number.isFinite(Number(v)) ? null : Math.round(Number(v)));
  const next = { ...d, title: String(form.title || "").trim() || d.title, prepTimeMinutes: num(form.prepTimeMinutes), cookTimeMinutes: num(form.cookTimeMinutes), servings: num(form.servings), ingredients, steps };
  const words = (r) => JSON.stringify([r.title, (r.ingredients || []).map((i) => [i.name, i.amount, i.unit, i.section || ""]), r.steps]);
  if (words(next) !== words(d)) next.contentVersion = (Number(d.contentVersion) || 0) + 1;
  return next;
}

/// The recipe form. `save(next)` writes it; `advanced()` opens the JSON editor.
export function editRecipe(d, { save, advanced }) {
  const title = input({ value: d.title || "" });
  const prep = input({ type: "number", min: "0", value: d.prepTimeMinutes ?? "" });
  const cook = input({ type: "number", min: "0", value: d.cookTimeMinutes ?? "" });
  const servings = input({ type: "number", min: "0", value: d.servings ?? "" });
  const rows = h("div.stack.ing-rows");
  const unitOptions = UNITS.map((u) => [u, unitLabel(u) || t("content.units.unspecified")]);
  const addIngredient = (i = {}) => {
    const amount = input({ type: "number", step: "any", min: "0", value: i.amount ?? "", placeholder: t("content.amount"), "aria-label": t("content.amount") });
    const unit = select(unitOptions, { value: i.unit || "unspecified", "aria-label": t("content.unit") });
    const name = input({ value: i.name || "", placeholder: t("content.name"), "aria-label": t("content.name") });
    const section = input({ value: i.section || "", placeholder: t("content.section"), "aria-label": t("content.section") });
    const row = h("div.ing-row", amount, unit, name, section);
    row.append(button("✕", { kind: "ghost icon", "aria-label": t("common.delete"), onclick: () => row.remove() }));
    row.read = () => ({ amount: amount.value, unit: unit.value, name: name.value, section: section.value });
    rows.append(row);
  };
  (Array.isArray(d.ingredients) ? d.ingredients : []).forEach(addIngredient);
  const steps = textarea({ value: (Array.isArray(d.steps) ? d.steps : []).join("\n"), style: { minHeight: "200px" } });
  const body = h("div.stack",
    field(t("common.title"), title),
    h("div.grid3", field(t("content.prep"), prep), field(t("content.cook"), cook), field(t("content.servings"), servings)),
    h("h3", t("content.ingredients")),
    rows,
    h("div.row", button(`+ ${t("content.addIngredient")}`, { kind: "small", onclick: () => addIngredient() })),
    field(t("content.steps"), steps, t("content.stepsHint")),
  );
  modal({ title: `${t("content.edit")}: ${d.title || ""}`, wide: true, body, actions: [
    (c) => button(t("content.advanced"), { kind: "ghost", onclick: () => { c(); advanced(); } }),
    (c) => button(t("common.cancel"), { onclick: c }),
    (c) => { const b = button(t("common.save"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      const form = { title: title.value, prepTimeMinutes: prep.value, cookTimeMinutes: cook.value, servings: servings.value, ingredients: [...rows.children].map((r) => r.read()), steps: steps.value.split("\n") };
      const next = applyRecipeForm(d, form);
      if (!next.ingredients.length && !next.steps.length) { toast(t("content.emptyRecipe"), "error"); return; }
      try { await save(next); toast(t("common.saved"), "ok"); c(); } catch (e) { toastError(e); }
    })); return b; },
  ] });
}
