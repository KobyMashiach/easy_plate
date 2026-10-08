const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "easy-plate";
process.env.FIREBASE_CONFIG = process.env.FIREBASE_CONFIG || JSON.stringify({ projectId: "easy-plate" });
const { parseRequest, voiceFor, synthesize, DEFAULT_VOICES, MAX_CHARS } = require("./speak").internals;

test("the request is trimmed, capped and given a known language", () => {
  assert.deepEqual(parseRequest({ text: "  שלום   עולם ", lang: "HE" }), { text: "שלום עולם", lang: "he" });
  assert.deepEqual(parseRequest({ text: "hi", lang: "de" }), { text: "hi", lang: "en" });
  assert.deepEqual(parseRequest({ text: "hi" }), { text: "hi", lang: "en" });
  assert.equal(parseRequest({ text: "   " }).error, "empty_text");
  assert.equal(parseRequest(null).error, "empty_text");
  assert.equal(parseRequest({ text: "x".repeat(MAX_CHARS + 50) }).text.length, MAX_CHARS);
});

test("the console picks the voice, within the language; otherwise the default", () => {
  assert.deepEqual(voiceFor({}, "he"), { languageCode: "he-IL", name: DEFAULT_VOICES.he });
  assert.deepEqual(voiceFor({ tts_voice_he: { defaultValue: { value: "he-IL-Wavenet-B" } } }, "he"), { languageCode: "he-IL", name: "he-IL-Wavenet-B" });
  // A voice of another language, or blank, is not sent.
  assert.deepEqual(voiceFor({ tts_voice_he: { defaultValue: { value: "en-US-Wavenet-A" } } }, "he"), { languageCode: "he-IL", name: DEFAULT_VOICES.he });
  assert.deepEqual(voiceFor({ tts_voice_fr: { defaultValue: { value: "" } } }, "fr"), { languageCode: "fr-FR", name: DEFAULT_VOICES.fr });
});

test("synthesize posts the text and the voice and decodes the audio", async () => {
  let seen;
  const fetchImpl = async (url, init) => {
    seen = { url, init };
    return { ok: true, status: 200, json: async () => ({ audioContent: Buffer.from("mp3!").toString("base64") }) };
  };
  const out = await synthesize({ text: "שלום", lang: "he" }, { fetchImpl, token: "T", parameters: {} });
  assert.equal(out.audio.toString(), "mp3!");
  assert.equal(out.voice, DEFAULT_VOICES.he);
  assert.equal(seen.init.headers.Authorization, "Bearer T");
  const body = JSON.parse(seen.init.body);
  assert.equal(body.input.text, "שלום");
  assert.equal(body.voice.languageCode, "he-IL");
  assert.equal(body.audioConfig.audioEncoding, "MP3");
});

test("a refusal from Google surfaces with its status", async () => {
  const fetchImpl = async () => ({ ok: false, status: 429, json: async () => ({ error: { message: "Quota" } }) });
  await assert.rejects(
    synthesize({ text: "x", lang: "en" }, { fetchImpl, token: "T", parameters: {} }),
    (err) => err.status === 429 && err.message === "Quota",
  );
});
