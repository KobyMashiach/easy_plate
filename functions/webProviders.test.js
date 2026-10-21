// The web purchase path — PayPlus (Israel, direct) and RevenueCat's Paddle
// Billing integration (everyone else): provider routing, signature checks,
// idempotency, the entitlement each event leads to, and the "not
// configured" answers. Firestore and the providers are faked.
const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const catalogs = require("./billingCatalog");
const payplus = require("./payplusClient");
const paddle = require("./paddleClient");
const web = require("./webEntitlement");
const pp = require("./payplusWebhook").internals;
const rcw = require("./revenueCatWebhook").internals;
const billing = require("./webBilling").internals;

const DAY = 86_400_000;
const NOW = Date.UTC(2026, 9, 18, 12, 0, 0);
const UID = "uid0000000001";

// ---------------------------------------------------------------------------
// Fakes

function fakeDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  const isDelete = (v) => v && typeof v === "object" && v.constructor && v.constructor.name === "DeleteTransform";
  const snapOf = (path) => ({ id: path.split("/").pop(), exists: store.has(path), data: () => store.get(path), get: (f) => (store.get(path) || {})[f], ref: docRef(path) });
  const write = (path, data, opts) => {
    const next = opts && opts.merge ? { ...(store.get(path) || {}) } : {};
    for (const [k, v] of Object.entries(data)) {
      if (isDelete(v)) delete next[k];
      else next[k] = v;
    }
    store.set(path, next);
  };
  function docRef(path) {
    return { path, id: path.split("/").pop(), get: async () => snapOf(path), set: async (d, o) => write(path, d, o), delete: async () => store.delete(path) };
  }
  const query = (name, filters = [], max = Infinity) => ({
    where: (field, op, value) => query(name, [...filters, [field, value]], max),
    limit: (n) => query(name, filters, n),
    get: async () => {
      const docs = [...store.keys()]
        .filter((p) => p.startsWith(`${name}/`) && p.split("/").length === 2)
        .filter((p) => filters.every(([f, v]) => (store.get(p) || {})[f] === v))
        .slice(0, max)
        .map(snapOf);
      return { empty: docs.length === 0, size: docs.length, docs };
    },
  });
  return {
    store,
    doc: (path) => docRef(path),
    collection: (name) => ({ doc: (id) => docRef(`${name}/${id}`), ...query(name) }),
    runTransaction: async (fn) => fn({ get: (ref) => ref.get(), set: (ref, d, o) => write(ref.path, d, o) }),
  };
}

function scripted(routes) {
  const calls = [];
  const fetchImpl = async (url, init) => {
    const u = new URL(url);
    const path = u.pathname.replace(/^\/api\/v1\.0/, "");
    calls.push({ method: init.method, host: u.host, path, query: u.search, body: init.body ? JSON.parse(init.body) : null, headers: init.headers });
    const handler = routes[`${init.method} ${path}`];
    const [status, body] = handler ? handler(init.body ? JSON.parse(init.body) : null) : [404, { error: { code: "not_found" } }];
    return { ok: status < 300, status, text: async () => JSON.stringify(body) };
  };
  return { calls, fetchImpl };
}

const CATALOG = catalogs.parseCatalog({
  payplus: {
    env: "staging",
    plans: [
      { id: "easy_plate_ai_pro_monthly", interval: "month", amount: 2000, order: 1 },
      { id: "easy_plate_ai_pro_duo_yearly", interval: "year", amount: 29900, order: 2 },
    ],
  },
  revenuecat: {
    purchaseLink: "https://pay.rev.cat/sandbox/abc123token/",
    projectId: "proj1a2b3c4d",
    plans: [
      { id: "easy_plate_ai_pro_monthly", productId: "pri_01abcdefghijk", packageId: "$rc_monthly", interval: "month", amount: 599, currency: "USD" },
      { id: "easy_plate_ai_pro_family_yearly", productId: "pri_01familyyearly", packageId: "family_yearly", interval: "year", amount: 9900, currency: "USD" },
    ],
  },
});
const OPEN = { master: 2, payplus: 2, revenuecat: 2 };
const PP_KEYS = { apiKey: "pp_api", secretKey: "pp_secret", terminalUid: "term-1", pageUid: "page-1", env: "staging" };
const KEYS = { payplus: PP_KEYS, paddle: { apiKey: "pdl_sdbx_apikey_123" }, revenuecat: { secretKey: "sk_rc_v2_secret" } };
const NO_KEYS = { payplus: { apiKey: "-", secretKey: "-", terminalUid: "-", pageUid: "-" }, paddle: { apiKey: "-" }, revenuecat: { secretKey: "-" } };
const ISRAELI = { uid: UID, phone_number: "+972541234567" };
const ABROAD = { uid: UID, phone_number: "+14155550100" };
const exists = async () => true;
const ms = (v) => (v && typeof v.toMillis === "function" ? v.toMillis() : v instanceof Date ? v.getTime() : v);

// ---------------------------------------------------------------------------
// Routing and catalogue

test("the provider follows the verified phone: +972 → PayPlus, anything else → RevenueCat (Paddle)", () => {
  assert.equal(catalogs.providerFor(ISRAELI), "payplus");
  assert.equal(catalogs.providerFor(ABROAD), "revenuecat");
  assert.equal(catalogs.providerFor({ uid: UID }), "revenuecat");
  // A visitor with no account: a guess from the page language, prices only.
  assert.equal(catalogs.providerFor(null, { lang: "he" }), "payplus");
  assert.equal(catalogs.providerFor(null, { lang: "fr" }), "revenuecat");
  // Only an administrator may force the other route; the retired names are no route.
  assert.equal(catalogs.providerFor(ISRAELI, { override: "revenuecat", isAdmin: true }), "revenuecat");
  assert.equal(catalogs.providerFor(ISRAELI, { override: "revenuecat", isAdmin: false }), "payplus");
  assert.equal(catalogs.providerFor(ABROAD, { override: "stripe", isAdmin: true }), "revenuecat");
  assert.equal(catalogs.providerFor(ABROAD, { override: "paddle", isAdmin: true }), "revenuecat");
});

