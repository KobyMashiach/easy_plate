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
	@override late final _Translations$auth$ar auth = _Translations$auth$ar._(_root);
	@override late final _Translations$profile$ar profile = _Translations$profile$ar._(_root);
	@override late final _Translations$onboarding$ar onboarding = _Translations$onboarding$ar._(_root);
	@override late final _Translations$dietary$ar dietary = _Translations$dietary$ar._(_root);
	@override late final _Translations$weekday$ar weekday = _Translations$weekday$ar._(_root);
	@override late final _Translations$settings$ar settings = _Translations$settings$ar._(_root);
	@override late final _Translations$more$ar more = _Translations$more$ar._(_root);
	@override late final _Translations$language$ar language = _Translations$language$ar._(_root);
	@override late final _Translations$books$ar books = _Translations$books$ar._(_root);
	@override late final _Translations$recipe$ar recipe = _Translations$recipe$ar._(_root);
	@override late final _Translations$community$ar community = _Translations$community$ar._(_root);
	@override late final _Translations$sharing$ar sharing = _Translations$sharing$ar._(_root);
	@override late final _Translations$notifications$ar notifications = _Translations$notifications$ar._(_root);
	@override late final _Translations$editor$ar editor = _Translations$editor$ar._(_root);
	@override late final _Translations$ingestion$ar ingestion = _Translations$ingestion$ar._(_root);
	@override late final _Translations$mealPlanner$ar mealPlanner = _Translations$mealPlanner$ar._(_root);
	@override late final _Translations$groceryList$ar groceryList = _Translations$groceryList$ar._(_root);
	@override late final _Translations$unit$ar unit = _Translations$unit$ar._(_root);
	@override late final _Translations$image$ar image = _Translations$image$ar._(_root);
	@override late final _Translations$nav$ar nav = _Translations$nav$ar._(_root);
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
	@override String get or => 'أو';
	@override String get missingInfo => '[معلومات ناقصة]';
}

// Path: auth
class _Translations$auth$ar extends Translations$auth$he {
	_Translations$auth$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'أهلًا بكم في EasyPlate';
	@override String get subtitle => 'سجّلوا الدخول لحفظ وصفاتكم';
	@override String get signIn => 'تسجيل الدخول';
	@override String get signUp => 'إنشاء حساب';
	@override String get signOut => 'تسجيل الخروج';
	@override String get email => 'البريد الإلكتروني';
	@override String get emailHint => 'name@example.com';
	@override String get password => 'كلمة المرور';
	@override String get passwordHint => '6 أحرف على الأقل';
	@override String get continueWithGoogle => 'المتابعة عبر Google';
	@override String get continueWithPhone => 'المتابعة عبر الهاتف';
	@override String get continueWithEmail => 'المتابعة عبر البريد';
	@override String get phoneNumber => 'رقم الهاتف';
	@override String get phoneHint => '+972501234567';
	@override String get sendCode => 'إرسال الرمز';
	@override String get smsCode => 'رمز الرسالة';
	@override String codeSentTo({required Object phone}) => 'أرسلنا رمز تحقق إلى ${phone}';
	@override String get verify => 'تحقق';
	@override String get resendCode => 'إعادة الإرسال';
	@override String get forgotPassword => 'نسيت كلمة المرور';
	@override String get resetSent => 'تم إرسال بريد إعادة التعيين';
	@override String get noAccount => 'لا يوجد حساب؟ سجّلوا';
	@override String get haveAccount => 'لديكم حساب؟ ادخلوا';
	@override String get invalidEmail => 'بريد إلكتروني غير صالح';
	@override String get passwordTooShort => 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';
	@override String get invalidPhone => 'رقم هاتف غير صالح';
	@override String get codeRequired => 'أدخلوا الرمز الذي وصلكم';
	@override String get errorUnauthorized => 'البيانات المُدخلة غير صحيحة';
	@override String get errorNetwork => 'لا يوجد اتصال بالإنترنت';
	@override String get errorUnknown => 'فشل تسجيل الدخول، حاولوا مجددًا';
	@override String get signOutTitle => 'تسجيل الخروج؟';
	@override String get signOutBody => 'ستحتاجون إلى تسجيل الدخول مجددًا للوصول إلى وصفاتكم.';
	@override String get errorOperationNotAllowed => 'طريقة تسجيل الدخول هذه غير متاحة حاليًا';
	@override String get errorTooManyRequests => 'محاولات كثيرة. حاولوا بعد بضع دقائق';
	@override String get errorInvalidPhone => 'رقم الهاتف غير صالح';
	@override String get errorEmailInUse => 'البريد الإلكتروني مسجّل بالفعل';
	@override String get verifyEmailTitle => 'تأكيد البريد الإلكتروني';
	@override String verifyEmailBody({required Object email}) => 'أرسلنا رابط تأكيد إلى ${email}. افتحوه ثم عودوا إلى هنا.';
	@override String get resendEmail => 'إعادة إرسال الرابط';
	@override String get emailResent => 'تم إرسال الرابط مجددًا';
	@override String get checkVerification => 'لقد أكّدت';
	@override String get stillNotVerified => 'لم يتم التأكيد بعد';
	@override String get linkPhone => 'تأكيد الهاتف';
	@override String get phoneLinked => 'تم تأكيد الهاتف';
	@override String get phoneAlreadyUsed => 'هذا الرقم مرتبط بحساب آخر';
	@override String get emailAlreadyLinked => 'الحساب مرتبط ببريد إلكتروني بالفعل';
	@override String get addEmailPassword => 'إضافة بريد وكلمة مرور';
	@override String get verified => 'مؤكَّد';
	@override String get linkGoogle => 'ربط حساب Google';
	@override String get googleLinked => 'مرتبط';
	@override String get googleAlreadyUsed => 'حساب Google هذا مرتبط بمستخدم آخر';
	@override String get googleAlreadyLinked => 'يوجد حساب Google مرتبط بالفعل';
	@override String get phoneGateTitle => 'تأكيد رقم الهاتف';
	@override String get phoneGateBody => 'كل حساب يتم تأكيده برقم هاتف. سنرسل لك رمزًا عبر رسالة نصية.';
	@override String get changeNumber => 'تغيير الرقم';
	@override String get signInTitle => 'تسجيل الدخول';
	@override String get phoneFirstHint => 'جديد هنا؟ تابع باستخدام الهاتف.';
	@override String get errorAccountExistsDifferentCredential => 'هذا البريد الإلكتروني يخص حسابًا آخر. سجّل الدخول بالطريقة التي سجّلت بها.';
	@override String get errorCredentialInUse => 'هذه البيانات تخص حسابًا آخر بالفعل';
	@override String get continueWithApple => 'المتابعة باستخدام Apple';
	@override String get linkApple => 'ربط حساب Apple';
	@override String get appleLinked => 'مرتبط';
	@override String get appleAlreadyUsed => 'حساب Apple هذا مرتبط بمستخدم آخر';
	@override String get appleAlreadyLinked => 'تم ربط حساب Apple بالفعل';
}

