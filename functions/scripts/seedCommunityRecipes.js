// Seeds ten varied recipes into the community feed (`shared_recipes`) so
// the feed, the planner and the nutrition dashboard have something to show
// while testing. Writes through the Firestore REST API with the Firebase
// CLI's own login, so it needs no service account: run from `functions/`
// after `firebase login`.
//
//   node scripts/seedCommunityRecipes.js
//
// Documents follow exactly what the app's `share()` writes (see
// lib/features/shared_recipes/data/datasources/shared_recipes_remote_datasource.dart),
// authored by the signed-in developer's own profile. Idempotent: each
// recipe has a fixed id, so re-running overwrites rather than duplicates.
const path = require("node:path");
const { execSync } = require("node:child_process");

const PROJECT = "easy-plate";
const AUTHOR_UID = "2oFsSVJ6bIT08ryIUkWXPAbV5fh2";
const globalRoot = execSync("npm root -g").toString().trim();
const auth = require(path.join(globalRoot, "firebase-tools", "lib", "auth.js"));

const BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

// Firestore's typed JSON.
function value(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number") return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, value(x)])) } };
}

const ing = (name, amount, unit) => ({ name, amount, unit });
const nut = (calories, proteinGrams, carbsGrams, fatGrams) => ({ calories, proteinGrams, carbsGrams, fatGrams });

