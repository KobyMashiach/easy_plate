// The WhatsApp grocery bot: a person writes "חלב, 2 כיכרות לחם ושמן זית"
// to EasyPlate's WhatsApp number and the lines land on their grocery list.
//
// Two endpoints:
//   whatsappWebhook  — Meta's WhatsApp Cloud API calls it. GET is the one-time
//                      verification handshake, POST carries incoming messages.
//   whatsappLink     — the app (Firebase ID token): status / code / setList /
//                      unlink.
//
// Linking a number never trusts a number the user typed. The app asks for a
// six-digit code, the user sends that code to the bot from WhatsApp, and
// Meta's `from` field — which WhatsApp itself vouches for — is what gets
// linked. So nobody can attach someone else's number to their account.
//
// Data (all server-written; the rules lock the users-document fields):
//   users/{uid}                 whatsapp_phone_number, whatsapp_link_code,
//                               whatsapp_link_code_expires_at,
//                               whatsapp_monthly_usage {month, message_count},
//                               whatsapp_list_id, whatsapp_linked_at,
//                               is_premium (a mirror for display only — the
//                               decision always reads entitlements/{uid})
//   whatsapp_numbers/{e164}     {uid, linkedAt} — the reverse index, one
//                               account per number
//   whatsapp_link_codes/{code}  {uid, expiresAt}
//   whatsapp_inbound/{wamid}    one row per delivered message, so Meta's
//                               retries never add the same lines twice
//   whatsapp_attempts/{e164}    wrong-code counter for an unlinked number
//
// Feature flag ff_whatsapp_bot: 2 everyone, 3 Premium only, anything else
// closed — except for a superuser / administrator (permissions.hasAllFeatures),
// the same bypass the app applies.
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("node:crypto");

const proxy = require("./aiProxy").internals;
const aiUsage = require("./aiUsage");
const remoteFlags = require("./remoteFlags");
const permissions = require("./permissions");
const { ORIGINS } = require("./origins");

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const whatsappToken = defineSecret("WHATSAPP_TOKEN");
const verifyToken = defineSecret("WHATSAPP_VERIFY_TOKEN");
const appSecret = defineSecret("WHATSAPP_APP_SECRET");
const phoneNumberId = defineString("WHATSAPP_PHONE_NUMBER_ID", { default: "" });
// The bot's own number, digits only (e.g. 972501234567), for the app's
// click-to-chat link. Not a secret.
const botNumber = defineString("WHATSAPP_BOT_NUMBER", { default: "" });

const FLAG = "ff_whatsapp_bot";
// Closed when the console gave nothing: the feature ships dark.
const FLAG_FALLBACK = 0;
const FREE_QUOTA_PARAM = "quota_whatsapp_free_monthly";
const FREE_QUOTA_FALLBACK = 10;
// Premium is generous but not unlimited: each message is a model call.
const PREMIUM_QUOTA_PARAM = "quota_whatsapp_premium_monthly";
const PREMIUM_QUOTA_FALLBACK = 300;

const MODEL = "gemini-3.8-flash";
const GRAPH_API = "https://graph.facebook.com/v23.0";
const CODE_TTL_MS = 15 * 60 * 1000;
const MAX_WRONG_CODES = 5;
const WRONG_CODE_WINDOW_MS = 60 * 60 * 1000;
const MAX_TEXT = 1000;
const MAX_ITEMS = 40;
const MODEL_TIMEOUT_MS = 20 * 1000;
const SEND_TIMEOUT_MS = 10 * 1000;
const TIME_ZONE = "Asia/Jerusalem";
const DEFAULT_CATEGORY = "כללי";
const UPGRADE_URL = "https://aieasyplate.app/upgrade";
const LIST_URL = "https://aieasyplate.app/list";

// ---------------------------------------------------------------------------
// Pure helpers (exported for tests)

/// "972501234567" (Meta's wa_id) or "+972 50-123-4567" → "+972501234567";
/// null when it is not a plausible E.164 number.
function toE164(raw) {
  const digits = String(raw || "").replace(/[^\d]/g, "");
  if (digits.length < 8 || digits.length > 15 || digits.startsWith("0")) return null;
  return `+${digits}`;
}

/// "YYYY-MM" in Israel time, the month the counter belongs to.
function monthKey(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-CA", { timeZone: TIME_ZONE, year: "numeric", month: "2-digit" }).formatToParts(date);
  const y = parts.find((p) => p.type === "year").value;
  const m = parts.find((p) => p.type === "month").value;
  return `${y}-${m}`;
}

/// The count that applies this month: a stored month that is not this one
/// starts again at zero.
function usedThisMonth(usage, month) {
  if (!usage || typeof usage !== "object" || usage.month !== month) return 0;
  const n = Number(usage.message_count);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0;
}

/// A message that is (mostly) a six-digit code: "123456", "קוד 123456",
/// "EasyPlate code: 123 456". Longer texts with a number in them are lists.
function extractCode(text) {
  const t = String(text || "").trim();
  if (t.length > 60) return null;
  const compact = t.replace(/(\d)[\s-](?=\d)/g, "$1");
  const m = compact.match(/(?:^|\D)(\d{6})(?:\D|$)/);
  if (!m) return null;
  // Whatever is left besides the code must be a few words at most.
  const rest = compact.replace(m[1], "").replace(/[^\p{L}]/gu, "");
  return rest.length <= 30 ? m[1] : null;
}

function newCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, "0");
}

/// The app's language enum names → the bot's language code.
const LANGS = { hebrew: "he", english: "en", arabic: "ar", french: "fr", russian: "ru" };
function langOfPreference(value) {
  return LANGS[value] || "he";
}

