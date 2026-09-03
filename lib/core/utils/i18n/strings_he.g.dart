///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsHe = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.he,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <he>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// he: 'איזי-פלייט'
	String get appName => 'איזי-פלייט';

	late final Translations$common$he common = Translations$common$he.internal(_root);
	late final Translations$onboarding$he onboarding = Translations$onboarding$he.internal(_root);
	late final Translations$dietary$he dietary = Translations$dietary$he.internal(_root);
	late final Translations$weekday$he weekday = Translations$weekday$he.internal(_root);
	late final Translations$settings$he settings = Translations$settings$he.internal(_root);
	late final Translations$language$he language = Translations$language$he.internal(_root);
	late final Translations$books$he books = Translations$books$he.internal(_root);
	late final Translations$recipe$he recipe = Translations$recipe$he.internal(_root);
	late final Translations$ingestion$he ingestion = Translations$ingestion$he.internal(_root);
	late final Translations$mealPlanner$he mealPlanner = Translations$mealPlanner$he.internal(_root);
	late final Translations$groceryList$he groceryList = Translations$groceryList$he.internal(_root);
	late final Translations$unit$he unit = Translations$unit$he.internal(_root);
	late final Translations$image$he image = Translations$image$he.internal(_root);
	late final Translations$nav$he nav = Translations$nav$he.internal(_root);
}

// Path: common
class Translations$common$he {
	Translations$common$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'שמירה'
	String get save => 'שמירה';

	/// he: 'ביטול'
	String get cancel => 'ביטול';

	/// he: 'הבא'
	String get next => 'הבא';

	/// he: 'חזרה'
	String get back => 'חזרה';

	/// he: 'סיום'
	String get done => 'סיום';

	/// he: 'הוספה'
	String get add => 'הוספה';

	/// he: 'עריכה'
	String get edit => 'עריכה';

	/// he: 'מחיקה'
	String get delete => 'מחיקה';

	/// he: 'חיפוש'
	String get search => 'חיפוש';

	/// he: 'נסה שוב'
	String get retry => 'נסה שוב';

	/// he: 'טוען...'
	String get loading => 'טוען...';

	/// he: 'אירעה שגיאה'
	String get error => 'אירעה שגיאה';

	/// he: '[חסר מידע]'
	String get missingInfo => '[חסר מידע]';
}

// Path: onboarding
class Translations$onboarding$he {
	Translations$onboarding$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ברוכים הבאים ל-EasyPlate'
	String get welcomeTitle => 'ברוכים הבאים ל-EasyPlate';

	/// he: 'תכננו ארוחות, בשלו וקנו — הכל במקום אחד'
	String get welcomeSubtitle => 'תכננו ארוחות, בשלו וקנו — הכל במקום אחד';

	/// he: 'מתי יום הקניות השבועי שלכם?'
	String get shoppingDayTitle => 'מתי יום הקניות השבועי שלכם?';

	/// he: 'מהן ההעדפות התזונתיות שלכם?'
	String get dietaryTitle => 'מהן ההעדפות התזונתיות שלכם?';

	/// he: 'אפשר לבחור יותר מאחת'
	String get dietarySubtitle => 'אפשר לבחור יותר מאחת';

	/// he: 'בואו נתחיל'
	String get finish => 'בואו נתחיל';
}

// Path: dietary
class Translations$dietary$he {
	Translations$dietary$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'בשרי'
	String get meat => 'בשרי';

	/// he: 'חלבי'
	String get dairy => 'חלבי';

	/// he: 'צמחוני'
	String get vegetarian => 'צמחוני';

	/// he: 'טבעוני'
	String get vegan => 'טבעוני';

	/// he: 'כשר'
	String get kosher => 'כשר';

	/// he: 'ללא גלוטן'
	String get glutenFree => 'ללא גלוטן';

	/// he: 'אלרגיה'
	String get allergy => 'אלרגיה';
}

// Path: weekday
class Translations$weekday$he {
	Translations$weekday$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ראשון'
	String get sunday => 'ראשון';

