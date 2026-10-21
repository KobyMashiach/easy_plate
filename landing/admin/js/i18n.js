// Every string the console shows, in the app's five languages. `t(key)`
// falls back to English for a key a language is missing, and to the key
// itself if English lacks it too — a missing string shows as its name
// rather than as nothing.

export const LANGS = { he: "עברית", en: "English", ar: "العربية", fr: "Français", ru: "Русский" };
export const RTL = new Set(["he", "ar"]);
// Arabic pinned to Western digits (nu-latn), like the app and the web app.
const LOCALES = { he: "he-IL", en: "en-GB", ar: "ar-u-nu-latn", fr: "fr-FR", ru: "ru-RU" };

const en = {
  lang: "Language",
  signOut: "Sign out",
  menu: "Menu",
  openApp: "Open the app",
  gate: {
    title: "EasyPlate Admin",
    intro: "The administration console. Sign in with the administrator's Google account.",
    google: "Sign in with Google",
    notAdmin: "This account is not the administrator. You were signed out.",
    failed: "Sign-in failed: {reason}",
    unauthorizedDomain: "This domain is not authorized for sign-in yet. Add aieasyplate.app under Firebase Console → Authentication → Settings → Authorized domains.",
  },
  nav: { dashboard: "Dashboard", users: "Accounts", community: "Community", recipes: "Shared recipes", personas: "Personas", households: "Households", tickets: "Tickets", config: "Configuration", seed: "Activity", audit: "Audit log", stores: "Downloads", notifications: "Notifications" , whatsnew: "What's new" },
  whatsnew: {
    intro: "One release per build. After an update the app shows a returning account the pages of every published release between the build it last acknowledged and the one it runs — a fresh install sees none. A page is dropped on the phone when its flag is hidden or “coming soon”.",
    none: "No releases yet.", newRelease: "New release", editRelease: "Edit release {v}", deleteRelease: "Delete release {v}?",
    versionCode: "Build number", versionCodeHint: "The integer after + in pubspec (1.2.0+12 → 12). The document id.", version: "Version", versionHint: "The marketing version, 1.2.0", releasedAt: "Released on",
    published: "Published", publishedHint: "Only a published release reaches the app.", publishedBadge: "Published", draft: "Draft", publishedNow: "Published", unpublishedNow: "Unpublished", unpublish: "Unpublish",
    features: "Features", featuresHint: "Tick the features this release highlights; each becomes one page, in the order below.", pickHint: "Tick features above to add pages.", pages: "{n} pages", build: "build {n}",
    featureTitle: "Headline", featureTitleHint: "Short; empty falls back to the feature's name in the app.", featureDescription: "Description", translate: "Translate with AI", translated: "Translated into the other languages", needText: "Write the text in one language first.",
    icon: "Icon", target: "“Try it” opens", targetHint: "Optional. A tab or a screen the app can open directly.", noTarget: "No button", image: "Picture URL", imageHint: "Optional, https. Shown above the text instead of the icon.",
    moveUp: "Move up", moveDown: "Move down", badCode: "The build number must be a positive integer.", badVersion: "The version must look like 1.2.0.", needFeatures: "Pick at least one feature.", needTitle: "“{name}” needs a headline in at least one language.", codeExists: "A release with this build number exists — edit it instead.",
    targets: { "tab:recipes": "Recipes tab", "tab:library": "Library tab", "tab:mealPlan": "Meal plan tab", "tab:groceries": "Groceries tab", "tab:community": "Community tab", ingestion: "Add a recipe", assistant: "Shefi", price_book: "Price book", settings: "Settings", preferences: "Preferences", notification_settings: "Notification settings", account_menu: "Account", notifications: "Inbox", profile_edit: "Profile", sharing: "Sharing", household: "Household", join_code: "Join with a code", scan_code: "Scan a code", home_widgets: "Home widgets", wake_word: "Hey Shefi", support: "Support", help: "Help", premium: "Premium", tutorial: "Guide" },
  },
  notif: {
    tabSent: "Sent", tabTemplates: "Templates", filterAll: "All", toAll: "Everyone", toUser: "One user", user: "User", pickUser: "Pick a user", target: "Send to",
    sendNow: "Send a notification", sendNowShort: "Send now", newTemplate: "New template", editTemplate: "Edit template", deleteTemplate: "Delete this template?",
    sendTemplateNow: "Send “{name}” now?", confirmAll: "This goes to every account.", needBody: "Write the text first.", sentOne: "Sent", saved: "Saved", savedNext: "Saved — next send {date}",
    name: "Template name", nameHint: "Only you see it", when: "When", at: "Date and time", time: "Time", israelTime: "Israel time", weekdays: "Days", dayOfMonth: "Day of the month", dayOfMonthHint: "A shorter month uses its last day",
    enabled: "Active", active: "Active", disabled: "Paused", enable: "Resume", disable: "Pause", next: "Next: {date}", last: "Last: {date}", runs: "{n} sends",
    noneSent: "Nothing sent yet.", noTemplates: "No templates yet.", failed: "Failed", counts: "{items} inboxes · {sent} pushes · {failed} failed",
    kinds: { manual: "Manual only (send now)", once: "Once", daily: "Every day", weekly: "Every week", monthly: "Every month" },
    describe: { once: "Once, {date}", daily: "Every day at {time}", weekly: "Every {days} at {time}", monthly: "Every month on day {day} at {time}" },
    days: { 0: "Sun", 1: "Mon", 2: "Tue", 3: "Wed", 4: "Thu", 5: "Fri", 6: "Sat" },
    sources: { console: "Console", app: "App", template: "Template", schedule: "Scheduled" },
    targets: { all: "Everyone", premium: "All Premium users", free: "All free users", users: "Picked users", user: "One user" },
    users: "Users", pickUsers: "Pick at least one user", pickedCount: "{n} picked", usersCount: "{n} users", confirmUsers: "This goes to {n} picked users.",
    confirm: { all: "This goes to every account.", premium: "This goes to every account with active Premium.", free: "This goes to every account without Premium." },
  },
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
    online: "Online", offline: "Offline", lastSeen: "Last seen", device: "Device", session: "Session", sessionUntil: "until {date}", permission: "Permission", permissionAdmin: "Admin", permissionUser: "User", permissionHint: "An administrator has the whole console, the support inbox and every account's data, and no device limit. Your own permission cannot be changed here.", permissionSuperuser: "Superuser", permissionSuperuserHint: "A superuser sees every feature, Premium ones included, whatever the flags say, and has no device limit. No administrator powers.", hardwareId: "Phone id (hash)", releaseRequest: "Sign-out request", takeoverAt: "New device gets in at {date}", declined: "declined",
    noSession: "no session", premium: "Premium", free: "Free", disabled: "Blocked", broadcast: "Broadcast", broadcastTitle: "Message to every account",
    broadcastSent: "{items} inbox items, {sent} pushes sent, {failed} failed", count: "{n} accounts", joined: "Joined", persona: "Persona",
    hint: "Online = the app is open on a phone right now (reported every minute). Kick = frees the device session, the app signs out at once.",
  },
  user: {
    product: "Product", deviceId: "Device id", fn: "Function", cacheHit: "cache",
    profile: "Profile", auth: "Sign-in", providers: "Providers", lastSignIn: "Last sign-in", created: "Created", lastRefresh: "Last token refresh",
    entitlement: "Subscription", premiumUntil: "Premium until", sourceStripe: "Website (Stripe)", stripeCustomer: "Stripe customer", cancelsAtPeriodEnd: "cancels at period end", sourcePayplus: "Website (PayPlus, Israel)", sourcePaddle: "Website (Paddle via RevenueCat, abroad)", webSubscription: "Web subscription id", adminLock: "Admin lock (webhook leaves it alone)", source: "Source",
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
    delete: "Delete ticket", none: "No tickets.", from: "From", appVersion: "App", yourReply: "Your reply",
    all: "All", sent: "Reply sent (inbox + push)", count: "{n} tickets",
    types: { bug: "Bug", suggestion: "Suggestion", account: "Account and sign-in", billing: "Premium and billing", sharing: "Sharing and partners", recipes: "Adding recipes and AI", other: "Other" }, details: "Details (not shown to the user)", detailKeys: { name: "Name", email: "Email", phone: "Phone", uid: "Account id", version: "Version", device: "Device", language: "Language" }, viaShefi: "via Shefi", updated: "Updated", you: "You", user: "User", closed: "Closed", close: "Close conversation", closeConfirm: "Close {name}'s conversation? They can read it under \"closed\" but not write in it.", reopen: "Reopen", closedNow: "Conversation closed", reopenedNow: "Conversation reopened", closedBadge: "Closed",
  },
  config: {
    search: "Search parameters…", groups: { features: "Features", ads: "Ads & quotas", share: "Free-tier sharing", tts: "Voice", versions: "Versions", gemini: "Gemini (needs deploy)", other: "Other" },
    flags: { 0: "Hidden", 1: "Coming soon", 2: "Free for all", 3: "Premium only" }, add: "Add parameter", addHint: "Adds a parameter to the live template and publishes it. Give it a Hebrew/English heading in the app's i18n too.",
    name: "Key", type: "Type", value: "Value", description: "Description", group: "Group (optional)", delete: "Remove parameter", deleteHint: "The app falls back to its built-in default for a parameter that is gone.",
    saved: "Published", version: "Template version {v}", deployNote: "gemini_* values only take effect on the next functions deploy.", filter: { all: "All states" },
    count: "{n} parameters", edited: "Edited", confirmDelete: "Remove {name} from Remote Config?",
  },
  audit: { when: "When", action: "Action", params: "Details", result: "Result", ok: "ok", failed: "failed", by: "By", count: "last {n} rows" },
  stores: {
    android: "Android", ios: "iOS", range: { d7: "7 days", d30: "30 days", d90: "90 days", y1: "Year", all: "All time" },
    totalAll: "Downloads, both stores", sinceFirst: "since the first report", share: "{p} of all downloads", inRange: "In this range",
    perDayAvg: "Per day (average)", daysCounted: "{n} days", activeDevices: "Active devices", playOnly: "Google Play only", iosOnly: "App Store only",
    playCounter: "Play's own counter", playCounterHint: "Total user installs, as Play reports it", uninstalls: "Uninstalls", updates: "Updates",
    redownloads: "Re-downloads", iap: "In-app purchases (units)", perDay: "Downloads per day", platformShare: "Android vs iOS",
    shareNote: "All-time first-time downloads. Play counts a user's first install; Apple counts first-time downloads (re-downloads kept apart).",
    byWeek: "By week (last 12)", byMonth: "By month", period: "Period", androidShare: "Android share", byCountry: "By country", country: "Country",
    dayTable: "Day by day", cumulative: "Cumulative", noData: "No data yet — configure the stores and sync.",
    syncNow: "Sync now", syncDone: "Store reports fetched", backfill: "Backfill App Store", settings: "Store settings",
    notConfigured: "not configured", failed: "failed", synced: "synced", neverSynced: "never synced", lastSync: "synced {when}", through: "through {date}",
    setupIntro: "Nothing is connected yet. Open Store settings: the Play Console bucket for Android, an App Store Connect API key for iOS.",
    playHelp: "{downloadReports} → {statistics} → “{copyUri}” gives the bucket.\nUnder {users} → “{invite}”, invite the service account below with “{perm}”.\nIt is an account permission, not an app permission (app permissions such as “View app information” alone are not enough), and it can take up to 24 hours to reach the bucket.",
    serviceAccount: "Service account to invite:", playBucket: "Cloud Storage bucket", playBucketHint: "pubsite_prod_… (with or without gs://)", playPackage: "Package name",
    appleHelp: "{usersAccess} → {integrations} → {api} → {teamKeys}: “{generate}” with the {sales} (or {admin}) role.\nThe {vendor} is on {payments}.", storeLang: "Store language", storeLangHint: "The language your store console is shown in; the menu names in the instructions follow it.", storeLangUnverified: "No official menu names are published for this language, so they are shown in a free translation.",
    appleVendor: "Vendor number", appleVendorHint: "Digits only", appleIssuerId: "Issuer ID", appleKeyId: "Key ID", applePrivateKey: "Private key (.p8)",
    keyHint: "Paste the whole AuthKey_….p8 file. Stored server-side; never shown again.", keyStored: "(a key is stored — paste a new one to replace it)", keyStoredHint: "Leave empty to keep the stored key.",
    appleAppId: "Apple ID of the app", iosSince: "Count iOS from", iosSinceHint: "Daily reports are fetched from this date (Apple keeps one year). Empty = the last 365 days.",
    footnote: "Google Play reports arrive once a day for the previous day; Apple's daily report is ready around 15:00 Israel time. The server refreshes at 16:30 daily.",
  },
  err: { network: "Network error", forbidden: "The server refused: administrator only", generic: "Failed: {message}", notConfigured: "Not configured on the server" },
};

