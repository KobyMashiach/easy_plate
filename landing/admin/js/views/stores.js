// Store downloads: the exact figures behind the listings' "500+" tags,
// pulled by the server from Google Play's install reports and Apple's
// sales reports (one document per day each). Everything here reads from
// those documents; "Sync now" asks the server to fetch again.
import { t, fmtNumber, fmtAgo, fmtDate, currentLang } from "../i18n.js";
import { h, clear, spinner, button, busy, chips, hbars, table, toast, toastError, modal, field, input, textarea, kv, badge, copyText } from "../ui.js";
import { call } from "../api.js";

const RANGES = [["7", "stores.range.d7"], ["30", "stores.range.d30"], ["90", "stores.range.d90"], ["365", "stores.range.y1"], ["all", "stores.range.all"]];
// Validated on the console's dark surface (dataviz six checks): both pass
// lightness, chroma, CVD separation and contrast.
const COLORS = { android: "#22b06a", ios: "#8c6bff" };
const DAY_MS = 86400000;

function dayKey(d) {
  return d.toISOString().slice(0, 10);
}

function regionName(code) {
  try {
    return new Intl.DisplayNames([currentLang()], { type: "region" }).of(code) || code;
  } catch (_) {
    return code;
  }
}

// The day documents of both platforms merged onto one calendar, padded
// so every day of the range has a point.
function merge(data, range) {
  const android = Object.fromEntries((data.days.android || []).map((d) => [d.date, d]));
  const ios = Object.fromEntries((data.days.ios || []).map((d) => [d.date, d]));
  const all = [...new Set([...Object.keys(android), ...Object.keys(ios)])].sort();
  if (!all.length) return [];
  const today = new Date();
  const end = dayKey(new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate() - 1)));
  let start = all[0];
  if (range !== "all") {
    const since = dayKey(new Date(Date.parse(`${end}T00:00:00Z`) - (Number(range) - 1) * DAY_MS));
    if (since > start) start = since;
  }
  const last = all[all.length - 1] > end ? all[all.length - 1] : end;
  const out = [];
  for (let ms = Date.parse(`${start}T00:00:00Z`); ms <= Date.parse(`${last}T00:00:00Z`); ms += DAY_MS) {
    const key = dayKey(new Date(ms));
    const a = android[key] || null;
    const i = ios[key] || null;
    out.push({ day: key, android: a ? a.installs || 0 : 0, ios: i ? i.downloads || 0 : 0, a, i, known: !!(a || i) });
  }
  return out;
}

function sum(points, key) {
  return points.reduce((n, p) => n + (p[key] || 0), 0);
}

function bucketBy(points, keyOf) {
  const map = new Map();
  for (const p of points) {
    const k = keyOf(p.day);
    const row = map.get(k) || { label: k, android: 0, ios: 0 };
    row.android += p.android;
    row.ios += p.ios;
    map.set(k, row);
  }
  return [...map.values()];
}

function isoWeek(day) {
  const d = new Date(`${day}T00:00:00Z`);
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const year = d.getUTCFullYear();
  const week = Math.ceil(((d - Date.UTC(year, 0, 1)) / DAY_MS + 1) / 7);
  return `${year}-W${String(week).padStart(2, "0")}`;
}

function countries(data, platform) {
  const out = {};
  for (const d of data.days[platform] || []) for (const [c, n] of Object.entries(d.countries || {})) out[c] = (out[c] || 0) + n;
  return out;
}

function pct(part, whole) {
  return whole > 0 ? `${Math.round((part / whole) * 100)}%` : "—";
}

