// Renders the keyword guide pages (topics.mjs) and the two home-page blocks
// that link to them. Used by build.mjs; nothing here runs on its own.

import { TOPICS, SLUGS, UI } from './topics.mjs';

// Short labels for cards, breadcrumbs and footer links.
export const LABELS = {
  'recipe-app': {
    en: { label: 'Recipe app', blurb: 'Save recipes from anywhere into one searchable cookbook, with nutrition per serving.' },
    he: { label: 'אפליקציית מתכונים', blurb: 'שומרים מתכונים מכל מקום לספר מתכונים אחד עם חיפוש וערכים תזונתיים למנה.' },
    ar: { label: 'تطبيق وصفات', blurb: 'احفظ الوصفات من أي مكان في كتاب طبخ واحد قابل للبحث، مع القيم الغذائية لكل حصة.' },
    fr: { label: 'Application de recettes', blurb: 'Enregistrez des recettes de partout dans un seul livre consultable, avec la nutrition par portion.' },
    ru: { label: 'Приложение рецептов', blurb: 'Сохраняйте рецепты откуда угодно в одну книгу с поиском и КБЖУ на порцию.' },
  },
  'grocery-list-app': {
    en: { label: 'Grocery list app', blurb: 'A shared shopping list that builds itself from the plan, grouped by aisle, with a price estimate.' },
    he: { label: 'רשימת קניות משותפת', blurb: 'רשימת קניות משותפת שנבנית לבד מהתפריט, מסודרת לפי מחלקות, עם הערכת מחיר.' },
    ar: { label: 'قائمة تسوّق مشتركة', blurb: 'قائمة تسوّق مشتركة تُبنى تلقائيًا من الخطة، مرتّبة حسب الأقسام، مع تقدير للسعر.' },
    fr: { label: 'Liste de courses partagée', blurb: 'Une liste de courses partagée qui se construit depuis le menu, par rayon, avec estimation du prix.' },
    ru: { label: 'Общий список покупок', blurb: 'Общий список покупок, который собирается из плана по отделам, с оценкой цены.' },
  },
  'meal-planner': {
    en: { label: 'Weekly meal planner', blurb: 'Drag recipes onto the week and get the grocery list and the macros for free.' },
    he: { label: 'תפריט שבועי', blurb: 'גוררים מתכונים לשבוע ומקבלים רשימת קניות וערכים תזונתיים בחינם.' },
    ar: { label: 'خطة وجبات أسبوعية', blurb: 'اسحب الوصفات إلى الأسبوع واحصل على قائمة التسوّق والقيم الغذائية مجانًا.' },
    fr: { label: 'Menu de la semaine', blurb: 'Glissez des recettes sur la semaine et obtenez la liste de courses et les macros.' },
    ru: { label: 'Меню на неделю', blurb: 'Перетащите рецепты на неделю и получите список покупок и КБЖУ бесплатно.' },
  },
  'save-tiktok-recipes': {
    en: { label: 'Save TikTok recipes', blurb: 'How a TikTok, Reel or YouTube video becomes a recipe with amounts, steps and macros.' },
    he: { label: 'מתכונים מטיקטוק', blurb: 'איך סרטון מטיקטוק, ריל או יוטיוב הופך למתכון עם כמויות, שלבים וערכים תזונתיים.' },
    ar: { label: 'وصفات تيك توك', blurb: 'كيف يتحوّل فيديو تيك توك أو ريل أو يوتيوب إلى وصفة بالكميات والخطوات والقيم الغذائية.' },
    fr: { label: 'Recettes TikTok', blurb: 'Comment une vidéo TikTok, un Reel ou YouTube devient une recette avec quantités, étapes et macros.' },
    ru: { label: 'Рецепты из TikTok', blurb: 'Как видео из TikTok, рилс или YouTube становится рецептом с количествами, шагами и КБЖУ.' },
  },
  'save-instagram-recipes': {
    en: { label: 'Save Instagram recipes', blurb: 'A Reel or a YouTube video becomes a recipe with ingredients, amounts, steps and nutrition.' },
    he: { label: 'מתכונים מאינסטגרם ויוטיוב', blurb: 'ריל או סרטון יוטיוב הופך למתכון עם מצרכים, כמויות, שלבים וערכים תזונתיים.' },
    ar: { label: 'وصفات إنستغرام ويوتيوب', blurb: 'يتحوّل الريل أو فيديو يوتيوب إلى وصفة بالمكوّنات والكميات والخطوات والقيم الغذائية.' },
    fr: { label: 'Recettes Instagram et YouTube', blurb: 'Un Reel ou une vidéo YouTube devient une recette avec ingrédients, quantités, étapes et nutrition.' },
    ru: { label: 'Рецепты из Instagram и YouTube', blurb: 'Рилс или видео YouTube становится рецептом с ингредиентами, количествами, шагами и КБЖУ.' },
  },
  'recipe-calorie-calculator': {
    en: { label: 'Recipe calorie calculator', blurb: 'Calories, protein, carbs and fat per serving for any recipe, and a weekly nutrition dashboard.' },
    he: { label: 'מחשבון קלוריות למתכון', blurb: 'קלוריות, חלבון, פחמימות ושומן למנה לכל מתכון, ולוח תזונה שבועי.' },
    ar: { label: 'حاسبة سعرات الوصفات', blurb: 'سعرات وبروتين وكربوهيدرات ودهون لكل حصة لأي وصفة، ولوحة تغذية أسبوعية.' },
    fr: { label: 'Calculateur de calories', blurb: 'Calories, protéines, glucides et lipides par portion pour toute recette, et un tableau nutrition hebdomadaire.' },
    ru: { label: 'Калькулятор калорий рецепта', blurb: 'Калории, белки, углеводы и жиры на порцию для любого рецепта и недельная панель питания.' },
  },
  'grocery-prices-receipt-scanner': {
    en: { label: 'Prices from receipts', blurb: 'Scan receipts into a price book and see what the grocery list will cost before you shop.' },
    he: { label: 'מחירים מהקבלות', blurb: 'סורקים קבלות לספר מחירים ורואים כמה רשימת הקניות תעלה לפני הקנייה.' },
    ar: { label: 'أسعار من الفواتير', blurb: 'امسح الفواتير إلى دفتر أسعار وشاهد كم ستكلّف قائمة التسوّق قبل الشراء.' },
    fr: { label: 'Prix depuis les tickets', blurb: 'Scannez les tickets dans un carnet de prix et voyez ce que coûtera la liste avant les courses.' },
    ru: { label: 'Цены из чеков', blurb: 'Сканируйте чеки в книгу цен и узнавайте, сколько будет стоить список, до магазина.' },
  },
  'family-cookbook': {
    en: { label: 'Family cookbook', blurb: 'Shared digital cookbooks the whole family reads and edits, from grandma’s voice note onward.' },
    he: { label: 'ספר מתכונים משפחתי', blurb: 'ספרי מתכונים דיגיטליים משותפים שכל המשפחה קוראת ועורכת, מההקלטה של סבתא והלאה.' },
    ar: { label: 'كتاب طبخ عائلي', blurb: 'كتب طبخ رقمية مشتركة تقرؤها العائلة كلها وتحرّرها، من رسالة الجدة الصوتية فصاعدًا.' },
    fr: { label: 'Livre de recettes familial', blurb: 'Des livres numériques partagés que toute la famille lit et modifie, de la note vocale de mamie à aujourd’hui.' },
    ru: { label: 'Семейная книга рецептов', blurb: 'Общие цифровые книги, которые вся семья читает и редактирует, начиная с голосового бабушки.' },
  },
  'cook-mode-timers': {
    en: { label: 'Cook mode and timers', blurb: 'One step per screen in large type, with background timers that ring even when you leave.' },
    he: { label: 'מצב בישול וטיימרים', blurb: 'שלב אחד בכל מסך באותיות גדולות, עם טיימרים ברקע שמצלצלים גם כשיוצאים.' },
    ar: { label: 'وضع الطبخ والمؤقّتات', blurb: 'خطوة واحدة في كل شاشة بخط كبير، مع مؤقّتات في الخلفية ترنّ حتى عند المغادرة.' },
    fr: { label: 'Mode cuisine et minuteurs', blurb: 'Une étape par écran en grands caractères, avec des minuteurs en arrière-plan qui sonnent même si vous partez.' },
    ru: { label: 'Режим готовки и таймеры', blurb: 'Один шаг на экран крупным шрифтом и фоновые таймеры, которые звонят, даже если вы вышли.' },
  },
  'recipe-from-pdf-or-voice': {
    en: { label: 'PDF or voice note to recipe', blurb: 'A PDF page or a WhatsApp voice note, written by the AI as a recipe with amounts and steps.' },
    he: { label: 'מ-PDF או מהקלטה למתכון', blurb: 'עמוד PDF או הודעה קולית מוואטסאפ, שה-AI כותב כמתכון עם כמויות ושלבים.' },
    ar: { label: 'من PDF أو رسالة صوتية إلى وصفة', blurb: 'صفحة PDF أو رسالة واتساب صوتية يكتبها الذكاء الاصطناعي كوصفة بالكميات والخطوات.' },
    fr: { label: 'PDF ou note vocale en recette', blurb: 'Une page PDF ou une note vocale WhatsApp, écrite par l’IA en recette avec quantités et étapes.' },
    ru: { label: 'PDF или голосовое в рецепт', blurb: 'Страница PDF или голосовое из WhatsApp, записанное ИИ как рецепт с количествами и шагами.' },
  },
  'weekly-family-meal-plan': {
    en: { label: 'Family weekly menu', blurb: 'One shared week for the whole family, with the grocery list and the nutrition built from it.' },
    he: { label: 'תפריט שבועי למשפחה', blurb: 'שבוע משותף אחד לכל המשפחה, עם רשימת הקניות והערכים התזונתיים שנבנים ממנו.' },
    ar: { label: 'قائمة أسبوعية للعائلة', blurb: 'أسبوع مشترك واحد للعائلة كلها، مع قائمة التسوّق والقيم الغذائية المبنية منه.' },
    fr: { label: 'Menu de la semaine en famille', blurb: 'Une semaine partagée pour toute la famille, avec la liste de courses et la nutrition qui en découlent.' },
    ru: { label: 'Семейное меню на неделю', blurb: 'Одна общая неделя для всей семьи, со списком покупок и КБЖУ, собранными из неё.' },
  },
  'ai-cooking-assistant': {
    en: { label: 'AI cooking assistant', blurb: 'Shefi answers about your own recipes, plans and lists, by voice or text, and acts on them.' },
    he: { label: 'עוזר בישול AI', blurb: 'שפי עונה על המתכונים, התפריטים והרשימות שלכם, בקול או בכתב, ופועל עליהם.' },
    ar: { label: 'مساعد طبخ بالذكاء الاصطناعي', blurb: 'يجيب شيفي عن وصفاتك وخططك وقوائمك، بالصوت أو الكتابة، ويتصرّف بناءً عليها.' },
    fr: { label: 'Assistant de cuisine IA', blurb: 'Shefi répond sur vos recettes, plans et listes, à la voix ou à l’écrit, et agit dessus.' },
    ru: { label: 'ИИ-помощник на кухне', blurb: 'Шефи отвечает о ваших рецептах, планах и списках голосом или текстом и действует.' },
  },
};

