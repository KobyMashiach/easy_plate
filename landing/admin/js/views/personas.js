// The invented members. Names come from the model (or by hand), faces
// from randomuser.me, and once created they can author anything the
// community holds.
import { t, fmtNumber, currentLang, LANGS } from "../i18n.js";
import { h, clear, spinner, avatar, badge, button, busy, select, input, textarea, field, modal, confirmDialog, toast, toastError, empty } from "../ui.js";
import { personas, invalidatePersonas } from "../data.js";
import { call, fileToImageDataUrl } from "../api.js";

function portrait(gender) {
  return `https://randomuser.me/api/portraits/${gender === "male" ? "men" : "women"}/${Math.floor(Math.random() * 100)}.jpg`;
}

function personaForm(initial = {}) {
  const name = input({ value: initial.name || "", placeholder: t("common.name") });
  const gender = select([["female", t("personas.gender.female")], ["male", t("personas.gender.male")]], { value: initial.gender || "female" });
  const bio = textarea({ value: initial.bio || "", placeholder: t("personas.bio") });
  const photoUrl = input({ value: initial.photoUrl && !String(initial.photoUrl).includes("firebasestorage") ? initial.photoUrl : "", placeholder: "https://…" });
  const preview = h("img.avatar.lg", { src: initial.photoUrl || portrait(gender.value), alt: "", referrerpolicy: "no-referrer" });
  let dataUrl = null;
  const file = h("input", { type: "file", accept: "image/*", class: "input", onchange: async () => { if (file.files[0]) { dataUrl = await fileToImageDataUrl(file.files[0], 600); preview.src = dataUrl; photoUrl.value = ""; } } });
  photoUrl.addEventListener("change", () => { if (photoUrl.value.trim()) { preview.src = photoUrl.value.trim(); dataUrl = null; } });
  const shuffle = button(t("personas.newPortrait"), { kind: "small", onclick: () => { photoUrl.value = portrait(gender.value); preview.src = photoUrl.value; dataUrl = null; } });
  if (!initial.uid) photoUrl.value = preview.src;
  const root = h("div.stack",
    h("div.row", preview, h("div.grow.stack", field(t("common.name"), name), field(t("personas.gender.male") + " / " + t("personas.gender.female"), gender))),
    h("div.row", h("div.grow", field(t("personas.photoUrl"), photoUrl)), shuffle),
    field(t("personas.photoUpload"), file),
    field(t("personas.bio"), bio),
  );
  return { root, value: () => ({ name: name.value.trim(), gender: gender.value, bio: bio.value.trim(), photoUrl: dataUrl ? undefined : (photoUrl.value.trim() || undefined), photoDataUrl: dataUrl || undefined }) };
}

