// The app's Instagram account: drafts (Claude's and uploads), approval,
// scheduling, publishing, stats and comments. Posts are a live Firestore
// listener (instagram_posts); every change goes through adminPanel
// (functions/adminInstagram.js), which is what keeps "only what was
// approved goes out" true. Media is uploaded straight to Storage
// (marketing/instagram/{postId}/…, admin-only in storage.rules) because a
// Reel is too large for a function request.
import { db, storage, storageUrl, collection, doc, onSnapshot, query, orderBy, limit } from "../firebase.js";
import { ref as storageRef, uploadBytesResumable } from "https://www.gstatic.com/firebasejs/12.4.0/firebase-storage.js";
import { t, fmtNumber, fmtDate } from "../i18n.js";
import { h, clear, badge, button, busy, input, textarea, select, field, modal, confirmDialog, toast, toastError, empty, tabs, spinner, withEmoji } from "../ui.js";
import { call } from "../api.js";

const STATUS_COLORS = { draft: "", approved: "mint", scheduled: "amber", publishing: "brand", published: "green", failed: "red" };
const TAB_STATUSES = { drafts: ["draft", "approved", "failed"], scheduled: ["scheduled", "publishing"], published: ["published"] };
const TYPES = ["image", "carousel", "reel", "story"];
const MAX_CAPTION = 2200;
const MAX_HASHTAGS = 30;
// The server's creative rule (adminInstagram.js), mirrored for a warning
// while typing; the server is the one that refuses.
const CREATIVE_RULE = /premium|פרימיום|פרמיום|\bpro\b|מנוי|subscription|abonnement|подписк|اشتراك|₪|€|\$\s?\d|\d\s?\$|trial|תקופת ניסיון|ניסיון חינם|חינם|unlimited|ללא הגבלה|בלי הגבלה/i;

const hashtagCount = (s) => (String(s || "").match(/(^|\s)#[^\s#]+/g) || []).length;

// The same checks the server makes before approving, for the editor's
// warning list.
function problemsOf(post) {
  const out = [];
  const media = post.media || [];
  const images = media.filter((m) => m.kind === "image").length;
  const videos = media.length - images;
  if (post.type === "image" && (media.length !== 1 || images !== 1)) out.push(t("ig.prob.image"));
  if (post.type === "carousel" && (media.length < 2 || media.length > 10)) out.push(t("ig.prob.carousel"));
  if (post.type === "reel" && (media.length !== 1 || videos !== 1)) out.push(t("ig.prob.reel"));
  if (post.type === "story" && media.length !== 1) out.push(t("ig.prob.story"));
  if (post.type !== "story") {
    for (const m of media) {
      if (m.kind === "image" && m.width && m.height && (m.width / m.height < 0.79 || m.width / m.height > 1.92)) { out.push(t("ig.prob.ratio")); break; }
    }
    if (!String(post.caption || "").trim()) out.push(t("ig.prob.noCaption"));
  }
  const caption = String(post.caption || "");
  if (caption.length > MAX_CAPTION) out.push(t("ig.prob.long", { n: caption.length }));
  if (hashtagCount(caption) > MAX_HASHTAGS) out.push(t("ig.prob.tags"));
  if (CREATIVE_RULE.test(caption)) out.push(t("ig.prob.rule"));
  return out;
}

function localInputValue(ms) {
  const d = new Date(ms - new Date(ms).getTimezoneOffset() * 60000);
  return d.toISOString().slice(0, 16);
}

const millis = (v) => (v && typeof v.toMillis === "function" ? v.toMillis() : typeof v === "number" ? v : null);

// ---------------------------------------------------------------------------
// Media: browser-side preparation and upload.
// ---------------------------------------------------------------------------

function loadImage(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => resolve({ img, url });
    img.onerror = () => { URL.revokeObjectURL(url); reject(new Error(t("ig.badImage", { name: file.name }))); };
    img.src = url;
  });
}

