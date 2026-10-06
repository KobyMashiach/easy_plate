#!/usr/bin/env node
// Publishes the parameters in ../remoteconfig.template.json into the live
// Remote Config template WITHOUT touching anything else in it: the console
// stays the source of truth for values edited there, and the file is how
// new parameters (and their defaults) reach the project from the repo.
//
//   node functions/scripts/publishRemoteConfig.js            # merge + publish
//   node functions/scripts/publishRemoteConfig.js --dry-run  # show the diff
//
// Needs application-default credentials (gcloud auth application-default login).
const fs = require("node:fs");
const path = require("node:path");
const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getRemoteConfig } = require("firebase-admin/remote-config");

const dryRun = process.argv.includes("--dry-run");
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
  if (added.length === 0) {
    console.log("nothing to add: every parameter in the file already exists");
    return;
  }
  console.log(`${dryRun ? "would add" : "adding"}: ${added.join(", ")}`);
  if (dryRun) return;
  const validated = await rc.validateTemplate(template);
  const published = await rc.publishTemplate(validated);
  console.log(`published version ${published.version?.versionNumber}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
