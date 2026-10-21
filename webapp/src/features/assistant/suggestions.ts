// Opening prompts (AssistantSuggestions.pick): templates and fillers in the
// current language, a fresh handful per conversation. Templates live in
// assistant.json as assistant.suggest.t0…t29 with [food]-style slots (square
// brackets, so the dictionary check does not read them as placeholders), and
// each pool is one "|"-separated string.
type Translate = (key: string) => string;

const POOLS = ["food", "dish", "day", "meal", "n", "site", "book", "diet"] as const;
const TEMPLATE_COUNT = 30;

const pickOne = <X>(xs: X[]): X => xs[Math.floor(Math.random() * xs.length)];

export function pickSuggestions(t: Translate, count: number): string[] {
  const pools = Object.fromEntries(POOLS.map((p) => [p, t(`assistant.suggest.${p}`).split("|").filter(Boolean)])) as Record<(typeof POOLS)[number], string[]>;
  const templates = Array.from({ length: TEMPLATE_COUNT }, (_, i) => t(`assistant.suggest.t${i}`)).filter((s) => !s.startsWith("assistant."));
  for (let i = templates.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [templates[i], templates[j]] = [templates[j], templates[i]];
  }
  const out: string[] = [];
  for (const template of templates) {
    if (out.length >= count) break;
    let text = template;
    let firstFood: string | null = null;
    for (const pool of POOLS) {
      const slot = `[${pool}]`;
      if (text.includes(slot) && pools[pool].length) {
        const value = pickOne(pools[pool]);
        if (pool === "food") firstFood = value;
        text = text.split(slot).join(value);
      }
    }
    if (text.includes("[food2]")) {
      const others = pools.food.filter((f) => f !== firstFood);
      if (others.length) text = text.split("[food2]").join(pickOne(others));
    }
    if (!out.includes(text)) out.push(text);
  }
  return out;
}

/** The fixed prompts of a scoped conversation (assistant.scopedPrompts.*). */
export function scopedPrompts(t: Translate, kind: "recipe" | "mealPlan" | "groceryList"): string[] {
  return Array.from({ length: 5 }, (_, i) => t(`assistant.scopedPrompts.${kind}.${i}`));
}
