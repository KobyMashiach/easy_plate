// Swear words and slurs kept out of the community, as in the app
// (lib/core/moderation/profanity_filter.dart). The canonical lists are in
// functions/profanity.js, which also masks what still reaches the server;
// functions/profanity.test.js fails when this copy drifts.
// Whole words only: recipes are full of "כוס" (a cup) and "מזין".

export const WORDS: string[] = [
  "זונה",
  "זונות",
  "שרמוטה",
  "שרמוטות",
  "שרמוט",
  "אחושרמוטה",
  "אחושלוקי",
  "מניאק",
  "מניאקית",
  "מניאקים",
  "מזדיין",
  "מזדיינת",
  "מזדיינים",
  "תזדיין",
  "תזדייני",
  "להזדיין",
  "זיון",
  "זיונים",
  "זין",
  "זיין",
  "כוסאמק",
  "כוסעמק",
  "כוסאמא",
  "כוסאמאשך",
  "כוסומו",
  "חרא",
  "חארה",
  "שמוק",
  "קוקסינל",
  "פאק",
  "פאקינג",
  "בנזונה",
  "יבנזונה",
  "fuck",
  "fucking",
  "fucker",
  "fuckers",
  "fucked",
  "fucks",
  "motherfucker",
  "motherfucking",
  "fck",
  "fuk",
  "shit",
  "shitty",
  "bullshit",
  "bitch",
  "bitches",
  "cunt",
  "cunts",
  "dickhead",
  "asshole",
  "assholes",
  "bastard",
  "slut",
  "sluts",
  "whore",
  "whores",
  "fag",
  "faggot",
  "nigger",
  "nigga",
  "retard",
  "twat",
  "wanker",
  "كس",
  "كسمك",
  "كسامك",
  "شرموطة",
  "شرموط",
  "منيوك",
  "منيك",
  "عرص",
  "زب",
  "نيك",
  "قحبة",
  "خول",
  "блять",
  "блядь",
  "бля",
  "сука",
  "суки",
  "хуй",
  "хуя",
  "хуйня",
  "пизда",
  "пиздец",
  "ебать",
  "ебал",
  "ебаный",
  "мудак",
  "долбоеб",
  "нахуй",
  "putain",
  "merde",
  "connard",
  "connasse",
  "salope",
  "encule",
  "pute",
  "niquer",
  "nique",
  "batard",
  "pede",
  "couilles",
];

export const PHRASES: string[] = [
  "בן זונה",
  "בת זונה",
  "יא זונה",
  "כוס אמק",
  "כוס עמק",
  "כוס אמא",
  "כוס אמא שלך",
  "כוס אחותך",
  "כוס אוחתק",
  "לך תזדיין",
  "son of a bitch",
  "piece of shit",
  "كس امك",
  "ابن الشرموطة",
  "fils de pute",
  "ta gueule",
];

const LOOKALIKE: Record<string, string> = { "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t", "@": "a", "$": "s" };

export function normalize(text: string): string {
  let s = String(text || "").toLowerCase();
  s = s.normalize("NFKD").replace(/[\u0300-\u036f]/g, "");
  s = s.replace(/[\u0591-\u05C7]/g, "").replace(/[\u064B-\u065F\u0670]/g, "").replace(/ё/g, "е");
  s = s.replace(/ך/g, "כ").replace(/ם/g, "מ").replace(/ן/g, "נ").replace(/ף/g, "פ").replace(/ץ/g, "צ");
  s = s.replace(/[013457@$]/g, (c) => LOOKALIKE[c]);
  return s.replace(/(\p{L})\1{2,}/gu, "$1");
}

export function tokens(text: string): string[] {
  const out: string[] = [];
  let run = "";
  for (const w of normalize(text).split(/[^\p{L}*]+/u).filter(Boolean)) {
    const word = w.replace(/\*/g, "");
    if ([...word].length === 1) { run += word; continue; }
    if (run) { out.push(run); run = ""; }
    if (word) out.push(word);
  }
  if (run) out.push(run);
  return out;
}

const WORD_SET = new Set(WORDS.map(normalize));
const PHRASE_TOKENS = PHRASES.map(tokens);

/** The first listed word or phrase in `text`, or null. */
export function findProfanity(text: string): string | null {
  const words = tokens(text);
  for (const w of words) if (WORD_SET.has(w)) return w;
  for (const phrase of PHRASE_TOKENS) {
    for (let i = 0; i + phrase.length <= words.length; i++) {
      if (phrase.every((p, j) => words[i + j] === p)) return phrase.join(" ");
    }
  }
  return null;
}

/** Whether any of `texts` may not be posted. */
export function hasProfanity(...texts: (string | null | undefined)[]): boolean {
  return texts.some((t) => !!t && findProfanity(t) !== null);
}
