const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { flattenTemplate, findParam, applyValue } = require("./adminRemoteConfig").internals;

const template = () => ({
  parameters: {
    ads_enabled: { defaultValue: { value: "true" }, description: "ads", valueType: "BOOLEAN" },
    quota_ai_premium: { defaultValue: { value: "10" }, valueType: "NUMBER" },
    isProd: { defaultValue: { value: "" }, valueType: "STRING" },
  },
  parameterGroups: {
    featureFlags: { parameters: { ff_books: { defaultValue: { value: "2" }, description: "books", valueType: "NUMBER" } } },
  },
});

test("the template is flattened in order with the group named", () => {
  const flat = flattenTemplate(template());
  assert.deepEqual(flat.map((p) => p.name), ["ads_enabled", "quota_ai_premium", "isProd", "ff_books"]);
  assert.deepEqual(flat[3], { name: "ff_books", group: "featureFlags", description: "books", valueType: "NUMBER", value: "2" });
  assert.equal(flat[2].value, "");
});

test("a parameter is found wherever it sits", () => {
  assert.ok(findParam(template(), "ff_books"));
  assert.ok(findParam(template(), "ads_enabled"));
  assert.equal(findParam(template(), "nope"), null);
});

test("values are checked against the type before they are written", () => {
  let t = template();
  assert.equal(applyValue(t, "ads_enabled", "false"), null);
  assert.equal(t.parameters.ads_enabled.defaultValue.value, "false");
  assert.equal(applyValue(t, "ads_enabled", "yes"), "invalid_boolean");
  assert.equal(applyValue(t, "quota_ai_premium", "abc"), "invalid_number");
  assert.equal(applyValue(t, "quota_ai_premium", 12), null);
  assert.equal(t.parameters.quota_ai_premium.defaultValue.value, "12");
  assert.equal(applyValue(t, "ff_books", "4"), "invalid_flag");
  assert.equal(applyValue(t, "ff_books", "3"), null);
  assert.equal(t.parameterGroups.featureFlags.parameters.ff_books.defaultValue.value, "3");
  assert.equal(applyValue(t, "isProd", "1.0.0"), null);
  assert.equal(applyValue(t, "missing", "1"), "not_found");
});