/// A best guess for a number that is not linked yet: the script it writes in.
function langOfText(text) {
  const t = String(text || "");
  if (/[֐-׿]/.test(t)) return "he";
  if (/[؀-ۿ]/.test(t)) return "ar";
  if (/[Ѐ-ӿ]/.test(t)) return "ru";
  if (/[àâçéèêëîïôûùüÿœæ]/i.test(t)) return "fr";
  if (/[a-z]/i.test(t)) return "en";
  return "he";
}

// Free-text units → the app's MeasurementUnit names. Anything else (a
// bottle, a pack, a loaf) is a counted unit, its word kept in the name.
const UNIT_WORDS = {
  gram: ["g", "gr", "gram", "grams", "גרם", "ג", "ג׳", "غرام", "غ", "г", "грамм", "gramme", "grammes"],
  kilogram: ["kg", "kilo", "kilos", "kilogram", "kilograms", "קילו", "ק\"ג", "קג", "كيلو", "كغ", "кг", "килограмм", "kilogramme"],
  milliliter: ["ml", "milliliter", "millilitre", "מ\"ל", "מל", "מיליליטר", "مل", "мл", "millilitre"],
  liter: ["l", "lt", "liter", "litre", "liters", "litres", "ליטר", "ל׳", "لتر", "л", "литр"],
  teaspoon: ["tsp", "teaspoon", "כפית", "כפיות", "ملعقة صغيرة", "ч.л.", "чайная ложка", "cuillère à café", "c. à c."],
  tablespoon: ["tbsp", "tablespoon", "כף", "כפות", "ملعقة كبيرة", "ст.л.", "столовая ложка", "cuillère à soupe", "c. à s."],
  cup: ["cup", "cups", "כוס", "כוסות", "كوب", "стакан", "tasse", "tasses"],
  pinch: ["pinch", "קורט", "רשה", "رشة", "щепотка", "pincée"],
  unit: ["", "unit", "units", "pc", "pcs", "piece", "pieces", "יחידה", "יחידות", "יח׳", "יח", "حبة", "شطر", "шт", "штука", "штуки", "pièce", "pièces"],
};
const UNIT_INDEX = (() => {
  const map = new Map();
  for (const [unit, words] of Object.entries(UNIT_WORDS)) for (const w of words) map.set(w.toLowerCase(), unit);
  return map;
})();

function unitFor(word) {
  const key = String(word || "").trim().toLowerCase();
  return UNIT_INDEX.get(key) || null;
}

/// The model's rows → clean lines: a name, a positive amount, the app's
/// unit, and the original unit word for the reply.
function cleanItems(rows) {
  if (!Array.isArray(rows)) return [];
  const out = [];
  for (const row of rows) {
    if (!row || typeof row !== "object") continue;
    const item = String(row.item || "").replace(/\s+/g, " ").trim().slice(0, 80);
    if (!item) continue;
    let amount = Number(row.amount);
    if (!Number.isFinite(amount) || amount <= 0) amount = 1;
    amount = Math.min(Math.round(amount * 100) / 100, 9999);
    const word = String(row.unit || "").replace(/\s+/g, " ").trim().slice(0, 24);
    const unit = unitFor(word);
    // A packaging word the app has no unit for stays visible in the name.
    const name = unit === null && word ? `${item} (${word})` : item;
    out.push({ item, name, amount, unit: unit || "unit", word });
    if (out.length >= MAX_ITEMS) break;
  }
  return out;
}

const sameName = (a, b) => String(a).trim().toLowerCase() === String(b).trim().toLowerCase();

/// Adds [wanted] to a list's items the way the app's quick add does: the
/// same name and unit gets one more source (and is unticked), anything else
/// is a new hand-added line.
function mergeItems(items, wanted, makeId = () => crypto.randomUUID()) {
  const out = Array.isArray(items) ? items.map((i) => ({ ...i })) : [];
  for (const w of wanted) {
    const at = out.findIndex((i) => sameName(i.name, w.name) && i.unit === w.unit);
    const source = { recipeId: null, label: w.name, amount: w.amount };
    if (at >= 0) {
      out[at] = { ...out[at], isChecked: false, sources: [...(out[at].sources || []), source] };
    } else {
      out.push({ id: makeId(), name: w.name, unit: w.unit, sources: [source], isChecked: false, category: DEFAULT_CATEGORY, isAdHoc: true });
    }
  }
  return out;
}

/// The app's save rule: stamped with the language it is written in, and
/// contentVersion moves on when the words changed.
function stamp(next, previous, lang) {
  const words = (l) => [l.name, ...(l.items || []).map((i) => i.name)].join("\n");
  const edited = previous === null || words(previous) !== words(next);
  if (!edited && next.contentLang) return next;
  const prevVersion = previous && Number.isInteger(previous.contentVersion) ? previous.contentVersion : 0;
  return { ...next, contentLang: lang, contentVersion: edited && previous !== null ? prevVersion + 1 : (next.contentVersion || 0) };
}

/// A new manual list, every key of GroceryListModel present.
function newList(id, name, lang, now = new Date()) {
  return {
    id, name, items: [], collaborators: {}, createdAt: now.toISOString(), selectedPlanIds: [],
    contentLang: lang, contentVersion: 0, source: "manual", recipeId: null, recipeScale: 1.0,
    recipeServings: null, recipeTitle: null, collabId: null, collabRole: null,
  };
}

/// A list the bot may write to: its own (not a shared copy, whose real
/// content lives in collab_containers), and not read-only.
function writable(list) {
  return !!list && typeof list === "object" && !list.collabId && list.collabRole !== "viewer" && Array.isArray(list.items);
}

const fmtAmount = (n) => (Number.isInteger(n) ? String(n) : String(Math.round(n * 100) / 100));

