// "Send me a link to upgrade": a one-time, personal link that opens the
// website already signed in as the account, straight on the pricing page, so
// nobody types a phone number and an SMS code again on their phone.
//
// How a link works: a random 256-bit token is handed out; only its SHA-256
// lives in `upgrade_links/{hash}` with the uid and a 30-minute expiry. The
// page at /app/upgrade/<token> posts it back (`redeem`); the function marks
// it used inside a transaction and answers with a Firebase custom token the
// page signs in with. The link is therefore worth exactly as much as an SMS
// code — whoever holds the phone holds the account — and no more: one use,
// half an hour, and it signs into the same account it was requested for.
//
// Three actions:
//   mint    (signed in)      → {url, expiresAt}. The app's "upgrade on the
//                              web" row calls this and opens the URL itself.
//   send    (signed in, or   → sends the link by SMS or email. Signed in, it
//            anonymous)        goes to the account's own phone/email; anonymous
//                              (the website's "send me a link" box), the
//                              account is looked up by the phone/email given,
//                              rate-limited, and the answer is the same whether
//                              or not an account exists.
//   redeem  (anonymous)      → {customToken, uid}
//
// Delivery: SMS through Twilio's REST API (secrets TWILIO_ACCOUNT_SID,
// TWILIO_AUTH_TOKEN, TWILIO_FROM — a "-" in any disables SMS); email through
// the Firebase "Trigger Email" extension, which sends what is written into
// the `mail` collection (install it with your SMTP account).
const crypto = require("node:crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const remoteFlags = require("./remoteFlags");
const billing = require("./webBilling").internals;

const twilioSid = defineSecret("TWILIO_ACCOUNT_SID");
const twilioToken = defineSecret("TWILIO_AUTH_TOKEN");
const twilioFrom = defineSecret("TWILIO_FROM");

const LINKS = "upgrade_links";
const REQUESTS = "upgrade_link_requests";
const MAIL = "mail";
const TTL_MS = 30 * 60 * 1000;

// Anonymous requests: per target and per caller address, per hour. Generous
// for a person, useless for a script trying to pump SMS.
const LIMIT_PER_TARGET = 3;
const LIMIT_PER_IP = 10;
// Every SMS the project sends in an hour, whoever asked. The two counters
// above are keyed on things a caller controls (the number it names, the
// x-forwarded-for it spoofs); this one is not, so a script rotating both
// still runs into a ceiling on the Twilio bill.
const LIMIT_GLOBAL_SMS = 200;
const GLOBAL_SMS_KEY = "global_sms";
// The same ceiling for email: the per-address counter alone let a script
// walk through every verified address it knew, three links each an hour,
// all through our sender.
const LIMIT_GLOBAL_EMAIL = 300;
const GLOBAL_EMAIL_KEY = "global_email";
const WINDOW_MS = 60 * 60 * 1000;

// ---------------------------------------------------------------------------
// Pure parts

function mintToken(randomBytes = crypto.randomBytes) {
  const token = randomBytes(32).toString("base64url");
  return { token, hash: hashToken(token) };
}

function hashToken(token) {
  return crypto.createHash("sha256").update(String(token)).digest("hex");
}

function linkFor(token) {
  return `${billing.WEB_ORIGIN}${billing.APP_PATH}/upgrade/${token}`;
}

function validToken(raw) {
  return typeof raw === "string" && /^[A-Za-z0-9_-]{43}$/.test(raw);
}

// +972 50-123 4567 / 050-1234567 / 0501234567 → +972501234567. Only Israeli
// local numbers are completed; anything else must already be international.
function normalizePhone(raw) {
  if (typeof raw !== "string") return null;
  let digits = raw.replace(/[^\d+]/g, "");
  if (digits.startsWith("00")) digits = `+${digits.slice(2)}`;
  if (/^0[2-9]\d{7,8}$/.test(digits)) digits = `+972${digits.slice(1)}`;
  return /^\+[1-9]\d{7,14}$/.test(digits) ? digits : null;
}

function normalizeEmail(raw) {
  if (typeof raw !== "string") return null;
  const email = raw.trim().toLowerCase();
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email) && email.length <= 254 ? email : null;
}

function parseRequest(body) {
  const action = typeof body.action === "string" ? body.action : "";
  if (!["mint", "send", "redeem"].includes(action)) return { error: "Unknown action" };
  const lang = typeof body.lang === "string" && /^[a-z]{2}$/.test(body.lang) ? body.lang : "he";
  const out = { action, lang };
  if (action === "redeem") {
    if (!validToken(body.token)) return { error: "token required" };
    out.token = body.token;
  }
  if (action === "send") {
    const channel = body.channel === "email" ? "email" : body.channel === "sms" ? "sms" : null;
    if (!channel) return { error: "channel must be sms or email" };
    out.channel = channel;
    if (body.to !== undefined && body.to !== null && body.to !== "") {
      const to = channel === "sms" ? normalizePhone(body.to) : normalizeEmail(body.to);
      if (!to) return { error: channel === "sms" ? "Not a phone number" : "Not an email address" };
      out.to = to;
    }
  }
  return out;
}