// Path: profile
class _Translations$profile$ar extends Translations$profile$he {
	_Translations$profile$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get setupTitle => 'تفاصيل أخيرة';
	@override String get setupSubtitle => 'لكي نعرف كيف نخاطبكم';
	@override String get fullName => 'الاسم الكامل';
	@override String get fullNameHint => 'محمد أحمد';
	@override String get fullNameRequired => 'الاسم الكامل مطلوب';
	@override String get photo => 'صورة الملف الشخصي';
	@override String get addPhoto => 'إضافة صورة';
	@override String get phoneOptional => 'الهاتف (اختياري)';
	@override String get emailOptional => 'البريد (اختياري)';
	@override String get save => 'إنهاء التسجيل';
	@override String get saving => 'جارٍ الحفظ...';
	@override String get saveFailed => 'تعذّر حفظ الملف الشخصي';
	@override String get myProfile => 'ملفي الشخصي';
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

// Path: more
class _Translations$more$ar extends Translations$more$he {
	_Translations$more$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المزيد';
	@override String get settings => 'الإعدادات';
	@override String get profile => 'ملفي الشخصي';
	@override String get support => 'الدعم';
	@override String get supportTitle => 'كيف يمكننا المساعدة؟';
	@override String get supportBody => 'اكتبوا لنا وسنعود إليكم قريبًا.';
	@override String get whatsapp => 'راسلونا على واتساب';
	@override String get email => 'إرسال بريد';
	@override String get supportUnavailable => 'تعذّر فتح التطبيق';
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
	@override String get renameBook => 'تعديل اسم الكتاب';
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
	@override String hours({required Object count}) => '${count} ساعة';
	@override String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours} ساعة و${minutes} دقيقة';
	@override String get instructions => 'طريقة التحضير';
	@override String get addToBook => 'إضافة إلى كتاب';
	@override String get removeFromBook => 'إزالة من الكتاب';
	@override String get deleteRecipe => 'حذف الوصفة';
	@override String get photo => 'صورة الوصفة';
	@override String get mine => 'وصفاتي';
	@override String get saved => 'وصفات محفوظة';
	@override String get noneMine => 'لم تنشئوا وصفات بعد';
	@override String get noneSaved => 'لم تحفظوا وصفات من المجتمع بعد';
	@override String get pendingAnalysis => 'بانتظار التحليل';
	@override String get pendingAnalysisHint => 'محفوظة كنص خام. حلّلوها الآن أو عدّلوها يدويًا.';
	@override String get analyzeNow => 'التحليل عبر AI الآن';
	@override String get analyzing => 'جارٍ تحليل الوصفة...';
	@override String get analyzeFailed => 'فشل التحليل — يمكنكم المحاولة لاحقًا';
}