// Two series on one axis as grouped bars, a crosshair tooltip, a legend;
// the day table under it is the readable twin.
function chart(points) {
  if (!points.length) return h("p.muted", t("stores.noData"));
  const W = 900, H = 220, padL = 36, padB = 24, padT = 10;
  const max = Math.max(1, ...points.map((p) => Math.max(p.android, p.ios)));
  const innerW = W - padL - 6;
  const innerH = H - padB - padT;
  const slot = innerW / points.length;
  const gap = Math.min(2, slot * 0.1);
  const barW = Math.max(1, (slot - gap * 2) / 2);
  const y = (v) => padT + innerH - (v / max) * innerH;
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", `0 0 ${W} ${H}`);
  svg.setAttribute("class", "chart");
  svg.setAttribute("role", "img");
  svg.setAttribute("aria-label", t("stores.perDay"));
  const ns = (tag, attrs) => {
    const el = document.createElementNS("http://www.w3.org/2000/svg", tag);
    for (const [k, v] of Object.entries(attrs)) el.setAttribute(k, v);
    return el;
  };
  // Four recessive gridlines with their values.
  for (let i = 0; i <= 4; i++) {
    const v = Math.round((max / 4) * i);
    const yy = y(v);
    svg.append(ns("line", { x1: padL, x2: W - 6, y1: yy, y2: yy, class: "grid" }));
    const label = ns("text", { x: padL - 6, y: yy + 4, class: "axis", "text-anchor": "end" });
    label.textContent = fmtNumber(v);
    svg.append(label);
  }
  points.forEach((p, idx) => {
    const x0 = padL + idx * slot + gap;
    for (const [key, offset] of [["android", 0], ["ios", barW]]) {
      const v = p[key];
      const top = y(v);
      const hgt = Math.max(v > 0 ? 2 : 0, padT + innerH - top);
      svg.append(ns("rect", { x: x0 + offset, y: padT + innerH - hgt, width: barW, height: hgt, rx: Math.min(3, barW / 2), fill: COLORS[key], "data-series": key }));
    }
    // One hit target per day, wider than the marks.
    const hit = ns("rect", { x: padL + idx * slot, y: padT, width: slot, height: innerH, fill: "transparent", class: "hit" });
    hit.dataset.idx = String(idx);
    svg.append(hit);
  });
  // Date labels: first, last and a few in between.
  const every = Math.max(1, Math.ceil(points.length / 6));
  points.forEach((p, idx) => {
    if (idx % every !== 0 && idx !== points.length - 1) return;
    const label = ns("text", { x: padL + idx * slot + slot / 2, y: H - 6, class: "axis", "text-anchor": "middle" });
    label.textContent = p.day.slice(5);
    svg.append(label);
  });
  const cross = ns("line", { x1: 0, x2: 0, y1: padT, y2: padT + innerH, class: "cross" });
  cross.setAttribute("visibility", "hidden");
  svg.append(cross);
  const tip = h("div.chart-tip", { hidden: true });
  const wrap = h("div.chart-wrap", svg, tip);
  svg.addEventListener("mousemove", (e) => {
    const target = e.target.closest(".hit");
    if (!target) return;
    const idx = Number(target.dataset.idx);
    const p = points[idx];
    cross.setAttribute("x1", padL + idx * slot + slot / 2);
    cross.setAttribute("x2", padL + idx * slot + slot / 2);
    cross.setAttribute("visibility", "visible");
    clear(tip);
    tip.append(h("div.tip-title", p.day), h("div.tip-row", h("i", { style: { background: COLORS.android } }), `${t("stores.android")}: ${fmtNumber(p.android)}`), h("div.tip-row", h("i", { style: { background: COLORS.ios } }), `${t("stores.ios")}: ${fmtNumber(p.ios)}`), h("div.tip-row.muted", `${t("common.total")}: ${fmtNumber(p.android + p.ios)}`));
    tip.hidden = false;
    const rect = wrap.getBoundingClientRect();
    const left = e.clientX - rect.left;
    tip.style.left = `${Math.min(rect.width - 170, Math.max(0, left + 12))}px`;
    tip.style.top = `${Math.max(0, e.clientY - rect.top - 10)}px`;
  });
  svg.addEventListener("mouseleave", () => { tip.hidden = true; cross.setAttribute("visibility", "hidden"); });
  const legend = h("div.legend", h("span", h("i.swatch", { style: { background: COLORS.android } }), t("stores.android")), h("span", h("i.swatch", { style: { background: COLORS.ios } }), t("stores.ios")));
  return h("div", legend, wrap);
}

