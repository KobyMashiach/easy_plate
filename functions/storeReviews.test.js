const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const {
  playIdFromLink, parsePlayReviewsCsv, fromPlayApi, fromApple, mergeReview, distribution, parsePlayRatings, recentMonthly, replyProblem, docId, listApple,
} = require("./storeReviews").internals;

const PKG = "com.KHEasyDev.easy_plate";
const CSV = [
  "Package Name,App Version Code,App Version Name,Reviewer Language,Device,Review Submit Date and Time,Review Submit Millis Since Epoch,Review Last Update Date and Time,Review Last Update Millis Since Epoch,Star Rating,Review Title,Review Text,Developer Reply Date and Time,Developer Reply Millis Since Epoch,Developer Reply Text,Review Link",
  `${PKG},12,1.0.7,he,a55x,2026-11-01T10:00:00Z,1761991200000,2026-11-01T10:00:00Z,1761991200000,5,,"אפליקציה מעולה, ממליץ",,,,"https://play.google.com/console/developers/1/app/2/user-feedback/review-details?reviewId=gp%3AAOqpTOabc&corpus=PUBLIC_REVIEWS"`,
  `${PKG},12,1.0.7,en,pixel8,2026-11-02T10:00:00Z,1762077600000,2026-11-02T10:00:00Z,1762077600000,4,,,,,,`,
  `com.other.app,1,1,en,x,2026-11-02T10:00:00Z,1762077600000,2026-11-02T10:00:00Z,1762077600000,1,,bad,,,,`,
].join("\n");

test("the review id is read from both forms of the Play Console link", () => {
  assert.equal(playIdFromLink("https://play.google.com/console/x/review-details?reviewId=gp%3AAOqpTOabc&corpus=1"), "gp:AOqpTOabc");
  assert.equal(playIdFromLink("https://play.google.com/apps/publisher?dev_acc=1#ReviewDetailsPlace:p=pkg&reviewid=gp:AOqpTOxyz"), "gp:AOqpTOxyz");
  assert.equal(playIdFromLink(""), "");
});

test("the reviews CSV keeps our package, star-only ratings get a stable id", () => {
  const rows = parsePlayReviewsCsv(CSV, PKG);
  assert.equal(rows.length, 2);
  assert.equal(rows[0].storeId, "gp:AOqpTOabc");
  assert.equal(rows[0].text, "אפליקציה מעולה, ממליץ");
  assert.equal(rows[0].rating, 5);
  assert.equal(rows[0].appVersion, "1.0.7");
  assert.match(rows[1].storeId, /^csv_[0-9a-f]{24}$/);
  assert.equal(parsePlayReviewsCsv(CSV, PKG)[1].storeId, rows[1].storeId);
  assert.equal(rows[1].text, "");
});

test("a Play API review keeps the reviewer's own words and the developer reply", () => {
  const r = fromPlayApi({
    reviewId: "gp:1",
    authorName: "Dana",
    comments: [
      { userComment: { text: "Great app\tgreat", originalText: "", starRating: 5, reviewerLanguage: "en", lastModified: { seconds: "1762000000", nanos: 0 }, appVersionName: "1.0.7", deviceMetadata: { manufacturer: "Samsung", productName: "a55x" }, thumbsUpCount: 2 } },
      { developerComment: { text: "Thanks!", lastModified: { seconds: "1762003600" } } },
    ],
  });
  assert.equal(r.author, "Dana");
  assert.equal(r.rating, 5);
  assert.equal(r.device, "Samsung a55x");
  assert.equal(r.createdAt, 1762000000000);
  assert.deepEqual(r.reply, { text: "Thanks!", at: 1762003600000, state: "published" });
});

test("an App Store review finds its included response", () => {
  const r = fromApple(
    { id: "abc", attributes: { rating: 2, title: "Crashes", body: "on open", reviewerNickname: "kk", createdDate: "2026-11-01T10:00:00-07:00", territory: "ISR" }, relationships: { response: { data: { type: "customerReviewResponses", id: "resp1" } } } },
    [{ type: "customerReviewResponses", id: "resp1", attributes: { responseBody: "Sorry!", lastModifiedDate: "2026-11-02T10:00:00-07:00", state: "PUBLISHED" } }],
  );
  assert.equal(r.title, "Crashes");
  assert.equal(r.country, "ISR");
  assert.equal(r.reply.text, "Sorry!");
  assert.equal(r.reply.state, "published");
  assert.equal(r.reply.responseId, "resp1");
  assert.equal(docId(r), "ios_abc");
});

test("merging: a new review with text is unread and needs a reply", () => {
  const m = mergeReview(null, { platform: "android", storeId: "gp:1", rating: 4, text: "nice", createdAt: 10, updatedAt: 10, reply: null });
  assert.equal(m.read, false);
  assert.equal(m.needsReply, true);
  assert.equal(m.answered, false);
});