	/// he: 'שני'
	String get monday => 'שני';

	/// he: 'שלישי'
	String get tuesday => 'שלישי';

	/// he: 'רביעי'
	String get wednesday => 'רביעי';

	/// he: 'חמישי'
	String get thursday => 'חמישי';

	/// he: 'שישי'
	String get friday => 'שישי';

	/// he: 'שבת'
	String get saturday => 'שבת';
}

// Path: settings
class Translations$settings$he {
	Translations$settings$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הגדרות'
	String get title => 'הגדרות';

	/// he: 'העדפות תזונתיות'
	String get dietaryPreferences => 'העדפות תזונתיות';

	/// he: 'יום קניות'
	String get shoppingDay => 'יום קניות';

	/// he: 'שפה'
	String get language => 'שפה';

	/// he: 'אפקטי קול (דפדוף עמודים)'
	String get soundEffects => 'אפקטי קול (דפדוף עמודים)';

	/// he: 'מעבר מהיר בספר'
	String get fastPageTurn => 'מעבר מהיר בספר';

	/// he: 'קפיצה מתוכן העניינים או מהניווט המהיר תדפדף דרך העמודים שבדרך. בכיבוי, המעבר לעמוד יהיה מיידי.'
	String get fastPageTurnHint => 'קפיצה מתוכן העניינים או מהניווט המהיר תדפדף דרך העמודים שבדרך. בכיבוי, המעבר לעמוד יהיה מיידי.';

	/// he: 'ניהול שיתופים'
	String get sharedAccess => 'ניהול שיתופים';

	/// he: 'עדיין לא שיתפתם ספרים או רשימות'
	String get noSharedAccess => 'עדיין לא שיתפתם ספרים או רשימות';
}

// Path: language
class Translations$language$he {
	Translations$language$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'עברית'
	String get hebrew => 'עברית';

	/// he: 'English'
	String get english => 'English';

	/// he: 'العربية'
	String get arabic => 'العربية';

	/// he: 'Français'
	String get french => 'Français';

	/// he: 'Русский'
	String get russian => 'Русский';
}

// Path: books
class Translations$books$he {
	Translations$books$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הספרייה שלי'
	String get myLibrary => 'הספרייה שלי';

	/// he: 'המתכונים שלי'
	String get myRecipes => 'המתכונים שלי';

	/// he: 'כל ספרי המתכונים שלכם במקום אחד'
	String get librarySubtitle => 'כל ספרי המתכונים שלכם במקום אחד';

	/// he: 'חפשו וסננו את כל המתכונים שאספתם'
	String get recipesSubtitle => 'חפשו וסננו את כל המתכונים שאספתם';

	/// he: 'אוסף'
	String get collection => 'אוסף';

	/// he: '$count מתכונים'
	String recipesCount({required Object count}) => '${count} מתכונים';

	/// he: 'ספר חדש'
	String get newBook => 'ספר חדש';

	/// he: 'שם הספר'
	String get newBookTitle => 'שם הספר';

	/// he: 'תוכן עניינים'
	String get tableOfContents => 'תוכן עניינים';

	/// he: 'עדיין אין לכם ספרים. צרו את הספר הראשון שלכם!'
	String get emptyLibrary => 'עדיין אין לכם ספרים. צרו את הספר הראשון שלכם!';

	/// he: 'הספר הזה ריק. הוסיפו מתכון ראשון'
	String get emptyBook => 'הספר הזה ריק. הוסיפו מתכון ראשון';

	/// he: 'ניווט מהיר'
	String get quickNav => 'ניווט מהיר';

	/// he: 'שיתוף ספר'
	String get share => 'שיתוף ספר';

	/// he: 'צופה'
	String get viewer => 'צופה';

	/// he: 'עורך'
	String get editor => 'עורך';

	/// he: 'גררו כדי לשנות את סדר המתכונים'
	String get reorderHint => 'גררו כדי לשנות את סדר המתכונים';

