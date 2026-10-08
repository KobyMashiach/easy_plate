#!/usr/bin/env node
// Publishes the parameters in ../remoteconfig.template.json into the live
// Remote Config template WITHOUT touching anything else in it: the console
// stays the source of truth for values edited there, and the file is how
// new parameters (and their defaults) reach the project from the repo.
//
//   node functions/scripts/publishRemoteConfig.js            # merge + publish
//   node functions/scripts/publishRemoteConfig.js --dry-run  # show the diff
//   node functions/scripts/publishRemoteConfig.js --remove a,b   # retire parameters
//
// Needs application-default credentials (gcloud auth application-default login).
const fs = require("node:fs");
const path = require("node:path");
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getRemoteConfig } = require("firebase-admin/remote-config");

const dryRun = process.argv.includes("--dry-run");
// Parameters to take out of the console (a gate the flags replaced). The
// only way the script ever removes anything, and only what is named.
const removeArg = process.argv.indexOf("--remove");
const toRemove = removeArg === -1 ? [] : String(process.argv[removeArg + 1] || "").split(",").map((s) => s.trim()).filter(Boolean);
const file = path.resolve(__dirname, "../../remoteconfig.template.json");
const fileTemplate = JSON.parse(fs.readFileSync(file, "utf8"));
const wanted = fileTemplate.parameters || {};
const fileConditions = fileTemplate.conditions || [];

async function main() {
  initializeApp({ credential: applicationDefault(), projectId: process.env.GCLOUD_PROJECT || "easy-plate" });
  const rc = getRemoteConfig();
  const template = await rc.getTemplate();
  const added = [];
  for (const [name, param] of Object.entries(wanted)) {
    if (template.parameters[name]) continue; // the console's value wins
    // A conditional value needs its condition; bring it from the file, or
    // drop the value rather than publish a dangling reference.
    for (const condName of Object.keys(param.conditionalValues || {})) {
      if (template.conditions.some((c) => c.name === condName)) continue;
      const fromFile = fileConditions.find((c) => c.name === condName);
      if (fromFile) {
        template.conditions.push(fromFile);
      } else {
        console.warn(`${name}: condition "${condName}" exists nowhere; its value is dropped`);
        delete param.conditionalValues[condName];
      }
    }
    template.parameters[name] = param;
    added.push(name);
  }
  // Parameter groups: the group is created when the console lacks it; a
  // parameter already in the console (in any group, or ungrouped) is left
  // alone, so a value edited there is never overwritten.
  const inConsole = new Set(Object.keys(template.parameters));
  for (const group of Object.values(template.parameterGroups || {})) {
    for (const name of Object.keys(group.parameters || {})) inConsole.add(name);
  }
  template.parameterGroups = template.parameterGroups || {};
  for (const [groupName, group] of Object.entries(fileTemplate.parameterGroups || {})) {
    const target = template.parameterGroups[groupName] || (template.parameterGroups[groupName] = { description: group.description, parameters: {} });
    if (!target.description && group.description) target.description = group.description;
    target.parameters = target.parameters || {};
    for (const [name, param] of Object.entries(group.parameters || {})) {
      if (inConsole.has(name)) continue;
      target.parameters[name] = param;
      added.push(`${groupName}/${name}`);
    }
  }
  const removed = [];
  for (const name of toRemove) {
    if (template.parameters[name]) {
      delete template.parameters[name];
      removed.push(name);
    }
    for (const group of Object.values(template.parameterGroups)) {
      if (group.parameters && group.parameters[name]) {
        delete group.parameters[name];
        removed.push(name);
      }
    }
  }
  if (added.length === 0 && removed.length === 0) {
    console.log("nothing to do: every parameter in the file already exists");
    return;
  }
  if (added.length) console.log(`${dryRun ? "would add" : "adding"}: ${added.join(", ")}`);
  if (removed.length) console.log(`${dryRun ? "would remove" : "removing"}: ${removed.join(", ")}`);
  if (dryRun) return;
  const validated = await rc.validateTemplate(template);
  const published = await rc.publishTemplate(validated);
  console.log(`published version ${published.version?.versionNumber}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
