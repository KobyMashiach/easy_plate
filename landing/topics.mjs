// Keyword-targeted guide pages, one per topic per language.
//
//   /recipe-app/            /he/recipe-app/   /ar/… /fr/… /ru/…
//   /grocery-list-app/
//   /meal-planner/
//   /save-tiktok-recipes/
//
// Each page is a long-form answer to one search intent ("אפליקציית מתכונים",
// "shared grocery list app", "weekly meal planner", "how to save a TikTok
// recipe"). build.mjs renders them with the home page's styles, hreflang
// across the five languages, breadcrumbs, HowTo and FAQ structured data.
// Edit copy here, then `npm run build`. Everything stated must be true of the
// app: no invented numbers, ratings or testimonials.

import { MORE_TOPICS } from './topics_more.mjs';
import { MORE_TOPICS_2 } from './topics_more2.mjs';
import { MORE_TOPICS_3 } from './topics_more3.mjs';

export const SLUGS = [
  'recipe-app', 'grocery-list-app', 'meal-planner', 'save-tiktok-recipes',
  'save-instagram-recipes', 'recipe-calorie-calculator', 'grocery-prices-receipt-scanner',
  'family-cookbook', 'cook-mode-timers', 'recipe-from-pdf-or-voice', 'weekly-family-meal-plan',
  'ai-cooking-assistant',
];

// Labels shared by every guide page.
export const UI = {
  en: { home: 'Home', guides: 'Guides', download: 'Get the app', free: 'Free to start. No credit card needed.', how: 'How it works', faq: 'Frequently asked questions', more: 'More guides', back: 'EasyPlate home', features: 'Features', pricing: 'Pricing', privacy: 'Privacy Policy', terms: 'Terms of Service', support: 'Support', appStoreTop: 'Download on the', appStore: 'App Store', playTop: 'GET IT ON', play: 'Google Play', copyright: '© 2026 EasyPlate. All rights reserved.', readingTime: 'min read' },
  he: { home: 'דף הבית', guides: 'מדריכים', download: 'להורדת האפליקציה', free: 'חינם להתחלה. בלי כרטיס אשראי.', how: 'איך זה עובד', faq: 'שאלות נפוצות', more: 'מדריכים נוספים', back: 'EasyPlate דף הבית', features: 'יכולות', pricing: 'מחירים', privacy: 'מדיניות פרטיות', terms: 'תנאי שימוש', support: 'תמיכה', appStoreTop: 'הורידו מ-', appStore: 'App Store', playTop: 'זמין ב-', play: 'Google Play', copyright: '© 2026 EasyPlate. כל הזכויות שמורות.', readingTime: 'דקות קריאה' },
  ar: { home: 'الرئيسية', guides: 'أدلة', download: 'حمّل التطبيق', free: 'مجاني للبدء. بلا بطاقة ائتمان.', how: 'كيف يعمل', faq: 'الأسئلة الشائعة', more: 'أدلة أخرى', back: 'الصفحة الرئيسية EasyPlate', features: 'الميزات', pricing: 'الأسعار', privacy: 'سياسة الخصوصية', terms: 'شروط الخدمة', support: 'الدعم', appStoreTop: 'حمّله من', appStore: 'App Store', playTop: 'احصل عليه من', play: 'Google Play', copyright: '© 2026 EasyPlate. جميع الحقوق محفوظة.', readingTime: 'دقائق قراءة' },
  fr: { home: 'Accueil', guides: 'Guides', download: 'Télécharger l’app', free: 'Gratuit pour commencer. Sans carte bancaire.', how: 'Comment ça marche', faq: 'Questions fréquentes', more: 'Autres guides', back: 'Accueil EasyPlate', features: 'Fonctionnalités', pricing: 'Tarifs', privacy: 'Politique de confidentialité', terms: 'Conditions d’utilisation', support: 'Support', appStoreTop: 'Télécharger dans l’', appStore: 'App Store', playTop: 'DISPONIBLE SUR', play: 'Google Play', copyright: '© 2026 EasyPlate. Tous droits réservés.', readingTime: 'min de lecture' },
  ru: { home: 'Главная', guides: 'Гиды', download: 'Скачать приложение', free: 'Бесплатно для начала. Без банковской карты.', how: 'Как это работает', faq: 'Частые вопросы', more: 'Другие гиды', back: 'EasyPlate главная', features: 'Возможности', pricing: 'Цены', privacy: 'Политика конфиденциальности', terms: 'Условия использования', support: 'Поддержка', appStoreTop: 'Загрузите в', appStore: 'App Store', playTop: 'ДОСТУПНО В', play: 'Google Play', copyright: '© 2026 EasyPlate. Все права защищены.', readingTime: 'мин чтения' },
};