const he = {
  lang: "שפה",
  signOut: "התנתקות",
  menu: "תפריט",
  openApp: "כניסה לאפליקציה",
  gate: {
    title: "EasyPlate Admin",
    intro: "קונסולת הניהול. מתחברים עם חשבון הגוגל של המנהל.",
    google: "כניסה עם Google",
    notAdmin: "החשבון הזה אינו המנהל. נותקת.",
    failed: "הכניסה נכשלה: {reason}",
    unauthorizedDomain: "הדומיין עדיין לא מאושר לכניסה. יש להוסיף את aieasyplate.app ב-Firebase Console → Authentication → Settings → Authorized domains.",
  },
  nav: { dashboard: "סקירה", users: "חשבונות", community: "קהילה", recipes: "מתכונים משותפים", personas: "דמויות", households: "חשבונות משותפים", tickets: "פניות", config: "תצורה", seed: "תנועה", audit: "יומן פעולות", stores: "הורדות", notifications: "התראות" , whatsnew: "מה חדש" },
  whatsnew: {
    intro: "שחרור אחד לכל מספר build. אחרי עדכון, האפליקציה מציגה לחשבון חוזר את העמודים של כל שחרור מפורסם בין ה-build שאושר לאחרונה ל-build שרץ — התקנה חדשה לא רואה כלום. עמוד שהדגל שלו מוסתר או \"בקרוב\" לא מוצג בטלפון.",
    none: "אין שחרורים עדיין.", newRelease: "שחרור חדש", editRelease: "עריכת שחרור {v}", deleteRelease: "למחוק את שחרור {v}?",
    versionCode: "מספר build", versionCodeHint: "המספר אחרי + ב-pubspec (1.2.0+12 → 12). זה מזהה המסמך.", version: "גרסה", versionHint: "גרסת השיווק, 1.2.0", releasedAt: "תאריך שחרור",
    published: "מפורסם", publishedHint: "רק שחרור מפורסם מגיע לאפליקציה.", publishedBadge: "מפורסם", draft: "טיוטה", publishedNow: "פורסם", unpublishedNow: "הפרסום בוטל", unpublish: "ביטול פרסום",
    features: "פיצ'רים", featuresHint: "סמנו את הפיצ'רים שהשחרור הזה מדגיש; כל אחד הופך לעמוד, בסדר שלמטה.", pickHint: "סמנו פיצ'רים למעלה כדי להוסיף עמודים.", pages: "{n} עמודים", build: "build {n}",
    featureTitle: "כותרת", featureTitleHint: "קצרה; ריק נופל לשם הפיצ'ר באפליקציה.", featureDescription: "תיאור", translate: "תרגום עם AI", translated: "תורגם לשאר השפות", needText: "כתבו קודם את הטקסט בשפה אחת.",
    icon: "אייקון", target: "\"לנסות\" פותח", targetHint: "לא חובה. טאב או מסך שהאפליקציה יכולה לפתוח ישירות.", noTarget: "בלי כפתור", image: "כתובת תמונה", imageHint: "לא חובה, https. מוצגת מעל הטקסט במקום האייקון.",
    moveUp: "הזזה למעלה", moveDown: "הזזה למטה", badCode: "מספר ה-build חייב להיות מספר שלם חיובי.", badVersion: "הגרסה צריכה להיראות כמו 1.2.0.", needFeatures: "בחרו לפחות פיצ'ר אחד.", needTitle: "ל\"{name}\" חסרה כותרת בשפה אחת לפחות.", codeExists: "כבר יש שחרור עם מספר ה-build הזה — ערכו אותו במקום.",
    targets: { "tab:recipes": "טאב מתכונים", "tab:library": "טאב ספרייה", "tab:mealPlan": "טאב תפריטים", "tab:groceries": "טאב קניות", "tab:community": "טאב קהילה", ingestion: "הוספת מתכון", assistant: "שפי", price_book: "ספר מחירים", settings: "הגדרות", preferences: "העדפות", notification_settings: "הגדרות התראות", account_menu: "חשבון", notifications: "תיבת הודעות", profile_edit: "פרופיל", sharing: "שיתוף", household: "חשבון משותף", join_code: "הצטרפות עם קוד", scan_code: "סריקת קוד", home_widgets: "ווידג'טים", wake_word: "היי שפי", support: "תמיכה", help: "עזרה", premium: "פרימיום", tutorial: "מדריך" },
  },
  notif: {
    tabSent: "נשלחו", tabTemplates: "תבניות", filterAll: "הכול", toAll: "לכולם", toUser: "למשתמש", user: "משתמש", pickUser: "בחירת משתמש", target: "למי",
    sendNow: "שליחת התראה", sendNowShort: "שלח עכשיו", newTemplate: "תבנית חדשה", editTemplate: "עריכת תבנית", deleteTemplate: "למחוק את התבנית?",
    sendTemplateNow: "לשלוח עכשיו את “{name}”?", confirmAll: "זה יישלח לכל החשבונות.", needBody: "צריך לכתוב טקסט.", sentOne: "נשלח", saved: "נשמר", savedNext: "נשמר — השליחה הבאה {date}",
    name: "שם התבנית", nameHint: "רק אתה רואה אותו", when: "מתי", at: "תאריך ושעה", time: "שעה", israelTime: "שעון ישראל", weekdays: "ימים", dayOfMonth: "יום בחודש", dayOfMonthHint: "בחודש קצר יותר — ביום האחרון שלו",
    enabled: "פעילה", active: "פעילה", disabled: "מושהית", enable: "הפעלה", disable: "השהיה", next: "הבאה: {date}", last: "אחרונה: {date}", runs: "{n} שליחות",
    noneSent: "עוד לא נשלחו התראות.", noTemplates: "אין עדיין תבניות.", failed: "נכשל", counts: "{items} תיבות · {sent} פושים · {failed} נכשלו",
    kinds: { manual: "ידני בלבד (שליחה עכשיו)", once: "חד פעמי", daily: "כל יום", weekly: "כל שבוע", monthly: "כל חודש" },
    describe: { once: "חד פעמי, {date}", daily: "כל יום ב-{time}", weekly: "כל {days} ב-{time}", monthly: "כל חודש ב-{day} לחודש ב-{time}" },
    days: { 0: "ראשון", 1: "שני", 2: "שלישי", 3: "רביעי", 4: "חמישי", 5: "שישי", 6: "שבת" },
    sources: { console: "קונסולה", app: "אפליקציה", template: "תבנית", schedule: "מתוזמן" },
    targets: { all: "כולם", premium: "כל משתמשי הפרימיום", free: "כל המשתמשים החינמיים", users: "בחירת משתמשים", user: "משתמש אחד" },
    users: "משתמשים", pickUsers: "צריך לבחור לפחות משתמש אחד", pickedCount: "{n} נבחרו", usersCount: "{n} משתמשים", confirmUsers: "זה יישלח ל-{n} המשתמשים שנבחרו.",
    confirm: { all: "זה יישלח לכל החשבונות.", premium: "זה יישלח לכל החשבונות עם פרימיום פעיל.", free: "זה יישלח לכל החשבונות בלי פרימיום." },
  },
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
    online: "מחובר", offline: "לא מחובר", lastSeen: "נראה לאחרונה", device: "מכשיר", session: "סשן", sessionUntil: "עד {date}", permission: "הרשאה", permissionAdmin: "מנהל", permissionUser: "משתמש", permissionHint: "מנהל מקבל את כל הקונסולה, את פניות התמיכה ואת הנתונים של כל חשבון, בלי הגבלת מכשירים. את ההרשאה של עצמך אי אפשר לשנות כאן.", permissionSuperuser: "סופר-משתמש", permissionSuperuserHint: "סופר-משתמש רואה את כל הפיצ'רים, כולל פרימיום, בלי קשר לדגלים, ובלי הגבלת מכשירים. בלי סמכויות מנהל.", hardwareId: "מזהה טלפון (hash)", releaseRequest: "בקשת התנתקות", takeoverAt: "המכשיר החדש ייכנס ב-{date}", declined: "נדחתה",
    noSession: "אין סשן", premium: "פרימיום", free: "חינמי", disabled: "חסום", broadcast: "הודעה לכולם", broadcastTitle: "הודעה לכל החשבונות",
    broadcastSent: "{items} הודעות בתיבה, {sent} פושים נשלחו, {failed} נכשלו", count: "{n} חשבונות", joined: "הצטרף", persona: "דמות",
    hint: "מחובר = האפליקציה פתוחה על הטלפון כרגע (דיווח כל דקה). ניתוק = משחרר את סשן המכשיר, האפליקציה מתנתקת מיד.",
  },
  user: {
    product: "מוצר", deviceId: "מזהה מכשיר", fn: "פונקציה", cacheHit: "מטמון",
    profile: "פרופיל", auth: "התחברות", providers: "ספקי כניסה", lastSignIn: "כניסה אחרונה", created: "נוצר", lastRefresh: "רענון טוקן אחרון",
    entitlement: "מנוי", premiumUntil: "פרימיום עד", sourceStripe: "אתר (Stripe)", stripeCustomer: "לקוח Stripe", cancelsAtPeriodEnd: "מתבטל בסוף התקופה", sourcePayplus: "אתר (PayPlus, ישראל)", sourcePaddle: "אתר (Paddle דרך RevenueCat, חו״ל)", webSubscription: "מזהה מנוי באתר", adminLock: "נעילת מנהל (ה-webhook לא נוגע)", source: "מקור",
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
    delete: "מחיקת הפנייה", none: "אין פניות.", from: "מאת", appVersion: "אפליקציה", yourReply: "התשובה שלך",
    all: "הכול", sent: "התשובה נשלחה (תיבה + פוש)", count: "{n} פניות",
    types: { bug: "תקלה", suggestion: "הצעה", account: "חשבון והתחברות", billing: "פרימיום ותשלום", sharing: "שיתוף ושותפים", recipes: "הוספת מתכונים ו-AI", other: "אחר" }, details: "פרטי הפנייה (לא מוצגים למשתמש)", detailKeys: { name: "שם", email: "מייל", phone: "טלפון", uid: "מזהה חשבון", version: "גרסה", device: "מכשיר", language: "שפה" }, viaShefi: "דרך שפי", updated: "עודכן", you: "אתה", user: "המשתמש", closed: "סגורות", close: "סגירת פנייה", closeConfirm: "לסגור את הפנייה של {name}? המשתמש יוכל לקרוא אותה ב\"פניות סגורות\" אבל לא לכתוב בה.", reopen: "פתיחה מחדש", closedNow: "הפנייה נסגרה", reopenedNow: "הפנייה נפתחה מחדש", closedBadge: "סגורה",
  },
  config: {
    search: "חיפוש פרמטרים…", groups: { features: "פיצ׳רים", ads: "פרסומות ומכסות", share: "שיתוף בחינם", tts: "קול", versions: "גרסאות", gemini: "Gemini (דורש deploy)", other: "אחר" },
    flags: { 0: "לא מוצג", 1: "בקרוב", 2: "חינמי לכולם", 3: "רק לפרימיום" }, add: "הוספת פרמטר", addHint: "מוסיף פרמטר לתבנית החיה ומפרסם. כדאי לתת לו כותרת בעברית/אנגלית גם ב-i18n של האפליקציה.",
    name: "מפתח", type: "סוג", value: "ערך", description: "תיאור", group: "קבוצה (לא חובה)", delete: "הסרת פרמטר", deleteHint: "האפליקציה חוזרת לברירת המחדל המובנית של פרמטר שנעלם.",
    saved: "פורסם", version: "גרסת תבנית {v}", deployNote: "ערכי gemini_* נכנסים לתוקף רק ב-deploy הבא של הפונקציות.", filter: { all: "כל המצבים" },
    count: "{n} פרמטרים", edited: "נערך", confirmDelete: "להסיר את {name} מ-Remote Config?",
  },
  audit: { when: "מתי", action: "פעולה", params: "פרטים", result: "תוצאה", ok: "הצליח", failed: "נכשל", by: "מי", count: "{n} השורות האחרונות" },
  stores: {
    android: "Android", ios: "iOS", range: { d7: "7 ימים", d30: "30 יום", d90: "90 יום", y1: "שנה", all: "מאז ומתמיד" },
    totalAll: "הורדות, שתי החנויות", sinceFirst: "מאז הדוח הראשון", share: "{p} מכלל ההורדות", inRange: "בטווח שנבחר",
    perDayAvg: "ליום (ממוצע)", daysCounted: "{n} ימים", activeDevices: "מכשירים פעילים", playOnly: "Google Play בלבד", iosOnly: "App Store בלבד",
    playCounter: "המונה של Play", playCounterHint: "סה״כ התקנות משתמשים, כפי ש-Play מדווח", uninstalls: "הסרות", updates: "עדכונים",
    redownloads: "הורדות חוזרות", iap: "רכישות בתוך האפליקציה (יחידות)", perDay: "הורדות ליום", platformShare: "Android מול iOS",
    shareNote: "הורדות ראשונות מאז ומתמיד. Play סופר התקנה ראשונה של משתמש; Apple סופרת הורדה ראשונה (הורדות חוזרות בנפרד).",
    byWeek: "לפי שבוע (12 האחרונים)", byMonth: "לפי חודש", period: "תקופה", androidShare: "חלק Android", byCountry: "לפי מדינה", country: "מדינה",
    dayTable: "יום אחרי יום", cumulative: "מצטבר", noData: "אין נתונים עדיין — יש להגדיר את החנויות ולסנכרן.",
    syncNow: "סנכרון עכשיו", syncDone: "דוחות החנויות נמשכו", backfill: "משיכת היסטוריה מ-App Store", settings: "הגדרות חנויות",
    notConfigured: "לא מוגדר", failed: "נכשל", synced: "מסונכרן", neverSynced: "טרם סונכרן", lastSync: "סונכרן {when}", through: "עד {date}",
    setupIntro: "עדיין לא חובר כלום. פותחים את הגדרות החנויות: ה-bucket של Play Console לאנדרואיד, ומפתח App Store Connect API ל-iOS.",
    playHelp: "{downloadReports} → {statistics} → “{copyUri}” נותן את ה-\u2068bucket\u2069.\nתחת {users} → “{invite}” מזמינים את חשבון השירות שלמטה עם ההרשאה “{perm}”.\nמסמנים אותה בלשונית “הרשאות חשבון” ולא ב“הרשאות הניתנות לאפליקציה” (שם “הצגת פרטי האפליקציה” לבד לא מספיקה), ועד שהיא מגיעה ל-\u2068bucket\u2069 יכולות לעבור עד 24 שעות.",
    serviceAccount: "חשבון השירות להזמנה:", playBucket: "Cloud Storage bucket", playBucketHint: "pubsite_prod_… (עם או בלי gs://)", playPackage: "שם החבילה",
    appleHelp: "{usersAccess} → {integrations} → {api} → {teamKeys}: “{generate}” עם התפקיד {sales} (או {admin}).\nה-{vendor} מופיע ב-{payments}.", storeLang: "שפת החנות", storeLangHint: "השפה שבה הקונסול של החנות מוצג אצלך; שמות התפריטים בהוראות יופיעו לפיה.", storeLangUnverified: "לשפה הזו לא פורסמו שמות תפריטים רשמיים, לכן הם מוצגים בתרגום חופשי.",
    appleVendor: "מספר Vendor", appleVendorHint: "ספרות בלבד", appleIssuerId: "Issuer ID", appleKeyId: "Key ID", applePrivateKey: "מפתח פרטי (.p8)",
    keyHint: "מדביקים את כל קובץ AuthKey_….p8. נשמר בשרת ולא מוצג שוב.", keyStored: "(יש מפתח שמור — הדבקה של חדש תחליף אותו)", keyStoredHint: "ריק = להשאיר את המפתח השמור.",
    appleAppId: "Apple ID של האפליקציה", iosSince: "לספור iOS החל מ-", iosSinceHint: "הדוחות היומיים נמשכים מהתאריך הזה (Apple שומרת שנה). ריק = 365 הימים האחרונים.",
    footnote: "דוחות Google Play מגיעים פעם ביום על היום הקודם; הדוח היומי של Apple מוכן בסביבות 15:00 שעון ישראל. השרת מרענן מדי יום ב-16:30.",
  },
  err: { network: "שגיאת רשת", forbidden: "השרת סירב: למנהל בלבד", generic: "נכשל: {message}", notConfigured: "לא מוגדר בשרת" },
};

