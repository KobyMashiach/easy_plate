// Every string the console shows, in the app's five languages. `t(key)`
// falls back to English for a key a language is missing, and to the key
// itself if English lacks it too — a missing string shows as its name
// rather than as nothing.

export const LANGS = { he: "עברית", en: "English", ar: "العربية", fr: "Français", ru: "Русский" };
export const RTL = new Set(["he", "ar"]);
const LOCALES = { he: "he-IL", en: "en-GB", ar: "ar", fr: "fr-FR", ru: "ru-RU" };

const en = {
  lang: "Language",
  signOut: "Sign out",
  gate: {
    title: "EasyPlate Admin",
    intro: "The administration console. Sign in with the administrator's Google account.",
    google: "Sign in with Google",
    notAdmin: "This account is not the administrator. You were signed out.",
    failed: "Sign-in failed: {reason}",
    unauthorizedDomain: "This domain is not authorized for sign-in yet. Add aieasyplate.app under Firebase Console → Authentication → Settings → Authorized domains.",
  },
  nav: { dashboard: "Dashboard", users: "Accounts", community: "Community", recipes: "Shared recipes", personas: "Personas", households: "Households", tickets: "Tickets", config: "Configuration", seed: "Activity", audit: "Audit log" },
  common: {
    save: "Save", cancel: "Cancel", delete: "Delete", edit: "Edit", close: "Close", confirm: "Confirm", yes: "Yes", no: "No",
    search: "Search…", loading: "Loading…", none: "Nothing here yet.", error: "Something went wrong", done: "Done", refresh: "Refresh",
    add: "Add", create: "Create", send: "Send", generate: "Write with AI", publish: "Publish", back: "Back", copy: "Copy", copied: "Copied",
    all: "All", now: "Now", unknown: "unknown", name: "Name", email: "Email", phone: "Phone", date: "Date", actions: "Actions",
    title: "Title", body: "Text", more: "More", apply: "Apply", random: "Random", upload: "Upload", url: "Link", pick: "Pick",
    remove: "Remove", me: "Me (administrator)", open: "Open", filter: "Filter", count: "Count", total: "Total", status: "Status",
    version: "Version", platform: "Platform", irreversible: "This cannot be undone.", working: "Working…", id: "ID", yesDelete: "Yes, delete",
    saved: "Saved", deleted: "Deleted", sent: "Sent", kept: "Kept", nothingFound: "Nothing matches.", language: "Language", optional: "optional",
    showMore: "Show more", today: "Today", invalidJson: "Not valid JSON", select: "Select", selected: "{n} selected", unnamed: "(no name)",
  },
  time: { justNow: "just now", never: "never" },
  dash: {
    range: { today: "Today", d30: "30 days", d60: "60 days", all: "All time" },
    users: "Accounts", newUsers: "New accounts", premium: "Premium", disabled: "Blocked", online: "Online now", withPush: "With push token",
    payments: "Payments", sandbox: "{n} sandbox skipped", aiCost: "AI cost", aiCalls: "AI calls", tokens: "Tokens", cacheHits: "Cache hits",
    recipes: "Shared recipes", posts: "Threads", tickets: "Tickets", personas: "Personas", households: "Households",
    byPlatform: "By platform", byVersion: "By app version", byModel: "By model", byKind: "By feature", signups: "Sign-ups per day",
    dailyCost: "AI cost per day", topUsers: "Accounts by AI cost", syncPricing: "Sync prices", synced: "Prices and rate refreshed",
    costNote: "Costs in ₪ at {rate} ₪/$ (prices {source}, updated {when}).", searches: "Searches", cost: "Cost", calls: "Calls",
    input: "In", output: "Out", cached: "Cached", noData: "No data for this range.", unpaid: "no payments", calc: "{calls} calls · {tokens} tokens",
  },
  users: {
    filter: { all: "All", online: "Online", premium: "Premium", disabled: "Blocked", session: "With device session" },
    online: "Online", offline: "Offline", lastSeen: "Last seen", device: "Device", session: "Session", sessionUntil: "until {date}",
    noSession: "no session", premium: "Premium", free: "Free", disabled: "Blocked", broadcast: "Broadcast", broadcastTitle: "Message to every account",
    broadcastSent: "{items} inbox items, {sent} pushes sent, {failed} failed", count: "{n} accounts", joined: "Joined", persona: "Persona",
    hint: "Online = the app is open on a phone right now (reported every minute). Kick = frees the device session, the app signs out at once.",
  },
  user: {
    profile: "Profile", auth: "Sign-in", providers: "Providers", lastSignIn: "Last sign-in", created: "Created", lastRefresh: "Last token refresh",
    entitlement: "Subscription", premiumUntil: "Premium until", adminLock: "Admin lock (webhook leaves it alone)", source: "Source",
    setPremium: "Grant Premium", removePremium: "Remove Premium", premiumForever: "Leave empty for no end date", notify: "Send message",
    disable: "Block account", enable: "Unblock", kick: "Disconnect device", kickHint: "Frees the device session and revokes tokens; the app signs out within seconds.",
    delete: "Delete account", deleteHint: "Removes the Auth user, the profile, every mirrored box, inbox, entitlement and usage. Community posts stay.",
    blockMessage: "Message shown on the blocked screen", usage: "AI usage", recentCalls: "Recent AI calls", inbox: "Inbox", content: "Content",
    collections: { recipes: "Recipes", books: "Books", meal_plans: "Meal plans", grocery_lists: "Grocery lists", preferences: "Preferences", price_records: "Price records", receipts: "Receipts", product_pricing: "Product pricing" },
    household: "Household", shared: "Shared items", posts: "Threads", sharedRecipes: "Shared recipes", feedback: "Tickets", editJson: "Edit as JSON",
    contentHint: "Edits land in the cloud copy; the phone picks them up on its next start (or live, inside a household).",
    root: { users: "Personal", households: "Household" }, disabledBanner: "This account is blocked: {message}", editProfile: "Edit profile",
    fullName: "Full name", photoUrl: "Photo URL", noAuth: "No Auth user (deleted or persona)", tokensValidAfter: "Tokens valid after", kicked: "Device disconnected",
    notified: "Message sent", shareCodes: "Share codes", invites: "Invites", none: "—", notFound: "Account not found", items: "{n} items",
    model: "Model", kind: "Feature", when: "When", ms: "ms", statusCol: "Status", noUsage: "No AI usage yet", pushToken: "Push token", appVersion: "App version",
    disabledYes: "Blocked", disabledNo: "Active", role: "Role", members: "Members", owner: "Owner", collabRecipes: "Shared recipes (collab)", collabContainers: "Shared books, plans, lists",
    tokenUntil: "Current token valid until", tokenExpired: "expired", tokenLive: "valid", tokenHint: "An ID token lives one hour from its last refresh; the device renews it silently while signed in.",
    uses: "uses", revoked: "revoked", expires: "expires", kind2: "Kind",
  },
  forum: {
    newThread: "New thread", replies: "{n} replies", reply: "Reply", as: "Post as", asMe: "Me (administrator)", draftAi: "Write with AI",
    topic: "Subject or angle (optional)", backdate: "Date", randomDate: "Random date in the last {days} days", likes: "{n} likes",
    seedLikes: "Add likes", seedLikesCount: "How many personas should like this?", likeAs: "Like as…", deleteThread: "Delete thread (with replies)",
    deleteReply: "Delete reply", edit: "Edit", posted: "Posted", noPersonas: "No personas yet — create some under Personas.", thread: "Thread",
    open: "Open thread", recipeLink: "Attached recipe", pending: "pending", threads: "{n} threads", added: "{n} likes added", context: "Thread text for the AI",
    live: "Live", editThread: "Edit thread", editReply: "Edit reply",
  },
  recipes: {
    new: "New shared recipe", generate: "Generate recipe", generating: "Writing the recipe…", titleHint: "Dish name, e.g. Shakshuka",
    hints: "Wishes for the AI (optional)", language: "Recipe language", ingredients: "Ingredients", steps: "Steps", servings: "Servings",
    prep: "Prep (min)", cook: "Cook (min)", tags: "Diet tags", allergens: "Contains", mayContain: "May contain", nutrition: "Nutrition per serving",
    calories: "Calories", protein: "Protein (g)", carbs: "Carbs (g)", fat: "Fat (g)", image: "Picture", imageSearch: "Search Google Images",
    imageUrl: "Picture link", imageUpload: "Upload picture", imageKeep: "Keep current", noImage: "No picture", searchMore: "More results",
    publish: "Publish to community", published: "Recipe published", by: "by", addIngredient: "Add ingredient", addStep: "Add step",
    amount: "Amount", unit: "Unit", ingredientName: "Ingredient", step: "Step {n}", edit: "Edit recipe", delete: "Delete recipe", count: "{n} recipes",
    searchHint: "Search phrase for the picture", noResults: "No pictures found.", pickedUrl: "Picked picture", generateFirst: "Type a dish name first.", nothing: "Add ingredients or steps first.",
  },
  seed: {
    title: "Generate recipes", count: "How many", theme: "Theme (optional)", themeHint: "e.g. vegan, Shabbat dinners, quick lunches, Moroccan", days: "Spread over the last N days",
    likes: "Likes per recipe (up to)", author: "Published as", random: "A random persona each time", suggest: "Suggest dishes", suggesting: "Asking the model for dishes…",
    run: "Create {n} recipes", running: "Writing recipe {i} of {n}…", done: "{n} recipes published, {failed} failed", noPersonas: "Create a few personas first — the recipes are published in their names.",
    titles: "Dishes (edit or untick)", addTitle: "Add a dish", stop: "Stop after this one", by: "by",
  },
  seedPage: {
    intro: "Fill the community before launch: invent members, then let the model write recipes and conversations in their names, spread over the past weeks.",
    personas: "1. Personas", personasText: "Invented members with names and portraits. Everything below is published in their names.", personasBtn: "Manage personas", personasCount: "{n} personas",
    recipes: "2. Recipes", recipesText: "Dish names from the model, each recipe written, pictured and published by a random persona with likes.",
    forum: "3. Forum threads", forumText: "Whole conversations: a thread by one persona and replies by others, dated over the chosen span.",
  },
  seedForum: { title: "Generate threads", count: "How many threads", replies: "Replies per thread (up to)", run: "Create {n} threads", running: "Writing thread {i} of {n}…", done: "{n} threads published, {failed} failed", replyCount: "{n} replies" },
  units: { gram: "g", kilogram: "kg", milliliter: "ml", liter: "l", teaspoon: "tsp", tablespoon: "tbsp", cup: "cup", unit: "unit", pinch: "pinch", unspecified: "—" },
  diets: { meat: "Meat", dairy: "Dairy", vegetarian: "Vegetarian", vegan: "Vegan", kosher: "Kosher", glutenFree: "Gluten-free", allergy: "Allergy" },
  allergens: { gluten: "Gluten", milk: "Milk", eggs: "Eggs", fish: "Fish", shellfish: "Shellfish", peanuts: "Peanuts", treeNuts: "Tree nuts", sesame: "Sesame", soy: "Soy" },
  personas: {
    intro: "Invented community members. Threads, replies, recipes and likes can be posted as them so the community is not empty on launch day. They have no sign-in; the app shows them like any member.",
    suggest: "Suggest names", suggestCount: "How many", create: "Create persona", createManual: "Add by hand", gender: { male: "Man", female: "Woman" },
    photo: "Portrait", bio: "Note (only you see it)", createSelected: "Create {n} selected", created: "{n} personas created", deleteWithContent: "Delete with everything they posted",
    deleteKeep: "Delete persona, keep posts", posts: "threads", recipes: "recipes", newPortrait: "New random portrait", replies: "replies", none: "No personas yet.",
    count: "{n} personas", suggesting: "Asking the AI for names…", deleteTitle: "Delete {name}?", removed: "Removed: {posts} threads, {replies} replies, {recipes} recipes",
    deleteAll: "Delete all personas", deleteAllTitle: "Delete all {n} personas?", deleting: "Deleting {i} of {n}…", deletedAll: "{n} personas deleted",
    edit: "Edit persona", photoUpload: "Upload portrait", photoUrl: "Portrait link",
  },
  hh: { tier: "Plan", seats: "Seats", owner: "Owner", members: "Members", remove: "Remove member", dissolve: "Dissolve household", dissolveHint: "Members lose the inherited Premium; the shared data is deleted from the server. The owner's phone keeps its copy.", none: "No households yet.", tiers: { duo: "Pro Duo", family: "Pro Family" }, count: "{n} households", created: "Created", removed: "Member removed", dissolved: "Household dissolved" },
  tickets: {
    unread: "Unread", read: "Read", markRead: "Mark read", markUnread: "Mark unread", reply: "Reply", replied: "Replied", replies: "Your replies",
    types: { bug: "Bug", suggestion: "Suggestion" }, delete: "Delete ticket", none: "No tickets.", from: "From", appVersion: "App", yourReply: "Your reply",
    all: "All", sent: "Reply sent (inbox + push)", count: "{n} tickets",
  },
  config: {
    search: "Search parameters…", groups: { features: "Features", ads: "Ads & quotas", share: "Free-tier sharing", tts: "Voice", versions: "Versions", gemini: "Gemini (needs deploy)", other: "Other" },
    flags: { 0: "Hidden", 1: "Coming soon", 2: "Free for all", 3: "Premium only" }, add: "Add parameter", addHint: "Adds a parameter to the live template and publishes it. Give it a Hebrew/English heading in the app's i18n too.",
    name: "Key", type: "Type", value: "Value", description: "Description", group: "Group (optional)", delete: "Remove parameter", deleteHint: "The app falls back to its built-in default for a parameter that is gone.",
    saved: "Published (version {v})", version: "Template version {v}", deployNote: "gemini_* values only take effect on the next functions deploy.", filter: { all: "All states" },
    count: "{n} parameters", edited: "Edited", confirmDelete: "Remove {name} from Remote Config?",
  },
  audit: { when: "When", action: "Action", params: "Details", result: "Result", ok: "ok", failed: "failed", by: "By", count: "last {n} rows" },
  err: { network: "Network error", forbidden: "The server refused: administrator only", generic: "Failed: {message}", notConfigured: "Not configured on the server" },
};

