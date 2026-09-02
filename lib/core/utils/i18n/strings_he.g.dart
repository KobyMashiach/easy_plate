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
	late final Translations$books$he books = Translations$books$he.internal(_root);
	late final Translations$recipe$he recipe = Translations$recipe$he.internal(_root);
	late final Translations$ingestion$he ingestion = Translations$ingestion$he.internal(_root);
	late final Translations$mealPlanner$he mealPlanner = Translations$mealPlanner$he.internal(_root);
	late final Translations$groceryList$he groceryList = Translations$groceryList$he.internal(_root);
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

	/// he: 'אפקטי קול (דפדוף עמודים)'
	String get soundEffects => 'אפקטי קול (דפדוף עמודים)';

	/// he: 'ניהול שיתופים'
	String get sharedAccess => 'ניהול שיתופים';

	/// he: 'עדיין לא שיתפתם ספרים או רשימות'
	String get noSharedAccess => 'עדיין לא שיתפתם ספרים או רשימות';
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

	/// he: 'אופן ההכנה'
	String get instructions => 'אופן ההכנה';

	/// he: 'הוסף לספר'
	String get addToBook => 'הוסף לספר';

	/// he: 'הסר מהספר'
	String get removeFromBook => 'הסר מהספר';

	/// he: 'מחיקת מתכון'
	String get deleteRecipe => 'מחיקת מתכון';
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

	/// he: 'תוספת חופשית'
	String get buffer => 'תוספת חופשית';

	/// he: 'שיתוף רשימה'
	String get share => 'שיתוף רשימה';

	/// he: 'הרשימה ריקה כרגע'
	String get empty => 'הרשימה ריקה כרגע';
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
			'settings.soundEffects' => 'אפקטי קול (דפדוף עמודים)',
			'settings.sharedAccess' => 'ניהול שיתופים',
			'settings.noSharedAccess' => 'עדיין לא שיתפתם ספרים או רשימות',
			'books.myLibrary' => 'הספרייה שלי',
			'books.myRecipes' => 'המתכונים שלי',
			'books.newBook' => 'ספר חדש',
			'books.newBookTitle' => 'שם הספר',
			'books.tableOfContents' => 'תוכן עניינים',
			'books.emptyLibrary' => 'עדיין אין לכם ספרים. צרו את הספר הראשון שלכם!',
			'books.emptyBook' => 'הספר הזה ריק. הוסיפו מתכון ראשון',
			'books.quickNav' => 'ניווט מהיר',
			'books.share' => 'שיתוף ספר',
			'books.viewer' => 'צופה',
			'books.editor' => 'עורך',
			'recipe.prepTime' => 'זמן הכנה',
			'recipe.cookTime' => 'זמן בישול',
			'recipe.ingredients' => 'מצרכים',
			'recipe.instructions' => 'אופן ההכנה',
			'recipe.addToBook' => 'הוסף לספר',
			'recipe.removeFromBook' => 'הסר מהספר',
			'recipe.deleteRecipe' => 'מחיקת מתכון',
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
			'groceryList.title' => 'רשימת קניות',
			'groceryList.aggregated' => 'מרוכז מכל התפריטים הפעילים',
			'groceryList.addItem' => 'פריט חדש',
			'groceryList.category' => 'קטגוריה',
			'groceryList.breakdownTitle' => 'מקורות הכמות',
			'groceryList.buffer' => 'תוספת חופשית',
			'groceryList.share' => 'שיתוף רשימה',
			'groceryList.empty' => 'הרשימה ריקה כרגע',
			_ => null,
		};
	}
}