// Any picture → a JPEG Instagram accepts: at most 1440 px wide and, for the
// feed, cropped to the nearest allowed shape (4:5 … 1.91:1) around its
// centre. A story keeps its shape.
async function prepareImage(file, { story }) {
  const { img, url } = await loadImage(file);
  try {
    let sx = 0, sy = 0, sw = img.naturalWidth, sh = img.naturalHeight;
    if (!story) {
      const ratio = sw / sh;
      if (ratio < 0.8) { const nh = Math.round(sw / 0.8); sy = Math.round((sh - nh) / 2); sh = nh; }
      else if (ratio > 1.91) { const nw = Math.round(sh * 1.91); sx = Math.round((sw - nw) / 2); sw = nw; }
    }
    const scale = Math.min(1, 1440 / sw);
    const w = Math.round(sw * scale), hgt = Math.round(sh * scale);
    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = hgt;
    const ctx = canvas.getContext("2d");
    ctx.fillStyle = "#fff";
    ctx.fillRect(0, 0, w, hgt);
    ctx.drawImage(img, sx, sy, sw, sh, 0, 0, w, hgt);
    let quality = 0.92;
    let blob = await new Promise((r) => canvas.toBlob(r, "image/jpeg", quality));
    while (blob && blob.size > 7.5 * 1024 * 1024 && quality > 0.5) {
      quality -= 0.1;
      blob = await new Promise((r) => canvas.toBlob(r, "image/jpeg", quality));
    }
    if (!blob) throw new Error(t("ig.badImage", { name: file.name }));
    return { blob, contentType: "image/jpeg", kind: "image", width: w, height: hgt, ext: "jpg" };
  } finally {
    URL.revokeObjectURL(url);
  }
}

function prepareVideo(file) {
  const type = (file.type || "").toLowerCase();
  const contentType = type === "video/quicktime" || /\.mov$/i.test(file.name) ? "video/quicktime" : "video/mp4";
  if (file.size >= 100 * 1024 * 1024) throw new Error(t("ig.videoTooBig", { name: file.name }));
  return { blob: file, contentType, kind: "video", ext: contentType === "video/quicktime" ? "mov" : "mp4" };
}

const isVideo = (file) => /^video\//.test(file.type || "") || /\.(mp4|mov)$/i.test(file.name);

