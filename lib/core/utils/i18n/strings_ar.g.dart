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
	@override String get appName => 'Easy Plate';
	@override late final _Translations$common$ar common = _Translations$common$ar._(_root);
	@override late final _Translations$auth$ar auth = _Translations$auth$ar._(_root);
	@override late final _Translations$profile$ar profile = _Translations$profile$ar._(_root);
	@override late final _Translations$onboarding$ar onboarding = _Translations$onboarding$ar._(_root);
	@override late final _Translations$dietary$ar dietary = _Translations$dietary$ar._(_root);
	@override late final _Translations$allergens$ar allergens = _Translations$allergens$ar._(_root);
	@override late final _Translations$weekday$ar weekday = _Translations$weekday$ar._(_root);
	@override late final _Translations$settings$ar settings = _Translations$settings$ar._(_root);
	@override late final _Translations$notificationSettings$ar notificationSettings = _Translations$notificationSettings$ar._(_root);
	@override late final _Translations$preferences$ar preferences = _Translations$preferences$ar._(_root);
	@override late final _Translations$more$ar more = _Translations$more$ar._(_root);
	@override late final _Translations$language$ar language = _Translations$language$ar._(_root);
	@override late final _Translations$books$ar books = _Translations$books$ar._(_root);
	@override late final _Translations$recipe$ar recipe = _Translations$recipe$ar._(_root);
	@override late final _Translations$cookMode$ar cookMode = _Translations$cookMode$ar._(_root);
	@override late final _Translations$nutrition$ar nutrition = _Translations$nutrition$ar._(_root);
	@override late final _Translations$community$ar community = _Translations$community$ar._(_root);
	@override late final _Translations$sharing$ar sharing = _Translations$sharing$ar._(_root);
	@override late final _Translations$notifications$ar notifications = _Translations$notifications$ar._(_root);
	@override late final _Translations$editor$ar editor = _Translations$editor$ar._(_root);
	@override late final _Translations$ingestion$ar ingestion = _Translations$ingestion$ar._(_root);
	@override late final _Translations$mealPlanner$ar mealPlanner = _Translations$mealPlanner$ar._(_root);
	@override late final _Translations$groceryList$ar groceryList = _Translations$groceryList$ar._(_root);
	@override late final _Translations$receipt$ar receipt = _Translations$receipt$ar._(_root);
	@override late final _Translations$unit$ar unit = _Translations$unit$ar._(_root);
	@override late final _Translations$image$ar image = _Translations$image$ar._(_root);
	@override late final _Translations$nav$ar nav = _Translations$nav$ar._(_root);
	@override late final _Translations$update$ar update = _Translations$update$ar._(_root);
	@override late final _Translations$ads$ar ads = _Translations$ads$ar._(_root);
	@override late final _Translations$premium$ar premium = _Translations$premium$ar._(_root);
	@override late final _Translations$walkthrough$ar walkthrough = _Translations$walkthrough$ar._(_root);
	@override late final _Translations$feedback$ar feedback = _Translations$feedback$ar._(_root);
	@override late final _Translations$adminBilling$ar adminBilling = _Translations$adminBilling$ar._(_root);
	@override late final _Translations$adminDashboard$ar adminDashboard = _Translations$adminDashboard$ar._(_root);
	@override late final _Translations$assistant$ar assistant = _Translations$assistant$ar._(_root);
	@override late final _Translations$shareCode$ar shareCode = _Translations$shareCode$ar._(_root);
	@override late final _Translations$household$ar household = _Translations$household$ar._(_root);
	@override late final _Translations$homeWidgets$ar homeWidgets = _Translations$homeWidgets$ar._(_root);
	@override late final _Translations$feature$ar feature = _Translations$feature$ar._(_root);
	@override late final _Translations$featureName$ar featureName = _Translations$featureName$ar._(_root);
}

