// The administrator's Remote Config editor. The app cannot write the
// console's template itself (that is the Admin SDK), so it asks here:
//
//   get                  every parameter, flat, with its group, description,
//                        type and current default value
//   set { name, value }  one parameter's default value, published at once
//
// Only the administrator, by the email on the ID token — the same check
// adminUsers makes. A plain set edits the default of each parameter and
// leaves conditional values alone.
//
// A per-platform value (2026-11-05, for minimumVersion) is a conditional
// value under IsAndroidProd / IsIosProd. Those conditions match the store
// app ids, so builds already in the field pick the split up with no app
// change. `platform: "android" | "ios"` writes that one value.
// `platform: "both"` writes the default and drops both platform values, so
// the two platforms read the same thing again.
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const { isAdmin } = require("./permissions");

const FLAG_RE = /^ff_/;
const PLATFORM_CONDITIONS = { android: "IsAndroidProd", ios: "IsIosProd" };

// Pure: the template's parameters and grouped parameters as one ordered
// list the app can draw.
function flattenTemplate(template) {
  const out = [];
  const push = (name, param, group) => out.push({
    name,
    group: group || "",
    description: (param && param.description) || "",
    valueType: (param && param.valueType) || "STRING",
    value: param && param.defaultValue && param.defaultValue.value !== undefined ? String(param.defaultValue.value) : "",
    // The value a platform overrides the default with; null when it follows the default.
    platforms: platformValues(param),
  });
  for (const [name, param] of Object.entries(template.parameters || {})) push(name, param, "");
  for (const [groupName, group] of Object.entries(template.parameterGroups || {})) {
    for (const [name, param] of Object.entries(group.parameters || {})) push(name, param, groupName);
  }
  return out;
}

// Pure: { android, ios }, each the platform's own conditional value or null.
function platformValues(param) {
  const conditional = (param && param.conditionalValues) || {};
  const out = {};
  for (const [platform, condition] of Object.entries(PLATFORM_CONDITIONS)) {
    const entry = conditional[condition];
    out[platform] = entry && entry.value !== undefined ? String(entry.value) : null;
  }
  return out;
}

// Pure: finds the parameter wherever it sits.
function findParam(template, name) {
  if (template.parameters && template.parameters[name]) return template.parameters[name];
  for (const group of Object.values(template.parameterGroups || {})) {
    if (group.parameters && group.parameters[name]) return group.parameters[name];
  }
  return null;
}

// Pure: the value checked against the parameter's type (and the 0–4 range
// of a feature flag), then written as the parameter's default, or as one
// platform's value (see the note at the top). Returns the error code, or
// null when the template was changed.
function applyValue(template, name, rawValue, platform) {
  if (platform !== undefined && platform !== null && platform !== "" &&
      platform !== "both" && !PLATFORM_CONDITIONS[platform]) return "invalid_platform";
  const param = findParam(template, name);
  if (!param) return "not_found";
  const value = String(rawValue === undefined || rawValue === null ? "" : rawValue).trim();
  switch (param.valueType) {
    case "BOOLEAN":
      if (value !== "true" && value !== "false") return "invalid_boolean";
      break;
    case "NUMBER": {
      if (value === "" || Number.isNaN(Number(value))) return "invalid_number";
      if (FLAG_RE.test(name) && !["0", "1", "2", "3", "4"].includes(value)) return "invalid_flag";
      break;
    }
    case "JSON":
      try { JSON.parse(value); } catch (_) { return "invalid_json"; }
      break;
    default:
      break;
  }
  if (PLATFORM_CONDITIONS[platform]) {
    const condition = PLATFORM_CONDITIONS[platform];
    if (!(template.conditions || []).some((c) => c.name === condition)) return "no_condition";
    param.conditionalValues = { ...(param.conditionalValues || {}), [condition]: { value } };
    return null;
  }
  param.defaultValue = { value };
  if (platform === "both" && param.conditionalValues) {
    for (const condition of Object.values(PLATFORM_CONDITIONS)) delete param.conditionalValues[condition];
    if (!Object.keys(param.conditionalValues).length) delete param.conditionalValues;
  }
  return null;
}

async function publish(template) {
  const rc = admin.remoteConfig();
  const validated = await rc.validateTemplate(template);
  return rc.publishTemplate(validated);
}

exports.adminRemoteConfig = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 2 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    // Revocation checked: the administrator's powers are the ones worth
    // stealing a token for, and revoking the refresh tokens (Firebase
    // console, or a password reset) has to end a stolen session now, not
    // within the hour the ID token still verifies. One Auth lookup per
    // console call.
    const caller = await proxy.verifyCaller(req, { checkRevoked: true });
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    if (!(await isAdmin(caller))) return res.status(403).json({ error: { message: "Administrator only" } });
    const action = req.body && req.body.action;
    try {
      const rc = admin.remoteConfig();
      if (action === "get") {
        const template = await rc.getTemplate();
        return res.status(200).json({ version: template.version && template.version.versionNumber, parameters: flattenTemplate(template) });
      }
      if (action === "set") {
        const name = String((req.body && req.body.name) || "").trim();
        if (!name) return res.status(400).json({ error: { code: "invalid", message: "name is required" } });
        const template = await rc.getTemplate();
        const error = applyValue(template, name, req.body.value, req.body.platform);
        if (error) return res.status(error === "not_found" ? 404 : 400).json({ error: { code: error, message: error } });
        const published = await publish(template);
        logger.info("remote config set", { by: caller.uid, name, value: String(req.body.value), platform: req.body.platform || "default" });
        return res.status(200).json({ version: published.version && published.version.versionNumber, parameters: flattenTemplate(published) });
      }
      return res.status(400).json({ error: { message: "Unknown action" } });
    } catch (err) {
      logger.error("remote config admin failed", { action, reason: err.message });
      return res.status(500).json({ error: { code: "failed", message: "Remote Config action failed" } });
    }
  },
);

exports.internals = { flattenTemplate, findParam, applyValue, publish, platformValues, PLATFORM_CONDITIONS };