const HOME_GUIDES = {
  en: { eyebrow: 'Guides', title: 'One app for recipes, the weekly menu and the shopping', sub: 'Short guides on what EasyPlate does for each part of the kitchen week: saving, planning, shopping and cooking.' },
  he: { eyebrow: 'מדריכים', title: 'אפליקציה אחת למתכונים, לתפריט השבועי ולקניות', sub: 'מדריכים קצרים על מה ש-EasyPlate עושה בכל חלק של שבוע המטבח: שמירה, תכנון, קניות ובישול.' },
  ar: { eyebrow: 'أدلة', title: 'تطبيق واحد للوصفات وقائمة الأسبوع والتسوّق', sub: 'أدلة قصيرة عمّا يفعله EasyPlate في كل جزء من أسبوع المطبخ: الحفظ والتخطيط والتسوّق والطبخ.' },
  fr: { eyebrow: 'Guides', title: 'Une seule app pour les recettes, le menu de la semaine et les courses', sub: 'Des guides courts sur ce qu’EasyPlate fait à chaque moment de la semaine en cuisine : enregistrer, planifier, acheter, cuisiner.' },
  ru: { eyebrow: 'Гиды', title: 'Одно приложение для рецептов, меню на неделю и покупок', sub: 'Короткие гиды о том, что EasyPlate делает в каждой части кухонной недели: сохранить, спланировать, купить, приготовить.' },
};

