const test = require("node:test");
const assert = require("node:assert/strict");
const { encode, verifySignature, sign, request, StripeError } = require("./stripeClient");

test("nested params take Stripe's bracket form", () => {
  const body = encode({
    mode: "subscription",
    line_items: [{ price: "price_1", quantity: 1 }],
    metadata: { uid: "u 1" },
    allow_promotion_codes: true,
    skipped: null,
    also: undefined,
  });
  assert.equal(
    body,
    "mode=subscription&line_items%5B0%5D%5Bprice%5D=price_1&line_items%5B0%5D%5Bquantity%5D=1&metadata%5Buid%5D=u%201&allow_promotion_codes=true",
  );
});

test("a signature is accepted only when fresh and matching", () => {
  const secret = "whsec_test";
  const body = Buffer.from('{"id":"evt_1"}');
  const now = 1_800_000_000_000;
  const header = sign(body, secret, Math.floor(now / 1000));
  assert.equal(verifySignature(header, body, secret, { nowMs: now }), null);
  // A second v1 (key rotation) is fine as long as one matches.
  assert.equal(verifySignature(`${header},v1=${"0".repeat(64)}`, body, secret, { nowMs: now }), null);
  assert.equal(verifySignature(header, Buffer.from('{"id":"evt_2"}'), secret, { nowMs: now }), "mismatch");
  assert.equal(verifySignature(header, body, "whsec_other", { nowMs: now }), "mismatch");
  assert.equal(verifySignature(header, body, secret, { nowMs: now + 10 * 60 * 1000 }), "stale");
  assert.equal(verifySignature(undefined, body, secret, { nowMs: now }), "missing");
  assert.equal(verifySignature("garbage", body, secret, { nowMs: now }), "malformed");
  assert.equal(verifySignature(header, body, "", { nowMs: now }), "missing");
  assert.equal(verifySignature(header, body, "-", { nowMs: now }), "missing");
});

test("request sends form bodies with the key and version, and surfaces Stripe errors", async () => {
  const calls = [];
  const fetchImpl = async (url, init) => {
    calls.push({ url, init });
    if (url.endsWith("/customers")) return { ok: true, text: async () => JSON.stringify({ id: "cus_1" }) };
    return { ok: false, status: 404, text: async () => JSON.stringify({ error: { code: "resource_missing", message: "No such price" } }) };
  };
  const customer = await request("sk_test", "POST", "/customers", { metadata: { uid: "u1" } }, { idempotencyKey: "k", fetchImpl });
  assert.equal(customer.id, "cus_1");
  assert.equal(calls[0].init.headers.Authorization, "Bearer sk_test");
  assert.equal(calls[0].init.headers["Idempotency-Key"], "k");
  assert.ok(calls[0].init.headers["Stripe-Version"]);
  assert.equal(calls[0].init.body, "metadata%5Buid%5D=u1");

  await assert.rejects(
    request("sk_test", "GET", "/prices/price_x", { expand: ["product"] }, { fetchImpl }),
    (err) => err instanceof StripeError && err.status === 404 && err.code === "resource_missing",
  );
  assert.ok(calls[1].url.endsWith("/prices/price_x?expand%5B0%5D=product"));
  assert.equal(calls[1].init.body, undefined);

  await assert.rejects(request("", "GET", "/prices", {}, { fetchImpl }), (err) => err.code === "not_configured");
  await assert.rejects(request("-", "GET", "/prices", {}, { fetchImpl }), (err) => err.code === "not_configured");
});