	/// he: 'תמונת כריכה'
	String get coverImage => 'תמונת כריכה';

	/// he: 'אפשרויות ספר'
	String get bookOptions => 'אפשרויות ספר';

	/// he: 'עריכת שם הספר'
	String get renameBook => 'עריכת שם הספר';
}

// Path: recipe
class Translations$recipe$he {
	Translations$recipe$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'זמן הכנה'
	String get prepTime => 'זמן הכנה';

	/// he: 'זמן בישול'
	String get cookTime => 'זמן בישול';

	/// he: 'מצרכים'
	String get ingredients => 'מצרכים';

	/// he: '$count מצרכים'
	String ingredientsCount({required Object count}) => '${count} מצרכים';

	/// he: '$count דק׳'
	String minutes({required Object count}) => '${count} דק׳';

	/// he: 'אופן ההכנה'
	String get instructions => 'אופן ההכנה';

	/// he: 'הוסף לספר'
	String get addToBook => 'הוסף לספר';

	/// he: 'הסר מהספר'
	String get removeFromBook => 'הסר מהספר';

	/// he: 'מחיקת מתכון'
	String get deleteRecipe => 'מחיקת מתכון';

	/// he: 'תמונת המתכון'
	String get photo => 'תמונת המתכון';
}

// Path: ingestion
class Translations$ingestion$he {
	Translations$ingestion$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הוספת מתכון'
	String get title => 'הוספת מתכון';

	/// he: 'הדבקת טקסט'
	String get pasteText => 'הדבקת טקסט';

	/// he: 'הדביקו כאן מתכון מוואטסאפ או מכל מקור אחר'
	String get pasteHint => 'הדביקו כאן מתכון מוואטסאפ או מכל מקור אחר';

	/// he: 'חיפוש באינטרנט'
	String get webSearch => 'חיפוש באינטרנט';

	/// he: 'קישור לאתר'
	String get urlScrape => 'קישור לאתר';

	/// he: 'TikTok / Reels'
	String get socialVideo => 'TikTok / Reels';

	/// he: 'נתח מתכון'
	String get parse => 'נתח מתכון';

	/// he: 'מנתח את המתכון...'
	String get parsing => 'מנתח את המתכון...';

	/// he: 'לא הצלחנו לנתח את המתכון'
	String get parseError => 'לא הצלחנו לנתח את המתכון';

	/// he: 'בדקו לפני שמירה'
	String get reviewTitle => 'בדקו לפני שמירה';

	/// he: 'התכונה הזו דורשת חיבור לשירות חיצוני שטרם הוגדר'
	String get notConfigured => 'התכונה הזו דורשת חיבור לשירות חיצוני שטרם הוגדר';
}

// Path: mealPlanner
class Translations$mealPlanner$he {
	Translations$mealPlanner$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'תכנון ארוחות'
	String get title => 'תכנון ארוחות';

	/// he: 'תפריט חדש'
	String get newPlan => 'תפריט חדש';

	/// he: 'שם התפריט'
	String get planName => 'שם התפריט';

	/// he: 'הוספת ארוחה'
	String get addMeal => 'הוספת ארוחה';

	/// he: 'שם הארוחה'
	String get mealName => 'שם הארוחה';

	/// he: 'הוספת פריט'
	String get addItem => 'הוספת פריט';

	/// he: 'בחירת מתכון'
	String get pickRecipe => 'בחירת מתכון';

	/// he: 'פריט מהיר'
	String get quickEntry => 'פריט מהיר';

	/// he: 'עדיין אין תפריטים. צרו את התפריט הראשון שלכם!'
	String get noPlans => 'עדיין אין תפריטים. צרו את התפריט הראשון שלכם!';

	/// he: 'בחרו מתכון או הוסיפו פריט מהיר'
	String get addMealHint => 'בחרו מתכון או הוסיפו פריט מהיר';

	/// he: 'בוקר'
	String get breakfast => 'בוקר';

	/// he: 'צהריים'
	String get lunch => 'צהריים';