const he = {
  lang: "שפה",
  signOut: "התנתקות",
  gate: {
    title: "EasyPlate Admin",
    intro: "קונסולת הניהול. מתחברים עם חשבון הגוגל של המנהל.",
    google: "כניסה עם Google",
    notAdmin: "החשבון הזה אינו המנהל. נותקת.",
    failed: "הכניסה נכשלה: {reason}",
    unauthorizedDomain: "הדומיין עדיין לא מאושר לכניסה. יש להוסיף את aieasyplate.app ב-Firebase Console → Authentication → Settings → Authorized domains.",
  },
  nav: { dashboard: "סקירה", users: "חשבונות", community: "קהילה", recipes: "מתכונים משותפים", personas: "דמויות", households: "חשבונות משותפים", tickets: "פניות", config: "תצורה", seed: "תנועה", audit: "יומן פעולות" },
  common: {
    save: "שמירה", cancel: "ביטול", delete: "מחיקה", edit: "עריכה", close: "סגירה", confirm: "אישור", yes: "כן", no: "לא",
    search: "חיפוש…", loading: "טוען…", none: "אין כאן כלום עדיין.", error: "משהו השתבש", done: "בוצע", refresh: "רענון",
    add: "הוספה", create: "יצירה", send: "שליחה", generate: "כתיבה עם AI", publish: "פרסום", back: "חזרה", copy: "העתקה", copied: "הועתק",
    all: "הכול", now: "עכשיו", unknown: "לא ידוע", name: "שם", email: "אימייל", phone: "טלפון", date: "תאריך", actions: "פעולות",
    title: "כותרת", body: "טקסט", more: "עוד", apply: "החלה", random: "אקראי", upload: "העלאה", url: "קישור", pick: "בחירה",
    remove: "הסרה", me: "אני (המנהל)", open: "פתיחה", filter: "סינון", count: "כמות", total: "סה״כ", status: "מצב",
    version: "גרסה", platform: "פלטפורמה", irreversible: "אי אפשר לבטל את הפעולה הזו.", working: "עובד…", id: "מזהה", yesDelete: "כן, למחוק",
    saved: "נשמר", deleted: "נמחק", sent: "נשלח", kept: "נשמר", nothingFound: "אין תוצאות.", language: "שפה", optional: "לא חובה",
    showMore: "הצג עוד", today: "היום", invalidJson: "JSON לא תקין", select: "בחירה", selected: "{n} נבחרו", unnamed: "(ללא שם)",
  },
  time: { justNow: "ממש עכשיו", never: "אף פעם" },
  dash: {
    range: { today: "היום", d30: "30 יום", d60: "60 יום", all: "מאז ומתמיד" },
    users: "חשבונות", newUsers: "חשבונות חדשים", premium: "פרימיום", disabled: "חסומים", online: "מחוברים עכשיו", withPush: "עם טוקן פוש",
    payments: "תשלומים", sandbox: "{n} בדיקה (sandbox) דולגו", aiCost: "עלות AI", aiCalls: "קריאות AI", tokens: "טוקנים", cacheHits: "פגיעות cache",
    recipes: "מתכונים משותפים", posts: "שרשורים", tickets: "פניות", personas: "דמויות", households: "חשבונות משותפים",
    byPlatform: "לפי פלטפורמה", byVersion: "לפי גרסת אפליקציה", byModel: "לפי מודל", byKind: "לפי פיצ׳ר", signups: "הרשמות ליום",
    dailyCost: "עלות AI ליום", topUsers: "חשבונות לפי עלות AI", syncPricing: "סנכרון מחירים", synced: "המחירים והשער עודכנו",
    costNote: "העלויות ב-₪ לפי {rate} ₪/$ (מחירים {source}, עודכן {when}).", searches: "חיפושים", cost: "עלות", calls: "קריאות",
    input: "קלט", output: "פלט", cached: "מטמון", noData: "אין נתונים לטווח הזה.", unpaid: "אין תשלומים", calc: "{calls} קריאות · {tokens} טוקנים",
  },
  users: {
    filter: { all: "הכול", online: "מחוברים", premium: "פרימיום", disabled: "חסומים", session: "עם סשן מכשיר" },
    online: "מחובר", offline: "לא מחובר", lastSeen: "נראה לאחרונה", device: "מכשיר", session: "סשן", sessionUntil: "עד {date}",
    noSession: "אין סשן", premium: "פרימיום", free: "חינמי", disabled: "חסום", broadcast: "הודעה לכולם", broadcastTitle: "הודעה לכל החשבונות",
    broadcastSent: "{items} הודעות בתיבה, {sent} פושים נשלחו, {failed} נכשלו", count: "{n} חשבונות", joined: "הצטרף", persona: "דמות",
    hint: "מחובר = האפליקציה פתוחה על הטלפון כרגע (דיווח כל דקה). ניתוק = משחרר את סשן המכשיר, האפליקציה מתנתקת מיד.",
  },
  user: {
    profile: "פרופיל", auth: "התחברות", providers: "ספקי כניסה", lastSignIn: "כניסה אחרונה", created: "נוצר", lastRefresh: "רענון טוקן אחרון",
    entitlement: "מנוי", premiumUntil: "פרימיום עד", adminLock: "נעילת מנהל (ה-webhook לא נוגע)", source: "מקור",
    setPremium: "הענקת פרימיום", removePremium: "הסרת פרימיום", premiumForever: "להשאיר ריק = בלי תאריך סיום", notify: "שליחת הודעה",
    disable: "חסימת חשבון", enable: "ביטול חסימה", kick: "ניתוק המכשיר", kickHint: "משחרר את סשן המכשיר ומבטל טוקנים; האפליקציה מתנתקת תוך שניות.",
    delete: "מחיקת חשבון", deleteHint: "מוחק את משתמש ה-Auth, הפרופיל, כל הקופסאות המשוקפות, התיבה, המנוי והשימוש. פוסטים בקהילה נשארים.",
    blockMessage: "הודעה שתוצג במסך החסימה", usage: "שימוש ב-AI", recentCalls: "קריאות AI אחרונות", inbox: "תיבת הודעות", content: "תוכן",
    collections: { recipes: "מתכונים", books: "ספרים", meal_plans: "תוכניות ארוחות", grocery_lists: "רשימות קניות", preferences: "העדפות", price_records: "רישומי מחירים", receipts: "קבלות", product_pricing: "מחירי מוצרים" },
    household: "חשבון משותף", shared: "פריטים משותפים", posts: "שרשורים", sharedRecipes: "מתכונים משותפים", feedback: "פניות", editJson: "עריכה כ-JSON",
    contentHint: "העריכה נכנסת לעותק בענן; הטלפון מושך אותה בהפעלה הבאה (או מיד, בתוך חשבון משותף).",
    root: { users: "אישי", households: "חשבון משותף" }, disabledBanner: "החשבון חסום: {message}", editProfile: "עריכת פרופיל",
    fullName: "שם מלא", photoUrl: "קישור לתמונה", noAuth: "אין משתמש Auth (נמחק או דמות)", tokensValidAfter: "טוקנים תקפים מאז", kicked: "המכשיר נותק",
    notified: "ההודעה נשלחה", shareCodes: "קודי שיתוף", invites: "הזמנות", none: "—", notFound: "החשבון לא נמצא", items: "{n} פריטים",
    model: "מודל", kind: "פיצ׳ר", when: "מתי", ms: "מ״ש", statusCol: "סטטוס", noUsage: "אין עדיין שימוש ב-AI", pushToken: "טוקן פוש", appVersion: "גרסת אפליקציה",
    disabledYes: "חסום", disabledNo: "פעיל", role: "תפקיד", members: "חברים", owner: "בעלים", collabRecipes: "מתכונים משותפים (collab)", collabContainers: "ספרים, תוכניות ורשימות משותפים",
    tokenUntil: "תוקף הטוקן הנוכחי", tokenExpired: "פג", tokenLive: "בתוקף", tokenHint: "טוקן זיהוי חי שעה מהרענון האחרון; המכשיר מחדש אותו בשקט כל עוד הוא מחובר.",
    uses: "שימושים", revoked: "בוטל", expires: "פג", kind2: "סוג",
  },
  forum: {
    newThread: "שרשור חדש", replies: "{n} תגובות", reply: "תגובה", as: "לפרסם בשם", asMe: "אני (המנהל)", draftAi: "כתיבה עם AI",
    topic: "נושא או זווית (לא חובה)", backdate: "תאריך", randomDate: "תאריך אקראי ב-{days} הימים האחרונים", likes: "{n} לייקים",
    seedLikes: "הוספת לייקים", seedLikesCount: "כמה דמויות יעשו לייק?", likeAs: "לייק בשם…", deleteThread: "מחיקת השרשור (עם התגובות)",
    deleteReply: "מחיקת התגובה", edit: "עריכה", posted: "פורסם", noPersonas: "אין דמויות עדיין — צרו כמה בלשונית דמויות.", thread: "שרשור",
    open: "פתיחת השרשור", recipeLink: "מתכון מצורף", pending: "ממתין", threads: "{n} שרשורים", added: "נוספו {n} לייקים", context: "טקסט השרשור ל-AI",
    live: "חי", editThread: "עריכת שרשור", editReply: "עריכת תגובה",
  },
  recipes: {
    new: "מתכון משותף חדש", generate: "יצירת מתכון", generating: "כותב את המתכון…", titleHint: "שם המנה, למשל שקשוקה",
    hints: "בקשות ל-AI (לא חובה)", language: "שפת המתכון", ingredients: "מצרכים", steps: "שלבים", servings: "מנות",
    prep: "הכנה (דק׳)", cook: "בישול (דק׳)", tags: "תגיות תזונה", allergens: "מכיל", mayContain: "עלול להכיל", nutrition: "ערכים תזונתיים למנה",
    calories: "קלוריות", protein: "חלבון (ג׳)", carbs: "פחמימות (ג׳)", fat: "שומן (ג׳)", image: "תמונה", imageSearch: "חיפוש בתמונות Google",
    imageUrl: "קישור לתמונה", imageUpload: "העלאת תמונה", imageKeep: "להשאיר את הנוכחית", noImage: "בלי תמונה", searchMore: "עוד תוצאות",
    publish: "פרסום לקהילה", published: "המתכון פורסם", by: "מאת", addIngredient: "הוספת מצרך", addStep: "הוספת שלב",
    amount: "כמות", unit: "יחידה", ingredientName: "מצרך", step: "שלב {n}", edit: "עריכת מתכון", delete: "מחיקת מתכון", count: "{n} מתכונים",
    searchHint: "ביטוי חיפוש לתמונה", noResults: "לא נמצאו תמונות.", pickedUrl: "התמונה שנבחרה", generateFirst: "קודם צריך שם מנה.", nothing: "קודם צריך מצרכים או שלבים.",
  },
  seed: {
    title: "יצירת מתכונים", count: "כמה", theme: "נושא (לא חובה)", themeHint: "למשל טבעוני, ארוחות שבת, צהריים מהירים, מרוקאי", days: "לפזר על פני N הימים האחרונים",
    likes: "לייקים למתכון (עד)", author: "מתפרסם בשם", random: "דמות אקראית בכל פעם", suggest: "הצעת מנות", suggesting: "מבקש מנות מהמודל…",
    run: "יצירת {n} מתכונים", running: "כותב מתכון {i} מתוך {n}…", done: "{n} מתכונים פורסמו, {failed} נכשלו", noPersonas: "קודם צרו כמה דמויות — המתכונים מתפרסמים בשמן.",
    titles: "מנות (אפשר לערוך או לבטל סימון)", addTitle: "הוספת מנה", stop: "לעצור אחרי הנוכחי", by: "מאת",
  },
  seedPage: {
    intro: "למלא את הקהילה לפני ההשקה: ממציאים חברים, ואז המודל כותב בשמם מתכונים ושיחות, מפוזרים על פני השבועות האחרונים.",
    personas: "1. דמויות", personasText: "חברים מומצאים עם שמות ותמונות. כל מה שלמטה מתפרסם בשמם.", personasBtn: "ניהול דמויות", personasCount: "{n} דמויות",
    recipes: "2. מתכונים", recipesText: "שמות מנות מהמודל, כל מתכון נכתב, מקבל תמונה ומתפרסם בשם דמות אקראית עם לייקים.",
    forum: "3. שרשורים בפורום", forumText: "שיחות שלמות: שרשור של דמות אחת ותגובות של אחרות, מתוארכים על פני הטווח שנבחר.",
  },
  seedForum: { title: "יצירת שרשורים", count: "כמה שרשורים", replies: "תגובות לשרשור (עד)", run: "יצירת {n} שרשורים", running: "כותב שרשור {i} מתוך {n}…", done: "{n} שרשורים פורסמו, {failed} נכשלו", replyCount: "{n} תגובות" },
  units: { gram: "גרם", kilogram: "ק״ג", milliliter: "מ״ל", liter: "ליטר", teaspoon: "כפית", tablespoon: "כף", cup: "כוס", unit: "יח׳", pinch: "קמצוץ", unspecified: "—" },
  diets: { meat: "בשרי", dairy: "חלבי", vegetarian: "צמחוני", vegan: "טבעוני", kosher: "כשר", glutenFree: "ללא גלוטן", allergy: "אלרגיה" },
  allergens: { gluten: "גלוטן", milk: "חלב", eggs: "ביצים", fish: "דגים", shellfish: "פירות ים", peanuts: "בוטנים", treeNuts: "אגוזים", sesame: "שומשום", soy: "סויה" },
  personas: {
    intro: "חברי קהילה מומצאים. אפשר לפרסם בשמם שרשורים, תגובות, מתכונים ולייקים, כדי שהקהילה לא תהיה ריקה ביום ההשקה. אין להם כניסה; האפליקציה מציגה אותם כמו כל חבר.",
    suggest: "הצעת שמות", suggestCount: "כמה", create: "יצירת דמות", createManual: "הוספה ידנית", gender: { male: "גבר", female: "אישה" },
    photo: "תמונת פרופיל", bio: "הערה (רק אתה רואה)", createSelected: "יצירת {n} שנבחרו", created: "נוצרו {n} דמויות", deleteWithContent: "מחיקה כולל כל מה שפרסמו",
    deleteKeep: "מחיקת הדמות, השארת הפוסטים", posts: "שרשורים", recipes: "מתכונים", newPortrait: "תמונה אקראית חדשה", replies: "תגובות", none: "אין דמויות עדיין.",
    count: "{n} דמויות", suggesting: "מבקש שמות מה-AI…", deleteTitle: "למחוק את {name}?", removed: "הוסרו: {posts} שרשורים, {replies} תגובות, {recipes} מתכונים",
    deleteAll: "מחיקת כל הדמויות", deleteAllTitle: "למחוק את כל {n} הדמויות?", deleting: "מוחק {i} מתוך {n}…", deletedAll: "{n} דמויות נמחקו",
    edit: "עריכת דמות", photoUpload: "העלאת תמונה", photoUrl: "קישור לתמונה",
  },
  hh: { tier: "תוכנית", seats: "מקומות", owner: "בעלים", members: "חברים", remove: "הסרת חבר", dissolve: "פירוק החשבון המשותף", dissolveHint: "החברים מאבדים את הפרימיום שירשו; המידע המשותף נמחק מהשרת. הטלפון של הבעלים שומר עותק.", none: "אין חשבונות משותפים עדיין.", tiers: { duo: "Pro Duo", family: "Pro Family" }, count: "{n} חשבונות משותפים", created: "נוצר", removed: "החבר הוסר", dissolved: "החשבון המשותף פורק" },
  tickets: {
    unread: "לא נקראו", read: "נקראו", markRead: "סימון כנקרא", markUnread: "סימון כלא נקרא", reply: "תגובה", replied: "נענה", replies: "התשובות שלך",
    types: { bug: "באג", suggestion: "הצעה" }, delete: "מחיקת הפנייה", none: "אין פניות.", from: "מאת", appVersion: "אפליקציה", yourReply: "התשובה שלך",
    all: "הכול", sent: "התשובה נשלחה (תיבה + פוש)", count: "{n} פניות",
  },
  config: {
    search: "חיפוש פרמטרים…", groups: { features: "פיצ׳רים", ads: "פרסומות ומכסות", share: "שיתוף בחינם", tts: "קול", versions: "גרסאות", gemini: "Gemini (דורש deploy)", other: "אחר" },
    flags: { 0: "לא מוצג", 1: "בקרוב", 2: "חינמי לכולם", 3: "רק לפרימיום" }, add: "הוספת פרמטר", addHint: "מוסיף פרמטר לתבנית החיה ומפרסם. כדאי לתת לו כותרת בעברית/אנגלית גם ב-i18n של האפליקציה.",
    name: "מפתח", type: "סוג", value: "ערך", description: "תיאור", group: "קבוצה (לא חובה)", delete: "הסרת פרמטר", deleteHint: "האפליקציה חוזרת לברירת המחדל המובנית של פרמטר שנעלם.",
    saved: "פורסם (גרסה {v})", version: "גרסת תבנית {v}", deployNote: "ערכי gemini_* נכנסים לתוקף רק ב-deploy הבא של הפונקציות.", filter: { all: "כל המצבים" },
    count: "{n} פרמטרים", edited: "נערך", confirmDelete: "להסיר את {name} מ-Remote Config?",
  },
  audit: { when: "מתי", action: "פעולה", params: "פרטים", result: "תוצאה", ok: "הצליח", failed: "נכשל", by: "מי", count: "{n} השורות האחרונות" },
  err: { network: "שגיאת רשת", forbidden: "השרת סירב: למנהל בלבד", generic: "נכשל: {message}", notConfigured: "לא מוגדר בשרת" },
};

