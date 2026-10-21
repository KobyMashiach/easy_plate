const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const {
  ACTIONS, parseRequest, normalizeRelease, langTexts, translatePrompt, isPersona, personaUid, backdated, normalizeRecipe, portraitUrl, summarize, decodeDataUrl, sniffImage, textPrompt, dishesPrompt, threadPrompt, peoplePrompt, ORIGINS,
} = require("./adminPanel").internals;

test("an unknown action, and a missing required field, are refused before any work", () => {
  assert.equal(parseRequest({ action: "nope" }).error, "unknown action");
  assert.equal(parseRequest({}).error, "unknown action");
  assert.equal(parseRequest({ action: "user.disable" }).error, "uid is required");
  assert.equal(parseRequest({ action: "user.disable", uid: "   " }).error, "uid is required");
  assert.equal(parseRequest({ action: "forum.post.create", as: "me", title: "t" }).error, "body is required");
});

test("fields are trimmed, capped and typed; strangers are dropped", () => {
  const r = parseRequest({ action: "user.notify", uid: " u1 ", title: "x".repeat(200), body: "hello", extra: "no" });
  assert.equal(r.uid, "u1");
  assert.equal(r.title.length, 80);
  assert.equal(r.extra, undefined);
  assert.equal(parseRequest({ action: "community.seedLikes", kind: "post", postId: "p", count: "12" }).count, 12);
  assert.equal(parseRequest({ action: "community.seedLikes", kind: "post", postId: "p", count: "lots" }).error, "count must be a number");
  assert.equal(parseRequest({ action: "community.like", as: "me", kind: "thread" }).error, "kind is not one of post, reply, recipe");
  assert.equal(parseRequest({ action: "user.entitlement", uid: "u", premium: "true" }).premium, true);
  assert.equal(parseRequest({ action: "user.content.set", root: "users", rootId: "u", collection: "recipes", id: "r", data: [] }).error, "data must be an object");
  assert.equal(parseRequest({ action: "user.content.set", root: "secrets", rootId: "u", collection: "recipes", id: "r", data: {} }).error, "root is not one of users, households");
});

test("every action has a spec, and none reads the request body blindly", () => {
  for (const [name, spec] of Object.entries(ACTIONS)) {
    assert.ok(/^[a-z]+(\.[a-zA-Z]+)*$/.test(name), name);
    for (const rule of Object.values(spec)) assert.ok(["string", "number", "boolean", "object", "enum", "stringList", "objectList"].includes(rule.kind), name);
  }
});

test("a list field keeps distinct trimmed strings and refuses too many", () => {
  const ok = parseRequest({ action: "user.notifyAudience", audience: "users", uids: [" a ", "a", "b", 3, ""], body: "hi" });
  assert.deepEqual(ok.uids, ["a", "b"]);
  assert.ok(parseRequest({ action: "user.notifyAudience", audience: "users", uids: "a", body: "hi" }).error);
  assert.ok(parseRequest({ action: "user.notifyAudience", audience: "users", uids: Array.from({ length: 501 }, (_, i) => `u${i}`), body: "hi" }).error);
  assert.ok(parseRequest({ action: "user.notifyAudience", audience: "vip", body: "hi" }).error);
});

test("persona uids are marked and random", () => {
  const a = personaUid();
  const b = personaUid();
  assert.ok(isPersona(a));
  assert.ok(!isPersona("TMUEhPfI5VcYpiluym1aT23daZc2"));
  assert.notEqual(a, b);
  assert.ok(/^seed_[A-Za-z0-9]{16,20}$/.test(a), a);
});

test("a backdate stays within the last year and never in the future", () => {
  const now = 1_800_000_000_000;
  assert.equal(backdated(undefined, now), now);
  assert.equal(backdated(now + 5000, now), now);
  assert.equal(backdated(now - 1000, now), now - 1000);
  assert.equal(backdated(0, now), now - 365 * 24 * 3600 * 1000);
});