export async function mount({ view, actions }) {
  const list = h("div.cards");
  const count = h("span.muted.small");
  view.append(h("p.small.muted", t("personas.intro")), h("div.toolbar", count), list);

  const render = async () => {
    clear(list);
    list.append(spinner());
    const rows = await personas({ fresh: true });
    clear(list);
    count.textContent = t("personas.count", { n: fmtNumber(rows.length) });
    if (!rows.length) { list.append(empty(t("personas.none"))); return; }
    for (const p of rows) {
      list.append(h("div.card", h("div.row.between",
        h("div.row", avatar(p.name, p.photoUrl, "lg"), h("div", h("h3", p.name), h("div.small.muted", t(`personas.gender.${p.gender || "female"}`)), p.bio ? h("div.small", p.bio) : null, h("a.small", { href: `#/users/${p.uid}` }, t("common.open")))),
        h("div.row", button(t("common.edit"), { kind: "small", onclick: () => edit(p) }), button(t("common.delete"), { kind: "small danger", onclick: () => remove(p) })),
      )));
    }
  };

  const edit = (p) => {
    const form = personaForm(p);
    modal({ title: t("personas.edit"), body: form.root, actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.save"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      const v = form.value();
      if (!v.name) return;
      // A portrait that is already ours is not re-fetched.
      if (v.photoUrl && p.photoUrl === v.photoUrl) delete v.photoUrl;
      try { await call("persona.update", { uid: p.uid, ...v }); invalidatePersonas(); toast(t("common.saved"), "ok"); c(); render(); } catch (e) { toastError(e); }
    })); return b; }] });
  };

  const remove = (p) => {
    const close = modal({ title: t("personas.deleteTitle", { name: p.name }), body: h("p.small.warn", t("common.irreversible")), actions: [
      (c) => button(t("common.cancel"), { onclick: c }),
      (c) => { const b = button(t("personas.deleteKeep"), { kind: "danger" }); b.addEventListener("click", busy(b, async () => { try { await call("persona.delete", { uid: p.uid, withContent: false }); invalidatePersonas(); toast(t("common.deleted"), "ok"); c(); render(); } catch (e) { toastError(e); } })); return b; },
      (c) => { const b = button(t("personas.deleteWithContent"), { kind: "danger" }); b.addEventListener("click", busy(b, async () => { try { const r = await call("persona.delete", { uid: p.uid, withContent: true }); invalidatePersonas(); toast(t("personas.removed", { posts: r.posts || 0, replies: r.replies || 0, recipes: r.recipes || 0 }), "ok"); c(); render(); } catch (e) { toastError(e); } })); return b; },
    ] });
    void close;
  };

  const createManual = () => {
    const form = personaForm();
    modal({ title: t("personas.create"), body: form.root, actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.create"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      const v = form.value();
      if (!v.name) return;
      try { await call("persona.create", v); invalidatePersonas(); toast(t("common.done"), "ok"); c(); render(); } catch (e) { toastError(e); }
    })); return b; }] });
  };

  const suggest = () => {
    const n = input({ type: "number", min: 1, max: 30, value: 8 });
    const lang = select(Object.entries(LANGS), { value: currentLang() });
    const results = h("div.stack");
    let people = [];
    const ask = button(t("personas.suggest"), { kind: "primary small" });
    ask.addEventListener("click", busy(ask, async () => {
      clear(results);
      results.append(h("p.muted.small", t("personas.suggesting")));
      try {
        const r = await call("persona.suggest", { count: Number(n.value) || 8, lang: lang.value });
        people = r.people.map((p) => ({ ...p, selected: true }));
        clear(results);
        for (const p of people) {
          const row = h("div.item.selectable.on", avatar(p.name, p.photoUrl, "lg"), h("div.body", h("h3", p.name), h("div.small.muted", t(`personas.gender.${p.gender}`))), button("↻", { kind: "ghost small", title: t("personas.newPortrait"), onclick: (e) => { e.stopPropagation(); p.photoUrl = portrait(p.gender); row.querySelector("img").src = p.photoUrl; } }));
          row.addEventListener("click", () => { p.selected = !p.selected; row.classList.toggle("on", p.selected); createBtn.textContent = t("personas.createSelected", { n: people.filter((x) => x.selected).length }); });
          results.append(row);
        }
        createBtn.textContent = t("personas.createSelected", { n: people.length });
        createBtn.hidden = !people.length;
      } catch (e) { clear(results); toastError(e); }
    }));
    const createBtn = button(t("personas.createSelected", { n: 0 }), { kind: "primary", hidden: true });
    const close = modal({ title: t("personas.suggest"), wide: true, body: h("div.stack", h("div.row", field(t("personas.suggestCount"), n), field(t("common.language"), lang), ask), results), actions: [(c) => button(t("common.cancel"), { onclick: c }), () => createBtn] });
    createBtn.addEventListener("click", busy(createBtn, async () => {
      const chosen = people.filter((p) => p.selected);
      let made = 0;
      for (const p of chosen) {
        try { await call("persona.create", { name: p.name, gender: p.gender, photoUrl: p.photoUrl }); made++; } catch (e) { toastError(e); }
      }
      invalidatePersonas();
      toast(t("personas.created", { n: made }), "ok");
      close();
      render();
    }));
  };

  // Everything at once, one persona per call so a failure stops one, not
  // all, and the count on screen moves.
  const removeAll = async () => {
    const rows = await personas({ fresh: true });
    if (!rows.length) return;
    const progress = h("p.small.muted");
    let withContent = false;
    const run = async (c, flag) => {
      withContent = flag;
      let done = 0;
      for (let i = 0; i < rows.length; i++) {
        progress.textContent = t("personas.deleting", { i: i + 1, n: rows.length });
        try { await call("persona.delete", { uid: rows[i].uid, withContent }); done++; } catch (e) { toastError(e); }
      }
      invalidatePersonas();
      toast(t("personas.deletedAll", { n: done }), "ok");
      c();
      render();
    };
    modal({ title: t("personas.deleteAllTitle", { n: rows.length }), body: h("div.stack", h("p.small.warn", t("common.irreversible")), progress), actions: [
      (c) => button(t("common.cancel"), { onclick: c }),
      (c) => { const b = button(t("personas.deleteKeep"), { kind: "danger" }); b.addEventListener("click", busy(b, () => run(c, false))); return b; },
      (c) => { const b = button(t("personas.deleteWithContent"), { kind: "danger" }); b.addEventListener("click", busy(b, () => run(c, true))); return b; },
    ] });
  };

  actions.append(button(t("personas.suggest"), { kind: "primary small", onclick: suggest }), button(t("personas.createManual"), { kind: "small", onclick: createManual }), button(t("personas.deleteAll"), { kind: "small danger", onclick: removeAll }));
  render();
  return () => {};
}