test("a provider sells only with its own switch and the master one on (administrators pass)", () => {
  assert.equal(catalogs.providerOpen({ master: 2, payplus: 2, revenuecat: 0 }, "payplus"), true);
  assert.equal(catalogs.providerOpen({ master: 2, payplus: 2, revenuecat: 0 }, "revenuecat"), false);
  assert.equal(catalogs.providerOpen({ master: 0, payplus: 2, revenuecat: 2 }, "payplus"), false);
  assert.equal(catalogs.providerOpen({ master: 0, payplus: 0, revenuecat: 0 }, "revenuecat", true), true);
  // No Remote Config read: everything closed.
  assert.deepEqual(catalogs.switches({}), { master: 0, payplus: 0, revenuecat: 0 });
  assert.equal(catalogs.switches({ ff_web_checkout_intl: { defaultValue: { value: "2" } } }).revenuecat, 2);
});

test("the catalogue keeps only well-formed plans, with the tier from the plan id", () => {
  assert.equal(CATALOG.payplus.plans.length, 2);
  assert.equal(CATALOG.payplus.plans[1].tier, "duo");
  assert.equal(CATALOG.payplus.plans[1].seats, 2);
  assert.equal(CATALOG.revenuecat.plans[1].tier, "family");
  assert.equal(CATALOG.revenuecat.plans[1].productId, "pri_01familyyearly");
  assert.equal(CATALOG.revenuecat.purchaseLink, "https://pay.rev.cat/sandbox/abc123token", "the trailing slash is dropped");
  assert.equal(CATALOG.revenuecat.projectId, "proj1a2b3c4d");
  const bad = catalogs.parseCatalog(JSON.stringify({
    payplus: { plans: [{ id: "x", interval: "month", amount: 1 }, { id: "easy_plate_ai_pro_monthly", interval: "week", amount: 1 }, { id: "easy_plate_ai_pro_monthly", interval: "month", amount: 10, currency: "USD" }] },
    revenuecat: { purchaseLink: "https://evil.example/pay.rev.cat/x", projectId: "-", plans: [{ id: "easy_plate_ai_pro_monthly", interval: "month", amount: 10 }] },
  }));
  assert.equal(bad.payplus.plans.length, 0);
  assert.equal(bad.revenuecat.plans.length, 0, "a RevenueCat plan needs its product id");
  assert.equal(bad.revenuecat.purchaseLink, null);
  assert.equal(bad.revenuecat.projectId, null);
  assert.equal(catalogs.parseCatalog({ revenuecat: { purchaseLink: "http://pay.rev.cat/abc" } }).revenuecat.purchaseLink, null, "https only");
  // The retired Paddle section is ignored.
  assert.equal(catalogs.parseCatalog({ paddle: { clientToken: "live_0123456789", plans: [] } }).paddle, undefined);
  assert.deepEqual(catalogs.parseCatalog("not json").payplus.plans, []);
});

test("periods are calendar months / years, clamped at month end", () => {
  assert.equal(new Date(catalogs.addInterval(Date.UTC(2026, 0, 31), "month")).toISOString().slice(0, 10), "2026-02-28");
  assert.equal(new Date(catalogs.addInterval(Date.UTC(2026, 9, 18), "year")).toISOString().slice(0, 10), "2027-10-18");
});

test("PayPlus dates are Israel local time", () => {
  // 18 Oct 2026 is summer time (+3).
  assert.equal(payplus.israelMs("2026-10-18 15:00:00"), Date.UTC(2026, 9, 18, 12, 0, 0));
  // 1 Jan is winter time (+2).
  assert.equal(payplus.israelMs("2026-01-01 02:00:00"), Date.UTC(2026, 0, 1, 0, 0, 0));
  assert.equal(payplus.israelMs("yesterday"), null);
});

// ---------------------------------------------------------------------------
// Signatures

test("PayPlus callbacks: the hash over the body with the secret key, the PayPlus user agent", () => {
  const body = JSON.stringify({ transaction_type: "Charge", transaction: { uid: "t1" } });
  const headers = payplus.sign(body, "pp_secret");
  assert.equal(payplus.verifyCallback(headers, Buffer.from(body), "pp_secret"), null);
  assert.equal(payplus.verifyCallback(headers, Buffer.from(body.replace("t1", "t2")), "pp_secret"), "mismatch");
  assert.equal(payplus.verifyCallback(headers, Buffer.from(body), "other"), "mismatch");
  assert.equal(payplus.verifyCallback({ ...headers, "user-agent": "curl/8" }, Buffer.from(body), "pp_secret"), "user_agent");
  assert.equal(payplus.verifyCallback({ "user-agent": "PayPlus" }, Buffer.from(body), "pp_secret"), "missing");
  // Signed compact, delivered pretty-printed: the re-serialised body matches.
  assert.equal(payplus.verifyCallback(headers, Buffer.from(JSON.stringify(JSON.parse(body), null, 2)), "pp_secret"), null);
  assert.equal(payplus.verifyCallback(headers, Buffer.from(body), "-"), "not_configured");
});

test("Paddle webhooks: ts;h1 over `ts:rawBody`, five-minute window, rotation, no placeholder secret", () => {
  const body = JSON.stringify({ event_id: "evt_1", event_type: "subscription.created" });
  const ts = Math.floor(NOW / 1000);
  const header = paddle.sign(body, "pdl_ntfset_secret", ts);
  assert.equal(paddle.verifySignature(header, Buffer.from(body), "pdl_ntfset_secret", { nowMs: NOW }), null);
  assert.equal(paddle.verifySignature(header, Buffer.from(body + " "), "pdl_ntfset_secret", { nowMs: NOW }), "mismatch");
  assert.equal(paddle.verifySignature(header, Buffer.from(body), "wrong", { nowMs: NOW }), "mismatch");
  // A captured delivery replayed later is refused by its timestamp.
  assert.equal(paddle.verifySignature(header, Buffer.from(body), "pdl_ntfset_secret", { nowMs: NOW + 10 * 60 * 1000 }), "stale");
  assert.equal(paddle.verifySignature("h1=abc", Buffer.from(body), "pdl_ntfset_secret", { nowMs: NOW }), "malformed");
  assert.equal(paddle.verifySignature(undefined, Buffer.from(body), "pdl_ntfset_secret", { nowMs: NOW }), "missing");
  // During a secret rotation two h1 values arrive; either may match.
  assert.equal(paddle.verifySignature(`ts=${ts};h1=${"0".repeat(64)};${header.split(";")[1]}`, Buffer.from(body), "pdl_ntfset_secret", { nowMs: NOW }), null);
  assert.equal(paddle.verifySignature(header, Buffer.from(body), "-", { nowMs: NOW }), "not_configured");
});