const ar = {
  lang: "اللغة",
  signOut: "تسجيل الخروج",
  menu: "القائمة",
  openApp: "الدخول إلى التطبيق",
  gate: { title: "EasyPlate Admin", intro: "لوحة الإدارة. سجّل الدخول بحساب Google الخاص بالمسؤول.", google: "تسجيل الدخول عبر Google", notAdmin: "هذا الحساب ليس المسؤول. تم تسجيل خروجك.", failed: "فشل تسجيل الدخول: {reason}", unauthorizedDomain: "هذا النطاق غير مصرّح به بعد لتسجيل الدخول. أضف aieasyplate.app في Firebase Console → Authentication → Settings → Authorized domains." },
  nav: { dashboard: "نظرة عامة", users: "الحسابات", community: "المجتمع", recipes: "الوصفات المشتركة", personas: "الشخصيات", households: "الحسابات المشتركة", tickets: "الرسائل", config: "الإعدادات", seed: "النشاط", audit: "سجل الإجراءات", stores: "التنزيلات", notifications: "الإشعارات" , whatsnew: "ما الجديد" },
  whatsnew: {
    intro: "إصدار واحد لكل رقم build. بعد التحديث يعرض التطبيق للحساب العائد صفحات كل إصدار منشور بين آخر build أقرّ به والـ build الذي يعمل — التثبيت الجديد لا يرى شيئًا. الصفحة التي علمها مخفي أو «قريبًا» لا تُعرض على الهاتف.",
    none: "لا إصدارات بعد.", newRelease: "إصدار جديد", editRelease: "تعديل الإصدار {v}", deleteRelease: "حذف الإصدار {v}؟",
    versionCode: "رقم build", versionCodeHint: "الرقم بعد + في pubspec ‏(1.2.0+12 ← 12). هو معرّف المستند.", version: "الإصدار", versionHint: "إصدار التسويق، 1.2.0", releasedAt: "تاريخ الإصدار",
    published: "منشور", publishedHint: "الإصدار المنشور فقط يصل إلى التطبيق.", publishedBadge: "منشور", draft: "مسودة", publishedNow: "نُشر", unpublishedNow: "أُلغي النشر", unpublish: "إلغاء النشر",
    features: "الميزات", featuresHint: "حدّد الميزات التي يبرزها هذا الإصدار؛ كل واحدة تصبح صفحة بالترتيب أدناه.", pickHint: "حدّد ميزات أعلاه لإضافة صفحات.", pages: "{n} صفحات", build: "build {n}",
    featureTitle: "العنوان", featureTitleHint: "قصير؛ الفارغ يعود إلى اسم الميزة في التطبيق.", featureDescription: "الوصف", translate: "ترجمة بالذكاء الاصطناعي", translated: "تُرجم إلى باقي اللغات", needText: "اكتب النص بلغة واحدة أولًا.",
    icon: "الأيقونة", target: "«جرّب» يفتح", targetHint: "اختياري. تبويب أو شاشة يمكن للتطبيق فتحها مباشرة.", noTarget: "بدون زر", image: "رابط الصورة", imageHint: "اختياري، https. تُعرض فوق النص بدل الأيقونة.",
    moveUp: "تحريك لأعلى", moveDown: "تحريك لأسفل", badCode: "رقم build يجب أن يكون عددًا صحيحًا موجبًا.", badVersion: "الإصدار يجب أن يبدو مثل 1.2.0.", needFeatures: "اختر ميزة واحدة على الأقل.", needTitle: "«{name}» يحتاج عنوانًا بلغة واحدة على الأقل.", codeExists: "يوجد إصدار بهذا الرقم — عدّله بدلًا من ذلك.",
    targets: { "tab:recipes": "تبويب الوصفات", "tab:library": "تبويب المكتبة", "tab:mealPlan": "تبويب القوائم", "tab:groceries": "تبويب المشتريات", "tab:community": "تبويب المجتمع", ingestion: "إضافة وصفة", assistant: "شيفي", price_book: "دفتر الأسعار", settings: "الإعدادات", preferences: "التفضيلات", notification_settings: "إعدادات الإشعارات", account_menu: "الحساب", notifications: "صندوق الوارد", profile_edit: "الملف الشخصي", sharing: "المشاركة", household: "الحساب المشترك", join_code: "الانضمام برمز", scan_code: "مسح رمز", home_widgets: "ودجات الشاشة الرئيسية", wake_word: "هاي شيفي", support: "الدعم", help: "المساعدة", premium: "بريميوم", tutorial: "الدليل" },
  },
  notif: {
    tabSent: "المُرسلة", tabTemplates: "القوالب", filterAll: "الكل", toAll: "للجميع", toUser: "لمستخدم", user: "المستخدم", pickUser: "اختر مستخدمًا", target: "إلى",
    sendNow: "إرسال إشعار", sendNowShort: "أرسل الآن", newTemplate: "قالب جديد", editTemplate: "تعديل القالب", deleteTemplate: "حذف هذا القالب؟",
    sendTemplateNow: "إرسال «{name}» الآن؟", confirmAll: "سيُرسل إلى كل الحسابات.", needBody: "اكتب النص أولًا.", sentOne: "أُرسل", saved: "تم الحفظ", savedNext: "تم الحفظ — الإرسال التالي {date}",
    name: "اسم القالب", nameHint: "تراه أنت فقط", when: "متى", at: "التاريخ والوقت", time: "الوقت", israelTime: "توقيت إسرائيل", weekdays: "الأيام", dayOfMonth: "يوم الشهر", dayOfMonthHint: "في الشهر الأقصر — آخر يوم فيه",
    enabled: "نشط", active: "نشط", disabled: "متوقف", enable: "تفعيل", disable: "إيقاف", next: "التالي: {date}", last: "الأخير: {date}", runs: "{n} مرات إرسال",
    noneSent: "لم يُرسل شيء بعد.", noTemplates: "لا توجد قوالب بعد.", failed: "فشل", counts: "{items} صناديق · {sent} إشعارات · {failed} فشلت",
    kinds: { manual: "يدوي فقط (أرسل الآن)", once: "مرة واحدة", daily: "كل يوم", weekly: "كل أسبوع", monthly: "كل شهر" },
    describe: { once: "مرة واحدة، {date}", daily: "كل يوم في {time}", weekly: "كل {days} في {time}", monthly: "كل شهر في اليوم {day} الساعة {time}" },
    days: { 0: "الأحد", 1: "الاثنين", 2: "الثلاثاء", 3: "الأربعاء", 4: "الخميس", 5: "الجمعة", 6: "السبت" },
    sources: { console: "وحدة التحكم", app: "التطبيق", template: "قالب", schedule: "مجدول" },
    targets: { all: "الجميع", premium: "كل مستخدمي بريميوم", free: "كل المستخدمين المجانيين", users: "مستخدمون مختارون", user: "مستخدم واحد" },
    users: "المستخدمون", pickUsers: "اختر مستخدمًا واحدًا على الأقل", pickedCount: "تم اختيار {n}", usersCount: "{n} مستخدمين", confirmUsers: "سيُرسل إلى {n} مستخدمين مختارين.",
    confirm: { all: "سيُرسل إلى كل الحسابات.", premium: "سيُرسل إلى كل الحسابات التي لديها بريميوم فعّال.", free: "سيُرسل إلى كل الحسابات بدون بريميوم." },
  },
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
    online: "متصل", offline: "غير متصل", lastSeen: "آخر ظهور", device: "الجهاز", session: "الجلسة", sessionUntil: "حتى {date}", permission: "الصلاحية", permissionAdmin: "مسؤول", permissionUser: "مستخدم", permissionHint: "المسؤول يملك وحدة التحكم كاملة وصندوق الدعم وبيانات كل الحسابات، وبلا حد للأجهزة. لا يمكن تغيير صلاحيتك أنت من هنا.", permissionSuperuser: "مستخدم خارق", permissionSuperuserHint: "المستخدم الخارق يرى كل الميزات بما فيها بريميوم مهما كانت الأعلام، وبلا حد للأجهزة. بلا صلاحيات مسؤول.", hardwareId: "معرّف الهاتف (hash)", releaseRequest: "طلب تسجيل خروج", takeoverAt: "يدخل الجهاز الجديد في {date}", declined: "مرفوض",
    noSession: "لا جلسة", premium: "بريميوم", free: "مجاني", disabled: "محظور", broadcast: "رسالة للجميع", broadcastTitle: "رسالة إلى كل الحسابات",
    broadcastSent: "{items} في صناديق الوارد، {sent} إشعارًا أُرسل، {failed} فشل", count: "{n} حسابات", joined: "انضم", persona: "شخصية",
    hint: "متصل = التطبيق مفتوح على الهاتف الآن (يُبلّغ كل دقيقة). فصل = يحرر جلسة الجهاز ويخرج التطبيق فورًا.",
  },
  user: {
    product: "المنتج", deviceId: "معرّف الجهاز", fn: "الدالة", cacheHit: "ذاكرة مؤقتة",
    profile: "الملف الشخصي", auth: "تسجيل الدخول", providers: "مزوّدو الدخول", lastSignIn: "آخر دخول", created: "أُنشئ", lastRefresh: "آخر تجديد للرمز",
    entitlement: "الاشتراك", premiumUntil: "بريميوم حتى", sourceStripe: "الموقع (Stripe)", stripeCustomer: "عميل Stripe", cancelsAtPeriodEnd: "يُلغى في نهاية الفترة", sourcePayplus: "الموقع (PayPlus، إسرائيل)", sourcePaddle: "الموقع (Paddle عبر RevenueCat، خارج إسرائيل)", webSubscription: "معرّف اشتراك الموقع", adminLock: "قفل المسؤول (الـ webhook لا يلمسه)", source: "المصدر",
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
    delete: "حذف الرسالة", none: "لا رسائل.", from: "من", appVersion: "التطبيق", yourReply: "ردك",
    all: "الكل", sent: "أُرسل الرد (صندوق الوارد + إشعار)", count: "{n} رسائل",
    types: { bug: "خلل", suggestion: "اقتراح", account: "الحساب وتسجيل الدخول", billing: "بريميوم والدفع", sharing: "المشاركة والشركاء", recipes: "إضافة الوصفات والذكاء الاصطناعي", other: "أخرى" }, details: "التفاصيل (لا تُعرض للمستخدم)", detailKeys: { name: "الاسم", email: "البريد", phone: "الهاتف", uid: "معرّف الحساب", version: "الإصدار", device: "الجهاز", language: "اللغة" }, viaShefi: "عبر شيفي", updated: "حُدّث", you: "أنت", user: "المستخدم", closed: "مغلقة", close: "إغلاق المحادثة", closeConfirm: "إغلاق محادثة {name}؟ يمكنه قراءتها ضمن \"المغلقة\" لكن لا الكتابة فيها.", reopen: "إعادة فتح", closedNow: "أُغلقت المحادثة", reopenedNow: "أُعيد فتح المحادثة", closedBadge: "مغلقة",
  },
  config: {
    search: "بحث في المعاملات…", groups: { features: "الميزات", ads: "الإعلانات والحصص", share: "المشاركة المجانية", tts: "الصوت", versions: "الإصدارات", gemini: "Gemini (يتطلب نشرًا)", other: "أخرى" },
    flags: { 0: "مخفي", 1: "قريبًا", 2: "مجاني للجميع", 3: "بريميوم فقط" }, add: "إضافة معامل", addHint: "يضيف معاملًا إلى القالب الحي وينشره. أعطه عنوانًا في i18n التطبيق أيضًا.",
    name: "المفتاح", type: "النوع", value: "القيمة", description: "الوصف", group: "المجموعة (اختياري)", delete: "إزالة المعامل", deleteHint: "يعود التطبيق إلى قيمته المدمجة لمعامل اختفى.",
    saved: "نُشر", version: "إصدار القالب {v}", deployNote: "قيم gemini_* تسري فقط عند النشر التالي للدوال.", filter: { all: "كل الحالات" },
    count: "{n} معاملات", edited: "عُدّل", confirmDelete: "إزالة {name} من Remote Config؟",
  },
  audit: { when: "متى", action: "الإجراء", params: "التفاصيل", result: "النتيجة", ok: "نجح", failed: "فشل", by: "بواسطة", count: "آخر {n} صف" },
  stores: {
    android: "Android", ios: "iOS", range: { d7: "7 أيام", d30: "30 يومًا", d90: "90 يومًا", y1: "سنة", all: "منذ البداية" },
    totalAll: "التنزيلات، المتجران معًا", sinceFirst: "منذ أول تقرير", share: "{p} من كل التنزيلات", inRange: "في هذه الفترة",
    perDayAvg: "في اليوم (متوسط)", daysCounted: "{n} يومًا", activeDevices: "الأجهزة النشطة", playOnly: "Google Play فقط", iosOnly: "App Store فقط",
    playCounter: "عدّاد Play نفسه", playCounterHint: "إجمالي تثبيتات المستخدمين كما يبلّغ عنه Play", uninstalls: "إلغاء التثبيت", updates: "التحديثات",
    redownloads: "إعادة التنزيل", iap: "مشتريات داخل التطبيق (وحدات)", perDay: "التنزيلات في اليوم", platformShare: "Android مقابل iOS",
    shareNote: "التنزيلات الأولى منذ البداية. يعدّ Play أول تثبيت للمستخدم؛ وتعدّ Apple التنزيل الأول (إعادة التنزيل منفصلة).",
    byWeek: "حسب الأسبوع (آخر 12)", byMonth: "حسب الشهر", period: "الفترة", androidShare: "حصة Android", byCountry: "حسب البلد", country: "البلد",
    dayTable: "يومًا بيوم", cumulative: "تراكمي", noData: "لا بيانات بعد — اضبط المتاجر ثم زامن.",
    syncNow: "مزامنة الآن", syncDone: "تم جلب تقارير المتاجر", backfill: "جلب سجل App Store", settings: "إعدادات المتاجر",
    notConfigured: "غير مضبوط", failed: "فشل", synced: "مُزامن", neverSynced: "لم يُزامن بعد", lastSync: "زُومن {when}", through: "حتى {date}",
    setupIntro: "لا شيء موصول بعد. افتح إعدادات المتاجر: حاوية Play Console لأندرويد، ومفتاح App Store Connect API لـ iOS.",
    playHelp: "{downloadReports} → {statistics} → «{copyUri}» يعطي الحاوية.\nفي {users} → «{invite}» ادعُ حساب الخدمة أدناه بصلاحية «{perm}».\nهذه صلاحية على مستوى الحساب وليست صلاحية للتطبيق (صلاحيات التطبيق مثل «عرض معلومات التطبيق» وحدها لا تكفي)، وقد يستغرق وصولها إلى الحاوية حتى 24 ساعة.",
    serviceAccount: "حساب الخدمة المطلوب دعوته:", playBucket: "حاوية Cloud Storage", playBucketHint: "pubsite_prod_… (مع gs:// أو بدونه)", playPackage: "اسم الحزمة",
    appleHelp: "{usersAccess} → {integrations} → {api} → {teamKeys}: «{generate}» بدور {sales} (أو {admin}).\nرقم {vendor} موجود في {payments}.", storeLang: "لغة المتجر", storeLangHint: "اللغة التي تُعرض بها وحدة تحكم المتجر لديك؛ أسماء القوائم في التعليمات تتبعها.", storeLangUnverified: "لا توجد أسماء قوائم رسمية منشورة لهذه اللغة، لذا تُعرض بترجمة حرة.",
    appleVendor: "رقم البائع", appleVendorHint: "أرقام فقط", appleIssuerId: "Issuer ID", appleKeyId: "Key ID", applePrivateKey: "المفتاح الخاص (.p8)",
    keyHint: "الصق ملف AuthKey_….p8 كاملًا. يُحفظ على الخادم ولا يُعرض ثانية.", keyStored: "(يوجد مفتاح محفوظ — الصق جديدًا لاستبداله)", keyStoredHint: "اتركه فارغًا للإبقاء على المفتاح المحفوظ.",
    appleAppId: "Apple ID للتطبيق", iosSince: "عدّ iOS ابتداءً من", iosSinceHint: "تُجلب التقارير اليومية من هذا التاريخ (تحتفظ Apple بسنة). فارغ = آخر 365 يومًا.",
    footnote: "تصل تقارير Google Play مرة يوميًا عن اليوم السابق؛ وتقرير Apple اليومي جاهز نحو 15:00 بتوقيت إسرائيل. يُحدّث الخادم يوميًا في 16:30.",
  },
  err: { network: "خطأ في الشبكة", forbidden: "رفض الخادم: للمسؤول فقط", generic: "فشل: {message}", notConfigured: "غير مهيأ على الخادم" },
};

