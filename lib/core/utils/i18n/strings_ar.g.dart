///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'إيزي بليت';
	@override late final _Translations$common$ar common = _Translations$common$ar._(_root);
	@override late final _Translations$onboarding$ar onboarding = _Translations$onboarding$ar._(_root);
	@override late final _Translations$dietary$ar dietary = _Translations$dietary$ar._(_root);
	@override late final _Translations$weekday$ar weekday = _Translations$weekday$ar._(_root);
	@override late final _Translations$settings$ar settings = _Translations$settings$ar._(_root);
	@override late final _Translations$language$ar language = _Translations$language$ar._(_root);
	@override late final _Translations$books$ar books = _Translations$books$ar._(_root);
	@override late final _Translations$recipe$ar recipe = _Translations$recipe$ar._(_root);
	@override late final _Translations$ingestion$ar ingestion = _Translations$ingestion$ar._(_root);
	@override late final _Translations$mealPlanner$ar mealPlanner = _Translations$mealPlanner$ar._(_root);
	@override late final _Translations$groceryList$ar groceryList = _Translations$groceryList$ar._(_root);
	@override late final _Translations$unit$ar unit = _Translations$unit$ar._(_root);
	@override late final _Translations$image$ar image = _Translations$image$ar._(_root);
}

// Path: common
class _Translations$common$ar extends Translations$common$he {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get save => 'حفظ';
	@override String get cancel => 'إلغاء';
	@override String get next => 'التالي';
	@override String get back => 'رجوع';
	@override String get done => 'تم';
	@override String get add => 'إضافة';
	@override String get edit => 'تعديل';
	@override String get delete => 'حذف';
	@override String get search => 'بحث';
	@override String get retry => 'حاول مرة أخرى';
	@override String get loading => 'جارٍ التحميل...';
	@override String get error => 'حدث خطأ ما';
	@override String get missingInfo => '[معلومات ناقصة]';
}

// Path: onboarding
class _Translations$onboarding$ar extends Translations$onboarding$he {
	_Translations$onboarding$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get welcomeTitle => 'أهلًا بك في EasyPlate';
	@override String get welcomeSubtitle => 'خطّط لوجباتك، اطبخ وتسوّق — كل ذلك في مكان واحد';
	@override String get shoppingDayTitle => 'ما هو يوم التسوّق الأسبوعي لديك؟';
	@override String get dietaryTitle => 'ما هي تفضيلاتك الغذائية؟';
	@override String get dietarySubtitle => 'يمكنك اختيار أكثر من واحد';
	@override String get finish => 'لنبدأ';
}

// Path: dietary
class _Translations$dietary$ar extends Translations$dietary$he {
	_Translations$dietary$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get meat => 'لحوم';
	@override String get dairy => 'ألبان';
	@override String get vegetarian => 'نباتي';
	@override String get vegan => 'نباتي صرف';
	@override String get kosher => 'كوشير';
	@override String get glutenFree => 'خالٍ من الغلوتين';
	@override String get allergy => 'حساسية';
}

// Path: weekday
class _Translations$weekday$ar extends Translations$weekday$he {
	_Translations$weekday$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get sunday => 'الأحد';
	@override String get monday => 'الاثنين';
	@override String get tuesday => 'الثلاثاء';
	@override String get wednesday => 'الأربعاء';
	@override String get thursday => 'الخميس';
	@override String get friday => 'الجمعة';
	@override String get saturday => 'السبت';
}

// Path: settings
class _Translations$settings$ar extends Translations$settings$he {
	_Translations$settings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الإعدادات';
	@override String get dietaryPreferences => 'التفضيلات الغذائية';
	@override String get shoppingDay => 'يوم التسوّق';
	@override String get language => 'اللغة';
	@override String get soundEffects => 'المؤثرات الصوتية (تقليب الصفحات)';
	@override String get fastPageTurn => 'تصفّح سريع في الكتاب';
	@override String get fastPageTurnHint => 'الانتقال من جدول المحتويات أو التنقّل السريع يقلّب الصفحات التي بينهما. أوقفه للانتقال إلى الصفحة مباشرة.';
	@override String get sharedAccess => 'إدارة المشاركة';
	@override String get noSharedAccess => 'لم تشارك أي كتب أو قوائم بعد';
}

