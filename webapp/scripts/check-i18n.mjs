// Fails the build when the five dictionaries in src/lib/i18n.tsx drift:
// every language must have exactly the same keys, and each key the same
// {placeholders}. Run by `npm run build` before tsc and vite.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const LANGS = ["he", "en", "ar", "fr", "ru"];
const file = fileURLToPath(new URL("../src/lib/i18n.tsx", import.meta.url));
const source = readFileSync(file, "utf8");

// Each dictionary is a plain object literal: `const he: Dict = { … };`.
const dicts = {};
for (const lang of LANGS) {
  const match = source.match(new RegExp(`^const ${lang}: Dict = (\\{[\\s\\S]*?^\\});`, "m"));
  if (!match) {
    console.error(`check-i18n: dictionary "${lang}" not found in ${file}`);
    process.exit(1);
  }
  dicts[lang] = new Function(`return (${match[1]});`)();
}

// Feature dictionaries (src/i18n/*.json): each file is checked on its own
// (same keys in every language, keys prefixed with the file's name) and merged
// into the totals; a key defined twice anywhere is an error.
import { readdirSync } from "node:fs";
const featureDir = fileURLToPath(new URL("../src/i18n/", import.meta.url));
const featureProblems = [];
let featureFiles = [];
try {
  featureFiles = readdirSync(featureDir).filter((f) => f.endsWith(".json"));
} catch (_) {
  featureFiles = [];
}
const owner = new Map(Object.keys(dicts.en).map((k) => [k, "lib/i18n.tsx"]));
for (const fileName of featureFiles) {
  const feature = fileName.replace(/\.json$/, "");
  let json;
  try {
    json = JSON.parse(readFileSync(featureDir + fileName, "utf8"));
  } catch (e) {
    featureProblems.push(`${fileName}: not valid JSON (${e.message})`);
    continue;
  }
  for (const lang of LANGS) {
    if (!json[lang] || typeof json[lang] !== "object") {
      featureProblems.push(`${fileName}: missing language "${lang}"`);
      json[lang] = {};
    }
  }
  for (const key of Object.keys(json.en || {})) {
    if (!key.startsWith(`${feature}.`)) featureProblems.push(`${fileName}: key "${key}" must start with "${feature}."`);
    if (owner.has(key)) featureProblems.push(`${fileName}: key "${key}" is already defined in ${owner.get(key)}`);
    owner.set(key, fileName);
  }
  for (const lang of LANGS) Object.assign(dicts[lang], json[lang]);
}

const placeholders = (text) => [...new Set([...String(text).matchAll(/\{(\w+)\}/g)].map((m) => m[1]))].sort().join(",");
const allKeys = new Set(LANGS.flatMap((lang) => Object.keys(dicts[lang])));
const problems = [];
for (const lang of LANGS) {
  const missing = [...allKeys].filter((key) => !(key in dicts[lang]));
  if (missing.length) problems.push(`${lang} is missing ${missing.length} key(s): ${missing.join(", ")}`);
}
for (const key of allKeys) {
  const sets = LANGS.filter((lang) => key in dicts[lang]).map((lang) => [lang, placeholders(dicts[lang][key])]);
  if (new Set(sets.map(([, p]) => p)).size > 1) problems.push(`"${key}" placeholders differ: ${sets.map(([l, p]) => `${l}{${p}}`).join(" ")}`);
}

problems.push(...featureProblems);
if (problems.length) {
  console.error(`check-i18n: ${problems.length} problem(s) in ${file}\n  ${problems.join("\n  ")}`);
  process.exit(1);
}
console.log(`check-i18n: ${LANGS.length} languages, ${allKeys.size} keys (${featureFiles.length} feature files), all in step`);