const ar = {
  lang: "اللغة",
  signOut: "تسجيل الخروج",
  gate: { title: "EasyPlate Admin", intro: "لوحة الإدارة. سجّل الدخول بحساب Google الخاص بالمسؤول.", google: "تسجيل الدخول عبر Google", notAdmin: "هذا الحساب ليس المسؤول. تم تسجيل خروجك.", failed: "فشل تسجيل الدخول: {reason}", unauthorizedDomain: "هذا النطاق غير مصرّح به بعد لتسجيل الدخول. أضف aieasyplate.app في Firebase Console → Authentication → Settings → Authorized domains." },
  nav: { dashboard: "نظرة عامة", users: "الحسابات", community: "المجتمع", recipes: "الوصفات المشتركة", personas: "الشخصيات", households: "الحسابات المشتركة", tickets: "الرسائل", config: "الإعدادات", seed: "النشاط", audit: "سجل الإجراءات" },
  common: {
    save: "حفظ", cancel: "إلغاء", delete: "حذف", edit: "تعديل", close: "إغلاق", confirm: "تأكيد", yes: "نعم", no: "لا",
    search: "بحث…", loading: "جارٍ التحميل…", none: "لا شيء هنا بعد.", error: "حدث خطأ ما", done: "تم", refresh: "تحديث",
    add: "إضافة", create: "إنشاء", send: "إرسال", generate: "كتابة بالذكاء الاصطناعي", publish: "نشر", back: "رجوع", copy: "نسخ", copied: "تم النسخ",
    all: "الكل", now: "الآن", unknown: "غير معروف", name: "الاسم", email: "البريد", phone: "الهاتف", date: "التاريخ", actions: "إجراءات",
    title: "العنوان", body: "النص", more: "المزيد", apply: "تطبيق", random: "عشوائي", upload: "رفع", url: "رابط", pick: "اختيار",
    remove: "إزالة", me: "أنا (المسؤول)", open: "فتح", filter: "تصفية", count: "العدد", total: "الإجمالي", status: "الحالة",
    version: "الإصدار", platform: "المنصة", irreversible: "لا يمكن التراجع عن هذا.", working: "جارٍ العمل…", id: "المعرّف", yesDelete: "نعم، احذف",
    saved: "تم الحفظ", deleted: "تم الحذف", sent: "تم الإرسال", kept: "تم الإبقاء", nothingFound: "لا نتائج.", language: "اللغة", optional: "اختياري",
    showMore: "عرض المزيد", today: "اليوم", invalidJson: "JSON غير صالح", select: "اختيار", selected: "{n} محددة", unnamed: "(بلا اسم)",
  },
  time: { justNow: "الآن", never: "أبدًا" },
  dash: {
    range: { today: "اليوم", d30: "30 يومًا", d60: "60 يومًا", all: "منذ البداية" },
    users: "الحسابات", newUsers: "حسابات جديدة", premium: "بريميوم", disabled: "محظورة", online: "متصلون الآن", withPush: "لديهم رمز إشعارات",
    payments: "المدفوعات", sandbox: "تم تخطي {n} تجريبية", aiCost: "تكلفة AI", aiCalls: "استدعاءات AI", tokens: "الرموز", cacheHits: "إصابات الذاكرة المؤقتة",
    recipes: "وصفات مشتركة", posts: "مواضيع", tickets: "رسائل", personas: "شخصيات", households: "حسابات مشتركة",
    byPlatform: "حسب المنصة", byVersion: "حسب إصدار التطبيق", byModel: "حسب النموذج", byKind: "حسب الميزة", signups: "التسجيلات يوميًا",
    dailyCost: "تكلفة AI يوميًا", topUsers: "الحسابات حسب تكلفة AI", syncPricing: "مزامنة الأسعار", synced: "تم تحديث الأسعار وسعر الصرف",
    costNote: "التكاليف بالشيكل حسب {rate} ₪/$ (الأسعار {source}، حُدّثت {when}).", searches: "عمليات البحث", cost: "التكلفة", calls: "الاستدعاءات",
    input: "إدخال", output: "إخراج", cached: "مخزّن", noData: "لا بيانات لهذه الفترة.", unpaid: "لا مدفوعات", calc: "{calls} استدعاء · {tokens} رمز",
  },
  users: {
    filter: { all: "الكل", online: "متصل", premium: "بريميوم", disabled: "محظور", session: "بجلسة جهاز" },
    online: "متصل", offline: "غير متصل", lastSeen: "آخر ظهور", device: "الجهاز", session: "الجلسة", sessionUntil: "حتى {date}",
    noSession: "لا جلسة", premium: "بريميوم", free: "مجاني", disabled: "محظور", broadcast: "رسالة للجميع", broadcastTitle: "رسالة إلى كل الحسابات",
    broadcastSent: "{items} في صناديق الوارد، {sent} إشعارًا أُرسل، {failed} فشل", count: "{n} حسابات", joined: "انضم", persona: "شخصية",
    hint: "متصل = التطبيق مفتوح على الهاتف الآن (يُبلّغ كل دقيقة). فصل = يحرر جلسة الجهاز ويخرج التطبيق فورًا.",
  },
  user: {
    profile: "الملف الشخصي", auth: "تسجيل الدخول", providers: "مزوّدو الدخول", lastSignIn: "آخر دخول", created: "أُنشئ", lastRefresh: "آخر تجديد للرمز",
    entitlement: "الاشتراك", premiumUntil: "بريميوم حتى", adminLock: "قفل المسؤول (الـ webhook لا يلمسه)", source: "المصدر",
    setPremium: "منح بريميوم", removePremium: "إزالة بريميوم", premiumForever: "اتركه فارغًا بلا تاريخ انتهاء", notify: "إرسال رسالة",
    disable: "حظر الحساب", enable: "إلغاء الحظر", kick: "فصل الجهاز", kickHint: "يحرر جلسة الجهاز ويلغي الرموز؛ يخرج التطبيق خلال ثوانٍ.",
    delete: "حذف الحساب", deleteHint: "يحذف مستخدم Auth والملف الشخصي وكل البيانات المنسوخة وصندوق الوارد والاشتراك والاستخدام. تبقى منشورات المجتمع.",
    blockMessage: "رسالة تظهر في شاشة الحظر", usage: "استخدام AI", recentCalls: "آخر استدعاءات AI", inbox: "صندوق الوارد", content: "المحتوى",
    collections: { recipes: "وصفات", books: "كتب", meal_plans: "خطط وجبات", grocery_lists: "قوائم تسوق", preferences: "التفضيلات", price_records: "سجلات الأسعار", receipts: "الإيصالات", product_pricing: "أسعار المنتجات" },
    household: "حساب مشترك", shared: "عناصر مشتركة", posts: "مواضيع", sharedRecipes: "وصفات مشتركة", feedback: "رسائل", editJson: "تعديل كـ JSON",
    contentHint: "تصل التعديلات إلى النسخة السحابية؛ يلتقطها الهاتف عند تشغيله التالي (أو فورًا داخل حساب مشترك).",
    root: { users: "شخصي", households: "حساب مشترك" }, disabledBanner: "هذا الحساب محظور: {message}", editProfile: "تعديل الملف",
    fullName: "الاسم الكامل", photoUrl: "رابط الصورة", noAuth: "لا مستخدم Auth (محذوف أو شخصية)", tokensValidAfter: "الرموز صالحة منذ", kicked: "تم فصل الجهاز",
    notified: "أُرسلت الرسالة", shareCodes: "رموز المشاركة", invites: "الدعوات", none: "—", notFound: "الحساب غير موجود", items: "{n} عناصر",
    model: "النموذج", kind: "الميزة", when: "متى", ms: "م.ث", statusCol: "الحالة", noUsage: "لا استخدام AI بعد", pushToken: "رمز الإشعارات", appVersion: "إصدار التطبيق",
    disabledYes: "محظور", disabledNo: "نشط", role: "الدور", members: "الأعضاء", owner: "المالك", collabRecipes: "وصفات مشتركة (collab)", collabContainers: "كتب وخطط وقوائم مشتركة",
    tokenUntil: "صلاحية الرمز الحالي حتى", tokenExpired: "منتهٍ", tokenLive: "ساري", tokenHint: "يعيش رمز الهوية ساعة من آخر تجديد؛ يجدده الجهاز بصمت ما دام متصلًا.",
    uses: "استخدامات", revoked: "ملغى", expires: "ينتهي", kind2: "النوع",
  },
  forum: {
    newThread: "موضوع جديد", replies: "{n} ردود", reply: "رد", as: "النشر باسم", asMe: "أنا (المسؤول)", draftAi: "كتابة بالذكاء الاصطناعي",
    topic: "الموضوع أو الزاوية (اختياري)", backdate: "التاريخ", randomDate: "تاريخ عشوائي في آخر {days} يومًا", likes: "{n} إعجابات",
    seedLikes: "إضافة إعجابات", seedLikesCount: "كم شخصية ستُعجب بهذا؟", likeAs: "إعجاب باسم…", deleteThread: "حذف الموضوع (مع الردود)",
    deleteReply: "حذف الرد", edit: "تعديل", posted: "نُشر", noPersonas: "لا شخصيات بعد — أنشئ بعضها في الشخصيات.", thread: "موضوع",
    open: "فتح الموضوع", recipeLink: "وصفة مرفقة", pending: "قيد الانتظار", threads: "{n} مواضيع", added: "أُضيف {n} إعجابًا", context: "نص الموضوع للذكاء الاصطناعي",
    live: "مباشر", editThread: "تعديل الموضوع", editReply: "تعديل الرد",
  },
  recipes: {
    new: "وصفة مشتركة جديدة", generate: "توليد وصفة", generating: "جارٍ كتابة الوصفة…", titleHint: "اسم الطبق، مثل شكشوكة",
    hints: "رغبات للذكاء الاصطناعي (اختياري)", language: "لغة الوصفة", ingredients: "المكونات", steps: "الخطوات", servings: "الحصص",
    prep: "التحضير (د)", cook: "الطهي (د)", tags: "وسوم غذائية", allergens: "يحتوي", mayContain: "قد يحتوي", nutrition: "القيم الغذائية للحصة",
    calories: "سعرات", protein: "بروتين (غ)", carbs: "كربوهيدرات (غ)", fat: "دهون (غ)", image: "الصورة", imageSearch: "بحث في صور Google",
    imageUrl: "رابط الصورة", imageUpload: "رفع صورة", imageKeep: "الإبقاء على الحالية", noImage: "بلا صورة", searchMore: "نتائج أكثر",
    publish: "نشر في المجتمع", published: "نُشرت الوصفة", by: "بواسطة", addIngredient: "إضافة مكوّن", addStep: "إضافة خطوة",
    amount: "الكمية", unit: "الوحدة", ingredientName: "المكوّن", step: "الخطوة {n}", edit: "تعديل الوصفة", delete: "حذف الوصفة", count: "{n} وصفات",
    searchHint: "عبارة البحث عن الصورة", noResults: "لم يُعثر على صور.", pickedUrl: "الصورة المختارة", generateFirst: "اكتب اسم الطبق أولًا.", nothing: "أضف مكونات أو خطوات أولًا.",
  },
  seed: {
    title: "توليد وصفات", count: "كم", theme: "الموضوع (اختياري)", themeHint: "مثل نباتي، عشاء السبت، غداء سريع، مغربي", days: "توزيع على آخر N يومًا",
    likes: "إعجابات لكل وصفة (حتى)", author: "تُنشر باسم", random: "شخصية عشوائية كل مرة", suggest: "اقتراح أطباق", suggesting: "جارٍ طلب أطباق من النموذج…",
    run: "إنشاء {n} وصفات", running: "جارٍ كتابة الوصفة {i} من {n}…", done: "نُشرت {n} وصفات، فشلت {failed}", noPersonas: "أنشئ بعض الشخصيات أولًا — تُنشر الوصفات بأسمائها.",
    titles: "الأطباق (عدّل أو ألغِ التحديد)", addTitle: "إضافة طبق", stop: "التوقف بعد الحالي", by: "بواسطة",
  },
  seedPage: {
    intro: "املأ المجتمع قبل الإطلاق: اخترع أعضاء، ثم دع النموذج يكتب باسمهم وصفات ومحادثات موزعة على الأسابيع الماضية.",
    personas: "1. الشخصيات", personasText: "أعضاء مُخترَعون بأسماء وصور. كل ما يلي يُنشر بأسمائهم.", personasBtn: "إدارة الشخصيات", personasCount: "{n} شخصيات",
    recipes: "2. الوصفات", recipesText: "أسماء أطباق من النموذج، كل وصفة تُكتب وتُصوَّر وتُنشر باسم شخصية عشوائية مع إعجابات.",
    forum: "3. مواضيع المنتدى", forumText: "محادثات كاملة: موضوع من شخصية وردود من أخريات، مؤرخة على المدى المختار.",
  },
  seedForum: { title: "توليد مواضيع", count: "كم موضوعًا", replies: "ردود لكل موضوع (حتى)", run: "إنشاء {n} مواضيع", running: "جارٍ كتابة الموضوع {i} من {n}…", done: "نُشر {n} مواضيع، فشل {failed}", replyCount: "{n} ردود" },
  units: { gram: "غ", kilogram: "كغ", milliliter: "مل", liter: "ل", teaspoon: "ملعقة صغيرة", tablespoon: "ملعقة كبيرة", cup: "كوب", unit: "وحدة", pinch: "رشة", unspecified: "—" },
  diets: { meat: "لحوم", dairy: "ألبان", vegetarian: "نباتي", vegan: "نباتي صرف", kosher: "كوشر", glutenFree: "خالٍ من الغلوتين", allergy: "حساسية" },
  allergens: { gluten: "غلوتين", milk: "حليب", eggs: "بيض", fish: "سمك", shellfish: "قشريات", peanuts: "فول سوداني", treeNuts: "مكسرات", sesame: "سمسم", soy: "صويا" },
  personas: {
    intro: "أعضاء مجتمع مُخترَعون. يمكن نشر مواضيع وردود ووصفات وإعجابات باسمهم حتى لا يكون المجتمع فارغًا يوم الإطلاق. لا تسجيل دخول لهم؛ يعرضهم التطبيق كأي عضو.",
    suggest: "اقتراح أسماء", suggestCount: "كم", create: "إنشاء شخصية", createManual: "إضافة يدويًا", gender: { male: "رجل", female: "امرأة" },
    photo: "الصورة", bio: "ملاحظة (تراها أنت فقط)", createSelected: "إنشاء {n} محددة", created: "أُنشئت {n} شخصيات", deleteWithContent: "حذف مع كل ما نشروه",
    deleteKeep: "حذف الشخصية والإبقاء على المنشورات", posts: "مواضيع", recipes: "وصفات", newPortrait: "صورة عشوائية جديدة", replies: "ردود", none: "لا شخصيات بعد.",
    count: "{n} شخصيات", suggesting: "جارٍ طلب أسماء من الذكاء الاصطناعي…", deleteTitle: "حذف {name}؟", removed: "أُزيل: {posts} مواضيع، {replies} ردود، {recipes} وصفات",
    deleteAll: "حذف كل الشخصيات", deleteAllTitle: "حذف كل الشخصيات ({n})؟", deleting: "جارٍ حذف {i} من {n}…", deletedAll: "حُذفت {n} شخصيات",
    edit: "تعديل الشخصية", photoUpload: "رفع صورة", photoUrl: "رابط الصورة",
  },
  hh: { tier: "الخطة", seats: "المقاعد", owner: "المالك", members: "الأعضاء", remove: "إزالة عضو", dissolve: "حل الحساب المشترك", dissolveHint: "يفقد الأعضاء البريميوم الموروث؛ تُحذف البيانات المشتركة من الخادم. يحتفظ هاتف المالك بنسخته.", none: "لا حسابات مشتركة بعد.", tiers: { duo: "Pro Duo", family: "Pro Family" }, count: "{n} حسابات مشتركة", created: "أُنشئ", removed: "أُزيل العضو", dissolved: "تم حل الحساب المشترك" },
  tickets: {
    unread: "غير مقروءة", read: "مقروءة", markRead: "تعليم كمقروء", markUnread: "تعليم كغير مقروء", reply: "رد", replied: "تم الرد", replies: "ردودك",
    types: { bug: "خلل", suggestion: "اقتراح" }, delete: "حذف الرسالة", none: "لا رسائل.", from: "من", appVersion: "التطبيق", yourReply: "ردك",
    all: "الكل", sent: "أُرسل الرد (صندوق الوارد + إشعار)", count: "{n} رسائل",
  },
  config: {
    search: "بحث في المعاملات…", groups: { features: "الميزات", ads: "الإعلانات والحصص", share: "المشاركة المجانية", tts: "الصوت", versions: "الإصدارات", gemini: "Gemini (يتطلب نشرًا)", other: "أخرى" },
    flags: { 0: "مخفي", 1: "قريبًا", 2: "مجاني للجميع", 3: "بريميوم فقط" }, add: "إضافة معامل", addHint: "يضيف معاملًا إلى القالب الحي وينشره. أعطه عنوانًا في i18n التطبيق أيضًا.",
    name: "المفتاح", type: "النوع", value: "القيمة", description: "الوصف", group: "المجموعة (اختياري)", delete: "إزالة المعامل", deleteHint: "يعود التطبيق إلى قيمته المدمجة لمعامل اختفى.",
    saved: "نُشر (الإصدار {v})", version: "إصدار القالب {v}", deployNote: "قيم gemini_* تسري فقط عند النشر التالي للدوال.", filter: { all: "كل الحالات" },
    count: "{n} معاملات", edited: "عُدّل", confirmDelete: "إزالة {name} من Remote Config؟",
  },
  audit: { when: "متى", action: "الإجراء", params: "التفاصيل", result: "النتيجة", ok: "نجح", failed: "فشل", by: "بواسطة", count: "آخر {n} صف" },
  err: { network: "خطأ في الشبكة", forbidden: "رفض الخادم: للمسؤول فقط", generic: "فشل: {message}", notConfigured: "غير مهيأ على الخادم" },
};

