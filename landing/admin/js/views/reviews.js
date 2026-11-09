// Store reviews: every Google Play and App Store review and rating in one
// inbox — stars, title, the reviewer's text, device, version, storefront —
// and the developer reply, written here (or drafted by the model) and sent
// back to the store through adminPanel (storeReviews.js). The list is a
// live Firestore listener; the server pulls the stores every 3 hours and
// on "Sync now".
import { db, collection, doc, onSnapshot, query, orderBy, limit } from "../firebase.js";
import { t, fmtNumber, fmtDate, currentLang } from "../i18n.js";
import { h, clear, badge, button, busy, chips, textarea, field, modal, confirmDialog, toast, toastError, empty, input, debounce } from "../ui.js";
import { call } from "../api.js";

const MAX_REPLY = { android: 350, ios: 5970 };
const STORE = { android: "Google Play", ios: "App Store" };
const STORE_COLOR = { android: "green", ios: "brand" };

// Ready replies, one set per reviewer language. "{name}" is the reviewer's
// store nickname (dropped with its comma when the store shows none). Each
// stays under Google Play's 350 characters. The coupon is offered for the
// trouble, through the app's support chat (stores have no private
// messages) — never in exchange for changing the rating, which both stores
// forbid.
const TEMPLATE_KEYS = ["thanks", "sorry", "coupon", "idea", "fixed"];
export const TEMPLATES = {
  he: {
    thanks: "תודה רבה{, name}! 💜 שמחים מאוד שהאפליקציה עוזרת לך במטבח. ביקורת כזו נותנת לנו המון כוח להמשיך לשפר. בתיאבון! — צוות EasyPlate",
    sorry: "היי{ name}, סליחה על אי הנוחות 🙏 זה בדיוק מה שאנחנו לא רוצים שיקרה. נשמח אם תכתבו לנו דרך מסך התמיכה באפליקציה (תפריט ← תמיכה) עם כמה פרטים, ונטפל בזה אישית ומהר. — צוות EasyPlate",
    coupon: "היי{ name}, אנחנו מצטערים מאוד על החוויה 🙏 כדי לפצות, נשמח לשלוח לך קוד קופון בפרטי — פשוט כתבו לנו בצ'אט התמיכה באפליקציה (תפריט ← תמיכה) ונשלח אותו לשם, ונבדוק גם את התקלה עצמה. — צוות EasyPlate",
    idea: "תודה{ name} על ההצעה! 💡 רשמנו אותה ברשימת הפיצ'רים שלנו, והרבה מהשיפורים באפליקציה מגיעים בדיוק מהערות כאלה. שווה לעקוב אחרי העדכונים הבאים 😉 — צוות EasyPlate",
    fixed: "היי{ name}, תודה שדיווחת! 🛠️ התקלה תוקנה בגרסה האחרונה — מומלץ לעדכן את האפליקציה בחנות. אם זה עדיין קורה, כתבו לנו במסך התמיכה באפליקציה ונבדוק מיד. — צוות EasyPlate",
  },
  en: {
    thanks: "Thank you so much{, name}! 💜 We're really happy EasyPlate helps you in the kitchen. Reviews like yours keep us going. Happy cooking! — The EasyPlate team",
    sorry: "Hi{ name}, sorry for the inconvenience 🙏 That's exactly what we don't want to happen. Please write to us from the Support screen in the app (Menu → Support) with a few details and we'll handle it personally and quickly. — The EasyPlate team",
    coupon: "Hi{ name}, we're really sorry about your experience 🙏 To make up for it, we'd like to send you a coupon code privately — just message us in the in-app support chat (Menu → Support) and we'll send it there and look into the issue too. — The EasyPlate team",
    idea: "Thanks for the suggestion{, name}! 💡 We've added it to our feature list — many of our improvements come straight from feedback like yours. Keep an eye on the next updates 😉 — The EasyPlate team",
    fixed: "Hi{ name}, thanks for reporting this! 🛠️ It's fixed in the latest version — please update the app from the store. If it still happens, write to us from the Support screen in the app and we'll check right away. — The EasyPlate team",
  },
  ar: {
    thanks: "شكرًا جزيلًا{، name}! 💜 يسعدنا جدًا أن EasyPlate يساعدك في المطبخ. تقييمات مثل تقييمك تمنحنا الدافع للاستمرار. بالهناء! — فريق EasyPlate",
    sorry: "مرحبًا{ name}، نعتذر عن الإزعاج 🙏 هذا بالضبط ما لا نريده أن يحدث. يرجى مراسلتنا من شاشة الدعم في التطبيق (القائمة ← الدعم) مع بعض التفاصيل وسنتابع الأمر شخصيًا وبسرعة. — فريق EasyPlate",
    coupon: "مرحبًا{ name}، نأسف جدًا لتجربتك 🙏 تعويضًا لك، يسعدنا أن نرسل لك رمز قسيمة بشكل خاص — فقط راسلنا في دردشة الدعم داخل التطبيق (القائمة ← الدعم) وسنرسله هناك ونفحص المشكلة أيضًا. — فريق EasyPlate",
    idea: "شكرًا على الاقتراح{، name}! 💡 أضفناه إلى قائمة الميزات لدينا — كثير من تحسيناتنا تأتي من ملاحظات مثل ملاحظتك. ترقّب التحديثات القادمة 😉 — فريق EasyPlate",
    fixed: "مرحبًا{ name}، شكرًا على البلاغ! 🛠️ تم إصلاح المشكلة في أحدث إصدار — يرجى تحديث التطبيق من المتجر. إن استمرت، راسلنا من شاشة الدعم في التطبيق وسنفحصها فورًا. — فريق EasyPlate",
  },
  fr: {
    thanks: "Merci beaucoup{, name} ! 💜 Nous sommes ravis qu'EasyPlate vous aide en cuisine. Des avis comme le vôtre nous motivent énormément. Bonne cuisine ! — L'équipe EasyPlate",
    sorry: "Bonjour{ name}, désolés pour la gêne occasionnée 🙏 Écrivez-nous depuis l'écran Assistance de l'app (Menu → Assistance) avec quelques détails : nous nous en occupons personnellement et rapidement. — L'équipe EasyPlate",
    coupon: "Bonjour{ name}, nous sommes vraiment désolés 🙏 Pour nous faire pardonner, nous aimerions vous envoyer un code promo en privé : écrivez-nous dans le chat d'assistance de l'app (Menu → Assistance), nous vous l'enverrons là-bas et examinerons le problème. — L'équipe EasyPlate",
    idea: "Merci pour la suggestion{, name} ! 💡 Nous l'avons ajoutée à notre liste : beaucoup de nos améliorations viennent de retours comme le vôtre. Restez attentif aux prochaines mises à jour 😉 — L'équipe EasyPlate",
    fixed: "Bonjour{ name}, merci pour le signalement ! 🛠️ C'est corrigé dans la dernière version : mettez l'app à jour depuis le store. Si le problème persiste, écrivez-nous depuis l'écran Assistance et nous vérifions tout de suite. — L'équipe EasyPlate",
  },
  ru: {
    thanks: "Большое спасибо{, name}! 💜 Очень рады, что EasyPlate помогает вам на кухне. Такие отзывы дают нам силы двигаться дальше. Приятного аппетита! — Команда EasyPlate",
    sorry: "Здравствуйте{, name}! Простите за неудобства 🙏 Напишите нам, пожалуйста, через экран поддержки в приложении (Меню → Поддержка) с парой подробностей — мы разберёмся лично и быстро. — Команда EasyPlate",
    coupon: "Здравствуйте{, name}! Нам очень жаль 🙏 В качестве компенсации хотим отправить вам промокод лично — просто напишите нам в чат поддержки в приложении (Меню → Поддержка), мы пришлём его туда и заодно разберёмся с проблемой. — Команда EasyPlate",
    idea: "Спасибо за идею{, name}! 💡 Мы добавили её в список функций — многие улучшения появляются именно из таких отзывов. Следите за обновлениями 😉 — Команда EasyPlate",
    fixed: "Здравствуйте{, name}! Спасибо, что сообщили 🛠️ Ошибка исправлена в последней версии — обновите приложение в магазине. Если повторится, напишите нам через экран поддержки, и мы сразу проверим. — Команда EasyPlate",
  },
};
const TEMPLATE_LANG_NAMES = { he: "עברית", en: "English", ar: "العربية", fr: "Français", ru: "Русский" };
// App Store territories that read each language by default.
const COUNTRY_LANG = { ISR: "he", IL: "he", FRA: "fr", FR: "fr", BEL: "fr", RUS: "ru", RU: "ru", UKR: "ru", ARE: "ar", SAU: "ar", EGY: "ar", JOR: "ar" };

