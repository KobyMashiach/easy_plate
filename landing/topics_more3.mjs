// Guide pages, part three: Shefi, the voice cooking assistant. Merged into
// TOPICS by topics.mjs. Everything stated must be true of the app.

export const MORE_TOPICS_3 = {
  // ------------------------------------------------------------ AI assistant
  'ai-cooking-assistant': {
    icon: 'mic', screens: ['02_recipe_details', '01_recipes'],
    en: {
      title: 'AI Cooking Assistant: Ask About Any Recipe by Voice | EasyPlate',
      description: 'Shefi answers questions about your recipes, plans and grocery lists, swaps ingredients, builds lists and starts Cook Mode. Type or talk, and hear the answer read back.',
      keywords: 'ai cooking assistant, voice cooking assistant, recipe chatbot, ask questions about a recipe, substitute ingredient app, hands-free recipe help, kitchen voice assistant',
      h1: 'Shefi: a cooking assistant that knows your recipes',
      intro: [
        'A general chatbot can tell you what to swap for heavy cream. It cannot tell you what to swap in your grandmother’s lasagne, because it has never seen it. Shefi lives inside EasyPlate, so it reads your recipes, your weekly plan and your grocery lists, and acts on them.',
        'Ask in writing or out loud. Shefi answers in your language, puts a recipe on Tuesday, adds the missing items to the list, scales a dish for eight, or starts Cook Mode on the recipe you are holding. Speak to it and it reads the answer back; type and it stays quiet. Open it from inside a recipe, a plan or a list and it talks about that item alone.',
      ],
      sections: [
        { h2: 'What Shefi can do', p: 'Shefi works over your own kitchen, not a search engine:', bullets: ['Answer about any recipe you saved: substitutions, timing, how to scale, what to serve with it.', 'Add a recipe to a day of the plan, or build the grocery list from the week.', 'Add items to a list, create a list from one recipe, mark things bought.', 'Start Cook Mode and set a timer on the step you are on.', 'Save a preference, such as an allergen, so every later answer respects it.'] },
        { h2: 'Talk, and hear it talk back', p: 'Tap the microphone, ask, and Shefi answers out loud with a natural voice in Hebrew, English, Arabic, French or Russian. When it needs something more from you the microphone opens again on its own, so a whole exchange happens without touching the screen. Type a question instead and the reply stays silent.', bullets: ['Speech recognition runs on the phone.', 'Replies are spoken by a natural cloud voice; a device voice is the fallback.', 'No asterisks or symbols are ever read aloud.'] },
        { h2: 'Focused on one recipe, plan or list', p: 'Every recipe, meal plan and grocery list has an "Ask Shefi" button. That conversation knows only that item and politely declines anything else, so "what can I leave out?" is answered about the dish in front of you. Shefi is part of EasyPlate Pro.', bullets: ['Opens with "What would you like to know about <name>?".', 'Reads the actual ingredients, amounts and steps.', 'Can edit the item in place when you ask.'] },
      ],
      steps: [
        { t: 'Tap the Shefi button', d: 'It floats on every tab. Inside a recipe, plan or list, use "Ask Shefi" for a focused chat.' },
        { t: 'Ask by voice or text', d: 'Tap the microphone and speak, or type. Shefi answers in your language and acts when you ask it to.' },
        { t: 'Let it do the work', d: 'Plan the day, fill the list, start cooking: each action shows what changed, and you can undo it.' },
      ],
      faq: [
        { q: 'Does Shefi see my recipes?', a: 'Yes, that is the point. It reads the recipes, plans and lists in your account to answer and to act. Nothing is shared with other users.' },
        { q: 'Which languages does it speak?', a: 'Hebrew, English, Arabic, French and Russian, both for understanding and for the spoken reply.' },
        { q: 'Does it need the internet?', a: 'Yes. Shefi runs on EasyPlate’s servers; your saved recipes still open offline.' },
        { q: 'Can it change my recipes?', a: 'Only when you ask it to, and it confirms what it changed. Edits can be undone.' },
        { q: 'Is Shefi free?', a: 'Shefi is included in EasyPlate Pro, together with Cook Mode, unlimited AI imports and no ads, for ₪20 a month through the App Store or Google Play.' },
      ],
      cta: { title: 'Ask your kitchen a question.', sub: 'Download EasyPlate and say hello to Shefi.' },
    },
    he: {
      title: 'עוזר בישול AI: שואלים על כל מתכון, גם בקול | EasyPlate',
      description: 'שפי עונה על שאלות על המתכונים, התפריטים ורשימות הקניות שלכם, מחליף מצרכים, בונה רשימות ומפעיל מצב בישול. מקלידים או מדברים, ושומעים את התשובה.',
      keywords: 'עוזר בישול AI, עוזר קולי למטבח, צ׳אט מתכונים, שאלות על מתכון, להחליף מצרך במתכון, עזרה במתכון בלי ידיים, אפליקציית בישול עם בינה מלאכותית',
      h1: 'שפי: עוזר בישול שמכיר את המתכונים שלכם',
      intro: [
        'צ׳אטבוט כללי יודע להגיד במה מחליפים שמנת. הוא לא יודע במה מחליפים אותה בלזניה של סבתא, כי הוא מעולם לא ראה אותה. שפי חי בתוך EasyPlate, ולכן הוא קורא את המתכונים, התפריט השבועי ורשימות הקניות שלכם, ופועל עליהם.',
        'שואלים בכתב או בקול. שפי עונה בשפה שלכם, שם מתכון ביום שלישי, מוסיף לרשימה את מה שחסר, מגדיל מנה לשמונה סועדים, או מפעיל מצב בישול על המתכון שפתוח מולכם. מדברים אליו והוא מקריא את התשובה; מקלידים והוא שותק. פותחים אותו מתוך מתכון, תפריט או רשימה והוא מדבר רק על הפריט הזה.',
      ],
      sections: [
        { h2: 'מה שפי יודע לעשות', p: 'שפי עובד על המטבח שלכם, לא על מנוע חיפוש:', bullets: ['לענות על כל מתכון ששמרתם: תחליפים, זמנים, איך להגדיל, מה להגיש לצד.', 'להוסיף מתכון ליום בתפריט, או לבנות את רשימת הקניות מהשבוע.', 'להוסיף פריטים לרשימה, ליצור רשימה ממתכון אחד, לסמן מה נקנה.', 'להפעיל מצב בישול ולקבוע טיימר על השלב שאתם בו.', 'לשמור העדפה, כמו אלרגן, כך שכל תשובה הבאה תכבד אותה.'] },
        { h2: 'מדברים, והוא עונה בקול', p: 'לוחצים על המיקרופון, שואלים, ושפי עונה בקול טבעי בעברית, אנגלית, ערבית, צרפתית או רוסית. כשהוא צריך עוד משהו מכם המיקרופון נפתח שוב לבד, כך ששיחה שלמה עוברת בלי לגעת במסך. מקלידים שאלה במקום, והתשובה נשארת שקטה.', bullets: ['זיהוי הדיבור רץ בטלפון.', 'התשובות מוקראות בקול ענן טבעי; קול המכשיר הוא הגיבוי.', 'כוכביות וסימנים לעולם לא מוקראים.'] },
        { h2: 'ממוקד במתכון, בתפריט או ברשימה אחת', p: 'לכל מתכון, תפריט ורשימת קניות יש כפתור ״שאלו את שפי״. השיחה הזו מכירה רק את הפריט הזה ומסרבת בנימוס לכל השאר, כך ש״מה אפשר להשמיט?״ נענה על המנה שמולכם. שפי הוא חלק מ-EasyPlate Pro.', bullets: ['נפתח ב״מה תרצו לדעת לגבי <שם>?״.', 'קורא את המצרכים, הכמויות והשלבים האמיתיים.', 'יכול לערוך את הפריט במקום כשמבקשים.'] },
      ],
      steps: [
        { t: 'לוחצים על כפתור שפי', d: 'הוא צף בכל טאב. בתוך מתכון, תפריט או רשימה משתמשים ב״שאלו את שפי״ לשיחה ממוקדת.' },
        { t: 'שואלים בקול או בכתב', d: 'לוחצים על המיקרופון ומדברים, או מקלידים. שפי עונה בשפה שלכם ופועל כשמבקשים.' },
        { t: 'נותנים לו לעבוד', d: 'לתכנן את היום, למלא את הרשימה, להתחיל לבשל: כל פעולה מראה מה השתנה, ואפשר לבטל.' },
      ],
      faq: [
        { q: 'שפי רואה את המתכונים שלי?', a: 'כן, זו הנקודה. הוא קורא את המתכונים, התפריטים והרשימות בחשבון שלכם כדי לענות ולפעול. שום דבר לא משותף עם משתמשים אחרים.' },
        { q: 'באילו שפות הוא מדבר?', a: 'עברית, אנגלית, ערבית, צרפתית ורוסית, גם בהבנה וגם בתשובה המדוברת.' },
        { q: 'צריך אינטרנט?', a: 'כן. שפי רץ בשרתים של EasyPlate; המתכונים השמורים שלכם עדיין נפתחים בלי חיבור.' },
        { q: 'הוא יכול לשנות לי מתכונים?', a: 'רק כשמבקשים, והוא מאשר מה שינה. עריכות אפשר לבטל.' },
        { q: 'שפי חינמי?', a: 'שפי כלול ב-EasyPlate Pro, יחד עם מצב בישול, ניתוחי AI ללא הגבלה ובלי פרסומות, ב-20 ₪ לחודש דרך App Store או Google Play.' },
      ],
      cta: { title: 'תשאלו את המטבח שלכם שאלה.', sub: 'הורידו את EasyPlate ותגידו שלום לשפי.' },
    },
    ar: {
      title: 'مساعد طبخ بالذكاء الاصطناعي: اسأل عن أي وصفة بصوتك | EasyPlate',
      description: 'يجيب شيفي عن أسئلتك حول وصفاتك وخططك وقوائم تسوّقك، يستبدل المكوّنات، يبني القوائم ويشغّل وضع الطبخ. اكتب أو تحدّث، واسمع الجواب.',
      keywords: 'مساعد طبخ ذكاء اصطناعي, مساعد صوتي للمطبخ, شات وصفات, أسئلة عن وصفة, استبدال مكوّن في وصفة, مساعدة في الوصفة بلا أيدٍ, تطبيق طبخ بالذكاء الاصطناعي',
      h1: 'شيفي: مساعد طبخ يعرف وصفاتك',
      intro: [
        'يستطيع أي روبوت محادثة أن يخبرك بما تستبدل به الكريمة. لكنه لا يعرف بماذا تستبدلها في لازانيا جدّتك، لأنه لم يرها قط. يعيش شيفي داخل EasyPlate، فيقرأ وصفاتك وخطتك الأسبوعية وقوائم تسوّقك، ويتصرّف بناءً عليها.',
        'اسأل كتابةً أو بصوتك. يجيب شيفي بلغتك، يضع وصفة يوم الثلاثاء، يضيف ما ينقص إلى القائمة، يضاعف طبقًا لثمانية، أو يشغّل وضع الطبخ على الوصفة المفتوحة أمامك. تحدّث إليه فيقرأ الجواب؛ اكتب فيبقى صامتًا. افتحه من داخل وصفة أو خطة أو قائمة فيتحدث عن ذلك العنصر وحده.',
      ],
      sections: [
        { h2: 'ما يستطيع شيفي فعله', p: 'يعمل شيفي على مطبخك أنت، لا على محرّك بحث:', bullets: ['الإجابة عن أي وصفة حفظتها: البدائل، التوقيت، كيفية المضاعفة، ما يُقدَّم معها.', 'إضافة وصفة إلى يوم في الخطة، أو بناء قائمة التسوّق من الأسبوع.', 'إضافة عناصر إلى قائمة، إنشاء قائمة من وصفة واحدة، تعليم ما اشتُري.', 'تشغيل وضع الطبخ وضبط مؤقّت على الخطوة الحالية.', 'حفظ تفضيل، مثل مادة مسبّبة للحساسية، فتحترمه كل إجابة لاحقة.'] },
        { h2: 'تحدّث، واسمعه يردّ', p: 'اضغط الميكروفون، اسأل، فيجيب شيفي بصوت طبيعي بالعبرية أو الإنجليزية أو العربية أو الفرنسية أو الروسية. وحين يحتاج شيئًا إضافيًا منك يُفتح الميكروفون من جديد تلقائيًا، فتتم محادثة كاملة دون لمس الشاشة. اكتب سؤالًا بدلًا من ذلك فيبقى الردّ صامتًا.', bullets: ['التعرّف على الكلام يعمل على الهاتف.', 'تُقرأ الردود بصوت سحابي طبيعي؛ وصوت الجهاز هو البديل.', 'لا تُقرأ النجوم أو الرموز أبدًا.'] },
        { h2: 'مركّز على وصفة أو خطة أو قائمة واحدة', p: 'لكل وصفة وخطة وجبات وقائمة تسوّق زر «اسأل شيفي». تعرف تلك المحادثة ذلك العنصر فقط وترفض بأدب ما سواه، فيُجاب عن «ماذا يمكنني أن أحذف؟» حول الطبق الذي أمامك. شيفي جزء من EasyPlate Pro.', bullets: ['يبدأ بـ«ماذا تريد أن تعرف عن <الاسم>؟».', 'يقرأ المكوّنات والكميات والخطوات الفعلية.', 'يمكنه تعديل العنصر في مكانه عندما تطلب.'] },
      ],
      steps: [
        { t: 'اضغط زر شيفي', d: 'يطفو في كل تبويب. داخل وصفة أو خطة أو قائمة استخدم «اسأل شيفي» لمحادثة مركّزة.' },
        { t: 'اسأل بصوتك أو كتابةً', d: 'اضغط الميكروفون وتحدّث، أو اكتب. يجيب شيفي بلغتك ويتصرّف حين تطلب.' },
        { t: 'دعه يقوم بالعمل', d: 'خطّط اليوم، املأ القائمة، ابدأ الطبخ: كل إجراء يُظهر ما تغيّر، ويمكنك التراجع عنه.' },
      ],
      faq: [
        { q: 'هل يرى شيفي وصفاتي؟', a: 'نعم، هذا هو المقصود. يقرأ الوصفات والخطط والقوائم في حسابك ليجيب ويتصرّف. لا يُشارَك شيء مع مستخدمين آخرين.' },
        { q: 'بأي لغات يتحدث؟', a: 'العبرية والإنجليزية والعربية والفرنسية والروسية، فهمًا وردًّا منطوقًا.' },
        { q: 'هل يحتاج إلى الإنترنت؟', a: 'نعم. يعمل شيفي على خوادم EasyPlate؛ وتبقى وصفاتك المحفوظة تُفتح دون اتصال.' },
        { q: 'هل يستطيع تغيير وصفاتي؟', a: 'فقط عندما تطلب، ويؤكد ما غيّره. ويمكن التراجع عن التعديلات.' },
        { q: 'هل شيفي مجاني؟', a: 'شيفي مضمّن في EasyPlate Pro مع وضع الطبخ والاستيراد غير المحدود بالذكاء الاصطناعي وبدون إعلانات، مقابل 20 ₪ شهريًا عبر App Store أو Google Play.' },
      ],
      cta: { title: 'اسأل مطبخك سؤالًا.', sub: 'حمّل EasyPlate وقل مرحبًا لشيفي.' },
    },
    fr: {
      title: 'Assistant de cuisine IA : posez vos questions sur une recette, à la voix | EasyPlate',
      description: 'Shefi répond aux questions sur vos recettes, vos plans et vos listes de courses, remplace des ingrédients, construit des listes et lance le mode cuisine. Écrivez ou parlez, et écoutez la réponse.',
      keywords: 'assistant de cuisine IA, assistant vocal cuisine, chatbot recettes, questions sur une recette, remplacer un ingrédient, aide recette mains libres, application cuisine intelligence artificielle',
      h1: 'Shefi : un assistant de cuisine qui connaît vos recettes',
      intro: [
        'Un chatbot généraliste sait par quoi remplacer la crème. Il ne sait pas par quoi la remplacer dans les lasagnes de votre grand-mère, car il ne les a jamais vues. Shefi vit dans EasyPlate : il lit vos recettes, votre plan de la semaine et vos listes de courses, et agit dessus.',
        'Demandez à l’écrit ou à voix haute. Shefi répond dans votre langue, place une recette le mardi, ajoute à la liste ce qui manque, adapte un plat pour huit, ou lance le mode cuisine sur la recette ouverte devant vous. Parlez-lui et il lit la réponse ; écrivez et il reste silencieux. Ouvrez-le depuis une recette, un plan ou une liste et il ne parle que de cet élément.',
      ],
      sections: [
        { h2: 'Ce que Shefi sait faire', p: 'Shefi travaille sur votre cuisine, pas sur un moteur de recherche :', bullets: ['Répondre sur toute recette enregistrée : substitutions, temps, comment adapter, que servir avec.', 'Ajouter une recette à un jour du plan, ou construire la liste de courses de la semaine.', 'Ajouter des articles à une liste, créer une liste depuis une recette, cocher ce qui est acheté.', 'Lancer le mode cuisine et régler un minuteur sur l’étape en cours.', 'Enregistrer une préférence, comme un allergène, respectée dans chaque réponse suivante.'] },
        { h2: 'Parlez, et écoutez-le répondre', p: 'Touchez le micro, posez votre question, et Shefi répond à voix haute avec une voix naturelle en hébreu, anglais, arabe, français ou russe. S’il a besoin d’une précision, le micro se rouvre tout seul : un échange entier se fait sans toucher l’écran. Écrivez la question et la réponse reste silencieuse.', bullets: ['La reconnaissance vocale tourne sur le téléphone.', 'Les réponses sont lues par une voix cloud naturelle ; la voix de l’appareil sert de secours.', 'Aucun astérisque ni symbole n’est jamais lu.'] },
        { h2: 'Concentré sur une recette, un plan ou une liste', p: 'Chaque recette, plan de repas et liste de courses a un bouton « Demander à Shefi ». Cette conversation ne connaît que cet élément et décline poliment le reste : « que puis-je omettre ? » est traité pour le plat sous vos yeux. Shefi fait partie d’EasyPlate Pro.', bullets: ['S’ouvre par « Que voulez-vous savoir sur <nom> ? ».', 'Lit les vrais ingrédients, quantités et étapes.', 'Peut modifier l’élément sur place quand vous le demandez.'] },
      ],
      steps: [
        { t: 'Touchez le bouton Shefi', d: 'Il flotte sur chaque onglet. Dans une recette, un plan ou une liste, utilisez « Demander à Shefi » pour une conversation ciblée.' },
        { t: 'Demandez à la voix ou à l’écrit', d: 'Touchez le micro et parlez, ou écrivez. Shefi répond dans votre langue et agit quand vous le demandez.' },
        { t: 'Laissez-le travailler', d: 'Planifier la journée, remplir la liste, commencer à cuisiner : chaque action montre ce qui a changé, et vous pouvez l’annuler.' },
      ],
      faq: [
        { q: 'Shefi voit-il mes recettes ?', a: 'Oui, c’est le principe. Il lit les recettes, plans et listes de votre compte pour répondre et agir. Rien n’est partagé avec d’autres utilisateurs.' },
        { q: 'Quelles langues parle-t-il ?', a: 'Hébreu, anglais, arabe, français et russe, pour comprendre comme pour la réponse parlée.' },
        { q: 'A-t-il besoin d’Internet ?', a: 'Oui. Shefi tourne sur les serveurs d’EasyPlate ; vos recettes enregistrées s’ouvrent toujours hors ligne.' },
        { q: 'Peut-il modifier mes recettes ?', a: 'Seulement quand vous le demandez, et il confirme ce qu’il a changé. Les modifications peuvent être annulées.' },
        { q: 'Shefi est-il gratuit ?', a: 'Shefi est inclus dans EasyPlate Pro, avec le mode cuisine, les imports IA illimités et zéro publicité, pour 20 ₪ par mois via l’App Store ou Google Play.' },
      ],
      cta: { title: 'Posez une question à votre cuisine.', sub: 'Téléchargez EasyPlate et dites bonjour à Shefi.' },
    },
    ru: {
      title: 'ИИ-помощник на кухне: спросите о любом рецепте голосом | EasyPlate',
      description: 'Шефи отвечает на вопросы о ваших рецептах, планах и списках покупок, заменяет ингредиенты, собирает списки и запускает режим готовки. Пишите или говорите — и слушайте ответ.',
      keywords: 'ии помощник для готовки, голосовой помощник на кухне, чат-бот рецептов, вопросы о рецепте, заменить ингредиент в рецепте, помощь с рецептом без рук, приложение для готовки с искусственным интеллектом',
      h1: 'Шефи: кухонный помощник, который знает ваши рецепты',
      intro: [
        'Обычный чат-бот скажет, чем заменить сливки. Но не скажет, чем заменить их в бабушкиной лазанье, потому что никогда её не видел. Шефи живёт внутри EasyPlate: он читает ваши рецепты, план на неделю и списки покупок — и действует.',
        'Спрашивайте текстом или голосом. Шефи отвечает на вашем языке, ставит рецепт на вторник, добавляет в список недостающее, пересчитывает блюдо на восьмерых или запускает режим готовки на открытом рецепте. Скажите ему — и он прочитает ответ вслух; напишите — и он промолчит. Откройте его из рецепта, плана или списка, и он будет говорить только об этом элементе.',
      ],
      sections: [
        { h2: 'Что умеет Шефи', p: 'Шефи работает с вашей кухней, а не с поисковиком:', bullets: ['Отвечать о любом сохранённом рецепте: замены, время, как пересчитать, с чем подать.', 'Добавить рецепт в день плана или собрать список покупок на неделю.', 'Добавить позиции в список, создать список из одного рецепта, отметить купленное.', 'Запустить режим готовки и поставить таймер на текущий шаг.', 'Запомнить предпочтение, например аллерген, и учитывать его в каждом ответе.'] },
        { h2: 'Говорите — и слушайте ответ', p: 'Нажмите микрофон, спросите, и Шефи ответит вслух естественным голосом на иврите, английском, арабском, французском или русском. Когда ему нужно уточнение, микрофон открывается сам, и весь разговор проходит без касания экрана. Напишите вопрос — и ответ останется беззвучным.', bullets: ['Распознавание речи работает на телефоне.', 'Ответы озвучивает естественный облачный голос; голос устройства — запасной.', 'Звёздочки и символы никогда не читаются вслух.'] },
        { h2: 'Сосредоточен на одном рецепте, плане или списке', p: 'У каждого рецепта, плана питания и списка покупок есть кнопка «Спросить Шефи». Этот разговор знает только этот элемент и вежливо отказывается от остального, так что «что можно убрать?» касается именно блюда перед вами. Шефи входит в EasyPlate Pro.', bullets: ['Начинается с «Что вы хотите узнать о <название>?».', 'Читает настоящие ингредиенты, количества и шаги.', 'Может отредактировать элемент на месте, когда вы попросите.'] },
      ],
      steps: [
        { t: 'Нажмите кнопку Шефи', d: 'Она плавает на каждой вкладке. Внутри рецепта, плана или списка используйте «Спросить Шефи» для сфокусированного чата.' },
        { t: 'Спросите голосом или текстом', d: 'Нажмите микрофон и говорите или напишите. Шефи отвечает на вашем языке и действует по вашей просьбе.' },
        { t: 'Дайте ему поработать', d: 'Спланировать день, заполнить список, начать готовить: каждое действие показывает, что изменилось, и его можно отменить.' },
      ],
      faq: [
        { q: 'Шефи видит мои рецепты?', a: 'Да, в этом и смысл. Он читает рецепты, планы и списки в вашем аккаунте, чтобы отвечать и действовать. Ничего не передаётся другим пользователям.' },
        { q: 'На каких языках он говорит?', a: 'Иврит, английский, арабский, французский и русский — и для понимания, и для озвученного ответа.' },
        { q: 'Нужен ли интернет?', a: 'Да. Шефи работает на серверах EasyPlate; сохранённые рецепты по-прежнему открываются офлайн.' },
        { q: 'Может ли он менять мои рецепты?', a: 'Только по вашей просьбе, и он подтверждает, что изменил. Правки можно отменить.' },
        { q: 'Шефи бесплатный?', a: 'Шефи входит в EasyPlate Pro вместе с режимом готовки, безлимитным ИИ-импортом и отсутствием рекламы — 20 ₪ в месяц через App Store или Google Play.' },
      ],
      cta: { title: 'Задайте вопрос своей кухне.', sub: 'Скачайте EasyPlate и поздоровайтесь с Шефи.' },
    },
  },
};
