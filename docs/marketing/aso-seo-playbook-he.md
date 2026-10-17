# איך לקוחות ימצאו את EasyPlate: מדריך צעד-אחר-צעד (עודכן 2026-10-18)

שלושה ערוצי גילוי: App Store, Google Play, וגוגל (האתר aieasyplate.app).
הקובץ הזה הוא רשימת משימות. מה שמסומן ✅ כבר נעשה בקוד ופרוס. מה שמסומן 🔑 רק
קובי יכול לעשות (צריך חשבון/כרטיס אשראי/אימות בעלות).

---

## 0. האמת על "מתכונים" לפני שמתחילים

- **"מתכונים" לבד בגוגל** – העמוד הראשון שייך לאתרי תוכן עם עשרות אלפי מתכונים.
  אפליקציה לא מנצחת שם. היא מנצחת על "אפליקציית מתכונים", "מתכונים AI",
  "מתכונים מטיקטוק", "סריקת קבלות", "רשימת קניות משותפת". זה מה שהאתר מכוון אליו.
- **בחנויות** הדירוג = התאמת מילות מפתח × קצב הורדות × דירוג כוכבים × שימור.
  אפליקציה חדשה בלי הורדות לא תהיה ראשונה על "מתכונים" ביום הראשון, גם עם מטא-דאטה מושלם.
- **להיות ראשון מיד** אפשר רק בתשלום: Apple Search Ads וקמפיין אפליקציות של גוגל (סעיף 6).
- **ציר זמן ריאלי:** זנב ארוך תוך 2–6 שבועות מהגשת ה-sitemap; ביטויי ראש בחנויות
  תוך 2–4 חודשים עם 50+ דירוגים ומאות הורדות; בגוגל ביטויי ראש רק עם קישורים נכנסים.

---

## 1. App Store Connect (iOS) 🔑

כל הטקסטים מוכנים ב-`docs/marketing/store-listing.md`, בדוקים מול המגבלות.

1. היכנס ל-https://appstoreconnect.apple.com → **My Apps** → EasyPlate (id 6809243199).
2. **App Information** (בצד שמאל):
   - **Primary Category:** Food & Drink. **Secondary:** Lifestyle.
   - **Age Rating:** 4+.
3. **Localizations** – בחלק העליון של העמוד בחר **Add Localization** והוסף:
   Hebrew, Arabic, French (France), Russian. אנגלית (U.S.) היא ה-Primary.
   כל שפה היא דף נפרד. **בלי לוקליזציית עברית לא מדורגים בישראל על שאילתות בעברית.**
4. לכל שפה, ב-**App Store** → הגרסה הנוכחית:
   - **Name** (30 תווים) – מהקובץ. השם הוא שדה החיפוש החזק ביותר.
   - **Subtitle** (30) – מהקובץ. השדה השני בחשיבותו.
   - **Keywords** (100 תווים, פסיקים **בלי רווחים**) – מהקובץ. לא לחזור על מילים שכבר בשם/בכותרת המשנה, אפל כבר מאנדקסת אותן.
   - **Promotional Text** (170) – מהקובץ. ניתן לשנות בלי גרסה חדשה.
   - **Description** (4000) – מהקובץ. לא מאונדקס לחיפוש, אבל קובע המרה.
   - **Support URL:** https://aieasyplate.app/he (או השפה). **Marketing URL:** https://aieasyplate.app.
   - **Privacy Policy URL:** https://aieasyplate.app/he/privacy.
5. **Screenshots** – לכל שפה לפחות 3 צילומי 6.7" (1290×2796). הקבצים ב-`store/screenshots/` (ראה `easyplate-store-screenshots`).
   הטקסט על הצילומים חייב להיות בשפת הלוקליזציה. חובה לפי החוקים: בלי מחירים ובלי מסכי תשלום.
