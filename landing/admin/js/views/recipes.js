// Community recipes: the feed as the app shows it, and an editor that can
// start from a dish name (the model writes the recipe), take a picture
// from Google Images, a link or a file, and publish as a persona.
import { db, collection, onSnapshot, query, orderBy, limit, storageUrl } from "../firebase.js";
import { t, fmtNumber, currentLang, LANGS } from "../i18n.js";
import { h, clear, append, spinner, avatar, badge, when, button, busy, select, input, textarea, field, multiChips, tabs, modal, confirmDialog, toast, toastError, empty, debounce } from "../ui.js";
import { authorOptions, isPersona } from "../data.js";
import { call, fileToImageDataUrl } from "../api.js";
import { likeControls } from "./community.js";

const UNITS = ["unspecified", "gram", "kilogram", "milliliter", "liter", "teaspoon", "tablespoon", "cup", "unit", "pinch"];
const DIETS = ["meat", "dairy", "vegetarian", "vegan", "kosher", "glutenFree", "allergy"];
const ALLERGENS = ["gluten", "milk", "eggs", "fish", "shellfish", "peanuts", "treeNuts", "sesame", "soy"];
const DAYS_BACK = 45;

function thumb(path, cls = "thumb") {
  const img = h(`img.${cls}`, { alt: "", loading: "lazy" });
  storageUrl(path).then((url) => { if (url) img.src = url; else img.style.opacity = 0.3; });
  return img;
}

// The editor's state is one plain recipe object, re-rendered on every
// structural change (an ingredient added or removed), with the text
// inputs bound straight to it.
function editor(recipe) {
  const state = recipe;
  const root = h("div.stack");
  const bind = (obj, key, ctl, parse = (v) => v) => { ctl.addEventListener("input", () => { obj[key] = parse(ctl.value); }); return ctl; };
  const num = (v) => (v === "" ? null : Number(v));
  const render = () => {
    clear(root);
    root.append(
      field(t("common.title"), bind(state, "title", input({ value: state.title || "" }))),
      h("div.grid3",
        field(t("recipes.servings"), bind(state, "servings", input({ type: "number", min: 1, value: state.servings ?? "" }), num)),
        field(t("recipes.prep"), bind(state, "prepTimeMinutes", input({ type: "number", min: 0, value: state.prepTimeMinutes ?? "" }), num)),
        field(t("recipes.cook"), bind(state, "cookTimeMinutes", input({ type: "number", min: 0, value: state.cookTimeMinutes ?? "" }), num)),
      ),
      h("div.field", h("label", t("recipes.ingredients")), h("div.ingredients",
        state.ingredients.map((ing, i) => h("div.row",
          bind(ing, "name", input({ class: "name", value: ing.name || "", placeholder: t("recipes.ingredientName") })),
          bind(ing, "amount", input({ type: "number", step: "any", value: ing.amount ?? "", placeholder: t("recipes.amount") }), num),
          bind(ing, "unit", select(UNITS.map((u) => [u, t(`units.${u}`)]), { value: ing.unit || "unspecified" })),
          button("✕", { kind: "ghost small", onclick: () => { state.ingredients.splice(i, 1); render(); } }),
        )),
        button(`+ ${t("recipes.addIngredient")}`, { kind: "small", onclick: () => { state.ingredients.push({ name: "", amount: null, unit: "unspecified" }); render(); } }),
      )),
      h("div.field.steps", h("label", t("recipes.steps")),
        state.steps.map((s, i) => h("div.row", h("span.muted.small", String(i + 1)), bind(state.steps, i, textarea({ value: s })), button("✕", { kind: "ghost small", onclick: () => { state.steps.splice(i, 1); render(); } }))),
        button(`+ ${t("recipes.addStep")}`, { kind: "small", onclick: () => { state.steps.push(""); render(); } }),
      ),
      field(t("recipes.tags"), multiChips(DIETS.map((d) => [d, t(`diets.${d}`)]), state.dietaryTags, (v) => { state.dietaryTags = v; })),
      field(t("recipes.allergens"), multiChips(ALLERGENS.map((a) => [a, t(`allergens.${a}`)]), state.allergens, (v) => { state.allergens = v; })),
      field(t("recipes.mayContain"), multiChips(ALLERGENS.map((a) => [a, t(`allergens.${a}`)]), state.mayContain, (v) => { state.mayContain = v; })),
      h("div.field", h("label", t("recipes.nutrition")), h("div.row",
        bind(state.nutrition, "calories", input({ type: "number", placeholder: t("recipes.calories"), value: state.nutrition.calories ?? "" }), num),
        bind(state.nutrition, "proteinGrams", input({ type: "number", step: "any", placeholder: t("recipes.protein"), value: state.nutrition.proteinGrams ?? "" }), num),
        bind(state.nutrition, "carbsGrams", input({ type: "number", step: "any", placeholder: t("recipes.carbs"), value: state.nutrition.carbsGrams ?? "" }), num),
        bind(state.nutrition, "fatGrams", input({ type: "number", step: "any", placeholder: t("recipes.fat"), value: state.nutrition.fatGrams ?? "" }), num),
      )),
    );
  };
  render();
  return { root, state };
}

