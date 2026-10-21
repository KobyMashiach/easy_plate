// Stripe → Firestore. Stripe posts one event per change to a web
// subscription and this writes the verdict onto `entitlements/{uid}` — the
// document the app follows (EntitlementService) and the RevenueCat webhook
// writes for store purchases. Same document, same rules (out-of-order events
// lose, an administrator's lock wins), so the app sees a web purchase exactly
// as it sees a store one: `premium: true` on its live listener, within a
// second of Stripe confirming the payment.
//
// Setup, once: Stripe dashboard → Developers → Webhooks → add this function's
// URL with the events
//   checkout.session.completed, customer.subscription.created,
//   customer.subscription.updated, customer.subscription.deleted,
//   invoice.paid, invoice.payment_failed
// and store the endpoint's signing secret:
//   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("./stripeClient");
const revenueCat = require("./revenueCatWebhook").internals;

const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

const EVENTS_COLLECTION = "purchase_events";
const CUSTOMERS = "stripe_customers";

// Subscription statuses that keep Premium on. `past_due` is Stripe's grace
// period (a failed renewal being retried) — the same courtesy RevenueCat's
// BILLING_ISSUE gets. `incomplete` is a first payment still in flight:
// nothing to say yet. Everything else is off.
const ON = new Set(["active", "trialing", "past_due"]);
const PENDING = new Set(["incomplete"]);

function metaUid(obj) {
  const uid = obj && obj.metadata && obj.metadata.uid;
  return typeof uid === "string" && uid.length >= 10 ? uid : null;
}

// The uid an event is about, read from wherever Stripe echoes our metadata.
// Null means "look the customer up" (see uidByCustomer).
function uidIn(event) {
  const obj = (event && event.data && event.data.object) || {};
  const type = String(event.type || "");
  if (type.startsWith("checkout.session.")) {
    return (typeof obj.client_reference_id === "string" && obj.client_reference_id) || metaUid(obj);
  }
  if (type.startsWith("customer.subscription.")) return metaUid(obj);
  if (type.startsWith("invoice.")) {
    const details = (obj.parent && obj.parent.subscription_details) || obj.subscription_details || null;
    return metaUid(details) || metaUid(obj);
  }
  return metaUid(obj);
}

function customerIdIn(event) {
  const obj = (event && event.data && event.data.object) || {};
  const c = obj.customer;
  if (typeof c === "string") return c;
  if (c && typeof c.id === "string") return c.id;
  return null;
}

// Stripe moved the period from the subscription to its items in the 2025
// API versions; read both so a dashboard set to either version works.
function periodEndMs(sub) {
  if (!sub) return null;
  const candidates = [];
  if (typeof sub.current_period_end === "number") candidates.push(sub.current_period_end);
  for (const item of (sub.items && sub.items.data) || []) {
    if (item && typeof item.current_period_end === "number") candidates.push(item.current_period_end);
  }
  if (candidates.length === 0) return null;
  return Math.max(...candidates) * 1000;
}

function priceOf(sub) {
  const item = sub && sub.items && sub.items.data && sub.items.data[0];
  return (item && item.price) || null;
}

function productIdOf(sub) {
  const price = priceOf(sub);
  if (!price) return "";
  return String(price.lookup_key || price.id || "");
}