const RLM = "‏";
const rtl = (lang) => lang === "he" || lang === "ar";

/// One line of the confirmation, in the user's own words: "1 בקבוק שמן זית".
function lineFor(w, lang) {
  const parts = [fmtAmount(w.amount), w.word, w.item].filter(Boolean);
  return `${rtl(lang) ? RLM : ""}• ${parts.join(" ")}`;
}

// Every reply, in the five app languages. Hebrew and Arabic lines start
// with a right-to-left mark so WhatsApp lays them out right to left even
// when a line opens with a number or a link.
const TEXT = {
  he: {
    notLinked: `היי! 👋 זה הבוט של EasyPlate לרשימת הקניות.\nהמספר הזה עוד לא מחובר לחשבון.\nכדי לחבר: באפליקציה פתחו הגדרות ← "חיבור לוואטסאפ", וקבלו קוד בן 6 ספרות — ואז שלחו אותו לכאן.`,
    linked: "מעולה, המספר חובר לחשבון EasyPlate שלך ✅\nמעכשיו פשוט כתבו לי מה לקנות, למשל: \"חלב, 2 כיכרות לחם ושמן זית\".",
    badCode: "הקוד לא תקין או שפג תוקפו. צרו קוד חדש באפליקציה (הגדרות ← \"חיבור לוואטסאפ\") ושלחו אותו שוב.",
    tooMany: "יותר מדי ניסיונות קוד. נסו שוב בעוד שעה.",
    takenNumber: "המספר הזה כבר מחובר לחשבון אחר. נתקו אותו קודם מהחשבון ההוא באפליקציה.",
    quota: (limit) => `הגעת למגבלת ${limit} ההודעות החודשיות במסלול החינמי של EasyPlate 🛒🔒. כדי להמשיך להוסיף מצרכים ישירות מהוואטסאפ, שדרג למנוי פרימיום: ${UPGRADE_URL}`,
    premiumQuota: (limit) => `הגעת ל-${limit} הודעות החודש — המכסה החודשית של מנוי הפרימיום. אפשר להמשיך להוסיף מצרכים באפליקציה, והמונה מתאפס בתחילת החודש הבא.`,
    premiumOnly: `הוספה מהוואטסאפ זמינה כרגע למנויי פרימיום בלבד 🔒. לשדרוג: ${UPGRADE_URL}`,
    unavailable: "הבוט לא זמין כרגע. אפשר להמשיך להוסיף מצרכים באפליקציה.",
    added: (lines) => `הוספתי לרשימת הקניות שלך ב-EasyPlate:\n${lines}\n\n${RLM}לצפייה וסימון בסופר: ${LIST_URL}`,
    nothing: "לא מצאתי מצרכים בהודעה 🤔 נסו למשל: \"חלב, 2 כיכרות לחם ושמן זית\". ההודעה הזו לא נספרה במכסה.",
    onlyText: "כרגע אני מבין רק הודעות טקסט. כתבו לי את המצרכים במילים 🙂",
    error: "משהו השתבש ולא הצלחתי להוסיף את המצרכים. נסו שוב בעוד רגע — ההודעה הזו לא נספרה במכסה.",
    listName: "קניות מוואטסאפ",
  },
  en: {
    notLinked: `Hi! 👋 This is EasyPlate's grocery bot.\nThis number isn't linked to an account yet.\nTo link it: in the app open Settings → "Connect WhatsApp", get a 6-digit code, and send it here.`,
    linked: "Great, this number is now linked to your EasyPlate account ✅\nFrom now on just tell me what to buy, e.g. \"milk, 2 loaves of bread and olive oil\".",
    badCode: "That code is wrong or has expired. Create a new one in the app (Settings → \"Connect WhatsApp\") and send it again.",
    tooMany: "Too many code attempts. Please try again in an hour.",
    takenNumber: "This number is already linked to another account. Unlink it from that account in the app first.",
    quota: (limit) => `You've reached the ${limit} monthly messages of EasyPlate's free plan 🛒🔒. To keep adding groceries straight from WhatsApp, upgrade to Premium: ${UPGRADE_URL}`,
    premiumQuota: (limit) => `You've sent ${limit} messages this month — Premium's monthly allowance. You can keep adding items in the app; the counter resets at the start of next month.`,
    premiumOnly: `Adding from WhatsApp is currently for Premium members only 🔒. Upgrade: ${UPGRADE_URL}`,
    unavailable: "The bot isn't available right now. You can keep adding items in the app.",
    added: (lines) => `Added to your EasyPlate grocery list:\n${lines}\n\nView and tick off at the store: ${LIST_URL}`,
    nothing: "I couldn't find any groceries in that message 🤔 Try e.g. \"milk, 2 loaves of bread and olive oil\". This message wasn't counted.",
    onlyText: "For now I only understand text messages. Type the groceries in words 🙂",
    error: "Something went wrong and I couldn't add the items. Please try again in a moment — this message wasn't counted.",
    listName: "From WhatsApp",
  },
  ar: {
    notLinked: `مرحبًا! 👋 هذا بوت قائمة المشتريات من EasyPlate.\nهذا الرقم غير مرتبط بحساب بعد.\nللربط: افتح في التطبيق الإعدادات ← "الربط مع واتساب"، واحصل على رمز من 6 أرقام ثم أرسله هنا.`,
    linked: "ممتاز، تم ربط هذا الرقم بحسابك في EasyPlate ✅\nمن الآن اكتب لي ما تريد شراءه، مثلًا: \"حليب، رغيفا خبز وزيت زيتون\".",
    badCode: "الرمز غير صحيح أو انتهت صلاحيته. أنشئ رمزًا جديدًا في التطبيق (الإعدادات ← \"الربط مع واتساب\") وأرسله مرة أخرى.",
    tooMany: "محاولات كثيرة جدًا. حاول مرة أخرى بعد ساعة.",
    takenNumber: "هذا الرقم مرتبط بحساب آخر. افصله عن ذلك الحساب في التطبيق أولًا.",
    quota: (limit) => `وصلت إلى حد ${limit} رسائل شهريًا في الخطة المجانية من EasyPlate 🛒🔒. لمواصلة إضافة المشتريات من واتساب، اشترك في Premium: ${UPGRADE_URL}`,
    premiumQuota: (limit) => `أرسلت ${limit} رسالة هذا الشهر — الحصة الشهرية لاشتراك Premium. يمكنك الاستمرار في الإضافة من التطبيق، ويُعاد العداد في بداية الشهر القادم.`,
    premiumOnly: `الإضافة من واتساب متاحة حاليًا لمشتركي Premium فقط 🔒. للترقية: ${UPGRADE_URL}`,
    unavailable: "البوت غير متاح حاليًا. يمكنك الاستمرار في الإضافة من التطبيق.",
    added: (lines) => `أضفت إلى قائمة مشترياتك في EasyPlate:\n${lines}\n\n${RLM}للعرض والتأشير في السوق: ${LIST_URL}`,
    nothing: "لم أجد مشتريات في الرسالة 🤔 جرّب مثلًا: \"حليب، رغيفا خبز وزيت زيتون\". لم تُحتسب هذه الرسالة.",
    onlyText: "أفهم الرسائل النصية فقط حاليًا. اكتب المشتريات بالكلمات 🙂",
    error: "حدث خطأ ولم أتمكن من إضافة المشتريات. حاول مرة أخرى بعد قليل — لم تُحتسب هذه الرسالة.",
    listName: "من واتساب",
  },
  fr: {
    notLinked: `Bonjour ! 👋 Ici le bot de liste de courses d'EasyPlate.\nCe numéro n'est pas encore lié à un compte.\nPour le lier : dans l'app, ouvrez Réglages → « Connecter WhatsApp », obtenez un code à 6 chiffres et envoyez-le ici.`,
    linked: "Parfait, ce numéro est lié à votre compte EasyPlate ✅\nDésormais, écrivez-moi simplement ce qu'il faut acheter, par ex. « lait, 2 baguettes et huile d'olive ».",
    badCode: "Ce code est incorrect ou a expiré. Créez-en un nouveau dans l'app (Réglages → « Connecter WhatsApp ») et renvoyez-le.",
    tooMany: "Trop de tentatives. Réessayez dans une heure.",
    takenNumber: "Ce numéro est déjà lié à un autre compte. Déliez-le d'abord de ce compte dans l'app.",
    quota: (limit) => `Vous avez atteint les ${limit} messages mensuels de l'offre gratuite d'EasyPlate 🛒🔒. Pour continuer à ajouter des courses depuis WhatsApp, passez à Premium : ${UPGRADE_URL}`,
    premiumQuota: (limit) => `Vous avez envoyé ${limit} messages ce mois-ci — l'allocation mensuelle de Premium. Vous pouvez continuer dans l'app ; le compteur repart à zéro le mois prochain.`,
    premiumOnly: `L'ajout depuis WhatsApp est pour l'instant réservé aux abonnés Premium 🔒. Passer à Premium : ${UPGRADE_URL}`,
    unavailable: "Le bot n'est pas disponible pour le moment. Vous pouvez continuer dans l'app.",
    added: (lines) => `Ajouté à votre liste de courses EasyPlate :\n${lines}\n\nPour voir et cocher au magasin : ${LIST_URL}`,
    nothing: "Je n'ai trouvé aucune course dans ce message 🤔 Essayez par ex. « lait, 2 baguettes et huile d'olive ». Ce message n'a pas été compté.",
    onlyText: "Pour l'instant je ne comprends que les messages texte. Écrivez les courses en toutes lettres 🙂",
    error: "Un problème est survenu et je n'ai pas pu ajouter les articles. Réessayez dans un instant — ce message n'a pas été compté.",
    listName: "Depuis WhatsApp",
  },
  ru: {
    notLinked: `Привет! 👋 Это бот списка покупок EasyPlate.\nЭтот номер ещё не привязан к аккаунту.\nЧтобы привязать: в приложении откройте Настройки → «Подключить WhatsApp», получите 6-значный код и отправьте его сюда.`,
    linked: "Отлично, номер привязан к вашему аккаунту EasyPlate ✅\nТеперь просто пишите, что купить, например: «молоко, 2 батона и оливковое масло».",
    badCode: "Код неверный или устарел. Создайте новый в приложении (Настройки → «Подключить WhatsApp») и отправьте снова.",
    tooMany: "Слишком много попыток. Попробуйте через час.",
    takenNumber: "Этот номер уже привязан к другому аккаунту. Сначала отвяжите его там в приложении.",
    quota: (limit) => `Вы исчерпали ${limit} сообщений в месяц бесплатного тарифа EasyPlate 🛒🔒. Чтобы и дальше добавлять покупки из WhatsApp, оформите Premium: ${UPGRADE_URL}`,
    premiumQuota: (limit) => `В этом месяце отправлено ${limit} сообщений — месячный лимит Premium. Добавлять можно в приложении; счётчик обнулится в начале следующего месяца.`,
    premiumOnly: `Добавление из WhatsApp сейчас доступно только подписчикам Premium 🔒. Оформить: ${UPGRADE_URL}`,
    unavailable: "Бот сейчас недоступен. Добавлять покупки можно в приложении.",
    added: (lines) => `Добавил в ваш список покупок EasyPlate:\n${lines}\n\nСмотреть и отмечать в магазине: ${LIST_URL}`,
    nothing: "Не нашёл покупок в сообщении 🤔 Попробуйте: «молоко, 2 батона и оливковое масло». Это сообщение не засчитано.",
    onlyText: "Пока я понимаю только текстовые сообщения. Напишите покупки словами 🙂",
    error: "Что-то пошло не так, и я не смог добавить покупки. Попробуйте чуть позже — это сообщение не засчитано.",
    listName: "Из WhatsApp",
  },
};