// Whether a one-time link may be redeemed now, or why not.
function redeemReason(doc, nowMs = Date.now()) {
  if (!doc) return "not_found";
  if (doc.used === true) return "used";
  const expires = doc.expiresAt && typeof doc.expiresAt.toMillis === "function" ? doc.expiresAt.toMillis() : Number(doc.expiresAt);
  if (!Number.isFinite(expires) || expires <= nowMs) return "expired";
  if (typeof doc.uid !== "string" || !doc.uid) return "not_found";
  return null;
}

// A fixed-window counter: {count, windowStart}. Returns the next state and
// whether this request is allowed.
function rateDecision(stored, nowMs, limit, windowMs = WINDOW_MS) {
  const start = stored && Number(stored.windowStart);
  const fresh = !Number.isFinite(start) || nowMs - start >= windowMs;
  const count = fresh ? 0 : Number(stored.count) || 0;
  if (count >= limit) return { allowed: false, next: { count, windowStart: fresh ? nowMs : start } };
  return { allowed: true, next: { count: count + 1, windowStart: fresh ? nowMs : start } };
}

// The counters one send advances: always the target address (an SMS costs
// money whoever asks for it, and a signed-in loop is still a loop), the
// caller's address too when nobody is signed in, and for an SMS the
// project-wide hourly ceiling as well.
function limitKeysFor({ channel, to, ip, anonymous }) {
  const keys = [{ key: `t_${hashToken(`${channel}:${to}`)}`, kind: "target", limit: LIMIT_PER_TARGET }];
  if (anonymous) keys.push({ key: `ip_${hashToken(ip || "none")}`, kind: "ip", limit: LIMIT_PER_IP });
  if (channel === "sms") keys.push({ key: GLOBAL_SMS_KEY, kind: "global", limit: LIMIT_GLOBAL_SMS });
  else keys.push({ key: GLOBAL_EMAIL_KEY, kind: "global", limit: LIMIT_GLOBAL_EMAIL });
  return keys;
}

const COPY = {
  he: {
    sms: (url) => `EasyPlate: הקישור האישי שלך לשדרוג לפרימיום (תקף ל-30 דקות): ${url}`,
    subject: "הקישור שלך לשדרוג EasyPlate Premium",
    text: (url) => `שלום,\n\nזה הקישור האישי שלך לשדרוג לפרימיום באתר EasyPlate. הוא נכנס לחשבון שלך אוטומטית ותקף ל-30 דקות, לשימוש אחד:\n${url}\n\nלא ביקשת? אפשר להתעלם מההודעה — בלי הלחיצה לא קורה כלום.\n\nEasyPlate`,
  },
  en: {
    sms: (url) => `EasyPlate: your personal link to upgrade to Premium (valid 30 minutes): ${url}`,
    subject: "Your EasyPlate Premium upgrade link",
    text: (url) => `Hi,\n\nHere is your personal link to upgrade to Premium on the EasyPlate website. It signs into your account by itself, is valid for 30 minutes and works once:\n${url}\n\nDidn't ask for it? Ignore this message — nothing happens unless the link is opened.\n\nEasyPlate`,
  },
};

function copyFor(lang) {
  return COPY[lang] || COPY.en;
}

// ---------------------------------------------------------------------------
// Firestore / Auth / delivery

async function createLink(db, uid, { channel, requestedBy, nowMs = Date.now() }) {
  const { token, hash } = mintToken();
  await db.collection(LINKS).doc(hash).set({
    uid,
    channel: channel || "direct",
    requestedBy: requestedBy || uid,
    used: false,
    createdAt: admin.firestore.Timestamp.fromMillis(nowMs),
    expiresAt: admin.firestore.Timestamp.fromMillis(nowMs + TTL_MS),
  });
  return { url: linkFor(token), expiresAt: nowMs + TTL_MS };
}

// Whether the administrator switched the account off from the console
// (account_status/{uid}.disabled, written by adminUsers). The Auth flag is
// set alongside it, but the console's own record is the one the app obeys,
// so a link must not sign into an account that record holds on the blocked
// screen. A read failure refuses: a link is not worth an unchecked sign-in.
async function switchedOff(db, uid) {
  try {
    const snap = await db.doc(`account_status/${uid}`).get();
    return snap.exists && snap.data().disabled === true;
  } catch (err) {
    logger.warn("account status read failed", { uid, reason: err.message });
    return true;
  }
}