test("a recipe is reduced to the app's shape", () => {
  const { recipe, error } = normalizeRecipe({
    title: "  Shakshuka ",
    prepTimeMinutes: "10",
    cookTimeMinutes: 25.6,
    servings: 0,
    ingredients: [
      { name: "eggs", amount: 4, unit: "unit" },
      { name: "tomatoes", amount: "2.5", unit: "cups" },
      { name: "", amount: 1, unit: "cup" },
      { name: "salt" },
    ],
    steps: ["Fry", "", "  Crack eggs  ", 42],
    dietaryTags: ["vegetarian", "paleo", "vegetarian"],
    allergens: ["eggs", "nothing"],
    mayContain: [],
    nutrition: { calories: 320.4, proteinGrams: "14", carbsGrams: 9.123, fatGrams: null },
    somethingElse: true,
  });
  assert.equal(error, undefined);
  assert.equal(recipe.title, "Shakshuka");
  assert.equal(recipe.prepTimeMinutes, 10);
  assert.equal(recipe.cookTimeMinutes, 26);
  assert.equal(recipe.servings, 1);
  assert.deepEqual(recipe.ingredients, [
    { name: "eggs", amount: 4, unit: "unit" },
    { name: "tomatoes", amount: 2.5, unit: "unspecified" },
    { name: "salt", amount: null, unit: "unspecified" },
  ]);
  assert.deepEqual(recipe.steps, ["Fry", "Crack eggs"]);
  assert.deepEqual(recipe.dietaryTags, ["vegetarian"]);
  assert.deepEqual(recipe.allergens, ["eggs"]);
  assert.deepEqual(recipe.nutrition, { calories: 320, proteinGrams: 14, carbsGrams: 9.12, fatGrams: 0 });
  assert.equal(recipe.somethingElse, undefined);
  assert.equal(normalizeRecipe({ title: "x" }).error, "recipe needs ingredients or steps");
  assert.equal(normalizeRecipe({ steps: ["a"] }).error, "recipe.title is required");
  assert.equal(normalizeRecipe({ title: "x", steps: ["a"], nutrition: { proteinGrams: 3 } }).recipe.nutrition, null);
});

test("portraits come from the hundred per gender", () => {
  assert.equal(portraitUrl("male", 7), "https://randomuser.me/api/portraits/men/7.jpg");
  assert.equal(portraitUrl("female", 107), "https://randomuser.me/api/portraits/women/7.jpg");
  assert.equal(portraitUrl("female", "x"), "https://randomuser.me/api/portraits/women/0.jpg");
});

test("the audit summary keeps ids and drops pictures and bodies", () => {
  const s = summarize({ action: "persona.create", name: "Dana", photoDataUrl: "data:image/jpeg;base64,AAAA", recipe: { title: "Soup", steps: ["x"] }, image: { dataUrl: "data:..." }, body: "y".repeat(400), data: { a: 1 } });
  assert.equal(s.action, undefined);
  assert.equal(s.name, "Dana");
  assert.equal(s.photoDataUrl, "<27 chars>");
  assert.deepEqual(s.recipe, { title: "Soup" });
  assert.deepEqual(s.image, { dataUrl: "<8 chars>" });
  assert.equal(s.body.length, 301);
  assert.equal(s.data, "<object>");
});

test("data urls and magic bytes are recognised", () => {
  const png = decodeDataUrl("data:image/png;base64,iVBORw0KGgoAAAANSUhEUg==");
  assert.equal(png.contentType, "image/png");
  // The declared type is not believed: an SVG called a PNG is refused, a
  // PNG called a JPEG is stored as what it is.
  const svg = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>').toString("base64");
  assert.equal(decodeDataUrl(`data:image/png;base64,${svg}`), null);
  assert.equal(decodeDataUrl(`data:image/svg+xml;base64,${svg}`), null);
  assert.equal(decodeDataUrl("data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUg==").contentType, "image/png");
  assert.equal(decodeDataUrl("data:text/plain;base64,aGk="), null);
  assert.equal(sniffImage(Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0, 0, 0, 0, 0])), "image/jpeg");
  assert.equal(sniffImage(Buffer.from("RIFF....WEBPVP8 ")), "image/webp");
  assert.equal(sniffImage(Buffer.from("hello world!")), null);
});

test("prompts carry the language and the persona", () => {
  const p = textPrompt({ kind: "reply", lang: "he", context: "How long do I boil eggs?", persona: "Dana Levi" });
  assert.match(p, /Hebrew/);
  assert.match(p, /Dana Levi/);
  assert.match(p, /boil eggs/);
  assert.match(textPrompt({ kind: "thread", lang: "xx" }), /Hebrew/);
});