	/// he: 'ערב'
	String get dinner => 'ערב';

	/// he: 'ביניים בוקר'
	String get morningSnack => 'ביניים בוקר';

	/// he: 'ביניים צהריים'
	String get afternoonSnack => 'ביניים צהריים';

	/// he: 'ביניים ערב'
	String get eveningSnack => 'ביניים ערב';

	/// he: 'תבנית התחלתית'
	String get template => 'תבנית התחלתית';

	/// he: 'בחירה חופשית'
	String get templateFree => 'בחירה חופשית';

	/// he: '3 ארוחות'
	String get templateThree => '3 ארוחות';

	/// he: '6 ארוחות'
	String get templateSix => '6 ארוחות';

	/// he: 'תפריט ריק — הוסיפו ארוחות בעצמכם'
	String get templateFreeHint => 'תפריט ריק — הוסיפו ארוחות בעצמכם';

	/// he: 'בוקר, צהריים וערב בכל ימות השבוע'
	String get templateThreeHint => 'בוקר, צהריים וערב בכל ימות השבוע';

	/// he: '3 ארוחות עיקריות + ארוחות ביניים בכל ימות השבוע'
	String get templateSixHint => '3 ארוחות עיקריות + ארוחות ביניים בכל ימות השבוע';

	/// he: 'צריך לתת שם לתפריט'
	String get nameRequired => 'צריך לתת שם לתפריט';

	/// he: 'מוצרים'
	String get products => 'מוצרים';

	/// he: 'הוספת מוצר'
	String get addProduct => 'הוספת מוצר';

	/// he: 'שם המוצר'
	String get productName => 'שם המוצר';

	/// he: 'בלי מוצרים הפריט ייכנס לרשימת הקניות כשורה אחת בשמו'
	String get noProducts => 'בלי מוצרים הפריט ייכנס לרשימת הקניות כשורה אחת בשמו';

	/// he: 'שם הפריט'
	String get itemName => 'שם הפריט';

	/// he: 'עריכת פריט'
	String get editItem => 'עריכת פריט';
}

// Path: groceryList
class Translations$groceryList$he {
	Translations$groceryList$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'רשימת קניות'
	String get title => 'רשימת קניות';

	/// he: 'מרוכז מכל התפריטים הפעילים'
	String get aggregated => 'מרוכז מכל התפריטים הפעילים';

	/// he: 'פריט חדש'
	String get addItem => 'פריט חדש';

	/// he: 'קטגוריה'
	String get category => 'קטגוריה';

	/// he: 'מקורות הכמות'
	String get breakdownTitle => 'מקורות הכמות';

	/// he: 'התקדמות איסוף'
	String get collectionProgress => 'התקדמות איסוף';

	/// he: '$collected מתוך $total פריטים נאספו'
	String itemsCollected({required Object collected, required Object total}) => '${collected} מתוך ${total} פריטים נאספו';

	/// he: 'עדכון כמויות'
	String get adjustAmounts => 'עדכון כמויות';

	/// he: 'תוספת חופשית'
	String get buffer => 'תוספת חופשית';

	/// he: 'שיתוף רשימה'
	String get share => 'שיתוף רשימה';

	/// he: 'הרשימה ריקה כרגע'
	String get empty => 'הרשימה ריקה כרגע';

	/// he: 'פריטים לא מסומנים'
	String get uncheckedSection => 'פריטים לא מסומנים';

	/// he: 'פריטים מסומנים'
	String get checkedSection => 'פריטים מסומנים';

	/// he: 'סמן הכל'
	String get selectAll => 'סמן הכל';

	/// he: 'בטל הכל'
	String get clearAll => 'בטל הכל';

	/// he: 'מחק מסומנים'
	String get deleteChecked => 'מחק מסומנים';

	/// he: 'כמות'
	String get amount => 'כמות';

	/// he: 'יחידת מידה'
	String get unit => 'יחידת מידה';

