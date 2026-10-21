# תשלומים באתר — PayPlus (ישראל) + RevenueCat/Paddle (חו״ל)

החלטה מ-2026-10-18: Stripe לא מקבלת עסקים שרשומים בישראל (ישראל לא מופיעה ב-stripe.com/global),
ולכן הרכישה באתר (`aieasyplate.app/app`) עוברת לשני ספקים:

| מי | ספק | למה |
|---|---|---|
| חשבון עם טלפון מאומת `+972…` | **PayPlus** — סולק ישראלי | רוב התשלומים; שקלים; הוראת קבע; Apple Pay / Google Pay בדף הסליקה |
| כל השאר | **RevenueCat → Paddle Billing** — Paddle = Merchant of Record | מקבל מוכרים ישראלים, מוכר בשמו, מטפל במע״מ/מס מכירה בעולם; **עובר דרך RevenueCat** כדי שכל המנויים (App Store, Play, אתר) יופיעו בדשבורד אחד |

**החלטה 2026-10-18 (קובי):** הקופה הבינלאומית עוברת דרך האינטגרציה של RevenueCat עם Paddle Billing.
PayPlus נשאר ישיר בדיוק כמו שהוא (ל-RevenueCat אין אינטגרציה עם PayPlus).
המסלול הישיר ל-Paddle (Paddle.js על הדף שלנו + `paddleWebhook`) **פרוש**: הקוד נשאר לעיון, `paddleWebhook` כבר לא מיוצא מ-`index.js`
(שני מקבלים לאותה רכישה = הענקה כפולה).

שני המסלולים כותבים לאותו `entitlements/{uid}` דרך אותו `applyInTransaction`
(admin-lock, מקור אחר, אירוע ישן) — PayPlus דרך `webEntitlement.js`, Paddle דרך `revenueCatWebhook` (source `revenuecat`, store `PADDLE`).
Stripe נשאר בקוד במצב רדום (`functions/stripeBilling.js`, `stripeWebhook.js`) לטובת מסלול US-LLC עתידי.

## למה PayPlus ולא Cardcom

| | PayPlus | Cardcom |
|---|---|---|
| דף סליקה מתארח עם הוראת קבע | `PaymentPages/generateLink` עם `charge_method: 3` + `recurring_settings` | LowProfile, הוראת קבע דרך מודול נפרד |
| API להוראות קבע | Add / Update / **DeleteRecurring** / Valid / View / ViewRecurring | ב-v11 רק Get (אין יצירה/ביטול) |
| אימות callback | header `hash` = HMAC-SHA256 base64 עם ה-secret key | אין חתימה — צריך למשוך `GetLpResult` |
| סביבת בדיקות | `restapidev.payplus.co.il` + כרטיסי בדיקה מתועדים | יש |
| Apple Pay / Google Pay / bit | `charge_default` / `allowed_charge_methods` כוללים `apple-pay`, `google-pay`, `bit` | Apple Pay נתמך |

PayPlus עדיף: callback חתום שהשרת מאמת, וביטול הוראת קבע ב-API. **לא אומת במסמכים:** ש-Apple Pay / Google Pay
זמינים על דף עם `charge_method: 3` (הוראת קבע) — לוודא מול התמיכה של PayPlus בפתיחת החשבון. **bit לא מתאים להוראת קבע**
(תשלום חד-פעמי ב-SMS) ולכן לא ישמש למנוי.

## עובדות שאומתו (מקורות רשמיים)