test("only our own origins may call", () => {
  assert.ok(ORIGINS.includes("https://aieasyplate.app"));
  assert.ok(!ORIGINS.some((o) => o === "*"));
});

test("the seed actions take their fields and the dish prompt carries the theme", () => {
  const r = parseRequest({ action: "recipe.seedOne", title: "Shakshuka", lang: "he", as: "random", likes: "4", createdAt: 1 });
  assert.equal(r.likes, 4);
  assert.equal(r.as, "random");
  assert.equal(parseRequest({ action: "recipe.seedOne" }).error, "title is required");
  assert.equal(parseRequest({ action: "dish.suggest", count: 12, lang: "fr", theme: "vegan" }).theme, "vegan");
  assert.match(dishesPrompt({ count: 5, lang: "ru", theme: "soups" }), /Russian[\s\S]*soups/);
});

test("names come in the language's own script, and a thread names its cast", () => {
  assert.match(peoplePrompt({ count: 3, lang: "he" }), /Hebrew letters/);
  assert.match(peoplePrompt({ count: 3, lang: "ru" }), /Cyrillic/);
  const p = threadPrompt({ lang: "he", topic: "leftovers", replies: 2, names: ["דנה", "יוסי", "מיכל"] });
  assert.match(p, /by דנה/);
  assert.match(p, /יוסי, מיכל/);
  assert.equal(parseRequest({ action: "forum.seedThread", lang: "he", replies: "3", days: 20, likes: 4 }).replies, 3);
});

test("a list of objects is typed, capped and required", () => {
  const ok = parseRequest({ action: "whatsnew.save", versionCode: "12", version: "1.2.0", features: [{ featureKey: "ff_a" }] });
  assert.equal(ok.versionCode, 12);
  assert.deepEqual(ok.features, [{ featureKey: "ff_a" }]);
  assert.equal(parseRequest({ action: "whatsnew.save", versionCode: 12, version: "1.2.0" }).error, "features is required");
  assert.equal(parseRequest({ action: "whatsnew.save", versionCode: 12, version: "1.2.0", features: [] }).error, "features is required");
  assert.equal(parseRequest({ action: "whatsnew.save", versionCode: 12, version: "1.2.0", features: ["x"] }).error, "features must be a list of objects");
  assert.ok(parseRequest({ action: "whatsnew.save", versionCode: 12, version: "1.2.0", features: Array.from({ length: 41 }, () => ({})) }).error);
  assert.equal(parseRequest({ action: "whatsnew.translate", title: "x", from: "jp" }).error, "from is not one of he, en, ar, fr, ru");
});

test("a release is reduced to the document the app reads", () => {
  const now = 1_800_000_000_000;
  const { release, error } = normalizeRelease({
    versionCode: 12,
    version: " 1.2.0 ",
    releasedAt: now + 48 * 3600 * 1000,
    isPublished: true,
    features: [
      { featureKey: "ff_b", title: { he: "ב", en: "B", jp: "no" }, description: "desc", sortOrder: 1, iconName: "timer", targetRoute: "tab:groceries", imageUrl: "https://x/y.png" },
      { featureKey: "ff_a", title: "A", sortOrder: 0 },
    ],
  }, now);
  assert.equal(error, undefined);
  assert.equal(release.version, "1.2.0");
  assert.equal(release.versionCode, 12);
  assert.equal(release.releasedAt, now, "a future date falls back to now");
  assert.equal(release.isPublished, true);
  assert.deepEqual(release.features.map((f) => f.featureKey), ["ff_a", "ff_b"]);
  assert.deepEqual(release.features[1].title, { he: "ב", en: "B" });
  assert.deepEqual(release.features[1].description, { he: "desc" });
  assert.deepEqual(release.features[0].title, { he: "A" });
  assert.equal(release.features[1].targetRoute, "tab:groceries");
  assert.equal(release.features[1].imageUrl, "https://x/y.png");
});