function text(lang) {
  return TEXT[lang] || TEXT.he;
}

/// A whole reply with every line marked right-to-left for he / ar.
function directional(body, lang) {
  if (!rtl(lang)) return body;
  return body.split("\n").map((l) => (l && !l.startsWith(RLM) ? RLM + l : l)).join("\n");
}

/// The webhook's X-Hub-Signature-256 against the raw body.
function signatureValid(rawBody, header, secret) {
  if (!secret || !rawBody || typeof header !== "string" || !header.startsWith("sha256=")) return false;
  const expected = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
  const given = header.slice("sha256=".length);
  if (given.length !== expected.length) return false;
  return crypto.timingSafeEqual(Buffer.from(given, "hex"), Buffer.from(expected, "hex"));
}

/// Every incoming message in a webhook body (statuses and other changes skipped).
function messagesIn(body) {
  const out = [];
  for (const entry of (body && body.entry) || []) {
    for (const change of entry.changes || []) {
      if (change.field !== "messages") continue;
      for (const m of (change.value && change.value.messages) || []) out.push(m);
    }
  }
  return out;
}

/// Flag + permission + plan → what this account may do.
///   "open" | "premium_only" | "closed"
function accessFor({ flag, premium, allFeatures }) {
  if (allFeatures) return "open";
  if (flag === 2) return "open";
  if (flag === 3) return premium ? "open" : "premium_only";
  return "closed";
}

