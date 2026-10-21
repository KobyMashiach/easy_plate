const test = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");

// The Remote Config console refuses a description longer than 256
// characters, and so does a publish of this template.
const MAX_DESCRIPTION = 256;

test("every Remote Config description fits the console's 256 characters", () => {
  const template = require(path.join(__dirname, "..", "remoteconfig.template.json"));
  const over = [];
  const check = (where, entry) => {
    const length = [...String((entry && entry.description) || "")].length;
    if (length > MAX_DESCRIPTION) over.push(`${where} (${length})`);
  };
  for (const [key, param] of Object.entries(template.parameters || {})) check(key, param);
  for (const [group, body] of Object.entries(template.parameterGroups || {})) {
    check(`group ${group}`, body);
    for (const [key, param] of Object.entries(body.parameters || {})) check(`${group}/${key}`, param);
  }
  assert.deepEqual(over, []);
});

test("the session release wait the server reads is in the template", () => {
  const template = require(path.join(__dirname, "..", "remoteconfig.template.json"));
  const param = template.parameters.session_release_wait_hours;
  assert.equal(param.valueType, "NUMBER");
  assert.equal(param.defaultValue.value, "24");
});

test("the translate cache-read budget the server reads is in the template", () => {
  const template = require(path.join(__dirname, "..", "remoteconfig.template.json"));
  const param = template.parameters.quota_translate_cache_reads_daily;
  assert.equal(param.valueType, "NUMBER");
  assert.equal(param.defaultValue.value, "50000");
});