const BASE_TOPICS = {
  // ------------------------------------------------------------------ A
  'recipe-app': {
    icon: 'book-open', screens: ['01_recipes', '02_recipe_details'],
    en: {
      title: 'Recipe App with AI: Save, Organize, Cook | EasyPlate',
      description: 'Save recipes from TikTok, Instagram, YouTube, websites, PDFs and voice notes into one cookbook with nutrition per serving, a weekly plan and a grocery list.',
      keywords: 'recipe app, recipe organizer app, recipe keeper, digital cookbook, save recipes app, recipe manager, AI recipe app, recipe app with nutrition, family cookbook app',
      h1: 'The recipe app that keeps every recipe you ever liked',
      intro: [
        'Recipes live everywhere now: a reel you liked, a screenshot in your camera roll, a blog with twelve paragraphs before the ingredients, a note from your mother. EasyPlate is a recipe app built to collect all of them into one tidy, searchable cookbook, with the same clean format for each: ingredients with amounts, numbered steps, servings, tags and estimated nutrition per serving.',
        'Instead of typing, you paste or share. The AI reads the video, page, text, PDF or voice note and returns a recipe you can edit. From there every recipe can go onto the weekly plan, into a shared book with your family, and onto the grocery list.',
      ],
      sections: [
        { h2: 'Save a recipe from anywhere', p: 'EasyPlate accepts eight kinds of input, and all of them end as the same structured recipe:', bullets: ['A link from TikTok, Instagram, YouTube, Facebook or any recipe website.', 'Pasted text, for example a WhatsApp message or a caption.', 'A web search by dish name: EasyPlate finds a recipe and brings it back structured.', 'A request in your own words ("a lentil soup for four, no onions").', 'A voice note, transcribed and turned into a recipe.', 'A PDF file, read as a whole document.'] },
        { h2: 'Organize recipes into cookbooks', p: 'Recipes are grouped into books you name yourself: weeknight dinners, holiday menus, the kids’ favourites. Books have a two-page spread you flip through, a cover photo, and tags and search across everything. A book can be shared with another account as a viewer or an editor, and edits reach everyone in real time.', bullets: ['Tags, servings, cooking time and allergens on every recipe.', 'Full-text search across your whole library.', 'Shared family cookbooks with live editing.', 'Offline-first: everything you saved opens without a connection.'] },
        { h2: 'Cook with your hands free', p: 'Cook Mode turns a recipe into large, step-by-step screens with the ingredient amounts right where you need them and timers that keep running in the background. Nutrition per serving is estimated for every recipe and summed into a weekly dashboard, so planning healthier meals does not require a second app.', bullets: ['Step-by-step cook mode with background timers.', 'Calories, protein, carbs and fat per serving.', 'Scale servings and the amounts follow.', 'Five languages, including full right-to-left layouts in Hebrew and Arabic.'] },
      ],
      steps: [
        { t: 'Share or paste', d: 'Found a recipe? Use the share button in TikTok, Instagram or your browser and pick EasyPlate, or paste the link, text or file into the search line.' },
        { t: 'Review the recipe', d: 'The AI returns ingredients, amounts, steps, servings, tags and nutrition in seconds. Edit anything, then save it into a book.' },
        { t: 'Plan, shop, cook', d: 'Drop the recipe on a day of the week. The grocery list builds itself, grouped by aisle, and Cook Mode walks you through the steps.' },
      ],
      faq: [
        { q: 'Is EasyPlate free?', a: 'Yes. A free account includes unlimited manual recipes and books, the weekly plan and the grocery list, plus a daily allowance of AI extractions. EasyPlate Pro removes the limit and the ads for ₪20 a month, billed through the App Store or Google Play.' },
        { q: 'Which recipe sources are supported?', a: 'TikTok, Instagram, YouTube, Facebook, any recipe website, pasted text, web search by dish name, written requests, voice notes and PDF files.' },
        { q: 'Can I edit a recipe after the AI extracts it?', a: 'Everything is editable: ingredients, amounts, steps, servings, tags, photo and nutrition. The AI output is a starting point, not a lock.' },
        { q: 'Does it work in Hebrew?', a: 'Yes. EasyPlate runs in Hebrew, Arabic, English, French and Russian with right-to-left layouts, and switching the language also translates your saved recipes, books, plans and lists.' },
        { q: 'Can my family use the same recipes?', a: 'Share a single recipe, a whole book or a weekly plan with another account as a viewer or an editor. Changes sync to everyone in real time.' },
      ],
      cta: { title: 'Your recipes, finally in one place.', sub: 'Download EasyPlate and save the next recipe you see.' },
    },
    he: {
      title: 'אפליקציית מתכונים בעברית עם AI | EasyPlate',
      description: 'שומרים מתכונים מטיקטוק, אינסטגרם, יוטיוב, אתרים, PDF והקלטות לספר מתכונים אחד עם ערכים תזונתיים, תפריט שבועי ורשימת קניות. חינם.',
      keywords: 'אפליקציית מתכונים, אפליקציית מתכונים בעברית, אפליקציה לשמירת מתכונים, ספר מתכונים דיגיטלי, ניהול מתכונים, אפליקציית מתכונים עם ערכים תזונתיים, ספר מתכונים משפחתי, אפליקציה לבישול',
      h1: 'אפליקציית המתכונים ששומרת כל מתכון שאהבתם',
      intro: [
        'מתכונים היום נמצאים בכל מקום: ריל שאהבתם, צילום מסך בגלריה, בלוג עם שתים-עשרה פסקאות לפני רשימת המצרכים, פתק מאמא. EasyPlate היא אפליקציית מתכונים בעברית שנבנתה כדי לאסוף את כולם לספר מתכונים אחד מסודר וניתן לחיפוש, באותו פורמט נקי לכל מתכון: מצרכים עם כמויות, שלבים ממוספרים, מספר מנות, תגיות וערכים תזונתיים משוערים למנה.',
        'במקום להקליד, מדביקים או משתפים. ה-AI קורא את הסרטון, העמוד, הטקסט, ה-PDF או ההקלטה ומחזיר מתכון שאפשר לערוך. משם כל מתכון יכול לעלות לתפריט השבועי, להיכנס לספר משותף עם המשפחה ולהגיע לרשימת הקניות.',
      ],
      sections: [
        { h2: 'שומרים מתכון מכל מקום', p: 'EasyPlate מקבלת שמונה סוגי קלט, וכולם מסתיימים באותו מתכון מובנה:', bullets: ['קישור מטיקטוק, אינסטגרם, יוטיוב, פייסבוק או כל אתר מתכונים.', 'טקסט מודבק, למשל הודעת וואטסאפ או כיתוב של פוסט.', 'חיפוש ברשת לפי שם המנה: EasyPlate מוצאת מתכון ומחזירה אותו מסודר.', 'בקשה במילים שלכם ("מרק עדשים לארבעה, בלי בצל").', 'הקלטה קולית שמתומללת והופכת למתכון.', 'קובץ PDF, שנקרא כמסמך שלם.'] },
        { h2: 'מסדרים מתכונים בספרים', p: 'המתכונים מקובצים לספרים שאתם קוראים להם בשם: ארוחות ערב של אמצע שבוע, תפריטי חג, המועדפים של הילדים. לכל ספר יש דפדוף בכפולת עמודים, תמונת שער, ותגיות וחיפוש על הכול. ספר אפשר לשתף עם חשבון אחר כצופה או כעורך, ועריכות מגיעות לכולם בזמן אמת.', bullets: ['תגיות, מנות, זמן הכנה ואלרגנים בכל מתכון.', 'חיפוש טקסט מלא בכל הספרייה.', 'ספרי מתכונים משפחתיים משותפים עם עריכה חיה.', 'עובד גם בלי אינטרנט: כל מה ששמרתם נפתח גם בלי חיבור.'] },
        { h2: 'מבשלים בלי ידיים', p: 'מצב בישול הופך מתכון למסכים גדולים, שלב אחרי שלב, עם כמויות המצרכים בדיוק איפה שצריך אותן וטיימרים שממשיכים לרוץ ברקע. לכל מתכון מחושבים ערכים תזונתיים משוערים למנה, והם מסתכמים ללוח שבועי, כך שתכנון ארוחות בריאות יותר לא דורש אפליקציה שנייה.', bullets: ['מצב בישול שלב אחרי שלב עם טיימרים ברקע.', 'קלוריות, חלבון, פחמימות ושומן למנה.', 'משנים את מספר המנות והכמויות מתעדכנות.', 'חמש שפות, כולל עברית וערבית מימין לשמאל.'] },
      ],
      steps: [
        { t: 'משתפים או מדביקים', d: 'מצאתם מתכון? לוחצים על כפתור השיתוף בטיקטוק, באינסטגרם או בדפדפן ובוחרים EasyPlate, או מדביקים את הקישור, הטקסט או הקובץ בשורת החיפוש.' },
        { t: 'עוברים על המתכון', d: 'ה-AI מחזיר מצרכים, כמויות, שלבים, מנות, תגיות וערכים תזונתיים תוך שניות. עורכים מה שרוצים ושומרים לספר.' },
        { t: 'מתכננים, קונים, מבשלים', d: 'גוררים את המתכון ליום בשבוע. רשימת הקניות נבנית לבד לפי מחלקות בסופר, ומצב בישול מוביל אתכם שלב אחרי שלב.' },
      ],
      faq: [
        { q: 'האם EasyPlate חינמית?', a: 'כן. חשבון חינמי כולל מתכונים וספרים ידניים ללא הגבלה, תפריט שבועי ורשימת קניות, ומכסה יומית של חילוצי AI. EasyPlate Pro מסירה את המגבלה ואת הפרסומות ב-20 ₪ לחודש, בחיוב דרך App Store או Google Play.' },
        { q: 'מאילו מקורות אפשר לשמור מתכונים?', a: 'טיקטוק, אינסטגרם, יוטיוב, פייסבוק, כל אתר מתכונים, טקסט מודבק, חיפוש ברשת לפי שם מנה, בקשות כתובות, הקלטות קוליות וקובצי PDF.' },
        { q: 'אפשר לערוך מתכון אחרי שה-AI חילץ אותו?', a: 'הכול ניתן לעריכה: מצרכים, כמויות, שלבים, מנות, תגיות, תמונה וערכים תזונתיים. הפלט של ה-AI הוא נקודת התחלה, לא נעילה.' },
        { q: 'האפליקציה עובדת בעברית?', a: 'כן. EasyPlate עובדת בעברית, ערבית, אנגלית, צרפתית ורוסית עם פריסה מימין לשמאל, והחלפת שפה גם מתרגמת את המתכונים, הספרים, התפריטים והרשימות ששמרתם.' },
        { q: 'המשפחה יכולה להשתמש באותם מתכונים?', a: 'משתפים מתכון בודד, ספר שלם או תפריט שבועי עם חשבון אחר כצופה או כעורך. שינויים מסתנכרנים לכולם בזמן אמת.' },
      ],
      cta: { title: 'המתכונים שלכם, סוף סוף במקום אחד.', sub: 'הורידו את EasyPlate ושמרו את המתכון הבא שתראו.' },
    },
    ar: {
      title: 'تطبيق وصفات بالذكاء الاصطناعي | EasyPlate',
      description: 'احفظ الوصفات من تيك توك وإنستغرام ويوتيوب والمواقع وPDF والرسائل الصوتية في كتاب طبخ واحد مع القيم الغذائية وخطة أسبوعية وقائمة تسوّق. مجاني.',
      keywords: 'تطبيق وصفات, تطبيق تنظيم الوصفات, حفظ الوصفات, كتاب طبخ رقمي, تطبيق وصفات بالذكاء الاصطناعي, تطبيق وصفات مع القيم الغذائية, كتاب طبخ عائلي, تطبيق طبخ',
      h1: 'تطبيق الوصفات الذي يحتفظ بكل وصفة أعجبتك',
      intro: [
        'الوصفات اليوم في كل مكان: ريل أعجبك، لقطة شاشة في المعرض، مدوّنة فيها اثنتا عشرة فقرة قبل المكوّنات، ورقة من أمك. EasyPlate تطبيق وصفات بُني ليجمعها كلها في كتاب طبخ واحد مرتّب وقابل للبحث، بالتنسيق النظيف نفسه لكل وصفة: مكوّنات بكمياتها، خطوات مرقّمة، عدد الحصص، وسوم، وقيم غذائية تقديرية لكل حصة.',
        'بدل الكتابة، تلصق أو تشارك. يقرأ الذكاء الاصطناعي الفيديو أو الصفحة أو النص أو ملف PDF أو الرسالة الصوتية ويعيد وصفة يمكنك تعديلها. ومن هناك تنتقل كل وصفة إلى الخطة الأسبوعية، وإلى كتاب مشترك مع عائلتك، وإلى قائمة التسوّق.',
      ],
      sections: [
        { h2: 'احفظ وصفة من أي مكان', p: 'يقبل EasyPlate ثمانية أنواع من المدخلات، وكلها تنتهي بالوصفة المنظمة نفسها:', bullets: ['رابط من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك أو أي موقع وصفات.', 'نص ملصوق، مثل رسالة واتساب أو تعليق منشور.', 'بحث في الويب باسم الطبق: يجد EasyPlate وصفة ويعيدها منظمة.', 'طلب بكلماتك ("شوربة عدس لأربعة أشخاص بدون بصل").', 'رسالة صوتية تُفرَّغ وتتحوّل إلى وصفة.', 'ملف PDF يُقرأ كمستند كامل.'] },
        { h2: 'نظّم الوصفات في كتب', p: 'تُجمع الوصفات في كتب تسمّيها بنفسك: عشاء أيام الأسبوع، قوائم الأعياد، المفضّلة عند الأطفال. لكل كتاب صفحات مزدوجة تقلّبها، وصورة غلاف، ووسوم وبحث في كل شيء. يمكن مشاركة الكتاب مع حساب آخر كمشاهد أو محرّر، وتصل التعديلات للجميع فورًا.', bullets: ['وسوم وحصص ووقت تحضير ومسببات حساسية في كل وصفة.', 'بحث نصي كامل في مكتبتك كلها.', 'كتب طبخ عائلية مشتركة مع تحرير مباشر.', 'يعمل دون إنترنت: كل ما حفظته يُفتح بلا اتصال.'] },
        { h2: 'اطبخ ويداك حرّتان', p: 'يحوّل وضع الطبخ الوصفة إلى شاشات كبيرة خطوة بخطوة، مع كميات المكوّنات حيث تحتاجها بالضبط، ومؤقّتات تستمر في الخلفية. تُقدَّر القيم الغذائية لكل حصة في كل وصفة وتُجمع في لوحة أسبوعية، فلا يحتاج تخطيط وجبات أصحّ إلى تطبيق ثانٍ.', bullets: ['وضع طبخ خطوة بخطوة مع مؤقّتات في الخلفية.', 'سعرات وبروتين وكربوهيدرات ودهون لكل حصة.', 'غيّر عدد الحصص وتتبعها الكميات.', 'خمس لغات، مع تخطيط كامل من اليمين إلى اليسار بالعربية والعبرية.'] },
      ],
      steps: [
        { t: 'شارك أو الصق', d: 'وجدت وصفة؟ استخدم زر المشاركة في تيك توك أو إنستغرام أو المتصفح واختر EasyPlate، أو الصق الرابط أو النص أو الملف في سطر البحث.' },
        { t: 'راجع الوصفة', d: 'يعيد الذكاء الاصطناعي المكوّنات والكميات والخطوات والحصص والوسوم والقيم الغذائية في ثوانٍ. عدّل ما تشاء ثم احفظها في كتاب.' },
        { t: 'خطّط وتسوّق واطبخ', d: 'ضع الوصفة على يوم في الأسبوع. تُبنى قائمة التسوّق تلقائيًا حسب أقسام المتجر، ويقودك وضع الطبخ خطوة بخطوة.' },
      ],
      faq: [
        { q: 'هل EasyPlate مجاني؟', a: 'نعم. يشمل الحساب المجاني وصفات وكتبًا يدوية بلا حدود، والخطة الأسبوعية وقائمة التسوّق، مع حصة يومية من استخراجات الذكاء الاصطناعي. يزيل EasyPlate Pro الحد والإعلانات مقابل 20 شيكل شهريًا عبر App Store أو Google Play.' },
        { q: 'ما مصادر الوصفات المدعومة؟', a: 'تيك توك وإنستغرام ويوتيوب وفيسبوك وأي موقع وصفات، والنص الملصوق، والبحث في الويب باسم الطبق، والطلبات المكتوبة، والرسائل الصوتية، وملفات PDF.' },
        { q: 'هل يمكن تعديل الوصفة بعد استخراجها؟', a: 'كل شيء قابل للتعديل: المكوّنات والكميات والخطوات والحصص والوسوم والصورة والقيم الغذائية. ناتج الذكاء الاصطناعي نقطة بداية لا قفل.' },
        { q: 'هل يعمل بالعربية؟', a: 'نعم. يعمل EasyPlate بالعربية والعبرية والإنجليزية والفرنسية والروسية بتخطيط من اليمين إلى اليسار، وتغيير اللغة يترجم أيضًا وصفاتك وكتبك وخططك وقوائمك المحفوظة.' },
        { q: 'هل تستطيع عائلتي استخدام الوصفات نفسها؟', a: 'شارك وصفة واحدة أو كتابًا كاملًا أو خطة أسبوعية مع حساب آخر كمشاهد أو محرّر. تتزامن التغييرات مع الجميع فورًا.' },
      ],
      cta: { title: 'وصفاتك، أخيرًا في مكان واحد.', sub: 'حمّل EasyPlate واحفظ الوصفة التالية التي تراها.' },
    },
    fr: {
      title: 'Application de recettes avec IA | EasyPlate',
      description: 'Enregistrez des recettes depuis TikTok, Instagram, YouTube, sites, PDF et notes vocales dans un livre avec nutrition, menu de la semaine et liste de courses.',
      keywords: 'application recettes, appli recettes, organiseur de recettes, livre de recettes numérique, enregistrer des recettes, application recettes IA, recettes avec valeurs nutritionnelles, livre de recettes familial, application cuisine',
      h1: 'L’application de recettes qui garde toutes celles que vous avez aimées',
      intro: [
        'Les recettes sont partout désormais : un reel que vous avez aimé, une capture d’écran dans la galerie, un blog avec douze paragraphes avant les ingrédients, un mot de votre mère. EasyPlate est une application de recettes conçue pour toutes les réunir dans un seul livre propre et consultable, avec le même format pour chacune : ingrédients avec quantités, étapes numérotées, portions, tags et nutrition estimée par portion.',
        'Au lieu de taper, vous collez ou partagez. L’IA lit la vidéo, la page, le texte, le PDF ou la note vocale et renvoie une recette modifiable. Ensuite, chaque recette peut rejoindre le menu de la semaine, un livre partagé avec la famille et la liste de courses.',
      ],
      sections: [
        { h2: 'Enregistrez une recette depuis n’importe où', p: 'EasyPlate accepte huit types d’entrée, et tous aboutissent à la même recette structurée :', bullets: ['Un lien TikTok, Instagram, YouTube, Facebook ou de n’importe quel site de recettes.', 'Un texte collé, par exemple un message WhatsApp ou une légende.', 'Une recherche web par nom de plat : EasyPlate trouve une recette et la ramène structurée.', 'Une demande avec vos mots (« une soupe de lentilles pour quatre, sans oignon »).', 'Une note vocale, transcrite et transformée en recette.', 'Un PDF ou une photo de recette imprimée.'] },
        { h2: 'Organisez vos recettes en livres', p: 'Les recettes sont regroupées dans des livres que vous nommez : dîners de semaine, menus de fête, les préférées des enfants. Chaque livre se feuillette en double page, a une couverture, des tags et une recherche sur tout. Un livre se partage avec un autre compte en lecture ou en édition, et les modifications arrivent chez tout le monde en temps réel.', bullets: ['Tags, portions, temps de préparation et allergènes sur chaque recette.', 'Recherche plein texte dans toute votre bibliothèque.', 'Livres de recettes familiaux partagés avec édition en direct.', 'Hors ligne d’abord : tout ce que vous avez enregistré s’ouvre sans connexion.'] },
        { h2: 'Cuisinez les mains libres', p: 'Le mode cuisson transforme la recette en grands écrans étape par étape, avec les quantités exactement là où vous en avez besoin et des minuteurs qui continuent en arrière-plan. La nutrition par portion est estimée pour chaque recette et additionnée dans un tableau hebdomadaire : planifier des repas plus sains ne demande pas une deuxième application.', bullets: ['Mode cuisson étape par étape avec minuteurs en arrière-plan.', 'Calories, protéines, glucides et lipides par portion.', 'Changez le nombre de portions, les quantités suivent.', 'Cinq langues, dont l’hébreu et l’arabe de droite à gauche.'] },
      ],
      steps: [
        { t: 'Partagez ou collez', d: 'Vous avez trouvé une recette ? Utilisez le bouton Partager de TikTok, Instagram ou du navigateur et choisissez EasyPlate, ou collez le lien, le texte ou le fichier dans la barre de recherche.' },
        { t: 'Relisez la recette', d: 'L’IA renvoie ingrédients, quantités, étapes, portions, tags et nutrition en quelques secondes. Modifiez ce que vous voulez, puis enregistrez dans un livre.' },
        { t: 'Planifiez, achetez, cuisinez', d: 'Déposez la recette sur un jour de la semaine. La liste de courses se construit seule, par rayon, et le mode cuisson vous guide étape par étape.' },
      ],
      faq: [
        { q: 'EasyPlate est-il gratuit ?', a: 'Oui. Un compte gratuit comprend des recettes et livres manuels illimités, le menu de la semaine et la liste de courses, plus un quota quotidien d’extractions par IA. EasyPlate Pro supprime la limite et les publicités pour 20 ₪ par mois, facturés via l’App Store ou Google Play.' },
        { q: 'Quelles sources de recettes sont prises en charge ?', a: 'TikTok, Instagram, YouTube, Facebook, tout site de recettes, le texte collé, la recherche web par nom de plat, les demandes écrites, les notes vocales et les fichiers PDF.' },
        { q: 'Puis-je modifier une recette après l’extraction ?', a: 'Tout est modifiable : ingrédients, quantités, étapes, portions, tags, photo et nutrition. Le résultat de l’IA est un point de départ, pas un verrou.' },
        { q: 'Fonctionne-t-il en français ?', a: 'Oui. EasyPlate fonctionne en français, anglais, hébreu, arabe et russe, et changer de langue traduit aussi vos recettes, livres, menus et listes enregistrés.' },
        { q: 'Ma famille peut-elle utiliser les mêmes recettes ?', a: 'Partagez une recette, un livre entier ou un menu de la semaine avec un autre compte, en lecture ou en édition. Les changements se synchronisent pour tous en temps réel.' },
      ],
      cta: { title: 'Vos recettes, enfin au même endroit.', sub: 'Téléchargez EasyPlate et enregistrez la prochaine recette que vous verrez.' },
    },
    ru: {
      title: 'Приложение рецептов с ИИ | EasyPlate',
      description: 'Сохраняйте рецепты из TikTok, Instagram, YouTube, с сайтов, из PDF и голосовых в одну книгу с КБЖУ, меню на неделю и списком покупок. Бесплатно.',
      keywords: 'приложение рецептов, приложение для рецептов, органайзер рецептов, цифровая книга рецептов, сохранить рецепт, приложение рецептов с ИИ, рецепты с КБЖУ, семейная книга рецептов, приложение для готовки',
      h1: 'Приложение рецептов, которое хранит всё, что вам понравилось',
      intro: [
        'Рецепты теперь повсюду: понравившийся рилс, скриншот в галерее, блог с двенадцатью абзацами до списка ингредиентов, записка от мамы. EasyPlate — приложение рецептов, созданное, чтобы собрать их все в одну аккуратную книгу с поиском, в одинаковом чистом формате: ингредиенты с количеством, пронумерованные шаги, порции, теги и примерная пищевая ценность на порцию.',
        'Вместо набора текста вы вставляете или делитесь. ИИ читает видео, страницу, текст, PDF или голосовую заметку и возвращает рецепт, который можно редактировать. Дальше любой рецепт попадает в меню на неделю, в общую книгу с семьёй и в список покупок.',
      ],
      sections: [
        { h2: 'Сохраняйте рецепт откуда угодно', p: 'EasyPlate принимает восемь видов ввода, и все они превращаются в один структурированный рецепт:', bullets: ['Ссылка из TikTok, Instagram, YouTube, Facebook или с любого сайта рецептов.', 'Вставленный текст, например сообщение из WhatsApp или подпись к посту.', 'Поиск в интернете по названию блюда: EasyPlate находит рецепт и возвращает его структурированным.', 'Запрос своими словами («чечевичный суп на четверых, без лука»).', 'Голосовая заметка, расшифрованная и превращённая в рецепт.', 'Файл PDF, читается как целый документ.'] },
        { h2: 'Упорядочивайте рецепты в книги', p: 'Рецепты собираются в книги, которые вы называете сами: ужины на будни, праздничные меню, любимое у детей. У книги есть разворот, который листают, обложка, теги и поиск по всему. Книгу можно открыть другому аккаунту для просмотра или редактирования, и правки доходят до всех в реальном времени.', bullets: ['Теги, порции, время готовки и аллергены у каждого рецепта.', 'Полнотекстовый поиск по всей библиотеке.', 'Общие семейные книги рецептов с живым редактированием.', 'Работает офлайн: всё сохранённое открывается без соединения.'] },
        { h2: 'Готовьте, не трогая телефон', p: 'Режим готовки превращает рецепт в крупные экраны шаг за шагом, с количеством ингредиентов ровно там, где оно нужно, и таймерами, которые продолжают идти в фоне. Пищевая ценность на порцию оценивается для каждого рецепта и суммируется в недельную панель, так что для более здорового меню не нужно второе приложение.', bullets: ['Пошаговый режим готовки с фоновыми таймерами.', 'Калории, белки, углеводы и жиры на порцию.', 'Меняете число порций — количества пересчитываются.', 'Пять языков, включая иврит и арабский справа налево.'] },
      ],
      steps: [
        { t: 'Поделитесь или вставьте', d: 'Нашли рецепт? Нажмите «Поделиться» в TikTok, Instagram или браузере и выберите EasyPlate, либо вставьте ссылку, текст или файл в строку поиска.' },
        { t: 'Проверьте рецепт', d: 'ИИ за секунды возвращает ингредиенты, количества, шаги, порции, теги и пищевую ценность. Исправьте что нужно и сохраните в книгу.' },
        { t: 'Планируйте, покупайте, готовьте', d: 'Перетащите рецепт на день недели. Список покупок соберётся сам по отделам магазина, а режим готовки проведёт по шагам.' },
      ],
      faq: [
        { q: 'EasyPlate бесплатный?', a: 'Да. Бесплатный аккаунт включает неограниченные ручные рецепты и книги, меню на неделю и список покупок, а также дневной лимит извлечений ИИ. EasyPlate Pro снимает лимит и рекламу за 20 ₪ в месяц через App Store или Google Play.' },
        { q: 'Какие источники рецептов поддерживаются?', a: 'TikTok, Instagram, YouTube, Facebook, любой сайт рецептов, вставленный текст, поиск по названию блюда, письменные запросы, голосовые заметки и файлы PDF.' },
        { q: 'Можно ли редактировать рецепт после извлечения?', a: 'Редактируется всё: ингредиенты, количества, шаги, порции, теги, фото и пищевая ценность. Результат ИИ — отправная точка, а не замок.' },
        { q: 'Работает ли на русском?', a: 'Да. EasyPlate работает на русском, английском, иврите, арабском и французском, а смена языка переводит и ваши сохранённые рецепты, книги, меню и списки.' },
        { q: 'Может ли семья пользоваться теми же рецептами?', a: 'Поделитесь одним рецептом, целой книгой или меню на неделю с другим аккаунтом в режиме просмотра или редактирования. Изменения синхронизируются у всех в реальном времени.' },
      ],
      cta: { title: 'Ваши рецепты — наконец в одном месте.', sub: 'Скачайте EasyPlate и сохраните следующий рецепт, который увидите.' },
    },
  },

  // ------------------------------------------------------------------ B
  'grocery-list-app': {
    icon: 'shopping-basket', screens: ['08_grocery', '06_meal_plan'],
    en: {
      title: 'Shared Grocery List App Built from Recipes | EasyPlate',
      description: 'A grocery list that builds itself from your meal plan, merges duplicates, groups by aisle, syncs with your family and estimates the cost from your receipts.',
      keywords: 'grocery list app, shopping list app, shared grocery list, family shopping list, grocery list from recipes, smart grocery list, grocery list by aisle, shopping list with prices',
      h1: 'A grocery list app that writes the list for you',
      intro: [
        'Most shopping list apps still start from a blank page. EasyPlate starts from what you are going to cook: every recipe on the weekly plan adds its ingredients, duplicates are merged into one line with the summed amount, and the whole list is grouped by supermarket aisle so you walk the store once.',
        'The list is shared. Your partner adds milk from the sofa, you tick it off in the dairy aisle, and both phones update instantly. Several lists can live side by side: the weekly shop, a party, the pharmacy run.',
      ],
      sections: [
        { h2: 'From recipes to a list in one tap', p: 'The grocery list is a view of your meal plan, not a separate chore:', bullets: ['Put recipes on the days of the week and the list fills itself.', 'Amounts are added up across recipes: two recipes with half an onion become one onion.', 'Scale a recipe to more servings and the list follows.', 'Build a list from a single recipe when you just want to cook one thing tonight.', 'Add manual items for everything that is not a recipe: soap, batteries, the dog’s food.'] },
        { h2: 'Grouped by aisle, shared in real time', p: 'Items are sorted by the departments of a typical supermarket: produce, dairy, meat and fish, bakery, pantry, frozen, household. Ticking an item moves it out of the way. Share the list with other accounts, and everyone sees the same state within a second.', bullets: ['Aisle grouping that matches how the store is laid out.', 'Shared lists for the whole household, with live updates.', 'Several lists at once, each with its own source: a plan, a recipe or manual items.', 'Works offline in the store; changes sync when you are back online.'] },
        { h2: 'Know what the shop will cost', p: 'Snap a photo of a receipt after shopping and EasyPlate reads the product names and prices into your personal price book. From then on the list shows an estimated total based on what you actually paid last time, and community medians fill the gaps for items you have not bought yet. Receipt scans keep only product names and prices, never the store or the payment details.', bullets: ['Estimated cost of the list before you leave home.', 'Your own price history, learned from your receipts.', 'Per-serving nutrition for every planned meal, summed into a weekly dashboard.'] },
      ],
      steps: [
        { t: 'Plan the week', d: 'Drop recipes onto the days of the week, or pick one recipe and build a list from it.' },
        { t: 'Open the list', d: 'Ingredients are already there, merged and grouped by aisle. Add anything else by hand and share the list with your household.' },
        { t: 'Shop and tick', d: 'Walk the store aisle by aisle, tick items off, and scan the receipt at the end so the next list shows a price estimate.' },
      ],
      faq: [
        { q: 'Can I share the grocery list with my family?', a: 'Yes. Share a list, a weekly plan or a whole cookbook with another account. Everyone sees additions and ticks in real time.' },
        { q: 'Does the list merge duplicate ingredients?', a: 'Yes. The same ingredient from several recipes becomes one line with the summed amount, and manual items join the same list.' },
        { q: 'Can I have more than one list?', a: 'Yes. Keep several lists, each built from a plan, from one recipe or by hand, and switch the active list on each device.' },
        { q: 'How does the price estimate work?', a: 'After you scan a receipt, product names and prices go into your personal price book. The list total is estimated from your own history first, and from community medians for items you have not bought before.' },
        { q: 'Is the grocery list free?', a: 'Yes. The weekly plan and the grocery list are part of the free account. Pro adds unlimited AI recipe extractions, no ads and cloud sync across devices.' },
      ],
      cta: { title: 'Stop writing the same list every week.', sub: 'Download EasyPlate and let the plan write it for you.' },
    },
    he: {
      title: 'אפליקציית רשימת קניות חכמה ומשותפת | EasyPlate',
      description: 'רשימת קניות שנבנית לבד מהתפריט השבועי, מאחדת כפילויות, מסודרת לפי מחלקות, מסתנכרנת עם המשפחה ומעריכה עלות מהקבלות שלכם. חינם.',
      keywords: 'אפליקציית רשימת קניות, רשימת קניות משותפת, רשימת קניות משפחתית, רשימת קניות לסופר, רשימת קניות ממתכונים, רשימת קניות חכמה, רשימת קניות לפי מחלקות, רשימת קניות עם מחירים',
      h1: 'אפליקציית רשימת קניות שכותבת את הרשימה בשבילכם',
      intro: [
        'רוב אפליקציות רשימת הקניות עדיין מתחילות מדף ריק. EasyPlate מתחילה ממה שאתם הולכים לבשל: כל מתכון בתפריט השבועי מוסיף את המצרכים שלו, כפילויות מתאחדות לשורה אחת עם הכמות המסוכמת, וכל הרשימה מסודרת לפי מחלקות בסופר כדי שתעברו בחנות פעם אחת.',
        'הרשימה משותפת. בן או בת הזוג מוסיפים חלב מהספה, אתם מסמנים אותו במחלקת החלב, ושני הטלפונים מתעדכנים מיד. כמה רשימות יכולות לחיות במקביל: הקנייה השבועית, מסיבה, סיבוב בבית המרקחת.',
      ],
      sections: [
        { h2: 'ממתכונים לרשימה בלחיצה אחת', p: 'רשימת הקניות היא תצוגה של התפריט שלכם, לא מטלה נפרדת:', bullets: ['שמים מתכונים על ימי השבוע והרשימה מתמלאת לבד.', 'הכמויות מסתכמות בין מתכונים: שני מתכונים עם חצי בצל הופכים לבצל אחד.', 'מגדילים מתכון ליותר מנות והרשימה מתעדכנת.', 'בונים רשימה ממתכון בודד כשרוצים לבשל רק דבר אחד הערב.', 'מוסיפים פריטים ידניים לכל מה שאינו מתכון: סבון, סוללות, אוכל לכלב.'] },
        { h2: 'מסודר לפי מחלקות, משותף בזמן אמת', p: 'הפריטים ממוינים לפי המחלקות של סופר טיפוסי: ירקות ופירות, מוצרי חלב, בשר ודגים, מאפייה, יבשים, קפואים, ניקיון. סימון פריט מזיז אותו הצידה. משתפים את הרשימה עם חשבונות אחרים, וכולם רואים את אותו מצב תוך שנייה.', bullets: ['קיבוץ לפי מחלקות שמתאים לסידור של החנות.', 'רשימות משותפות לכל הבית, עם עדכונים חיים.', 'כמה רשימות במקביל, לכל אחת מקור משלה: תפריט, מתכון או פריטים ידניים.', 'עובד בלי אינטרנט בתוך החנות; השינויים מסתנכרנים כשחוזרים לרשת.'] },
        { h2: 'לדעת כמה הקנייה תעלה', p: 'מצלמים קבלה אחרי הקנייה ו-EasyPlate קוראת את שמות המוצרים והמחירים לספר המחירים האישי שלכם. מאז הרשימה מציגה סכום משוער לפי מה ששילמתם בפעם הקודמת, וחציוני קהילה משלימים פריטים שעוד לא קניתם. סריקת קבלה שומרת רק שמות מוצרים ומחירים, לעולם לא את החנות או פרטי התשלום.', bullets: ['עלות משוערת של הרשימה לפני שיוצאים מהבית.', 'היסטוריית מחירים משלכם, שנלמדת מהקבלות.', 'ערכים תזונתיים למנה לכל ארוחה מתוכננת, מסוכמים ללוח שבועי.'] },
      ],
      steps: [
        { t: 'מתכננים את השבוע', d: 'גוררים מתכונים לימי השבוע, או בוחרים מתכון אחד ובונים ממנו רשימה.' },
        { t: 'פותחים את הרשימה', d: 'המצרכים כבר שם, מאוחדים ומסודרים לפי מחלקות. מוסיפים ידנית כל דבר אחר ומשתפים את הרשימה עם הבית.' },
        { t: 'קונים ומסמנים', d: 'עוברים בחנות מחלקה אחרי מחלקה, מסמנים פריטים, ובסוף סורקים את הקבלה כדי שהרשימה הבאה תציג הערכת מחיר.' },
      ],
      faq: [
        { q: 'אפשר לשתף את רשימת הקניות עם המשפחה?', a: 'כן. משתפים רשימה, תפריט שבועי או ספר מתכונים שלם עם חשבון אחר. כולם רואים הוספות וסימונים בזמן אמת.' },
        { q: 'הרשימה מאחדת מצרכים כפולים?', a: 'כן. אותו מצרך מכמה מתכונים הופך לשורה אחת עם הכמות המסוכמת, ופריטים ידניים מצטרפים לאותה רשימה.' },
        { q: 'אפשר להחזיק יותר מרשימה אחת?', a: 'כן. מנהלים כמה רשימות, כל אחת נבנית מתפריט, ממתכון אחד או ידנית, ובוחרים את הרשימה הפעילה בכל מכשיר.' },
        { q: 'איך עובדת הערכת המחיר?', a: 'אחרי סריקת קבלה, שמות המוצרים והמחירים נכנסים לספר המחירים האישי. סכום הרשימה מוערך קודם מההיסטוריה שלכם, ומחציוני קהילה לפריטים שעוד לא קניתם.' },
        { q: 'רשימת הקניות חינמית?', a: 'כן. התפריט השבועי ורשימת הקניות הם חלק מהחשבון החינמי. Pro מוסיף חילוצי AI ללא הגבלה, בלי פרסומות וסנכרון ענן בין מכשירים.' },
      ],
      cta: { title: 'די לכתוב את אותה רשימה כל שבוע.', sub: 'הורידו את EasyPlate ותנו לתפריט לכתוב אותה בשבילכם.' },
    },
    ar: {
      title: 'تطبيق قائمة تسوّق ذكية ومشتركة | EasyPlate',
      description: 'قائمة تسوّق تُبنى تلقائيًا من خطة الوجبات، تدمج المكررات، تُرتّب حسب الأقسام، تتزامن مع العائلة وتقدّر التكلفة من فواتيرك. مجانية.',
      keywords: 'تطبيق قائمة تسوق, تطبيق قائمة مشتريات, قائمة تسوق مشتركة, قائمة تسوق عائلية, قائمة تسوق من الوصفات, قائمة تسوق ذكية, قائمة تسوق حسب الأقسام, قائمة تسوق مع الأسعار',
      h1: 'تطبيق قائمة تسوّق يكتب القائمة بدلًا منك',
      intro: [
        'معظم تطبيقات قوائم التسوّق ما زالت تبدأ من صفحة فارغة. يبدأ EasyPlate مما ستطبخه: كل وصفة في الخطة الأسبوعية تضيف مكوّناتها، وتُدمج المكررات في سطر واحد بكمية مجموعة، وتُرتَّب القائمة كلها حسب أقسام المتجر لتمرّ بالمتجر مرة واحدة.',
        'القائمة مشتركة. يضيف شريكك الحليب من الأريكة، وتشطبه أنت في قسم الألبان، ويتحدّث الهاتفان فورًا. ويمكن أن تعيش عدة قوائم جنبًا إلى جنب: تسوّق الأسبوع، حفلة، جولة الصيدلية.',
      ],
      sections: [
        { h2: 'من الوصفات إلى قائمة بنقرة واحدة', p: 'قائمة التسوّق عرض لخطة وجباتك، لا مهمة منفصلة:', bullets: ['ضع الوصفات على أيام الأسبوع وتمتلئ القائمة وحدها.', 'تُجمع الكميات عبر الوصفات: وصفتان بنصف بصلة تصبحان بصلة واحدة.', 'زِد حصص وصفة وتتبعها القائمة.', 'ابنِ قائمة من وصفة واحدة عندما تريد طبخ شيء واحد الليلة.', 'أضف أصنافًا يدوية لكل ما ليس وصفة: صابون، بطاريات، طعام الكلب.'] },
        { h2: 'مرتّبة حسب الأقسام، مشتركة فورًا', p: 'تُرتَّب الأصناف حسب أقسام المتجر المعتاد: خضار وفواكه، ألبان، لحوم وأسماك، مخبوزات، بقالة، مجمّدات، منزلية. شطب صنف يبعده عن الطريق. شارك القائمة مع حسابات أخرى، ويرى الجميع الحالة نفسها خلال ثانية.', bullets: ['تجميع حسب الأقسام يطابق ترتيب المتجر.', 'قوائم مشتركة للبيت كله مع تحديثات مباشرة.', 'عدة قوائم في آن واحد، لكل منها مصدرها: خطة أو وصفة أو أصناف يدوية.', 'يعمل دون إنترنت داخل المتجر؛ تتزامن التغييرات عند عودة الاتصال.'] },
        { h2: 'اعرف كم ستكلّف المشتريات', p: 'صوّر الفاتورة بعد التسوّق ويقرأ EasyPlate أسماء المنتجات وأسعارها في دفتر أسعارك الشخصي. منذ ذلك الحين تعرض القائمة مجموعًا تقديريًا بناءً على ما دفعته فعلًا في المرة السابقة، وتكمل وسيطات المجتمع ما لم تشترِه بعد. يحتفظ مسح الفاتورة بأسماء المنتجات والأسعار فقط، لا المتجر ولا بيانات الدفع.', bullets: ['تكلفة تقديرية للقائمة قبل مغادرة البيت.', 'سجلّ أسعارك الخاص، يُتعلَّم من فواتيرك.', 'قيم غذائية لكل حصة لكل وجبة مخطَّطة، مجموعة في لوحة أسبوعية.'] },
      ],
      steps: [
        { t: 'خطّط الأسبوع', d: 'ضع الوصفات على أيام الأسبوع، أو اختر وصفة واحدة وابنِ منها قائمة.' },
        { t: 'افتح القائمة', d: 'المكوّنات موجودة بالفعل، مدمجة ومرتّبة حسب الأقسام. أضف أي شيء آخر يدويًا وشارك القائمة مع أهل البيت.' },
        { t: 'تسوّق واشطب', d: 'امشِ في المتجر قسمًا قسمًا، اشطب الأصناف، وامسح الفاتورة في النهاية لتعرض القائمة التالية تقدير السعر.' },
      ],
      faq: [
        { q: 'هل يمكن مشاركة قائمة التسوّق مع عائلتي؟', a: 'نعم. شارك قائمة أو خطة أسبوعية أو كتاب طبخ كاملًا مع حساب آخر. يرى الجميع الإضافات والشطب فورًا.' },
        { q: 'هل تدمج القائمة المكوّنات المكررة؟', a: 'نعم. المكوّن نفسه من عدة وصفات يصبح سطرًا واحدًا بكمية مجموعة، وتنضم الأصناف اليدوية إلى القائمة نفسها.' },
        { q: 'هل يمكن أن يكون لديّ أكثر من قائمة؟', a: 'نعم. احتفظ بعدة قوائم، كل منها مبنية من خطة أو من وصفة واحدة أو يدويًا، وبدّل القائمة النشطة على كل جهاز.' },
        { q: 'كيف يعمل تقدير السعر؟', a: 'بعد مسح فاتورة، تدخل أسماء المنتجات والأسعار في دفتر أسعارك الشخصي. يُقدَّر مجموع القائمة من سجلّك أولًا، ومن وسيطات المجتمع للأصناف التي لم تشترِها من قبل.' },
        { q: 'هل قائمة التسوّق مجانية؟', a: 'نعم. الخطة الأسبوعية وقائمة التسوّق جزء من الحساب المجاني. يضيف Pro استخراجات وصفات بلا حدود، وبلا إعلانات، ومزامنة سحابية بين الأجهزة.' },
      ],
      cta: { title: 'كفى كتابة القائمة نفسها كل أسبوع.', sub: 'حمّل EasyPlate ودع الخطة تكتبها لك.' },
    },
    fr: {
      title: 'Liste de courses partagée et intelligente | EasyPlate',
      description: 'Une liste de courses qui se construit depuis votre menu, fusionne les doublons, se range par rayon, se partage en famille et estime le coût d’après vos tickets.',
      keywords: 'application liste de courses, liste de courses partagée, liste de courses familiale, liste de courses depuis recettes, liste de courses intelligente, liste de courses par rayon, liste de courses avec prix',
      h1: 'Une application de liste de courses qui écrit la liste à votre place',
      intro: [
        'La plupart des applications de liste de courses partent encore d’une page blanche. EasyPlate part de ce que vous allez cuisiner : chaque recette du menu de la semaine ajoute ses ingrédients, les doublons sont fusionnés en une ligne avec la quantité totale, et toute la liste est regroupée par rayon pour parcourir le magasin une seule fois.',
        'La liste est partagée. Votre conjoint ajoute le lait depuis le canapé, vous le cochez au rayon frais, et les deux téléphones se mettent à jour instantanément. Plusieurs listes peuvent coexister : les courses de la semaine, une fête, le passage à la pharmacie.',
      ],
      sections: [
        { h2: 'Des recettes à la liste en un geste', p: 'La liste de courses est une vue de votre menu, pas une corvée à part :', bullets: ['Placez des recettes sur les jours de la semaine et la liste se remplit seule.', 'Les quantités s’additionnent entre recettes : deux recettes avec un demi-oignon donnent un oignon.', 'Augmentez les portions d’une recette et la liste suit.', 'Créez une liste depuis une seule recette quand vous ne cuisinez qu’un plat ce soir.', 'Ajoutez à la main tout ce qui n’est pas une recette : savon, piles, croquettes.'] },
        { h2: 'Regroupée par rayon, partagée en temps réel', p: 'Les articles sont triés selon les rayons d’un supermarché classique : fruits et légumes, crèmerie, boucherie et poissonnerie, boulangerie, épicerie, surgelés, entretien. Cocher un article l’écarte du chemin. Partagez la liste avec d’autres comptes et tout le monde voit le même état en une seconde.', bullets: ['Regroupement par rayon fidèle à l’agencement du magasin.', 'Listes partagées pour tout le foyer, mises à jour en direct.', 'Plusieurs listes à la fois, chacune avec sa source : un menu, une recette ou des articles manuels.', 'Fonctionne hors ligne en magasin ; les changements se synchronisent au retour du réseau.'] },
        { h2: 'Sachez combien coûteront les courses', p: 'Photographiez le ticket de caisse après les courses : EasyPlate lit les noms de produits et les prix dans votre carnet de prix personnel. Ensuite, la liste affiche un total estimé d’après ce que vous avez réellement payé la dernière fois, et des médianes communautaires complètent les articles jamais achetés. Le scan ne conserve que les noms de produits et les prix, jamais le magasin ni le paiement.', bullets: ['Coût estimé de la liste avant de partir.', 'Votre propre historique de prix, appris de vos tickets.', 'Nutrition par portion pour chaque repas planifié, additionnée dans un tableau hebdomadaire.'] },
      ],
      steps: [
        { t: 'Planifiez la semaine', d: 'Déposez des recettes sur les jours de la semaine, ou choisissez une recette et créez une liste à partir d’elle.' },
        { t: 'Ouvrez la liste', d: 'Les ingrédients sont déjà là, fusionnés et regroupés par rayon. Ajoutez le reste à la main et partagez la liste avec le foyer.' },
        { t: 'Faites les courses et cochez', d: 'Parcourez le magasin rayon par rayon, cochez les articles, puis scannez le ticket pour que la prochaine liste affiche une estimation de prix.' },
      ],
      faq: [
        { q: 'Puis-je partager la liste de courses avec ma famille ?', a: 'Oui. Partagez une liste, un menu de la semaine ou un livre entier avec un autre compte. Tout le monde voit les ajouts et les cases cochées en temps réel.' },
        { q: 'La liste fusionne-t-elle les ingrédients en double ?', a: 'Oui. Le même ingrédient venant de plusieurs recettes devient une ligne avec la quantité totale, et les articles manuels rejoignent la même liste.' },
        { q: 'Puis-je avoir plusieurs listes ?', a: 'Oui. Gardez plusieurs listes, construites depuis un menu, une recette ou à la main, et changez la liste active sur chaque appareil.' },
        { q: 'Comment fonctionne l’estimation de prix ?', a: 'Après le scan d’un ticket, les noms de produits et les prix entrent dans votre carnet de prix. Le total est estimé d’abord depuis votre historique, puis depuis des médianes communautaires pour les articles jamais achetés.' },
        { q: 'La liste de courses est-elle gratuite ?', a: 'Oui. Le menu de la semaine et la liste de courses font partie du compte gratuit. Pro ajoute les extractions IA illimitées, zéro publicité et la synchronisation cloud entre appareils.' },
      ],
      cta: { title: 'Arrêtez d’écrire la même liste chaque semaine.', sub: 'Téléchargez EasyPlate et laissez le menu l’écrire pour vous.' },
    },
    ru: {
      title: 'Умный общий список покупок | EasyPlate',
      description: 'Список покупок, который собирается из меню, объединяет повторы, группирует по отделам, синхронизируется с семьёй и оценивает стоимость по чекам.',
      keywords: 'приложение список покупок, общий список покупок, семейный список покупок, список покупок из рецептов, умный список покупок, список покупок по отделам, список покупок с ценами',
      h1: 'Приложение для списка покупок, которое пишет список за вас',
      intro: [
        'Большинство приложений для списка покупок всё ещё начинают с пустой страницы. EasyPlate начинает с того, что вы будете готовить: каждый рецепт в меню на неделю добавляет свои ингредиенты, повторы объединяются в одну строку с суммарным количеством, а весь список группируется по отделам магазина, чтобы пройти его один раз.',
        'Список общий. Партнёр добавляет молоко с дивана, вы отмечаете его в молочном отделе, и оба телефона обновляются мгновенно. Несколько списков могут жить рядом: покупки на неделю, вечеринка, поход в аптеку.',
      ],
      sections: [
        { h2: 'Из рецептов в список одним нажатием', p: 'Список покупок — это представление вашего меню, а не отдельная обязанность:', bullets: ['Расставьте рецепты по дням недели, и список заполнится сам.', 'Количества суммируются между рецептами: два рецепта с половиной луковицы дают одну луковицу.', 'Увеличьте порции рецепта — список подстроится.', 'Соберите список из одного рецепта, когда вечером нужно приготовить только одно блюдо.', 'Добавляйте вручную всё, что не рецепт: мыло, батарейки, корм для собаки.'] },
        { h2: 'По отделам, в реальном времени', p: 'Позиции отсортированы по отделам типичного супермаркета: овощи и фрукты, молочное, мясо и рыба, выпечка, бакалея, заморозка, бытовое. Отмеченная позиция уходит с дороги. Поделитесь списком с другими аккаунтами, и все увидят одно и то же состояние в течение секунды.', bullets: ['Группировка по отделам, совпадающая с планировкой магазина.', 'Общие списки на всю семью с живыми обновлениями.', 'Несколько списков одновременно, у каждого свой источник: меню, рецепт или ручные позиции.', 'Работает офлайн в магазине; изменения синхронизируются при возвращении сети.'] },
        { h2: 'Знайте, во сколько обойдутся покупки', p: 'Сфотографируйте чек после покупок, и EasyPlate считает названия товаров и цены в вашу личную книгу цен. С этого момента список показывает ориентировочную сумму по тому, что вы реально платили в прошлый раз, а медианы сообщества заполняют пробелы по товарам, которых вы ещё не покупали. Скан чека сохраняет только названия и цены, никогда магазин или данные оплаты.', bullets: ['Ориентировочная стоимость списка до выхода из дома.', 'Собственная история цен, выученная по чекам.', 'КБЖУ на порцию для каждого запланированного блюда, суммированные в недельную панель.'] },
      ],
      steps: [
        { t: 'Спланируйте неделю', d: 'Перетащите рецепты на дни недели или выберите один рецепт и соберите список из него.' },
        { t: 'Откройте список', d: 'Ингредиенты уже там, объединены и сгруппированы по отделам. Добавьте остальное вручную и поделитесь списком с домашними.' },
        { t: 'Покупайте и отмечайте', d: 'Пройдите магазин отдел за отделом, отмечайте позиции, а в конце отсканируйте чек, чтобы следующий список показал оценку цены.' },
      ],
      faq: [
        { q: 'Можно ли поделиться списком покупок с семьёй?', a: 'Да. Поделитесь списком, меню на неделю или целой книгой рецептов с другим аккаунтом. Все видят добавления и отметки в реальном времени.' },
        { q: 'Объединяет ли список повторяющиеся ингредиенты?', a: 'Да. Один и тот же ингредиент из нескольких рецептов становится одной строкой с суммарным количеством, а ручные позиции попадают в тот же список.' },
        { q: 'Можно ли вести несколько списков?', a: 'Да. Держите несколько списков, собранных из меню, из одного рецепта или вручную, и переключайте активный список на каждом устройстве.' },
        { q: 'Как работает оценка цены?', a: 'После скана чека названия товаров и цены попадают в личную книгу цен. Сумма списка оценивается сначала по вашей истории, а затем по медианам сообщества для товаров, которых вы ещё не покупали.' },
        { q: 'Список покупок бесплатный?', a: 'Да. Меню на неделю и список покупок входят в бесплатный аккаунт. Pro добавляет неограниченные извлечения рецептов ИИ, отсутствие рекламы и облачную синхронизацию между устройствами.' },
      ],
      cta: { title: 'Хватит писать один и тот же список каждую неделю.', sub: 'Скачайте EasyPlate и дайте меню написать его за вас.' },
    },
  },

  // ------------------------------------------------------------------ C
  'meal-planner': {
    icon: 'calendar-days', screens: ['06_meal_plan', '07_nutrition'],
    en: {
      title: 'Weekly Meal Planner with Grocery List | EasyPlate',
      description: 'Drag recipes onto the days of the week and get the grocery list and the calories, protein, carbs and fat per serving automatically. Share the plan with family.',
      keywords: 'meal planner app, weekly meal plan, meal planning app, menu planner, weekly menu, meal prep planner, meal plan with grocery list, family meal planner, calorie meal planner',
      h1: 'A weekly meal planner that ends with a grocery list',
      intro: [
        'Meal planning fails when it is a separate spreadsheet. In EasyPlate the plan is made of your own recipes: drag one onto Tuesday dinner and the ingredients are already on the grocery list, the nutrition is already in the weekly dashboard, and Cook Mode is one tap away when Tuesday comes.',
        'The plan is shared with whoever cooks with you. Change Thursday and your partner sees it immediately. Plans can be saved and reused, so a good week becomes a template rather than a memory.',
      ],
      sections: [
        { h2: 'Plan with recipes you actually have', p: 'Every recipe in your books can go on the plan, including the ones you just saved from TikTok or a blog:', bullets: ['Breakfast, lunch, dinner and snacks for each day of the week.', 'Drag a recipe onto a day; scale servings for the number of people eating.', 'Ask the built-in assistant for ideas: "plan four cheap vegetarian dinners from my books".', 'Reuse a plan next week or share it as a ready-made menu.'] },
        { h2: 'The grocery list and the macros come free', p: 'A plan is the source of the grocery list and of the nutrition dashboard. You never copy ingredients, and you never add up calories by hand.', bullets: ['One grocery list for the whole week, merged and grouped by aisle.', 'Calories, protein, carbs and fat per serving on each planned meal.', 'A weekly dashboard that sums the plan, so you see the week before you eat it.', 'Estimated cost of the week from your own receipt history.'] },
        { h2: 'Shared with the household', p: 'Share a plan with another account as a viewer or an editor. Every edit reaches the other phone in real time, and the shared plan keeps working as recipes are added to it. It is the simplest way to stop the nightly "what are we eating" conversation.', bullets: ['Real-time sync between family members.', 'Viewer or editor access per person.', 'Offline-first: the plan opens in the kitchen without a signal.', 'Five languages; switching translates your plans and recipes too.'] },
      ],
      steps: [
        { t: 'Collect recipes', d: 'Save recipes from links, text, voice or PDF, or write your own. Each one gets nutrition per serving automatically.' },
        { t: 'Fill the week', d: 'Drag recipes onto the days of the week. The grocery list and the weekly nutrition total build themselves.' },
        { t: 'Shop once, cook daily', d: 'Walk the store with the aisle-grouped list, then open Cook Mode each evening for hands-free steps and timers.' },
      ],
      faq: [
        { q: 'Does the meal planner create the grocery list automatically?', a: 'Yes. Every recipe on the plan adds its ingredients; duplicates are merged and the list is grouped by supermarket aisle.' },
        { q: 'Can I see calories for the whole week?', a: 'Yes. Each recipe has estimated calories, protein, carbs and fat per serving, and the dashboard sums the planned meals across the week.' },
        { q: 'Can I plan for a different number of people?', a: 'Yes. Scale the servings of any planned recipe and both the amounts and the grocery list follow.' },
        { q: 'Can my partner edit the plan?', a: 'Yes. Share the plan as an editor and changes sync in real time on both phones.' },
        { q: 'Is the meal planner free?', a: 'Yes. The weekly plan, grocery list and nutrition dashboard are included in the free account. Pro removes the daily AI limit and the ads.' },
      ],
      cta: { title: 'Plan the week once. Cook all week.', sub: 'Download EasyPlate and build your first plan from recipes you already love.' },
    },
    he: {
      title: 'תכנון תפריט שבועי עם רשימת קניות | EasyPlate',
      description: 'גוררים מתכונים לימי השבוע ומקבלים אוטומטית רשימת קניות וקלוריות, חלבון, פחמימות ושומן למנה. משתפים את התפריט עם המשפחה. חינם.',
      keywords: 'תכנון תפריט שבועי, אפליקציה לתכנון ארוחות, תפריט שבועי למשפחה, מתכנן ארוחות, תפריט שבועי עם רשימת קניות, תכנון ארוחות שבועי, תפריט שבועי קלוריות, תפריט שבועי בריא',
      h1: 'תכנון תפריט שבועי שמסתיים ברשימת קניות',
      intro: [
        'תכנון ארוחות נכשל כשהוא גיליון נפרד. ב-EasyPlate התפריט בנוי מהמתכונים שלכם: גוררים אחד לארוחת ערב של יום שלישי, והמצרכים כבר ברשימת הקניות, הערכים התזונתיים כבר בלוח השבועי, ומצב בישול במרחק לחיצה כשיום שלישי מגיע.',
        'התפריט משותף עם מי שמבשל איתכם. משנים את יום חמישי ובן או בת הזוג רואים מיד. תפריטים אפשר לשמור ולהשתמש בהם שוב, כך ששבוע טוב הופך לתבנית ולא לזיכרון.',
      ],
      sections: [
        { h2: 'מתכננים עם מתכונים שבאמת יש לכם', p: 'כל מתכון בספרים שלכם יכול לעלות לתפריט, כולל אלה שזה עתה שמרתם מטיקטוק או מבלוג:', bullets: ['ארוחת בוקר, צהריים, ערב ונשנושים לכל יום בשבוע.', 'גוררים מתכון ליום; משנים מנות לפי מספר הסועדים.', 'מבקשים רעיונות מהעוזר המובנה: "תכנן ארבע ארוחות ערב צמחוניות וזולות מהספרים שלי".', 'משתמשים שוב בתפריט בשבוע הבא או משתפים אותו כתפריט מוכן.'] },
        { h2: 'רשימת הקניות והערכים התזונתיים מגיעים בחינם', p: 'התפריט הוא המקור של רשימת הקניות ושל לוח התזונה. לעולם לא מעתיקים מצרכים, ולעולם לא מסכמים קלוריות ביד.', bullets: ['רשימת קניות אחת לכל השבוע, מאוחדת ומסודרת לפי מחלקות.', 'קלוריות, חלבון, פחמימות ושומן למנה בכל ארוחה מתוכננת.', 'לוח שבועי שמסכם את התפריט, כך שרואים את השבוע לפני שאוכלים אותו.', 'עלות משוערת של השבוע מהיסטוריית הקבלות שלכם.'] },
        { h2: 'משותף עם כל הבית', p: 'משתפים תפריט עם חשבון אחר כצופה או כעורך. כל עריכה מגיעה לטלפון השני בזמן אמת, והתפריט המשותף ממשיך לעבוד כשמוסיפים לו מתכונים. זו הדרך הפשוטה ביותר לסיים את שיחת "מה אוכלים" של כל ערב.', bullets: ['סנכרון בזמן אמת בין בני המשפחה.', 'הרשאת צפייה או עריכה לכל אדם.', 'עובד בלי אינטרנט: התפריט נפתח במטבח גם בלי קליטה.', 'חמש שפות; החלפת שפה מתרגמת גם את התפריטים והמתכונים.'] },
      ],
      steps: [
        { t: 'אוספים מתכונים', d: 'שומרים מתכונים מקישורים, טקסט, הקלטה או PDF, או כותבים משלכם. כל אחד מקבל ערכים תזונתיים למנה אוטומטית.' },
        { t: 'ממלאים את השבוע', d: 'גוררים מתכונים לימי השבוע. רשימת הקניות וסיכום התזונה השבועי נבנים לבד.' },
        { t: 'קונים פעם אחת, מבשלים כל יום', d: 'עוברים בחנות עם רשימה מסודרת לפי מחלקות, ובכל ערב פותחים מצב בישול לשלבים וטיימרים בלי ידיים.' },
      ],
      faq: [
        { q: 'התכנון יוצר את רשימת הקניות אוטומטית?', a: 'כן. כל מתכון בתפריט מוסיף את המצרכים שלו; כפילויות מתאחדות והרשימה מסודרת לפי מחלקות בסופר.' },
        { q: 'אפשר לראות קלוריות לכל השבוע?', a: 'כן. לכל מתכון יש קלוריות, חלבון, פחמימות ושומן משוערים למנה, והלוח מסכם את הארוחות המתוכננות לאורך השבוע.' },
        { q: 'אפשר לתכנן למספר סועדים שונה?', a: 'כן. משנים את מספר המנות של כל מתכון מתוכנן, והכמויות ורשימת הקניות מתעדכנות.' },
        { q: 'בן או בת הזוג יכולים לערוך את התפריט?', a: 'כן. משתפים את התפריט בהרשאת עריכה והשינויים מסתנכרנים בזמן אמת בשני הטלפונים.' },
        { q: 'תכנון התפריט חינמי?', a: 'כן. התפריט השבועי, רשימת הקניות ולוח התזונה כלולים בחשבון החינמי. Pro מסיר את מכסת ה-AI היומית ואת הפרסומות.' },
      ],
      cta: { title: 'מתכננים את השבוע פעם אחת. מבשלים כל השבוע.', sub: 'הורידו את EasyPlate ובנו תפריט ראשון ממתכונים שאתם כבר אוהבים.' },
    },
    ar: {
      title: 'تخطيط وجبات أسبوعي مع قائمة تسوّق | EasyPlate',
      description: 'اسحب الوصفات إلى أيام الأسبوع واحصل تلقائيًا على قائمة التسوّق والسعرات والبروتين والكربوهيدرات والدهون لكل حصة. شارك الخطة مع العائلة.',
      keywords: 'تطبيق تخطيط الوجبات, خطة وجبات أسبوعية, تخطيط الوجبات الأسبوعي, قائمة الطعام الأسبوعية, منظم الوجبات, خطة وجبات مع قائمة تسوق, تخطيط وجبات العائلة, خطة وجبات بالسعرات',
      h1: 'مخطِّط وجبات أسبوعي ينتهي بقائمة تسوّق',
      intro: [
        'يفشل تخطيط الوجبات عندما يكون جدولًا منفصلًا. في EasyPlate تتكوّن الخطة من وصفاتك أنت: اسحب واحدة إلى عشاء الثلاثاء، فتكون المكوّنات في قائمة التسوّق، والقيم الغذائية في اللوحة الأسبوعية، ووضع الطبخ على بُعد نقرة عندما يأتي الثلاثاء.',
        'الخطة مشتركة مع كل من يطبخ معك. غيّر الخميس ويراه شريكك فورًا. يمكن حفظ الخطط وإعادة استخدامها، فيصبح الأسبوع الجيد قالبًا لا ذكرى.',
      ],
      sections: [
        { h2: 'خطّط بوصفات تملكها فعلًا', p: 'كل وصفة في كتبك يمكن أن تدخل الخطة، بما فيها التي حفظتها للتو من تيك توك أو مدوّنة:', bullets: ['فطور وغداء وعشاء ووجبات خفيفة لكل يوم من الأسبوع.', 'اسحب وصفة إلى يوم؛ عدّل الحصص حسب عدد الآكلين.', 'اطلب أفكارًا من المساعد المدمج: "خطّط أربعة عشاءات نباتية رخيصة من كتبي".', 'أعد استخدام الخطة الأسبوع القادم أو شاركها كقائمة جاهزة.'] },
        { h2: 'قائمة التسوّق والقيم الغذائية تأتي مجانًا', p: 'الخطة هي مصدر قائمة التسوّق ولوحة التغذية. لا تنسخ مكوّنات أبدًا، ولا تجمع السعرات يدويًا أبدًا.', bullets: ['قائمة تسوّق واحدة للأسبوع كله، مدمجة ومرتّبة حسب الأقسام.', 'سعرات وبروتين وكربوهيدرات ودهون لكل حصة في كل وجبة مخطَّطة.', 'لوحة أسبوعية تجمع الخطة، فترى الأسبوع قبل أن تأكله.', 'تكلفة تقديرية للأسبوع من سجلّ فواتيرك.'] },
        { h2: 'مشتركة مع أهل البيت', p: 'شارك خطة مع حساب آخر كمشاهد أو محرّر. يصل كل تعديل إلى الهاتف الآخر فورًا، وتستمر الخطة المشتركة في العمل مع إضافة وصفات إليها. إنها أبسط طريقة لإنهاء حوار "ماذا نأكل" كل مساء.', bullets: ['مزامنة فورية بين أفراد العائلة.', 'صلاحية مشاهدة أو تحرير لكل شخص.', 'يعمل دون إنترنت: تُفتح الخطة في المطبخ بلا إشارة.', 'خمس لغات؛ تغيير اللغة يترجم خططك ووصفاتك أيضًا.'] },
      ],
      steps: [
        { t: 'اجمع الوصفات', d: 'احفظ وصفات من روابط أو نص أو صوت أو PDF، أو اكتب وصفاتك. تحصل كل واحدة على قيم غذائية لكل حصة تلقائيًا.' },
        { t: 'املأ الأسبوع', d: 'اسحب الوصفات إلى أيام الأسبوع. تُبنى قائمة التسوّق ومجموع التغذية الأسبوعي تلقائيًا.' },
        { t: 'تسوّق مرة، واطبخ يوميًا', d: 'امشِ في المتجر بقائمة مرتّبة حسب الأقسام، ثم افتح وضع الطبخ كل مساء لخطوات ومؤقّتات دون لمس الهاتف.' },
      ],
      faq: [
        { q: 'هل ينشئ مخطِّط الوجبات قائمة التسوّق تلقائيًا؟', a: 'نعم. كل وصفة في الخطة تضيف مكوّناتها؛ تُدمج المكررات وتُرتَّب القائمة حسب أقسام المتجر.' },
        { q: 'هل يمكنني رؤية السعرات للأسبوع كله؟', a: 'نعم. لكل وصفة سعرات وبروتين وكربوهيدرات ودهون تقديرية لكل حصة، وتجمع اللوحة الوجبات المخطَّطة عبر الأسبوع.' },
        { q: 'هل يمكن التخطيط لعدد مختلف من الأشخاص؟', a: 'نعم. عدّل حصص أي وصفة مخطَّطة فتتبعها الكميات وقائمة التسوّق.' },
        { q: 'هل يستطيع شريكي تعديل الخطة؟', a: 'نعم. شارك الخطة بصلاحية تحرير وتتزامن التغييرات فورًا على الهاتفين.' },
        { q: 'هل مخطِّط الوجبات مجاني؟', a: 'نعم. الخطة الأسبوعية وقائمة التسوّق ولوحة التغذية مشمولة في الحساب المجاني. يزيل Pro حد الذكاء الاصطناعي اليومي والإعلانات.' },
      ],
      cta: { title: 'خطّط الأسبوع مرة. اطبخ طوال الأسبوع.', sub: 'حمّل EasyPlate وابنِ خطتك الأولى من وصفات تحبها بالفعل.' },
    },
    fr: {
      title: 'Menu de la semaine avec liste de courses | EasyPlate',
      description: 'Glissez des recettes sur les jours de la semaine et obtenez la liste de courses et les calories, protéines, glucides et lipides par portion. Partagez le menu.',
      keywords: 'planificateur de repas, menu de la semaine, application planning repas, planning repas hebdomadaire, menu hebdomadaire famille, batch cooking planning, menu avec liste de courses, planificateur de repas calories',
      h1: 'Un menu de la semaine qui se termine par une liste de courses',
      intro: [
        'La planification des repas échoue quand c’est un tableur à part. Dans EasyPlate, le menu est fait de vos propres recettes : glissez-en une sur le dîner de mardi et les ingrédients sont déjà sur la liste de courses, la nutrition déjà dans le tableau de la semaine, et le mode cuisson à un geste quand mardi arrive.',
        'Le menu est partagé avec ceux qui cuisinent avec vous. Changez le jeudi et votre conjoint le voit immédiatement. Les menus se sauvegardent et se réutilisent : une bonne semaine devient un modèle plutôt qu’un souvenir.',
      ],
      sections: [
        { h2: 'Planifiez avec les recettes que vous avez vraiment', p: 'Toute recette de vos livres peut rejoindre le menu, y compris celles que vous venez d’enregistrer depuis TikTok ou un blog :', bullets: ['Petit-déjeuner, déjeuner, dîner et collations pour chaque jour.', 'Glissez une recette sur un jour ; ajustez les portions au nombre de convives.', 'Demandez des idées à l’assistant intégré : « planifie quatre dîners végétariens pas chers depuis mes livres ».', 'Réutilisez un menu la semaine suivante ou partagez-le comme menu prêt à l’emploi.'] },
        { h2: 'La liste de courses et les macros sont incluses', p: 'Le menu est la source de la liste de courses et du tableau nutritionnel. Vous ne recopiez jamais d’ingrédients et n’additionnez jamais de calories à la main.', bullets: ['Une liste de courses pour toute la semaine, fusionnée et regroupée par rayon.', 'Calories, protéines, glucides et lipides par portion sur chaque repas planifié.', 'Un tableau hebdomadaire qui additionne le menu : vous voyez la semaine avant de la manger.', 'Coût estimé de la semaine d’après votre historique de tickets.'] },
        { h2: 'Partagé avec le foyer', p: 'Partagez un menu avec un autre compte en lecture ou en édition. Chaque modification arrive sur l’autre téléphone en temps réel, et le menu partagé continue de fonctionner à mesure qu’on y ajoute des recettes. C’est le moyen le plus simple d’en finir avec le « qu’est-ce qu’on mange » du soir.', bullets: ['Synchronisation en temps réel entre les membres de la famille.', 'Accès lecture ou édition par personne.', 'Hors ligne d’abord : le menu s’ouvre en cuisine sans réseau.', 'Cinq langues ; changer de langue traduit aussi vos menus et recettes.'] },
      ],
      steps: [
        { t: 'Rassemblez des recettes', d: 'Enregistrez des recettes depuis des liens, du texte, une note vocale ou un PDF, ou écrivez les vôtres. Chacune reçoit automatiquement sa nutrition par portion.' },
        { t: 'Remplissez la semaine', d: 'Glissez des recettes sur les jours de la semaine. La liste de courses et le total nutritionnel hebdomadaire se construisent seuls.' },
        { t: 'Courses une fois, cuisine chaque jour', d: 'Parcourez le magasin avec la liste par rayon, puis ouvrez le mode cuisson chaque soir pour des étapes et minuteurs mains libres.' },
      ],
      faq: [
        { q: 'Le planificateur crée-t-il la liste de courses automatiquement ?', a: 'Oui. Chaque recette du menu ajoute ses ingrédients ; les doublons sont fusionnés et la liste est regroupée par rayon.' },
        { q: 'Puis-je voir les calories de toute la semaine ?', a: 'Oui. Chaque recette a des calories, protéines, glucides et lipides estimés par portion, et le tableau additionne les repas planifiés sur la semaine.' },
        { q: 'Puis-je planifier pour un autre nombre de personnes ?', a: 'Oui. Ajustez les portions de n’importe quelle recette planifiée : les quantités et la liste de courses suivent.' },
        { q: 'Mon conjoint peut-il modifier le menu ?', a: 'Oui. Partagez le menu en édition et les changements se synchronisent en temps réel sur les deux téléphones.' },
        { q: 'Le planificateur de repas est-il gratuit ?', a: 'Oui. Le menu de la semaine, la liste de courses et le tableau nutritionnel sont inclus dans le compte gratuit. Pro supprime la limite quotidienne d’IA et les publicités.' },
      ],
      cta: { title: 'Planifiez la semaine une fois. Cuisinez toute la semaine.', sub: 'Téléchargez EasyPlate et créez votre premier menu avec des recettes que vous aimez déjà.' },
    },
    ru: {
      title: 'Меню на неделю со списком покупок | EasyPlate',
      description: 'Перетаскивайте рецепты на дни недели и автоматически получайте список покупок и калории, белки, углеводы и жиры на порцию. Делитесь меню с семьёй.',
      keywords: 'планировщик питания, меню на неделю, приложение планирование меню, планирование питания на неделю, семейное меню на неделю, меню со списком покупок, планировщик меню калории, план питания',
      h1: 'Планировщик меню на неделю, который заканчивается списком покупок',
      intro: [
        'Планирование питания проваливается, когда это отдельная таблица. В EasyPlate план состоит из ваших собственных рецептов: перетащите один на ужин вторника, и ингредиенты уже в списке покупок, КБЖУ уже в недельной панели, а режим готовки в одном касании, когда вторник наступит.',
        'План общий с теми, кто готовит вместе с вами. Измените четверг, и партнёр увидит это сразу. Планы можно сохранять и использовать снова, так что удачная неделя становится шаблоном, а не воспоминанием.',
      ],
      sections: [
        { h2: 'Планируйте с рецептами, которые у вас действительно есть', p: 'Любой рецепт из ваших книг может попасть в план, включая только что сохранённые из TikTok или блога:', bullets: ['Завтрак, обед, ужин и перекусы на каждый день недели.', 'Перетащите рецепт на день; подстройте порции под число едоков.', 'Попросите идеи у встроенного помощника: «спланируй четыре недорогих вегетарианских ужина из моих книг».', 'Используйте план снова на следующей неделе или поделитесь им как готовым меню.'] },
        { h2: 'Список покупок и КБЖУ достаются бесплатно', p: 'План — источник списка покупок и панели питания. Вы никогда не копируете ингредиенты и не считаете калории вручную.', bullets: ['Один список покупок на всю неделю, объединённый и сгруппированный по отделам.', 'Калории, белки, углеводы и жиры на порцию для каждого запланированного блюда.', 'Недельная панель, суммирующая план: вы видите неделю до того, как её съедите.', 'Ориентировочная стоимость недели по вашей истории чеков.'] },
        { h2: 'Общий для всей семьи', p: 'Поделитесь планом с другим аккаунтом в режиме просмотра или редактирования. Каждая правка доходит до другого телефона в реальном времени, а общий план продолжает работать по мере добавления рецептов. Это самый простой способ закончить вечерний разговор «что мы едим».', bullets: ['Синхронизация в реальном времени между членами семьи.', 'Доступ на просмотр или редактирование для каждого.', 'Работает офлайн: план открывается на кухне без сигнала.', 'Пять языков; смена языка переводит и ваши планы с рецептами.'] },
      ],
      steps: [
        { t: 'Соберите рецепты', d: 'Сохраняйте рецепты из ссылок, текста, голоса или PDF либо пишите свои. Каждый автоматически получает КБЖУ на порцию.' },
        { t: 'Заполните неделю', d: 'Перетащите рецепты на дни недели. Список покупок и недельный итог питания соберутся сами.' },
        { t: 'Купите раз, готовьте каждый день', d: 'Пройдите магазин со списком по отделам, а по вечерам открывайте режим готовки с шагами и таймерами без рук.' },
      ],
      faq: [
        { q: 'Планировщик создаёт список покупок автоматически?', a: 'Да. Каждый рецепт в плане добавляет свои ингредиенты; повторы объединяются, а список группируется по отделам магазина.' },
        { q: 'Можно ли увидеть калории за всю неделю?', a: 'Да. У каждого рецепта есть примерные калории, белки, углеводы и жиры на порцию, а панель суммирует запланированные блюда за неделю.' },
        { q: 'Можно ли планировать на другое число людей?', a: 'Да. Измените порции любого запланированного рецепта, и количества вместе со списком покупок подстроятся.' },
        { q: 'Может ли партнёр редактировать план?', a: 'Да. Поделитесь планом с правом редактирования, и изменения синхронизируются в реальном времени на обоих телефонах.' },
        { q: 'Планировщик бесплатный?', a: 'Да. Меню на неделю, список покупок и панель питания входят в бесплатный аккаунт. Pro снимает дневной лимит ИИ и рекламу.' },
      ],
      cta: { title: 'Спланируйте неделю один раз. Готовьте всю неделю.', sub: 'Скачайте EasyPlate и соберите первый план из рецептов, которые уже любите.' },
    },
  },

  // ------------------------------------------------------------------ D
  'save-tiktok-recipes': {
    icon: 'sparkles', screens: ['03_ai_import', '02_recipe_details'],
    en: {
      title: 'Save TikTok Recipes as Real Recipes | EasyPlate',
      description: 'Share a TikTok, Reel or YouTube video to EasyPlate: the AI watches it, reads the caption and returns a recipe with ingredients, amounts, steps and nutrition.',
      keywords: 'save recipes from TikTok, TikTok recipe saver, save Instagram recipes, Instagram reel recipe, YouTube recipe extractor, video to recipe, TikTok recipes app, how to save a recipe from TikTok, recipe from video AI',
      h1: 'How to save a recipe from TikTok, Instagram or YouTube',
      intro: [
        'A recipe in a 40-second video is easy to like and hard to cook from. The amounts are said out loud, the steps fly past, and a week later the video is gone from your feed. EasyPlate turns that video into a real recipe: the AI watches the clip, reads the caption and on-screen text, and returns ingredients with amounts, numbered steps, servings, tags and estimated nutrition.',
        'It works the same way for TikTok, Instagram posts and Reels, YouTube and Shorts, Facebook videos and any recipe website. Below is the full flow, the cases where it needs a little help, and what happens after the recipe is saved.',
      ],
      sections: [
        { h2: 'Three ways to send a video to EasyPlate', p: 'Pick whichever is fastest in the moment:', bullets: ['Share sheet: tap Share in TikTok, Instagram or YouTube and choose EasyPlate. The recipe starts extracting immediately.', 'Paste the link: copy the video URL and paste it into the search line in the app.', 'Paste the caption: for a private account or a video that cannot be fetched, paste the caption text and EasyPlate builds the recipe from that.'] },
        { h2: 'What the AI actually does', p: 'EasyPlate does not just copy the caption. It analyses the video frames and audio, reads the caption and any on-screen text, and merges them into one structured recipe. Amounts that were only spoken end up in the ingredient list; steps that were only shown end up as numbered instructions.', bullets: ['Ingredients with amounts and units, in your language.', 'Numbered steps, servings, cooking time and tags.', 'Calories, protein, carbs and fat per serving, estimated from the ingredients.', 'The source link stays attached, so the creator is one tap away.', 'Everything is editable before and after saving.'] },
        { h2: 'After the video: plan, shop, cook', p: 'A saved recipe is not a bookmark. Put it on the weekly plan, and its ingredients join the grocery list, grouped by aisle. Share the book with your family. When it is time to cook, Cook Mode shows one big step at a time with timers that keep running when the screen locks.', bullets: ['Weekly meal plan with automatic grocery list.', 'Shared cookbooks with real-time editing.', 'Hands-free Cook Mode with background timers.', 'Offline-first: the recipe opens in the kitchen with no signal.'] },
      ],
      steps: [
        { t: 'Find a recipe video', d: 'On TikTok, Instagram, YouTube or Facebook, tap Share and choose EasyPlate, or copy the link.' },
        { t: 'Let the AI watch it', d: 'EasyPlate analyses the video and the caption and returns a structured recipe in seconds. Check the amounts and save it to a book.' },
        { t: 'Cook it this week', d: 'Drop it on the plan, shop with the aisle-grouped list, and cook with hands-free steps and timers.' },
      ],
      faq: [
        { q: 'Does it work with private Instagram accounts?', a: 'A private video cannot be fetched by link. Paste the caption text instead and EasyPlate builds the recipe from it; if the caption is missing, describe the dish and the AI writes a recipe you can adjust.' },
        { q: 'Which platforms are supported?', a: 'TikTok, Instagram posts and Reels, YouTube and Shorts, Facebook videos and posts, and any recipe website. Pasted text, voice notes and PDF files work too.' },
        { q: 'Are the amounts accurate?', a: 'The AI takes amounts from the audio, the caption and the on-screen text. When a video never states an amount, it estimates one and you can correct it before saving.' },
        { q: 'Is there a limit?', a: 'A free account has a daily allowance of AI extractions, which a short video can extend. Pro removes the limit for ₪20 a month.' },
        { q: 'Does EasyPlate keep the video?', a: 'No. It keeps the recipe it extracted and the link to the original, so the creator is always credited and reachable.' },
      ],
      cta: { title: 'The next recipe you like is already a recipe.', sub: 'Download EasyPlate and share your first video to it.' },
    },
    he: {
      title: 'איך שומרים מתכון מטיקטוק כמתכון אמיתי | EasyPlate',
      description: 'משתפים סרטון מטיקטוק, ריל או יוטיוב ל-EasyPlate: ה-AI צופה בו, קורא את הכיתוב ומחזיר מתכון עם מצרכים, כמויות, שלבים וערכים תזונתיים. חינם.',
      keywords: 'מתכונים מטיקטוק, שמירת מתכון מטיקטוק, מתכונים מאינסטגרם, מתכון מריל, מתכונים מיוטיוב, סרטון למתכון, אפליקציה למתכונים מטיקטוק, איך שומרים מתכון מטיקטוק, מתכון מסרטון AI',
      h1: 'איך שומרים מתכון מטיקטוק, אינסטגרם או יוטיוב',
      intro: [
        'מתכון בסרטון של 40 שניות קל לאהוב וקשה לבשל ממנו. הכמויות נאמרות בקול, השלבים חולפים, ושבוע אחר כך הסרטון נעלם מהפיד. EasyPlate הופכת את הסרטון הזה למתכון אמיתי: ה-AI צופה בקליפ, קורא את הכיתוב ואת הטקסט שעל המסך, ומחזיר מצרכים עם כמויות, שלבים ממוספרים, מנות, תגיות וערכים תזונתיים משוערים.',
        'זה עובד אותו דבר לטיקטוק, פוסטים ורילס באינסטגרם, יוטיוב ושורטס, סרטוני פייסבוק וכל אתר מתכונים. למטה התהליך המלא, המקרים שבהם צריך קצת עזרה, ומה קורה אחרי שהמתכון נשמר.',
      ],
      sections: [
        { h2: 'שלוש דרכים לשלוח סרטון ל-EasyPlate', p: 'בוחרים את מה שהכי מהיר ברגע:', bullets: ['גיליון שיתוף: לוחצים על שיתוף בטיקטוק, באינסטגרם או ביוטיוב ובוחרים EasyPlate. החילוץ מתחיל מיד.', 'מדביקים קישור: מעתיקים את כתובת הסרטון ומדביקים בשורת החיפוש באפליקציה.', 'מדביקים את הכיתוב: לחשבון פרטי או לסרטון שאי אפשר למשוך, מדביקים את טקסט הכיתוב ו-EasyPlate בונה ממנו את המתכון.'] },
        { h2: 'מה ה-AI עושה בפועל', p: 'EasyPlate לא רק מעתיקה את הכיתוב. היא מנתחת את הפריימים והשמע של הסרטון, קוראת את הכיתוב ואת הטקסט שעל המסך, וממזגת הכול למתכון מובנה אחד. כמויות שרק נאמרו נכנסות לרשימת המצרכים; שלבים שרק הוצגו הופכים להוראות ממוספרות.', bullets: ['מצרכים עם כמויות ויחידות, בשפה שלכם.', 'שלבים ממוספרים, מנות, זמן הכנה ותגיות.', 'קלוריות, חלבון, פחמימות ושומן למנה, משוערים מהמצרכים.', 'קישור המקור נשאר מצורף, כך שהיוצר במרחק לחיצה.', 'הכול ניתן לעריכה לפני השמירה ואחריה.'] },
        { h2: 'אחרי הסרטון: מתכננים, קונים, מבשלים', p: 'מתכון שמור הוא לא סימנייה. שמים אותו בתפריט השבועי, והמצרכים שלו מצטרפים לרשימת הקניות, מסודרים לפי מחלקות. משתפים את הספר עם המשפחה. כשמגיע הזמן לבשל, מצב בישול מציג שלב גדול אחד בכל פעם עם טיימרים שממשיכים לרוץ כשהמסך נעול.', bullets: ['תפריט שבועי עם רשימת קניות אוטומטית.', 'ספרי מתכונים משותפים עם עריכה בזמן אמת.', 'מצב בישול בלי ידיים עם טיימרים ברקע.', 'עובד בלי אינטרנט: המתכון נפתח במטבח גם בלי קליטה.'] },
      ],
      steps: [
        { t: 'מוצאים סרטון מתכון', d: 'בטיקטוק, אינסטגרם, יוטיוב או פייסבוק לוחצים על שיתוף ובוחרים EasyPlate, או מעתיקים את הקישור.' },
        { t: 'נותנים ל-AI לצפות', d: 'EasyPlate מנתחת את הסרטון והכיתוב ומחזירה מתכון מובנה תוך שניות. בודקים את הכמויות ושומרים לספר.' },
        { t: 'מבשלים השבוע', d: 'גוררים לתפריט, קונים עם רשימה לפי מחלקות, ומבשלים עם שלבים וטיימרים בלי ידיים.' },
      ],
      faq: [
        { q: 'זה עובד עם חשבונות אינסטגרם פרטיים?', a: 'סרטון פרטי אי אפשר למשוך לפי קישור. במקום זה מדביקים את טקסט הכיתוב ו-EasyPlate בונה ממנו את המתכון; אם אין כיתוב, מתארים את המנה וה-AI כותב מתכון שאפשר להתאים.' },
        { q: 'אילו פלטפורמות נתמכות?', a: 'טיקטוק, פוסטים ורילס באינסטגרם, יוטיוב ושורטס, סרטונים ופוסטים בפייסבוק, וכל אתר מתכונים. גם טקסט מודבק, הקלטות קוליות וקובצי PDF.' },
        { q: 'הכמויות מדויקות?', a: 'ה-AI לוקח כמויות מהשמע, מהכיתוב ומהטקסט שעל המסך. כשסרטון לא מציין כמות בכלל, הוא מעריך אחת ואפשר לתקן לפני השמירה.' },
        { q: 'יש מגבלה?', a: 'לחשבון חינמי יש מכסה יומית של חילוצי AI, שסרטון קצר יכול להרחיב. Pro מסיר את המגבלה ב-20 ₪ לחודש.' },
        { q: 'EasyPlate שומרת את הסרטון?', a: 'לא. היא שומרת את המתכון שחולץ ואת הקישור למקור, כך שהיוצר תמיד מקבל קרדיט ונגיש.' },
      ],
      cta: { title: 'המתכון הבא שתאהבו כבר מתכון.', sub: 'הורידו את EasyPlate ושתפו אליה את הסרטון הראשון.' },
    },
    ar: {
      title: 'احفظ وصفات تيك توك كوصفات حقيقية | EasyPlate',
      description: 'شارك فيديو تيك توك أو ريل أو يوتيوب مع EasyPlate: يشاهده الذكاء الاصطناعي ويقرأ التعليق ويعيد وصفة بالمكوّنات والكميات والخطوات والقيم الغذائية.',
      keywords: 'حفظ وصفات تيك توك, وصفات تيك توك, حفظ وصفات إنستغرام, وصفة من ريل, وصفات يوتيوب, تحويل فيديو إلى وصفة, تطبيق وصفات تيك توك, كيف أحفظ وصفة من تيك توك, وصفة من فيديو بالذكاء الاصطناعي',
      h1: 'كيف تحفظ وصفة من تيك توك أو إنستغرام أو يوتيوب',
      intro: [
        'الوصفة في فيديو من 40 ثانية سهلة الإعجاب وصعبة الطبخ. تُقال الكميات شفهيًا، وتمرّ الخطوات بسرعة، وبعد أسبوع يختفي الفيديو من صفحتك. يحوّل EasyPlate ذلك الفيديو إلى وصفة حقيقية: يشاهد الذكاء الاصطناعي المقطع، ويقرأ التعليق والنص على الشاشة، ويعيد مكوّنات بكمياتها، وخطوات مرقّمة، وحصصًا، ووسومًا، وقيمًا غذائية تقديرية.',
        'يعمل بالطريقة نفسها مع تيك توك، ومنشورات وريلز إنستغرام، ويوتيوب وشورتس، وفيديوهات فيسبوك، وأي موقع وصفات. فيما يلي المسار الكامل، والحالات التي تحتاج إلى مساعدة بسيطة، وما يحدث بعد حفظ الوصفة.',
      ],
      sections: [
        { h2: 'ثلاث طرق لإرسال فيديو إلى EasyPlate', p: 'اختر الأسرع في اللحظة:', bullets: ['ورقة المشاركة: اضغط مشاركة في تيك توك أو إنستغرام أو يوتيوب واختر EasyPlate. يبدأ الاستخراج فورًا.', 'الصق الرابط: انسخ عنوان الفيديو والصقه في سطر البحث داخل التطبيق.', 'الصق التعليق: لحساب خاص أو فيديو لا يمكن جلبه، الصق نص التعليق ويبني EasyPlate الوصفة منه.'] },
        { h2: 'ما يفعله الذكاء الاصطناعي فعلًا', p: 'لا يكتفي EasyPlate بنسخ التعليق. يحلّل إطارات الفيديو والصوت، ويقرأ التعليق وأي نص على الشاشة، ويدمجها في وصفة منظمة واحدة. الكميات التي قيلت شفهيًا فقط تدخل قائمة المكوّنات؛ والخطوات التي عُرضت فقط تصبح تعليمات مرقّمة.', bullets: ['مكوّنات بكميات ووحدات، بلغتك.', 'خطوات مرقّمة وحصص ووقت طبخ ووسوم.', 'سعرات وبروتين وكربوهيدرات ودهون لكل حصة، مقدَّرة من المكوّنات.', 'يبقى رابط المصدر مرفقًا، فيكون صانع المحتوى على بُعد نقرة.', 'كل شيء قابل للتعديل قبل الحفظ وبعده.'] },
        { h2: 'بعد الفيديو: خطّط وتسوّق واطبخ', p: 'الوصفة المحفوظة ليست إشارة مرجعية. ضعها في الخطة الأسبوعية فتنضم مكوّناتها إلى قائمة التسوّق مرتّبة حسب الأقسام. شارك الكتاب مع عائلتك. وعندما يحين وقت الطبخ، يعرض وضع الطبخ خطوة كبيرة واحدة في كل مرة مع مؤقّتات تستمر عند قفل الشاشة.', bullets: ['خطة وجبات أسبوعية مع قائمة تسوّق تلقائية.', 'كتب طبخ مشتركة مع تحرير فوري.', 'وضع طبخ دون لمس الهاتف مع مؤقّتات في الخلفية.', 'يعمل دون إنترنت: تُفتح الوصفة في المطبخ بلا إشارة.'] },
      ],
      steps: [
        { t: 'اعثر على فيديو وصفة', d: 'في تيك توك أو إنستغرام أو يوتيوب أو فيسبوك، اضغط مشاركة واختر EasyPlate، أو انسخ الرابط.' },
        { t: 'دع الذكاء الاصطناعي يشاهده', d: 'يحلّل EasyPlate الفيديو والتعليق ويعيد وصفة منظمة في ثوانٍ. راجع الكميات واحفظها في كتاب.' },
        { t: 'اطبخها هذا الأسبوع', d: 'ضعها في الخطة، وتسوّق بالقائمة المرتّبة حسب الأقسام، واطبخ بخطوات ومؤقّتات دون لمس الهاتف.' },
      ],
      faq: [
        { q: 'هل يعمل مع حسابات إنستغرام الخاصة؟', a: 'لا يمكن جلب الفيديو الخاص بالرابط. الصق نص التعليق بدلًا من ذلك فيبني EasyPlate الوصفة منه؛ وإن غاب التعليق، صِف الطبق فيكتب الذكاء الاصطناعي وصفة يمكنك تعديلها.' },
        { q: 'ما المنصات المدعومة؟', a: 'تيك توك، ومنشورات وريلز إنستغرام، ويوتيوب وشورتس، وفيديوهات ومنشورات فيسبوك، وأي موقع وصفات. ويعمل أيضًا النص الملصوق والرسائل الصوتية وملفات PDF.' },
        { q: 'هل الكميات دقيقة؟', a: 'يأخذ الذكاء الاصطناعي الكميات من الصوت والتعليق والنص على الشاشة. وعندما لا يذكر الفيديو كمية أصلًا، يقدّر واحدة ويمكنك تصحيحها قبل الحفظ.' },
        { q: 'هل هناك حد؟', a: 'للحساب المجاني حصة يومية من استخراجات الذكاء الاصطناعي، يمكن لفيديو قصير أن يزيدها. يزيل Pro الحد مقابل 20 شيكل شهريًا.' },
        { q: 'هل يحتفظ EasyPlate بالفيديو؟', a: 'لا. يحتفظ بالوصفة المستخرجة وبرابط الأصل، فيبقى صانع المحتوى منسوبًا إليه ويمكن الوصول إليه دائمًا.' },
      ],
      cta: { title: 'الوصفة التالية التي ستعجبك هي وصفة بالفعل.', sub: 'حمّل EasyPlate وشارك أول فيديو معه.' },
    },
    fr: {
      title: 'Enregistrer une recette TikTok en vraie recette | EasyPlate',
      description: 'Partagez une vidéo TikTok, un Reel ou YouTube vers EasyPlate : l’IA la regarde, lit la légende et renvoie une recette avec ingrédients, quantités et étapes.',
      keywords: 'enregistrer recette TikTok, recettes TikTok, enregistrer recettes Instagram, recette depuis un reel, recettes YouTube, vidéo en recette, application recettes TikTok, comment sauvegarder une recette TikTok, recette depuis vidéo IA',
      h1: 'Comment enregistrer une recette depuis TikTok, Instagram ou YouTube',
      intro: [
        'Une recette dans une vidéo de 40 secondes est facile à aimer et difficile à cuisiner. Les quantités sont dites à l’oral, les étapes défilent, et une semaine plus tard la vidéo a disparu du fil. EasyPlate transforme cette vidéo en vraie recette : l’IA regarde le clip, lit la légende et le texte à l’écran, et renvoie des ingrédients avec quantités, des étapes numérotées, les portions, des tags et une nutrition estimée.',
        'Cela fonctionne de la même façon pour TikTok, les posts et Reels Instagram, YouTube et Shorts, les vidéos Facebook et tout site de recettes. Voici le déroulé complet, les cas où il faut un petit coup de main, et ce qui se passe une fois la recette enregistrée.',
      ],
      sections: [
        { h2: 'Trois façons d’envoyer une vidéo à EasyPlate', p: 'Choisissez la plus rapide sur le moment :', bullets: ['Feuille de partage : appuyez sur Partager dans TikTok, Instagram ou YouTube et choisissez EasyPlate. L’extraction démarre aussitôt.', 'Coller le lien : copiez l’URL de la vidéo et collez-la dans la barre de recherche de l’app.', 'Coller la légende : pour un compte privé ou une vidéo impossible à récupérer, collez le texte de la légende et EasyPlate construit la recette à partir de là.'] },
        { h2: 'Ce que l’IA fait vraiment', p: 'EasyPlate ne se contente pas de copier la légende. Elle analyse les images et l’audio de la vidéo, lit la légende et le texte à l’écran, et fusionne le tout en une recette structurée. Les quantités seulement dites à l’oral se retrouvent dans la liste d’ingrédients ; les étapes seulement montrées deviennent des instructions numérotées.', bullets: ['Ingrédients avec quantités et unités, dans votre langue.', 'Étapes numérotées, portions, temps de cuisson et tags.', 'Calories, protéines, glucides et lipides par portion, estimés d’après les ingrédients.', 'Le lien source reste attaché : le créateur est à un geste.', 'Tout est modifiable avant et après l’enregistrement.'] },
        { h2: 'Après la vidéo : planifier, acheter, cuisiner', p: 'Une recette enregistrée n’est pas un favori. Placez-la sur le menu de la semaine et ses ingrédients rejoignent la liste de courses, regroupés par rayon. Partagez le livre avec la famille. Au moment de cuisiner, le mode cuisson affiche une grande étape à la fois avec des minuteurs qui continuent écran verrouillé.', bullets: ['Menu de la semaine avec liste de courses automatique.', 'Livres de recettes partagés avec édition en temps réel.', 'Mode cuisson mains libres avec minuteurs en arrière-plan.', 'Hors ligne d’abord : la recette s’ouvre en cuisine sans réseau.'] },
      ],
      steps: [
        { t: 'Trouvez une vidéo de recette', d: 'Sur TikTok, Instagram, YouTube ou Facebook, appuyez sur Partager et choisissez EasyPlate, ou copiez le lien.' },
        { t: 'Laissez l’IA la regarder', d: 'EasyPlate analyse la vidéo et la légende et renvoie une recette structurée en quelques secondes. Vérifiez les quantités et enregistrez-la dans un livre.' },
        { t: 'Cuisinez-la cette semaine', d: 'Déposez-la sur le menu, faites les courses avec la liste par rayon, et cuisinez avec des étapes et minuteurs mains libres.' },
      ],
      faq: [
        { q: 'Est-ce que ça marche avec les comptes Instagram privés ?', a: 'Une vidéo privée ne peut pas être récupérée par lien. Collez plutôt le texte de la légende et EasyPlate en construit la recette ; sans légende, décrivez le plat et l’IA écrit une recette que vous ajustez.' },
        { q: 'Quelles plateformes sont prises en charge ?', a: 'TikTok, posts et Reels Instagram, YouTube et Shorts, vidéos et posts Facebook, et tout site de recettes. Le texte collé, les notes vocales et les PDF fonctionnent aussi.' },
        { q: 'Les quantités sont-elles exactes ?', a: 'L’IA prend les quantités dans l’audio, la légende et le texte à l’écran. Quand une vidéo n’en donne aucune, elle en estime une que vous pouvez corriger avant d’enregistrer.' },
        { q: 'Y a-t-il une limite ?', a: 'Un compte gratuit a un quota quotidien d’extractions par IA, qu’une courte vidéo peut prolonger. Pro supprime la limite pour 20 ₪ par mois.' },
        { q: 'EasyPlate garde-t-il la vidéo ?', a: 'Non. Il garde la recette extraite et le lien vers l’original : le créateur est toujours crédité et joignable.' },
      ],
      cta: { title: 'La prochaine recette que vous aimerez est déjà une recette.', sub: 'Téléchargez EasyPlate et partagez-lui votre première vidéo.' },
    },
    ru: {
      title: 'Сохранить рецепт из TikTok как рецепт | EasyPlate',
      description: 'Поделитесь видео из TikTok, рилсом или YouTube с EasyPlate: ИИ посмотрит его, прочитает подпись и вернёт рецепт с ингредиентами, количествами и шагами.',
      keywords: 'сохранить рецепт из TikTok, рецепты из TikTok, сохранить рецепт из Instagram, рецепт из рилс, рецепты из YouTube, видео в рецепт, приложение рецепты TikTok, как сохранить рецепт из тиктока, рецепт из видео ИИ',
      h1: 'Как сохранить рецепт из TikTok, Instagram или YouTube',
      intro: [
        'Рецепт в 40-секундном видео легко лайкнуть и трудно по нему готовить. Количества называют вслух, шаги мелькают, а через неделю видео исчезает из ленты. EasyPlate превращает это видео в настоящий рецепт: ИИ смотрит ролик, читает подпись и текст на экране и возвращает ингредиенты с количествами, пронумерованные шаги, порции, теги и примерную пищевую ценность.',
        'Это одинаково работает для TikTok, постов и рилсов Instagram, YouTube и Shorts, видео из Facebook и любого сайта с рецептами. Ниже весь путь, случаи, где нужна небольшая помощь, и что происходит после сохранения рецепта.',
      ],
      sections: [
        { h2: 'Три способа отправить видео в EasyPlate', p: 'Выбирайте тот, что быстрее в моменте:', bullets: ['Через «Поделиться»: нажмите Share в TikTok, Instagram или YouTube и выберите EasyPlate. Извлечение начнётся сразу.', 'Вставить ссылку: скопируйте адрес видео и вставьте в строку поиска в приложении.', 'Вставить подпись: для закрытого аккаунта или видео, которое нельзя загрузить, вставьте текст подписи, и EasyPlate соберёт рецепт из него.'] },
        { h2: 'Что на самом деле делает ИИ', p: 'EasyPlate не просто копирует подпись. Он анализирует кадры и звук видео, читает подпись и текст на экране и объединяет всё в один структурированный рецепт. Количества, которые только произнесли, попадают в список ингредиентов; шаги, которые только показали, становятся пронумерованными инструкциями.', bullets: ['Ингредиенты с количествами и единицами, на вашем языке.', 'Пронумерованные шаги, порции, время готовки и теги.', 'Калории, белки, углеводы и жиры на порцию, оценённые по ингредиентам.', 'Ссылка на источник остаётся прикреплённой: автор в одном касании.', 'Всё редактируется до и после сохранения.'] },
        { h2: 'После видео: планируйте, покупайте, готовьте', p: 'Сохранённый рецепт — не закладка. Поставьте его в меню на неделю, и его ингредиенты попадут в список покупок, сгруппированный по отделам. Поделитесь книгой с семьёй. Когда придёт время готовить, режим готовки покажет один крупный шаг за раз с таймерами, которые идут даже при заблокированном экране.', bullets: ['Меню на неделю с автоматическим списком покупок.', 'Общие книги рецептов с редактированием в реальном времени.', 'Режим готовки без рук с фоновыми таймерами.', 'Работает офлайн: рецепт открывается на кухне без сигнала.'] },
      ],
      steps: [
        { t: 'Найдите видео с рецептом', d: 'В TikTok, Instagram, YouTube или Facebook нажмите «Поделиться» и выберите EasyPlate либо скопируйте ссылку.' },
        { t: 'Дайте ИИ посмотреть', d: 'EasyPlate анализирует видео и подпись и за секунды возвращает структурированный рецепт. Проверьте количества и сохраните в книгу.' },
        { t: 'Приготовьте на этой неделе', d: 'Поставьте в план, сходите в магазин со списком по отделам и готовьте с шагами и таймерами без рук.' },
      ],
      faq: [
        { q: 'Работает ли с закрытыми аккаунтами Instagram?', a: 'Закрытое видео нельзя загрузить по ссылке. Вставьте текст подписи, и EasyPlate соберёт рецепт из него; если подписи нет, опишите блюдо, и ИИ напишет рецепт, который вы подправите.' },
        { q: 'Какие платформы поддерживаются?', a: 'TikTok, посты и рилсы Instagram, YouTube и Shorts, видео и посты Facebook и любой сайт с рецептами. Вставленный текст, голосовые заметки и PDF тоже работают.' },
        { q: 'Точны ли количества?', a: 'ИИ берёт количества из звука, подписи и текста на экране. Если в видео количество не названо вовсе, он оценивает его, и вы можете исправить до сохранения.' },
        { q: 'Есть ли лимит?', a: 'У бесплатного аккаунта есть дневной лимит извлечений ИИ, который можно расширить коротким видео. Pro снимает лимит за 20 ₪ в месяц.' },
        { q: 'Хранит ли EasyPlate видео?', a: 'Нет. Он хранит извлечённый рецепт и ссылку на оригинал, так что автор всегда указан и доступен.' },
      ],
      cta: { title: 'Следующий рецепт, который вам понравится, уже рецепт.', sub: 'Скачайте EasyPlate и поделитесь с ним первым видео.' },
    },
  },
};

export const TOPICS = { ...BASE_TOPICS, ...MORE_TOPICS, ...MORE_TOPICS_2, ...MORE_TOPICS_3 };