// ---------------------------------------------------------------------------
// Side effects

async function settings() {
  const p = await remoteFlags.params();
  return {
    flag: remoteFlags.intFrom(p, FLAG, FLAG_FALLBACK),
    freeLimit: Math.max(0, remoteFlags.intFrom(p, FREE_QUOTA_PARAM, FREE_QUOTA_FALLBACK)),
    premiumLimit: Math.max(0, remoteFlags.intFrom(p, PREMIUM_QUOTA_PARAM, PREMIUM_QUOTA_FALLBACK)),
  };
}

async function accountOf(db, uid) {
  const [user, entitlement, prefs] = await Promise.all([
    db.doc(`users/${uid}`).get(),
    db.doc(`entitlements/${uid}`).get(),
    db.doc(`users/${uid}/preferences/current`).get(),
  ]);
  const data = user.exists ? user.data() : {};
  return {
    data,
    premium: entitlement.exists && remoteFlags.isPremium(entitlement.data()),
    allFeatures: permissions.hasAllFeatures(permissions.permissionOf(data)),
    lang: langOfPreference(prefs.exists ? prefs.get("language") : null),
  };
}

async function rootOf(db, uid) {
  const snap = await db.collection("households").where("memberUids", "array-contains", uid).limit(1).get();
  return snap.empty ? `users/${uid}` : `households/${snap.docs[0].id}`;
}

async function sendText(to, body, lang, fetchImpl = fetch) {
  const id = phoneNumberId.value();
  if (!id) {
    logger.error("WHATSAPP_PHONE_NUMBER_ID is not set; reply dropped");
    return false;
  }
  try {
    const res = await fetchImpl(`${GRAPH_API}/${id}/messages`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${whatsappToken.value()}` },
      body: JSON.stringify({ messaging_product: "whatsapp", to: String(to).replace(/^\+/, ""), type: "text", text: { body: directional(body, lang), preview_url: true } }),
      signal: AbortSignal.timeout(SEND_TIMEOUT_MS),
    });
    if (!res.ok) {
      logger.error("whatsapp send failed", { status: res.status, body: (await res.text()).slice(0, 300) });
      return false;
    }
    return true;
  } catch (err) {
    logger.error("whatsapp send failed", { reason: err.message });
    return false;
  }
}

/// The model reads the message and returns the grocery rows.
async function parseGroceries(message, lang, fetchImpl = fetch) {
  const body = {
    contents: [{ role: "user", parts: [{ text: message.slice(0, MAX_TEXT) }] }],
    system_instruction: { parts: [{ text: [
      "You read a short chat message someone sent to their grocery-list bot and extract the groceries to buy.",
      "Return a JSON array; each entry is {\"item\": name, \"amount\": number, \"unit\": unit word or \"\"}.",
      "Keep item names and unit words in the language the message is written in, singular where natural, without the amount.",
      "amount defaults to 1. unit is a measure (g, kg, ml, liter, cup...) or a package word (bottle, pack, loaf, can) exactly as written, else \"\".",
      "Split lists joined by commas, 'and', 'ו', new lines. Ignore greetings, questions and anything that is not a grocery.",
      "If there are no groceries, return []. Answer with the array only.",
    ].join(" ") }] },
    generation_config: {
      response_mime_type: "application/json",
      response_json_schema: {
        type: "array",
        items: { type: "object", properties: { item: { type: "string" }, amount: { type: "number" }, unit: { type: "string" } }, required: ["item", "amount", "unit"] },
      },
      thinking_config: { thinking_level: "low" },
    },
  };
  const res = await fetchImpl(`${proxy.GOOGLE_ORIGIN}/v1beta/models/${MODEL}:generateContent`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": geminiApiKey.value() },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(MODEL_TIMEOUT_MS),
  });
  const raw = await res.text();
  if (!res.ok) throw Object.assign(new Error(`gemini ${res.status}: ${raw.slice(0, 200)}`), { status: res.status });
  const data = JSON.parse(raw);
  const answer = ((((data.candidates || [])[0] || {}).content || {}).parts || []).map((p) => p.text || "").join("");
  return { items: cleanItems(JSON.parse(answer || "[]")), usage: aiUsage.extractUsage(data) };
}

/// Claims one message of this month's allowance inside a transaction, so
/// two messages arriving together cannot both take the last one.
async function reserve(db, uid, { premium, limit, month }) {
  const ref = db.doc(`users/${uid}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const used = usedThisMonth(snap.exists ? snap.get("whatsapp_monthly_usage") : null, month);
    if (used >= limit) {
      tx.set(ref, { is_premium: premium }, { merge: true });
      return { allowed: false, used };
    }
    tx.set(ref, { is_premium: premium, whatsapp_monthly_usage: { month, message_count: used + 1 } }, { merge: true });
    return { allowed: true, used: used + 1 };
  });
}

