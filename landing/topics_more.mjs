// More keyword guide pages, merged into TOPICS by topics.mjs. Same shape as
// there: title ≤ 60 chars, description ≤ 155, keyword first and the brand
// last. Everything stated must be true of the app.

export const MORE_TOPICS = {
  // ------------------------------------------------------------------ Instagram / YouTube
  'save-instagram-recipes': {
    icon: 'sparkles', screens: ['03_ai_import', '02_recipe_details'],
    en: {
      title: 'Save Instagram and YouTube Recipes as Real Recipes | EasyPlate',
      description: 'Share a Reel or a YouTube video to EasyPlate and get a recipe with ingredients, amounts, steps and nutrition, not a saved post. Free on iOS and Android.',
      keywords: 'save instagram recipes, instagram recipe to text, youtube video to recipe, reel recipe, extract recipe from video, recipe from instagram',
      h1: 'Save a recipe from Instagram or YouTube as a real recipe',
      intro: [
        'Instagram’s "saved" tab is where recipes go to be forgotten: a grid of Reels with no ingredient list, no amounts and no way to search. YouTube is worse, with the recipe buried in a 12-minute video and a description that says "link in bio".',
        'EasyPlate turns the video itself into a recipe. Share the Reel or the YouTube link to the app, and the AI watches it, reads the caption and the on-screen text, and returns ingredients with amounts, numbered steps, servings and estimated nutrition. From there it is yours: editable, searchable, ready for the weekly plan and the grocery list.',
      ],
      sections: [
        { h2: 'What the AI reads from a Reel or a video', p: 'A short cooking video rarely states everything out loud, so EasyPlate combines three sources into one recipe:', bullets: ['The video: what is added, in what order, and the amounts shown or said.', 'The caption or description: many creators put the full recipe there.', 'On-screen text and the title, for dish name, servings and cooking time.', 'When a video says nothing useful, the caption alone is used and you are told so.'] },
        { h2: 'Instagram, YouTube, TikTok and Facebook', p: 'The same share flow works for all four platforms, and for YouTube Shorts as well as full-length videos. Private accounts and videos that block downloading cannot be read: EasyPlate tells you instead of guessing.', bullets: ['Instagram Reels and video posts.', 'YouTube videos and Shorts.', 'TikTok and Facebook videos.', 'A link to any recipe website, as a bonus.'] },
        { h2: 'After the recipe exists', p: 'An extracted recipe behaves like one you typed: scale the servings and the amounts follow, add it to a cookbook, drop it on a day of the week, share it with your family, and cook it hands-free in Cook Mode with timers. Nutrition per serving is estimated automatically.', bullets: ['Everything is editable: ingredients, steps, servings, photo.', 'Searchable by ingredient, tag or dish name.', 'The grocery list adds its ingredients, merged with the rest of the week.', 'Works in Hebrew, English, Arabic, French and Russian.'] },
      ],
      steps: [
        { t: 'Tap share on the Reel or video', d: 'In Instagram or YouTube, use the share button and pick EasyPlate. On a computer, copy the link and paste it in the app.' },
        { t: 'Let the AI watch it', d: 'A few seconds later the recipe appears: ingredients, amounts, steps, servings, tags and nutrition. Fix anything the video left vague.' },
        { t: 'Save, plan, shop', d: 'Save it into a book, add it to the weekly plan, and the grocery list is updated. Cook Mode walks you through the steps.' },
      ],
      faq: [
        { q: 'Does it work with Instagram Reels?', a: 'Yes. Share the Reel from Instagram to EasyPlate or paste its link. Video posts and carousels with a recipe in the caption work too.' },
        { q: 'Does it work with YouTube?', a: 'Yes, with full videos and Shorts. The AI watches the video and reads the description, so a recipe only shown on screen is still captured.' },
        { q: 'What if the recipe is only in the caption?', a: 'Then the caption is used. If neither the video nor the caption contains a recipe, EasyPlate says so instead of inventing one.' },
        { q: 'Can I save a private video?', a: 'No. EasyPlate reads only what the platform serves publicly. A private or download-protected video cannot be processed.' },
        { q: 'Is there a limit?', a: 'A free account has a daily allowance of AI extractions; EasyPlate Pro removes it for ₪20 a month, billed through the App Store or Google Play.' },
      ],
      cta: { title: 'Your saved Reels, finally cookable.', sub: 'Download EasyPlate and share the next recipe video to it.' },
    },
    he: {
      title: 'לשמור מתכון מאינסטגרם ומיוטיוב כמתכון אמיתי | EasyPlate',
      description: 'משתפים ריל או סרטון יוטיוב ל-EasyPlate ומקבלים מתכון עם מצרכים, כמויות, שלבים וערכים תזונתיים, לא עוד פוסט שמור. חינם לאייפון ולאנדרואיד.',
      keywords: 'לשמור מתכון מאינסטגרם, מתכונים מאינסטגרם, מתכון מריל, מתכון מסרטון יוטיוב, מתכונים מיוטיוב, חילוץ מתכון מסרטון, אפליקציה למתכונים מאינסטגרם',
      h1: 'איך שומרים מתכון מאינסטגרם או מיוטיוב כמתכון אמיתי',
      intro: [
        'הטאב "שמורים" באינסטגרם הוא המקום שבו מתכונים הולכים להישכח: רשת של רילס בלי רשימת מצרכים, בלי כמויות ובלי חיפוש. ביוטיוב זה גרוע יותר, המתכון קבור בסרטון של 12 דקות והתיאור אומר "קישור בביו".',
        'EasyPlate הופכת את הסרטון עצמו למתכון. משתפים את הריל או את קישור היוטיוב לאפליקציה, ה-AI צופה בו, קורא את הכיתוב ואת הטקסט שעל המסך, ומחזיר מצרכים עם כמויות, שלבים ממוספרים, מנות וערכים תזונתיים משוערים. משם הוא שלכם: ניתן לעריכה, לחיפוש, מוכן לתפריט השבועי ולרשימת הקניות.',
      ],
      sections: [
        { h2: 'מה ה-AI קורא מריל או מסרטון', p: 'סרטון בישול קצר כמעט אף פעם לא אומר הכול בקול, אז EasyPlate משלבת שלושה מקורות למתכון אחד:', bullets: ['הסרטון: מה מוסיפים, באיזה סדר, והכמויות שמוצגות או נאמרות.', 'הכיתוב או התיאור: הרבה יוצרים כותבים שם את המתכון המלא.', 'טקסט על המסך והכותרת, לשם המנה, מספר המנות וזמן ההכנה.', 'כשסרטון לא אומר כלום מועיל, משתמשים בכיתוב בלבד ואומרים לכם את זה.'] },
        { h2: 'אינסטגרם, יוטיוב, טיקטוק ופייסבוק', p: 'אותו מסלול שיתוף עובד בארבע הפלטפורמות, וגם ב-Shorts של יוטיוב וגם בסרטונים ארוכים. חשבונות פרטיים וסרטונים שחוסמים הורדה אי אפשר לקרוא: EasyPlate אומרת לכם במקום לנחש.', bullets: ['רילס ופוסטים עם וידאו באינסטגרם.', 'סרטוני יוטיוב ו-Shorts.', 'סרטונים מטיקטוק ומפייסבוק.', 'וגם קישור לכל אתר מתכונים.'] },
        { h2: 'אחרי שהמתכון קיים', p: 'מתכון שחולץ מתנהג כמו מתכון שהקלדתם: משנים מנות והכמויות מתעדכנות, מוסיפים לספר, גוררים ליום בשבוע, משתפים עם המשפחה ומבשלים בלי ידיים במצב בישול עם טיימרים. ערכים תזונתיים למנה מחושבים אוטומטית.', bullets: ['הכול ניתן לעריכה: מצרכים, שלבים, מנות, תמונה.', 'חיפוש לפי מצרך, תגית או שם מנה.', 'רשימת הקניות מוסיפה את המצרכים, מאוחדים עם שאר השבוע.', 'עובד בעברית, אנגלית, ערבית, צרפתית ורוסית.'] },
      ],
      steps: [
        { t: 'לוחצים שיתוף על הריל או הסרטון', d: 'באינסטגרם או ביוטיוב לוחצים על כפתור השיתוף ובוחרים EasyPlate. במחשב מעתיקים את הקישור ומדביקים באפליקציה.' },
        { t: 'נותנים ל-AI לצפות', d: 'כמה שניות אחר כך המתכון מופיע: מצרכים, כמויות, שלבים, מנות, תגיות וערכים תזונתיים. מתקנים מה שהסרטון השאיר מעורפל.' },
        { t: 'שומרים, מתכננים, קונים', d: 'שומרים לספר, מוסיפים לתפריט השבועי ורשימת הקניות מתעדכנת. מצב בישול מוביל אתכם שלב אחרי שלב.' },
      ],
      faq: [
        { q: 'זה עובד עם רילס באינסטגרם?', a: 'כן. משתפים את הריל מאינסטגרם ל-EasyPlate או מדביקים את הקישור שלו. גם פוסטים עם וידאו וקרוסלות עם מתכון בכיתוב עובדים.' },
        { q: 'זה עובד עם יוטיוב?', a: 'כן, עם סרטונים מלאים ועם Shorts. ה-AI צופה בסרטון וקורא את התיאור, אז מתכון שמוצג רק על המסך נתפס גם הוא.' },
        { q: 'מה אם המתכון נמצא רק בכיתוב?', a: 'אז משתמשים בכיתוב. אם לא בסרטון ולא בכיתוב יש מתכון, EasyPlate אומרת זאת במקום להמציא אחד.' },
        { q: 'אפשר לשמור סרטון פרטי?', a: 'לא. EasyPlate קוראת רק מה שהפלטפורמה מגישה בפומבי. סרטון פרטי או מוגן מהורדה אי אפשר לעבד.' },
        { q: 'יש הגבלה?', a: 'לחשבון חינמי יש מכסה יומית של חילוצי AI; EasyPlate Pro מסירה אותה ב-20 ₪ לחודש, בחיוב דרך App Store או Google Play.' },
      ],
      cta: { title: 'הרילס ששמרתם, סוף סוף אפשר לבשל.', sub: 'הורידו את EasyPlate ושתפו אליה את סרטון המתכון הבא.' },
    },
    ar: {
      title: 'احفظ وصفات إنستغرام ويوتيوب كوصفات حقيقية | EasyPlate',
      description: 'شارك ريل أو فيديو يوتيوب مع EasyPlate واحصل على وصفة بالمكوّنات والكميات والخطوات والقيم الغذائية، لا منشورًا محفوظًا. مجاني على iOS وأندرويد.',
      keywords: 'حفظ وصفات إنستغرام, وصفة من ريل, وصفة من فيديو يوتيوب, استخراج وصفة من فيديو, وصفات إنستغرام, تطبيق وصفات إنستغرام',
      h1: 'احفظ وصفة من إنستغرام أو يوتيوب كوصفة حقيقية',
      intro: [
        'قسم "المحفوظات" في إنستغرام هو المكان الذي تُنسى فيه الوصفات: شبكة من الريلز بلا قائمة مكوّنات ولا كميات ولا بحث. ويوتيوب أسوأ: الوصفة مدفونة في فيديو من 12 دقيقة والوصف يقول "الرابط في البايو".',
        'يحوّل EasyPlate الفيديو نفسه إلى وصفة. شارك الريل أو رابط يوتيوب مع التطبيق، فيشاهده الذكاء الاصطناعي ويقرأ التعليق والنص الظاهر على الشاشة ويعيد مكوّنات بكمياتها وخطوات مرقّمة وعدد الحصص وقيمًا غذائية تقديرية. ومن هناك تصبح لك: قابلة للتعديل والبحث، وجاهزة للخطة الأسبوعية وقائمة التسوّق.',
      ],
      sections: [
        { h2: 'ما يقرأه الذكاء الاصطناعي من الريل أو الفيديو', p: 'نادرًا ما يقول فيديو الطبخ القصير كل شيء بصوت عالٍ، لذلك يجمع EasyPlate ثلاثة مصادر في وصفة واحدة:', bullets: ['الفيديو: ما يُضاف وبأي ترتيب والكميات المعروضة أو المذكورة.', 'التعليق أو الوصف: كثير من صنّاع المحتوى يكتبون الوصفة كاملة هناك.', 'النص على الشاشة والعنوان: لاسم الطبق وعدد الحصص ووقت التحضير.', 'عندما لا يقول الفيديو شيئًا مفيدًا، يُستخدم التعليق وحده ويخبرك التطبيق بذلك.'] },
        { h2: 'إنستغرام ويوتيوب وتيك توك وفيسبوك', p: 'مسار المشاركة نفسه يعمل في المنصات الأربع، ومع Shorts يوتيوب كما مع الفيديوهات الطويلة. لا يمكن قراءة الحسابات الخاصة والفيديوهات التي تمنع التنزيل: يخبرك EasyPlate بدل أن يخمّن.', bullets: ['ريلز إنستغرام ومنشورات الفيديو.', 'فيديوهات يوتيوب وShorts.', 'فيديوهات تيك توك وفيسبوك.', 'ورابط أي موقع وصفات كذلك.'] },
        { h2: 'بعد أن تصبح الوصفة موجودة', p: 'تتصرف الوصفة المستخرجة كأنك كتبتها: غيّر الحصص فتتبعها الكميات، أضفها إلى كتاب، ضعها على يوم من الأسبوع، شاركها مع عائلتك، واطبخها بيدين حرّتين في وضع الطبخ مع المؤقّتات. تُقدَّر القيم الغذائية لكل حصة تلقائيًا.', bullets: ['كل شيء قابل للتعديل: المكوّنات والخطوات والحصص والصورة.', 'بحث حسب المكوّن أو الوسم أو اسم الطبق.', 'تضيف قائمة التسوّق مكوّناتها مدمجة مع بقية الأسبوع.', 'يعمل بالعربية والعبرية والإنجليزية والفرنسية والروسية.'] },
      ],
      steps: [
        { t: 'اضغط مشاركة على الريل أو الفيديو', d: 'في إنستغرام أو يوتيوب استخدم زر المشاركة واختر EasyPlate. على الحاسوب انسخ الرابط والصقه في التطبيق.' },
        { t: 'دع الذكاء الاصطناعي يشاهده', d: 'بعد ثوانٍ تظهر الوصفة: مكوّنات وكميات وخطوات وحصص ووسوم وقيم غذائية. صحّح ما تركه الفيديو غامضًا.' },
        { t: 'احفظ وخطّط وتسوّق', d: 'احفظها في كتاب، أضفها إلى الخطة الأسبوعية، وتتحدّث قائمة التسوّق. يقودك وضع الطبخ خطوة بخطوة.' },
      ],
      faq: [
        { q: 'هل يعمل مع ريلز إنستغرام؟', a: 'نعم. شارك الريل من إنستغرام مع EasyPlate أو الصق رابطه. تعمل أيضًا منشورات الفيديو والمنشورات المتعددة التي تحتوي وصفة في التعليق.' },
        { q: 'هل يعمل مع يوتيوب؟', a: 'نعم، مع الفيديوهات الكاملة وShorts. يشاهد الذكاء الاصطناعي الفيديو ويقرأ الوصف، فتُلتقط حتى الوصفة المعروضة على الشاشة فقط.' },
        { q: 'ماذا لو كانت الوصفة في التعليق فقط؟', a: 'عندها يُستخدم التعليق. وإذا لم يحتوِ الفيديو ولا التعليق على وصفة، يخبرك EasyPlate بدل أن يخترع واحدة.' },
        { q: 'هل يمكنني حفظ فيديو خاص؟', a: 'لا. يقرأ EasyPlate فقط ما تعرضه المنصة علنًا. لا يمكن معالجة فيديو خاص أو محمي من التنزيل.' },
        { q: 'هل هناك حد؟', a: 'للحساب المجاني حصة يومية من الاستخراجات بالذكاء الاصطناعي؛ يزيلها EasyPlate Pro مقابل 20 شيكل شهريًا عبر App Store أو Google Play.' },
      ],
      cta: { title: 'الريلز المحفوظة، أخيرًا قابلة للطبخ.', sub: 'حمّل EasyPlate وشارك معه فيديو الوصفة التالي.' },
    },
    fr: {
      title: 'Enregistrer une recette Instagram ou YouTube | EasyPlate',
      description: 'Partagez un Reel ou une vidéo YouTube vers EasyPlate et obtenez une vraie recette : ingrédients, quantités, étapes et nutrition. Gratuit sur iOS et Android.',
      keywords: 'enregistrer recette instagram, recette reel, vidéo youtube en recette, extraire recette vidéo, recettes instagram, application recettes instagram',
      h1: 'Enregistrer une recette Instagram ou YouTube comme une vraie recette',
      intro: [
        'L’onglet « Enregistrés » d’Instagram est l’endroit où les recettes vont se faire oublier : une grille de Reels sans liste d’ingrédients, sans quantités et sans recherche. YouTube est pire, la recette est enfouie dans une vidéo de 12 minutes et la description dit « lien en bio ».',
        'EasyPlate transforme la vidéo elle-même en recette. Partagez le Reel ou le lien YouTube vers l’app : l’IA la regarde, lit la légende et le texte à l’écran, et renvoie des ingrédients avec quantités, des étapes numérotées, le nombre de portions et une nutrition estimée. Ensuite, elle est à vous : modifiable, consultable, prête pour le menu de la semaine et la liste de courses.',
      ],
      sections: [
        { h2: 'Ce que l’IA lit dans un Reel ou une vidéo', p: 'Une courte vidéo de cuisine dit rarement tout à voix haute, alors EasyPlate combine trois sources en une recette :', bullets: ['La vidéo : ce qui est ajouté, dans quel ordre, et les quantités montrées ou dites.', 'La légende ou la description : beaucoup de créateurs y mettent la recette complète.', 'Le texte à l’écran et le titre, pour le nom du plat, les portions et le temps de cuisson.', 'Quand la vidéo ne dit rien d’utile, seule la légende est utilisée et vous en êtes informé.'] },
        { h2: 'Instagram, YouTube, TikTok et Facebook', p: 'Le même partage fonctionne sur les quatre plateformes, pour les Shorts YouTube comme pour les vidéos longues. Les comptes privés et les vidéos qui bloquent le téléchargement ne peuvent pas être lus : EasyPlate vous le dit au lieu de deviner.', bullets: ['Reels et publications vidéo Instagram.', 'Vidéos YouTube et Shorts.', 'Vidéos TikTok et Facebook.', 'Et le lien de n’importe quel site de recettes.'] },
        { h2: 'Une fois la recette créée', p: 'Une recette extraite se comporte comme une recette saisie : ajustez les portions et les quantités suivent, ajoutez-la à un livre, placez-la sur un jour de la semaine, partagez-la avec la famille et cuisinez mains libres en mode cuisine avec minuteurs. La nutrition par portion est estimée automatiquement.', bullets: ['Tout est modifiable : ingrédients, étapes, portions, photo.', 'Recherche par ingrédient, tag ou nom de plat.', 'La liste de courses ajoute ses ingrédients, fusionnés avec le reste de la semaine.', 'Fonctionne en français, anglais, hébreu, arabe et russe.'] },
      ],
      steps: [
        { t: 'Touchez Partager sur le Reel ou la vidéo', d: 'Dans Instagram ou YouTube, utilisez le bouton de partage et choisissez EasyPlate. Sur ordinateur, copiez le lien et collez-le dans l’app.' },
        { t: 'Laissez l’IA regarder', d: 'Quelques secondes plus tard, la recette apparaît : ingrédients, quantités, étapes, portions, tags et nutrition. Corrigez ce que la vidéo a laissé flou.' },
        { t: 'Enregistrez, planifiez, achetez', d: 'Enregistrez-la dans un livre, ajoutez-la au menu de la semaine et la liste de courses se met à jour. Le mode cuisine vous guide étape par étape.' },
      ],
      faq: [
        { q: 'Ça marche avec les Reels Instagram ?', a: 'Oui. Partagez le Reel depuis Instagram vers EasyPlate ou collez son lien. Les publications vidéo et les carrousels avec la recette en légende fonctionnent aussi.' },
        { q: 'Ça marche avec YouTube ?', a: 'Oui, avec les vidéos complètes et les Shorts. L’IA regarde la vidéo et lit la description, donc une recette seulement affichée à l’écran est capturée aussi.' },
        { q: 'Et si la recette n’est que dans la légende ?', a: 'Alors la légende est utilisée. Si ni la vidéo ni la légende ne contiennent de recette, EasyPlate le dit au lieu d’en inventer une.' },
        { q: 'Puis-je enregistrer une vidéo privée ?', a: 'Non. EasyPlate ne lit que ce que la plateforme sert publiquement. Une vidéo privée ou protégée contre le téléchargement ne peut pas être traitée.' },
        { q: 'Y a-t-il une limite ?', a: 'Un compte gratuit a un quota quotidien d’extractions IA ; EasyPlate Pro le supprime pour 20 ₪ par mois via l’App Store ou Google Play.' },
      ],
      cta: { title: 'Vos Reels enregistrés, enfin cuisinables.', sub: 'Téléchargez EasyPlate et partagez-lui la prochaine vidéo de recette.' },
    },
    ru: {
      title: 'Сохранить рецепт из Instagram и YouTube | EasyPlate',
      description: 'Поделитесь рилсом или видео YouTube с EasyPlate и получите настоящий рецепт: ингредиенты, количества, шаги и КБЖУ. Бесплатно для iOS и Android.',
      keywords: 'сохранить рецепт из инстаграм, рецепт из рилс, видео youtube в рецепт, извлечь рецепт из видео, рецепты из инстаграм, приложение рецепты инстаграм',
      h1: 'Как сохранить рецепт из Instagram или YouTube как настоящий рецепт',
      intro: [
        'Вкладка «Сохранённое» в Instagram — место, где рецепты забываются: сетка рилсов без списка ингредиентов, без количеств и без поиска. YouTube хуже: рецепт спрятан в 12-минутном видео, а в описании написано «ссылка в био».',
        'EasyPlate превращает само видео в рецепт. Поделитесь рилсом или ссылкой YouTube с приложением: ИИ посмотрит его, прочитает подпись и текст на экране и вернёт ингредиенты с количествами, пронумерованные шаги, число порций и примерное КБЖУ. Дальше рецепт ваш: его можно редактировать, искать, ставить в меню на неделю и в список покупок.',
      ],
      sections: [
        { h2: 'Что ИИ читает из рилса или видео', p: 'Короткое кулинарное видео редко проговаривает всё вслух, поэтому EasyPlate собирает рецепт из трёх источников:', bullets: ['Видео: что добавляют, в каком порядке и какие количества показаны или названы.', 'Подпись или описание: многие авторы пишут там полный рецепт.', 'Текст на экране и заголовок: название блюда, порции, время готовки.', 'Если видео не говорит ничего полезного, используется только подпись, и вам об этом сообщают.'] },
        { h2: 'Instagram, YouTube, TikTok и Facebook', p: 'Один и тот же способ «поделиться» работает на всех четырёх платформах, для YouTube Shorts и длинных видео. Приватные аккаунты и видео с запретом на скачивание прочитать нельзя: EasyPlate скажет об этом, а не будет гадать.', bullets: ['Рилсы и видеопосты Instagram.', 'Видео YouTube и Shorts.', 'Видео TikTok и Facebook.', 'И ссылка на любой сайт с рецептами.'] },
        { h2: 'Когда рецепт уже есть', p: 'Извлечённый рецепт ведёт себя как набранный вручную: измените порции — количества пересчитаются, добавьте в книгу, поставьте на день недели, поделитесь с семьёй и готовьте без рук в режиме готовки с таймерами. КБЖУ на порцию оценивается автоматически.', bullets: ['Редактируется всё: ингредиенты, шаги, порции, фото.', 'Поиск по ингредиенту, тегу или названию блюда.', 'Список покупок добавляет ингредиенты, объединяя их с остальной неделей.', 'Работает на русском, английском, иврите, арабском и французском.'] },
      ],
      steps: [
        { t: 'Нажмите «Поделиться» на рилсе или видео', d: 'В Instagram или YouTube нажмите кнопку «Поделиться» и выберите EasyPlate. На компьютере скопируйте ссылку и вставьте в приложение.' },
        { t: 'Дайте ИИ посмотреть', d: 'Через несколько секунд появится рецепт: ингредиенты, количества, шаги, порции, теги и КБЖУ. Поправьте то, что видео оставило неясным.' },
        { t: 'Сохраните, спланируйте, купите', d: 'Сохраните в книгу, добавьте в меню на неделю — список покупок обновится. Режим готовки проведёт по шагам.' },
      ],
      faq: [
        { q: 'Работает с рилсами Instagram?', a: 'Да. Поделитесь рилсом из Instagram с EasyPlate или вставьте его ссылку. Видеопосты и карусели с рецептом в подписи тоже работают.' },
        { q: 'Работает с YouTube?', a: 'Да, с полными видео и Shorts. ИИ смотрит видео и читает описание, поэтому рецепт, показанный только на экране, тоже попадает в приложение.' },
        { q: 'А если рецепт только в подписи?', a: 'Тогда используется подпись. Если ни в видео, ни в подписи рецепта нет, EasyPlate скажет об этом, а не придумает.' },
        { q: 'Можно сохранить приватное видео?', a: 'Нет. EasyPlate читает только то, что платформа отдаёт публично. Приватное или защищённое от скачивания видео обработать нельзя.' },
        { q: 'Есть ли лимит?', a: 'У бесплатного аккаунта есть дневная квота извлечений ИИ; EasyPlate Pro снимает её за 20 ₪ в месяц через App Store или Google Play.' },
      ],
      cta: { title: 'Сохранённые рилсы — наконец по ним можно готовить.', sub: 'Скачайте EasyPlate и поделитесь с ним следующим видео с рецептом.' },
    },
  },

  // ------------------------------------------------------------------ Calories / nutrition
  'recipe-calorie-calculator': {
    icon: 'calculator', screens: ['07_nutrition', '02_recipe_details'],
    en: {
      title: 'Recipe Calorie Calculator: Nutrition per Serving | EasyPlate',
      description: 'Paste or save any recipe and get calories, protein, carbs and fat per serving, plus a weekly nutrition dashboard for your meal plan. Free on iOS and Android.',
      keywords: 'recipe calorie calculator, calories per serving calculator, recipe nutrition calculator, macros per serving, nutrition facts for recipe, calorie counter for recipes',
      h1: 'A recipe calorie calculator that works on any recipe',
      intro: [
        'Most calorie apps count packaged foods with barcodes. A home recipe has no barcode: it has "2 cups of flour", "a handful of parsley" and "serves 4 to 6". Working out the calories per serving by hand means looking up every ingredient, converting units and dividing, and almost nobody does it twice.',
        'EasyPlate estimates nutrition for every recipe you save, automatically. The AI reads the ingredient list with its amounts and the number of servings, and returns calories, protein, carbohydrates and fat per serving. Change the servings or an amount and the numbers follow. The week’s plan then adds up into a nutrition dashboard, per day and per week.',
      ],
      sections: [
        { h2: 'What is calculated, and how', p: 'The estimate is made from the ingredients as written, not from a photo of the plate:', bullets: ['Calories, protein, carbohydrates and fat per serving.', 'The servings count on the recipe decides the division; set it to what you actually get.', 'Scaling a recipe to more or fewer servings keeps the per-serving values and recalculates the total.', 'Ingredients without an amount ("salt to taste") are treated as negligible.'] },
        { h2: 'From one recipe to the whole week', p: 'Because every recipe carries its nutrition, a weekly meal plan built from recipes carries it too. The nutrition dashboard shows each day’s totals and the week’s, so you can see at a glance whether Tuesday is all carbs or where the protein is missing.', bullets: ['Per-day and per-week totals from the meal plan.', 'Quick items without a recipe can be given values by hand.', 'Shared plans show the same numbers to everyone in the family.', 'Nothing to log after eating: the plan is the log.'] },
        { h2: 'An estimate, honestly labelled', p: 'The numbers are an AI estimate from standard ingredient values, not a laboratory analysis. They are good enough to compare recipes, spot a very heavy dinner or plan a balanced week; they are not a substitute for medical advice, and allergens are listed separately so a nutrition line never hides one.', bullets: ['Every value is editable if you know better.', 'Allergens and dietary tags (vegan, gluten-free, kosher-style categories) sit next to the nutrition.', 'Works in Hebrew, English, Arabic, French and Russian.'] },
      ],
      steps: [
        { t: 'Save or paste a recipe', d: 'From a link, a video, a PDF, a voice note or your own typing. The ingredients and servings are what the calculator needs.' },
        { t: 'Read the nutrition line', d: 'Calories, protein, carbs and fat per serving appear on the recipe. Adjust servings or amounts and watch them update.' },
        { t: 'Plan the week', d: 'Put recipes on the days of the week and open the nutrition dashboard for daily and weekly totals.' },
      ],
      faq: [
        { q: 'Do I have to type the ingredients?', a: 'No. Any recipe EasyPlate extracts from a link, video, PDF or voice note already has its ingredients and amounts, and the nutrition is estimated from them.' },
        { q: 'How accurate are the calories?', a: 'They are estimates from standard values per ingredient, so expect them to be close, not exact. Brands, cooking losses and portion size all move the real number.' },
        { q: 'Can I correct a value?', a: 'Yes. Servings, amounts and the nutrition values themselves are all editable on the recipe.' },
        { q: 'Does it count what I ate?', a: 'EasyPlate counts what is planned: the meal plan’s recipes add up into daily and weekly totals. It is not a food diary with a barcode scanner.' },
        { q: 'Is it free?', a: 'Nutrition estimates are part of saving a recipe. A free account has a daily allowance of AI extractions; EasyPlate Pro removes it.' },
      ],
      cta: { title: 'Know what a serving costs you.', sub: 'Download EasyPlate and save a recipe to see its nutrition.' },
    },
    he: {
      title: 'מחשבון קלוריות למתכון: ערכים תזונתיים למנה | EasyPlate',
      description: 'מדביקים או שומרים כל מתכון ומקבלים קלוריות, חלבון, פחמימות ושומן למנה, ולוח תזונה שבועי לתפריט. חינם לאייפון ולאנדרואיד.',
      keywords: 'מחשבון קלוריות למתכון, חישוב קלוריות למנה, ערכים תזונתיים למתכון, מחשבון ערכים תזונתיים, קלוריות במתכון ביתי, חלבון למנה, אפליקציית ערכים תזונתיים',
      h1: 'מחשבון קלוריות למתכון שעובד על כל מתכון',
      intro: [
        'רוב אפליקציות הקלוריות סופרות מוצרים ארוזים עם ברקוד. למתכון ביתי אין ברקוד: יש בו "2 כוסות קמח", "חופן פטרוזיליה" ו"מספיק ל-4 עד 6". לחשב ביד קלוריות למנה אומר לחפש כל מצרך, להמיר יחידות ולחלק, וכמעט אף אחד לא עושה את זה פעמיים.',
        'EasyPlate מעריכה ערכים תזונתיים לכל מתכון שאתם שומרים, אוטומטית. ה-AI קורא את רשימת המצרכים עם הכמויות ואת מספר המנות, ומחזיר קלוריות, חלבון, פחמימות ושומן למנה. משנים את מספר המנות או כמות והמספרים מתעדכנים. התפריט השבועי מסתכם ללוח תזונה, לפי יום ולפי שבוע.',
      ],
      sections: [
        { h2: 'מה מחושב, ואיך', p: 'ההערכה נעשית מהמצרכים כפי שנכתבו, לא מתמונה של הצלחת:', bullets: ['קלוריות, חלבון, פחמימות ושומן למנה.', 'מספר המנות שבמתכון קובע את החלוקה; כוונו אותו למה שבאמת יוצא לכם.', 'הגדלה או הקטנה של המתכון שומרת את הערכים למנה ומחשבת מחדש את הסך הכול.', 'מצרכים בלי כמות ("מלח לפי הטעם") נחשבים זניחים.'] },
        { h2: 'ממתכון אחד לשבוע שלם', p: 'כי כל מתכון נושא את הערכים שלו, גם תפריט שבועי שבנוי ממתכונים נושא אותם. לוח התזונה מציג את הסיכום של כל יום ושל השבוע, אז רואים במבט אם יום שלישי הוא כולו פחמימות או איפה חסר חלבון.', bullets: ['סיכומים ליום ולשבוע מהתפריט.', 'לפריטים מהירים בלי מתכון אפשר להזין ערכים ביד.', 'תפריט משותף מציג את אותם מספרים לכל המשפחה.', 'שום דבר לרשום אחרי האוכל: התפריט הוא היומן.'] },
        { h2: 'הערכה, ומסומנת ככזו', p: 'המספרים הם הערכת AI מערכים סטנדרטיים למצרכים, לא ניתוח מעבדה. הם טובים מספיק כדי להשוות מתכונים, לזהות ארוחת ערב כבדה במיוחד או לתכנן שבוע מאוזן; הם לא תחליף לייעוץ רפואי, והאלרגנים מופיעים בנפרד כדי ששורת תזונה לעולם לא תסתיר אחד.', bullets: ['כל ערך ניתן לעריכה אם אתם יודעים טוב יותר.', 'אלרגנים ותגיות תזונה (טבעוני, ללא גלוטן, קטגוריות כשרות) ליד הערכים.', 'עובד בעברית, אנגלית, ערבית, צרפתית ורוסית.'] },
      ],
      steps: [
        { t: 'שומרים או מדביקים מתכון', d: 'מקישור, מסרטון, מ-PDF, מהקלטה או בהקלדה. המצרכים ומספר המנות הם מה שהמחשבון צריך.' },
        { t: 'קוראים את שורת התזונה', d: 'קלוריות, חלבון, פחמימות ושומן למנה מופיעים על המתכון. משנים מנות או כמויות ורואים אותם מתעדכנים.' },
        { t: 'מתכננים את השבוע', d: 'שמים מתכונים על ימי השבוע ופותחים את לוח התזונה לסיכומים יומיים ושבועיים.' },
      ],
      faq: [
        { q: 'צריך להקליד את המצרכים?', a: 'לא. לכל מתכון ש-EasyPlate מחלצת מקישור, סרטון, PDF או הקלטה כבר יש מצרכים וכמויות, והערכים מחושבים מהם.' },
        { q: 'כמה מדויקות הקלוריות?', a: 'אלה הערכות מערכים סטנדרטיים למצרך, אז צפו למספר קרוב, לא מדויק. מותגים, איבודי בישול וגודל המנה כולם מזיזים את המספר האמיתי.' },
        { q: 'אפשר לתקן ערך?', a: 'כן. מספר מנות, כמויות והערכים התזונתיים עצמם, הכול ניתן לעריכה במתכון.' },
        { q: 'זה סופר מה שאכלתי?', a: 'EasyPlate סופרת מה שמתוכנן: המתכונים בתפריט מסתכמים לסיכומים יומיים ושבועיים. זה לא יומן אוכל עם סורק ברקודים.' },
        { q: 'זה חינם?', a: 'הערכת הערכים התזונתיים היא חלק משמירת מתכון. לחשבון חינמי יש מכסה יומית של חילוצי AI; EasyPlate Pro מסירה אותה.' },
      ],
      cta: { title: 'לדעת מה מנה עולה לכם.', sub: 'הורידו את EasyPlate ושמרו מתכון כדי לראות את הערכים שלו.' },
    },
    ar: {
      title: 'حاسبة سعرات الوصفات: القيم الغذائية لكل حصة | EasyPlate',
      description: 'الصق أو احفظ أي وصفة واحصل على السعرات والبروتين والكربوهيدرات والدهون لكل حصة، مع لوحة تغذية أسبوعية لخطتك. مجاني على iOS وأندرويد.',
      keywords: 'حاسبة سعرات الوصفات, حساب السعرات لكل حصة, القيم الغذائية للوصفة, حاسبة القيم الغذائية, سعرات وصفة منزلية, بروتين لكل حصة',
      h1: 'حاسبة سعرات حرارية تعمل على أي وصفة',
      intro: [
        'تحسب معظم تطبيقات السعرات الأطعمة المعبّأة ذات الباركود. أما الوصفة المنزلية فلا باركود لها: فيها "كوبان من الدقيق" و"حفنة بقدونس" و"تكفي 4 إلى 6 أشخاص". حساب السعرات لكل حصة يدويًا يعني البحث عن كل مكوّن وتحويل الوحدات والقسمة، ولا أحد تقريبًا يفعل ذلك مرتين.',
        'يقدّر EasyPlate القيم الغذائية لكل وصفة تحفظها تلقائيًا. يقرأ الذكاء الاصطناعي قائمة المكوّنات بكمياتها وعدد الحصص، ويعيد السعرات والبروتين والكربوهيدرات والدهون لكل حصة. غيّر الحصص أو كمية فتتبعها الأرقام. ثم تُجمع خطة الأسبوع في لوحة تغذية، لكل يوم ولكل أسبوع.',
      ],
      sections: [
        { h2: 'ما يُحسب وكيف', p: 'يُحسب التقدير من المكوّنات كما كُتبت، لا من صورة الطبق:', bullets: ['السعرات والبروتين والكربوهيدرات والدهون لكل حصة.', 'عدد الحصص في الوصفة يحدد القسمة؛ اضبطه على ما تحصل عليه فعلًا.', 'تكبير الوصفة أو تصغيرها يحافظ على قيم الحصة ويعيد حساب المجموع.', 'المكوّنات بلا كمية ("ملح حسب الذوق") تُعدّ مهملة.'] },
        { h2: 'من وصفة واحدة إلى الأسبوع كله', p: 'لأن كل وصفة تحمل قيمها الغذائية، تحملها أيضًا خطة الوجبات الأسبوعية المبنية من وصفات. تعرض لوحة التغذية مجاميع كل يوم والأسبوع، فترى بنظرة إن كان يوم الثلاثاء كله كربوهيدرات أو أين ينقص البروتين.', bullets: ['مجاميع يومية وأسبوعية من خطة الوجبات.', 'يمكن إعطاء العناصر السريعة بلا وصفة قيمًا يدويًا.', 'الخطط المشتركة تعرض الأرقام نفسها لكل العائلة.', 'لا شيء لتسجيله بعد الأكل: الخطة هي السجل.'] },
        { h2: 'تقدير، ومُعلَّم بصدق', p: 'الأرقام تقدير بالذكاء الاصطناعي من القيم القياسية للمكوّنات، لا تحليل مختبري. تكفي لمقارنة الوصفات، أو رصد عشاء ثقيل جدًا، أو تخطيط أسبوع متوازن؛ وهي ليست بديلًا عن الاستشارة الطبية، وتُدرج مسببات الحساسية على حدة حتى لا يخفيها سطر التغذية أبدًا.', bullets: ['كل قيمة قابلة للتعديل إن كنت تعرف أفضل.', 'مسببات الحساسية والوسوم الغذائية (نباتي، خالٍ من الغلوتين، فئات الكوشر) بجانب القيم.', 'يعمل بالعربية والعبرية والإنجليزية والفرنسية والروسية.'] },
      ],
      steps: [
        { t: 'احفظ أو الصق وصفة', d: 'من رابط أو فيديو أو PDF أو رسالة صوتية أو بكتابتك. المكوّنات وعدد الحصص هما ما تحتاجه الحاسبة.' },
        { t: 'اقرأ سطر التغذية', d: 'تظهر السعرات والبروتين والكربوهيدرات والدهون لكل حصة على الوصفة. عدّل الحصص أو الكميات وراقبها تتحدث.' },
        { t: 'خطّط الأسبوع', d: 'ضع الوصفات على أيام الأسبوع وافتح لوحة التغذية للمجاميع اليومية والأسبوعية.' },
      ],
      faq: [
        { q: 'هل عليّ كتابة المكوّنات؟', a: 'لا. أي وصفة يستخرجها EasyPlate من رابط أو فيديو أو PDF أو رسالة صوتية تحتوي مكوّناتها وكمياتها، وتُقدَّر القيم منها.' },
        { q: 'ما مدى دقة السعرات؟', a: 'إنها تقديرات من قيم قياسية لكل مكوّن، فتوقّع رقمًا قريبًا لا دقيقًا. العلامات التجارية وفقد الطهي وحجم الحصة كلها تغيّر الرقم الحقيقي.' },
        { q: 'هل يمكنني تصحيح قيمة؟', a: 'نعم. الحصص والكميات والقيم الغذائية نفسها كلها قابلة للتعديل في الوصفة.' },
        { q: 'هل يحسب ما أكلته؟', a: 'يحسب EasyPlate ما هو مخطط: وصفات خطة الوجبات تُجمع في مجاميع يومية وأسبوعية. ليس مذكرة طعام بماسح باركود.' },
        { q: 'هل هو مجاني؟', a: 'تقدير القيم الغذائية جزء من حفظ الوصفة. للحساب المجاني حصة يومية من الاستخراجات بالذكاء الاصطناعي؛ يزيلها EasyPlate Pro.' },
      ],
      cta: { title: 'اعرف ما تكلّفك الحصة.', sub: 'حمّل EasyPlate واحفظ وصفة لترى قيمها الغذائية.' },
    },
    fr: {
      title: 'Calculateur de calories par recette et portion | EasyPlate',
      description: 'Collez ou enregistrez une recette : calories, protéines, glucides et lipides par portion, plus un tableau nutrition hebdomadaire. Gratuit sur iOS et Android.',
      keywords: 'calculateur calories recette, calories par portion, calcul nutrition recette, macros par portion, valeurs nutritionnelles recette, compteur calories recettes',
      h1: 'Un calculateur de calories qui fonctionne sur n’importe quelle recette',
      intro: [
        'La plupart des applis de calories comptent des produits emballés avec code-barres. Une recette maison n’a pas de code-barres : elle a « 2 tasses de farine », « une poignée de persil » et « pour 4 à 6 personnes ». Calculer les calories par portion à la main, c’est chercher chaque ingrédient, convertir les unités et diviser, et presque personne ne le fait deux fois.',
        'EasyPlate estime la nutrition de chaque recette enregistrée, automatiquement. L’IA lit la liste d’ingrédients avec les quantités et le nombre de portions, et renvoie calories, protéines, glucides et lipides par portion. Changez les portions ou une quantité, les chiffres suivent. Le menu de la semaine s’additionne ensuite dans un tableau nutrition, par jour et par semaine.',
      ],
      sections: [
        { h2: 'Ce qui est calculé, et comment', p: 'L’estimation part des ingrédients tels qu’écrits, pas d’une photo de l’assiette :', bullets: ['Calories, protéines, glucides et lipides par portion.', 'Le nombre de portions de la recette décide de la division ; réglez-le sur ce que vous obtenez vraiment.', 'Ajuster une recette à plus ou moins de portions conserve les valeurs par portion et recalcule le total.', 'Les ingrédients sans quantité (« sel au goût ») sont considérés comme négligeables.'] },
        { h2: 'D’une recette à toute la semaine', p: 'Comme chaque recette porte sa nutrition, un menu hebdomadaire construit avec des recettes la porte aussi. Le tableau nutrition montre les totaux de chaque jour et de la semaine, pour voir d’un coup d’œil si mardi n’est que glucides ou où manquent les protéines.', bullets: ['Totaux par jour et par semaine depuis le menu.', 'Les éléments rapides sans recette peuvent recevoir des valeurs à la main.', 'Les menus partagés montrent les mêmes chiffres à toute la famille.', 'Rien à saisir après le repas : le menu est le journal.'] },
        { h2: 'Une estimation, dite comme telle', p: 'Les chiffres sont une estimation IA à partir de valeurs standard par ingrédient, pas une analyse de laboratoire. Ils suffisent pour comparer des recettes, repérer un dîner très lourd ou planifier une semaine équilibrée ; ils ne remplacent pas un avis médical, et les allergènes sont listés à part pour qu’une ligne nutrition n’en cache jamais un.', bullets: ['Chaque valeur est modifiable si vous savez mieux.', 'Allergènes et tags alimentaires (végan, sans gluten, catégories casher) à côté de la nutrition.', 'Fonctionne en français, anglais, hébreu, arabe et russe.'] },
      ],
      steps: [
        { t: 'Enregistrez ou collez une recette', d: 'Depuis un lien, une vidéo, un PDF, une note vocale ou votre propre saisie. Les ingrédients et les portions sont ce dont le calculateur a besoin.' },
        { t: 'Lisez la ligne nutrition', d: 'Calories, protéines, glucides et lipides par portion apparaissent sur la recette. Ajustez portions ou quantités et regardez-les se mettre à jour.' },
        { t: 'Planifiez la semaine', d: 'Placez des recettes sur les jours de la semaine et ouvrez le tableau nutrition pour les totaux quotidiens et hebdomadaires.' },
      ],
      faq: [
        { q: 'Dois-je saisir les ingrédients ?', a: 'Non. Toute recette qu’EasyPlate extrait d’un lien, d’une vidéo, d’un PDF ou d’une note vocale a déjà ses ingrédients et quantités, et la nutrition en est estimée.' },
        { q: 'Les calories sont-elles précises ?', a: 'Ce sont des estimations à partir de valeurs standard par ingrédient : attendez-vous à un chiffre proche, pas exact. Marques, pertes à la cuisson et taille des portions font bouger la vraie valeur.' },
        { q: 'Puis-je corriger une valeur ?', a: 'Oui. Portions, quantités et valeurs nutritionnelles elles-mêmes sont modifiables sur la recette.' },
        { q: 'Compte-t-il ce que j’ai mangé ?', a: 'EasyPlate compte ce qui est planifié : les recettes du menu s’additionnent en totaux quotidiens et hebdomadaires. Ce n’est pas un journal alimentaire avec scanner de code-barres.' },
        { q: 'Est-ce gratuit ?', a: 'L’estimation nutritionnelle fait partie de l’enregistrement d’une recette. Un compte gratuit a un quota quotidien d’extractions IA ; EasyPlate Pro le supprime.' },
      ],
      cta: { title: 'Sachez ce qu’une portion vous coûte.', sub: 'Téléchargez EasyPlate et enregistrez une recette pour voir sa nutrition.' },
    },
    ru: {
      title: 'Калькулятор калорий рецепта: КБЖУ на порцию | EasyPlate',
      description: 'Вставьте или сохраните любой рецепт и получите калории, белки, углеводы и жиры на порцию, а также недельную панель питания. Бесплатно для iOS и Android.',
      keywords: 'калькулятор калорий рецепта, калории на порцию, кбжу рецепта, расчёт калорийности блюда, пищевая ценность рецепта, счётчик калорий рецепты',
      h1: 'Калькулятор калорий, который работает с любым рецептом',
      intro: [
        'Большинство приложений для подсчёта калорий считают упакованные продукты со штрихкодом. У домашнего рецепта штрихкода нет: в нём «2 стакана муки», «горсть петрушки» и «на 4–6 порций». Считать калории на порцию вручную — значит искать каждый ингредиент, переводить единицы и делить, и почти никто не делает этого дважды.',
        'EasyPlate оценивает КБЖУ каждого сохранённого рецепта автоматически. ИИ читает список ингредиентов с количествами и число порций и возвращает калории, белки, углеводы и жиры на порцию. Измените порции или количество — цифры пересчитаются. Меню на неделю складывается в панель питания по дням и за неделю.',
      ],
      sections: [
        { h2: 'Что считается и как', p: 'Оценка делается по ингредиентам, как они записаны, а не по фото тарелки:', bullets: ['Калории, белки, углеводы и жиры на порцию.', 'Число порций в рецепте определяет деление; выставьте то, что реально получается.', 'Масштабирование рецепта сохраняет значения на порцию и пересчитывает итог.', 'Ингредиенты без количества («соль по вкусу») считаются незначительными.'] },
        { h2: 'От одного рецепта ко всей неделе', p: 'Раз каждый рецепт несёт своё КБЖУ, несёт его и недельное меню, собранное из рецептов. Панель питания показывает итоги каждого дня и недели, так что сразу видно, что во вторник одни углеводы или где не хватает белка.', bullets: ['Итоги по дням и за неделю из меню.', 'Быстрым пунктам без рецепта значения можно задать вручную.', 'Общие меню показывают те же цифры всей семье.', 'Ничего не записывать после еды: меню и есть дневник.'] },
        { h2: 'Оценка, честно обозначенная', p: 'Цифры — оценка ИИ по стандартным значениям ингредиентов, а не лабораторный анализ. Их хватает, чтобы сравнить рецепты, заметить слишком тяжёлый ужин или спланировать сбалансированную неделю; они не заменяют медицинский совет, а аллергены указаны отдельно, чтобы строка КБЖУ никогда их не скрывала.', bullets: ['Любое значение можно изменить, если вы знаете лучше.', 'Аллергены и пищевые теги (веган, без глютена, кошерные категории) рядом с КБЖУ.', 'Работает на русском, английском, иврите, арабском и французском.'] },
      ],
      steps: [
        { t: 'Сохраните или вставьте рецепт', d: 'Из ссылки, видео, PDF, голосового сообщения или набрав вручную. Калькулятору нужны ингредиенты и число порций.' },
        { t: 'Прочитайте строку КБЖУ', d: 'Калории, белки, углеводы и жиры на порцию появятся в рецепте. Измените порции или количества и увидите пересчёт.' },
        { t: 'Спланируйте неделю', d: 'Поставьте рецепты на дни недели и откройте панель питания с дневными и недельными итогами.' },
      ],
      faq: [
        { q: 'Нужно ли вводить ингредиенты?', a: 'Нет. У любого рецепта, который EasyPlate извлекает из ссылки, видео, PDF или голосового, уже есть ингредиенты и количества, и КБЖУ оценивается по ним.' },
        { q: 'Насколько точны калории?', a: 'Это оценки по стандартным значениям на ингредиент: ждите близкой, а не точной цифры. Бренды, потери при готовке и размер порции меняют реальное число.' },
        { q: 'Можно исправить значение?', a: 'Да. Порции, количества и сами значения КБЖУ редактируются в рецепте.' },
        { q: 'Считает ли оно, что я съел?', a: 'EasyPlate считает запланированное: рецепты меню складываются в дневные и недельные итоги. Это не дневник питания со сканером штрихкодов.' },
        { q: 'Это бесплатно?', a: 'Оценка КБЖУ — часть сохранения рецепта. У бесплатного аккаунта есть дневная квота извлечений ИИ; EasyPlate Pro снимает её.' },
      ],
      cta: { title: 'Знайте, во что обходится порция.', sub: 'Скачайте EasyPlate и сохраните рецепт, чтобы увидеть его КБЖУ.' },
    },
  },

  // ------------------------------------------------------------------ Receipts / prices
  'grocery-prices-receipt-scanner': {
    icon: 'receipt', screens: ['08_grocery', '06_meal_plan'],
    en: {
      title: 'Grocery List with Prices from Your Receipts | EasyPlate',
      description: 'Scan supermarket receipts, keep your own price book and see what next week’s grocery list will cost before you shop. Free on iOS and Android.',
      keywords: 'grocery list with prices, receipt scanner app, grocery price tracker, estimate grocery cost, price book app, supermarket receipt app, grocery budget',
      h1: 'A grocery list that knows what it will cost',
      intro: [
        'The supermarket is the one place where the bill is a surprise every time. A grocery list says what to buy, never what it adds up to, and the only record of last week’s prices is a crumpled receipt in the car.',
        'EasyPlate reads the receipt instead. Scan it with the camera, pick it from the gallery or share a PDF receipt, and the AI pulls out the products, quantities and prices into your personal price book. From then on the grocery list shows an estimated cost for the week, built from the prices you actually paid, and you can see what each line costs before you leave the house.',
      ],
      sections: [
        { h2: 'What a receipt scan keeps', p: 'A receipt scan stores only what is needed to price your list, and nothing about the payment:', bullets: ['Product names, quantities and the price paid.', 'Not the store, the date, the card or who paid.', 'Each product joins your price book; the latest price is the one used for estimates.', 'Fix a misread line or add a price by hand at any time.'] },
        { h2: 'The estimated cost of the week', p: 'When the grocery list is built from the meal plan, every line is matched against the price book and the card at the bottom shows the estimate and how much of the list is priced. Lines with no price yet are listed, so one scan of the next receipt fills most of them in.', bullets: ['Estimate per line and for the whole list.', 'Coverage: how many lines have a known price.', 'Works for lists from the meal plan, from a single recipe or written by hand.', 'Shared lists show the owner’s estimate to everyone.'] },
        { h2: 'Community prices, if you want them', p: 'With an opt-in setting, the prices from your receipts are added anonymously to community medians, and lines you have never bought are estimated from what other shoppers paid. Nothing identifying leaves your account, and the switch is off by default.', bullets: ['Opt in from Preferences; off by default.', 'Only product name, quantity and price are contributed.', 'Your own price always wins over the community figure.'] },
      ],
      steps: [
        { t: 'Scan the receipt', d: 'From the grocery list or the price book: camera, gallery or a PDF receipt. The AI reads the lines in a few seconds.' },
        { t: 'Check the price book', d: 'Products and prices appear in your price book. Correct a line if the receipt was smudged.' },
        { t: 'Read the estimate', d: 'The next grocery list shows what it will cost, line by line and in total, before you shop.' },
      ],
      faq: [
        { q: 'Which receipts can it read?', a: 'Printed supermarket receipts photographed with the camera or picked from the gallery, and PDF receipts from online orders. Crumpled or faded lines may need a correction.' },
        { q: 'Does it store my payment details?', a: 'No. Only product names, quantities and prices are kept. The store, date, card and payer are not recorded.' },
        { q: 'Is the estimate exact?', a: 'It is built from the last price you paid for each product, so it is as current as your last receipt. Prices change, so treat it as a close estimate.' },
        { q: 'Can I add prices without a receipt?', a: 'Yes. Any product in the price book, and any line on the list, can be given a price by hand.' },
        { q: 'Is it free?', a: 'The price book and the estimate are free. Receipt reading uses an AI extraction from the daily allowance; EasyPlate Pro removes the limit.' },
      ],
      cta: { title: 'No more surprises at the checkout.', sub: 'Download EasyPlate and scan your next receipt.' },
    },
    he: {
      title: 'רשימת קניות עם מחירים מהקבלות שלכם | EasyPlate',
      description: 'סורקים קבלות מהסופר, שומרים ספר מחירים אישי ורואים כמה רשימת הקניות של השבוע הבא תעלה עוד לפני הקנייה. חינם לאייפון ולאנדרואיד.',
      keywords: 'רשימת קניות עם מחירים, סריקת קבלות, אפליקציה לסריקת קבלות, מעקב מחירים בסופר, הערכת עלות קניות, ספר מחירים, תקציב קניות לסופר, השוואת מחירים סופר',
      h1: 'רשימת קניות שיודעת כמה היא תעלה',
      intro: [
        'הסופר הוא המקום היחיד שבו החשבון מפתיע בכל פעם. רשימת קניות אומרת מה לקנות, אף פעם לא כמה זה מצטבר, והתיעוד היחיד של המחירים משבוע שעבר הוא קבלה מקומטת באוטו.',
        'EasyPlate קוראת את הקבלה במקומכם. מצלמים אותה, בוחרים מהגלריה או משתפים קבלת PDF, וה-AI שולף את המוצרים, הכמויות והמחירים לספר המחירים האישי שלכם. מאותו רגע רשימת הקניות מציגה עלות משוערת לשבוע, שבנויה מהמחירים שבאמת שילמתם, ורואים כמה כל שורה עולה לפני שיוצאים מהבית.',
      ],
      sections: [
        { h2: 'מה סריקת קבלה שומרת', p: 'סריקת קבלה שומרת רק מה שצריך כדי לתמחר את הרשימה, ושום דבר על התשלום:', bullets: ['שמות מוצרים, כמויות והמחיר ששולם.', 'לא את החנות, התאריך, הכרטיס או מי שילם.', 'כל מוצר מצטרף לספר המחירים; המחיר האחרון הוא זה שמשמש להערכה.', 'מתקנים שורה שנקראה לא נכון או מוסיפים מחיר ביד בכל עת.'] },
        { h2: 'העלות המשוערת של השבוע', p: 'כשרשימת הקניות נבנית מהתפריט, כל שורה מותאמת מול ספר המחירים והכרטיס בתחתית מציג את ההערכה ואיזה חלק מהרשימה מתומחר. שורות שעדיין אין להן מחיר רשומות, כך שסריקה אחת של הקבלה הבאה ממלאת את רובן.', bullets: ['הערכה לכל שורה ולרשימה כולה.', 'כיסוי: כמה שורות עם מחיר ידוע.', 'עובד לרשימות מהתפריט, ממתכון בודד או כתובות ביד.', 'רשימה משותפת מציגה את ההערכה של הבעלים לכולם.'] },
        { h2: 'מחירי קהילה, אם רוצים', p: 'עם הגדרה שמפעילים בעצמכם, המחירים מהקבלות שלכם מצטרפים באופן אנונימי לחציוני הקהילה, ושורות שמעולם לא קניתם מוערכות לפי מה שקונים אחרים שילמו. שום דבר מזהה לא יוצא מהחשבון, והמתג כבוי כברירת מחדל.', bullets: ['מפעילים בהעדפות; כבוי כברירת מחדל.', 'נתרמים רק שם מוצר, כמות ומחיר.', 'המחיר שלכם תמיד גובר על המספר הקהילתי.'] },
      ],
      steps: [
        { t: 'סורקים את הקבלה', d: 'מרשימת הקניות או מספר המחירים: מצלמה, גלריה או קבלת PDF. ה-AI קורא את השורות תוך שניות.' },
        { t: 'בודקים את ספר המחירים', d: 'המוצרים והמחירים מופיעים בספר המחירים. מתקנים שורה אם הקבלה הייתה מרוחה.' },
        { t: 'קוראים את ההערכה', d: 'רשימת הקניות הבאה מציגה כמה היא תעלה, שורה שורה ובסך הכול, לפני הקנייה.' },
      ],
      faq: [
        { q: 'אילו קבלות אפשר לקרוא?', a: 'קבלות מודפסות מהסופר שצולמו במצלמה או נבחרו מהגלריה, וקבלות PDF מהזמנות אונליין. שורות מקומטות או דהויות עשויות לדרוש תיקון.' },
        { q: 'זה שומר פרטי תשלום?', a: 'לא. נשמרים רק שמות מוצרים, כמויות ומחירים. החנות, התאריך, הכרטיס והמשלם לא נרשמים.' },
        { q: 'ההערכה מדויקת?', a: 'היא בנויה מהמחיר האחרון ששילמתם על כל מוצר, אז היא עדכנית כמו הקבלה האחרונה שלכם. מחירים משתנים, אז התייחסו אליה כהערכה קרובה.' },
        { q: 'אפשר להוסיף מחירים בלי קבלה?', a: 'כן. לכל מוצר בספר המחירים ולכל שורה ברשימה אפשר לתת מחיר ביד.' },
        { q: 'זה חינם?', a: 'ספר המחירים וההערכה חינמיים. קריאת קבלה משתמשת בחילוץ AI מהמכסה היומית; EasyPlate Pro מסירה את המגבלה.' },
      ],
      cta: { title: 'בלי הפתעות בקופה.', sub: 'הורידו את EasyPlate וסרקו את הקבלה הבאה שלכם.' },
    },
    ar: {
      title: 'قائمة تسوّق بأسعار من فواتيرك | EasyPlate',
      description: 'امسح فواتير السوبرماركت، واحتفظ بدفتر أسعارك الخاص، وشاهد كم ستكلّف قائمة الأسبوع القادم قبل التسوّق. مجاني على iOS وأندرويد.',
      keywords: 'قائمة تسوّق بالأسعار, تطبيق مسح الفواتير, تتبع أسعار السوبرماركت, تقدير تكلفة التسوّق, دفتر أسعار, ميزانية التسوّق',
      h1: 'قائمة تسوّق تعرف كم ستكلّف',
      intro: [
        'السوبرماركت هو المكان الوحيد الذي تفاجئك فيه الفاتورة كل مرة. تقول قائمة التسوّق ما تشتريه، لا كم يبلغ المجموع، والسجل الوحيد لأسعار الأسبوع الماضي فاتورة مجعّدة في السيارة.',
        'يقرأ EasyPlate الفاتورة بدلًا منك. صوّرها بالكاميرا أو اخترها من المعرض أو شارك فاتورة PDF، فيستخرج الذكاء الاصطناعي المنتجات والكميات والأسعار إلى دفتر أسعارك الخاص. ومن ثم تعرض قائمة التسوّق تكلفة تقديرية للأسبوع مبنية على الأسعار التي دفعتها فعلًا، وترى كم يكلّف كل سطر قبل أن تغادر البيت.',
      ],
      sections: [
        { h2: 'ما تحتفظ به عملية مسح الفاتورة', p: 'يحفظ مسح الفاتورة فقط ما يلزم لتسعير قائمتك، ولا شيء عن الدفع:', bullets: ['أسماء المنتجات والكميات والسعر المدفوع.', 'لا المتجر ولا التاريخ ولا البطاقة ولا من دفع.', 'ينضم كل منتج إلى دفتر الأسعار؛ وآخر سعر هو المستخدم في التقدير.', 'صحّح سطرًا قُرئ خطأ أو أضف سعرًا يدويًا في أي وقت.'] },
        { h2: 'التكلفة التقديرية للأسبوع', p: 'عندما تُبنى قائمة التسوّق من خطة الوجبات، يُطابَق كل سطر مع دفتر الأسعار وتعرض البطاقة في الأسفل التقدير ونسبة القائمة المسعّرة. تُدرج الأسطر التي لا سعر لها بعد، فمسح واحد للفاتورة التالية يملأ معظمها.', bullets: ['تقدير لكل سطر وللقائمة كلها.', 'التغطية: كم سطرًا له سعر معروف.', 'يعمل مع القوائم من خطة الوجبات أو من وصفة واحدة أو المكتوبة يدويًا.', 'القوائم المشتركة تعرض تقدير المالك للجميع.'] },
        { h2: 'أسعار المجتمع، إن أردت', p: 'بإعداد تفعّله بنفسك، تُضاف أسعار فواتيرك مجهولة الهوية إلى وسيط أسعار المجتمع، وتُقدَّر الأسطر التي لم تشترها قط مما دفعه متسوّقون آخرون. لا يخرج أي شيء يعرّفك من حسابك، والمفتاح مطفأ افتراضيًا.', bullets: ['فعّله من التفضيلات؛ مطفأ افتراضيًا.', 'يُساهَم فقط باسم المنتج والكمية والسعر.', 'سعرك الخاص يتقدّم دائمًا على رقم المجتمع.'] },
      ],
      steps: [
        { t: 'امسح الفاتورة', d: 'من قائمة التسوّق أو دفتر الأسعار: الكاميرا أو المعرض أو فاتورة PDF. يقرأ الذكاء الاصطناعي الأسطر في ثوانٍ.' },
        { t: 'راجع دفتر الأسعار', d: 'تظهر المنتجات والأسعار في دفتر أسعارك. صحّح سطرًا إن كانت الفاتورة باهتة.' },
        { t: 'اقرأ التقدير', d: 'تعرض قائمة التسوّق التالية كم ستكلّف، سطرًا سطرًا وبالمجموع، قبل التسوّق.' },
      ],
      faq: [
        { q: 'أي فواتير يمكنه قراءتها؟', a: 'فواتير السوبرماركت المطبوعة المصوّرة بالكاميرا أو المختارة من المعرض، وفواتير PDF من الطلبات الإلكترونية. قد تحتاج الأسطر المجعّدة أو الباهتة إلى تصحيح.' },
        { q: 'هل يخزّن بيانات الدفع؟', a: 'لا. تُحفظ فقط أسماء المنتجات والكميات والأسعار. لا يُسجَّل المتجر ولا التاريخ ولا البطاقة ولا الدافع.' },
        { q: 'هل التقدير دقيق؟', a: 'يُبنى من آخر سعر دفعته لكل منتج، فهو حديث بقدر فاتورتك الأخيرة. تتغير الأسعار، فاعتبره تقديرًا قريبًا.' },
        { q: 'هل يمكنني إضافة أسعار بلا فاتورة؟', a: 'نعم. يمكن إعطاء أي منتج في دفتر الأسعار وأي سطر في القائمة سعرًا يدويًا.' },
        { q: 'هل هو مجاني؟', a: 'دفتر الأسعار والتقدير مجانيان. تستخدم قراءة الفاتورة استخراجًا بالذكاء الاصطناعي من الحصة اليومية؛ يزيل EasyPlate Pro الحد.' },
      ],
      cta: { title: 'لا مفاجآت عند الصندوق.', sub: 'حمّل EasyPlate وامسح فاتورتك التالية.' },
    },
    fr: {
      title: 'Liste de courses avec prix depuis vos tickets | EasyPlate',
      description: 'Scannez vos tickets de caisse, gardez votre carnet de prix et voyez ce que coûtera la liste de la semaine prochaine avant d’y aller. Gratuit sur iOS et Android.',
      keywords: 'liste de courses avec prix, scanner ticket de caisse, suivi prix supermarché, estimer coût courses, carnet de prix, budget courses',
      h1: 'Une liste de courses qui sait ce qu’elle va coûter',
      intro: [
        'Le supermarché est le seul endroit où l’addition surprend à chaque fois. Une liste de courses dit quoi acheter, jamais combien ça fait, et la seule trace des prix de la semaine dernière est un ticket froissé dans la voiture.',
        'EasyPlate lit le ticket à votre place. Photographiez-le, choisissez-le dans la galerie ou partagez un ticket PDF : l’IA extrait les produits, les quantités et les prix dans votre carnet de prix personnel. Dès lors, la liste de courses affiche un coût estimé pour la semaine, construit à partir des prix que vous avez vraiment payés, et vous voyez ce que coûte chaque ligne avant de sortir.',
      ],
      sections: [
        { h2: 'Ce qu’un scan de ticket conserve', p: 'Un scan ne garde que ce qu’il faut pour chiffrer votre liste, et rien sur le paiement :', bullets: ['Noms des produits, quantités et prix payé.', 'Ni le magasin, ni la date, ni la carte, ni qui a payé.', 'Chaque produit rejoint votre carnet de prix ; le dernier prix sert aux estimations.', 'Corrigez une ligne mal lue ou ajoutez un prix à la main à tout moment.'] },
        { h2: 'Le coût estimé de la semaine', p: 'Quand la liste est construite depuis le menu, chaque ligne est rapprochée du carnet de prix et la carte en bas montre l’estimation et la part de la liste chiffrée. Les lignes sans prix sont listées : un scan du prochain ticket en remplit la plupart.', bullets: ['Estimation par ligne et pour toute la liste.', 'Couverture : combien de lignes ont un prix connu.', 'Fonctionne pour les listes issues du menu, d’une seule recette ou écrites à la main.', 'Les listes partagées montrent l’estimation du propriétaire à tous.'] },
        { h2: 'Les prix de la communauté, si vous voulez', p: 'Avec un réglage à activer vous-même, les prix de vos tickets rejoignent anonymement les médianes de la communauté, et les lignes que vous n’avez jamais achetées sont estimées d’après ce que d’autres ont payé. Rien d’identifiant ne quitte votre compte, et l’option est désactivée par défaut.', bullets: ['À activer dans les Préférences ; désactivé par défaut.', 'Seuls le nom du produit, la quantité et le prix sont partagés.', 'Votre propre prix l’emporte toujours sur le chiffre communautaire.'] },
      ],
      steps: [
        { t: 'Scannez le ticket', d: 'Depuis la liste de courses ou le carnet de prix : appareil photo, galerie ou ticket PDF. L’IA lit les lignes en quelques secondes.' },
        { t: 'Vérifiez le carnet de prix', d: 'Produits et prix apparaissent dans votre carnet. Corrigez une ligne si le ticket était effacé.' },
        { t: 'Lisez l’estimation', d: 'La prochaine liste de courses affiche ce qu’elle coûtera, ligne par ligne et au total, avant les courses.' },
      ],
      faq: [
        { q: 'Quels tickets peut-il lire ?', a: 'Les tickets de supermarché imprimés, photographiés ou pris dans la galerie, et les tickets PDF des commandes en ligne. Les lignes froissées ou effacées peuvent demander une correction.' },
        { q: 'Enregistre-t-il mes données de paiement ?', a: 'Non. Seuls les noms de produits, quantités et prix sont conservés. Magasin, date, carte et payeur ne sont pas enregistrés.' },
        { q: 'L’estimation est-elle exacte ?', a: 'Elle part du dernier prix payé pour chaque produit, donc elle est aussi à jour que votre dernier ticket. Les prix changent : considérez-la comme une estimation proche.' },
        { q: 'Puis-je ajouter des prix sans ticket ?', a: 'Oui. Tout produit du carnet et toute ligne de la liste peuvent recevoir un prix à la main.' },
        { q: 'Est-ce gratuit ?', a: 'Le carnet de prix et l’estimation sont gratuits. La lecture d’un ticket utilise une extraction IA du quota quotidien ; EasyPlate Pro supprime la limite.' },
      ],
      cta: { title: 'Plus de surprises en caisse.', sub: 'Téléchargez EasyPlate et scannez votre prochain ticket.' },
    },
    ru: {
      title: 'Список покупок с ценами из ваших чеков | EasyPlate',
      description: 'Сканируйте чеки, ведите книгу цен и узнавайте, сколько будет стоить список на следующую неделю, ещё до магазина. Бесплатно для iOS и Android.',
      keywords: 'список покупок с ценами, сканер чеков, учёт цен в супермаркете, оценка стоимости покупок, книга цен, бюджет на продукты',
      h1: 'Список покупок, который знает, сколько будет стоить',
      intro: [
        'Супермаркет — единственное место, где счёт удивляет каждый раз. Список покупок говорит, что купить, но никогда — сколько это выйдет, а единственная запись прошлых цен — мятый чек в машине.',
        'EasyPlate читает чек за вас. Сфотографируйте его, выберите из галереи или поделитесь PDF-чеком — ИИ вытащит товары, количества и цены в вашу личную книгу цен. С этого момента список покупок показывает примерную стоимость недели по ценам, которые вы реально платили, и видно, сколько стоит каждая строка, ещё до выхода из дома.',
      ],
      sections: [
        { h2: 'Что сохраняет скан чека', p: 'Скан сохраняет только то, что нужно для оценки списка, и ничего о платеже:', bullets: ['Названия товаров, количества и уплаченную цену.', 'Не магазин, не дату, не карту и не того, кто платил.', 'Каждый товар попадает в книгу цен; для оценки берётся последняя цена.', 'Исправьте неверно прочитанную строку или добавьте цену вручную в любой момент.'] },
        { h2: 'Примерная стоимость недели', p: 'Когда список собран из меню, каждая строка сверяется с книгой цен, а карточка внизу показывает оценку и долю списка с известными ценами. Строки без цены перечислены, так что один скан следующего чека заполнит большинство.', bullets: ['Оценка по строке и для всего списка.', 'Покрытие: сколько строк с известной ценой.', 'Работает для списков из меню, из одного рецепта или написанных вручную.', 'Общие списки показывают оценку владельца всем.'] },
        { h2: 'Цены сообщества, если хотите', p: 'С настройкой, которую вы включаете сами, цены из ваших чеков анонимно попадают в медианы сообщества, а строки, которые вы никогда не покупали, оцениваются по тому, что платили другие. Ничего идентифицирующего не покидает аккаунт, и переключатель выключен по умолчанию.', bullets: ['Включается в Предпочтениях; по умолчанию выключено.', 'Передаются только название товара, количество и цена.', 'Ваша цена всегда важнее цифры сообщества.'] },
      ],
      steps: [
        { t: 'Отсканируйте чек', d: 'Из списка покупок или книги цен: камера, галерея или PDF-чек. ИИ читает строки за несколько секунд.' },
        { t: 'Проверьте книгу цен', d: 'Товары и цены появляются в вашей книге цен. Исправьте строку, если чек был смазан.' },
        { t: 'Прочитайте оценку', d: 'Следующий список покупок покажет, сколько он будет стоить, построчно и в сумме, до похода в магазин.' },
      ],
      faq: [
        { q: 'Какие чеки он читает?', a: 'Печатные чеки супермаркетов, снятые на камеру или выбранные из галереи, и PDF-чеки онлайн-заказов. Мятые или выцветшие строки могут потребовать правки.' },
        { q: 'Хранит ли он платёжные данные?', a: 'Нет. Сохраняются только названия товаров, количества и цены. Магазин, дата, карта и плательщик не записываются.' },
        { q: 'Оценка точная?', a: 'Она строится по последней цене, которую вы платили за каждый товар, так что актуальна как ваш последний чек. Цены меняются — считайте её близкой оценкой.' },
        { q: 'Можно добавить цены без чека?', a: 'Да. Любому товару в книге цен и любой строке списка можно задать цену вручную.' },
        { q: 'Это бесплатно?', a: 'Книга цен и оценка бесплатны. Чтение чека использует извлечение ИИ из дневной квоты; EasyPlate Pro снимает лимит.' },
      ],
      cta: { title: 'Больше никаких сюрпризов на кассе.', sub: 'Скачайте EasyPlate и отсканируйте следующий чек.' },
    },
  },

  // ------------------------------------------------------------------ Family cookbook
  'family-cookbook': {
    icon: 'users', screens: ['04_library', '05_book_flip'],
    en: {
      title: 'Shared Family Cookbook App | EasyPlate',
      description: 'Collect the family’s recipes into shared digital cookbooks everyone can read or edit, from grandma’s voice note to tonight’s dinner. Free on iOS and Android.',
      keywords: 'family cookbook app, shared cookbook, digital family recipe book, share recipes with family, family recipe app, grandma recipes app, collaborative cookbook',
      h1: 'A family cookbook that everyone can open and add to',
      intro: [
        'Every family has the same archive: a notebook in one kitchen, a WhatsApp thread with photos of handwritten cards, a voice note from grandma explaining the kubbeh, and three people who each have "the real" version of the cholent. None of it is in one place, and none of it is searchable.',
        'EasyPlate turns that archive into shared cookbooks. Each person saves recipes from wherever they have them: a dictated voice note, a PDF, a link, a video, or typing. Recipes go into books that are shared with the family as viewers or editors, and every change reaches everyone in real time. The book is also a real book: a two-page spread you flip through, with a cover you pick.',
      ],
      sections: [
        { h2: 'Getting the old recipes in', p: 'The hard part of a family cookbook is the first fifty recipes. EasyPlate takes them in whatever form they already exist:', bullets: ['A voice note: record grandma, or share a WhatsApp voice message, and it is transcribed into ingredients and steps.', 'A PDF of a typed collection, read as a whole file.', 'A link to a blog or a video, for the recipes that were never written down at home.', 'Typing, with the AI filling in servings, tags and nutrition.'] },
        { h2: 'One book, many hands', p: 'A cookbook is shared with a contact (email or phone), with a code, a link or a QR you show at the table. Viewers read; editors add and change recipes. The owner can remove anyone, and anyone can leave. Recipes inside a shared book stay in sync: an edit made by your sister shows up on your phone.', bullets: ['Viewer or editor, per person.', 'Share by contact, code, link or QR.', 'Live sync of every recipe in the book.', 'Each recipe keeps its own photo, servings, tags and nutrition.'] },
        { h2: 'The whole household on one account', p: 'For a family that cooks from one kitchen, EasyPlate Pro Duo and Pro Family open a shared household: recipes, books, meal plans, grocery lists and receipts live under the household, every member sees and edits them, and the subscriber’s Pro status covers everyone. Preferences and profiles stay personal.', bullets: ['Pro Duo: two accounts. Pro Family: up to six.', 'Shared recipes, books, plans, lists and price book.', 'Join with one code; leave or be removed at any time.'] },
      ],
      steps: [
        { t: 'Make a book', d: 'Name it, pick a cover (a photo, or one the AI draws from a theme) and add the first recipes from voice notes, PDFs, links or typing.' },
        { t: 'Share it', d: 'Send an invite to a contact, or show a code or QR. Choose whether they read or edit.' },
        { t: 'Cook from it', d: 'Open the book like a real one, flip to a recipe, scale it to tonight’s table and start Cook Mode.' },
      ],
      faq: [
        { q: 'Can grandma use it?', a: 'She does not have to. Record her explaining a recipe, or forward her WhatsApp voice note to EasyPlate, and the AI writes it down. You can read it back to her to check.' },
        { q: 'Can we import a scanned handwritten card?', a: 'Not as a photo yet. Dictate it as a voice note or type it; a typed collection saved as a PDF is read as a file.' },
        { q: 'Who can change a shared recipe?', a: 'Editors can; viewers cannot. The owner of the book decides each person’s role and can change it later.' },
        { q: 'What happens if someone leaves?', a: 'Their copy of the shared book is removed from their device. The book and its recipes stay with the owner and the other members.' },
        { q: 'Do we need Pro?', a: 'Sharing a book is available on a free account, with a limit on how many books can be shared at once. Pro Duo and Pro Family add a shared household for everything.' },
      ],
      cta: { title: 'Grandma’s recipes, in everyone’s pocket.', sub: 'Download EasyPlate and start the family book.' },
    },
    he: {
      title: 'ספר מתכונים משפחתי משותף: ספר אחד לכולם | EasyPlate',
      description: 'אוספים את מתכוני המשפחה לספרי מתכונים דיגיטליים שכולם קוראים או עורכים, מההקלטה של סבתא ועד ארוחת הערב של היום. חינם לאייפון ולאנדרואיד.',
      keywords: 'ספר מתכונים משפחתי, ספר מתכונים דיגיטלי, ספר מתכונים משותף, לשתף מתכונים עם המשפחה, המתכונים של סבתא, אפליקציית מתכונים למשפחה, ספר מתכונים אישי',
      h1: 'ספר מתכונים משפחתי שכולם יכולים לפתוח ולהוסיף אליו',
      intro: [
        'לכל משפחה יש אותו ארכיון: מחברת במטבח אחד, שרשור וואטסאפ עם צילומים של כרטיסיות בכתב יד, הקלטה של סבתא שמסבירה את הקובה, ושלושה אנשים שלכל אחד מהם יש "הגרסה האמיתית" של החמין. שום דבר מזה לא במקום אחד, ושום דבר מזה לא ניתן לחיפוש.',
        'EasyPlate הופכת את הארכיון הזה לספרי מתכונים משותפים. כל אחד שומר מתכונים מאיפה שהם נמצאים אצלו: הקלטה קולית, PDF, קישור, סרטון או הקלדה. המתכונים נכנסים לספרים שמשותפים עם המשפחה כצופים או כעורכים, וכל שינוי מגיע לכולם בזמן אמת. והספר הוא גם ספר אמיתי: כפולת עמודים שמדפדפים בה, עם כריכה שבוחרים.',
      ],
      sections: [
        { h2: 'איך מכניסים את המתכונים הישנים', p: 'החלק הקשה בספר מתכונים משפחתי הוא חמישים המתכונים הראשונים. EasyPlate מקבלת אותם בצורה שבה הם כבר קיימים:', bullets: ['הקלטה קולית: מקליטים את סבתא, או משתפים הודעה קולית מוואטסאפ, וזה מתומלל למצרכים ושלבים.', 'PDF של אוסף מוקלד, שנקרא כקובץ שלם.', 'קישור לבלוג או לסרטון, למתכונים שמעולם לא נכתבו בבית.', 'הקלדה, כשה-AI משלים מנות, תגיות וערכים תזונתיים.'] },
        { h2: 'ספר אחד, הרבה ידיים', p: 'ספר משתפים עם איש קשר (אימייל או טלפון), בקוד, בקישור או ב-QR שמראים ליד השולחן. צופים קוראים; עורכים מוסיפים ומשנים מתכונים. הבעלים יכול להסיר כל אחד, וכל אחד יכול לצאת. המתכונים בתוך ספר משותף נשארים מסונכרנים: עריכה שאחותכם עשתה מופיעה אצלכם בטלפון.', bullets: ['צופה או עורך, לכל אדם בנפרד.', 'שיתוף באיש קשר, בקוד, בקישור או ב-QR.', 'סנכרון חי של כל מתכון בספר.', 'לכל מתכון תמונה, מנות, תגיות וערכים תזונתיים משלו.'] },
        { h2: 'כל משק הבית בחשבון אחד', p: 'למשפחה שמבשלת ממטבח אחד, EasyPlate Pro Duo ו-Pro Family פותחים משק בית משותף: מתכונים, ספרים, תפריטים, רשימות קניות וקבלות חיים תחת משק הבית, כל חבר רואה ועורך אותם, וסטטוס ה-Pro של המנוי מכסה את כולם. העדפות ופרופילים נשארים אישיים.', bullets: ['Pro Duo: שני חשבונות. Pro Family: עד שישה.', 'מתכונים, ספרים, תפריטים, רשימות וספר מחירים משותפים.', 'מצטרפים בקוד אחד; יוצאים או מוסרים בכל עת.'] },
      ],
      steps: [
        { t: 'יוצרים ספר', d: 'נותנים שם, בוחרים כריכה (תמונה, או כזו שה-AI מצייר לפי נושא) ומוסיפים את המתכונים הראשונים מהקלטות, PDF, קישורים או הקלדה.' },
        { t: 'משתפים', d: 'שולחים הזמנה לאיש קשר, או מראים קוד או QR. בוחרים אם קוראים או עורכים.' },
        { t: 'מבשלים ממנו', d: 'פותחים את הספר כמו ספר אמיתי, מדפדפים למתכון, מתאימים את הכמויות לשולחן של הערב ומפעילים מצב בישול.' },
      ],
      faq: [
        { q: 'סבתא יכולה להשתמש בזה?', a: 'היא לא חייבת. מקליטים אותה מסבירה מתכון, או מעבירים את ההודעה הקולית שלה מוואטסאפ ל-EasyPlate, וה-AI כותב אותו. אפשר להקריא לה בחזרה כדי לבדוק.' },
        { q: 'אפשר לייבא כרטיסייה סרוקה בכתב יד?', a: 'עדיין לא כתמונה. מקריאים אותה כהקלטה קולית או מקלידים; אוסף מוקלד ששמור כ-PDF נקרא כקובץ.' },
        { q: 'מי יכול לשנות מתכון משותף?', a: 'עורכים יכולים; צופים לא. הבעלים של הספר קובע את התפקיד של כל אחד ויכול לשנות אותו אחר כך.' },
        { q: 'מה קורה אם מישהו יוצא?', a: 'העותק שלו של הספר המשותף מוסר מהמכשיר שלו. הספר והמתכונים שבו נשארים אצל הבעלים ואצל שאר החברים.' },
        { q: 'צריך Pro?', a: 'שיתוף ספר זמין גם בחשבון חינמי, עם מגבלה על כמה ספרים משותפים בו-זמנית. Pro Duo ו-Pro Family מוסיפים משק בית משותף לכל דבר.' },
      ],
      cta: { title: 'המתכונים של סבתא, בכיס של כולם.', sub: 'הורידו את EasyPlate ופתחו את הספר המשפחתי.' },
    },
    ar: {
      title: 'كتاب طبخ عائلي مشترك: كتاب واحد للجميع | EasyPlate',
      description: 'اجمع وصفات العائلة في كتب طبخ رقمية مشتركة يقرأها الجميع أو يحرّرونها، من رسالة الجدة الصوتية إلى عشاء الليلة. مجاني على iOS وأندرويد.',
      keywords: 'كتاب طبخ عائلي, كتاب طبخ رقمي, كتاب وصفات مشترك, مشاركة الوصفات مع العائلة, وصفات الجدة, تطبيق وصفات للعائلة',
      h1: 'كتاب طبخ عائلي يفتحه الجميع ويضيفون إليه',
      intro: [
        'لكل عائلة الأرشيف نفسه: دفتر في مطبخ ما، ومحادثة واتساب فيها صور لبطاقات بخط اليد، ورسالة صوتية من الجدة تشرح الكبة، وثلاثة أشخاص لدى كل منهم "النسخة الحقيقية" من الطبق. لا شيء منها في مكان واحد، ولا شيء منها قابل للبحث.',
        'يحوّل EasyPlate هذا الأرشيف إلى كتب طبخ مشتركة. يحفظ كل شخص الوصفات من حيث هي عنده: رسالة صوتية أو PDF أو رابط أو فيديو أو كتابة. تدخل الوصفات في كتب تُشارك مع العائلة كمشاهدين أو محرّرين، ويصل كل تغيير إلى الجميع فورًا. والكتاب كتاب حقيقي أيضًا: صفحات مزدوجة تقلّبها، بغلاف تختاره.',
      ],
      sections: [
        { h2: 'إدخال الوصفات القديمة', p: 'الجزء الصعب في كتاب الطبخ العائلي هو أول خمسين وصفة. يقبلها EasyPlate بالشكل الذي توجد فيه أصلًا:', bullets: ['رسالة صوتية: سجّل الجدة، أو شارك رسالة واتساب صوتية، فتُفرَّغ إلى مكوّنات وخطوات.', 'ملف PDF لمجموعة مطبوعة، يُقرأ كملف كامل.', 'رابط لمدوّنة أو فيديو، للوصفات التي لم تُكتب في البيت قط.', 'الكتابة، ويكمل الذكاء الاصطناعي الحصص والوسوم والقيم الغذائية.'] },
        { h2: 'كتاب واحد وأيدٍ كثيرة', p: 'يُشارك الكتاب مع جهة اتصال (بريد أو هاتف) أو برمز أو رابط أو QR تعرضه على المائدة. يقرأ المشاهدون؛ ويضيف المحرّرون ويعدّلون. يمكن للمالك إزالة أي شخص، ويمكن لأي شخص المغادرة. تبقى الوصفات داخل الكتاب المشترك متزامنة: تعديل أجرته أختك يظهر على هاتفك.', bullets: ['مشاهد أو محرّر، لكل شخص.', 'مشاركة عبر جهة اتصال أو رمز أو رابط أو QR.', 'مزامنة مباشرة لكل وصفة في الكتاب.', 'تحتفظ كل وصفة بصورتها وحصصها ووسومها وقيمها الغذائية.'] },
        { h2: 'الأسرة كلها في حساب واحد', p: 'للعائلة التي تطبخ من مطبخ واحد، يفتح EasyPlate Pro Duo وPro Family أسرة مشتركة: تعيش الوصفات والكتب وخطط الوجبات وقوائم التسوّق والفواتير تحت الأسرة، ويراها كل عضو ويعدّلها، وتغطي حالة Pro للمشترك الجميع. تبقى التفضيلات والملفات الشخصية خاصة.', bullets: ['Pro Duo: حسابان. Pro Family: حتى ستة.', 'وصفات وكتب وخطط وقوائم ودفتر أسعار مشتركة.', 'انضم برمز واحد؛ غادر أو أُزِل في أي وقت.'] },
      ],
      steps: [
        { t: 'أنشئ كتابًا', d: 'سمّه، اختر غلافًا (صورة، أو غلافًا يرسمه الذكاء الاصطناعي من فكرة) وأضف الوصفات الأولى من رسائل صوتية أو PDF أو روابط أو كتابة.' },
        { t: 'شاركه', d: 'أرسل دعوة إلى جهة اتصال، أو اعرض رمزًا أو QR. اختر هل يقرؤون أم يحرّرون.' },
        { t: 'اطبخ منه', d: 'افتح الكتاب كأنه حقيقي، قلّب إلى وصفة، اضبط كمياتها لمائدة الليلة وابدأ وضع الطبخ.' },
      ],
      faq: [
        { q: 'هل تستطيع الجدة استخدامه؟', a: 'ليس عليها ذلك. سجّلها وهي تشرح وصفة، أو أعد توجيه رسالتها الصوتية من واتساب إلى EasyPlate، فيكتبها الذكاء الاصطناعي. يمكنك قراءتها لها للتحقق.' },
        { q: 'هل يمكن استيراد بطاقة مكتوبة بخط اليد وممسوحة؟', a: 'ليس كصورة بعد. أملِها كرسالة صوتية أو اكتبها؛ والمجموعة المطبوعة المحفوظة كملف PDF تُقرأ كملف.' },
        { q: 'من يستطيع تعديل وصفة مشتركة؟', a: 'المحرّرون يستطيعون؛ المشاهدون لا. يحدد مالك الكتاب دور كل شخص ويمكنه تغييره لاحقًا.' },
        { q: 'ماذا يحدث إذا غادر أحدهم؟', a: 'تُزال نسخته من الكتاب المشترك من جهازه. يبقى الكتاب ووصفاته لدى المالك وبقية الأعضاء.' },
        { q: 'هل نحتاج إلى Pro؟', a: 'مشاركة الكتاب متاحة في الحساب المجاني، مع حد لعدد الكتب المشتركة في الوقت نفسه. يضيف Pro Duo وPro Family أسرة مشتركة لكل شيء.' },
      ],
      cta: { title: 'وصفات الجدة في جيب الجميع.', sub: 'حمّل EasyPlate وابدأ كتاب العائلة.' },
    },
    fr: {
      title: 'Livre de recettes familial partagé | EasyPlate',
      description: 'Rassemblez les recettes de la famille dans des livres numériques partagés que chacun lit ou modifie. Gratuit sur iOS et Android.',
      keywords: 'livre de recettes familial, livre de recettes numérique, livre de recettes partagé, partager recettes en famille, recettes de grand-mère, application recettes famille',
      h1: 'Un livre de recettes familial que tout le monde peut ouvrir et enrichir',
      intro: [
        'Chaque famille a les mêmes archives : un cahier dans une cuisine, un fil WhatsApp avec des photos de fiches manuscrites, une note vocale de mamie qui explique la kubbeh, et trois personnes qui ont chacune « la vraie » version du plat du dimanche. Rien n’est au même endroit, et rien n’est consultable.',
        'EasyPlate transforme ces archives en livres de recettes partagés. Chacun enregistre les recettes là où il les a : une note vocale, un PDF, un lien, une vidéo ou la saisie. Les recettes vont dans des livres partagés avec la famille, en lecture ou en modification, et chaque changement arrive chez tout le monde en temps réel. Le livre est aussi un vrai livre : une double page que l’on feuillette, avec une couverture choisie.',
      ],
      sections: [
        { h2: 'Faire entrer les vieilles recettes', p: 'Le plus dur dans un livre familial, ce sont les cinquante premières recettes. EasyPlate les prend sous la forme où elles existent déjà :', bullets: ['Une note vocale : enregistrez mamie, ou partagez un message vocal WhatsApp, et c’est transcrit en ingrédients et étapes.', 'Un PDF d’une collection tapée, lu comme un fichier entier.', 'Un lien vers un blog ou une vidéo, pour les recettes jamais écrites à la maison.', 'La saisie, l’IA complétant portions, tags et nutrition.'] },
        { h2: 'Un livre, beaucoup de mains', p: 'Un livre se partage avec un contact (e-mail ou téléphone), par code, par lien ou par QR montré à table. Les lecteurs lisent ; les éditeurs ajoutent et modifient. Le propriétaire peut retirer n’importe qui, et chacun peut partir. Les recettes d’un livre partagé restent synchronisées : une modification de votre sœur apparaît sur votre téléphone.', bullets: ['Lecteur ou éditeur, par personne.', 'Partage par contact, code, lien ou QR.', 'Synchronisation en direct de chaque recette du livre.', 'Chaque recette garde sa photo, ses portions, ses tags et sa nutrition.'] },
        { h2: 'Tout le foyer sur un seul compte', p: 'Pour une famille qui cuisine depuis une seule cuisine, EasyPlate Pro Duo et Pro Family ouvrent un foyer partagé : recettes, livres, menus, listes de courses et tickets vivent sous le foyer, chaque membre les voit et les modifie, et le statut Pro de l’abonné couvre tout le monde. Préférences et profils restent personnels.', bullets: ['Pro Duo : deux comptes. Pro Family : jusqu’à six.', 'Recettes, livres, menus, listes et carnet de prix partagés.', 'On rejoint avec un code ; on part ou on est retiré à tout moment.'] },
      ],
      steps: [
        { t: 'Créez un livre', d: 'Nommez-le, choisissez une couverture (une photo, ou une dessinée par l’IA à partir d’un thème) et ajoutez les premières recettes depuis des notes vocales, PDF, liens ou saisie.' },
        { t: 'Partagez-le', d: 'Envoyez une invitation à un contact, ou montrez un code ou un QR. Choisissez lecture ou modification.' },
        { t: 'Cuisinez avec', d: 'Ouvrez le livre comme un vrai, feuilletez jusqu’à une recette, ajustez-la à la table du soir et lancez le mode cuisine.' },
      ],
      faq: [
        { q: 'Mamie peut-elle l’utiliser ?', a: 'Elle n’a pas besoin. Enregistrez-la en train d’expliquer une recette, ou transférez sa note vocale WhatsApp à EasyPlate, et l’IA l’écrit. Vous pouvez lui relire pour vérifier.' },
        { q: 'Peut-on importer une fiche manuscrite scannée ?', a: 'Pas encore en photo. Dictez-la en note vocale ou tapez-la ; une collection tapée enregistrée en PDF est lue comme un fichier.' },
        { q: 'Qui peut modifier une recette partagée ?', a: 'Les éditeurs, pas les lecteurs. Le propriétaire du livre décide du rôle de chacun et peut le changer ensuite.' },
        { q: 'Que se passe-t-il si quelqu’un part ?', a: 'Sa copie du livre partagé est retirée de son appareil. Le livre et ses recettes restent chez le propriétaire et les autres membres.' },
        { q: 'Faut-il Pro ?', a: 'Le partage d’un livre existe sur un compte gratuit, avec une limite du nombre de livres partagés en même temps. Pro Duo et Pro Family ajoutent un foyer partagé pour tout.' },
      ],
      cta: { title: 'Les recettes de mamie, dans toutes les poches.', sub: 'Téléchargez EasyPlate et commencez le livre de famille.' },
    },
    ru: {
      title: 'Семейная книга рецептов: одна книга для всех | EasyPlate',
      description: 'Соберите семейные рецепты в общие цифровые книги, которые все читают или редактируют, от голосового бабушки до сегодняшнего ужина. Бесплатно для iOS и Android.',
      keywords: 'семейная книга рецептов, цифровая книга рецептов, общая книга рецептов, поделиться рецептами с семьёй, бабушкины рецепты, приложение рецептов для семьи',
      h1: 'Семейная книга рецептов, которую каждый может открыть и дополнить',
      intro: [
        'У каждой семьи один и тот же архив: тетрадь на чьей-то кухне, чат в WhatsApp с фото рукописных карточек, голосовое от бабушки, где она объясняет кубе, и трое людей, у каждого из которых «настоящая» версия чолнта. Ничего из этого не лежит в одном месте, и ничего нельзя найти поиском.',
        'EasyPlate превращает этот архив в общие книги рецептов. Каждый сохраняет рецепты там, где они у него есть: голосовое, PDF, ссылка, видео или набор вручную. Рецепты попадают в книги, которыми делятся с семьёй как с читателями или редакторами, и каждое изменение доходит до всех сразу. И книга — настоящая книга: разворот, который листают, с выбранной обложкой.',
      ],
      sections: [
        { h2: 'Как занести старые рецепты', p: 'Самое трудное в семейной книге — первые пятьдесят рецептов. EasyPlate принимает их в том виде, в каком они уже есть:', bullets: ['Голосовое: запишите бабушку или перешлите голосовое из WhatsApp — оно расшифруется в ингредиенты и шаги.', 'PDF набранной коллекции, читается целиком как файл.', 'Ссылка на блог или видео — для рецептов, которые дома никогда не записывали.', 'Набор вручную, а ИИ дополнит порции, теги и КБЖУ.'] },
        { h2: 'Одна книга, много рук', p: 'Книгой делятся с контактом (почта или телефон), кодом, ссылкой или QR, который показывают за столом. Читатели читают; редакторы добавляют и меняют. Владелец может удалить любого, и любой может выйти. Рецепты внутри общей книги остаются синхронными: правка сестры появится у вас на телефоне.', bullets: ['Читатель или редактор — для каждого отдельно.', 'Поделиться через контакт, код, ссылку или QR.', 'Живая синхронизация каждого рецепта в книге.', 'У каждого рецепта своё фото, порции, теги и КБЖУ.'] },
        { h2: 'Вся семья в одном аккаунте', p: 'Для семьи, которая готовит на одной кухне, EasyPlate Pro Duo и Pro Family открывают общую семью: рецепты, книги, меню, списки покупок и чеки живут под семьёй, каждый участник их видит и редактирует, а статус Pro подписчика распространяется на всех. Предпочтения и профили остаются личными.', bullets: ['Pro Duo: два аккаунта. Pro Family: до шести.', 'Общие рецепты, книги, меню, списки и книга цен.', 'Вход по одному коду; выйти или быть удалённым можно в любой момент.'] },
      ],
      steps: [
        { t: 'Создайте книгу', d: 'Назовите её, выберите обложку (фото или нарисованную ИИ по теме) и добавьте первые рецепты из голосовых, PDF, ссылок или вручную.' },
        { t: 'Поделитесь', d: 'Отправьте приглашение контакту или покажите код или QR. Выберите, читать им или редактировать.' },
        { t: 'Готовьте по ней', d: 'Откройте книгу как настоящую, перелистните к рецепту, подгоните под сегодняшний стол и включите режим готовки.' },
      ],
      faq: [
        { q: 'Сможет ли бабушка этим пользоваться?', a: 'Ей не нужно. Запишите, как она объясняет рецепт, или перешлите её голосовое из WhatsApp в EasyPlate — ИИ запишет. Можно прочитать ей вслух для проверки.' },
        { q: 'Можно импортировать отсканированную рукописную карточку?', a: 'Как фото — пока нет. Надиктуйте её голосовым или наберите; набранная коллекция, сохранённая в PDF, читается как файл.' },
        { q: 'Кто может менять общий рецепт?', a: 'Редакторы могут, читатели нет. Владелец книги задаёт роль каждому и может изменить её позже.' },
        { q: 'Что будет, если кто-то выйдет?', a: 'Его копия общей книги удаляется с его устройства. Книга и рецепты остаются у владельца и остальных участников.' },
        { q: 'Нужен ли Pro?', a: 'Поделиться книгой можно и с бесплатного аккаунта, с ограничением на число книг, которыми делятся одновременно. Pro Duo и Pro Family добавляют общую семью для всего.' },
      ],
      cta: { title: 'Бабушкины рецепты — в кармане у каждого.', sub: 'Скачайте EasyPlate и начните семейную книгу.' },
    },
  },
};
