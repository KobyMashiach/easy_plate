const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { parseRequest, planFromPrice, tierOf, eligibility, checkoutParams, listPlans, _resetCache } = require("./stripeBilling").internals;

const NOW = 1_800_000_000_000;
const ts = (ms) => ({ toMillis: () => ms });

const price = (over = {}) => ({
  id: "price_1AbCdEfGhIjK",
  active: true,
  recurring: { interval: "month", interval_count: 1 },
  lookup_key: "easy_plate_ai_pro_monthly",
  unit_amount: 2000,
  currency: "ils",
  product: { name: "EasyPlate Premium", description: "No ads, no limits" },
  metadata: {},
  ...over,
});

test("requests are typed: only the three actions, a real price id for checkout", () => {
  assert.equal(parseRequest({}).error, "Unknown action");
  assert.equal(parseRequest({ action: "checkout" }).error, "priceId required");
  assert.equal(parseRequest({ action: "checkout", priceId: "cus_123456789" }).error, "priceId required");
  assert.deepEqual(parseRequest({ action: "checkout", priceId: "price_1AbCdEfGhIjK", lang: "he" }), { action: "checkout", lang: "he", priceId: "price_1AbCdEfGhIjK" });
  assert.deepEqual(parseRequest({ action: "plans", lang: "nonsense" }), { action: "plans", lang: "en" });
  assert.deepEqual(parseRequest({ action: "portal" }), { action: "portal", lang: "en" });
});

test("only our active recurring prices become plans; the tier comes from the lookup key", () => {
  const plan = planFromPrice(price());
  assert.equal(plan.tier, "pro");
  assert.equal(plan.seats, 1);
  assert.equal(plan.amount, 2000);
  assert.equal(plan.currency, "ils");
  assert.equal(plan.name, "EasyPlate Premium");
  assert.equal(plan.introCoupon, null);
  assert.equal(planFromPrice(price({ lookup_key: "easy_plate_ai_pro_family_yearly", recurring: { interval: "year" } })).tier, "family");
  assert.equal(planFromPrice(price({ lookup_key: "easy_plate_ai_pro_duo_monthly" })).seats, 2);
  assert.equal(planFromPrice(price({ active: false })), null);
  assert.equal(planFromPrice(price({ recurring: null })), null);
  assert.equal(planFromPrice(price({ lookup_key: "someone_elses_price" })), null);
  assert.equal(planFromPrice(price({ lookup_key: null })), null);
  assert.equal(planFromPrice(price({ unit_amount: null })), null);
  assert.equal(tierOf("EASY_PLATE_AI_PRO_DUO"), "duo");
  assert.equal(tierOf(""), "pro");
});

test("an intro offer needs both the coupon and the display amount", () => {
  assert.equal(planFromPrice(price({ metadata: { intro_coupon: "FIRST10", intro_amount: "1000" } })).introAmount, 1000);
  assert.equal(planFromPrice(price({ metadata: { intro_amount: "1000" } })).introAmount, null);
  assert.equal(planFromPrice(price({ metadata: { intro_coupon: "FIRST10" } })).introCoupon, "FIRST10");
  assert.equal(planFromPrice(price({ metadata: { intro_coupon: "FIRST10" } })).introAmount, null);
});

test("who may start a web subscription", () => {
  const future = ts(NOW + 86_400_000);
  assert.equal(eligibility(null, null, NOW), null);
  assert.equal(eligibility({ premium: false, source: "revenuecat" }, null, NOW), null);
  assert.equal(eligibility({ premium: true, premiumUntil: future, source: "revenuecat" }, null, NOW), "store_subscription");
  // A lapsed store subscription is no obstacle.
  assert.equal(eligibility({ premium: true, premiumUntil: ts(NOW - 1), source: "revenuecat" }, null, NOW), null);
  assert.equal(eligibility({ premium: true, source: "household" }, null, NOW), "household_member");
  assert.equal(eligibility({ premium: true, source: "admin", adminLock: true }, null, NOW), "gifted");
  assert.equal(eligibility({ premium: true, source: "admin", adminLock: false }, null, NOW), null);
  assert.equal(eligibility({ premium: true, source: "stripe", premiumUntil: future }, { subscriptionStatus: "active" }, NOW), "already_subscribed");
  assert.equal(eligibility({ premium: true, source: "stripe", premiumUntil: future }, { subscriptionStatus: "past_due" }, NOW), "already_subscribed");
  // The web subscription ended: they may buy again.
  assert.equal(eligibility({ premium: false, source: "stripe" }, { subscriptionStatus: "canceled" }, NOW), null);
});