/// Gives the message back (the model failed, or found nothing to add).
async function refund(db, uid, month) {
  const ref = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const used = usedThisMonth(snap.exists ? snap.get("whatsapp_monthly_usage") : null, month);
    if (used > 0) tx.set(ref, { whatsapp_monthly_usage: { month, message_count: used - 1 } }, { merge: true });
  });
}

/// Writes the lines onto the account's chosen list (or its main list, or
/// a new "From WhatsApp" list) and returns the list id.
async function addToList(db, uid, wanted, lang) {
  const root = await rootOf(db, uid);
  const lists = db.collection(`${root}/grocery_lists`);
  const userRef = db.doc(`users/${uid}`);
  return db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    const chosen = user.exists ? user.get("whatsapp_list_id") : null;
    let ref = null;
    let current = null;
    if (typeof chosen === "string" && chosen && !chosen.includes("/")) {
      const snap = await tx.get(lists.doc(chosen));
      if (snap.exists && writable(snap.data())) { ref = snap.ref; current = snap.data(); }
    }
    if (!ref) {
      const primary = await tx.get(lists.doc("primary"));
      if (primary.exists && writable(primary.data())) { ref = primary.ref; current = primary.data(); }
    }
    if (!ref) {
      const all = await tx.get(lists.limit(50));
      const own = all.docs.filter((d) => writable(d.data())).sort((a, b) => String(a.get("createdAt")).localeCompare(String(b.get("createdAt"))));
      if (own.length) { ref = own[0].ref; current = own[0].data(); }
    }
    let next;
    if (ref) {
      next = stamp({ ...current, items: mergeItems(current.items, wanted) }, current, lang);
    } else {
      const id = crypto.randomUUID();
      ref = lists.doc(id);
      next = stamp({ ...newList(id, text(lang).listName, lang), items: mergeItems([], wanted) }, null, lang);
      tx.set(userRef, { whatsapp_list_id: id }, { merge: true });
    }
    tx.set(ref, next);
    return ref.id;
  });
}