test("merging: a star-only rating needs no reply", () => {
  const m = mergeReview(null, { platform: "android", storeId: "csv_1", rating: 3, text: "", createdAt: 10, updatedAt: 10, reply: null });
  assert.equal(m.needsReply, false);
});

test("merging: the CSV's older copy does not lose the API's author or the reply", () => {
  const api = mergeReview(null, { platform: "android", storeId: "gp:1", author: "Dana", rating: 5, text: "v2", createdAt: 200, updatedAt: 200, reply: { text: "Thanks", at: 250 } });
  const both = mergeReview(api, { platform: "android", storeId: "gp:1", author: "", rating: 4, text: "v1", createdAt: 100, updatedAt: 100, reply: null, link: "https://x" });
  assert.equal(both.text, "v2");
  assert.equal(both.rating, 5);
  assert.equal(both.author, "Dana");
  assert.equal(both.link, "https://x");
  assert.equal(both.createdAt, 100);
  assert.equal(both.reply.text, "Thanks");
});

test("merging: a review edited after it was answered asks for attention again", () => {
  const answered = { platform: "ios", storeId: "a", rating: 2, text: "bad", createdAt: 0, updatedAt: 0, reply: { text: "sorry", at: 1000 }, read: true };
  const edited = mergeReview(answered, { platform: "ios", storeId: "a", rating: 1, text: "still bad", createdAt: 0, updatedAt: 1000 + 3600000, reply: { text: "sorry", at: 1000 } });
  assert.equal(edited.editedAfterReply, true);
  assert.equal(edited.needsReply, true);
  assert.equal(edited.read, false);
  // The same copy again keeps the read mark the console set.
  const again = mergeReview({ ...edited, read: true }, { ...edited, read: undefined });
  assert.equal(again.read, true);
});

test("distribution counts stars, mean, texts and open replies", () => {
  const d = distribution([{ rating: 5, text: "a", needsReply: true }, { rating: 4 }, { rating: 1, title: "x" }]);
  assert.deepEqual(d.stars, { 1: 1, 2: 0, 3: 0, 4: 1, 5: 1 });
  assert.equal(d.total, 3);
  assert.equal(d.average, 3.33);
  assert.equal(d.withText, 2);
  assert.equal(d.needsReply, 1);
  assert.equal(distribution([]).average, null);
});

test("the ratings overview gives the newest total average", () => {
  const csv = "Date,Package Name,Daily Average Rating,Total Average Rating\n2026-11-01,pkg,5,4.5\n2026-11-03,pkg,NA,4.61\n2026-11-02,pkg,4,4.55";
  assert.deepEqual(parsePlayRatings(csv, "pkg"), { date: "2026-11-03", average: 4.61 });
});

test("a nightly read takes this month's and last month's files", () => {
  const files = ["reviews/reviews_p_202609.csv", "reviews/reviews_p_202610.csv", "reviews/reviews_p_202611.csv", "stats/ratings/ratings_p_202611_overview.csv"].map((name) => ({ name }));
  const now = Date.parse("2026-11-09T00:00:00Z");
  assert.deepEqual(recentMonthly(files, now).map((f) => f.name), files.slice(1).map((f) => f.name));
});

test("a reply longer than the store takes is refused before anything is sent", () => {
  assert.equal(replyProblem("android", "x".repeat(350)), null);
  assert.match(replyProblem("android", "x".repeat(351)), /350/);
  assert.equal(replyProblem("ios", "x".repeat(351)), null);
  assert.match(replyProblem("ios", "  "), /empty/);
});

test("App Store reviews are paged and the walk stops at old pages", async () => {
  const crypto = require("node:crypto");
  const { privateKey } = crypto.generateKeyPairSync("ec", { namedCurve: "P-256" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" });
  const calls = [];
  const page = (id, date, next) => ({ ok: true, status: 200, json: async () => ({ data: [{ id, attributes: { rating: 5, body: "b", createdDate: date } }], included: [], links: next ? { next } : {} }) });
  const fetchImpl = async (url) => {
    calls.push(url);
    if (calls.length === 1) return page("new", "2026-11-08T00:00:00Z", "https://next/1");
    if (calls.length === 2) return page("old", "2026-01-01T00:00:00Z", "https://next/2");
    return page("older", "2025-01-01T00:00:00Z", null);
  };
  const out = await listApple({ config: { appleIssuerId: "i", appleKeyId: "k", appleAppId: "6809243199" }, privateKey: pem, fetchImpl, stopAt: Date.parse("2026-06-01T00:00:00Z") });
  assert.deepEqual(out.map((r) => r.storeId), ["new", "old"]);
  assert.match(calls[0], /\/v1\/apps\/6809243199\/customerReviews\?sort=-createdDate/);
});