// Turns one event into the writes it implies. Pure, so the mapping has a
// unit test without Firestore or Stripe. `uid` is resolved by the caller
// (from the event, else from stripe_customers); null means nothing is written
// beyond the audit row.
function decide(event, uid, now = Date.now()) {
  if (!event || typeof event !== "object") return { entitlement: null, customer: null };
  const type = String(event.type || "");
  const obj = (event.data && event.data.object) || {};
  const at = (Number(event.created) || Math.floor(now / 1000)) * 1000;
  const base = {
    source: "stripe",
    store: "stripe",
    lastEventType: type,
    lastEventId: String(event.id || ""),
    lastEventAt: at,
    environment: event.livemode ? "PRODUCTION" : "SANDBOX",
  };
  if (!uid) return { entitlement: null, customer: null };

  if (type === "checkout.session.completed") {
    if (obj.mode !== "subscription") return { entitlement: null, customer: null };
    return {
      entitlement: null,
      customer: {
        uid,
        data: {
          stripeCustomerId: typeof obj.customer === "string" ? obj.customer : null,
          subscriptionId: typeof obj.subscription === "string" ? obj.subscription : null,
          everSubscribed: true,
          lastCheckoutAt: new Date(at),
        },
      },
    };
  }

  if (type.startsWith("customer.subscription.")) {
    const status = String(obj.status || "");
    const deleted = type === "customer.subscription.deleted";
    const customer = {
      uid,
      data: {
        stripeCustomerId: typeof obj.customer === "string" ? obj.customer : null,
        subscriptionId: String(obj.id || ""),
        subscriptionStatus: deleted ? "canceled" : status,
        cancelAtPeriodEnd: obj.cancel_at_period_end === true,
        priceLookupKey: productIdOf(obj),
        everSubscribed: true,
        // So an older status delivered late cannot overwrite a newer one
        // (webBilling refuses a checkout on `subscriptionStatus`).
        lastEventAt: at,
      },
    };
    if (!deleted && PENDING.has(status)) return { entitlement: null, customer };
    const on = !deleted && ON.has(status);
    const until = periodEndMs(obj);
    return {
      customer,
      entitlement: {
        uid,
        data: {
          ...base,
          premium: on,
          premiumUntil: on && until ? new Date(until) : null,
          productId: productIdOf(obj),
          stripeCustomerId: customer.data.stripeCustomerId,
          stripeSubscriptionId: customer.data.subscriptionId,
          cancelAtPeriodEnd: customer.data.cancelAtPeriodEnd,
        },
      },
    };
  }

  // invoice.paid / invoice.payment_failed: the audit row is enough; the
  // subscription event that follows carries the verdict.
  return { entitlement: null, customer: null };
}

// The audit row, like the RevenueCat one, so the administrator's
// subscriptions screen lists web and store purchases side by side.
function eventRecord(event, uid, now = Date.now()) {
  if (!event || typeof event !== "object" || !event.id) return null;
  const type = String(event.type || "");
  const obj = (event.data && event.data.object) || {};
  const at = (Number(event.created) || Math.floor(now / 1000)) * 1000;
  const sub = type.startsWith("customer.subscription.") ? obj : null;
  const amount = type.startsWith("invoice.") ? Number(obj.amount_paid ?? obj.amount_due) : null;
  const until = sub ? periodEndMs(sub) : null;
  return {
    id: String(event.id),
    data: {
      type,
      appUserId: uid || "",
      aliases: [],
      uid: uid || null,
      productId: sub ? productIdOf(sub) : String((obj.lines && obj.lines.data && obj.lines.data[0] && obj.lines.data[0].pricing && obj.lines.data[0].pricing.price_details && obj.lines.data[0].pricing.price_details.price) || ""),
      store: "stripe",
      entitlementIds: sub && ON.has(String(sub.status)) ? [revenueCat.PREMIUM_ENTITLEMENT] : [],
      grantsPremium: !!(sub && ON.has(String(sub.status))),
      environment: event.livemode ? "PRODUCTION" : "SANDBOX",
      periodType: sub && sub.status === "trialing" ? "TRIAL" : "NORMAL",
      eventAt: new Date(at),
      expiresAt: until ? new Date(until) : null,
      price: Number.isFinite(amount) ? amount / 100 : null,
      currency: String(obj.currency || (sub && priceOf(sub) && priceOf(sub).currency) || "").toUpperCase(),
      stripeCustomerId: customerIdIn(event),
      stripeStatus: sub ? String(sub.status || "") : String(obj.status || ""),
    },
  };
}

async function uidByCustomer(db, customerId) {
  if (!customerId) return null;
  const snap = await db.collection(CUSTOMERS).where("stripeCustomerId", "==", customerId).limit(1).get();
  return snap.empty ? null : snap.docs[0].id;
}

// Whether the account an event names still exists. Deleting an account
// cancels its subscription and deletes its Stripe customer (deleteAccount.js),
// and Stripe then posts the resulting events: without this check they would
// write entitlements/{uid} and stripe_customers/{uid} back for a uid that
// is gone. The audit row is still kept.
async function authUserExists(uid) {
  try {
    await admin.auth().getUser(uid);
    return true;
  } catch (err) {
    return err.code !== "auth/user-not-found";
  }
}