test("a release with a bad build, version, picture or duplicate flag is refused", () => {
  assert.ok(normalizeRelease({ versionCode: 0, version: "1.0.0", features: [] }).error);
  assert.ok(normalizeRelease({ versionCode: 1.5, version: "1.0.0", features: [] }).error);
  assert.ok(normalizeRelease({ versionCode: 3, version: "v1", features: [] }).error);
  assert.ok(normalizeRelease({ versionCode: 3, version: "1.0.0", features: [{ featureKey: "ff_a" }, { featureKey: "ff_a" }] }).error);
  assert.ok(normalizeRelease({ versionCode: 3, version: "1.0.0", features: [{ featureKey: "ff_a", imageUrl: "http://plain" }] }).error);
  assert.ok(normalizeRelease({ versionCode: 3, version: "1.0.0", features: [{ featureKey: "ff a" }] }).error);
  assert.ok(normalizeRelease({ versionCode: 3, version: "1.0.0", features: [{ featureKey: "ff_a", targetRoute: "../x" }] }).error);
  assert.equal(normalizeRelease({ versionCode: 3, version: "1.0.0", isPublished: "true", features: [] }).release.isPublished, false);
});

test("language texts keep the five languages and the source string", () => {
  assert.deepEqual(langTexts({ he: " א ", en: "", ru: "р", xx: "no" }, 10), { he: "א", ru: "р" });
  assert.deepEqual(langTexts("hello", 3, "en"), { en: "hel" });
  assert.deepEqual(langTexts(null, 3), {});
  const prompt = translatePrompt({ title: "Cook mode", description: "Hands-free steps", from: "en" });
  assert.match(prompt, /he \(Hebrew\)/);
  assert.doesNotMatch(prompt, /en \(English\)/);
  assert.match(prompt, /"Cook mode"/);
});

test("user.permission grants user, superuser or admin", () => {
  assert.equal(parseRequest({ action: "user.permission", uid: "u", permission: "superuser" }).permission, "superuser");
  assert.equal(parseRequest({ action: "user.permission", uid: "u", permission: "admin" }).permission, "admin");
  assert.ok(parseRequest({ action: "user.permission", uid: "u", permission: "boss" }).error);
});

const { isPrivateAddress, isInternalHostname, assertPublicUrl, fetchImage } = require("./adminPanel").internals;

test("addresses inside the network are recognised, in both IP versions", () => {
  for (const ip of ["127.0.0.1", "10.1.2.3", "172.16.0.9", "172.31.255.255", "192.168.1.1", "169.254.169.254", "100.64.0.1", "0.0.0.0", "224.0.0.1", "255.255.255.255", "198.18.0.1",
    "::1", "::", "fe80::1", "fc00::1", "fd12:3456::1", "::ffff:127.0.0.1", "::ffff:10.0.0.1", "64:ff9b::a00:1", "2002:7f00:1::", "ff02::1", "2001:db8::1", "not-an-ip", ""]) {
    assert.equal(isPrivateAddress(ip), true, ip);
  }
  for (const ip of ["93.184.216.34", "8.8.8.8", "172.32.0.1", "172.15.0.1", "2606:4700::6810:84e5", "::ffff:8.8.8.8", "2a00:1450:4001:80b::200e"]) {
    assert.equal(isPrivateAddress(ip), false, ip);
  }
  assert.equal(isInternalHostname("localhost"), true);
  assert.equal(isInternalHostname("metadata.google.internal"), true);
  assert.equal(isInternalHostname("printer.local"), true);
  assert.equal(isInternalHostname("example.com."), false);
});

test("an image url must be http(s) to a public address, whatever its host resolves to", async () => {
  const resolving = (addresses) => async () => addresses.map((address) => ({ address, family: address.includes(":") ? 6 : 4 }));
  const code = async (p) => p.then(() => null, (e) => e.code);
  assert.equal(await code(assertPublicUrl("ftp://example.com/a.jpg", { lookup: resolving(["1.1.1.1"]) })), "invalid_image");
  assert.equal(await code(assertPublicUrl("file:///etc/passwd")), "invalid_image");
  assert.equal(await code(assertPublicUrl("http://169.254.169.254/computeMetadata/v1/")), "forbidden_host");
  assert.equal(await code(assertPublicUrl("http://[::1]/x.png")), "forbidden_host");
  assert.equal(await code(assertPublicUrl("http://[::ffff:127.0.0.1]/x.png")), "forbidden_host");
  assert.equal(await code(assertPublicUrl("http://metadata.google.internal/x")), "forbidden_host");
  assert.equal(await code(assertPublicUrl("http://localhost:8080/x")), "forbidden_host");
  assert.equal(await code(assertPublicUrl("http://user:pw@example.com/x", { lookup: resolving(["1.1.1.1"]) })), "invalid_image");
  // A public name that resolves to a private address (DNS rebinding) is refused on any of its addresses.
  assert.equal(await code(assertPublicUrl("https://evil.example/x.jpg", { lookup: resolving(["93.184.216.34", "10.0.0.2"]) })), "forbidden_host");
  assert.equal(await code(assertPublicUrl("https://nowhere.example/x.jpg", { lookup: async () => { throw new Error("ENOTFOUND"); } })), "image_fetch");
  const ok = await assertPublicUrl("https://images.example/x.jpg", { lookup: resolving(["93.184.216.34"]) });
  assert.equal(ok.hostname, "images.example");
});

