const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG =
  process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });

const { extractUsage, kindOf, modelKey } = require("./aiUsage");

test("reads the Interactions API usage block", () => {
  const u = extractUsage({
    usage: { input_tokens: 1200, output_tokens: 300, thoughts_tokens: 50, total_tokens: 1550 },
  });
  assert.deepEqual(
    { input: u.input, output: u.output, thoughts: u.thoughts, cached: u.cached, total: u.total },
    { input: 1200, output: 300, thoughts: 50, cached: 0, total: 1550 },
  );
  assert.equal(u.raw.input_tokens, 1200);
});

test("reads generateContent usageMetadata", () => {
  const u = extractUsage({
    usageMetadata: {
      promptTokenCount: 9000,
      candidatesTokenCount: 400,
      thoughtsTokenCount: 120,
      cachedContentTokenCount: 800,
      totalTokenCount: 9520,
    },
  });
  assert.equal(u.input, 9000);
  assert.equal(u.output, 400);
  assert.equal(u.thoughts, 120);
  assert.equal(u.cached, 800);
  assert.equal(u.total, 9520);
});

test("reads the Interactions API as it really answers", () => {
  const u = extractUsage({
    usage: {
      total_input_tokens: 133,
      total_output_tokens: 1567,
      total_thought_tokens: 0,
      total_cached_tokens: 0,
      total_tokens: 1700,
      total_tool_use_tokens: 0,
      input_tokens_by_modality: [{ modality: "text", tokens: 133 }],
      output_tokens_by_modality: [{ modality: "image", tokens: 1120 }],
      raw_prompt_token: 575,
      model_invocation_token_counts: [
        { prompt_tokens_details: [{ modality: "text", tokens: 575 }], candidates_tokens_details: [{ modality: "text", tokens: 449 }] },
      ],
      grounding_tool_count: [{ type: "google_search", count: 2, search_query_count: 2 }],
    },
  });
  assert.equal(u.input, 133);
  assert.equal(u.output, 1567);
  assert.equal(u.total, 1700);
  assert.equal(u.imageOutput, 1120);
  assert.equal(u.searches, 2);
});

test("a missing total is the sum of the parts", () => {
  const u = extractUsage({ usage: { input_tokens: 10, output_tokens: 5 } });
  assert.equal(u.total, 15);
});

test("an answer without usage yields null, not zeros", () => {
  assert.equal(extractUsage({ steps: [] }), null);
  assert.equal(extractUsage(null), null);
  assert.equal(extractUsage("text"), null);
});

test("the feature header names the kind", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-feature": "receipt" } }), "receipt");
});

test("a bad feature header is ignored", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-feature": "<script>" }, body: {} }), "text");
});

test("without a feature header the cache kind, tools or model decide", () => {
  assert.equal(kindOf({ headers: { "x-easyplate-source-kind": "url" } }), "url");
  assert.equal(kindOf({ headers: {}, body: { tools: [{ google_search: {} }] } }), "search");
  assert.equal(kindOf({ headers: {}, body: { model: "gemini-3.1-flash-image" } }), "image");
  assert.equal(kindOf({ headers: {}, body: { model: "gemini-3.8-flash" } }), "text");
  assert.equal(kindOf({ fn: "socialRecipe", headers: {} }), "social_video");
});

test("model keys are safe Firestore field names", () => {
  assert.equal(modelKey("gemini-3.8-flash"), "gemini-3_8-flash");
  assert.equal(modelKey(""), "unknown");
  assert.equal(modelKey(undefined), "unknown");
});