function tile(label, value, sub, color) {
  return h("div.tile", h("div.label", color ? h("span.row", h("i.swatch", { style: { background: color } }), label) : label), h("div.value", value), sub ? h("div.sub", sub) : null);
}

function statusLine(name, state, color) {
  const parts = [h("span.row", h("i.swatch", { style: { background: color } }), h("b", name))];
  if (!state.configured) parts.push(badge(t("stores.notConfigured"), "amber"));
  else if (state.error) parts.push(badge(t("stores.failed"), "red"), h("span.small.error", state.error));
  else if (state.lastSyncAt) parts.push(badge(t("stores.synced"), "green"), h("span.small.muted", t("stores.lastSync", { when: fmtAgo(state.lastSyncAt) })));
  else parts.push(badge(t("stores.neverSynced"), "amber"));
  if (state.configured && state.lastDay) parts.push(h("span.small.muted", t("stores.through", { date: state.lastDay })));
  return h("div.row", parts);
}

function openSettings(state, onSaved) {
  const c = state.config || {};
  const f = {
    playBucket: input({ value: c.playBucket || "", placeholder: "pubsite_prod_1234567890", dir: "ltr" }),
    playPackage: input({ value: c.playPackage || "", dir: "ltr" }),
    appleVendor: input({ value: c.appleVendor || "", placeholder: "8xxxxxxx", dir: "ltr" }),
    appleIssuerId: input({ value: c.appleIssuerId || "", placeholder: "69a6de7e-xxxx-xxxx-xxxx-xxxxxxxxxxxx", dir: "ltr" }),
    appleKeyId: input({ value: c.appleKeyId || "", placeholder: "ABC123DEFG", dir: "ltr" }),
    appleAppId: input({ value: c.appleAppId || "", dir: "ltr" }),
    iosSince: input({ value: c.iosSince || "", type: "date", dir: "ltr" }),
    applePrivateKey: textarea({ placeholder: state.ios && state.ios.keyPresent ? t("stores.keyStored") : "-----BEGIN PRIVATE KEY-----\n…\n-----END PRIVATE KEY-----", rows: 5, dir: "ltr", style: { fontFamily: "ui-monospace, Menlo, monospace", fontSize: "12px" } }),
  };
  const sa = state.serviceAccount || "";
  const body = h("div.stack",
    h("div.card.stack",
      h("h3", t("stores.android")),
      h("p.small.muted", t("stores.playHelp")),
      sa ? h("div.row", h("span.small.muted", t("stores.serviceAccount")), h("code.mono", sa), button(t("common.copy"), { kind: "small ghost", onclick: () => copyText(sa) })) : null,
      field(t("stores.playBucket"), f.playBucket, t("stores.playBucketHint")),
      field(t("stores.playPackage"), f.playPackage),
    ),
    h("div.card.stack",
      h("h3", t("stores.ios")),
      h("p.small.muted", t("stores.appleHelp")),
      field(t("stores.appleVendor"), f.appleVendor, t("stores.appleVendorHint")),
      field(t("stores.appleIssuerId"), f.appleIssuerId),
      field(t("stores.appleKeyId"), f.appleKeyId),
      field(t("stores.applePrivateKey"), f.applePrivateKey, state.ios && state.ios.keyPresent ? t("stores.keyStoredHint") : t("stores.keyHint")),
      field(t("stores.appleAppId"), f.appleAppId),
      field(t("stores.iosSince"), f.iosSince, t("stores.iosSinceHint")),
    ),
  );
  const close = modal({
    title: t("stores.settings"),
    body,
    wide: true,
    actions: [
      button(t("common.cancel"), { onclick: () => close() }),
      (() => {
        const save = button(t("common.save"), { kind: "primary" });
        save.addEventListener("click", busy(save, async () => {
          const payload = {};
          for (const [k, el] of Object.entries(f)) {
            const v = el.value.trim();
            if (k === "applePrivateKey") { if (v) payload[k] = v; }
            else payload[k] = v;
          }
          try {
            await call("stores.config", payload);
            toast(t("common.saved"), "ok");
            close();
            onSaved();
          } catch (err) {
            toastError(err);
          }
        }));
        return save;
      })(),
    ],
  });
}

