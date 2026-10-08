// The administrator's Remote Config editor. The app cannot write the
// console's template itself (that is the Admin SDK), so it asks here:
//
//   get                  every parameter, flat, with its group, description,
//                        type and current default value
//   set { name, value }  one parameter's default value, published at once
//
// Only the administrator, by the email on the ID token — the same check
// adminUsers makes. Conditional values are left alone: this edits the
// default of each parameter, which is what the app reads.
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const proxy = require("./aiProxy").internals;
const { isAdmin } = require("./adminUsers").internals;

const FLAG_RE = /^ff_/;

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
  });
  for (const [name, param] of Object.entries(template.parameters || {})) push(name, param, "");
  for (const [groupName, group] of Object.entries(template.parameterGroups || {})) {
    for (const [name, param] of Object.entries(group.parameters || {})) push(name, param, groupName);
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

// Pure: the value checked against the parameter's type (and the 0–3 range
// of a feature flag), then written as the parameter's default. Returns
// the error code, or null when the template was changed.
function applyValue(template, name, rawValue) {
  const param = findParam(template, name);
  if (!param) return "not_found";
  const value = String(rawValue === undefined || rawValue === null ? "" : rawValue).trim();
  switch (param.valueType) {
    case "BOOLEAN":
      if (value !== "true" && value !== "false") return "invalid_boolean";
      break;
    case "NUMBER": {
      if (value === "" || Number.isNaN(Number(value))) return "invalid_number";
      if (FLAG_RE.test(name) && !["0", "1", "2", "3"].includes(value)) return "invalid_flag";
      break;
    }
    case "JSON":
      try { JSON.parse(value); } catch (_) { return "invalid_json"; }
      break;
    default:
      break;
  }
  param.defaultValue = { value };
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
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    if (!isAdmin(caller)) return res.status(403).json({ error: { message: "Administrator only" } });
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
        const error = applyValue(template, name, req.body.value);
        if (error) return res.status(error === "not_found" ? 404 : 400).json({ error: { code: error, message: error } });
        const published = await publish(template);
        logger.info("remote config set", { by: caller.uid, name, value: String(req.body.value) });
        return res.status(200).json({ version: published.version && published.version.versionNumber, parameters: flattenTemplate(published) });
      }
      return res.status(400).json({ error: { message: "Unknown action" } });
    } catch (err) {
      logger.error("remote config admin failed", { action, reason: err.message });
      return res.status(500).json({ error: { message: err.message } });
    }
  },
);

exports.internals = { flattenTemplate, findParam, applyValue };
