// Splits the feature dictionaries (src/i18n/<feature>.json, all five
// languages in each) into one file per language: src/i18n-gen/<lang>.json.
// The app then downloads only the visitor's language (plus English as the
// fallback) instead of every language of every page. Run before tsc/vite by
// `npm run build` and `npm run dev`; the output is generated, not committed.
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const LANGS = ["he", "en", "ar", "fr", "ru"];
const src = fileURLToPath(new URL("../src/i18n/", import.meta.url));
const out = fileURLToPath(new URL("../src/i18n-gen/", import.meta.url));
mkdirSync(out, { recursive: true });
const merged = Object.fromEntries(LANGS.map((l) => [l, {}]));
for (const file of readdirSync(src).filter((f) => f.endsWith(".json")).sort()) {
  const json = JSON.parse(readFileSync(src + file, "utf8"));
  for (const lang of LANGS) Object.assign(merged[lang], json[lang] || {});
}
for (const lang of LANGS) writeFileSync(`${out}${lang}.json`, JSON.stringify(merged[lang]));
console.log(`split-i18n: ${Object.keys(merged.en).length} feature keys × ${LANGS.length} languages`);
