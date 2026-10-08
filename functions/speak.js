// Shefi's voice: the assistant's reply text comes in, MP3 comes out, from
// Google Cloud Text-to-Speech. The device's own engine is the fallback in
// the app, but a natural voice (Chirp 3 HD) only exists in the cloud, and
// the key to it is this project's own service account, not anything the
// app could carry.
//
// Which voice reads each language is a Remote Config parameter
// (`tts_voice_he`, `tts_voice_en`, …), so a different voice is a console
// edit, not a deploy. The console template is cached per instance.
const { onRequest } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { GoogleAuth } = require("google-auth-library");
const proxy = require("./aiProxy").internals;
const remoteFlags = require("./remoteFlags");

const ENDPOINT = "https://texttospeech.googleapis.com/v1/text:synthesize";
const MAX_CHARS = 1500;

// The default voice per language: Google's Chirp 3 HD, which speaks all
// five. The console can swap any of them for another name from
// `GET /v1/voices?languageCode=…`.
const DEFAULT_VOICES = {
  he: "he-IL-Chirp3-HD-Aoede",
  en: "en-US-Chirp3-HD-Aoede",
  ar: "ar-XA-Chirp3-HD-Aoede",
  fr: "fr-FR-Chirp3-HD-Aoede",
  ru: "ru-RU-Chirp3-HD-Aoede",
};
const LOCALES = { he: "he-IL", en: "en-US", ar: "ar-XA", fr: "fr-FR", ru: "ru-RU" };

let auth = null;
async function accessToken() {
  auth = auth || new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/cloud-platform"] });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return typeof token === "string" ? token : token && token.token;
}

// Pure: the request, trimmed to what the API takes.
function parseRequest(body) {
  const raw = body && typeof body.text === "string" ? body.text : "";
  const text = raw.replace(/\s+/g, " ").trim().slice(0, MAX_CHARS);
  if (!text) return { error: "empty_text" };
  const lang = body && typeof body.lang === "string" ? body.lang.trim().toLowerCase().slice(0, 2) : "";
  return { text, lang: LOCALES[lang] ? lang : "en" };
}

// Pure: the voice for a language, the console's choice first. A console
// value that names a voice of another language is ignored rather than sent.
function voiceFor(parameters, lang) {
  const raw = parameters && parameters[`tts_voice_${lang}`] && parameters[`tts_voice_${lang}`].defaultValue
    ? String(parameters[`tts_voice_${lang}`].defaultValue.value || "").trim()
    : "";
  const locale = LOCALES[lang];
  const name = raw && raw.startsWith(locale) ? raw : DEFAULT_VOICES[lang];
  return { languageCode: locale, name };
}

async function synthesize({ text, lang }, { fetchImpl = fetch, token, parameters }) {
  const voice = voiceFor(parameters, lang);
  const response = await fetchImpl(ENDPOINT, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      input: { text },
      voice,
      audioConfig: { audioEncoding: "MP3", speakingRate: 1.0 },
    }),
  });
  const json = await response.json().catch(() => ({}));
  if (!response.ok) {
    const reason = json && json.error && json.error.message ? json.error.message : `HTTP ${response.status}`;
    const error = new Error(reason);
    error.status = response.status === 429 ? 429 : 502;
    throw error;
  }
  if (!json.audioContent) throw new Error("no audio in response");
  return { audio: Buffer.from(json.audioContent, "base64"), voice: voice.name };
}

exports.speak = onRequest(
  { region: "europe-west1", cors: false, maxInstances: 10, timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "Method not allowed" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    const request = parseRequest(req.body);
    if (request.error) return res.status(400).json({ error: { code: request.error, message: request.error } });
    try {
      const [token, parameters] = await Promise.all([accessToken(), remoteFlags.params()]);
      const { audio, voice } = await synthesize(request, { token, parameters });
      logger.info("spoke", { uid: caller.uid, lang: request.lang, voice, chars: request.text.length, bytes: audio.length });
      res.set("Content-Type", "audio/mpeg");
      res.set("Cache-Control", "no-store");
      return res.status(200).send(audio);
    } catch (err) {
      logger.error("speak failed", { uid: caller.uid, reason: err.message });
      return res.status(err.status || 502).json({ error: { message: "Speech failed" } });
    }
  },
);

exports.internals = { parseRequest, voiceFor, synthesize, DEFAULT_VOICES, LOCALES, MAX_CHARS };
