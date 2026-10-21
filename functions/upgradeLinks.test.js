const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { deliverableContact, switchedOff, mintToken, hashToken, linkFor, validToken, normalizePhone, normalizeEmail, parseRequest, redeemReason, rateDecision, limitKeysFor, copyFor, smsConfigured, TTL_MS, LIMIT_PER_TARGET, LIMIT_PER_IP, LIMIT_GLOBAL_SMS, GLOBAL_SMS_KEY, LIMIT_GLOBAL_EMAIL, GLOBAL_EMAIL_KEY } = require("./upgradeLinks").internals;

const NOW = 1_800_000_000_000;
const ts = (ms) => ({ toMillis: () => ms });

test("a token is 256 random bits; only its hash is what the document is keyed by", () => {
  const { token, hash } = mintToken();
  assert.ok(validToken(token), token);
  assert.equal(hash, hashToken(token));
  assert.equal(hash.length, 64);
  assert.notEqual(mintToken().token, token);
  assert.equal(linkFor(token), `https://aieasyplate.app/app/upgrade/${token}`);
  assert.equal(validToken("short"), false);
  assert.equal(validToken(`${token}!`), false);
});

test("phones are completed to E.164 for Israeli local numbers only; emails are lower-cased", () => {
  assert.equal(normalizePhone("050-123 4567"), "+972501234567");
  assert.equal(normalizePhone("0501234567"), "+972501234567");
  assert.equal(normalizePhone("+972 50 123 4567"), "+972501234567");
  assert.equal(normalizePhone("00972501234567"), "+972501234567");
  assert.equal(normalizePhone("+14155551234"), "+14155551234");
  assert.equal(normalizePhone("4155551234"), null);
  assert.equal(normalizePhone("abc"), null);
  assert.equal(normalizePhone(5), null);
  assert.equal(normalizeEmail("  Koby@Example.COM "), "koby@example.com");
  assert.equal(normalizeEmail("nope"), null);
  assert.equal(normalizeEmail("a@b.c"), null);
});

test("requests are typed per action", () => {
  assert.equal(parseRequest({}).error, "Unknown action");
  assert.equal(parseRequest({ action: "redeem", token: "x" }).error, "token required");
  const { token } = mintToken();
  assert.deepEqual(parseRequest({ action: "redeem", token }), { action: "redeem", lang: "he", token });
  assert.equal(parseRequest({ action: "send" }).error, "channel must be sms or email");
  assert.equal(parseRequest({ action: "send", channel: "sms", to: "123" }).error, "Not a phone number");
  assert.equal(parseRequest({ action: "send", channel: "email", to: "x" }).error, "Not an email address");
  assert.deepEqual(parseRequest({ action: "send", channel: "sms", to: "0501234567", lang: "en" }), { action: "send", lang: "en", channel: "sms", to: "+972501234567" });
  assert.deepEqual(parseRequest({ action: "send", channel: "email" }), { action: "send", lang: "he", channel: "email" });
  assert.deepEqual(parseRequest({ action: "mint" }), { action: "mint", lang: "he" });
});

test("a link is redeemed once, within its half hour", () => {
  const good = { uid: "u1", used: false, expiresAt: ts(NOW + 1000) };
  assert.equal(redeemReason(good, NOW), null);
  assert.equal(redeemReason(null, NOW), "not_found");
  assert.equal(redeemReason({ ...good, used: true }, NOW), "used");
  assert.equal(redeemReason({ ...good, expiresAt: ts(NOW) }, NOW), "expired");
  assert.equal(redeemReason({ ...good, expiresAt: undefined }, NOW), "expired");
  assert.equal(redeemReason({ ...good, uid: "" }, NOW), "not_found");
  assert.equal(TTL_MS, 30 * 60 * 1000);
});

test("the anonymous box is rate-limited per fixed window", () => {
  let state = null;
  for (let i = 0; i < 3; i += 1) {
    const d = rateDecision(state, NOW + i, 3);
    assert.equal(d.allowed, true, `call ${i}`);
    state = d.next;
  }
  assert.equal(rateDecision(state, NOW + 10, 3).allowed, false);
  // Refusals do not extend the window.
  assert.equal(rateDecision(state, NOW + 10, 3).next.windowStart, NOW);
  // A new window starts over.
  const later = rateDecision(state, NOW + 60 * 60 * 1000, 3);
  assert.equal(later.allowed, true);
  assert.deepEqual(later.next, { count: 1, windowStart: NOW + 60 * 60 * 1000 });
  assert.equal(rateDecision({ count: "garbage" }, NOW, 3).allowed, true);
});

