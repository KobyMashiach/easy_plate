// Run with: npm test  (node's built-in runner walks scripts/ too)
const test = require("node:test");
const assert = require("node:assert/strict");

const { resolveKnob, render, KNOBS } = require("./syncRuntimeOptions");

const minInstances = KNOBS[0];
const timeout = KNOBS[2];

test("a console value is used as written", () => {
  assert.equal(resolveKnob({ defaultValue: { value: "3" } }, minInstances), 3);
});

test("a parameter that does not exist falls back", () => {
  assert.equal(resolveKnob(undefined, minInstances), 1);
});

test("a blank console value is treated as unset, not as zero", () => {
  assert.equal(resolveKnob({ defaultValue: { value: "  " } }, minInstances), 1);
});

test("a parameter set to in-app default falls back", () => {
  assert.equal(resolveKnob({ defaultValue: { useInAppDefault: true } }, minInstances), 1);
});

test("a non-numeric value fails the deploy rather than shipping", () => {
  assert.throws(
    () => resolveKnob({ defaultValue: { value: "ten" } }, minInstances),
    /not a whole number/,
  );
});

test("a value Google would refuse fails here first", () => {
  assert.throws(
    () => resolveKnob({ defaultValue: { value: "9999" } }, timeout),
    /outside the allowed/,
  );
});

test("zero warm instances is a legitimate choice", () => {
  assert.equal(resolveKnob({ defaultValue: { value: "0" } }, minInstances), 0);
});

test("the rendered file is a readable env file", () => {
  const text = render({ GEMINI_MIN_INSTANCES: 1, GEMINI_MAX_INSTANCES: 10 });
  assert.match(text, /^GEMINI_MIN_INSTANCES=1$/m);
  assert.match(text, /^GEMINI_MAX_INSTANCES=10$/m);
});