function blank() {
  return { title: "", servings: 4, prepTimeMinutes: null, cookTimeMinutes: null, ingredients: [{ name: "", amount: null, unit: "unspecified" }], steps: [""], dietaryTags: [], allergens: [], mayContain: [], nutrition: {} };
}

function fromDoc(d) {
  return { title: d.title || "", servings: d.servings ?? null, prepTimeMinutes: d.prepTimeMinutes ?? null, cookTimeMinutes: d.cookTimeMinutes ?? null, ingredients: (d.ingredients || []).map((i) => ({ ...i })), steps: [...(d.steps || [])], dietaryTags: [...(d.dietaryTags || [])], allergens: [...(d.allergens || [])], mayContain: [...(d.mayContain || [])], nutrition: { ...(d.nutrition || {}) } };
}

// The picture picker: Google Images, a link, a file, or none. Its value is
// what the function's `image` field takes.
function imagePicker(initialPath, queryHint) {
  let value = initialPath ? { storagePath: initialPath } : null;
  const preview = h("div");
  const results = h("div.imggrid");
  const q = input({ value: queryHint || "", placeholder: t("recipes.searchHint") });
  let nextStart = 1;
  const show = (src) => { clear(preview); if (src) preview.append(h("img.thumb.lg", { src, alt: "", referrerpolicy: "no-referrer" })); };
  if (initialPath) storageUrl(initialPath).then(show);
  const search = async (more = false) => {
    if (!q.value.trim()) return;
    if (!more) { clear(results); nextStart = 1; }
    const loading = spinner();
    results.append(loading);
    try {
      const r = await call("image.search", { query: q.value.trim(), start: nextStart, lang: currentLang() });
      loading.remove();
      nextStart = r.nextStart;
      if (!r.items.length && !more) results.append(h("p.muted.small", t("recipes.noResults")));
      for (const item of r.items) {
        const img = h("img", { src: item.thumbnail, alt: item.title || "", title: item.source || "", referrerpolicy: "no-referrer", onclick: () => { for (const o of results.querySelectorAll("img")) o.classList.remove("on"); img.classList.add("on"); value = { url: item.url }; show(item.url); } });
        results.append(img);
      }
      moreBtn.hidden = !nextStart;
    } catch (e) { loading.remove(); toastError(e); }
  };
  const moreBtn = button(t("recipes.searchMore"), { kind: "small", hidden: true, onclick: () => search(true) });
  const searchBtn = button(t("recipes.imageSearch"), { kind: "small primary" });
  searchBtn.addEventListener("click", busy(searchBtn, () => search(false)));
  q.addEventListener("keydown", (e) => { if (e.key === "Enter") { e.preventDefault(); search(false); } });
  const urlCtl = input({ placeholder: "https://…", onchange: () => { if (urlCtl.value.trim()) { value = { url: urlCtl.value.trim() }; show(urlCtl.value.trim()); } } });
  const file = h("input", { type: "file", accept: "image/*", class: "input", onchange: async () => { if (file.files[0]) { const dataUrl = await fileToImageDataUrl(file.files[0]); value = { dataUrl }; show(dataUrl); } } });
  let mode = "search";
  const panes = { search: h("div.stack", h("div.row", h("div.grow", q), searchBtn), results, moreBtn), url: field(t("recipes.imageUrl"), urlCtl), upload: field(t("recipes.imageUpload"), file), none: h("p.muted.small", t("recipes.noImage")) };
  const pane = h("div", panes.search);
  const items = [["search", t("recipes.imageSearch")], ["url", t("common.url")], ["upload", t("common.upload")], ["none", t("recipes.noImage")]];
  if (initialPath) items.unshift(["keep", t("recipes.imageKeep")]);
  if (initialPath) { mode = "keep"; clear(pane); }
  const root = h("div.stack", h("label.small.muted", t("recipes.image")), tabs(items, mode, (m) => { mode = m; clear(pane); if (m === "keep") { value = { storagePath: initialPath }; storageUrl(initialPath).then(show); } else if (m === "none") { value = null; show(null); pane.append(panes.none); } else pane.append(panes[m]); }), preview, pane);
  return { root, get value() { return value; }, setQuery: (s) => { q.value = s; } };
}