const fr = {
  lang: "Langue",
  signOut: "Se déconnecter",
  menu: "Menu",
  openApp: "Ouvrir l’app",
  gate: { title: "EasyPlate Admin", intro: "La console d’administration. Connectez-vous avec le compte Google de l’administrateur.", google: "Se connecter avec Google", notAdmin: "Ce compte n’est pas l’administrateur. Vous avez été déconnecté.", failed: "Connexion échouée : {reason}", unauthorizedDomain: "Ce domaine n’est pas encore autorisé pour la connexion. Ajoutez aieasyplate.app dans Firebase Console → Authentication → Settings → Authorized domains." },
  nav: { dashboard: "Tableau de bord", users: "Comptes", community: "Communauté", recipes: "Recettes partagées", personas: "Personas", households: "Comptes partagés", tickets: "Tickets", config: "Configuration", seed: "Activité", audit: "Journal", stores: "Téléchargements", notifications: "Notifications" , whatsnew: "Nouveautés" },
  whatsnew: {
    intro: "Une version par numéro de build. Après une mise à jour, l'app montre à un compte qui revient les pages de chaque version publiée entre le build qu'il a validé en dernier et celui qu'il exécute — une installation neuve n'en voit aucune. Une page dont le flag est masqué ou « bientôt » n'est pas affichée sur le téléphone.",
    none: "Pas encore de version.", newRelease: "Nouvelle version", editRelease: "Modifier la version {v}", deleteRelease: "Supprimer la version {v} ?",
    versionCode: "Numéro de build", versionCodeHint: "L'entier après + dans pubspec (1.2.0+12 → 12). C'est l'identifiant du document.", version: "Version", versionHint: "La version marketing, 1.2.0", releasedAt: "Date de sortie",
    published: "Publiée", publishedHint: "Seule une version publiée atteint l'app.", publishedBadge: "Publiée", draft: "Brouillon", publishedNow: "Publiée", unpublishedNow: "Dépubliée", unpublish: "Dépublier",
    features: "Fonctionnalités", featuresHint: "Cochez les fonctionnalités mises en avant ; chacune devient une page, dans l'ordre ci-dessous.", pickHint: "Cochez des fonctionnalités ci-dessus pour ajouter des pages.", pages: "{n} pages", build: "build {n}",
    featureTitle: "Titre", featureTitleHint: "Court ; vide, l'app utilise le nom de la fonctionnalité.", featureDescription: "Description", translate: "Traduire avec l'IA", translated: "Traduit dans les autres langues", needText: "Écrivez d'abord le texte dans une langue.",
    icon: "Icône", target: "« Essayer » ouvre", targetHint: "Facultatif. Un onglet ou un écran que l'app peut ouvrir directement.", noTarget: "Pas de bouton", image: "URL de l'image", imageHint: "Facultatif, https. Affichée au-dessus du texte à la place de l'icône.",
    moveUp: "Monter", moveDown: "Descendre", badCode: "Le numéro de build doit être un entier positif.", badVersion: "La version doit ressembler à 1.2.0.", needFeatures: "Choisissez au moins une fonctionnalité.", needTitle: "« {name} » a besoin d'un titre dans au moins une langue.", codeExists: "Une version avec ce numéro existe déjà — modifiez-la.",
    targets: { "tab:recipes": "Onglet Recettes", "tab:library": "Onglet Bibliothèque", "tab:mealPlan": "Onglet Menus", "tab:groceries": "Onglet Courses", "tab:community": "Onglet Communauté", ingestion: "Ajouter une recette", assistant: "Shefi", price_book: "Carnet de prix", settings: "Réglages", preferences: "Préférences", notification_settings: "Réglages des notifications", account_menu: "Compte", notifications: "Boîte de réception", profile_edit: "Profil", sharing: "Partage", household: "Compte partagé", join_code: "Rejoindre avec un code", scan_code: "Scanner un code", home_widgets: "Widgets", wake_word: "Hey Shefi", support: "Support", help: "Aide", premium: "Premium", tutorial: "Guide" },
  },
  notif: {
    tabSent: "Envoyées", tabTemplates: "Modèles", filterAll: "Toutes", toAll: "Tout le monde", toUser: "Un utilisateur", user: "Utilisateur", pickUser: "Choisir un utilisateur", target: "Destinataires",
    sendNow: "Envoyer une notification", sendNowShort: "Envoyer", newTemplate: "Nouveau modèle", editTemplate: "Modifier le modèle", deleteTemplate: "Supprimer ce modèle ?",
    sendTemplateNow: "Envoyer « {name} » maintenant ?", confirmAll: "Cela part vers tous les comptes.", needBody: "Écrivez d’abord le texte.", sentOne: "Envoyé", saved: "Enregistré", savedNext: "Enregistré — prochain envoi {date}",
    name: "Nom du modèle", nameHint: "Visible par vous seul", when: "Quand", at: "Date et heure", time: "Heure", israelTime: "heure d’Israël", weekdays: "Jours", dayOfMonth: "Jour du mois", dayOfMonthHint: "Un mois plus court utilise son dernier jour",
    enabled: "Actif", active: "Actif", disabled: "En pause", enable: "Reprendre", disable: "Mettre en pause", next: "Prochain : {date}", last: "Dernier : {date}", runs: "{n} envois",
    noneSent: "Rien n’a encore été envoyé.", noTemplates: "Aucun modèle.", failed: "Échec", counts: "{items} boîtes · {sent} push · {failed} échecs",
    kinds: { manual: "Manuel uniquement (envoyer)", once: "Une fois", daily: "Chaque jour", weekly: "Chaque semaine", monthly: "Chaque mois" },
    describe: { once: "Une fois, {date}", daily: "Chaque jour à {time}", weekly: "Chaque {days} à {time}", monthly: "Chaque mois le {day} à {time}" },
    days: { 0: "dim.", 1: "lun.", 2: "mar.", 3: "mer.", 4: "jeu.", 5: "ven.", 6: "sam." },
    sources: { console: "Console", app: "App", template: "Modèle", schedule: "Programmée" },
    targets: { all: "Tout le monde", premium: "Tous les utilisateurs Premium", free: "Tous les utilisateurs gratuits", users: "Utilisateurs choisis", user: "Un utilisateur" },
    users: "Utilisateurs", pickUsers: "Choisissez au moins un utilisateur", pickedCount: "{n} choisis", usersCount: "{n} utilisateurs", confirmUsers: "Cela part vers {n} utilisateurs choisis.",
    confirm: { all: "Cela part vers tous les comptes.", premium: "Cela part vers tous les comptes Premium actifs.", free: "Cela part vers tous les comptes sans Premium." },
  },
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
    online: "En ligne", offline: "Hors ligne", lastSeen: "Vu", device: "Appareil", session: "Session", sessionUntil: "jusqu’au {date}", permission: "Permission", permissionAdmin: "Admin", permissionUser: "Utilisateur", permissionHint: "Un admin dispose de toute la console, de la boîte de support et des données de chaque compte, sans limite d’appareils. Votre propre permission ne se change pas ici.", permissionSuperuser: "Super-utilisateur", permissionSuperuserHint: "Un super-utilisateur voit toutes les fonctionnalités, Premium comprises, quels que soient les flags, sans limite d'appareils. Sans pouvoirs d'administrateur.", hardwareId: "Id du téléphone (hash)", releaseRequest: "Demande de déconnexion", takeoverAt: "Le nouvel appareil entre le {date}", declined: "refusée",
    noSession: "pas de session", premium: "Premium", free: "Gratuit", disabled: "Bloqué", broadcast: "Message à tous", broadcastTitle: "Message à tous les comptes",
    broadcastSent: "{items} messages, {sent} push envoyés, {failed} échecs", count: "{n} comptes", joined: "Inscrit", persona: "Persona",
    hint: "En ligne = l’app est ouverte sur un téléphone en ce moment (signalé chaque minute). Déconnecter libère la session ; l’app se déconnecte aussitôt.",
  },
  user: {
    product: "Produit", deviceId: "Identifiant de l'appareil", fn: "Fonction", cacheHit: "cache",
    profile: "Profil", auth: "Connexion", providers: "Fournisseurs", lastSignIn: "Dernière connexion", created: "Créé", lastRefresh: "Dernier rafraîchissement",
    entitlement: "Abonnement", premiumUntil: "Premium jusqu’au", sourceStripe: "Site web (Stripe)", stripeCustomer: "Client Stripe", cancelsAtPeriodEnd: "s’arrête en fin de période", sourcePayplus: "Site web (PayPlus, Israël)", sourcePaddle: "Site web (Paddle via RevenueCat, étranger)", webSubscription: "ID d’abonnement web", adminLock: "Verrou admin (le webhook n’y touche pas)", source: "Source",
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
    delete: "Supprimer le ticket", none: "Aucun ticket.", from: "De", appVersion: "App", yourReply: "Votre réponse",
    all: "Tous", sent: "Réponse envoyée (boîte + push)", count: "{n} tickets",
    types: { bug: "Bug", suggestion: "Suggestion", account: "Compte et connexion", billing: "Premium et paiement", sharing: "Partage et partenaires", recipes: "Ajout de recettes et IA", other: "Autre" }, details: "Détails (non montrés à l'utilisateur)", detailKeys: { name: "Nom", email: "E-mail", phone: "Téléphone", uid: "Id du compte", version: "Version", device: "Appareil", language: "Langue" }, viaShefi: "via Shefi", updated: "Mis à jour", you: "Vous", user: "Utilisateur", closed: "Closes", close: "Clore la conversation", closeConfirm: "Clore la conversation de {name} ? Il pourra la lire sous « closes » mais plus y écrire.", reopen: "Rouvrir", closedNow: "Conversation close", reopenedNow: "Conversation rouverte", closedBadge: "Close",
  },
  config: {
    search: "Rechercher un paramètre…", groups: { features: "Fonctions", ads: "Pubs et quotas", share: "Partage gratuit", tts: "Voix", versions: "Versions", gemini: "Gemini (déploiement requis)", other: "Autres" },
    flags: { 0: "Masqué", 1: "Bientôt", 2: "Gratuit pour tous", 3: "Premium seulement" }, add: "Ajouter un paramètre", addHint: "Ajoute un paramètre au modèle en ligne et le publie. Donnez-lui aussi un libellé dans l’i18n de l’app.",
    name: "Clé", type: "Type", value: "Valeur", description: "Description", group: "Groupe (facultatif)", delete: "Retirer le paramètre", deleteHint: "L’app revient à sa valeur intégrée pour un paramètre disparu.",
    saved: "Publié", version: "Version du modèle {v}", deployNote: "Les valeurs gemini_* ne prennent effet qu’au prochain déploiement des fonctions.", filter: { all: "Tous les états" },
    count: "{n} paramètres", edited: "Modifié", confirmDelete: "Retirer {name} de Remote Config ?",
  },
  audit: { when: "Quand", action: "Action", params: "Détails", result: "Résultat", ok: "ok", failed: "échec", by: "Par", count: "{n} dernières lignes" },
  stores: {
    android: "Android", ios: "iOS", range: { d7: "7 jours", d30: "30 jours", d90: "90 jours", y1: "Un an", all: "Depuis le début" },
    totalAll: "Téléchargements, deux stores", sinceFirst: "depuis le premier rapport", share: "{p} de tous les téléchargements", inRange: "Sur la période",
    perDayAvg: "Par jour (moyenne)", daysCounted: "{n} jours", activeDevices: "Appareils actifs", playOnly: "Google Play seulement", iosOnly: "App Store seulement",
    playCounter: "Compteur de Play", playCounterHint: "Total des installations utilisateur, tel que Play le rapporte", uninstalls: "Désinstallations", updates: "Mises à jour",
    redownloads: "Retéléchargements", iap: "Achats intégrés (unités)", perDay: "Téléchargements par jour", platformShare: "Android vs iOS",
    shareNote: "Premiers téléchargements depuis le début. Play compte la première installation d’un utilisateur ; Apple compte le premier téléchargement (retéléchargements à part).",
    byWeek: "Par semaine (12 dernières)", byMonth: "Par mois", period: "Période", androidShare: "Part Android", byCountry: "Par pays", country: "Pays",
    dayTable: "Jour par jour", cumulative: "Cumul", noData: "Pas encore de données — configurez les stores puis synchronisez.",
    syncNow: "Synchroniser", syncDone: "Rapports des stores récupérés", backfill: "Récupérer l’historique App Store", settings: "Réglages des stores",
    notConfigured: "non configuré", failed: "échec", synced: "synchronisé", neverSynced: "jamais synchronisé", lastSync: "synchronisé {when}", through: "jusqu’au {date}",
    setupIntro: "Rien n’est encore connecté. Ouvrez les réglages : le bucket Play Console pour Android, une clé App Store Connect API pour iOS.",
    playHelp: "{downloadReports} → {statistics} → « {copyUri} » donne le bucket.\nSous {users} → « {invite} », invitez le compte de service ci-dessous avec « {perm} ».\nC’est une autorisation au niveau du compte, pas de l’application (les autorisations d’application comme « Afficher les informations sur les applications » seules ne suffisent pas), et elle peut mettre jusqu’à 24 heures à atteindre le bucket.",
    serviceAccount: "Compte de service à inviter :", playBucket: "Bucket Cloud Storage", playBucketHint: "pubsite_prod_… (avec ou sans gs://)", playPackage: "Nom du package",
    appleHelp: "{usersAccess} → {integrations} → {api} → {teamKeys} : « {generate} » avec le rôle {sales} (ou {admin}).\nLe {vendor} figure dans {payments}.", storeLang: "Langue de la boutique", storeLangHint: "La langue d’affichage de votre console ; les noms de menus des instructions la suivent.", storeLangUnverified: "Aucun nom de menu officiel n’est publié pour cette langue : ils sont affichés en traduction libre.",
    appleVendor: "Numéro de vendeur", appleVendorHint: "Chiffres seulement", appleIssuerId: "Issuer ID", appleKeyId: "Key ID", applePrivateKey: "Clé privée (.p8)",
    keyHint: "Collez tout le fichier AuthKey_….p8. Stockée côté serveur, jamais réaffichée.", keyStored: "(une clé est stockée — collez-en une nouvelle pour la remplacer)", keyStoredHint: "Laissez vide pour garder la clé stockée.",
    appleAppId: "Apple ID de l’app", iosSince: "Compter iOS à partir du", iosSinceHint: "Les rapports quotidiens sont récupérés depuis cette date (Apple garde un an). Vide = les 365 derniers jours.",
    footnote: "Les rapports Google Play arrivent une fois par jour pour la veille ; le rapport quotidien d’Apple est prêt vers 15 h (heure d’Israël). Le serveur actualise chaque jour à 16 h 30.",
  },
  err: { network: "Erreur réseau", forbidden: "Le serveur a refusé : administrateur seulement", generic: "Échec : {message}", notConfigured: "Non configuré côté serveur" },
};

