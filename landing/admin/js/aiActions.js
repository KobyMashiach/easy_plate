// What an account did with the AI — "recipe from a photo", "cover for a
// book" — rather than which raw kind the proxy logged. New rows carry
// `action`; older ai_calls rows and aggregates (ai_usage, ai_daily) only
// have `fn` / `kind`, mapped here. Pure: no Firestore, no DOM.

export const ACTIONS = [
  "recipe_text", "recipe_photo", "recipe_pdf", "recipe_audio", "recipe_file", "recipe_url", "recipe_video",
  "recipe_generate", "recipe_refine", "recipe_search", "recipe_suggest", "nutrition", "receipt_scan",
  "image_recipe", "image_book_cover", "image_other", "assistant_chat", "translate", "whatsapp", "admin", "other",
];

const BY_FN = { adminPanel: "admin", translateContent: "translate", whatsappWebhook: "whatsapp", socialRecipe: "recipe_video" };

const BY_KIND = {
  text: "recipe_text", url: "recipe_url", social: "recipe_video", social_video: "recipe_video", video: "recipe_video",
  file: "recipe_file", search: "recipe_search", image: "image_other", receipt: "receipt_scan", nutrition: "nutrition",
  refine: "recipe_refine", generate: "recipe_generate", assistant: "assistant_chat", translate: "translate", whatsapp: "whatsapp",
};

export function actionOfKind(kind) {
  return BY_KIND[String(kind || "")] || "other";
}

// One ai_calls row → its action id.
export function actionOf(row) {
  if (!row) return "other";
  if (row.action) return String(row.action);
  if (BY_FN[row.fn]) return BY_FN[row.fn];
  return actionOfKind(row.kind);
}

// Counter maps added field by field (calls, total, input, output, …).
function addCounters(a, b) {
  const out = { ...a };
  for (const [k, v] of Object.entries(b || {})) if (typeof v === "number") out[k] = (out[k] || 0) + v;
  return out;
}

// An aggregate doc (ai_usage/{uid}, ai_daily/{day}) → { action: counters }:
// its `actions` map when it has one, otherwise its `kinds` folded through
// the kind table.
export function actionTallies(aggregate) {
  if (!aggregate) return {};
  if (aggregate.actions && typeof aggregate.actions === "object" && Object.keys(aggregate.actions).length) {
    return Object.fromEntries(Object.entries(aggregate.actions).map(([k, v]) => [k, addCounters({}, v)]));
  }
  const out = {};
  for (const [kind, v] of Object.entries(aggregate.kinds || {})) {
    const action = actionOfKind(kind);
    out[action] = addCounters(out[action] || {}, v);
  }
  return out;
}

// The i18n key of an action's label; an unknown id falls back to its raw name.
export function actionKey(action) {
  return ACTIONS.includes(action) ? `ai.actions.${action}` : null;
}

// The area an action belongs to — the main split ("recipes", "books", …);
// the action itself is the detail.
const CATEGORY_OF = {
  recipe_text: "recipes", recipe_photo: "recipes", recipe_pdf: "recipes", recipe_audio: "recipes", recipe_file: "recipes",
  recipe_url: "recipes", recipe_video: "recipes", recipe_generate: "recipes", recipe_refine: "recipes", recipe_search: "recipes",
  recipe_suggest: "recipes", nutrition: "recipes", image_recipe: "recipes",
  image_book_cover: "books",
  receipt_scan: "shopping", whatsapp: "shopping",
  assistant_chat: "assistant", translate: "translate", admin: "admin",
};
export const CATEGORIES = ["recipes", "books", "shopping", "assistant", "translate", "admin", "other"];

export function categoryOf(action) {
  return CATEGORY_OF[action] || "other";
}

// { action: counters } → { category: counters }.
export function categoryTallies(byAction) {
  const out = {};
  for (const [action, v] of Object.entries(byAction || {})) {
    const c = categoryOf(action);
    out[c] = addCounters(out[c] || {}, v);
  }
  return out;
}