test("fetchImage checks every redirect hop rather than following blindly", async () => {
  const lookup = async () => [{ address: "93.184.216.34", family: 4 }];
  const png = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0, 0]);
  const response = (status, headers = {}, body = Buffer.alloc(0)) => ({
    status, ok: status >= 200 && status < 300, headers: new Headers(headers), arrayBuffer: async () => body,
  });
  const seen = [];
  const fetchImpl = async (url, options) => {
    seen.push({ url, redirect: options.redirect });
    if (url === "https://images.example/a") return response(302, { location: "http://169.254.169.254/computeMetadata/v1/token" });
    if (url === "https://images.example/b") return response(301, { location: "/final.png" });
    if (url === "https://images.example/final.png") return response(200, { "content-type": "image/png" }, png);
    return response(404);
  };
  await assert.rejects(fetchImage("https://images.example/a", fetchImpl, { lookup }), (e) => e.code === "forbidden_host");
  assert.ok(seen.every((s) => s.redirect === "manual"), "redirects are never followed by fetch itself");
  assert.ok(!seen.some((s) => s.url.includes("169.254")), "the metadata server is never contacted");

  const image = await fetchImage("https://images.example/b", fetchImpl, { lookup });
  assert.equal(image.contentType, "image/png");
  assert.equal(image.bytes.length, png.length);

  const loop = async (url) => response(302, { location: url });
  await assert.rejects(fetchImage("https://images.example/loop", loop, { lookup }), (e) => e.code === "image_fetch");
});

test("an explicit empty value clears a clearable field; a required one stays required", () => {
  const p = parseRequest({ action: "user.profile", uid: "u1", fullName: "", photoUrl: "  " });
  assert.equal(p.fullName, "");
  assert.equal(p.photoUrl, "");
  assert.ok(!("fullName" in parseRequest({ action: "user.profile", uid: "u1" })), "absent is still absent");
  assert.equal(parseRequest({ action: "user.profile", uid: "" }).error, "uid is required");
  assert.equal(parseRequest({ action: "stores.config", playBucket: "", appleVendor: "" }).playBucket, "");
  assert.ok(!("applePrivateKey" in parseRequest({ action: "stores.config", applePrivateKey: "" })), "an empty key never deletes the stored one");
  assert.equal(parseRequest({ action: "notify.template.save", name: "", body: "x", target: "all", schedule: {} }).name, "");
  assert.equal(parseRequest({ action: "recipe.update", id: "r1", recipe: {}, image: null }).image, null);
  assert.ok(!("image" in parseRequest({ action: "recipe.update", id: "r1", recipe: {} })));
  assert.equal(parseRequest({ action: "notify.template.save", body: "", target: "all", schedule: {} }).error, "body is required");
});

test("ids that would be a path, or a name Firestore refuses, are refused", () => {
  const { validId } = require("./adminPanel").internals;
  for (const bad of ["a/b", ".", "..", "__x__", "/"]) assert.equal(validId(bad), false, bad);
  assert.equal(validId("seed_abc"), true);
  assert.equal(parseRequest({ action: "user.delete", uid: "a/b" }).error, "uid is not a valid id");
  assert.equal(parseRequest({ action: "forum.reply.delete", postId: "p", replyId: "../x" }).error, "replyId is not a valid id");
  assert.equal(parseRequest({ action: "user.notifyAudience", audience: "users", uids: ["ok", "a/b"], body: "x" }).error, "uids holds an invalid id");
});