// Writes a checkout record (no status, no lastEventAt). It never replaces a
// subscription id a subscription event already wrote: the subscription
// events own that field (see applySubscription).
async function applyCustomer(db, customer) {
  const ref = db.collection(CUSTOMERS).doc(customer.uid);
  const data = { ...customer.data, updatedAt: admin.firestore.FieldValue.serverTimestamp() };
  if (data.lastCheckoutAt) data.lastCheckoutAt = admin.firestore.Timestamp.fromDate(data.lastCheckoutAt);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const seenAt = snap.exists ? Number(snap.get("lastEventAt")) || 0 : 0;
    if (typeof data.lastEventAt === "number" && seenAt > data.lastEventAt) return;
    if (snap.exists && snap.get("subscriptionId")) delete data.subscriptionId;
    tx.set(ref, data, { merge: true });
  });
}

// Pure: how far along a subscription's life a status is, for breaking a
// same-second tie: ended > live > not yet paid.
function statusRank(status) {
  if (status === "canceled" || status === "incomplete_expired") return 2;
  if (ON.has(status)) return 1;
  return 0;
}

// How many subscriptions stripe_customers/{uid}.subscriptions remembers.
const MAX_TRACKED_SUBS = 10;

// One account can end up with two web subscriptions (two checkouts paid
// before the first webhook landed). Each subscription's events are ordered
// on their own (`subscriptions.{id}.at`), and the entitlement is always
// derived from the best live one: cancelling or losing an old subscription
// never removes Premium a live one grants, and the live one with the latest
// period end decides premiumUntil. Pure: (stored customer doc, decide()'s
// output) → what to write, or null when the event is stale for its own
// subscription.
function mergeSubscription(stored, customer, entitlement) {
  stored = stored || {};
  const id = customer.data.subscriptionId;
  const at = customer.data.lastEventAt;
  const subs = {};
  const raw = stored.subscriptions && typeof stored.subscriptions === "object" ? stored.subscriptions : {};
  for (const [k, v] of Object.entries(raw)) if (v && typeof v === "object") subs[k] = v;
  // A record written before the map existed: its one subscription joins.
  if (typeof stored.subscriptionId === "string" && stored.subscriptionId && !subs[stored.subscriptionId] && stored.subscriptionStatus) {
    subs[stored.subscriptionId] = { status: String(stored.subscriptionStatus), at: Number(stored.lastEventAt) || 0, until: null, cancel: stored.cancelAtPeriodEnd === true, product: String(stored.priceLookupKey || "") };
  }
  const prev = subs[id];
  if (prev && Number(prev.at) > at) return null;
  // Stripe stamps whole seconds, so two events of one subscription can carry
  // the same `created` (created → incomplete and updated → active in one
  // second) and arrive in either order: the tie goes to the later state.
  if (prev && Number(prev.at) === at && statusRank(prev.status) > statusRank(customer.data.subscriptionStatus)) return null;
  const ent = entitlement ? entitlement.data : null;
  subs[id] = {
    status: customer.data.subscriptionStatus,
    at,
    until: ent && ent.premiumUntil ? ent.premiumUntil.getTime() : null,
    cancel: customer.data.cancelAtPeriodEnd === true,
    product: customer.data.priceLookupKey || "",
  };
  // Keep the map small: live ones first, then the most recent.
  const ids = Object.keys(subs).sort((a, b) => (ON.has(subs[b].status) - ON.has(subs[a].status)) || (Number(subs[b].at) - Number(subs[a].at)));
  const dropped = ids.slice(MAX_TRACKED_SUBS);
  for (const drop of dropped) delete subs[drop];

  // The live subscription that decides: not cancelling first, then the
  // latest period end.
  const live = Object.entries(subs)
    .filter(([, v]) => ON.has(v.status))
    .sort(([, a], [, b]) => ((a.cancel === true) - (b.cancel === true)) || ((Number(b.until) || 0) - (Number(a.until) || 0)));
  const seenAt = Number(stored.lastEventAt) || 0;
  const lastEventAt = Math.max(at, seenAt);
  if (live.length === 0 || live[0][0] === id) {
    // This event's subscription decides (or none is live): its own verdict.
    return {
      customer: { ...customer.data, subscriptions: subs, lastEventAt },
      entitlement: ent ? { uid: entitlement.uid, data: { ...ent, lastEventAt } } : null,
      superseded: false,
      dropped,
    };
  }
  // Another subscription is live and decides: the top-level fields and the
  // entitlement follow it, whatever this event said about its own.
  const [liveId, best] = live[0];
  return {
    customer: {
      stripeCustomerId: customer.data.stripeCustomerId || stored.stripeCustomerId || null,
      subscriptionId: liveId,
      subscriptionStatus: best.status,
      cancelAtPeriodEnd: best.cancel === true,
      priceLookupKey: best.product || "",
      everSubscribed: true,
      subscriptions: subs,
      lastEventAt,
    },
    entitlement: ent
      ? {
          uid: entitlement.uid,
          data: {
            ...ent,
            premium: true,
            premiumUntil: best.until ? new Date(Number(best.until)) : null,
            productId: best.product || ent.productId,
            stripeSubscriptionId: liveId,
            cancelAtPeriodEnd: best.cancel === true,
            lastEventAt,
          },
        }
      : null,
    superseded: true,
    dropped,
  };
}

