# אינסטגרם של EasyPlate

הכל מנוהל מהקונסולה: **aieasyplate.app/admin ← אינסטגרם**.
ה-API של אינסטגרם חינמי. Claude כותב את הכיתובים ומרכיב את התמונות בעצמו, בלי Gemini ובלי עלות.

## איך זה עובד

1. Claude מכין טיוטה:
   ```
   python3 tools/instagram/compose.py <id>   # posts/<id>/out/NN.jpg
   node tools/instagram/push.mjs <id>        # מעלה ויוצר טיוטה בקונסולה
   ```
2. בקונסולה Koby עורך, מאשר, ואז מפרסם עכשיו או מתזמן לתאריך ושעה.
3. אפשר גם להעלות פוסט משלך: "פוסט חדש" בקונסולה.
4. פוסט שפורסם מציג לייקים, חשיפה, שמירות ותגובות, ואפשר לענות לתגובות או להסתיר אותן.

השרת (`functions/adminInstagram.js`) מפרסם רק פוסט שאושר. כל עריכה מחזירה את הפוסט לטיוטה.
כיתוב שמזכיר מחיר, מנוי, פרימיום, Pro, ניסיון או "חינם" נחסם לפי כלל הקריאייטיב.

ה-runner `runInstagram` רץ כל 5 דקות:
- מפרסם פוסטים מתוזמנים
- מרענן נתונים פעם ביום
- מחדש את הטוקן פעם בשבוע

## חיבור חד-פעמי (רק Koby)

1. פותחים חשבון אינסטגרם ומעבירים אותו לחשבון מקצועי מסוג עסקי. בביו שמים https://aieasyplate.app/he
2. נכנסים ל-https://developers.facebook.com/apps, לוחצים Create App, בוחרים את ה-use case "Manage messaging & content on Instagram" ואת הסוג Business.
3. באפליקציה: Instagram ← API setup with Instagram login ← Generate access tokens ← מוסיפים את החשבון.
   מאשרים את ההרשאות:
   - `instagram_business_basic`
   - `instagram_business_content_publish`
   - `instagram_business_manage_comments`
   - `instagram_business_manage_insights`

   אם מבקשים Instagram Tester: באפליקציה נכנסים ל-App roles ← Roles ← Add Instagram Testers. אחר כך באינסטגרם מאשרים את ההזמנה ב: הגדרות ← אפליקציות ואתרים ← הזמנות לבודקים.
4. מדביקים את הטוקן בקונסולה בדף אינסטגרם. הוא נשמר בשרת בלבד (`admin_config/instagram_private`).

אין צורך ב-App Review, כי זה החשבון שלך ואתה מנהל באפליקציה.
