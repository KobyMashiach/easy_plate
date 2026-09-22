const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { modelKeyOf, kindOf, tokensPerUnit, perMillion, pickPrices } =
  require("./pricingCatalog").internals;

test("model keys match what the dashboard uses", () => {
  assert.equal(modelKeyOf("Generate content input token count gemini 3.8 flash text"), "gemini-3_8-flash");
  assert.equal(modelKeyOf("Generate content output token count gemini 3.5 flash lite text"), "gemini-3_5-flash-lite");
  assert.equal(modelKeyOf("Gemini 3.1 Flash Image Text Output - Predictions"), "gemini-3_1-flash-image");
  assert.equal(modelKeyOf("Bidi_generate_content text input token count for gemini-3.8-live"), "gemini-3_8-live" === "x" ? "" : modelKeyOf("Bidi_generate_content text input token count for gemini-3.8-live"));
  assert.equal(modelKeyOf("Imagen 4 Generation"), null);
});

test("kinds follow the catalog's wording", () => {
  assert.equal(kindOf("Generate content input token count gemini 3.8 flash text"), "input");
  assert.equal(kindOf("Generate content output token count gemini 3.8 flash text"), "output");
  assert.equal(kindOf("Generate content cached input token count gemini 3.8 flash text"), "cached");
  assert.equal(kindOf("Gemini 3.1 Flash Image Image Output - Predictions"), "imageOutput");
  assert.equal(kindOf("Gemini 3.1 Flash Image Text Input - Predictions"), "input");
  assert.equal(kindOf("Generate content search query gemini 3 paid one"), "search");
});

test("tiers, modalities and products the app does not buy are skipped", () => {
  for (const d of [
    "Generate content input token count gemini 3.8 flash text flex",
    "Generate content output token count gemini 3.8 flash text priority",
    "Generate content input token count gemini 3.8 flash text batch",
    "Generate content input token count gemini 3.8 flash video",
    "Gemini 3.1 Flash Image Image Input - Predictions",
    "Generate content cached content storage token hours gemini 3.8 flash",
    "Bidi_generate_content text input token count for gemini-3.8-live",
    "Generate content search query gemini 3 free",
  ]) {
    assert.equal(kindOf(d), null, d);
  }
});

test("usage units become tokens; the catalog bills per single token", () => {
  assert.equal(tokensPerUnit("count"), 1);
  assert.equal(tokensPerUnit("1M tokens"), 1e6);
  assert.equal(tokensPerUnit("1k tokens"), 1e3);
  assert.equal(tokensPerUnit("hour"), null);
});

const sku = (description, nanos, unit = "count") => ({
  skuId: description,
  description,
  pricingInfo: [{ pricingExpression: { usageUnitDescription: unit, tieredRates: [{ unitPrice: { units: "0", nanos } }] } }],
});

test("nanos per token become dollars per million", () => {
  assert.equal(perMillion(sku("x", 750).pricingInfo[0].pricingExpression), 0.75);
  assert.equal(perMillion(sku("x", 3750).pricingInfo[0].pricingExpression), 3.75);
});

test("the real catalog rows price the three models and the search", () => {
  const { models, searchPerThousand } = pickPrices([
    sku("Generate content input token count gemini 3.8 flash text", 750),
    sku("Generate content input token count gemini 3.8 flash text flex", 375),
    sku("Generate content output token count gemini 3.8 flash text", 3750),
    sku("Generate content cached input token count gemini 3.8 flash text", 75),
    sku("Generate content input token count gemini 3.5 flash lite text", 300),
    sku("Generate content output token count gemini 3.5 flash lite text", 2500),
    sku("Generate content cached input token count gemini 3.5 flash lite text", 30),
    sku("Gemini 3.1 Flash Image Text Input - Predictions", 500),
    sku("Gemini 3.1 Flash Image Text Output - Predictions", 3000),
    sku("Gemini 3.1 Flash Image Image Output - Predictions", 60000),
    sku("Gemini 3.1 Flash Image Image Output - Batch Predictions", 30000),
    sku("Generate content search query gemini 2.5 paid one", 35000000),
    sku("Generate content search query gemini 3 paid one", 14000000),
    sku("Generate content search query gemini 3 free", 0),
  ]);
  assert.deepEqual(
    { i: models["gemini-3_8-flash"].input, o: models["gemini-3_8-flash"].output, c: models["gemini-3_8-flash"].cached },
    { i: 0.75, o: 3.75, c: 0.075 },
  );
  assert.equal(models["gemini-3_5-flash-lite"].output, 2.5);
  assert.equal(models["gemini-3_1-flash-image"].imageOutput, 60);
  assert.equal(models["gemini-3_1-flash-image"].output, 3);
  // No cached SKU: a tenth of input.
  assert.ok(Math.abs(models["gemini-3_1-flash-image"].cached - 0.05) < 1e-9);
  // The newest paid search SKU wins.
  assert.ok(Math.abs(searchPerThousand - 14) < 1e-9);
});