async function redeem(db, token, nowMs = Date.now()) {
  const ref = db.collection(LINKS).doc(hashToken(token));
  const outcome = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const doc = snap.exists ? snap.data() : null;
    const reason = redeemReason(doc, nowMs);
    if (reason) return { error: reason };
    tx.update(ref, { used: true, usedAt: admin.firestore.Timestamp.fromMillis(nowMs) });
    return { uid: doc.uid };
  });
  if (outcome.error) return outcome;
  let record;
  try {
    record = await admin.auth().getUser(outcome.uid);
  } catch (_) {
    return { error: "not_found" };
  }
  if (record.disabled || (await switchedOff(db, outcome.uid))) return { error: "disabled" };
  const customToken = await admin.auth().createCustomToken(outcome.uid, { upgradeLink: true });
  return { uid: outcome.uid, customToken };
}

async function withinLimits(db, keys, nowMs) {
  // One transaction over the counters: either all advance or the request is
  // refused, so a refused call never eats part of the allowance.
  return db.runTransaction(async (tx) => {
    const refs = keys.map(({ key }) => db.collection(REQUESTS).doc(key));
    const snaps = await Promise.all(refs.map((r) => tx.get(r)));
    const decisions = snaps.map((s, i) => rateDecision(s.exists ? s.data() : null, nowMs, keys[i].limit));
    if (decisions.some((d) => !d.allowed)) return false;
    decisions.forEach((d, i) => tx.set(refs[i], { ...d.next, kind: keys[i].kind }, { merge: true }));
    return true;
  });
}

function smsConfigured(sid, token, from) {
  const unset = (v) => !v || v === "-";
  return !(unset(sid) || unset(token) || unset(from));
}