/// Links [phone] to the account behind [code]. Returns the uid, or a
/// refusal word: "bad_code" | "taken".
async function linkByCode(db, code, phone, now = Date.now()) {
  const codeRef = db.doc(`whatsapp_link_codes/${code}`);
  const numberRef = db.doc(`whatsapp_numbers/${phone}`);
  return db.runTransaction(async (tx) => {
    const [codeSnap, numberSnap] = await Promise.all([tx.get(codeRef), tx.get(numberRef)]);
    if (!codeSnap.exists) return { refused: "bad_code" };
    const { uid, expiresAt } = codeSnap.data();
    const exp = expiresAt && expiresAt.toMillis ? expiresAt.toMillis() : 0;
    if (!uid || exp < now) {
      tx.delete(codeRef);
      return { refused: "bad_code" };
    }
    if (numberSnap.exists && numberSnap.get("uid") !== uid) return { refused: "taken" };
    const userRef = db.doc(`users/${uid}`);
    const user = await tx.get(userRef);
    const previous = user.exists ? user.get("whatsapp_phone_number") : null;
    if (previous && previous !== phone) tx.delete(db.doc(`whatsapp_numbers/${previous}`));
    tx.set(numberRef, { uid, linkedAt: admin.firestore.FieldValue.serverTimestamp() });
    tx.set(userRef, {
      whatsapp_phone_number: phone,
      whatsapp_link_code: admin.firestore.FieldValue.delete(),
      whatsapp_link_code_expires_at: admin.firestore.FieldValue.delete(),
      whatsapp_linked_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.delete(codeRef);
    return { uid };
  });
}

/// Counts a wrong code from an unlinked number; true once it is over the limit.
async function wrongCodeLimited(db, phone, now = Date.now()) {
  const ref = db.doc(`whatsapp_attempts/${phone}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.exists ? snap.data() : {};
    const fresh = !d.windowStart || now - d.windowStart > WRONG_CODE_WINDOW_MS;
    const count = (fresh ? 0 : d.count || 0) + 1;
    tx.set(ref, { windowStart: fresh ? now : d.windowStart, count });
    return count > MAX_WRONG_CODES;
  });
}

async function attemptsBlocked(db, phone, now = Date.now()) {
  const snap = await db.doc(`whatsapp_attempts/${phone}`).get();
  if (!snap.exists) return false;
  const d = snap.data();
  return now - (d.windowStart || 0) <= WRONG_CODE_WINDOW_MS && (d.count || 0) >= MAX_WRONG_CODES;
}

/// One incoming message, start to finish. Never throws.
async function handleMessage(db, message, conf) {
  const phone = toE164(message.from);
  if (!phone) return;
  // Meta delivers at least once: the message id is claimed first.
  try {
    await db.doc(`whatsapp_inbound/${String(message.id).replace(/\//g, "_")}`).create({
      at: admin.firestore.FieldValue.serverTimestamp(),
      expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 3600 * 1000),
    });
  } catch (err) {
    if (err.code === 6 || /already exists/i.test(err.message)) return; // a retry
    throw err;
  }

  const body = message.type === "text" && message.text ? String(message.text.body || "") : "";
  const numberSnap = await db.doc(`whatsapp_numbers/${phone}`).get();
  let uid = numberSnap.exists ? numberSnap.get("uid") : null;
  const code = body ? extractCode(body) : null;

  // A code: link (or move) this number.
  if (code) {
    if (!uid && await attemptsBlocked(db, phone)) {
      if (accessFor({ flag: conf.flag }) !== "closed") await sendText(phone, text(langOfText(body)).tooMany, langOfText(body));
      return;
    }
    const result = await linkByCode(db, code, phone);
    if (result.uid) {
      const account = await accountOf(db, result.uid);
      logger.info("whatsapp linked", { uid: result.uid });
      await sendText(phone, text(account.lang).linked, account.lang);
      return;
    }
    if (!uid) {
      const limited = await wrongCodeLimited(db, phone);
      // While the feature is dark, strangers get no answer at all.
      if (accessFor({ flag: conf.flag }) === "closed") return;
      const lang = langOfText(body);
      await sendText(phone, limited ? text(lang).tooMany : (result.refused === "taken" ? text(lang).takenNumber : text(lang).badCode), lang);
      return;
    }
    if (result.refused === "taken") {
      const account = await accountOf(db, uid);
      await sendText(phone, text(account.lang).takenNumber, account.lang);
      return;
    }
    // A linked number sending a stale code: fall through and treat it as text.
  }

  if (!uid) {
    if (accessFor({ flag: conf.flag }) === "closed") return;
    const lang = langOfText(body);
    await sendText(phone, text(lang).notLinked, lang);
    return;
  }

  const account = await accountOf(db, uid);
  const t = text(account.lang);
  const access = accessFor({ flag: conf.flag, premium: account.premium, allFeatures: account.allFeatures });
  if (access === "closed") return void (await sendText(phone, t.unavailable, account.lang));
  if (access === "premium_only") return void (await sendText(phone, t.premiumOnly, account.lang));
  if (!body.trim()) return void (await sendText(phone, t.onlyText, account.lang));

  const month = monthKey();
  const limit = account.premium ? conf.premiumLimit : conf.freeLimit;
  const claim = await reserve(db, uid, { premium: account.premium, limit, month });
  if (!claim.allowed) {
    logger.info("whatsapp quota reached", { uid, premium: account.premium, used: claim.used });
    await sendText(phone, account.premium ? t.premiumQuota(limit) : t.quota(limit), account.lang);
    return;
  }

  const started = Date.now();
  let parsed;
  try {
    parsed = await parseGroceries(body, account.lang);
  } catch (err) {
    logger.error("whatsapp parse failed", { uid, reason: err.message });
    void aiUsage.recordCall({ uid, fn: "whatsappWebhook", model: MODEL, kind: "whatsapp", status: 502, ms: Date.now() - started, usage: null });
    await refund(db, uid, month);
    await sendText(phone, t.error, account.lang);
    return;
  }
  void aiUsage.recordCall({ uid, fn: "whatsappWebhook", model: MODEL, kind: "whatsapp", status: 200, ms: Date.now() - started, usage: parsed.usage });

  if (!parsed.items.length) {
    await refund(db, uid, month);
    await sendText(phone, t.nothing, account.lang);
    return;
  }
  try {
    await addToList(db, uid, parsed.items, account.lang);
  } catch (err) {
    logger.error("whatsapp list write failed", { uid, reason: err.message });
    await refund(db, uid, month);
    await sendText(phone, t.error, account.lang);
    return;
  }
  logger.info("whatsapp items added", { uid, items: parsed.items.length });
  await sendText(phone, t.added(parsed.items.map((w) => lineFor(w, account.lang)).join("\n")), account.lang);
}

exports.whatsappWebhook = onRequest(
  {
    region: "europe-west1",
    secrets: [geminiApiKey, whatsappToken, verifyToken, appSecret],
    timeoutSeconds: 60,
    maxInstances: 5,
    memory: "256MiB",
  },
  async (req, res) => {
    if (req.method === "GET") {
      // Meta's subscription handshake.
      const mode = req.query["hub.mode"];
      const token = req.query["hub.verify_token"];
      const challenge = req.query["hub.challenge"];
      if (mode === "subscribe" && token && token === verifyToken.value()) return res.status(200).send(String(challenge || ""));
      return res.status(403).send("Forbidden");
    }
    if (req.method !== "POST") return res.status(405).send("Method not allowed");
    if (!signatureValid(req.rawBody, req.get("x-hub-signature-256"), appSecret.value())) {
      logger.warn("whatsapp webhook: bad signature");
      return res.status(401).send("Bad signature");
    }
    const db = admin.firestore();
    const messages = messagesIn(req.body);
    if (messages.length) {
      const conf = await settings();
      for (const message of messages) {
        try {
          await handleMessage(db, message, conf);
        } catch (err) {
          logger.error("whatsapp message failed", { reason: err.message });
        }
      }
    }
    // Always 200 once the signature is good: a non-2xx makes Meta retry for
    // days, and every message is already deduplicated by its id.
    return res.status(200).send("OK");
  },
);

// ---------------------------------------------------------------------------
// The app's side

async function statusOf(db, uid, conf) {
  const account = await accountOf(db, uid);
  const d = account.data;
  const month = monthKey();
  const code = d.whatsapp_link_code;
  const exp = d.whatsapp_link_code_expires_at && d.whatsapp_link_code_expires_at.toMillis ? d.whatsapp_link_code_expires_at.toMillis() : 0;
  return {
    linked: !!d.whatsapp_phone_number,
    phone: d.whatsapp_phone_number || null,
    premium: account.premium,
    used: usedThisMonth(d.whatsapp_monthly_usage, month),
    limit: account.premium ? conf.premiumLimit : conf.freeLimit,
    month,
    listId: d.whatsapp_list_id || null,
    code: code && exp > Date.now() ? code : null,
    codeExpiresAt: code && exp > Date.now() ? new Date(exp).toISOString() : null,
    botNumber: botNumber.value() || null,
    access: accessFor({ flag: conf.flag, premium: account.premium, allFeatures: account.allFeatures }),
  };
}

async function issueCode(db, uid) {
  const userRef = db.doc(`users/${uid}`);
  const old = await userRef.get();
  const previous = old.exists ? old.get("whatsapp_link_code") : null;
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = newCode();
    const expiresAt = admin.firestore.Timestamp.fromMillis(Date.now() + CODE_TTL_MS);
    try {
      await db.doc(`whatsapp_link_codes/${code}`).create({ uid, expiresAt });
    } catch (err) {
      if (err.code === 6 || /already exists/i.test(err.message)) continue;
      throw err;
    }
    if (previous && previous !== code) await db.doc(`whatsapp_link_codes/${previous}`).delete().catch(() => {});
    await userRef.set({ whatsapp_link_code: code, whatsapp_link_code_expires_at: expiresAt }, { merge: true });
    return code;
  }
  throw new Error("no free code");
}

