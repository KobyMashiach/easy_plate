const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const zlib = require("node:zlib");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const {
  daysBetween, decodeReport, parseCsv, parsePlayOverview, parsePlayCountries, classifyProductType, parseAppleSales,
  isPem, normalizePem, appleJwt, cleanConfig, androidConfigured, iosConfigured, totals, fetchAppleDay, syncIos, DEFAULT_PACKAGE,
} = require("./storeStats").internals;

const OVERVIEW = [
  "Date,Package Name,Daily Device Installs,Daily Device Uninstalls,Daily Device Upgrades,Total User Installs,Daily User Installs,Daily User Uninstalls,Active Device Installs,Install events,Update events,Uninstall events",
  "2026-10-01,com.KHEasyDev.easy_plate,12,1,3,540,11,1,420,13,4,1",
  "2026-10-02,com.KHEasyDev.easy_plate,20,2,0,558,18,2,436,21,0,2",
  "2026-10-02,com.other.app,99,0,0,9,9,0,9,9,0,0",
].join("\r\n");

test("a Play export is UTF-16LE with a BOM, and decodes to the same text as plain UTF-8", () => {
  const utf16 = Buffer.concat([Buffer.from([0xff, 0xfe]), Buffer.from(OVERVIEW, "utf16le")]);
  assert.equal(decodeReport(utf16), OVERVIEW);
  assert.equal(decodeReport(Buffer.from("﻿" + OVERVIEW, "utf8")), OVERVIEW);
});

test("the overview CSV becomes one entry per day for our package only", () => {
  const days = parsePlayOverview(OVERVIEW, DEFAULT_PACKAGE);
  assert.deepEqual(Object.keys(days), ["2026-10-01", "2026-10-02"]);
  assert.equal(days["2026-10-01"].installs, 11);
  assert.equal(days["2026-10-01"].deviceInstalls, 12);
  assert.equal(days["2026-10-02"].totalUserInstalls, 558);
  assert.equal(days["2026-10-02"].activeDevices, 436);
  assert.equal(days["2026-10-02"].uninstalls, 2);
  assert.equal(days["2026-10-02"].installEvents, 21);
});

test("quoted cells and a header with different names still parse", () => {
  const rows = parseCsv('a,"b,c",d\n1,"x ""y""",3\n');
  assert.deepEqual(rows, [["a", "b,c", "d"], ["1", 'x "y"', "3"]]);
  const days = parsePlayOverview("Date,Package Name,User Installs,User Uninstalls\n2026-09-30,p,7,1\n", "p");
  assert.equal(days["2026-09-30"].installs, 7);
  assert.equal(days["2026-09-30"].uninstalls, 1);
});

test("country rows are summed per day and country, zero rows dropped", () => {
  const text = [
    "Date,Package Name,Country,Daily Device Installs,Daily Device Uninstalls,Daily Device Upgrades,Total User Installs,Daily User Installs,Daily User Uninstalls,Active Device Installs",
    "2026-10-02,com.KHEasyDev.easy_plate,IL,14,0,0,400,13,0,300",
    "2026-10-02,com.KHEasyDev.easy_plate,US,5,0,0,100,5,0,90",
    "2026-10-02,com.KHEasyDev.easy_plate,FR,0,0,0,1,0,0,1",
  ].join("\n");
  assert.deepEqual(parsePlayCountries(text, DEFAULT_PACKAGE), { "2026-10-02": { IL: 13, US: 5 } });
});

test("Apple product types fall into downloads, re-downloads, updates, purchases", () => {
  assert.equal(classifyProductType("1F"), "downloads");
  assert.equal(classifyProductType("1"), "downloads");
  assert.equal(classifyProductType("1T"), "downloads");
  assert.equal(classifyProductType("1EP"), "downloads");
  assert.equal(classifyProductType("F1"), "downloads");
  assert.equal(classifyProductType("3F"), "redownloads");
  assert.equal(classifyProductType("7F"), "updates");
  assert.equal(classifyProductType("7T"), "updates");
  assert.equal(classifyProductType("IAY"), "iap");
  assert.equal(classifyProductType("FI1"), "iap");
  assert.equal(classifyProductType(""), null);
});