// Pure: the reviewer's language for the templates.
export function templateLang(review) {
  const code = String(review.lang || "").slice(0, 2).toLowerCase();
  if (code === "iw") return "he";
  if (TEMPLATES[code]) return code;
  const text = `${review.title || ""} ${review.text || ""}`;
  if (/[\u0590-\u05FF]/.test(text)) return "he";
  if (/[\u0600-\u06FF]/.test(text)) return "ar";
  if (/[\u0400-\u04FF]/.test(text)) return "ru";
  return COUNTRY_LANG[String(review.country || "").toUpperCase()] || "en";
}

// Pure: a template with the reviewer's name, or without it (and the
// separator before it) when the store shows none.
export function fillTemplate(template, name) {
  const n = String(name || "").trim();
  return template.replace(/\{([^{}]*?)name\}/g, (_, sep) => (n ? `${sep}${n}` : "")).trim();
}

const stars = (n) => "★".repeat(Math.max(0, Math.min(5, n || 0))) + "☆".repeat(5 - Math.max(0, Math.min(5, n || 0)));

function regionName(code) {
  if (!code) return "";
  // App Store territories are ISO alpha-3 (ISR, USA); Intl wants alpha-2.
  const a3 = { ISR: "IL", USA: "US", GBR: "GB", CAN: "CA", AUS: "AU", FRA: "FR", DEU: "DE", RUS: "RU", ARE: "AE", SAU: "SA", UKR: "UA", ESP: "ES", ITA: "IT", NLD: "NL" };
  const cc = code.length === 3 ? a3[code] || "" : code;
  try {
    return (cc && new Intl.DisplayNames([currentLang()], { type: "region" }).of(cc)) || code;
  } catch (_) {
    return code;
  }
}

