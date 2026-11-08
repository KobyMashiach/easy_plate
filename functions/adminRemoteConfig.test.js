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
  assert.deepEqual(flat[3], { name: "ff_books", group: "featureFlags", description: "books", valueType: "NUMBER", value: "2", platforms: { android: null, ios: null } });
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
  assert.equal(applyValue(t, "ff_books", "5"), "invalid_flag");
  assert.equal(applyValue(t, "ff_books", "4"), null);
  assert.equal(applyValue(t, "ff_books", "3"), null);
  assert.equal(t.parameterGroups.featureFlags.parameters.ff_books.defaultValue.value, "3");
  assert.equal(applyValue(t, "isProd", "1.0.0"), null);
  assert.equal(applyValue(t, "missing", "1"), "not_found");
});

const withConditions = () => ({
  ...template(),
  conditions: [{ name: "IsAndroidProd", expression: "x" }, { name: "IsIosProd", expression: "y" }],
  parameters: { ...template().parameters, minimumVersion: { defaultValue: { value: "1.0.5" }, valueType: "STRING" } },
});

test("one platform's minimum version is set without touching the other", () => {
  const t = withConditions();
  assert.equal(applyValue(t, "minimumVersion", "1.0.9", "android"), null);
  const p = t.parameters.minimumVersion;
  assert.equal(p.defaultValue.value, "1.0.5");
  assert.deepEqual(p.conditionalValues, { IsAndroidProd: { value: "1.0.9" } });
  const flat = flattenTemplate(t).find((x) => x.name === "minimumVersion");
  assert.deepEqual(flat.platforms, { android: "1.0.9", ios: null });
  assert.equal(applyValue(t, "minimumVersion", "1.0.7", "ios"), null);
  assert.deepEqual(flattenTemplate(t).find((x) => x.name === "minimumVersion").platforms, { android: "1.0.9", ios: "1.0.7" });
});

test("both platforms together writes the default and drops the overrides", () => {
  const t = withConditions();
  applyValue(t, "minimumVersion", "1.0.9", "android");
  applyValue(t, "minimumVersion", "1.0.7", "ios");
  assert.equal(applyValue(t, "minimumVersion", "1.1.0", "both"), null);
  assert.equal(t.parameters.minimumVersion.defaultValue.value, "1.1.0");
  assert.equal(t.parameters.minimumVersion.conditionalValues, undefined);
});

test("a plain set keeps conditional values, as before", () => {
  const t = withConditions();
  t.parameters.isProd.conditionalValues = { IsAndroidProd: { value: "1.0.8" }, Other: { value: "z" } };
  assert.equal(applyValue(t, "isProd", "1.0.0"), null);
  assert.deepEqual(Object.keys(t.parameters.isProd.conditionalValues), ["IsAndroidProd", "Other"]);
  // "both" drops only the two platform values, never another condition.
  assert.equal(applyValue(t, "isProd", "1.0.1", "both"), null);
  assert.deepEqual(t.parameters.isProd.conditionalValues, { Other: { value: "z" } });
});

test("an unknown platform or a missing condition is refused", () => {
  assert.equal(applyValue(withConditions(), "minimumVersion", "1.0.9", "web"), "invalid_platform");
  assert.equal(applyValue(template(), "isProd", "1.0.9", "ios"), "no_condition");
});