6. **App Preview** (וידאו 15–30 שניות) – אופציונלי. אם יש, להעלות את גרסת 30 השניות מה-TikTok ad בלי הקריינות המשוערת.
7. **Save** → **Add for Review** → **Submit**. שינוי מילות מפתח דורש גרסה חדשה (אפשר Build זהה עם מספר build חדש).
8. אחרי האישור: ב-**App Store Connect → App Analytics → Acquisition → Sources** תראה "App Store Search" ומאיזה ביטויים.
9. **Ratings:** באפליקציה כבר קיים (✅) חלון הדירוג המובנה של אפל אחרי המתכון השני שנשמר (דגל `ff_store_review` בקונסול). אל תבקש דירוג במסך אחר – אפל אוסרת.

---

## 2. Google Play Console (Android) 🔑

1. https://play.google.com/console → EasyPlate (`com.KHEasyDev.easy_plate`).
2. **Grow → Store presence → Main store listing**.
3. **Default language:** English (United States). למעלה **Manage translations → Add your own translation texts** → הוסף: Hebrew, Arabic, French, Russian.
4. לכל שפה:
   - **App name** (30) – מהקובץ.
   - **Short description** (80) – מהקובץ. מוצג מעל הקפל, מאונדקס.
   - **Full description** (4000) – מהקובץ. **כולו מאונדקס**; המילים המרכזיות (מתכונים, רשימת קניות, תפריט, קבלה, AI) מופיעות בו 3–5 פעמים כל אחת, בכוונה. לא להוסיף מילות מפתח כרשימה – גוגל מענישה.
   - **App icon** 512×512, **Feature graphic** 1024×500 (חובה; בלי טקסט מחירים).
   - **Phone screenshots** לפחות 4, 1080×1920 ומעלה, בשפת הלוקליזציה.
5. **Store settings → App category:** Food & Drink. **Tags** (עד 5): Recipes, Meal planning, Shopping lists, Cooking, Productivity.
6. **Store presence → Custom store listings** – צור listing ל-**Israel** בעברית עם ה-Short description הישראלי:
   "מתכונים מטיקטוק, תפריט שבועי, רשימת קניות וסריקת קבלות מהסופר." (זה מתגבר על הכללי למשתמשים בישראל).
7. **Store presence → Store listing experiments** – אחרי 2 שבועות הרץ ניסוי A/B על האייקון ועל הצילום הראשון. גוגל בוחרת אוטומטית את המנצח.
8. **Monitor and improve → Ratings and reviews:** ענה לכל ביקורת תוך 48 שעות; תגובת מפתח מעלה דירוג ממוצע מוכח.
9. **Policy → App content:** ודא ש-**Data safety** תואם למדיניות הפרטיות (קבלות = תמונות, מיקרופון לשפי, קישורים חברתיים).
10. **Android vitals:** קריסות מעל 1.09% וANR מעל 0.47% מורידים מהחיפוש. לבדוק שבועית.

---

## 3. גוגל: Search Console + Bing 🔑 (הצעד הכי חשוב שעוד לא נעשה)

בלי זה גוגל לא מקבל את ה-sitemap (90 כתובות) ואין נתוני שאילתות.

1. https://search.google.com/search-console → **Add property** → **Domain** → `aieasyplate.app`.
2. גוגל נותן רשומת **TXT** (`google-site-verification=…`). הוסף אותה ב-DNS של הדומיין (איפה שקנית את aieasyplate.app → DNS → Add record → Type TXT, Host `@`, Value = מה שגוגל נתן). חכה 5–30 דקות → **Verify**.
   - חלופה: שלח לי את המחרוזת ואוסיף `<meta name="google-site-verification">` לתבנית ואפרוס.