test("the PayPlus webhook answers 503 billing_disabled while its secret is the placeholder", async () => {
  const call = async (fn, headers = {}) => {
    let status = 0;
    let payload = null;
    const req = { method: "POST", headers, get: (h) => headers[h.toLowerCase()], rawBody: Buffer.from("{}"), body: {} };
    const res = { status(s) { status = s; return this; }, json(b) { payload = b; return this; }, send(b) { payload = b; return this; }, set() { return this; }, setHeader() {}, getHeader() {}, end() {} };
    await fn(req, res);
    return { status, payload };
  };
  process.env.PAYPLUS_SECRET_KEY = "-";
  const b = await call(require("./payplusWebhook").payplusWebhook);
  assert.equal(b.status, 503);
  assert.equal(b.payload.error.code, "billing_disabled");
  // Configured, but unsigned: refused.
  process.env.PAYPLUS_SECRET_KEY = "pp_secret";
  assert.equal((await call(require("./payplusWebhook").payplusWebhook, { "user-agent": "PayPlus", hash: "bogus" })).status, 401);
  delete process.env.PAYPLUS_SECRET_KEY;
});

test("the direct Paddle webhook is retired: not exported, so a Paddle notification cannot grant twice", () => {
  const src = require("node:fs").readFileSync(require("node:path").join(__dirname, "index.js"), "utf8");
  assert.equal(/exports\.paddleWebhook\s*=/.test(src), false);
});

// ---------------------------------------------------------------------------
// PayPlus events → entitlement

const ppCharge = (over = {}, tx = {}) => ({
  transaction_type: "Charge",
  transaction: {
    uid: "tx-1",
    payment_request_uid: "page-req-1",
    date: "2026-10-18 15:00:00",
    status_code: "000",
    amount: 299,
    currency: "ILS",
    more_info: UID,
    more_info_1: "easy_plate_ai_pro_duo_yearly",
    recurring_charge_information: { recurring_uid: "rec-1", charge_uid: "ch-1" },
    ...tx,
  },
  data: { customer_uid: "cust-1" },
  ...over,
});

test("PayPlus: the first charge turns Premium on for the paid period + grace, with the tier in productId", async () => {
  const db = fakeDb();
  const out = await pp.process(db, ppCharge(), { catalog: CATALOG, userExists: exists, nowMs: NOW });
  assert.equal(out.outcome, "apply");
  const ent = db.store.get(`entitlements/${UID}`);
  assert.equal(ent.premium, true);
  assert.equal(ent.source, "payplus");
  assert.equal(ent.productId, "easy_plate_ai_pro_duo_yearly");
  assert.equal(catalogs.tierOf(ent.productId), "duo");
  assert.equal(ms(ent.premiumUntil), catalogs.addInterval(NOW, "year") + web.GRACE_MS.payplus);
  const cust = db.store.get(`web_customers/${UID}`);
  assert.equal(cust.provider, "payplus");
  assert.equal(cust.subscriptionId, "rec-1");
  assert.equal(cust.payplusCustomerUid, "cust-1");
  assert.equal(cust.everSubscribed, true);
  assert.ok(db.store.get("purchase_events/payplus_tx-1_charge"));
});

test("PayPlus: the same callback twice is applied once", async () => {
  const db = fakeDb();
  await pp.process(db, ppCharge(), { catalog: CATALOG, userExists: exists, nowMs: NOW });
  const first = { ...db.store.get(`entitlements/${UID}`) };
  const again = await pp.process(db, ppCharge(), { catalog: CATALOG, userExists: exists, nowMs: NOW + 1000 });
  assert.equal(again.outcome, "replayed");
  assert.deepEqual(db.store.get(`entitlements/${UID}`), first);
});

test("PayPlus: a renewal (no uid in it) is found by its recurring and extends the period", async () => {
  const db = fakeDb();
  await pp.process(db, ppCharge({}, { more_info_1: "easy_plate_ai_pro_monthly" }), { catalog: CATALOG, userExists: exists, nowMs: NOW });
  const renewal = ppCharge({}, { uid: "tx-2", payment_request_uid: undefined, more_info: undefined, more_info_1: undefined, date: "2026-11-18 15:00:00" });
  const out = await pp.process(db, renewal, { catalog: CATALOG, userExists: exists, nowMs: NOW + 31 * DAY });
  assert.equal(out.uid, UID);
  assert.equal(out.outcome, "apply");
  const ent = db.store.get(`entitlements/${UID}`);
  assert.equal(ent.productId, "easy_plate_ai_pro_monthly");
  assert.equal(ms(ent.premiumUntil), catalogs.addInterval(Date.UTC(2026, 10, 18, 13, 0, 0), "month") + web.GRACE_MS.payplus);
});

test("PayPlus: a failed renewal is past_due and keeps the paid end; a refund ends Premium and deletes the recurring", async () => {
  const db = fakeDb();
  await pp.process(db, ppCharge(), { catalog: CATALOG, userExists: exists, nowMs: NOW });
  const paidUntil = ms(db.store.get(`entitlements/${UID}`).premiumUntil);
  const failed = ppCharge({}, { uid: "tx-f", status_code: "033", more_info: undefined, payment_request_uid: undefined, date: "2026-10-19 10:00:00" });
  const f = await pp.process(db, failed, { catalog: CATALOG, userExists: exists, nowMs: NOW + DAY });
  assert.equal(f.outcome, "apply");
  assert.equal(db.store.get(`web_customers/${UID}`).subscriptionStatus, "past_due");
  assert.equal(db.store.get(`entitlements/${UID}`).premium, true);
  assert.equal(ms(db.store.get(`entitlements/${UID}`).premiumUntil), paidUntil);

  const s = scripted({ "POST /RecurringPayments/DeleteRecurring/rec-1": () => [200, { results: { status: "success" } }] });
  const refund = { transaction_type: "Refund", transaction: { uid: "tx-r", status_code: "000", date: "2026-10-20 10:00:00", amount: 299, currency: "ILS" }, data: { customer_uid: "cust-1" } };
  const r = await pp.process(db, refund, { catalog: CATALOG, keys: PP_KEYS, fetchImpl: s.fetchImpl, userExists: exists, nowMs: NOW + 2 * DAY });
  assert.equal(r.outcome, "apply");
  const ent = db.store.get(`entitlements/${UID}`);
  assert.equal(ent.premium, false);
  assert.equal(ent.premiumUntil, null);
  assert.equal(db.store.get(`web_customers/${UID}`).subscriptionStatus, "refunded");
  assert.equal(s.calls.length, 1);
  assert.equal(s.calls[0].path, "/RecurringPayments/DeleteRecurring/rec-1");
  assert.equal(s.calls[0].body.terminal_uid, "term-1");
});