const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const ICON_SVG = {
  'book-open': '<path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>',
  'shopping-basket': '<path d="m15 11-1 9"/><path d="m19 11-4-7"/><path d="M2 11h20"/><path d="m3.5 11 1.6 7.4a2 2 0 0 0 2 1.6h9.8a2 2 0 0 0 2-1.6l1.7-7.4"/><path d="M4.5 15.5h15"/><path d="m5 11 4-7"/><path d="m9 11 1 9"/>',
  'calendar-days': '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/>',
  'sparkles': '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"/>',
  'calculator': '<rect width="16" height="20" x="4" y="2" rx="2"/><line x1="8" x2="16" y1="6" y2="6"/><line x1="16" x2="16" y1="14" y2="18"/><path d="M16 10h.01"/><path d="M12 10h.01"/><path d="M8 10h.01"/><path d="M12 14h.01"/><path d="M8 14h.01"/><path d="M12 18h.01"/><path d="M8 18h.01"/>',
  'receipt': '<path d="M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/><path d="M12 17.5v-11"/>',
  'users': '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  'flame': '<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>',
  'file-text': '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M10 9H8"/><path d="M16 13H8"/><path d="M16 17H8"/>',
  'check': '<path d="M20 6 9 17l-5-5"/>',
  'arrow': '<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>',
  'globe': '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20"/><path d="M2 12h20"/>',
  'mail': '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
  'mic': '<path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" x2="12" y1="19" y2="22"/>',
  'shield': '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
};
const icon = (name, cls = 'h-5 w-5') => `<svg xmlns="http://www.w3.org/2000/svg" class="${cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON_SVG[name]}</svg>`;