async function unlink(db, uid) {
  const userRef = db.doc(`users/${uid}`);
  await db.runTransaction(async (tx) => {
    const user = await tx.get(userRef);
    const phone = user.exists ? user.get("whatsapp_phone_number") : null;
    if (phone) {
      const idx = await tx.get(db.doc(`whatsapp_numbers/${phone}`));
      if (idx.exists && idx.get("uid") === uid) tx.delete(idx.ref);
    }
    tx.set(userRef, {
      whatsapp_phone_number: admin.firestore.FieldValue.delete(),
      whatsapp_linked_at: admin.firestore.FieldValue.delete(),
    }, { merge: true });
  });
}

async function setList(db, uid, listId) {
  if (listId === null) {
    await db.doc(`users/${uid}`).set({ whatsapp_list_id: admin.firestore.FieldValue.delete() }, { merge: true });
    return { ok: true };
  }
  if (typeof listId !== "string" || !listId || listId.includes("/") || listId.length > 128) return { error: "invalid" };
  const root = await rootOf(db, uid);
  const snap = await db.doc(`${root}/grocery_lists/${listId}`).get();
  if (!snap.exists || !writable(snap.data())) return { error: "list_not_writable" };
  await db.doc(`users/${uid}`).set({ whatsapp_list_id: listId }, { merge: true });
  return { ok: true };
}

/// What account deletion removes besides the users document.
async function forgetAccount(db, uid, data) {
  const phone = data && data.whatsapp_phone_number;
  if (phone) {
    const idx = await db.doc(`whatsapp_numbers/${phone}`).get();
    if (idx.exists && idx.get("uid") === uid) await idx.ref.delete();
  }
  const code = data && data.whatsapp_link_code;
  if (code) await db.doc(`whatsapp_link_codes/${code}`).delete().catch(() => {});
}

exports.whatsappLink = onRequest(
  { region: "europe-west1", cors: ORIGINS, maxInstances: 5 },
  async (req, res) => {
    if (req.method !== "POST") return res.status(405).json({ error: { message: "POST only" } });
    const caller = await proxy.verifyCaller(req);
    if (!caller) return res.status(401).json({ error: { message: "A valid Firebase ID token is required" } });
    if (caller.disabled === true) return res.status(403).json({ error: { code: "account_disabled", message: "This account is disabled" } });
    const db = admin.firestore();
    const action = (req.body || {}).action;
    try {
      const conf = await settings();
      const status = await statusOf(db, caller.uid, conf);
      // Unlinking and reading are always allowed — a closed feature must
      // still let an account take its number back.
      if (action === "status") return res.status(200).json(status);
      if (action === "unlink") {
        await unlink(db, caller.uid);
        return res.status(200).json(await statusOf(db, caller.uid, conf));
      }
      if (status.access === "closed") return res.status(403).json({ error: { code: "unavailable", message: "Not available" } });
      if (status.access === "premium_only") return res.status(403).json({ error: { code: "premium_required", message: "Premium only" } });
      if (action === "code") {
        await issueCode(db, caller.uid);
        return res.status(200).json(await statusOf(db, caller.uid, conf));
      }
      if (action === "setList") {
        const result = await setList(db, caller.uid, (req.body || {}).listId ?? null);
        if (result.error) return res.status(400).json({ error: { code: result.error, message: result.error } });
        return res.status(200).json(await statusOf(db, caller.uid, conf));
      }
      return res.status(400).json({ error: { message: "Unknown action" } });
    } catch (err) {
      logger.error("whatsappLink failed", { uid: caller.uid, action, reason: err.message });
      return res.status(500).json({ error: { message: "WhatsApp link failed" } });
    }
  },
);

exports.internals = {
  toE164, monthKey, usedThisMonth, extractCode, langOfText, langOfPreference, unitFor, cleanItems,
  mergeItems, stamp, newList, writable, lineFor, directional, signatureValid, messagesIn, accessFor,
  forgetAccount, TEXT, FLAG, FREE_QUOTA_FALLBACK, PREMIUM_QUOTA_FALLBACK, RLM,
};
