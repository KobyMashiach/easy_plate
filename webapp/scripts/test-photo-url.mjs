// The profile-picture filter of the website (src/lib/photoUrl.ts) and of the
// admin console (landing/admin/js/ui.js) must accept exactly what the rules'
// trustedPhotoUrl (firestore.rules) lets a document hold: this project's own
// bucket in both URL forms, and Google account photos (lhN). Needs a Node that
// strips TypeScript types (22.18+ / 23.6+); an older Node skips it.
import assert from "node:assert/strict";

let web;
try {
  web = await import("../src/lib/photoUrl.ts");
} catch (e) {
  console.warn(`test-photo-url: skipped (${e.code || e.message})`);
  process.exit(0);
}
const admin = await import("../../landing/admin/js/ui.js");

const accepted = [
  "https://firebasestorage.googleapis.com/v0/b/easy-plate.firebasestorage.app/o/profile_photos%2Fabc.jpg?alt=media&token=1",
  "https://firebasestorage.googleapis.com/v0/b/easy-plate.appspot.com/o/x.jpg",
  "https://storage.googleapis.com/easy-plate.firebasestorage.app/recipe_images/a.jpg",
  "https://lh3.googleusercontent.com/a/ACg8ocK=s96-c",
];
const refused = [
  "https://firebasestorage.googleapis.com/v0/b/other-project.appspot.com/o/x.jpg",
  "https://storage.googleapis.com/other-bucket/x.jpg",
  "https://abc-colab.googleusercontent.com/x.jpg",
  "https://lh3.googleusercontent.com.evil.example/x.jpg",
  "https://lh3.googleusercontent.com@evil.example/x.jpg",
  "http://lh3.googleusercontent.com/x.jpg",
  "https://evil.example/?u=https://lh3.googleusercontent.com/",
  "javascript:alert(1)",
  "",
  null,
  undefined,
  "https://lh3.googleusercontent.com/" + "a".repeat(2100),
];
for (const [name, f] of [["website", web.trustedPhotoUrl], ["console", admin.trustedPhotoUrl]]) {
  for (const url of accepted) assert.ok(f(url), `${name} should show ${url}`);
  for (const url of refused) assert.equal(f(url), null, `${name} should refuse ${String(url).slice(0, 80)}`);
}
console.log("test-photo-url: ok");