function tile(label, value, sub) {
  return h("div.tile", h("div.label", label), h("div.value", value), sub ? h("div.sub", sub) : null);
}

function starBars(dist) {
  const top = Math.max(1, ...Object.values(dist.stars || {}));
  return h("div", [5, 4, 3, 2, 1].map((s) => h("div.hbar", h("span", `${s}★`), h("div.track", h("div.fill", { style: { width: `${((dist.stars?.[s] || 0) / top) * 100}%` } })), h("span.n", fmtNumber(dist.stars?.[s] || 0)))));
}

export async function mount({ view, actions }) {
  let reviews = [];
  let meta = {};
  let filter = "open";
  let store = "all";
  let starFilter = "all";
  let search = "";

  const syncBtn = button(t("reviews.sync"), { kind: "primary" });
  syncBtn.addEventListener("click", busy(syncBtn, async () => {
    try {
      const r = await call("reviews.sync", { platform: "all" });
      const added = (r.android?.added || 0) + (r.ios?.added || 0);
      const errs = [...(r.android?.errors || []), ...(r.ios?.errors || [])];
      toast(t("reviews.synced", { n: fmtNumber(added) }), errs.length ? "" : "ok");
    } catch (e) { toastError(e); }
  }));
  const backfillBtn = button(t("reviews.backfill"), { kind: "ghost small", title: t("reviews.backfillHint") });
  backfillBtn.addEventListener("click", busy(backfillBtn, async () => {
    try { await call("reviews.sync", { platform: "all", backfill: true }); toast(t("reviews.synced", { n: "✓" }), "ok"); } catch (e) { toastError(e); }
  }));
  actions.append(backfillBtn, syncBtn);

  const summary = h("div.stack");
  const status = h("div.stack");
  const list = h("div.list");
  const count = h("span.muted.small");
  const searchBox = input({ type: "search", placeholder: t("reviews.search"), class: "search" });
  searchBox.addEventListener("input", debounce(() => { search = searchBox.value.trim().toLowerCase(); render(); }));

  view.append(
    summary,
    status,
    h("div.toolbar",
      chips([["open", t("reviews.f.open")], ["unread", t("reviews.f.unread")], ["text", t("reviews.f.text")], ["answered", t("reviews.f.answered")], ["all", t("reviews.f.all")]], filter, (v) => { filter = v; render(); }),
      chips([["all", t("reviews.allStores")], ["android", STORE.android], ["ios", STORE.ios]], store, (v) => { store = v; render(); }),
      chips([["all", t("reviews.allStars")], ["low", "1–2★"], ["3", "3★"], ["high", "4–5★"]], starFilter, (v) => { starFilter = v; render(); }),
      searchBox, count),
    list,
  );

  const renderSummary = () => {
    clear(summary);
    const c = meta.counts || {};
    const a = meta.android || {};
    const i = meta.ios || {};
    const all = c.all || { total: 0, stars: {} };
    const avg = (v) => (v === null || v === undefined ? "—" : `${Number(v).toFixed(2)}★`);
    summary.append(h("div.tiles",
      tile(t("reviews.t.total"), fmtNumber(all.total || 0), t("reviews.t.withText", { n: fmtNumber(all.withText || 0) })),
      tile(t("reviews.t.open"), fmtNumber(all.needsReply || 0), t("reviews.t.openSub")),
      tile(`${STORE.android} — ${t("reviews.t.storeAvg")}`, avg(a.storeAverage && a.storeAverage.average), t("reviews.t.here", { avg: avg(c.android?.average), n: fmtNumber(c.android?.total || 0) })),
      tile(`${STORE.ios} — ${t("reviews.t.storeAvg")}`, avg(i.storeAverage), t("reviews.t.iosCount", { n: fmtNumber(i.storeCount || 0), avg: avg(c.ios?.average), here: fmtNumber(c.ios?.total || 0) })),
    ));
    if (all.total) summary.append(h("div.card", h("h2", t("reviews.distribution")), starBars(all)));
  };

  const renderStatus = () => {
    clear(status);
    const lines = [];
    for (const p of ["android", "ios"]) {
      const s = meta[p] || {};
      if (s.error) lines.push(h("div.card.small", h("strong", `${STORE[p]}: `), h("span.warn.pre", s.error)));
    }
    if (meta.lastSyncAt) lines.push(h("div.small.muted", t("reviews.lastSync", { date: fmtDate(meta.lastSyncAt.toDate ? meta.lastSyncAt.toDate() : new Date(meta.lastSyncAt)) })));
    else lines.push(h("div.card.small", h("p", t("reviews.neverSynced")), h("ul.small.muted", { style: { margin: 0, paddingInlineStart: "1.2em" } }, t("reviews.setup").split("\n").map((l) => h("li", l)))));
    status.append(...lines);
  };

  const setRead = async (r, read) => {
    try { await call("reviews.read", { ids: [r.id], read }); } catch (e) { toastError(e); }
  };

  const replyDialog = (r) => {
    const max = MAX_REPLY[r.platform];
    const text = textarea({ rows: 6, maxlength: String(max), value: r.reply?.text || "" });
    const counter = h("span.small.muted");
    const updateCount = () => { counter.textContent = `${text.value.length} / ${max}`; counter.className = text.value.length > max ? "small warn" : "small muted"; };
    text.addEventListener("input", updateCount);
    updateCount();
    let tplLang = templateLang(r);
    const langPick = h("select.input", { "aria-label": t("reviews.tplLang"), style: { width: "auto" } }, Object.entries(TEMPLATE_LANG_NAMES).map(([code, label]) => h("option", { value: code, selected: code === tplLang }, label)));
    langPick.value = tplLang;
    // The template last put in the box: switching the language rewrites it
    // in the new language (the box would otherwise keep the old one until
    // a template button was pressed again).
    let lastKey = null;
    const fill = (key) => {
      lastKey = key;
      text.value = fillTemplate(TEMPLATES[tplLang][key], r.author).slice(0, max);
      updateCount();
    };
    langPick.addEventListener("change", () => {
      tplLang = langPick.value;
      if (lastKey) fill(lastKey);
    });
    const templates = h("div.row", { style: { flexWrap: "wrap", gap: "6px" } },
      h("span.small.muted", t("reviews.templates")),
      TEMPLATE_KEYS.map((key) => button(t(`reviews.tpl.${key}`), { kind: "small", onclick: () => {
        fill(key);
        text.focus();
      } })),
      langPick);
    const hint = input({ placeholder: t("reviews.draftHint") });
    const translation = h("p.small.muted.pre", { hidden: true });
    const draftBtn = button(t("reviews.draft"), { kind: "small" });
    draftBtn.addEventListener("click", busy(draftBtn, async () => {
      try {
        const d = await call("reviews.draft", { reviewId: r.id, lang: currentLang(), hint: hint.value.trim() });
        text.value = d.reply || "";
        lastKey = null;
        updateCount();
        if (d.translation) { translation.hidden = false; translation.textContent = `${t("reviews.translation")} (${d.language || "?"}): ${d.translation}`; }
      } catch (e) { toastError(e); }
    }));
    modal({
      wide: true,
      title: `${t("reviews.replyTo")} ${r.author || t("reviews.anonymous")} · ${STORE[r.platform]}`,
      body: h("div.stack",
        h("div", h("span", { style: { color: "var(--amber)" } }, stars(r.rating)), r.title ? h("strong", ` ${r.title}`) : null),
        h("p.pre", r.text || t("reviews.noText")),
        translation,
        templates,
        h("div.row", hint, draftBtn),
        field(t("reviews.yourReply"), text, r.platform === "android" ? t("reviews.playLimit") : t("reviews.appleNote")),
        counter,
        r.reply ? h("p.small.muted", t("reviews.replaces")) : null,
      ),
      actions: [
        (c) => button(t("common.cancel"), { onclick: c }),
        (c) => {
          const b = button(t("reviews.send"), { kind: "primary" });
          b.addEventListener("click", busy(b, async () => {
            const body = text.value.trim();
            if (!body) return;
            if (body.length > max) { toast(t("reviews.tooLong", { max }), "error"); return; }
            try {
              await call("reviews.reply", { reviewId: r.id, text: body });
              toast(t("reviews.sent"), "ok");
              c();
            } catch (e) { toastError(e); }
          }));
          return b;
        },
      ],
    });
  };

  const deleteReply = async (r) => {
    if (!(await confirmDialog({ title: t("reviews.deleteReply"), text: t("reviews.deleteReplyText") }))) return;
    try { await call("reviews.deleteReply", { reviewId: r.id }); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
  };

  const matches = (r) => {
    if (store !== "all" && r.platform !== store) return false;
    if (starFilter === "low" && r.rating > 2) return false;
    if (starFilter === "3" && r.rating !== 3) return false;
    if (starFilter === "high" && r.rating < 4) return false;
    if (filter === "open" && !r.needsReply) return false;
    if (filter === "unread" && r.read) return false;
    if (filter === "text" && !(r.text || r.title)) return false;
    if (filter === "answered" && !r.reply) return false;
    if (search) {
      const hay = [r.author, r.title, r.text, r.reply?.text, r.device, r.appVersion, r.country, r.lang].join(" ").toLowerCase();
      if (!hay.includes(search)) return false;
    }
    return true;
  };

  const render = () => {
    const rows = reviews.filter(matches);
    count.textContent = t("reviews.count", { n: fmtNumber(rows.length) });
    clear(list);
    if (!rows.length) { list.append(empty(t("reviews.none"))); return; }
    for (const r of rows.slice(0, 300)) {
      const metaBits = [
        badge(STORE[r.platform], STORE_COLOR[r.platform]),
        h("span", { style: { color: "var(--amber)", letterSpacing: "1px" }, title: `${r.rating}/5` }, stars(r.rating)),
        h("strong", r.author || t("reviews.anonymous")),
        r.createdAt ? h("span.small.muted", fmtDate(new Date(r.createdAt))) : null,
        r.updatedAt && r.createdAt && r.updatedAt - r.createdAt > 3600000 ? h("span.small.muted", `${t("reviews.edited")} ${fmtDate(new Date(r.updatedAt))}`) : null,
        r.country ? h("span.small.muted", regionName(r.country)) : null,
        r.lang ? h("span.small.muted", r.lang) : null,
        r.appVersion ? h("span.small.muted", `v${r.appVersion}`) : null,
        r.device ? h("span.small.muted", r.device) : null,
        r.thumbsUp ? h("span.small.muted", `👍 ${fmtNumber(r.thumbsUp)}`) : null,
        r.editedAfterReply ? badge(t("reviews.editedAfter"), "amber") : null,
        r.needsReply && !r.editedAfterReply ? badge(t("reviews.needsReply"), "red") : null,
        r.reply && r.reply.state && r.reply.state !== "published" ? badge(t("reviews.pending"), "amber") : null,
      ];
      const canReply = !(r.platform === "android" && String(r.storeId).startsWith("csv_")) && (r.text || r.title || r.platform === "ios");
      list.append(h(`div.item${r.read ? "" : ".unread"}`, h("div.body",
        h("div.row.meta", metaBits),
        r.title ? h("h3", { dir: "auto", style: { margin: "6px 0 2px" } }, r.title) : null,
        r.text ? h("p.pre", { dir: "auto", style: { margin: "4px 0" } }, r.text) : h("p.small.muted", t("reviews.ratingOnly")),
        r.reply ? h("div.small.pre", { dir: "auto", style: { borderInlineStart: "2px solid var(--brand)", paddingInlineStart: "8px", marginTop: "6px" } }, h("span.muted", `${t("reviews.you")}${r.reply.at ? ` · ${fmtDate(new Date(r.reply.at))}` : ""}: `), r.reply.text) : null,
        h("div.row", { style: { marginTop: "8px" } },
          canReply ? button(r.reply ? t("reviews.editReply") : t("reviews.reply"), { kind: "small primary", onclick: () => replyDialog(r) }) : null,
          r.reply && r.platform === "ios" ? button(t("reviews.deleteReply"), { kind: "ghost small", onclick: () => deleteReply(r) }) : null,
          button(r.read ? t("reviews.markUnread") : t("reviews.markRead"), { kind: "small", onclick: () => setRead(r, !r.read) }),
          r.link ? h("a.small", { href: r.link, target: "_blank", rel: "noopener" }, t("reviews.openInStore")) : null,
        ),
      )));
    }
    if (rows.length > 300) list.append(h("p.small.muted", t("reviews.more", { n: fmtNumber(rows.length - 300) })));
  };

  const subs = [
    onSnapshot(query(collection(db, "store_reviews"), orderBy("createdAt", "desc"), limit(3000)), (snap) => { reviews = snap.docs.map((d) => ({ id: d.id, ...d.data() })); render(); }, toastError),
    onSnapshot(doc(db, "store_reviews_meta", "summary"), (snap) => { meta = snap.exists() ? snap.data() : {}; renderSummary(); renderStatus(); }, () => { renderSummary(); renderStatus(); }),
  ];
  renderSummary();
  renderStatus();
  render();
  return () => subs.forEach((u) => u());
}