const ru = {
  lang: "Язык",
  signOut: "Выйти",
  menu: "Меню",
  openApp: "Открыть приложение",
  gate: { title: "EasyPlate Admin", intro: "Консоль администратора. Войдите через Google-аккаунт администратора.", google: "Войти через Google", notAdmin: "Этот аккаунт не администратор. Вы вышли.", failed: "Вход не удался: {reason}", unauthorizedDomain: "Домен ещё не разрешён для входа. Добавьте aieasyplate.app в Firebase Console → Authentication → Settings → Authorized domains." },
  nav: { dashboard: "Обзор", users: "Аккаунты", community: "Сообщество", recipes: "Общие рецепты", personas: "Персонажи", households: "Общие аккаунты", tickets: "Обращения", config: "Настройки", seed: "Активность", audit: "Журнал", stores: "Загрузки", notifications: "Уведомления" , whatsnew: "Что нового" },
  whatsnew: {
    intro: "Один выпуск на номер build. После обновления приложение показывает вернувшемуся аккаунту страницы каждого опубликованного выпуска между последним подтверждённым build и текущим — новая установка не видит ничего. Страница, флаг которой скрыт или «скоро», на телефоне не показывается.",
    none: "Выпусков пока нет.", newRelease: "Новый выпуск", editRelease: "Изменить выпуск {v}", deleteRelease: "Удалить выпуск {v}?",
    versionCode: "Номер build", versionCodeHint: "Число после + в pubspec (1.2.0+12 → 12). Это идентификатор документа.", version: "Версия", versionHint: "Маркетинговая версия, 1.2.0", releasedAt: "Дата выпуска",
    published: "Опубликован", publishedHint: "В приложение попадает только опубликованный выпуск.", publishedBadge: "Опубликован", draft: "Черновик", publishedNow: "Опубликован", unpublishedNow: "Публикация снята", unpublish: "Снять с публикации",
    features: "Функции", featuresHint: "Отметьте функции, которые выделяет этот выпуск; каждая становится страницей в порядке ниже.", pickHint: "Отметьте функции выше, чтобы добавить страницы.", pages: "Страниц: {n}", build: "build {n}",
    featureTitle: "Заголовок", featureTitleHint: "Коротко; пустой заменяется названием функции в приложении.", featureDescription: "Описание", translate: "Перевести с ИИ", translated: "Переведено на остальные языки", needText: "Сначала напишите текст на одном языке.",
    icon: "Значок", target: "«Попробовать» открывает", targetHint: "Необязательно. Вкладка или экран, который приложение может открыть напрямую.", noTarget: "Без кнопки", image: "URL картинки", imageHint: "Необязательно, https. Показывается над текстом вместо значка.",
    moveUp: "Выше", moveDown: "Ниже", badCode: "Номер build должен быть положительным целым числом.", badVersion: "Версия должна выглядеть как 1.2.0.", needFeatures: "Выберите хотя бы одну функцию.", needTitle: "«{name}» нужен заголовок хотя бы на одном языке.", codeExists: "Выпуск с таким номером уже есть — измените его.",
    targets: { "tab:recipes": "Вкладка «Рецепты»", "tab:library": "Вкладка «Библиотека»", "tab:mealPlan": "Вкладка «Меню»", "tab:groceries": "Вкладка «Покупки»", "tab:community": "Вкладка «Сообщество»", ingestion: "Добавить рецепт", assistant: "Шефи", price_book: "Книга цен", settings: "Настройки", preferences: "Предпочтения", notification_settings: "Настройки уведомлений", account_menu: "Аккаунт", notifications: "Входящие", profile_edit: "Профиль", sharing: "Общий доступ", household: "Общий аккаунт", join_code: "Присоединиться по коду", scan_code: "Сканировать код", home_widgets: "Виджеты", wake_word: "Hey Shefi", support: "Поддержка", help: "Помощь", premium: "Премиум", tutorial: "Справочник" },
  },
  notif: {
    tabSent: "Отправленные", tabTemplates: "Шаблоны", filterAll: "Все", toAll: "Всем", toUser: "Пользователю", user: "Пользователь", pickUser: "Выберите пользователя", target: "Кому",
    sendNow: "Отправить уведомление", sendNowShort: "Отправить", newTemplate: "Новый шаблон", editTemplate: "Изменить шаблон", deleteTemplate: "Удалить шаблон?",
    sendTemplateNow: "Отправить «{name}» сейчас?", confirmAll: "Уйдёт во все аккаунты.", needBody: "Сначала напишите текст.", sentOne: "Отправлено", saved: "Сохранено", savedNext: "Сохранено — следующая отправка {date}",
    name: "Название шаблона", nameHint: "Видно только вам", when: "Когда", at: "Дата и время", time: "Время", israelTime: "время Израиля", weekdays: "Дни", dayOfMonth: "День месяца", dayOfMonthHint: "В коротком месяце — последний день",
    enabled: "Активен", active: "Активен", disabled: "На паузе", enable: "Возобновить", disable: "Пауза", next: "Следующая: {date}", last: "Последняя: {date}", runs: "{n} отправок",
    noneSent: "Пока ничего не отправлено.", noTemplates: "Шаблонов пока нет.", failed: "Ошибка", counts: "{items} ящиков · {sent} пушей · {failed} ошибок",
    kinds: { manual: "Только вручную (отправить)", once: "Один раз", daily: "Каждый день", weekly: "Каждую неделю", monthly: "Каждый месяц" },
    describe: { once: "Один раз, {date}", daily: "Каждый день в {time}", weekly: "Каждую {days} в {time}", monthly: "Каждый месяц {day} числа в {time}" },
    days: { 0: "вс", 1: "пн", 2: "вт", 3: "ср", 4: "чт", 5: "пт", 6: "сб" },
    sources: { console: "Консоль", app: "Приложение", template: "Шаблон", schedule: "По расписанию" },
    targets: { all: "Всем", premium: "Всем пользователям Премиум", free: "Всем бесплатным пользователям", users: "Выбранным пользователям", user: "Одному пользователю" },
    users: "Пользователи", pickUsers: "Выберите хотя бы одного пользователя", pickedCount: "Выбрано: {n}", usersCount: "{n} польз.", confirmUsers: "Уйдёт {n} выбранным пользователям.",
    confirm: { all: "Уйдёт во все аккаунты.", premium: "Уйдёт во все аккаунты с активным Премиум.", free: "Уйдёт во все аккаунты без Премиум." },
  },
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
    online: "Онлайн", offline: "Не в сети", lastSeen: "Был(а)", device: "Устройство", session: "Сессия", sessionUntil: "до {date}", permission: "Права", permissionAdmin: "Администратор", permissionUser: "Пользователь", permissionHint: "Администратор получает всю консоль, поддержку и данные каждой учётной записи, без лимита устройств. Свои собственные права здесь изменить нельзя.", permissionSuperuser: "Суперпользователь", permissionSuperuserHint: "Суперпользователь видит все функции, включая Премиум, независимо от флагов, и без лимита устройств. Без прав администратора.", hardwareId: "Id телефона (hash)", releaseRequest: "Запрос на выход", takeoverAt: "Новое устройство войдёт {date}", declined: "отклонён",
    noSession: "нет сессии", premium: "Premium", free: "Бесплатно", disabled: "Заблокирован", broadcast: "Сообщение всем", broadcastTitle: "Сообщение всем аккаунтам",
    broadcastSent: "{items} сообщений, {sent} push отправлено, {failed} не удалось", count: "{n} аккаунтов", joined: "Зарегистрирован", persona: "Персонаж",
    hint: "Онлайн = приложение сейчас открыто на телефоне (отчёт каждую минуту). Отключить = освобождает сессию устройства, приложение сразу выходит.",
  },
  user: {
    product: "Продукт", deviceId: "ID устройства", fn: "Функция", cacheHit: "кэш",
    profile: "Профиль", auth: "Вход", providers: "Провайдеры", lastSignIn: "Последний вход", created: "Создан", lastRefresh: "Последнее обновление токена",
    entitlement: "Подписка", premiumUntil: "Premium до", sourceStripe: "Сайт (Stripe)", stripeCustomer: "Клиент Stripe", cancelsAtPeriodEnd: "отменяется в конце периода", sourcePayplus: "Сайт (PayPlus, Израиль)", sourcePaddle: "Сайт (Paddle через RevenueCat, за рубежом)", webSubscription: "ID веб-подписки", adminLock: "Блокировка администратора (webhook не трогает)", source: "Источник",
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
    delete: "Удалить обращение", none: "Обращений нет.", from: "От", appVersion: "Приложение", yourReply: "Ваш ответ",
    all: "Все", sent: "Ответ отправлен (входящие + push)", count: "{n} обращений",
    types: { bug: "Ошибка", suggestion: "Предложение", account: "Аккаунт и вход", billing: "Премиум и оплата", sharing: "Общий доступ и партнёры", recipes: "Добавление рецептов и ИИ", other: "Другое" }, details: "Детали (пользователю не показываются)", detailKeys: { name: "Имя", email: "Почта", phone: "Телефон", uid: "ID аккаунта", version: "Версия", device: "Устройство", language: "Язык" }, viaShefi: "через Шефи", updated: "Обновлено", you: "Вы", user: "Пользователь", closed: "Закрытые", close: "Закрыть обращение", closeConfirm: "Закрыть обращение {name}? Он сможет читать его в «закрытых», но не писать.", reopen: "Открыть снова", closedNow: "Обращение закрыто", reopenedNow: "Обращение открыто снова", closedBadge: "Закрыто",
  },
  config: {
    search: "Поиск параметров…", groups: { features: "Функции", ads: "Реклама и квоты", share: "Бесплатный шеринг", tts: "Голос", versions: "Версии", gemini: "Gemini (нужен деплой)", other: "Прочее" },
    flags: { 0: "Скрыто", 1: "Скоро", 2: "Бесплатно всем", 3: "Только Premium" }, add: "Добавить параметр", addHint: "Добавляет параметр в живой шаблон и публикует его. Дайте ему подпись и в i18n приложения.",
    name: "Ключ", type: "Тип", value: "Значение", description: "Описание", group: "Группа (необязательно)", delete: "Удалить параметр", deleteHint: "Для исчезнувшего параметра приложение использует встроенное значение.",
    saved: "Опубликовано", version: "Версия шаблона {v}", deployNote: "Значения gemini_* вступают в силу только при следующем деплое функций.", filter: { all: "Все состояния" },
    count: "{n} параметров", edited: "Изменено", confirmDelete: "Удалить {name} из Remote Config?",
  },
  audit: { when: "Когда", action: "Действие", params: "Детали", result: "Результат", ok: "ок", failed: "ошибка", by: "Кто", count: "последние {n} строк" },
  stores: {
    android: "Android", ios: "iOS", range: { d7: "7 дней", d30: "30 дней", d90: "90 дней", y1: "Год", all: "За всё время" },
    totalAll: "Загрузки, оба магазина", sinceFirst: "с первого отчёта", share: "{p} всех загрузок", inRange: "За период",
    perDayAvg: "В день (в среднем)", daysCounted: "{n} дней", activeDevices: "Активные устройства", playOnly: "Только Google Play", iosOnly: "Только App Store",
    playCounter: "Счётчик самого Play", playCounterHint: "Всего установок пользователями, как сообщает Play", uninstalls: "Удаления", updates: "Обновления",
    redownloads: "Повторные загрузки", iap: "Покупки в приложении (единицы)", perDay: "Загрузок в день", platformShare: "Android и iOS",
    shareNote: "Первые загрузки за всё время. Play считает первую установку пользователя; Apple — первую загрузку (повторные отдельно).",
    byWeek: "По неделям (последние 12)", byMonth: "По месяцам", period: "Период", androidShare: "Доля Android", byCountry: "По странам", country: "Страна",
    dayTable: "По дням", cumulative: "Накопительно", noData: "Данных пока нет — настройте магазины и синхронизируйте.",
    syncNow: "Синхронизировать", syncDone: "Отчёты магазинов получены", backfill: "Загрузить историю App Store", settings: "Настройки магазинов",
    notConfigured: "не настроено", failed: "ошибка", synced: "синхронизировано", neverSynced: "ещё не синхронизировано", lastSync: "синхронизировано {when}", through: "по {date}",
    setupIntro: "Пока ничего не подключено. Откройте настройки магазинов: bucket Play Console для Android и ключ App Store Connect API для iOS.",
    playHelp: "{downloadReports} → {statistics} → «{copyUri}» даёт bucket.\nВ {users} → «{invite}» пригласите сервисный аккаунт ниже с правом «{perm}».\nЭто разрешение уровня аккаунта, а не приложения (одних разрешений приложения вроде «Просмотр информации о приложении» недостаточно), и до bucket оно может дойти в течение 24 часов.",
    serviceAccount: "Сервисный аккаунт для приглашения:", playBucket: "Bucket Cloud Storage", playBucketHint: "pubsite_prod_… (с gs:// или без)", playPackage: "Имя пакета",
    appleHelp: "{usersAccess} → {integrations} → {api} → {teamKeys}: «{generate}» с ролью {sales} (или {admin}).\n{vendor} указан в {payments}.", storeLang: "Язык магазина", storeLangHint: "Язык, на котором у вас открыта консоль; названия меню в инструкции следуют ему.", storeLangUnverified: "Официальные названия меню на этом языке не опубликованы, поэтому они показаны в свободном переводе.",
    appleVendor: "Номер продавца (vendor)", appleVendorHint: "Только цифры", appleIssuerId: "Issuer ID", appleKeyId: "Key ID", applePrivateKey: "Закрытый ключ (.p8)",
    keyHint: "Вставьте весь файл AuthKey_….p8. Хранится на сервере и больше не показывается.", keyStored: "(ключ сохранён — вставьте новый, чтобы заменить)", keyStoredHint: "Оставьте пустым, чтобы сохранить текущий ключ.",
    appleAppId: "Apple ID приложения", iosSince: "Считать iOS с", iosSinceHint: "Ежедневные отчёты берутся с этой даты (Apple хранит год). Пусто = последние 365 дней.",
    footnote: "Отчёты Google Play приходят раз в день за предыдущий день; дневной отчёт Apple готов около 15:00 по Израилю. Сервер обновляет данные ежедневно в 16:30.",
  },
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
  for (const el of document.querySelectorAll("[data-i18n-label]")) el.setAttribute("aria-label", t(el.getAttribute("data-i18n-label")));
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