test("PayPlus: a failed first payment and a stranger's callback write nothing but the audit row", async () => {
  const db = fakeDb();
  const failedFirst = ppCharge({}, { status_code: "006" });
  assert.equal((await pp.process(db, failedFirst, { catalog: CATALOG, userExists: exists, nowMs: NOW })).outcome, "audit_only");
  const stranger = ppCharge({}, { more_info: undefined, recurring_charge_information: { recurring_uid: "someone-else" } });
  stranger.data = { customer_uid: "nobody" };
  assert.equal((await pp.process(db, stranger, { catalog: CATALOG, userExists: exists, nowMs: NOW })).outcome, "audit_only");
  assert.equal(db.store.has(`entitlements/${UID}`), false);
});

test("PayPlus: a second live subscription is not applied — it is stopped and flagged for a refund", async () => {
  const db = fakeDb();
  await pp.process(db, ppCharge(), { catalog: CATALOG, userExists: exists, nowMs: NOW });
  const s = scripted({ "POST /RecurringPayments/DeleteRecurring/rec-2": () => [200, { results: { status: "success" } }] });
  const second = ppCharge({}, { uid: "tx-9", payment_request_uid: "page-req-2", recurring_charge_information: { recurring_uid: "rec-2" } });
  second.data = { customer_uid: "cust-2" };
  const out = await pp.process(db, second, { catalog: CATALOG, keys: PP_KEYS, fetchImpl: s.fetchImpl, userExists: exists, nowMs: NOW + 1000 });
  assert.equal(out.outcome, "duplicate");
  assert.equal(db.store.get(`web_customers/${UID}`).subscriptionId, "rec-1");
  assert.equal(db.store.get("purchase_events/payplus_tx-9_charge").refundDue, true);
  assert.equal(s.calls[0].path, "/RecurringPayments/DeleteRecurring/rec-2");
});

test("PayPlus: an event for a deleted account writes the audit row only", async () => {
  const db = fakeDb();
  const out = await pp.process(db, ppCharge(), { catalog: CATALOG, userExists: async () => false, nowMs: NOW });
  assert.equal(out.outcome, "orphan");
  assert.equal(db.store.has(`entitlements/${UID}`), false);
});

// ---------------------------------------------------------------------------
// RevenueCat (Paddle) events → entitlement

const rcEvent = (type, over = {}) => ({
  id: `evt_${type}_${over.event_timestamp_ms || NOW}`,
  type,
  app_user_id: UID,
  aliases: [UID],
  store: "PADDLE",
  environment: "SANDBOX",
  product_id: "pri_01familyyearly",
  entitlement_ids: ["easy_plate_ai_pro"],
  event_timestamp_ms: NOW,
  expiration_at_ms: NOW + 365 * DAY,
  price: 99,
  ...over,
});
const applyAll = async (db, events, catalog = CATALOG) => {
  for (const e of events) for (const w of rcw.decide(e, NOW, { catalog })) await rcw.apply(db, w);
};

test("RevenueCat/Paddle: a purchase turns Premium on to the period end; the Paddle price maps back to the plan id (family tier)", async () => {
  const db = fakeDb();
  await applyAll(db, [rcEvent("INITIAL_PURCHASE")]);
  const ent = db.store.get(`entitlements/${UID}`);
  assert.equal(ent.premium, true);
  assert.equal(ent.source, "revenuecat");
  assert.equal(ent.store, "PADDLE");
  assert.equal(ent.productId, "easy_plate_ai_pro_family_yearly");
  assert.equal(ent.storeProductId, "pri_01familyyearly");
  assert.equal(catalogs.tierOf(ent.productId), "family");
  assert.equal(ms(ent.premiumUntil), NOW + 365 * DAY);
  assert.equal(ent.cancelAtPeriodEnd, false);
  // A product the catalogue does not list stays as RevenueCat named it.
  assert.equal(rcw.decide(rcEvent("RENEWAL", { product_id: "pri_unknown" }), NOW, { catalog: CATALOG })[0].data.productId, "pri_unknown");
  // A store purchase is never mapped.
  assert.equal(rcw.decide(rcEvent("RENEWAL", { store: "APP_STORE", product_id: "pri_01familyyearly" }), NOW, { catalog: CATALOG })[0].data.storeProductId, undefined);
});

test("RevenueCat/Paddle: a cancellation keeps Premium to the period end (ends, not renews); expiration ends it", async () => {
  const db = fakeDb();
  await applyAll(db, [rcEvent("INITIAL_PURCHASE"), rcEvent("CANCELLATION", { event_timestamp_ms: NOW + DAY, cancel_reason: "UNSUBSCRIBE" })]);
  let ent = db.store.get(`entitlements/${UID}`);
  assert.equal(ent.premium, true);
  assert.equal(ent.cancelAtPeriodEnd, true);
  await applyAll(db, [rcEvent("UNCANCELLATION", { event_timestamp_ms: NOW + 2 * DAY })]);
  assert.equal(db.store.get(`entitlements/${UID}`).cancelAtPeriodEnd, false);
  await applyAll(db, [rcEvent("EXPIRATION", { event_timestamp_ms: NOW + 3 * DAY })]);
  ent = db.store.get(`entitlements/${UID}`);
  assert.equal(ent.premium, false);
});

