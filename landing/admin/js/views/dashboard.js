// The overview: accounts, payments, AI spend — the same figures the app's
// dashboard tab shows, read from the same documents.
import { db, collection, getDocs, query, where, orderBy, limit, documentId, getCountFromServer, Timestamp } from "../firebase.js";
import { t, fmtNumber, fmtMoney, fmtDate, fmtAgo } from "../i18n.js";
import { h, clear, spinner, button, busy, chips, bars, hbars, table, toast, toastError, avatar } from "../ui.js";
import { pricing, tally, addTally, ZERO, costUsd, costIls, isOnline, premiumActive, platformLabel, modelName } from "../data.js";
import { call } from "../api.js";

const RANGES = [["today", "dash.range.today"], ["30", "dash.range.d30"], ["60", "dash.range.d60"], ["all", "dash.range.all"]];
const PAYMENT_TYPES = new Set(["INITIAL_PURCHASE", "RENEWAL", "NON_RENEWING_PURCHASE", "UNCANCELLATION", "PRODUCT_CHANGE"]);

function dayKey(d) {
  return d.toISOString().slice(0, 10);
}

function sinceDay(range, now) {
  if (range === "all") return null;
  const days = range === "today" ? 0 : Number(range) - 1;
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - days));
  return dayKey(d);
}

async function load(range) {
  const now = new Date();
  const since = sinceDay(range, now);
  const chartSince = since || dayKey(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - 60)));
  const sinceTs = since ? Timestamp.fromDate(new Date(`${since}T00:00:00Z`)) : null;

  const events = sinceTs
    ? query(collection(db, "purchase_events"), where("eventAt", ">=", sinceTs))
    : query(collection(db, "purchase_events"), orderBy("eventAt", "desc"), limit(2000));
  const daily = query(collection(db, "ai_daily"), where(documentId(), ">=", chartSince));

  const [users, ents, statuses, eventSnap, dailySnap, usageSnap, counts, prices] = await Promise.all([
    getDocs(query(collection(db, "users"), limit(5000))),
    getDocs(query(collection(db, "entitlements"), limit(5000))),
    getDocs(query(collection(db, "account_status"), limit(5000))),
    getDocs(events),
    getDocs(daily),
    range === "all" ? getDocs(query(collection(db, "ai_usage"), limit(5000))) : Promise.resolve(null),
    Promise.all(["shared_recipes", "forum_posts", "feedback", "seed_personas", "households"].map((c) => getCountFromServer(collection(db, c)).then((s) => s.data().count).catch(() => 0))),
    pricing(),
  ]);

  const entitlements = Object.fromEntries(ents.docs.map((d) => [d.id, d.data()]));
  const status = Object.fromEntries(statuses.docs.map((d) => [d.id, d.data()]));
  const profiles = {};
  let premium = 0, disabled = 0, online = 0, withPush = 0, newUsers = 0;
  const byPlatform = {}, byVersion = {}, signups = {};
  const nowMs = now.getTime();
  for (const d of users.docs) {
    const p = d.data();
    profiles[d.id] = p;
    if (premiumActive(entitlements[d.id], nowMs)) premium++;
    if (status[d.id] && status[d.id].disabled === true) disabled++;
    if (isOnline(p, nowMs)) online++;
    if (p.pushToken) withPush++;
    const platform = platformLabel(p.platform);
    byPlatform[platform] = (byPlatform[platform] || 0) + 1;
    if (p.appVersion) byVersion[p.appVersion] = (byVersion[p.appVersion] || 0) + 1;
    const created = p.createdAt && p.createdAt.toDate ? p.createdAt.toDate() : null;
    if (created) {
      const day = dayKey(created);
      if (!since || day >= since) newUsers++;
      if (day >= chartSince) signups[day] = (signups[day] || 0) + 1;
    }
  }
  for (const uid of Object.keys(entitlements)) if (!profiles[uid] && premiumActive(entitlements[uid], nowMs)) premium++;

  const payments = {};
  let paymentsCount = 0, sandbox = 0;
  for (const d of eventSnap.docs) {
    const e = d.data();
    if (!PAYMENT_TYPES.has(e.type) || !(e.price > 0)) continue;
    if (String(e.environment || "").toUpperCase() === "SANDBOX") { sandbox++; continue; }
    paymentsCount++;
    const cur = String(e.currency || "").toUpperCase() || "?";
    payments[cur] = (payments[cur] || 0) + e.price;
  }

  const days = dailySnap.docs.map((d) => ({ day: d.id, data: d.data() })).sort((a, b) => a.day.localeCompare(b.day));
  const inRange = days.filter((d) => !since || d.day >= since);
  let total = { ...ZERO };
  const byModel = {}, byKind = {}, byUser = {};
  for (const { data } of inRange) {
    total = addTally(total, tally(data));
    for (const [k, v] of Object.entries(data.models || {})) byModel[k] = addTally(byModel[k] || ZERO, tally(v));
    for (const [k, v] of Object.entries(data.kinds || {})) byKind[k] = addTally(byKind[k] || ZERO, tally(v));
    if (!usageSnap) for (const [uid, u] of Object.entries(data.users || {})) {
      byUser[uid] = byUser[uid] || {};
      for (const [k, v] of Object.entries(u.models || {})) byUser[uid][k] = addTally(byUser[uid][k] || ZERO, tally(v));
    }
  }
  if (usageSnap) for (const d of usageSnap.docs) {
    const models = d.data().models || {};
    if (Object.keys(models).length) byUser[d.id] = Object.fromEntries(Object.entries(models).map(([k, v]) => [k, tally(v)]));
  }
  const usersByCost = Object.entries(byUser).map(([uid, models]) => ({ uid, models, cost: costIls(models, prices), total: Object.values(models).reduce((a, b) => addTally(a, b), { ...ZERO }) }))
    .sort((a, b) => b.cost - a.cost).slice(0, 15);

  // Pad the chart: one point per day of a bounded range.
  const chart = [];
  if (since) {
    const map = Object.fromEntries(days.map((d) => [d.day, d.data]));
    for (let d = new Date(`${since}T00:00:00Z`); d <= now; d.setUTCDate(d.getUTCDate() + 1)) {
      const key = dayKey(d);
      chart.push({ day: key, cost: costIls((map[key] || {}).models, prices), signups: signups[key] || 0 });
    }
  } else {
    for (const d of days) chart.push({ day: d.day, cost: costIls(d.data.models, prices), signups: signups[d.day] || 0 });
  }

  return {
    usersTotal: users.docs.length, newUsers, premium, disabled, online, withPush, byPlatform, byVersion,
    payments, paymentsCount, sandbox, total, byModel, byKind, usersByCost, profiles, entitlements, chart, prices,
    counts: { recipes: counts[0], posts: counts[1], tickets: counts[2], personas: counts[3], households: counts[4] },
  };
}

