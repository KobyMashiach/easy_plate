// The forum: threads and replies live, written as the administrator or as
// a persona, drafted by the model when asked, dated back when the feed
// should not look like it was filled in one afternoon.
import { db, collection, doc, onSnapshot, query, orderBy, limit } from "../firebase.js";
import { t, fmtNumber, fmtDate, currentLang, LANGS } from "../i18n.js";
import { h, clear, append, spinner, avatar, badge, when, button, busy, select, input, textarea, field, modal, confirmDialog, promptDialog, toast, toastError, empty, debounce } from "../ui.js";
import { authorOptions, isPersona } from "../data.js";
import { call } from "../api.js";

const DAYS_BACK = 45;

function randomPast(days = DAYS_BACK) {
  return Date.now() - Math.floor(Math.random() * days * 86400000);
}

function toLocalInput(ms) {
  const d = new Date(ms);
  const pad = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

// The composer every post and reply shares: author, text, date, AI draft.
export async function composer({ kind, context, onSubmit, title: showTitle = false, initial = {} }) {
  const options = await authorOptions();
  const as = select(options, { value: initial.as || (options.length > 1 ? options[Math.floor(Math.random() * (options.length - 1)) + 1][0] : "me") });
  const titleCtl = input({ value: initial.title || "", placeholder: t("common.title") });
  const body = textarea({ value: initial.body || "", placeholder: t("common.body") });
  const topic = input({ placeholder: t("forum.topic") });
  const date = input({ type: "datetime-local", value: toLocalInput(initial.createdAt || Date.now()) });
  const draft = button(t("forum.draftAi"), { kind: "small" });
  draft.addEventListener("click", busy(draft, async () => {
    try {
      const persona = as.value === "me" ? "" : (options.find((o) => o[0] === as.value) || [])[1];
      const r = await call("text.generate", { kind, lang: currentLang(), topic: topic.value.trim(), context: context || "", persona });
      if (showTitle && r.title) titleCtl.value = r.title;
      body.value = r.body || "";
    } catch (e) { toastError(e); }
  }));
  const form = h("div.stack",
    h("div.grid2", field(t("forum.as"), as), field(t("forum.backdate"), h("div.row", date, button(t("common.random"), { kind: "small", title: t("forum.randomDate", { days: DAYS_BACK }), onclick: () => { date.value = toLocalInput(randomPast()); } })))),
    showTitle ? field(t("common.title"), titleCtl) : null,
    field(t("common.body"), body),
    h("div.row", topic, draft),
  );
  const submit = (c) => {
    const b = button(initial.id ? t("common.save") : t("common.publish"), { kind: "primary" });
    b.addEventListener("click", busy(b, async () => {
      if (!body.value.trim() || (showTitle && !titleCtl.value.trim())) return;
      const createdAt = date.value ? new Date(date.value).getTime() : Date.now();
      try { await onSubmit({ as: as.value, title: titleCtl.value.trim(), body: body.value.trim(), createdAt }); c(); } catch (e) { toastError(e); }
    }));
    return b;
  };
  return { form, submit };
}

async function likeControls({ kind, postId, replyId, recipeId, onDone }) {
  const options = await authorOptions();
  const as = select(options, { value: "me" });
  const like = button("♥", { kind: "small", title: t("forum.likeAs") });
  like.addEventListener("click", busy(like, async () => {
    try { await call("community.like", { as: as.value, kind, postId, replyId, recipeId, on: true }); toast(t("common.done"), "ok"); onDone && onDone(); } catch (e) { toastError(e); }
  }));
  const seed = button(t("forum.seedLikes"), { kind: "small" });
  seed.addEventListener("click", async () => {
    const n = await promptDialog({ title: t("forum.seedLikes"), label: t("forum.seedLikesCount"), value: "5" });
    if (n === null) return;
    try { const r = await call("community.seedLikes", { kind, postId, replyId, recipeId, count: Number(n) || 0 }); toast(t("forum.added", { n: r.added }), "ok"); onDone && onDone(); } catch (e) { toastError(e); }
  });
  return h("div.row", h("div.row", as, like), seed);
}

export { likeControls };

// The forum wizard: N whole conversations by the personas, one call each.
export async function openForumSeeder() {
  const options = await authorOptions();
  if (options.length < 3) { toast(t("seed.noPersonas"), "error"); return; }
  const count = input({ type: "number", min: 1, max: 40, value: 10 });
  const lang = select(Object.entries(LANGS), { value: currentLang() });
  const topic = input({ placeholder: t("seed.themeHint") });
  const replies = input({ type: "number", min: 0, max: 12, value: 4 });
  const days = input({ type: "number", min: 0, max: 365, value: DAYS_BACK });
  const likes = input({ type: "number", min: 0, max: 50, value: 5 });
  const progress = h("div.stack");
  let stop = false;
  const stopBtn = button(t("seed.stop"), { kind: "small danger", hidden: true, onclick: () => { stop = true; stopBtn.disabled = true; } });
  const runBtn = button(t("seedForum.run", { n: count.value }), { kind: "primary" });
  count.addEventListener("input", () => { runBtn.textContent = t("seedForum.run", { n: count.value }); });
  runBtn.addEventListener("click", busy(runBtn, async () => {
    const n = Math.max(1, Math.min(40, Number(count.value) || 1));
    stop = false; stopBtn.hidden = false; stopBtn.disabled = false;
    clear(progress);
    const status = h("p.small.muted");
    progress.append(status);
    let made = 0, failed = 0;
    for (let i = 0; i < n; i++) {
      if (stop) break;
      status.textContent = t("seedForum.running", { i: i + 1, n });
      const row = h("div.row", h("span.spinner"), h("span.muted", "…"));
      progress.append(row);
      try {
        const r = await call("forum.seedThread", { lang: lang.value, topic: topic.value.trim(), replies: Math.round(Math.random() * (Number(replies.value) || 0)), days: Number(days.value) || 0, likes: Math.round(Math.random() * (Number(likes.value) || 0)) });
        made++;
        clear(row);
        append(row, [badge("✓", "green"), h("a", { href: `#/community/${r.postId}` }, r.title), h("span.small.muted", `${t("seed.by")} ${r.authorName}`), badge(t("seedForum.replyCount", { n: r.replies })), r.liked ? badge(`♥ ${r.liked}`) : null]);
      } catch (e) {
        failed++;
        clear(row);
        append(row, [badge("✕", "red"), h("span.small.error", e.message)]);
      }
    }
    stopBtn.hidden = true;
    status.textContent = t("seedForum.done", { n: made, failed });
    toast(t("seedForum.done", { n: made, failed }), made ? "ok" : "error");
  }));
  modal({
    title: t("seedForum.title"),
    wide: true,
    body: h("div.stack",
      h("div.grid3", field(t("seedForum.count"), count), field(t("recipes.language"), lang), field(t("seedForum.replies"), replies)),
      h("div.grid3", field(t("seed.theme"), topic), field(t("seed.days"), days), field(t("seed.likes"), likes)),
      progress,
    ),
    actions: [(c) => button(t("common.close"), { onclick: c }), () => stopBtn, () => runBtn],
  });
}

function authorLine(p) {
  return h("div.meta", avatar(p.authorName, p.authorPhotoUrl, "sm"), h("a", { href: `#/users/${p.authorUid}` }, p.authorName || t("common.unnamed")), isPersona(p.authorUid) ? badge(t("users.persona"), "brand") : null, when(p.createdAt), p.editedAt ? h("span.muted", `(${t("config.edited").toLowerCase()})`) : null);
}

async function threadList({ view, actions }) {
  let posts = [], search = "";
  const list = h("div.list");
  const count = h("span.muted.small");
  view.append(h("div.toolbar", h("div.search", input({ placeholder: t("common.search"), oninput: debounce((e) => { search = e.target.value.trim().toLowerCase(); render(); }, 150) })), count), list);

  actions.append(button(t("seedForum.title"), { kind: "small", onclick: openForumSeeder }));
  const newThread = button(t("forum.newThread"), { kind: "primary small" });
  newThread.addEventListener("click", async () => {
    const { form, submit } = await composer({ kind: "thread", title: true, onSubmit: async (d) => { await call("forum.post.create", d); toast(t("forum.posted"), "ok"); } });
    modal({ title: t("forum.newThread"), wide: true, body: form, actions: [(c) => button(t("common.cancel"), { onclick: c }), submit] });
  });
  actions.append(newThread);

  const render = () => {
    const rows = search ? posts.filter((p) => [p.title, p.body, p.authorName].some((v) => String(v || "").toLowerCase().includes(search))) : posts;
    count.textContent = t("forum.threads", { n: fmtNumber(rows.length) });
    clear(list);
    if (!rows.length) { list.append(empty()); return; }
    for (const p of rows) {
      list.append(h("div.item", h("div.body",
        h("a", { href: `#/community/${p.id}`, style: { fontWeight: 700, fontSize: "15px" } }, p.title),
        h("div.clamp2.small.muted", p.body),
        h("div.row", authorLine(p), badge(t("forum.replies", { n: p.replyCount || 0 })), badge(t("forum.likes", { n: p.likeCount || 0 }))),
      )));
    }
  };
  const unsub = onSnapshot(query(collection(db, "forum_posts"), orderBy("createdAt", "desc"), limit(150)), (snap) => { posts = snap.docs.map((d) => ({ id: d.id, ...d.data() })); render(); }, toastError);
  return unsub;
}

async function thread({ view, actions, postId, setTitle }) {
  let post = null, replies = [];
  const head = h("div.card");
  const list = h("div.list");
  view.append(h("a", { href: "#/community" }, `← ${t("common.back")}`), head, h("h3", t("forum.replies", { n: "" }).trim()), list);
  const likes = await likeControls({ kind: "post", postId });

  const renderHead = () => {
    clear(head);
    if (!post) { head.append(empty()); return; }
    setTitle(post.title);
    head.append(
      h("h3", post.title),
      h("p.pre", post.body),
      h("div.row.between", authorLine(post), h("div.row", badge(t("forum.likes", { n: post.likeCount || 0 })), badge(t("forum.replies", { n: post.replyCount || 0 })))),
      h("div.row", likes,
        button(t("forum.edit"), { kind: "small", onclick: () => edit() }),
        button(t("forum.reply"), { kind: "small primary", onclick: () => reply() }),
        button(t("forum.deleteThread"), { kind: "small danger", onclick: async () => {
          if (!(await confirmDialog({ title: t("forum.deleteThread") }))) return;
          try { await call("forum.post.delete", { postId }); toast(t("common.deleted"), "ok"); location.hash = "#/community"; } catch (e) { toastError(e); }
        } }),
      ),
    );
  };
  const edit = () => {
    const titleCtl = input({ value: post.title });
    const body = textarea({ value: post.body });
    modal({ title: t("forum.editThread"), body: h("div.stack", field(t("common.title"), titleCtl), field(t("common.body"), body)), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.save"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => { try { await call("forum.post.update", { postId, title: titleCtl.value.trim(), body: body.value.trim() }); toast(t("common.saved"), "ok"); c(); } catch (e) { toastError(e); } })); return b; }] });
  };
  const context = () => [`${post.authorName}: ${post.title}\n${post.body}`, ...replies.map((r) => `${r.authorName}: ${r.body}`)].join("\n---\n").slice(0, 4000);
  const reply = async () => {
    const { form, submit } = await composer({ kind: "reply", context: context(), onSubmit: async (d) => { await call("forum.reply.create", { postId, as: d.as, body: d.body, createdAt: d.createdAt }); toast(t("forum.posted"), "ok"); } });
    modal({ title: t("forum.reply"), wide: true, body: form, actions: [(c) => button(t("common.cancel"), { onclick: c }), submit] });
  };
  const renderReplies = async () => {
    clear(list);
    if (!replies.length) { list.append(empty()); return; }
    for (const r of replies) {
      const item = h("div.item.reply", h("div.body",
        h("p.pre", r.body),
        r.sharedRecipeTitle ? h("div.small", `${t("forum.recipeLink")}: ${r.sharedRecipeTitle}`) : null,
        h("div.row.between", authorLine(r), h("div.row", badge(t("forum.likes", { n: r.likeCount || 0 })),
          button(t("forum.edit"), { kind: "ghost small", onclick: async () => {
            const text = await promptDialog({ title: t("forum.editReply"), label: t("common.body"), multiline: true, value: r.body, okLabel: t("common.save") });
            if (text === null || !text) return;
            try { await call("forum.reply.update", { postId, replyId: r.id, body: text }); toast(t("common.saved"), "ok"); } catch (e) { toastError(e); }
          } }),
          button(t("common.delete"), { kind: "ghost small", onclick: async () => {
            if (!(await confirmDialog({ title: t("forum.deleteReply") }))) return;
            try { await call("forum.reply.delete", { postId, replyId: r.id }); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
          } }))),
      ));
      item.querySelector(".body").append(await likeControls({ kind: "reply", postId, replyId: r.id }));
      list.append(item);
    }
  };
  const subs = [
    onSnapshot(doc(db, "forum_posts", postId), (snap) => { post = snap.exists() ? { id: snap.id, ...snap.data() } : null; renderHead(); }, toastError),
    onSnapshot(query(collection(db, "forum_posts", postId, "replies"), orderBy("createdAt")), (snap) => { replies = snap.docs.map((d) => ({ id: d.id, ...d.data() })); renderReplies(); }, toastError),
  ];
  actions.append(button(t("forum.reply"), { kind: "primary small", onclick: reply }));
  return () => subs.forEach((u) => u());
}

export async function mount(ctx) {
  const postId = ctx.params[0];
  if (postId) return thread({ ...ctx, postId });
  return threadList(ctx);
}
