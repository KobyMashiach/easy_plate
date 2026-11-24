// Swear words and slurs kept out of the community (threads, replies,
// community recipes). The app and the website refuse to send them; this is
// the server's backstop for older builds and direct writes, which masks
// them with asterisks (communityModeration in index.js).
//
// Matching is by whole word, never by substring: Hebrew recipes are full of
// "כוס" (a cup) and "מזין" (nourishing), so only the unmistakable forms and
// phrases are listed. Text is normalised first — lower case, accents and
// niqqud off, look-alike digits/symbols read as letters, a letter repeated
// for emphasis read once — and letters spelled out one by one ("f u c k")
// are read together.
//
// THE SAME LISTS live in lib/core/moderation/profanity_filter.dart and
// webapp/src/lib/profanity.ts; profanity.test.js fails when they drift.

const WORDS = [
  // Hebrew
  "זונה", "זונות", "שרמוטה", "שרמוטות", "שרמוט", "אחושרמוטה", "אחושלוקי", "מניאק", "מניאקית", "מניאקים",
  "מזדיין", "מזדיינת", "מזדיינים", "תזדיין", "תזדייני", "להזדיין", "זיון", "זיונים", "זין", "זיין",
  "כוסאמק", "כוסעמק", "כוסאמא", "כוסאמאשך", "כוסומו", "חרא", "חארה", "שמוק", "קוקסינל",
  "פאק", "פאקינג", "בנזונה", "יבנזונה",
  // English
  "fuck", "fucking", "fucker", "fuckers", "fucked", "fucks", "motherfucker", "motherfucking", "fck", "fuk",
  "shit", "shitty", "bullshit", "bitch", "bitches", "cunt", "cunts", "dickhead", "asshole", "assholes",
  "bastard", "slut", "sluts", "whore", "whores", "fag", "faggot", "nigger", "nigga", "retard", "twat", "wanker",
  // Arabic
  "كس", "كسمك", "كسامك", "شرموطة", "شرموط", "منيوك", "منيك", "عرص", "زب", "نيك", "قحبة", "خول",
  // Russian
  "блять", "блядь", "бля", "сука", "суки", "хуй", "хуя", "хуйня", "пизда", "пиздец", "ебать", "ебал",
  "ебаный", "мудак", "долбоеб", "нахуй",
  // French
  "putain", "merde", "connard", "connasse", "salope", "encule", "pute", "niquer", "nique", "batard", "pede", "couilles",
];

// Several words together, matched as a run of whole words.
const PHRASES = [
  "בן זונה", "בת זונה", "יא זונה", "כוס אמק", "כוס עמק", "כוס אמא", "כוס אמא שלך", "כוס אחותך", "כוס אוחתק", "לך תזדיין",
  "son of a bitch", "piece of shit",
  "كس امك", "ابن الشرموطة",
  "fils de pute", "ta gueule",
];

const LOOKALIKE = { "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s" };

// One word or text, the way it is compared.
function normalize(text) {
  let s = String(text || "").toLowerCase();
  s = s.normalize("NFKD").replace(/[̀-ͯ]/g, ""); // é → e
  s = s.replace(/[֑-ׇ]/g, ""); // niqqud and cantillation
  s = s.replace(/[ً-ٰٟ]/g, ""); // Arabic harakat
  s = s.replace(/ё/g, "е");
  // Hebrew final letters read as their regular forms.
  s = s.replace(/ך/g, "כ").replace(/ם/g, "מ").replace(/ן/g, "נ").replace(/ף/g, "פ").replace(/ץ/g, "צ");
  s = s.replace(/[013457@$]/g, (c) => LOOKALIKE[c]);
  s = s.replace(/(\p{L})\1{2,}/gu, "$1"); // fuuuck → fuck (two in a row stay: "לפני", "cook")
  return s;
}

// The text as a list of normalised words, with letters spelled out one at
// a time ("f u c k", "f.u.c.k") joined into one word.
function tokens(text) {
  const raw = normalize(text).split(/[^\p{L}*]+/u).filter(Boolean);
  const out = [];
  let run = "";
  for (const w of raw) {
    const word = w.replace(/\*/g, "");
    if (word.length === 1) { run += word; continue; }
    if (run) { out.push(run); run = ""; }
    if (word) out.push(word);
  }
  if (run) out.push(run);
  return out;
}

const WORD_SET = new Set(WORDS.map(normalize));
const PHRASE_TOKENS = PHRASES.map((p) => tokens(p));

/// The first listed word or phrase in [text], or null.
function findProfanity(text) {
  const words = tokens(text);
  for (const w of words) if (WORD_SET.has(w)) return w;
  for (const phrase of PHRASE_TOKENS) {
    for (let i = 0; i + phrase.length <= words.length; i++) {
      if (phrase.every((p, j) => words[i + j] === p)) return phrase.join(" ");
    }
  }
  return null;
}

/// [text] with each listed word (and each word of a listed phrase) replaced
/// by asterisks of its length; the rest of the text untouched.
function maskProfanity(text) {
  const s = String(text || "");
  if (!findProfanity(s)) return s;
  const parts = s.split(/([^\p{L}\p{N}@$*]+)/u); // words and the gaps between them
  const idx = parts.map((p, i) => (i % 2 === 0 && p ? i : -1)).filter((i) => i >= 0);
  const norm = idx.map((i) => normalize(parts[i]).replace(/\*/g, ""));
  const hit = new Set();
  norm.forEach((w, k) => { if (WORD_SET.has(w)) hit.add(idx[k]); });
  for (const phrase of PHRASE_TOKENS) {
    for (let k = 0; k + phrase.length <= norm.length; k++) {
      if (phrase.every((p, j) => norm[k + j] === p)) for (let j = 0; j < phrase.length; j++) hit.add(idx[k + j]);
    }
  }
  // Letters spelled out one by one: mask every single-letter run that reads as a word.
  let start = -1;
  const flushRun = (end) => {
    if (start < 0) return;
    const run = norm.slice(start, end).join("");
    if (end - start > 1 && WORD_SET.has(run)) for (let k = start; k < end; k++) hit.add(idx[k]);
    start = -1;
  };
  norm.forEach((w, k) => { if (w.length === 1) { if (start < 0) start = k; } else flushRun(k); });
  flushRun(norm.length);
  return parts.map((p, i) => (hit.has(i) ? "*".repeat([...p].length) : p)).join("");
}

module.exports = { WORDS, PHRASES, normalize, tokens, findProfanity, maskProfanity };