test("the checkout session carries the uid everywhere and the intro coupon only the first time", () => {
  const plan = planFromPrice(price({ metadata: { intro_coupon: "FIRST10", intro_amount: "1000" } }));
  const first = checkoutParams({ uid: "uid_1", customerId: "cus_1", plan, firstTime: true, lang: "he" });
  assert.equal(first.mode, "subscription");
  assert.equal(first.customer, "cus_1");
  assert.equal(first.client_reference_id, "uid_1");
  assert.equal(first.metadata.uid, "uid_1");
  assert.equal(first.subscription_data.metadata.uid, "uid_1");
  assert.equal(first.subscription_data.metadata.lookup_key, "easy_plate_ai_pro_monthly");
  assert.deepEqual(first.line_items, [{ price: plan.priceId, quantity: 1 }]);
  assert.deepEqual(first.discounts, [{ coupon: "FIRST10" }]);
  assert.equal(first.allow_promotion_codes, undefined);
  assert.match(first.success_url, /\/app\/checkout\/success\?session_id=\{CHECKOUT_SESSION_ID\}$/);
  assert.match(first.cancel_url, /\/app\/pricing/);

  const again = checkoutParams({ uid: "uid_1", customerId: "cus_1", plan, firstTime: false, lang: "he" });
  assert.equal(again.discounts, undefined);
  assert.equal(again.allow_promotion_codes, true);

  const noIntro = checkoutParams({ uid: "uid_1", customerId: "cus_1", plan: planFromPrice(price()), firstTime: true, lang: "en" });
  assert.equal(noIntro.allow_promotion_codes, true);
});

test("plans are read from Stripe once and cached, sorted by order then price", async () => {
  _resetCache();
  let calls = 0;
  const fetchImpl = async () => {
    calls += 1;
    return {
      ok: true,
      text: async () =>
        JSON.stringify({
          data: [
            price({ id: "price_family000000", lookup_key: "easy_plate_ai_pro_family_monthly", unit_amount: 4000, metadata: { order: "3" } }),
            price({ id: "price_pro0000000000", metadata: { order: "1" } }),
            price({ id: "price_other00000000", lookup_key: "unrelated" }),
            price({ id: "price_duo0000000000", lookup_key: "easy_plate_ai_pro_duo_monthly", unit_amount: 3000, metadata: { order: "2" } }),
          ],
        }),
    };
  };
  const plans = await listPlans("sk_test", NOW, fetchImpl);
  assert.deepEqual(plans.map((p) => p.tier), ["pro", "duo", "family"]);
  await listPlans("sk_test", NOW + 1000, fetchImpl);
  assert.equal(calls, 1);
  await listPlans("sk_test", NOW + 6 * 60 * 1000, fetchImpl);
  assert.equal(calls, 2);
  _resetCache();
});

test("a checkout started moments ago holds the account; an old marker does not", () => {
  const { checkoutBlock, CHECKOUT_PENDING_MS } = require("./stripeBilling").internals;
  const now = Date.parse("2026-10-18T10:00:00Z");
  const at = (ms) => ({ toMillis: () => ms });
  assert.equal(checkoutBlock(null, null, now), null);
  assert.equal(checkoutBlock(null, { checkoutPendingUntil: at(now + CHECKOUT_PENDING_MS) }, now), "checkout_pending");
  assert.equal(checkoutBlock(null, { checkoutPendingUntil: at(now) }, now), null);
  // A live subscription is still the stronger answer (it carries the portal).
  assert.equal(checkoutBlock(null, { subscriptionStatus: "active", checkoutPendingUntil: at(now + 1000) }, now), "already_subscribed");
});