// A subscription event: the per-subscription merge above and the
// entitlement it implies, in one transaction. The entitlement used to be
// written in a second transaction after this one, so two deliveries could
// merge in one order and write their entitlements in the other — the older
// verdict last. Same rules as RevenueCat's apply (admin lock, another
// source's grant, stale lastEventAt), now serialized with the merge.
async function applySubscription(db, customer, entitlement) {
  const ref = db.collection(CUSTOMERS).doc(customer.uid);
  const entRef = db.collection("entitlements").doc(customer.uid);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const entSnap = await tx.get(entRef);
    const merged = mergeSubscription(snap.exists ? snap.data() : null, customer, entitlement);
    if (!merged) return { entitlement: null, stale: true };
    // A merge-set merges nested maps key by key: pruned ids need an explicit delete.
    const subscriptions = { ...merged.customer.subscriptions };
    for (const drop of merged.dropped) subscriptions[drop] = admin.firestore.FieldValue.delete();
    tx.set(ref, { ...merged.customer, subscriptions, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    const wrote = merged.entitlement ? revenueCat.applyInTransaction(tx, entRef, entSnap, merged.entitlement.data) : false;
    return { entitlement: merged.entitlement, wrote, superseded: merged.superseded };
  });
}

async function process(db, event, { userExists = authUserExists } = {}) {
  const uid = uidIn(event) || (await uidByCustomer(db, customerIdIn(event)));
  const record = eventRecord(event, uid);
  if (record) {
    await db.collection(EVENTS_COLLECTION).doc(record.id).set(
      {
        ...record.data,
        eventAt: admin.firestore.Timestamp.fromDate(record.data.eventAt),
        expiresAt: record.data.expiresAt ? admin.firestore.Timestamp.fromDate(record.data.expiresAt) : null,
        receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  const { entitlement, customer } = decide(event, uid);
  if ((entitlement || customer) && !(await userExists(uid))) {
    logger.info("stripe event for a deleted account, audit row only", { type: event.type, id: event.id, uid });
    return { uid, wrote: false, orphan: true };
  }
  if (customer && String(event.type || "").startsWith("customer.subscription.")) {
    const out = await applySubscription(db, customer, entitlement);
    if (out.superseded) logger.info("stripe event for a non-deciding subscription; the live one keeps premium", { type: event.type, id: event.id, uid });
    return { uid, wrote: !!out.entitlement, superseded: !!out.superseded, stale: !!out.stale };
  }
  if (customer) await applyCustomer(db, customer);
  if (entitlement) await revenueCat.apply(db, entitlement);
  return { uid, wrote: !!entitlement };
}

exports.stripeWebhook = onRequest(
  { region: "europe-west1", secrets: [webhookSecret], minInstances: 0, maxInstances: 5, timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).send("POST only");
    const refused = stripe.verifySignature(req.get("stripe-signature"), req.rawBody, webhookSecret.value());
    if (refused) {
      logger.warn("stripe webhook refused", { reason: refused });
      return res.status(400).send(`bad signature: ${refused}`);
    }
    let event;
    try {
      event = JSON.parse(req.rawBody.toString("utf8"));
    } catch (_) {
      return res.status(400).send("not json");
    }
    try {
      const result = await process(admin.firestore(), event);
      logger.info("stripe event handled", { type: event.type, id: event.id, uid: result.uid, wrote: result.wrote });
      return res.status(200).json({ ok: true });
    } catch (err) {
      console.error("stripeWebhook failed", err);
      // A non-2xx makes Stripe retry with backoff for up to three days.
      return res.status(500).send("failed");
    }
  },
);

exports.internals = { uidIn, customerIdIn, periodEndMs, productIdOf, decide, eventRecord, process, applyCustomer, applySubscription, mergeSubscription, statusRank, ON, PENDING, CUSTOMERS, EVENTS_COLLECTION };