// Path: common
class _Translations$common$ar extends Translations$common$he {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get save => 'حفظ';
	@override String get cancel => 'إلغاء';
	@override String get ok => 'حسناً';
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
	@override String get networkError => 'لا يوجد اتصال بالإنترنت';
	@override String get landscapeHint => 'يفضّل العمل بالوضع الأفقي';
	@override String get rotateLandscape => 'تدوير';
	@override String get rotatePortrait => 'العودة للوضع الرأسي';
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
	@override String get blockedTitle => 'تم حظر الحساب';
	@override String get blockedBody => 'تم حظر هذا الحساب من قِبل مدير التطبيق. للتفاصيل تواصل معنا من شاشة الدعم.';
	@override String get phoneClaimedTitle => 'هذا الرقم تابع لحساب موجود';
	@override String phoneClaimedBody({required Object phone}) => 'الرقم ${phone} مرتبط بالفعل بحساب EasyPlate آخر. للوصول إلى ذلك الحساب ووصفاته، سجّل الدخول بالطريقة التي استخدمتها سابقًا (Google أو Apple أو البريد) وتحقّق من الرقم هناك مجددًا.';
	@override String get phoneClaimedSignIn => 'الدخول إلى حسابي الموجود';
	@override String get phoneClaimedCreateNew => 'إنشاء حساب جديد على أي حال';
	@override String get phoneClaimedCreateNewConfirm => 'سيُفتح حساب جديد فارغ لهذا الرقم. يبقى الحساب الموجود كما هو، لكن لن يمكن الوصول إليه بهذا الرقم بعد الآن.';
	@override String get sessionOtherDeviceTitle => 'الحساب مسجّل الدخول على جهاز آخر';
	@override String sessionOtherDeviceBody({required Object platform, required Object since}) => 'هذا الحساب مفتوح الآن على ${platform}${since}. يمكن استخدامه على جهاز واحد في كل مرة: سجّل الخروج هناك ثم اضغط «حاول مجددًا».';
	@override String sessionSince({required Object date}) => ' منذ ${date}';
	@override String get sessionExpiredTitle => 'انتهت صلاحية تسجيل الدخول';
	@override String get sessionExpiredBody => 'يستمر تسجيل الدخول حتى شهر. سجّل الدخول من جديد للمتابعة.';
	@override String get sessionRetry => 'حاول مجددًا';
	@override String get platformIos => 'آيفون';
	@override String get platformAndroid => 'هاتف أندرويد';
	@override String get platformOther => 'جهاز آخر';
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

// Path: allergens
class _Translations$allergens$ar extends Translations$allergens$he {
	_Translations$allergens$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مسببات الحساسية';
	@override String get pick => 'تحديد مسببات الحساسية';
	@override String get contains => 'يحتوي على';
	@override String get mayContain => 'قد يحتوي على';
	@override String get gluten => 'غلوتين';
	@override String get milk => 'حليب';
	@override String get eggs => 'بيض';
	@override String get fish => 'سمك';
	@override String get shellfish => 'مأكولات بحرية';
	@override String get peanuts => 'فول سوداني';
	@override String get treeNuts => 'مكسرات';
	@override String get sesame => 'سمسم';
	@override String get soy => 'صويا';
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
	@override String get appearance => 'المظهر';
	@override String get themeSystem => 'حسب الجهاز';
	@override String get themeLight => 'فاتح';
	@override String get themeDark => 'داكن';
	@override String get soundEffects => 'المؤثرات الصوتية (تقليب الصفحات)';
	@override String get fastPageTurn => 'تصفّح سريع في الكتاب';
	@override String get fastPageTurnHint => 'القفز من جدول المحتويات أو التنقل السريع يقلّب صفحة واحدة فقط إلى الوجهة. أوقفه لتقليب كل الصفحات في الطريق.';
	@override String get sharedAccess => 'إدارة المشاركة';
	@override String get noSharedAccess => 'لم تشارك أي كتب أو قوائم بعد';
	@override String get communityPrices => 'متوسط أسعار المستخدمين';
	@override String get communityPricesHint => 'عندما لا يكون لديك سعر خاص بمنتج، اعرض السعر الوسيط الذي شاركه الآخرون';
	@override String get shoppingReminders => 'تذكيرات يوم التسوق';
	@override String get shoppingRemindersHint => 'تُرسل من الجهاز حسب يوم التسوق المختار';
	@override String get reminderTwoDaysBefore => 'قبل يومين (مساءً)';
	@override String get reminderDayBefore => 'قبل يوم (مساءً)';
	@override String get reminderSameDayMorning => 'يوم التسوق (صباحًا)';
	@override String get reminderSameDayAfternoon => 'يوم التسوق (بعد الظهر)';
	@override String get translatingContent => 'جارٍ ترجمة وصفاتك وقوائمك…';
	@override String translatedContent({required Object count}) => 'تمت ترجمة ${count} عناصر';
	@override String get translationPartialTitle => 'الترجمة لم تكتمل';
	@override String translationPartial({required Object count}) => 'بقي ${count} عناصر بلغتها الأصلية. يمكن المحاولة لاحقًا.';
	@override String get translationFailed => 'فشلت الترجمة. بقي المحتوى بلغته الأصلية.';
	@override String get account => 'الحساب';
	@override String get notifications => 'الإشعارات';
	@override String get notificationsHint => 'أي التنبيهات تصلك، وكيف';
	@override String get settingsHint => 'الحساب، الإشعارات، اللغة والمظهر';
	@override String get dangerZone => 'منطقة الخطر';
	@override String get deleteAccount => 'حذف الحساب';
	@override String get deleteAccountHint => 'حذف الحساب وكل ما فيه نهائياً';
	@override String get deleteAccountTitle => 'حذف الحساب نهائياً؟';
	@override String get deleteAccountBody => 'سيُحذف حسابك ووصفاتك وكتبك وخطط وجباتك وقوائم التسوق والإيصالات والصور والمنشورات والردود نهائياً من خوادمنا ومن هذا الجهاز ولا يمكن استرجاعها. ما شاركته سيُزال أيضاً ممن شاركتهم إياه. الاشتراك النشط لا يُلغى تلقائياً: ألغِه من App Store أو Google Play.';
	@override String get deleteAccountConfirm => 'حذف نهائي';
	@override String get deletingAccount => 'جارٍ حذف الحساب…';
	@override String get deleteAccountFailed => 'فشل حذف الحساب. حاول مرة أخرى أو راسلنا على support@aieasyplate.app.';
	@override String get deleteAccountHousehold => 'أنت مالك أسرة مشتركة. أغلقها أولاً من شاشة "الأسرة" ثم حاول مرة أخرى.';
}

// Path: notificationSettings
class _Translations$notificationSettings$ar extends Translations$notificationSettings$he {
	_Translations$notificationSettings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إعدادات الإشعارات';
	@override String get push => 'الإشعارات الفورية';
	@override String get pushHint => 'تنبيهات على هذا الجهاز. عند الإيقاف لا يُرسل شيء إلى الهاتف؛ يستمر صندوق الإشعارات بالامتلاء.';
	@override String get pushDenied => 'إشعارات EasyPlate محظورة في إعدادات الجهاز. اسمح بها هناك لتلقي التنبيهات.';
	@override String get community => 'المجتمع';
	@override String get repliesOnMyPosts => 'الردود على منشوراتي';
	@override String get repliesOnMyPostsHint => 'أجاب أحدهم في نقاش فتحته';
	@override String get repliesOnThreads => 'الردود في نقاشات شاركت فيها';
	@override String get repliesOnThreadsHint => 'رد جديد في نقاش رددت فيه';
	@override String get sharing => 'المشاركة';
	@override String get shareInvites => 'دعوات المشاركة';
	@override String get shareInvitesHint => 'شارك أحدهم معك وصفة أو كتابًا أو خطة. تصل الدعوة دائمًا إلى الصندوق؛ هذا هو التنبيه فقط.';
	@override String get sharedRecipeUpdates => 'تحديثات الوصفات المحفوظة';
	@override String get sharedRecipeUpdatesHint => 'غيّر الكاتب وصفة من المجتمع حفظتها';
	@override String get easyPlate => 'من EasyPlate';
	@override String get adminReplies => 'الردود على رسائل الدعم الخاصة بي';
	@override String get announcements => 'الإعلانات';
	@override String get announcementsHint => 'أخبار وتحديثات من فريق EasyPlate';
	@override String get inApp => 'أثناء فتح التطبيق';
	@override String get foregroundPopups => 'عرض التنبيهات كنافذة منبثقة';
	@override String get foregroundPopupsHint => 'التنبيه الذي يصل أثناء وجودك في التطبيق يفتح بطاقة صغيرة. عند الإيقاف يذهب إلى الصندوق فقط.';
	@override String get reminders => 'تذكيرات التسوق';
}

// Path: preferences
class _Translations$preferences$ar extends Translations$preferences$he {
	_Translations$preferences$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'التفضيلات';
	@override String get hint => 'التسوق، الاحتياجات الغذائية وسلوك الكتب';
	@override String get shopping => 'التسوق';
	@override String get books => 'كتب الوصفات';
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
	@override String get preferences => 'التفضيلات';
	@override String get help => 'الدعم والمعلومات';
	@override String get helpHint => 'الدعم وسياسة الخصوصية وشروط الخدمة';
	@override String get legal => 'معلومات قانونية';
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
	@override String get spineColor => 'لون الكعب';
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
	@override String get communityUpdateTitle => 'هذه الوصفة مشاركة';
	@override String get communityUpdateBody => 'تحديث نسخة المجتمع أيضًا، أم نسختك فقط؟';
	@override String get communityUpdateBoth => 'المجتمع أيضًا';
	@override String get communityUpdateLocal => 'نسختي فقط';
	@override String get communityUpdated => 'تم تحديث نسخة المجتمع';
	@override String get communityGone => 'الوصفة لم تعد في المجتمع، حُفظت لك فقط';
}

// Path: cookMode
class _Translations$cookMode$ar extends Translations$cookMode$he {
	_Translations$cookMode$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'وضع الطبخ';
	@override String get start => 'ابدأ الطبخ';
	@override String stepOf({required Object n, required Object total}) => 'الخطوة ${n} من ${total}';
	@override String get ingredients => 'المكوّنات';
	@override String get inThisStep => 'في هذه الخطوة';
	@override String get timer => 'مؤقّت';
	@override String get startTimer => 'تشغيل المؤقّت';
	@override String get pause => 'إيقاف مؤقت';
	@override String get resume => 'متابعة';
	@override String get reset => 'إعادة ضبط';
	@override String get timeUp => 'انتهى الوقت!';
	@override String get next => 'الخطوة التالية';
	@override String get previous => 'السابقة';
	@override String get finish => 'انتهيت من الطبخ';
	@override String get finishedTitle => 'بالهناء والشفاء!';
	@override String get finishedBody => 'اكتملت كل الخطوات. يمكن للشاشة أن تنطفئ الآن.';
	@override String get screenOn => 'تبقى الشاشة مضاءة أثناء الطبخ';
	@override String get noSteps => 'لا توجد خطوات لهذه الوصفة بعد';
	@override String runningOnStep({required Object n}) => 'المؤقّت يعمل في الخطوة ${n}';
	@override String get inProgress => 'الطبخ قيد التنفيذ';
	@override String inProgressBody({required Object recipe, required Object n, required Object total}) => '"${recipe}" · الخطوة ${n} من ${total}';
	@override String get resumeCooking => 'متابعة';
	@override String get endCooking => 'إنهاء';
	@override String stepLabel({required Object n}) => 'الخطوة ${n}';
	@override String ongoingBody({required Object time, required Object total, required Object n}) => 'ينتهي في ${time} · ${total} · الخطوة ${n}';
	@override String timeUpBody({required Object n}) => 'الخطوة ${n}: انتهى الوقت';
	@override String get runningTimers => 'مؤقّتات تعمل';
	@override String get premiumOnly => 'وضع الطبخ جزء من EasyPlate Premium';
}

// Path: nutrition
class _Translations$nutrition$ar extends Translations$nutrition$he {
	_Translations$nutrition$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'القيم الغذائية';
	@override String get perServing => 'للحصة';
	@override String get perServingHint => 'جميع القيم لحصة واحدة. اتركه فارغًا لإزالة التقدير.';
	@override String get servings => 'حصص';
	@override String servingsCount({required Object count}) => '${count} حصص';
	@override String get calories => 'سعرات حرارية';
	@override String get kcal => 'سعرة';
	@override String get protein => 'بروتين';
	@override String get carbs => 'كربوهيدرات';
	@override String get fat => 'دهون';
	@override String get gramsShort => 'غ';
	@override String get estimate => 'تقدير بالذكاء الاصطناعي';
	@override String get estimating => 'جارٍ تقدير القيم الغذائية…';
	@override String get estimateFailed => 'فشل التقدير، حاول مرة أخرى';
	@override String get none => 'لا توجد قيم غذائية لهذه الوصفة بعد';
	@override String get noneHint => 'يمكن للذكاء الاصطناعي تقدير السعرات والبروتين والكربوهيدرات والدهون من قائمة المكونات';
	@override String get estimated => 'تم تحديث القيم الغذائية';
	@override String get editorServings => 'عدد الحصص';
	@override String get editorCalories => 'سعرات لكل حصة';
	@override String get editorProtein => 'بروتين (غ)';
	@override String get editorCarbs => 'كربوهيدرات (غ)';
	@override String get editorFat => 'دهون (غ)';
	@override String get dashboard => 'لوحة التغذية';
	@override String get weekly => 'هذا الأسبوع';
	@override String get today => 'اليوم';
	@override String get dayTotal => 'إجمالي اليوم';
	@override String get weekTotal => 'إجمالي الأسبوع';
	@override String get dailyAverage => 'المتوسط لكل يوم مخطط';
	@override String get perMeal => 'حسب الوجبة';
	@override String get perDay => 'حسب اليوم';
	@override String get noPlanned => 'لم يتم التخطيط لوجبات بوصفات بعد';
	@override String missingCount({required Object count}) => '${count} عناصر بدون قيم غذائية';
	@override String get macroSplit => 'توزيع السعرات';
	@override String get kcalPerDay => 'سعرة في اليوم';
	@override String get openDashboard => 'اللوحة الأسبوعية';
	@override String get perRecipe => 'الوصفة كاملة';
	@override String perRecipeServings({required Object count}) => '${count} حصص';
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
	@override String get savedTag => 'محفوظة لديك';
	@override String get removeSaved => 'إزالة من الوصفات المحفوظة';
	@override String get removeSavedConfirm => 'ستُزال الوصفة من وصفاتك المحفوظة. يمكنك حفظها مجدداً من المجتمع.';
	@override String get oneNewPost => 'منشور جديد واحد';
	@override String newPosts({required Object count}) => '${count} منشورات جديدة';
	@override String get replyFailed => 'تعذّر إرسال ردك';
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
	@override String get self => 'لا يمكنك المشاركة مع نفسك';
	@override String get failed => 'فشلت المشاركة، حاولوا مجددًا';
	@override String get pendingInvites => 'دعوات معلّقة';
	@override String get noPendingInvites => 'لا توجد دعوات معلّقة';
	@override String get sharedByMe => 'ما شاركته';
	@override String get sharedWithMe => 'ما تمت مشاركته معي';
	@override String get nothingSharedByMe => 'لم تشارك أي شيء بعد';
	@override String get nothingSharedWithMe => 'لم تتم مشاركة أي شيء معك بعد';
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
	@override String get shareBook => 'مشاركة الكتاب';
	@override String get sharePlan => 'مشاركة الخطة';
	@override String get acceptedBook => 'تمت إضافة الكتاب إلى مكتبتك';
	@override String get acceptedPlan => 'تمت إضافة الخطة إلى خططك';
	@override String get viewerCannotEditBook => 'تمت مشاركة هذا الكتاب معك للعرض فقط';
	@override String get viewerCannotEditPlan => 'تمت مشاركة هذه الخطة معك للعرض فقط';
	@override String get kindRecipe => 'وصفة';
	@override String get kindBook => 'كتاب';
	@override String get kindPlan => 'خطة';
	@override String get recipesTravel => 'ستتم مشاركة الوصفات الموجودة بداخله معه';
	@override String get shareList => 'مشاركة قائمة التسوق';
	@override String get acceptedList => 'أُضيفت القائمة إلى قوائم التسوق لديك';
	@override String get viewerCannotEditList => 'هذه القائمة مشاركة معك للعرض فقط';
	@override String get kindList => 'قائمة تسوق';
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
	@override String recipeUpdated({required Object name, required Object recipe}) => '${name} حدّث/ت "${recipe}"';
	@override String get recipeUpdatedHint => 'هناك نسخة جديدة من وصفة حفظتها';
	@override String get refreshCopy => 'التحديث للنسخة الجديدة';
	@override String get keepCopy => 'الاحتفاظ بنسختي';
	@override String get refreshed => 'تم تحديث نسختك إلى الجديدة';
	@override String get keptCopy => 'بقيت نسختك كما هي';
	@override String get recipeGone => 'الوصفة لم تعد في المجتمع';
	@override String get deleteAll => 'حذف كل الإشعارات';
	@override String get deleteAllBody => 'ستُحذف كل الإشعارات.';
	@override String get openInbox => 'فتح الإشعارات';
	@override String sharedBook({required Object name, required Object recipe}) => '${name} شارك/ت معك الكتاب "${recipe}"';
	@override String sharedPlan({required Object name, required Object recipe}) => '${name} شارك/ت معك الخطة "${recipe}"';
	@override String get adminReply => 'رد من فريق EasyPlate على رسالتك';
	@override String adminReplyQuote({required Object excerpt}) => 'رسالتك: "${excerpt}"';
	@override String get adminMessage => 'رسالة من EasyPlate';
	@override String forumReplyOnMyPost({required Object name, required Object post}) => 'ردّ ${name} على منشورك "${post}"';
	@override String forumReplyOnThread({required Object name, required Object post}) => 'ردّ ${name} في "${post}"';
	@override String get openThread => 'فتح النقاش';
	@override String get threadGone => 'تم حذف هذا النقاش';
	@override String get settings => 'الإعدادات';
	@override String sharedList({required Object name, required Object recipe}) => '${name} شارك/ت معك قائمة التسوق "${recipe}"';
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
	@override String get socialVideo => 'فيديو من الشبكات';
	@override String get socialVideoHint => 'الصق رابط فيديو من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك';
	@override String get socialUnreadable => 'تعذّرت قراءة هذا الفيديو. قد يكون الحساب خاصًا أو حظرت المنصة الطلب. يمكنك نسخ الوصف ولصقه كنص.';
	@override String get aiRequest => 'طلب وصفة';
	@override String get aiRequestHint => 'صِف ما تريد تحضيره. مثلاً: عصيدة سميد لطفلة بعمر سنة مع الفواكه';
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
	@override String get generate => 'إنشاء وصفة';
	@override String get generating => 'جارٍ كتابة الوصفة...';
	@override String get file => 'تسجيل / PDF';
	@override String get fileHint => 'يمكنك أيضًا مشاركة تسجيل أو PDF مباشرةً إلى Easy Plate من أي تطبيق عبر زر المشاركة المعتاد.';
	@override String get chooseFile => 'اختيار ملف';
	@override String get replaceFile => 'ملف آخر';
	@override String get fileTooLarge => 'الملفات كبيرة جدًا. الحد الإجمالي هو 10MB، نحو عشر دقائق من التسجيل.';
	@override String get fileUnsupported => 'يمكن تحليل ملفات الصوت وملفات PDF فقط.';
	@override String sharedIn({required Object app}) => 'من ${app}';
	@override String get addFile => 'إضافة ملف';
	@override String filesAsOne({required Object count}) => '${count} ملفات — تُحلَّل معًا كوصفة واحدة، بالترتيب';
	@override String get shareMoreHint => 'يمكنك العودة إلى واتساب ومشاركة تسجيل آخر — سينضم إلى القائمة هنا.';
	@override String get chooseSource => 'من أين تأتي الوصفة؟';
	@override String get pasteTextDescription => 'وصلتك وصفة على واتساب أو نسختها من موقع أو رسالة؟ الصق النص هنا كما هو. سيتعرّف النموذج على اسم الطبق والمكوّنات بكمياتها وخطوات التحضير، ويرتّب كل شيء بصيغة موحّدة. بلا حدّ يومي.';
	@override String get webSearchDescription => 'اكتب ما تشتهي تحضيره وسنبحث لك عن وصفات في الإنترنت. من النتائج يمكنك قراءة الوصفة الأصلية كما هي، أو استيرادها إلى الصيغة المنظّمة في التطبيق.';
	@override String get webSearchHint => 'مثلًا: شكشوكة، كعكة الجبن، كبة شمندر';
	@override String get urlScrapeDescription => 'الصق رابطًا لصفحة وصفة في موقع أو مدونة. سنقرأ الصفحة ونتجاهل الإعلانات والقصص حولها، ونستخرج الوصفة فقط: المكوّنات والكميات والخطوات. في مواقع كثيرة لا يستهلك هذا حتى من حصّتك اليومية.';
	@override String get urlScrapeHint => 'https://www.example.com/recipe/...';
	@override String get socialVideoDescription => 'الصق رابط فيديو من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك. سنشاهد الفيديو عنك ونستمع لما يُقال ونقرأ الترجمة والوصف، ونحوّله إلى وصفة مكتوبة ومرتّبة. يستغرق ذلك نحو دقيقة.';
	@override String get aiRequestDescription => 'ليست لديك وصفة، فقط فكرة؟ صِف الطبق ولمن هو وما يهمّك، وسيكتب لك النموذج وصفة كاملة وفق التفضيلات الغذائية التي حدّدتها.';
	@override String get manualDescription => 'اكتب الوصفة بنفسك مباشرة في المحرّر المنظّم: الاسم، المكوّنات بكمياتها ووحداتها، وخطوات التحضير. بلا ذكاء اصطناعي وبلا انتظار. مناسب لوصفة الجدّة التي تحفظها عن ظهر قلب.';
	@override String get fileDescription => 'اختر ملفًا صوتيًا يقرأ فيه أحدهم الوصفة أو يرويها، أو رسالة صوتية من واتساب، أو ملف PDF لوصفة. سنفرّغ ونقرأ كل شيء ونستخرج وصفة مرتّبة. يمكن إرفاق عدة ملفات وتُحلَّل معًا كوصفة واحدة.';
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
	@override String get planOptions => 'خيارات الخطة';
	@override String get deletePlan => 'حذف الخطة';
	@override String deletePlanConfirm({required Object name}) => 'حذف الخطة "${name}"؟ ستُحذف وجباتها أيضاً.';
	@override String leavePlanConfirm({required Object name}) => 'مغادرة الخطة المشتركة "${name}"؟ ستُزال من قائمتك.';
	@override String get planDeleted => 'تم حذف الخطة';
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
	@override String get myLists => 'قوائمي';
	@override String listsCount({required Object count}) => '${count} قوائم';
	@override String get oneList => 'قائمة واحدة';
	@override String get newList => 'قائمة جديدة';
	@override String get newListTitle => 'قائمة تسوق جديدة';
	@override String get listName => 'اسم القائمة';
	@override String get defaultListName => 'قائمة التسوق';
	@override String get fromPlans => 'من القوائم الغذائية';
	@override String get fromPlansHint => 'تجمع وصفات خطط وجباتك';
	@override String get fromRecipe => 'من وصفة';
	@override String get fromRecipeHint => 'مكونات وصفة واحدة';
	@override String get emptyList => 'قائمة فارغة';
	@override String get emptyListHint => 'تضيف العناصر يدويًا';
	@override String get sourcePlans => 'من القوائم الغذائية';
	@override String sourceRecipe({required Object title}) => 'من وصفة "${title}"';
	@override String get sourceManual => 'قائمة يدوية';
	@override String get renameList => 'إعادة تسمية القائمة';
	@override String get deleteList => 'حذف القائمة';
	@override String deleteListConfirm({required Object name}) => 'سيتم حذف "${name}" وكل عناصرها.';
	@override String progress({required Object checked, required Object total}) => '${checked}/${total}';
	@override String get servings => 'حصص';
	@override String get timesOver => 'الكمية';
	@override String scaleValue({required Object value}) => '×${value}';
	@override String get rebuildFromRecipe => 'إعادة البناء من الوصفة';
	@override String get createFromRecipe => 'إنشاء قائمة تسوق';
	@override String get createList => 'إنشاء القائمة';
	@override String get recipeListTitle => 'قائمة تسوق من وصفة';
	@override String get recipeListHint => 'مكونات الوصفة حسب الكمية التي تحضّرها';
	@override String listCreated({required Object name}) => 'تم إنشاء القائمة "${name}"';
	@override String get openList => 'فتح القائمة';
	@override String get stayHere => 'البقاء هنا';
	@override String get noIngredients => 'لا توجد في هذه الوصفة مكونات للشراء';
	@override String get addFirstItem => 'إضافة عنصر';
	@override String leaveListConfirm({required Object name}) => 'مغادرة القائمة المشتركة "${name}"؟ ستُزال من قوائمك.';
}

// Path: receipt
class _Translations$receipt$ar extends Translations$receipt$he {
	_Translations$receipt$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مسح إيصال';
	@override String get subtitle => 'صوّر إيصالاً أو ارفع PDF، وتُحفظ الأسعار لقائمة التسوق';
	@override String get camera => 'تصوير الإيصال';
	@override String get cameraHint => 'إيصال طويل؟ التقط عدة صور وسندمجها';
	@override String get gallery => 'اختيار من المعرض';
	@override String get pdf => 'ملف PDF';
	@override String get addPhoto => 'صورة أخرى';
	@override String get scan => 'مسح';
	@override String get scanning => 'جارٍ قراءة الإيصال…';
	@override String pagesCount({required Object count}) => '${count} صور';
	@override String get scanFailed => 'تعذّرت قراءة الإيصال. جرّب صورة أوضح أو PDF.';
	@override String get reviewTitle => 'ما تم التقاطه';
	@override String get reviewSubtitle => 'صحّح الأسماء والأسعار قبل الحفظ';
	@override String get store => 'المتجر';
	@override String get date => 'التاريخ';
	@override String get receiptTotal => 'إجمالي الإيصال';
	@override String get itemsTotal => 'إجمالي المنتجات الملتقطة';
	@override String get captured => 'المنتجات الملتقطة';
	@override String capturedCount({required Object count}) => '${count} منتجات';
	@override String get unreadable => 'تعذّر الالتقاط';
	@override String get unreadableHint => 'ملاحظات عن السطور التي تعذّرت قراءتها. يمكنك إضافتها يدويًا أدناه.';
	@override String get addLine => 'إضافة منتج';
	@override String get itemName => 'اسم المنتج';
	@override String get price => 'سعر الوحدة';
	@override String get quantity => 'الكمية';
	@override String get removeLine => 'إزالة السطر';
	@override String get shareToggle => 'مشاركة الأسعار مع المجتمع';
	@override String get shareHint => 'أسماء المنتجات والأسعار فقط. لا المتجر ولا التاريخ ولا من دفع.';
	@override String get save => 'حفظ الأسعار';
	@override String saved({required Object count}) => 'تم حفظ ${count} أسعار';
	@override String savedShared({required Object count}) => 'تم حفظ ومشاركة ${count} أسعار';
	@override String get nothingToSave => 'لا منتجات للحفظ';
	@override String get estimated => 'تقدير بناءً على بيانات سابقة';
	@override String get estimatedTotal => 'التكلفة التقديرية';
	@override String get noData => 'لا بيانات';
	@override String get fromReceipt => 'من إيصالك';
	@override String get fromCommunity => 'وسيط المستخدمين';
	@override String unpriced({required Object count}) => '${count} عناصر بلا سعر';
	@override String get priceBook => 'أسعاري';
	@override String get priceBookEmpty => 'لم تُمسح أي إيصالات بعد. امسح الأول لترى تكلفة التسوق.';
	@override String get deleteRecord => 'حذف السعر';
	@override String get cameraGuide => 'ضع الإيصال داخل الإطار';
	@override String get cameraHold => 'اثبت قليلًا…';
	@override String get cameraCaptured => 'تم الالتقاط!';
	@override String get cameraUnavailable => 'لا يمكن الوصول إلى الكاميرا';
	@override String get perUnit => 'للوحدة';
	@override String get perKg => 'للكيلو';
	@override String get perLiter => 'لللتر';
	@override String printedAs({required Object name}) => 'مطبوع: ${name}';
	@override String get receipts => 'الإيصالات';
	@override String get prices => 'الأسعار';
	@override String get sortBy => 'ترتيب';
	@override String get sortDate => 'التاريخ';
	@override String get sortStore => 'المتجر';
	@override String get sortTotal => 'المبلغ';
	@override String get sortName => 'الاسم';
	@override String get noReceipts => 'لا إيصالات محفوظة بعد';
	@override String get noPrices => 'لا أسعار محفوظة بعد';
	@override String get deleteReceipt => 'حذف الإيصال';
	@override String get deleteReceiptBody => 'سيُحذف الإيصال وكل الأسعار المقروءة منه.';
	@override String get addPrice => 'إضافة سعر';
	@override String get addPriceHint => 'بدون إيصال: سعر دفعته أو تعرفه';
	@override String get manualSource => 'أُدخل يدويًا';
	@override String get lastPaid => 'آخر دفع';
	@override String get priceSaved => 'تم حفظ السعر';
	@override String itemsInReceipt({required Object count}) => '${count} منتجات';
	@override String get search => 'بحث عن منتج';
	@override String get viewImage => 'صورة الإيصال';
	@override String get noImage => 'لم تُحفظ صورة لهذا الإيصال';
	@override String get pdfFile => 'إيصال من ملف PDF';
	@override String get filter => 'تصفية';
	@override String get filterAll => 'الكل';
	@override String get periodAll => 'كل الفترة';
	@override String get period30 => '30 يومًا';
	@override String get period90 => '90 يومًا';
	@override String get sourceReceipt => 'من الإيصالات';
	@override String get sourceManual => 'أُدخلت يدويًا';
	@override String get deleteProduct => 'حذف المنتج';
	@override String get deleteProductBody => 'ستُحذف كل الأسعار المحفوظة لهذا المنتج.';
	@override String get pickFromPrices => 'اختيار من أسعاري';
	@override String get pickerTitle => 'منتجاتي';
	@override String existingPrice({required Object price}) => 'معروف مسبقًا: ${price}';
	@override String get keepNew => 'السعر الجديد';
	@override String get keepOld => 'السعر القديم';
	@override String get keepAverage => 'المتوسط';
	@override String get deleteReceiptOnly => 'حذف الإيصال فقط';
	@override String get deleteReceiptOnlyHint => 'تبقى الأسعار المقروءة منه';
	@override String get deleteReceiptAndPrices => 'حذف الإيصال وأسعاره';
	@override String get deleteAll => 'حذف كل الأسعار';
	@override String get deleteAllBody => 'ستُحذف كل الأسعار والإيصالات والاختيارات. لا يمكن التراجع.';
	@override String get pricingTitle => 'أي سعر يُستخدم';
	@override String get pricingLatest => 'الأحدث';
	@override String get pricingAverage => 'متوسط الكل';
	@override String get pricingStore => 'حسب المتجر';
	@override String get pricingReceipts => 'إيصالات مختارة';
	@override String pricingActive({required Object price}) => 'المستخدم: ${price}';
	@override String get history => 'سجل الأسعار';
	@override String get noStore => 'بدون متجر';
	@override String get pricingSaved => 'تم حفظ الاختيار';
	@override String get renameStore => 'تغيير اسم المتجر';
	@override String get storeName => 'اسم المتجر';
	@override String get allStores => 'كل المتاجر';
	@override String get applyFilters => 'تطبيق';
	@override String get clearFilters => 'مسح';
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
	@override String get generate => 'إنشاء صورة بالذكاء الاصطناعي';
	@override String get generating => 'جارٍ إنشاء الصورة… يستغرق ذلك بضع ثوانٍ';
	@override String get generateFailed => 'فشل إنشاء الصورة، حاول مرة أخرى';
	@override String get coverTitle => 'أي غلاف تريد إنشاءه؟';
	@override String get coverHint => 'اختر فئة أو اكتب شيئًا أو كليهما';
	@override String get coverFreeText => 'نص حر، مثلًا: برغر';
	@override String get coverRequired => 'اختر فئة أو اكتب شيئًا';
	@override String get coverGenerate => 'إنشاء الغلاف';
	@override String get themeKids => 'أطفال';
	@override String get themeHealthy => 'صحي';
	@override String get themeIndulgent => 'دسم ولذيذ';
	@override String get themeSweets => 'حلويات ومخبوزات';
	@override String get themeMeat => 'لحوم ومشاوي';
	@override String get themeVegan => 'نباتي';
	@override String get themeHolidays => 'أعياد';
	@override String get themeQuick => 'سريع وبسيط';
	@override String get webSearch => 'بحث صور في جوجل';
	@override String get webSearchTitle => 'بحث عن صورة';
	@override String get webSearchHint => 'عمّ تبحث؟ مثلاً: كبة شمندر';
	@override String get webSearchEmpty => 'لم يتم العثور على صور، جرّب كلمات أخرى';
	@override String get webSearchFailed => 'فشل البحث، حاول مرة أخرى';
	@override String get webSearchUnavailable => 'بحث الصور غير متاح حالياً';
	@override String get webSearchEnd => 'هذه كل النتائج';
	@override String get webSearchDownloadFailed => 'تعذّر تنزيل هذه الصورة، جرّب صورة أخرى';
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

// Path: update
class _Translations$update$ar extends Translations$update$he {
	_Translations$update$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get forcedTitle => 'التحديث مطلوب';
	@override String forcedBody({required Object version}) => 'لم تعد هذه النسخة من EasyPlate مدعومة. حدِّث إلى ${version} للمتابعة.';
	@override String get optionalTitle => 'صدرت نسخة جديدة';
	@override String optionalBody({required Object version}) => 'النسخة ${version} من EasyPlate متوفرة في المتجر مع آخر التحسينات.';
	@override String get updateNow => 'تحديث الآن';
	@override String get later => 'تخطٍ';
}

// Path: ads
class _Translations$ads$ar extends Translations$ads$he {
	_Translations$ads$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get badge => 'إعلان';
	@override String freeViewsLeft({required Object count}) => 'تبقّى لك ${count} وصفات مجانية لليوم';
	@override String rewardedViewsLeft({required Object count}) => 'تبقّى ${count} فتحات بفيديو قصير لليوم';
	@override String get sharedQuotaReached => 'وصلت إلى الحد اليومي للوصفات المشتركة. سيُعاد ضبطه غدًا!';
	@override String get unlockRecipeTitle => 'فتح وصفة مشتركة';
	@override String unlockRecipeMessage({required Object count}) => 'شاهد فيديو قصيرًا لفتح هذه الوصفة (تبقّى ${count} لليوم)';
	@override String aiQuotaLeft({required Object remaining, required Object total}) => 'تبقّى لك ${remaining}/${total} استخراجات بالذكاء الاصطناعي لليوم';
	@override String get aiQuotaReached => 'وصلت إلى الحد اليومي لاستخراجات الذكاء الاصطناعي. سيُفتح غدًا!';
	@override String get aiLockedHint => 'الاستخراج من رابط يتطلب مشاهدة فيديو قصير';
	@override String get unlockAiTitle => 'استخراج وصفة بالذكاء الاصطناعي';
	@override String unlockAiMessage({required Object count}) => 'شاهد فيديو قصيرًا لاستخراج الوصفة من الرابط (تبقّى ${count} لليوم)';
	@override String get watchVideo => 'مشاهدة الفيديو';
	@override String get parseWithVideo => 'مشاهدة فيديو ثم التحليل';
	@override String get blockedForToday => 'مغلق لليوم';
	@override String get loadingVideo => 'جارٍ تحميل الفيديو...';
	@override String get videoNotCompleted => 'لم يكتمل الفيديو، تبقى الوصفة مغلقة';
	@override String get videoUnavailable => 'لا يوجد فيديو متاح الآن، حاول مجددًا بعد قليل';
}

// Path: premium
class _Translations$premium$ar extends Translations$premium$he {
	_Translations$premium$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إيزي-بلايت بريميوم';
	@override String get headline => 'بلا إعلانات، بلا حدود';
	@override String get subtitle => 'كل ما يقدّمه إيزي-بلايت، دون انتظار الغد.';
	@override String get benefitNoAds => 'بلا إعلانات في خلاصات المجتمع';
	@override String get benefitShared => 'وصفات مشتركة بلا حدّ يومي';
	@override String benefitAi({required Object count}) => 'استخراج الوصفات بالذكاء الاصطناعي من أي رابط، حتى ${count} في اليوم';
	@override String get periodWeekly => 'أسبوعي';
	@override String get periodMonthly => 'شهري';
	@override String get periodTwoMonth => 'كل شهرين';
	@override String get periodThreeMonth => 'ربع سنوي';
	@override String get periodSixMonth => 'كل 6 أشهر';
	@override String get periodAnnual => 'سنوي';
	@override String get periodLifetime => 'مدى الحياة';
	@override String get bestValue => 'الأوفر';
	@override String subscribeFor({required Object price}) => 'الاشتراك مقابل ${price}';
	@override String buyFor({required Object price}) => 'الشراء مقابل ${price}';
	@override String get restore => 'استعادة المشتريات';
	@override String get restored => 'تمت استعادة اشتراكك';
	@override String get nothingToRestore => 'لا توجد مشتريات لاستعادتها';
	@override String get activeTitle => 'بريميوم مفعّل';
	@override String get activeBody => 'شكرًا! الإعلانات والحدود اليومية متوقفة في هذا الحساب.';
	@override String get manage => 'إدارة الاشتراك';
	@override String get cancel => 'إلغاء الاشتراك';
	@override String get cancelNote => 'الإلغاء يوقف التجديد التلقائي. يبقى الاشتراك المميز فعالاً حتى نهاية الفترة المدفوعة. لا يوجد استرداد للمبلغ.';
	@override String get unavailable => 'الاشتراكات غير متاحة حاليًا. حاول مرة أخرى لاحقًا.';
	@override String get purchaseFailed => 'لم تكتمل عملية الشراء';
	@override String get purchased => 'مرحبًا بك في بريميوم!';
	@override String get legal => 'يتجدد الاشتراك تلقائيًا في نهاية كل فترة ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من انتهائها. يتم الدفع عبر حساب المتجر الخاص بك، ويمكن إدارته أو إلغاؤه من إعدادات المتجر.';
	@override String get terms => 'شروط الاستخدام';
	@override String get privacy => 'سياسة الخصوصية';
	@override String startFor({required Object price}) => 'ابدأ بـ ${price}';
	@override String get startFree => 'ابدأ مجانًا';
	@override String get free => 'مجانًا';
	@override String introDays({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'لليوم الأول',
		other: 'لأول ${n} أيام',
	);
	@override String introWeeks({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'للأسبوع الأول',
		other: 'لأول ${n} أسابيع',
	);
	@override String introMonths({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'للشهر الأول',
		other: 'لأول ${n} أشهر',
	);
	@override String introYears({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		one: 'للسنة الأولى',
		other: 'لأول ${n} سنوات',
	);
	@override String introPaidTerms({required Object price, required Object span, required Object then}) => '${price} ${span}، ثم ${then}. يتغيّر السعر تلقائيًا.';
	@override String introFreeTerms({required Object span, required Object then}) => 'مجانًا ${span}، ثم ${then}. يبدأ الدفع تلقائيًا.';
	@override String get redeem => 'لديّ رمز قسيمة';
	@override String get redeemTitle => 'رمز القسيمة';
	@override String get redeemHint => 'اكتب الرمز الذي استلمته';
	@override String get redeemConfirm => 'الاستخدام في المتجر';
	@override String get perWeekly => 'في الأسبوع';
	@override String get perMonthly => 'في الشهر';
	@override String get perTwoMonth => 'كل شهرين';
	@override String get perThreeMonth => 'كل 3 أشهر';
	@override String get perSixMonth => 'كل 6 أشهر';
	@override String get perAnnual => 'في السنة';
	@override String get tierPro => 'Pro';
	@override String get tierDuo => 'Pro Duo';
	@override String get tierFamily => 'Pro Family';
	@override String get tierProHint => 'حساب واحد';
	@override String get tierDuoHint => 'حسابان، كل شيء متزامن';
	@override String get tierFamilyHint => 'حتى 6 حسابات، كل شيء متزامن';
	@override String benefitHousehold({required Object n}) => 'حساب مشترك لـ ${n} أشخاص: الوصفات والخطط والقوائم متزامنة';
}

// Path: walkthrough
class _Translations$walkthrough$ar extends Translations$walkthrough$he {
	_Translations$walkthrough$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الدليل';
	@override String get start => 'تشغيل الدليل';
	@override String get startHint => 'جولة إرشادية في كل وظائف التطبيق، خطوة بخطوة';
	@override String get startFull => 'ابدأ الجولة الكاملة';
	@override String get focused => 'عرض إرشاد مركّز';
	@override String get next => 'التالي';
	@override String get finish => 'إنهاء';
	@override String get skipStep => 'تخطّي الخطوة';
	@override String get close => 'إغلاق الدليل';
	@override String stepOf({required Object current, required Object total}) => 'الخطوة ${current} من ${total}';
	@override String get tapHint => 'اضغط على المنطقة المميّزة أو على "التالي"';
	@override String get bookTitle => 'دليل EasyPlate';
	@override String get bookSubtitle => 'كل ما يمكن فعله في التطبيق، فصلاً بعد فصل. الأمثلة في هذا الكتاب لا تُحفظ؛ الجولة الحيّة تنفّذ الإجراءات فعلاً، والحقول معبّأة مسبقاً.';
	@override String get contents => 'المحتويات';
	@override String chapter({required Object number}) => 'الفصل ${number}';
	@override String get backToContents => 'العودة إلى المحتويات';
	@override String get stepsTitle => 'الخطوات';
	@override String get welcomeTitle => 'مرحباً بك في EasyPlate';
	@override String get welcomeBody => 'سنمرّ معاً على الإجراءات الرئيسية وننفّذها فعلاً: الحقول معبّأة لكم مسبقاً. يمكنكم تخطّي أي خطوة، أو الإغلاق والبدء من جديد من شاشة الدعم.';
	@override late final _Translations$walkthrough$topics$ar topics = _Translations$walkthrough$topics$ar._(_root);
	@override late final _Translations$walkthrough$demo$ar demo = _Translations$walkthrough$demo$ar._(_root);
	@override String get demoRecipes => 'وصفات نموذجية';
	@override String get demoRecipesHint => 'هكذا تبدو الوصفات في التطبيق. اضغط على وصفة لرؤية صفحتها الكاملة: الأوقات، المواضيع، مسببات الحساسية، المكونات والخطوات.';
	@override String get demoBooks => 'كتب نموذجية';
	@override String get demoBooksHint => 'هكذا يبدو كتاب الوصفات. اضغط على كتاب لفتحه وتقليب صفحاته والانتقال من الفهرس.';
	@override String get demoOnly => 'نموذج فقط، لا يُحفظ';
}

// Path: feedback
class _Translations$feedback$ar extends Translations$feedback$he {
	_Translations$feedback$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إبلاغ واقتراحات';
	@override String get subtitle => 'وجدت خللاً؟ لديك فكرة؟ اكتب لنا هنا، ونقرأ كل رسالة.';
	@override String get bug => 'خلل';
	@override String get suggestion => 'اقتراح تحسين';
	@override String get bugHint => 'صف الخلل: ماذا فعلت، ماذا حدث، وماذا توقعت أن يحدث...';
	@override String get suggestionHint => 'أخبرنا بما تودّ أن يوفره التطبيق، وكيف سيساعدك...';
	@override String get send => 'إرسال';
	@override String get sent => 'شكراً! تم إرسال رسالتك.';
	@override String get failed => 'فشل الإرسال، حاول لاحقاً';
	@override String get admin => 'إدارة الرسائل';
	@override String get all => 'الكل';
	@override String get bugs => 'أخطاء';
	@override String get suggestions => 'اقتراحات';
	@override String get none => 'لا توجد رسائل بعد';
	@override String version({required Object version}) => 'الإصدار ${version}';
	@override String get notAllowed => 'هذه الشاشة للمدير فقط';
}

// Path: adminBilling
class _Translations$adminBilling$ar extends Translations$adminBilling$he {
	_Translations$adminBilling$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الاشتراكات';
	@override String get all => 'الكل';
	@override String get paying => 'يدفعون';
	@override String get problems => 'مشاكل';
	@override String get searchHint => 'بحث بالاسم أو البريد أو الهاتف أو uid';
	@override String get none => 'لا حسابات للعرض';
	@override String get premium => 'بريميوم';
	@override String get free => 'مجاني';
	@override String untilDate({required Object date}) => 'حتى ${date}';
	@override String get adminLocked => 'محدد يدويًا';
	@override String get viaRevenueCat => 'من RevenueCat';
	@override String get sandbox => 'Sandbox';
	@override String lastEvent({required Object type, required Object date}) => '${type} · ${date}';
	@override String product({required Object id}) => 'المنتج: ${id}';
	@override String eventsCount({required Object count}) => '${count} أحداث';
	@override String get grant => 'منح بريميوم';
	@override String get revoke => 'إلغاء بريميوم';
	@override String get release => 'إعادة إلى RevenueCat';
	@override String get releaseHint => 'محدد يدويًا: يتم تجاهل الحدث التالي من RevenueCat حتى الإفراج.';
	@override String get granted => 'تم منح بريميوم';
	@override String get revoked => 'تم إلغاء بريميوم';
	@override String get released => 'عاد الحساب إلى RevenueCat';
	@override String revokeConfirm({required Object name}) => 'إلغاء بريميوم لـ ${name}؟';
	@override String get problemPaidNotPremium => 'دفع، لكن الحساب ليس بريميوم';
	@override String get problemNoEntitlement => 'وصلت عملية شراء بدون الـ entitlement (المنتج غير مرتبط في RevenueCat)';
	@override String get orphanTitle => 'مشتريات بدون حساب';
	@override String get orphanBody => 'إيصالات وصلت تحت معرّف مجهول في RevenueCat، بدون مستخدم لفتحه';
	@override String summary({required Object premium, required Object problems, required Object total}) => '${premium} بريميوم · ${problems} مشاكل · ${total} حسابات';
	@override String get noEntitlementTag => 'بدون entitlement';
}

// Path: adminDashboard
class _Translations$adminDashboard$ar extends Translations$adminDashboard$he {
	_Translations$adminDashboard$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'لوحة التحكم';
	@override String get tabDashboard => 'لوحة';
	@override String get tabSubscriptions => 'الاشتراكات';
	@override String get tabTickets => 'الرسائل';
	@override String get rangeToday => 'اليوم';
	@override String get rangeMonth => '30 يومًا';
	@override String get rangeAll => 'الكل';
	@override String get aiCost => 'تكلفة الذكاء الاصطناعي';
	@override String get aiCostHint => 'الرموز × قائمة الأسعار';
	@override String get revenue => 'الإيرادات';
	@override String get revenueNone => 'لا مدفوعات في هذه الفترة';
	@override String sandboxNote({required Object count}) => '${count} مدفوعات sandbox لم تُحتسب';
	@override String paymentsCount({required Object count}) => '${count} مدفوعات';
	@override String get aiCalls => 'طلبات الذكاء الاصطناعي';
	@override String cacheSaved({required Object count}) => '${count} من الذاكرة المؤقتة (مجانًا)';
	@override String errorsCount({required Object count}) => '${count} أخطاء';
	@override String get tokens => 'الرموز';
	@override String tokensHint({required Object input, required Object output}) => 'إدخال ${input} · إخراج ${output}';
	@override String get usersTotal => 'إجمالي المستخدمين';
	@override String newUsers({required Object count}) => '${count} جدد';
	@override String disabledCount({required Object count}) => '${count} محظورون';
	@override String get premiumUsers => 'مدفوع';
	@override String freeCount({required Object count}) => '${count} مجاني';
	@override String get freeUsers => 'مجاني';
	@override String get activeUsers => 'مستخدمو الذكاء الاصطناعي النشطون';
	@override String get costPerUser => 'التكلفة لكل مستخدم نشط';
	@override String get tickets => 'الرسائل';
	@override String unreadCount({required Object count}) => '${count} جديدة';
	@override String get chartCost => 'تكلفة الذكاء الاصطناعي يوميًا';
	@override String get chartCalls => 'الطلبات يوميًا';
	@override String get chartSignups => 'التسجيلات يوميًا';
	@override String get chartPlatform => 'المستخدمون حسب المنصة';
	@override String get chartPlan => 'مجاني مقابل مدفوع';
	@override String get chartKinds => 'الطلبات حسب الميزة';
	@override String get chartModels => 'التكلفة حسب النموذج';
	@override String get chartVersions => 'إصدارات التطبيق';
	@override String get platformIos => 'iOS';
	@override String get platformAndroid => 'Android';
	@override String get platformUnknown => 'غير معروف';
	@override String get noAiUsage => 'لا استخدام للذكاء الاصطناعي في هذه الفترة';
	@override String get unknownModel => 'ليس في قائمة الأسعار';
	@override String get usersCost => 'التكلفة حسب المستخدم';
	@override String usersCount({required Object count}) => '${count} مستخدمين';
	@override String get searchUser => 'بحث بالاسم أو البريد أو uid';
	@override String showAll({required Object count}) => 'عرض كل ${count} المستخدمين';
	@override String callsCount({required Object count}) => '${count} طلبات';
	@override String get content => 'المحتوى والمجتمع';
	@override String get sharedRecipes => 'وصفات مشتركة';
	@override String get forumPosts => 'مواضيع المنتدى';
	@override String get withPush => 'أجهزة مع إشعارات';
	@override String get cacheEntries => 'روابط محفوظة';
	@override String get cacheHits => 'إصابات الذاكرة (طلبات موفّرة)';
	@override String get config => 'الإعدادات عن بُعد';
	@override String get environment => 'البيئة';
	@override String get prod => 'Production';
	@override String get dev => 'Dev';
	@override String get adsEnabled => 'الإعلانات';
	@override String get adsFailOpen => 'فتح بدون إعلان';
	@override String get on => 'مفعّل';
	@override String get off => 'معطّل';
	@override String get feedInterval => 'فاصل إعلانات الخلاصة';
	@override String get quotaSharedFree => 'مشاهدات مجانية يوميًا';
	@override String get quotaSharedRewarded => 'مشاهدات بالفيديو يوميًا';
	@override String get quotaAiRewarded => 'ذكاء اصطناعي بالفيديو يوميًا';
	@override String get quotaAiPremium => 'ذكاء اصطناعي للمميز يوميًا';
	@override String get minVersion => 'الحد الأدنى للإصدار';
	@override String get latestVersion => 'أحدث إصدار';
	@override String get thisBuild => 'هذا الإصدار';
	@override String get pricing => 'قائمة أسعار الرموز';
	@override String get pricingHint => 'دولار أمريكي لكل مليون رمز. القيم الافتراضية تقديرية — حدّثها من قائمة أسعار Google.';
	@override String get editPricing => 'تعديل الأسعار';
	@override String get priceInput => 'إدخال';
	@override String get priceOutput => 'إخراج';
	@override String get priceCached => 'إدخال مخزّن';
	@override String get usdToIls => 'سعر الدولار/الشيكل';
	@override String get pricingSaved => 'تم حفظ الأسعار';
	@override String loadedAt({required Object date}) => 'تم التحديث ${date}';
	@override String get kindText => 'نص';
	@override String get kindUrl => 'رابط';
	@override String get kindSocial => 'شبكة اجتماعية';
	@override String get kindSocialVideo => 'فيديو (خادم)';
	@override String get kindVideo => 'فيديو';
	@override String get kindSearch => 'بحث';
	@override String get kindImage => 'صورة';
	@override String get kindReceipt => 'فاتورة';
	@override String get kindNutrition => 'تغذية';
	@override String get kindRefine => 'تحسين';
	@override String get kindGenerate => 'توليد';
	@override String get allTime => 'كل الوقت';
	@override String get recentCalls => 'آخر الطلبات';
	@override String get noCalls => 'لا طلبات';
	@override String get cacheHit => 'ذاكرة';
	@override String get statusOk => 'سليم';
	@override String get pushTitle => 'العنوان (اختياري)';
	@override String get pushBody => 'نص الرسالة';
	@override String get send => 'إرسال';
	@override String get blocked => 'محظورون';
	@override String get disable => 'حظر الحساب';
	@override String get enable => 'إلغاء الحظر';
	@override String get blockMessageHint => 'ما سيراه المستخدم عند محاولة الدخول';
	@override String get disabledDone => 'تم حظر الحساب';
	@override String get enabledDone => 'تم إلغاء الحظر';
	@override String get deleteAccount => 'حذف الحساب';
	@override String deleteAccountConfirm({required Object name}) => 'حذف ${name} نهائيًا؟ سيُحذف المستخدم ووصفاته وكتبه وقوائمه ولا يمكن الاسترجاع.';
	@override String get deleted => 'تم حذف الحساب';
	@override String get sendPush => 'إرسال إشعار';
	@override String get noPush => 'لا يوجد رمز إشعارات لهذا الجهاز — ستظهر الرسالة في شاشة الإشعارات فقط';
	@override String get pushSent => 'تم إرسال الإشعار';
	@override String get sendPushAll => 'إشعار لجميع المستخدمين';
	@override String broadcastConfirm({required Object count}) => 'إرسال الرسالة إلى جميع المستخدمين (${count})؟';
	@override String broadcastDone({required Object items, required Object sent, required Object failed}) => 'كُتبت في ${items} صندوقًا · ${sent} إشعارات نجحت · ${failed} فشلت';
	@override String platformTag({required Object platform, required Object version}) => '${platform} · v${version}';
	@override String lastSeen({required Object date}) => 'آخر ظهور ${date}';
	@override String disabledSince({required Object message}) => 'سبب الحظر: ${message}';
	@override String get unread => 'جديدة';
	@override String get markAllRead => 'قرأت الكل';
	@override String get allRead => 'تم تعليم كل الرسائل كمقروءة';
	@override String get noUnread => 'لا رسائل جديدة';
	@override String get deleteTicket => 'حذف الرسالة';
	@override String deleteTicketConfirm({required Object name}) => 'حذف رسالة ${name}؟';
	@override String get ticketDeleted => 'تم حذف الرسالة';
	@override String get reply => 'رد';
	@override String get replyHint => 'سيصل الرد إلى إشعارات المستخدم (وكإشعار على الهاتف)';
	@override String get replySent => 'تم إرسال الرد';
	@override String yourReply({required Object date}) => 'ردك · ${date}';
	@override String get markRead => 'تعليم كمقروء';
	@override String get markUnread => 'تعليم كغير مقروء';
	@override String get pricingSync => 'مزامنة الأسعار من Google';
	@override String pricingSynced({required Object count}) => 'تم تحديث ${count} نماذج من كتالوج Google Cloud Billing';
	@override String pricingSyncFailed({required Object reason}) => 'فشلت المزامنة: ${reason}';
	@override String pricingSourceCatalog({required Object date}) => 'المصدر: Google Cloud Billing (أسعار حقيقية) · ${date}';
	@override String pricingSourceManual({required Object date}) => 'المصدر: أُدخل يدويًا · ${date}';
	@override String get pricingSourceDefaults => 'تقدير فقط — اضغط مزامنة لجلب الأسعار الحقيقية من Google';
	@override String get searchPrice => 'بحث Google (دولار لكل 1000 استعلام)';
	@override String rateLine({required Object rate, required Object date}) => '${rate} · يتحدّث أسبوعيًا · ${date}';
	@override String searchesCount({required Object count}) => '${count} عمليات بحث';
	@override String get rangeCustom => 'اختيار';
	@override String customRange({required Object from, required Object to}) => '${from} – ${to} · اضغط للتغيير';
	@override String get priceImageOutput => 'إخراج صورة';
	@override String dataSince({required Object date}) => 'تُجمع البيانات منذ ${date}. رسوم Google السابقة غير مسجّلة هنا.';
	@override String grantTitle({required Object name}) => 'اشتراك مميز لـ ${name} — لكم من الوقت؟';
	@override String get grantForever => 'دائمًا (حتى أُلغيه)';
	@override String get grantWeek => 'أسبوع';
	@override String get grantMonth => 'شهر';
	@override String get grantYear => 'سنة';
	@override String get grantRange => 'نطاق تواريخ محدد';
	@override String grantedUntil({required Object date}) => 'مُنح الاشتراك حتى ${date}';
	@override String grantStarts({required Object date}) => 'يبدأ في ${date}';
}

// Path: assistant
class _Translations$assistant$ar extends Translations$assistant$he {
	_Translations$assistant$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'شيفي';
	@override String get subtitle => 'مساعد الطاهي: اسأل، خطط، تسوّق، اطبخ';
	@override String get placeholder => 'اسأل أو قل لي ماذا أفعل…';
	@override String get send => 'إرسال';
	@override String get thinking => 'أفكّر…';
	@override String working({required Object tool}) => 'أنفّذ: ${tool}';
	@override String welcome({required Object name}) => 'مرحبًا ${name}! أستطيع إضافة مشتريات، تخطيط أسبوعك، استيراد وصفات من روابط، بدء وضع الطبخ والمزيد. ماذا نفعل؟';
	@override String get error => 'حدث خطأ ما. حاول مجددًا.';
	@override String get quotaReached => 'استُهلكت حصة الذكاء الاصطناعي لليوم. تُفتح غدًا.';
	@override String get premiumOnly => 'شيفي جزء من EasyPlate Premium';
	@override String get unlock => 'عرض بريميوم';
	@override String get clear => 'محادثة جديدة';
	@override String get openResult => 'فتح';
	@override String get done => 'تم';
	@override String get undone => 'تم التراجع';
	@override String get confirmTitle => 'حذف؟';
	@override String confirmBody({required Object what}) => 'سيتم حذف ${what}.';
	@override String notFound({required Object name}) => 'لم أجد "${name}".';
	@override String get listTitle => 'قائمة التسوّق';
	@override String addedItems({required Object count}) => 'أُضيف ${count} عناصر';
	@override String plannedMeal({required Object day, required Object slot}) => 'خُطط لـ${day} · ${slot}';
	@override String get recipeSaved => 'حُفظت الوصفة';
	@override String get cookStarted => 'بدأ وضع الطبخ';
	@override String timerSet({required Object n}) => 'ضُبط مؤقّت للخطوة ${n}';
	@override String get prefSaved => 'حُفظ التفضيل';
	@override String get needsPremium => 'هذا يتطلب EasyPlate Premium.';
	@override String results({required Object count}) => '${count} نتائج';
	@override late final _Translations$assistant$suggest$ar suggest = _Translations$assistant$suggest$ar._(_root);
	@override String get whichList => 'أي قائمة؟';
	@override String get listCreated => 'أُنشئت القائمة';
	@override String get offTopic => 'أنا هنا للطبخ والوصفات وتخطيط الوجبات والمشتريات. اسألني أي شيء يخص المطبخ وسأتولاه!';
	@override String get welcomeAnon => 'مرحبًا! أستطيع إضافة مشتريات، تخطيط أسبوعك، استيراد وصفات من روابط، بدء وضع الطبخ والمزيد. ماذا نفعل؟';
	@override String scopedWelcome({required Object name}) => 'ماذا تريد أن تعرف عن "${name}"؟';
	@override String scopedOffTopic({required Object name}) => 'هنا أساعد فقط فيما يخص "${name}". لأي شيء آخر افتح شيفي من القائمة.';
	@override String get askAboutRecipe => 'اسأل شيفي عن هذه الوصفة';
	@override String get askAboutPlan => 'اسأل شيفي عن هذه الخطة';
	@override String get askAboutList => 'اسأل شيفي عن هذه القائمة';
	@override String get listen => 'تحدّث إلى شيفي';
	@override String get stopListening => 'إيقاف الاستماع';
	@override String get speakReplies => 'قراءة الردود بصوت عالٍ';
	@override String get micUnavailable => 'لا يمكن استخدام الميكروفون. تحقق من أذونات الميكروفون والتعرف على الكلام في إعدادات الجهاز.';
	@override late final _Translations$assistant$scopedPrompts$ar scopedPrompts = _Translations$assistant$scopedPrompts$ar._(_root);
	@override String get listening => 'أستمع…';
	@override String get stop => 'إيقاف';
	@override String get cancelled => 'أُلغي.';
}

// Path: shareCode
class _Translations$shareCode$ar extends Translations$shareCode$he {
	_Translations$shareCode$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'رمز ورابط';
	@override String get tabContact => 'جهة اتصال';
	@override String get tabCode => 'رمز أو رابط';
	@override String explain({required Object role}) => 'كل من لديه هذا الرمز يمكنه الانضمام كـ${role}. صالح لمدة 30 يومًا.';
	@override String get create => 'إنشاء رمز';
	@override String get code => 'الرمز';
	@override String get link => 'الرابط';
	@override String get copy => 'نسخ';
	@override String get copied => 'تم النسخ';
	@override String get share => 'مشاركة';
	@override String get showQr => 'عرض QR';
	@override String get scanQr => 'مسح QR';
	@override String get enterCode => 'إدخال رمز';
	@override String get join => 'انضمام';
	@override String get joinTitle => 'الانضمام برمز';
	@override String get joinHint => 'الصق الرمز الذي تلقيته، أو امسح رمز QR الخاص به.';
	@override String get joinPlaceholder => 'XXXXXXXX';
	@override String joined({required Object title}) => 'انضممت: ${title}';
	@override String get alreadyMember => 'لديك هذا بالفعل.';
	@override String get invalid => 'الرمز غير صالح.';
	@override String get expired => 'انتهت صلاحية الرمز.';
	@override String get revoked => 'أُلغي الرمز.';
	@override String get usedUp => 'استُنفد الرمز.';
	@override String get self => 'هذا رمزك أنت.';
	@override String get gone => 'ما شاركه هذا الرمز لم يعد موجودًا.';
	@override String get failed => 'تعذّر الانضمام. حاول مجددًا.';
	@override String messageText({required Object name, required Object title, required Object code, required Object link}) => 'شارك ${name} معك "${title}" على EasyPlate. الرمز: ${code}\n${link}';
	@override String get revoke => 'إلغاء الرمز';
	@override String limitRecipes({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} وصفات أسبوعيًا.';
	@override String limitBooks({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} كتب.';
	@override String limitPlans({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} خطط.';
	@override String get upgrade => 'عرض بريميوم';
	@override String get scanHint => 'وجّه الكاميرا نحو رمز QR للمشاركة';
	@override String householdMessage({required Object name, required Object code, required Object link}) => 'دعاك ${name} إلى حسابه المشترك في EasyPlate. الرمز: ${code}\n${link}';
	@override String limitLists({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} قوائم تسوق.';
}

// Path: household
class _Translations$household$ar extends Translations$household$he {
	_Translations$household$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'حساب مشترك';
	@override String get duo => 'Pro Duo';
	@override String get family => 'Pro Family';
	@override String seats({required Object used, required Object total}) => '${used} من ${total} مقاعد مستخدمة';
	@override String get intro => 'افتح حسابًا مشتركًا: الوصفات والكتب والخطط والقوائم تظهر لكل من فيه، ويحصلون على بريميوم معك.';
	@override String get create => 'فتح حساب مشترك';
	@override String get nameHint => 'الاسم، مثلًا عائلة أحمد';
	@override String get notEligible => 'يأتي الحساب المشترك مع Pro Duo (حسابان) أو Pro Family (حتى 6 حسابات).';
	@override String get seePlans => 'عرض الخطط';
	@override String get members => 'الأعضاء';
	@override String get owner => 'المالك';
	@override String get you => 'أنت';
	@override String get invite => 'دعوة عضو';
	@override String inviteExplain({required Object free}) => 'كل من لديه هذا الرمز ينضم إلى الحساب المشترك. بقي ${free} مقاعد.';
	@override String get noSeats => 'كل المقاعد مشغولة.';
	@override String get remove => 'إزالة';
	@override String removeConfirm({required Object name}) => 'إزالة ${name} من الحساب المشترك؟ سيفقد الوصول وبريميوم.';
	@override String get leave => 'مغادرة الحساب المشترك';
	@override String get leaveConfirm => 'المغادرة؟ ما حُفظ هنا يبقى في الحساب المشترك؛ ويعود حسابك إلى ما كان لديك من قبل.';
	@override String get dissolve => 'إغلاق الحساب المشترك';
	@override String get dissolveConfirm => 'إغلاق الحساب المشترك؟ يفقد الأعضاء الوصول وبريميوم. وتعود بياناتك إلى حسابك الخاص.';
	@override String get joined => 'مرحبًا بك في الحساب المشترك!';
	@override String inheritedNote({required Object name}) => 'بريميوم يأتي من اشتراك ${name}.';
	@override String get failed => 'لم ينجح ذلك. حاول مجددًا.';
	@override String get full => 'الحساب المشترك ممتلئ.';
	@override String get inHousehold => 'أنت بالفعل في حساب مشترك.';
	@override String get notEligibleCode => 'خطة المالك لم تعد تشمل حسابًا مشتركًا.';
	@override String get lapsed => 'انتهى اشتراك المالك؛ بريميوم متوقف مؤقتًا للأعضاء.';
}

// Path: homeWidgets
class _Translations$homeWidgets$ar extends Translations$homeWidgets$he {
	_Translations$homeWidgets$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'أدوات الشاشة الرئيسية';
	@override String get hint => 'شيفي وقائمة التسوق وقائمة طعام اليوم، مباشرة على الشاشة الرئيسية';
	@override String get intro => 'أضيفوا أدوات EasyPlate إلى الشاشة الرئيسية: اسألوا شيفي، أضيفوا إلى قائمة التسوق، وشاهدوا القائمة وقائمة طعام اليوم دون فتح التطبيق.';
	@override String get howToIos => 'اضغطوا مطولاً على مكان فارغ في الشاشة الرئيسية، ثم على +، ابحثوا عن EasyPlate واختاروا أداة. الأدوات نفسها تناسب شاشة القفل.';
	@override String get howToAndroid => 'اضغطوا مطولاً على مكان فارغ في الشاشة الرئيسية، اختاروا "الأدوات" وابحثوا عن EasyPlate، أو اضغطوا "إضافة إلى الشاشة الرئيسية" أدناه.';
	@override String get addToHome => 'إضافة إلى الشاشة الرئيسية';
	@override String installed({required Object count}) => '${count} على الشاشة الرئيسية';
	@override String get pinFailed => 'لم يعرض المشغّل إضافة الأداة. أضيفوها من قائمة أدوات الشاشة الرئيسية.';
	@override String get defaults => 'الإعدادات الافتراضية للأدوات الجديدة';
	@override String get defaultsHint => 'يمكن تغيير كل أداة لاحقًا من إعداداتها (ضغطة مطولة على الأداة).';
	@override String get defaultList => 'قائمة التسوق';
	@override String get openList => 'القائمة المفتوحة';
	@override String get defaultPlan => 'خطة الوجبات';
	@override String get firstPlan => 'الخطة الأولى';
	@override String get noLists => 'لا توجد قائمة تسوق بعد';
	@override String get noPlans => 'لا توجد خطة وجبات بعد';
	@override String get followApp => 'مثل التطبيق';
	@override String get voiceOpen => 'يفتح شيفي وهو يستمع';
	@override String get voiceOpenHint => 'زر شيفي يشغّل الميكروفون فورًا';
	@override String get widgetAssistant => 'اسأل شيفي';
	@override String get widgetAssistantHint => 'زر يفتح شيفي، مع الميكروفون إن أردتم، وأسئلة سريعة.';
	@override String get widgetGroceryAdd => 'إضافة سريعة إلى القائمة';
	@override String get widgetGroceryAddHint => 'اكتبوا أو أملوا عنصرًا مباشرة إلى القائمة التي تختارونها.';
	@override String get widgetGroceryList => 'قائمة التسوق';
	@override String get widgetGroceryListHint => 'ما تبقى لشرائه؛ علّموا العناصر من الأداة.';
	@override String get widgetTodayMenu => 'قائمة طعام اليوم';
	@override String get widgetTodayMenuHint => 'وجبات اليوم من خطة تختارونها، كل يوم.';
	@override String get askShefi => 'اسأل شيفي';
	@override String get tapToAsk => 'ماذا نطبخ؟';
	@override String get speak => 'تحدّث';
	@override String get quickAdd => 'إضافة سريعة';
	@override String get addItem => 'إضافة عنصر';
	@override String get itemHint => 'ماذا نشتري؟';
	@override String get add => 'إضافة';
	@override String get todayMenu => 'قائمة طعام اليوم';
	@override String get today => 'اليوم';
	@override String get noMeals => 'لا وجبات مخططة لليوم';
	@override String get noPlan => 'لا توجد خطة وجبات بعد';
	@override String get emptyList => 'القائمة فارغة';
	@override String get allDone => 'تم شراء كل شيء';
	@override String get remainingNative => '{n} بقي للشراء';
	@override String get signIn => 'سجّلوا الدخول إلى EasyPlate لرؤية قوائمكم';
	@override String get openApp => 'فتح EasyPlate';
	@override String get showChecked => 'إظهار العناصر المعلّمة أيضًا';
	@override String get pendingSync => 'سيتم المزامنة عند فتح التطبيق';
	@override String get configTitle => 'إعدادات الأداة';
	@override String get prompt1 => 'ماذا أطبخ اليوم؟';
	@override String get prompt2 => 'ما الناقص في القائمة؟';
	@override String get prompt3 => 'خطّط أسبوعي';
	@override String get demo1 => 'حليب';
	@override String get demo2 => 'خبز';
	@override String get demo3 => 'بيض';
}

// Path: feature
class _Translations$feature$ar extends Translations$feature$he {
	_Translations$feature$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get comingSoon => 'قريباً';
	@override String get comingSoonMessage => 'هذه الميزة ستصل قريباً';
	@override String get unavailable => 'هذه الميزة غير متاحة حالياً';
	@override String get premiumOnly => 'بريميوم';
	@override String get premiumOnlyMessage => 'هذه الميزة لمشتركي بريميوم';
	@override String get premiumOnlyTitle => 'لمشتركي بريميوم فقط';
	@override String premiumOnlyFor({required Object name}) => 'خيار "${name}" متاح لمشتركي بريميوم فقط';
	@override String get goPremium => 'الانتقال إلى بريميوم';
}

// Path: featureName
class _Translations$featureName$ar extends Translations$featureName$he {
	_Translations$featureName$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get books => 'كتب الوصفات';
	@override String get mealPlans => 'خطط الوجبات';
	@override String get groceryLists => 'قوائم التسوق';
	@override String get community => 'المجتمع';
	@override String get ingestText => 'وصفة من نص';
	@override String get ingestWebSearch => 'البحث عن وصفة على الإنترنت';
	@override String get ingestLink => 'وصفة من رابط';
	@override String get ingestSocialVideo => 'وصفة من فيديو';
	@override String get ingestAiRequest => 'طلب وصفة من الذكاء الاصطناعي';
	@override String get ingestFile => 'وصفة من ملف';
	@override String get shareIn => 'المشاركة من تطبيق آخر';
	@override String get saveWithAi => 'الحفظ بالذكاء الاصطناعي';
	@override String get cookMode => 'وضع الطهي';
	@override String get cookTimers => 'مؤقتات الطهي';
	@override String get nutrition => 'القيم الغذائية';
	@override String get recipeImageAi => 'صورة بالذكاء الاصطناعي';
	@override String get recipeImageSearch => 'بحث الصور في جوجل';
	@override String get groceryFromRecipe => 'قائمة تسوق من وصفة';
	@override String get sharedRecipes => 'الوصفات المشتركة';
	@override String get forum => 'المنتدى';
	@override String get likes => 'الإعجابات';
	@override String get shareRecipes => 'مشاركة الوصفات';
	@override String get shareBooks => 'مشاركة الكتب';
	@override String get sharePlans => 'مشاركة الخطط';
	@override String get shareGroceryLists => 'مشاركة قوائم التسوق';
	@override String get shareCodes => 'المشاركة برمز';
	@override String get households => 'الأسرة';
	@override String get priceBook => 'دفتر الأسعار';
	@override String get receiptScan => 'مسح الإيصال';
	@override String get groceryCost => 'التكلفة التقديرية';
	@override String get shoppingReminder => 'تذكير التسوق';
	@override String get assistant => 'شيفي (المساعد)';
	@override String get notifications => 'الإشعارات';
	@override String get premium => 'بريميوم';
	@override String get contentTranslation => 'ترجمة المحتوى';
	@override String get theming => 'المظهر';
	@override String get walkthrough => 'جولة إرشادية';
	@override String get tutorialBook => 'كتاب التعليمات';
	@override String get feedback => 'الملاحظات';
	@override String get assistantScoped => 'شيفي داخل عنصر';
	@override String get assistantVoice => 'التحدث مع شيفي';
	@override String get singleSession => 'جهاز واحد لكل حساب';
	@override String get homeWidgets => 'أدوات الشاشة الرئيسية';
}

// Path: walkthrough.topics
class _Translations$walkthrough$topics$ar extends Translations$walkthrough$topics$he {
	_Translations$walkthrough$topics$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$walkthrough$topics$addRecipe$ar addRecipe = _Translations$walkthrough$topics$addRecipe$ar._(_root);
	@override late final _Translations$walkthrough$topics$myRecipes$ar myRecipes = _Translations$walkthrough$topics$myRecipes$ar._(_root);
	@override late final _Translations$walkthrough$topics$library$ar library = _Translations$walkthrough$topics$library$ar._(_root);
	@override late final _Translations$walkthrough$topics$mealPlan$ar mealPlan = _Translations$walkthrough$topics$mealPlan$ar._(_root);
	@override late final _Translations$walkthrough$topics$groceries$ar groceries = _Translations$walkthrough$topics$groceries$ar._(_root);
	@override late final _Translations$walkthrough$topics$community$ar community = _Translations$walkthrough$topics$community$ar._(_root);
	@override late final _Translations$walkthrough$topics$account$ar account = _Translations$walkthrough$topics$account$ar._(_root);
	@override late final _Translations$walkthrough$topics$settings$ar settings = _Translations$walkthrough$topics$settings$ar._(_root);
}

// Path: walkthrough.demo
class _Translations$walkthrough$demo$ar extends Translations$walkthrough$demo$he {
	_Translations$walkthrough$demo$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get bookTitle => 'دليل';
	@override String get planName => 'خطة الدليل';
	@override String get mealName => 'عشاء';
	@override String get groceryItem => 'طماطم';
	@override String get recipeText => 'شكشوكة مقدسية\n\nالمكوّنات:\n400 غرام طماطم مهروسة\n4 بيضات\nبصلة واحدة\nملعقتا طعام زيت زيتون\nملعقة صغيرة بابريكا حلوة\nرشّة ملح\n\nالطريقة:\n1. سخّن زيت الزيتون في مقلاة وقلّب البصل حتى يذهبّ.\n2. أضف الطماطم والبابريكا واطبخ 10 دقائق على نار هادئة.\n3. اكسر البيض فوق الصلصة، غطِّ المقلاة واطبخ حتى يتماسك البياض.';
}

// Path: assistant.suggest
class _Translations$assistant$suggest$ar extends Translations$assistant$suggest$he {
	_Translations$assistant$suggest$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override List<String> get templates => [
		'أضف {food} إلى قائمة التسوّق',
		'أضف {food} و{food2} إلى القائمة',
		'خطط {dish} لـ{meal} يوم {day}',
		'خطط شيئًا سريعًا لـ{meal} يوم {day}',
		'ماذا أطبخ بـ{food} و{food2}؟',
		'استورد وصفة من {site}',
		'ابحث عن وصفة {dish} على الإنترنت',
		'ابدأ طبخ {dish}',
		'شغّل مؤقّت {n} دقيقة للخطوة 2',
		'أنشئ قائمة تسوّق من {dish}',
		'أنشئ كتابًا باسم {book}',
		'أي وصفاتي {diet}؟',
		'علّم {food} كمشترى',
		'احذف {food} من القائمة',
		'أنشئ خطة للأسبوع القادم',
		'ماذا خُطط ليوم {day}؟',
		'غيّر يوم التسوّق إلى {day}',
		'اقترح عشاءً {diet} ليوم {day}',
		'كم أسلق البيضة؟',
		'بماذا أستبدل {food} في وصفة؟',
		'كيف أحفظ {food}؟',
		'كم سعرة في {dish}؟',
		'ما درجة حرارة الفرن المناسبة لـ{dish}؟',
		'كيف أجعل {dish} نباتيًا؟',
		'كم غرامًا في {n} ملاعق كبيرة؟',
		'لماذا خرج {dish} جافًا؟',
		'ماذا يناسب بجانب {dish}؟',
		'هل يمكن تجميد {food}؟',
		'كيف أثخّن الصلصة؟',
		'فكرة {meal} {diet} سريعة؟',
	];
	@override List<String> get food => [
		'حليب',
		'بيض',
		'خبز',
		'طماطم',
		'بصل',
		'زيت زيتون',
		'أرز',
		'دجاج',
		'ليمون',
		'ثوم',
		'زبدة',
		'طحين',
		'جبنة',
		'لبن',
		'خيار',
		'معكرونة',
	];
	@override List<String> get dish => [
		'شكشوكة',
		'شوربة عدس',
		'معكرونة بيستو',
		'كاري دجاج',
		'سلمون',
		'خضار مقلية',
		'بانكيك',
		'حمص',
		'خضار مشوية',
		'خبز الموز',
	];
	@override List<String> get day => [
		'الأحد',
		'الاثنين',
		'الثلاثاء',
		'الأربعاء',
		'الخميس',
		'الجمعة',
		'السبت',
		'غدًا',
	];
	@override List<String> get meal => [
		'الفطور',
		'الغداء',
		'العشاء',
	];
	@override List<String> get n => [
		'5',
		'8',
		'10',
		'12',
		'15',
		'20',
		'25',
		'30',
	];
	@override List<String> get site => [
		'تيك توك',
		'إنستغرام',
		'يوتيوب',
		'مدونة',
	];
	@override List<String> get book => [
		'أيام الأسبوع',
		'العطلة',
		'الأطفال',
		'حلويات',
	];
	@override List<String> get diet => [
		'نباتية',
		'نباتية صرفة',
		'خالية من الغلوتين',
		'ألبان',
	];
}

// Path: assistant.scopedPrompts
class _Translations$assistant$scopedPrompts$ar extends Translations$assistant$scopedPrompts$he {
	_Translations$assistant$scopedPrompts$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override List<String> get recipe => [
		'ما القيم الغذائية لكل حصة؟',
		'كيف أحضّرها لثمانية أشخاص؟',
		'بماذا أستبدل مكوّنًا لا أملكه؟',
		'أضف هذه الوصفة إلى خطة الغد',
		'أنشئ قائمة تسوّق من هذه الوصفة',
	];
	@override List<String> get mealPlan => [
		'ماذا نأكل اليوم؟',
		'أضف عشاءً يوم الثلاثاء',
		'ما الناقص هذا الأسبوع؟',
		'أنشئ قائمة تسوّق من هذه الخطة',
		'كم سعرة يوم الأربعاء؟',
	];
	@override List<String> get groceryList => [
		'ما الذي بقي لشرائه؟',
		'أضف حليبًا وبيضًا',
		'علّم الطماطم كمشتراة',
		'احذف ما اشتريته بالفعل',
		'كم يساوي كوبان من الدقيق بالغرام؟',
	];
}

// Path: walkthrough.topics.addRecipe
class _Translations$walkthrough$topics$addRecipe$ar extends Translations$walkthrough$topics$addRecipe$he {
	_Translations$walkthrough$topics$addRecipe$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إضافة وصفة';
	@override String get summary => 'أدخل وصفة من أي مصدر، ويرتّبها الذكاء الاصطناعي بصيغة موحّدة: مكوّنات وكميات وخطوات ووسوم وحصص وقيم غذائية.';
	@override String get s1 => 'اضغط على زر الشرارة بجانب العنوان لإضافة وصفة.';
	@override String get s2 => 'اختر مصدراً: نص ملصق، بحث على الإنترنت، رابط موقع، فيديو من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك، طلب حرّ من الذكاء الاصطناعي، أو كتابة يدوية.';
	@override String get s3 => 'عبّأنا هنا وصفة نموذجية كما لو أنك لصقتها. الزر في الأسفل يرسلها إلى الذكاء الاصطناعي الذي يعيدها مرتّبة للمراجعة والتعديل والحفظ. يستغرق التحليل حتى نصف دقيقة، فاتركه إلى ما بعد الجولة.';
}

// Path: walkthrough.topics.myRecipes
class _Translations$walkthrough$topics$myRecipes$ar extends Translations$walkthrough$topics$myRecipes$he {
	_Translations$walkthrough$topics$myRecipes$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'وصفاتي والمحفوظة';
	@override String get summary => 'الوصفات التي كتبتها والتي حفظتها من المجتمع، مع بحث وتصفية حسب الموضوع.';
	@override String get s1 => 'انتقل هنا بين الوصفات التي كتبتها والوصفات التي حفظتها من المجتمع.';
	@override String get s2 => 'ابحث بالاسم وصفِّ حسب الموضوع: لحوم، ألبان، نباتي، نباتي صرف، كوشر، خالٍ من الغلوتين وحساسية. كل وصفة تحدّد أيضاً مسبّبات الحساسية فيها.';
}

// Path: walkthrough.topics.library
class _Translations$walkthrough$topics$library$ar extends Translations$walkthrough$topics$library$he {
	_Translations$walkthrough$topics$library$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'كتب الوصفات';
	@override String get summary => 'رتّب الوصفات في كتب مع فهرس وغلاف وتقليب صفحات، وشارك كتاباً كاملاً مع حساب آخر.';
	@override String get s1 => 'اضغط على "المكتبة" للانتقال إلى الكتب.';
	@override String get s2 => 'اضغط على زر الزائد لإنشاء كتاب جديد.';
	@override String get s3 => 'اسم الكتاب معبّأ مسبقاً: "دليل". اضغط على الحقل لتغييره، ثم تابع.';
	@override String get s4 => 'اضغط "حفظ" لإنشاء الكتاب.';
	@override String get s5 => 'اختر لون الكعب الذي يميّز الكتب على الرف، واضغط "حفظ". يُفتح الكتاب فوراً.';
	@override String get s6 => 'هذا هو الكتاب الذي أنشأته. من هنا تضيف إليه وصفات، وداخله تقلّب الصفحات وتقفز من الفهرس. الضغط المطوّل على كتاب في الرف يفتح المشاركة والغلاف وإعادة التسمية والحذف.';
}

// Path: walkthrough.topics.mealPlan
class _Translations$walkthrough$topics$mealPlan$ar extends Translations$walkthrough$topics$mealPlan$he {
	_Translations$walkthrough$topics$mealPlan$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الخطة الأسبوعية والتغذية';
	@override String get summary => 'خطة وجبات للأسبوع كله مع ملخّص غذائي لكل يوم، تغذّي قائمة التسوّق.';
	@override String get s1 => 'اضغط على "الوجبات" لتخطيط الأسبوع.';
	@override String get s2 => 'اضغط هنا لإنشاء خطة أسبوعية.';
	@override String get s3 => 'اسم الخطة معبّأ مسبقاً. في الأسفل اختر قالباً: حرّ، ثلاث وجبات يومياً أو ست.';
	@override String get s4 => 'اضغط "حفظ" لإنشاء الخطة.';
	@override String get s5 => 'ضع الوصفات في وجبات كل يوم. تجمع بطاقة التغذية السعرات والبروتين والكربوهيدرات والدهون حسب الحصص. اضغط على الرسم لفتح لوحة الأسبوع.';
	@override String get s6 => 'اللوحة: المتوسط اليومي، مجموع الأسبوع، عمود لكل يوم وتوزيع المغذّيات الكبرى. تُقدَّر القيم بالذكاء الاصطناعي لكل وصفة، لكل حصة.';
	@override String get s7 => 'زر المشاركة يرسل الخطة إلى حساب آخر، كمحرّر أو كمشاهد. أي تعديل من طرف يصل إلى الجميع.';
}

// Path: walkthrough.topics.groceries
class _Translations$walkthrough$topics$groceries$ar extends Translations$walkthrough$topics$groceries$he {
	_Translations$walkthrough$topics$groceries$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'قائمة التسوّق والأسعار';
	@override String get summary => 'قائمة تُبنى من الخطة، مع تعليم ما جُمع وتقدير للتكلفة من إيصالاتك، ومشاركة مع من يتسوّق معك.';
	@override String get s1 => 'اضغط على "التسوّق".';
	@override String get s2 => 'التحديث يعيد بناء القائمة من كل وصفات الخطة الأسبوعية.';
	@override String get s3 => 'اضغط على زر الزائد لإضافة عنصر يدوياً.';
	@override String get s4 => 'اسم العنصر معبّأ مسبقاً. اختر كمية ووحدة، أو ابدأ من منتج تعرفه إيصالاتك أصلاً.';
	@override String get s5 => 'اضغط "إضافة" ويدخل العنصر إلى القائمة.';
	@override String get s6 => 'اضغط هنا لفتح دفتر الأسعار.';
	@override String get s7 => 'امسح إيصالاً ويُحفظ سعر كل منتج. من هنا تحصل قائمة التسوّق على تقدير للتكلفة، وتكمل أسعار المجتمع الوسيطة ما لم تشترِه بعد.';
	@override String get shefi => 'اسأل شيفي عن هذه القائمة: ما ينقص لوجبة، ما يمكن استبداله، أو أضف عناصر بصوتك.';
}

// Path: walkthrough.topics.community
class _Translations$walkthrough$topics$community$ar extends Translations$walkthrough$topics$community$he {
	_Translations$walkthrough$topics$community$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المجتمع';
	@override String get summary => 'وصفات يشاركها الجميع، ومنتدى للأسئلة والأجوبة.';
	@override String get s1 => 'اضغط على "المجتمع".';
	@override String get s2 => 'وصفات مشتركة ومنتدى. أعجب بوصفة أو موضوع أو ردّ، احفظ وصفة عندك، وأرفق وصفة بردّ في المنتدى.';
	@override String get s3 => 'زر المشاركة ينشر وصفة من وصفاتك إلى المجتمع.';
}

// Path: walkthrough.topics.account
class _Translations$walkthrough$topics$account$ar extends Translations$walkthrough$topics$account$he {
	_Translations$walkthrough$topics$account$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الحساب والاشتراك والإعدادات';
	@override String get summary => 'إشعارات بدعوات المشاركة، والحساب مع الاشتراك المميّز والوصول المشترك والإعدادات ووضع العرض.';
	@override String get s1 => 'الإشعارات: دعوات لمشاركة الكتب والخطط، وتحديثات.';
	@override String get s2 => 'اضغط على الصورة لفتح حسابك.';
	@override String get s3 => 'الاشتراك المميّز: تحليلات ذكاء اصطناعي بلا حدّ يومي وبلا إعلانات. يحصل الحساب المجاني على حصة يومية يمكن توسيعها بمشاهدة فيديو قصير.';
	@override String get s4 => 'الوصول المشترك: من يشارك معك الكتب والخطط وقوائم التسوّق، وما شاركته أنت.';
	@override String get s5 => 'اضغط على "الإعدادات".';
	@override String get s6 => 'وضع العرض: فاتح أو داكن أو حسب الجهاز. في الإعدادات أيضاً اللغة والتفضيلات الغذائية ومسبّبات الحساسية. يمكن تشغيل هذا الدليل مجدداً من شاشة الدعم في الحساب.';
	@override String get shefi => 'شيفي، المساعد الذكي: هذا الزر العائم يفتح محادثة. اسأل كتابةً أو بصوتك، فيجيب شيفي ويضيف إلى الخطة ويبني قائمة أو يشغّل وضع الطبخ. داخل وصفة أو خطة أو قائمة، زر «اسأل شيفي» يتحدث عن هذا العنصر فقط.';
}

// Path: walkthrough.topics.settings
class _Translations$walkthrough$topics$settings$ar extends Translations$walkthrough$topics$settings$he {
	_Translations$walkthrough$topics$settings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الإعدادات والتفضيلات';
	@override String get summary => 'كل صف في الإعدادات والتفضيلات: الملف الشخصي، المشاركة، الإشعارات، اللغة، المظهر، حذف الحساب، يوم التسوّق، الأسعار، التغذية والكتب.';
	@override String get s1 => 'اضغط "الإعدادات": هنا الحساب والتطبيق.';
	@override String get s2 => 'الملف الشخصي: الاسم والصورة اللذان يراهما من تشاركهم، وطرق تسجيل الدخول المرتبطة.';
	@override String get s3 => 'الوصول المشترك: من يشارك معك الوصفات والكتب والخطط والقوائم، وما شاركته أنت. من هنا أيضًا تنضم برمز أو QR.';
	@override String get s4 => 'اضغط "إعدادات الإشعارات".';
	@override String get s5 => 'إشعارات الدفع: المفتاح الرئيسي. عندما يكون مطفأً لا يُرسل شيء؛ وتحته تختار ما يُرسل: الردود والدعوات والتحديثات ورسائل الفريق.';
	@override String get s6 => 'تذكيرات يوم التسوّق: متى نذكّرك قبل التسوّق. مجدولة على الجهاز، بمعزل عن الدفع.';
	@override String get s7 => 'اللغة: التبديل يترجم أيضًا وصفاتك وكتبك وخططك وقوائمك.';
	@override String get s8 => 'المظهر: فاتح أو داكن أو حسب الجهاز. يُحفظ الاختيار في الحساب وينتقل معك إلى الجهاز التالي.';
	@override String get s9 => 'حذف الحساب: يحذف الحساب وكل ما فيه نهائيًا بعد التأكيد. يُلغى اشتراك المتجر على حدة.';
	@override String get s10 => 'عودة إلى الحساب: اضغط "التفضيلات"، كيف يتصرف التطبيق من أجلك.';
	@override String get s11 => 'يوم التسوّق: اليوم الذي تُبنى حوله قائمة التسوّق وتُوقَّت التذكيرات.';
	@override String get s12 => 'أسعار المجتمع: عند التفعيل تنضم أسعار فواتيرك مجهولة الهوية إلى المتوسطات، وتُقدَّر الأسطر التي لم تشترها وفقها.';
	@override String get s13 => 'التفضيلات الغذائية ومسببات الحساسية: علّمها هنا ويبرزها التطبيق في الوصفات والوصفات المشتركة.';
	@override String get s14 => 'تقليب سريع في الكتب: القفز إلى صفحة بعيدة يقلّب صفحة واحدة فقط. عند الإيقاف يقلّب كل الصفحات في الطريق.';
	@override String get s15 => 'الأصوات: مؤثرات صوتية عند التقليب والإجراءات. يمكن إيقافها.';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Easy Plate',
			'common.save' => 'حفظ',
			'common.cancel' => 'إلغاء',
			'common.ok' => 'حسناً',
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
			'common.networkError' => 'لا يوجد اتصال بالإنترنت',
			'common.landscapeHint' => 'يفضّل العمل بالوضع الأفقي',
			'common.rotateLandscape' => 'تدوير',
			'common.rotatePortrait' => 'العودة للوضع الرأسي',
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
			'auth.blockedTitle' => 'تم حظر الحساب',
			'auth.blockedBody' => 'تم حظر هذا الحساب من قِبل مدير التطبيق. للتفاصيل تواصل معنا من شاشة الدعم.',
			'auth.phoneClaimedTitle' => 'هذا الرقم تابع لحساب موجود',
			'auth.phoneClaimedBody' => ({required Object phone}) => 'الرقم ${phone} مرتبط بالفعل بحساب EasyPlate آخر. للوصول إلى ذلك الحساب ووصفاته، سجّل الدخول بالطريقة التي استخدمتها سابقًا (Google أو Apple أو البريد) وتحقّق من الرقم هناك مجددًا.',
			'auth.phoneClaimedSignIn' => 'الدخول إلى حسابي الموجود',
			'auth.phoneClaimedCreateNew' => 'إنشاء حساب جديد على أي حال',
			'auth.phoneClaimedCreateNewConfirm' => 'سيُفتح حساب جديد فارغ لهذا الرقم. يبقى الحساب الموجود كما هو، لكن لن يمكن الوصول إليه بهذا الرقم بعد الآن.',
			'auth.sessionOtherDeviceTitle' => 'الحساب مسجّل الدخول على جهاز آخر',
			'auth.sessionOtherDeviceBody' => ({required Object platform, required Object since}) => 'هذا الحساب مفتوح الآن على ${platform}${since}. يمكن استخدامه على جهاز واحد في كل مرة: سجّل الخروج هناك ثم اضغط «حاول مجددًا».',
			'auth.sessionSince' => ({required Object date}) => ' منذ ${date}',
			'auth.sessionExpiredTitle' => 'انتهت صلاحية تسجيل الدخول',
			'auth.sessionExpiredBody' => 'يستمر تسجيل الدخول حتى شهر. سجّل الدخول من جديد للمتابعة.',
			'auth.sessionRetry' => 'حاول مجددًا',
			'auth.platformIos' => 'آيفون',
			'auth.platformAndroid' => 'هاتف أندرويد',
			'auth.platformOther' => 'جهاز آخر',
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
			'allergens.title' => 'مسببات الحساسية',
			'allergens.pick' => 'تحديد مسببات الحساسية',
			'allergens.contains' => 'يحتوي على',
			'allergens.mayContain' => 'قد يحتوي على',
			'allergens.gluten' => 'غلوتين',
			'allergens.milk' => 'حليب',
			'allergens.eggs' => 'بيض',
			'allergens.fish' => 'سمك',
			'allergens.shellfish' => 'مأكولات بحرية',
			'allergens.peanuts' => 'فول سوداني',
			'allergens.treeNuts' => 'مكسرات',
			'allergens.sesame' => 'سمسم',
			'allergens.soy' => 'صويا',
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
			'settings.appearance' => 'المظهر',
			'settings.themeSystem' => 'حسب الجهاز',
			'settings.themeLight' => 'فاتح',
			'settings.themeDark' => 'داكن',
			'settings.soundEffects' => 'المؤثرات الصوتية (تقليب الصفحات)',
			'settings.fastPageTurn' => 'تصفّح سريع في الكتاب',
			'settings.fastPageTurnHint' => 'القفز من جدول المحتويات أو التنقل السريع يقلّب صفحة واحدة فقط إلى الوجهة. أوقفه لتقليب كل الصفحات في الطريق.',
			'settings.sharedAccess' => 'إدارة المشاركة',
			'settings.noSharedAccess' => 'لم تشارك أي كتب أو قوائم بعد',
			'settings.communityPrices' => 'متوسط أسعار المستخدمين',
			'settings.communityPricesHint' => 'عندما لا يكون لديك سعر خاص بمنتج، اعرض السعر الوسيط الذي شاركه الآخرون',
			'settings.shoppingReminders' => 'تذكيرات يوم التسوق',
			'settings.shoppingRemindersHint' => 'تُرسل من الجهاز حسب يوم التسوق المختار',
			'settings.reminderTwoDaysBefore' => 'قبل يومين (مساءً)',
			'settings.reminderDayBefore' => 'قبل يوم (مساءً)',
			'settings.reminderSameDayMorning' => 'يوم التسوق (صباحًا)',
			'settings.reminderSameDayAfternoon' => 'يوم التسوق (بعد الظهر)',
			'settings.translatingContent' => 'جارٍ ترجمة وصفاتك وقوائمك…',
			'settings.translatedContent' => ({required Object count}) => 'تمت ترجمة ${count} عناصر',
			'settings.translationPartialTitle' => 'الترجمة لم تكتمل',
			'settings.translationPartial' => ({required Object count}) => 'بقي ${count} عناصر بلغتها الأصلية. يمكن المحاولة لاحقًا.',
			'settings.translationFailed' => 'فشلت الترجمة. بقي المحتوى بلغته الأصلية.',
			'settings.account' => 'الحساب',
			'settings.notifications' => 'الإشعارات',
			'settings.notificationsHint' => 'أي التنبيهات تصلك، وكيف',
			'settings.settingsHint' => 'الحساب، الإشعارات، اللغة والمظهر',
			'settings.dangerZone' => 'منطقة الخطر',
			'settings.deleteAccount' => 'حذف الحساب',
			'settings.deleteAccountHint' => 'حذف الحساب وكل ما فيه نهائياً',
			'settings.deleteAccountTitle' => 'حذف الحساب نهائياً؟',
			'settings.deleteAccountBody' => 'سيُحذف حسابك ووصفاتك وكتبك وخطط وجباتك وقوائم التسوق والإيصالات والصور والمنشورات والردود نهائياً من خوادمنا ومن هذا الجهاز ولا يمكن استرجاعها. ما شاركته سيُزال أيضاً ممن شاركتهم إياه. الاشتراك النشط لا يُلغى تلقائياً: ألغِه من App Store أو Google Play.',
			'settings.deleteAccountConfirm' => 'حذف نهائي',
			'settings.deletingAccount' => 'جارٍ حذف الحساب…',
			'settings.deleteAccountFailed' => 'فشل حذف الحساب. حاول مرة أخرى أو راسلنا على support@aieasyplate.app.',
			'settings.deleteAccountHousehold' => 'أنت مالك أسرة مشتركة. أغلقها أولاً من شاشة "الأسرة" ثم حاول مرة أخرى.',
			'notificationSettings.title' => 'إعدادات الإشعارات',
			'notificationSettings.push' => 'الإشعارات الفورية',
			'notificationSettings.pushHint' => 'تنبيهات على هذا الجهاز. عند الإيقاف لا يُرسل شيء إلى الهاتف؛ يستمر صندوق الإشعارات بالامتلاء.',
			'notificationSettings.pushDenied' => 'إشعارات EasyPlate محظورة في إعدادات الجهاز. اسمح بها هناك لتلقي التنبيهات.',
			'notificationSettings.community' => 'المجتمع',
			'notificationSettings.repliesOnMyPosts' => 'الردود على منشوراتي',
			'notificationSettings.repliesOnMyPostsHint' => 'أجاب أحدهم في نقاش فتحته',
			'notificationSettings.repliesOnThreads' => 'الردود في نقاشات شاركت فيها',
			'notificationSettings.repliesOnThreadsHint' => 'رد جديد في نقاش رددت فيه',
			'notificationSettings.sharing' => 'المشاركة',
			'notificationSettings.shareInvites' => 'دعوات المشاركة',
			'notificationSettings.shareInvitesHint' => 'شارك أحدهم معك وصفة أو كتابًا أو خطة. تصل الدعوة دائمًا إلى الصندوق؛ هذا هو التنبيه فقط.',
			'notificationSettings.sharedRecipeUpdates' => 'تحديثات الوصفات المحفوظة',
			'notificationSettings.sharedRecipeUpdatesHint' => 'غيّر الكاتب وصفة من المجتمع حفظتها',
			'notificationSettings.easyPlate' => 'من EasyPlate',
			'notificationSettings.adminReplies' => 'الردود على رسائل الدعم الخاصة بي',
			'notificationSettings.announcements' => 'الإعلانات',
			'notificationSettings.announcementsHint' => 'أخبار وتحديثات من فريق EasyPlate',
			'notificationSettings.inApp' => 'أثناء فتح التطبيق',
			'notificationSettings.foregroundPopups' => 'عرض التنبيهات كنافذة منبثقة',
			'notificationSettings.foregroundPopupsHint' => 'التنبيه الذي يصل أثناء وجودك في التطبيق يفتح بطاقة صغيرة. عند الإيقاف يذهب إلى الصندوق فقط.',
			'notificationSettings.reminders' => 'تذكيرات التسوق',
			'preferences.title' => 'التفضيلات',
			'preferences.hint' => 'التسوق، الاحتياجات الغذائية وسلوك الكتب',
			'preferences.shopping' => 'التسوق',
			'preferences.books' => 'كتب الوصفات',
			'more.title' => 'المزيد',
			'more.settings' => 'الإعدادات',
			'more.profile' => 'ملفي الشخصي',
			'more.support' => 'الدعم',
			'more.supportTitle' => 'كيف يمكننا المساعدة؟',
			'more.supportBody' => 'اكتبوا لنا وسنعود إليكم قريبًا.',
			'more.whatsapp' => 'راسلونا على واتساب',
			'more.email' => 'إرسال بريد',
			'more.supportUnavailable' => 'تعذّر فتح التطبيق',
			'more.preferences' => 'التفضيلات',
			'more.help' => 'الدعم والمعلومات',
			'more.helpHint' => 'الدعم وسياسة الخصوصية وشروط الخدمة',
			'more.legal' => 'معلومات قانونية',
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
			'books.spineColor' => 'لون الكعب',
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
			'recipe.communityUpdateTitle' => 'هذه الوصفة مشاركة',
			'recipe.communityUpdateBody' => 'تحديث نسخة المجتمع أيضًا، أم نسختك فقط؟',
			'recipe.communityUpdateBoth' => 'المجتمع أيضًا',
			'recipe.communityUpdateLocal' => 'نسختي فقط',
			'recipe.communityUpdated' => 'تم تحديث نسخة المجتمع',
			'recipe.communityGone' => 'الوصفة لم تعد في المجتمع، حُفظت لك فقط',
			'cookMode.title' => 'وضع الطبخ',
			'cookMode.start' => 'ابدأ الطبخ',
			'cookMode.stepOf' => ({required Object n, required Object total}) => 'الخطوة ${n} من ${total}',
			'cookMode.ingredients' => 'المكوّنات',
			'cookMode.inThisStep' => 'في هذه الخطوة',
			'cookMode.timer' => 'مؤقّت',
			'cookMode.startTimer' => 'تشغيل المؤقّت',
			'cookMode.pause' => 'إيقاف مؤقت',
			'cookMode.resume' => 'متابعة',
			'cookMode.reset' => 'إعادة ضبط',
			'cookMode.timeUp' => 'انتهى الوقت!',
			'cookMode.next' => 'الخطوة التالية',
			'cookMode.previous' => 'السابقة',
			'cookMode.finish' => 'انتهيت من الطبخ',
			'cookMode.finishedTitle' => 'بالهناء والشفاء!',
			'cookMode.finishedBody' => 'اكتملت كل الخطوات. يمكن للشاشة أن تنطفئ الآن.',
			'cookMode.screenOn' => 'تبقى الشاشة مضاءة أثناء الطبخ',
			'cookMode.noSteps' => 'لا توجد خطوات لهذه الوصفة بعد',
			'cookMode.runningOnStep' => ({required Object n}) => 'المؤقّت يعمل في الخطوة ${n}',
			'cookMode.inProgress' => 'الطبخ قيد التنفيذ',
			'cookMode.inProgressBody' => ({required Object recipe, required Object n, required Object total}) => '"${recipe}" · الخطوة ${n} من ${total}',
			'cookMode.resumeCooking' => 'متابعة',
			'cookMode.endCooking' => 'إنهاء',
			'cookMode.stepLabel' => ({required Object n}) => 'الخطوة ${n}',
			'cookMode.ongoingBody' => ({required Object time, required Object total, required Object n}) => 'ينتهي في ${time} · ${total} · الخطوة ${n}',
			'cookMode.timeUpBody' => ({required Object n}) => 'الخطوة ${n}: انتهى الوقت',
			'cookMode.runningTimers' => 'مؤقّتات تعمل',
			'cookMode.premiumOnly' => 'وضع الطبخ جزء من EasyPlate Premium',
			'nutrition.title' => 'القيم الغذائية',
			'nutrition.perServing' => 'للحصة',
			'nutrition.perServingHint' => 'جميع القيم لحصة واحدة. اتركه فارغًا لإزالة التقدير.',
			'nutrition.servings' => 'حصص',
			'nutrition.servingsCount' => ({required Object count}) => '${count} حصص',
			'nutrition.calories' => 'سعرات حرارية',
			'nutrition.kcal' => 'سعرة',
			'nutrition.protein' => 'بروتين',
			'nutrition.carbs' => 'كربوهيدرات',
			'nutrition.fat' => 'دهون',
			'nutrition.gramsShort' => 'غ',
			'nutrition.estimate' => 'تقدير بالذكاء الاصطناعي',
			'nutrition.estimating' => 'جارٍ تقدير القيم الغذائية…',
			'nutrition.estimateFailed' => 'فشل التقدير، حاول مرة أخرى',
			'nutrition.none' => 'لا توجد قيم غذائية لهذه الوصفة بعد',
			'nutrition.noneHint' => 'يمكن للذكاء الاصطناعي تقدير السعرات والبروتين والكربوهيدرات والدهون من قائمة المكونات',
			'nutrition.estimated' => 'تم تحديث القيم الغذائية',
			'nutrition.editorServings' => 'عدد الحصص',
			'nutrition.editorCalories' => 'سعرات لكل حصة',
			'nutrition.editorProtein' => 'بروتين (غ)',
			'nutrition.editorCarbs' => 'كربوهيدرات (غ)',
			'nutrition.editorFat' => 'دهون (غ)',
			'nutrition.dashboard' => 'لوحة التغذية',
			'nutrition.weekly' => 'هذا الأسبوع',
			'nutrition.today' => 'اليوم',
			'nutrition.dayTotal' => 'إجمالي اليوم',
			'nutrition.weekTotal' => 'إجمالي الأسبوع',
			'nutrition.dailyAverage' => 'المتوسط لكل يوم مخطط',
			'nutrition.perMeal' => 'حسب الوجبة',
			'nutrition.perDay' => 'حسب اليوم',
			'nutrition.noPlanned' => 'لم يتم التخطيط لوجبات بوصفات بعد',
			'nutrition.missingCount' => ({required Object count}) => '${count} عناصر بدون قيم غذائية',
			'nutrition.macroSplit' => 'توزيع السعرات',
			'nutrition.kcalPerDay' => 'سعرة في اليوم',
			'nutrition.openDashboard' => 'اللوحة الأسبوعية',
			'nutrition.perRecipe' => 'الوصفة كاملة',
			'nutrition.perRecipeServings' => ({required Object count}) => '${count} حصص',
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
			'community.savedTag' => 'محفوظة لديك',
			'community.removeSaved' => 'إزالة من الوصفات المحفوظة',
			'community.removeSavedConfirm' => 'ستُزال الوصفة من وصفاتك المحفوظة. يمكنك حفظها مجدداً من المجتمع.',
			'community.oneNewPost' => 'منشور جديد واحد',
			'community.newPosts' => ({required Object count}) => '${count} منشورات جديدة',
			'community.replyFailed' => 'تعذّر إرسال ردك',
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
			'sharing.self' => 'لا يمكنك المشاركة مع نفسك',
			'sharing.failed' => 'فشلت المشاركة، حاولوا مجددًا',
			'sharing.pendingInvites' => 'دعوات معلّقة',
			'sharing.noPendingInvites' => 'لا توجد دعوات معلّقة',
			'sharing.sharedByMe' => 'ما شاركته',
			'sharing.sharedWithMe' => 'ما تمت مشاركته معي',
			'sharing.nothingSharedByMe' => 'لم تشارك أي شيء بعد',
			'sharing.nothingSharedWithMe' => 'لم تتم مشاركة أي شيء معك بعد',
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
			'sharing.shareBook' => 'مشاركة الكتاب',
			'sharing.sharePlan' => 'مشاركة الخطة',
			'sharing.acceptedBook' => 'تمت إضافة الكتاب إلى مكتبتك',
			'sharing.acceptedPlan' => 'تمت إضافة الخطة إلى خططك',
			'sharing.viewerCannotEditBook' => 'تمت مشاركة هذا الكتاب معك للعرض فقط',
			'sharing.viewerCannotEditPlan' => 'تمت مشاركة هذه الخطة معك للعرض فقط',
			'sharing.kindRecipe' => 'وصفة',
			'sharing.kindBook' => 'كتاب',
			'sharing.kindPlan' => 'خطة',
			'sharing.recipesTravel' => 'ستتم مشاركة الوصفات الموجودة بداخله معه',
			'sharing.shareList' => 'مشاركة قائمة التسوق',
			'sharing.acceptedList' => 'أُضيفت القائمة إلى قوائم التسوق لديك',
			'sharing.viewerCannotEditList' => 'هذه القائمة مشاركة معك للعرض فقط',
			'sharing.kindList' => 'قائمة تسوق',
			'notifications.title' => 'الإشعارات',
			'notifications.empty' => 'لا توجد إشعارات',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => 'شارك/ت ${name} معك "${recipe}"',
			'notifications.asViewer' => 'للعرض فقط',
			'notifications.asEditor' => 'للتعديل',
			'notifications.markAllRead' => 'تعليم الكل كمقروء',
			'notifications.openRecipe' => 'فتح الوصفة',
			'notifications.alreadyHandled' => 'تمت معالجة هذه الدعوة',
			'notifications.recipeUpdated' => ({required Object name, required Object recipe}) => '${name} حدّث/ت "${recipe}"',
			'notifications.recipeUpdatedHint' => 'هناك نسخة جديدة من وصفة حفظتها',
			'notifications.refreshCopy' => 'التحديث للنسخة الجديدة',
			'notifications.keepCopy' => 'الاحتفاظ بنسختي',
			'notifications.refreshed' => 'تم تحديث نسختك إلى الجديدة',
			'notifications.keptCopy' => 'بقيت نسختك كما هي',
			'notifications.recipeGone' => 'الوصفة لم تعد في المجتمع',
			'notifications.deleteAll' => 'حذف كل الإشعارات',
			'notifications.deleteAllBody' => 'ستُحذف كل الإشعارات.',
			'notifications.openInbox' => 'فتح الإشعارات',
			'notifications.sharedBook' => ({required Object name, required Object recipe}) => '${name} شارك/ت معك الكتاب "${recipe}"',
			'notifications.sharedPlan' => ({required Object name, required Object recipe}) => '${name} شارك/ت معك الخطة "${recipe}"',
			'notifications.adminReply' => 'رد من فريق EasyPlate على رسالتك',
			'notifications.adminReplyQuote' => ({required Object excerpt}) => 'رسالتك: "${excerpt}"',
			'notifications.adminMessage' => 'رسالة من EasyPlate',
			'notifications.forumReplyOnMyPost' => ({required Object name, required Object post}) => 'ردّ ${name} على منشورك "${post}"',
			'notifications.forumReplyOnThread' => ({required Object name, required Object post}) => 'ردّ ${name} في "${post}"',
			'notifications.openThread' => 'فتح النقاش',
			'notifications.threadGone' => 'تم حذف هذا النقاش',
			'notifications.settings' => 'الإعدادات',
			'notifications.sharedList' => ({required Object name, required Object recipe}) => '${name} شارك/ت معك قائمة التسوق "${recipe}"',
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
			_ => null,
		} ?? switch (path) {
			'editor.savePlainHint' => 'حفظ التغييرات كما هي، بدون انتظار',
			'editor.saveWithAi' => 'حفظ مع مراجعة AI',
			'editor.saveWithAiHint' => 'تصحيح الإملاء ومطابقة الأوقات المذكورة في الخطوات',
			'ingestion.title' => 'إضافة وصفة',
			'ingestion.pasteText' => 'لصق نص',
			'ingestion.pasteHint' => 'الصق هنا وصفة من واتساب أو من أي مصدر آخر',
			'ingestion.webSearch' => 'بحث في الإنترنت',
			'ingestion.urlScrape' => 'رابط موقع',
			'ingestion.socialVideo' => 'فيديو من الشبكات',
			'ingestion.socialVideoHint' => 'الصق رابط فيديو من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك',
			'ingestion.socialUnreadable' => 'تعذّرت قراءة هذا الفيديو. قد يكون الحساب خاصًا أو حظرت المنصة الطلب. يمكنك نسخ الوصف ولصقه كنص.',
			'ingestion.aiRequest' => 'طلب وصفة',
			'ingestion.aiRequestHint' => 'صِف ما تريد تحضيره. مثلاً: عصيدة سميد لطفلة بعمر سنة مع الفواكه',
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
			'ingestion.generate' => 'إنشاء وصفة',
			'ingestion.generating' => 'جارٍ كتابة الوصفة...',
			'ingestion.file' => 'تسجيل / PDF',
			'ingestion.fileHint' => 'يمكنك أيضًا مشاركة تسجيل أو PDF مباشرةً إلى Easy Plate من أي تطبيق عبر زر المشاركة المعتاد.',
			'ingestion.chooseFile' => 'اختيار ملف',
			'ingestion.replaceFile' => 'ملف آخر',
			'ingestion.fileTooLarge' => 'الملفات كبيرة جدًا. الحد الإجمالي هو 10MB، نحو عشر دقائق من التسجيل.',
			'ingestion.fileUnsupported' => 'يمكن تحليل ملفات الصوت وملفات PDF فقط.',
			'ingestion.sharedIn' => ({required Object app}) => 'من ${app}',
			'ingestion.addFile' => 'إضافة ملف',
			'ingestion.filesAsOne' => ({required Object count}) => '${count} ملفات — تُحلَّل معًا كوصفة واحدة، بالترتيب',
			'ingestion.shareMoreHint' => 'يمكنك العودة إلى واتساب ومشاركة تسجيل آخر — سينضم إلى القائمة هنا.',
			'ingestion.chooseSource' => 'من أين تأتي الوصفة؟',
			'ingestion.pasteTextDescription' => 'وصلتك وصفة على واتساب أو نسختها من موقع أو رسالة؟ الصق النص هنا كما هو. سيتعرّف النموذج على اسم الطبق والمكوّنات بكمياتها وخطوات التحضير، ويرتّب كل شيء بصيغة موحّدة. بلا حدّ يومي.',
			'ingestion.webSearchDescription' => 'اكتب ما تشتهي تحضيره وسنبحث لك عن وصفات في الإنترنت. من النتائج يمكنك قراءة الوصفة الأصلية كما هي، أو استيرادها إلى الصيغة المنظّمة في التطبيق.',
			'ingestion.webSearchHint' => 'مثلًا: شكشوكة، كعكة الجبن، كبة شمندر',
			'ingestion.urlScrapeDescription' => 'الصق رابطًا لصفحة وصفة في موقع أو مدونة. سنقرأ الصفحة ونتجاهل الإعلانات والقصص حولها، ونستخرج الوصفة فقط: المكوّنات والكميات والخطوات. في مواقع كثيرة لا يستهلك هذا حتى من حصّتك اليومية.',
			'ingestion.urlScrapeHint' => 'https://www.example.com/recipe/...',
			'ingestion.socialVideoDescription' => 'الصق رابط فيديو من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك. سنشاهد الفيديو عنك ونستمع لما يُقال ونقرأ الترجمة والوصف، ونحوّله إلى وصفة مكتوبة ومرتّبة. يستغرق ذلك نحو دقيقة.',
			'ingestion.aiRequestDescription' => 'ليست لديك وصفة، فقط فكرة؟ صِف الطبق ولمن هو وما يهمّك، وسيكتب لك النموذج وصفة كاملة وفق التفضيلات الغذائية التي حدّدتها.',
			'ingestion.manualDescription' => 'اكتب الوصفة بنفسك مباشرة في المحرّر المنظّم: الاسم، المكوّنات بكمياتها ووحداتها، وخطوات التحضير. بلا ذكاء اصطناعي وبلا انتظار. مناسب لوصفة الجدّة التي تحفظها عن ظهر قلب.',
			'ingestion.fileDescription' => 'اختر ملفًا صوتيًا يقرأ فيه أحدهم الوصفة أو يرويها، أو رسالة صوتية من واتساب، أو ملف PDF لوصفة. سنفرّغ ونقرأ كل شيء ونستخرج وصفة مرتّبة. يمكن إرفاق عدة ملفات وتُحلَّل معًا كوصفة واحدة.',
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
			'mealPlanner.planOptions' => 'خيارات الخطة',
			'mealPlanner.deletePlan' => 'حذف الخطة',
			'mealPlanner.deletePlanConfirm' => ({required Object name}) => 'حذف الخطة "${name}"؟ ستُحذف وجباتها أيضاً.',
			'mealPlanner.leavePlanConfirm' => ({required Object name}) => 'مغادرة الخطة المشتركة "${name}"؟ ستُزال من قائمتك.',
			'mealPlanner.planDeleted' => 'تم حذف الخطة',
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
			'groceryList.myLists' => 'قوائمي',
			'groceryList.listsCount' => ({required Object count}) => '${count} قوائم',
			'groceryList.oneList' => 'قائمة واحدة',
			'groceryList.newList' => 'قائمة جديدة',
			'groceryList.newListTitle' => 'قائمة تسوق جديدة',
			'groceryList.listName' => 'اسم القائمة',
			'groceryList.defaultListName' => 'قائمة التسوق',
			'groceryList.fromPlans' => 'من القوائم الغذائية',
			'groceryList.fromPlansHint' => 'تجمع وصفات خطط وجباتك',
			'groceryList.fromRecipe' => 'من وصفة',
			'groceryList.fromRecipeHint' => 'مكونات وصفة واحدة',
			'groceryList.emptyList' => 'قائمة فارغة',
			'groceryList.emptyListHint' => 'تضيف العناصر يدويًا',
			'groceryList.sourcePlans' => 'من القوائم الغذائية',
			'groceryList.sourceRecipe' => ({required Object title}) => 'من وصفة "${title}"',
			'groceryList.sourceManual' => 'قائمة يدوية',
			'groceryList.renameList' => 'إعادة تسمية القائمة',
			'groceryList.deleteList' => 'حذف القائمة',
			'groceryList.deleteListConfirm' => ({required Object name}) => 'سيتم حذف "${name}" وكل عناصرها.',
			'groceryList.progress' => ({required Object checked, required Object total}) => '${checked}/${total}',
			'groceryList.servings' => 'حصص',
			'groceryList.timesOver' => 'الكمية',
			'groceryList.scaleValue' => ({required Object value}) => '×${value}',
			'groceryList.rebuildFromRecipe' => 'إعادة البناء من الوصفة',
			'groceryList.createFromRecipe' => 'إنشاء قائمة تسوق',
			'groceryList.createList' => 'إنشاء القائمة',
			'groceryList.recipeListTitle' => 'قائمة تسوق من وصفة',
			'groceryList.recipeListHint' => 'مكونات الوصفة حسب الكمية التي تحضّرها',
			'groceryList.listCreated' => ({required Object name}) => 'تم إنشاء القائمة "${name}"',
			'groceryList.openList' => 'فتح القائمة',
			'groceryList.stayHere' => 'البقاء هنا',
			'groceryList.noIngredients' => 'لا توجد في هذه الوصفة مكونات للشراء',
			'groceryList.addFirstItem' => 'إضافة عنصر',
			'groceryList.leaveListConfirm' => ({required Object name}) => 'مغادرة القائمة المشتركة "${name}"؟ ستُزال من قوائمك.',
			'receipt.title' => 'مسح إيصال',
			'receipt.subtitle' => 'صوّر إيصالاً أو ارفع PDF، وتُحفظ الأسعار لقائمة التسوق',
			'receipt.camera' => 'تصوير الإيصال',
			'receipt.cameraHint' => 'إيصال طويل؟ التقط عدة صور وسندمجها',
			'receipt.gallery' => 'اختيار من المعرض',
			'receipt.pdf' => 'ملف PDF',
			'receipt.addPhoto' => 'صورة أخرى',
			'receipt.scan' => 'مسح',
			'receipt.scanning' => 'جارٍ قراءة الإيصال…',
			'receipt.pagesCount' => ({required Object count}) => '${count} صور',
			'receipt.scanFailed' => 'تعذّرت قراءة الإيصال. جرّب صورة أوضح أو PDF.',
			'receipt.reviewTitle' => 'ما تم التقاطه',
			'receipt.reviewSubtitle' => 'صحّح الأسماء والأسعار قبل الحفظ',
			'receipt.store' => 'المتجر',
			'receipt.date' => 'التاريخ',
			'receipt.receiptTotal' => 'إجمالي الإيصال',
			'receipt.itemsTotal' => 'إجمالي المنتجات الملتقطة',
			'receipt.captured' => 'المنتجات الملتقطة',
			'receipt.capturedCount' => ({required Object count}) => '${count} منتجات',
			'receipt.unreadable' => 'تعذّر الالتقاط',
			'receipt.unreadableHint' => 'ملاحظات عن السطور التي تعذّرت قراءتها. يمكنك إضافتها يدويًا أدناه.',
			'receipt.addLine' => 'إضافة منتج',
			'receipt.itemName' => 'اسم المنتج',
			'receipt.price' => 'سعر الوحدة',
			'receipt.quantity' => 'الكمية',
			'receipt.removeLine' => 'إزالة السطر',
			'receipt.shareToggle' => 'مشاركة الأسعار مع المجتمع',
			'receipt.shareHint' => 'أسماء المنتجات والأسعار فقط. لا المتجر ولا التاريخ ولا من دفع.',
			'receipt.save' => 'حفظ الأسعار',
			'receipt.saved' => ({required Object count}) => 'تم حفظ ${count} أسعار',
			'receipt.savedShared' => ({required Object count}) => 'تم حفظ ومشاركة ${count} أسعار',
			'receipt.nothingToSave' => 'لا منتجات للحفظ',
			'receipt.estimated' => 'تقدير بناءً على بيانات سابقة',
			'receipt.estimatedTotal' => 'التكلفة التقديرية',
			'receipt.noData' => 'لا بيانات',
			'receipt.fromReceipt' => 'من إيصالك',
			'receipt.fromCommunity' => 'وسيط المستخدمين',
			'receipt.unpriced' => ({required Object count}) => '${count} عناصر بلا سعر',
			'receipt.priceBook' => 'أسعاري',
			'receipt.priceBookEmpty' => 'لم تُمسح أي إيصالات بعد. امسح الأول لترى تكلفة التسوق.',
			'receipt.deleteRecord' => 'حذف السعر',
			'receipt.cameraGuide' => 'ضع الإيصال داخل الإطار',
			'receipt.cameraHold' => 'اثبت قليلًا…',
			'receipt.cameraCaptured' => 'تم الالتقاط!',
			'receipt.cameraUnavailable' => 'لا يمكن الوصول إلى الكاميرا',
			'receipt.perUnit' => 'للوحدة',
			'receipt.perKg' => 'للكيلو',
			'receipt.perLiter' => 'لللتر',
			'receipt.printedAs' => ({required Object name}) => 'مطبوع: ${name}',
			'receipt.receipts' => 'الإيصالات',
			'receipt.prices' => 'الأسعار',
			'receipt.sortBy' => 'ترتيب',
			'receipt.sortDate' => 'التاريخ',
			'receipt.sortStore' => 'المتجر',
			'receipt.sortTotal' => 'المبلغ',
			'receipt.sortName' => 'الاسم',
			'receipt.noReceipts' => 'لا إيصالات محفوظة بعد',
			'receipt.noPrices' => 'لا أسعار محفوظة بعد',
			'receipt.deleteReceipt' => 'حذف الإيصال',
			'receipt.deleteReceiptBody' => 'سيُحذف الإيصال وكل الأسعار المقروءة منه.',
			'receipt.addPrice' => 'إضافة سعر',
			'receipt.addPriceHint' => 'بدون إيصال: سعر دفعته أو تعرفه',
			'receipt.manualSource' => 'أُدخل يدويًا',
			'receipt.lastPaid' => 'آخر دفع',
			'receipt.priceSaved' => 'تم حفظ السعر',
			'receipt.itemsInReceipt' => ({required Object count}) => '${count} منتجات',
			'receipt.search' => 'بحث عن منتج',
			'receipt.viewImage' => 'صورة الإيصال',
			'receipt.noImage' => 'لم تُحفظ صورة لهذا الإيصال',
			'receipt.pdfFile' => 'إيصال من ملف PDF',
			'receipt.filter' => 'تصفية',
			'receipt.filterAll' => 'الكل',
			'receipt.periodAll' => 'كل الفترة',
			'receipt.period30' => '30 يومًا',
			'receipt.period90' => '90 يومًا',
			'receipt.sourceReceipt' => 'من الإيصالات',
			'receipt.sourceManual' => 'أُدخلت يدويًا',
			'receipt.deleteProduct' => 'حذف المنتج',
			'receipt.deleteProductBody' => 'ستُحذف كل الأسعار المحفوظة لهذا المنتج.',
			'receipt.pickFromPrices' => 'اختيار من أسعاري',
			'receipt.pickerTitle' => 'منتجاتي',
			'receipt.existingPrice' => ({required Object price}) => 'معروف مسبقًا: ${price}',
			'receipt.keepNew' => 'السعر الجديد',
			'receipt.keepOld' => 'السعر القديم',
			'receipt.keepAverage' => 'المتوسط',
			'receipt.deleteReceiptOnly' => 'حذف الإيصال فقط',
			'receipt.deleteReceiptOnlyHint' => 'تبقى الأسعار المقروءة منه',
			'receipt.deleteReceiptAndPrices' => 'حذف الإيصال وأسعاره',
			'receipt.deleteAll' => 'حذف كل الأسعار',
			'receipt.deleteAllBody' => 'ستُحذف كل الأسعار والإيصالات والاختيارات. لا يمكن التراجع.',
			'receipt.pricingTitle' => 'أي سعر يُستخدم',
			'receipt.pricingLatest' => 'الأحدث',
			'receipt.pricingAverage' => 'متوسط الكل',
			'receipt.pricingStore' => 'حسب المتجر',
			'receipt.pricingReceipts' => 'إيصالات مختارة',
			'receipt.pricingActive' => ({required Object price}) => 'المستخدم: ${price}',
			'receipt.history' => 'سجل الأسعار',
			'receipt.noStore' => 'بدون متجر',
			'receipt.pricingSaved' => 'تم حفظ الاختيار',
			'receipt.renameStore' => 'تغيير اسم المتجر',
			'receipt.storeName' => 'اسم المتجر',
			'receipt.allStores' => 'كل المتاجر',
			'receipt.applyFilters' => 'تطبيق',
			'receipt.clearFilters' => 'مسح',
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
			'image.generate' => 'إنشاء صورة بالذكاء الاصطناعي',
			'image.generating' => 'جارٍ إنشاء الصورة… يستغرق ذلك بضع ثوانٍ',
			'image.generateFailed' => 'فشل إنشاء الصورة، حاول مرة أخرى',
			'image.coverTitle' => 'أي غلاف تريد إنشاءه؟',
			'image.coverHint' => 'اختر فئة أو اكتب شيئًا أو كليهما',
			'image.coverFreeText' => 'نص حر، مثلًا: برغر',
			'image.coverRequired' => 'اختر فئة أو اكتب شيئًا',
			'image.coverGenerate' => 'إنشاء الغلاف',
			'image.themeKids' => 'أطفال',
			'image.themeHealthy' => 'صحي',
			'image.themeIndulgent' => 'دسم ولذيذ',
			'image.themeSweets' => 'حلويات ومخبوزات',
			'image.themeMeat' => 'لحوم ومشاوي',
			'image.themeVegan' => 'نباتي',
			'image.themeHolidays' => 'أعياد',
			'image.themeQuick' => 'سريع وبسيط',
			'image.webSearch' => 'بحث صور في جوجل',
			'image.webSearchTitle' => 'بحث عن صورة',
			'image.webSearchHint' => 'عمّ تبحث؟ مثلاً: كبة شمندر',
			'image.webSearchEmpty' => 'لم يتم العثور على صور، جرّب كلمات أخرى',
			'image.webSearchFailed' => 'فشل البحث، حاول مرة أخرى',
			'image.webSearchUnavailable' => 'بحث الصور غير متاح حالياً',
			'image.webSearchEnd' => 'هذه كل النتائج',
			'image.webSearchDownloadFailed' => 'تعذّر تنزيل هذه الصورة، جرّب صورة أخرى',
			'nav.library' => 'المكتبة',
			'nav.recipes' => 'الوصفات',
			'nav.mealPlan' => 'الوجبات',
			'nav.groceries' => 'التسوّق',
			'nav.settings' => 'الإعدادات',
			'nav.community' => 'المجتمع',
			'update.forcedTitle' => 'التحديث مطلوب',
			'update.forcedBody' => ({required Object version}) => 'لم تعد هذه النسخة من EasyPlate مدعومة. حدِّث إلى ${version} للمتابعة.',
			'update.optionalTitle' => 'صدرت نسخة جديدة',
			'update.optionalBody' => ({required Object version}) => 'النسخة ${version} من EasyPlate متوفرة في المتجر مع آخر التحسينات.',
			'update.updateNow' => 'تحديث الآن',
			'update.later' => 'تخطٍ',
			'ads.badge' => 'إعلان',
			'ads.freeViewsLeft' => ({required Object count}) => 'تبقّى لك ${count} وصفات مجانية لليوم',
			'ads.rewardedViewsLeft' => ({required Object count}) => 'تبقّى ${count} فتحات بفيديو قصير لليوم',
			'ads.sharedQuotaReached' => 'وصلت إلى الحد اليومي للوصفات المشتركة. سيُعاد ضبطه غدًا!',
			'ads.unlockRecipeTitle' => 'فتح وصفة مشتركة',
			'ads.unlockRecipeMessage' => ({required Object count}) => 'شاهد فيديو قصيرًا لفتح هذه الوصفة (تبقّى ${count} لليوم)',
			'ads.aiQuotaLeft' => ({required Object remaining, required Object total}) => 'تبقّى لك ${remaining}/${total} استخراجات بالذكاء الاصطناعي لليوم',
			'ads.aiQuotaReached' => 'وصلت إلى الحد اليومي لاستخراجات الذكاء الاصطناعي. سيُفتح غدًا!',
			'ads.aiLockedHint' => 'الاستخراج من رابط يتطلب مشاهدة فيديو قصير',
			'ads.unlockAiTitle' => 'استخراج وصفة بالذكاء الاصطناعي',
			'ads.unlockAiMessage' => ({required Object count}) => 'شاهد فيديو قصيرًا لاستخراج الوصفة من الرابط (تبقّى ${count} لليوم)',
			'ads.watchVideo' => 'مشاهدة الفيديو',
			'ads.parseWithVideo' => 'مشاهدة فيديو ثم التحليل',
			'ads.blockedForToday' => 'مغلق لليوم',
			'ads.loadingVideo' => 'جارٍ تحميل الفيديو...',
			'ads.videoNotCompleted' => 'لم يكتمل الفيديو، تبقى الوصفة مغلقة',
			'ads.videoUnavailable' => 'لا يوجد فيديو متاح الآن، حاول مجددًا بعد قليل',
			'premium.title' => 'إيزي-بلايت بريميوم',
			'premium.headline' => 'بلا إعلانات، بلا حدود',
			'premium.subtitle' => 'كل ما يقدّمه إيزي-بلايت، دون انتظار الغد.',
			'premium.benefitNoAds' => 'بلا إعلانات في خلاصات المجتمع',
			'premium.benefitShared' => 'وصفات مشتركة بلا حدّ يومي',
			'premium.benefitAi' => ({required Object count}) => 'استخراج الوصفات بالذكاء الاصطناعي من أي رابط، حتى ${count} في اليوم',
			'premium.periodWeekly' => 'أسبوعي',
			'premium.periodMonthly' => 'شهري',
			'premium.periodTwoMonth' => 'كل شهرين',
			'premium.periodThreeMonth' => 'ربع سنوي',
			'premium.periodSixMonth' => 'كل 6 أشهر',
			'premium.periodAnnual' => 'سنوي',
			'premium.periodLifetime' => 'مدى الحياة',
			'premium.bestValue' => 'الأوفر',
			'premium.subscribeFor' => ({required Object price}) => 'الاشتراك مقابل ${price}',
			'premium.buyFor' => ({required Object price}) => 'الشراء مقابل ${price}',
			'premium.restore' => 'استعادة المشتريات',
			'premium.restored' => 'تمت استعادة اشتراكك',
			'premium.nothingToRestore' => 'لا توجد مشتريات لاستعادتها',
			'premium.activeTitle' => 'بريميوم مفعّل',
			'premium.activeBody' => 'شكرًا! الإعلانات والحدود اليومية متوقفة في هذا الحساب.',
			'premium.manage' => 'إدارة الاشتراك',
			'premium.cancel' => 'إلغاء الاشتراك',
			'premium.cancelNote' => 'الإلغاء يوقف التجديد التلقائي. يبقى الاشتراك المميز فعالاً حتى نهاية الفترة المدفوعة. لا يوجد استرداد للمبلغ.',
			'premium.unavailable' => 'الاشتراكات غير متاحة حاليًا. حاول مرة أخرى لاحقًا.',
			'premium.purchaseFailed' => 'لم تكتمل عملية الشراء',
			'premium.purchased' => 'مرحبًا بك في بريميوم!',
			'premium.legal' => 'يتجدد الاشتراك تلقائيًا في نهاية كل فترة ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من انتهائها. يتم الدفع عبر حساب المتجر الخاص بك، ويمكن إدارته أو إلغاؤه من إعدادات المتجر.',
			'premium.terms' => 'شروط الاستخدام',
			'premium.privacy' => 'سياسة الخصوصية',
			'premium.startFor' => ({required Object price}) => 'ابدأ بـ ${price}',
			'premium.startFree' => 'ابدأ مجانًا',
			'premium.free' => 'مجانًا',
			'premium.introDays' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'لليوم الأول', other: 'لأول ${n} أيام', ), 
			'premium.introWeeks' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'للأسبوع الأول', other: 'لأول ${n} أسابيع', ), 
			'premium.introMonths' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'للشهر الأول', other: 'لأول ${n} أشهر', ), 
			'premium.introYears' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, one: 'للسنة الأولى', other: 'لأول ${n} سنوات', ), 
			'premium.introPaidTerms' => ({required Object price, required Object span, required Object then}) => '${price} ${span}، ثم ${then}. يتغيّر السعر تلقائيًا.',
			'premium.introFreeTerms' => ({required Object span, required Object then}) => 'مجانًا ${span}، ثم ${then}. يبدأ الدفع تلقائيًا.',
			'premium.redeem' => 'لديّ رمز قسيمة',
			'premium.redeemTitle' => 'رمز القسيمة',
			'premium.redeemHint' => 'اكتب الرمز الذي استلمته',
			'premium.redeemConfirm' => 'الاستخدام في المتجر',
			'premium.perWeekly' => 'في الأسبوع',
			'premium.perMonthly' => 'في الشهر',
			'premium.perTwoMonth' => 'كل شهرين',
			'premium.perThreeMonth' => 'كل 3 أشهر',
			'premium.perSixMonth' => 'كل 6 أشهر',
			'premium.perAnnual' => 'في السنة',
			'premium.tierPro' => 'Pro',
			'premium.tierDuo' => 'Pro Duo',
			'premium.tierFamily' => 'Pro Family',
			'premium.tierProHint' => 'حساب واحد',
			'premium.tierDuoHint' => 'حسابان، كل شيء متزامن',
			'premium.tierFamilyHint' => 'حتى 6 حسابات، كل شيء متزامن',
			'premium.benefitHousehold' => ({required Object n}) => 'حساب مشترك لـ ${n} أشخاص: الوصفات والخطط والقوائم متزامنة',
			'walkthrough.title' => 'الدليل',
			'walkthrough.start' => 'تشغيل الدليل',
			'walkthrough.startHint' => 'جولة إرشادية في كل وظائف التطبيق، خطوة بخطوة',
			'walkthrough.startFull' => 'ابدأ الجولة الكاملة',
			'walkthrough.focused' => 'عرض إرشاد مركّز',
			'walkthrough.next' => 'التالي',
			'walkthrough.finish' => 'إنهاء',
			'walkthrough.skipStep' => 'تخطّي الخطوة',
			'walkthrough.close' => 'إغلاق الدليل',
			'walkthrough.stepOf' => ({required Object current, required Object total}) => 'الخطوة ${current} من ${total}',
			'walkthrough.tapHint' => 'اضغط على المنطقة المميّزة أو على "التالي"',
			'walkthrough.bookTitle' => 'دليل EasyPlate',
			'walkthrough.bookSubtitle' => 'كل ما يمكن فعله في التطبيق، فصلاً بعد فصل. الأمثلة في هذا الكتاب لا تُحفظ؛ الجولة الحيّة تنفّذ الإجراءات فعلاً، والحقول معبّأة مسبقاً.',
			'walkthrough.contents' => 'المحتويات',
			'walkthrough.chapter' => ({required Object number}) => 'الفصل ${number}',
			'walkthrough.backToContents' => 'العودة إلى المحتويات',
			'walkthrough.stepsTitle' => 'الخطوات',
			'walkthrough.welcomeTitle' => 'مرحباً بك في EasyPlate',
			'walkthrough.welcomeBody' => 'سنمرّ معاً على الإجراءات الرئيسية وننفّذها فعلاً: الحقول معبّأة لكم مسبقاً. يمكنكم تخطّي أي خطوة، أو الإغلاق والبدء من جديد من شاشة الدعم.',
			'walkthrough.topics.addRecipe.title' => 'إضافة وصفة',
			'walkthrough.topics.addRecipe.summary' => 'أدخل وصفة من أي مصدر، ويرتّبها الذكاء الاصطناعي بصيغة موحّدة: مكوّنات وكميات وخطوات ووسوم وحصص وقيم غذائية.',
			'walkthrough.topics.addRecipe.s1' => 'اضغط على زر الشرارة بجانب العنوان لإضافة وصفة.',
			'walkthrough.topics.addRecipe.s2' => 'اختر مصدراً: نص ملصق، بحث على الإنترنت، رابط موقع، فيديو من تيك توك أو إنستغرام أو يوتيوب أو فيسبوك، طلب حرّ من الذكاء الاصطناعي، أو كتابة يدوية.',
			'walkthrough.topics.addRecipe.s3' => 'عبّأنا هنا وصفة نموذجية كما لو أنك لصقتها. الزر في الأسفل يرسلها إلى الذكاء الاصطناعي الذي يعيدها مرتّبة للمراجعة والتعديل والحفظ. يستغرق التحليل حتى نصف دقيقة، فاتركه إلى ما بعد الجولة.',
			'walkthrough.topics.myRecipes.title' => 'وصفاتي والمحفوظة',
			'walkthrough.topics.myRecipes.summary' => 'الوصفات التي كتبتها والتي حفظتها من المجتمع، مع بحث وتصفية حسب الموضوع.',
			'walkthrough.topics.myRecipes.s1' => 'انتقل هنا بين الوصفات التي كتبتها والوصفات التي حفظتها من المجتمع.',
			'walkthrough.topics.myRecipes.s2' => 'ابحث بالاسم وصفِّ حسب الموضوع: لحوم، ألبان، نباتي، نباتي صرف، كوشر، خالٍ من الغلوتين وحساسية. كل وصفة تحدّد أيضاً مسبّبات الحساسية فيها.',
			'walkthrough.topics.library.title' => 'كتب الوصفات',
			'walkthrough.topics.library.summary' => 'رتّب الوصفات في كتب مع فهرس وغلاف وتقليب صفحات، وشارك كتاباً كاملاً مع حساب آخر.',
			'walkthrough.topics.library.s1' => 'اضغط على "المكتبة" للانتقال إلى الكتب.',
			'walkthrough.topics.library.s2' => 'اضغط على زر الزائد لإنشاء كتاب جديد.',
			'walkthrough.topics.library.s3' => 'اسم الكتاب معبّأ مسبقاً: "دليل". اضغط على الحقل لتغييره، ثم تابع.',
			'walkthrough.topics.library.s4' => 'اضغط "حفظ" لإنشاء الكتاب.',
			'walkthrough.topics.library.s5' => 'اختر لون الكعب الذي يميّز الكتب على الرف، واضغط "حفظ". يُفتح الكتاب فوراً.',
			'walkthrough.topics.library.s6' => 'هذا هو الكتاب الذي أنشأته. من هنا تضيف إليه وصفات، وداخله تقلّب الصفحات وتقفز من الفهرس. الضغط المطوّل على كتاب في الرف يفتح المشاركة والغلاف وإعادة التسمية والحذف.',
			'walkthrough.topics.mealPlan.title' => 'الخطة الأسبوعية والتغذية',
			'walkthrough.topics.mealPlan.summary' => 'خطة وجبات للأسبوع كله مع ملخّص غذائي لكل يوم، تغذّي قائمة التسوّق.',
			'walkthrough.topics.mealPlan.s1' => 'اضغط على "الوجبات" لتخطيط الأسبوع.',
			'walkthrough.topics.mealPlan.s2' => 'اضغط هنا لإنشاء خطة أسبوعية.',
			'walkthrough.topics.mealPlan.s3' => 'اسم الخطة معبّأ مسبقاً. في الأسفل اختر قالباً: حرّ، ثلاث وجبات يومياً أو ست.',
			'walkthrough.topics.mealPlan.s4' => 'اضغط "حفظ" لإنشاء الخطة.',
			'walkthrough.topics.mealPlan.s5' => 'ضع الوصفات في وجبات كل يوم. تجمع بطاقة التغذية السعرات والبروتين والكربوهيدرات والدهون حسب الحصص. اضغط على الرسم لفتح لوحة الأسبوع.',
			'walkthrough.topics.mealPlan.s6' => 'اللوحة: المتوسط اليومي، مجموع الأسبوع، عمود لكل يوم وتوزيع المغذّيات الكبرى. تُقدَّر القيم بالذكاء الاصطناعي لكل وصفة، لكل حصة.',
			'walkthrough.topics.mealPlan.s7' => 'زر المشاركة يرسل الخطة إلى حساب آخر، كمحرّر أو كمشاهد. أي تعديل من طرف يصل إلى الجميع.',
			'walkthrough.topics.groceries.title' => 'قائمة التسوّق والأسعار',
			'walkthrough.topics.groceries.summary' => 'قائمة تُبنى من الخطة، مع تعليم ما جُمع وتقدير للتكلفة من إيصالاتك، ومشاركة مع من يتسوّق معك.',
			'walkthrough.topics.groceries.s1' => 'اضغط على "التسوّق".',
			'walkthrough.topics.groceries.s2' => 'التحديث يعيد بناء القائمة من كل وصفات الخطة الأسبوعية.',
			'walkthrough.topics.groceries.s3' => 'اضغط على زر الزائد لإضافة عنصر يدوياً.',
			'walkthrough.topics.groceries.s4' => 'اسم العنصر معبّأ مسبقاً. اختر كمية ووحدة، أو ابدأ من منتج تعرفه إيصالاتك أصلاً.',
			'walkthrough.topics.groceries.s5' => 'اضغط "إضافة" ويدخل العنصر إلى القائمة.',
			'walkthrough.topics.groceries.s6' => 'اضغط هنا لفتح دفتر الأسعار.',
			'walkthrough.topics.groceries.s7' => 'امسح إيصالاً ويُحفظ سعر كل منتج. من هنا تحصل قائمة التسوّق على تقدير للتكلفة، وتكمل أسعار المجتمع الوسيطة ما لم تشترِه بعد.',
			'walkthrough.topics.groceries.shefi' => 'اسأل شيفي عن هذه القائمة: ما ينقص لوجبة، ما يمكن استبداله، أو أضف عناصر بصوتك.',
			'walkthrough.topics.community.title' => 'المجتمع',
			'walkthrough.topics.community.summary' => 'وصفات يشاركها الجميع، ومنتدى للأسئلة والأجوبة.',
			'walkthrough.topics.community.s1' => 'اضغط على "المجتمع".',
			'walkthrough.topics.community.s2' => 'وصفات مشتركة ومنتدى. أعجب بوصفة أو موضوع أو ردّ، احفظ وصفة عندك، وأرفق وصفة بردّ في المنتدى.',
			'walkthrough.topics.community.s3' => 'زر المشاركة ينشر وصفة من وصفاتك إلى المجتمع.',
			'walkthrough.topics.account.title' => 'الحساب والاشتراك والإعدادات',
			'walkthrough.topics.account.summary' => 'إشعارات بدعوات المشاركة، والحساب مع الاشتراك المميّز والوصول المشترك والإعدادات ووضع العرض.',
			'walkthrough.topics.account.s1' => 'الإشعارات: دعوات لمشاركة الكتب والخطط، وتحديثات.',
			'walkthrough.topics.account.s2' => 'اضغط على الصورة لفتح حسابك.',
			'walkthrough.topics.account.s3' => 'الاشتراك المميّز: تحليلات ذكاء اصطناعي بلا حدّ يومي وبلا إعلانات. يحصل الحساب المجاني على حصة يومية يمكن توسيعها بمشاهدة فيديو قصير.',
			'walkthrough.topics.account.s4' => 'الوصول المشترك: من يشارك معك الكتب والخطط وقوائم التسوّق، وما شاركته أنت.',
			'walkthrough.topics.account.s5' => 'اضغط على "الإعدادات".',
			'walkthrough.topics.account.s6' => 'وضع العرض: فاتح أو داكن أو حسب الجهاز. في الإعدادات أيضاً اللغة والتفضيلات الغذائية ومسبّبات الحساسية. يمكن تشغيل هذا الدليل مجدداً من شاشة الدعم في الحساب.',
			'walkthrough.topics.account.shefi' => 'شيفي، المساعد الذكي: هذا الزر العائم يفتح محادثة. اسأل كتابةً أو بصوتك، فيجيب شيفي ويضيف إلى الخطة ويبني قائمة أو يشغّل وضع الطبخ. داخل وصفة أو خطة أو قائمة، زر «اسأل شيفي» يتحدث عن هذا العنصر فقط.',
			'walkthrough.topics.settings.title' => 'الإعدادات والتفضيلات',
			'walkthrough.topics.settings.summary' => 'كل صف في الإعدادات والتفضيلات: الملف الشخصي، المشاركة، الإشعارات، اللغة، المظهر، حذف الحساب، يوم التسوّق، الأسعار، التغذية والكتب.',
			'walkthrough.topics.settings.s1' => 'اضغط "الإعدادات": هنا الحساب والتطبيق.',
			'walkthrough.topics.settings.s2' => 'الملف الشخصي: الاسم والصورة اللذان يراهما من تشاركهم، وطرق تسجيل الدخول المرتبطة.',
			'walkthrough.topics.settings.s3' => 'الوصول المشترك: من يشارك معك الوصفات والكتب والخطط والقوائم، وما شاركته أنت. من هنا أيضًا تنضم برمز أو QR.',
			'walkthrough.topics.settings.s4' => 'اضغط "إعدادات الإشعارات".',
			'walkthrough.topics.settings.s5' => 'إشعارات الدفع: المفتاح الرئيسي. عندما يكون مطفأً لا يُرسل شيء؛ وتحته تختار ما يُرسل: الردود والدعوات والتحديثات ورسائل الفريق.',
			'walkthrough.topics.settings.s6' => 'تذكيرات يوم التسوّق: متى نذكّرك قبل التسوّق. مجدولة على الجهاز، بمعزل عن الدفع.',
			'walkthrough.topics.settings.s7' => 'اللغة: التبديل يترجم أيضًا وصفاتك وكتبك وخططك وقوائمك.',
			'walkthrough.topics.settings.s8' => 'المظهر: فاتح أو داكن أو حسب الجهاز. يُحفظ الاختيار في الحساب وينتقل معك إلى الجهاز التالي.',
			'walkthrough.topics.settings.s9' => 'حذف الحساب: يحذف الحساب وكل ما فيه نهائيًا بعد التأكيد. يُلغى اشتراك المتجر على حدة.',
			'walkthrough.topics.settings.s10' => 'عودة إلى الحساب: اضغط "التفضيلات"، كيف يتصرف التطبيق من أجلك.',
			'walkthrough.topics.settings.s11' => 'يوم التسوّق: اليوم الذي تُبنى حوله قائمة التسوّق وتُوقَّت التذكيرات.',
			'walkthrough.topics.settings.s12' => 'أسعار المجتمع: عند التفعيل تنضم أسعار فواتيرك مجهولة الهوية إلى المتوسطات، وتُقدَّر الأسطر التي لم تشترها وفقها.',
			'walkthrough.topics.settings.s13' => 'التفضيلات الغذائية ومسببات الحساسية: علّمها هنا ويبرزها التطبيق في الوصفات والوصفات المشتركة.',
			'walkthrough.topics.settings.s14' => 'تقليب سريع في الكتب: القفز إلى صفحة بعيدة يقلّب صفحة واحدة فقط. عند الإيقاف يقلّب كل الصفحات في الطريق.',
			'walkthrough.topics.settings.s15' => 'الأصوات: مؤثرات صوتية عند التقليب والإجراءات. يمكن إيقافها.',
			'walkthrough.demo.bookTitle' => 'دليل',
			'walkthrough.demo.planName' => 'خطة الدليل',
			'walkthrough.demo.mealName' => 'عشاء',
			'walkthrough.demo.groceryItem' => 'طماطم',
			'walkthrough.demo.recipeText' => 'شكشوكة مقدسية\n\nالمكوّنات:\n400 غرام طماطم مهروسة\n4 بيضات\nبصلة واحدة\nملعقتا طعام زيت زيتون\nملعقة صغيرة بابريكا حلوة\nرشّة ملح\n\nالطريقة:\n1. سخّن زيت الزيتون في مقلاة وقلّب البصل حتى يذهبّ.\n2. أضف الطماطم والبابريكا واطبخ 10 دقائق على نار هادئة.\n3. اكسر البيض فوق الصلصة، غطِّ المقلاة واطبخ حتى يتماسك البياض.',
			'walkthrough.demoRecipes' => 'وصفات نموذجية',
			'walkthrough.demoRecipesHint' => 'هكذا تبدو الوصفات في التطبيق. اضغط على وصفة لرؤية صفحتها الكاملة: الأوقات، المواضيع، مسببات الحساسية، المكونات والخطوات.',
			'walkthrough.demoBooks' => 'كتب نموذجية',
			'walkthrough.demoBooksHint' => 'هكذا يبدو كتاب الوصفات. اضغط على كتاب لفتحه وتقليب صفحاته والانتقال من الفهرس.',
			'walkthrough.demoOnly' => 'نموذج فقط، لا يُحفظ',
			'feedback.title' => 'إبلاغ واقتراحات',
			'feedback.subtitle' => 'وجدت خللاً؟ لديك فكرة؟ اكتب لنا هنا، ونقرأ كل رسالة.',
			'feedback.bug' => 'خلل',
			'feedback.suggestion' => 'اقتراح تحسين',
			'feedback.bugHint' => 'صف الخلل: ماذا فعلت، ماذا حدث، وماذا توقعت أن يحدث...',
			'feedback.suggestionHint' => 'أخبرنا بما تودّ أن يوفره التطبيق، وكيف سيساعدك...',
			'feedback.send' => 'إرسال',
			'feedback.sent' => 'شكراً! تم إرسال رسالتك.',
			'feedback.failed' => 'فشل الإرسال، حاول لاحقاً',
			'feedback.admin' => 'إدارة الرسائل',
			'feedback.all' => 'الكل',
			'feedback.bugs' => 'أخطاء',
			'feedback.suggestions' => 'اقتراحات',
			'feedback.none' => 'لا توجد رسائل بعد',
			'feedback.version' => ({required Object version}) => 'الإصدار ${version}',
			'feedback.notAllowed' => 'هذه الشاشة للمدير فقط',
			'adminBilling.title' => 'الاشتراكات',
			'adminBilling.all' => 'الكل',
			'adminBilling.paying' => 'يدفعون',
			'adminBilling.problems' => 'مشاكل',
			'adminBilling.searchHint' => 'بحث بالاسم أو البريد أو الهاتف أو uid',
			'adminBilling.none' => 'لا حسابات للعرض',
			'adminBilling.premium' => 'بريميوم',
			'adminBilling.free' => 'مجاني',
			'adminBilling.untilDate' => ({required Object date}) => 'حتى ${date}',
			'adminBilling.adminLocked' => 'محدد يدويًا',
			'adminBilling.viaRevenueCat' => 'من RevenueCat',
			'adminBilling.sandbox' => 'Sandbox',
			'adminBilling.lastEvent' => ({required Object type, required Object date}) => '${type} · ${date}',
			_ => null,
		} ?? switch (path) {
			'adminBilling.product' => ({required Object id}) => 'المنتج: ${id}',
			'adminBilling.eventsCount' => ({required Object count}) => '${count} أحداث',
			'adminBilling.grant' => 'منح بريميوم',
			'adminBilling.revoke' => 'إلغاء بريميوم',
			'adminBilling.release' => 'إعادة إلى RevenueCat',
			'adminBilling.releaseHint' => 'محدد يدويًا: يتم تجاهل الحدث التالي من RevenueCat حتى الإفراج.',
			'adminBilling.granted' => 'تم منح بريميوم',
			'adminBilling.revoked' => 'تم إلغاء بريميوم',
			'adminBilling.released' => 'عاد الحساب إلى RevenueCat',
			'adminBilling.revokeConfirm' => ({required Object name}) => 'إلغاء بريميوم لـ ${name}؟',
			'adminBilling.problemPaidNotPremium' => 'دفع، لكن الحساب ليس بريميوم',
			'adminBilling.problemNoEntitlement' => 'وصلت عملية شراء بدون الـ entitlement (المنتج غير مرتبط في RevenueCat)',
			'adminBilling.orphanTitle' => 'مشتريات بدون حساب',
			'adminBilling.orphanBody' => 'إيصالات وصلت تحت معرّف مجهول في RevenueCat، بدون مستخدم لفتحه',
			'adminBilling.summary' => ({required Object premium, required Object problems, required Object total}) => '${premium} بريميوم · ${problems} مشاكل · ${total} حسابات',
			'adminBilling.noEntitlementTag' => 'بدون entitlement',
			'adminDashboard.title' => 'لوحة التحكم',
			'adminDashboard.tabDashboard' => 'لوحة',
			'adminDashboard.tabSubscriptions' => 'الاشتراكات',
			'adminDashboard.tabTickets' => 'الرسائل',
			'adminDashboard.rangeToday' => 'اليوم',
			'adminDashboard.rangeMonth' => '30 يومًا',
			'adminDashboard.rangeAll' => 'الكل',
			'adminDashboard.aiCost' => 'تكلفة الذكاء الاصطناعي',
			'adminDashboard.aiCostHint' => 'الرموز × قائمة الأسعار',
			'adminDashboard.revenue' => 'الإيرادات',
			'adminDashboard.revenueNone' => 'لا مدفوعات في هذه الفترة',
			'adminDashboard.sandboxNote' => ({required Object count}) => '${count} مدفوعات sandbox لم تُحتسب',
			'adminDashboard.paymentsCount' => ({required Object count}) => '${count} مدفوعات',
			'adminDashboard.aiCalls' => 'طلبات الذكاء الاصطناعي',
			'adminDashboard.cacheSaved' => ({required Object count}) => '${count} من الذاكرة المؤقتة (مجانًا)',
			'adminDashboard.errorsCount' => ({required Object count}) => '${count} أخطاء',
			'adminDashboard.tokens' => 'الرموز',
			'adminDashboard.tokensHint' => ({required Object input, required Object output}) => 'إدخال ${input} · إخراج ${output}',
			'adminDashboard.usersTotal' => 'إجمالي المستخدمين',
			'adminDashboard.newUsers' => ({required Object count}) => '${count} جدد',
			'adminDashboard.disabledCount' => ({required Object count}) => '${count} محظورون',
			'adminDashboard.premiumUsers' => 'مدفوع',
			'adminDashboard.freeCount' => ({required Object count}) => '${count} مجاني',
			'adminDashboard.freeUsers' => 'مجاني',
			'adminDashboard.activeUsers' => 'مستخدمو الذكاء الاصطناعي النشطون',
			'adminDashboard.costPerUser' => 'التكلفة لكل مستخدم نشط',
			'adminDashboard.tickets' => 'الرسائل',
			'adminDashboard.unreadCount' => ({required Object count}) => '${count} جديدة',
			'adminDashboard.chartCost' => 'تكلفة الذكاء الاصطناعي يوميًا',
			'adminDashboard.chartCalls' => 'الطلبات يوميًا',
			'adminDashboard.chartSignups' => 'التسجيلات يوميًا',
			'adminDashboard.chartPlatform' => 'المستخدمون حسب المنصة',
			'adminDashboard.chartPlan' => 'مجاني مقابل مدفوع',
			'adminDashboard.chartKinds' => 'الطلبات حسب الميزة',
			'adminDashboard.chartModels' => 'التكلفة حسب النموذج',
			'adminDashboard.chartVersions' => 'إصدارات التطبيق',
			'adminDashboard.platformIos' => 'iOS',
			'adminDashboard.platformAndroid' => 'Android',
			'adminDashboard.platformUnknown' => 'غير معروف',
			'adminDashboard.noAiUsage' => 'لا استخدام للذكاء الاصطناعي في هذه الفترة',
			'adminDashboard.unknownModel' => 'ليس في قائمة الأسعار',
			'adminDashboard.usersCost' => 'التكلفة حسب المستخدم',
			'adminDashboard.usersCount' => ({required Object count}) => '${count} مستخدمين',
			'adminDashboard.searchUser' => 'بحث بالاسم أو البريد أو uid',
			'adminDashboard.showAll' => ({required Object count}) => 'عرض كل ${count} المستخدمين',
			'adminDashboard.callsCount' => ({required Object count}) => '${count} طلبات',
			'adminDashboard.content' => 'المحتوى والمجتمع',
			'adminDashboard.sharedRecipes' => 'وصفات مشتركة',
			'adminDashboard.forumPosts' => 'مواضيع المنتدى',
			'adminDashboard.withPush' => 'أجهزة مع إشعارات',
			'adminDashboard.cacheEntries' => 'روابط محفوظة',
			'adminDashboard.cacheHits' => 'إصابات الذاكرة (طلبات موفّرة)',
			'adminDashboard.config' => 'الإعدادات عن بُعد',
			'adminDashboard.environment' => 'البيئة',
			'adminDashboard.prod' => 'Production',
			'adminDashboard.dev' => 'Dev',
			'adminDashboard.adsEnabled' => 'الإعلانات',
			'adminDashboard.adsFailOpen' => 'فتح بدون إعلان',
			'adminDashboard.on' => 'مفعّل',
			'adminDashboard.off' => 'معطّل',
			'adminDashboard.feedInterval' => 'فاصل إعلانات الخلاصة',
			'adminDashboard.quotaSharedFree' => 'مشاهدات مجانية يوميًا',
			'adminDashboard.quotaSharedRewarded' => 'مشاهدات بالفيديو يوميًا',
			'adminDashboard.quotaAiRewarded' => 'ذكاء اصطناعي بالفيديو يوميًا',
			'adminDashboard.quotaAiPremium' => 'ذكاء اصطناعي للمميز يوميًا',
			'adminDashboard.minVersion' => 'الحد الأدنى للإصدار',
			'adminDashboard.latestVersion' => 'أحدث إصدار',
			'adminDashboard.thisBuild' => 'هذا الإصدار',
			'adminDashboard.pricing' => 'قائمة أسعار الرموز',
			'adminDashboard.pricingHint' => 'دولار أمريكي لكل مليون رمز. القيم الافتراضية تقديرية — حدّثها من قائمة أسعار Google.',
			'adminDashboard.editPricing' => 'تعديل الأسعار',
			'adminDashboard.priceInput' => 'إدخال',
			'adminDashboard.priceOutput' => 'إخراج',
			'adminDashboard.priceCached' => 'إدخال مخزّن',
			'adminDashboard.usdToIls' => 'سعر الدولار/الشيكل',
			'adminDashboard.pricingSaved' => 'تم حفظ الأسعار',
			'adminDashboard.loadedAt' => ({required Object date}) => 'تم التحديث ${date}',
			'adminDashboard.kindText' => 'نص',
			'adminDashboard.kindUrl' => 'رابط',
			'adminDashboard.kindSocial' => 'شبكة اجتماعية',
			'adminDashboard.kindSocialVideo' => 'فيديو (خادم)',
			'adminDashboard.kindVideo' => 'فيديو',
			'adminDashboard.kindSearch' => 'بحث',
			'adminDashboard.kindImage' => 'صورة',
			'adminDashboard.kindReceipt' => 'فاتورة',
			'adminDashboard.kindNutrition' => 'تغذية',
			'adminDashboard.kindRefine' => 'تحسين',
			'adminDashboard.kindGenerate' => 'توليد',
			'adminDashboard.allTime' => 'كل الوقت',
			'adminDashboard.recentCalls' => 'آخر الطلبات',
			'adminDashboard.noCalls' => 'لا طلبات',
			'adminDashboard.cacheHit' => 'ذاكرة',
			'adminDashboard.statusOk' => 'سليم',
			'adminDashboard.pushTitle' => 'العنوان (اختياري)',
			'adminDashboard.pushBody' => 'نص الرسالة',
			'adminDashboard.send' => 'إرسال',
			'adminDashboard.blocked' => 'محظورون',
			'adminDashboard.disable' => 'حظر الحساب',
			'adminDashboard.enable' => 'إلغاء الحظر',
			'adminDashboard.blockMessageHint' => 'ما سيراه المستخدم عند محاولة الدخول',
			'adminDashboard.disabledDone' => 'تم حظر الحساب',
			'adminDashboard.enabledDone' => 'تم إلغاء الحظر',
			'adminDashboard.deleteAccount' => 'حذف الحساب',
			'adminDashboard.deleteAccountConfirm' => ({required Object name}) => 'حذف ${name} نهائيًا؟ سيُحذف المستخدم ووصفاته وكتبه وقوائمه ولا يمكن الاسترجاع.',
			'adminDashboard.deleted' => 'تم حذف الحساب',
			'adminDashboard.sendPush' => 'إرسال إشعار',
			'adminDashboard.noPush' => 'لا يوجد رمز إشعارات لهذا الجهاز — ستظهر الرسالة في شاشة الإشعارات فقط',
			'adminDashboard.pushSent' => 'تم إرسال الإشعار',
			'adminDashboard.sendPushAll' => 'إشعار لجميع المستخدمين',
			'adminDashboard.broadcastConfirm' => ({required Object count}) => 'إرسال الرسالة إلى جميع المستخدمين (${count})؟',
			'adminDashboard.broadcastDone' => ({required Object items, required Object sent, required Object failed}) => 'كُتبت في ${items} صندوقًا · ${sent} إشعارات نجحت · ${failed} فشلت',
			'adminDashboard.platformTag' => ({required Object platform, required Object version}) => '${platform} · v${version}',
			'adminDashboard.lastSeen' => ({required Object date}) => 'آخر ظهور ${date}',
			'adminDashboard.disabledSince' => ({required Object message}) => 'سبب الحظر: ${message}',
			'adminDashboard.unread' => 'جديدة',
			'adminDashboard.markAllRead' => 'قرأت الكل',
			'adminDashboard.allRead' => 'تم تعليم كل الرسائل كمقروءة',
			'adminDashboard.noUnread' => 'لا رسائل جديدة',
			'adminDashboard.deleteTicket' => 'حذف الرسالة',
			'adminDashboard.deleteTicketConfirm' => ({required Object name}) => 'حذف رسالة ${name}؟',
			'adminDashboard.ticketDeleted' => 'تم حذف الرسالة',
			'adminDashboard.reply' => 'رد',
			'adminDashboard.replyHint' => 'سيصل الرد إلى إشعارات المستخدم (وكإشعار على الهاتف)',
			'adminDashboard.replySent' => 'تم إرسال الرد',
			'adminDashboard.yourReply' => ({required Object date}) => 'ردك · ${date}',
			'adminDashboard.markRead' => 'تعليم كمقروء',
			'adminDashboard.markUnread' => 'تعليم كغير مقروء',
			'adminDashboard.pricingSync' => 'مزامنة الأسعار من Google',
			'adminDashboard.pricingSynced' => ({required Object count}) => 'تم تحديث ${count} نماذج من كتالوج Google Cloud Billing',
			'adminDashboard.pricingSyncFailed' => ({required Object reason}) => 'فشلت المزامنة: ${reason}',
			'adminDashboard.pricingSourceCatalog' => ({required Object date}) => 'المصدر: Google Cloud Billing (أسعار حقيقية) · ${date}',
			'adminDashboard.pricingSourceManual' => ({required Object date}) => 'المصدر: أُدخل يدويًا · ${date}',
			'adminDashboard.pricingSourceDefaults' => 'تقدير فقط — اضغط مزامنة لجلب الأسعار الحقيقية من Google',
			'adminDashboard.searchPrice' => 'بحث Google (دولار لكل 1000 استعلام)',
			'adminDashboard.rateLine' => ({required Object rate, required Object date}) => '${rate} · يتحدّث أسبوعيًا · ${date}',
			'adminDashboard.searchesCount' => ({required Object count}) => '${count} عمليات بحث',
			'adminDashboard.rangeCustom' => 'اختيار',
			'adminDashboard.customRange' => ({required Object from, required Object to}) => '${from} – ${to} · اضغط للتغيير',
			'adminDashboard.priceImageOutput' => 'إخراج صورة',
			'adminDashboard.dataSince' => ({required Object date}) => 'تُجمع البيانات منذ ${date}. رسوم Google السابقة غير مسجّلة هنا.',
			'adminDashboard.grantTitle' => ({required Object name}) => 'اشتراك مميز لـ ${name} — لكم من الوقت؟',
			'adminDashboard.grantForever' => 'دائمًا (حتى أُلغيه)',
			'adminDashboard.grantWeek' => 'أسبوع',
			'adminDashboard.grantMonth' => 'شهر',
			'adminDashboard.grantYear' => 'سنة',
			'adminDashboard.grantRange' => 'نطاق تواريخ محدد',
			'adminDashboard.grantedUntil' => ({required Object date}) => 'مُنح الاشتراك حتى ${date}',
			'adminDashboard.grantStarts' => ({required Object date}) => 'يبدأ في ${date}',
			'assistant.title' => 'شيفي',
			'assistant.subtitle' => 'مساعد الطاهي: اسأل، خطط، تسوّق، اطبخ',
			'assistant.placeholder' => 'اسأل أو قل لي ماذا أفعل…',
			'assistant.send' => 'إرسال',
			'assistant.thinking' => 'أفكّر…',
			'assistant.working' => ({required Object tool}) => 'أنفّذ: ${tool}',
			'assistant.welcome' => ({required Object name}) => 'مرحبًا ${name}! أستطيع إضافة مشتريات، تخطيط أسبوعك، استيراد وصفات من روابط، بدء وضع الطبخ والمزيد. ماذا نفعل؟',
			'assistant.error' => 'حدث خطأ ما. حاول مجددًا.',
			'assistant.quotaReached' => 'استُهلكت حصة الذكاء الاصطناعي لليوم. تُفتح غدًا.',
			'assistant.premiumOnly' => 'شيفي جزء من EasyPlate Premium',
			'assistant.unlock' => 'عرض بريميوم',
			'assistant.clear' => 'محادثة جديدة',
			'assistant.openResult' => 'فتح',
			'assistant.done' => 'تم',
			'assistant.undone' => 'تم التراجع',
			'assistant.confirmTitle' => 'حذف؟',
			'assistant.confirmBody' => ({required Object what}) => 'سيتم حذف ${what}.',
			'assistant.notFound' => ({required Object name}) => 'لم أجد "${name}".',
			'assistant.listTitle' => 'قائمة التسوّق',
			'assistant.addedItems' => ({required Object count}) => 'أُضيف ${count} عناصر',
			'assistant.plannedMeal' => ({required Object day, required Object slot}) => 'خُطط لـ${day} · ${slot}',
			'assistant.recipeSaved' => 'حُفظت الوصفة',
			'assistant.cookStarted' => 'بدأ وضع الطبخ',
			'assistant.timerSet' => ({required Object n}) => 'ضُبط مؤقّت للخطوة ${n}',
			'assistant.prefSaved' => 'حُفظ التفضيل',
			'assistant.needsPremium' => 'هذا يتطلب EasyPlate Premium.',
			'assistant.results' => ({required Object count}) => '${count} نتائج',
			'assistant.suggest.templates.0' => 'أضف {food} إلى قائمة التسوّق',
			'assistant.suggest.templates.1' => 'أضف {food} و{food2} إلى القائمة',
			'assistant.suggest.templates.2' => 'خطط {dish} لـ{meal} يوم {day}',
			'assistant.suggest.templates.3' => 'خطط شيئًا سريعًا لـ{meal} يوم {day}',
			'assistant.suggest.templates.4' => 'ماذا أطبخ بـ{food} و{food2}؟',
			'assistant.suggest.templates.5' => 'استورد وصفة من {site}',
			'assistant.suggest.templates.6' => 'ابحث عن وصفة {dish} على الإنترنت',
			'assistant.suggest.templates.7' => 'ابدأ طبخ {dish}',
			'assistant.suggest.templates.8' => 'شغّل مؤقّت {n} دقيقة للخطوة 2',
			'assistant.suggest.templates.9' => 'أنشئ قائمة تسوّق من {dish}',
			'assistant.suggest.templates.10' => 'أنشئ كتابًا باسم {book}',
			'assistant.suggest.templates.11' => 'أي وصفاتي {diet}؟',
			'assistant.suggest.templates.12' => 'علّم {food} كمشترى',
			'assistant.suggest.templates.13' => 'احذف {food} من القائمة',
			'assistant.suggest.templates.14' => 'أنشئ خطة للأسبوع القادم',
			'assistant.suggest.templates.15' => 'ماذا خُطط ليوم {day}؟',
			'assistant.suggest.templates.16' => 'غيّر يوم التسوّق إلى {day}',
			'assistant.suggest.templates.17' => 'اقترح عشاءً {diet} ليوم {day}',
			'assistant.suggest.templates.18' => 'كم أسلق البيضة؟',
			'assistant.suggest.templates.19' => 'بماذا أستبدل {food} في وصفة؟',
			'assistant.suggest.templates.20' => 'كيف أحفظ {food}؟',
			'assistant.suggest.templates.21' => 'كم سعرة في {dish}؟',
			'assistant.suggest.templates.22' => 'ما درجة حرارة الفرن المناسبة لـ{dish}؟',
			'assistant.suggest.templates.23' => 'كيف أجعل {dish} نباتيًا؟',
			'assistant.suggest.templates.24' => 'كم غرامًا في {n} ملاعق كبيرة؟',
			'assistant.suggest.templates.25' => 'لماذا خرج {dish} جافًا؟',
			'assistant.suggest.templates.26' => 'ماذا يناسب بجانب {dish}؟',
			'assistant.suggest.templates.27' => 'هل يمكن تجميد {food}؟',
			'assistant.suggest.templates.28' => 'كيف أثخّن الصلصة؟',
			'assistant.suggest.templates.29' => 'فكرة {meal} {diet} سريعة؟',
			'assistant.suggest.food.0' => 'حليب',
			'assistant.suggest.food.1' => 'بيض',
			'assistant.suggest.food.2' => 'خبز',
			'assistant.suggest.food.3' => 'طماطم',
			'assistant.suggest.food.4' => 'بصل',
			'assistant.suggest.food.5' => 'زيت زيتون',
			'assistant.suggest.food.6' => 'أرز',
			'assistant.suggest.food.7' => 'دجاج',
			'assistant.suggest.food.8' => 'ليمون',
			'assistant.suggest.food.9' => 'ثوم',
			'assistant.suggest.food.10' => 'زبدة',
			'assistant.suggest.food.11' => 'طحين',
			'assistant.suggest.food.12' => 'جبنة',
			'assistant.suggest.food.13' => 'لبن',
			'assistant.suggest.food.14' => 'خيار',
			'assistant.suggest.food.15' => 'معكرونة',
			'assistant.suggest.dish.0' => 'شكشوكة',
			'assistant.suggest.dish.1' => 'شوربة عدس',
			'assistant.suggest.dish.2' => 'معكرونة بيستو',
			'assistant.suggest.dish.3' => 'كاري دجاج',
			'assistant.suggest.dish.4' => 'سلمون',
			'assistant.suggest.dish.5' => 'خضار مقلية',
			'assistant.suggest.dish.6' => 'بانكيك',
			'assistant.suggest.dish.7' => 'حمص',
			'assistant.suggest.dish.8' => 'خضار مشوية',
			'assistant.suggest.dish.9' => 'خبز الموز',
			'assistant.suggest.day.0' => 'الأحد',
			'assistant.suggest.day.1' => 'الاثنين',
			'assistant.suggest.day.2' => 'الثلاثاء',
			'assistant.suggest.day.3' => 'الأربعاء',
			'assistant.suggest.day.4' => 'الخميس',
			'assistant.suggest.day.5' => 'الجمعة',
			'assistant.suggest.day.6' => 'السبت',
			'assistant.suggest.day.7' => 'غدًا',
			'assistant.suggest.meal.0' => 'الفطور',
			'assistant.suggest.meal.1' => 'الغداء',
			'assistant.suggest.meal.2' => 'العشاء',
			'assistant.suggest.n.0' => '5',
			'assistant.suggest.n.1' => '8',
			'assistant.suggest.n.2' => '10',
			'assistant.suggest.n.3' => '12',
			'assistant.suggest.n.4' => '15',
			'assistant.suggest.n.5' => '20',
			'assistant.suggest.n.6' => '25',
			'assistant.suggest.n.7' => '30',
			'assistant.suggest.site.0' => 'تيك توك',
			'assistant.suggest.site.1' => 'إنستغرام',
			'assistant.suggest.site.2' => 'يوتيوب',
			'assistant.suggest.site.3' => 'مدونة',
			'assistant.suggest.book.0' => 'أيام الأسبوع',
			'assistant.suggest.book.1' => 'العطلة',
			'assistant.suggest.book.2' => 'الأطفال',
			'assistant.suggest.book.3' => 'حلويات',
			'assistant.suggest.diet.0' => 'نباتية',
			'assistant.suggest.diet.1' => 'نباتية صرفة',
			'assistant.suggest.diet.2' => 'خالية من الغلوتين',
			'assistant.suggest.diet.3' => 'ألبان',
			'assistant.whichList' => 'أي قائمة؟',
			'assistant.listCreated' => 'أُنشئت القائمة',
			'assistant.offTopic' => 'أنا هنا للطبخ والوصفات وتخطيط الوجبات والمشتريات. اسألني أي شيء يخص المطبخ وسأتولاه!',
			'assistant.welcomeAnon' => 'مرحبًا! أستطيع إضافة مشتريات، تخطيط أسبوعك، استيراد وصفات من روابط، بدء وضع الطبخ والمزيد. ماذا نفعل؟',
			'assistant.scopedWelcome' => ({required Object name}) => 'ماذا تريد أن تعرف عن "${name}"؟',
			'assistant.scopedOffTopic' => ({required Object name}) => 'هنا أساعد فقط فيما يخص "${name}". لأي شيء آخر افتح شيفي من القائمة.',
			'assistant.askAboutRecipe' => 'اسأل شيفي عن هذه الوصفة',
			'assistant.askAboutPlan' => 'اسأل شيفي عن هذه الخطة',
			'assistant.askAboutList' => 'اسأل شيفي عن هذه القائمة',
			'assistant.listen' => 'تحدّث إلى شيفي',
			'assistant.stopListening' => 'إيقاف الاستماع',
			'assistant.speakReplies' => 'قراءة الردود بصوت عالٍ',
			'assistant.micUnavailable' => 'لا يمكن استخدام الميكروفون. تحقق من أذونات الميكروفون والتعرف على الكلام في إعدادات الجهاز.',
			'assistant.scopedPrompts.recipe.0' => 'ما القيم الغذائية لكل حصة؟',
			'assistant.scopedPrompts.recipe.1' => 'كيف أحضّرها لثمانية أشخاص؟',
			'assistant.scopedPrompts.recipe.2' => 'بماذا أستبدل مكوّنًا لا أملكه؟',
			'assistant.scopedPrompts.recipe.3' => 'أضف هذه الوصفة إلى خطة الغد',
			'assistant.scopedPrompts.recipe.4' => 'أنشئ قائمة تسوّق من هذه الوصفة',
			'assistant.scopedPrompts.mealPlan.0' => 'ماذا نأكل اليوم؟',
			'assistant.scopedPrompts.mealPlan.1' => 'أضف عشاءً يوم الثلاثاء',
			'assistant.scopedPrompts.mealPlan.2' => 'ما الناقص هذا الأسبوع؟',
			'assistant.scopedPrompts.mealPlan.3' => 'أنشئ قائمة تسوّق من هذه الخطة',
			'assistant.scopedPrompts.mealPlan.4' => 'كم سعرة يوم الأربعاء؟',
			'assistant.scopedPrompts.groceryList.0' => 'ما الذي بقي لشرائه؟',
			'assistant.scopedPrompts.groceryList.1' => 'أضف حليبًا وبيضًا',
			'assistant.scopedPrompts.groceryList.2' => 'علّم الطماطم كمشتراة',
			'assistant.scopedPrompts.groceryList.3' => 'احذف ما اشتريته بالفعل',
			'assistant.scopedPrompts.groceryList.4' => 'كم يساوي كوبان من الدقيق بالغرام؟',
			'assistant.listening' => 'أستمع…',
			'assistant.stop' => 'إيقاف',
			'assistant.cancelled' => 'أُلغي.',
			'shareCode.title' => 'رمز ورابط',
			'shareCode.tabContact' => 'جهة اتصال',
			'shareCode.tabCode' => 'رمز أو رابط',
			'shareCode.explain' => ({required Object role}) => 'كل من لديه هذا الرمز يمكنه الانضمام كـ${role}. صالح لمدة 30 يومًا.',
			'shareCode.create' => 'إنشاء رمز',
			'shareCode.code' => 'الرمز',
			'shareCode.link' => 'الرابط',
			'shareCode.copy' => 'نسخ',
			'shareCode.copied' => 'تم النسخ',
			'shareCode.share' => 'مشاركة',
			'shareCode.showQr' => 'عرض QR',
			'shareCode.scanQr' => 'مسح QR',
			'shareCode.enterCode' => 'إدخال رمز',
			'shareCode.join' => 'انضمام',
			'shareCode.joinTitle' => 'الانضمام برمز',
			'shareCode.joinHint' => 'الصق الرمز الذي تلقيته، أو امسح رمز QR الخاص به.',
			'shareCode.joinPlaceholder' => 'XXXXXXXX',
			'shareCode.joined' => ({required Object title}) => 'انضممت: ${title}',
			'shareCode.alreadyMember' => 'لديك هذا بالفعل.',
			'shareCode.invalid' => 'الرمز غير صالح.',
			'shareCode.expired' => 'انتهت صلاحية الرمز.',
			'shareCode.revoked' => 'أُلغي الرمز.',
			'shareCode.usedUp' => 'استُنفد الرمز.',
			'shareCode.self' => 'هذا رمزك أنت.',
			'shareCode.gone' => 'ما شاركه هذا الرمز لم يعد موجودًا.',
			'shareCode.failed' => 'تعذّر الانضمام. حاول مجددًا.',
			'shareCode.messageText' => ({required Object name, required Object title, required Object code, required Object link}) => 'شارك ${name} معك "${title}" على EasyPlate. الرمز: ${code}\n${link}',
			'shareCode.revoke' => 'إلغاء الرمز',
			'shareCode.limitRecipes' => ({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} وصفات أسبوعيًا.',
			'shareCode.limitBooks' => ({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} كتب.',
			'shareCode.limitPlans' => ({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} خطط.',
			'shareCode.upgrade' => 'عرض بريميوم',
			'shareCode.scanHint' => 'وجّه الكاميرا نحو رمز QR للمشاركة',
			'shareCode.householdMessage' => ({required Object name, required Object code, required Object link}) => 'دعاك ${name} إلى حسابه المشترك في EasyPlate. الرمز: ${code}\n${link}',
			'shareCode.limitLists' => ({required Object count}) => 'يمكن للحساب المجاني مشاركة حتى ${count} قوائم تسوق.',
			'household.title' => 'حساب مشترك',
			'household.duo' => 'Pro Duo',
			'household.family' => 'Pro Family',
			'household.seats' => ({required Object used, required Object total}) => '${used} من ${total} مقاعد مستخدمة',
			'household.intro' => 'افتح حسابًا مشتركًا: الوصفات والكتب والخطط والقوائم تظهر لكل من فيه، ويحصلون على بريميوم معك.',
			'household.create' => 'فتح حساب مشترك',
			'household.nameHint' => 'الاسم، مثلًا عائلة أحمد',
			'household.notEligible' => 'يأتي الحساب المشترك مع Pro Duo (حسابان) أو Pro Family (حتى 6 حسابات).',
			'household.seePlans' => 'عرض الخطط',
			'household.members' => 'الأعضاء',
			'household.owner' => 'المالك',
			'household.you' => 'أنت',
			'household.invite' => 'دعوة عضو',
			'household.inviteExplain' => ({required Object free}) => 'كل من لديه هذا الرمز ينضم إلى الحساب المشترك. بقي ${free} مقاعد.',
			'household.noSeats' => 'كل المقاعد مشغولة.',
			'household.remove' => 'إزالة',
			'household.removeConfirm' => ({required Object name}) => 'إزالة ${name} من الحساب المشترك؟ سيفقد الوصول وبريميوم.',
			'household.leave' => 'مغادرة الحساب المشترك',
			'household.leaveConfirm' => 'المغادرة؟ ما حُفظ هنا يبقى في الحساب المشترك؛ ويعود حسابك إلى ما كان لديك من قبل.',
			'household.dissolve' => 'إغلاق الحساب المشترك',
			'household.dissolveConfirm' => 'إغلاق الحساب المشترك؟ يفقد الأعضاء الوصول وبريميوم. وتعود بياناتك إلى حسابك الخاص.',
			'household.joined' => 'مرحبًا بك في الحساب المشترك!',
			'household.inheritedNote' => ({required Object name}) => 'بريميوم يأتي من اشتراك ${name}.',
			'household.failed' => 'لم ينجح ذلك. حاول مجددًا.',
			'household.full' => 'الحساب المشترك ممتلئ.',
			'household.inHousehold' => 'أنت بالفعل في حساب مشترك.',
			'household.notEligibleCode' => 'خطة المالك لم تعد تشمل حسابًا مشتركًا.',
			'household.lapsed' => 'انتهى اشتراك المالك؛ بريميوم متوقف مؤقتًا للأعضاء.',
			'homeWidgets.title' => 'أدوات الشاشة الرئيسية',
			'homeWidgets.hint' => 'شيفي وقائمة التسوق وقائمة طعام اليوم، مباشرة على الشاشة الرئيسية',
			'homeWidgets.intro' => 'أضيفوا أدوات EasyPlate إلى الشاشة الرئيسية: اسألوا شيفي، أضيفوا إلى قائمة التسوق، وشاهدوا القائمة وقائمة طعام اليوم دون فتح التطبيق.',
			'homeWidgets.howToIos' => 'اضغطوا مطولاً على مكان فارغ في الشاشة الرئيسية، ثم على +، ابحثوا عن EasyPlate واختاروا أداة. الأدوات نفسها تناسب شاشة القفل.',
			'homeWidgets.howToAndroid' => 'اضغطوا مطولاً على مكان فارغ في الشاشة الرئيسية، اختاروا "الأدوات" وابحثوا عن EasyPlate، أو اضغطوا "إضافة إلى الشاشة الرئيسية" أدناه.',
			'homeWidgets.addToHome' => 'إضافة إلى الشاشة الرئيسية',
			'homeWidgets.installed' => ({required Object count}) => '${count} على الشاشة الرئيسية',
			'homeWidgets.pinFailed' => 'لم يعرض المشغّل إضافة الأداة. أضيفوها من قائمة أدوات الشاشة الرئيسية.',
			'homeWidgets.defaults' => 'الإعدادات الافتراضية للأدوات الجديدة',
			'homeWidgets.defaultsHint' => 'يمكن تغيير كل أداة لاحقًا من إعداداتها (ضغطة مطولة على الأداة).',
			'homeWidgets.defaultList' => 'قائمة التسوق',
			'homeWidgets.openList' => 'القائمة المفتوحة',
			'homeWidgets.defaultPlan' => 'خطة الوجبات',
			'homeWidgets.firstPlan' => 'الخطة الأولى',
			'homeWidgets.noLists' => 'لا توجد قائمة تسوق بعد',
			'homeWidgets.noPlans' => 'لا توجد خطة وجبات بعد',
			'homeWidgets.followApp' => 'مثل التطبيق',
			'homeWidgets.voiceOpen' => 'يفتح شيفي وهو يستمع',
			'homeWidgets.voiceOpenHint' => 'زر شيفي يشغّل الميكروفون فورًا',
			'homeWidgets.widgetAssistant' => 'اسأل شيفي',
			'homeWidgets.widgetAssistantHint' => 'زر يفتح شيفي، مع الميكروفون إن أردتم، وأسئلة سريعة.',
			'homeWidgets.widgetGroceryAdd' => 'إضافة سريعة إلى القائمة',
			'homeWidgets.widgetGroceryAddHint' => 'اكتبوا أو أملوا عنصرًا مباشرة إلى القائمة التي تختارونها.',
			'homeWidgets.widgetGroceryList' => 'قائمة التسوق',
			'homeWidgets.widgetGroceryListHint' => 'ما تبقى لشرائه؛ علّموا العناصر من الأداة.',
			'homeWidgets.widgetTodayMenu' => 'قائمة طعام اليوم',
			'homeWidgets.widgetTodayMenuHint' => 'وجبات اليوم من خطة تختارونها، كل يوم.',
			'homeWidgets.askShefi' => 'اسأل شيفي',
			'homeWidgets.tapToAsk' => 'ماذا نطبخ؟',
			'homeWidgets.speak' => 'تحدّث',
			'homeWidgets.quickAdd' => 'إضافة سريعة',
			'homeWidgets.addItem' => 'إضافة عنصر',
			'homeWidgets.itemHint' => 'ماذا نشتري؟',
			'homeWidgets.add' => 'إضافة',
			'homeWidgets.todayMenu' => 'قائمة طعام اليوم',
			'homeWidgets.today' => 'اليوم',
			'homeWidgets.noMeals' => 'لا وجبات مخططة لليوم',
			'homeWidgets.noPlan' => 'لا توجد خطة وجبات بعد',
			'homeWidgets.emptyList' => 'القائمة فارغة',
			'homeWidgets.allDone' => 'تم شراء كل شيء',
			'homeWidgets.remainingNative' => '{n} بقي للشراء',
			'homeWidgets.signIn' => 'سجّلوا الدخول إلى EasyPlate لرؤية قوائمكم',
			'homeWidgets.openApp' => 'فتح EasyPlate',
			'homeWidgets.showChecked' => 'إظهار العناصر المعلّمة أيضًا',
			'homeWidgets.pendingSync' => 'سيتم المزامنة عند فتح التطبيق',
			'homeWidgets.configTitle' => 'إعدادات الأداة',
			'homeWidgets.prompt1' => 'ماذا أطبخ اليوم؟',
			'homeWidgets.prompt2' => 'ما الناقص في القائمة؟',
			'homeWidgets.prompt3' => 'خطّط أسبوعي',
			'homeWidgets.demo1' => 'حليب',
			'homeWidgets.demo2' => 'خبز',
			'homeWidgets.demo3' => 'بيض',
			'feature.comingSoon' => 'قريباً',
			'feature.comingSoonMessage' => 'هذه الميزة ستصل قريباً',
			'feature.unavailable' => 'هذه الميزة غير متاحة حالياً',
			'feature.premiumOnly' => 'بريميوم',
			'feature.premiumOnlyMessage' => 'هذه الميزة لمشتركي بريميوم',
			'feature.premiumOnlyTitle' => 'لمشتركي بريميوم فقط',
			'feature.premiumOnlyFor' => ({required Object name}) => 'خيار "${name}" متاح لمشتركي بريميوم فقط',
			'feature.goPremium' => 'الانتقال إلى بريميوم',
			'featureName.books' => 'كتب الوصفات',
			'featureName.mealPlans' => 'خطط الوجبات',
			'featureName.groceryLists' => 'قوائم التسوق',
			'featureName.community' => 'المجتمع',
			'featureName.ingestText' => 'وصفة من نص',
			'featureName.ingestWebSearch' => 'البحث عن وصفة على الإنترنت',
			'featureName.ingestLink' => 'وصفة من رابط',
			'featureName.ingestSocialVideo' => 'وصفة من فيديو',
			'featureName.ingestAiRequest' => 'طلب وصفة من الذكاء الاصطناعي',
			'featureName.ingestFile' => 'وصفة من ملف',
			'featureName.shareIn' => 'المشاركة من تطبيق آخر',
			'featureName.saveWithAi' => 'الحفظ بالذكاء الاصطناعي',
			'featureName.cookMode' => 'وضع الطهي',
			'featureName.cookTimers' => 'مؤقتات الطهي',
			'featureName.nutrition' => 'القيم الغذائية',
			'featureName.recipeImageAi' => 'صورة بالذكاء الاصطناعي',
			'featureName.recipeImageSearch' => 'بحث الصور في جوجل',
			'featureName.groceryFromRecipe' => 'قائمة تسوق من وصفة',
			'featureName.sharedRecipes' => 'الوصفات المشتركة',
			'featureName.forum' => 'المنتدى',
			'featureName.likes' => 'الإعجابات',
			'featureName.shareRecipes' => 'مشاركة الوصفات',
			'featureName.shareBooks' => 'مشاركة الكتب',
			'featureName.sharePlans' => 'مشاركة الخطط',
			'featureName.shareGroceryLists' => 'مشاركة قوائم التسوق',
			'featureName.shareCodes' => 'المشاركة برمز',
			'featureName.households' => 'الأسرة',
			'featureName.priceBook' => 'دفتر الأسعار',
			'featureName.receiptScan' => 'مسح الإيصال',
			'featureName.groceryCost' => 'التكلفة التقديرية',
			'featureName.shoppingReminder' => 'تذكير التسوق',
			'featureName.assistant' => 'شيفي (المساعد)',
			'featureName.notifications' => 'الإشعارات',
			'featureName.premium' => 'بريميوم',
			'featureName.contentTranslation' => 'ترجمة المحتوى',
			'featureName.theming' => 'المظهر',
			'featureName.walkthrough' => 'جولة إرشادية',
			'featureName.tutorialBook' => 'كتاب التعليمات',
			'featureName.feedback' => 'الملاحظات',
			'featureName.assistantScoped' => 'شيفي داخل عنصر',
			'featureName.assistantVoice' => 'التحدث مع شيفي',
			'featureName.singleSession' => 'جهاز واحد لكل حساب',
			'featureName.homeWidgets' => 'أدوات الشاشة الرئيسية',
			_ => null,
		};
	}
}