function uploadOne(postId, prepared, onProgress) {
  const name = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}.${prepared.ext}`;
  const path = `marketing/instagram/${postId}/${name}`;
  return new Promise((resolve, reject) => {
    const task = uploadBytesResumable(storageRef(storage, path), prepared.blob, { contentType: prepared.contentType });
    task.on("state_changed", (s) => onProgress(s.bytesTransferred / Math.max(1, s.totalBytes)), reject, () => {
      const item = { path, kind: prepared.kind, contentType: prepared.contentType };
      if (prepared.width) { item.width = prepared.width; item.height = prepared.height; }
      resolve(item);
    });
  });
}

// Files from a picker → uploaded media items, in order, with one progress line.
async function uploadFiles(postId, files, { story, progress }) {
  const out = [];
  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    progress.textContent = t("ig.preparing", { i: i + 1, n: files.length });
    const prepared = isVideo(file) ? prepareVideo(file) : await prepareImage(file, { story });
    out.push(await uploadOne(postId, prepared, (p) => { progress.textContent = t("ig.uploading", { i: i + 1, n: files.length, p: Math.round(p * 100) }); }));
  }
  progress.textContent = "";
  return out;
}

function guessType(media, story) {
  if (story) return "story";
  if (media.length === 1 && media[0].kind === "video") return "reel";
  return media.length > 1 ? "carousel" : "image";
}

// ---------------------------------------------------------------------------
// Preview: the post the way Instagram shows it.
// ---------------------------------------------------------------------------

function preview(post, account) {
  const media = post.media || [];
  let index = 0;
  const tall = post.type === "story" || post.type === "reel";
  const stage = h("div.ig-stage", { style: { aspectRatio: tall ? "9 / 16" : "4 / 5" } });
  const dots = h("div.ig-dots");
  const prev = button("‹", { kind: "ghost icon", class: "ig-nav ig-prev", "aria-label": t("ig.prev") });
  const next = button("›", { kind: "ghost icon", class: "ig-nav ig-next", "aria-label": t("ig.next") });
  const paint = async () => {
    clear(stage);
    clear(dots);
    if (!media.length) { stage.append(h("div.empty", t("ig.noMedia"))); return; }
    const m = media[index];
    const url = await storageUrl(m.path);
    if (m.kind === "video") stage.append(h("video", { src: url || "", controls: true, muted: true, playsInline: true, preload: "metadata" }));
    else stage.append(h("img", { src: url || "", alt: "" }));
    media.forEach((_, i) => dots.append(h(`span${i === index ? ".on" : ""}`)));
    prev.hidden = index === 0;
    next.hidden = index >= media.length - 1;
  };
  prev.addEventListener("click", () => { index = Math.max(0, index - 1); paint(); });
  next.addEventListener("click", () => { index = Math.min(media.length - 1, index + 1); paint(); });
  paint();
  const user = (account && account.username) || "easyplate";
  const head = h("div.ig-head", account && account.picture ? h("img.ig-avatar", { src: account.picture, alt: "" }) : h("span.ig-avatar"), h("b", user));
  const caption = post.type === "story" ? null : h("div.ig-caption", { dir: "auto" }, h("b", user + " "), post.caption || "");
  return h("div.ig-phone", head, h("div.ig-media", stage, prev, next), media.length > 1 ? dots : null, caption);
}

// ---------------------------------------------------------------------------
// The page.
// ---------------------------------------------------------------------------

export async function mount({ view, actions }) {
  let tab = "drafts";
  let posts = [];
  let account = null;
  let accountState = null;

  const accountBox = h("div");
  const tabsBox = h("div");
  const listBox = h("div");
  view.append(accountBox, tabsBox, listBox);

  const newBtn = button(t("ig.newPost"), { kind: "primary" });
  newBtn.addEventListener("click", () => newPost());
  actions.append(newBtn);

  // ---- account -------------------------------------------------------------

  async function loadAccount() {
    clear(accountBox).append(spinner());
    try {
      accountState = await call("ig.account.get");
      account = accountState.account;
    } catch (e) {
      accountState = { connected: false, error: e.message };
    }
    renderAccount();
  }

  function renderAccount() {
    clear(accountBox);
    if (!accountState || !accountState.connected) { accountBox.append(connectCard()); return; }
    const a = account || {};
    const expires = millis(a.expiresAt);
    const daysLeft = expires ? Math.max(0, Math.round((expires - Date.now()) / 86400000)) : null;
    const quota = accountState.quota;
    const tile = (label, value, sub) => h("div.tile", h("div.label", label), h("div.value", value), sub ? h("div.sub", sub) : null);
    const refreshBtn = button(t("ig.refreshStats"), { kind: "small" });
    refreshBtn.addEventListener("click", busy(refreshBtn, async () => {
      try { const r = await call("ig.insights.refresh"); toast(t("ig.statsRefreshed", { n: r.refreshed }), "ok"); await loadAccount(); } catch (e) { toastError(e); }
    }));
    const disconnectBtn = button(t("ig.disconnect"), { kind: "small ghost" });
    disconnectBtn.addEventListener("click", async () => {
      if (!(await confirmDialog({ title: t("ig.disconnect"), text: t("ig.disconnectText"), danger: true, okLabel: t("ig.disconnect") }))) return;
      try { await call("ig.account.disconnect"); await loadAccount(); } catch (e) { toastError(e); }
    });
    const card = h("div.card.stack",
      h("div.row.between",
        h("div.row", a.picture ? h("img.ig-avatar.lg", { src: a.picture, alt: "" }) : null,
          h("div", h("h3", h("a", { href: `https://www.instagram.com/${a.username || ""}/`, target: "_blank", rel: "noopener" }, "@" + (a.username || "?"))), h("div.small.muted", a.name || ""))),
        h("div.row", refreshBtn, disconnectBtn)),
      h("div.tiles",
        tile(t("ig.followers"), fmtNumber(a.followers)),
        tile(t("ig.postsOnProfile"), fmtNumber(a.mediaCount)),
        tile(t("ig.quota"), quota ? `${fmtNumber(quota.total - quota.used)} / ${fmtNumber(quota.total)}` : "—", t("ig.quotaSub")),
        tile(t("ig.token"), daysLeft === null ? "—" : t("ig.daysLeft", { n: daysLeft }), t("ig.tokenSub"))),
      accountState.tokenExpired ? h("div.error", t("ig.tokenExpired")) : accountState.error ? h("div.small.warn", accountState.error) : null,
      accountState.tokenExpired ? connectForm() : null);
    accountBox.append(card);
  }

  function connectForm() {
    const token = textarea({ rows: 3, dir: "ltr", placeholder: "IGAA…", autocomplete: "off", spellcheck: false });
    const go = button(t("ig.connect"), { kind: "primary" });
    go.addEventListener("click", busy(go, async () => {
      const value = token.value.trim();
      if (!value) return toast(t("ig.pasteToken"), "error");
      try {
        const r = await call("ig.account.connect", { token: value });
        toast(t("ig.connected", { user: r.account.username }), "ok");
        await loadAccount();
      } catch (e) { toastError(e); }
    }));
    return h("div.stack", field(t("ig.tokenLabel"), token, t("ig.tokenHint")), h("div.row", go));
  }

  function connectCard() {
    const steps = h("ol.steps", ["step1", "step2", "step3", "step4"].map((k) => h("li", t(`ig.setup.${k}`))));
    return h("div.card.stack", h("h3", t("ig.notConnected")), h("p.muted", t("ig.setup.intro")), steps,
      h("a", { href: "https://developers.facebook.com/apps", target: "_blank", rel: "noopener" }, "developers.facebook.com/apps ↗"),
      connectForm());
  }

  // ---- list ----------------------------------------------------------------

  function renderTabs() {
    const count = (k) => posts.filter((p) => TAB_STATUSES[k].includes(p.status)).length;
    clear(tabsBox).append(tabs([
      ["drafts", `${t("ig.tabs.drafts")} (${count("drafts")})`],
      ["scheduled", `${t("ig.tabs.scheduled")} (${count("scheduled")})`],
      ["published", `${t("ig.tabs.published")} (${count("published")})`],
    ], tab, (k) => { tab = k; renderList(); }));
  }

  function card(p) {
    const thumb = h("div.ig-thumb");
    const first = (p.media || [])[0];
    if (first) storageUrl(first.path).then((url) => {
      if (!url) return;
      thumb.append(first.kind === "video" ? h("video", { src: url, muted: true, preload: "metadata" }) : h("img", { src: url, alt: "", loading: "lazy" }));
    });
    if ((p.media || []).length > 1) thumb.append(h("span.ig-count", `1/${p.media.length}`));
    if (first && first.kind === "video") thumb.append(h("span.ig-count.ig-play", "▶"));
    const when = p.status === "scheduled" ? t("ig.at", { date: fmtDate(millis(p.scheduledAt)) })
      : p.status === "published" ? t("ig.publishedAt", { date: fmtDate(millis(p.published && p.published.at)) })
      : t("ig.updated", { date: fmtDate(millis(p.updatedAt)) });
    const ins = p.insights;
    const stats = ins ? h("div.small.muted", `❤ ${fmtNumber(ins.likes)} · 💬 ${fmtNumber(ins.comments)}${ins.reach !== undefined ? ` · 👁 ${fmtNumber(ins.reach)}` : ""}${ins.saved !== undefined ? ` · 🔖 ${fmtNumber(ins.saved)}` : ""}`) : null;
    const el = h("div.card.ig-card", { tabIndex: 0, role: "button" }, thumb,
      h("div.stack", { style: { gap: "6px" } },
        h("div.row", { style: { gap: "6px" } }, badge(t(`ig.status.${p.status}`), STATUS_COLORS[p.status]), badge(t(`ig.types.${p.type}`)), p.source === "claude" ? badge("Claude", "brand") : null),
        p.title ? h("b", p.title) : null,
        h("div.small.clamp2", { dir: "auto" }, p.caption || "—"),
        h("div.small.muted", when),
        stats,
        p.status === "failed" && p.error ? h("div.small.warn.clamp2", p.error) : null));
    el.addEventListener("click", () => openPost(p.id));
    el.addEventListener("keydown", (e) => { if (e.key === "Enter") openPost(p.id); });
    return el;
  }

  function renderList() {
    renderTabs();
    clear(listBox);
    const rows = posts.filter((p) => TAB_STATUSES[tab].includes(p.status));
    if (tab === "scheduled") rows.sort((a, b) => (millis(a.scheduledAt) || 0) - (millis(b.scheduledAt) || 0));
    if (tab === "published") rows.sort((a, b) => (millis(b.published && b.published.at) || 0) - (millis(a.published && a.published.at) || 0));
    if (!rows.length) { listBox.append(empty(t(`ig.empty.${tab}`))); return; }
    listBox.append(h("div.cards.ig-cards", rows.map(card)));
  }

  // ---- one post ------------------------------------------------------------

  let openClose = null;
  let openId = null;
  let openSig = "";
  const current = (id) => posts.find((p) => p.id === id);
  // What makes the open window worth redrawing: a write to that post.
  const sigOf = (p) => (p ? `${p.status}|${millis(p.updatedAt)}|${millis(p.insights && p.insights.at)}|${p.published ? p.published.mediaId : ""}` : "");

  function openPost(id) {
    if (openClose) openClose();
    openId = id;
    openSig = sigOf(current(id));
    openClose = modal({ title: t("ig.post"), wide: true, body: (close) => postBody(current(id), close), onClose: () => { openClose = null; openId = null; } });
  }

  // Re-render the open post when its document changes (published by the
  // runner, stats refreshed) — but never under the operator's typing.
  let dirtyEditor = false;
  function refreshOpen() {
    if (!openId || dirtyEditor) return;
    const p = current(openId);
    if (!p) { if (openClose) openClose(); return; }
    if (sigOf(p) === openSig) return;
    openPost(openId);
  }

  function postBody(p, close) {
    dirtyEditor = false;
    if (!p) return empty();
    const editable = ["draft", "approved", "scheduled", "failed"].includes(p.status);
    const draft = { ...p, media: [...(p.media || [])] };
    const left = h("div.stack");
    const paintPreview = () => clear(left).append(preview(draft, account));
    paintPreview();

    const right = h("div.stack");
    const head = h("div.row", { style: { gap: "6px" } }, badge(t(`ig.status.${p.status}`), STATUS_COLORS[p.status]), badge(t(`ig.types.${p.type}`)), p.source === "claude" ? badge("Claude", "brand") : null);
    right.append(head);
    if (p.status === "failed" && p.error) right.append(h("div.error", p.error));
    if (p.status === "scheduled") right.append(h("div.small", t("ig.at", { date: fmtDate(millis(p.scheduledAt)) })));
    if (p.status === "publishing") right.append(h("div.row", h("span.spinner"), t("ig.publishingNow")));

    if (p.status === "published") {
      right.append(publishedPanel(p));
    } else if (editable) {
      right.append(editorPanel(p, draft, paintPreview, close));
    }
    const del = button(t("common.delete"), { kind: "danger small" });
    del.addEventListener("click", async () => {
      const text = p.status === "published" ? t("ig.deletePublished") : t("ig.deleteText");
      if (!(await confirmDialog({ title: t("ig.deleteTitle"), text }))) return;
      try { await call("ig.post.delete", { id: p.id }); toast(t("common.deleted"), "ok"); close(); } catch (e) { toastError(e); }
    });
    if (p.status !== "publishing") right.append(h("div.row", { style: { justifyContent: "flex-end" } }, del));
    return h("div.ig-editor", left, right);
  }

  function editorPanel(p, draft, paintPreview, close) {
    const markDirty = () => { dirtyEditor = true; };
    const title = input({ value: p.title || "", maxLength: 120, placeholder: t("ig.titlePh") });
    const type = select(TYPES.map((k) => [k, t(`ig.types.${k}`)]), { value: draft.type });
    const caption = textarea({ rows: 10, dir: "auto" });
    caption.value = p.caption || "";
    const counter = h("div.small.muted");
    const probs = h("ul.small.warn.ig-probs");
    const paintChecks = () => {
      draft.caption = caption.value;
      draft.type = type.value;
      counter.textContent = t("ig.counter", { c: caption.value.length, max: MAX_CAPTION, h: hashtagCount(caption.value), hmax: MAX_HASHTAGS });
      clear(probs);
      for (const x of problemsOf(draft)) probs.append(h("li", x));
    };
    caption.addEventListener("input", () => { markDirty(); paintChecks(); paintPreview(); });
    type.addEventListener("change", () => { markDirty(); paintChecks(); paintPreview(); });
    title.addEventListener("input", markDirty);

    // Media: reorder, remove, add.
    const mediaBox = h("div.ig-media-list");
    const progress = h("div.small.muted");
    const paintMedia = () => {
      clear(mediaBox);
      draft.media.forEach((m, i) => {
        const cell = h("div.ig-media-cell");
        storageUrl(m.path).then((url) => { if (url) cell.prepend(m.kind === "video" ? h("video", { src: url, muted: true, preload: "metadata" }) : h("img", { src: url, alt: "" })); });
        const move = (d) => { const j = i + d; if (j < 0 || j >= draft.media.length) return; [draft.media[i], draft.media[j]] = [draft.media[j], draft.media[i]]; markDirty(); paintMedia(); paintPreview(); paintChecks(); };
        cell.append(h("div.ig-media-tools",
          button("‹", { kind: "ghost icon small", "aria-label": t("ig.moveBack"), onclick: () => move(-1) }),
          button("✕", { kind: "ghost icon small", "aria-label": t("common.remove"), onclick: () => { draft.media.splice(i, 1); markDirty(); paintMedia(); paintPreview(); paintChecks(); } }),
          button("›", { kind: "ghost icon small", "aria-label": t("ig.moveForward"), onclick: () => move(1) })));
        mediaBox.append(cell);
      });
      const picker = h("input", { type: "file", accept: "image/*,video/mp4,video/quicktime", multiple: true, hidden: true });
      const add = h("button.ig-media-cell.ig-add", { type: "button", "aria-label": t("ig.addMedia") }, "+");
      add.addEventListener("click", () => picker.click());
      picker.addEventListener("change", async () => {
        const files = [...picker.files];
        if (!files.length) return;
        try {
          const items = await uploadFiles(p.id, files, { story: type.value === "story", progress });
          draft.media.push(...items);
          markDirty();
          paintMedia(); paintPreview(); paintChecks();
        } catch (e) { progress.textContent = ""; toastError(e); }
      });
      mediaBox.append(add, picker);
    };
    paintMedia();
    paintChecks();

    const payload = () => ({ id: p.id, type: type.value, title: title.value.trim(), caption: caption.value, media: draft.media, source: p.source });
    const save = async () => { await call("ig.post.save", payload()); dirtyEditor = false; };
    const unchanged = () => !dirtyEditor;

    const buttons = h("div.row");
    const mk = (label, kind, fn) => { const b = button(label, { kind }); b.addEventListener("click", busy(b, async () => { try { await fn(); } catch (e) { toastError(e); } })); buttons.append(b); return b; };

    mk(t("common.save"), "", async () => { await save(); toast(t("ig.savedDraft"), "ok"); refreshOpenSoon(); });
    if (["draft", "failed"].includes(p.status)) {
      mk(t("ig.approve"), "primary", async () => {
        if (!unchanged()) await save();
        await call("ig.post.approve", { id: p.id });
        toast(t("ig.approved"), "ok");
        refreshOpenSoon();
      });
    }
    if (["approved", "scheduled"].includes(p.status)) {
      mk(t("ig.publishNow"), "primary", async () => {
        if (!unchanged()) return toast(t("ig.saveFirst"), "error");
        if (!(await confirmDialog({ title: t("ig.publishNow"), text: t("ig.publishConfirm"), danger: false, okLabel: t("ig.publishNow") }))) return;
        toast(t("ig.publishingNow"));
        const r = await call("ig.post.publish", { id: p.id });
        toast(t("ig.publishedOk"), "ok");
        if (r.permalink) window.open(r.permalink, "_blank", "noopener");
        refreshOpenSoon();
      });
      const at = input({ type: "datetime-local", dir: "ltr", value: localInputValue(millis(p.scheduledAt) || Date.now() + 3600000) });
      const schedBtn = button(p.status === "scheduled" ? t("ig.reschedule") : t("ig.schedule"));
      schedBtn.addEventListener("click", busy(schedBtn, async () => {
        if (!unchanged()) return toast(t("ig.saveFirst"), "error");
        const ms = new Date(at.value).getTime();
        try { await call("ig.post.schedule", { id: p.id, at: ms }); toast(t("ig.scheduledOk", { date: fmtDate(ms) }), "ok"); refreshOpenSoon(); } catch (e) { toastError(e); }
      }));
      buttons.append(h("div.row", { style: { gap: "6px" } }, at, schedBtn));
      if (p.status === "scheduled") mk(t("ig.unschedule"), "ghost", async () => { await call("ig.post.unschedule", { id: p.id }); refreshOpenSoon(); });
      mk(t("ig.backToDraft"), "ghost", async () => { await call("ig.post.unapprove", { id: p.id }); refreshOpenSoon(); });
    }

    return h("div.stack",
      field(t("ig.title"), title, t("ig.titleHint")),
      field(t("ig.type"), type),
      field(t("ig.media"), h("div.stack", mediaBox, progress), t("ig.mediaHint")),
      field(t("ig.caption"), withEmoji(caption)),
      counter, probs,
      p.status !== "draft" && p.status !== "failed" ? h("div.small.muted", t("ig.editResets")) : null,
      buttons);
  }

  function publishedPanel(p) {
    const ins = p.insights || {};
    const tile = (label, v) => h("div.tile", h("div.label", label), h("div.value", v === undefined ? "—" : fmtNumber(v)));
    const out = h("div.stack");
    if (p.published && p.published.permalink) out.append(h("a", { href: p.published.permalink, target: "_blank", rel: "noopener" }, t("ig.openOnInstagram")));
    out.append(h("div.tiles", tile(t("ig.likes"), ins.likes), tile(t("ig.comments"), ins.comments), tile(t("ig.reach"), ins.reach), tile(t("ig.saves"), ins.saved), tile(t("ig.shares"), ins.shares), tile(t("ig.views"), ins.views)));
    const refreshBtn = button(t("ig.refreshStats"), { kind: "small" });
    refreshBtn.addEventListener("click", busy(refreshBtn, async () => { try { await call("ig.insights.refresh", { id: p.id }); refreshOpenSoon(); } catch (e) { toastError(e); } }));
    out.append(h("div.row", refreshBtn, ins.at ? h("span.small.muted", t("ig.statsAt", { date: fmtDate(millis(ins.at)) })) : null));
    out.append(h("div.small.muted", h("b", t("ig.caption") + ": "), h("span", { dir: "auto", style: { whiteSpace: "pre-wrap" } }, p.caption || "")));
    const comments = h("div.stack");
    out.append(h("h3", t("ig.comments")), comments);
    loadComments(p, comments);
    return out;
  }

  async function loadComments(p, box) {
    clear(box).append(spinner());
    let list;
    try { list = (await call("ig.comments.list", { id: p.id })).comments; } catch (e) { clear(box).append(h("div.small.warn", e.message)); return; }
    clear(box);
    if (!list.length) { box.append(empty(t("ig.noComments"))); return; }
    for (const c of list) box.append(commentRow(p, c, box, true));
  }

  function commentRow(p, c, box, top) {
    const hideBtn = button(c.hidden ? t("ig.unhide") : t("ig.hide"), { kind: "ghost small" });
    hideBtn.addEventListener("click", busy(hideBtn, async () => { try { await call("ig.comment.hide", { commentId: c.id, hide: !c.hidden }); loadComments(p, box); } catch (e) { toastError(e); } }));
    const row = h(`div.ig-comment${c.hidden ? ".hidden" : ""}`,
      h("div.row.between", h("b", "@" + c.username), h("span.small.muted", c.at ? fmtDate(c.at) : "")),
      h("div", { dir: "auto" }, c.text),
      h("div.row", hideBtn));
    if (top) {
      const reply = input({ dir: "auto", placeholder: t("ig.replyPh") });
      const send = button(t("ig.reply"), { kind: "small primary" });
      send.addEventListener("click", busy(send, async () => {
        const text = reply.value.trim();
        if (!text) return;
        try { await call("ig.comment.reply", { commentId: c.id, text }); toast(t("ig.replied"), "ok"); loadComments(p, box); } catch (e) { toastError(e); }
      }));
      row.append(h("div.row", { style: { flexWrap: "nowrap" } }, reply, send));
      for (const r of c.replies || []) row.append(h("div.ig-reply", commentRow(p, r, box, false)));
    }
    return row;
  }

  // After an action the listener brings the new state; re-open on it.
  function refreshOpenSoon() { dirtyEditor = false; setTimeout(refreshOpen, 400); }

  // ---- new post ------------------------------------------------------------

  function newPost() {
    const postId = doc(collection(db, "instagram_posts")).id;
    const picker = h("input", { type: "file", accept: "image/*,video/mp4,video/quicktime", multiple: true });
    const story = h("input", { type: "checkbox" });
    const title = input({ maxLength: 120, placeholder: t("ig.titlePh") });
    const caption = textarea({ rows: 6, dir: "auto" });
    const progress = h("div.small.muted");
    modal({
      title: t("ig.newPost"),
      body: h("div.stack",
        field(t("ig.files"), picker, t("ig.filesHint")),
        h("label.row", { style: { gap: "6px" } }, story, t("ig.asStory")),
        field(t("ig.title"), title, t("ig.titleHint")),
        field(t("ig.caption"), withEmoji(caption)),
        progress),
      actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => {
        const b = button(t("ig.createDraft"), { kind: "primary" });
        b.addEventListener("click", busy(b, async () => {
          const files = [...picker.files];
          if (!files.length) return toast(t("ig.pickFiles"), "error");
          if (files.length > 10) return toast(t("ig.prob.carousel"), "error");
          try {
            const media = await uploadFiles(postId, files, { story: story.checked, progress });
            const r = await call("ig.post.save", { id: postId, type: guessType(media, story.checked), title: title.value.trim(), caption: caption.value, media, source: "upload" });
            toast(t("ig.savedDraft"), "ok");
            c();
            tab = "drafts";
            setTimeout(() => openPost(r.id), 500);
          } catch (e) { progress.textContent = ""; toastError(e); }
        }));
        return b;
      }],
    });
  }

  // ---- live ----------------------------------------------------------------

  listBox.append(spinner());
  const stop = onSnapshot(query(collection(db, "instagram_posts"), orderBy("updatedAt", "desc"), limit(300)), (snap) => {
    posts = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    renderList();
    refreshOpen();
  }, (err) => { clear(listBox).append(h("div.card.error", err.message)); });

  loadAccount();
  return () => { stop(); if (openClose) openClose(); };
}