async function openEditor({ existing } = {}) {
  const isNew = !existing;
  const ed = editor(isNew ? blank() : fromDoc(existing));
  const edWrap = h("div", ed.root);
  const options = await authorOptions();
  const as = select(options, { value: options.length > 1 ? options[Math.floor(Math.random() * (options.length - 1)) + 1][0] : "me" });
  const lang = select(Object.entries(LANGS), { value: currentLang() });
  const hints = input({ placeholder: t("recipes.hints") });
  const date = input({ type: "datetime-local" });
  const picker = imagePicker(existing ? existing.imageStoragePath : null, existing ? existing.title : "");
  const gen = button(t("recipes.generate"), { kind: "primary small" });
  gen.addEventListener("click", busy(gen, async () => {
    if (!ed.state.title.trim()) { toast(t("recipes.generateFirst"), "error"); return; }
    try {
      const r = await call("recipe.generate", { title: ed.state.title.trim(), lang: lang.value, hints: hints.value.trim() });
      Object.assign(ed.state, { ...r.recipe, nutrition: r.recipe.nutrition || {} });
      clear(edWrap);
      edWrap.append(editor(ed.state).root);
      picker.setQuery(r.imageQuery || r.recipe.title);
    } catch (e) { toastError(e); }
  }));
  const body = h("div.stack",
    isNew ? h("div.card", h("div.row", h("div.grow", field(t("recipes.language"), lang)), h("div.grow", field(t("recipes.hints"), hints)), gen), h("p.small.muted", t("recipes.titleHint"))) : null,
    edWrap,
    h("div.card", picker.root),
    isNew ? h("div.grid2", field(t("forum.as"), as), field(t("forum.backdate"), h("div.row", date, button(t("common.random"), { kind: "small", onclick: () => { const d = new Date(Date.now() - Math.random() * DAYS_BACK * 86400000); date.value = d.toISOString().slice(0, 16); } })))) : null,
  );
  modal({
    title: isNew ? t("recipes.new") : t("recipes.edit"),
    wide: true,
    body,
    actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => {
      const b = button(isNew ? t("recipes.publish") : t("common.save"), { kind: "primary" });
      b.addEventListener("click", busy(b, async () => {
        const recipe = { ...ed.state, ingredients: ed.state.ingredients.filter((i) => i.name && i.name.trim()), steps: ed.state.steps.filter((s) => s && s.trim()) };
        if (!recipe.title.trim()) { toast(t("recipes.generateFirst"), "error"); return; }
        if (!recipe.ingredients.length && !recipe.steps.length) { toast(t("recipes.nothing"), "error"); return; }
        if (!(recipe.nutrition && recipe.nutrition.calories)) recipe.nutrition = null;
        try {
          if (isNew) await call("recipe.create", { as: as.value, recipe, image: picker.value || undefined, createdAt: date.value ? new Date(date.value).getTime() : undefined });
          else await call("recipe.update", { id: existing.id, recipe, image: picker.value && !picker.value.storagePath ? picker.value : undefined });
          toast(isNew ? t("recipes.published") : t("common.saved"), "ok");
          c();
        } catch (e) { toastError(e); }
      }));
      return b;
    }],
  });
}