// Path: language
class _Translations$language$ar extends Translations$language$he {
	_Translations$language$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get hebrew => 'עברית';
	@override String get english => 'English';
	@override String get arabic => 'العربية';
	@override String get french => 'Français';
	@override String get russian => 'Русский';
}

// Path: books
class _Translations$books$ar extends Translations$books$he {
	_Translations$books$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get myLibrary => 'مكتبتي';
	@override String get myRecipes => 'وصفاتي';
	@override String get librarySubtitle => 'كل كتب الوصفات في مكان واحد';
	@override String get recipesSubtitle => 'ابحث وصفِّ كل الوصفات التي جمعتها';
	@override String get collection => 'مجموعة';
	@override String recipesCount({required Object count}) => '${count} وصفات';
	@override String get newBook => 'كتاب جديد';
	@override String get newBookTitle => 'اسم الكتاب';
	@override String get tableOfContents => 'جدول المحتويات';
	@override String get emptyLibrary => 'ليس لديك أي كتب بعد. أنشئ كتابك الأول!';
	@override String get emptyBook => 'هذا الكتاب فارغ. أضف وصفتك الأولى';
	@override String get quickNav => 'تنقّل سريع';
	@override String get share => 'مشاركة الكتاب';
	@override String get viewer => 'مشاهد';
	@override String get editor => 'محرّر';
	@override String get reorderHint => 'اسحب لإعادة ترتيب الوصفات';
	@override String get coverImage => 'صورة الغلاف';
	@override String get bookOptions => 'خيارات الكتاب';
}

// Path: recipe
class _Translations$recipe$ar extends Translations$recipe$he {
	_Translations$recipe$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get prepTime => 'وقت التحضير';
	@override String get cookTime => 'وقت الطهي';
	@override String get ingredients => 'المكوّنات';
	@override String ingredientsCount({required Object count}) => '${count} مكوّنات';
	@override String minutes({required Object count}) => '${count} دقيقة';
	@override String get instructions => 'طريقة التحضير';
	@override String get addToBook => 'إضافة إلى كتاب';
	@override String get removeFromBook => 'إزالة من الكتاب';
	@override String get deleteRecipe => 'حذف الوصفة';
	@override String get photo => 'صورة الوصفة';
}

// Path: ingestion
class _Translations$ingestion$ar extends Translations$ingestion$he {
	_Translations$ingestion$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إضافة وصفة';
	@override String get pasteText => 'لصق نص';
	@override String get pasteHint => 'الصق هنا وصفة من واتساب أو من أي مصدر آخر';
	@override String get webSearch => 'بحث في الإنترنت';
	@override String get urlScrape => 'رابط موقع';
	@override String get socialVideo => 'TikTok / Reels';
	@override String get parse => 'تحليل الوصفة';
	@override String get parsing => 'جارٍ تحليل الوصفة...';
	@override String get parseError => 'لم نتمكّن من تحليل الوصفة';
	@override String get reviewTitle => 'راجع قبل الحفظ';
	@override String get notConfigured => 'تتطلّب هذه الميزة خدمة خارجية لم يتم إعدادها بعد';
}

// Path: mealPlanner
class _Translations$mealPlanner$ar extends Translations$mealPlanner$he {
	_Translations$mealPlanner$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تخطيط الوجبات';
	@override String get newPlan => 'خطة جديدة';
	@override String get planName => 'اسم الخطة';
	@override String get addMeal => 'إضافة وجبة';
	@override String get mealName => 'اسم الوجبة';
	@override String get addItem => 'إضافة عنصر';
	@override String get pickRecipe => 'اختيار وصفة';
	@override String get quickEntry => 'عنصر سريع';
	@override String get noPlans => 'لا توجد خطط بعد. أنشئ خطتك الأولى!';
	@override String get addMealHint => 'اختر وصفة أو أضف عنصرًا سريعًا';
	@override String get breakfast => 'فطور';
	@override String get lunch => 'غداء';
	@override String get dinner => 'عشاء';
	@override String get morningSnack => 'وجبة خفيفة صباحية';
	@override String get afternoonSnack => 'وجبة خفيفة بعد الظهر';
	@override String get eveningSnack => 'وجبة خفيفة مسائية';
	@override String get template => 'قالب البداية';
	@override String get templateFree => 'ابدأ فارغًا';
	@override String get templateThree => '3 وجبات';
	@override String get templateSix => '6 وجبات';
	@override String get templateFreeHint => 'خطة فارغة — أضف الوجبات بنفسك';
	@override String get templateThreeHint => 'فطور وغداء وعشاء كل يوم';
	@override String get templateSixHint => '3 وجبات رئيسية مع وجبات خفيفة كل يوم';
	@override String get nameRequired => 'أعطِ الخطة اسمًا';
	@override String get products => 'المنتجات';
	@override String get addProduct => 'إضافة منتج';
	@override String get productName => 'اسم المنتج';
	@override String get noProducts => 'بدون منتجات يُضاف العنصر إلى قائمة التسوّق كسطر واحد باسمه';
	@override String get itemName => 'اسم العنصر';
	@override String get editItem => 'تعديل العنصر';
}