test("RevenueCat/Paddle: a refund (CUSTOMER_SUPPORT, negative price) ends Premium at once", async () => {
  assert.equal(rcw.isRefund(rcEvent("CANCELLATION", { cancel_reason: "CUSTOMER_SUPPORT", price: -99 })), true);
  assert.equal(rcw.isRefund(rcEvent("CANCELLATION", { cancel_reason: "UNSUBSCRIBE", price: 99 })), false);
  const db = fakeDb();
  await applyAll(db, [rcEvent("INITIAL_PURCHASE"), rcEvent("CANCELLATION", { event_timestamp_ms: NOW + DAY, cancel_reason: "CUSTOMER_SUPPORT", price: -99 })]);
  assert.equal(db.store.get(`entitlements/${UID}`).premium, false);
});

test("RevenueCat/Paddle: one store's end does not undo a plan live in another store or another source", async () => {
  const future = { toMillis: () => NOW + 100 * DAY };
  // App Store plan live; the Paddle one expires.
  const store = fakeDb({ [`entitlements/${UID}`]: { premium: true, premiumUntil: future, source: "revenuecat", store: "APP_STORE", lastEventAt: 0 } });
  await applyAll(store, [rcEvent("EXPIRATION")]);
  assert.equal(store.store.get(`entitlements/${UID}`).premium, true);
  // A live PayPlus plan; the Paddle one expires.
  const pay = fakeDb({ [`entitlements/${UID}`]: { premium: true, premiumUntil: future, source: "payplus", lastEventAt: 0 } });
  await applyAll(pay, [rcEvent("EXPIRATION")]);
  assert.equal(pay.store.get(`entitlements/${UID}`).premium, true);
  // The administrator's lock holds.
  const locked = fakeDb({ [`entitlements/${UID}`]: { premium: false, adminLock: true, source: "admin", lastEventAt: 0 } });
  await applyAll(locked, [rcEvent("INITIAL_PURCHASE")]);
  assert.equal(locked.store.get(`entitlements/${UID}`).premium, false);
  // The same store: the expiration does end it.
  const same = fakeDb({ [`entitlements/${UID}`]: { premium: true, premiumUntil: future, source: "revenuecat", store: "PADDLE", lastEventAt: 0 } });
  await applyAll(same, [rcEvent("EXPIRATION")]);
  assert.equal(same.store.get(`entitlements/${UID}`).premium, false);
});

test("RevenueCat/Paddle: the audit row records the mapped plan and the cancel reason", () => {
  const row = rcw.eventRecord(rcEvent("CANCELLATION", { cancel_reason: "CUSTOMER_SUPPORT", price: -99 }), NOW, { catalog: CATALOG });
  assert.equal(row.data.store, "PADDLE");
  assert.equal(row.data.planId, "easy_plate_ai_pro_family_yearly");
  assert.equal(row.data.cancelReason, "CUSTOMER_SUPPORT");
  assert.equal(rcw.eventRecord(rcEvent("RENEWAL", { store: "PLAY_STORE" }), NOW).data.planId, null);
});

// ---------------------------------------------------------------------------
// webBilling

const req = (action, extra = {}) => billing.parseRequest({ action, lang: "he", ...extra });

test("requests are typed: plan ids, the old `portal` name, the confirm flag", () => {
  assert.equal(billing.parseRequest({ action: "nope" }).error, "Unknown action");
  assert.equal(billing.parseRequest({ action: "checkout", planId: "price_123" }).error, "planId required");
  assert.equal(billing.parseRequest({ action: "portal" }).action, "manage");
  assert.equal(billing.parseRequest({ action: "manage", confirm: true }).confirm, true);
  assert.equal(billing.parseRequest({ action: "plans", provider: "stripe" }).provider, undefined);
});

test("plans: an Israeli caller sees PayPlus prices, a foreign one RevenueCat's (Paddle) plans", async () => {
  const db = fakeDb();
  const il = await billing.handle({ db, caller: ISRAELI, request: req("plans"), keys: KEYS, catalog: CATALOG, switches: OPEN });
  assert.equal(il.body.provider, "payplus");
  assert.equal(il.body.enabled, true);
  assert.equal(il.body.plans[0].currency, "ils");
  assert.equal(il.body.paddle, undefined);
  const intl = await billing.handle({ db, caller: ABROAD, request: req("plans"), keys: KEYS, catalog: CATALOG, switches: OPEN });
  assert.equal(intl.body.provider, "revenuecat");
  assert.equal(intl.body.enabled, true);
  assert.equal(intl.body.plans.length, 2);
  // No purchase link yet: not configured, nothing on sale.
  const noLink = await billing.handle({ db, caller: ABROAD, request: req("plans"), keys: KEYS, catalog: { ...CATALOG, revenuecat: { ...CATALOG.revenuecat, purchaseLink: null } }, switches: OPEN });
  assert.equal(noLink.body.enabled, false);
  assert.equal(noLink.body.configured, false);
  // Switch at 1: coming soon, no plans.
  const soon = await billing.handle({ db, caller: ABROAD, request: req("plans"), keys: KEYS, catalog: CATALOG, switches: { master: 2, payplus: 2, revenuecat: 1 } });
  assert.equal(soon.body.enabled, false);
  assert.equal(soon.body.comingSoon, true);
  assert.deepEqual(soon.body.plans, []);
});

test("a provider whose secrets are still '-' answers 503 billing_disabled; a closed switch 403", async () => {
  const db = fakeDb();
  const plans = await billing.handle({ db, caller: ISRAELI, request: req("plans"), keys: NO_KEYS, catalog: CATALOG, switches: OPEN });
  assert.equal(plans.body.enabled, false);
  assert.equal(plans.body.configured, false);
  const out = await billing.handle({ db, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: NO_KEYS, catalog: CATALOG, switches: OPEN });
  assert.equal(out.status, 503);
  assert.equal(out.body.error.code, "billing_disabled");
  const rcOut = await billing.handle({ db, caller: ABROAD, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: NO_KEYS, catalog: { ...CATALOG, revenuecat: { ...CATALOG.revenuecat, purchaseLink: null } }, switches: OPEN });
  assert.equal(rcOut.status, 503);
  const closed = await billing.handle({ db, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: { master: 2, payplus: 0, revenuecat: 2 } });
  assert.equal(closed.status, 403);
  assert.equal(closed.body.error.code, "disabled");
  const noPhone = await billing.handle({ db, caller: { uid: UID }, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: OPEN });
  assert.equal(noPhone.body.error.code, "phone_required");
});

