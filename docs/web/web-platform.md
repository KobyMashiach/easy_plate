# EasyPlate על ה-Web — ארכיטקטורה והטמעה

נבנה 2026-10-18. האתר יושב על אותו דומיין כמו דף הנחיתה (`aieasyplate.app`) תחת
`/app`, מתחבר לאותו Firebase (Auth + Firestore) כמו האפליקציה, ומוכר פרימיום בלי עמלת חנות.

> **עדכון 2026-10-18:** Stripe לא מקבלת עסקים ישראליים. התשלום באתר עבר ל-**PayPlus** (חשבונות `+972`)
> ול-**RevenueCat + Paddle** (כל השאר: דף רכישה של RevenueCat, Paddle = merchant of record; מאז 2026-10-18). הכול — עובדות, מבנה, מיפוי והגדרות שקובי צריך לעשות — ב-
> [`web-payments.md`](web-payments.md). קטעי Stripe למטה נשארו כתיעוד של הקוד הרדום (`functions/stripeBilling.js`).

## מפת הקוד

| חלק | איפה | מה |
|---|---|---|
| אפליקציית Web | `webapp/` (Vite + React 18 + TypeScript + Tailwind 3.4) | נבנה אל `landing/app/` ומוגש על ידי Firebase Hosting תחת `/app/**` (rewrite ל-`index.html`) |
| טוקני עיצוב | `webapp/src/styles/tokens.css` | נוצר מ-`lib/core/constants/app_palette.dart` (בהיר + כהה), RGB triplets. ה-Tailwind (`tailwind.config.cjs`) ממפה אליהם צבעים, רדיוסים (8/16/24/32/48), צללים (AppShadows) וסקאלת טיפוגרפיה (AppTextStyles) |
| רכיבי Clay | `webapp/src/styles/index.css`, `components/ui.tsx` | `.clay`, `.clay-btn-*` (אקסטרוזיה 4px שנלחצת), `.clay-input`, pills |
| מסגרת | `components/Shell.tsx` | בנייד — מסך מלא; בדסקטופ — עמודה 480px במסגרת "מכשיר" מעוגלת. header: לוגו, שפה, מראה; footer: פרטיות/תנאים/תמיכה |
| Firebase | `lib/firebase.ts` | config מ-`/__/firebase/init.json` (כמו הקונסול); מקומית `VITE_FIREBASE_CONFIG` |
| אימות | `lib/auth.tsx`, `pages/LoginPage.tsx`, `pages/PhoneGatePage.tsx` | טלפון (SMS) קודם, Google / Apple כדרך חזרה. חשבון בלי ספק `phone` נעצר בשער הטלפון (כמו `AuthStage.needsPhone`) |
| זכאות | `lib/entitlement.ts` | אותו `resolvePremium` כמו ב-Dart; listener על `entitlements/{uid}` + `web_customers/{uid}` |
| חשבון | `pages/AccountPage.tsx` | סטטוס, מקור (חנות/אתר/משק בית/מנהל), ניהול (Stripe Portal) או שדרוג, שליחת קישור, מתכונים |
| תמחור | `pages/PricingPage.tsx` | חבילות מ-Stripe (`webBilling plans`), checkout, טיפול ב-409 |
| קישור אישי | `pages/UpgradePage.tsx`, `pages/LinkRequestPage.tsx` | `/upgrade/:token` → redeem → `signInWithCustomToken` → תמחור |
| מתכונים (צפייה בלייב) | `pages/RecipesPage.tsx`, `pages/RecipeViewPage.tsx`, `components/Protected.tsx` | `user-select: none`, חסימת קליק ימני/העתקה/גרירה/קיצורי הדפסה, סימן מים דינמי (מייל/טלפון + תאריך), טשטוש כשהחלון מאבד פוקוס או בהדפסה |
| שרת — חיוב | `functions/webBilling.js` + `billingCatalog.js` | `plans` / `checkout` / `manage` / `status`; ספק לפי טלפון (PayPlus / RevenueCat-Paddle) — ראו `web-payments.md`. Stripe הישן ב-`stripeBilling.js` (רדום) |
| שרת — webhook | `functions/payplusWebhook.js` + `functions/revenueCatWebhook.js` (store `PADDLE`); `paddleWebhook.js` פרוש ולא מיוצא; `stripeWebhook.js` רדום | PayPlus: אימות חתימה (HMAC), אידמפוטנטיות, `webEntitlement.js`. Paddle: מגיע מ-RevenueCat כמו רכישה בחנות. הכול דרך אותו `applyInTransaction`, שורת audit ב-`purchase_events` |
| שרת — קישורים | `functions/upgradeLinks.js` | `mint` / `send` / `redeem`; טוקן 256 ביט, נשמר רק ה-SHA-256, חד-פעמי, 30 דק׳; SMS דרך Twilio REST, מייל דרך אוסף `mail` (Trigger Email extension); rate limit לבקשות אנונימיות |
| אפליקציה | `lib/core/monetization/web_billing_links.dart`, תפריט חשבון, פייוול | שורת "שדרוג וניהול המנוי באתר" (דגל `ff_web_checkout`), פייוול שמפנה לאתר כשהמנוי נרכש שם (`EntitlementService.fromWeb`) |

## זרימת הכסף (Stripe — רדום; הזרימה הנוכחית ב-`web-payments.md`)