const SALES = [
  "Provider\tProvider Country\tSKU\tDeveloper\tTitle\tVersion\tProduct Type Identifier\tUnits\tDeveloper Proceeds\tBegin Date\tEnd Date\tCustomer Currency\tCountry Code\tCurrency of Proceeds\tApple Identifier\tCustomer Price\tPromo Code\tParent Identifier\tSubscription\tPeriod\tCategory\tCMB\tDevice\tSupported Platforms\tProceeds Reason\tPreserved Pricing\tClient\tOrder Type",
  "APPLE\tUS\tEP001\tKoby\tEasyPlate\t1.0\t1F\t7\t0\t10/02/2026\t10/02/2026\tILS\tIL\tILS\t6809243199\t0\t\t\t\t\tFood\t\tiPhone\tiOS\t\t\t\t",
  "APPLE\tUS\tEP001\tKoby\tEasyPlate\t1.0\t1F\t2\t0\t10/02/2026\t10/02/2026\tUSD\tUS\tUSD\t6809243199\t0\t\t\t\t\tFood\t\tiPad\tiOS\t\t\t\t",
  "APPLE\tUS\tEP001\tKoby\tEasyPlate\t1.0\t3F\t1\t0\t10/02/2026\t10/02/2026\tILS\tIL\tILS\t6809243199\t0\t\t\t\t\tFood\t\tiPhone\tiOS\t\t\t\t",
  "APPLE\tUS\tEP001\tKoby\tEasyPlate\t1.0\t7F\t30\t0\t10/02/2026\t10/02/2026\tILS\tIL\tILS\t6809243199\t0\t\t\t\t\tFood\t\tiPhone\tiOS\t\t\t\t",
  "APPLE\tUS\tPRO_M\tKoby\tPro monthly\t\tIAY\t1\t12\t10/02/2026\t10/02/2026\tILS\tIL\tILS\t999\t15\t\tEP001\t\t\tFood\t\tiPhone\tiOS\t\t\t\t",
  "APPLE\tUS\tOTHER\tKoby\tOther app\t1.0\t1F\t50\t0\t10/02/2026\t10/02/2026\tUSD\tUS\tUSD\t111\t0\t\t\t\t\tGames\t\tiPhone\tiOS\t\t\t\t",
].join("\n");

test("a sales report is reduced to the app's own downloads, by country and device", () => {
  const day = parseAppleSales(SALES, "6809243199");
  assert.equal(day.downloads, 9);
  assert.equal(day.redownloads, 1);
  assert.equal(day.updates, 30);
  assert.equal(day.iap, 1);
  assert.deepEqual(day.countries, { IL: 7, US: 2 });
  assert.deepEqual(day.devices, { iPhone: 7, iPad: 2 });
  // Without an app id every app on the vendor is counted.
  assert.equal(parseAppleSales(SALES, "").downloads, 59);
  assert.equal(parseAppleSales("", "6809243199").downloads, 0);
});

test("a .p8 key is recognised, with or without escaped newlines", () => {
  const { privateKey } = crypto.generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" });
  assert.ok(isPem(pem));
  assert.ok(isPem(pem.replace(/\n/g, "\\n")));
  assert.equal(normalizePem(pem.replace(/\n/g, "\\n")), pem.trim());
  assert.ok(!isPem("AuthKey_ABC123"));
  assert.ok(!isPem(""));
});

test("the App Store Connect token is an ES256 JWT Apple can verify", () => {
  const { privateKey, publicKey } = crypto.generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" });
  const token = appleJwt({ issuerId: "iss-1", keyId: "KEY123", privateKey: pem, now: 1_800_000_000_000 });
  const [h, p, s] = token.split(".");
  const header = JSON.parse(Buffer.from(h, "base64url").toString());
  const payload = JSON.parse(Buffer.from(p, "base64url").toString());
  assert.deepEqual(header, { alg: "ES256", kid: "KEY123", typ: "JWT" });
  assert.equal(payload.iss, "iss-1");
  assert.equal(payload.aud, "appstoreconnect-v1");
  assert.equal(payload.exp - payload.iat, 1200);
  assert.ok(crypto.verify("sha256", Buffer.from(`${h}.${p}`), { key: publicKey, dsaEncoding: "ieee-p1363" }, Buffer.from(s, "base64url")));
});

test("the configuration is cleaned: gs:// stripped, digits only where digits belong, defaults filled", () => {
  const c = cleanConfig({ playBucket: "gs://pubsite_prod_123/stats", appleVendor: " 8912 345 ", appleAppId: "id6809243199", iosSince: "2026-09-01", playPackage: "" });
  assert.equal(c.playBucket, "pubsite_prod_123");
  assert.equal(c.appleVendor, "8912345");
  assert.equal(c.appleAppId, "6809243199");
  assert.equal(c.playPackage, DEFAULT_PACKAGE);
  assert.equal(c.iosSince, "2026-09-01");
  assert.equal(cleanConfig({ iosSince: "yesterday" }).iosSince, "");
  assert.ok(androidConfigured(c));
  assert.ok(!iosConfigured(c, true));
  assert.ok(iosConfigured({ ...c, appleIssuerId: "i", appleKeyId: "k" }, true));
  assert.ok(!iosConfigured({ ...c, appleIssuerId: "i", appleKeyId: "k" }, false));
});