test("the session's idempotency key is per account, price and minute", () => {
  const { checkoutIdempotencyKey } = require("./stripeBilling").internals;
  const t = Date.parse("2026-10-18T10:00:05Z");
  assert.equal(checkoutIdempotencyKey("u1", "price_A", t), checkoutIdempotencyKey("u1", "price_A", t + 30000));
  assert.notEqual(checkoutIdempotencyKey("u1", "price_A", t), checkoutIdempotencyKey("u1", "price_A", t + 60000));
  assert.notEqual(checkoutIdempotencyKey("u1", "price_A", t), checkoutIdempotencyKey("u2", "price_A", t));
  assert.notEqual(checkoutIdempotencyKey("u1", "price_A", t), checkoutIdempotencyKey("u1", "price_B", t));
});

test("the session and the pending marker expire at the same instant, ≥ 30 min after creation, identical within the idempotency minute", () => {
  const { checkoutExpiresAtMs, CHECKOUT_PENDING_MS } = require("./stripeBilling").internals;
  const t = Date.parse("2026-10-18T10:00:59Z");
  assert.equal(checkoutExpiresAtMs(t), checkoutExpiresAtMs(Date.parse("2026-10-18T10:00:00Z")));
  // Created at worst at the end of the minute plus a slow call: still > 30 min.
  assert.ok(checkoutExpiresAtMs(t) - (t + 10_000) >= 30 * 60 * 1000);
  assert.ok(CHECKOUT_PENDING_MS >= 31 * 60 * 1000);
  const plan = planFromPrice(price());
  const p = checkoutParams({ uid: "uid_1", customerId: "cus_1", plan, firstTime: false, lang: "en", expiresAtMs: checkoutExpiresAtMs(t) });
  assert.equal(p.expires_at, checkoutExpiresAtMs(t) / 1000);
});

// handle() over an in-memory Firestore and a scripted Stripe.
function billingDb(seed = {}) {
  const store = new Map(Object.entries(seed));
  const snapOf = (path) => ({ exists: store.has(path), data: () => store.get(path), get: (f) => (store.get(path) || {})[f] });
  const write = (path, data, opts) => {
    const next = opts && opts.merge ? { ...(store.get(path) || {}) } : {};
    for (const [k, v] of Object.entries(data)) {
      if (v && typeof v === "object" && v.constructor && v.constructor.name === "DeleteTransform") delete next[k];
      else next[k] = v;
    }
    store.set(path, next);
  };
  const docRef = (path) => ({ path, get: async () => snapOf(path), set: async (d, o) => write(path, d, o) });
  return {
    store,
    collection: (name) => ({ doc: (id) => docRef(`${name}/${id}`) }),
    runTransaction: (fn) => fn({ get: (ref) => ref.get(), set: (ref, d, o) => write(ref.path, d, o) }),
  };
}

function scriptedStripe(routes) {
  const calls = [];
  const fetchImpl = async (url, init) => {
    const path = new URL(url).pathname.replace(/^\/v1/, "");
    calls.push({ method: init.method, path, body: init.body || "", key: init.headers["Idempotency-Key"] });
    const handler = routes[`${init.method} ${path}`];
    const [status, body] = handler ? handler() : [404, { error: { message: "no route" } }];
    return { ok: status < 300, status, text: async () => JSON.stringify(body) };
  };
  return { calls, fetchImpl };
}