1. המשתמש בוחר חבילה → `POST webBilling {action:'checkout', priceId}` עם ID token.
2. השרת בודק: הדגל פעיל, המחיר שלנו (lookup key מתחיל ב-`easy_plate_`), אין מנוי חנות/משק בית/הענקה נעולה/מנוי web פעיל. יוצר (או מוצא) Stripe customer עם `metadata.uid`, שומר ב-`stripe_customers/{uid}`.
3. Checkout Session במצב subscription; ה-uid נוסע כ-`client_reference_id` וב-metadata של הסשן והמנוי. קופון intro (metadata `intro_coupon`) רק למי שמעולם לא היה לו מנוי (`everSubscribed`).
4. Stripe שולח `customer.subscription.created/updated/deleted` → `stripeWebhook` כותב `entitlements/{uid}` עם `premium`, `premiumUntil` (סוף התקופה), `source:'stripe'`, `productId` (lookup key — מכיל `duo`/`family` לטייר של משק הבית).
5. האפליקציה כבר מקשיבה למסמך הזה → פרימיום נפתח מיידית; `onOwnerEntitlementChanged` מפזר למשק הבית כרגיל.
6. ביטול: Stripe Portal (`portal`) → `cancel_at_period_end` → פרימיום נשאר עד סוף התקופה, אז `deleted` מכבה.

## מה צריך להגדיר (רק קובי)

> תשלומים: ההגדרות של PayPlus ושל RevenueCat + Paddle (חשבונות, secrets, Remote Config, deploy) ב-[`web-payments.md`](web-payments.md). סעיפים 1–3 כאן (Stripe) כבר לא רלוונטיים; 4–6 עדיין כן.

1. **Stripe**: חשבון, מוצר "EasyPlate Premium" עם מחירים מתחדשים ו-lookup keys:
   `easy_plate_ai_pro_monthly` (₪20), אופציונלי `easy_plate_ai_pro_duo_monthly`, `easy_plate_ai_pro_family_monthly`, `..._yearly`.
   על המחיר: metadata `order` (סדר תצוגה), ולהצעת ₪10 לחודש ראשון — קופון `amount_off=1000, duration=once` ואז metadata `intro_coupon=<coupon id>`, `intro_amount=1000`.
   להפעיל Apple Pay / Google Pay ב-Settings → Payment methods. להפעיל Customer Portal (Settings → Billing → Customer portal) עם ביטול והחלפת מחירים.
2. **Webhook ב-Stripe**: URL `https://europe-west1-easy-plate.cloudfunctions.net/stripeWebhook`, אירועים:
   `checkout.session.completed`, `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.paid`, `invoice.payment_failed`.
3. **Secrets** (ואז deploy):
   ```bash
   firebase functions:secrets:set STRIPE_SECRET_KEY
   firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
   firebase functions:secrets:set TWILIO_ACCOUNT_SID    # "-" אם אין SMS
   firebase functions:secrets:set TWILIO_AUTH_TOKEN     # "-"
   firebase functions:secrets:set TWILIO_FROM           # מספר או Messaging Service SID, "-"
   firebase deploy --only functions:webBilling,functions:stripeWebhook,functions:upgradeLinks
   ```
4. **Firebase Authentication → Settings → Authorized domains**: להוסיף `aieasyplate.app` (חוסם גם את הקונסול). Phone auth ב-web דורש reCAPTCHA — עובד אוטומטית אחרי זה. Apple ב-web דורש Service ID + return URL `https://easy-plate.firebaseapp.com/__/auth/handler`.
5. **מייל**: להתקין את ה-extension "Trigger Email from Firestore" על אוסף `mail` עם SMTP (או להחליף את `sendEmail` ב-`upgradeLinks.js`).
6. **Remote Config**: `ff_web_checkout` נוסף לתבנית עם ברירת מחדל `0` (מוסתר). לפרסם (`node functions/scripts/publishRemoteConfig.js`) ולהעלות ל-`2` כשהכל מוכן. **שימו לב למדיניות החנויות**: קישור מתוך האפליקציה לרכישה חיצונית מותר רק באזורים מסוימים (ארה"ב אחרי Epic, האיחוד האירופי תחת DMA, יפן). באתר עצמו אין מגבלה.

## פיתוח מקומי

```bash
cd webapp && npm install
echo 'VITE_FIREBASE_CONFIG={"apiKey":"...","authDomain":"easy-plate.firebaseapp.com","projectId":"easy-plate",...}' > .env.local
npm run dev          # http://localhost:5173/app/
npm run build        # → landing/app
./run.sh deployWebsite   # בונה webapp + landing ומעלה hosting
```

הפונקציות מקבלות `localhost` ב-CORS. `functions/` — `npm test` (192 טסטים, כולל 21 חדשים).

## אבטחה — מה כן ומה לא

- הלקוח לעולם לא כותב `entitlements`, `stripe_customers`, `upgrade_links`: רק הפונקציות (admin SDK). החוקים: קריאה עצמית בלבד.
- החתימה של Stripe מאומתת על `rawBody` עם סבילות 5 דקות; אירועים ישנים לא מדרסים חדשים (`lastEventAt`); נעילת מנהל מכובדת.
- קישור שדרוג = אותו כוח כמו קוד SMS: מי שמחזיק את הטלפון מחזיק את החשבון. חד-פעמי, 30 דק׳, hash בלבד במסד.
- הבקשה האנונימית ל"שלח לי קישור" לא מגלה אם קיים חשבון, ומוגבלת ל-3 לשעה ליעד ו-10 לשעה ל-IP.
- הגנות התוכן באתר הן הרתעה (סימון, העתקה, קליק ימני, הדפסה, טשטוש) — צילום מסך ממכשיר אחר תמיד אפשרי; לכן סימן המים נושא את זהות הצופה.