// Path: groceryList
class _Translations$groceryList$ar extends Translations$groceryList$he {
	_Translations$groceryList$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'قائمة التسوّق';
	@override String get aggregated => 'مجمّعة من كل الخطط النشطة';
	@override String get addItem => 'عنصر جديد';
	@override String get category => 'الفئة';
	@override String get breakdownTitle => 'مصادر الكمية';
	@override String get collectionProgress => 'تقدّم الجمع';
	@override String itemsCollected({required Object collected, required Object total}) => 'تم جمع ${collected} من أصل ${total} عناصر';
	@override String get adjustAmounts => 'تعديل الكميات';
	@override String get buffer => 'كمية إضافية';
	@override String get share => 'مشاركة القائمة';
	@override String get empty => 'القائمة فارغة حاليًا';
	@override String get uncheckedSection => 'لم تُجمع بعد';
	@override String get checkedSection => 'تم جمعها';
	@override String get selectAll => 'تحديد الكل';
	@override String get clearAll => 'إلغاء التحديد';
	@override String get deleteChecked => 'حذف المحددة';
	@override String get amount => 'الكمية';
	@override String get unit => 'وحدة القياس';
	@override String get lastSource => 'يجب أن يبقى مصدر واحد على الأقل';
	@override String get itemName => 'اسم العنصر';
}

// Path: unit
class _Translations$unit$ar extends Translations$unit$he {
	_Translations$unit$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get gram => 'غرام';
	@override String get kilogram => 'كغ';
	@override String get milliliter => 'مل';
	@override String get liter => 'لتر';
	@override String get teaspoon => 'ملعقة صغيرة';
	@override String get tablespoon => 'ملعقة كبيرة';
	@override String get cup => 'كوب';
	@override String get unit => 'وحدة';
	@override String get pinch => 'رشّة';
	@override String get unspecified => '—';
}