async function sendSms({ to, body, sid, token, from, fetchImpl = fetch }) {
  const res = await fetchImpl(`https://api.twilio.com/2010-04-01/Accounts/${encodeURIComponent(sid)}/Messages.json`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${Buffer.from(`${sid}:${token}`).toString("base64")}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({ To: to, Body: body, ...(from.startsWith("MG") ? { MessagingServiceSid: from } : { From: from }) }).toString(),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Twilio ${res.status}: ${text.slice(0, 200)}`);
  }
}

async function sendEmail(db, { to, subject, text }) {
  await db.collection(MAIL).add({ to: [to], message: { subject, text }, createdAt: admin.firestore.FieldValue.serverTimestamp() });
}

// Pure: the account's contact a link may go to on [channel], or null. An
// email counts only once verified: the link signs into the account, and an
// address typed at sign-up but never confirmed may be somebody else's.
function deliverableContact(record, channel) {
  if (!record || record.disabled) return null;
  if (channel === "sms") return record.phoneNumber || null;
  return record.email && record.emailVerified === true ? record.email : null;
}

async function findUid(channel, to) {
  try {
    const record = channel === "sms" ? await admin.auth().getUserByPhoneNumber(to) : await admin.auth().getUserByEmail(to);
    return deliverableContact(record, channel) ? record.uid : null;
  } catch (_) {
    return null;
  }
}

async function flagOn() {
  const p = await remoteFlags.params();
  // Closed when Remote Config gave nothing, as in webBilling.flagValue.
  return remoteFlags.intFrom(p, billing.FLAG, 0) >= 2;
}

async function handle({ db, caller, request, ip, sms, nowMs = Date.now(), fetchImpl }) {
  if (request.action === "redeem") {
    const result = await redeem(db, request.token, nowMs);
    if (result.error) {
      const status = result.error === "disabled" ? 403 : result.error === "not_found" ? 404 : 410;
      return { status, body: { error: { code: result.error, message: result.error } } };
    }
    return { status: 200, body: { customToken: result.customToken, uid: result.uid, path: `${billing.APP_PATH}/pricing` } };
  }

  if (!(await flagOn())) return { status: 403, body: { error: { code: "disabled", message: "Web checkout is switched off" } } };

  if (request.action === "mint") {
    if (!caller) return { status: 401, body: { error: { code: "unauthenticated", message: "A valid Firebase ID token is required" } } };
    const link = await createLink(db, caller.uid, { channel: "direct", nowMs });
    return { status: 200, body: link };
  }

  // send
  const copy = copyFor(request.lang);
  let uid = null;
  let to = request.to || null;
  if (caller) {
    let record = null;
    try {
      record = await admin.auth().getUser(caller.uid);
    } catch (_) {
      record = null;
    }
    const own = deliverableContact(record, request.channel);
    // A signed-in account may only send to itself: the link signs into *this*
    // account, so it goes to this account's contact and nowhere else.
    if (!own) return { status: 404, body: { error: { code: "no_contact", message: `No ${request.channel === "sms" ? "phone" : "email"} on this account` } } };
    if (to && to !== own) return { status: 403, body: { error: { code: "not_yours", message: "Only your own contact" } } };
    to = own;
    uid = caller.uid;
    if (!(await withinLimits(db, limitKeysFor({ channel: request.channel, to, ip, anonymous: false }), nowMs))) {
      return { status: 429, body: { error: { code: "rate_limited", message: "Try again later" } } };
    }
  } else {
    if (!to) return { status: 400, body: { error: { code: "invalid", message: "to required" } } };
    const keys = limitKeysFor({ channel: request.channel, to, ip, anonymous: true });
    const own = keys.filter((k) => k.kind !== "global");
    if (!(await withinLimits(db, own, nowMs))) return { status: 429, body: { error: { code: "rate_limited", message: "Try again later" } } };
    uid = await findUid(request.channel, to);
    // No account behind this contact: say nothing that tells the caller so.
    // Checked before the project-wide counter, which only a message that is
    // really sent advances: random numbers used to spend the hour's ceiling
    // and lock everyone else out for nothing.
    if (!uid) return { status: 200, body: { ok: true, channel: request.channel } };
    if (!(await withinLimits(db, keys.filter((k) => k.kind === "global"), nowMs))) {
      return { status: 429, body: { error: { code: "rate_limited", message: "Try again later" } } };
    }
  }

  if (request.channel === "sms" && !smsConfigured(sms.sid, sms.token, sms.from)) {
    return { status: 503, body: { error: { code: "delivery_unavailable", message: "SMS delivery is not configured" } } };
  }

  const link = await createLink(db, uid, { channel: request.channel, requestedBy: caller ? caller.uid : "anonymous", nowMs });
  if (request.channel === "sms") {
    await sendSms({ to, body: copy.sms(link.url), sid: sms.sid, token: sms.token, from: sms.from, fetchImpl });
  } else {
    await sendEmail(db, { to, subject: copy.subject, text: copy.text(link.url) });
  }
  logger.info("upgrade link sent", { uid, channel: request.channel, anonymous: !caller });
  return { status: 200, body: { ok: true, channel: request.channel, expiresAt: link.expiresAt } };
}

// Pure: the caller's address. Google's front end in front of Cloud Run
// appends the address it saw to whatever X-Forwarded-For the caller sent,
// so only the LAST hop is ours; the first is whatever the caller typed (and
// Express's req.ip, with trust proxy on, is that same first hop). No
// Hosting rewrite or load balancer sits in front of this function — one
// would add its own hop and this would have to skip it.
function clientIp(forwardedFor, fallback) {
  const hops = String(forwardedFor || "").split(",").map((h) => h.trim()).filter(Boolean);
  return hops.length ? hops[hops.length - 1] : String(fallback || "");
}

async function verifyCurrent(req) {
  const match = (req.get("authorization") || "").match(/^Bearer\s+(.+)$/i);
  if (!match) return null;
  try {
    return await admin.auth().verifyIdToken(match[1], true);
  } catch (err) {
    logger.warn("rejected an ID token", { reason: err.code || err.message });
    return null;
  }
}

exports.upgradeLinks = onRequest(
  { region: "europe-west1", cors: billing.ORIGINS, maxInstances: 5, timeoutSeconds: 30, secrets: [twilioSid, twilioToken, twilioFrom] },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const request = parseRequest(req.body || {});
    if (request.error) return res.status(400).json({ error: { code: "invalid", message: request.error } });
    // Revocation checked too: a link redeems into a custom token, i.e. a
    // fresh session, so an ID token whose refresh tokens were revoked (a
    // session expired by sessions.js, an administrator's kick) must not be
    // able to mint its way back in during the hour it still verifies.
    const caller = request.action === "redeem" ? null : await verifyCurrent(req);
    const ip = clientIp(req.get("x-forwarded-for"), req.ip);
    try {
      const out = await handle({
        db: admin.firestore(),
        caller,
        request,
        ip,
        sms: { sid: twilioSid.value(), token: twilioToken.value(), from: twilioFrom.value() },
      });
      return res.status(out.status).json(out.body);
    } catch (err) {
      logger.error("upgradeLinks failed", { action: request.action, reason: err.message });
      return res.status(500).json({ error: { message: "Failed" } });
    }
  },
);

exports.internals = { clientIp, deliverableContact, switchedOff, mintToken, hashToken, linkFor, validToken, normalizePhone, normalizeEmail, parseRequest, redeemReason, rateDecision, limitKeysFor, copyFor, smsConfigured, createLink, redeem, handle, TTL_MS, LINKS, REQUESTS, MAIL, LIMIT_PER_TARGET, LIMIT_PER_IP, LIMIT_GLOBAL_SMS, GLOBAL_SMS_KEY, LIMIT_GLOBAL_EMAIL, GLOBAL_EMAIL_KEY, WINDOW_MS };