**PayPlus** (docs.payplus.co.il)
- כתובות: Production `https://restapi.payplus.co.il/api/v1.0/`, Staging `https://restapidev.payplus.co.il/api/v1.0/` — [Environment URLs](https://docs.payplus.co.il/reference/payplus-rest-api-urls)
- אימות: headers `api-key`, `secret-key`; קריאות רק מהשרת — [Website or App](https://docs.payplus.co.il/reference/website-or-app)
- דף תשלום: `POST /PaymentPages/generateLink` (`payment_page_uid`, `amount`, `currency_code`, `charge_method` 3 = Recurring, `recurring_settings`, `refURL_success/failure/cancel/callback`, `send_failure_callback`, `more_info…more_info_5`, `customer`, `expiry_datetime`) → `data.payment_page_link`, `data.page_request_uid` — [Generate Payment Link](https://docs.payplus.co.il/reference/post_paymentpages-generatelink)
- callback: `transaction_type` (Charge/Refund), `transaction.status_code` ("000" = הצליח), `transaction.more_info*`, `transaction.recurring_charge_information.recurring_uid`, `data.customer_uid` — [Transaction Callback Response](https://docs.payplus.co.il/reference/get_yourdomain-yourendpoint)
- אימות callback: `user-agent: PayPlus` ו-`hash` = `base64(HMAC-SHA256(secret_key, JSON.stringify(body)))` — [Validate Requests](https://docs.payplus.co.il/reference/validate-requests-received-from-payplus)
- ביטול: `POST /RecurringPayments/DeleteRecurring/{uid}` עם `terminal_uid` — [Delete Recurring](https://docs.payplus.co.il/reference/post_recurringpayments-deleterecurring-uid); רשימה לפי לקוח `GET /RecurringPayments/View?customer_uid=` — [View](https://docs.payplus.co.il/reference/get_recurringpayments-view)
- סגירת דף שלא שולם: `POST /PaymentPages/Disable/{page_request_uid}` — [Disable Payment Link](https://docs.payplus.co.il/reference/post_paymentpages-disable-page-request-uid)
- כרטיסי בדיקה: `5326-1402-8077-9844` 05/30 CVV 000 (מצליח), `5326-1402-0001-0120` (נדחה) — [Sandbox cards](https://docs.payplus.co.il/reference/sandbox-credit-card-numbers)
- Google Pay ו-Apple Pay מופעלים בדשבורד (Settings → Alternative Payment Methods / תמיכה) — [Payment Methods](https://docs.payplus.co.il/reference/payment-methods)

**RevenueCat + Paddle Billing** (revenuecat.com/docs — נבדק 2026-10-18)
- שלוש דרכים לקופה עם Paddle: Web SDK (`@revenuecat/purchases-js`), **Web Purchase Links** (דף מתארח של RevenueCat), Paywalls/Funnels — [Paddle integration](https://www.revenuecat.com/docs/web/integrations/paddle), [Web overview](https://www.revenuecat.com/docs/web/overview) ("Paddle remains the billing engine and merchant of record"; "no additional RevenueCat fees" על רכישות web — עמלות Paddle כרגיל).
- **בחרנו Web Purchase Link.** ה-SDK תומך ב-Paddle, אבל אז ה-App User ID נקבע בדפדפן ו-Paddle.js נטען מהדף שלנו (CSP + אישור דומיין שלנו ב-Paddle). ב-Link השרת בונה את ה-URL מה-uid של ה-ID token המאומת — הלקוח לא בוחר חשבון — ואין סקריפט צד שלישי בדף שלנו.
- פורמט: `https://pay.rev.cat/<token>/<URL-encoded App User ID>` — "You must append the URL-encoded App User ID of the customer to the link"; פרמטרים: `email`, `package_id` (בחירת חבילה מראש), `hide_back_button`, `skip_purchase_success`; הפניה אחרי הצלחה לדף שלנו ("Redirect to a custom success page", RevenueCat מוסיף `app_user_id`) — [Web Purchase Links](https://www.revenuecat.com/docs/web/web-billing/web-purchase-links). ה-ID ב-path ולא ב-query (`?app_user_id=` מחזיר 404 — [קהילה](https://community.revenuecat.com/general-questions-7/issue-with-app-user-id-query-parameter-causing-404-error-in-web-purchase-link-6906)). לכל link יש URL Production ו-URL Sandbox.
- הגדרות Paddle שנדרשות (מתוך מדריך RevenueCat): API key **שלא פג** עם ההרשאות שברשימה (כולל **Customer portal sessions: Write** — בלעדיו "RevenueCat can't generate the URLs customers need to manage or cancel"), **Website approval ל-`pay.rev.cat`** (production דורש אישור Paddle), Default payment link = `https://pay.rev.cat` אם אין, **לכבות abandoned-cart emails** ("The link in these emails can't reopen a checkout started by RevenueCat"), מעקב רכישות אוטומטי (webhooks) — RevenueCat מגדיר לבד את יעד ההתראות ב-Paddle (ההרשאה Notification settings: Read and Write). Webhook simulator של Paddle **לא נתמך** — בודקים עם רכישות sandbox אמיתיות.
- מוצרים: כל Paddle **Price** = מוצר אחד ב-RevenueCat (ייבוא: Product catalog → Products → Import); רכישה = מוצר אחד; אין שני מנויים פעילים לאותו מוצר — [Paddle app-to-web](https://www.revenuecat.com/docs/web/guides/paddle-app-to-web).
- Webhook של RevenueCat: `store` כולל `PADDLE` (וגם `RC_BILLING`, `STRIPE`); החזר = `CANCELLATION` עם `cancel_reason: CUSTOMER_SUPPORT` ומחיר שלילי; אין אירוע REFUND נפרד — [Event types and fields](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields).
- ניהול/ביטול: REST v2 `GET /projects/{project_id}/subscriptions/{id}/authenticated_management_url` → ל-Paddle "a short-lived authenticated Paddle Customer Portal URL"; `GET /projects/{project_id}/customers/{id}/subscriptions` (שדות `store`, `gives_access`, `auto_renewal_status`, `store_subscription_identifier`, `management_url`). **ה-cancel/refund של RevenueCat הם ל-RevenueCat Billing בלבד** ("Cancel an active Web Billing subscription") — לכן מחיקת חשבון מבטלת את מנוי ה-Paddle ישירות ב-API של Paddle (`POST /subscriptions/{sub_…}/cancel`) — [Subscription API](https://www.revenuecat.com/docs/api-v2/subscription), [Data model](https://www.revenuecat.com/docs/api-v2/subscription-data-model).
- **לא אומת במסמכים:** ש-`store_subscription_identifier` של מנוי Paddle הוא ה-`sub_…` של Paddle (הקוד מבטל רק כשהוא מתחיל ב-`sub_`, אחרת רושם אזהרה); מה בדיוק ה-`product_id` בוובהוק (מניחים את ה-`pri_…` המיובא — המיפוי ב-`productId` במחירון מכסה כל ערך); ודיווח בקהילה על link של Paddle ששייך רכישה ל-anonymous ([7088](https://community.revenuecat.com/third-party-integrations-53/paddle-web-purchase-link-not-assigning-purchase-to-correct-app-user-id-7088), לא נפתר שם) — **לבדוק ב-sandbox שה-uid מגיע** (`purchase_events.appUserId`).

**Paddle Billing** (מסמכי ה-API שעדיין בשימוש)
- ביטול: `POST /subscriptions/{id}/cancel` עם `effective_from` — [Cancel](https://developer.paddle.com/build/subscriptions/cancel-subscriptions). מפתח `pdl_sdbx_…` = sandbox (נקבע אוטומטית).
- ILS במטבעות הנתמכים — [Supported currencies](https://developer.paddle.com/concepts/sell/supported-currencies).

**זהות המשתמש באפליקציה (נבדק):** `lib/core/monetization/purchases_service.dart` — `Purchases.configure(PurchasesConfiguration(key)..appUserID = uid)` ו-`Purchases.logIn(uid)` עם ה-Firebase uid; `logOut` ביציאה. ה-uid שה-Link נושא הוא אותו App User ID — רכישה באתר מופיעה באפליקציה גם דרך ה-SDK (CustomerInfo) וגם דרך `entitlements/{uid}`. אין צורך במיגרציה.

## איך זה בנוי

| קובץ | מה |
|---|---|
| `functions/billingCatalog.js` | ניתוב (`+972` → `payplus`, אחרת `revenuecat`; אורח לפי שפה; מנהל יכול לכפות `provider`), מתגים, מחירון `web_billing_catalog`, `purchaseUrl()` |
| `functions/payplusClient.js` | REST דק + אימות חתימה; `"-"` = לא מוגדר |
| `functions/revenueCatClient.js` | REST v2 של RevenueCat: מנויי לקוח, management URL מאומת |
| `functions/paddleClient.js` | רק `cancelSubscription` (מחיקת חשבון) + אימות חתימה ל-`paddleWebhook.js` הפרוש |
| `functions/webBilling.js` | `plans` / `checkout` / `manage` / `status` (`portal` = שם ישן של manage) |
| `functions/payplusWebhook.js` | אימות → מיפוי → `webEntitlement.apply` |
| `functions/revenueCatWebhook.js` | כל אירועי RevenueCat, כולל store `PADDLE`: מיפוי `product_id` (pri_…) → מזהה החבילה שלנו (טייר duo/family), `cancelAtPeriodEnd`, החזר = כיבוי מיד, store-aware מול מקורות אחרים |
| `functions/paddleWebhook.js` | **פרוש, לא מיוצא** — לעיון בלבד |
| `functions/deleteAccount.js` | `deleteWebCustomer`: PayPlus (DeleteRecurring), Paddle-דרך-RevenueCat (RevenueCat מוצא `sub_…`, Paddle מבטל), Paddle ישיר ישן |
| `webapp/src/lib/webBillingFlows.tsx` | `useCheckout` (שני הספקים → הפניה לדף מתארח), `useManage` (RevenueCat → פורטל Paddle; PayPlus → AppDialog אישור ביטול) |

**Checkout**
- PayPlus: ללא שינוי — `generateLink` עם `charge_method: 3`, `recurring_settings`, `more_info = uid`, `more_info_1 = planId`, `refURL_callback = payplusWebhook`, תוקף 30 דק׳, סימון נגד checkout כפול (`checkoutPendingUntil`).
- RevenueCat: `checkout` בודק זכאות (מנוי חי באתר/בחנות/במשק בית/מתנת מנהל → 409) ומחזיר
  `https://pay.rev.cat/<token>/<encodeURIComponent(uid)>?package_id=<packageId>&email=<email>` — ה-uid מה-ID token בלבד.
  אין סימון pending (שום דבר לא נוצר עד התשלום; RevenueCat עצמו חוסם מנוי כפול לאותו מוצר).
  האתר מפנה רק ל-`https://pay.rev.cat/…` (allow-list בשרת ובדפדפן). אחרי תשלום RevenueCat מפנה ל-`/app/checkout/success?provider=revenuecat`,
  והדף מחכה ש-`entitlements/{uid}` יתהפך (webhook של RevenueCat).

**מיפוי ל-entitlement** — PayPlus כמו קודם (`source: payplus`). RevenueCat/Paddle (`source: revenuecat`, `store: PADDLE`):

| אירוע RevenueCat | תוצאה |
|---|---|
| INITIAL_PURCHASE / RENEWAL / PRODUCT_CHANGE / UNCANCELLATION | פרימיום עד `expiration_at_ms`; `productId` = מזהה החבילה מהמחירון (`storeProductId` = pri_…); `cancelAtPeriodEnd: false` |
| CANCELLATION (auto-renew כבוי) | פרימיום נשאר עד הסוף; `cancelAtPeriodEnd: true` |
| CANCELLATION + `CUSTOMER_SUPPORT` + מחיר שלילי (החזר) | כבוי מיד |
| EXPIRATION | כבוי — **אלא אם** מקור אחר חי (PayPlus, משק בית, מנהל) **או חנות אחרת** של RevenueCat חיה (APP_STORE מול PADDLE) |
| BILLING_ISSUE | פרימיום נשאר עד `expiration_at_ms` (תקופת החסד של RevenueCat) |
| TRANSFER | כמו קודם |

**ניהול** — RevenueCat/Paddle: `manage` → REST v2 (מנוי `store: paddle`, עדיף `gives_access`) → `authenticated_management_url` (או `management_url`) → הפניה לפורטל של Paddle (allow-list `*.paddle.com` / `*.revenuecat.com` / `rev.cat`).
באפליקציה: `EntitlementService.fromWeb` נכון גם ל-`revenuecat` + `PADDLE`/`RC_BILLING`/`STRIPE`, אז "ניהול" בפייוול פותח את האתר (לא את ה-Customer Center).
**מחיקת חשבון** — אם ה-entitlement או שורה ב-`purchase_events` אומרים `PADDLE`: RevenueCat מחזיר את המנויים, כל מנוי Paddle שעוד מתחדש מבוטל מיד ב-Paddle; כשל עוצר את המחיקה; מפתחות חסרים → דילוג עם אזהרה.

**מתגים** — `ff_web_checkout` (ראשי) **וגם** `ff_web_checkout_il` (PayPlus) / `ff_web_checkout_intl` (RevenueCat/Paddle). ספק מוכר רק כששניהם ≥ 2; מנהל עוקף.

**Apple Pay domain file** (`landing/.well-known/apple-developer-merchantid-domain-association`) — לא בשימוש במסלול החדש (הקופה על `pay.rev.cat`); נשאר כי לא מזיק ויחזור לשימוש אם הקופה תעבור לדומיין שלנו (Web SDK). **לא** לאשר אותו ב-Paddle.
**CSP** — כל הדומיינים של Paddle (cdn/sandbox-cdn/buy/profitwell/*.paddle.com) הוסרו מ-`/app`; הפניה (navigation) לא כפופה ל-CSP.

## מה קובי צריך לעשות

### 1. PayPlus
1. לפתוח חשבון: https://www.payplus.co.il/signup (נציג חוזר; מסוף אשראי אצל חברת האשראי).
2. לבקש **מודול הוראות קבע** (Recurring Payments) ומסוף שתומך ביצירת הוראות קבע מדף הסליקה.
3. להפעיל **Apple Pay** ו-**Google Pay** (Settings → Alternative Payment Methods / דרך התמיכה) ולוודא איתם שהם עובדים **על דף עם הוראת קבע** (`charge_method 3`). bit — לא למנוי.
4. ליצור **דף תשלום** (Payment Page) ולהגדיר בו: הפניה אחרי תשלום ב-**GET** (לא POST — האתר סטטי), שפה עברית.
5. **Callback URL של החשבון** (לחידושים): `https://europe-west1-easy-plate.cloudfunctions.net/payplusWebhook`
6. להעתיק: API Key, Secret Key, Terminal UID, Payment Page UID (מדריך: "העתקת הפרמטרים API Key/Secret Key/Page UID/Terminal UID" במרכז הידע של PayPlus).
7. אופציונלי: מודול חשבוניות (חשבונית לכל חיוב — `successful_invoice: true` כבר נשלח).

### 2. Paddle + RevenueCat (חו״ל)
**Paddle** (קודם Sandbox: https://sandbox-vendors.paddle.com, אחר כך live https://vendors.paddle.com):
1. לפתוח חשבון, להפעיל **Paddle Billing** (לא Classic).
2. **Checkout → Website approval**: להוסיף **`pay.rev.cat`** (ב-live — להמתין לאישור Paddle). אם אין Default payment link — `https://pay.rev.cat`.
3. **Checkout settings → לכבות abandoned cart / checkout recovery emails.**
4. **Catalog → Products/Prices**: מוצר "EasyPlate Premium" עם מחיר חודשי/שנתי לכל טייר (Pro / Duo / Family). לרשום כל `pri_…`.
5. **Developer tools → Authentication → API key** בשביל RevenueCat: **Expiry: never**, הרשאות לפי המדריך של RevenueCat (Read+Write: Client-side tokens, Notification settings, Transactions; Write: **Customer portal sessions**; Read: Addresses, Adjustments, Businesses, Customers, Discounts, Notifications, Payment methods, Prices, Products, Subscriptions). להדביק ישר ב-RevenueCat (אי אפשר להעתיק אחר כך).
6. **API key שני בשבילנו** (`PADDLE_API_KEY`) — רק Subscriptions: Write (ביטול במחיקת חשבון).
7. **לא** ליצור Notification destination ידני ל-`paddleWebhook` — RevenueCat מגדיר את שלו. אם נוצר בעבר יעד ל-`…/paddleWebhook` — למחוק אותו.

**RevenueCat** (app.revenuecat.com, אותו פרויקט של האפליקציה):
1. **Apps & providers → + Paddle Billing** (Sandbox קודם): להדביק את ה-API key, Purchase tracking = **automatic (webhooks)**.
2. **Product catalog → Products → Import** מ-Paddle; לחבר כל מוצר ל-entitlement **`easy_plate_ai_pro`**.
3. **Offering** (למשל `web`) עם package לכל מחיר (`$rc_monthly`, `$rc_annual`, או מזהה משלך כמו `duo_monthly`).
4. **Web → Web Purchase Links → New** על ה-offering: Paddle Billing, הצלחה = **Redirect to a custom success page** → `https://aieasyplate.app/app/checkout/success?provider=revenuecat`. להעתיק את ה-URL (Sandbox קודם, אחר כך Production).
5. **Project settings → API keys → + New secret API key (v2)** עם `customer_information:subscriptions:read` (`REVENUECAT_SECRET_KEY`), ולרשום את **Project ID** (`proj…`).
6. ה-webhook הקיים (`revenueCatWebhook`) כבר מקבל את אירועי Paddle — לוודא שהוא לא מסונן לפלטפורמה/סביבה אחת.

### 3. Secrets (`"-"` = לא מוגדר; כל פונקציה עונה 503 `billing_disabled` / מדלגת עם אזהרה)
```bash
firebase functions:secrets:set PAYPLUS_API_KEY --project easy-plate
firebase functions:secrets:set PAYPLUS_SECRET_KEY --project easy-plate
firebase functions:secrets:set PAYPLUS_TERMINAL_UID --project easy-plate
firebase functions:secrets:set PAYPLUS_PAGE_UID --project easy-plate
firebase functions:secrets:set REVENUECAT_SECRET_KEY --project easy-plate   # sk_… (REST v2): פורטל ניהול + מחיקת חשבון
firebase functions:secrets:set PADDLE_API_KEY --project easy-plate          # pdl_sdbx_… / pdl_live_…: רק ביטול במחיקת חשבון
```
`PADDLE_WEBHOOK_SECRET` כבר לא בשימוש (שום פונקציה פרוסה לא קוראת אותו) — אפשר להשאיר או למחוק.

### 4. Remote Config (קונסול האדמין → תצורה, או Firebase)
- `web_billing_catalog` (JSON), לדוגמה:
```json
{"payplus":{"env":"production","plans":[
  {"id":"easy_plate_ai_pro_monthly","interval":"month","amount":2000,"order":1},
  {"id":"easy_plate_ai_pro_yearly","interval":"year","amount":19900,"order":2},
  {"id":"easy_plate_ai_pro_duo_monthly","interval":"month","amount":2900,"order":3},
  {"id":"easy_plate_ai_pro_family_monthly","interval":"month","amount":3900,"order":4}]},
 "revenuecat":{"purchaseLink":"https://pay.rev.cat/<token>","projectId":"proj…","plans":[
  {"id":"easy_plate_ai_pro_monthly","productId":"pri_…","packageId":"$rc_monthly","interval":"month","amount":599,"currency":"USD","order":1},
  {"id":"easy_plate_ai_pro_family_yearly","productId":"pri_…","packageId":"family_yearly","interval":"year","amount":9900,"currency":"USD","order":2}]}}
```
  `id` = מה שנשמר כ-`productId` ב-entitlement (חייב להכיל duo/family לפי הטייר); `productId` = מזהה המוצר ב-RevenueCat (ה-`pri_…` המיובא) — כך הוובהוק מתרגם בחזרה; `packageId` = מזהה ה-package ב-offering;
  `amount`/`currency` לתצוגה בלבד — **המחיר שנגבה הוא של Paddle**, לשמור אותם זהים. `purchaseLink` בלי `/` בסוף (Sandbox או Production).
- `ff_web_checkout` = 2, `ff_web_checkout_il` = 2, `ff_web_checkout_intl` = 2 כשמוכנים (ברירת מחדל 0).

### 5. Deploy
פורס (2026-10-18) — functions (בלי `paddleWebhook`, שנמחק מהפרויקט), firestore:rules, hosting, ו-Remote Config (`web_billing_catalog` עם מקטע `revenuecat`).

### 6. בדיקה
- PayPlus staging: `env: "staging"` במחירון + מפתחות staging; כרטיס `5326-1402-8077-9844` 05/30 000.
- RevenueCat/Paddle sandbox: Paddle sandbox + Paddle Billing (Sandbox) ב-RevenueCat + ה-URL ה-Sandbox של ה-link ב-`purchaseLink`; כרטיס הבדיקה של Paddle `4242 4242 4242 4242`.
  לבדוק: (א) `purchase_events` מקבל שורה עם `store: PADDLE` ו-`appUserId` = ה-uid; (ב) `entitlements/{uid}.productId` הוא מזהה החבילה שלנו; (ג) "ניהול" באתר פותח פורטל Paddle; (ד) ביטול → "מסתיים ב-"; (ה) מחיקת חשבון מבטלת ב-Paddle.
  ה-webhook simulator של Paddle לא נתמך ע״י RevenueCat — רק רכישות sandbox אמיתיות.
- מנהל יכול לבדוק כשהמתגים עוד 0, ולכפות ספק: `webBilling {action:"checkout", provider:"revenuecat", …}`.