	/// he: 'חייב להישאר לפחות מקור אחד'
	String get lastSource => 'חייב להישאר לפחות מקור אחד';

	/// he: 'שם הפריט'
	String get itemName => 'שם הפריט';
}

// Path: unit
class Translations$unit$he {
	Translations$unit$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'גרם'
	String get gram => 'גרם';

	/// he: 'ק"ג'
	String get kilogram => 'ק"ג';

	/// he: 'מ"ל'
	String get milliliter => 'מ"ל';

	/// he: 'ליטר'
	String get liter => 'ליטר';

	/// he: 'כפית'
	String get teaspoon => 'כפית';

	/// he: 'כף'
	String get tablespoon => 'כף';

	/// he: 'כוס'
	String get cup => 'כוס';

	/// he: 'יחידה'
	String get unit => 'יחידה';

	/// he: 'קורט'
	String get pinch => 'קורט';

	/// he: '—'
	String get unspecified => '—';
}

// Path: image
class Translations$image$he {
	Translations$image$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הוספת תמונה'
	String get add => 'הוספת תמונה';

	/// he: 'שינוי תמונה'
	String get change => 'שינוי תמונה';

	/// he: 'בחירה מהגלריה'
	String get gallery => 'בחירה מהגלריה';

	/// he: 'צילום תמונה'
	String get camera => 'צילום תמונה';

	/// he: 'הסרת התמונה'
	String get remove => 'הסרת התמונה';
}

// Path: nav
class Translations$nav$he {
	Translations$nav$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ספרייה'
	String get library => 'ספרייה';

	/// he: 'מתכונים'
	String get recipes => 'מתכונים';

	/// he: 'תפריטים'
	String get mealPlan => 'תפריטים';

	/// he: 'קניות'
	String get groceries => 'קניות';

	/// he: 'הגדרות'
	String get settings => 'הגדרות';
}