3. ב-Search Console: **Sitemaps** → הזן `sitemap.xml` → **Submit**.
4. **URL Inspection** → הדבק `https://aieasyplate.app/he` → **Request indexing**. חזור על זה ל-`/he/recipe-app`, `/he/recipe-search`, `/he/ai-recipes`, `/he/receipt-scanner`, `/he/grocery-list-app`, `/he/save-tiktok-recipes` (מכסה יומית ~10).
5. **Settings → International targeting** אין יותר; ה-hreflang כבר בכל עמוד (✅).
6. אחרי 7 ימים: **Performance → Search results** → פילטר **Country: Israel** → רשימת השאילתות האמיתיות. את הביטויים שמופיעים במקום 8–20 נחזק בעמודים (שלח לי את הרשימה).
7. **Bing Webmaster Tools** https://www.bing.com/webmasters → **Import from Google Search Console** (לחיצה אחת, מייבא אימות ו-sitemap). Bing מזין גם את DuckDuckGo ואת חיפוש ChatGPT.
8. **Google Business Profile** לא רלוונטי (אין כתובת פיזית).

---

## 4. קישורים נכנסים (backlinks) 🔑 – בלי זה האתר לא עולה על ביטויי ראש

לפי סדר קלות:
1. **דפי החנות עצמם** – ודא שב-App Store "Marketing URL" וב-Play "Website" מצביעים ל-https://aieasyplate.app. שני הקישורים הכי חזקים שיש.
2. **פרופילים חברתיים** – TikTok, Instagram, Facebook Page, YouTube, LinkedIn של KH Easy Dev, X. בכל ביו: הקישור + "אפליקציית מתכונים AI".
3. **Product Hunt** – השקה אחת (יום שלישי, 00:01 PST). עמוד ProductHunt מדורג מצוין בגוגל על "<שם> app".
4. **AlternativeTo, Slant, G2, Capterra** – הגשה חינמית תחת Paprika / Whisk / AnyList alternatives.
5. **קבוצות פייסבוק ישראליות** – "מתכונים", "אמהות מבשלות", "חיסכון בסופר": פוסט על **סריקת קבלות** (לא על האפליקציה בכלל) עם קישור ל-`/he/receipt-scanner`.
6. **בלוגי אוכל ישראליים** – 5 מיילים לבלוגרים בינוניים: הצעה "תוסיפי כפתור 'שמור ב-EasyPlate' למתכונים שלך" או כתבה "איך אני שומרת מתכונים מטיקטוק".
7. **Reddit** r/MealPrepSunday, r/Cooking, r/israel – תשובות אמיתיות לשאלות "how do you save TikTok recipes", עם קישור ל-`/save-tiktok-recipes`.
8. **ynet / וואלה אוכל / Geektime** – הודעה לעיתונות קצרה על "סריקת קבלות עם AI בעברית" – זווית הצרכנות מעניינת עיתונאים יותר מ"עוד אפליקציית מתכונים".

---

## 5. התוכן באתר – מה כבר יש ומה הלאה

✅ 15 עמודי מדריך × 5 שפות (90 כתובות ב-sitemap), כולל השלושה החדשים:
- `/he/recipe-search` – "חיפוש מתכונים"
- `/he/ai-recipes` – "מתכונים AI"
- `/he/receipt-scanner` – "סריקת קבלות"

הצעד הבא בתוכן (אחרי שיש נתונים מ-Search Console):
- עמודי "מתכון מ-X": `/he/save-youtube-recipes`, `/he/save-facebook-recipes`.
- עמוד השוואה: "EasyPlate לעומת Paprika / AnyList / Whisk" – ביטויי השוואה ממירים הכי טוב.
- בלוג קצר בעברית, פוסט בשבועיים: "תפריט שבועי משפחתי ב-200 ₪", "10 מתכונים מטיקטוק ששווה לשמור" – כל פוסט מקשר לעמוד מדריך.
- `aggregateRating` ב-JSON-LD ברגע שיש 5+ דירוגים ב-App Store (אני אוסיף; עד אז אסור להמציא).

---

## 6. תשלום כדי להיות ראשון מיד 🔑