export async function mount({ view, actions }) {
  let range = "30";
  try { range = localStorage.getItem("ep-admin-stores-range") || "30"; } catch (_) {}
  const body = h("div.stack");
  let data = null;
  view.append(chips(RANGES.map(([k, l]) => [k, t(l)]), range, (v) => { range = v; try { localStorage.setItem("ep-admin-stores-range", v); } catch (_) {} draw(); }), body);

  const sync = button(t("stores.syncNow"), { kind: "primary small" });
  sync.addEventListener("click", busy(sync, async () => {
    try {
      const r = await call("stores.sync", { platform: "all" });
      const problems = Object.entries(r.errors || {}).filter(([, v]) => v !== "not_configured");
      if (problems.length) toast(problems.map(([k, v]) => `${t(`stores.${k}`)}: ${v}`).join(" · "), "error");
      else toast(t("stores.syncDone"), "ok");
      await load();
    } catch (err) { toastError(err); }
  }));
  const backfill = button(t("stores.backfill"), { kind: "small" });
  backfill.addEventListener("click", busy(backfill, async () => {
    try {
      await call("stores.sync", { platform: "ios", backfill: true });
      toast(t("stores.syncDone"), "ok");
      await load();
    } catch (err) { toastError(err); }
  }));
  const settings = button(t("stores.settings"), { kind: "small" });
  settings.addEventListener("click", async () => {
    try {
      const state = data || (await call("stores.status"));
      openSettings(state, load);
    } catch (err) { toastError(err); }
  });
  actions.append(backfill, settings, sync);

  async function load() {
    clear(body);
    body.append(spinner());
    try {
      data = await call("stores.stats");
      draw();
    } catch (err) {
      clear(body);
      body.append(h("div.card.error", err.message));
      console.error(err);
    }
  }

  function draw() {
    if (!data) return;
    clear(body);
    const tot = data.totals || { android: {}, ios: {} };
    const allTotal = (tot.android.installs || 0) + (tot.ios.downloads || 0);
    const points = merge(data, range);
    const inRange = { android: sum(points, "android"), ios: sum(points, "ios") };
    const rangeTotal = inRange.android + inRange.ios;
    const latestAndroid = (data.days.android || []).slice(-1)[0] || null;
    const androidUninstalls = points.reduce((n, p) => n + (p.a ? p.a.uninstalls || 0 : 0), 0);
    const iosUpdates = points.reduce((n, p) => n + (p.i ? p.i.updates || 0 : 0), 0);
    const iosRedownloads = points.reduce((n, p) => n + (p.i ? p.i.redownloads || 0 : 0), 0);
    const neither = !data.android.configured && !data.ios.configured;

    body.append(h("div.card.stack", statusLine(t("stores.android"), data.android, COLORS.android), statusLine(t("stores.ios"), data.ios, COLORS.ios),
      neither ? h("p.small.muted", t("stores.setupIntro")) : null));

    body.append(h("div.tiles",
      tile(t("stores.totalAll"), fmtNumber(allTotal), t("stores.sinceFirst")),
      tile(t("stores.android"), fmtNumber(tot.android.installs || 0), t("stores.share", { p: pct(tot.android.installs || 0, allTotal) }), COLORS.android),
      tile(t("stores.ios"), fmtNumber(tot.ios.downloads || 0), t("stores.share", { p: pct(tot.ios.downloads || 0, allTotal) }), COLORS.ios),
      tile(t("stores.inRange"), fmtNumber(rangeTotal), `${t("stores.android")} ${fmtNumber(inRange.android)} · ${t("stores.ios")} ${fmtNumber(inRange.ios)}`),
      tile(t("stores.perDayAvg"), fmtNumber(points.length ? rangeTotal / points.length : 0, 1), t("stores.daysCounted", { n: fmtNumber(points.length) })),
      tile(t("stores.activeDevices"), fmtNumber(latestAndroid ? latestAndroid.activeDevices || 0 : 0), t("stores.playOnly")),
      tile(t("stores.playCounter"), fmtNumber(data.android.totalUserInstalls || 0), t("stores.playCounterHint")),
      tile(t("stores.uninstalls"), fmtNumber(androidUninstalls), t("stores.playOnly")),
      tile(t("stores.updates"), fmtNumber(iosUpdates), t("stores.iosOnly")),
      tile(t("stores.redownloads"), fmtNumber(iosRedownloads), t("stores.iosOnly")),
      tile(t("stores.iap"), fmtNumber(tot.ios.iap || 0), t("stores.iosOnly")),
    ));

    body.append(h("div.card", h("h2", t("stores.perDay")), chart(points)));

    const share = [[t("stores.android"), tot.android.installs || 0], [t("stores.ios"), tot.ios.downloads || 0]];
    const weeks = bucketBy(points, isoWeek).slice(-12).reverse();
    const months = bucketBy(merge(data, "all"), (d) => d.slice(0, 7)).reverse();
    const periodTable = (rows) => table([
      { label: t("stores.period"), cell: (r) => h("span.mono", r.label) },
      { label: t("stores.android"), num: true, cell: (r) => fmtNumber(r.android) },
      { label: t("stores.ios"), num: true, cell: (r) => fmtNumber(r.ios) },
      { label: t("common.total"), num: true, cell: (r) => h("b", fmtNumber(r.android + r.ios)) },
      { label: t("stores.androidShare"), num: true, cell: (r) => pct(r.android, r.android + r.ios) },
    ], rows, { emptyText: t("stores.noData") });
    body.append(h("div.grid2",
      h("div.card", h("h2", t("stores.platformShare")), hbars(share, fmtNumber), h("p.small.muted", t("stores.shareNote"))),
      h("div.card", h("h2", t("stores.byWeek")), periodTable(weeks)),
    ));
    body.append(h("div.card", h("h2", t("stores.byMonth")), periodTable(months)));

    const ca = countries(data, "android");
    const ci = countries(data, "ios");
    const codes = [...new Set([...Object.keys(ca), ...Object.keys(ci)])].map((c) => ({ code: c, android: ca[c] || 0, ios: ci[c] || 0 })).sort((a, b) => (b.android + b.ios) - (a.android + a.ios)).slice(0, 15);
    body.append(h("div.card", h("h2", t("stores.byCountry")), table([
      { label: t("stores.country"), cell: (r) => `${regionName(r.code)} (${r.code})` },
      { label: t("stores.android"), num: true, cell: (r) => fmtNumber(r.android) },
      { label: t("stores.ios"), num: true, cell: (r) => fmtNumber(r.ios) },
      { label: t("common.total"), num: true, cell: (r) => h("b", fmtNumber(r.android + r.ios)) },
    ], codes, { emptyText: t("stores.noData") })));

    let running = 0;
    const dayRows = merge(data, "all").map((p) => { running += p.android + p.ios; return { ...p, running }; }).reverse().filter((p) => points.some((q) => q.day === p.day)).slice(0, 120);
    body.append(h("div.card", h("h2", t("stores.dayTable")), table([
      { label: t("common.date"), cell: (r) => h("span.mono", r.day) },
      { label: t("stores.android"), num: true, cell: (r) => fmtNumber(r.android) },
      { label: t("stores.ios"), num: true, cell: (r) => fmtNumber(r.ios) },
      { label: t("common.total"), num: true, cell: (r) => h("b", fmtNumber(r.android + r.ios)) },
      { label: t("stores.cumulative"), num: true, cell: (r) => fmtNumber(r.running) },
      { label: t("stores.activeDevices"), num: true, cell: (r) => (r.a ? fmtNumber(r.a.activeDevices || 0) : "—") },
      { label: t("stores.uninstalls"), num: true, cell: (r) => (r.a ? fmtNumber(r.a.uninstalls || 0) : "—") },
      { label: t("stores.updates"), num: true, cell: (r) => (r.i ? fmtNumber(r.i.updates || 0) : "—") },
    ], dayRows, { emptyText: t("stores.noData") })));

    body.append(h("p.small.muted", t("stores.footnote")));
  }

  load();
  return () => {};
}