test("a kept recipe picture must be one of the author's own", async () => {
  const { ownedImagePath, recipeImage } = require("./adminPanel").internals;
  assert.equal(ownedImagePath("recipe_images/seed_a/x.jpg", "seed_a"), true);
  assert.equal(ownedImagePath("recipe_images/seed_b/x.jpg", "seed_a"), false);
  assert.equal(ownedImagePath("recipe_images/seed_a/../seed_b/x.jpg", "seed_a"), false);
  assert.equal(ownedImagePath("recipe_images/seed_a/", "seed_a"), false);
  assert.equal(ownedImagePath("/recipe_images/seed_a/x.jpg", "seed_a"), false);
  assert.equal(ownedImagePath("profile_photos/u1.jpg", "seed_a"), false);
  assert.deepEqual(await recipeImage({ authorUid: "seed_a", image: { storagePath: "recipe_images/seed_a/x.jpg" } }), { path: "recipe_images/seed_a/x.jpg", fileName: "x.jpg" });
  await assert.rejects(recipeImage({ authorUid: "seed_a", image: { storagePath: "profile_photos/u1.jpg" } }), (err) => err.status === 400);
});

test("a grant's end date past 2100 is refused", async () => {
  const { run, MAX_PREMIUM_UNTIL_MS } = require("./adminPanel").internals;
  const writes = [];
  const db = { doc: () => ({ set: async (d) => writes.push(d) }) };
  await assert.rejects(run({ action: "user.entitlement", uid: "u1", premium: true, premiumUntil: MAX_PREMIUM_UNTIL_MS + 1 }, { caller: { uid: "a" }, db }), (err) => err.status === 400);
  assert.equal(writes.length, 0);
});

test("an image body is read no further than the cap", async () => {
  const { readCapped } = require("./adminPanel").internals;
  const headers = (h = {}) => ({ get: (k) => h[k.toLowerCase()] ?? null });
  const stream = (chunks) => ({ async *[Symbol.asyncIterator]() { for (const c of chunks) yield c; }, cancel: async () => {} });
  const small = await readCapped({ headers: headers(), body: stream([new Uint8Array([1, 2]), new Uint8Array([3])]) }, 10);
  assert.deepEqual([...small], [1, 2, 3]);
  await assert.rejects(readCapped({ headers: headers({ "content-length": "11" }), body: stream([]) }, 10), (e) => e.code === "image_too_large");
  let pulled = 0;
  const endless = { async *[Symbol.asyncIterator]() { for (;;) { pulled++; yield new Uint8Array(4); } }, cancel: async () => {} };
  await assert.rejects(readCapped({ headers: headers(), body: endless }, 10), (e) => e.code === "image_too_large");
  assert.equal(pulled, 3);
});

test("console Remote Config group names: no prototype keys, no control characters", () => {
  const { validGroupName } = require("./adminPanel").internals;
  assert.equal(validGroupName("תשלומים"), true);
  assert.equal(validGroupName("Quotas"), true);
  for (const bad of ["__proto__", "constructor", "prototype", "", " lead", "a\nb", "x".repeat(121), 5]) assert.equal(validGroupName(bad), false, String(bad));
});

test("a profile picture set from the console is held to the hosts the rules accept", () => {
  const { trustedPhotoUrl } = require("./adminPanel").internals;
  assert.ok(trustedPhotoUrl("https://firebasestorage.googleapis.com/v0/b/easy-plate.firebasestorage.app/o/profile_photos%2Fu.jpg?alt=media&token=t"));
  assert.ok(trustedPhotoUrl("https://storage.googleapis.com/easy-plate.firebasestorage.app/profile_photos/u.jpg"));
  assert.ok(trustedPhotoUrl("https://lh3.googleusercontent.com/a/ACg8ocK=s96-c"));
  for (const bad of [
    "http://firebasestorage.googleapis.com/v0/b/x/o/p.jpg",
    "https://evil.example.com/p.jpg",
    "https://firebasestorage.googleapis.com.evil.example.com/p.jpg",
    "https://firebasestorage.googleapis.com@evil.example.com/p.jpg",
    "https://xgoogleusercontent.com/a/b",
    "https://firebasestorage.googleapis.com",
    "data:image/png;base64,AAAA",
    "https://lh3.googleusercontent.com/" + "a".repeat(2048),
    7,
    null,
  ]) assert.equal(trustedPhotoUrl(bad), false, String(bad).slice(0, 60));
});