// The seeding wizard: dish names from the model (editable), then one call
// per recipe — written, pictured, published as a persona on a past date,
// liked by a few others — with the progress on screen.
export async function openSeeder() {
  const options = await authorOptions();
  if (options.length < 2) { toast(t("seed.noPersonas"), "error"); return; }
  const count = input({ type: "number", min: 1, max: 40, value: 10 });
  const lang = select(Object.entries(LANGS), { value: currentLang() });
  const theme = input({ placeholder: t("seed.themeHint") });
  const days = input({ type: "number", min: 0, max: 365, value: DAYS_BACK });
  const likes = input({ type: "number", min: 0, max: 50, value: 6 });
  const as = select([["random", t("seed.random")], ...options], { value: "random" });
  const titles = h("div.stack");
  const progress = h("div.stack");
  let dishes = [];
  let stop = false;
  const renderTitles = () => {
    clear(titles);
    if (!dishes.length) return;
    titles.append(h("label.small.muted", t("seed.titles")));
    dishes.forEach((d, i) => {
      const check = h("input", { type: "checkbox", checked: d.on, onchange: () => { d.on = check.checked; runBtn.textContent = t("seed.run", { n: dishes.filter((x) => x.on).length }); } });
      titles.append(h("div.row", check, h("div.grow", input({ value: d.title, oninput: (e) => { d.title = e.target.value; } })), button("✕", { kind: "ghost small", onclick: () => { dishes.splice(i, 1); renderTitles(); } })));
    });
    titles.append(button(`+ ${t("seed.addTitle")}`, { kind: "small", onclick: () => { dishes.push({ title: "", imageQuery: "", on: true }); renderTitles(); } }));
    runBtn.textContent = t("seed.run", { n: dishes.filter((x) => x.on).length });
    runBtn.hidden = false;
  };
  const suggest = button(t("seed.suggest"), { kind: "primary small" });
  suggest.addEventListener("click", busy(suggest, async () => {
    clear(titles);
    titles.append(h("p.muted.small", t("seed.suggesting")));
    try {
      const r = await call("dish.suggest", { count: Number(count.value) || 10, lang: lang.value, theme: theme.value.trim() });
      dishes = r.dishes.map((d) => ({ ...d, on: true }));
      renderTitles();
    } catch (e) { clear(titles); toastError(e); }
  }));
  const runBtn = button(t("seed.run", { n: 0 }), { kind: "primary", hidden: true });
  const stopBtn = button(t("seed.stop"), { kind: "small danger", hidden: true, onclick: () => { stop = true; stopBtn.disabled = true; } });
  runBtn.addEventListener("click", busy(runBtn, async () => {
    const chosen = dishes.filter((d) => d.on && d.title.trim());
    if (!chosen.length) return;
    stop = false;
    stopBtn.hidden = false;
    stopBtn.disabled = false;
    clear(progress);
    const status = h("p.small.muted");
    progress.append(status);
    let made = 0, failed = 0;
    const span = Math.max(0, Number(days.value) || 0) * 86400000;
    for (let i = 0; i < chosen.length; i++) {
      if (stop) break;
      const d = chosen[i];
      status.textContent = t("seed.running", { i: i + 1, n: chosen.length });
      const row = h("div.row", h("span.spinner"), h("span", d.title));
      progress.append(row);
      try {
        const r = await call("recipe.seedOne", { title: d.title.trim(), lang: lang.value, as: as.value, createdAt: Date.now() - Math.random() * span, imageQuery: d.imageQuery || "", likes: Math.round(Math.random() * (Number(likes.value) || 0)) });
        made++;
        clear(row);
        append(row, [badge("✓", "green"), h("span", r.title), h("span.small.muted", `${t("seed.by")} ${r.authorName}`), r.image ? null : badge(t("recipes.noImage"), "amber"), r.liked ? badge(`♥ ${r.liked}`) : null]);
      } catch (e) {
        failed++;
        clear(row);
        append(row, [badge("✕", "red"), h("span", d.title), h("span.small.error", e.message)]);
      }
    }
    stopBtn.hidden = true;
    status.textContent = t("seed.done", { n: made, failed });
    toast(t("seed.done", { n: made, failed }), made ? "ok" : "error");
  }));
  modal({
    title: t("seed.title"),
    wide: true,
    body: h("div.stack",
      h("div.grid3", field(t("seed.count"), count), field(t("recipes.language"), lang), field(t("seed.author"), as)),
      h("div.grid3", field(t("seed.theme"), theme), field(t("seed.days"), days), field(t("seed.likes"), likes)),
      h("div.row", suggest),
      titles,
      progress,
    ),
    actions: [(c) => button(t("common.close"), { onclick: c }), () => stopBtn, () => runBtn],
  });
}

