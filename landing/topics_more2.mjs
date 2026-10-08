// Guide pages, part two: cook mode, PDF / voice import, the family's weekly
// menu. Merged into TOPICS by topics.mjs.

export const MORE_TOPICS_2 = {
  // ------------------------------------------------------------------ Cook mode
  'cook-mode-timers': {
    icon: 'flame', screens: ['02_recipe_details', '01_recipes'],
    en: {
      title: 'Cook Mode with Timers, Hands-Free Recipes | EasyPlate',
      description: 'One step per screen in large type, the amounts you need right there, and timers that ring in the background. Cook from your phone without touching it.',
      keywords: 'cook mode app, hands-free recipe app, step by step cooking app, cooking timer app, recipe with timers, keep screen on while cooking',
      h1: 'Cook Mode: one step at a time, timers included',
      intro: [
        'A recipe on a phone is the wrong shape for cooking: tiny text, a screen that locks every thirty seconds, and the ingredient list three scrolls above the step you are on. Floury fingers do not help.',
        'Cook Mode rebuilds the recipe for the stove. Each step gets its own screen in large type with the ingredients that step needs and their amounts. When a step says "simmer for 20 minutes", a timer is ready on it; start it and it keeps counting in the background and rings when it is done, even if you leave the app. The screen stays awake for as long as you cook.',
      ],
      sections: [
        { h2: 'What a step looks like', p: 'Everything the step needs, nothing from the rest of the recipe:', bullets: ['The instruction, in text large enough to read from across the counter.', 'The ingredients mentioned in that step with their amounts, already scaled to the servings you chose.', 'A timer, when the step names a duration, with start, pause and reset.', 'Swipe or tap to the next step; a progress bar shows where you are.'] },
        { h2: 'Timers that survive leaving the app', p: 'Start a timer and go answer the door. It counts in the background, a notification rings when it ends, and a strip at the top of every screen shows every timer still running. Coming back into Cook Mode lands you on the step you left.', bullets: ['Several timers at once, for several steps or several recipes.', 'A ring you cannot miss, with the step it belongs to.', 'The inbox shows what is cooking, with a "resume" card.', 'Ending the cooking clears every timer and the banner.'] },
        { h2: 'For any recipe, read-only ones too', p: 'Cook Mode works on your own recipes, on recipes shared with you and on recipes from the community, because it only reads. Scale the servings first and every amount on every step follows. Cook Mode is part of EasyPlate Pro.', bullets: ['Any recipe with steps, from any source.', 'Scaled amounts on every step.', 'Hebrew, English, Arabic, French and Russian.'] },
      ],
      steps: [
        { t: 'Open a recipe and tap "Start cooking"', d: 'Set the servings first if tonight’s table is bigger or smaller than the recipe.' },
        { t: 'Cook step by step', d: 'Read the step, see its ingredients, start the timer if there is one, swipe to the next.' },
        { t: 'Let the timers ring', d: 'Leave the app if you need to; the ring comes anyway, and the resume card brings you back to the step.' },
      ],
      faq: [
        { q: 'Does the screen stay on?', a: 'Yes, while the Cook Mode screen is open. Leave it and the phone behaves normally, with timers still counting in the background.' },
        { q: 'Do timers work when the app is closed?', a: 'Timers keep running in the background and ring with a notification. On Android an ongoing notification shows the countdown; on first use the app asks for notification permission so the ring can be delivered.' },
        { q: 'Can I run two recipes at once?', a: 'Yes. Each recipe has its own timers, the strip at the top shows all of them, and the inbox lets you resume either one.' },
        { q: 'Where do the timers come from?', a: 'From the step text: "bake 25 minutes" becomes a 25-minute timer on that step. You can also start a timer on any step and set its length.' },
        { q: 'Is Cook Mode free?', a: 'Cook Mode is included in EasyPlate Pro, which also removes ads and the daily AI limit, for ₪20 a month through the App Store or Google Play.' },
      ],
      cta: { title: 'Cook with your hands, not your thumbs.', sub: 'Download EasyPlate and start Cook Mode on any recipe.' },
    },
    he: {
      title: 'מצב בישול עם טיימרים: מתכון שלב אחרי שלב בלי ידיים | EasyPlate',
      description: 'שלב אחד בכל מסך באותיות גדולות, הכמויות שצריך בדיוק שם, וטיימרים שמצלצלים גם ברקע. מבשלים מהטלפון בלי לגעת בו. לאייפון ולאנדרואיד.',
      keywords: 'מצב בישול, טיימר לבישול, אפליקציית טיימרים למטבח, מתכון שלב אחרי שלב, בישול בלי ידיים, מסך דולק בזמן בישול, אפליקציה לבישול',
      h1: 'מצב בישול: שלב אחד בכל פעם, טיימרים כלולים',
      intro: [
        'מתכון בטלפון הוא בצורה הלא נכונה לבישול: טקסט זעיר, מסך שננעל כל שלושים שניות, ורשימת המצרכים שלוש גלילות מעל השלב שאתם בו. אצבעות עם קמח לא עוזרות.',
        'מצב בישול בונה את המתכון מחדש בשביל הכיריים. כל שלב מקבל מסך משלו באותיות גדולות עם המצרכים שהשלב הזה צריך והכמויות שלהם. כששלב אומר "מבשלים 20 דקות", טיימר מוכן עליו; מפעילים והוא ממשיך לספור ברקע ומצלצל כשנגמר, גם אם יצאתם מהאפליקציה. המסך נשאר דולק כל זמן שמבשלים.',
      ],
      sections: [
        { h2: 'איך נראה שלב', p: 'כל מה שהשלב צריך, ושום דבר משאר המתכון:', bullets: ['ההוראה, בטקסט גדול מספיק לקרוא מהצד השני של השיש.', 'המצרכים שמוזכרים בשלב עם הכמויות שלהם, כבר מותאמות למספר המנות שבחרתם.', 'טיימר, כשהשלב נוקב בזמן, עם הפעלה, השהיה ואיפוס.', 'מחליקים או לוחצים לשלב הבא; פס התקדמות מראה איפה אתם.'] },
        { h2: 'טיימרים ששורדים יציאה מהאפליקציה', p: 'מפעילים טיימר והולכים לפתוח את הדלת. הוא סופר ברקע, התראה מצלצלת כשנגמר, ופס בראש כל מסך מציג כל טיימר שעדיין רץ. חזרה למצב בישול מחזירה אתכם לשלב שעזבתם.', bullets: ['כמה טיימרים במקביל, לכמה שלבים או לכמה מתכונים.', 'צלצול שאי אפשר לפספס, עם השלב שהוא שייך לו.', 'תיבת ההתראות מראה מה מתבשל, עם כרטיס "להמשיך".', 'סיום הבישול מנקה כל טיימר ואת הפס.'] },
        { h2: 'לכל מתכון, גם כאלה לקריאה בלבד', p: 'מצב בישול עובד על המתכונים שלכם, על מתכונים ששותפו איתכם ועל מתכונים מהקהילה, כי הוא רק קורא. מתאימים קודם את מספר המנות וכל כמות בכל שלב מתעדכנת. מצב בישול הוא חלק מ-EasyPlate Pro.', bullets: ['כל מתכון עם שלבים, מכל מקור.', 'כמויות מותאמות בכל שלב.', 'עברית, אנגלית, ערבית, צרפתית ורוסית.'] },
      ],
      steps: [
        { t: 'פותחים מתכון ולוחצים "התחלת בישול"', d: 'קובעים קודם את מספר המנות אם השולחן של הערב גדול או קטן מהמתכון.' },
        { t: 'מבשלים שלב אחרי שלב', d: 'קוראים את השלב, רואים את המצרכים שלו, מפעילים את הטיימר אם יש, מחליקים לשלב הבא.' },
        { t: 'נותנים לטיימרים לצלצל', d: 'יוצאים מהאפליקציה אם צריך; הצלצול מגיע בכל מקרה, וכרטיס ההמשך מחזיר אתכם לשלב.' },
      ],
      faq: [
        { q: 'המסך נשאר דולק?', a: 'כן, כל זמן שמסך מצב הבישול פתוח. עוזבים אותו והטלפון מתנהג רגיל, כשהטיימרים ממשיכים לספור ברקע.' },
        { q: 'הטיימרים עובדים כשהאפליקציה סגורה?', a: 'הטיימרים ממשיכים לרוץ ברקע ומצלצלים בהתראה. באנדרואיד התראה קבועה מציגה את הספירה לאחור; בשימוש הראשון האפליקציה מבקשת הרשאת התראות כדי שהצלצול יגיע.' },
        { q: 'אפשר להריץ שני מתכונים במקביל?', a: 'כן. לכל מתכון טיימרים משלו, הפס למעלה מציג את כולם, ותיבת ההתראות מאפשרת להמשיך כל אחד מהם.' },
        { q: 'מאיפה הטיימרים מגיעים?', a: 'מטקסט השלב: "אופים 25 דקות" הופך לטיימר של 25 דקות על השלב הזה. אפשר גם להפעיל טיימר על כל שלב ולקבוע את אורכו.' },
        { q: 'מצב בישול חינמי?', a: 'מצב בישול כלול ב-EasyPlate Pro, שגם מסיר פרסומות ואת מגבלת ה-AI היומית, ב-20 ₪ לחודש דרך App Store או Google Play.' },
      ],
      cta: { title: 'מבשלים עם הידיים, לא עם האגודלים.', sub: 'הורידו את EasyPlate והפעילו מצב בישול על כל מתכון.' },
    },
    ar: {
      title: 'وضع الطبخ مع المؤقّتات: وصفة خطوة بخطوة بلا أيدٍ | EasyPlate',
      description: 'خطوة واحدة في كل شاشة بخط كبير، والكميات التي تحتاجها هناك، ومؤقّتات ترنّ حتى في الخلفية. اطبخ من هاتفك دون لمسه. iOS وأندرويد.',
      keywords: 'وضع الطبخ, مؤقّت للطبخ, تطبيق مؤقّتات المطبخ, وصفة خطوة بخطوة, الطبخ بلا أيدٍ, إبقاء الشاشة مضاءة أثناء الطبخ',
      h1: 'وضع الطبخ: خطوة واحدة في كل مرة، مع المؤقّتات',
      intro: [
        'الوصفة على الهاتف بالشكل الخطأ للطبخ: نص صغير، وشاشة تُقفل كل ثلاثين ثانية، وقائمة المكوّنات على بُعد ثلاث تمريرات فوق الخطوة التي أنت فيها. والأصابع المغطاة بالدقيق لا تساعد.',
        'يعيد وضع الطبخ بناء الوصفة من أجل الموقد. تحصل كل خطوة على شاشتها بخط كبير مع المكوّنات التي تحتاجها تلك الخطوة وكمياتها. وعندما تقول خطوة "اتركه على نار هادئة 20 دقيقة"، يكون المؤقّت جاهزًا عليها؛ شغّله فيستمر في العد في الخلفية ويرنّ عند الانتهاء حتى لو غادرت التطبيق. وتبقى الشاشة مضاءة ما دمت تطبخ.',
      ],
      sections: [
        { h2: 'كيف تبدو الخطوة', p: 'كل ما تحتاجه الخطوة، ولا شيء من بقية الوصفة:', bullets: ['التعليمة بنص كبير يُقرأ من الجهة الأخرى من المطبخ.', 'المكوّنات المذكورة في تلك الخطوة بكمياتها، مضبوطة مسبقًا على الحصص التي اخترتها.', 'مؤقّت عندما تذكر الخطوة مدة، مع تشغيل وإيقاف مؤقت وإعادة ضبط.', 'اسحب أو اضغط للخطوة التالية؛ يعرض شريط التقدم أين أنت.'] },
        { h2: 'مؤقّتات تصمد بعد مغادرة التطبيق', p: 'شغّل مؤقّتًا واذهب لفتح الباب. يعدّ في الخلفية، ويرنّ إشعار عند انتهائه، ويعرض شريط في أعلى كل شاشة كل مؤقّت لا يزال يعمل. والعودة إلى وضع الطبخ تعيدك إلى الخطوة التي تركتها.', bullets: ['عدة مؤقّتات معًا، لعدة خطوات أو عدة وصفات.', 'رنين لا يمكن تفويته، مع الخطوة التي يخصّها.', 'يعرض صندوق الإشعارات ما يُطبخ مع بطاقة "متابعة".', 'إنهاء الطبخ يمسح كل مؤقّت والشريط.'] },
        { h2: 'لأي وصفة، حتى وصفات القراءة فقط', p: 'يعمل وضع الطبخ على وصفاتك وعلى الوصفات المشاركة معك وعلى وصفات المجتمع، لأنه يقرأ فقط. اضبط الحصص أولًا فتتبعها كل كمية في كل خطوة. وضع الطبخ جزء من EasyPlate Pro.', bullets: ['أي وصفة بخطوات، من أي مصدر.', 'كميات مضبوطة في كل خطوة.', 'العربية والعبرية والإنجليزية والفرنسية والروسية.'] },
      ],
      steps: [
        { t: 'افتح وصفة واضغط "ابدأ الطبخ"', d: 'اضبط الحصص أولًا إن كانت مائدة الليلة أكبر أو أصغر من الوصفة.' },
        { t: 'اطبخ خطوة بخطوة', d: 'اقرأ الخطوة، شاهد مكوّناتها، شغّل المؤقّت إن وُجد، واسحب إلى التالية.' },
        { t: 'دع المؤقّتات ترنّ', d: 'غادر التطبيق إن احتجت؛ يأتي الرنين على أي حال، وتعيدك بطاقة المتابعة إلى الخطوة.' },
      ],
      faq: [
        { q: 'هل تبقى الشاشة مضاءة؟', a: 'نعم، ما دامت شاشة وضع الطبخ مفتوحة. اتركها فيتصرف الهاتف كالمعتاد، مع استمرار المؤقّتات في العد في الخلفية.' },
        { q: 'هل تعمل المؤقّتات والتطبيق مغلق؟', a: 'تستمر المؤقّتات في الخلفية وترنّ بإشعار. على أندرويد يعرض إشعار دائم العد التنازلي؛ وعند أول استخدام يطلب التطبيق إذن الإشعارات ليصل الرنين.' },
        { q: 'هل يمكنني طبخ وصفتين معًا؟', a: 'نعم. لكل وصفة مؤقّتاتها، ويعرض الشريط العلوي كلها، ويتيح صندوق الإشعارات متابعة أي منهما.' },
        { q: 'من أين تأتي المؤقّتات؟', a: 'من نص الخطوة: "اخبز 25 دقيقة" يصبح مؤقّتًا لـ25 دقيقة على تلك الخطوة. يمكنك أيضًا تشغيل مؤقّت على أي خطوة وتحديد مدته.' },
        { q: 'هل وضع الطبخ مجاني؟', a: 'وضع الطبخ مشمول في EasyPlate Pro، الذي يزيل أيضًا الإعلانات وحد الذكاء الاصطناعي اليومي، مقابل 20 شيكل شهريًا عبر App Store أو Google Play.' },
      ],
      cta: { title: 'اطبخ بيديك لا بإبهاميك.', sub: 'حمّل EasyPlate وشغّل وضع الطبخ على أي وصفة.' },
    },
    fr: {
      title: 'Mode cuisine avec minuteurs, mains libres | EasyPlate',
      description: 'Une étape par écran en grands caractères, les quantités sous les yeux, et des minuteurs qui sonnent en arrière-plan. Cuisinez sans toucher le téléphone.',
      keywords: 'mode cuisine, minuteur de cuisine, application minuteurs cuisine, recette pas à pas, cuisiner mains libres, écran allumé en cuisinant',
      h1: 'Mode cuisine : une étape à la fois, minuteurs compris',
      intro: [
        'Une recette sur un téléphone a la mauvaise forme pour cuisiner : texte minuscule, écran qui se verrouille toutes les trente secondes, et la liste d’ingrédients trois défilements au-dessus de l’étape en cours. Les doigts pleins de farine n’aident pas.',
        'Le mode cuisine reconstruit la recette pour les fourneaux. Chaque étape a son écran en grands caractères avec les ingrédients qu’elle demande et leurs quantités. Quand une étape dit « laisser mijoter 20 minutes », un minuteur est prêt dessus ; lancez-le, il compte en arrière-plan et sonne à la fin, même si vous quittez l’app. L’écran reste allumé tant que vous cuisinez.',
      ],
      sections: [
        { h2: 'À quoi ressemble une étape', p: 'Tout ce dont l’étape a besoin, rien du reste de la recette :', bullets: ['L’instruction, en texte assez grand pour être lu de l’autre bout du plan de travail.', 'Les ingrédients cités dans cette étape avec leurs quantités, déjà ajustées aux portions choisies.', 'Un minuteur, quand l’étape indique une durée, avec démarrer, pause et remise à zéro.', 'Glissez ou touchez pour l’étape suivante ; une barre de progression montre où vous en êtes.'] },
        { h2: 'Des minuteurs qui survivent à la sortie de l’app', p: 'Lancez un minuteur et allez ouvrir la porte. Il compte en arrière-plan, une notification sonne à la fin, et une bande en haut de chaque écran montre chaque minuteur encore en cours. Revenir en mode cuisine vous ramène à l’étape quittée.', bullets: ['Plusieurs minuteurs à la fois, pour plusieurs étapes ou plusieurs recettes.', 'Une sonnerie impossible à manquer, avec l’étape concernée.', 'La boîte de réception montre ce qui cuit, avec une carte « reprendre ».', 'Terminer la cuisson efface tous les minuteurs et la bande.'] },
        { h2: 'Pour toute recette, même en lecture seule', p: 'Le mode cuisine fonctionne sur vos recettes, sur celles partagées avec vous et sur celles de la communauté, car il ne fait que lire. Ajustez d’abord les portions et chaque quantité de chaque étape suit. Le mode cuisine fait partie d’EasyPlate Pro.', bullets: ['Toute recette avec des étapes, de toute source.', 'Quantités ajustées à chaque étape.', 'Français, anglais, hébreu, arabe et russe.'] },
      ],
      steps: [
        { t: 'Ouvrez une recette et touchez « Commencer à cuisiner »', d: 'Réglez d’abord les portions si la table du soir est plus grande ou plus petite que la recette.' },
        { t: 'Cuisinez étape par étape', d: 'Lisez l’étape, voyez ses ingrédients, lancez le minuteur s’il y en a un, glissez vers la suivante.' },
        { t: 'Laissez sonner les minuteurs', d: 'Quittez l’app si besoin ; la sonnerie arrive quand même, et la carte « reprendre » vous ramène à l’étape.' },
      ],
      faq: [
        { q: 'L’écran reste-t-il allumé ?', a: 'Oui, tant que l’écran du mode cuisine est ouvert. Quittez-le et le téléphone se comporte normalement, les minuteurs continuant en arrière-plan.' },
        { q: 'Les minuteurs marchent-ils app fermée ?', a: 'Ils continuent en arrière-plan et sonnent par notification. Sur Android, une notification permanente affiche le compte à rebours ; à la première utilisation l’app demande l’autorisation de notifications pour que la sonnerie arrive.' },
        { q: 'Puis-je cuisiner deux recettes en même temps ?', a: 'Oui. Chaque recette a ses minuteurs, la bande en haut les montre tous, et la boîte de réception permet de reprendre l’une ou l’autre.' },
        { q: 'D’où viennent les minuteurs ?', a: 'Du texte de l’étape : « cuire 25 minutes » devient un minuteur de 25 minutes sur cette étape. Vous pouvez aussi lancer un minuteur sur n’importe quelle étape et fixer sa durée.' },
        { q: 'Le mode cuisine est-il gratuit ?', a: 'Il est inclus dans EasyPlate Pro, qui supprime aussi les publicités et la limite IA quotidienne, pour 20 ₪ par mois via l’App Store ou Google Play.' },
      ],
      cta: { title: 'Cuisinez avec vos mains, pas vos pouces.', sub: 'Téléchargez EasyPlate et lancez le mode cuisine sur n’importe quelle recette.' },
    },
    ru: {
      title: 'Режим готовки с таймерами: рецепт по шагам без рук | EasyPlate',
      description: 'Один шаг на экран крупным шрифтом, нужные количества прямо там, и таймеры, которые звонят даже в фоне. Готовьте по телефону, не трогая его. iOS и Android.',
      keywords: 'режим готовки, таймер для готовки, приложение кухонные таймеры, рецепт по шагам, готовить без рук, экран не гаснет при готовке',
      h1: 'Режим готовки: по одному шагу, таймеры в комплекте',
      intro: [
        'Рецепт на телефоне — неудобная форма для готовки: мелкий текст, экран гаснет каждые тридцать секунд, а список ингредиентов — тремя прокрутками выше нужного шага. Пальцы в муке не помогают.',
        'Режим готовки пересобирает рецепт под плиту. Каждый шаг получает свой экран крупным шрифтом с ингредиентами, которые нужны на этом шаге, и их количествами. Когда в шаге сказано «тушить 20 минут», таймер уже готов; запустите его — он считает в фоне и звонит по окончании, даже если вы вышли из приложения. Экран не гаснет, пока вы готовите.',
      ],
      sections: [
        { h2: 'Как выглядит шаг', p: 'Всё, что нужно шагу, и ничего из остального рецепта:', bullets: ['Инструкция шрифтом, который читается с другого конца столешницы.', 'Ингредиенты этого шага с количествами, уже пересчитанными на выбранные порции.', 'Таймер, если в шаге указано время, со стартом, паузой и сбросом.', 'Свайп или тап — к следующему шагу; полоса прогресса показывает, где вы.'] },
        { h2: 'Таймеры, которые переживают выход из приложения', p: 'Запустите таймер и идите открывать дверь. Он считает в фоне, уведомление звонит по окончании, а полоса вверху каждого экрана показывает все работающие таймеры. Возврат в режим готовки приводит на тот шаг, где вы остановились.', bullets: ['Несколько таймеров одновременно — для нескольких шагов или рецептов.', 'Звонок, который не пропустишь, с указанием шага.', 'Во входящих видно, что готовится, с карточкой «продолжить».', 'Завершение готовки убирает все таймеры и полосу.'] },
        { h2: 'Для любого рецепта, даже только для чтения', p: 'Режим готовки работает с вашими рецептами, с теми, которыми с вами поделились, и с рецептами сообщества, потому что он только читает. Сначала задайте порции — и каждое количество на каждом шаге пересчитается. Режим готовки входит в EasyPlate Pro.', bullets: ['Любой рецепт с шагами из любого источника.', 'Пересчитанные количества на каждом шаге.', 'Русский, английский, иврит, арабский и французский.'] },
      ],
      steps: [
        { t: 'Откройте рецепт и нажмите «Начать готовить»', d: 'Сначала задайте порции, если сегодняшний стол больше или меньше рецепта.' },
        { t: 'Готовьте шаг за шагом', d: 'Прочитайте шаг, посмотрите его ингредиенты, запустите таймер, если он есть, и свайпните дальше.' },
        { t: 'Дайте таймерам прозвонить', d: 'Выходите из приложения, если нужно; звонок придёт всё равно, а карточка «продолжить» вернёт к шагу.' },
      ],
      faq: [
        { q: 'Экран не гаснет?', a: 'Да, пока открыт экран режима готовки. Выйдите из него — телефон ведёт себя как обычно, а таймеры продолжают считать в фоне.' },
        { q: 'Таймеры работают при закрытом приложении?', a: 'Таймеры продолжают идти в фоне и звонят уведомлением. На Android постоянное уведомление показывает обратный отсчёт; при первом использовании приложение просит разрешение на уведомления, чтобы звонок дошёл.' },
        { q: 'Можно готовить два рецепта сразу?', a: 'Да. У каждого рецепта свои таймеры, полоса вверху показывает все, а во входящих можно продолжить любой из них.' },
        { q: 'Откуда берутся таймеры?', a: 'Из текста шага: «выпекать 25 минут» становится таймером на 25 минут на этом шаге. Таймер можно запустить и на любом шаге, задав длительность.' },
        { q: 'Режим готовки бесплатный?', a: 'Режим готовки входит в EasyPlate Pro, который также убирает рекламу и дневной лимит ИИ, за 20 ₪ в месяц через App Store или Google Play.' },
      ],
      cta: { title: 'Готовьте руками, а не большими пальцами.', sub: 'Скачайте EasyPlate и включите режим готовки на любом рецепте.' },
    },
  },

  // ------------------------------------------------------------------ PDF / voice
  'recipe-from-pdf-or-voice': {
    icon: 'file-text', screens: ['03_ai_import', '01_recipes'],
    en: {
      title: 'Turn a PDF or a Voice Note into a Recipe | EasyPlate',
      description: 'Share a PDF cookbook page or a WhatsApp voice note to EasyPlate and the AI writes it as a recipe with ingredients, amounts and steps. Free on iOS and Android.',
      keywords: 'voice note to recipe, pdf to recipe, recipe from audio, dictate a recipe, import recipe from pdf, whatsapp voice message recipe, recipe transcription',
      h1: 'From a PDF or a voice note to a recipe you can cook',
      intro: [
        'Some recipes never had a web page. They are a PDF someone emailed years ago, a scan of a typed collection, or a voice message in which your aunt explains the whole thing in one breath, amounts included, with no way to search it later.',
        'EasyPlate reads both. Share the PDF or the audio file to the app, or pick it from your files, and the AI reads the document or transcribes the recording and returns a structured recipe: ingredients with amounts, numbered steps, servings, tags and estimated nutrition. You check it, fix a word the recording swallowed, and save it into a book.',
      ],
      sections: [
        { h2: 'Voice notes and recordings', p: 'A recording is transcribed first and then read as a recipe, so the usual spoken shape ("you take about a cup of flour, then two eggs…") becomes a list:', bullets: ['WhatsApp voice messages, shared straight from the chat.', 'Recordings from the phone’s voice recorder, in the common audio formats.', 'Hebrew, English, Arabic, French and Russian speech.', 'Amounts said in words ("half a kilo") are written as numbers.'] },
        { h2: 'PDF files', p: 'A PDF is read as a whole, so a scanned page of a cookbook or a collection typed years ago both work. One recipe per file gives the cleanest result; a page with several recipes is read as the first one and can be split by hand.', bullets: ['Text PDFs and scanned PDFs with readable text.', 'Shared from mail, files or the browser.', 'Headings, lists and amounts are kept.'] },
        { h2: 'Then it is an ordinary recipe', p: 'Everything the AI returns is editable, and from then on the recipe behaves like any other: it goes into a book, onto the weekly plan and the grocery list, it can be shared with family, scaled, translated when you switch language, and cooked in Cook Mode.', bullets: ['Editable ingredients, steps, servings and photo.', 'A photo from the gallery, the camera, a Google image search or drawn by the AI.', 'Searchable with the rest of your library.'] },
      ],
      steps: [
        { t: 'Share the file to EasyPlate', d: 'From WhatsApp, Files, Mail or any app: tap share and choose EasyPlate. Or open the app, choose the file channel and pick it.' },
        { t: 'Let the AI read or listen', d: 'A PDF is read in seconds; a recording is transcribed first. The recipe appears with ingredients, amounts and steps.' },
        { t: 'Check and save', d: 'Fix anything the recording left unclear, add a photo, and save it into a book.' },
      ],
      faq: [
        { q: 'Which audio formats work?', a: 'The common ones: WhatsApp voice notes, m4a, mp3, wav, aac and ogg. Share the message or the file to EasyPlate.' },
        { q: 'Can it read a handwritten recipe from a photo?', a: 'Not yet. Dictate it as a voice note, or type it; a typed collection saved as a PDF is read as a file.' },
        { q: 'How long can a recording be?', a: 'A few minutes is ideal. Very long recordings take longer and may be cut at the model’s limit; split a long one into two.' },
        { q: 'What if the recording is unclear?', a: 'The AI does its best and marks nothing invented. Read the result once, correct a word or an amount, and save.' },
        { q: 'Is it free?', a: 'File and voice imports use an AI extraction from the free daily allowance. EasyPlate Pro removes the limit for ₪20 a month.' },
      ],
      cta: { title: 'That voice note is a recipe now.', sub: 'Download EasyPlate and share your first file.' },
    },
    he: {
      title: 'הופכים PDF או הקלטה קולית למתכון | EasyPlate',
      description: 'משתפים עמוד PDF מספר בישול או הודעה קולית מוואטסאפ ל-EasyPlate, וה-AI כותב אותם כמתכון עם מצרכים, כמויות ושלבים. חינם לאייפון ולאנדרואיד.',
      keywords: 'הקלטה קולית למתכון, מתכון מ-PDF, מתכון מהקלטה, להקריא מתכון, ייבוא מתכון מקובץ, הודעה קולית וואטסאפ מתכון, תמלול מתכון',
      h1: 'מ-PDF או מהקלטה קולית למתכון שאפשר לבשל',
      intro: [
        'לחלק מהמתכונים מעולם לא היה דף אינטרנט. הם PDF שמישהו שלח במייל לפני שנים, סריקה של אוסף מוקלד, או הודעה קולית שבה הדודה מסבירה את כל העניין בנשימה אחת, כולל כמויות, בלי שום דרך לחפש בה אחר כך.',
        'EasyPlate קוראת את שניהם. משתפים את ה-PDF או את קובץ השמע לאפליקציה, או בוחרים אותו מהקבצים, וה-AI קורא את המסמך או מתמלל את ההקלטה ומחזיר מתכון מובנה: מצרכים עם כמויות, שלבים ממוספרים, מנות, תגיות וערכים תזונתיים משוערים. בודקים, מתקנים מילה שההקלטה בלעה, ושומרים לספר.',
      ],
      sections: [
        { h2: 'הודעות קוליות והקלטות', p: 'הקלטה מתומללת קודם ואז נקראת כמתכון, כך שהצורה המדוברת הרגילה ("לוקחים בערך כוס קמח, אחר כך שתי ביצים…") הופכת לרשימה:', bullets: ['הודעות קוליות מוואטסאפ, בשיתוף ישר מהצ׳אט.', 'הקלטות מהרשמקול של הטלפון, בפורמטים המקובלים.', 'דיבור בעברית, אנגלית, ערבית, צרפתית ורוסית.', 'כמויות שנאמרות במילים ("חצי קילו") נכתבות כמספרים.'] },
        { h2: 'קובצי PDF', p: 'PDF נקרא בשלמותו, אז גם עמוד סרוק מספר בישול וגם אוסף שהוקלד לפני שנים עובדים. מתכון אחד לקובץ נותן את התוצאה הנקייה ביותר; עמוד עם כמה מתכונים נקרא כראשון שבהם ואפשר לפצל ביד.', bullets: ['PDF של טקסט ו-PDF סרוק עם טקסט קריא.', 'בשיתוף מהמייל, מהקבצים או מהדפדפן.', 'כותרות, רשימות וכמויות נשמרות.'] },
        { h2: 'ואז זה מתכון רגיל', p: 'כל מה שה-AI מחזיר ניתן לעריכה, ומאותו רגע המתכון מתנהג כמו כל מתכון אחר: נכנס לספר, לתפריט השבועי ולרשימת הקניות, אפשר לשתף אותו עם המשפחה, לשנות כמויות, לתרגם כשמחליפים שפה ולבשל במצב בישול.', bullets: ['מצרכים, שלבים, מנות ותמונה ניתנים לעריכה.', 'תמונה מהגלריה, מהמצלמה, מחיפוש תמונות בגוגל או מצוירת ב-AI.', 'ניתן לחיפוש יחד עם שאר הספרייה.'] },
      ],
      steps: [
        { t: 'משתפים את הקובץ ל-EasyPlate', d: 'מוואטסאפ, מהקבצים, מהמייל או מכל אפליקציה: לוחצים שיתוף ובוחרים EasyPlate. או פותחים את האפליקציה, בוחרים את ערוץ הקובץ ובוחרים אותו.' },
        { t: 'נותנים ל-AI לקרוא או להקשיב', d: 'PDF נקרא תוך שניות; הקלטה מתומללת קודם. המתכון מופיע עם מצרכים, כמויות ושלבים.' },
        { t: 'בודקים ושומרים', d: 'מתקנים מה שההקלטה השאירה לא ברור, מוסיפים תמונה ושומרים לספר.' },
      ],
      faq: [
        { q: 'אילו פורמטים של שמע עובדים?', a: 'המקובלים: הודעות קוליות מוואטסאפ, m4a, mp3, wav, aac ו-ogg. משתפים את ההודעה או את הקובץ ל-EasyPlate.' },
        { q: 'אפשר לקרוא מתכון בכתב יד מתמונה?', a: 'עדיין לא. מקריאים אותו כהקלטה קולית או מקלידים; אוסף מוקלד ששמור כ-PDF נקרא כקובץ.' },
        { q: 'כמה ארוכה יכולה להיות הקלטה?', a: 'כמה דקות זה אידיאלי. הקלטות ארוכות מאוד לוקחות יותר זמן ועלולות להיחתך במגבלת המודל; מפצלים הקלטה ארוכה לשתיים.' },
        { q: 'מה אם ההקלטה לא ברורה?', a: 'ה-AI עושה כמיטב יכולתו ולא ממציא. קוראים את התוצאה פעם אחת, מתקנים מילה או כמות, ושומרים.' },
        { q: 'זה חינם?', a: 'ייבוא מקובץ ומהקלטה משתמש בחילוץ AI מהמכסה היומית החינמית. EasyPlate Pro מסירה את המגבלה ב-20 ₪ לחודש.' },
      ],
      cta: { title: 'ההודעה הקולית הזו היא עכשיו מתכון.', sub: 'הורידו את EasyPlate ושתפו את הקובץ הראשון שלכם.' },
    },
    ar: {
      title: 'حوّل ملف PDF أو رسالة صوتية إلى وصفة | EasyPlate',
      description: 'شارك صفحة PDF من كتاب طبخ أو رسالة واتساب صوتية مع EasyPlate، فيكتبها الذكاء الاصطناعي كوصفة بالمكوّنات والكميات والخطوات. مجاني على iOS وأندرويد.',
      keywords: 'رسالة صوتية إلى وصفة, وصفة من PDF, وصفة من تسجيل صوتي, إملاء وصفة, استيراد وصفة من ملف, رسالة واتساب صوتية وصفة, تفريغ وصفة',
      h1: 'من ملف PDF أو رسالة صوتية إلى وصفة يمكنك طبخها',
      intro: [
        'بعض الوصفات لم يكن لها صفحة ويب قط. هي ملف PDF أرسله أحدهم بالبريد قبل سنوات، أو مسح لمجموعة مطبوعة، أو رسالة صوتية تشرح فيها خالتك كل شيء في نفَس واحد، بالكميات، دون أي طريقة للبحث فيها لاحقًا.',
        'يقرأ EasyPlate الاثنين. شارك ملف PDF أو الملف الصوتي مع التطبيق، أو اختره من ملفاتك، فيقرأ الذكاء الاصطناعي المستند أو يفرّغ التسجيل ويعيد وصفة منظمة: مكوّنات بكمياتها وخطوات مرقّمة وحصص ووسوم وقيم غذائية تقديرية. تراجعها، وتصحّح كلمة ابتلعها التسجيل، وتحفظها في كتاب.',
      ],
      sections: [
        { h2: 'الرسائل الصوتية والتسجيلات', p: 'يُفرَّغ التسجيل أولًا ثم يُقرأ كوصفة، فيتحوّل الشكل المنطوق المعتاد ("تأخذ حوالي كوب دقيق، ثم بيضتين…") إلى قائمة:', bullets: ['رسائل واتساب الصوتية، تُشارك مباشرة من المحادثة.', 'تسجيلات من مسجّل الهاتف بالصيغ الشائعة.', 'كلام بالعربية والعبرية والإنجليزية والفرنسية والروسية.', 'الكميات المنطوقة بالكلمات ("نصف كيلو") تُكتب أرقامًا.'] },
        { h2: 'ملفات PDF', p: 'يُقرأ ملف PDF كاملًا، فتعمل صفحة ممسوحة من كتاب طبخ ومجموعة طُبعت قبل سنوات على حد سواء. وصفة واحدة لكل ملف تعطي أنظف نتيجة؛ وصفحة فيها عدة وصفات تُقرأ كالأولى منها ويمكن تقسيمها يدويًا.', bullets: ['ملفات PDF نصية وممسوحة بنص مقروء.', 'تُشارك من البريد أو الملفات أو المتصفح.', 'تُحفظ العناوين والقوائم والكميات.'] },
        { h2: 'ثم تصبح وصفة عادية', p: 'كل ما يعيده الذكاء الاصطناعي قابل للتعديل، ومن ثم تتصرف الوصفة كأي وصفة أخرى: تدخل كتابًا والخطة الأسبوعية وقائمة التسوّق، ويمكن مشاركتها مع العائلة، وتغيير حصصها، وترجمتها عند تبديل اللغة، وطبخها في وضع الطبخ.', bullets: ['مكوّنات وخطوات وحصص وصورة قابلة للتعديل.', 'صورة من المعرض أو الكاميرا أو بحث صور جوجل أو يرسمها الذكاء الاصطناعي.', 'قابلة للبحث مع بقية مكتبتك.'] },
      ],
      steps: [
        { t: 'شارك الملف مع EasyPlate', d: 'من واتساب أو الملفات أو البريد أو أي تطبيق: اضغط مشاركة واختر EasyPlate. أو افتح التطبيق، واختر قناة الملف، واختره.' },
        { t: 'دع الذكاء الاصطناعي يقرأ أو يستمع', d: 'يُقرأ PDF في ثوانٍ؛ ويُفرَّغ التسجيل أولًا. تظهر الوصفة بالمكوّنات والكميات والخطوات.' },
        { t: 'راجع واحفظ', d: 'صحّح ما تركه التسجيل غير واضح، أضف صورة، واحفظها في كتاب.' },
      ],
      faq: [
        { q: 'ما الصيغ الصوتية التي تعمل؟', a: 'الشائعة: رسائل واتساب الصوتية وm4a وmp3 وwav وaac وogg. شارك الرسالة أو الملف مع EasyPlate.' },
        { q: 'هل يقرأ وصفة بخط اليد من صورة؟', a: 'ليس بعد. أملِها كرسالة صوتية أو اكتبها؛ والمجموعة المطبوعة المحفوظة كملف PDF تُقرأ كملف.' },
        { q: 'كم يمكن أن يطول التسجيل؟', a: 'بضع دقائق مثالية. التسجيلات الطويلة جدًا تستغرق وقتًا أطول وقد تُقطع عند حد النموذج؛ قسّم الطويل إلى اثنين.' },
        { q: 'ماذا لو كان التسجيل غير واضح؟', a: 'يبذل الذكاء الاصطناعي جهده ولا يخترع شيئًا. اقرأ النتيجة مرة، وصحّح كلمة أو كمية، واحفظ.' },
        { q: 'هل هو مجاني؟', a: 'يستخدم الاستيراد من الملفات والصوت استخراجًا بالذكاء الاصطناعي من الحصة اليومية المجانية. يزيل EasyPlate Pro الحد مقابل 20 شيكل شهريًا.' },
      ],
      cta: { title: 'تلك الرسالة الصوتية أصبحت وصفة الآن.', sub: 'حمّل EasyPlate وشارك ملفك الأول.' },
    },
    fr: {
      title: 'Transformer un PDF ou une note vocale en recette | EasyPlate',
      description: 'Partagez une page PDF ou une note vocale WhatsApp vers EasyPlate : l’IA l’écrit en recette avec ingrédients, quantités et étapes. Gratuit sur iOS et Android.',
      keywords: 'note vocale en recette, pdf en recette, recette depuis audio, dicter une recette, importer recette pdf, message vocal whatsapp recette, transcription recette',
      h1: 'D’un PDF ou d’une note vocale à une recette à cuisiner',
      intro: [
        'Certaines recettes n’ont jamais eu de page web. Ce sont un PDF envoyé par e-mail il y a des années, le scan d’une collection tapée, ou un message vocal où votre tante explique tout d’une traite, quantités comprises, sans aucun moyen de le retrouver plus tard.',
        'EasyPlate lit les deux. Partagez le PDF ou le fichier audio vers l’app, ou choisissez-le dans vos fichiers : l’IA lit le document ou transcrit l’enregistrement et renvoie une recette structurée, ingrédients avec quantités, étapes numérotées, portions, tags et nutrition estimée. Vous vérifiez, corrigez un mot avalé par l’enregistrement, et enregistrez dans un livre.',
      ],
      sections: [
        { h2: 'Notes vocales et enregistrements', p: 'Un enregistrement est d’abord transcrit puis lu comme une recette, si bien que la forme parlée habituelle (« tu prends à peu près une tasse de farine, puis deux œufs… ») devient une liste :', bullets: ['Messages vocaux WhatsApp, partagés directement depuis la conversation.', 'Enregistrements du dictaphone du téléphone, aux formats courants.', 'Parole en français, anglais, hébreu, arabe et russe.', 'Les quantités dites en mots (« un demi-kilo ») sont écrites en chiffres.'] },
        { h2: 'Fichiers PDF', p: 'Un PDF est lu en entier : une page scannée de livre de cuisine ou une collection tapée il y a des années fonctionnent toutes deux. Une recette par fichier donne le résultat le plus propre ; une page à plusieurs recettes est lue comme la première et peut être découpée à la main.', bullets: ['PDF texte et PDF scannés au texte lisible.', 'Partagés depuis le mail, les fichiers ou le navigateur.', 'Titres, listes et quantités sont conservés.'] },
        { h2: 'Ensuite, c’est une recette ordinaire', p: 'Tout ce que l’IA renvoie est modifiable, et la recette se comporte ensuite comme les autres : elle va dans un livre, sur le menu de la semaine et la liste de courses, se partage en famille, s’ajuste, se traduit au changement de langue et se cuisine en mode cuisine.', bullets: ['Ingrédients, étapes, portions et photo modifiables.', 'Une photo depuis la galerie, l’appareil photo, une recherche d’images Google ou dessinée par l’IA.', 'Consultable avec le reste de votre bibliothèque.'] },
      ],
      steps: [
        { t: 'Partagez le fichier vers EasyPlate', d: 'Depuis WhatsApp, Fichiers, Mail ou toute app : touchez Partager et choisissez EasyPlate. Ou ouvrez l’app, choisissez le canal fichier et sélectionnez-le.' },
        { t: 'Laissez l’IA lire ou écouter', d: 'Un PDF est lu en quelques secondes ; un enregistrement est d’abord transcrit. La recette apparaît avec ingrédients, quantités et étapes.' },
        { t: 'Vérifiez et enregistrez', d: 'Corrigez ce que l’enregistrement a laissé flou, ajoutez une photo et enregistrez dans un livre.' },
      ],
      faq: [
        { q: 'Quels formats audio fonctionnent ?', a: 'Les formats courants : notes vocales WhatsApp, m4a, mp3, wav, aac et ogg. Partagez le message ou le fichier vers EasyPlate.' },
        { q: 'Peut-il lire une recette manuscrite en photo ?', a: 'Pas encore. Dictez-la en note vocale ou tapez-la ; une collection tapée enregistrée en PDF est lue comme un fichier.' },
        { q: 'Quelle durée pour un enregistrement ?', a: 'Quelques minutes, idéalement. Les très longs enregistrements prennent plus de temps et peuvent être coupés à la limite du modèle ; découpez-les en deux.' },
        { q: 'Et si l’enregistrement n’est pas clair ?', a: 'L’IA fait de son mieux et n’invente rien. Relisez le résultat une fois, corrigez un mot ou une quantité, et enregistrez.' },
        { q: 'Est-ce gratuit ?', a: 'Les imports de fichiers et vocaux utilisent une extraction IA du quota quotidien gratuit. EasyPlate Pro supprime la limite pour 20 ₪ par mois.' },
      ],
      cta: { title: 'Cette note vocale est une recette maintenant.', sub: 'Téléchargez EasyPlate et partagez votre premier fichier.' },
    },
    ru: {
      title: 'Превратить PDF или голосовое в рецепт | EasyPlate',
      description: 'Поделитесь страницей PDF или голосовым из WhatsApp с EasyPlate — ИИ запишет это как рецепт с ингредиентами, количествами и шагами. Бесплатно.',
      keywords: 'голосовое в рецепт, pdf в рецепт, рецепт из аудио, надиктовать рецепт, импорт рецепта из pdf, голосовое whatsapp рецепт, расшифровка рецепта',
      h1: 'Из PDF или голосового — в рецепт, по которому можно готовить',
      intro: [
        'У некоторых рецептов никогда не было веб-страницы. Это PDF, который кто-то прислал по почте много лет назад, скан набранной коллекции или голосовое, в котором тётя объясняет всё на одном дыхании, с количествами, и потом это никак не найти.',
        'EasyPlate читает и то и другое. Поделитесь PDF или аудиофайлом с приложением или выберите его из файлов: ИИ прочитает документ или расшифрует запись и вернёт структурированный рецепт — ингредиенты с количествами, пронумерованные шаги, порции, теги и примерное КБЖУ. Вы проверяете, исправляете слово, которое проглотила запись, и сохраняете в книгу.',
      ],
      sections: [
        { h2: 'Голосовые и записи', p: 'Запись сначала расшифровывается, а потом читается как рецепт, так что обычная устная форма («берёшь примерно стакан муки, потом два яйца…») становится списком:', bullets: ['Голосовые WhatsApp — прямо из чата.', 'Записи с диктофона телефона в распространённых форматах.', 'Речь на русском, английском, иврите, арабском и французском.', 'Количества словами («полкило») записываются цифрами.'] },
        { h2: 'Файлы PDF', p: 'PDF читается целиком, поэтому подходят и отсканированная страница кулинарной книги, и набранная много лет назад коллекция. Один рецепт на файл даёт самый чистый результат; страница с несколькими рецептами читается как первый, остальные можно разделить вручную.', bullets: ['Текстовые PDF и сканы с читаемым текстом.', 'Из почты, файлов или браузера.', 'Заголовки, списки и количества сохраняются.'] },
        { h2: 'А дальше это обычный рецепт', p: 'Всё, что возвращает ИИ, редактируется, и дальше рецепт ведёт себя как любой другой: попадает в книгу, в меню на неделю и в список покупок, им можно делиться с семьёй, масштабировать, переводить при смене языка и готовить в режиме готовки.', bullets: ['Редактируемые ингредиенты, шаги, порции и фото.', 'Фото из галереи, с камеры, из поиска Google Картинок или нарисованное ИИ.', 'Ищется вместе с остальной библиотекой.'] },
      ],
      steps: [
        { t: 'Поделитесь файлом с EasyPlate', d: 'Из WhatsApp, Файлов, Почты или любого приложения: нажмите «Поделиться» и выберите EasyPlate. Или откройте приложение, выберите канал «Файл» и укажите его.' },
        { t: 'Дайте ИИ прочитать или послушать', d: 'PDF читается за секунды; запись сначала расшифровывается. Рецепт появляется с ингредиентами, количествами и шагами.' },
        { t: 'Проверьте и сохраните', d: 'Поправьте то, что запись оставила неясным, добавьте фото и сохраните в книгу.' },
      ],
      faq: [
        { q: 'Какие аудиоформаты работают?', a: 'Распространённые: голосовые WhatsApp, m4a, mp3, wav, aac и ogg. Поделитесь сообщением или файлом с EasyPlate.' },
        { q: 'Читает ли он рукописный рецепт с фото?', a: 'Пока нет. Надиктуйте его голосовым или наберите; набранная коллекция, сохранённая в PDF, читается как файл.' },
        { q: 'Какой длины может быть запись?', a: 'Несколько минут — идеально. Очень длинные записи обрабатываются дольше и могут обрезаться на лимите модели; разделите длинную на две.' },
        { q: 'А если запись неразборчива?', a: 'ИИ делает что может и ничего не выдумывает. Прочитайте результат один раз, поправьте слово или количество и сохраните.' },
        { q: 'Это бесплатно?', a: 'Импорт файлов и голосовых использует извлечение ИИ из бесплатной дневной квоты. EasyPlate Pro снимает лимит за 20 ₪ в месяц.' },
      ],
      cta: { title: 'Это голосовое — теперь рецепт.', sub: 'Скачайте EasyPlate и поделитесь первым файлом.' },
    },
  },

  // ------------------------------------------------------------------ Weekly family menu
  'weekly-family-meal-plan': {
    icon: 'calendar-days', screens: ['06_meal_plan', '08_grocery'],
    en: {
      title: 'Weekly Meal Plan for the Family, Shared | EasyPlate',
      description: 'Plan the family’s week in one shared menu, from your own recipes, and get the grocery list and the nutrition for free. Free on iOS and Android.',
      keywords: 'weekly meal plan for family, family meal planner, plan meals for the week, weekly menu for family, shared meal plan, meal prep planner, dinner plan for the week',
      h1: 'A weekly meal plan the whole family can see',
      intro: [
        'The question "what’s for dinner" costs a family a decision every evening and a supermarket run every other day. A weekly plan answers it once: seven days, the meals on each, the shopping done in one trip. The catch is that a plan on one person’s phone is a plan nobody else can see or change.',
        'EasyPlate’s meal plans are shared. One person builds the week from the family’s recipes, shares it with the others as viewers or editors, and everyone sees the same board on their own phone. The grocery list is built from the plan, the nutrition adds up per day, and next week starts from a template so the board is never empty.',
      ],
      sections: [
        { h2: 'Building the week', p: 'A plan is a board of days and meals. Start from a template, then fill it in:', bullets: ['Templates: empty, three meals a day, or six (meals and snacks).', 'Drop a recipe from your library on any meal, or type a quick item ("leftovers", "pizza night").', 'Several plans side by side: a regular week, a holiday week, the kids’ week.', 'Change servings on a recipe and the list follows.'] },
        { h2: 'One board for the household', p: 'Share the plan with a contact, a code or a QR. Editors can move meals and add recipes; viewers can see what is coming and tick the shopping. Changes reach everyone in real time, so the person at the supermarket sees the dinner that was just added.', bullets: ['Viewer or editor, per person.', 'Recipes in the plan travel with it, so everyone can open them.', 'Pro Duo and Pro Family keep the whole household on one shared account.'] },
        { h2: 'What falls out of the plan', p: 'A plan is not only a calendar. From it EasyPlate builds the grocery list, grouped by aisle with duplicates merged across the week, and the nutrition dashboard, per day and per week, from the recipes’ estimated values. Both update when the plan does.', bullets: ['Grocery list from one plan or several.', 'Estimated cost of the list from your receipts.', 'Calories, protein, carbs and fat per day.', 'Reminders on your shopping day, if you want them.'] },
      ],
      steps: [
        { t: 'Create a plan from a template', d: 'Name it and pick three meals a day, six, or empty.' },
        { t: 'Fill the days', d: 'Drop recipes from your library or type quick items. Mix both freely.' },
        { t: 'Share and shop', d: 'Share the plan with the family, build the grocery list from it and go once.' },
      ],
      faq: [
        { q: 'Can two people edit the same plan?', a: 'Yes. Share it with edit access and both can move meals and add recipes; the board updates for everyone in real time.' },
        { q: 'Do I need recipes for every meal?', a: 'No. A meal can be a quick item like "sandwiches" with no recipe behind it. Only recipes feed the grocery list and the nutrition.' },
        { q: 'Can I plan more than one week?', a: 'Make as many plans as you like and switch between them; each one is a week board. The grocery list can be built from one plan or from several at once.' },
        { q: 'Does it work with my own recipes?', a: 'Any recipe in your library, including ones extracted from videos or links and ones shared with you by family.' },
        { q: 'Is it free?', a: 'Plans, sharing and the grocery list are free. A free account can share a limited number of plans at once; Pro removes the limit and adds a shared household.' },
      ],
      cta: { title: 'Decide the week once.', sub: 'Download EasyPlate and share the first plan with your family.' },
    },
    he: {
      title: 'תפריט שבועי למשפחה: משותף ומוכן לקניות | EasyPlate',
      description: 'מתכננים את השבוע של המשפחה בתפריט משותף אחד, מהמתכונים שלכם, ומקבלים את רשימת הקניות ואת הערכים התזונתיים בחינם. לאייפון ולאנדרואיד.',
      keywords: 'תפריט שבועי למשפחה, תכנון ארוחות לשבוע, תפריט שבועי משפחתי, תכנון ארוחות שבועי, תפריט משותף, תפריט ארוחות ערב לשבוע, אפליקציה לתכנון ארוחות',
      h1: 'תפריט שבועי שכל המשפחה רואה',
      intro: [
        'השאלה "מה אוכלים בערב" עולה למשפחה החלטה כל ערב וריצה לסופר יום כן יום לא. תפריט שבועי עונה עליה פעם אחת: שבעה ימים, הארוחות בכל אחד, והקניות בנסיעה אחת. הבעיה היא שתפריט בטלפון של אדם אחד הוא תפריט שאף אחד אחר לא רואה ולא יכול לשנות.',
        'התפריטים ב-EasyPlate משותפים. אחד בונה את השבוע מהמתכונים של המשפחה, משתף אותו עם האחרים כצופים או כעורכים, וכולם רואים את אותו לוח בטלפון שלהם. רשימת הקניות נבנית מהתפריט, הערכים התזונתיים מסתכמים לכל יום, והשבוע הבא מתחיל מתבנית כך שהלוח לעולם לא ריק.',
      ],
      sections: [
        { h2: 'בונים את השבוע', p: 'תפריט הוא לוח של ימים וארוחות. מתחילים מתבנית ואז ממלאים:', bullets: ['תבניות: ריק, שלוש ארוחות ביום, או שש (ארוחות וביניים).', 'גוררים מתכון מהספרייה לכל ארוחה, או מקלידים פריט מהיר ("שאריות", "ערב פיצה").', 'כמה תפריטים זה לצד זה: שבוע רגיל, שבוע חג, השבוע של הילדים.', 'משנים מנות במתכון והרשימה מתעדכנת.'] },
        { h2: 'לוח אחד למשק הבית', p: 'משתפים את התפריט עם איש קשר, בקוד או ב-QR. עורכים מזיזים ארוחות ומוסיפים מתכונים; צופים רואים מה מגיע ומסמנים בקניות. שינויים מגיעים לכולם בזמן אמת, אז מי שבסופר רואה את ארוחת הערב שרק עכשיו נוספה.', bullets: ['צופה או עורך, לכל אדם בנפרד.', 'המתכונים שבתפריט נוסעים איתו, כך שכולם יכולים לפתוח אותם.', 'Pro Duo ו-Pro Family מחזיקים את כל משק הבית בחשבון משותף אחד.'] },
        { h2: 'מה יוצא מהתפריט', p: 'תפריט הוא לא רק לוח שנה. ממנו EasyPlate בונה את רשימת הקניות, מסודרת לפי מחלקות עם כפילויות מאוחדות לאורך השבוע, ואת לוח התזונה, לפי יום ולפי שבוע, מהערכים המשוערים של המתכונים. שניהם מתעדכנים כשהתפריט משתנה.', bullets: ['רשימת קניות מתפריט אחד או מכמה.', 'עלות משוערת של הרשימה מהקבלות שלכם.', 'קלוריות, חלבון, פחמימות ושומן ליום.', 'תזכורות ביום הקניות, אם רוצים.'] },
      ],
      steps: [
        { t: 'יוצרים תפריט מתבנית', d: 'נותנים שם ובוחרים שלוש ארוחות ביום, שש, או ריק.' },
        { t: 'ממלאים את הימים', d: 'גוררים מתכונים מהספרייה או מקלידים פריטים מהירים. מערבבים חופשי.' },
        { t: 'משתפים וקונים', d: 'משתפים את התפריט עם המשפחה, בונים ממנו את רשימת הקניות ונוסעים פעם אחת.' },
      ],
      faq: [
        { q: 'שני אנשים יכולים לערוך את אותו תפריט?', a: 'כן. משתפים עם הרשאת עריכה ושניהם מזיזים ארוחות ומוסיפים מתכונים; הלוח מתעדכן לכולם בזמן אמת.' },
        { q: 'צריך מתכון לכל ארוחה?', a: 'לא. ארוחה יכולה להיות פריט מהיר כמו "סנדוויצ׳ים" בלי מתכון מאחוריה. רק מתכונים מזינים את רשימת הקניות ואת הערכים התזונתיים.' },
        { q: 'אפשר לתכנן יותר משבוע אחד?', a: 'יוצרים כמה תפריטים שרוצים ועוברים ביניהם; כל אחד הוא לוח של שבוע. את רשימת הקניות אפשר לבנות מתפריט אחד או מכמה יחד.' },
        { q: 'זה עובד עם המתכונים שלי?', a: 'עם כל מתכון בספרייה, כולל כאלה שחולצו מסרטונים או מקישורים וכאלה שהמשפחה שיתפה איתכם.' },
        { q: 'זה חינם?', a: 'תפריטים, שיתוף ורשימת הקניות חינמיים. חשבון חינמי יכול לשתף מספר מוגבל של תפריטים בו-זמנית; Pro מסיר את המגבלה ומוסיף משק בית משותף.' },
      ],
      cta: { title: 'מחליטים על השבוע פעם אחת.', sub: 'הורידו את EasyPlate ושתפו את התפריט הראשון עם המשפחה.' },
    },
    ar: {
      title: 'خطة وجبات أسبوعية للعائلة: مشتركة وجاهزة للتسوّق | EasyPlate',
      description: 'خطّط أسبوع العائلة في قائمة مشتركة واحدة من وصفاتك، واحصل على قائمة التسوّق والقيم الغذائية مجانًا. لنظامي iOS وأندرويد.',
      keywords: 'خطة وجبات أسبوعية للعائلة, تخطيط وجبات الأسبوع, قائمة طعام أسبوعية للعائلة, خطة وجبات مشتركة, تطبيق تخطيط الوجبات, عشاء الأسبوع',
      h1: 'خطة وجبات أسبوعية تراها العائلة كلها',
      intro: [
        'سؤال "ماذا نأكل على العشاء" يكلّف العائلة قرارًا كل مساء وزيارة للسوبرماركت كل يومين. تجيب الخطة الأسبوعية عنه مرة واحدة: سبعة أيام، والوجبات في كل يوم، والتسوّق في رحلة واحدة. المشكلة أن خطة على هاتف شخص واحد خطة لا يراها أحد غيره ولا يستطيع تغييرها.',
        'خطط الوجبات في EasyPlate مشتركة. يبني شخص الأسبوع من وصفات العائلة، ويشاركه مع الآخرين كمشاهدين أو محرّرين، فيرى الجميع اللوحة نفسها على هواتفهم. تُبنى قائمة التسوّق من الخطة، وتُجمع القيم الغذائية لكل يوم، ويبدأ الأسبوع التالي من قالب فلا تكون اللوحة فارغة أبدًا.',
      ],
      sections: [
        { h2: 'بناء الأسبوع', p: 'الخطة لوحة من الأيام والوجبات. ابدأ من قالب ثم املأها:', bullets: ['قوالب: فارغ، أو ثلاث وجبات يوميًا، أو ست (وجبات ووجبات خفيفة).', 'اسحب وصفة من مكتبتك إلى أي وجبة، أو اكتب عنصرًا سريعًا ("بقايا"، "ليلة بيتزا").', 'عدة خطط جنبًا إلى جنب: أسبوع عادي، أسبوع عيد، أسبوع الأطفال.', 'غيّر حصص وصفة فتتبعها القائمة.'] },
        { h2: 'لوحة واحدة للأسرة', p: 'شارك الخطة مع جهة اتصال أو برمز أو QR. يحرّك المحرّرون الوجبات ويضيفون الوصفات؛ ويرى المشاهدون ما هو قادم ويؤشرون على المشتريات. تصل التغييرات للجميع فورًا، فيرى من في السوبرماركت العشاء الذي أُضيف للتو.', bullets: ['مشاهد أو محرّر، لكل شخص.', 'تنتقل وصفات الخطة معها، فيستطيع الجميع فتحها.', 'يحتفظ Pro Duo وPro Family بالأسرة كلها في حساب مشترك واحد.'] },
        { h2: 'ما ينتج عن الخطة', p: 'الخطة ليست تقويمًا فقط. منها يبني EasyPlate قائمة التسوّق مرتّبة حسب الأقسام مع دمج المكررات عبر الأسبوع، ولوحة التغذية لكل يوم وأسبوع من القيم التقديرية للوصفات. ويتحدّث الاثنان مع تغيّر الخطة.', bullets: ['قائمة تسوّق من خطة واحدة أو عدة خطط.', 'تكلفة تقديرية للقائمة من فواتيرك.', 'سعرات وبروتين وكربوهيدرات ودهون لكل يوم.', 'تذكيرات في يوم التسوّق إن أردت.'] },
      ],
      steps: [
        { t: 'أنشئ خطة من قالب', d: 'سمّها واختر ثلاث وجبات يوميًا أو ستًا أو فارغًا.' },
        { t: 'املأ الأيام', d: 'اسحب وصفات من مكتبتك أو اكتب عناصر سريعة. امزج بحرية.' },
        { t: 'شارك وتسوّق', d: 'شارك الخطة مع العائلة، وابنِ قائمة التسوّق منها، واذهب مرة واحدة.' },
      ],
      faq: [
        { q: 'هل يستطيع شخصان تعديل الخطة نفسها؟', a: 'نعم. شاركها بصلاحية التعديل فيستطيع كلاهما تحريك الوجبات وإضافة الوصفات؛ وتتحدّث اللوحة للجميع فورًا.' },
        { q: 'هل أحتاج وصفة لكل وجبة؟', a: 'لا. يمكن أن تكون الوجبة عنصرًا سريعًا مثل "ساندويتشات" بلا وصفة. الوصفات وحدها تغذّي قائمة التسوّق والقيم الغذائية.' },
        { q: 'هل يمكنني تخطيط أكثر من أسبوع؟', a: 'أنشئ ما شئت من الخطط وتنقّل بينها؛ كل واحدة لوحة أسبوع. ويمكن بناء قائمة التسوّق من خطة واحدة أو عدة خطط معًا.' },
        { q: 'هل يعمل مع وصفاتي؟', a: 'مع أي وصفة في مكتبتك، بما فيها المستخرجة من الفيديوهات أو الروابط والمشاركة معك من العائلة.' },
        { q: 'هل هو مجاني؟', a: 'الخطط والمشاركة وقائمة التسوّق مجانية. يستطيع الحساب المجاني مشاركة عدد محدود من الخطط في الوقت نفسه؛ ويزيل Pro الحد ويضيف أسرة مشتركة.' },
      ],
      cta: { title: 'قرّر الأسبوع مرة واحدة.', sub: 'حمّل EasyPlate وشارك الخطة الأولى مع عائلتك.' },
    },
    fr: {
      title: 'Menu de la semaine pour la famille | EasyPlate',
      description: 'Planifiez la semaine de la famille dans un seul menu partagé, à partir de vos recettes, avec la liste de courses et la nutrition. iOS et Android.',
      keywords: 'menu de la semaine famille, planning repas famille, planifier les repas de la semaine, menu hebdomadaire familial, planning repas partagé, application planning repas',
      h1: 'Un menu de la semaine que toute la famille voit',
      intro: [
        'La question « qu’est-ce qu’on mange ce soir » coûte à une famille une décision chaque soir et un passage au supermarché un jour sur deux. Un menu de la semaine y répond une fois : sept jours, les repas de chacun, les courses en un seul trajet. Le hic, c’est qu’un menu sur le téléphone d’une seule personne est un menu que personne d’autre ne voit ni ne modifie.',
        'Les menus d’EasyPlate sont partagés. Une personne construit la semaine avec les recettes de la famille, la partage avec les autres en lecture ou en modification, et tout le monde voit le même tableau sur son téléphone. La liste de courses se construit depuis le menu, la nutrition s’additionne par jour, et la semaine suivante part d’un modèle pour que le tableau ne soit jamais vide.',
      ],
      sections: [
        { h2: 'Construire la semaine', p: 'Un menu est un tableau de jours et de repas. Partez d’un modèle, puis remplissez :', bullets: ['Modèles : vide, trois repas par jour, ou six (repas et collations).', 'Déposez une recette de votre bibliothèque sur un repas, ou tapez un élément rapide (« restes », « soirée pizza »).', 'Plusieurs menus côte à côte : une semaine normale, une semaine de fête, la semaine des enfants.', 'Changez les portions d’une recette et la liste suit.'] },
        { h2: 'Un seul tableau pour le foyer', p: 'Partagez le menu avec un contact, un code ou un QR. Les éditeurs déplacent les repas et ajoutent des recettes ; les lecteurs voient ce qui vient et cochent les courses. Les changements arrivent chez tous en temps réel : la personne au supermarché voit le dîner qui vient d’être ajouté.', bullets: ['Lecteur ou éditeur, par personne.', 'Les recettes du menu voyagent avec lui, chacun peut les ouvrir.', 'Pro Duo et Pro Family gardent tout le foyer sur un compte partagé.'] },
        { h2: 'Ce qui découle du menu', p: 'Un menu n’est pas qu’un calendrier. EasyPlate en construit la liste de courses, par rayon avec les doublons fusionnés sur la semaine, et le tableau nutrition, par jour et par semaine, à partir des valeurs estimées des recettes. Les deux se mettent à jour quand le menu change.', bullets: ['Liste de courses depuis un menu ou plusieurs.', 'Coût estimé de la liste d’après vos tickets.', 'Calories, protéines, glucides et lipides par jour.', 'Rappels le jour des courses, si vous le souhaitez.'] },
      ],
      steps: [
        { t: 'Créez un menu depuis un modèle', d: 'Nommez-le et choisissez trois repas par jour, six, ou vide.' },
        { t: 'Remplissez les jours', d: 'Déposez des recettes de votre bibliothèque ou tapez des éléments rapides. Mélangez librement.' },
        { t: 'Partagez et faites les courses', d: 'Partagez le menu avec la famille, construisez la liste de courses à partir de lui et n’y allez qu’une fois.' },
      ],
      faq: [
        { q: 'Deux personnes peuvent-elles modifier le même menu ?', a: 'Oui. Partagez-le avec accès en modification et les deux déplacent les repas et ajoutent des recettes ; le tableau se met à jour pour tous en temps réel.' },
        { q: 'Faut-il une recette pour chaque repas ?', a: 'Non. Un repas peut être un élément rapide comme « sandwichs » sans recette derrière. Seules les recettes alimentent la liste de courses et la nutrition.' },
        { q: 'Puis-je planifier plus d’une semaine ?', a: 'Créez autant de menus que vous voulez et passez de l’un à l’autre ; chacun est un tableau d’une semaine. La liste de courses peut être construite depuis un menu ou plusieurs à la fois.' },
        { q: 'Ça marche avec mes propres recettes ?', a: 'Avec toute recette de votre bibliothèque, y compris celles extraites de vidéos ou de liens et celles partagées par la famille.' },
        { q: 'Est-ce gratuit ?', a: 'Menus, partage et liste de courses sont gratuits. Un compte gratuit peut partager un nombre limité de menus à la fois ; Pro supprime la limite et ajoute un foyer partagé.' },
      ],
      cta: { title: 'Décidez de la semaine une seule fois.', sub: 'Téléchargez EasyPlate et partagez le premier menu avec votre famille.' },
    },
    ru: {
      title: 'Меню на неделю для семьи, общее | EasyPlate',
      description: 'Планируйте неделю семьи в одном общем меню из своих рецептов и получайте список покупок и КБЖУ бесплатно. Для iOS и Android.',
      keywords: 'меню на неделю для семьи, планирование питания на неделю, семейное меню на неделю, общее меню, приложение планирование питания, ужины на неделю',
      h1: 'Меню на неделю, которое видит вся семья',
      intro: [
        'Вопрос «что на ужин» стоит семье решения каждый вечер и похода в супермаркет через день. Недельное меню отвечает на него один раз: семь дней, блюда в каждом, покупки за одну поездку. Загвоздка в том, что меню в телефоне одного человека — это меню, которое никто другой не видит и не может изменить.',
        'Меню в EasyPlate общие. Один человек собирает неделю из семейных рецептов, делится с остальными как с читателями или редакторами, и все видят одну и ту же доску на своих телефонах. Список покупок строится из меню, КБЖУ складывается по дням, а следующая неделя начинается с шаблона, так что доска никогда не пуста.',
      ],
      sections: [
        { h2: 'Собираем неделю', p: 'Меню — это доска из дней и приёмов пищи. Начните с шаблона и заполняйте:', bullets: ['Шаблоны: пустой, три приёма пищи в день или шесть (с перекусами).', 'Перетащите рецепт из библиотеки на любой приём пищи или впишите быстрый пункт («остатки», «вечер пиццы»).', 'Несколько меню рядом: обычная неделя, праздничная, детская.', 'Измените порции в рецепте — список пересчитается.'] },
        { h2: 'Одна доска на всю семью', p: 'Поделитесь меню с контактом, кодом или QR. Редакторы двигают блюда и добавляют рецепты; читатели видят, что впереди, и отмечают покупки. Изменения доходят до всех сразу, так что тот, кто в супермаркете, видит только что добавленный ужин.', bullets: ['Читатель или редактор — для каждого отдельно.', 'Рецепты меню путешествуют вместе с ним, их может открыть каждый.', 'Pro Duo и Pro Family держат всю семью в одном общем аккаунте.'] },
        { h2: 'Что получается из меню', p: 'Меню — не только календарь. Из него EasyPlate строит список покупок по отделам с объединением повторов за неделю и панель питания по дням и за неделю из оценочных значений рецептов. Оба обновляются вместе с меню.', bullets: ['Список покупок из одного меню или нескольких.', 'Примерная стоимость списка по вашим чекам.', 'Калории, белки, углеводы и жиры по дням.', 'Напоминания в день покупок, если хотите.'] },
      ],
      steps: [
        { t: 'Создайте меню из шаблона', d: 'Назовите его и выберите три приёма пищи в день, шесть или пустой.' },
        { t: 'Заполните дни', d: 'Перетащите рецепты из библиотеки или впишите быстрые пункты. Смешивайте свободно.' },
        { t: 'Поделитесь и купите', d: 'Поделитесь меню с семьёй, соберите из него список покупок и съездите один раз.' },
      ],
      faq: [
        { q: 'Могут ли два человека редактировать одно меню?', a: 'Да. Поделитесь с правом редактирования — оба смогут двигать блюда и добавлять рецепты; доска обновляется у всех сразу.' },
        { q: 'Нужен ли рецепт на каждый приём пищи?', a: 'Нет. Приём пищи может быть быстрым пунктом вроде «бутерброды» без рецепта. Только рецепты попадают в список покупок и КБЖУ.' },
        { q: 'Можно планировать больше одной недели?', a: 'Создавайте сколько угодно меню и переключайтесь между ними; каждое — доска на неделю. Список покупок можно собрать из одного меню или из нескольких сразу.' },
        { q: 'Работает с моими рецептами?', a: 'С любым рецептом из библиотеки, включая извлечённые из видео или ссылок и те, которыми поделилась семья.' },
        { q: 'Это бесплатно?', a: 'Меню, обмен и список покупок бесплатны. Бесплатный аккаунт может делиться ограниченным числом меню одновременно; Pro снимает лимит и добавляет общую семью.' },
      ],
      cta: { title: 'Решите про неделю один раз.', sub: 'Скачайте EasyPlate и поделитесь первым меню с семьёй.' },
    },
  },
};