const APPLE_PATH = 'M16.37 12.72c-.03-2.6 2.12-3.85 2.22-3.91-1.21-1.77-3.09-2.01-3.76-2.04-1.6-.16-3.12.94-3.93.94-.81 0-2.06-.92-3.39-.89-1.74.03-3.35 1.01-4.25 2.57-1.81 3.14-.46 7.79 1.3 10.34.86 1.25 1.89 2.65 3.23 2.6 1.3-.05 1.79-.84 3.36-.84 1.57 0 2.01.84 3.39.81 1.4-.02 2.29-1.27 3.14-2.52.99-1.45 1.4-2.85 1.42-2.92-.03-.01-2.72-1.04-2.73-4.14zM13.78 5.08c.71-.86 1.19-2.06 1.06-3.26-1.03.04-2.27.68-3 1.54-.66.76-1.24 1.98-1.08 3.15 1.14.09 2.31-.58 3.02-1.43z';
const PLAY_SVG = '<svg viewBox="0 0 24 24" class="h-7 w-7" aria-hidden="true"><path fill="#34A853" d="M3.6 2.4 13 12l-9.4 9.6c-.4-.2-.6-.6-.6-1.1V3.5c0-.5.2-.9.6-1.1z"/><path fill="#FBBC04" d="M16.3 15.3 13 12l3.3-3.3 3.9 2.2c1.1.6 1.1 1.6 0 2.2z"/><path fill="#4285F4" d="M16.3 8.7 13 12 3.6 2.4c.4-.2.9-.2 1.4.1z"/><path fill="#EA4335" d="M16.3 15.3 5 21.5c-.5.3-1 .3-1.4.1L13 12z"/></svg>';

export function guideUrl(lang, slug, langUrls) { return (langUrls[lang] === '/' ? '' : langUrls[lang]) + '/' + slug; }

function storeBadges(ui, appStore, play) {
  return `<div class="flex flex-wrap items-center gap-3">
            <a href="${appStore}" target="_blank" rel="noopener" class="store-badge"><svg viewBox="0 0 24 24" class="h-7 w-7 fill-white" aria-hidden="true"><path d="${APPLE_PATH}"/></svg><span class="flex flex-col leading-none text-start"><span class="text-[10px] font-medium text-white/70">${esc(ui.appStoreTop)}</span><span class="text-lg font-bold -mt-0.5">${esc(ui.appStore)}</span></span></a>
            <a href="${play}" target="_blank" rel="noopener" class="store-badge">${PLAY_SVG}<span class="flex flex-col leading-none text-start"><span class="text-[10px] font-medium text-white/70">${esc(ui.playTop)}</span><span class="text-lg font-bold -mt-0.5">${esc(ui.play)}</span></span></a>
          </div>`;
}

function phone(src, alt, extra = '') {
  return `<div class="iphone photo ${extra}">
              <span class="btn-side action"></span><span class="btn-side vol1"></span><span class="btn-side vol2"></span><span class="btn-side power"></span>
              <div class="screen"><div class="island"></div><div class="status"><span>9:41</span><span></span></div><div class="glare"></div>
                <img class="shot" src="${src}" alt="${esc(alt)}" width="540" height="1129" loading="lazy" decoding="async" />
                <div class="home" style="background: rgba(24,20,69,.7)"></div>
              </div>
            </div>`;
}

/**
 * ctx: { lang, slug, site, langUrls, ogLocale, appStore, play, support, styles, i18nMeta, lastmod }
 */