const fr = {
  lang: "Langue",
  signOut: "Se déconnecter",
  gate: { title: "EasyPlate Admin", intro: "La console d’administration. Connectez-vous avec le compte Google de l’administrateur.", google: "Se connecter avec Google", notAdmin: "Ce compte n’est pas l’administrateur. Vous avez été déconnecté.", failed: "Connexion échouée : {reason}", unauthorizedDomain: "Ce domaine n’est pas encore autorisé pour la connexion. Ajoutez aieasyplate.app dans Firebase Console → Authentication → Settings → Authorized domains." },
  nav: { dashboard: "Tableau de bord", users: "Comptes", community: "Communauté", recipes: "Recettes partagées", personas: "Personas", households: "Comptes partagés", tickets: "Tickets", config: "Configuration", seed: "Activité", audit: "Journal" },
  common: {
    save: "Enregistrer", cancel: "Annuler", delete: "Supprimer", edit: "Modifier", close: "Fermer", confirm: "Confirmer", yes: "Oui", no: "Non",
    search: "Rechercher…", loading: "Chargement…", none: "Rien ici pour l’instant.", error: "Une erreur est survenue", done: "Terminé", refresh: "Actualiser",
    add: "Ajouter", create: "Créer", send: "Envoyer", generate: "Écrire avec l’IA", publish: "Publier", back: "Retour", copy: "Copier", copied: "Copié",
    all: "Tout", now: "Maintenant", unknown: "inconnu", name: "Nom", email: "E-mail", phone: "Téléphone", date: "Date", actions: "Actions",
    title: "Titre", body: "Texte", more: "Plus", apply: "Appliquer", random: "Aléatoire", upload: "Téléverser", url: "Lien", pick: "Choisir",
    remove: "Retirer", me: "Moi (administrateur)", open: "Ouvrir", filter: "Filtrer", count: "Nombre", total: "Total", status: "État",
    version: "Version", platform: "Plateforme", irreversible: "Cette action est irréversible.", working: "En cours…", id: "ID", yesDelete: "Oui, supprimer",
    saved: "Enregistré", deleted: "Supprimé", sent: "Envoyé", kept: "Conservé", nothingFound: "Aucun résultat.", language: "Langue", optional: "facultatif",
    showMore: "Afficher plus", today: "Aujourd’hui", invalidJson: "JSON invalide", select: "Sélectionner", selected: "{n} sélectionné(s)", unnamed: "(sans nom)",
  },
  time: { justNow: "à l’instant", never: "jamais" },
  dash: {
    range: { today: "Aujourd’hui", d30: "30 jours", d60: "60 jours", all: "Depuis le début" },
    users: "Comptes", newUsers: "Nouveaux comptes", premium: "Premium", disabled: "Bloqués", online: "En ligne", withPush: "Avec jeton push",
    payments: "Paiements", sandbox: "{n} sandbox ignorés", aiCost: "Coût IA", aiCalls: "Appels IA", tokens: "Jetons", cacheHits: "Hits de cache",
    recipes: "Recettes partagées", posts: "Fils", tickets: "Tickets", personas: "Personas", households: "Comptes partagés",
    byPlatform: "Par plateforme", byVersion: "Par version", byModel: "Par modèle", byKind: "Par fonction", signups: "Inscriptions par jour",
    dailyCost: "Coût IA par jour", topUsers: "Comptes par coût IA", syncPricing: "Synchroniser les prix", synced: "Prix et taux actualisés",
    costNote: "Coûts en ₪ à {rate} ₪/$ (prix {source}, mis à jour {when}).", searches: "Recherches", cost: "Coût", calls: "Appels",
    input: "Entrée", output: "Sortie", cached: "Cache", noData: "Pas de données pour cette période.", unpaid: "aucun paiement", calc: "{calls} appels · {tokens} jetons",
  },
  users: {
    filter: { all: "Tous", online: "En ligne", premium: "Premium", disabled: "Bloqués", session: "Avec session" },
    online: "En ligne", offline: "Hors ligne", lastSeen: "Vu", device: "Appareil", session: "Session", sessionUntil: "jusqu’au {date}",
    noSession: "pas de session", premium: "Premium", free: "Gratuit", disabled: "Bloqué", broadcast: "Message à tous", broadcastTitle: "Message à tous les comptes",
    broadcastSent: "{items} messages, {sent} push envoyés, {failed} échecs", count: "{n} comptes", joined: "Inscrit", persona: "Persona",
    hint: "En ligne = l’app est ouverte sur un téléphone en ce moment (signalé chaque minute). Déconnecter libère la session ; l’app se déconnecte aussitôt.",
  },
  user: {
    profile: "Profil", auth: "Connexion", providers: "Fournisseurs", lastSignIn: "Dernière connexion", created: "Créé", lastRefresh: "Dernier rafraîchissement",
    entitlement: "Abonnement", premiumUntil: "Premium jusqu’au", adminLock: "Verrou admin (le webhook n’y touche pas)", source: "Source",
    setPremium: "Accorder Premium", removePremium: "Retirer Premium", premiumForever: "Laisser vide pour aucune fin", notify: "Envoyer un message",
    disable: "Bloquer le compte", enable: "Débloquer", kick: "Déconnecter l’appareil", kickHint: "Libère la session et révoque les jetons ; l’app se déconnecte en quelques secondes.",
    delete: "Supprimer le compte", deleteHint: "Supprime l’utilisateur Auth, le profil, toutes les données miroir, la boîte de réception, l’abonnement et l’usage. Les posts restent.",
    blockMessage: "Message affiché sur l’écran de blocage", usage: "Usage IA", recentCalls: "Derniers appels IA", inbox: "Boîte de réception", content: "Contenu",
    collections: { recipes: "Recettes", books: "Livres", meal_plans: "Plans de repas", grocery_lists: "Listes de courses", preferences: "Préférences", price_records: "Relevés de prix", receipts: "Tickets de caisse", product_pricing: "Prix des produits" },
    household: "Compte partagé", shared: "Éléments partagés", posts: "Fils", sharedRecipes: "Recettes partagées", feedback: "Tickets", editJson: "Modifier en JSON",
    contentHint: "Les modifications vont dans la copie cloud ; le téléphone les récupère au prochain démarrage (ou en direct dans un compte partagé).",
    root: { users: "Personnel", households: "Compte partagé" }, disabledBanner: "Ce compte est bloqué : {message}", editProfile: "Modifier le profil",
    fullName: "Nom complet", photoUrl: "URL de la photo", noAuth: "Pas d’utilisateur Auth (supprimé ou persona)", tokensValidAfter: "Jetons valides depuis", kicked: "Appareil déconnecté",
    notified: "Message envoyé", shareCodes: "Codes de partage", invites: "Invitations", none: "—", notFound: "Compte introuvable", items: "{n} éléments",
    model: "Modèle", kind: "Fonction", when: "Quand", ms: "ms", statusCol: "Statut", noUsage: "Pas encore d’usage IA", pushToken: "Jeton push", appVersion: "Version de l’app",
    disabledYes: "Bloqué", disabledNo: "Actif", role: "Rôle", members: "Membres", owner: "Propriétaire", collabRecipes: "Recettes partagées (collab)", collabContainers: "Livres, plans et listes partagés",
    tokenUntil: "Jeton actuel valable jusqu’au", tokenExpired: "expiré", tokenLive: "valide", tokenHint: "Un jeton d’identité vit une heure après son dernier rafraîchissement ; l’appareil le renouvelle en silence tant qu’il est connecté.",
    uses: "utilisations", revoked: "révoqué", expires: "expire", kind2: "Type",
  },
  forum: {
    newThread: "Nouveau fil", replies: "{n} réponses", reply: "Répondre", as: "Publier en tant que", asMe: "Moi (administrateur)", draftAi: "Écrire avec l’IA",
    topic: "Sujet ou angle (facultatif)", backdate: "Date", randomDate: "Date aléatoire dans les {days} derniers jours", likes: "{n} j’aime",
    seedLikes: "Ajouter des j’aime", seedLikesCount: "Combien de personas doivent aimer ceci ?", likeAs: "Aimer en tant que…", deleteThread: "Supprimer le fil (avec réponses)",
    deleteReply: "Supprimer la réponse", edit: "Modifier", posted: "Publié", noPersonas: "Pas encore de personas — créez-en dans Personas.", thread: "Fil",
    open: "Ouvrir le fil", recipeLink: "Recette jointe", pending: "en attente", threads: "{n} fils", added: "{n} j’aime ajoutés", context: "Texte du fil pour l’IA",
    live: "Direct", editThread: "Modifier le fil", editReply: "Modifier la réponse",
  },
  recipes: {
    new: "Nouvelle recette partagée", generate: "Générer la recette", generating: "Rédaction de la recette…", titleHint: "Nom du plat, p. ex. Shakshuka",
    hints: "Souhaits pour l’IA (facultatif)", language: "Langue de la recette", ingredients: "Ingrédients", steps: "Étapes", servings: "Portions",
    prep: "Préparation (min)", cook: "Cuisson (min)", tags: "Régimes", allergens: "Contient", mayContain: "Peut contenir", nutrition: "Nutrition par portion",
    calories: "Calories", protein: "Protéines (g)", carbs: "Glucides (g)", fat: "Lipides (g)", image: "Photo", imageSearch: "Chercher dans Google Images",
    imageUrl: "Lien de la photo", imageUpload: "Téléverser une photo", imageKeep: "Garder l’actuelle", noImage: "Sans photo", searchMore: "Plus de résultats",
    publish: "Publier dans la communauté", published: "Recette publiée", by: "par", addIngredient: "Ajouter un ingrédient", addStep: "Ajouter une étape",
    amount: "Quantité", unit: "Unité", ingredientName: "Ingrédient", step: "Étape {n}", edit: "Modifier la recette", delete: "Supprimer la recette", count: "{n} recettes",
    searchHint: "Mots-clés pour la photo", noResults: "Aucune photo trouvée.", pickedUrl: "Photo choisie", generateFirst: "Saisissez d’abord un nom de plat.", nothing: "Ajoutez d’abord des ingrédients ou des étapes.",
  },
  seed: {
    title: "Générer des recettes", count: "Combien", theme: "Thème (facultatif)", themeHint: "p. ex. végan, dîners de shabbat, déjeuners rapides, marocain", days: "Répartir sur les N derniers jours",
    likes: "J’aime par recette (jusqu’à)", author: "Publié en tant que", random: "Une persona aléatoire à chaque fois", suggest: "Suggérer des plats", suggesting: "Demande de plats au modèle…",
    run: "Créer {n} recettes", running: "Rédaction de la recette {i} sur {n}…", done: "{n} recettes publiées, {failed} échecs", noPersonas: "Créez d’abord quelques personas — les recettes sont publiées en leur nom.",
    titles: "Plats (modifier ou décocher)", addTitle: "Ajouter un plat", stop: "Arrêter après celle-ci", by: "par",
  },
  seedPage: {
    intro: "Remplir la communauté avant le lancement : inventer des membres, puis laisser le modèle écrire en leur nom des recettes et des conversations réparties sur les dernières semaines.",
    personas: "1. Personas", personasText: "Membres inventés avec noms et portraits. Tout ce qui suit est publié en leur nom.", personasBtn: "Gérer les personas", personasCount: "{n} personas",
    recipes: "2. Recettes", recipesText: "Noms de plats par le modèle ; chaque recette est écrite, illustrée et publiée par une persona aléatoire avec des j’aime.",
    forum: "3. Fils du forum", forumText: "Des conversations entières : un fil par une persona et des réponses par d’autres, datées sur la période choisie.",
  },
  seedForum: { title: "Générer des fils", count: "Combien de fils", replies: "Réponses par fil (jusqu’à)", run: "Créer {n} fils", running: "Rédaction du fil {i} sur {n}…", done: "{n} fils publiés, {failed} échecs", replyCount: "{n} réponses" },
  units: { gram: "g", kilogram: "kg", milliliter: "ml", liter: "l", teaspoon: "c. à c.", tablespoon: "c. à s.", cup: "tasse", unit: "unité", pinch: "pincée", unspecified: "—" },
  diets: { meat: "Viande", dairy: "Laitier", vegetarian: "Végétarien", vegan: "Végan", kosher: "Casher", glutenFree: "Sans gluten", allergy: "Allergie" },
  allergens: { gluten: "Gluten", milk: "Lait", eggs: "Œufs", fish: "Poisson", shellfish: "Crustacés", peanuts: "Arachides", treeNuts: "Fruits à coque", sesame: "Sésame", soy: "Soja" },
  personas: {
    intro: "Membres inventés de la communauté. Fils, réponses, recettes et j’aime peuvent être publiés en leur nom pour que la communauté ne soit pas vide au lancement. Ils n’ont pas de connexion ; l’app les affiche comme n’importe quel membre.",
    suggest: "Suggérer des noms", suggestCount: "Combien", create: "Créer une persona", createManual: "Ajouter à la main", gender: { male: "Homme", female: "Femme" },
    photo: "Portrait", bio: "Note (visible par vous seul)", createSelected: "Créer {n} sélectionnée(s)", created: "{n} personas créées", deleteWithContent: "Supprimer avec tout ce qu’elles ont publié",
    deleteKeep: "Supprimer la persona, garder les posts", posts: "fils", recipes: "recettes", newPortrait: "Nouveau portrait aléatoire", replies: "réponses", none: "Pas encore de personas.",
    count: "{n} personas", suggesting: "Demande de noms à l’IA…", deleteTitle: "Supprimer {name} ?", removed: "Supprimé : {posts} fils, {replies} réponses, {recipes} recettes",
    deleteAll: "Supprimer toutes les personas", deleteAllTitle: "Supprimer les {n} personas ?", deleting: "Suppression {i} sur {n}…", deletedAll: "{n} personas supprimées",
    edit: "Modifier la persona", photoUpload: "Téléverser un portrait", photoUrl: "Lien du portrait",
  },
  hh: { tier: "Formule", seats: "Places", owner: "Propriétaire", members: "Membres", remove: "Retirer le membre", dissolve: "Dissoudre le compte partagé", dissolveHint: "Les membres perdent le Premium hérité ; les données partagées sont supprimées du serveur. Le téléphone du propriétaire garde sa copie.", none: "Pas encore de comptes partagés.", tiers: { duo: "Pro Duo", family: "Pro Family" }, count: "{n} comptes partagés", created: "Créé", removed: "Membre retiré", dissolved: "Compte partagé dissous" },
  tickets: {
    unread: "Non lus", read: "Lus", markRead: "Marquer lu", markUnread: "Marquer non lu", reply: "Répondre", replied: "Répondu", replies: "Vos réponses",
    types: { bug: "Bug", suggestion: "Suggestion" }, delete: "Supprimer le ticket", none: "Aucun ticket.", from: "De", appVersion: "App", yourReply: "Votre réponse",
    all: "Tous", sent: "Réponse envoyée (boîte + push)", count: "{n} tickets",
  },
  config: {
    search: "Rechercher un paramètre…", groups: { features: "Fonctions", ads: "Pubs et quotas", share: "Partage gratuit", tts: "Voix", versions: "Versions", gemini: "Gemini (déploiement requis)", other: "Autres" },
    flags: { 0: "Masqué", 1: "Bientôt", 2: "Gratuit pour tous", 3: "Premium seulement" }, add: "Ajouter un paramètre", addHint: "Ajoute un paramètre au modèle en ligne et le publie. Donnez-lui aussi un libellé dans l’i18n de l’app.",
    name: "Clé", type: "Type", value: "Valeur", description: "Description", group: "Groupe (facultatif)", delete: "Retirer le paramètre", deleteHint: "L’app revient à sa valeur intégrée pour un paramètre disparu.",
    saved: "Publié (version {v})", version: "Version du modèle {v}", deployNote: "Les valeurs gemini_* ne prennent effet qu’au prochain déploiement des fonctions.", filter: { all: "Tous les états" },
    count: "{n} paramètres", edited: "Modifié", confirmDelete: "Retirer {name} de Remote Config ?",
  },
  audit: { when: "Quand", action: "Action", params: "Détails", result: "Résultat", ok: "ok", failed: "échec", by: "Par", count: "{n} dernières lignes" },
  err: { network: "Erreur réseau", forbidden: "Le serveur a refusé : administrateur seulement", generic: "Échec : {message}", notConfigured: "Non configuré côté serveur" },
};