### Apple Search Ads (iOS, ישראל + ארה"ב)
1. https://searchads.apple.com → **Advanced** → קמפיין חדש → Country: Israel.
2. **Ad group 1 – Brand/Exact:** מילים מדויקות: `מתכונים`, `אפליקציית מתכונים`, `רשימת קניות`, `תפריט שבועי`, `recipe app`, `grocery list`. Match type **Exact**. הצעה: 1.5–3 ₪ לטאפ.
3. **Ad group 2 – Search Match** (אפל בוחרת): תקציב 20 ₪/יום לשבועיים, ואז העבר את הביטויים שהמירו ל-Exact.
4. **Negative keywords:** free games, diet pills, delivery.
5. **Conversion:** חבר ל-Firebase (SKAN כבר מוגדר ✅) ומדוד `onboarding_complete` ו-`recipe_saved`.
6. תקציב התחלתי מומלץ: 50 ₪/יום × 30 יום. עצור ביטויים עם CPI מעל 12 ₪.

### Google Ads – App Campaign (Android + iOS)
1. https://ads.google.com → **New campaign** → **App promotion** → **App installs** → בחר EasyPlate Android.
2. **Locations:** Israel. **Languages:** Hebrew, English, Arabic, Russian.
3. **Assets:** 5 כותרות (עד 30 תווים) ו-5 תיאורים (עד 90) מהקובץ store-listing; 4 תמונות (1200×628, 1200×1200), 2 סרטונים (ה-TikTok ad). **בלי מחירים.**
4. **Conversions:** Firebase → `onboarding_complete` (primary), `recipe_saved`, `grocery_list_created` (secondary).
5. **Bid:** Target CPI 8 ₪. **Budget:** 60 ₪/יום. גוגל לומדת 7–10 ימים; לא לגעת לפני.
6. הקמפיין מריץ גם ב-Google Search על "אפליקציית מתכונים", ב-Play Store search, ב-YouTube וב-Discover – זה הדרך היחידה להיות "ראשון" ב-Play על ביטוי כללי מהיום הראשון.

### TikTok Ads (ישראל)
- Spark Ads על הסרטון הקיים, יעד App Install, 40 ₪/יום. ה-SKAN id של TikTok כבר ב-Info.plist ✅.

---

## 7. מה כבר קיים בקוד (לא צריך לעשות כלום)

- ✅ 90 כתובות ב-sitemap עם hreflang, JSON-LD (Article/HowTo/FAQ/Breadcrumb), OG images, robots.txt, 404, clean URLs.
- ✅ כותרות ≤60, תיאורים ≤155, מילת המפתח ראשונה, המותג אחרון.
- ✅ דגל `ff_store_review` + בקשת דירוג מובנית אחרי המתכון השני (מקסימום 3 פעמים, כל 120 יום). לכיבוי: קונסול → תצורה → "בקשת דירוג בחנות" → 0.
- ✅ Firebase Analytics conversions, ATT, SKAN (Apple + TikTok), AD_ID.
- ✅ טקסטי חנות ב-5 שפות בדוקים מול המגבלות: `docs/marketing/store-listing.md` (`node docs/marketing/check-listing.mjs`).

---

## 8. מעקב שבועי (10 דקות)

| מה | איפה | סימן אזהרה |
|---|---|---|
| ביטויי חיפוש בישראל | Search Console → Performance → Country IL | ירידה בהקלקות שבוע על שבוע |
| מקור הורדות iOS | App Store Connect → Analytics → Sources | "App Store Search" מתחת ל-40% |
| מילות מפתח iOS | App Store Connect → Analytics → Metrics → Search terms | ביטוי חדש = להוסיף ל-Keywords |
| Play: Store listing conversion | Play Console → Store performance | מתחת ל-25% = להחליף צילום ראשון |
| דירוגים | שתי החנויות | ביקורת בלי תגובה מעל 48 שעות |
| Vitals | Play Console → Android vitals | קריסות מעל 1.09% |