export function renderGuide(ctx) {
  const { lang, slug, site, langUrls, ogLocale, appStore, play, support, styles, i18nMeta, lastmod } = ctx;
  const t = TOPICS[slug][lang], ui = UI[lang], topic = TOPICS[slug];
  const dir = i18nMeta[lang].dir, rtl = dir === 'rtl';
  const url = site + guideUrl(lang, slug, langUrls);
  const home = site + langUrls[lang];
  const og = `${site}/og/${lang}.png`;
  const langs = Object.keys(langUrls);
  const screens = topic.screens.map(s => `/screens/${s}.jpg`);
  const words = [t.h1, ...t.intro, ...t.sections.flatMap(s => [s.h2, s.p, ...(s.bullets || [])]), ...t.steps.flatMap(s => [s.t, s.d]), ...t.faq.flatMap(f => [f.q, f.a])].join(' ').split(/\s+/).length;
  const minutes = Math.max(2, Math.round(words / 180));

  const hreflang = langs.map(l => `  <link rel="alternate" hreflang="${l}" href="${site + guideUrl(l, slug, langUrls)}" />`).join('\n') +
    `\n  <link rel="alternate" hreflang="x-default" href="${site + guideUrl('en', slug, langUrls)}" />`;

  const ld = {
    '@context': 'https://schema.org',
    '@graph': [
      { '@type': 'WebPage', '@id': url, url, name: t.title, description: t.description, inLanguage: lang, isPartOf: { '@id': `${site}/#website` }, about: { '@id': `${site}/#app` }, primaryImageOfPage: { '@type': 'ImageObject', url: og, width: 1200, height: 630 }, breadcrumb: { '@id': `${url}#breadcrumb` }, dateModified: lastmod },
      { '@type': 'BreadcrumbList', '@id': `${url}#breadcrumb`, itemListElement: [
        { '@type': 'ListItem', position: 1, name: ui.home, item: home },
        { '@type': 'ListItem', position: 2, name: ui.guides, item: `${home}#guides` },
        { '@type': 'ListItem', position: 3, name: LABELS[slug][lang].label, item: url },
      ] },
      { '@type': 'Article', '@id': `${url}#article`, headline: t.h1, description: t.description, inLanguage: lang, mainEntityOfPage: { '@id': url }, image: [og, ...screens.map(s => site + s)], author: { '@id': `${site}/#organization` }, publisher: { '@id': `${site}/#organization` }, datePublished: '2026-10-06', dateModified: lastmod, about: { '@id': `${site}/#app` }, wordCount: words },
      { '@type': 'HowTo', '@id': `${url}#how`, name: t.h1, inLanguage: lang, step: t.steps.map((s, i) => ({ '@type': 'HowToStep', position: i + 1, name: s.t, text: s.d })) },
      { '@type': 'FAQPage', '@id': `${url}#faq`, inLanguage: lang, mainEntity: t.faq.map(f => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a } })) },
      { '@type': 'Organization', '@id': `${site}/#organization`, name: 'EasyPlate', legalName: 'KH Easy Dev', url: site, logo: { '@type': 'ImageObject', url: `${site}/icon-192.png`, width: 192, height: 192 }, email: support },
      { '@type': 'WebSite', '@id': `${site}/#website`, url: site, name: 'EasyPlate', inLanguage: langs },
      { '@type': ['SoftwareApplication', 'MobileApplication'], '@id': `${site}/#app`, name: 'EasyPlate', url: site, operatingSystem: 'iOS, Android', applicationCategory: 'LifestyleApplication', installUrl: [appStore, play] },
    ],
  };

  const langLinks = langs.map(l => `<a href="${guideUrl(l, slug, langUrls)}" hreflang="${l}" lang="${l}" class="rounded-full border px-3 py-1 text-xs font-medium transition ${l === lang ? 'border-brand-400/60 bg-brand-600/30 text-white' : 'border-white/10 text-white/60 hover:text-white hover:border-white/30'}">${esc(i18nMeta[l].name)}</a>`).join('\n            ');
  const otherGuides = SLUGS.filter(s => s !== slug).map(s => `
          <a href="${guideUrl(lang, s, langUrls)}" class="card p-6 flex flex-col gap-3 hover:border-brand-400/40">
            <span class="h-10 w-10 rounded-2xl bg-gradient-to-br from-brand-400 to-brand-700 grid place-items-center text-white">${icon(TOPICS[s].icon)}</span>
            <span class="font-bold text-lg">${esc(LABELS[s][lang].label)}</span>
            <span class="text-sm text-white/60 leading-relaxed">${esc(LABELS[s][lang].blurb)}</span>
            <span class="mt-auto inline-flex items-center gap-1 text-sm font-semibold text-brand-300">${esc(ui.guides)} ${icon('arrow', 'h-4 w-4 rtl-flip')}</span>
          </a>`).join('');

  return `<!DOCTYPE html>
<html lang="${lang}" dir="${dir}" class="scroll-smooth">
<head>
  <meta charset="UTF-8" />
  <!-- The Firebase default hosts serve the same files; keep one address for users and search engines. -->
  <script>
  if (window.location.hostname.endsWith('web.app') || window.location.hostname.endsWith('firebaseapp.com')) {
    window.location.replace('https://aieasyplate.app' + window.location.pathname + window.location.search);
  }
  </script>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
  <title>${esc(t.title)}</title>
  <meta name="description" content="${esc(t.description)}" />
  <meta name="keywords" content="${esc(t.keywords)}" />
  <meta name="robots" content="index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1" />
  <meta name="author" content="EasyPlate (KH Easy Dev)" />
  <link rel="canonical" href="${url}" />
${hreflang}
  <meta property="og:type" content="article" />
  <meta property="og:site_name" content="EasyPlate" />
  <meta property="og:locale" content="${ogLocale[lang]}" />
${langs.filter(l => l !== lang).map(l => `  <meta property="og:locale:alternate" content="${ogLocale[l]}" />`).join('\n')}
  <meta property="og:url" content="${url}" />
  <meta property="og:title" content="${esc(t.h1)}" />
  <meta property="og:description" content="${esc(t.description)}" />
  <meta property="og:image" content="${og}" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:image:alt" content="${esc(t.h1)}" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${esc(t.h1)}" />
  <meta name="twitter:description" content="${esc(t.description)}" />
  <meta name="twitter:image" content="${og}" />
  <script type="application/ld+json">${JSON.stringify(ld).replace(/<\//g, '<\\/')}</script>
  <meta name="theme-color" content="#0c0a1f" />
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png" />
  <link rel="icon" type="image/png" sizes="192x192" href="/icon-192.png" />
  <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
  <link rel="manifest" href="/site.webmanifest" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700;800&family=Heebo:wght@400;500;600;700;800&family=Noto+Sans+Arabic:wght@400;500;600;700;800&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="/assets/tailwind.css" />
${styles}
  <style>
    .reveal { opacity: 1; transform: none; }
    .prose-guide p { color: rgba(243,238,255,.72); line-height: 1.75; }
    details > summary { list-style: none; cursor: pointer; }
    details > summary::-webkit-details-marker { display: none; }
    details[open] .chev { transform: rotate(180deg); }
    .chev { transition: transform .3s; }
  </style>
</head>
<body class="font-sans antialiased min-h-screen relative">
  <div class="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
    <div class="absolute inset-0 grid-bg"></div>
    <div class="absolute -top-40 left-1/2 -translate-x-1/2 h-[700px] w-[900px] rounded-full bg-brand-600/30 blur-[140px]"></div>
    <div class="absolute top-[50%] -left-40 h-[500px] w-[500px] rounded-full bg-mint-500/15 blur-[120px]"></div>
  </div>

  <header class="sticky top-0 z-50 py-3">
    <div class="mx-auto max-w-7xl px-4 sm:px-6">
      <nav class="glass flex items-center justify-between rounded-2xl px-4 py-2.5 shadow-card">
        <a href="${langUrls[lang]}" class="flex items-center gap-3" aria-label="${esc(ui.back)}"><img src="/icon-64.png" alt="" width="36" height="36" class="h-9 w-9 rounded-xl shadow-glow" /><span class="text-lg font-extrabold tracking-tight">Easy<span class="text-gradient">Plate</span></span></a>
        <div class="hidden md:flex items-center gap-1 text-sm font-medium text-white/70">
          <a href="${langUrls[lang]}#features" class="px-3.5 py-2 rounded-xl hover:text-white hover:bg-white/5 transition">${esc(ui.features)}</a>
          <a href="${langUrls[lang]}#guides" class="px-3.5 py-2 rounded-xl hover:text-white hover:bg-white/5 transition">${esc(ui.guides)}</a>
          <a href="${langUrls[lang]}#pricing" class="px-3.5 py-2 rounded-xl hover:text-white hover:bg-white/5 transition">${esc(ui.pricing)}</a>
        </div>
        <a href="#download" class="btn-primary inline-flex items-center gap-2 rounded-xl px-4 py-2 text-sm font-semibold text-white"><span>${esc(ui.download)}</span>${icon('arrow', 'h-4 w-4 rtl-flip')}</a>
      </nav>
    </div>
  </header>

  <main>
    <article>
      <section class="relative pt-10 pb-16 sm:pt-16 lg:pb-24 noise">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 grid lg:grid-cols-12 gap-12 items-center">
          <div class="lg:col-span-7 relative z-10">
            <nav aria-label="breadcrumb" class="flex flex-wrap items-center gap-2 text-xs text-white/50">
              <a href="${langUrls[lang]}" class="hover:text-white">${esc(ui.home)}</a><span>›</span>
              <a href="${langUrls[lang]}#guides" class="hover:text-white">${esc(ui.guides)}</a><span>›</span>
              <span class="text-white/80">${esc(LABELS[slug][lang].label)}</span>
            </nav>
            <h1 class="mt-6 text-4xl sm:text-5xl lg:text-[3.6rem] font-extrabold leading-[1.08] tracking-tight">${esc(t.h1)}</h1>
            <div class="prose-guide mt-6 max-w-2xl space-y-4 text-base sm:text-lg">
              ${t.intro.map(p => `<p>${esc(p)}</p>`).join('\n              ')}
            </div>
            <p class="mt-4 text-xs text-white/40">${minutes} ${esc(ui.readingTime)}</p>
            <div class="mt-8">${storeBadges(ui, appStore, play)}</div>
            <p class="mt-5 flex items-center gap-2 text-sm text-white/60">${icon('shield', 'h-4 w-4 text-mint-400')}<span>${esc(ui.free)}</span></p>
          </div>
          <div class="lg:col-span-5 flex justify-center lg:justify-end">
            <div class="absolute -z-10 h-[420px] w-[420px] rounded-full bg-brand-500/25 blur-3xl"></div>
            ${phone(screens[0], t.h1, 'hero-phone')}
          </div>
        </div>
      </section>

      <section class="py-6 border-y border-white/5 bg-white/[.02]">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 flex flex-wrap items-center gap-2">
          <span class="text-xs text-white/40 me-2">${icon('globe', 'h-4 w-4 inline')}</span>
            ${langLinks}
        </div>
      </section>

      <section class="py-20 lg:py-28">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 grid lg:grid-cols-12 gap-12">
          <div class="lg:col-span-7 space-y-6">
            ${t.sections.map(s => `<div class="card p-7 lg:p-9">
              <h2 class="text-2xl lg:text-3xl font-extrabold tracking-tight">${esc(s.h2)}</h2>
              <div class="prose-guide mt-4"><p>${esc(s.p)}</p></div>
              ${s.bullets ? `<ul class="mt-5 space-y-3 text-sm sm:text-base">${s.bullets.map(b => `
                <li class="flex items-start gap-3"><span class="mt-1 h-5 w-5 rounded-full bg-gradient-to-br from-brand-400 to-mint-400 grid place-items-center flex-none text-ink-900">${icon('check', 'h-3 w-3')}</span><span class="text-white/80">${esc(b)}</span></li>`).join('')}
              </ul>` : ''}
            </div>`).join('\n            ')}
          </div>
          <aside class="lg:col-span-5">
            <div class="lg:sticky lg:top-28 flex flex-col items-center gap-8">
              ${phone(screens[1], t.sections[1].h2)}
              <div class="glass rounded-3xl p-6 w-full max-w-sm">
                <p class="text-sm font-semibold text-brand-300 uppercase tracking-wide">${esc(ui.more)}</p>
                <ul class="mt-3 space-y-2 text-sm">
                  ${SLUGS.filter(s => s !== slug).map(s => `<li><a href="${guideUrl(lang, s, langUrls)}" class="flex items-center gap-2 text-white/75 hover:text-white">${icon(TOPICS[s].icon, 'h-4 w-4 text-brand-300')}<span>${esc(LABELS[s][lang].label)}</span></a></li>`).join('\n                  ')}
                </ul>
              </div>
            </div>
          </aside>
        </div>
      </section>

      <section id="how" class="py-20 lg:py-24 border-t border-white/5">
        <div class="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-center">${esc(ui.how)}</h2>
          <ol class="mt-12 grid md:grid-cols-3 gap-5">
            ${t.steps.map((s, i) => `<li class="card p-7">
              <span class="h-10 w-10 rounded-2xl bg-gradient-to-br from-brand-400 to-brand-700 grid place-items-center font-extrabold text-sm text-white">0${i + 1}</span>
              <h3 class="mt-4 font-bold text-lg">${esc(s.t)}</h3>
              <p class="mt-2 text-sm text-white/60 leading-relaxed">${esc(s.d)}</p>
            </li>`).join('\n            ')}
          </ol>
        </div>
      </section>

      <section id="faq" class="py-20 lg:py-24 border-t border-white/5">
        <div class="mx-auto max-w-3xl px-4 sm:px-6">
          <h2 class="text-3xl sm:text-4xl font-extrabold tracking-tight text-center">${esc(ui.faq)}</h2>
          <div class="mt-10 glass rounded-3xl px-6 sm:px-8 divide-y divide-white/8">
            ${t.faq.map((f, i) => `<details class="group py-5"${i === 0 ? ' open' : ''}>
              <summary class="flex items-center justify-between gap-6 font-semibold text-base sm:text-lg text-white/90"><span>${esc(f.q)}</span><span class="chev flex-none h-8 w-8 rounded-full grid place-items-center bg-white/8 text-white/60"><svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg></span></summary>
              <p class="mt-3 text-white/60 leading-relaxed">${esc(f.a)}</p>
            </details>`).join('\n            ')}
          </div>
        </div>
      </section>

      <section class="py-16 border-t border-white/5">
        <div class="mx-auto max-w-7xl px-4 sm:px-6">
          <h2 class="text-2xl font-extrabold tracking-tight">${esc(ui.more)}</h2>
          <div class="mt-6 grid md:grid-cols-3 gap-5">${otherGuides}
          </div>
        </div>
      </section>

      <section id="download" class="py-20 lg:py-28">
        <div class="mx-auto max-w-5xl px-4 sm:px-6">
          <div class="relative overflow-hidden rounded-[40px] border border-white/10 p-10 sm:p-16 text-center" style="background: radial-gradient(120% 140% at 50% 0%, rgba(116,89,247,.45), rgba(12,10,31,.6) 60%)">
            <div class="absolute inset-0 grid-bg opacity-60"></div>
            <div class="relative">
              <img src="/icon-192.png" alt="EasyPlate app icon" width="72" height="72" loading="lazy" class="mx-auto h-[72px] w-[72px] rounded-[20px] shadow-glow" />
              <h2 class="mt-6 text-3xl sm:text-5xl font-extrabold tracking-tight leading-tight">${esc(t.cta.title)}</h2>
              <p class="mt-4 text-white/65 text-lg">${esc(t.cta.sub)}</p>
              <div class="mt-8 flex justify-center">${storeBadges(ui, appStore, play)}</div>
            </div>
          </div>
        </div>
      </section>
    </article>
  </main>

  <footer class="border-t border-white/8 py-14">
    <div class="mx-auto max-w-7xl px-4 sm:px-6 grid gap-10 md:grid-cols-12">
      <div class="md:col-span-5">
        <a href="${langUrls[lang]}" class="flex items-center gap-3"><img src="/icon-64.png" alt="" width="36" height="36" loading="lazy" class="h-9 w-9 rounded-xl" /><span class="text-lg font-extrabold tracking-tight">Easy<span class="text-gradient">Plate</span></span></a>
        <div class="mt-6 flex flex-wrap gap-2">
            ${langLinks}
        </div>
      </div>
      <div class="md:col-span-2">
        <h4 class="text-sm font-bold text-white/80">${esc(ui.guides)}</h4>
        <ul class="mt-4 space-y-2.5 text-sm text-white/55">
          ${SLUGS.map(s => `<li><a href="${guideUrl(lang, s, langUrls)}" class="hover:text-white transition">${esc(LABELS[s][lang].label)}</a></li>`).join('\n          ')}
        </ul>
      </div>
      <div class="md:col-span-2">
        <h4 class="text-sm font-bold text-white/80">EasyPlate</h4>
        <ul class="mt-4 space-y-2.5 text-sm text-white/55">
          <li><a href="${langUrls[lang]}#features" class="hover:text-white transition">${esc(ui.features)}</a></li>
          <li><a href="${langUrls[lang]}#pricing" class="hover:text-white transition">${esc(ui.pricing)}</a></li>
          <li><a href="${guideUrl(lang, 'privacy', langUrls)}" class="hover:text-white transition">${esc(ui.privacy)}</a></li>
          <li><a href="${guideUrl(lang, 'terms', langUrls)}" class="hover:text-white transition">${esc(ui.terms)}</a></li>
        </ul>
      </div>
      <div class="md:col-span-3">
        <h4 class="text-sm font-bold text-white/80">${esc(ui.support)}</h4>
        <a href="mailto:${support}" class="mt-4 inline-flex items-center gap-2 rounded-xl btn-ghost px-3.5 py-2 text-sm">${icon('mail', 'h-4 w-4 text-brand-300')}<span dir="ltr">${support}</span></a>
      </div>
    </div>
    <div class="mx-auto max-w-7xl px-4 sm:px-6 mt-12 pt-6 border-t border-white/5 text-xs text-white/40">${esc(ui.copyright)}</div>
  </footer>
</body>
</html>
`;
}