export async function mount({ view, actions }) {
  let recipes = [], search = "";
  const list = h("div.cards");
  const count = h("span.muted.small");
  view.append(h("div.toolbar", h("div.search", input({ placeholder: t("common.search"), oninput: debounce((e) => { search = e.target.value.trim().toLowerCase(); render(); }, 150) })), count), list);
  actions.append(button(t("seed.title"), { kind: "primary small", onclick: () => openSeeder() }), button(t("recipes.new"), { kind: "small", onclick: () => openEditor() }));

  const render = async () => {
    const rows = search ? recipes.filter((r) => [r.title, r.authorName].some((v) => String(v || "").toLowerCase().includes(search))) : recipes;
    count.textContent = t("recipes.count", { n: fmtNumber(rows.length) });
    clear(list);
    if (!rows.length) { list.append(empty()); return; }
    for (const r of rows) {
      const card = h("div.card.stack",
        h("div.row", r.imageStoragePath ? thumb(r.imageStoragePath) : h("div.thumb"), h("div.grow", h("h3.ellipsis", { title: r.title }, r.title), h("div.small.muted", `${t("recipes.by")} `, h("a", { href: `#/users/${r.authorUid}` }, r.authorName), isPersona(r.authorUid) ? h("span", " · ", badge(t("users.persona"), "brand")) : null), h("div.small.muted", when(r.createdAt), ` · ${fmtNumber((r.ingredients || []).length)} ${t("recipes.ingredients").toLowerCase()} · `, badge(t("forum.likes", { n: r.likeCount || 0 }))))),
        h("div.row", button(t("common.edit"), { kind: "small", onclick: () => openEditor({ existing: r }) }), button(t("common.delete"), { kind: "small danger", onclick: async () => {
          if (!(await confirmDialog({ title: `${t("recipes.delete")}: ${r.title}` }))) return;
          try { await call("recipe.delete", { id: r.id }); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
        } })),
      );
      card.append(await likeControls({ kind: "recipe", recipeId: r.id }));
      list.append(card);
    }
  };
  const unsub = onSnapshot(query(collection(db, "shared_recipes"), orderBy("createdAt", "desc"), limit(200)), (snap) => { recipes = snap.docs.map((d) => ({ id: d.id, ...d.data() })); render(); }, toastError);
  return unsub;
}