// Path: image
class _Translations$image$ar extends Translations$image$he {
	_Translations$image$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get add => 'إضافة صورة';
	@override String get change => 'تغيير الصورة';
	@override String get gallery => 'اختيار من المعرض';
	@override String get camera => 'التقاط صورة';
	@override String get remove => 'إزالة الصورة';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'إيزي بليت',
			'common.save' => 'حفظ',
			'common.cancel' => 'إلغاء',
			'common.next' => 'التالي',
			'common.back' => 'رجوع',
			'common.done' => 'تم',
			'common.add' => 'إضافة',
			'common.edit' => 'تعديل',
			'common.delete' => 'حذف',
			'common.search' => 'بحث',
			'common.retry' => 'حاول مرة أخرى',
			'common.loading' => 'جارٍ التحميل...',
			'common.error' => 'حدث خطأ ما',
			'common.missingInfo' => '[معلومات ناقصة]',
			'onboarding.welcomeTitle' => 'أهلًا بك في EasyPlate',
			'onboarding.welcomeSubtitle' => 'خطّط لوجباتك، اطبخ وتسوّق — كل ذلك في مكان واحد',
			'onboarding.shoppingDayTitle' => 'ما هو يوم التسوّق الأسبوعي لديك؟',
			'onboarding.dietaryTitle' => 'ما هي تفضيلاتك الغذائية؟',
			'onboarding.dietarySubtitle' => 'يمكنك اختيار أكثر من واحد',
			'onboarding.finish' => 'لنبدأ',
			'dietary.meat' => 'لحوم',
			'dietary.dairy' => 'ألبان',
			'dietary.vegetarian' => 'نباتي',
			'dietary.vegan' => 'نباتي صرف',
			'dietary.kosher' => 'كوشير',
			'dietary.glutenFree' => 'خالٍ من الغلوتين',
			'dietary.allergy' => 'حساسية',
			'weekday.sunday' => 'الأحد',
			'weekday.monday' => 'الاثنين',
			'weekday.tuesday' => 'الثلاثاء',
			'weekday.wednesday' => 'الأربعاء',
			'weekday.thursday' => 'الخميس',
			'weekday.friday' => 'الجمعة',
			'weekday.saturday' => 'السبت',
			'settings.title' => 'الإعدادات',
			'settings.dietaryPreferences' => 'التفضيلات الغذائية',
			'settings.shoppingDay' => 'يوم التسوّق',
			'settings.language' => 'اللغة',
			'settings.soundEffects' => 'المؤثرات الصوتية (تقليب الصفحات)',
			'settings.fastPageTurn' => 'تصفّح سريع في الكتاب',
			'settings.fastPageTurnHint' => 'الانتقال من جدول المحتويات أو التنقّل السريع يقلّب الصفحات التي بينهما. أوقفه للانتقال إلى الصفحة مباشرة.',
			'settings.sharedAccess' => 'إدارة المشاركة',
			'settings.noSharedAccess' => 'لم تشارك أي كتب أو قوائم بعد',
			'language.hebrew' => 'עברית',
			'language.english' => 'English',
			'language.arabic' => 'العربية',
			'language.french' => 'Français',
			'language.russian' => 'Русский',
			'books.myLibrary' => 'مكتبتي',
			'books.myRecipes' => 'وصفاتي',
			'books.librarySubtitle' => 'كل كتب الوصفات في مكان واحد',
			'books.recipesSubtitle' => 'ابحث وصفِّ كل الوصفات التي جمعتها',
			'books.collection' => 'مجموعة',
			'books.recipesCount' => ({required Object count}) => '${count} وصفات',
			'books.newBook' => 'كتاب جديد',
			'books.newBookTitle' => 'اسم الكتاب',
			'books.tableOfContents' => 'جدول المحتويات',
			'books.emptyLibrary' => 'ليس لديك أي كتب بعد. أنشئ كتابك الأول!',
			'books.emptyBook' => 'هذا الكتاب فارغ. أضف وصفتك الأولى',
			'books.quickNav' => 'تنقّل سريع',
			'books.share' => 'مشاركة الكتاب',
			'books.viewer' => 'مشاهد',
			'books.editor' => 'محرّر',
			'books.reorderHint' => 'اسحب لإعادة ترتيب الوصفات',
			'books.coverImage' => 'صورة الغلاف',
			'books.bookOptions' => 'خيارات الكتاب',
			'recipe.prepTime' => 'وقت التحضير',
			'recipe.cookTime' => 'وقت الطهي',
			'recipe.ingredients' => 'المكوّنات',
			'recipe.ingredientsCount' => ({required Object count}) => '${count} مكوّنات',
			'recipe.minutes' => ({required Object count}) => '${count} دقيقة',
			'recipe.instructions' => 'طريقة التحضير',
			'recipe.addToBook' => 'إضافة إلى كتاب',
			'recipe.removeFromBook' => 'إزالة من الكتاب',
			'recipe.deleteRecipe' => 'حذف الوصفة',
			'recipe.photo' => 'صورة الوصفة',
			'ingestion.title' => 'إضافة وصفة',
			'ingestion.pasteText' => 'لصق نص',
			'ingestion.pasteHint' => 'الصق هنا وصفة من واتساب أو من أي مصدر آخر',
			'ingestion.webSearch' => 'بحث في الإنترنت',
			'ingestion.urlScrape' => 'رابط موقع',
			'ingestion.socialVideo' => 'TikTok / Reels',
			'ingestion.parse' => 'تحليل الوصفة',
			'ingestion.parsing' => 'جارٍ تحليل الوصفة...',
			'ingestion.parseError' => 'لم نتمكّن من تحليل الوصفة',
			'ingestion.reviewTitle' => 'راجع قبل الحفظ',
			'ingestion.notConfigured' => 'تتطلّب هذه الميزة خدمة خارجية لم يتم إعدادها بعد',
			'mealPlanner.title' => 'تخطيط الوجبات',
			'mealPlanner.newPlan' => 'خطة جديدة',
			'mealPlanner.planName' => 'اسم الخطة',
			'mealPlanner.addMeal' => 'إضافة وجبة',
			'mealPlanner.mealName' => 'اسم الوجبة',
			'mealPlanner.addItem' => 'إضافة عنصر',
			'mealPlanner.pickRecipe' => 'اختيار وصفة',
			'mealPlanner.quickEntry' => 'عنصر سريع',
			'mealPlanner.noPlans' => 'لا توجد خطط بعد. أنشئ خطتك الأولى!',
			'mealPlanner.addMealHint' => 'اختر وصفة أو أضف عنصرًا سريعًا',
			'mealPlanner.breakfast' => 'فطور',
			'mealPlanner.lunch' => 'غداء',
			'mealPlanner.dinner' => 'عشاء',
			'mealPlanner.morningSnack' => 'وجبة خفيفة صباحية',
			'mealPlanner.afternoonSnack' => 'وجبة خفيفة بعد الظهر',
			'mealPlanner.eveningSnack' => 'وجبة خفيفة مسائية',
			'mealPlanner.template' => 'قالب البداية',
			'mealPlanner.templateFree' => 'ابدأ فارغًا',
			'mealPlanner.templateThree' => '3 وجبات',
			'mealPlanner.templateSix' => '6 وجبات',
			'mealPlanner.templateFreeHint' => 'خطة فارغة — أضف الوجبات بنفسك',
			'mealPlanner.templateThreeHint' => 'فطور وغداء وعشاء كل يوم',
			'mealPlanner.templateSixHint' => '3 وجبات رئيسية مع وجبات خفيفة كل يوم',
			'mealPlanner.nameRequired' => 'أعطِ الخطة اسمًا',
			'mealPlanner.products' => 'المنتجات',
			'mealPlanner.addProduct' => 'إضافة منتج',
			'mealPlanner.productName' => 'اسم المنتج',
			'mealPlanner.noProducts' => 'بدون منتجات يُضاف العنصر إلى قائمة التسوّق كسطر واحد باسمه',
			'mealPlanner.itemName' => 'اسم العنصر',
			'mealPlanner.editItem' => 'تعديل العنصر',
			'groceryList.title' => 'قائمة التسوّق',
			'groceryList.aggregated' => 'مجمّعة من كل الخطط النشطة',
			'groceryList.addItem' => 'عنصر جديد',
			'groceryList.category' => 'الفئة',
			'groceryList.breakdownTitle' => 'مصادر الكمية',
			'groceryList.collectionProgress' => 'تقدّم الجمع',
			'groceryList.itemsCollected' => ({required Object collected, required Object total}) => 'تم جمع ${collected} من أصل ${total} عناصر',
			'groceryList.adjustAmounts' => 'تعديل الكميات',
			'groceryList.buffer' => 'كمية إضافية',
			'groceryList.share' => 'مشاركة القائمة',
			'groceryList.empty' => 'القائمة فارغة حاليًا',
			'groceryList.uncheckedSection' => 'لم تُجمع بعد',
			'groceryList.checkedSection' => 'تم جمعها',
			'groceryList.selectAll' => 'تحديد الكل',
			'groceryList.clearAll' => 'إلغاء التحديد',
			'groceryList.deleteChecked' => 'حذف المحددة',
			'groceryList.amount' => 'الكمية',
			'groceryList.unit' => 'وحدة القياس',
			'groceryList.lastSource' => 'يجب أن يبقى مصدر واحد على الأقل',
			'groceryList.itemName' => 'اسم العنصر',
			'unit.gram' => 'غرام',
			'unit.kilogram' => 'كغ',
			'unit.milliliter' => 'مل',
			'unit.liter' => 'لتر',
			'unit.teaspoon' => 'ملعقة صغيرة',
			'unit.tablespoon' => 'ملعقة كبيرة',
			'unit.cup' => 'كوب',
			'unit.unit' => 'وحدة',
			'unit.pinch' => 'رشّة',
			'unit.unspecified' => '—',
			'image.add' => 'إضافة صورة',
			'image.change' => 'تغيير الصورة',
			'image.gallery' => 'اختيار من المعرض',
			'image.camera' => 'التقاط صورة',
			'image.remove' => 'إزالة الصورة',
			_ => null,
		};
	}
}
