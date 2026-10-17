// Guide pages, part four: the three search intents Koby asked for on
// 2026-10-18 — "חיפוש מתכונים", "מתכונים AI", "סריקת קבלות" and their
// equivalents. Merged into TOPICS by topics.mjs. Everything stated must be
// true of the app; no prices, plans or tiers in this copy.

export const MORE_TOPICS_4 = {
  // ------------------------------------------------------------ recipe search
  'recipe-search': {
    icon: 'search', screens: ['01_recipes', '03_ai_import'],
    en: {
      title: 'Recipe Search: Find a Dish Online or in Yours | EasyPlate',
      description: 'Search the web for a recipe and save it in one tap, or search your own recipes by name and diet. Ask the AI for a dish when nothing fits. Free app.',
      keywords: 'recipe search, search recipes, find a recipe, recipe finder app, search recipes by diet, recipe search engine, what to cook tonight',
      h1: 'Recipe search that ends with a saved recipe',
      intro: [
        'Searching for a recipe usually ends in twelve open tabs and a screenshot. EasyPlate puts the search inside the app: type a dish, pick a result, and the recipe is read into a clean page with ingredients, steps, servings and nutrition, ready to plan and shop from.',
        'Once recipes are saved, the second search begins: the one inside your own kitchen. The recipes tab finds a dish by name as you type and narrows by diet, so "gluten free" and "vegan" are a tap, not a question. And when neither the web nor your library has what you want, you describe the dish and the AI writes it.',
      ],
      sections: [
        { h2: 'Search the web from inside the app', p: 'Choose "Search the web" when adding a recipe, type what you want to cook, and EasyPlate lists matching pages with a title and a short preview. Tap one and the AI reads the page into the recipe format, so there is nothing to copy.', bullets: ['Results come from the open web, in your language.', 'The original page stays linked on the saved recipe.', 'Servings, timing and per-serving nutrition are filled in on save.'] },
        { h2: 'Find what you already saved', p: 'The recipes tab is a search box over your whole library. It matches titles as you type and stacks diet filters on top:', bullets: ['Dietary filters: vegetarian, vegan, gluten free, dairy free and more, combined.', 'Books group recipes by theme, so a search can start from "weeknight" or "holidays".', 'Shefi, the assistant, answers "what do I have with chicken?" over the same library.'] },
        { h2: 'Nothing fits? Ask for a recipe', p: 'The "Ask AI" way in describes what you want in a sentence, such as "a 30-minute chicken and rice dinner for four with no dairy", and comes back with a complete recipe you can edit before saving.', bullets: ['Allergens and diets you set in your profile are respected.', 'Every recipe is translated when you switch the app language.', 'The result is a normal recipe: plan it, add it to a list, cook it.'] },
      ],
      steps: [
        { t: 'Tap the plus and choose "Search the web"', d: 'Type the dish. Results appear with a title and a preview.' },
        { t: 'Pick a result', d: 'The AI reads the page into ingredients, steps and nutrition. Review and save.' },
        { t: 'Search your own recipes later', d: 'Type a word on the recipes tab, add a diet filter, open the dish.' },
      ],
      faq: [
        { q: 'Does recipe search work in Hebrew?', a: 'Yes. Search in Hebrew, English, Arabic, French or Russian; results and the saved recipe follow the language you use.' },
        { q: 'Can I search by ingredient?', a: 'The library search matches recipe names; for "what can I make with eggs and spinach" ask Shefi, who reads your saved recipes.' },
        { q: 'Does saving a web recipe need the internet?', a: 'Yes, for the search and the AI read. Saved recipes open offline afterwards.' },
        { q: 'Is the search free?', a: 'Searching and saving recipes is part of the free app, with a daily number of AI reads that can be extended by watching a short video.' },
      ],
      cta: { title: 'Search once. Save forever.', sub: 'Download EasyPlate and find tonight’s dinner.' },
    },
    he: {
      title: 'חיפוש מתכונים: מוצאים מנה ברשת או בספר שלכם | EasyPlate',
      description: 'מחפשים מתכון ברשת ושומרים בלחיצה, או מחפשים במתכונים שלכם לפי שם ותזונה. כשאין התאמה, מבקשים מה-AI מתכון. חינם לאייפון ולאנדרואיד.',
      keywords: 'חיפוש מתכונים, חיפוש מתכון, למצוא מתכון, אפליקציה לחיפוש מתכונים, חיפוש מתכונים לפי תזונה, מנוע חיפוש מתכונים, מה לבשל הערב',
      h1: 'חיפוש מתכונים שנגמר במתכון שמור',
      intro: [
        'חיפוש מתכון נגמר בדרך כלל בשתים-עשרה לשוניות פתוחות וצילום מסך. EasyPlate מכניסה את החיפוש לתוך האפליקציה: מקלידים מנה, בוחרים תוצאה, והמתכון נקרא לעמוד מסודר עם מצרכים, שלבים, מנות וערכים תזונתיים, מוכן לתכנון ולקניות.',
        'אחרי שיש מתכונים שמורים מתחיל החיפוש השני: זה שבתוך המטבח שלכם. טאב המתכונים מוצא מנה לפי שם תוך כדי הקלדה ומצמצם לפי תזונה, כך ש״ללא גלוטן״ ו״טבעוני״ הם לחיצה ולא שאלה. וכשלא ברשת ולא בספרייה יש מה שרציתם, מתארים את המנה וה-AI כותב אותה.',
      ],
      sections: [
        { h2: 'חיפוש ברשת מתוך האפליקציה', p: 'בוחרים ״חיפוש ברשת״ בהוספת מתכון, מקלידים מה רוצים לבשל, ו-EasyPlate מציגה עמודים מתאימים עם כותרת ותקציר. לוחצים על אחד וה-AI קורא את העמוד לפורמט של מתכון, בלי להעתיק כלום.', bullets: ['התוצאות מגיעות מהרשת הפתוחה, בשפה שלכם.', 'העמוד המקורי נשאר מקושר למתכון השמור.', 'מנות, זמנים וערכים תזונתיים למנה מתמלאים בשמירה.'] },
        { h2: 'מוצאים מה שכבר שמרתם', p: 'טאב המתכונים הוא תיבת חיפוש על כל הספרייה. הוא מתאים כותרות תוך כדי הקלדה ומוסיף מסנני תזונה מעל:', bullets: ['מסנני תזונה: צמחוני, טבעוני, ללא גלוטן, ללא חלב ועוד, גם ביחד.', 'ספרים מקבצים מתכונים לפי נושא, כך שחיפוש יכול להתחיל מ״ערב חול״ או ״חגים״.', 'שפי, העוזר, עונה על ״מה יש לי עם עוף?״ על אותה ספרייה.'] },
        { h2: 'לא מצאתם? מבקשים מתכון', p: 'הדרך ״בקשה מה-AI״ מתארת במשפט מה רוצים, למשל ״ארוחת עוף ואורז ל-4 ב-30 דקות בלי חלב״, וחוזרת עם מתכון שלם שאפשר לערוך לפני השמירה.', bullets: ['אלרגנים ותזונה שהגדרתם בפרופיל נשמרים.', 'כל מתכון מתורגם כשמחליפים את שפת האפליקציה.', 'התוצאה היא מתכון רגיל: מתכננים, מוסיפים לרשימה, מבשלים.'] },
      ],
      steps: [
        { t: 'לוחצים על הפלוס ובוחרים ״חיפוש ברשת״', d: 'מקלידים את המנה. התוצאות מופיעות עם כותרת ותקציר.' },
        { t: 'בוחרים תוצאה', d: 'ה-AI קורא את העמוד למצרכים, שלבים וערכים תזונתיים. בודקים ושומרים.' },
        { t: 'מחפשים אחר כך בספרייה שלכם', d: 'מקלידים מילה בטאב המתכונים, מוסיפים מסנן תזונה, פותחים את המנה.' },
      ],
      faq: [
        { q: 'חיפוש המתכונים עובד בעברית?', a: 'כן. מחפשים בעברית, אנגלית, ערבית, צרפתית או רוסית; התוצאות והמתכון השמור הולכים אחרי השפה שבה כתבתם.' },
        { q: 'אפשר לחפש לפי מצרך?', a: 'חיפוש הספרייה מתאים שמות מתכונים; ל״מה אפשר להכין מביצים ותרד״ שואלים את שפי, שקורא את המתכונים השמורים שלכם.' },
        { q: 'שמירת מתכון מהרשת צריכה אינטרנט?', a: 'כן, לחיפוש ולקריאת ה-AI. מתכונים שמורים נפתחים אחר כך גם בלי חיבור.' },
        { q: 'החיפוש חינמי?', a: 'חיפוש ושמירת מתכונים הם חלק מהאפליקציה החינמית, עם מספר יומי של קריאות AI שאפשר להרחיב בצפייה בסרטון קצר.' },
      ],
      cta: { title: 'מחפשים פעם אחת. שומרים לתמיד.', sub: 'הורידו את EasyPlate ומצאו את ארוחת הערב.' },
    },
    ar: {
      title: 'البحث عن وصفات: في الإنترنت أو في مطبخك | EasyPlate',
      description: 'ابحث في الإنترنت عن وصفة واحفظها بلمسة، أو ابحث في وصفاتك بالاسم والنظام الغذائي. اطلب من الذكاء الاصطناعي طبقًا حين لا يناسبك شيء. مجاني على iOS وأندرويد.',
      keywords: 'البحث عن وصفات, بحث وصفات, إيجاد وصفة, تطبيق للبحث عن الوصفات, البحث عن وصفات حسب النظام الغذائي, محرك بحث وصفات, ماذا أطبخ الليلة',
      h1: 'بحث عن وصفات ينتهي بوصفة محفوظة',
      intro: [
        'ينتهي البحث عن وصفة عادةً باثني عشر تبويبًا مفتوحًا ولقطة شاشة. يضع EasyPlate البحث داخل التطبيق: اكتب طبقًا، اختر نتيجة، فتُقرأ الوصفة في صفحة مرتّبة بالمكوّنات والخطوات والحصص والقيم الغذائية، جاهزة للتخطيط والتسوّق.',
        'بعد حفظ الوصفات يبدأ البحث الثاني: الذي داخل مطبخك. يجد تبويب الوصفات الطبق بالاسم أثناء الكتابة ويضيّق حسب النظام الغذائي، فيصبح «خالٍ من الغلوتين» و«نباتي» لمسة لا سؤالًا. وحين لا يحوي الإنترنت ولا مكتبتك ما تريد، تصف الطبق فيكتبه الذكاء الاصطناعي.',
      ],
      sections: [
        { h2: 'ابحث في الإنترنت من داخل التطبيق', p: 'اختر «البحث في الإنترنت» عند إضافة وصفة، اكتب ما تريد طبخه، فيعرض EasyPlate الصفحات المطابقة بعنوان ومعاينة قصيرة. المس إحداها فيقرأها الذكاء الاصطناعي بصيغة الوصفة، دون نسخ أي شيء.', bullets: ['تأتي النتائج من الإنترنت المفتوح، بلغتك.', 'تبقى الصفحة الأصلية مرتبطة بالوصفة المحفوظة.', 'تُملأ الحصص والتوقيت والقيم الغذائية لكل حصة عند الحفظ.'] },
        { h2: 'اعثر على ما حفظته', p: 'تبويب الوصفات هو صندوق بحث على مكتبتك كلها. يطابق العناوين أثناء الكتابة ويضيف فلاتر النظام الغذائي فوقها:', bullets: ['فلاتر غذائية: نباتي، نباتي صرف، خالٍ من الغلوتين، خالٍ من الألبان وغيرها، مجتمعة.', 'تجمع الكتب الوصفات حسب الموضوع، فيبدأ البحث من «أيام الأسبوع» أو «الأعياد».', 'يجيب شيفي، المساعد، عن «ماذا لديّ مع الدجاج؟» على المكتبة نفسها.'] },
        { h2: 'لا شيء يناسب؟ اطلب وصفة', p: 'طريقة «اطلب من الذكاء الاصطناعي» تصف ما تريد في جملة، مثل «عشاء دجاج وأرز لأربعة في 30 دقيقة بلا ألبان»، وتعود بوصفة كاملة يمكنك تعديلها قبل الحفظ.', bullets: ['تُحترم مسبّبات الحساسية والأنظمة الغذائية المحدّدة في ملفك.', 'تُترجم كل وصفة عند تغيير لغة التطبيق.', 'النتيجة وصفة عادية: خطّطها، أضفها إلى قائمة، اطبخها.'] },
      ],
      steps: [
        { t: 'المس زر الإضافة واختر «البحث في الإنترنت»', d: 'اكتب الطبق. تظهر النتائج بعنوان ومعاينة.' },
        { t: 'اختر نتيجة', d: 'يقرأ الذكاء الاصطناعي الصفحة إلى مكوّنات وخطوات وقيم غذائية. راجع واحفظ.' },
        { t: 'ابحث لاحقًا في وصفاتك', d: 'اكتب كلمة في تبويب الوصفات، أضف فلتر نظام غذائي، افتح الطبق.' },
      ],
      faq: [
        { q: 'هل يعمل البحث عن الوصفات بالعربية؟', a: 'نعم. ابحث بالعربية أو العبرية أو الإنجليزية أو الفرنسية أو الروسية؛ تتبع النتائج والوصفة المحفوظة اللغة التي تكتب بها.' },
        { q: 'هل يمكن البحث حسب المكوّن؟', a: 'يطابق بحث المكتبة أسماء الوصفات؛ لسؤال «ماذا أصنع بالبيض والسبانخ» اسأل شيفي الذي يقرأ وصفاتك المحفوظة.' },
        { q: 'هل يحتاج حفظ وصفة من الإنترنت إلى اتصال؟', a: 'نعم، للبحث ولقراءة الذكاء الاصطناعي. تُفتح الوصفات المحفوظة بعد ذلك دون اتصال.' },
        { q: 'هل البحث مجاني؟', a: 'البحث عن الوصفات وحفظها جزء من التطبيق المجاني، مع عدد يومي من قراءات الذكاء الاصطناعي يمكن تمديده بمشاهدة فيديو قصير.' },
      ],
      cta: { title: 'ابحث مرة. احفظ للأبد.', sub: 'حمّل EasyPlate واعثر على عشاء الليلة.' },
    },
    fr: {
      title: 'Recherche de recettes en ligne ou chez vous | EasyPlate',
      description: 'Cherchez une recette sur le web et enregistrez-la en un geste, ou dans vos recettes par nom et régime. Demandez un plat à l’IA si rien ne convient.',
      keywords: 'recherche de recettes, chercher une recette, trouver une recette, application recherche recettes, recettes par régime, moteur de recherche recettes, quoi cuisiner ce soir',
      h1: 'Une recherche de recettes qui finit par une recette enregistrée',
      intro: [
        'Chercher une recette finit souvent en douze onglets ouverts et une capture d’écran. EasyPlate met la recherche dans l’app : tapez un plat, choisissez un résultat, et la recette est lue dans une page propre avec ingrédients, étapes, portions et nutrition, prête à planifier et à acheter.',
        'Une fois des recettes enregistrées commence la seconde recherche : celle dans votre propre cuisine. L’onglet recettes trouve un plat par son nom pendant que vous tapez et filtre par régime, si bien que « sans gluten » et « végan » sont un geste, pas une question. Et quand ni le web ni votre bibliothèque n’ont ce que vous voulez, vous décrivez le plat et l’IA l’écrit.',
      ],
      sections: [
        { h2: 'Chercher sur le web depuis l’app', p: 'Choisissez « Chercher sur le web » en ajoutant une recette, tapez ce que vous voulez cuisiner, et EasyPlate liste les pages correspondantes avec un titre et un aperçu. Touchez-en une : l’IA lit la page au format recette, rien à copier.', bullets: ['Les résultats viennent du web ouvert, dans votre langue.', 'La page d’origine reste liée à la recette enregistrée.', 'Portions, temps et nutrition par portion sont remplis à l’enregistrement.'] },
        { h2: 'Retrouver ce que vous avez déjà', p: 'L’onglet recettes est un champ de recherche sur toute votre bibliothèque. Il fait correspondre les titres pendant la frappe et empile les filtres de régime :', bullets: ['Filtres : végétarien, végan, sans gluten, sans lactose et plus, combinables.', 'Les livres regroupent les recettes par thème, pour partir de « semaine » ou « fêtes ».', 'Shefi, l’assistant, répond à « qu’est-ce que j’ai avec du poulet ? » sur la même bibliothèque.'] },
        { h2: 'Rien ne convient ? Demandez une recette', p: 'La voie « Demander à l’IA » décrit ce que vous voulez en une phrase, comme « un dîner poulet-riz pour quatre en 30 minutes sans lactose », et revient avec une recette complète à modifier avant d’enregistrer.', bullets: ['Les allergènes et régimes de votre profil sont respectés.', 'Chaque recette est traduite quand vous changez la langue de l’app.', 'Le résultat est une recette normale : à planifier, à lister, à cuisiner.'] },
      ],
      steps: [
        { t: 'Touchez le plus et choisissez « Chercher sur le web »', d: 'Tapez le plat. Les résultats apparaissent avec un titre et un aperçu.' },
        { t: 'Choisissez un résultat', d: 'L’IA lit la page en ingrédients, étapes et nutrition. Vérifiez et enregistrez.' },
        { t: 'Cherchez ensuite dans vos recettes', d: 'Tapez un mot dans l’onglet recettes, ajoutez un filtre de régime, ouvrez le plat.' },
      ],
      faq: [
        { q: 'La recherche de recettes fonctionne-t-elle en français ?', a: 'Oui. Cherchez en français, hébreu, anglais, arabe ou russe ; les résultats et la recette enregistrée suivent la langue utilisée.' },
        { q: 'Peut-on chercher par ingrédient ?', a: 'La recherche de la bibliothèque porte sur les noms ; pour « que faire avec des œufs et des épinards », demandez à Shefi, qui lit vos recettes enregistrées.' },
        { q: 'Faut-il Internet pour enregistrer une recette du web ?', a: 'Oui, pour la recherche et la lecture par l’IA. Les recettes enregistrées s’ouvrent ensuite hors ligne.' },
        { q: 'La recherche est-elle gratuite ?', a: 'Chercher et enregistrer des recettes fait partie de l’app gratuite, avec un nombre quotidien de lectures IA extensible en regardant une courte vidéo.' },
      ],
      cta: { title: 'Cherchez une fois. Gardez pour toujours.', sub: 'Téléchargez EasyPlate et trouvez le dîner de ce soir.' },
    },
    ru: {
      title: 'Поиск рецептов: в интернете или среди своих | EasyPlate',
      description: 'Ищите рецепт в интернете и сохраняйте одним касанием, или среди своих рецептов по названию и диете. Нет подходящего — попросите ИИ. Бесплатно.',
      keywords: 'поиск рецептов, найти рецепт, приложение для поиска рецептов, поиск рецептов по диете, поисковик рецептов, что приготовить на ужин',
      h1: 'Поиск рецептов, который заканчивается сохранённым рецептом',
      intro: [
        'Поиск рецепта обычно заканчивается двенадцатью открытыми вкладками и скриншотом. EasyPlate переносит поиск внутрь приложения: введите блюдо, выберите результат — и рецепт считывается в аккуратную страницу с ингредиентами, шагами, порциями и КБЖУ, готовую для плана и покупок.',
        'Когда рецепты сохранены, начинается второй поиск — по вашей собственной кухне. Вкладка рецептов находит блюдо по названию по мере ввода и сужает по диете, так что «без глютена» и «веганское» — это одно касание, а не вопрос. А если ни в интернете, ни в вашей библиотеке нет нужного, опишите блюдо — и ИИ его напишет.',
      ],
      sections: [
        { h2: 'Поиск в интернете прямо из приложения', p: 'Выберите «Поиск в интернете» при добавлении рецепта, введите, что хотите приготовить, и EasyPlate покажет подходящие страницы с заголовком и кратким описанием. Коснитесь одной — ИИ считает страницу в формат рецепта, копировать ничего не нужно.', bullets: ['Результаты приходят из открытого интернета, на вашем языке.', 'Исходная страница остаётся привязанной к сохранённому рецепту.', 'Порции, время и КБЖУ на порцию заполняются при сохранении.'] },
        { h2: 'Найти то, что уже сохранено', p: 'Вкладка рецептов — это строка поиска по всей библиотеке. Она сопоставляет названия по мере ввода и добавляет фильтры по диете:', bullets: ['Фильтры: вегетарианское, веганское, без глютена, без молока и другие, вместе.', 'Книги группируют рецепты по теме, так что поиск начинается с «будни» или «праздники».', 'Шефи, помощник, отвечает на «что у меня есть с курицей?» по той же библиотеке.'] },
        { h2: 'Ничего не подходит? Попросите рецепт', p: 'Способ «Попросить ИИ» описывает желаемое одной фразой, например «ужин из курицы и риса на четверых за 30 минут без молочного», и возвращает полный рецепт, который можно отредактировать перед сохранением.', bullets: ['Аллергены и диеты из вашего профиля учитываются.', 'Каждый рецепт переводится при смене языка приложения.', 'Результат — обычный рецепт: планируйте, добавляйте в список, готовьте.'] },
      ],
      steps: [
        { t: 'Нажмите плюс и выберите «Поиск в интернете»', d: 'Введите блюдо. Появятся результаты с заголовком и описанием.' },
        { t: 'Выберите результат', d: 'ИИ считает страницу в ингредиенты, шаги и КБЖУ. Проверьте и сохраните.' },
        { t: 'Потом ищите среди своих рецептов', d: 'Введите слово на вкладке рецептов, добавьте фильтр диеты, откройте блюдо.' },
      ],
      faq: [
        { q: 'Поиск рецептов работает на русском?', a: 'Да. Ищите на русском, иврите, английском, арабском или французском; результаты и сохранённый рецепт следуют языку запроса.' },
        { q: 'Можно искать по ингредиенту?', a: 'Поиск по библиотеке сопоставляет названия; на «что приготовить из яиц и шпината» ответит Шефи, который читает ваши сохранённые рецепты.' },
        { q: 'Нужен ли интернет для сохранения рецепта из сети?', a: 'Да, для поиска и чтения ИИ. Сохранённые рецепты потом открываются офлайн.' },
        { q: 'Поиск бесплатный?', a: 'Поиск и сохранение рецептов — часть бесплатного приложения, с дневным числом ИИ-чтений, которое можно расширить, посмотрев короткое видео.' },
      ],
      cta: { title: 'Найдите один раз. Сохраните навсегда.', sub: 'Скачайте EasyPlate и найдите сегодняшний ужин.' },
    },
  },

  // ------------------------------------------------------------ AI recipes
  'ai-recipes': {
    icon: 'sparkles', screens: ['03_ai_import', '07_nutrition'],
    en: {
      title: 'AI Recipes: Create and Import Recipes with AI | EasyPlate',
      description: 'An AI recipe app: write what you crave and get a recipe, or turn a link, video, PDF or voice note into one. Nutrition, pictures and translation included.',
      keywords: 'ai recipes, ai recipe app, ai recipe generator, recipe maker ai, create recipe with ai, ai meal ideas, recipe from ingredients ai',
      h1: 'AI recipes you actually cook',
      intro: [
        'AI can write a recipe for anything, which is the problem: a wall of text is not dinner. EasyPlate turns every AI result into a real recipe card with ingredients, quantities, steps, servings and per-serving nutrition, inside the same library as the recipes you saved from a video or a link.',
        'There are two ways to get an AI recipe. Describe what you want and the AI writes it, respecting the diets and allergens on your profile. Or hand it something you already have, a TikTok, a web page, a PDF, a voice note, and it reads that into the same format. Either way you review before saving, and the recipe is yours to edit, plan, shop and cook.',
      ],
      sections: [
        { h2: 'Write a sentence, get a recipe', p: 'Choose "Ask AI" and type what you are after: "a vegan lentil soup for six", "something quick with the salmon in the fridge", "a birthday cake without eggs". The AI answers with a full recipe in your language.', bullets: ['Diets and allergens from your profile are applied automatically.', 'Servings scale the ingredient quantities.', 'Edit anything before saving; the AI never overwrites your changes.'] },
        { h2: 'AI reads what you already have', p: 'Most recipes you want already exist somewhere. EasyPlate reads them into the same card:', bullets: ['A TikTok, Instagram, YouTube or Facebook video, including recipes that are only spoken.', 'A web page or a pasted text.', 'A PDF, a photo of a recipe page or a voice note shared from another app.'] },
        { h2: 'Finished by AI, not just written', p: 'Every saved recipe gets what a text generator leaves out:', bullets: ['Per-serving calories, protein, carbs and fat, estimated on save.', 'A picture: generated by AI or chosen from Google image search.', 'Translation of the whole recipe when you switch language.', 'Shefi, the assistant, to answer questions about it later.'] },
      ],
      steps: [
        { t: 'Tap the plus and choose "Ask AI"', d: 'Describe the dish, the number of people and anything to avoid.' },
        { t: 'Review the recipe', d: 'Ingredients, steps and nutrition are filled in. Change what you like.' },
        { t: 'Save and use it', d: 'Put it on the weekly plan, build the grocery list, start Cook Mode.' },
      ],
      faq: [
        { q: 'Which AI does EasyPlate use?', a: 'Google Gemini, through EasyPlate’s own servers. Your request and the result are not used to train models.' },
        { q: 'Are AI recipes accurate?', a: 'They are a strong draft: the AI writes real quantities and steps, and nutrition is an estimate. You review everything before saving, and you can edit later.' },
        { q: 'Can the AI use ingredients I have at home?', a: 'Yes. List them in the request ("I have chicken thighs, rice and a lemon") and the recipe is built around them.' },
        { q: 'Does it work in Hebrew and other languages?', a: 'Hebrew, English, Arabic, French and Russian, for the request, the recipe and the spoken answers of Shefi.' },
        { q: 'How many AI recipes can I make?', a: 'The free app includes a daily number of AI reads and requests, which a short video extends.' },
      ],
      cta: { title: 'Tell the AI what you crave.', sub: 'Download EasyPlate and make your first AI recipe.' },
    },
    he: {
      title: 'מתכונים AI: יוצרים ומייבאים מתכונים עם AI | EasyPlate',
      description: 'אפליקציית מתכונים AI: כותבים מה בא לכם ומקבלים מתכון, או הופכים קישור, סרטון, PDF או הודעה קולית למתכון. ערכים תזונתיים, תמונה ותרגום כלולים. חינם.',
      keywords: 'מתכונים AI, מתכונים בינה מלאכותית, אפליקציית מתכונים AI, יצירת מתכון עם AI, מחולל מתכונים, מתכון לפי מצרכים AI, רעיונות לארוחה AI',
      h1: 'מתכונים AI שבאמת מבשלים',
      intro: [
        'בינה מלאכותית יכולה לכתוב מתכון לכל דבר, וזו הבעיה: קיר של טקסט הוא לא ארוחת ערב. EasyPlate הופכת כל תוצאה של AI לכרטיס מתכון אמיתי עם מצרכים, כמויות, שלבים, מנות וערכים תזונתיים למנה, בתוך אותה ספרייה כמו המתכונים ששמרתם מסרטון או מקישור.',
        'יש שתי דרכים לקבל מתכון AI. מתארים מה רוצים וה-AI כותב, תוך שמירה על התזונה והאלרגנים בפרופיל שלכם. או נותנים לו משהו שכבר יש לכם, טיקטוק, עמוד אינטרנט, PDF, הודעה קולית, והוא קורא את זה לאותו פורמט. בשני המקרים בודקים לפני השמירה, והמתכון שלכם לעריכה, לתכנון, לקניות ולבישול.',
      ],
      sections: [
        { h2: 'כותבים משפט, מקבלים מתכון', p: 'בוחרים ״בקשה מה-AI״ ומקלידים מה מחפשים: ״מרק עדשים טבעוני לשישה״, ״משהו מהיר עם הסלמון שבמקרר״, ״עוגת יום הולדת בלי ביצים״. ה-AI עונה במתכון מלא בשפה שלכם.', bullets: ['תזונה ואלרגנים מהפרופיל מוחלים אוטומטית.', 'מספר המנות מגדיל ומקטין את הכמויות.', 'עורכים כל דבר לפני השמירה; ה-AI לעולם לא דורס שינויים שלכם.'] },
        { h2: 'ה-AI קורא מה שכבר יש לכם', p: 'רוב המתכונים שאתם רוצים כבר קיימים איפשהו. EasyPlate קוראת אותם לאותו כרטיס:', bullets: ['סרטון טיקטוק, אינסטגרם, יוטיוב או פייסבוק, כולל מתכונים שרק נאמרים בקול.', 'עמוד אינטרנט או טקסט מודבק.', 'PDF, צילום של עמוד מתכון או הודעה קולית ששותפה מאפליקציה אחרת.'] },
        { h2: 'מושלם על ידי AI, לא רק נכתב', p: 'כל מתכון שמור מקבל את מה שמחולל טקסט משאיר בחוץ:', bullets: ['קלוריות, חלבון, פחמימות ושומן למנה, מוערכים בשמירה.', 'תמונה: נוצרת ב-AI או נבחרת מחיפוש תמונות בגוגל.', 'תרגום של כל המתכון כשמחליפים שפה.', 'שפי, העוזר, לשאלות על המתכון אחר כך.'] },
      ],
      steps: [
        { t: 'לוחצים על הפלוס ובוחרים ״בקשה מה-AI״', d: 'מתארים את המנה, מספר הסועדים וכל מה שצריך להימנע ממנו.' },
        { t: 'בודקים את המתכון', d: 'מצרכים, שלבים וערכים תזונתיים מולאו. משנים מה שרוצים.' },
        { t: 'שומרים ומשתמשים', d: 'שמים בתפריט השבועי, בונים רשימת קניות, מפעילים מצב בישול.' },
      ],
      faq: [
        { q: 'באיזה AI משתמשת EasyPlate?', a: 'Google Gemini, דרך השרתים של EasyPlate. הבקשה והתוצאה שלכם לא משמשות לאימון מודלים.' },
        { q: 'מתכוני AI מדויקים?', a: 'הם טיוטה חזקה: ה-AI כותב כמויות ושלבים אמיתיים, והערכים התזונתיים הם הערכה. בודקים הכול לפני השמירה, ואפשר לערוך אחר כך.' },
        { q: 'ה-AI יכול להשתמש במה שיש לי בבית?', a: 'כן. מפרטים בבקשה (״יש לי שוקי עוף, אורז ולימון״) והמתכון נבנה סביבם.' },
        { q: 'זה עובד בעברית?', a: 'עברית, אנגלית, ערבית, צרפתית ורוסית, לבקשה, למתכון ולתשובות המדוברות של שפי.' },
        { q: 'כמה מתכוני AI אפשר להכין?', a: 'האפליקציה החינמית כוללת מספר יומי של קריאות ובקשות AI, שסרטון קצר מרחיב.' },
      ],
      cta: { title: 'תגידו ל-AI מה בא לכם.', sub: 'הורידו את EasyPlate והכינו את מתכון ה-AI הראשון שלכם.' },
    },
    ar: {
      title: 'وصفات بالذكاء الاصطناعي: أنشئ واستورد وصفاتك | EasyPlate',
      description: 'اكتب ما تشتهيه واحصل على وصفة، أو حوّل رابطًا أو فيديو أو PDF أو رسالة صوتية إلى وصفة. القيم الغذائية والصور والترجمة مشمولة. مجاني.',
      keywords: 'وصفات بالذكاء الاصطناعي, تطبيق وصفات ذكاء اصطناعي, مولّد وصفات, إنشاء وصفة بالذكاء الاصطناعي, وصفة من المكوّنات, أفكار وجبات بالذكاء الاصطناعي',
      h1: 'وصفات بالذكاء الاصطناعي تطبخها فعلًا',
      intro: [
        'يستطيع الذكاء الاصطناعي كتابة وصفة لأي شيء، وهذه هي المشكلة: جدار من النص ليس عشاءً. يحوّل EasyPlate كل نتيجة من الذكاء الاصطناعي إلى بطاقة وصفة حقيقية بالمكوّنات والكميات والخطوات والحصص والقيم الغذائية لكل حصة، داخل المكتبة نفسها التي تضم وصفاتك المحفوظة من فيديو أو رابط.',
        'هناك طريقتان للحصول على وصفة بالذكاء الاصطناعي. صِف ما تريد فيكتبه الذكاء الاصطناعي مراعيًا الأنظمة الغذائية ومسبّبات الحساسية في ملفك. أو أعطه شيئًا لديك أصلًا، فيديو تيك توك أو صفحة ويب أو PDF أو رسالة صوتية، فيقرأه بالصيغة نفسها. في الحالتين تراجع قبل الحفظ، والوصفة لك لتعدّلها وتخطّطها وتتسوّق لها وتطبخها.',
      ],
      sections: [
        { h2: 'اكتب جملة، واحصل على وصفة', p: 'اختر «اطلب من الذكاء الاصطناعي» واكتب ما تبحث عنه: «شوربة عدس نباتية لستة»، «شيء سريع بالسلمون الموجود في الثلاجة»، «كعكة عيد ميلاد بلا بيض». يجيب الذكاء الاصطناعي بوصفة كاملة بلغتك.', bullets: ['تُطبّق الأنظمة الغذائية ومسبّبات الحساسية من ملفك تلقائيًا.', 'عدد الحصص يضاعف الكميات أو يقلّلها.', 'عدّل أي شيء قبل الحفظ؛ لا يكتب الذكاء الاصطناعي فوق تغييراتك أبدًا.'] },
        { h2: 'الذكاء الاصطناعي يقرأ ما لديك', p: 'معظم الوصفات التي تريدها موجودة في مكان ما. يقرأها EasyPlate إلى البطاقة نفسها:', bullets: ['فيديو تيك توك أو إنستغرام أو يوتيوب أو فيسبوك، بما فيها الوصفات المنطوقة فقط.', 'صفحة ويب أو نص ملصق.', 'ملف PDF أو صورة لصفحة وصفة أو رسالة صوتية مشاركة من تطبيق آخر.'] },
        { h2: 'مكتملة بالذكاء الاصطناعي، لا مكتوبة فحسب', p: 'تحصل كل وصفة محفوظة على ما يغفله مولّد النصوص:', bullets: ['السعرات والبروتين والكربوهيدرات والدهون لكل حصة، تُقدَّر عند الحفظ.', 'صورة: مولّدة بالذكاء الاصطناعي أو مختارة من بحث صور جوجل.', 'ترجمة الوصفة كاملة عند تغيير اللغة.', 'شيفي، المساعد، للإجابة عن أسئلتك حولها لاحقًا.'] },
      ],
      steps: [
        { t: 'المس زر الإضافة واختر «اطلب من الذكاء الاصطناعي»', d: 'صِف الطبق وعدد الأشخاص وما يجب تجنّبه.' },
        { t: 'راجع الوصفة', d: 'المكوّنات والخطوات والقيم الغذائية مملوءة. غيّر ما تشاء.' },
        { t: 'احفظ واستخدمها', d: 'ضعها في خطة الأسبوع، ابنِ قائمة التسوّق، شغّل وضع الطبخ.' },
      ],
      faq: [
        { q: 'أي ذكاء اصطناعي يستخدم EasyPlate؟', a: 'Google Gemini عبر خوادم EasyPlate الخاصة. لا يُستخدم طلبك ولا النتيجة لتدريب النماذج.' },
        { q: 'هل وصفات الذكاء الاصطناعي دقيقة؟', a: 'هي مسودة قوية: يكتب الذكاء الاصطناعي كميات وخطوات حقيقية، والقيم الغذائية تقدير. تراجع كل شيء قبل الحفظ ويمكنك التعديل لاحقًا.' },
        { q: 'هل يستخدم الذكاء الاصطناعي ما لديّ في البيت؟', a: 'نعم. اذكرها في الطلب («لديّ أفخاذ دجاج وأرز وليمونة») فتُبنى الوصفة حولها.' },
        { q: 'هل يعمل بالعربية؟', a: 'العربية والعبرية والإنجليزية والفرنسية والروسية، للطلب والوصفة والردود المنطوقة من شيفي.' },
        { q: 'كم وصفة يمكنني إنشاؤها؟', a: 'يتضمن التطبيق المجاني عددًا يوميًا من قراءات وطلبات الذكاء الاصطناعي، يمدّده فيديو قصير.' },
      ],
      cta: { title: 'أخبر الذكاء الاصطناعي بما تشتهيه.', sub: 'حمّل EasyPlate وأنشئ أول وصفة لك.' },
    },
    fr: {
      title: 'Recettes IA : créer et importer des recettes | EasyPlate',
      description: 'Écrivez ce qui vous fait envie et obtenez une recette, ou transformez un lien, une vidéo, un PDF ou une note vocale. Nutrition et traduction comprises.',
      keywords: 'recettes ia, application recettes ia, générateur de recettes ia, créer une recette avec l’ia, recette à partir des ingrédients, idées repas ia',
      h1: 'Des recettes IA que vous cuisinez vraiment',
      intro: [
        'L’IA peut écrire une recette pour n’importe quoi, et c’est le problème : un mur de texte n’est pas un dîner. EasyPlate transforme chaque résultat IA en vraie fiche recette avec ingrédients, quantités, étapes, portions et nutrition par portion, dans la même bibliothèque que les recettes enregistrées depuis une vidéo ou un lien.',
        'Il y a deux façons d’obtenir une recette IA. Décrivez ce que vous voulez et l’IA l’écrit, en respectant les régimes et allergènes de votre profil. Ou donnez-lui quelque chose que vous avez déjà, un TikTok, une page web, un PDF, une note vocale, et elle le lit au même format. Dans les deux cas vous vérifiez avant d’enregistrer, et la recette est à vous : à modifier, planifier, acheter et cuisiner.',
      ],
      sections: [
        { h2: 'Une phrase, une recette', p: 'Choisissez « Demander à l’IA » et tapez ce que vous cherchez : « une soupe de lentilles végane pour six », « quelque chose de rapide avec le saumon du frigo », « un gâteau d’anniversaire sans œufs ». L’IA répond par une recette complète dans votre langue.', bullets: ['Régimes et allergènes du profil appliqués automatiquement.', 'Le nombre de portions ajuste les quantités.', 'Modifiez tout avant d’enregistrer ; l’IA n’écrase jamais vos changements.'] },
        { h2: 'L’IA lit ce que vous avez déjà', p: 'La plupart des recettes que vous voulez existent déjà quelque part. EasyPlate les lit dans la même fiche :', bullets: ['Une vidéo TikTok, Instagram, YouTube ou Facebook, même quand la recette est seulement parlée.', 'Une page web ou un texte collé.', 'Un PDF, une photo de page de recette ou une note vocale partagée depuis une autre app.'] },
        { h2: 'Finie par l’IA, pas seulement écrite', p: 'Chaque recette enregistrée reçoit ce qu’un générateur de texte oublie :', bullets: ['Calories, protéines, glucides et lipides par portion, estimés à l’enregistrement.', 'Une image : générée par l’IA ou choisie dans la recherche d’images Google.', 'La traduction de toute la recette quand vous changez de langue.', 'Shefi, l’assistant, pour répondre à vos questions plus tard.'] },
      ],
      steps: [
        { t: 'Touchez le plus et choisissez « Demander à l’IA »', d: 'Décrivez le plat, le nombre de convives et ce qu’il faut éviter.' },
        { t: 'Vérifiez la recette', d: 'Ingrédients, étapes et nutrition sont remplis. Changez ce que vous voulez.' },
        { t: 'Enregistrez et utilisez', d: 'Mettez-la au menu de la semaine, créez la liste de courses, lancez le mode cuisine.' },
      ],
      faq: [
        { q: 'Quelle IA utilise EasyPlate ?', a: 'Google Gemini, via les serveurs d’EasyPlate. Votre demande et le résultat ne servent pas à entraîner des modèles.' },
        { q: 'Les recettes IA sont-elles fiables ?', a: 'C’est un brouillon solide : l’IA écrit de vraies quantités et étapes, la nutrition est une estimation. Vous vérifiez tout avant d’enregistrer et pouvez modifier ensuite.' },
        { q: 'L’IA peut-elle utiliser ce que j’ai à la maison ?', a: 'Oui. Listez-le dans la demande (« j’ai des hauts de cuisse, du riz et un citron ») et la recette est construite autour.' },
        { q: 'Ça marche en français ?', a: 'Français, hébreu, anglais, arabe et russe, pour la demande, la recette et les réponses parlées de Shefi.' },
        { q: 'Combien de recettes IA puis-je faire ?', a: 'L’app gratuite comprend un nombre quotidien de lectures et de demandes IA, qu’une courte vidéo prolonge.' },
      ],
      cta: { title: 'Dites à l’IA ce qui vous fait envie.', sub: 'Téléchargez EasyPlate et créez votre première recette IA.' },
    },
    ru: {
      title: 'ИИ-рецепты: создавайте и импортируйте рецепты | EasyPlate',
      description: 'Напишите, чего хочется, и получите рецепт, или превратите ссылку, видео, PDF или голосовое в рецепт. КБЖУ, картинки и перевод включены. Бесплатно.',
      keywords: 'ии рецепты, рецепты с искусственным интеллектом, приложение рецептов ии, генератор рецептов, создать рецепт с ии, рецепт из продуктов ии, идеи для ужина ии',
      h1: 'ИИ-рецепты, которые вы действительно готовите',
      intro: [
        'ИИ может написать рецепт чего угодно — в этом и проблема: стена текста не ужин. EasyPlate превращает каждый ответ ИИ в настоящую карточку рецепта с ингредиентами, количествами, шагами, порциями и КБЖУ на порцию — в той же библиотеке, что и рецепты, сохранённые из видео или по ссылке.',
        'Получить ИИ-рецепт можно двумя способами. Опишите, что хотите, и ИИ напишет его с учётом диет и аллергенов из вашего профиля. Или дайте ему то, что уже есть: TikTok, веб-страницу, PDF, голосовое сообщение — и он считает это в тот же формат. В обоих случаях вы проверяете перед сохранением, а рецепт ваш: редактируйте, планируйте, покупайте, готовьте.',
      ],
      sections: [
        { h2: 'Напишите фразу — получите рецепт', p: 'Выберите «Попросить ИИ» и введите, что ищете: «веганский чечевичный суп на шестерых», «что-то быстрое с лососем из холодильника», «торт на день рождения без яиц». ИИ ответит полным рецептом на вашем языке.', bullets: ['Диеты и аллергены из профиля применяются автоматически.', 'Число порций пересчитывает количества.', 'Редактируйте что угодно перед сохранением; ИИ никогда не перезаписывает ваши правки.'] },
        { h2: 'ИИ читает то, что у вас уже есть', p: 'Большинство нужных рецептов уже где-то существует. EasyPlate считывает их в ту же карточку:', bullets: ['Видео из TikTok, Instagram, YouTube или Facebook, включая рецепты, которые только проговариваются.', 'Веб-страницу или вставленный текст.', 'PDF, фото страницы с рецептом или голосовое сообщение из другого приложения.'] },
        { h2: 'Доведён ИИ до конца, а не просто написан', p: 'Каждый сохранённый рецепт получает то, что генератор текста пропускает:', bullets: ['Калории, белки, углеводы и жиры на порцию, оценённые при сохранении.', 'Картинку: сгенерированную ИИ или выбранную из поиска картинок Google.', 'Перевод всего рецепта при смене языка.', 'Шефи, помощника, чтобы потом отвечать на вопросы о нём.'] },
      ],
      steps: [
        { t: 'Нажмите плюс и выберите «Попросить ИИ»', d: 'Опишите блюдо, число человек и чего избегать.' },
        { t: 'Проверьте рецепт', d: 'Ингредиенты, шаги и КБЖУ заполнены. Измените, что хотите.' },
        { t: 'Сохраните и используйте', d: 'Поставьте в план на неделю, соберите список покупок, включите режим готовки.' },
      ],
      faq: [
        { q: 'Какой ИИ использует EasyPlate?', a: 'Google Gemini через собственные серверы EasyPlate. Ваш запрос и результат не используются для обучения моделей.' },
        { q: 'Точны ли ИИ-рецепты?', a: 'Это сильный черновик: ИИ пишет реальные количества и шаги, КБЖУ — оценка. Вы проверяете всё перед сохранением и можете редактировать потом.' },
        { q: 'Может ли ИИ использовать то, что есть дома?', a: 'Да. Перечислите в запросе («есть куриные бёдра, рис и лимон») — и рецепт построится вокруг них.' },
        { q: 'Работает на русском?', a: 'Русский, иврит, английский, арабский и французский — для запроса, рецепта и голосовых ответов Шефи.' },
        { q: 'Сколько ИИ-рецептов можно сделать?', a: 'Бесплатное приложение включает дневное число ИИ-чтений и запросов, которое расширяет короткое видео.' },
      ],
      cta: { title: 'Скажите ИИ, чего хочется.', sub: 'Скачайте EasyPlate и создайте первый ИИ-рецепт.' },
    },
  },

  // ------------------------------------------------------------ receipt scanner
  'receipt-scanner': {
    icon: 'scan', screens: ['08_grocery', '01_recipes'],
    en: {
      title: 'Receipt Scanner App: Keep Every Grocery Price | EasyPlate',
      description: 'Point the camera at a supermarket receipt and the AI reads every line into your personal price book. Several photos or a PDF for long receipts. Free app.',
      keywords: 'receipt scanner app, scan grocery receipt, supermarket receipt scanner, receipt reader app, grocery receipt tracker, scan receipt to list, receipt scanning ai',
      h1: 'A receipt scanner that remembers what groceries cost',
      intro: [
        'A supermarket receipt is the most accurate price list you will ever hold, and it goes in the bin on the way out. EasyPlate scans it first. Point the camera, the app recognizes the paper and takes the picture on its own, and the AI reads each line into a product, a quantity, a unit and a price.',
        'Those lines become your price book. The next time an item is on your grocery list, EasyPlate shows what you paid for it last and estimates the total of the whole list before you leave the house. Long receipt? Take several photos or upload the PDF and they are merged into one.',
      ],
      sections: [
        { h2: 'Scan without pressing anything', p: 'Open the scanner from the grocery list. A tall guide frame shows where the receipt goes; when the paper sits inside it and the phone is still, the picture is taken for you.', bullets: ['Several photos for a long receipt, merged into one scan.', 'A photo from the gallery or a PDF receipt from the store app works too.', 'If the camera is unavailable the phone’s own camera opens instead.'] },
        { h2: 'The AI reads every line', p: 'The scan goes to the AI, which returns product lines, not a pile of text:', bullets: ['Generic product names ("entrecôte"), with the till’s wording kept alongside.', 'A unit for every line: per piece, per kilogram or per liter, with the quantity in that unit.', 'Deposits, bag charges, discounts and totals are left out, so the book holds prices only.', 'Lines the AI could not read are listed as notes, so nothing is silently dropped.'] },
        { h2: 'From receipt to price book to list', p: 'You review the lines, fix anything, and save. From then on:', bullets: ['The grocery list shows a price per line and an estimated total, marked as based on your past receipts.', 'The price book lists receipts by date, store and total, and the latest price per product.', 'Optionally share anonymized prices and see the median other shoppers paid.'] },
      ],
      steps: [
        { t: 'Open the scanner from the grocery list', d: 'Tap the receipt icon, then the camera. Hold the receipt inside the frame.' },
        { t: 'Let the AI read it', d: 'Lines appear with product, quantity, unit and price. Fix anything, add what was missed.' },
        { t: 'Save and shop smarter', d: 'Prices attach to your list items; the estimated total appears on the next list.' },
      ],
      faq: [
        { q: 'Which receipts can it read?', a: 'Any printed supermarket or grocery receipt, in the languages the app supports. Faded thermal paper is read as far as it is legible; unreadable lines are flagged.' },
        { q: 'Is my receipt uploaded anywhere?', a: 'The picture is sent to EasyPlate’s servers for the AI to read and the result is stored in your account. Sharing prices with other users is a switch you control, and it never includes the receipt itself.' },
        { q: 'Can I add a price without a receipt?', a: 'Yes. The price book has an "add price" action for a product, store and price you typed.' },
        { q: 'Does it track my spending?', a: 'It keeps the receipts you scanned, with store, date and total, and the price history per product. It is a price book, not a budget app.' },
      ],
      cta: { title: 'Scan the receipt before it hits the bin.', sub: 'Download EasyPlate and keep every price.' },
    },
    he: {
      title: 'סריקת קבלות: האפליקציה שזוכרת כל מחיר מהסופר | EasyPlate',
      description: 'מכוונים את המצלמה לקבלה מהסופר וה-AI קורא כל שורה לספר המחירים האישי שלכם. כמה צילומים או PDF לקבלה ארוכה. חינם לאייפון ולאנדרואיד.',
      keywords: 'סריקת קבלות, אפליקציה לסריקת קבלות, סריקת קבלה מהסופר, קורא קבלות, מעקב קבלות סופר, סריקת קבלה לרשימת קניות, סריקת קבלות AI',
      h1: 'סורק קבלות שזוכר כמה עלו הקניות',
      intro: [
        'קבלה מהסופר היא מחירון מדויק יותר מכל דבר אחר שתחזיקו, והיא הולכת לפח בדרך החוצה. EasyPlate סורקת אותה קודם. מכוונים את המצלמה, האפליקציה מזהה את הנייר ומצלמת לבד, וה-AI קורא כל שורה למוצר, כמות, יחידה ומחיר.',
        'השורות האלה הופכות לספר המחירים שלכם. בפעם הבאה שפריט נמצא ברשימת הקניות, EasyPlate מראה כמה שילמתם עליו בפעם הקודמת ומעריכה את הסכום של כל הרשימה לפני שיוצאים מהבית. קבלה ארוכה? מצלמים כמה תמונות או מעלים PDF והן מאוחדות לסריקה אחת.',
      ],
      sections: [
        { h2: 'סורקים בלי ללחוץ על כלום', p: 'פותחים את הסורק מרשימת הקניות. מסגרת הנחיה גבוהה מראה איפה הקבלה אמורה להיות; כשהנייר בתוכה והטלפון יציב, הצילום נעשה בשבילכם.', bullets: ['כמה צילומים לקבלה ארוכה, מאוחדים לסריקה אחת.', 'גם תמונה מהגלריה או קבלת PDF מאפליקציית הרשת עובדות.', 'אם המצלמה לא זמינה, נפתחת מצלמת הטלפון עצמה.'] },
        { h2: 'ה-AI קורא כל שורה', p: 'הסריקה נשלחת ל-AI, שמחזיר שורות מוצר ולא ערימת טקסט:', bullets: ['שמות מוצר גנריים (״אנטריקוט״), והניסוח של הקופה נשמר לצדם.', 'יחידה לכל שורה: ליחידה, לקילוגרם או לליטר, עם הכמות באותה יחידה.', 'פיקדונות, שקיות, הנחות וסכומים מושמטים, כך שבספר יש רק מחירים.', 'שורות שה-AI לא הצליח לקרוא מופיעות כהערות, כדי ששום דבר לא ייעלם בשקט.'] },
        { h2: 'מקבלה לספר מחירים לרשימה', p: 'בודקים את השורות, מתקנים מה שצריך, ושומרים. מכאן והלאה:', bullets: ['רשימת הקניות מציגה מחיר לכל שורה וסכום משוער, מסומן כמבוסס על הקבלות הקודמות שלכם.', 'ספר המחירים מציג קבלות לפי תאריך, חנות וסכום, ואת המחיר האחרון לכל מוצר.', 'אפשר לשתף מחירים באופן אנונימי ולראות את החציון ששילמו קונים אחרים.'] },
      ],
      steps: [
        { t: 'פותחים את הסורק מרשימת הקניות', d: 'לוחצים על אייקון הקבלה, ואז על המצלמה. מחזיקים את הקבלה בתוך המסגרת.' },
        { t: 'נותנים ל-AI לקרוא', d: 'השורות מופיעות עם מוצר, כמות, יחידה ומחיר. מתקנים, מוסיפים מה שפוספס.' },
        { t: 'שומרים וקונים חכם', d: 'המחירים נצמדים לפריטי הרשימה; הסכום המשוער מופיע ברשימה הבאה.' },
      ],
      faq: [
        { q: 'אילו קבלות הוא קורא?', a: 'כל קבלה מודפסת מסופר או מכולת, בשפות שהאפליקציה תומכת בהן. נייר תרמי דהוי נקרא עד כמה שהוא קריא; שורות לא קריאות מסומנות.' },
        { q: 'הקבלה שלי נשלחת לאנשהו?', a: 'התמונה נשלחת לשרתים של EasyPlate כדי שה-AI יקרא אותה, והתוצאה נשמרת בחשבון שלכם. שיתוף מחירים עם משתמשים אחרים הוא מתג בשליטתכם, והוא לעולם לא כולל את הקבלה עצמה.' },
        { q: 'אפשר להוסיף מחיר בלי קבלה?', a: 'כן. בספר המחירים יש פעולת ״הוספת מחיר״ למוצר, חנות ומחיר שהקלדתם.' },
        { q: 'זה עוקב אחרי ההוצאות שלי?', a: 'הוא שומר את הקבלות שסרקתם, עם חנות, תאריך וסכום, והיסטוריית מחירים לכל מוצר. זה ספר מחירים, לא אפליקציית תקציב.' },
      ],
      cta: { title: 'סורקים את הקבלה לפני שהיא בפח.', sub: 'הורידו את EasyPlate ושמרו כל מחיר.' },
    },
    ar: {
      title: 'تطبيق مسح الإيصالات: احفظ كل سعر من البقالة | EasyPlate',
      description: 'وجّه الكاميرا إلى إيصال السوبرماركت فيقرأ الذكاء الاصطناعي كل سطر في دفتر أسعارك الشخصي. عدة صور أو PDF للإيصالات الطويلة. مجاني على iOS وأندرويد.',
      keywords: 'تطبيق مسح الإيصالات, مسح إيصال البقالة, ماسح إيصالات السوبرماركت, قارئ الإيصالات, تتبّع إيصالات البقالة, مسح الإيصال إلى قائمة, مسح الإيصالات بالذكاء الاصطناعي',
      h1: 'ماسح إيصالات يتذكّر كم كلّفت البقالة',
      intro: [
        'إيصال السوبرماركت أدق قائمة أسعار ستحملها يومًا، ويذهب إلى سلة المهملات في طريق الخروج. يمسحه EasyPlate أولًا. وجّه الكاميرا، فيتعرّف التطبيق على الورقة ويلتقط الصورة بنفسه، ويقرأ الذكاء الاصطناعي كل سطر إلى منتج وكمية ووحدة وسعر.',
        'تصبح تلك السطور دفتر أسعارك. في المرة التالية التي يكون فيها عنصر في قائمة تسوّقك، يعرض EasyPlate ما دفعته آخر مرة ويقدّر مجموع القائمة كلها قبل مغادرة البيت. إيصال طويل؟ التقط عدة صور أو ارفع ملف PDF فتُدمج في مسح واحد.',
      ],
      sections: [
        { h2: 'امسح دون الضغط على شيء', p: 'افتح الماسح من قائمة التسوّق. يُظهر إطار إرشادي طويل مكان الإيصال؛ وعندما تستقر الورقة داخله ويثبت الهاتف، تُلتقط الصورة عنك.', bullets: ['عدة صور لإيصال طويل، تُدمج في مسح واحد.', 'تعمل أيضًا صورة من المعرض أو إيصال PDF من تطبيق المتجر.', 'إن لم تتوفر الكاميرا تُفتح كاميرا الهاتف نفسها.'] },
        { h2: 'الذكاء الاصطناعي يقرأ كل سطر', p: 'يذهب المسح إلى الذكاء الاصطناعي الذي يعيد سطور منتجات لا كومة نص:', bullets: ['أسماء منتجات عامة («أنتريكوت») مع الاحتفاظ بصياغة الكاشير بجانبها.', 'وحدة لكل سطر: للقطعة أو للكيلوغرام أو لللتر، مع الكمية بتلك الوحدة.', 'تُستبعد الودائع ورسوم الأكياس والخصومات والمجاميع، فلا يحوي الدفتر إلا الأسعار.', 'تُدرج السطور التي تعذّرت قراءتها كملاحظات، فلا يسقط شيء بصمت.'] },
        { h2: 'من الإيصال إلى دفتر الأسعار إلى القائمة', p: 'تراجع السطور وتصحّح ما يلزم وتحفظ. ومن ثمّ:', bullets: ['تعرض قائمة التسوّق سعرًا لكل سطر ومجموعًا تقديريًا، مُعلَّمًا بأنه مبني على إيصالاتك السابقة.', 'يعرض دفتر الأسعار الإيصالات حسب التاريخ والمتجر والمجموع، وآخر سعر لكل منتج.', 'يمكنك اختياريًا مشاركة أسعار مجهولة الهوية ورؤية الوسيط الذي دفعه متسوّقون آخرون.'] },
      ],
      steps: [
        { t: 'افتح الماسح من قائمة التسوّق', d: 'المس أيقونة الإيصال ثم الكاميرا. أمسك الإيصال داخل الإطار.' },
        { t: 'دع الذكاء الاصطناعي يقرأه', d: 'تظهر السطور بالمنتج والكمية والوحدة والسعر. صحّح ما يلزم وأضف ما فات.' },
        { t: 'احفظ وتسوّق بذكاء', d: 'تلتصق الأسعار بعناصر قائمتك؛ ويظهر المجموع التقديري في القائمة التالية.' },
      ],
      faq: [
        { q: 'أي إيصالات يقرأ؟', a: 'أي إيصال مطبوع من سوبرماركت أو بقالة، باللغات التي يدعمها التطبيق. يُقرأ الورق الحراري الباهت بقدر وضوحه؛ وتُعلَّم السطور غير المقروءة.' },
        { q: 'هل يُرفع إيصالي إلى مكان ما؟', a: 'تُرسل الصورة إلى خوادم EasyPlate ليقرأها الذكاء الاصطناعي وتُحفظ النتيجة في حسابك. مشاركة الأسعار مع مستخدمين آخرين مفتاح تتحكم به أنت، ولا يشمل الإيصال نفسه أبدًا.' },
        { q: 'هل يمكن إضافة سعر دون إيصال؟', a: 'نعم. في دفتر الأسعار إجراء «إضافة سعر» لمنتج ومتجر وسعر تكتبها بنفسك.' },
        { q: 'هل يتتبّع إنفاقي؟', a: 'يحتفظ بالإيصالات التي مسحتها، بالمتجر والتاريخ والمجموع، وبتاريخ الأسعار لكل منتج. هو دفتر أسعار لا تطبيق ميزانية.' },
      ],
      cta: { title: 'امسح الإيصال قبل أن يصل إلى السلة.', sub: 'حمّل EasyPlate واحفظ كل سعر.' },
    },
    fr: {
      title: 'Scanner de tickets de caisse : chaque prix gardé | EasyPlate',
      description: 'Visez un ticket de supermarché : l’IA lit chaque ligne dans votre carnet de prix personnel. Plusieurs photos ou un PDF pour les longs tickets. Gratuit.',
      keywords: 'scanner ticket de caisse, application scan ticket de caisse, scanner reçu supermarché, lecteur de tickets, suivi tickets de courses, scanner ticket vers liste, scan ticket ia',
      h1: 'Un scanner de tickets qui se souvient du prix des courses',
      intro: [
        'Un ticket de supermarché est la liste de prix la plus précise que vous tiendrez jamais, et il finit à la poubelle en sortant. EasyPlate le scanne d’abord. Visez-le, l’app reconnaît le papier et prend la photo toute seule, et l’IA lit chaque ligne en produit, quantité, unité et prix.',
        'Ces lignes deviennent votre carnet de prix. La prochaine fois qu’un article est sur votre liste de courses, EasyPlate montre ce que vous l’avez payé la dernière fois et estime le total de toute la liste avant de partir. Ticket long ? Prenez plusieurs photos ou importez le PDF : ils sont fusionnés en un seul scan.',
      ],
      sections: [
        { h2: 'Scanner sans rien presser', p: 'Ouvrez le scanner depuis la liste de courses. Un cadre vertical montre où placer le ticket ; quand le papier est dedans et le téléphone immobile, la photo est prise pour vous.', bullets: ['Plusieurs photos pour un long ticket, fusionnées en un scan.', 'Une photo de la galerie ou un ticket PDF de l’app du magasin fonctionnent aussi.', 'Si l’appareil photo est indisponible, celui du téléphone s’ouvre à la place.'] },
        { h2: 'L’IA lit chaque ligne', p: 'Le scan part à l’IA, qui renvoie des lignes de produits, pas un tas de texte :', bullets: ['Des noms de produits génériques (« entrecôte »), avec le libellé de la caisse conservé à côté.', 'Une unité par ligne : à la pièce, au kilo ou au litre, avec la quantité dans cette unité.', 'Consignes, sacs, remises et totaux sont écartés : le carnet ne garde que des prix.', 'Les lignes illisibles sont listées comme notes, rien n’est perdu en silence.'] },
        { h2: 'Du ticket au carnet de prix à la liste', p: 'Vous vérifiez les lignes, corrigez, enregistrez. Ensuite :', bullets: ['La liste de courses affiche un prix par ligne et un total estimé, signalé comme basé sur vos tickets passés.', 'Le carnet de prix liste les tickets par date, magasin et total, et le dernier prix de chaque produit.', 'Partagez éventuellement des prix anonymisés et voyez la médiane payée par les autres.'] },
      ],
      steps: [
        { t: 'Ouvrez le scanner depuis la liste de courses', d: 'Touchez l’icône ticket, puis l’appareil photo. Tenez le ticket dans le cadre.' },
        { t: 'Laissez l’IA le lire', d: 'Les lignes apparaissent avec produit, quantité, unité et prix. Corrigez, ajoutez ce qui manque.' },
        { t: 'Enregistrez et achetez malin', d: 'Les prix s’attachent aux articles de votre liste ; le total estimé apparaît sur la prochaine.' },
      ],
      faq: [
        { q: 'Quels tickets peut-il lire ?', a: 'Tout ticket imprimé de supermarché ou d’épicerie, dans les langues prises en charge. Le papier thermique pâli est lu tant qu’il est lisible ; les lignes illisibles sont signalées.' },
        { q: 'Mon ticket est-il envoyé quelque part ?', a: 'La photo part aux serveurs d’EasyPlate pour la lecture par l’IA et le résultat est stocké dans votre compte. Le partage des prix avec d’autres utilisateurs est un interrupteur que vous contrôlez, et il n’inclut jamais le ticket lui-même.' },
        { q: 'Puis-je ajouter un prix sans ticket ?', a: 'Oui. Le carnet de prix a une action « ajouter un prix » pour un produit, un magasin et un prix saisis.' },
        { q: 'Suit-il mes dépenses ?', a: 'Il garde les tickets scannés, avec magasin, date et total, et l’historique des prix par produit. C’est un carnet de prix, pas une app de budget.' },
      ],
      cta: { title: 'Scannez le ticket avant la poubelle.', sub: 'Téléchargez EasyPlate et gardez chaque prix.' },
    },
    ru: {
      title: 'Сканер чеков: сохраните каждую цену из магазина | EasyPlate',
      description: 'Наведите камеру на чек из супермаркета — ИИ считает каждую строку в вашу личную книгу цен. Несколько фото или PDF для длинных чеков. Бесплатно.',
      keywords: 'сканер чеков, приложение для сканирования чеков, сканировать чек из магазина, распознавание чеков, учёт чеков продуктов, чек в список покупок, сканирование чеков ии',
      h1: 'Сканер чеков, который помнит, сколько стоили продукты',
      intro: [
        'Чек из супермаркета — самый точный прайс-лист, который вы когда-либо держали, и он летит в урну на выходе. EasyPlate сначала его сканирует. Наведите камеру — приложение распознает бумагу и само сделает снимок, а ИИ считает каждую строку в продукт, количество, единицу и цену.',
        'Эти строки становятся вашей книгой цен. Когда товар снова окажется в списке покупок, EasyPlate покажет, сколько вы платили за него в прошлый раз, и оценит сумму всего списка ещё до выхода из дома. Длинный чек? Сделайте несколько фото или загрузите PDF — они объединятся в одно сканирование.',
      ],
      sections: [
        { h2: 'Сканируйте, ничего не нажимая', p: 'Откройте сканер из списка покупок. Высокая рамка показывает, где должен быть чек; когда бумага внутри и телефон неподвижен, снимок делается сам.', bullets: ['Несколько фото для длинного чека, объединённые в одно сканирование.', 'Фото из галереи или PDF-чек из приложения магазина тоже подходят.', 'Если камера недоступна, откроется штатная камера телефона.'] },
        { h2: 'ИИ читает каждую строку', p: 'Скан уходит ИИ, который возвращает строки товаров, а не кучу текста:', bullets: ['Общие названия продуктов («антрекот») с сохранением формулировки кассы рядом.', 'Единица для каждой строки: за штуку, за килограмм или за литр, с количеством в этой единице.', 'Залоги, пакеты, скидки и итоги исключаются — в книге только цены.', 'Нечитаемые строки перечислены как заметки, ничто не пропадает молча.'] },
        { h2: 'От чека к книге цен и к списку', p: 'Вы проверяете строки, исправляете и сохраняете. Дальше:', bullets: ['Список покупок показывает цену каждой строки и примерную сумму с пометкой, что она основана на ваших прошлых чеках.', 'Книга цен показывает чеки по дате, магазину и сумме и последнюю цену каждого продукта.', 'По желанию делитесь обезличенными ценами и видите медиану, которую платили другие.'] },
      ],
      steps: [
        { t: 'Откройте сканер из списка покупок', d: 'Нажмите значок чека, затем камеру. Держите чек внутри рамки.' },
        { t: 'Дайте ИИ прочитать', d: 'Появятся строки с продуктом, количеством, единицей и ценой. Исправьте, добавьте пропущенное.' },
        { t: 'Сохраните и покупайте умнее', d: 'Цены привяжутся к позициям списка; примерная сумма появится в следующем списке.' },
      ],
      faq: [
        { q: 'Какие чеки он читает?', a: 'Любой печатный чек супермаркета или магазина на поддерживаемых языках. Выцветшая термобумага читается, насколько разборчива; нечитаемые строки помечаются.' },
        { q: 'Мой чек куда-то отправляется?', a: 'Снимок отправляется на серверы EasyPlate для чтения ИИ, результат хранится в вашем аккаунте. Обмен ценами с другими — переключатель под вашим контролем, и сам чек в него никогда не входит.' },
        { q: 'Можно добавить цену без чека?', a: 'Да. В книге цен есть действие «добавить цену» для продукта, магазина и цены, введённых вручную.' },
        { q: 'Он следит за моими расходами?', a: 'Он хранит отсканированные чеки с магазином, датой и суммой и историю цен по продуктам. Это книга цен, а не приложение для бюджета.' },
      ],
      cta: { title: 'Отсканируйте чек, пока он не в урне.', sub: 'Скачайте EasyPlate и сохраните каждую цену.' },
    },
  },
};