test("checkout via PayPlus: a recurring payment page carrying the uid; a second click is held", async () => {
  const db = fakeDb();
  const s = scripted({ "POST /PaymentPages/generateLink": () => [200, { results: { status: "success", code: 0 }, data: { page_request_uid: "pr-1", payment_page_link: "https://paymentsdev.payplus.co.il/pr-1" } }] });
  const out = await billing.handle({ db, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_duo_yearly" }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s.fetchImpl, nowMs: NOW, user: { email: "a@b.co" } });
  assert.equal(out.status, 200);
  assert.equal(out.body.provider, "payplus");
  assert.equal(out.body.url, "https://paymentsdev.payplus.co.il/pr-1");
  const call = s.calls[0];
  assert.equal(call.host, "restapidev.payplus.co.il");
  assert.equal(call.headers["api-key"], "pp_api");
  assert.equal(call.body.charge_method, 3);
  assert.equal(call.body.amount, 299);
  assert.equal(call.body.currency_code, "ILS");
  assert.equal(call.body.more_info, UID);
  assert.equal(call.body.more_info_1, "easy_plate_ai_pro_duo_yearly");
  assert.equal(call.body.recurring_settings.recurring_type, 2);
  assert.equal(call.body.recurring_settings.recurring_range, 12);
  assert.equal(call.body.recurring_settings.number_of_charges, 0);
  assert.equal(call.body.recurring_settings.instant_first_payment, true);
  assert.match(call.body.refURL_callback, /\/payplusWebhook$/);
  assert.equal(db.store.get(`web_customers/${UID}`).checkoutRef, "pr-1");
  // Back from the page and again: the old page is disabled first, then a new one.
  const s2 = scripted({
    "POST /PaymentPages/Disable/pr-1": () => [200, { results: { status: "success" } }],
    "POST /PaymentPages/generateLink": () => [200, { results: { status: "success" }, data: { page_request_uid: "pr-2", payment_page_link: "https://paymentsdev.payplus.co.il/pr-2" } }],
  });
  const again = await billing.handle({ db, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s2.fetchImpl, nowMs: NOW + 60_000, user: {} });
  assert.equal(again.status, 200);
  assert.deepEqual(s2.calls.map((c) => c.path), ["/PaymentPages/Disable/pr-1", "/PaymentPages/generateLink"]);
  // The old page could not be closed (paid meanwhile): no second page.
  const s3 = scripted({ "POST /PaymentPages/Disable/pr-2": () => [422, { results: { status: "error" } }] });
  const held = await billing.handle({ db, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s3.fetchImpl, nowMs: NOW + 120_000, user: {} });
  assert.equal(held.status, 409);
  assert.equal(held.body.error.code, "checkout_pending");
  assert.equal(s3.calls.some((c) => c.path === "/PaymentPages/generateLink"), false);
});

test("checkout via RevenueCat: the Web Purchase Link with the verified uid as App User ID, no provider call, no hold", async () => {
  const db = fakeDb();
  const caller = { ...ABROAD, uid: "uid with/slash", email: "a+b@c.co" };
  const out = await billing.handle({ db, caller, request: { ...req("checkout", { planId: "easy_plate_ai_pro_family_yearly" }), uid: "someone_else" }, keys: NO_KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: async () => { throw new Error("must not be called"); }, nowMs: NOW });
  assert.equal(out.status, 200);
  assert.equal(out.body.provider, "revenuecat");
  assert.equal(out.body.url, "https://pay.rev.cat/sandbox/abc123token/uid%20with%2Fslash?package_id=family_yearly&email=a%2Bb%40c.co");
  assert.equal(billing.isPurchaseLink(out.body.url), true);
  assert.equal(db.store.has(`web_customers/${UID}`), false, "no pending hold for a hosted checkout");
  // A plan with no package: RevenueCat's page lets the buyer choose.
  assert.equal(catalogs.purchaseUrl("https://pay.rev.cat/t", "u1"), "https://pay.rev.cat/t/u1");
  // The request cannot pick the account.
  assert.equal(billing.parseRequest({ action: "checkout", planId: "easy_plate_ai_pro_monthly", uid: "x" }).uid, undefined);
});

test("a refused PayPlus call releases the hold; a network failure keeps it", async () => {
  const db = fakeDb();
  const s = scripted({ "POST /PaymentPages/generateLink": () => [400, { results: { status: "error" } }] });
  await assert.rejects(billing.handle({ db, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s.fetchImpl, nowMs: NOW, user: {} }));
  assert.equal(db.store.get(`web_customers/${UID}`).checkoutPendingUntil, undefined);
  const db2 = fakeDb();
  await assert.rejects(billing.handle({ db: db2, caller: ISRAELI, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: async () => { throw new TypeError("fetch failed"); }, nowMs: NOW, user: {} }));
  assert.ok(db2.store.get(`web_customers/${UID}`).checkoutPendingUntil);
});

test("checkout is refused to a live web subscriber, a store subscriber and a household member", async () => {
  const future = { toMillis: () => NOW + 30 * DAY };
  const cases = [
    [{ [`web_customers/${UID}`]: { provider: "payplus", subscriptionId: "rec_1", subscriptionStatus: "active", currentPeriodEnd: future } }, "already_subscribed"],
    [{ [`entitlements/${UID}`]: { premium: true, premiumUntil: future, source: "revenuecat", store: "PADDLE" } }, "already_subscribed"],
    [{ [`entitlements/${UID}`]: { premium: true, premiumUntil: future, source: "revenuecat" } }, "store_subscription"],
    [{ [`entitlements/${UID}`]: { premium: true, source: "household" } }, "household_member"],
  ];
  for (const [seed, code] of cases) {
    const out = await billing.handle({ db: fakeDb(seed), caller: ABROAD, request: req("checkout", { planId: "easy_plate_ai_pro_monthly" }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: async () => { throw new Error("must not be called"); }, nowMs: NOW });
    assert.equal(out.status, 409);
    assert.equal(out.body.error.code, code);
  }
});

test("manage: RevenueCat/Paddle → the authenticated Paddle portal from RevenueCat's API; PayPlus → confirm, then the recurring stops", async () => {
  const future = NOW + 20 * DAY;
  const ts = { toMillis: () => future };
  const rcDb = fakeDb({ [`entitlements/${UID}`]: { premium: true, premiumUntil: ts, source: "revenuecat", store: "PADDLE" } });
  const s = scripted({
    "GET /v2/projects/proj1a2b3c4d/customers/uid0000000001/subscriptions": () => [200, { items: [
      { id: "sub_rc_old", store: "paddle", gives_access: false, current_period_ends_at: NOW - DAY, management_url: null },
      { id: "sub_rc_1", store: "paddle", gives_access: true, current_period_ends_at: future, management_url: "https://sandbox-customer-portal.paddle.com/cpl_1" },
      { id: "sub_rc_ios", store: "app_store", gives_access: true, current_period_ends_at: future },
    ] }],
    "GET /v2/projects/proj1a2b3c4d/subscriptions/sub_rc_1/authenticated_management_url": () => [200, { object: "authenticated_management_url", management_url: "https://sandbox-customer-portal.paddle.com/cpl_1?token=x" }],
  });
  const portal = await billing.handle({ db: rcDb, caller: ABROAD, request: req("manage"), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s.fetchImpl, nowMs: NOW });
  assert.equal(portal.status, 200);
  assert.equal(portal.body.provider, "revenuecat");
  assert.equal(portal.body.url, "https://sandbox-customer-portal.paddle.com/cpl_1?token=x");
  assert.equal(s.calls[0].headers.Authorization, "Bearer sk_rc_v2_secret");
  assert.equal(s.calls[0].host, "api.revenuecat.com");
  // RevenueCat answers with no authenticated link: the subscription's own management URL.
  const s1 = scripted({
    "GET /v2/projects/proj1a2b3c4d/customers/uid0000000001/subscriptions": () => [200, { items: [{ id: "sub_rc_1", store: "paddle", gives_access: true, management_url: "https://customer-portal.paddle.com/cpl_2" }] }],
    "GET /v2/projects/proj1a2b3c4d/subscriptions/sub_rc_1/authenticated_management_url": () => [200, { management_url: null }],
  });
  assert.equal((await billing.handle({ db: rcDb, caller: ABROAD, request: req("manage"), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s1.fetchImpl, nowMs: NOW })).body.url, "https://customer-portal.paddle.com/cpl_2");
  // An unexpected host is never handed to the browser.
  const sEvil = scripted({
    "GET /v2/projects/proj1a2b3c4d/customers/uid0000000001/subscriptions": () => [200, { items: [{ id: "sub_rc_1", store: "paddle", gives_access: true, management_url: "https://evil.example/" }] }],
  });
  assert.equal((await billing.handle({ db: rcDb, caller: ABROAD, request: req("manage"), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: sEvil.fetchImpl, nowMs: NOW })).status, 502);
  // No RevenueCat key yet: 503; a store subscriber has nothing to manage here.
  assert.equal((await billing.handle({ db: rcDb, caller: ABROAD, request: req("manage"), keys: NO_KEYS, catalog: CATALOG, switches: OPEN, nowMs: NOW })).status, 503);
  const iosDb = fakeDb({ [`entitlements/${UID}`]: { premium: true, premiumUntil: ts, source: "revenuecat", store: "APP_STORE" } });
  assert.equal((await billing.handle({ db: iosDb, caller: ABROAD, request: req("manage"), keys: KEYS, catalog: CATALOG, switches: OPEN, nowMs: NOW })).status, 404);
  // status reads the RevenueCat subscription off the entitlement.
  const st = await billing.handle({ db: rcDb, caller: ABROAD, request: req("status"), keys: KEYS, catalog: CATALOG, switches: OPEN, nowMs: NOW });
  assert.equal(st.body.subscription.provider, "revenuecat");
  assert.equal(st.body.subscription.live, true);

  const ppDb = fakeDb({ [`web_customers/${UID}`]: { provider: "payplus", subscriptionId: "rec-1", subscriptionStatus: "active", currentPeriodEnd: ts, planId: "easy_plate_ai_pro_monthly", lastEventAt: NOW - DAY } });
  const ask = await billing.handle({ db: ppDb, caller: ISRAELI, request: req("manage"), keys: KEYS, catalog: CATALOG, switches: OPEN, nowMs: NOW });
  assert.equal(ask.body.confirmRequired, true);
  const s2 = scripted({ "POST /RecurringPayments/DeleteRecurring/rec-1": () => [200, { result: { status: "success" } }] });
  const done = await billing.handle({ db: ppDb, caller: ISRAELI, request: req("manage", { confirm: true }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: s2.fetchImpl, nowMs: NOW });
  assert.equal(done.body.cancelled, true);
  assert.equal(s2.calls[0].body.terminal_uid, "term-1");
  const ent = ppDb.store.get(`entitlements/${UID}`);
  assert.equal(ent.premium, true);
  assert.equal(ent.cancelAtPeriodEnd, true);
  assert.equal(ms(ent.premiumUntil), future, "no grace once cancelled");
  // Asked again: already done, no second call.
  const twice = await billing.handle({ db: ppDb, caller: ISRAELI, request: req("manage", { confirm: true }), keys: KEYS, catalog: CATALOG, switches: OPEN, fetchImpl: async () => { throw new Error("no call"); }, nowMs: NOW });
  assert.equal(twice.body.alreadyCancelled, true);
  // Nothing to manage.
  const none = await billing.handle({ db: fakeDb(), caller: ISRAELI, request: req("manage"), keys: KEYS, catalog: CATALOG, switches: OPEN, nowMs: NOW });
  assert.equal(none.status, 404);
});

test("the redirect allow-lists: PayPlus pages, RevenueCat purchase links, Paddle / RevenueCat portals only", () => {
  assert.equal(billing.isPayPlusPage("https://payments.payplus.co.il/abc"), true);
  assert.equal(billing.isPayPlusPage("https://payments.payplus.co.il.evil.com/abc"), false);
  assert.equal(billing.isPayPlusPage("javascript:alert(1)"), false);
  assert.equal(billing.isPurchaseLink("https://pay.rev.cat/abc/uid1"), true);
  assert.equal(billing.isPurchaseLink("https://pay.rev.cat.evil.io/abc"), false);
  assert.equal(billing.isManagePage("https://customer-portal.paddle.com/cpl_1"), true);
  assert.equal(billing.isManagePage("https://sandbox-customer-portal.paddle.com/cpl_1"), true);
  assert.equal(billing.isManagePage("https://paddle.com.evil.io/"), false);
  assert.equal(billing.isManagePage("https://app.revenuecat.com/portal"), true);
  assert.equal(billing.isManagePage("http://customer-portal.paddle.com/"), false);
});

test("account deletion stops a live web subscription first", async () => {
  const { deleteWebCustomer, webCleanupFor } = require("./deleteAccount").internals;
  assert.deepEqual(webCleanupFor({ provider: "paddle", subscriptionId: "sub_1", subscriptionStatus: "canceled" }), { provider: "paddle", stop: false });
  assert.deepEqual(webCleanupFor({ provider: "payplus", subscriptionId: "rec-1", subscriptionStatus: "active", cancelAtPeriodEnd: true }), { provider: "payplus", stop: false });
  const db = fakeDb({ [`web_customers/${UID}`]: { provider: "paddle", subscriptionId: "sub_1", subscriptionStatus: "active" } });
  const s = scripted({ "POST /subscriptions/sub_1/cancel": () => [200, { data: {} }] });
  const out = await deleteWebCustomer(db, UID, KEYS, { fetchImpl: s.fetchImpl });
  assert.equal(out.stopped, true);
  assert.equal(db.store.has(`web_customers/${UID}`), false);
  // Keys not set: skipped (logged), the record still goes.
  const db2 = fakeDb({ [`web_customers/${UID}`]: { provider: "payplus", subscriptionId: "rec-1", subscriptionStatus: "active" } });
  assert.equal((await deleteWebCustomer(db2, UID, NO_KEYS)).skipped, true);
  // A provider failure stops the deletion before anything of ours is gone.
  const db3 = fakeDb({ [`web_customers/${UID}`]: { provider: "payplus", subscriptionId: "rec-1", subscriptionStatus: "active" } });
  const s3 = scripted({ "POST /RecurringPayments/DeleteRecurring/rec-1": () => [500, {}] });
  await assert.rejects(deleteWebCustomer(db3, UID, KEYS, { fetchImpl: s3.fetchImpl }));
  assert.equal(db3.store.has(`web_customers/${UID}`), true);
});

test("account deletion stops a Paddle subscription bought through RevenueCat (found via RevenueCat, cancelled at Paddle)", async () => {
  const { deleteWebCustomer } = require("./deleteAccount").internals;
  const db = fakeDb({ [`entitlements/${UID}`]: { premium: true, source: "revenuecat", store: "PADDLE" } });
  const s = scripted({
    "GET /v2/projects/proj1a2b3c4d/customers/uid0000000001/subscriptions": () => [200, { items: [
      { id: "rc1", store: "paddle", status: "active", auto_renewal_status: "will_renew", store_subscription_identifier: "sub_01live" },
      { id: "rc2", store: "paddle", status: "active", auto_renewal_status: "will_not_renew", store_subscription_identifier: "sub_01ending" },
      { id: "rc3", store: "paddle", status: "expired", auto_renewal_status: "will_renew", store_subscription_identifier: "sub_01old" },
      { id: "rc4", store: "app_store", status: "active", auto_renewal_status: "will_renew", store_subscription_identifier: "2000000123" },
    ] }],
    "POST /subscriptions/sub_01live/cancel": () => [200, { data: { status: "canceled" } }],
  });
  const out = await deleteWebCustomer(db, UID, KEYS, { fetchImpl: s.fetchImpl, catalog: CATALOG });
  assert.equal(out.stopped, true);
  assert.equal(out.provider, "revenuecat");
  const cancels = s.calls.filter((c) => c.method === "POST");
  assert.deepEqual(cancels.map((c) => c.path), ["/subscriptions/sub_01live/cancel"]);
  assert.equal(cancels[0].host, "sandbox-api.paddle.com");
  assert.deepEqual(cancels[0].body, { effective_from: "immediately" });
  // Found through the audit rows when the entitlement moved on to a store plan.
  const db2 = fakeDb({ [`entitlements/${UID}`]: { premium: true, source: "revenuecat", store: "APP_STORE" }, "purchase_events/e1": { uid: UID, store: "PADDLE" } });
  const s2 = scripted({ "GET /v2/projects/proj1a2b3c4d/customers/uid0000000001/subscriptions": () => [200, { items: [] }] });
  assert.equal((await deleteWebCustomer(db2, UID, KEYS, { fetchImpl: s2.fetchImpl, catalog: CATALOG })).stopped, false);
  assert.equal(s2.calls.length, 1);
  // Never bought on the web: RevenueCat is not even asked.
  const db3 = fakeDb({ [`entitlements/${UID}`]: { premium: true, source: "revenuecat", store: "APP_STORE" } });
  assert.deepEqual(await deleteWebCustomer(db3, UID, KEYS, { fetchImpl: async () => { throw new Error("no call"); }, catalog: CATALOG }), { stopped: false, skipped: false, provider: null });
  // Keys not set: skipped with a warning; RevenueCat failing stops the deletion.
  assert.equal((await deleteWebCustomer(fakeDb({ [`entitlements/${UID}`]: { store: "PADDLE" } }), UID, NO_KEYS, { catalog: CATALOG })).skipped, true);
  const s4 = scripted({ "GET /v2/projects/proj1a2b3c4d/customers/uid0000000001/subscriptions": () => [500, {}] });
  await assert.rejects(deleteWebCustomer(fakeDb({ [`entitlements/${UID}`]: { store: "PADDLE" } }), UID, KEYS, { fetchImpl: s4.fetchImpl, catalog: CATALOG }));
});