const RECIPES = [
  {
    id: "seed-shakshuka",
    title: "שקשוקה קלאסית",
    prepTimeMinutes: 10, cookTimeMinutes: 25, servings: 4,
    ingredients: [ing("עגבניות בשלות", 6, "unit"), ing("בצל", 1, "unit"), ing("שום", 3, "unit"), ing("פלפל אדום", 1, "unit"), ing("רסק עגבניות", 2, "tablespoon"), ing("ביצים", 6, "unit"), ing("שמן זית", 3, "tablespoon"), ing("כמון", 1, "teaspoon"), ing("פפריקה מתוקה", 1, "teaspoon"), ing("מלח", 1, "pinch")],
    steps: ["קוצצים בצל, שום ופלפל ומטגנים בשמן זית עד שהבצל שקוף.", "מוסיפים עגבניות חתוכות, רסק ותבלינים, ומבשלים 15 דקות עד שהרוטב מסמיך.", "יוצרים גומות ברוטב, שוברים לתוכן ביצים ומכסים.", "מבשלים 6-8 דקות עד שהחלבון נקרש והחלמון עדיין רך.", "מגישים עם לחם טרי."],
    dietaryTags: ["vegetarian", "kosher", "allergy"], allergens: ["eggs"], mayContain: [],
    nutrition: nut(290, 14, 16, 19),
  },
  {
    id: "seed-schnitzel",
    title: "שניצל עוף פריך",
    prepTimeMinutes: 20, cookTimeMinutes: 15, servings: 4,
    ingredients: [ing("חזה עוף", 800, "gram"), ing("ביצים", 2, "unit"), ing("פירורי לחם", 2, "cup"), ing("קמח", 0.5, "cup"), ing("שומשום", 2, "tablespoon"), ing("פפריקה", 1, "teaspoon"), ing("שמן לטיגון", 1, "cup"), ing("מלח", 1, "teaspoon")],
    steps: ["פורסים את החזה לפרוסות דקות ומרדדים קלות.", "מכינים שלוש צלחות: קמח, ביצים טרופות, ופירורי לחם עם שומשום ופפריקה.", "מצפים כל פרוסה בקמח, בביצה ובפירורים.", "מטגנים בשמן חם 3 דקות מכל צד עד שהציפוי זהוב.", "מניחים על נייר סופג ומגישים עם לימון."],
    dietaryTags: ["meat", "kosher", "allergy"], allergens: ["eggs", "gluten", "sesame"], mayContain: [],
    nutrition: nut(520, 42, 30, 25),
  },
  {
    id: "seed-lentil-soup",
    title: "מרק עדשים כתומות",
    prepTimeMinutes: 10, cookTimeMinutes: 35, servings: 6,
    ingredients: [ing("עדשים כתומות", 2, "cup"), ing("בצל", 1, "unit"), ing("גזר", 2, "unit"), ing("שום", 2, "unit"), ing("כמון", 1, "teaspoon"), ing("כורכום", 0.5, "teaspoon"), ing("מים", 2, "liter"), ing("שמן זית", 2, "tablespoon"), ing("לימון", 1, "unit")],
    steps: ["מטגנים בצל, גזר ושום בשמן זית עד ריכוך.", "מוסיפים את התבלינים ומערבבים חצי דקה.", "מוסיפים עדשים שטופות ומים, מביאים לרתיחה ומנמיכים.", "מבשלים 30 דקות עד שהעדשים מתפרקות.", "טוחנים חלקית, מתקנים תיבול ומוסיפים לימון לפני ההגשה."],
    dietaryTags: ["vegan", "vegetarian", "kosher", "glutenFree"], allergens: [], mayContain: [],
    nutrition: nut(240, 14, 36, 5),
  },
  {
    id: "seed-israeli-salad",
    title: "סלט ישראלי קצוץ",
    prepTimeMinutes: 15, cookTimeMinutes: 0, servings: 4,
    ingredients: [ing("מלפפונים", 4, "unit"), ing("עגבניות", 4, "unit"), ing("בצל סגול", 0.5, "unit"), ing("פטרוזיליה", 0.5, "cup"), ing("לימון", 1, "unit"), ing("שמן זית", 3, "tablespoon"), ing("מלח", 1, "pinch"), ing("פלפל שחור", 1, "pinch")],
    steps: ["קוצצים את הירקות לקוביות קטנות ואחידות.", "קוצצים פטרוזיליה דק ומוסיפים.", "מתבלים בשמן זית, מיץ לימון, מלח ופלפל.", "מערבבים ומגישים מיד."],
    dietaryTags: ["vegan", "vegetarian", "kosher", "glutenFree"], allergens: [], mayContain: [],
    nutrition: nut(120, 2, 9, 10),
  },
  {
    id: "seed-pasta-pomodoro",
    title: "פסטה ברוטב עגבניות ובזיליקום",
    prepTimeMinutes: 10, cookTimeMinutes: 25, servings: 4,
    ingredients: [ing("ספגטי", 400, "gram"), ing("עגבניות מרוסקות", 800, "gram"), ing("שום", 3, "unit"), ing("בזיליקום טרי", 1, "cup"), ing("שמן זית", 4, "tablespoon"), ing("סוכר", 1, "teaspoon"), ing("פרמזן", 50, "gram"), ing("מלח", 1, "teaspoon")],
    steps: ["מבשלים ספגטי במים רותחים ומלוחים לפי ההוראות.", "בינתיים מטגנים שום פרוס בשמן זית עד שמזהיב קלות.", "מוסיפים עגבניות מרוסקות, סוכר ומלח ומבשלים 15 דקות.", "מוסיפים בזיליקום קרוע ומערבבים עם הפסטה.", "מגישים עם פרמזן מגורר."],
    dietaryTags: ["vegetarian", "dairy", "kosher", "allergy"], allergens: ["gluten", "milk"], mayContain: [],
    nutrition: nut(560, 18, 88, 15),
  },
  {
    id: "seed-baked-salmon",
    title: "סלמון בתנור עם לימון ושמיר",
    prepTimeMinutes: 10, cookTimeMinutes: 18, servings: 4,
    ingredients: [ing("פילה סלמון", 800, "gram"), ing("לימון", 1, "unit"), ing("שמיר", 0.5, "cup"), ing("שום", 2, "unit"), ing("שמן זית", 2, "tablespoon"), ing("מלח", 1, "teaspoon"), ing("פלפל שחור", 0.5, "teaspoon")],
    steps: ["מחממים תנור ל-200 מעלות.", "מניחים את הסלמון בתבנית, מברישים בשמן זית ומתבלים.", "מפזרים שום כתוש, שמיר קצוץ ופרוסות לימון.", "אופים 15-18 דקות עד שהדג מתפורר במזלג."],
    dietaryTags: ["kosher", "glutenFree", "allergy"], allergens: ["fish"], mayContain: [],
    nutrition: nut(380, 38, 2, 24),
  },
  {
    id: "seed-chicken-rice",
    title: "אורז עם עוף ובצל מקורמל",
    prepTimeMinutes: 15, cookTimeMinutes: 40, servings: 6,
    ingredients: [ing("פרגיות", 1, "kilogram"), ing("אורז בסמטי", 2, "cup"), ing("בצל", 3, "unit"), ing("שמן", 4, "tablespoon"), ing("כורכום", 1, "teaspoon"), ing("בהרט", 1, "teaspoon"), ing("מים", 3.5, "cup"), ing("מלח", 1.5, "teaspoon")],
    steps: ["מטגנים בצל פרוס בשמן על אש בינונית 15 דקות עד שמשחים ומתקרמל.", "מוסיפים את הפרגיות ומשחימים מכל צד.", "מוסיפים אורז שטוף, תבלינים ומים ומביאים לרתיחה.", "מכסים ומבשלים על אש נמוכה 20 דקות.", "מכבים, ממתינים 10 דקות ומפרידים במזלג."],
    dietaryTags: ["meat", "kosher", "glutenFree"], allergens: [], mayContain: [],
    nutrition: nut(610, 35, 58, 26),
  },
  {
    id: "seed-hummus",
    title: "חומוס ביתי חלק",
    prepTimeMinutes: 15, cookTimeMinutes: 90, servings: 8,
    ingredients: [ing("גרגירי חומוס יבשים", 2, "cup"), ing("טחינה גולמית", 0.75, "cup"), ing("לימון", 2, "unit"), ing("שום", 2, "unit"), ing("כמון", 1, "teaspoon"), ing("קרח", 0.5, "cup"), ing("מלח", 1.5, "teaspoon"), ing("שמן זית", 2, "tablespoon")],
    steps: ["משרים את הגרגירים במים לילה שלם.", "מבשלים בסיר עם מים חדשים כשעה וחצי עד שהם רכים מאוד.", "טוחנים את הגרגירים החמים עם שום, כמון ומלח.", "מוסיפים טחינה, לימון וקרח וטוחנים עוד 3 דקות עד למרקם חלק.", "מגישים עם שמן זית ופפריקה."],
    dietaryTags: ["vegan", "vegetarian", "kosher", "glutenFree", "allergy"], allergens: ["sesame"], mayContain: [],
    nutrition: nut(260, 11, 26, 13),
  },
  {
    id: "seed-chocolate-cake",
    title: "עוגת שוקולד רכה",
    prepTimeMinutes: 15, cookTimeMinutes: 35, servings: 10,
    ingredients: [ing("שוקולד מריר", 200, "gram"), ing("חמאה", 200, "gram"), ing("ביצים", 4, "unit"), ing("סוכר", 1, "cup"), ing("קמח", 0.75, "cup"), ing("קקאו", 2, "tablespoon"), ing("תמצית וניל", 1, "teaspoon"), ing("מלח", 1, "pinch")],
    steps: ["מחממים תנור ל-170 מעלות ומשמנים תבנית עגולה.", "ממיסים שוקולד וחמאה יחד ומצננים מעט.", "מקציפים ביצים עם סוכר ווניל עד שהתערובת בהירה.", "מקפלים את השוקולד המומס, ואז קמח, קקאו ומלח.", "אופים 30-35 דקות; המרכז צריך להישאר מעט רך."],
    dietaryTags: ["vegetarian", "dairy", "kosher", "allergy"], allergens: ["eggs", "milk", "gluten"], mayContain: ["treeNuts"],
    nutrition: nut(420, 6, 40, 27),
  },
  {
    id: "seed-tofu-stirfry",
    title: "מוקפץ טופו וירקות ברוטב סויה",
    prepTimeMinutes: 15, cookTimeMinutes: 12, servings: 3,
    ingredients: [ing("טופו קשה", 400, "gram"), ing("ברוקולי", 1, "unit"), ing("פלפל אדום", 1, "unit"), ing("גזר", 1, "unit"), ing("רוטב סויה", 3, "tablespoon"), ing("שמן שומשום", 1, "tablespoon"), ing("ג'ינג'ר", 1, "tablespoon"), ing("שום", 2, "unit"), ing("קורנפלור", 1, "tablespoon"), ing("שמן", 2, "tablespoon")],
    steps: ["מייבשים את הטופו, חותכים לקוביות ומצפים בקורנפלור.", "מטגנים את הטופו במחבת חמה עד שהוא זהוב מכל הצדדים ומוציאים.", "מקפיצים שום, ג'ינג'ר והירקות 4 דקות על אש גבוהה.", "מחזירים את הטופו, מוסיפים סויה ושמן שומשום ומערבבים דקה.", "מגישים על אורז."],
    dietaryTags: ["vegan", "vegetarian", "allergy"], allergens: ["sesame"], mayContain: ["gluten"],
    nutrition: nut(330, 22, 18, 20),
  },
];