// Path: community
class _Translations$community$ar extends Translations$community$he {
	_Translations$community$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المجتمع';
	@override String get forum => 'المنتدى';
	@override String get sharedRecipes => 'وصفات مشتركة';
	@override String get newPost => 'منشور جديد';
	@override String get postTitle => 'العنوان';
	@override String get postBody => 'ما الذي تودّون سؤاله أو مشاركته؟';
	@override String get postTitleRequired => 'العنوان مطلوب';
	@override String get postBodyRequired => 'المحتوى مطلوب';
	@override String get publish => 'نشر';
	@override String replies({required Object count}) => '${count} ردود';
	@override String get noReplies => 'لا توجد ردود بعد';
	@override String get oneReply => 'رد واحد';
	@override String get writeReply => 'اكتبوا ردًا...';
	@override String get send => 'إرسال';
	@override String get noPosts => 'لا توجد منشورات بعد. كونوا الأوائل!';
	@override String get noSharedRecipes => 'لم تتم مشاركة وصفات بعد. شاركوا الأولى!';
	@override String get shareRecipe => 'مشاركة وصفة';
	@override String get pickRecipeToShare => 'أي وصفة تريدون مشاركتها؟';
	@override String get saveToMyRecipes => 'حفظ في وصفاتي';
	@override String get savedToMyRecipes => 'تم حفظ الوصفة';
	@override String get deletePost => 'حذف المنشور';
	@override String get deletePostConfirm => 'سيتم حذف المنشور وردوده نهائيًا.';
	@override String get unshare => 'إزالة المشاركة';
	@override String get unshareConfirm => 'ستتم إزالة الوصفة من الخلاصة المشتركة.';
	@override String byAuthor({required Object name}) => 'بواسطة ${name}';
	@override String get loadFailed => 'تعذّر تحميل المحتوى';
	@override String get allRecipes => 'كل الوصفات';
	@override String get myRecipes => 'وصفاتي';
	@override String get editShared => 'تعديل الوصفة المشتركة';
	@override String get sharedUpdated => 'تم تحديث الوصفة';
	@override String get noneOfMine => 'لم تشاركوا أي وصفات بعد';
	@override String get search => 'بحث';
	@override String get searchHint => 'اسم الوصفة أو الناشر';
	@override String get savedOnly => 'المحفوظة';
	@override String get noResults => 'لا توجد نتائج';
	@override String get attachRecipe => 'إرفاق وصفة';
	@override String get openRecipe => 'فتح الوصفة';
	@override String get recipeUnavailable => 'هذه الوصفة لم تعد متاحة';
	@override String get sortAndFilter => 'الترتيب والتصفية';
	@override String get sort => 'ترتيب';
	@override String get sortNewest => 'الأحدث';
	@override String get sortOldest => 'الأقدم';
	@override String get sortMostLiked => 'الأكثر إعجابًا';
	@override String get topics => 'المواضيع';
	@override String get likes => 'الإعجابات';
	@override String get anyLikes => 'الكل';
	@override String atLeastLikes({required Object count}) => '${count} فأكثر';
	@override String get totalTime => 'الوقت الإجمالي';
	@override String get anyTime => 'أي وقت';
	@override String upTo({required Object duration}) => 'حتى ${duration}';
	@override String get clearFilters => 'مسح التصفية';
	@override String get applyFilters => 'عرض النتائج';
	@override String likesPlus({required Object count}) => '${count}+';
	@override String durationPlus({required Object duration}) => '${duration}+';
	@override String get splitTimes => 'الفصل بين التحضير والطهي';
	@override String get alreadySaved => 'هذه الوصفة محفوظة لديكم بالفعل';
}

// Path: sharing
class _Translations$sharing$ar extends Translations$sharing$he {
	_Translations$sharing$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مشاركة الوصفة';
	@override String get contactLabel => 'بريد أو هاتف الشريك';
	@override String get contactHint => 'name@example.com أو 05…';
	@override String get roleTitle => 'الصلاحية';
	@override String get roleViewer => 'عرض فقط';
	@override String get roleViewerHint => 'يرى الوصفة ولا يمكنه تغييرها';
	@override String get roleEditor => 'تعديل';
	@override String get roleEditorHint => 'تعديلاته تظهر لديكم أيضًا';
	@override String get send => 'إرسال الدعوة';
	@override String get sent => 'تم إرسال الدعوة';
	@override String get invalidContact => 'أدخلوا بريدًا أو رقم هاتف صالحًا';
	@override String get notFound => 'لا يوجد حساب بهذه البيانات. تأكدوا أن البريد أو الهاتف مرتبط بحسابه/ها وأن التطبيق فُتح لديه/ها مؤخرًا.';
	@override String get self => 'لا يمكن مشاركة وصفة مع نفسك';
	@override String get failed => 'فشلت المشاركة، حاولوا مجددًا';
	@override String get pendingInvites => 'دعوات معلّقة';
	@override String get noPendingInvites => 'لا توجد دعوات معلّقة';
	@override String get sharedByMe => 'وصفات شاركتها';
	@override String get sharedWithMe => 'وصفات شُوركت معي';
	@override String get nothingSharedByMe => 'لم تشاركوا وصفات بعد';
	@override String get nothingSharedWithMe => 'لم تُشارك معكم وصفات بعد';
	@override String get accept => 'قبول';
	@override String get decline => 'رفض';
	@override String get accepted => 'أُضيفت الوصفة إلى وصفاتكم';
	@override String get declined => 'رُفضت الدعوة';
	@override String get acceptFailed => 'فشل القبول، حاولوا مجددًا';
	@override String get members => 'الشركاء';
	@override String get noMembersYet => 'لم يقبل أحد بعد';
	@override String get remove => 'إزالة';
	@override String get leave => 'مغادرة';
	@override String get removed => 'تمت إزالة الشريك';
	@override String get left => 'غادرتم المشاركة';
	@override String invitedBy({required Object name}) => 'من ${name}';
	@override String get sharedTag => 'مشتركة';
	@override String get viewerTag => 'عرض فقط';
	@override String get editorTag => 'محرّر';
	@override String get ownerTag => 'ملكي';
	@override String get syncFailed => 'تعذّر تحديث الوصفة المشتركة، تُعرض النسخة المحفوظة';
	@override String get viewerCannotEdit => 'هذه الوصفة مشتركة معكم للعرض فقط';
	@override String get shareAction => 'مشاركة';
	@override String get directoryUnavailable => 'المشاركة غير مهيّأة على الخادم بعد. سجّلوا الخروج والدخول مجددًا؛ وإن استمرّ الأمر فيجب نشر قواعد Firestore.';
}