/** Home-page section linking to the four guides (goes between the guides markers). */
export function homeGuidesSection(lang, langUrls) {
  const h = HOME_GUIDES[lang];
  return `  <!-- guides:start -->
    <section id="guides" class="relative py-24 lg:py-32 scroll-mt-24">
      <div class="mx-auto max-w-7xl px-4 sm:px-6">
        <div class="max-w-2xl reveal">
          <p class="text-sm font-semibold tracking-wide text-brand-300 uppercase">${esc(h.eyebrow)}</p>
          <h2 class="mt-3 text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight leading-tight">${esc(h.title)}</h2>
          <p class="mt-4 text-lg text-white/60">${esc(h.sub)}</p>
        </div>
        <div class="mt-12 grid sm:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-5">
          ${SLUGS.map((s, i) => `<a href="${guideUrl(lang, s, langUrls)}" class="card p-6 flex flex-col gap-3 reveal" data-delay="${i}" @mousemove="glow($event)">
            <span class="h-10 w-10 rounded-2xl bg-gradient-to-br from-brand-400 to-brand-700 grid place-items-center text-white">${icon(TOPICS[s].icon)}</span>
            <h3 class="font-bold text-lg">${esc(LABELS[s][lang].label)}</h3>
            <p class="text-sm text-white/60 leading-relaxed">${esc(LABELS[s][lang].blurb)}</p>
            <span class="mt-auto inline-flex items-center gap-1 text-sm font-semibold text-brand-300">${esc(UI[lang].guides)} ${icon('arrow', 'h-4 w-4 rtl-flip')}</span>
          </a>`).join('\n          ')}
        </div>
      </div>
    </section>
  <!-- guides:end -->`;
}

/** Footer column on the home page (goes between the footer-guides markers). */
export function homeFooterGuides(lang, langUrls) {
  return `<!-- footer-guides:start -->
      <div class="md:col-span-2">
        <h4 class="text-sm font-bold text-white/80">${esc(UI[lang].guides)}</h4>
        <ul class="mt-4 space-y-2.5 text-sm text-white/55">
          ${SLUGS.map(s => `<li><a href="${guideUrl(lang, s, langUrls)}" class="hover:text-white transition">${esc(LABELS[s][lang].label)}</a></li>`).join('\n          ')}
        </ul>
      </div>
      <!-- footer-guides:end -->`;
}