/// The flat map containing all translations for locale <he>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'איזי-פלייט',
			'common.save' => 'שמירה',
			'common.cancel' => 'ביטול',
			'common.next' => 'הבא',
			'common.back' => 'חזרה',
			'common.done' => 'סיום',
			'common.add' => 'הוספה',
			'common.edit' => 'עריכה',
			'common.delete' => 'מחיקה',
			'common.search' => 'חיפוש',
			'common.retry' => 'נסה שוב',
			'common.loading' => 'טוען...',
			'common.error' => 'אירעה שגיאה',
			'common.missingInfo' => '[חסר מידע]',
			'onboarding.welcomeTitle' => 'ברוכים הבאים ל-EasyPlate',
			'onboarding.welcomeSubtitle' => 'תכננו ארוחות, בשלו וקנו — הכל במקום אחד',
			'onboarding.shoppingDayTitle' => 'מתי יום הקניות השבועי שלכם?',
			'onboarding.dietaryTitle' => 'מהן ההעדפות התזונתיות שלכם?',
			'onboarding.dietarySubtitle' => 'אפשר לבחור יותר מאחת',
			'onboarding.finish' => 'בואו נתחיל',
			'dietary.meat' => 'בשרי',
			'dietary.dairy' => 'חלבי',
			'dietary.vegetarian' => 'צמחוני',
			'dietary.vegan' => 'טבעוני',
			'dietary.kosher' => 'כשר',
			'dietary.glutenFree' => 'ללא גלוטן',
			'dietary.allergy' => 'אלרגיה',
			'weekday.sunday' => 'ראשון',
			'weekday.monday' => 'שני',
			'weekday.tuesday' => 'שלישי',
			'weekday.wednesday' => 'רביעי',
			'weekday.thursday' => 'חמישי',
			'weekday.friday' => 'שישי',
			'weekday.saturday' => 'שבת',
			'settings.title' => 'הגדרות',
			'settings.dietaryPreferences' => 'העדפות תזונתיות',
			'settings.shoppingDay' => 'יום קניות',
			'settings.language' => 'שפה',
			'settings.soundEffects' => 'אפקטי קול (דפדוף עמודים)',
			'settings.fastPageTurn' => 'מעבר מהיר בספר',
			'settings.fastPageTurnHint' => 'קפיצה מתוכן העניינים או מהניווט המהיר תדפדף דרך העמודים שבדרך. בכיבוי, המעבר לעמוד יהיה מיידי.',
			'settings.sharedAccess' => 'ניהול שיתופים',
			'settings.noSharedAccess' => 'עדיין לא שיתפתם ספרים או רשימות',
			'language.hebrew' => 'עברית',
			'language.english' => 'English',
			'language.arabic' => 'العربية',
			'language.french' => 'Français',
			'language.russian' => 'Русский',
			'books.myLibrary' => 'הספרייה שלי',
			'books.myRecipes' => 'המתכונים שלי',
			'books.librarySubtitle' => 'כל ספרי המתכונים שלכם במקום אחד',
			'books.recipesSubtitle' => 'חפשו וסננו את כל המתכונים שאספתם',
			'books.collection' => 'אוסף',
			'books.recipesCount' => ({required Object count}) => '${count} מתכונים',
			'books.newBook' => 'ספר חדש',
			'books.newBookTitle' => 'שם הספר',
			'books.tableOfContents' => 'תוכן עניינים',
			'books.emptyLibrary' => 'עדיין אין לכם ספרים. צרו את הספר הראשון שלכם!',
			'books.emptyBook' => 'הספר הזה ריק. הוסיפו מתכון ראשון',
			'books.quickNav' => 'ניווט מהיר',
			'books.share' => 'שיתוף ספר',
			'books.viewer' => 'צופה',
			'books.editor' => 'עורך',
			'books.reorderHint' => 'גררו כדי לשנות את סדר המתכונים',
			'books.coverImage' => 'תמונת כריכה',
			'books.bookOptions' => 'אפשרויות ספר',
			'books.renameBook' => 'עריכת שם הספר',
			'recipe.prepTime' => 'זמן הכנה',
			'recipe.cookTime' => 'זמן בישול',
			'recipe.ingredients' => 'מצרכים',
			'recipe.ingredientsCount' => ({required Object count}) => '${count} מצרכים',
			'recipe.minutes' => ({required Object count}) => '${count} דק׳',
			'recipe.instructions' => 'אופן ההכנה',
			'recipe.addToBook' => 'הוסף לספר',
			'recipe.removeFromBook' => 'הסר מהספר',
			'recipe.deleteRecipe' => 'מחיקת מתכון',
			'recipe.photo' => 'תמונת המתכון',
			'ingestion.title' => 'הוספת מתכון',
			'ingestion.pasteText' => 'הדבקת טקסט',
			'ingestion.pasteHint' => 'הדביקו כאן מתכון מוואטסאפ או מכל מקור אחר',
			'ingestion.webSearch' => 'חיפוש באינטרנט',
			'ingestion.urlScrape' => 'קישור לאתר',
			'ingestion.socialVideo' => 'TikTok / Reels',
			'ingestion.parse' => 'נתח מתכון',
			'ingestion.parsing' => 'מנתח את המתכון...',
			'ingestion.parseError' => 'לא הצלחנו לנתח את המתכון',
			'ingestion.reviewTitle' => 'בדקו לפני שמירה',
			'ingestion.notConfigured' => 'התכונה הזו דורשת חיבור לשירות חיצוני שטרם הוגדר',
			'mealPlanner.title' => 'תכנון ארוחות',
			'mealPlanner.newPlan' => 'תפריט חדש',
			'mealPlanner.planName' => 'שם התפריט',
			'mealPlanner.addMeal' => 'הוספת ארוחה',
			'mealPlanner.mealName' => 'שם הארוחה',
			'mealPlanner.addItem' => 'הוספת פריט',
			'mealPlanner.pickRecipe' => 'בחירת מתכון',
			'mealPlanner.quickEntry' => 'פריט מהיר',
			'mealPlanner.noPlans' => 'עדיין אין תפריטים. צרו את התפריט הראשון שלכם!',
			'mealPlanner.addMealHint' => 'בחרו מתכון או הוסיפו פריט מהיר',
			'mealPlanner.breakfast' => 'בוקר',
			'mealPlanner.lunch' => 'צהריים',
			'mealPlanner.dinner' => 'ערב',
			'mealPlanner.morningSnack' => 'ביניים בוקר',
			'mealPlanner.afternoonSnack' => 'ביניים צהריים',
			'mealPlanner.eveningSnack' => 'ביניים ערב',
			'mealPlanner.template' => 'תבנית התחלתית',
			'mealPlanner.templateFree' => 'בחירה חופשית',
			'mealPlanner.templateThree' => '3 ארוחות',
			'mealPlanner.templateSix' => '6 ארוחות',
			'mealPlanner.templateFreeHint' => 'תפריט ריק — הוסיפו ארוחות בעצמכם',
			'mealPlanner.templateThreeHint' => 'בוקר, צהריים וערב בכל ימות השבוע',
			'mealPlanner.templateSixHint' => '3 ארוחות עיקריות + ארוחות ביניים בכל ימות השבוע',
			'mealPlanner.nameRequired' => 'צריך לתת שם לתפריט',
			'mealPlanner.products' => 'מוצרים',
			'mealPlanner.addProduct' => 'הוספת מוצר',
			'mealPlanner.productName' => 'שם המוצר',
			'mealPlanner.noProducts' => 'בלי מוצרים הפריט ייכנס לרשימת הקניות כשורה אחת בשמו',
			'mealPlanner.itemName' => 'שם הפריט',
			'mealPlanner.editItem' => 'עריכת פריט',
			'groceryList.title' => 'רשימת קניות',
			'groceryList.aggregated' => 'מרוכז מכל התפריטים הפעילים',
			'groceryList.addItem' => 'פריט חדש',
			'groceryList.category' => 'קטגוריה',
			'groceryList.breakdownTitle' => 'מקורות הכמות',
			'groceryList.collectionProgress' => 'התקדמות איסוף',
			'groceryList.itemsCollected' => ({required Object collected, required Object total}) => '${collected} מתוך ${total} פריטים נאספו',
			'groceryList.adjustAmounts' => 'עדכון כמויות',
			'groceryList.buffer' => 'תוספת חופשית',
			'groceryList.share' => 'שיתוף רשימה',
			'groceryList.empty' => 'הרשימה ריקה כרגע',
			'groceryList.uncheckedSection' => 'פריטים לא מסומנים',
			'groceryList.checkedSection' => 'פריטים מסומנים',
			'groceryList.selectAll' => 'סמן הכל',
			'groceryList.clearAll' => 'בטל הכל',
			'groceryList.deleteChecked' => 'מחק מסומנים',
			'groceryList.amount' => 'כמות',
			'groceryList.unit' => 'יחידת מידה',
			'groceryList.lastSource' => 'חייב להישאר לפחות מקור אחד',
			'groceryList.itemName' => 'שם הפריט',
			'unit.gram' => 'גרם',
			'unit.kilogram' => 'ק"ג',
			'unit.milliliter' => 'מ"ל',
			'unit.liter' => 'ליטר',
			'unit.teaspoon' => 'כפית',
			'unit.tablespoon' => 'כף',
			'unit.cup' => 'כוס',
			'unit.unit' => 'יחידה',
			'unit.pinch' => 'קורט',
			'unit.unspecified' => '—',
			'image.add' => 'הוספת תמונה',
			'image.change' => 'שינוי תמונה',
			'image.gallery' => 'בחירה מהגלריה',
			'image.camera' => 'צילום תמונה',
			'image.remove' => 'הסרת התמונה',
			'nav.library' => 'ספרייה',
			'nav.recipes' => 'מתכונים',
			'nav.mealPlan' => 'תפריטים',
			'nav.groceries' => 'קניות',
			'nav.settings' => 'הגדרות',
			_ => null,
		};
	}
}