function toDocument(r, author) {
  const createdAt = new Date(Date.now() - RECIPES.indexOf(r) * 3600 * 1000 * 5);
  return {
    fields: Object.fromEntries(Object.entries({
      title: r.title,
      prepTimeMinutes: r.prepTimeMinutes,
      cookTimeMinutes: r.cookTimeMinutes,
      ingredients: r.ingredients,
      steps: r.steps,
      dietaryTags: r.dietaryTags,
      allergens: r.allergens,
      mayContain: r.mayContain,
      imageFileName: null,
      imageStoragePath: null,
      servings: r.servings,
      nutrition: r.nutrition,
      authorUid: AUTHOR_UID,
      authorName: author.name,
      authorPhotoUrl: author.photoUrl,
      likeCount: 0,
      createdAt,
    }).map(([k, v]) => [k, value(v)])),
  };
}

(async () => {
  const account = auth.getGlobalDefaultAccount();
  const token = await auth.getAccessToken(account.tokens.refresh_token, ["https://www.googleapis.com/auth/cloud-platform"]);
  const headers = { Authorization: `Bearer ${token.access_token || token}`, "Content-Type": "application/json" };

  const profile = await (await fetch(`${BASE}/public_profiles/${AUTHOR_UID}`, { headers })).json();
  const author = {
    name: profile.fields?.fullName?.stringValue || "EasyPlate",
    photoUrl: profile.fields?.photoUrl?.stringValue || null,
  };

  for (const recipe of RECIPES) {
    const res = await fetch(`${BASE}/shared_recipes/${recipe.id}`, {
      method: "PATCH",
      headers,
      body: JSON.stringify(toDocument(recipe, author)),
    });
    console.log(res.ok ? "ok " : "FAIL", recipe.id, res.ok ? "" : await res.text());
  }
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