// Path: notifications
class _Translations$notifications$ar extends Translations$notifications$he {
	_Translations$notifications$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الإشعارات';
	@override String get empty => 'لا توجد إشعارات';
	@override String sharedRecipe({required Object name, required Object recipe}) => 'شارك/ت ${name} معك "${recipe}"';
	@override String get asViewer => 'للعرض فقط';
	@override String get asEditor => 'للتعديل';
	@override String get markAllRead => 'تعليم الكل كمقروء';
	@override String get openRecipe => 'فتح الوصفة';
	@override String get alreadyHandled => 'تمت معالجة هذه الدعوة';
}

// Path: editor
class _Translations$editor$ar extends Translations$editor$he {
	_Translations$editor$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تعديل الوصفة';
	@override String get recipeTitle => 'اسم الوصفة';
	@override String get titleHint => 'مثال: شكشوكة القدس';
	@override String get topics => 'المواضيع';
	@override String get titleRequired => 'يجب إدخال اسم للوصفة';
	@override String get prepMinutes => 'وقت التحضير (دقيقة)';
	@override String get cookMinutes => 'وقت الطهي (دقيقة)';
	@override String get amount => 'الكمية';
	@override String get unit => 'الوحدة';
	@override String get ingredientName => 'اسم المكوّن';
	@override String get stepHint => 'صف الخطوة';
	@override String get addIngredient => 'إضافة مكوّن';
	@override String get addStep => 'إضافة خطوة';
	@override String get removeIngredient => 'إزالة المكوّن';
	@override String get removeStep => 'إزالة الخطوة';
	@override String get reorderStep => 'إعادة ترتيب الخطوة';
	@override String get fixSpelling => 'تصحيح الإملاء';
	@override String get refining => 'جارٍ تصحيح الوصفة...';
	@override String get refineError => 'تعذّر تصحيح الوصفة';
	@override String get spellingFixed => 'تم تصحيح الوصفة';
	@override String get noChanges => 'لم يتم العثور على أخطاء إملائية';
	@override String get timesSynced => 'تم تحديث الأوقات في خطوات التحضير';
	@override String get discardTitle => 'تجاهل التغييرات؟';
	@override String get discardBody => 'لن يتم حفظ تعديلاتك.';
	@override String get discard => 'تجاهل';
	@override String get saveOptionsTitle => 'كيف تريدون الحفظ؟';
	@override String get savePlainHint => 'حفظ التغييرات كما هي، بدون انتظار';
	@override String get saveWithAi => 'حفظ مع مراجعة AI';
	@override String get saveWithAiHint => 'تصحيح الإملاء ومطابقة الأوقات المذكورة في الخطوات';
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
	@override String get openOptionsTitle => 'كيف تريدون فتح الوصفة؟';
	@override String get viewOriginal => 'عرض الوصفة الأصلية';
	@override String get viewOriginalHint => 'النص كما هو في الموقع، بدون معالجة — يُحمَّل فورًا';
	@override String get generateStructured => 'إنشاء وصفة منظّمة';
	@override String get generateStructuredHint => 'استخراج تلقائي للمكوّنات والكميات والخطوات';
	@override String get originalTitle => 'الوصفة الأصلية';
	@override String get fetchFailed => 'تعذّر تحميل الصفحة';
	@override String get loadingOriginal => 'جارٍ تحميل الصفحة...';
	@override String get structuredFromSite => 'قُرئت مباشرة من البيانات المنظّمة للموقع، بدون AI';
	@override String get useStructured => 'المتابعة بالوصفة المنظّمة';
	@override String get preferAi => 'المعالجة عبر AI بدلًا من ذلك';
	@override String get analysisTimedOut => 'لم يكتمل التحليل في الوقت المحدد';
	@override String get analysisFailed => 'فشل التحليل';
	@override String get unparsedHint => 'تم حفظ النص كما هو. يمكنكم المحاولة مجددًا أو التعديل يدويًا أو الحفظ والتحليل لاحقًا.';
	@override String get retryAnalysis => 'محاولة أخرى';
	@override String get editManually => 'تعديل يدوي';
	@override String get saveForLater => 'حفظ وتحليل لاحقًا';
	@override String get untitledRecipe => 'وصفة بلا اسم';
	@override String get manual => 'كتابة يدوية';
	@override String get manualHint => 'املؤوا الوصفة بأنفسكم بالتنسيق المنظّم — بدون AI وبدون انتظار.';
	@override String get openBlankEditor => 'فتح محرّر فارغ';
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
	@override String get planFilter => 'كل القوائم';
	@override String get choosePlans => 'اختيار القوائم';
	@override String plansSelected({required Object count}) => 'تم اختيار ${count} قوائم';
	@override String get onePlanSelected => 'تم اختيار قائمة واحدة';
	@override String get noPlansToPick => 'لا توجد قوائم للاختيار بعد';
	@override String get allPlansHint => 'مجمّعة من كل القوائم';
	@override String get selectPlansTitle => 'أي القوائم تغذّي هذه اللائحة؟';
	@override String get applySelection => 'تحديث اللائحة';
	@override String get selectAllPlans => 'كل القوائم';
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

// Path: nav
class _Translations$nav$ar extends Translations$nav$he {
	_Translations$nav$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get library => 'المكتبة';
	@override String get recipes => 'الوصفات';
	@override String get mealPlan => 'الوجبات';
	@override String get groceries => 'التسوّق';
	@override String get settings => 'الإعدادات';
	@override String get community => 'المجتمع';
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
			'common.or' => 'أو',
			'common.missingInfo' => '[معلومات ناقصة]',
			'auth.welcome' => 'أهلًا بكم في EasyPlate',
			'auth.subtitle' => 'سجّلوا الدخول لحفظ وصفاتكم',
			'auth.signIn' => 'تسجيل الدخول',
			'auth.signUp' => 'إنشاء حساب',
			'auth.signOut' => 'تسجيل الخروج',
			'auth.email' => 'البريد الإلكتروني',
			'auth.emailHint' => 'name@example.com',
			'auth.password' => 'كلمة المرور',
			'auth.passwordHint' => '6 أحرف على الأقل',
			'auth.continueWithGoogle' => 'المتابعة عبر Google',
			'auth.continueWithPhone' => 'المتابعة عبر الهاتف',
			'auth.continueWithEmail' => 'المتابعة عبر البريد',
			'auth.phoneNumber' => 'رقم الهاتف',
			'auth.phoneHint' => '+972501234567',
			'auth.sendCode' => 'إرسال الرمز',
			'auth.smsCode' => 'رمز الرسالة',
			'auth.codeSentTo' => ({required Object phone}) => 'أرسلنا رمز تحقق إلى ${phone}',
			'auth.verify' => 'تحقق',
			'auth.resendCode' => 'إعادة الإرسال',
			'auth.forgotPassword' => 'نسيت كلمة المرور',
			'auth.resetSent' => 'تم إرسال بريد إعادة التعيين',
			'auth.noAccount' => 'لا يوجد حساب؟ سجّلوا',
			'auth.haveAccount' => 'لديكم حساب؟ ادخلوا',
			'auth.invalidEmail' => 'بريد إلكتروني غير صالح',
			'auth.passwordTooShort' => 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل',
			'auth.invalidPhone' => 'رقم هاتف غير صالح',
			'auth.codeRequired' => 'أدخلوا الرمز الذي وصلكم',
			'auth.errorUnauthorized' => 'البيانات المُدخلة غير صحيحة',
			'auth.errorNetwork' => 'لا يوجد اتصال بالإنترنت',
			'auth.errorUnknown' => 'فشل تسجيل الدخول، حاولوا مجددًا',
			'auth.signOutTitle' => 'تسجيل الخروج؟',
			'auth.signOutBody' => 'ستحتاجون إلى تسجيل الدخول مجددًا للوصول إلى وصفاتكم.',
			'auth.errorOperationNotAllowed' => 'طريقة تسجيل الدخول هذه غير متاحة حاليًا',
			'auth.errorTooManyRequests' => 'محاولات كثيرة. حاولوا بعد بضع دقائق',
			'auth.errorInvalidPhone' => 'رقم الهاتف غير صالح',
			'auth.errorEmailInUse' => 'البريد الإلكتروني مسجّل بالفعل',
			'auth.verifyEmailTitle' => 'تأكيد البريد الإلكتروني',
			'auth.verifyEmailBody' => ({required Object email}) => 'أرسلنا رابط تأكيد إلى ${email}. افتحوه ثم عودوا إلى هنا.',
			'auth.resendEmail' => 'إعادة إرسال الرابط',
			'auth.emailResent' => 'تم إرسال الرابط مجددًا',
			'auth.checkVerification' => 'لقد أكّدت',
			'auth.stillNotVerified' => 'لم يتم التأكيد بعد',
			'auth.linkPhone' => 'تأكيد الهاتف',
			'auth.phoneLinked' => 'تم تأكيد الهاتف',
			'auth.phoneAlreadyUsed' => 'هذا الرقم مرتبط بحساب آخر',
			'auth.emailAlreadyLinked' => 'الحساب مرتبط ببريد إلكتروني بالفعل',
			'auth.addEmailPassword' => 'إضافة بريد وكلمة مرور',
			'auth.verified' => 'مؤكَّد',
			'auth.linkGoogle' => 'ربط حساب Google',
			'auth.googleLinked' => 'مرتبط',
			'auth.googleAlreadyUsed' => 'حساب Google هذا مرتبط بمستخدم آخر',
			'auth.googleAlreadyLinked' => 'يوجد حساب Google مرتبط بالفعل',
			'auth.phoneGateTitle' => 'تأكيد رقم الهاتف',
			'auth.phoneGateBody' => 'كل حساب يتم تأكيده برقم هاتف. سنرسل لك رمزًا عبر رسالة نصية.',
			'auth.changeNumber' => 'تغيير الرقم',
			'auth.signInTitle' => 'تسجيل الدخول',
			'auth.phoneFirstHint' => 'جديد هنا؟ تابع باستخدام الهاتف.',
			'auth.errorAccountExistsDifferentCredential' => 'هذا البريد الإلكتروني يخص حسابًا آخر. سجّل الدخول بالطريقة التي سجّلت بها.',
			'auth.errorCredentialInUse' => 'هذه البيانات تخص حسابًا آخر بالفعل',
			'auth.continueWithApple' => 'المتابعة باستخدام Apple',
			'auth.linkApple' => 'ربط حساب Apple',
			'auth.appleLinked' => 'مرتبط',
			'auth.appleAlreadyUsed' => 'حساب Apple هذا مرتبط بمستخدم آخر',
			'auth.appleAlreadyLinked' => 'تم ربط حساب Apple بالفعل',
			'profile.setupTitle' => 'تفاصيل أخيرة',
			'profile.setupSubtitle' => 'لكي نعرف كيف نخاطبكم',
			'profile.fullName' => 'الاسم الكامل',
			'profile.fullNameHint' => 'محمد أحمد',
			'profile.fullNameRequired' => 'الاسم الكامل مطلوب',
			'profile.photo' => 'صورة الملف الشخصي',
			'profile.addPhoto' => 'إضافة صورة',
			'profile.phoneOptional' => 'الهاتف (اختياري)',
			'profile.emailOptional' => 'البريد (اختياري)',
			'profile.save' => 'إنهاء التسجيل',
			'profile.saving' => 'جارٍ الحفظ...',
			'profile.saveFailed' => 'تعذّر حفظ الملف الشخصي',
			'profile.myProfile' => 'ملفي الشخصي',
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
			'more.title' => 'المزيد',
			'more.settings' => 'الإعدادات',
			'more.profile' => 'ملفي الشخصي',
			'more.support' => 'الدعم',
			'more.supportTitle' => 'كيف يمكننا المساعدة؟',
			'more.supportBody' => 'اكتبوا لنا وسنعود إليكم قريبًا.',
			'more.whatsapp' => 'راسلونا على واتساب',
			'more.email' => 'إرسال بريد',
			'more.supportUnavailable' => 'تعذّر فتح التطبيق',
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
			'books.renameBook' => 'تعديل اسم الكتاب',
			'recipe.prepTime' => 'وقت التحضير',
			'recipe.cookTime' => 'وقت الطهي',
			'recipe.ingredients' => 'المكوّنات',
			'recipe.ingredientsCount' => ({required Object count}) => '${count} مكوّنات',
			'recipe.minutes' => ({required Object count}) => '${count} دقيقة',
			'recipe.hours' => ({required Object count}) => '${count} ساعة',
			'recipe.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours} ساعة و${minutes} دقيقة',
			'recipe.instructions' => 'طريقة التحضير',
			'recipe.addToBook' => 'إضافة إلى كتاب',
			'recipe.removeFromBook' => 'إزالة من الكتاب',
			'recipe.deleteRecipe' => 'حذف الوصفة',
			'recipe.photo' => 'صورة الوصفة',
			'recipe.mine' => 'وصفاتي',
			'recipe.saved' => 'وصفات محفوظة',
			'recipe.noneMine' => 'لم تنشئوا وصفات بعد',
			'recipe.noneSaved' => 'لم تحفظوا وصفات من المجتمع بعد',
			'recipe.pendingAnalysis' => 'بانتظار التحليل',
			'recipe.pendingAnalysisHint' => 'محفوظة كنص خام. حلّلوها الآن أو عدّلوها يدويًا.',
			'recipe.analyzeNow' => 'التحليل عبر AI الآن',
			'recipe.analyzing' => 'جارٍ تحليل الوصفة...',
			'recipe.analyzeFailed' => 'فشل التحليل — يمكنكم المحاولة لاحقًا',
			'community.title' => 'المجتمع',
			'community.forum' => 'المنتدى',
			'community.sharedRecipes' => 'وصفات مشتركة',
			'community.newPost' => 'منشور جديد',
			'community.postTitle' => 'العنوان',
			'community.postBody' => 'ما الذي تودّون سؤاله أو مشاركته؟',
			'community.postTitleRequired' => 'العنوان مطلوب',
			'community.postBodyRequired' => 'المحتوى مطلوب',
			'community.publish' => 'نشر',
			'community.replies' => ({required Object count}) => '${count} ردود',
			'community.noReplies' => 'لا توجد ردود بعد',
			'community.oneReply' => 'رد واحد',
			'community.writeReply' => 'اكتبوا ردًا...',
			'community.send' => 'إرسال',
			'community.noPosts' => 'لا توجد منشورات بعد. كونوا الأوائل!',
			'community.noSharedRecipes' => 'لم تتم مشاركة وصفات بعد. شاركوا الأولى!',
			'community.shareRecipe' => 'مشاركة وصفة',
			'community.pickRecipeToShare' => 'أي وصفة تريدون مشاركتها؟',
			'community.saveToMyRecipes' => 'حفظ في وصفاتي',
			'community.savedToMyRecipes' => 'تم حفظ الوصفة',
			'community.deletePost' => 'حذف المنشور',
			'community.deletePostConfirm' => 'سيتم حذف المنشور وردوده نهائيًا.',
			'community.unshare' => 'إزالة المشاركة',
			'community.unshareConfirm' => 'ستتم إزالة الوصفة من الخلاصة المشتركة.',
			'community.byAuthor' => ({required Object name}) => 'بواسطة ${name}',
			'community.loadFailed' => 'تعذّر تحميل المحتوى',
			'community.allRecipes' => 'كل الوصفات',
			'community.myRecipes' => 'وصفاتي',
			'community.editShared' => 'تعديل الوصفة المشتركة',
			'community.sharedUpdated' => 'تم تحديث الوصفة',
			'community.noneOfMine' => 'لم تشاركوا أي وصفات بعد',
			'community.search' => 'بحث',
			'community.searchHint' => 'اسم الوصفة أو الناشر',
			'community.savedOnly' => 'المحفوظة',
			'community.noResults' => 'لا توجد نتائج',
			'community.attachRecipe' => 'إرفاق وصفة',
			'community.openRecipe' => 'فتح الوصفة',
			'community.recipeUnavailable' => 'هذه الوصفة لم تعد متاحة',
			'community.sortAndFilter' => 'الترتيب والتصفية',
			'community.sort' => 'ترتيب',
			'community.sortNewest' => 'الأحدث',
			'community.sortOldest' => 'الأقدم',
			'community.sortMostLiked' => 'الأكثر إعجابًا',
			'community.topics' => 'المواضيع',
			'community.likes' => 'الإعجابات',
			'community.anyLikes' => 'الكل',
			'community.atLeastLikes' => ({required Object count}) => '${count} فأكثر',
			'community.totalTime' => 'الوقت الإجمالي',
			'community.anyTime' => 'أي وقت',
			'community.upTo' => ({required Object duration}) => 'حتى ${duration}',
			'community.clearFilters' => 'مسح التصفية',
			'community.applyFilters' => 'عرض النتائج',
			'community.likesPlus' => ({required Object count}) => '${count}+',
			'community.durationPlus' => ({required Object duration}) => '${duration}+',
			'community.splitTimes' => 'الفصل بين التحضير والطهي',
			'community.alreadySaved' => 'هذه الوصفة محفوظة لديكم بالفعل',
			'sharing.title' => 'مشاركة الوصفة',
			'sharing.contactLabel' => 'بريد أو هاتف الشريك',
			'sharing.contactHint' => 'name@example.com أو 05…',
			'sharing.roleTitle' => 'الصلاحية',
			'sharing.roleViewer' => 'عرض فقط',
			'sharing.roleViewerHint' => 'يرى الوصفة ولا يمكنه تغييرها',
			'sharing.roleEditor' => 'تعديل',
			'sharing.roleEditorHint' => 'تعديلاته تظهر لديكم أيضًا',
			'sharing.send' => 'إرسال الدعوة',
			'sharing.sent' => 'تم إرسال الدعوة',
			'sharing.invalidContact' => 'أدخلوا بريدًا أو رقم هاتف صالحًا',
			'sharing.notFound' => 'لا يوجد حساب بهذه البيانات. تأكدوا أن البريد أو الهاتف مرتبط بحسابه/ها وأن التطبيق فُتح لديه/ها مؤخرًا.',
			'sharing.self' => 'لا يمكن مشاركة وصفة مع نفسك',
			'sharing.failed' => 'فشلت المشاركة، حاولوا مجددًا',
			'sharing.pendingInvites' => 'دعوات معلّقة',
			'sharing.noPendingInvites' => 'لا توجد دعوات معلّقة',
			'sharing.sharedByMe' => 'وصفات شاركتها',
			'sharing.sharedWithMe' => 'وصفات شُوركت معي',
			'sharing.nothingSharedByMe' => 'لم تشاركوا وصفات بعد',
			'sharing.nothingSharedWithMe' => 'لم تُشارك معكم وصفات بعد',
			'sharing.accept' => 'قبول',
			'sharing.decline' => 'رفض',
			'sharing.accepted' => 'أُضيفت الوصفة إلى وصفاتكم',
			'sharing.declined' => 'رُفضت الدعوة',
			'sharing.acceptFailed' => 'فشل القبول، حاولوا مجددًا',
			'sharing.members' => 'الشركاء',
			'sharing.noMembersYet' => 'لم يقبل أحد بعد',
			'sharing.remove' => 'إزالة',
			'sharing.leave' => 'مغادرة',
			'sharing.removed' => 'تمت إزالة الشريك',
			'sharing.left' => 'غادرتم المشاركة',
			'sharing.invitedBy' => ({required Object name}) => 'من ${name}',
			'sharing.sharedTag' => 'مشتركة',
			'sharing.viewerTag' => 'عرض فقط',
			'sharing.editorTag' => 'محرّر',
			'sharing.ownerTag' => 'ملكي',
			'sharing.syncFailed' => 'تعذّر تحديث الوصفة المشتركة، تُعرض النسخة المحفوظة',
			'sharing.viewerCannotEdit' => 'هذه الوصفة مشتركة معكم للعرض فقط',
			'sharing.shareAction' => 'مشاركة',
			'sharing.directoryUnavailable' => 'المشاركة غير مهيّأة على الخادم بعد. سجّلوا الخروج والدخول مجددًا؛ وإن استمرّ الأمر فيجب نشر قواعد Firestore.',
			'notifications.title' => 'الإشعارات',
			'notifications.empty' => 'لا توجد إشعارات',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => 'شارك/ت ${name} معك "${recipe}"',
			'notifications.asViewer' => 'للعرض فقط',
			'notifications.asEditor' => 'للتعديل',
			'notifications.markAllRead' => 'تعليم الكل كمقروء',
			'notifications.openRecipe' => 'فتح الوصفة',
			'notifications.alreadyHandled' => 'تمت معالجة هذه الدعوة',
			'editor.title' => 'تعديل الوصفة',
			'editor.recipeTitle' => 'اسم الوصفة',
			'editor.titleHint' => 'مثال: شكشوكة القدس',
			'editor.topics' => 'المواضيع',
			'editor.titleRequired' => 'يجب إدخال اسم للوصفة',
			'editor.prepMinutes' => 'وقت التحضير (دقيقة)',
			'editor.cookMinutes' => 'وقت الطهي (دقيقة)',
			'editor.amount' => 'الكمية',
			'editor.unit' => 'الوحدة',
			'editor.ingredientName' => 'اسم المكوّن',
			'editor.stepHint' => 'صف الخطوة',
			'editor.addIngredient' => 'إضافة مكوّن',
			'editor.addStep' => 'إضافة خطوة',
			'editor.removeIngredient' => 'إزالة المكوّن',
			'editor.removeStep' => 'إزالة الخطوة',
			'editor.reorderStep' => 'إعادة ترتيب الخطوة',
			'editor.fixSpelling' => 'تصحيح الإملاء',
			'editor.refining' => 'جارٍ تصحيح الوصفة...',
			'editor.refineError' => 'تعذّر تصحيح الوصفة',
			'editor.spellingFixed' => 'تم تصحيح الوصفة',
			'editor.noChanges' => 'لم يتم العثور على أخطاء إملائية',
			'editor.timesSynced' => 'تم تحديث الأوقات في خطوات التحضير',
			'editor.discardTitle' => 'تجاهل التغييرات؟',
			'editor.discardBody' => 'لن يتم حفظ تعديلاتك.',
			'editor.discard' => 'تجاهل',
			'editor.saveOptionsTitle' => 'كيف تريدون الحفظ؟',
			'editor.savePlainHint' => 'حفظ التغييرات كما هي، بدون انتظار',
			'editor.saveWithAi' => 'حفظ مع مراجعة AI',
			'editor.saveWithAiHint' => 'تصحيح الإملاء ومطابقة الأوقات المذكورة في الخطوات',
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
			'ingestion.openOptionsTitle' => 'كيف تريدون فتح الوصفة؟',
			'ingestion.viewOriginal' => 'عرض الوصفة الأصلية',
			'ingestion.viewOriginalHint' => 'النص كما هو في الموقع، بدون معالجة — يُحمَّل فورًا',
			'ingestion.generateStructured' => 'إنشاء وصفة منظّمة',
			'ingestion.generateStructuredHint' => 'استخراج تلقائي للمكوّنات والكميات والخطوات',
			'ingestion.originalTitle' => 'الوصفة الأصلية',
			'ingestion.fetchFailed' => 'تعذّر تحميل الصفحة',
			'ingestion.loadingOriginal' => 'جارٍ تحميل الصفحة...',
			'ingestion.structuredFromSite' => 'قُرئت مباشرة من البيانات المنظّمة للموقع، بدون AI',
			'ingestion.useStructured' => 'المتابعة بالوصفة المنظّمة',
			'ingestion.preferAi' => 'المعالجة عبر AI بدلًا من ذلك',
			'ingestion.analysisTimedOut' => 'لم يكتمل التحليل في الوقت المحدد',
			'ingestion.analysisFailed' => 'فشل التحليل',
			'ingestion.unparsedHint' => 'تم حفظ النص كما هو. يمكنكم المحاولة مجددًا أو التعديل يدويًا أو الحفظ والتحليل لاحقًا.',
			'ingestion.retryAnalysis' => 'محاولة أخرى',
			'ingestion.editManually' => 'تعديل يدوي',
			'ingestion.saveForLater' => 'حفظ وتحليل لاحقًا',
			'ingestion.untitledRecipe' => 'وصفة بلا اسم',
			'ingestion.manual' => 'كتابة يدوية',
			'ingestion.manualHint' => 'املؤوا الوصفة بأنفسكم بالتنسيق المنظّم — بدون AI وبدون انتظار.',
			'ingestion.openBlankEditor' => 'فتح محرّر فارغ',
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
			'groceryList.planFilter' => 'كل القوائم',
			'groceryList.choosePlans' => 'اختيار القوائم',
			'groceryList.plansSelected' => ({required Object count}) => 'تم اختيار ${count} قوائم',
			'groceryList.onePlanSelected' => 'تم اختيار قائمة واحدة',
			'groceryList.noPlansToPick' => 'لا توجد قوائم للاختيار بعد',
			'groceryList.allPlansHint' => 'مجمّعة من كل القوائم',
			'groceryList.selectPlansTitle' => 'أي القوائم تغذّي هذه اللائحة؟',
			'groceryList.applySelection' => 'تحديث اللائحة',
			'groceryList.selectAllPlans' => 'كل القوائم',
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
			'nav.library' => 'المكتبة',
			'nav.recipes' => 'الوصفات',
			'nav.mealPlan' => 'الوجبات',
			'nav.groceries' => 'التسوّق',
			'nav.settings' => 'الإعدادات',
			'nav.community' => 'المجتمع',
			_ => null,
		};
	}
}