test("messages carry the link and exist in Hebrew and English; SMS needs all three Twilio values", () => {
  const url = "https://aieasyplate.app/app/upgrade/x";
  assert.ok(copyFor("he").sms(url).includes(url));
  assert.ok(copyFor("en").text(url).includes(url));
  assert.equal(copyFor("fr").subject, copyFor("en").subject);
  assert.equal(smsConfigured("AC1", "tok", "+1555"), true);
  assert.equal(smsConfigured("AC1", "tok", "-"), false);
  assert.equal(smsConfigured("", "tok", "+1555"), false);
});

test("every send counts against its target; an anonymous one against the caller's address too; every SMS against the project-wide hour", () => {
  const signedIn = limitKeysFor({ channel: "sms", to: "+972501234567", ip: "1.2.3.4", anonymous: false });
  assert.equal(signedIn.length, 2);
  assert.deepEqual(signedIn[0], { key: `t_${hashToken("sms:+972501234567")}`, kind: "target", limit: LIMIT_PER_TARGET });
  assert.deepEqual(signedIn[1], { key: GLOBAL_SMS_KEY, kind: "global", limit: LIMIT_GLOBAL_SMS });
  const anonymous = limitKeysFor({ channel: "sms", to: "+972501234567", ip: "1.2.3.4", anonymous: true });
  assert.equal(anonymous.length, 3);
  assert.equal(anonymous[0].key, signedIn[0].key);
  assert.deepEqual(anonymous[1], { key: `ip_${hashToken("1.2.3.4")}`, kind: "ip", limit: LIMIT_PER_IP });
  assert.equal(anonymous[2].key, GLOBAL_SMS_KEY);
  // The global counter is one document whatever the number or the address.
  assert.equal(limitKeysFor({ channel: "sms", to: "+15550001111", ip: "9.9.9.9", anonymous: true })[2].key, GLOBAL_SMS_KEY);
  assert.equal(LIMIT_GLOBAL_SMS, 200);
  // Email costs nothing to send and is not under the SMS ceiling.
  // Email has a project-wide hourly ceiling of its own.
  assert.equal(limitKeysFor({ channel: "email", to: "a@b.co", anonymous: false }).length, 2);
  assert.equal(limitKeysFor({ channel: "email", to: "a@b.co", ip: "1.2.3.4", anonymous: true }).length, 3);
  assert.deepEqual(limitKeysFor({ channel: "email", to: "a@b.co", anonymous: false })[1], { key: GLOBAL_EMAIL_KEY, kind: "global", limit: LIMIT_GLOBAL_EMAIL });
  // The channel is part of the key: an email and an SMS to "the same" person are separate allowances.
  assert.notEqual(limitKeysFor({ channel: "email", to: "a@b.co", anonymous: false })[0].key, limitKeysFor({ channel: "sms", to: "a@b.co", anonymous: false })[0].key);
  assert.equal(limitKeysFor({ channel: "sms", to: "+1", ip: "", anonymous: true })[1].key, `ip_${hashToken("none")}`);
});

test("a link does not sign into an account the console switched off", async () => {
  const dbWith = (docs) => ({ doc: (path) => ({ get: async () => ({ exists: path in docs, data: () => docs[path] }) }) });
  assert.equal(await switchedOff(dbWith({ "account_status/u1": { disabled: true } }), "u1"), true);
  assert.equal(await switchedOff(dbWith({ "account_status/u1": { disabled: false } }), "u1"), false);
  assert.equal(await switchedOff(dbWith({}), "u1"), false);
  const broken = { doc: () => ({ get: async () => { throw new Error("unavailable"); } }) };
  assert.equal(await switchedOff(broken, "u1"), true, "an unreadable status refuses");
});

test("a link goes only to a phone, or to an email the account has verified", () => {
  assert.equal(deliverableContact({ phoneNumber: "+972500000000" }, "sms"), "+972500000000");
  assert.equal(deliverableContact({ email: "a@b.c", emailVerified: true }, "email"), "a@b.c");
  assert.equal(deliverableContact({ email: "a@b.c", emailVerified: false }, "email"), null);
  assert.equal(deliverableContact({ email: "a@b.c" }, "email"), null);
  assert.equal(deliverableContact({ phoneNumber: "+972500000000", disabled: true }, "sms"), null);
  assert.equal(deliverableContact(null, "sms"), null);
});

test("the caller's address is the hop Google's front end appended, not the one the caller sent", () => {
  const { clientIp } = require("./upgradeLinks").internals;
  assert.equal(clientIp("6.6.6.6, 203.0.113.9", "6.6.6.6"), "203.0.113.9");
  assert.equal(clientIp("203.0.113.9", null), "203.0.113.9");
  assert.equal(clientIp("1.1.1.1,  2.2.2.2 ,", null), "2.2.2.2");
  assert.equal(clientIp("", "198.51.100.1"), "198.51.100.1");
  assert.equal(clientIp(undefined, undefined), "");
});
