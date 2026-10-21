// Proves the emulator mode cannot ship: runs the production build (same
// config as `npm run build`, but into a temporary folder so landing/app is
// left alone) WITH VITE_EMULATORS=1 set, then fails if any emulator trace —
// host, port, demo project, the preview hook or the local flags file — is in
// the output.
//
//   npm run preview:check-build
import { spawnSync } from "node:child_process";
import { mkdtempSync, readdirSync, readFileSync, rmSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const webapp = fileURLToPath(new URL("../../", import.meta.url));
const out = mkdtempSync(join(tmpdir(), "easyplate-build-check-"));
const run = spawnSync("npx", ["vite", "build", "--outDir", out, "--emptyOutDir", "--logLevel", "warn"], {
  cwd: webapp,
  stdio: "inherit",
  env: { ...process.env, VITE_EMULATORS: "1" },
});
if (run.status !== 0) process.exit(run.status ?? 1);

// (The SDK itself carries the words "connectFirestoreEmulator" in a warning
// string even in the shipped bundle, so function names are not needles.)
const NEEDLES = ["127.0.0.1", "localhost:", ":9299", ":9399", ":8288", ":5299", "demo-easyplate", "demo-key", "__easyplatePreview", "remote-config.json", "127.0.0.1:"];
const files = [];
const walk = (d) => readdirSync(d).forEach((f) => (statSync(join(d, f)).isDirectory() ? walk(join(d, f)) : files.push(join(d, f))));
walk(out);
let bad = 0;
for (const f of files.filter((f) => /\.(js|html|css|json)$/.test(f))) {
  const text = readFileSync(f, "utf8");
  for (const n of NEEDLES) {
    if (text.includes(n)) {
      console.error(`FOUND ${JSON.stringify(n)} in ${f.slice(out.length + 1)}`);
      bad++;
    }
  }
}
rmSync(out, { recursive: true, force: true });
if (bad) {
  console.error(`check-build: ${bad} emulator trace(s) in the production bundle`);
  process.exit(1);
}
console.log(`check-build: OK — ${files.length} files, no emulator host strings (built with VITE_EMULATORS=1)`);