function tile(label, value, sub, accent) {
  return h(`div.tile${accent ? ".accent" : ""}`, h("div.label", label), h("div.value", value), sub ? h("div.sub", sub) : null);
}

export async function mount({ view, actions }) {
  let range = "30";
  try { range = localStorage.getItem("ep-admin-range") || "30"; } catch (_) {}
  const body = h("div.stack");
  view.append(chips(RANGES.map(([k, l]) => [k, t(l)]), range, (v) => { range = v; try { localStorage.setItem("ep-admin-range", v); } catch (_) {} render(); }), body);

  const sync = button(t("dash.syncPricing"), { kind: "small" });
  sync.addEventListener("click", busy(sync, async () => {
    try { await call("pricing.sync"); toast(t("dash.synced"), "ok"); render(); } catch (err) { toastError(err); }
  }));
  actions.append(sync);

  async function render() {
    clear(body);
    body.append(spinner());
    try {
      const d = await load(range);
      clear(body);
      const totalCost = costIls(d.byModel, d.prices);
      body.append(h("div.tiles",
        tile(t("dash.users"), fmtNumber(d.usersTotal), `+${fmtNumber(d.newUsers)} ${t("dash.newUsers").toLowerCase()}`),
        tile(t("dash.online"), fmtNumber(d.online), null, true),
        tile(t("dash.premium"), fmtNumber(d.premium)),
        tile(t("dash.disabled"), fmtNumber(d.disabled)),
        tile(t("dash.withPush"), fmtNumber(d.withPush)),
        tile(t("dash.payments"), Object.keys(d.payments).length ? Object.entries(d.payments).map(([c, v]) => fmtMoney(v, c)).join(" · ") : t("dash.unpaid"), d.sandbox ? t("dash.sandbox", { n: d.sandbox }) : `${fmtNumber(d.paymentsCount)}`),
        tile(t("dash.aiCost"), fmtMoney(totalCost), t("dash.calc", { calls: fmtNumber(d.total.calls), tokens: fmtNumber(d.total.total) }), true),
        tile(t("dash.cacheHits"), fmtNumber(d.total.cacheHits)),
        tile(t("dash.recipes"), fmtNumber(d.counts.recipes)),
        tile(t("dash.posts"), fmtNumber(d.counts.posts)),
        tile(t("dash.tickets"), fmtNumber(d.counts.tickets)),
        tile(t("dash.personas"), fmtNumber(d.counts.personas)),
        tile(t("dash.households"), fmtNumber(d.counts.households)),
      ));
      body.append(h("p.small.muted", t("dash.costNote", { rate: fmtNumber(d.prices.usdToIls, 2), source: d.prices.source || "—", when: d.prices.updatedAt ? fmtAgo(d.prices.updatedAt) : "—" })));

      body.append(h("div.grid2",
        h("div.card", h("h2", t("dash.dailyCost")), d.chart.length ? bars(d.chart.map((c) => ({ label: c.day, value: c.cost })), { label: (v) => fmtMoney(v) }) : h("p.muted", t("dash.noData"))),
        h("div.card", h("h2", t("dash.signups")), d.chart.length ? bars(d.chart.map((c) => ({ label: c.day, value: c.signups }))) : h("p.muted", t("dash.noData"))),
      ));

      const modelRows = Object.entries(d.byModel).map(([k, v]) => [modelName(k), costUsd(v, k, d.prices) * (d.prices.usdToIls || 3.7)]).sort((a, b) => b[1] - a[1]);
      const kindRows = Object.entries(d.byKind).map(([k, v]) => [k, v.calls]).sort((a, b) => b[1] - a[1]);
      body.append(h("div.grid2",
        h("div.card", h("h2", t("dash.byModel")), modelRows.length ? hbars(modelRows, (v) => fmtMoney(v)) : h("p.muted", t("dash.noData"))),
        h("div.card", h("h2", t("dash.byKind")), kindRows.length ? hbars(kindRows, (v) => fmtNumber(v)) : h("p.muted", t("dash.noData"))),
        h("div.card", h("h2", t("dash.byPlatform")), hbars(Object.entries(d.byPlatform).sort((a, b) => b[1] - a[1]), fmtNumber)),
        h("div.card", h("h2", t("dash.byVersion")), hbars(Object.entries(d.byVersion).sort((a, b) => b[1] - a[1]).slice(0, 8), fmtNumber)),
      ));

      body.append(h("div.card", h("h2", t("dash.topUsers")), table([
        { label: t("common.name"), cell: (r) => { const p = d.profiles[r.uid] || {}; return h("div.row", avatar(p.fullName || r.uid, p.photoUrl, "sm"), h("span", p.fullName || r.uid)); } },
        { label: t("dash.calls"), num: true, cell: (r) => fmtNumber(r.total.calls) },
        { label: t("dash.input"), num: true, cell: (r) => fmtNumber(r.total.input) },
        { label: t("dash.output"), num: true, cell: (r) => fmtNumber(r.total.output + r.total.thoughts) },
        { label: t("dash.cached"), num: true, cell: (r) => fmtNumber(r.total.cached) },
        { label: t("dash.cost"), num: true, cell: (r) => fmtMoney(r.cost) },
      ], d.usersByCost, { onRow: (r) => { location.hash = `#/users/${r.uid}`; }, emptyText: t("dash.noData") })));
    } catch (err) {
      clear(body);
      body.append(h("div.card.error", err.message));
      console.error(err);
    }
  }
  render();
  return () => {};
}