const ru = {
  lang: "Язык",
  signOut: "Выйти",
  gate: { title: "EasyPlate Admin", intro: "Консоль администратора. Войдите через Google-аккаунт администратора.", google: "Войти через Google", notAdmin: "Этот аккаунт не администратор. Вы вышли.", failed: "Вход не удался: {reason}", unauthorizedDomain: "Домен ещё не разрешён для входа. Добавьте aieasyplate.app в Firebase Console → Authentication → Settings → Authorized domains." },
  nav: { dashboard: "Обзор", users: "Аккаунты", community: "Сообщество", recipes: "Общие рецепты", personas: "Персонажи", households: "Общие аккаунты", tickets: "Обращения", config: "Настройки", seed: "Активность", audit: "Журнал" },
  common: {
    save: "Сохранить", cancel: "Отмена", delete: "Удалить", edit: "Изменить", close: "Закрыть", confirm: "Подтвердить", yes: "Да", no: "Нет",
    search: "Поиск…", loading: "Загрузка…", none: "Здесь пока пусто.", error: "Что-то пошло не так", done: "Готово", refresh: "Обновить",
    add: "Добавить", create: "Создать", send: "Отправить", generate: "Написать с ИИ", publish: "Опубликовать", back: "Назад", copy: "Копировать", copied: "Скопировано",
    all: "Все", now: "Сейчас", unknown: "неизвестно", name: "Имя", email: "E-mail", phone: "Телефон", date: "Дата", actions: "Действия",
    title: "Заголовок", body: "Текст", more: "Ещё", apply: "Применить", random: "Случайно", upload: "Загрузить", url: "Ссылка", pick: "Выбрать",
    remove: "Убрать", me: "Я (администратор)", open: "Открыть", filter: "Фильтр", count: "Количество", total: "Итого", status: "Статус",
    version: "Версия", platform: "Платформа", irreversible: "Это действие нельзя отменить.", working: "Выполняется…", id: "ID", yesDelete: "Да, удалить",
    saved: "Сохранено", deleted: "Удалено", sent: "Отправлено", kept: "Сохранено", nothingFound: "Ничего не найдено.", language: "Язык", optional: "необязательно",
    showMore: "Показать ещё", today: "Сегодня", invalidJson: "Некорректный JSON", select: "Выбрать", selected: "Выбрано: {n}", unnamed: "(без имени)",
  },
  time: { justNow: "только что", never: "никогда" },
  dash: {
    range: { today: "Сегодня", d30: "30 дней", d60: "60 дней", all: "За всё время" },
    users: "Аккаунты", newUsers: "Новые аккаунты", premium: "Premium", disabled: "Заблокированы", online: "Сейчас онлайн", withPush: "С push-токеном",
    payments: "Платежи", sandbox: "{n} тестовых пропущено", aiCost: "Затраты на ИИ", aiCalls: "Вызовы ИИ", tokens: "Токены", cacheHits: "Попадания в кэш",
    recipes: "Общие рецепты", posts: "Темы", tickets: "Обращения", personas: "Персонажи", households: "Общие аккаунты",
    byPlatform: "По платформе", byVersion: "По версии приложения", byModel: "По модели", byKind: "По функции", signups: "Регистрации по дням",
    dailyCost: "Затраты на ИИ по дням", topUsers: "Аккаунты по затратам на ИИ", syncPricing: "Синхронизировать цены", synced: "Цены и курс обновлены",
    costNote: "Затраты в ₪ по курсу {rate} ₪/$ (цены {source}, обновлено {when}).", searches: "Поиски", cost: "Стоимость", calls: "Вызовы",
    input: "Вход", output: "Выход", cached: "Кэш", noData: "Нет данных за этот период.", unpaid: "платежей нет", calc: "{calls} вызовов · {tokens} токенов",
  },
  users: {
    filter: { all: "Все", online: "Онлайн", premium: "Premium", disabled: "Заблокированы", session: "С сессией устройства" },
    online: "Онлайн", offline: "Не в сети", lastSeen: "Был(а)", device: "Устройство", session: "Сессия", sessionUntil: "до {date}",
    noSession: "нет сессии", premium: "Premium", free: "Бесплатно", disabled: "Заблокирован", broadcast: "Сообщение всем", broadcastTitle: "Сообщение всем аккаунтам",
    broadcastSent: "{items} сообщений, {sent} push отправлено, {failed} не удалось", count: "{n} аккаунтов", joined: "Зарегистрирован", persona: "Персонаж",
    hint: "Онлайн = приложение сейчас открыто на телефоне (отчёт каждую минуту). Отключить = освобождает сессию устройства, приложение сразу выходит.",
  },
  user: {
    profile: "Профиль", auth: "Вход", providers: "Провайдеры", lastSignIn: "Последний вход", created: "Создан", lastRefresh: "Последнее обновление токена",
    entitlement: "Подписка", premiumUntil: "Premium до", adminLock: "Блокировка администратора (webhook не трогает)", source: "Источник",
    setPremium: "Выдать Premium", removePremium: "Снять Premium", premiumForever: "Оставьте пустым — без даты окончания", notify: "Отправить сообщение",
    disable: "Заблокировать аккаунт", enable: "Разблокировать", kick: "Отключить устройство", kickHint: "Освобождает сессию устройства и отзывает токены; приложение выйдет за секунды.",
    delete: "Удалить аккаунт", deleteHint: "Удаляет пользователя Auth, профиль, все зеркальные данные, входящие, подписку и использование. Посты в сообществе остаются.",
    blockMessage: "Сообщение на экране блокировки", usage: "Использование ИИ", recentCalls: "Последние вызовы ИИ", inbox: "Входящие", content: "Контент",
    collections: { recipes: "Рецепты", books: "Книги", meal_plans: "Планы питания", grocery_lists: "Списки покупок", preferences: "Настройки", price_records: "Записи цен", receipts: "Чеки", product_pricing: "Цены товаров" },
    household: "Общий аккаунт", shared: "Общие элементы", posts: "Темы", sharedRecipes: "Общие рецепты", feedback: "Обращения", editJson: "Редактировать как JSON",
    contentHint: "Правки попадают в облачную копию; телефон подхватит их при следующем запуске (или сразу — внутри общего аккаунта).",
    root: { users: "Личное", households: "Общий аккаунт" }, disabledBanner: "Аккаунт заблокирован: {message}", editProfile: "Изменить профиль",
    fullName: "Полное имя", photoUrl: "Ссылка на фото", noAuth: "Нет пользователя Auth (удалён или персонаж)", tokensValidAfter: "Токены действительны с", kicked: "Устройство отключено",
    notified: "Сообщение отправлено", shareCodes: "Коды доступа", invites: "Приглашения", none: "—", notFound: "Аккаунт не найден", items: "{n} элементов",
    model: "Модель", kind: "Функция", when: "Когда", ms: "мс", statusCol: "Статус", noUsage: "ИИ ещё не использовался", pushToken: "Push-токен", appVersion: "Версия приложения",
    disabledYes: "Заблокирован", disabledNo: "Активен", role: "Роль", members: "Участники", owner: "Владелец", collabRecipes: "Общие рецепты (collab)", collabContainers: "Общие книги, планы и списки",
    tokenUntil: "Текущий токен действителен до", tokenExpired: "истёк", tokenLive: "действует", tokenHint: "ID-токен живёт час с последнего обновления; устройство обновляет его незаметно, пока выполнен вход.",
    uses: "использований", revoked: "отозван", expires: "истекает", kind2: "Тип",
  },
  forum: {
    newThread: "Новая тема", replies: "{n} ответов", reply: "Ответить", as: "От имени", asMe: "Я (администратор)", draftAi: "Написать с ИИ",
    topic: "Тема или угол (необязательно)", backdate: "Дата", randomDate: "Случайная дата за последние {days} дней", likes: "{n} лайков",
    seedLikes: "Добавить лайки", seedLikesCount: "Сколько персонажей поставят лайк?", likeAs: "Лайк от имени…", deleteThread: "Удалить тему (с ответами)",
    deleteReply: "Удалить ответ", edit: "Изменить", posted: "Опубликовано", noPersonas: "Персонажей пока нет — создайте их в разделе Персонажи.", thread: "Тема",
    open: "Открыть тему", recipeLink: "Прикреплённый рецепт", pending: "ожидание", threads: "{n} тем", added: "Добавлено лайков: {n}", context: "Текст темы для ИИ",
    live: "Live", editThread: "Изменить тему", editReply: "Изменить ответ",
  },
  recipes: {
    new: "Новый общий рецепт", generate: "Сгенерировать рецепт", generating: "Пишу рецепт…", titleHint: "Название блюда, например Шакшука",
    hints: "Пожелания для ИИ (необязательно)", language: "Язык рецепта", ingredients: "Ингредиенты", steps: "Шаги", servings: "Порции",
    prep: "Подготовка (мин)", cook: "Готовка (мин)", tags: "Диеты", allergens: "Содержит", mayContain: "Может содержать", nutrition: "Пищевая ценность на порцию",
    calories: "Калории", protein: "Белки (г)", carbs: "Углеводы (г)", fat: "Жиры (г)", image: "Фото", imageSearch: "Поиск в Google Картинках",
    imageUrl: "Ссылка на фото", imageUpload: "Загрузить фото", imageKeep: "Оставить текущее", noImage: "Без фото", searchMore: "Ещё результаты",
    publish: "Опубликовать в сообществе", published: "Рецепт опубликован", by: "от", addIngredient: "Добавить ингредиент", addStep: "Добавить шаг",
    amount: "Количество", unit: "Единица", ingredientName: "Ингредиент", step: "Шаг {n}", edit: "Изменить рецепт", delete: "Удалить рецепт", count: "{n} рецептов",
    searchHint: "Запрос для поиска фото", noResults: "Фото не найдены.", pickedUrl: "Выбранное фото", generateFirst: "Сначала введите название блюда.", nothing: "Сначала добавьте ингредиенты или шаги.",
  },
  seed: {
    title: "Сгенерировать рецепты", count: "Сколько", theme: "Тема (необязательно)", themeHint: "например веганское, шаббатний ужин, быстрый обед, марокканская кухня", days: "Распределить по последним N дням",
    likes: "Лайков на рецепт (до)", author: "Публикуется от имени", random: "Случайный персонаж каждый раз", suggest: "Предложить блюда", suggesting: "Запрашиваю блюда у модели…",
    run: "Создать рецептов: {n}", running: "Пишу рецепт {i} из {n}…", done: "Опубликовано: {n}, не удалось: {failed}", noPersonas: "Сначала создайте персонажей — рецепты публикуются от их имени.",
    titles: "Блюда (можно изменить или снять отметку)", addTitle: "Добавить блюдо", stop: "Остановить после текущего", by: "от",
  },
  seedPage: {
    intro: "Заполнить сообщество до запуска: придумать участников, а затем дать модели написать от их имени рецепты и обсуждения, распределённые по последним неделям.",
    personas: "1. Персонажи", personasText: "Вымышленные участники с именами и портретами. Всё ниже публикуется от их имени.", personasBtn: "Управлять персонажами", personasCount: "{n} персонажей",
    recipes: "2. Рецепты", recipesText: "Названия блюд от модели; каждый рецепт пишется, получает фото и публикуется случайным персонажем с лайками.",
    forum: "3. Темы форума", forumText: "Целые обсуждения: тема от одного персонажа и ответы других, датированные в выбранном диапазоне.",
  },
  seedForum: { title: "Сгенерировать темы", count: "Сколько тем", replies: "Ответов на тему (до)", run: "Создать тем: {n}", running: "Пишу тему {i} из {n}…", done: "Опубликовано тем: {n}, не удалось: {failed}", replyCount: "{n} ответов" },
  units: { gram: "г", kilogram: "кг", milliliter: "мл", liter: "л", teaspoon: "ч. л.", tablespoon: "ст. л.", cup: "стакан", unit: "шт", pinch: "щепотка", unspecified: "—" },
  diets: { meat: "Мясное", dairy: "Молочное", vegetarian: "Вегетарианское", vegan: "Веганское", kosher: "Кошерное", glutenFree: "Без глютена", allergy: "Аллергия" },
  allergens: { gluten: "Глютен", milk: "Молоко", eggs: "Яйца", fish: "Рыба", shellfish: "Моллюски", peanuts: "Арахис", treeNuts: "Орехи", sesame: "Кунжут", soy: "Соя" },
  personas: {
    intro: "Вымышленные участники сообщества. От их имени можно публиковать темы, ответы, рецепты и лайки, чтобы сообщество не было пустым в день запуска. У них нет входа; приложение показывает их как любого участника.",
    suggest: "Предложить имена", suggestCount: "Сколько", create: "Создать персонажа", createManual: "Добавить вручную", gender: { male: "Мужчина", female: "Женщина" },
    photo: "Портрет", bio: "Заметка (видите только вы)", createSelected: "Создать выбранных: {n}", created: "Создано персонажей: {n}", deleteWithContent: "Удалить вместе со всем, что они опубликовали",
    deleteKeep: "Удалить персонажа, оставить посты", posts: "тем", recipes: "рецептов", newPortrait: "Новый случайный портрет", replies: "ответов", none: "Персонажей пока нет.",
    count: "{n} персонажей", suggesting: "Запрашиваю имена у ИИ…", deleteTitle: "Удалить {name}?", removed: "Удалено: {posts} тем, {replies} ответов, {recipes} рецептов",
    deleteAll: "Удалить всех персонажей", deleteAllTitle: "Удалить всех персонажей ({n})?", deleting: "Удаляю {i} из {n}…", deletedAll: "Удалено персонажей: {n}",
    edit: "Изменить персонажа", photoUpload: "Загрузить портрет", photoUrl: "Ссылка на портрет",
  },
  hh: { tier: "Тариф", seats: "Мест", owner: "Владелец", members: "Участники", remove: "Удалить участника", dissolve: "Расформировать общий аккаунт", dissolveHint: "Участники теряют унаследованный Premium; общие данные удаляются с сервера. Телефон владельца сохраняет копию.", none: "Общих аккаунтов пока нет.", tiers: { duo: "Pro Duo", family: "Pro Family" }, count: "{n} общих аккаунтов", created: "Создан", removed: "Участник удалён", dissolved: "Общий аккаунт расформирован" },
  tickets: {
    unread: "Непрочитанные", read: "Прочитанные", markRead: "Отметить прочитанным", markUnread: "Отметить непрочитанным", reply: "Ответить", replied: "Отвечено", replies: "Ваши ответы",
    types: { bug: "Ошибка", suggestion: "Предложение" }, delete: "Удалить обращение", none: "Обращений нет.", from: "От", appVersion: "Приложение", yourReply: "Ваш ответ",
    all: "Все", sent: "Ответ отправлен (входящие + push)", count: "{n} обращений",
  },
  config: {
    search: "Поиск параметров…", groups: { features: "Функции", ads: "Реклама и квоты", share: "Бесплатный шеринг", tts: "Голос", versions: "Версии", gemini: "Gemini (нужен деплой)", other: "Прочее" },
    flags: { 0: "Скрыто", 1: "Скоро", 2: "Бесплатно всем", 3: "Только Premium" }, add: "Добавить параметр", addHint: "Добавляет параметр в живой шаблон и публикует его. Дайте ему подпись и в i18n приложения.",
    name: "Ключ", type: "Тип", value: "Значение", description: "Описание", group: "Группа (необязательно)", delete: "Удалить параметр", deleteHint: "Для исчезнувшего параметра приложение использует встроенное значение.",
    saved: "Опубликовано (версия {v})", version: "Версия шаблона {v}", deployNote: "Значения gemini_* вступают в силу только при следующем деплое функций.", filter: { all: "Все состояния" },
    count: "{n} параметров", edited: "Изменено", confirmDelete: "Удалить {name} из Remote Config?",
  },
  audit: { when: "Когда", action: "Действие", params: "Детали", result: "Результат", ok: "ок", failed: "ошибка", by: "Кто", count: "последние {n} строк" },
  err: { network: "Ошибка сети", forbidden: "Сервер отказал: только администратор", generic: "Ошибка: {message}", notConfigured: "Не настроено на сервере" },
};