test("days between two dates are inclusive and cross a month end", () => {
  assert.deepEqual(daysBetween("2026-09-29", "2026-10-02"), ["2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02"]);
  assert.deepEqual(daysBetween("2026-10-02", "2026-10-01"), []);
});

test("cumulative totals add up the day documents", () => {
  const t = totals({ android: [{ installs: 3, uninstalls: 1 }, { installs: 4 }], ios: [{ downloads: 2, updates: 9 }, { downloads: 5, redownloads: 1, iap: 2 }] });
  assert.deepEqual(t, { android: { installs: 7, uninstalls: 1 }, ios: { downloads: 7, redownloads: 1, updates: 9, iap: 2 } });
});

function gz(text) {
  return new Response(zlib.gzipSync(Buffer.from(text)), { status: 200 });
}

test("a day Apple has no report for is a zero day, not an error; a bad key is", async () => {
  const config = cleanConfig({ appleVendor: "1", appleIssuerId: "i", appleKeyId: "k" });
  const missing = await fetchAppleDay({ config, token: "t", date: "2026-10-01", fetchImpl: async () => new Response("", { status: 404 }) });
  assert.equal(missing.downloads, 0);
  assert.equal(missing.missing, true);
  const ok = await fetchAppleDay({ config, token: "t", date: "2026-10-02", fetchImpl: async (url, init) => {
    assert.ok(url.includes("filter%5BreportDate%5D=2026-10-02"));
    assert.equal(init.headers.Authorization, "Bearer t");
    return gz(SALES);
  } });
  assert.equal(ok.downloads, 9);
  await assert.rejects(
    fetchAppleDay({ config, token: "t", date: "2026-10-02", fetchImpl: async () => new Response(JSON.stringify({ errors: [{ title: "NOT_AUTHORIZED", detail: "Authentication credentials are missing or invalid." }] }), { status: 401 }) }),
    (err) => err.code === "apple_access" && /401/.test(err.message) && /issuer id/.test(err.message),
  );
});

// A Firestore stand-in just large enough for syncIos: a days collection
// with ids, batch writes, and the summary doc.
function fakeDb(existing = []) {
  const docs = new Map(existing.map((d) => [d, { date: d, downloads: 0 }]));
  const summary = {};
  const col = {
    select: () => col,
    orderBy: () => col,
    get: async () => ({ docs: [...docs.entries()].map(([id, data]) => ({ id, data: () => data, get: (k) => data[k] })) }),
  };
  return {
    docs, summary,
    collection: () => col,
    doc: (path) => ({ set: async (data) => { if (path.endsWith("/ios")) Object.assign(summary, data); else docs.set(path.split("/").pop(), data); } }),
    batch: () => {
      const ops = [];
      return { set: (ref, data) => ops.push([ref, data]), commit: async () => { for (const [ref, data] of ops) await ref.set(data); } };
    },
  };
}

test("a sync asks only for the days not stored yet, plus the newest few", async () => {
  const { privateKey } = crypto.generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" });
  const now = Date.parse("2026-10-09T12:00:00Z");
  const config = cleanConfig({ appleVendor: "1", appleIssuerId: "i", appleKeyId: "k", iosSince: "2026-10-01" });
  const asked = [];
  const fetchImpl = async (url) => { asked.push(new URL(url).searchParams.get("filter[reportDate]")); return gz(SALES); };
  const db = fakeDb(["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-05"]);
  const result = await syncIos({ db, config, privateKey: pem, fetchImpl, now });
  assert.deepEqual(asked.sort(), ["2026-10-04", "2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08"]);
  assert.equal(result.days, 5);
  assert.equal(db.summary.days, 8);
  assert.equal(db.summary.error, null);
  assert.equal(db.docs.get("2026-10-08").downloads, 9);

  asked.length = 0;
  await syncIos({ db: fakeDb([]), config, privateKey: pem, fetchImpl, now, backfill: true });
  assert.equal(asked.length, 8);
  assert.equal(asked.sort()[0], "2026-10-01");
});

test("a failing sync keeps what it fetched and records the reason", async () => {
  const { privateKey } = crypto.generateKeyPairSync("ec", { namedCurve: "prime256v1" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" });
  const config = cleanConfig({ appleVendor: "1", appleIssuerId: "i", appleKeyId: "k", iosSince: "2026-10-06" });
  const db = fakeDb([]);
  const fetchImpl = async () => new Response("", { status: 403 });
  await assert.rejects(syncIos({ db, config, privateKey: pem, fetchImpl, now: Date.parse("2026-10-09T12:00:00Z") }), /403/);
  assert.match(db.summary.error, /403/);
});