test("a pending checkout with a known session is replaced (old session expired first); a paid one is not", async () => {
  const remoteFlags = require("./remoteFlags");
  const realParams = remoteFlags.params;
  remoteFlags.params = async () => ({ ff_web_checkout: { defaultValue: { value: "2" } } });
  const { handle, _resetCache: reset, checkoutExpiresAtMs } = require("./stripeBilling").internals;
  try {
    reset();
    const ts = (ms) => ({ toMillis: () => ms });
    const later = ts(Date.now() + 20 * 60 * 1000);
    const routes = (expire, oldStatus) => ({
      "GET /prices": () => [200, { data: [price()] }],
      "POST /checkout/sessions/cs_old/expire": () => expire,
      "GET /checkout/sessions/cs_old": () => [200, { id: "cs_old", status: oldStatus }],
      "POST /checkout/sessions": () => [200, { id: "cs_new", url: "https://checkout.stripe.com/new" }],
    });
    const caller = { uid: "uid_000000001" };
    const request = { action: "checkout", priceId: price().id, lang: "en" };

    // Back from Stripe: the open session is expired, a new one opens.
    const db = billingDb({ "stripe_customers/uid_000000001": { stripeCustomerId: "cus_1", checkoutPendingUntil: later, checkoutSessionId: "cs_old" } });
    const s1 = scriptedStripe(routes([200, { id: "cs_old", status: "expired" }], "expired"));
    const out = await handle({ db, secret: "sk_test", caller, request, fetchImpl: s1.fetchImpl });
    assert.equal(out.status, 200);
    assert.equal(out.body.sessionId, "cs_new");
    const order = s1.calls.map((c) => `${c.method} ${c.path}`);
    assert.ok(order.indexOf("POST /checkout/sessions/cs_old/expire") < order.indexOf("POST /checkout/sessions"));
    const create = s1.calls.find((c) => c.path === "/checkout/sessions");
    assert.match(create.key, /_after_cs_old$/);
    assert.match(decodeURIComponent(create.body), /expires_at=\d+/);
    const rec = db.store.get("stripe_customers/uid_000000001");
    assert.equal(rec.checkoutSessionId, "cs_new");
    assert.ok(Math.abs(rec.checkoutPendingUntil.toMillis() - checkoutExpiresAtMs(Date.now())) <= 60_000);

    // The old session was already paid: refused, no second session.
    const db2 = billingDb({ "stripe_customers/uid_000000001": { stripeCustomerId: "cus_1", checkoutPendingUntil: later, checkoutSessionId: "cs_old" } });
    const s2 = scriptedStripe(routes([400, { error: { message: "complete" } }], "complete"));
    const out2 = await handle({ db: db2, secret: "sk_test", caller, request, fetchImpl: s2.fetchImpl });
    assert.equal(out2.status, 409);
    assert.equal(out2.body.error.code, "checkout_pending");
    assert.equal(s2.calls.some((c) => c.method === "POST" && c.path === "/checkout/sessions"), false);

    // Pending with no known session (a twin tab mid-create): refused.
    const db3 = billingDb({ "stripe_customers/uid_000000001": { stripeCustomerId: "cus_1", checkoutPendingUntil: later } });
    const s3 = scriptedStripe(routes([200, {}], "expired"));
    const out3 = await handle({ db: db3, secret: "sk_test", caller, request, fetchImpl: s3.fetchImpl });
    assert.equal(out3.status, 409);
    assert.equal(s3.calls.some((c) => c.path.startsWith("/checkout/sessions")), false);
  } finally {
    remoteFlags.params = realParams;
    reset();
  }
});

test("a failed checkout drops its pending marker only when no session can exist", () => {
  const { pendingClearable } = require("./stripeBilling").internals;
  const { StripeError } = require("./stripeClient");
  assert.equal(pendingClearable(new Error("firestore"), false), true);
  assert.equal(pendingClearable(new StripeError(400, { error: { message: "bad" } }), true), true);
  assert.equal(pendingClearable(new StripeError(500, {}), true), false);
  assert.equal(pendingClearable(new TypeError("fetch failed"), true), false);
});

test("expiring the earlier session over a broken network answers false, not a throw", async () => {
  const { expireSession } = require("./stripeBilling").internals;
  const fetchImpl = async () => { throw new TypeError("fetch failed"); };
  assert.equal(await expireSession("sk_test_x", "cs_1", fetchImpl), false);
});