const DICT = { en, he, ar, fr, ru };

let current = "he";
const listeners = new Set();

export function currentLang() {
  return current;
}

export function locale() {
  return LOCALES[current] || "en";
}

export function detectLang() {
  try {
    const stored = localStorage.getItem("ep-admin-lang");
    if (stored && DICT[stored]) return stored;
  } catch (_) {}
  const nav = (navigator.language || "en").slice(0, 2).toLowerCase();
  return DICT[nav] ? nav : "he";
}

export function setLang(lang) {
  if (!DICT[lang]) lang = "en";
  current = lang;
  try {
    localStorage.setItem("ep-admin-lang", lang);
  } catch (_) {}
  document.documentElement.lang = lang;
  document.documentElement.dir = RTL.has(lang) ? "rtl" : "ltr";
  for (const el of document.querySelectorAll("[data-i18n]")) el.textContent = t(el.getAttribute("data-i18n"));
  for (const fn of listeners) fn(lang);
}

export function onLangChange(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

function lookup(dict, key) {
  let node = dict;
  for (const part of key.split(".")) {
    if (node === null || node === undefined || typeof node !== "object") return undefined;
    node = node[part];
  }
  return typeof node === "string" ? node : undefined;
}

export function t(key, params) {
  let text = lookup(DICT[current], key);
  if (text === undefined) text = lookup(en, key);
  if (text === undefined) return key;
  if (params) for (const [k, v] of Object.entries(params)) text = text.split(`{${k}}`).join(String(v));
  return text;
}

// ---- formatting ----
export function fmtNumber(n, digits = 0) {
  if (n === null || n === undefined || Number.isNaN(n)) return "—";
  return new Intl.NumberFormat(locale(), { maximumFractionDigits: digits }).format(n);
}

export function fmtMoney(n, currency = "ILS") {
  if (n === null || n === undefined || Number.isNaN(n)) return "—";
  try {
    return new Intl.NumberFormat(locale(), { style: "currency", currency, maximumFractionDigits: 2 }).format(n);
  } catch (_) {
    return `${fmtNumber(n, 2)} ${currency}`;
  }
}

export function fmtDate(d, withTime = true) {
  const date = toDate(d);
  if (!date) return "—";
  return new Intl.DateTimeFormat(locale(), withTime ? { dateStyle: "short", timeStyle: "short" } : { dateStyle: "medium" }).format(date);
}

export function fmtAgo(d, now = Date.now()) {
  const date = toDate(d);
  if (!date) return t("time.never");
  const diff = (date.getTime() - now) / 1000;
  const abs = Math.abs(diff);
  if (abs < 45) return t("time.justNow");
  const rtf = new Intl.RelativeTimeFormat(locale(), { numeric: "auto" });
  if (abs < 3600) return rtf.format(Math.round(diff / 60), "minute");
  if (abs < 86400) return rtf.format(Math.round(diff / 3600), "hour");
  if (abs < 86400 * 30) return rtf.format(Math.round(diff / 86400), "day");
  return fmtDate(date, false);
}

export function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value.toDate === "function") return value.toDate();
  if (typeof value === "number") return new Date(value);
  if (typeof value === "string") {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  if (typeof value.seconds === "number") return new Date(value.seconds * 1000);
  return null;
}
