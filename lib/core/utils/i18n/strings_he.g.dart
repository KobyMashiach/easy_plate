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

	/// he: 'Easy Plate'
	String get appName => 'Easy Plate';

	late final Translations$common$he common = Translations$common$he.internal(_root);
	late final Translations$auth$he auth = Translations$auth$he.internal(_root);
	late final Translations$profile$he profile = Translations$profile$he.internal(_root);
	late final Translations$onboarding$he onboarding = Translations$onboarding$he.internal(_root);
	late final Translations$dietary$he dietary = Translations$dietary$he.internal(_root);
	late final Translations$allergens$he allergens = Translations$allergens$he.internal(_root);
	late final Translations$weekday$he weekday = Translations$weekday$he.internal(_root);
	late final Translations$settings$he settings = Translations$settings$he.internal(_root);
	late final Translations$notificationSettings$he notificationSettings = Translations$notificationSettings$he.internal(_root);
	late final Translations$preferences$he preferences = Translations$preferences$he.internal(_root);
	late final Translations$more$he more = Translations$more$he.internal(_root);
	late final Translations$language$he language = Translations$language$he.internal(_root);
	late final Translations$books$he books = Translations$books$he.internal(_root);
	late final Translations$recipe$he recipe = Translations$recipe$he.internal(_root);
	late final Translations$cookMode$he cookMode = Translations$cookMode$he.internal(_root);
	late final Translations$nutrition$he nutrition = Translations$nutrition$he.internal(_root);
	late final Translations$community$he community = Translations$community$he.internal(_root);
	late final Translations$sharing$he sharing = Translations$sharing$he.internal(_root);
	late final Translations$notifications$he notifications = Translations$notifications$he.internal(_root);
	late final Translations$editor$he editor = Translations$editor$he.internal(_root);
	late final Translations$ingestion$he ingestion = Translations$ingestion$he.internal(_root);
	late final Translations$mealPlanner$he mealPlanner = Translations$mealPlanner$he.internal(_root);
	late final Translations$groceryList$he groceryList = Translations$groceryList$he.internal(_root);
	late final Translations$receipt$he receipt = Translations$receipt$he.internal(_root);
	late final Translations$unit$he unit = Translations$unit$he.internal(_root);
	late final Translations$image$he image = Translations$image$he.internal(_root);
	late final Translations$nav$he nav = Translations$nav$he.internal(_root);
	late final Translations$update$he update = Translations$update$he.internal(_root);
	late final Translations$ads$he ads = Translations$ads$he.internal(_root);
	late final Translations$premium$he premium = Translations$premium$he.internal(_root);
	late final Translations$walkthrough$he walkthrough = Translations$walkthrough$he.internal(_root);
	late final Translations$feedback$he feedback = Translations$feedback$he.internal(_root);
	late final Translations$adminBilling$he adminBilling = Translations$adminBilling$he.internal(_root);
	late final Translations$adminDashboard$he adminDashboard = Translations$adminDashboard$he.internal(_root);
	late final Translations$assistant$he assistant = Translations$assistant$he.internal(_root);
	late final Translations$shareCode$he shareCode = Translations$shareCode$he.internal(_root);
	late final Translations$household$he household = Translations$household$he.internal(_root);
	late final Translations$feature$he feature = Translations$feature$he.internal(_root);
	late final Translations$featureName$he featureName = Translations$featureName$he.internal(_root);
	late final Translations$adminConfig$he adminConfig = Translations$adminConfig$he.internal(_root);
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

	/// he: 'הבנתי'
	String get ok => 'הבנתי';

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

	/// he: 'או'
	String get or => 'או';

	/// he: '[חסר מידע]'
	String get missingInfo => '[חסר מידע]';

	/// he: 'אין חיבור לאינטרנט'
	String get networkError => 'אין חיבור לאינטרנט';

	/// he: 'מומלץ לעבוד עם מסך לרוחב'
	String get landscapeHint => 'מומלץ לעבוד עם מסך לרוחב';

	/// he: 'סובב לרוחב'
	String get rotateLandscape => 'סובב לרוחב';

	/// he: 'חזרה לאורך'
	String get rotatePortrait => 'חזרה לאורך';
}

// Path: auth
class Translations$auth$he {
	Translations$auth$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ברוכים הבאים ל-EasyPlate'
	String get welcome => 'ברוכים הבאים ל-EasyPlate';

	/// he: 'התחברו כדי לשמור את המתכונים שלכם'
	String get subtitle => 'התחברו כדי לשמור את המתכונים שלכם';

	/// he: 'התחברות'
	String get signIn => 'התחברות';

	/// he: 'הרשמה'
	String get signUp => 'הרשמה';

	/// he: 'התנתקות'
	String get signOut => 'התנתקות';

	/// he: 'אימייל'
	String get email => 'אימייל';

	/// he: 'name@example.com'
	String get emailHint => 'name@example.com';

	/// he: 'סיסמה'
	String get password => 'סיסמה';

	/// he: 'לפחות 6 תווים'
	String get passwordHint => 'לפחות 6 תווים';

	/// he: 'המשך עם Google'
	String get continueWithGoogle => 'המשך עם Google';

	/// he: 'המשך עם טלפון'
	String get continueWithPhone => 'המשך עם טלפון';

	/// he: 'המשך עם אימייל'
	String get continueWithEmail => 'המשך עם אימייל';

	/// he: 'מספר טלפון'
	String get phoneNumber => 'מספר טלפון';

	/// he: '+972501234567'
	String get phoneHint => '+972501234567';

	/// he: 'שליחת קוד'
	String get sendCode => 'שליחת קוד';

	/// he: 'קוד מה-SMS'
	String get smsCode => 'קוד מה-SMS';

	/// he: 'שלחנו קוד אימות אל $phone'
	String codeSentTo({required Object phone}) => 'שלחנו קוד אימות אל ${phone}';

	/// he: 'אימות'
	String get verify => 'אימות';

	/// he: 'שליחה מחדש'
	String get resendCode => 'שליחה מחדש';

	/// he: 'שכחתי סיסמה'
	String get forgotPassword => 'שכחתי סיסמה';

	/// he: 'נשלח מייל לאיפוס הסיסמה'
	String get resetSent => 'נשלח מייל לאיפוס הסיסמה';

	/// he: 'אין לכם חשבון? הרשמו'
	String get noAccount => 'אין לכם חשבון? הרשמו';

	/// he: 'יש לכם חשבון? התחברו'
	String get haveAccount => 'יש לכם חשבון? התחברו';

	/// he: 'כתובת אימייל לא תקינה'
	String get invalidEmail => 'כתובת אימייל לא תקינה';

	/// he: 'הסיסמה חייבת להכיל לפחות 6 תווים'
	String get passwordTooShort => 'הסיסמה חייבת להכיל לפחות 6 תווים';

	/// he: 'מספר טלפון לא תקין'
	String get invalidPhone => 'מספר טלפון לא תקין';

	/// he: 'יש להזין את הקוד שקיבלתם'
	String get codeRequired => 'יש להזין את הקוד שקיבלתם';

	/// he: 'הפרטים שהוזנו שגויים'
	String get errorUnauthorized => 'הפרטים שהוזנו שגויים';

	/// he: 'אין חיבור לאינטרנט'
	String get errorNetwork => 'אין חיבור לאינטרנט';

	/// he: 'ההתחברות נכשלה, נסו שוב'
	String get errorUnknown => 'ההתחברות נכשלה, נסו שוב';

	/// he: 'להתנתק?'
	String get signOutTitle => 'להתנתק?';

	/// he: 'תצטרכו להתחבר מחדש כדי להגיע למתכונים שלכם.'
	String get signOutBody => 'תצטרכו להתחבר מחדש כדי להגיע למתכונים שלכם.';

	/// he: 'שיטת ההתחברות הזו אינה זמינה כרגע'
	String get errorOperationNotAllowed => 'שיטת ההתחברות הזו אינה זמינה כרגע';

	/// he: 'יותר מדי ניסיונות. נסו שוב עוד כמה דקות'
	String get errorTooManyRequests => 'יותר מדי ניסיונות. נסו שוב עוד כמה דקות';

	/// he: 'מספר הטלפון אינו תקין'
	String get errorInvalidPhone => 'מספר הטלפון אינו תקין';

	/// he: 'כתובת האימייל כבר רשומה'
	String get errorEmailInUse => 'כתובת האימייל כבר רשומה';

	/// he: 'אימות כתובת המייל'
	String get verifyEmailTitle => 'אימות כתובת המייל';

	/// he: 'שלחנו קישור אימות אל $email. פתחו אותו ואז חזרו לכאן.'
	String verifyEmailBody({required Object email}) => 'שלחנו קישור אימות אל ${email}. פתחו אותו ואז חזרו לכאן.';

	/// he: 'שליחת הקישור מחדש'
	String get resendEmail => 'שליחת הקישור מחדש';

	/// he: 'הקישור נשלח שוב'
	String get emailResent => 'הקישור נשלח שוב';

	/// he: 'כבר אימתתי'
	String get checkVerification => 'כבר אימתתי';

	/// he: 'הכתובת עדיין לא אומתה'
	String get stillNotVerified => 'הכתובת עדיין לא אומתה';

	/// he: 'אימות טלפון'
	String get linkPhone => 'אימות טלפון';

	/// he: 'הטלפון אומת'
	String get phoneLinked => 'הטלפון אומת';

	/// he: 'המספר הזה כבר משויך לחשבון אחר'
	String get phoneAlreadyUsed => 'המספר הזה כבר משויך לחשבון אחר';

	/// he: 'לחשבון כבר משויכת כתובת מייל'
	String get emailAlreadyLinked => 'לחשבון כבר משויכת כתובת מייל';

	/// he: 'הוספת מייל וסיסמה'
	String get addEmailPassword => 'הוספת מייל וסיסמה';

	/// he: 'מאומת'
	String get verified => 'מאומת';

	/// he: 'קישור חשבון Google'
	String get linkGoogle => 'קישור חשבון Google';

	/// he: 'מקושר'
	String get googleLinked => 'מקושר';

	/// he: 'חשבון Google הזה כבר משויך למשתמש אחר'
	String get googleAlreadyUsed => 'חשבון Google הזה כבר משויך למשתמש אחר';

	/// he: 'כבר מקושר חשבון Google'
	String get googleAlreadyLinked => 'כבר מקושר חשבון Google';

	/// he: 'אימות מספר טלפון'
	String get phoneGateTitle => 'אימות מספר טלפון';

	/// he: 'כל חשבון מאומת במספר טלפון. נשלח לכם קוד ב-SMS.'
	String get phoneGateBody => 'כל חשבון מאומת במספר טלפון. נשלח לכם קוד ב-SMS.';

	/// he: 'שינוי המספר'
	String get changeNumber => 'שינוי המספר';

	/// he: 'כניסה'
	String get signInTitle => 'כניסה';

	/// he: 'חדשים כאן? המשיכו עם טלפון.'
	String get phoneFirstHint => 'חדשים כאן? המשיכו עם טלפון.';

	/// he: 'כתובת המייל הזו כבר משויכת לחשבון אחר. היכנסו בדרך שבה נרשמתם.'
	String get errorAccountExistsDifferentCredential => 'כתובת המייל הזו כבר משויכת לחשבון אחר. היכנסו בדרך שבה נרשמתם.';

	/// he: 'הפרטים האלה כבר משויכים לחשבון אחר'
	String get errorCredentialInUse => 'הפרטים האלה כבר משויכים לחשבון אחר';

	/// he: 'המשך עם Apple'
	String get continueWithApple => 'המשך עם Apple';

	/// he: 'קישור חשבון Apple'
	String get linkApple => 'קישור חשבון Apple';

	/// he: 'מקושר'
	String get appleLinked => 'מקושר';

	/// he: 'חשבון Apple הזה כבר משויך למשתמש אחר'
	String get appleAlreadyUsed => 'חשבון Apple הזה כבר משויך למשתמש אחר';

	/// he: 'כבר מקושר חשבון Apple'
	String get appleAlreadyLinked => 'כבר מקושר חשבון Apple';

	/// he: 'החשבון נחסם'
	String get blockedTitle => 'החשבון נחסם';

	/// he: 'החשבון הזה נחסם על ידי מנהל האפליקציה. לפרטים אפשר לפנות אלינו במסך התמיכה.'
	String get blockedBody => 'החשבון הזה נחסם על ידי מנהל האפליקציה. לפרטים אפשר לפנות אלינו במסך התמיכה.';

	/// he: 'המספר הזה שייך לחשבון קיים'
	String get phoneClaimedTitle => 'המספר הזה שייך לחשבון קיים';

	/// he: 'המספר $phone כבר מחובר לחשבון EasyPlate אחר. כדי להגיע לחשבון הזה ולמתכונים שלו, היכנסו כמו שנכנסתם אליו עד עכשיו (Google, ‏Apple או מייל), ואמתו שם את המספר מחדש.'
	String phoneClaimedBody({required Object phone}) => 'המספר ${phone} כבר מחובר לחשבון EasyPlate אחר. כדי להגיע לחשבון הזה ולמתכונים שלו, היכנסו כמו שנכנסתם אליו עד עכשיו (Google, ‏Apple או מייל), ואמתו שם את המספר מחדש.';

	/// he: 'כניסה לחשבון הקיים שלי'
	String get phoneClaimedSignIn => 'כניסה לחשבון הקיים שלי';

	/// he: 'יצירת חשבון חדש בכל זאת'
	String get phoneClaimedCreateNew => 'יצירת חשבון חדש בכל זאת';

	/// he: 'ייפתח חשבון חדש וריק עבור המספר הזה. החשבון הקיים יישאר כמו שהוא, אבל לא יהיה אפשר להגיע אליו יותר עם המספר הזה.'
	String get phoneClaimedCreateNewConfirm => 'ייפתח חשבון חדש וריק עבור המספר הזה. החשבון הקיים יישאר כמו שהוא, אבל לא יהיה אפשר להגיע אליו יותר עם המספר הזה.';

	/// he: 'החשבון מחובר במכשיר אחר'
	String get sessionOtherDeviceTitle => 'החשבון מחובר במכשיר אחר';

	/// he: 'החשבון הזה פתוח כרגע ב$platform$since. אפשר להשתמש בו במכשיר אחד בכל פעם: התנתקו שם, ואז לחצו ״נסו שוב״.'
	String sessionOtherDeviceBody({required Object platform, required Object since}) => 'החשבון הזה פתוח כרגע ב${platform}${since}. אפשר להשתמש בו במכשיר אחד בכל פעם: התנתקו שם, ואז לחצו ״נסו שוב״.';

	/// he: ' מאז $date'
	String sessionSince({required Object date}) => ' מאז ${date}';

	/// he: 'ההתחברות פגה'
	String get sessionExpiredTitle => 'ההתחברות פגה';

	/// he: 'התחברות נמשכת עד חודש. כדי להמשיך, התחברו מחדש.'
	String get sessionExpiredBody => 'התחברות נמשכת עד חודש. כדי להמשיך, התחברו מחדש.';

	/// he: 'נסו שוב'
	String get sessionRetry => 'נסו שוב';

	/// he: 'אייפון'
	String get platformIos => 'אייפון';

	/// he: 'אנדרואיד'
	String get platformAndroid => 'אנדרואיד';

	/// he: 'מכשיר אחר'
	String get platformOther => 'מכשיר אחר';
}

// Path: profile
class Translations$profile$he {
	Translations$profile$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'כמה פרטים אחרונים'
	String get setupTitle => 'כמה פרטים אחרונים';

	/// he: 'כדי שנדע איך לפנות אליכם'
	String get setupSubtitle => 'כדי שנדע איך לפנות אליכם';

	/// he: 'שם מלא'
	String get fullName => 'שם מלא';

	/// he: 'ישראל ישראלי'
	String get fullNameHint => 'ישראל ישראלי';

	/// he: 'יש להזין שם מלא'
	String get fullNameRequired => 'יש להזין שם מלא';

	/// he: 'תמונת פרופיל'
	String get photo => 'תמונת פרופיל';

	/// he: 'הוספת תמונה'
	String get addPhoto => 'הוספת תמונה';

	/// he: 'טלפון (לא חובה)'
	String get phoneOptional => 'טלפון (לא חובה)';

	/// he: 'אימייל (לא חובה)'
	String get emailOptional => 'אימייל (לא חובה)';

	/// he: 'סיום הרשמה'
	String get save => 'סיום הרשמה';

	/// he: 'שומר...'
	String get saving => 'שומר...';

	/// he: 'לא הצלחנו לשמור את הפרופיל'
	String get saveFailed => 'לא הצלחנו לשמור את הפרופיל';

	/// he: 'הפרופיל שלי'
	String get myProfile => 'הפרופיל שלי';
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

// Path: allergens
class Translations$allergens$he {
	Translations$allergens$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'אלרגנים'
	String get title => 'אלרגנים';

	/// he: 'סימון אלרגנים'
	String get pick => 'סימון אלרגנים';

	/// he: 'מכיל'
	String get contains => 'מכיל';

	/// he: 'עלול להכיל'
	String get mayContain => 'עלול להכיל';

	/// he: 'גלוטן'
	String get gluten => 'גלוטן';

	/// he: 'חלב'
	String get milk => 'חלב';

	/// he: 'ביצים'
	String get eggs => 'ביצים';

	/// he: 'דגים'
	String get fish => 'דגים';

	/// he: 'פירות ים'
	String get shellfish => 'פירות ים';

	/// he: 'בוטנים'
	String get peanuts => 'בוטנים';

	/// he: 'אגוזים'
	String get treeNuts => 'אגוזים';

	/// he: 'שומשום'
	String get sesame => 'שומשום';

	/// he: 'סויה'
	String get soy => 'סויה';
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

	/// he: 'מראה'
	String get appearance => 'מראה';

	/// he: 'לפי המכשיר'
	String get themeSystem => 'לפי המכשיר';

	/// he: 'בהיר'
	String get themeLight => 'בהיר';

	/// he: 'כהה'
	String get themeDark => 'כהה';

	/// he: 'אפקטי קול (דפדוף עמודים)'
	String get soundEffects => 'אפקטי קול (דפדוף עמודים)';

	/// he: 'מעבר מהיר בספר'
	String get fastPageTurn => 'מעבר מהיר בספר';

	/// he: 'קפיצה מתוכן העניינים או מהניווט המהיר מדפדפת דף אחד בלבד אל היעד. בכיבוי מדפדפים דרך כל העמודים שבדרך.'
	String get fastPageTurnHint => 'קפיצה מתוכן העניינים או מהניווט המהיר מדפדפת דף אחד בלבד אל היעד. בכיבוי מדפדפים דרך כל העמודים שבדרך.';

	/// he: 'ניהול שיתופים'
	String get sharedAccess => 'ניהול שיתופים';

	/// he: 'עדיין לא שיתפתם ספרים או רשימות'
	String get noSharedAccess => 'עדיין לא שיתפתם ספרים או רשימות';

	/// he: 'מחירים לפי ממוצע המשתמשים'
	String get communityPrices => 'מחירים לפי ממוצע המשתמשים';

	/// he: 'כשאין לך מחיר משלך למוצר, הצג את המחיר החציוני שאנשים אחרים שיתפו'
	String get communityPricesHint => 'כשאין לך מחיר משלך למוצר, הצג את המחיר החציוני שאנשים אחרים שיתפו';

	/// he: 'תזכורות ליום הקניות'
	String get shoppingReminders => 'תזכורות ליום הקניות';

	/// he: 'ההתראות נשלחות מהמכשיר, לפי יום הקניות שנבחר'
	String get shoppingRemindersHint => 'ההתראות נשלחות מהמכשיר, לפי יום הקניות שנבחר';

	/// he: 'יומיים לפני (ערב)'
	String get reminderTwoDaysBefore => 'יומיים לפני (ערב)';

	/// he: 'יום לפני (ערב)'
	String get reminderDayBefore => 'יום לפני (ערב)';

	/// he: 'ביום הקניות (בוקר)'
	String get reminderSameDayMorning => 'ביום הקניות (בוקר)';

	/// he: 'ביום הקניות (אחה״צ)'
	String get reminderSameDayAfternoon => 'ביום הקניות (אחה״צ)';

	/// he: 'מתרגם את המתכונים והתפריטים שלך...'
	String get translatingContent => 'מתרגם את המתכונים והתפריטים שלך...';

	/// he: '$count פריטים תורגמו'
	String translatedContent({required Object count}) => '${count} פריטים תורגמו';

	/// he: 'התרגום לא הושלם'
	String get translationPartialTitle => 'התרגום לא הושלם';

	/// he: '$count פריטים נשארו בשפת המקור. אפשר לנסות שוב מאוחר יותר.'
	String translationPartial({required Object count}) => '${count} פריטים נשארו בשפת המקור. אפשר לנסות שוב מאוחר יותר.';

	/// he: 'התרגום נכשל. התוכן נשאר בשפת המקור.'
	String get translationFailed => 'התרגום נכשל. התוכן נשאר בשפת המקור.';

	/// he: 'חשבון'
	String get account => 'חשבון';

	/// he: 'התראות'
	String get notifications => 'התראות';

	/// he: 'אילו התראות מגיעות אליך, ואיך'
	String get notificationsHint => 'אילו התראות מגיעות אליך, ואיך';

	/// he: 'חשבון, התראות, שפה ומראה'
	String get settingsHint => 'חשבון, התראות, שפה ומראה';

	/// he: 'אזור מסוכן'
	String get dangerZone => 'אזור מסוכן';

	/// he: 'מחיקת החשבון'
	String get deleteAccount => 'מחיקת החשבון';

	/// he: 'מחיקה לצמיתות של החשבון וכל המידע שבו'
	String get deleteAccountHint => 'מחיקה לצמיתות של החשבון וכל המידע שבו';

	/// he: 'למחוק את החשבון לצמיתות?'
	String get deleteAccountTitle => 'למחוק את החשבון לצמיתות?';

	/// he: 'החשבון, המתכונים, הספרים, התפריטים, רשימות הקניות, הקבלות, התמונות, הפוסטים והתגובות שלכם יימחקו לצמיתות משרתינו ומהמכשיר הזה, ואי אפשר יהיה לשחזר אותם. מה ששיתפתם יוסר גם ממי ששיתפתם איתו. מנוי פעיל אינו מתבטל אוטומטית: בטלו אותו ב-App Store או ב-Google Play.'
	String get deleteAccountBody => 'החשבון, המתכונים, הספרים, התפריטים, רשימות הקניות, הקבלות, התמונות, הפוסטים והתגובות שלכם יימחקו לצמיתות משרתינו ומהמכשיר הזה, ואי אפשר יהיה לשחזר אותם. מה ששיתפתם יוסר גם ממי ששיתפתם איתו. מנוי פעיל אינו מתבטל אוטומטית: בטלו אותו ב-App Store או ב-Google Play.';

	/// he: 'מחיקה לצמיתות'
	String get deleteAccountConfirm => 'מחיקה לצמיתות';

	/// he: 'מוחקים את החשבון…'
	String get deletingAccount => 'מוחקים את החשבון…';

	/// he: 'מחיקת החשבון נכשלה. נסו שוב, או כתבו ל-support@aieasyplate.app.'
	String get deleteAccountFailed => 'מחיקת החשבון נכשלה. נסו שוב, או כתבו ל-support@aieasyplate.app.';

	/// he: 'אתם הבעלים של משק בית משותף. סגרו אותו קודם במסך "משק בית" ואז נסו שוב.'
	String get deleteAccountHousehold => 'אתם הבעלים של משק בית משותף. סגרו אותו קודם במסך "משק בית" ואז נסו שוב.';
}

// Path: notificationSettings
class Translations$notificationSettings$he {
	Translations$notificationSettings$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הגדרות התראות'
	String get title => 'הגדרות התראות';

	/// he: 'התראות דחיפה'
	String get push => 'התראות דחיפה';

	/// he: 'התראות במכשיר הזה. בכיבוי, שום דבר לא נשלח לטלפון; תיבת ההתראות ממשיכה להתמלא.'
	String get pushHint => 'התראות במכשיר הזה. בכיבוי, שום דבר לא נשלח לטלפון; תיבת ההתראות ממשיכה להתמלא.';

	/// he: 'ההתראות של EasyPlate חסומות בהגדרות המכשיר. כדי לקבל התראות, יש לאפשר אותן שם.'
	String get pushDenied => 'ההתראות של EasyPlate חסומות בהגדרות המכשיר. כדי לקבל התראות, יש לאפשר אותן שם.';

	/// he: 'קהילה'
	String get community => 'קהילה';

	/// he: 'תגובות לפוסטים שלי'
	String get repliesOnMyPosts => 'תגובות לפוסטים שלי';

	/// he: 'מישהו ענה בדיון שפתחת'
	String get repliesOnMyPostsHint => 'מישהו ענה בדיון שפתחת';

	/// he: 'תגובות בדיונים שהשתתפתי בהם'
	String get repliesOnThreads => 'תגובות בדיונים שהשתתפתי בהם';

	/// he: 'תגובה חדשה בדיון שהגבת בו'
	String get repliesOnThreadsHint => 'תגובה חדשה בדיון שהגבת בו';

	/// he: 'שיתוף'
	String get sharing => 'שיתוף';

	/// he: 'הזמנות לשיתוף'
	String get shareInvites => 'הזמנות לשיתוף';

	/// he: 'מישהו שיתף איתך מתכון, ספר או תפריט. ההזמנה תמיד מגיעה לתיבה; כאן נקבע רק אם תישלח התראה.'
	String get shareInvitesHint => 'מישהו שיתף איתך מתכון, ספר או תפריט. ההזמנה תמיד מגיעה לתיבה; כאן נקבע רק אם תישלח התראה.';

	/// he: 'עדכונים למתכונים ששמרתי'
	String get sharedRecipeUpdates => 'עדכונים למתכונים ששמרתי';

	/// he: 'הכותב/ת שינה/תה מתכון מהקהילה ששמרת'
	String get sharedRecipeUpdatesHint => 'הכותב/ת שינה/תה מתכון מהקהילה ששמרת';

	/// he: 'מ-EasyPlate'
	String get easyPlate => 'מ-EasyPlate';

	/// he: 'תשובות לפניות שלי לתמיכה'
	String get adminReplies => 'תשובות לפניות שלי לתמיכה';

	/// he: 'הודעות מהצוות'
	String get announcements => 'הודעות מהצוות';

	/// he: 'חדשות ועדכונים מצוות EasyPlate'
	String get announcementsHint => 'חדשות ועדכונים מצוות EasyPlate';

	/// he: 'כשהאפליקציה פתוחה'
	String get inApp => 'כשהאפליקציה פתוחה';

	/// he: 'הצגת התראות כחלונית'
	String get foregroundPopups => 'הצגת התראות כחלונית';

	/// he: 'התראה שמגיעה בזמן שהאפליקציה פתוחה נפתחת בכרטיס קטן. בכיבוי, היא מגיעה רק לתיבת ההתראות.'
	String get foregroundPopupsHint => 'התראה שמגיעה בזמן שהאפליקציה פתוחה נפתחת בכרטיס קטן. בכיבוי, היא מגיעה רק לתיבת ההתראות.';

	/// he: 'תזכורות קניות'
	String get reminders => 'תזכורות קניות';
}

// Path: preferences
class Translations$preferences$he {
	Translations$preferences$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'העדפות'
	String get title => 'העדפות';

	/// he: 'קניות, העדפות תזונתיות והתנהגות הספרים'
	String get hint => 'קניות, העדפות תזונתיות והתנהגות הספרים';

	/// he: 'קניות'
	String get shopping => 'קניות';

	/// he: 'ספרי מתכונים'
	String get books => 'ספרי מתכונים';
}

// Path: more
class Translations$more$he {
	Translations$more$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'עוד'
	String get title => 'עוד';

	/// he: 'הגדרות'
	String get settings => 'הגדרות';

	/// he: 'פרופיל אישי'
	String get profile => 'פרופיל אישי';

	/// he: 'תמיכה'
	String get support => 'תמיכה';

	/// he: 'איך אפשר לעזור?'
	String get supportTitle => 'איך אפשר לעזור?';

	/// he: 'כתבו לנו ונחזור אליכם בהקדם.'
	String get supportBody => 'כתבו לנו ונחזור אליכם בהקדם.';

	/// he: 'שליחת הודעה בוואטסאפ'
	String get whatsapp => 'שליחת הודעה בוואטסאפ';

	/// he: 'שליחת מייל'
	String get email => 'שליחת מייל';

	/// he: 'לא הצלחנו לפתוח את האפליקציה'
	String get supportUnavailable => 'לא הצלחנו לפתוח את האפליקציה';

	/// he: 'העדפות'
	String get preferences => 'העדפות';

	/// he: 'תמיכה ומידע'
	String get help => 'תמיכה ומידע';

	/// he: 'תמיכה, מדיניות פרטיות ותנאי שימוש'
	String get helpHint => 'תמיכה, מדיניות פרטיות ותנאי שימוש';

	/// he: 'מידע משפטי'
	String get legal => 'מידע משפטי';
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

	/// he: 'צבע הפס'
	String get spineColor => 'צבע הפס';
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

	/// he: '$count שע׳'
	String hours({required Object count}) => '${count} שע׳';

	/// he: '$hours שע׳ ו$minutes דק׳'
	String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours} שע׳ ו${minutes} דק׳';

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

	/// he: 'המתכונים שלי'
	String get mine => 'המתכונים שלי';

	/// he: 'מתכונים ששמרתי'
	String get saved => 'מתכונים ששמרתי';

	/// he: 'עדיין לא יצרתם מתכונים'
	String get noneMine => 'עדיין לא יצרתם מתכונים';

	/// he: 'עדיין לא שמרתם מתכונים מהקהילה'
	String get noneSaved => 'עדיין לא שמרתם מתכונים מהקהילה';

	/// he: 'ממתין לניתוח'
	String get pendingAnalysis => 'ממתין לניתוח';

	/// he: 'המתכון נשמר כטקסט גולמי. אפשר לנתח אותו עכשיו או לערוך ידנית.'
	String get pendingAnalysisHint => 'המתכון נשמר כטקסט גולמי. אפשר לנתח אותו עכשיו או לערוך ידנית.';

	/// he: 'ניתוח באמצעות AI עכשיו'
	String get analyzeNow => 'ניתוח באמצעות AI עכשיו';

	/// he: 'מנתח את המתכון...'
	String get analyzing => 'מנתח את המתכון...';

	/// he: 'הניתוח נכשל, אפשר לנסות שוב מאוחר יותר'
	String get analyzeFailed => 'הניתוח נכשל, אפשר לנסות שוב מאוחר יותר';

	/// he: 'המתכון משותף בקהילה'
	String get communityUpdateTitle => 'המתכון משותף בקהילה';

	/// he: 'לעדכן גם את העותק בקהילה, או רק אצלך?'
	String get communityUpdateBody => 'לעדכן גם את העותק בקהילה, או רק אצלך?';

	/// he: 'גם בקהילה'
	String get communityUpdateBoth => 'גם בקהילה';

	/// he: 'רק אצלי'
	String get communityUpdateLocal => 'רק אצלי';

	/// he: 'העותק בקהילה עודכן'
	String get communityUpdated => 'העותק בקהילה עודכן';

	/// he: 'המתכון כבר לא בקהילה, נשמר רק אצלך'
	String get communityGone => 'המתכון כבר לא בקהילה, נשמר רק אצלך';
}

// Path: cookMode
class Translations$cookMode$he {
	Translations$cookMode$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'מצב בישול'
	String get title => 'מצב בישול';

	/// he: 'להתחיל לבשל'
	String get start => 'להתחיל לבשל';

	/// he: 'שלב $n מתוך $total'
	String stepOf({required Object n, required Object total}) => 'שלב ${n} מתוך ${total}';

	/// he: 'מצרכים'
	String get ingredients => 'מצרכים';

	/// he: 'בשלב הזה'
	String get inThisStep => 'בשלב הזה';

	/// he: 'טיימר'
	String get timer => 'טיימר';

	/// he: 'להפעיל טיימר'
	String get startTimer => 'להפעיל טיימר';

	/// he: 'השהיה'
	String get pause => 'השהיה';

	/// he: 'להמשיך'
	String get resume => 'להמשיך';

	/// he: 'איפוס'
	String get reset => 'איפוס';

	/// he: 'הזמן נגמר!'
	String get timeUp => 'הזמן נגמר!';

	/// he: 'לשלב הבא'
	String get next => 'לשלב הבא';

	/// he: 'הקודם'
	String get previous => 'הקודם';

	/// he: 'סיימתי לבשל'
	String get finish => 'סיימתי לבשל';

	/// he: 'בתיאבון!'
	String get finishedTitle => 'בתיאבון!';

	/// he: 'כל השלבים הושלמו. המסך יכול לכבות שוב.'
	String get finishedBody => 'כל השלבים הושלמו. המסך יכול לכבות שוב.';

	/// he: 'המסך נשאר דולק בזמן הבישול'
	String get screenOn => 'המסך נשאר דולק בזמן הבישול';

	/// he: 'למתכון הזה אין עדיין שלבים'
	String get noSteps => 'למתכון הזה אין עדיין שלבים';

	/// he: 'טיימר רץ בשלב $n'
	String runningOnStep({required Object n}) => 'טיימר רץ בשלב ${n}';

	/// he: 'באמצע מצב בישול'
	String get inProgress => 'באמצע מצב בישול';

	/// he: '"$recipe" · שלב $n מתוך $total'
	String inProgressBody({required Object recipe, required Object n, required Object total}) => '"${recipe}" · שלב ${n} מתוך ${total}';

	/// he: 'המשך'
	String get resumeCooking => 'המשך';

	/// he: 'סיום'
	String get endCooking => 'סיום';

	/// he: 'שלב $n'
	String stepLabel({required Object n}) => 'שלב ${n}';

	/// he: 'מסתיים ב-$time · $total · שלב $n'
	String ongoingBody({required Object time, required Object total, required Object n}) => 'מסתיים ב-${time} · ${total} · שלב ${n}';

	/// he: 'שלב $n: הזמן נגמר'
	String timeUpBody({required Object n}) => 'שלב ${n}: הזמן נגמר';

	/// he: 'טיימרים פועלים'
	String get runningTimers => 'טיימרים פועלים';

	/// he: 'מצב בישול הוא חלק מ-EasyPlate Premium'
	String get premiumOnly => 'מצב בישול הוא חלק מ-EasyPlate Premium';
}

// Path: nutrition
class Translations$nutrition$he {
	Translations$nutrition$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ערכים תזונתיים'
	String get title => 'ערכים תזונתיים';

	/// he: 'למנה'
	String get perServing => 'למנה';

	/// he: 'כל הערכים הם למנה אחת. השאירו ריק כדי להוריד את ההערכה.'
	String get perServingHint => 'כל הערכים הם למנה אחת. השאירו ריק כדי להוריד את ההערכה.';

	/// he: 'מנות'
	String get servings => 'מנות';

	/// he: '$count מנות'
	String servingsCount({required Object count}) => '${count} מנות';

	/// he: 'קלוריות'
	String get calories => 'קלוריות';

	/// he: 'קק״ל'
	String get kcal => 'קק״ל';

	/// he: 'חלבון'
	String get protein => 'חלבון';

	/// he: 'פחמימות'
	String get carbs => 'פחמימות';

	/// he: 'שומן'
	String get fat => 'שומן';

	/// he: 'ג׳'
	String get gramsShort => 'ג׳';

	/// he: 'הערכה עם AI'
	String get estimate => 'הערכה עם AI';

	/// he: 'מעריך ערכים תזונתיים…'
	String get estimating => 'מעריך ערכים תזונתיים…';

	/// he: 'ההערכה לא הצליחה, נסו שוב'
	String get estimateFailed => 'ההערכה לא הצליחה, נסו שוב';

	/// he: 'עוד אין ערכים תזונתיים למתכון הזה'
	String get none => 'עוד אין ערכים תזונתיים למתכון הזה';

	/// he: 'ה-AI יכול להעריך קלוריות, חלבון, פחמימות ושומן מרשימת המצרכים'
	String get noneHint => 'ה-AI יכול להעריך קלוריות, חלבון, פחמימות ושומן מרשימת המצרכים';

	/// he: 'הערכים התזונתיים עודכנו'
	String get estimated => 'הערכים התזונתיים עודכנו';

	/// he: 'מספר מנות'
	String get editorServings => 'מספר מנות';

	/// he: 'קלוריות למנה'
	String get editorCalories => 'קלוריות למנה';

	/// he: 'חלבון (גרם)'
	String get editorProtein => 'חלבון (גרם)';

	/// he: 'פחמימות (גרם)'
	String get editorCarbs => 'פחמימות (גרם)';

	/// he: 'שומן (גרם)'
	String get editorFat => 'שומן (גרם)';

	/// he: 'דאשבורד תזונה'
	String get dashboard => 'דאשבורד תזונה';

	/// he: 'השבוע'
	String get weekly => 'השבוע';

	/// he: 'היום'
	String get today => 'היום';

	/// he: 'סה״כ ליום'
	String get dayTotal => 'סה״כ ליום';

	/// he: 'סה״כ לשבוע'
	String get weekTotal => 'סה״כ לשבוע';

	/// he: 'ממוצע ליום מתוכנן'
	String get dailyAverage => 'ממוצע ליום מתוכנן';

	/// he: 'לפי ארוחה'
	String get perMeal => 'לפי ארוחה';

	/// he: 'לפי יום'
	String get perDay => 'לפי יום';

	/// he: 'עוד לא תוכננו ארוחות עם מתכונים'
	String get noPlanned => 'עוד לא תוכננו ארוחות עם מתכונים';

	/// he: '$count פריטים בלי ערכים תזונתיים'
	String missingCount({required Object count}) => '${count} פריטים בלי ערכים תזונתיים';

	/// he: 'חלוקת קלוריות'
	String get macroSplit => 'חלוקת קלוריות';

	/// he: 'קק״ל ליום'
	String get kcalPerDay => 'קק״ל ליום';

	/// he: 'דאשבורד שבועי'
	String get openDashboard => 'דאשבורד שבועי';

	/// he: 'לכל המתכון'
	String get perRecipe => 'לכל המתכון';

	/// he: '$count מנות'
	String perRecipeServings({required Object count}) => '${count} מנות';
}

// Path: community
class Translations$community$he {
	Translations$community$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'קהילה'
	String get title => 'קהילה';

	/// he: 'פורום'
	String get forum => 'פורום';

	/// he: 'מתכונים משותפים'
	String get sharedRecipes => 'מתכונים משותפים';

	/// he: 'פוסט חדש'
	String get newPost => 'פוסט חדש';

	/// he: 'כותרת'
	String get postTitle => 'כותרת';

	/// he: 'מה בא לכם לשאול או לספר?'
	String get postBody => 'מה בא לכם לשאול או לספר?';

	/// he: 'צריך כותרת לפוסט'
	String get postTitleRequired => 'צריך כותרת לפוסט';

	/// he: 'צריך תוכן לפוסט'
	String get postBodyRequired => 'צריך תוכן לפוסט';

	/// he: 'פרסום'
	String get publish => 'פרסום';

	/// he: '$count תגובות'
	String replies({required Object count}) => '${count} תגובות';

	/// he: 'עדיין אין תגובות'
	String get noReplies => 'עדיין אין תגובות';

	/// he: 'תגובה אחת'
	String get oneReply => 'תגובה אחת';

	/// he: 'כתבו תגובה...'
	String get writeReply => 'כתבו תגובה...';

	/// he: 'שליחה'
	String get send => 'שליחה';

	/// he: 'אין עדיין פוסטים. תהיו הראשונים!'
	String get noPosts => 'אין עדיין פוסטים. תהיו הראשונים!';

	/// he: 'עדיין לא שותפו מתכונים. שתפו את הראשון!'
	String get noSharedRecipes => 'עדיין לא שותפו מתכונים. שתפו את הראשון!';

	/// he: 'שיתוף מתכון'
	String get shareRecipe => 'שיתוף מתכון';

	/// he: 'איזה מתכון לשתף?'
	String get pickRecipeToShare => 'איזה מתכון לשתף?';

	/// he: 'שמירה למתכונים שלי'
	String get saveToMyRecipes => 'שמירה למתכונים שלי';

	/// he: 'המתכון נשמר אצלכם'
	String get savedToMyRecipes => 'המתכון נשמר אצלכם';

	/// he: 'מחיקת פוסט'
	String get deletePost => 'מחיקת פוסט';

	/// he: 'הפוסט והתגובות שלו יימחקו לצמיתות.'
	String get deletePostConfirm => 'הפוסט והתגובות שלו יימחקו לצמיתות.';

	/// he: 'הסרת השיתוף'
	String get unshare => 'הסרת השיתוף';

	/// he: 'המתכון יוסר מהפיד המשותף.'
	String get unshareConfirm => 'המתכון יוסר מהפיד המשותף.';

	/// he: 'מאת $name'
	String byAuthor({required Object name}) => 'מאת ${name}';

	/// he: 'לא הצלחנו לטעון את התוכן'
	String get loadFailed => 'לא הצלחנו לטעון את התוכן';

	/// he: 'כל המתכונים'
	String get allRecipes => 'כל המתכונים';

	/// he: 'המתכונים שלי'
	String get myRecipes => 'המתכונים שלי';

	/// he: 'עריכת המתכון המשותף'
	String get editShared => 'עריכת המתכון המשותף';

	/// he: 'המתכון המשותף עודכן'
	String get sharedUpdated => 'המתכון המשותף עודכן';

	/// he: 'עדיין לא שיתפתם מתכונים'
	String get noneOfMine => 'עדיין לא שיתפתם מתכונים';

	/// he: 'חיפוש'
	String get search => 'חיפוש';

	/// he: 'שם מתכון או שם מפרסם'
	String get searchHint => 'שם מתכון או שם מפרסם';

	/// he: 'ששמרתי'
	String get savedOnly => 'ששמרתי';

	/// he: 'לא נמצאו תוצאות'
	String get noResults => 'לא נמצאו תוצאות';

	/// he: 'צירוף מתכון'
	String get attachRecipe => 'צירוף מתכון';

	/// he: 'פתיחת המתכון'
	String get openRecipe => 'פתיחת המתכון';

	/// he: 'המתכון הזה כבר לא זמין'
	String get recipeUnavailable => 'המתכון הזה כבר לא זמין';

	/// he: 'מיון וסינון'
	String get sortAndFilter => 'מיון וסינון';

	/// he: 'מיון'
	String get sort => 'מיון';

	/// he: 'החדשים ביותר'
	String get sortNewest => 'החדשים ביותר';

	/// he: 'הישנים ביותר'
	String get sortOldest => 'הישנים ביותר';

	/// he: 'הכי אהובים'
	String get sortMostLiked => 'הכי אהובים';

	/// he: 'נושאים'
	String get topics => 'נושאים';

	/// he: 'לייקים'
	String get likes => 'לייקים';

	/// he: 'כל כמות'
	String get anyLikes => 'כל כמות';

	/// he: '$count ומעלה'
	String atLeastLikes({required Object count}) => '${count} ומעלה';

	/// he: 'זמן הכנה כולל'
	String get totalTime => 'זמן הכנה כולל';

	/// he: 'כל זמן'
	String get anyTime => 'כל זמן';

	/// he: 'עד $duration'
	String upTo({required Object duration}) => 'עד ${duration}';

	/// he: 'ניקוי סינונים'
	String get clearFilters => 'ניקוי סינונים';

	/// he: 'הצגת התוצאות'
	String get applyFilters => 'הצגת התוצאות';

	/// he: '$count+'
	String likesPlus({required Object count}) => '${count}+';

	/// he: '$duration+'
	String durationPlus({required Object duration}) => '${duration}+';

	/// he: 'פיצול להכנה ובישול'
	String get splitTimes => 'פיצול להכנה ובישול';

	/// he: 'המתכון כבר שמור אצלכם'
	String get alreadySaved => 'המתכון כבר שמור אצלכם';

	/// he: 'שמור אצלכם'
	String get savedTag => 'שמור אצלכם';

	/// he: 'הסרה מהמתכונים ששמרתי'
	String get removeSaved => 'הסרה מהמתכונים ששמרתי';

	/// he: 'המתכון יוסר מהמתכונים ששמרתם. אפשר לשמור אותו שוב מהקהילה.'
	String get removeSavedConfirm => 'המתכון יוסר מהמתכונים ששמרתם. אפשר לשמור אותו שוב מהקהילה.';

	/// he: 'פוסט חדש אחד'
	String get oneNewPost => 'פוסט חדש אחד';

	/// he: '$count פוסטים חדשים'
	String newPosts({required Object count}) => '${count} פוסטים חדשים';

	/// he: 'לא הצלחנו לשלוח את התגובה'
	String get replyFailed => 'לא הצלחנו לשלוח את התגובה';
}

// Path: sharing
class Translations$sharing$he {
	Translations$sharing$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'שיתוף מתכון'
	String get title => 'שיתוף מתכון';

	/// he: 'אימייל או טלפון של השותף/ה'
	String get contactLabel => 'אימייל או טלפון של השותף/ה';

	/// he: 'name@example.com או 05…'
	String get contactHint => 'name@example.com או 05…';

	/// he: 'הרשאה'
	String get roleTitle => 'הרשאה';

	/// he: 'צפייה בלבד'
	String get roleViewer => 'צפייה בלבד';

	/// he: 'רואה את המתכון, לא יכול/ה לשנות אותו'
	String get roleViewerHint => 'רואה את המתכון, לא יכול/ה לשנות אותו';

	/// he: 'עריכה'
	String get roleEditor => 'עריכה';

	/// he: 'שינויים שלו/ה יופיעו גם אצלכם'
	String get roleEditorHint => 'שינויים שלו/ה יופיעו גם אצלכם';

	/// he: 'שליחת הזמנה'
	String get send => 'שליחת הזמנה';

	/// he: 'ההזמנה נשלחה'
	String get sent => 'ההזמנה נשלחה';

	/// he: 'יש להזין אימייל או מספר טלפון תקינים'
	String get invalidContact => 'יש להזין אימייל או מספר טלפון תקינים';

	/// he: 'לא נמצא חשבון עם הפרטים האלה. ודאו שהאימייל או הטלפון מקושרים לחשבון שלו/ה, ושהאפליקציה נפתחה אצלו/ה לאחרונה.'
	String get notFound => 'לא נמצא חשבון עם הפרטים האלה. ודאו שהאימייל או הטלפון מקושרים לחשבון שלו/ה, ושהאפליקציה נפתחה אצלו/ה לאחרונה.';

	/// he: 'אי אפשר לשתף עם עצמכם'
	String get self => 'אי אפשר לשתף עם עצמכם';

	/// he: 'השיתוף נכשל, נסו שוב'
	String get failed => 'השיתוף נכשל, נסו שוב';

	/// he: 'הזמנות ממתינות'
	String get pendingInvites => 'הזמנות ממתינות';

	/// he: 'אין הזמנות ממתינות'
	String get noPendingInvites => 'אין הזמנות ממתינות';

	/// he: 'מה ששיתפתי'
	String get sharedByMe => 'מה ששיתפתי';

	/// he: 'מה ששותף איתי'
	String get sharedWithMe => 'מה ששותף איתי';

	/// he: 'עדיין לא שיתפתם כלום'
	String get nothingSharedByMe => 'עדיין לא שיתפתם כלום';

	/// he: 'עדיין לא שותף איתכם כלום'
	String get nothingSharedWithMe => 'עדיין לא שותף איתכם כלום';

	/// he: 'אישור'
	String get accept => 'אישור';

	/// he: 'ביטול'
	String get decline => 'ביטול';

	/// he: 'המתכון נוסף למתכונים שלכם'
	String get accepted => 'המתכון נוסף למתכונים שלכם';

	/// he: 'ההזמנה נדחתה'
	String get declined => 'ההזמנה נדחתה';

	/// he: 'האישור נכשל, נסו שוב'
	String get acceptFailed => 'האישור נכשל, נסו שוב';

	/// he: 'שותפים'
	String get members => 'שותפים';

	/// he: 'עדיין אין שותפים שאישרו'
	String get noMembersYet => 'עדיין אין שותפים שאישרו';

	/// he: 'הסרה'
	String get remove => 'הסרה';

	/// he: 'יציאה מהשיתוף'
	String get leave => 'יציאה מהשיתוף';

	/// he: 'השותף/ה הוסר/ה'
	String get removed => 'השותף/ה הוסר/ה';

	/// he: 'יצאתם מהשיתוף'
	String get left => 'יצאתם מהשיתוף';

	/// he: 'מאת $name'
	String invitedBy({required Object name}) => 'מאת ${name}';

	/// he: 'משותף'
	String get sharedTag => 'משותף';

	/// he: 'צפייה בלבד'
	String get viewerTag => 'צפייה בלבד';

	/// he: 'עריכה'
	String get editorTag => 'עריכה';

	/// he: 'בבעלותי'
	String get ownerTag => 'בבעלותי';

	/// he: 'לא הצלחנו לרענן את המתכון המשותף, מוצגת הגרסה השמורה'
	String get syncFailed => 'לא הצלחנו לרענן את המתכון המשותף, מוצגת הגרסה השמורה';

	/// he: 'המתכון שותף איתכם לצפייה בלבד'
	String get viewerCannotEdit => 'המתכון שותף איתכם לצפייה בלבד';

	/// he: 'שיתוף'
	String get shareAction => 'שיתוף';

	/// he: 'השיתוף עדיין לא מוגדר בשרת. נסו לצאת ולהיכנס שוב; אם זה נמשך, יש לפרוס את חוקי Firestore.'
	String get directoryUnavailable => 'השיתוף עדיין לא מוגדר בשרת. נסו לצאת ולהיכנס שוב; אם זה נמשך, יש לפרוס את חוקי Firestore.';

	/// he: 'שיתוף ספר'
	String get shareBook => 'שיתוף ספר';

	/// he: 'שיתוף תפריט'
	String get sharePlan => 'שיתוף תפריט';

	/// he: 'הספר נוסף לספרייה שלכם'
	String get acceptedBook => 'הספר נוסף לספרייה שלכם';

	/// he: 'התפריט נוסף לתפריטים שלכם'
	String get acceptedPlan => 'התפריט נוסף לתפריטים שלכם';

	/// he: 'הספר שותף איתכם לצפייה בלבד'
	String get viewerCannotEditBook => 'הספר שותף איתכם לצפייה בלבד';

	/// he: 'התפריט שותף איתכם לצפייה בלבד'
	String get viewerCannotEditPlan => 'התפריט שותף איתכם לצפייה בלבד';

	/// he: 'מתכון'
	String get kindRecipe => 'מתכון';

	/// he: 'ספר'
	String get kindBook => 'ספר';

	/// he: 'תפריט'
	String get kindPlan => 'תפריט';

	/// he: 'המתכונים שבפנים ישותפו יחד איתו'
	String get recipesTravel => 'המתכונים שבפנים ישותפו יחד איתו';

	/// he: 'שיתוף רשימת קניות'
	String get shareList => 'שיתוף רשימת קניות';

	/// he: 'הרשימה נוספה לרשימות הקניות שלכם'
	String get acceptedList => 'הרשימה נוספה לרשימות הקניות שלכם';

	/// he: 'הרשימה שותפה איתכם לצפייה בלבד'
	String get viewerCannotEditList => 'הרשימה שותפה איתכם לצפייה בלבד';

	/// he: 'רשימת קניות'
	String get kindList => 'רשימת קניות';
}

// Path: notifications
class Translations$notifications$he {
	Translations$notifications$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'התראות'
	String get title => 'התראות';

	/// he: 'אין התראות'
	String get empty => 'אין התראות';

	/// he: '$name שיתף/ה איתך את "$recipe"'
	String sharedRecipe({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את "${recipe}"';

	/// he: 'לצפייה בלבד'
	String get asViewer => 'לצפייה בלבד';

	/// he: 'לעריכה'
	String get asEditor => 'לעריכה';

	/// he: 'סימון הכל כנקרא'
	String get markAllRead => 'סימון הכל כנקרא';

	/// he: 'פתיחת המתכון'
	String get openRecipe => 'פתיחת המתכון';

	/// he: 'ההזמנה כבר טופלה'
	String get alreadyHandled => 'ההזמנה כבר טופלה';

	/// he: '$name עדכן/ה את "$recipe"'
	String recipeUpdated({required Object name, required Object recipe}) => '${name} עדכן/ה את "${recipe}"';

	/// he: 'יש גרסה חדשה של מתכון ששמרת'
	String get recipeUpdatedHint => 'יש גרסה חדשה של מתכון ששמרת';

	/// he: 'רענון לגרסה החדשה'
	String get refreshCopy => 'רענון לגרסה החדשה';

	/// he: 'שמירת העותק שלי'
	String get keepCopy => 'שמירת העותק שלי';

	/// he: 'העותק שלך עודכן לגרסה החדשה'
	String get refreshed => 'העותק שלך עודכן לגרסה החדשה';

	/// he: 'העותק שלך נשאר כמו שהוא'
	String get keptCopy => 'העותק שלך נשאר כמו שהוא';

	/// he: 'המתכון כבר לא בקהילה'
	String get recipeGone => 'המתכון כבר לא בקהילה';

	/// he: 'מחיקת כל ההתראות'
	String get deleteAll => 'מחיקת כל ההתראות';

	/// he: 'כל ההתראות יימחקו.'
	String get deleteAllBody => 'כל ההתראות יימחקו.';

	/// he: 'פתיחת ההתראות'
	String get openInbox => 'פתיחת ההתראות';

	/// he: '$name שיתף/ה איתך את הספר "$recipe"'
	String sharedBook({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את הספר "${recipe}"';

	/// he: '$name שיתף/ה איתך את התפריט "$recipe"'
	String sharedPlan({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את התפריט "${recipe}"';

	/// he: 'תשובה מצוות EasyPlate לפנייה שלך'
	String get adminReply => 'תשובה מצוות EasyPlate לפנייה שלך';

	/// he: 'הפנייה שלך: "$excerpt"'
	String adminReplyQuote({required Object excerpt}) => 'הפנייה שלך: "${excerpt}"';

	/// he: 'הודעה מ-EasyPlate'
	String get adminMessage => 'הודעה מ-EasyPlate';

	/// he: '$name הגיב/ה לפוסט שלך "$post"'
	String forumReplyOnMyPost({required Object name, required Object post}) => '${name} הגיב/ה לפוסט שלך "${post}"';

	/// he: '$name הגיב/ה בדיון "$post"'
	String forumReplyOnThread({required Object name, required Object post}) => '${name} הגיב/ה בדיון "${post}"';

	/// he: 'פתיחת הדיון'
	String get openThread => 'פתיחת הדיון';

	/// he: 'הדיון הזה נמחק'
	String get threadGone => 'הדיון הזה נמחק';

	/// he: 'הגדרות'
	String get settings => 'הגדרות';

	/// he: '$name שיתף/ה איתך את רשימת הקניות "$recipe"'
	String sharedList({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את רשימת הקניות "${recipe}"';
}

// Path: editor
class Translations$editor$he {
	Translations$editor$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'עריכת מתכון'
	String get title => 'עריכת מתכון';

	/// he: 'שם המתכון'
	String get recipeTitle => 'שם המתכון';

	/// he: 'לדוגמה: שקשוקה ירושלמית'
	String get titleHint => 'לדוגמה: שקשוקה ירושלמית';

	/// he: 'נושאים'
	String get topics => 'נושאים';

	/// he: 'חובה להזין שם למתכון'
	String get titleRequired => 'חובה להזין שם למתכון';

	/// he: 'זמן הכנה (דק׳)'
	String get prepMinutes => 'זמן הכנה (דק׳)';

	/// he: 'זמן בישול (דק׳)'
	String get cookMinutes => 'זמן בישול (דק׳)';

	/// he: 'כמות'
	String get amount => 'כמות';

	/// he: 'יחידה'
	String get unit => 'יחידה';

	/// he: 'שם המצרך'
	String get ingredientName => 'שם המצרך';

	/// he: 'תארו את השלב'
	String get stepHint => 'תארו את השלב';

	/// he: 'הוספת מצרך'
	String get addIngredient => 'הוספת מצרך';

	/// he: 'הוספת שלב'
	String get addStep => 'הוספת שלב';

	/// he: 'הסרת מצרך'
	String get removeIngredient => 'הסרת מצרך';

	/// he: 'הסרת שלב'
	String get removeStep => 'הסרת שלב';

	/// he: 'שינוי סדר השלב'
	String get reorderStep => 'שינוי סדר השלב';

	/// he: 'תיקון שגיאות כתיב'
	String get fixSpelling => 'תיקון שגיאות כתיב';

	/// he: 'מתקן את המתכון...'
	String get refining => 'מתקן את המתכון...';

	/// he: 'לא הצלחנו לתקן את המתכון'
	String get refineError => 'לא הצלחנו לתקן את המתכון';

	/// he: 'המתכון תוקן'
	String get spellingFixed => 'המתכון תוקן';

	/// he: 'לא נמצאו שגיאות כתיב'
	String get noChanges => 'לא נמצאו שגיאות כתיב';

	/// he: 'הזמנים באופן ההכנה עודכנו לפי הזמנים החדשים'
	String get timesSynced => 'הזמנים באופן ההכנה עודכנו לפי הזמנים החדשים';

	/// he: 'לבטל את השינויים?'
	String get discardTitle => 'לבטל את השינויים?';

	/// he: 'השינויים שביצעתם לא יישמרו.'
	String get discardBody => 'השינויים שביצעתם לא יישמרו.';

	/// he: 'בטל שינויים'
	String get discard => 'בטל שינויים';

	/// he: 'איך לשמור?'
	String get saveOptionsTitle => 'איך לשמור?';

	/// he: 'שמירת השינויים כפי שהם, ללא המתנה'
	String get savePlainHint => 'שמירת השינויים כפי שהם, ללא המתנה';

	/// he: 'שמירה עם עיבוד AI'
	String get saveWithAi => 'שמירה עם עיבוד AI';

	/// he: 'תיקון שגיאות כתיב והתאמת הזמנים שבשלבי ההכנה'
	String get saveWithAiHint => 'תיקון שגיאות כתיב והתאמת הזמנים שבשלבי ההכנה';
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

	/// he: 'סרטון מהרשתות'
	String get socialVideo => 'סרטון מהרשתות';

	/// he: 'הדביקו קישור לסרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק'
	String get socialVideoHint => 'הדביקו קישור לסרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק';

	/// he: 'לא הצלחנו לקרוא את הסרטון. ייתכן שהחשבון פרטי או שהפלטפורמה חסמה את הגישה. אפשר להעתיק את הטקסט מתיאור הסרטון ולהדביק אותו כטקסט.'
	String get socialUnreadable => 'לא הצלחנו לקרוא את הסרטון. ייתכן שהחשבון פרטי או שהפלטפורמה חסמה את הגישה. אפשר להעתיק את הטקסט מתיאור הסרטון ולהדביק אותו כטקסט.';

	/// he: 'בקשת מתכון'
	String get aiRequest => 'בקשת מתכון';

	/// he: 'תארו מה בא לכם להכין. לדוגמה: מתכון לדייסת סולת לתינוקת בת שנה עם פירות'
	String get aiRequestHint => 'תארו מה בא לכם להכין. לדוגמה: מתכון לדייסת סולת לתינוקת בת שנה עם פירות';

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

	/// he: 'איך לפתוח את המתכון?'
	String get openOptionsTitle => 'איך לפתוח את המתכון?';

	/// he: 'הצגת המתכון המקורי'
	String get viewOriginal => 'הצגת המתכון המקורי';

	/// he: 'הטקסט כפי שמופיע באתר, ללא עיבוד — נטען מיד'
	String get viewOriginalHint => 'הטקסט כפי שמופיע באתר, ללא עיבוד — נטען מיד';

	/// he: 'יצירת מתכון מובנה'
	String get generateStructured => 'יצירת מתכון מובנה';

	/// he: 'ניתוח אוטומטי למצרכים, לכמויות ולשלבי ההכנה'
	String get generateStructuredHint => 'ניתוח אוטומטי למצרכים, לכמויות ולשלבי ההכנה';

	/// he: 'המתכון המקורי'
	String get originalTitle => 'המתכון המקורי';

	/// he: 'לא הצלחנו לטעון את העמוד'
	String get fetchFailed => 'לא הצלחנו לטעון את העמוד';

	/// he: 'טוען את העמוד...'
	String get loadingOriginal => 'טוען את העמוד...';

	/// he: 'המתכון נקרא ישירות מהנתונים המובנים של האתר, ללא עיבוד AI'
	String get structuredFromSite => 'המתכון נקרא ישירות מהנתונים המובנים של האתר, ללא עיבוד AI';

	/// he: 'המשך למתכון המובנה'
	String get useStructured => 'המשך למתכון המובנה';

	/// he: 'עיבוד באמצעות AI במקום'
	String get preferAi => 'עיבוד באמצעות AI במקום';

	/// he: 'הניתוח לא הושלם בזמן'
	String get analysisTimedOut => 'הניתוח לא הושלם בזמן';

	/// he: 'הניתוח נכשל'
	String get analysisFailed => 'הניתוח נכשל';

	/// he: 'הטקסט נשמר כפי שהוא. אפשר לנסות שוב, לערוך ידנית, או לשמור ולנתח מאוחר יותר.'
	String get unparsedHint => 'הטקסט נשמר כפי שהוא. אפשר לנסות שוב, לערוך ידנית, או לשמור ולנתח מאוחר יותר.';

	/// he: 'ניסיון נוסף'
	String get retryAnalysis => 'ניסיון נוסף';

	/// he: 'עריכה ידנית'
	String get editManually => 'עריכה ידנית';

	/// he: 'שמירה לניתוח מאוחר יותר'
	String get saveForLater => 'שמירה לניתוח מאוחר יותר';

	/// he: 'מתכון ללא שם'
	String get untitledRecipe => 'מתכון ללא שם';

	/// he: 'כתיבה ידנית'
	String get manual => 'כתיבה ידנית';

	/// he: 'מילוי המתכון בעצמכם בפורמט המובנה — ללא ניתוח AI וללא המתנה.'
	String get manualHint => 'מילוי המתכון בעצמכם בפורמט המובנה — ללא ניתוח AI וללא המתנה.';

	/// he: 'פתיחת עורך ריק'
	String get openBlankEditor => 'פתיחת עורך ריק';

	/// he: 'יצירת מתכון'
	String get generate => 'יצירת מתכון';

	/// he: 'כותב לכם מתכון...'
	String get generating => 'כותב לכם מתכון...';

	/// he: 'הקלטה / PDF'
	String get file => 'הקלטה / PDF';

	/// he: 'אפשר גם לשתף הקלטה או PDF ישירות מכל אפליקציה אל Easy Plate, דרך כפתור השיתוף הרגיל.'
	String get fileHint => 'אפשר גם לשתף הקלטה או PDF ישירות מכל אפליקציה אל Easy Plate, דרך כפתור השיתוף הרגיל.';

	/// he: 'בחירת קובץ'
	String get chooseFile => 'בחירת קובץ';

	/// he: 'קובץ אחר'
	String get replaceFile => 'קובץ אחר';

	/// he: 'הקבצים גדולים מדי. הגבול הכולל הוא 10MB — כעשר דקות של הקלטה.'
	String get fileTooLarge => 'הקבצים גדולים מדי. הגבול הכולל הוא 10MB — כעשר דקות של הקלטה.';

	/// he: 'אפשר לנתח רק קובצי אודיו ו‑PDF.'
	String get fileUnsupported => 'אפשר לנתח רק קובצי אודיו ו‑PDF.';

	/// he: 'הגיע מ‑$app'
	String sharedIn({required Object app}) => 'הגיע מ‑${app}';

	/// he: 'הוספת קובץ'
	String get addFile => 'הוספת קובץ';

	/// he: '$count קבצים — ינותחו יחד כמתכון אחד, לפי הסדר'
	String filesAsOne({required Object count}) => '${count} קבצים — ינותחו יחד כמתכון אחד, לפי הסדר';

	/// he: 'אפשר לחזור לוואטסאפ ולשתף עוד הקלטה — היא תצטרף לרשימה כאן.'
	String get shareMoreHint => 'אפשר לחזור לוואטסאפ ולשתף עוד הקלטה — היא תצטרף לרשימה כאן.';

	/// he: 'מאיפה מגיע המתכון?'
	String get chooseSource => 'מאיפה מגיע המתכון?';

	/// he: 'קיבלתם מתכון בוואטסאפ, העתקתם מאתר או מהודעה? הדביקו כאן את הטקסט כמו שהוא. המודל יזהה את שם המנה, המצרכים עם הכמויות ושלבי ההכנה, ויסדר הכול בפורמט אחיד. בלי מגבלה יומית.'
	String get pasteTextDescription => 'קיבלתם מתכון בוואטסאפ, העתקתם מאתר או מהודעה? הדביקו כאן את הטקסט כמו שהוא. המודל יזהה את שם המנה, המצרכים עם הכמויות ושלבי ההכנה, ויסדר הכול בפורמט אחיד. בלי מגבלה יומית.';

	/// he: 'כתבו מה בא לכם להכין, ונחפש בשבילכם מתכונים ברחבי האינטרנט. מתוך התוצאות תוכלו לקרוא את המתכון המקורי כפי שהוא, או לייבא אותו לפורמט המובנה של האפליקציה.'
	String get webSearchDescription => 'כתבו מה בא לכם להכין, ונחפש בשבילכם מתכונים ברחבי האינטרנט. מתוך התוצאות תוכלו לקרוא את המתכון המקורי כפי שהוא, או לייבא אותו לפורמט המובנה של האפליקציה.';

	/// he: 'לדוגמה: קובה סלק, שקשוקה, עוגת גבינה'
	String get webSearchHint => 'לדוגמה: קובה סלק, שקשוקה, עוגת גבינה';

	/// he: 'הדביקו קישור לעמוד מתכון באתר או בבלוג. נקרא את העמוד, נתעלם מהפרסומות ומהסיפורים שמסביב, ונחלץ רק את המתכון: מצרכים, כמויות ושלבים. באתרים רבים זה אפילו לא צורך מהמכסה היומית.'
	String get urlScrapeDescription => 'הדביקו קישור לעמוד מתכון באתר או בבלוג. נקרא את העמוד, נתעלם מהפרסומות ומהסיפורים שמסביב, ונחלץ רק את המתכון: מצרכים, כמויות ושלבים. באתרים רבים זה אפילו לא צורך מהמכסה היומית.';

	/// he: 'https://www.example.co.il/recipe/...'
	String get urlScrapeHint => 'https://www.example.co.il/recipe/...';

	/// he: 'הדביקו קישור לסרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק. נצפה בסרטון בשבילכם, נקשיב למה שנאמר ונקרא את הכתוביות והתיאור, ונהפוך את זה למתכון כתוב ומסודר. זה לוקח כדקה.'
	String get socialVideoDescription => 'הדביקו קישור לסרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק. נצפה בסרטון בשבילכם, נקשיב למה שנאמר ונקרא את הכתוביות והתיאור, ונהפוך את זה למתכון כתוב ומסודר. זה לוקח כדקה.';

	/// he: 'אין לכם מתכון, רק רעיון? תארו את המנה, למי היא מיועדת ומה חשוב לכם, והמודל יכתוב לכם מתכון מלא בהתאם להעדפות התזונתיות שהגדרתם.'
	String get aiRequestDescription => 'אין לכם מתכון, רק רעיון? תארו את המנה, למי היא מיועדת ומה חשוב לכם, והמודל יכתוב לכם מתכון מלא בהתאם להעדפות התזונתיות שהגדרתם.';

	/// he: 'כותבים את המתכון בעצמכם, ישירות בעורך המובנה: שם, מצרכים עם כמויות ויחידות, ושלבי הכנה. בלי AI ובלי המתנה. מתאים למתכון של סבתא שאתם יודעים בעל פה.'
	String get manualDescription => 'כותבים את המתכון בעצמכם, ישירות בעורך המובנה: שם, מצרכים עם כמויות ויחידות, ושלבי הכנה. בלי AI ובלי המתנה. מתאים למתכון של סבתא שאתם יודעים בעל פה.';

	/// he: 'בחרו קובץ אודיו שבו מישהו מקריא או מספר את המתכון, הודעה קולית מוואטסאפ, או PDF של מתכון. נתמלל ונקרא את הכול ונחלץ ממנו מתכון מסודר. אפשר לצרף כמה קבצים, והם ינותחו יחד כמתכון אחד.'
	String get fileDescription => 'בחרו קובץ אודיו שבו מישהו מקריא או מספר את המתכון, הודעה קולית מוואטסאפ, או PDF של מתכון. נתמלל ונקרא את הכול ונחלץ ממנו מתכון מסודר. אפשר לצרף כמה קבצים, והם ינותחו יחד כמתכון אחד.';
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

	/// he: 'אפשרויות תפריט'
	String get planOptions => 'אפשרויות תפריט';

	/// he: 'מחיקת התפריט'
	String get deletePlan => 'מחיקת התפריט';

	/// he: 'למחוק את התפריט "$name"? הארוחות שבו יימחקו.'
	String deletePlanConfirm({required Object name}) => 'למחוק את התפריט "${name}"? הארוחות שבו יימחקו.';

	/// he: 'לצאת מהשיתוף של התפריט "$name"? הוא יוסר מהרשימה שלך.'
	String leavePlanConfirm({required Object name}) => 'לצאת מהשיתוף של התפריט "${name}"? הוא יוסר מהרשימה שלך.';

	/// he: 'התפריט נמחק'
	String get planDeleted => 'התפריט נמחק';
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

	/// he: 'כל התפריטים'
	String get planFilter => 'כל התפריטים';

	/// he: 'בחר תפריטים'
	String get choosePlans => 'בחר תפריטים';

	/// he: '$count תפריטים נבחרו'
	String plansSelected({required Object count}) => '${count} תפריטים נבחרו';

	/// he: 'תפריט אחד נבחר'
	String get onePlanSelected => 'תפריט אחד נבחר';

	/// he: 'עדיין אין תפריטים לבחור מהם'
	String get noPlansToPick => 'עדיין אין תפריטים לבחור מהם';

	/// he: 'הרשימה מרוכזת מכל התפריטים'
	String get allPlansHint => 'הרשימה מרוכזת מכל התפריטים';

	/// he: 'אילו תפריטים ייכנסו לרשימה?'
	String get selectPlansTitle => 'אילו תפריטים ייכנסו לרשימה?';

	/// he: 'עדכון הרשימה'
	String get applySelection => 'עדכון הרשימה';

	/// he: 'כל התפריטים'
	String get selectAllPlans => 'כל התפריטים';

	/// he: 'הרשימות שלי'
	String get myLists => 'הרשימות שלי';

	/// he: '$count רשימות'
	String listsCount({required Object count}) => '${count} רשימות';

	/// he: 'רשימה אחת'
	String get oneList => 'רשימה אחת';

	/// he: 'רשימה חדשה'
	String get newList => 'רשימה חדשה';

	/// he: 'רשימת קניות חדשה'
	String get newListTitle => 'רשימת קניות חדשה';

	/// he: 'שם הרשימה'
	String get listName => 'שם הרשימה';

	/// he: 'רשימת קניות'
	String get defaultListName => 'רשימת קניות';

	/// he: 'מהתפריטים'
	String get fromPlans => 'מהתפריטים';

	/// he: 'מרכזת את המתכונים שבתפריטים שלך'
	String get fromPlansHint => 'מרכזת את המתכונים שבתפריטים שלך';

	/// he: 'ממתכון'
	String get fromRecipe => 'ממתכון';

	/// he: 'המצרכים של מתכון אחד'
	String get fromRecipeHint => 'המצרכים של מתכון אחד';

	/// he: 'רשימה ריקה'
	String get emptyList => 'רשימה ריקה';

	/// he: 'מוסיפים את הפריטים ידנית'
	String get emptyListHint => 'מוסיפים את הפריטים ידנית';

	/// he: 'מהתפריטים'
	String get sourcePlans => 'מהתפריטים';

	/// he: 'מהמתכון "$title"'
	String sourceRecipe({required Object title}) => 'מהמתכון "${title}"';

	/// he: 'רשימה ידנית'
	String get sourceManual => 'רשימה ידנית';

	/// he: 'שינוי שם הרשימה'
	String get renameList => 'שינוי שם הרשימה';

	/// he: 'מחיקת הרשימה'
	String get deleteList => 'מחיקת הרשימה';

	/// he: '"$name" וכל הפריטים שבה יימחקו.'
	String deleteListConfirm({required Object name}) => '"${name}" וכל הפריטים שבה יימחקו.';

	/// he: '$checked/$total'
	String progress({required Object checked, required Object total}) => '${checked}/${total}';

	/// he: 'מנות'
	String get servings => 'מנות';

	/// he: 'כמות'
	String get timesOver => 'כמות';

	/// he: '×$value'
	String scaleValue({required Object value}) => '×${value}';

	/// he: 'בנייה מחדש מהמתכון'
	String get rebuildFromRecipe => 'בנייה מחדש מהמתכון';

	/// he: 'יצירת רשימת קניות'
	String get createFromRecipe => 'יצירת רשימת קניות';

	/// he: 'יצירת הרשימה'
	String get createList => 'יצירת הרשימה';

	/// he: 'רשימת קניות ממתכון'
	String get recipeListTitle => 'רשימת קניות ממתכון';

	/// he: 'המצרכים של המתכון, לפי הכמות שמכינים'
	String get recipeListHint => 'המצרכים של המתכון, לפי הכמות שמכינים';

	/// he: 'הרשימה "$name" נוצרה'
	String listCreated({required Object name}) => 'הרשימה "${name}" נוצרה';

	/// he: 'פתיחת הרשימה'
	String get openList => 'פתיחת הרשימה';

	/// he: 'להישאר כאן'
	String get stayHere => 'להישאר כאן';

	/// he: 'אין במתכון הזה מצרכים לקנות'
	String get noIngredients => 'אין במתכון הזה מצרכים לקנות';

	/// he: 'הוספת פריט'
	String get addFirstItem => 'הוספת פריט';

	/// he: 'לצאת מהשיתוף של הרשימה "$name"? היא תוסר מהרשימות שלך.'
	String leaveListConfirm({required Object name}) => 'לצאת מהשיתוף של הרשימה "${name}"? היא תוסר מהרשימות שלך.';
}

// Path: receipt
class Translations$receipt$he {
	Translations$receipt$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'סריקת קבלה'
	String get title => 'סריקת קבלה';

	/// he: 'צלמו קבלה או העלו PDF, והמחירים יישמרו לרשימת הקניות'
	String get subtitle => 'צלמו קבלה או העלו PDF, והמחירים יישמרו לרשימת הקניות';

	/// he: 'צילום קבלה'
	String get camera => 'צילום קבלה';

	/// he: 'קבלה ארוכה? צלמו כמה תמונות, נאחד אותן'
	String get cameraHint => 'קבלה ארוכה? צלמו כמה תמונות, נאחד אותן';

	/// he: 'בחירה מהגלריה'
	String get gallery => 'בחירה מהגלריה';

	/// he: 'קובץ PDF'
	String get pdf => 'קובץ PDF';

	/// he: 'תמונה נוספת'
	String get addPhoto => 'תמונה נוספת';

	/// he: 'סרוק'
	String get scan => 'סרוק';

	/// he: 'קורא את הקבלה…'
	String get scanning => 'קורא את הקבלה…';

	/// he: '$count תמונות'
	String pagesCount({required Object count}) => '${count} תמונות';

	/// he: 'לא הצלחנו לקרוא את הקבלה. נסו תמונה חדה יותר או PDF.'
	String get scanFailed => 'לא הצלחנו לקרוא את הקבלה. נסו תמונה חדה יותר או PDF.';

	/// he: 'מה נקלט'
	String get reviewTitle => 'מה נקלט';

	/// he: 'אפשר לתקן שמות ומחירים לפני השמירה'
	String get reviewSubtitle => 'אפשר לתקן שמות ומחירים לפני השמירה';

	/// he: 'חנות'
	String get store => 'חנות';

	/// he: 'תאריך'
	String get date => 'תאריך';

	/// he: 'סה״כ בקבלה'
	String get receiptTotal => 'סה״כ בקבלה';

	/// he: 'סה״כ מוצרים שנקלטו'
	String get itemsTotal => 'סה״כ מוצרים שנקלטו';

	/// he: 'מוצרים שנקלטו'
	String get captured => 'מוצרים שנקלטו';

	/// he: '$count מוצרים'
	String capturedCount({required Object count}) => '${count} מוצרים';

	/// he: 'לא הצלחנו לקלוט'
	String get unreadable => 'לא הצלחנו לקלוט';

	/// he: 'הערות על שורות שלא הצלחנו לקרוא. אפשר להוסיף אותן ידנית למטה.'
	String get unreadableHint => 'הערות על שורות שלא הצלחנו לקרוא. אפשר להוסיף אותן ידנית למטה.';

	/// he: 'הוספת מוצר'
	String get addLine => 'הוספת מוצר';

	/// he: 'שם המוצר'
	String get itemName => 'שם המוצר';

	/// he: 'מחיר ליחידה'
	String get price => 'מחיר ליחידה';

	/// he: 'כמות'
	String get quantity => 'כמות';

	/// he: 'הסרת שורה'
	String get removeLine => 'הסרת שורה';

	/// he: 'שיתוף המחירים עם הקהילה'
	String get shareToggle => 'שיתוף המחירים עם הקהילה';

	/// he: 'רק שמות מוצרים ומחירים. בלי החנות, התאריך או מי קנה.'
	String get shareHint => 'רק שמות מוצרים ומחירים. בלי החנות, התאריך או מי קנה.';

	/// he: 'שמירת המחירים'
	String get save => 'שמירת המחירים';

	/// he: '$count מחירים נשמרו'
	String saved({required Object count}) => '${count} מחירים נשמרו';

	/// he: '$count מחירים נשמרו ושותפו'
	String savedShared({required Object count}) => '${count} מחירים נשמרו ושותפו';

	/// he: 'אין מוצרים לשמירה'
	String get nothingToSave => 'אין מוצרים לשמירה';

	/// he: 'משוער לפי נתוני עבר'
	String get estimated => 'משוער לפי נתוני עבר';

	/// he: 'עלות משוערת'
	String get estimatedTotal => 'עלות משוערת';

	/// he: 'אין נתונים'
	String get noData => 'אין נתונים';

	/// he: 'מהקבלה שלך'
	String get fromReceipt => 'מהקבלה שלך';

	/// he: 'ממוצע המשתמשים'
	String get fromCommunity => 'ממוצע המשתמשים';

	/// he: '$count פריטים בלי מחיר'
	String unpriced({required Object count}) => '${count} פריטים בלי מחיר';

	/// he: 'המחירים שלי'
	String get priceBook => 'המחירים שלי';

	/// he: 'עוד לא נסרקו קבלות. סרקו את הראשונה כדי לראות כמה עולה הקנייה.'
	String get priceBookEmpty => 'עוד לא נסרקו קבלות. סרקו את הראשונה כדי לראות כמה עולה הקנייה.';

	/// he: 'מחיקת מחיר'
	String get deleteRecord => 'מחיקת מחיר';

	/// he: 'הכניסו את הקבלה למלבן'
	String get cameraGuide => 'הכניסו את הקבלה למלבן';

	/// he: 'החזיקו יציב…'
	String get cameraHold => 'החזיקו יציב…';

	/// he: 'נקלט!'
	String get cameraCaptured => 'נקלט!';

	/// he: 'אין גישה למצלמה'
	String get cameraUnavailable => 'אין גישה למצלמה';

	/// he: 'ליח׳'
	String get perUnit => 'ליח׳';

	/// he: 'לק״ג'
	String get perKg => 'לק״ג';

	/// he: 'לליטר'
	String get perLiter => 'לליטר';

	/// he: 'מודפס: $name'
	String printedAs({required Object name}) => 'מודפס: ${name}';

	/// he: 'קבלות'
	String get receipts => 'קבלות';

	/// he: 'מחירים'
	String get prices => 'מחירים';

	/// he: 'מיון'
	String get sortBy => 'מיון';

	/// he: 'תאריך'
	String get sortDate => 'תאריך';

	/// he: 'חנות'
	String get sortStore => 'חנות';

	/// he: 'סכום'
	String get sortTotal => 'סכום';

	/// he: 'שם'
	String get sortName => 'שם';

	/// he: 'עוד אין קבלות שמורות'
	String get noReceipts => 'עוד אין קבלות שמורות';

	/// he: 'עוד אין מחירים שמורים'
	String get noPrices => 'עוד אין מחירים שמורים';

	/// he: 'מחיקת הקבלה'
	String get deleteReceipt => 'מחיקת הקבלה';

	/// he: 'הקבלה וכל המחירים שנקלטו ממנה יימחקו.'
	String get deleteReceiptBody => 'הקבלה וכל המחירים שנקלטו ממנה יימחקו.';

	/// he: 'הוספת מחיר'
	String get addPrice => 'הוספת מחיר';

	/// he: 'בלי קבלה: מחיר ששילמתם או שאתם יודעים'
	String get addPriceHint => 'בלי קבלה: מחיר ששילמתם או שאתם יודעים';

	/// he: 'הוזן ידנית'
	String get manualSource => 'הוזן ידנית';

	/// he: 'שולם לאחרונה'
	String get lastPaid => 'שולם לאחרונה';

	/// he: 'המחיר נשמר'
	String get priceSaved => 'המחיר נשמר';

	/// he: '$count מוצרים'
	String itemsInReceipt({required Object count}) => '${count} מוצרים';

	/// he: 'חיפוש מוצר'
	String get search => 'חיפוש מוצר';

	/// he: 'תמונת הקבלה'
	String get viewImage => 'תמונת הקבלה';

	/// he: 'לא נשמרה תמונה לקבלה הזו'
	String get noImage => 'לא נשמרה תמונה לקבלה הזו';

	/// he: 'קבלה מקובץ PDF'
	String get pdfFile => 'קבלה מקובץ PDF';

	/// he: 'סינון'
	String get filter => 'סינון';

	/// he: 'הכל'
	String get filterAll => 'הכל';

	/// he: 'כל התקופה'
	String get periodAll => 'כל התקופה';

	/// he: '30 יום'
	String get period30 => '30 יום';

	/// he: '90 יום'
	String get period90 => '90 יום';

	/// he: 'מקבלות'
	String get sourceReceipt => 'מקבלות';

	/// he: 'הוזנו ידנית'
	String get sourceManual => 'הוזנו ידנית';

	/// he: 'מחיקת המוצר'
	String get deleteProduct => 'מחיקת המוצר';

	/// he: 'כל המחירים שנשמרו למוצר הזה יימחקו.'
	String get deleteProductBody => 'כל המחירים שנשמרו למוצר הזה יימחקו.';

	/// he: 'בחירה מהמחירים שלי'
	String get pickFromPrices => 'בחירה מהמחירים שלי';

	/// he: 'המוצרים שלי'
	String get pickerTitle => 'המוצרים שלי';

	/// he: 'כבר קיים: $price'
	String existingPrice({required Object price}) => 'כבר קיים: ${price}';

	/// he: 'המחיר החדש'
	String get keepNew => 'המחיר החדש';

	/// he: 'המחיר הישן'
	String get keepOld => 'המחיר הישן';

	/// he: 'ממוצע'
	String get keepAverage => 'ממוצע';

	/// he: 'מחיקת הקבלה בלבד'
	String get deleteReceiptOnly => 'מחיקת הקבלה בלבד';

	/// he: 'המחירים שנקלטו ממנה נשארים'
	String get deleteReceiptOnlyHint => 'המחירים שנקלטו ממנה נשארים';

	/// he: 'מחיקת הקבלה והמחירים שלה'
	String get deleteReceiptAndPrices => 'מחיקת הקבלה והמחירים שלה';

	/// he: 'מחיקת כל המחירים'
	String get deleteAll => 'מחיקת כל המחירים';

	/// he: 'כל המחירים, הקבלות והבחירות יימחקו. אי אפשר לבטל.'
	String get deleteAllBody => 'כל המחירים, הקבלות והבחירות יימחקו. אי אפשר לבטל.';

	/// he: 'איזה מחיר להשתמש בו'
	String get pricingTitle => 'איזה מחיר להשתמש בו';

	/// he: 'האחרון'
	String get pricingLatest => 'האחרון';

	/// he: 'ממוצע של הכל'
	String get pricingAverage => 'ממוצע של הכל';

	/// he: 'לפי סופר'
	String get pricingStore => 'לפי סופר';

	/// he: 'קבלות נבחרות'
	String get pricingReceipts => 'קבלות נבחרות';

	/// he: 'בשימוש: $price'
	String pricingActive({required Object price}) => 'בשימוש: ${price}';

	/// he: 'היסטוריית מחירים'
	String get history => 'היסטוריית מחירים';

	/// he: 'ללא חנות'
	String get noStore => 'ללא חנות';

	/// he: 'הבחירה נשמרה'
	String get pricingSaved => 'הבחירה נשמרה';

	/// he: 'שינוי שם החנות'
	String get renameStore => 'שינוי שם החנות';

	/// he: 'שם החנות'
	String get storeName => 'שם החנות';

	/// he: 'כל החנויות'
	String get allStores => 'כל החנויות';

	/// he: 'החל סינון'
	String get applyFilters => 'החל סינון';

	/// he: 'ניקוי'
	String get clearFilters => 'ניקוי';
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

	/// he: 'צור תמונה ב-AI'
	String get generate => 'צור תמונה ב-AI';

	/// he: 'יוצר תמונה… זה לוקח כמה שניות'
	String get generating => 'יוצר תמונה… זה לוקח כמה שניות';

	/// he: 'יצירת התמונה נכשלה, נסו שוב'
	String get generateFailed => 'יצירת התמונה נכשלה, נסו שוב';

	/// he: 'איזו כריכה ליצור?'
	String get coverTitle => 'איזו כריכה ליצור?';

	/// he: 'בחרו קטגוריה, כתבו משהו, או שניהם'
	String get coverHint => 'בחרו קטגוריה, כתבו משהו, או שניהם';

	/// he: 'טקסט חופשי, למשל: המבורגר'
	String get coverFreeText => 'טקסט חופשי, למשל: המבורגר';

	/// he: 'צריך לבחור קטגוריה או לכתוב משהו'
	String get coverRequired => 'צריך לבחור קטגוריה או לכתוב משהו';

	/// he: 'צור כריכה'
	String get coverGenerate => 'צור כריכה';

	/// he: 'ילדים'
	String get themeKids => 'ילדים';

	/// he: 'בריא'
	String get themeHealthy => 'בריא';

	/// he: 'שחיתות'
	String get themeIndulgent => 'שחיתות';

	/// he: 'מתוקים ואפייה'
	String get themeSweets => 'מתוקים ואפייה';

	/// he: 'בשרים וגריל'
	String get themeMeat => 'בשרים וגריל';

	/// he: 'טבעוני'
	String get themeVegan => 'טבעוני';

	/// he: 'חגים'
	String get themeHolidays => 'חגים';

	/// he: 'מהיר ופשוט'
	String get themeQuick => 'מהיר ופשוט';

	/// he: 'חיפוש תמונה בגוגל'
	String get webSearch => 'חיפוש תמונה בגוגל';

	/// he: 'חיפוש תמונה'
	String get webSearchTitle => 'חיפוש תמונה';

	/// he: 'מה לחפש? למשל: קובה סלק'
	String get webSearchHint => 'מה לחפש? למשל: קובה סלק';

	/// he: 'לא נמצאו תמונות, נסו ניסוח אחר'
	String get webSearchEmpty => 'לא נמצאו תמונות, נסו ניסוח אחר';

	/// he: 'החיפוש נכשל, נסו שוב'
	String get webSearchFailed => 'החיפוש נכשל, נסו שוב';

	/// he: 'חיפוש התמונות לא זמין כרגע'
	String get webSearchUnavailable => 'חיפוש התמונות לא זמין כרגע';

	/// he: 'אלה כל התוצאות'
	String get webSearchEnd => 'אלה כל התוצאות';

	/// he: 'לא הצלחנו להוריד את התמונה, נסו אחרת'
	String get webSearchDownloadFailed => 'לא הצלחנו להוריד את התמונה, נסו אחרת';
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

	/// he: 'קהילה'
	String get community => 'קהילה';
}

// Path: update
class Translations$update$he {
	Translations$update$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'נדרש עדכון'
	String get forcedTitle => 'נדרש עדכון';

	/// he: 'הגרסה הזו של EasyPlate כבר לא נתמכת. עדכנו לגרסה $version כדי להמשיך.'
	String forcedBody({required Object version}) => 'הגרסה הזו של EasyPlate כבר לא נתמכת. עדכנו לגרסה ${version} כדי להמשיך.';

	/// he: 'יש גרסה חדשה'
	String get optionalTitle => 'יש גרסה חדשה';

	/// he: 'גרסה $version של EasyPlate כבר בחנות, עם השיפורים האחרונים.'
	String optionalBody({required Object version}) => 'גרסה ${version} של EasyPlate כבר בחנות, עם השיפורים האחרונים.';

	/// he: 'עדכון עכשיו'
	String get updateNow => 'עדכון עכשיו';

	/// he: 'דלג'
	String get later => 'דלג';
}

// Path: ads
class Translations$ads$he {
	Translations$ads$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'מודעה'
	String get badge => 'מודעה';

	/// he: 'נשארו לך $count מתכונים חופשיים להיום'
	String freeViewsLeft({required Object count}) => 'נשארו לך ${count} מתכונים חופשיים להיום';

	/// he: 'נותרו $count פתיחות עם סרטון קצר להיום'
	String rewardedViewsLeft({required Object count}) => 'נותרו ${count} פתיחות עם סרטון קצר להיום';

	/// he: 'הגעת למכסה היומית של מתכונים משותפים. המכסה תתאפס מחר!'
	String get sharedQuotaReached => 'הגעת למכסה היומית של מתכונים משותפים. המכסה תתאפס מחר!';

	/// he: 'פתיחת מתכון משותף'
	String get unlockRecipeTitle => 'פתיחת מתכון משותף';

	/// he: 'צפה בסרטון קצר כדי לפתוח מתכון זה (נשארו עוד $count להיום)'
	String unlockRecipeMessage({required Object count}) => 'צפה בסרטון קצר כדי לפתוח מתכון זה (נשארו עוד ${count} להיום)';

	/// he: 'נשארו לך $remaining/$total חילוצי AI להיום'
	String aiQuotaLeft({required Object remaining, required Object total}) => 'נשארו לך ${remaining}/${total} חילוצי AI להיום';

	/// he: 'הגעת למכסה היומית של חילוצי AI. האפשרות תיפתח מחר!'
	String get aiQuotaReached => 'הגעת למכסה היומית של חילוצי AI. האפשרות תיפתח מחר!';

	/// he: 'חילוץ מקישור דורש צפייה בסרטון קצר'
	String get aiLockedHint => 'חילוץ מקישור דורש צפייה בסרטון קצר';

	/// he: 'חילוץ מתכון עם AI'
	String get unlockAiTitle => 'חילוץ מתכון עם AI';

	/// he: 'צפה בסרטון קצר כדי לחלץ את המתכון מהקישור (נשארו עוד $count להיום)'
	String unlockAiMessage({required Object count}) => 'צפה בסרטון קצר כדי לחלץ את המתכון מהקישור (נשארו עוד ${count} להיום)';

	/// he: 'צפייה בסרטון'
	String get watchVideo => 'צפייה בסרטון';

	/// he: 'צפייה בסרטון וניתוח'
	String get parseWithVideo => 'צפייה בסרטון וניתוח';

	/// he: 'נחסם להיום'
	String get blockedForToday => 'נחסם להיום';

	/// he: 'טוען סרטון...'
	String get loadingVideo => 'טוען סרטון...';

	/// he: 'הסרטון לא הושלם, המתכון נשאר נעול'
	String get videoNotCompleted => 'הסרטון לא הושלם, המתכון נשאר נעול';

	/// he: 'אין סרטון זמין כרגע, נסו שוב בעוד רגע'
	String get videoUnavailable => 'אין סרטון זמין כרגע, נסו שוב בעוד רגע';
}

// Path: premium
class Translations$premium$he {
	Translations$premium$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'איזי-פלייט פרימיום'
	String get title => 'איזי-פלייט פרימיום';

	/// he: 'בלי מודעות, בלי מכסות'
	String get headline => 'בלי מודעות, בלי מכסות';

	/// he: 'כל מה שאיזי-פלייט יודעת לעשות, בלי לחכות למחר.'
	String get subtitle => 'כל מה שאיזי-פלייט יודעת לעשות, בלי לחכות למחר.';

	/// he: 'בלי מודעות בפידים של הקהילה'
	String get benefitNoAds => 'בלי מודעות בפידים של הקהילה';

	/// he: 'מתכונים משותפים ללא הגבלה יומית'
	String get benefitShared => 'מתכונים משותפים ללא הגבלה יומית';

	/// he: 'חילוץ מתכונים עם AI מכל קישור, עד $count ביום'
	String benefitAi({required Object count}) => 'חילוץ מתכונים עם AI מכל קישור, עד ${count} ביום';

	/// he: 'שבועי'
	String get periodWeekly => 'שבועי';

	/// he: 'חודשי'
	String get periodMonthly => 'חודשי';

	/// he: 'דו-חודשי'
	String get periodTwoMonth => 'דו-חודשי';

	/// he: 'רבעוני'
	String get periodThreeMonth => 'רבעוני';

	/// he: 'חצי-שנתי'
	String get periodSixMonth => 'חצי-שנתי';

	/// he: 'שנתי'
	String get periodAnnual => 'שנתי';

	/// he: 'לכל החיים'
	String get periodLifetime => 'לכל החיים';

	/// he: 'הכי משתלם'
	String get bestValue => 'הכי משתלם';

	/// he: 'הרשמה למנוי ב-$price'
	String subscribeFor({required Object price}) => 'הרשמה למנוי ב-${price}';

	/// he: 'רכישה ב-$price'
	String buyFor({required Object price}) => 'רכישה ב-${price}';

	/// he: 'שחזור רכישות'
	String get restore => 'שחזור רכישות';

	/// he: 'המנוי שוחזר בהצלחה'
	String get restored => 'המנוי שוחזר בהצלחה';

	/// he: 'לא נמצאו רכישות לשחזור'
	String get nothingToRestore => 'לא נמצאו רכישות לשחזור';

	/// he: 'פרימיום פעיל'
	String get activeTitle => 'פרימיום פעיל';

	/// he: 'תודה! המודעות והמכסות היומיות כבויות בחשבון הזה.'
	String get activeBody => 'תודה! המודעות והמכסות היומיות כבויות בחשבון הזה.';

	/// he: 'ניהול המנוי'
	String get manage => 'ניהול המנוי';

	/// he: 'ביטול המנוי'
	String get cancel => 'ביטול המנוי';

	/// he: 'הביטול מפסיק את החידוש האוטומטי. הפרימיום נשאר פעיל עד סוף התקופה ששולמה, ללא החזר כספי.'
	String get cancelNote => 'הביטול מפסיק את החידוש האוטומטי. הפרימיום נשאר פעיל עד סוף התקופה ששולמה, ללא החזר כספי.';

	/// he: 'המנוי אינו זמין כרגע. נסו שוב מאוחר יותר.'
	String get unavailable => 'המנוי אינו זמין כרגע. נסו שוב מאוחר יותר.';

	/// he: 'הרכישה לא הושלמה'
	String get purchaseFailed => 'הרכישה לא הושלמה';

	/// he: 'ברוכים הבאים לפרימיום!'
	String get purchased => 'ברוכים הבאים לפרימיום!';

	/// he: 'המנוי מתחדש אוטומטית בסוף כל תקופה, אלא אם בוטל לפחות 24 שעות לפני סיומה. החיוב מתבצע דרך חשבון החנות שלך, וניתן לנהל או לבטל אותו בהגדרות החנות.'
	String get legal => 'המנוי מתחדש אוטומטית בסוף כל תקופה, אלא אם בוטל לפחות 24 שעות לפני סיומה. החיוב מתבצע דרך חשבון החנות שלך, וניתן לנהל או לבטל אותו בהגדרות החנות.';

	/// he: 'תנאי שימוש'
	String get terms => 'תנאי שימוש';

	/// he: 'מדיניות פרטיות'
	String get privacy => 'מדיניות פרטיות';

	/// he: 'מתחילים ב-$price'
	String startFor({required Object price}) => 'מתחילים ב-${price}';

	/// he: 'מתחילים בחינם'
	String get startFree => 'מתחילים בחינם';

	/// he: 'חינם'
	String get free => 'חינם';

	/// he: '(one) {ליום הראשון} (other) {ל-$n הימים הראשונים}'
	String introDays({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'ליום הראשון',
		other: 'ל-${n} הימים הראשונים',
	);

	/// he: '(one) {לשבוע הראשון} (other) {ל-$n השבועות הראשונים}'
	String introWeeks({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'לשבוע הראשון',
		other: 'ל-${n} השבועות הראשונים',
	);

	/// he: '(one) {לחודש הראשון} (other) {ל-$n החודשים הראשונים}'
	String introMonths({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'לחודש הראשון',
		other: 'ל-${n} החודשים הראשונים',
	);

	/// he: '(one) {לשנה הראשונה} (other) {ל-$n השנים הראשונות}'
	String introYears({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n,
		one: 'לשנה הראשונה',
		other: 'ל-${n} השנים הראשונות',
	);

	/// he: '$price $span, ולאחר מכן $then. המחיר מתעדכן אוטומטית.'
	String introPaidTerms({required Object price, required Object span, required Object then}) => '${price} ${span}, ולאחר מכן ${then}. המחיר מתעדכן אוטומטית.';

	/// he: 'חינם $span, ולאחר מכן $then. החיוב מתחיל אוטומטית.'
	String introFreeTerms({required Object span, required Object then}) => 'חינם ${span}, ולאחר מכן ${then}. החיוב מתחיל אוטומטית.';

	/// he: 'יש לי קוד קופון'
	String get redeem => 'יש לי קוד קופון';

	/// he: 'קוד קופון'
	String get redeemTitle => 'קוד קופון';

	/// he: 'הקלידו את הקוד שקיבלתם'
	String get redeemHint => 'הקלידו את הקוד שקיבלתם';

	/// he: 'מימוש בחנות'
	String get redeemConfirm => 'מימוש בחנות';

	/// he: 'לשבוע'
	String get perWeekly => 'לשבוע';

	/// he: 'לחודש'
	String get perMonthly => 'לחודש';

	/// he: 'לחודשיים'
	String get perTwoMonth => 'לחודשיים';

	/// he: 'ל-3 חודשים'
	String get perThreeMonth => 'ל-3 חודשים';

	/// he: 'ל-6 חודשים'
	String get perSixMonth => 'ל-6 חודשים';

	/// he: 'לשנה'
	String get perAnnual => 'לשנה';

	/// he: 'Pro'
	String get tierPro => 'Pro';

	/// he: 'Pro Duo'
	String get tierDuo => 'Pro Duo';

	/// he: 'Pro Family'
	String get tierFamily => 'Pro Family';

	/// he: 'חשבון אחד'
	String get tierProHint => 'חשבון אחד';

	/// he: '2 חשבונות, הכל משתקף'
	String get tierDuoHint => '2 חשבונות, הכל משתקף';

	/// he: 'עד 6 חשבונות, הכל משתקף'
	String get tierFamilyHint => 'עד 6 חשבונות, הכל משתקף';

	/// he: 'חשבון משותף ל-$n אנשים: מתכונים, תפריטים ורשימות מסונכרנים'
	String benefitHousehold({required Object n}) => 'חשבון משותף ל-${n} אנשים: מתכונים, תפריטים ורשימות מסונכרנים';
}

// Path: walkthrough
class Translations$walkthrough$he {
	Translations$walkthrough$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הדרכה'
	String get title => 'הדרכה';

	/// he: 'הפעל הדרכה'
	String get start => 'הפעל הדרכה';

	/// he: 'סיור מודרך בכל הפעולות באפליקציה, צעד אחר צעד'
	String get startHint => 'סיור מודרך בכל הפעולות באפליקציה, צעד אחר צעד';

	/// he: 'התחל הדרכה מלאה'
	String get startFull => 'התחל הדרכה מלאה';

	/// he: 'הצג הנחיה ממוקדת'
	String get focused => 'הצג הנחיה ממוקדת';

	/// he: 'הבא'
	String get next => 'הבא';

	/// he: 'סיום'
	String get finish => 'סיום';

	/// he: 'דלג על שלב'
	String get skipStep => 'דלג על שלב';

	/// he: 'סגור הדרכה'
	String get close => 'סגור הדרכה';

	/// he: 'שלב $current מתוך $total'
	String stepOf({required Object current, required Object total}) => 'שלב ${current} מתוך ${total}';

	/// he: 'לחצו על האזור המודגש, או על ״הבא״'
	String get tapHint => 'לחצו על האזור המודגש, או על ״הבא״';

	/// he: 'מדריך EasyPlate'
	String get bookTitle => 'מדריך EasyPlate';

	/// he: 'כל מה שאפשר לעשות באפליקציה, פרק אחר פרק. הדוגמאות בספר לא נשמרות; בסיור החי עושים את הפעולות באמת, עם שדות שכבר מולאו.'
	String get bookSubtitle => 'כל מה שאפשר לעשות באפליקציה, פרק אחר פרק. הדוגמאות בספר לא נשמרות; בסיור החי עושים את הפעולות באמת, עם שדות שכבר מולאו.';

	/// he: 'תוכן עניינים'
	String get contents => 'תוכן עניינים';

	/// he: 'פרק $number'
	String chapter({required Object number}) => 'פרק ${number}';

	/// he: 'לתוכן העניינים'
	String get backToContents => 'לתוכן העניינים';

	/// he: 'השלבים'
	String get stepsTitle => 'השלבים';

	/// he: 'ברוכים הבאים ל-EasyPlate'
	String get welcomeTitle => 'ברוכים הבאים ל-EasyPlate';

	/// he: 'נעבור יחד על הפעולות העיקריות ונעשה אותן באמת: השדות כבר מולאו בשבילכם. אפשר לדלג על כל שלב, או לסגור ולהפעיל שוב ממסך התמיכה.'
	String get welcomeBody => 'נעבור יחד על הפעולות העיקריות ונעשה אותן באמת: השדות כבר מולאו בשבילכם. אפשר לדלג על כל שלב, או לסגור ולהפעיל שוב ממסך התמיכה.';

	late final Translations$walkthrough$topics$he topics = Translations$walkthrough$topics$he.internal(_root);
	late final Translations$walkthrough$demo$he demo = Translations$walkthrough$demo$he.internal(_root);

	/// he: 'מתכונים לדוגמה'
	String get demoRecipes => 'מתכונים לדוגמה';

	/// he: 'כך נראים מתכונים באפליקציה. לחצו על מתכון כדי לראות את העמוד המלא: זמנים, נושאים, אלרגנים, מצרכים ושלבים.'
	String get demoRecipesHint => 'כך נראים מתכונים באפליקציה. לחצו על מתכון כדי לראות את העמוד המלא: זמנים, נושאים, אלרגנים, מצרכים ושלבים.';

	/// he: 'ספרים לדוגמה'
	String get demoBooks => 'ספרים לדוגמה';

	/// he: 'כך נראה ספר מתכונים. לחצו על ספר כדי לפתוח אותו, לדפדף בין העמודים ולקפוץ מתוכן העניינים.'
	String get demoBooksHint => 'כך נראה ספר מתכונים. לחצו על ספר כדי לפתוח אותו, לדפדף בין העמודים ולקפוץ מתוכן העניינים.';

	/// he: 'דוגמה בלבד, לא נשמר'
	String get demoOnly => 'דוגמה בלבד, לא נשמר';
}

// Path: feedback
class Translations$feedback$he {
	Translations$feedback$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'דיווח והצעות'
	String get title => 'דיווח והצעות';

	/// he: 'מצאתם תקלה? יש רעיון? כתבו לנו כאן, ונקרא כל פנייה.'
	String get subtitle => 'מצאתם תקלה? יש רעיון? כתבו לנו כאן, ונקרא כל פנייה.';

	/// he: 'תקלה (באג)'
	String get bug => 'תקלה (באג)';

	/// he: 'הצעה לשיפור'
	String get suggestion => 'הצעה לשיפור';

	/// he: 'תארו את התקלה: מה עשיתם, מה קרה ומה ציפיתם שיקרה...'
	String get bugHint => 'תארו את התקלה: מה עשיתם, מה קרה ומה ציפיתם שיקרה...';

	/// he: 'ספרו לנו מה הייתם רוצים שיהיה באפליקציה, ואיך זה יעזור לכם...'
	String get suggestionHint => 'ספרו לנו מה הייתם רוצים שיהיה באפליקציה, ואיך זה יעזור לכם...';

	/// he: 'שליחה'
	String get send => 'שליחה';

	/// he: 'תודה! הפנייה נשלחה.'
	String get sent => 'תודה! הפנייה נשלחה.';

	/// he: 'השליחה נכשלה, נסו שוב מאוחר יותר'
	String get failed => 'השליחה נכשלה, נסו שוב מאוחר יותר';

	/// he: 'ניהול פניות'
	String get admin => 'ניהול פניות';

	/// he: 'הכל'
	String get all => 'הכל';

	/// he: 'תקלות'
	String get bugs => 'תקלות';

	/// he: 'הצעות'
	String get suggestions => 'הצעות';

	/// he: 'אין פניות עדיין'
	String get none => 'אין פניות עדיין';

	/// he: 'גרסה $version'
	String version({required Object version}) => 'גרסה ${version}';

	/// he: 'המסך הזה זמין למנהל בלבד'
	String get notAllowed => 'המסך הזה זמין למנהל בלבד';
}

// Path: adminBilling
class Translations$adminBilling$he {
	Translations$adminBilling$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'מנויים'
	String get title => 'מנויים';

	/// he: 'הכל'
	String get all => 'הכל';

	/// he: 'משלמים'
	String get paying => 'משלמים';

	/// he: 'בעיות'
	String get problems => 'בעיות';

	/// he: 'חיפוש לפי שם, מייל, טלפון או uid'
	String get searchHint => 'חיפוש לפי שם, מייל, טלפון או uid';

	/// he: 'אין חשבונות להצגה'
	String get none => 'אין חשבונות להצגה';

	/// he: 'פרימיום'
	String get premium => 'פרימיום';

	/// he: 'חינמי'
	String get free => 'חינמי';

	/// he: 'עד $date'
	String untilDate({required Object date}) => 'עד ${date}';

	/// he: 'הוגדר ידנית'
	String get adminLocked => 'הוגדר ידנית';

	/// he: 'מ-RevenueCat'
	String get viaRevenueCat => 'מ-RevenueCat';

	/// he: 'Sandbox'
	String get sandbox => 'Sandbox';

	/// he: '$type · $date'
	String lastEvent({required Object type, required Object date}) => '${type} · ${date}';

	/// he: 'מוצר: $id'
	String product({required Object id}) => 'מוצר: ${id}';

	/// he: '$count אירועים'
	String eventsCount({required Object count}) => '${count} אירועים';

	/// he: 'תן פרימיום'
	String get grant => 'תן פרימיום';

	/// he: 'בטל פרימיום'
	String get revoke => 'בטל פרימיום';

	/// he: 'החזר ל-RevenueCat'
	String get release => 'החזר ל-RevenueCat';

	/// he: 'הוגדר ידנית: האירוע הבא מ-RevenueCat לא ישנה את החשבון עד השחרור.'
	String get releaseHint => 'הוגדר ידנית: האירוע הבא מ-RevenueCat לא ישנה את החשבון עד השחרור.';

	/// he: 'ניתן פרימיום'
	String get granted => 'ניתן פרימיום';

	/// he: 'הפרימיום בוטל'
	String get revoked => 'הפרימיום בוטל';

	/// he: 'החשבון חזר לשליטת RevenueCat'
	String get released => 'החשבון חזר לשליטת RevenueCat';

	/// he: 'לבטל את הפרימיום של $name?'
	String revokeConfirm({required Object name}) => 'לבטל את הפרימיום של ${name}?';

	/// he: 'שילם, אבל החשבון לא פרימיום'
	String get problemPaidNotPremium => 'שילם, אבל החשבון לא פרימיום';

	/// he: 'הגיעה רכישה בלי ה-entitlement (המוצר לא מחובר ב-RevenueCat)'
	String get problemNoEntitlement => 'הגיעה רכישה בלי ה-entitlement (המוצר לא מחובר ב-RevenueCat)';

	/// he: 'רכישות בלי חשבון'
	String get orphanTitle => 'רכישות בלי חשבון';

	/// he: 'קבלות שהגיעו תחת מזהה אנונימי של RevenueCat, בלי משתמש לפתוח לו'
	String get orphanBody => 'קבלות שהגיעו תחת מזהה אנונימי של RevenueCat, בלי משתמש לפתוח לו';

	/// he: '$premium פרימיום · $problems בעיות · $total חשבונות'
	String summary({required Object premium, required Object problems, required Object total}) => '${premium} פרימיום · ${problems} בעיות · ${total} חשבונות';

	/// he: 'בלי entitlement'
	String get noEntitlementTag => 'בלי entitlement';
}

// Path: adminDashboard
class Translations$adminDashboard$he {
	Translations$adminDashboard$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'לוח בקרה'
	String get title => 'לוח בקרה';

	/// he: 'סקירה'
	String get tabDashboard => 'סקירה';

	/// he: 'מנויים'
	String get tabSubscriptions => 'מנויים';

	/// he: 'פניות'
	String get tabTickets => 'פניות';

	/// he: 'היום'
	String get rangeToday => 'היום';

	/// he: '30 יום'
	String get rangeMonth => '30 יום';

	/// he: 'הכל'
	String get rangeAll => 'הכל';

	/// he: 'עלות AI'
	String get aiCost => 'עלות AI';

	/// he: 'טוקנים × מחירון'
	String get aiCostHint => 'טוקנים × מחירון';

	/// he: 'הכנסות'
	String get revenue => 'הכנסות';

	/// he: 'אין תשלומים בטווח'
	String get revenueNone => 'אין תשלומים בטווח';

	/// he: '$count תשלומי sandbox לא נספרו'
	String sandboxNote({required Object count}) => '${count} תשלומי sandbox לא נספרו';

	/// he: '$count תשלומים'
	String paymentsCount({required Object count}) => '${count} תשלומים';

	/// he: 'קריאות AI'
	String get aiCalls => 'קריאות AI';

	/// he: '$count מהמטמון (חינם)'
	String cacheSaved({required Object count}) => '${count} מהמטמון (חינם)';

	/// he: '$count שגיאות'
	String errorsCount({required Object count}) => '${count} שגיאות';

	/// he: 'טוקנים'
	String get tokens => 'טוקנים';

	/// he: 'קלט $input · פלט $output'
	String tokensHint({required Object input, required Object output}) => 'קלט ${input} · פלט ${output}';

	/// he: 'משתמשים סה"כ'
	String get usersTotal => 'משתמשים סה"כ';

	/// he: '$count חדשים בטווח'
	String newUsers({required Object count}) => '${count} חדשים בטווח';

	/// he: '$count חסומים'
	String disabledCount({required Object count}) => '${count} חסומים';

	/// he: 'משלמים'
	String get premiumUsers => 'משלמים';

	/// he: '$count חינמיים'
	String freeCount({required Object count}) => '${count} חינמיים';

	/// he: 'חינמיים'
	String get freeUsers => 'חינמיים';

	/// he: 'משתמשי AI פעילים'
	String get activeUsers => 'משתמשי AI פעילים';

	/// he: 'עלות למשתמש פעיל'
	String get costPerUser => 'עלות למשתמש פעיל';

	/// he: 'פניות'
	String get tickets => 'פניות';

	/// he: '$count חדשות'
	String unreadCount({required Object count}) => '${count} חדשות';

	/// he: 'עלות AI לפי יום'
	String get chartCost => 'עלות AI לפי יום';

	/// he: 'קריאות AI לפי יום'
	String get chartCalls => 'קריאות AI לפי יום';

	/// he: 'הרשמות לפי יום'
	String get chartSignups => 'הרשמות לפי יום';

	/// he: 'משתמשים לפי פלטפורמה'
	String get chartPlatform => 'משתמשים לפי פלטפורמה';

	/// he: 'חינמי מול משלם'
	String get chartPlan => 'חינמי מול משלם';

	/// he: 'קריאות לפי פיצ'ר'
	String get chartKinds => 'קריאות לפי פיצ\'ר';

	/// he: 'עלות לפי מודל'
	String get chartModels => 'עלות לפי מודל';

	/// he: 'גרסאות אפליקציה'
	String get chartVersions => 'גרסאות אפליקציה';

	/// he: 'iOS'
	String get platformIos => 'iOS';

	/// he: 'Android'
	String get platformAndroid => 'Android';

	/// he: 'לא ידוע'
	String get platformUnknown => 'לא ידוע';

	/// he: 'אין שימוש ב-AI בטווח הזה'
	String get noAiUsage => 'אין שימוש ב-AI בטווח הזה';

	/// he: 'לא במחירון'
	String get unknownModel => 'לא במחירון';

	/// he: 'עלות לפי משתמש'
	String get usersCost => 'עלות לפי משתמש';

	/// he: '$count משתמשים'
	String usersCount({required Object count}) => '${count} משתמשים';

	/// he: 'חיפוש לפי שם, מייל או uid'
	String get searchUser => 'חיפוש לפי שם, מייל או uid';

	/// he: 'הצגת כל $count המשתמשים'
	String showAll({required Object count}) => 'הצגת כל ${count} המשתמשים';

	/// he: '$count קריאות'
	String callsCount({required Object count}) => '${count} קריאות';

	/// he: 'תוכן וקהילה'
	String get content => 'תוכן וקהילה';

	/// he: 'מתכונים משותפים'
	String get sharedRecipes => 'מתכונים משותפים';

	/// he: 'שרשורי פורום'
	String get forumPosts => 'שרשורי פורום';

	/// he: 'מכשירים עם התראות'
	String get withPush => 'מכשירים עם התראות';

	/// he: 'קישורים במטמון'
	String get cacheEntries => 'קישורים במטמון';

	/// he: 'פגיעות מטמון (קריאות שנחסכו)'
	String get cacheHits => 'פגיעות מטמון (קריאות שנחסכו)';

	/// he: 'הגדרות מרחוק'
	String get config => 'הגדרות מרחוק';

	/// he: 'סביבה'
	String get environment => 'סביבה';

	/// he: 'Production'
	String get prod => 'Production';

	/// he: 'Dev'
	String get dev => 'Dev';

	/// he: 'מודעות'
	String get adsEnabled => 'מודעות';

	/// he: 'פתיחה כשאין מודעה'
	String get adsFailOpen => 'פתיחה כשאין מודעה';

	/// he: 'פעיל'
	String get on => 'פעיל';

	/// he: 'כבוי'
	String get off => 'כבוי';

	/// he: 'מרווח מודעות בפיד'
	String get feedInterval => 'מרווח מודעות בפיד';

	/// he: 'צפיות חינם ביום'
	String get quotaSharedFree => 'צפיות חינם ביום';

	/// he: 'צפיות בווידאו ביום'
	String get quotaSharedRewarded => 'צפיות בווידאו ביום';

	/// he: 'AI בווידאו ביום'
	String get quotaAiRewarded => 'AI בווידאו ביום';

	/// he: 'AI לפרימיום ביום'
	String get quotaAiPremium => 'AI לפרימיום ביום';

	/// he: 'גרסה מינימלית'
	String get minVersion => 'גרסה מינימלית';

	/// he: 'גרסה אחרונה'
	String get latestVersion => 'גרסה אחרונה';

	/// he: 'הבנייה הזו'
	String get thisBuild => 'הבנייה הזו';

	/// he: 'מחירון טוקנים'
	String get pricing => 'מחירון טוקנים';

	/// he: 'דולר למיליון טוקנים. מחירי ברירת המחדל הם הערכה — כדאי לעדכן לפי המחירון של Google.'
	String get pricingHint => 'דולר למיליון טוקנים. מחירי ברירת המחדל הם הערכה — כדאי לעדכן לפי המחירון של Google.';

	/// he: 'עריכת מחירון'
	String get editPricing => 'עריכת מחירון';

	/// he: 'קלט'
	String get priceInput => 'קלט';

	/// he: 'פלט'
	String get priceOutput => 'פלט';

	/// he: 'קלט מהמטמון'
	String get priceCached => 'קלט מהמטמון';

	/// he: 'שער דולר/שקל'
	String get usdToIls => 'שער דולר/שקל';

	/// he: 'המחירון נשמר'
	String get pricingSaved => 'המחירון נשמר';

	/// he: 'עודכן $date'
	String loadedAt({required Object date}) => 'עודכן ${date}';

	/// he: 'טקסט'
	String get kindText => 'טקסט';

	/// he: 'קישור'
	String get kindUrl => 'קישור';

	/// he: 'רשת חברתית'
	String get kindSocial => 'רשת חברתית';

	/// he: 'וידאו (שרת)'
	String get kindSocialVideo => 'וידאו (שרת)';

	/// he: 'וידאו'
	String get kindVideo => 'וידאו';

	/// he: 'חיפוש'
	String get kindSearch => 'חיפוש';

	/// he: 'תמונה'
	String get kindImage => 'תמונה';

	/// he: 'קבלה'
	String get kindReceipt => 'קבלה';

	/// he: 'תזונה'
	String get kindNutrition => 'תזונה';

	/// he: 'ליטוש'
	String get kindRefine => 'ליטוש';

	/// he: 'יצירה'
	String get kindGenerate => 'יצירה';

	/// he: 'כל הזמן'
	String get allTime => 'כל הזמן';

	/// he: 'קריאות אחרונות'
	String get recentCalls => 'קריאות אחרונות';

	/// he: 'אין קריאות'
	String get noCalls => 'אין קריאות';

	/// he: 'מטמון'
	String get cacheHit => 'מטמון';

	/// he: 'תקין'
	String get statusOk => 'תקין';

	/// he: 'כותרת (לא חובה)'
	String get pushTitle => 'כותרת (לא חובה)';

	/// he: 'תוכן ההודעה'
	String get pushBody => 'תוכן ההודעה';

	/// he: 'שליחה'
	String get send => 'שליחה';

	/// he: 'חסומים'
	String get blocked => 'חסומים';

	/// he: 'חסימת חשבון'
	String get disable => 'חסימת חשבון';

	/// he: 'ביטול חסימה'
	String get enable => 'ביטול חסימה';

	/// he: 'מה המשתמש יראה כשינסה להתחבר'
	String get blockMessageHint => 'מה המשתמש יראה כשינסה להתחבר';

	/// he: 'החשבון נחסם'
	String get disabledDone => 'החשבון נחסם';

	/// he: 'החסימה הוסרה'
	String get enabledDone => 'החסימה הוסרה';

	/// he: 'מחיקת חשבון'
	String get deleteAccount => 'מחיקת חשבון';

	/// he: 'למחוק את $name לצמיתות? המשתמש, המתכונים, הספרים והתפריטים שלו יימחקו ואי אפשר לשחזר.'
	String deleteAccountConfirm({required Object name}) => 'למחוק את ${name} לצמיתות? המשתמש, המתכונים, הספרים והתפריטים שלו יימחקו ואי אפשר לשחזר.';

	/// he: 'החשבון נמחק'
	String get deleted => 'החשבון נמחק';

	/// he: 'שליחת התראה'
	String get sendPush => 'שליחת התראה';

	/// he: 'למכשיר הזה אין טוקן דחיפה — ההודעה תופיע רק במסך ההתראות'
	String get noPush => 'למכשיר הזה אין טוקן דחיפה — ההודעה תופיע רק במסך ההתראות';

	/// he: 'ההתראה נשלחה'
	String get pushSent => 'ההתראה נשלחה';

	/// he: 'התראה לכל המשתמשים'
	String get sendPushAll => 'התראה לכל המשתמשים';

	/// he: 'לשלוח את ההודעה לכל $count המשתמשים?'
	String broadcastConfirm({required Object count}) => 'לשלוח את ההודעה לכל ${count} המשתמשים?';

	/// he: 'נכתב ל-$items תיבות · $sent דחיפות הצליחו · $failed נכשלו'
	String broadcastDone({required Object items, required Object sent, required Object failed}) => 'נכתב ל-${items} תיבות · ${sent} דחיפות הצליחו · ${failed} נכשלו';

	/// he: '$platform · v$version'
	String platformTag({required Object platform, required Object version}) => '${platform} · v${version}';

	/// he: 'נראה לאחרונה $date'
	String lastSeen({required Object date}) => 'נראה לאחרונה ${date}';

	/// he: 'סיבת החסימה: $message'
	String disabledSince({required Object message}) => 'סיבת החסימה: ${message}';

	/// he: 'חדשות'
	String get unread => 'חדשות';

	/// he: 'קראתי הכל'
	String get markAllRead => 'קראתי הכל';

	/// he: 'כל הפניות סומנו כנקראו'
	String get allRead => 'כל הפניות סומנו כנקראו';

	/// he: 'אין פניות חדשות'
	String get noUnread => 'אין פניות חדשות';

	/// he: 'מחיקת פנייה'
	String get deleteTicket => 'מחיקת פנייה';

	/// he: 'למחוק את הפנייה של $name?'
	String deleteTicketConfirm({required Object name}) => 'למחוק את הפנייה של ${name}?';

	/// he: 'הפנייה נמחקה'
	String get ticketDeleted => 'הפנייה נמחקה';

	/// he: 'תגובה'
	String get reply => 'תגובה';

	/// he: 'התשובה תגיע למשתמש במסך ההתראות (וכדחיפה לטלפון)'
	String get replyHint => 'התשובה תגיע למשתמש במסך ההתראות (וכדחיפה לטלפון)';

	/// he: 'התשובה נשלחה'
	String get replySent => 'התשובה נשלחה';

	/// he: 'התשובה שלך · $date'
	String yourReply({required Object date}) => 'התשובה שלך · ${date}';

	/// he: 'סימון כנקרא'
	String get markRead => 'סימון כנקרא';

	/// he: 'סימון כלא נקרא'
	String get markUnread => 'סימון כלא נקרא';

	/// he: 'סנכרון מחירים מ-Google'
	String get pricingSync => 'סנכרון מחירים מ-Google';

	/// he: '$count מודלים עודכנו מהמחירון של Google Cloud Billing'
	String pricingSynced({required Object count}) => '${count} מודלים עודכנו מהמחירון של Google Cloud Billing';

	/// he: 'הסנכרון נכשל: $reason'
	String pricingSyncFailed({required Object reason}) => 'הסנכרון נכשל: ${reason}';

	/// he: 'מקור: Google Cloud Billing (מחירי מחירון אמיתיים) · $date'
	String pricingSourceCatalog({required Object date}) => 'מקור: Google Cloud Billing (מחירי מחירון אמיתיים) · ${date}';

	/// he: 'מקור: הוזן ידנית · $date'
	String pricingSourceManual({required Object date}) => 'מקור: הוזן ידנית · ${date}';

	/// he: 'הערכה בלבד — לחצו על סנכרון כדי למשוך את המחירים האמיתיים מ-Google'
	String get pricingSourceDefaults => 'הערכה בלבד — לחצו על סנכרון כדי למשוך את המחירים האמיתיים מ-Google';

	/// he: 'חיפוש Google בהארקה (דולר ל-1,000 שאילתות)'
	String get searchPrice => 'חיפוש Google בהארקה (דולר ל-1,000 שאילתות)';

	/// he: '$rate · מתעדכן אוטומטית פעם בשבוע · $date'
	String rateLine({required Object rate, required Object date}) => '${rate} · מתעדכן אוטומטית פעם בשבוע · ${date}';

	/// he: '$count חיפושים'
	String searchesCount({required Object count}) => '${count} חיפושים';

	/// he: 'בחירה'
	String get rangeCustom => 'בחירה';

	/// he: '$from – $to · לחיצה לשינוי'
	String customRange({required Object from, required Object to}) => '${from} – ${to} · לחיצה לשינוי';

	/// he: 'פלט תמונה'
	String get priceImageOutput => 'פלט תמונה';

	/// he: 'הנתונים נאספים מ-$date. חיובים קודמים בגוגל אינם רשומים כאן.'
	String dataSince({required Object date}) => 'הנתונים נאספים מ-${date}. חיובים קודמים בגוגל אינם רשומים כאן.';

	/// he: 'פרימיום ל-$name — לכמה זמן?'
	String grantTitle({required Object name}) => 'פרימיום ל-${name} — לכמה זמן?';

	/// he: 'לתמיד (עד שאבטל)'
	String get grantForever => 'לתמיד (עד שאבטל)';

	/// he: 'שבוע'
	String get grantWeek => 'שבוע';

	/// he: 'חודש'
	String get grantMonth => 'חודש';

	/// he: 'שנה'
	String get grantYear => 'שנה';

	/// he: 'טווח תאריכים מדויק'
	String get grantRange => 'טווח תאריכים מדויק';

	/// he: 'ניתן פרימיום עד $date'
	String grantedUntil({required Object date}) => 'ניתן פרימיום עד ${date}';

	/// he: 'מתחיל ב-$date'
	String grantStarts({required Object date}) => 'מתחיל ב-${date}';

	/// he: 'תצורה'
	String get tabConfig => 'תצורה';

	/// he: 'ניתוק מהמכשיר המחובר'
	String get releaseSession => 'ניתוק מהמכשיר המחובר';

	/// he: 'המכשיר נותק; המשתמש יתבקש להתחבר מחדש'
	String get releaseSessionDone => 'המכשיר נותק; המשתמש יתבקש להתחבר מחדש';
}

// Path: assistant
class Translations$assistant$he {
	Translations$assistant$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'שפי'
	String get title => 'שפי';

	/// he: 'הסו-שף שלך: שאלות, תכנון, קניות ובישול'
	String get subtitle => 'הסו-שף שלך: שאלות, תכנון, קניות ובישול';

	/// he: 'שאלו או אמרו לי מה לעשות…'
	String get placeholder => 'שאלו או אמרו לי מה לעשות…';

	/// he: 'שליחה'
	String get send => 'שליחה';

	/// he: 'חושב…'
	String get thinking => 'חושב…';

	/// he: 'מבצע: $tool'
	String working({required Object tool}) => 'מבצע: ${tool}';

	/// he: 'היי $name! אני יכול להוסיף לרשימת הקניות, לתכנן את השבוע, לייבא מתכונים מקישורים, להתחיל מצב בישול ועוד. מה עושים?'
	String welcome({required Object name}) => 'היי ${name}! אני יכול להוסיף לרשימת הקניות, לתכנן את השבוע, לייבא מתכונים מקישורים, להתחיל מצב בישול ועוד. מה עושים?';

	/// he: 'משהו השתבש. נסו שוב.'
	String get error => 'משהו השתבש. נסו שוב.';

	/// he: 'מכסת ה-AI להיום נגמרה. היא נפתחת מחר.'
	String get quotaReached => 'מכסת ה-AI להיום נגמרה. היא נפתחת מחר.';

	/// he: 'שפי הוא חלק מ-EasyPlate Premium'
	String get premiumOnly => 'שפי הוא חלק מ-EasyPlate Premium';

	/// he: 'לפרימיום'
	String get unlock => 'לפרימיום';

	/// he: 'שיחה חדשה'
	String get clear => 'שיחה חדשה';

	/// he: 'פתיחה'
	String get openResult => 'פתיחה';

	/// he: 'בוצע'
	String get done => 'בוצע';

	/// he: 'בוטל'
	String get undone => 'בוטל';

	/// he: 'למחוק?'
	String get confirmTitle => 'למחוק?';

	/// he: '$what יימחק.'
	String confirmBody({required Object what}) => '${what} יימחק.';

	/// he: 'לא מצאתי את "$name".'
	String notFound({required Object name}) => 'לא מצאתי את "${name}".';

	/// he: 'רשימת קניות'
	String get listTitle => 'רשימת קניות';

	/// he: 'נוספו $count פריטים'
	String addedItems({required Object count}) => 'נוספו ${count} פריטים';

	/// he: 'תוכנן ל$day · $slot'
	String plannedMeal({required Object day, required Object slot}) => 'תוכנן ל${day} · ${slot}';

	/// he: 'המתכון נשמר'
	String get recipeSaved => 'המתכון נשמר';

	/// he: 'מצב בישול הופעל'
	String get cookStarted => 'מצב בישול הופעל';

	/// he: 'טיימר הוגדר לשלב $n'
	String timerSet({required Object n}) => 'טיימר הוגדר לשלב ${n}';

	/// he: 'ההעדפה נשמרה'
	String get prefSaved => 'ההעדפה נשמרה';

	/// he: 'זה דורש EasyPlate Premium.'
	String get needsPremium => 'זה דורש EasyPlate Premium.';

	/// he: '$count תוצאות'
	String results({required Object count}) => '${count} תוצאות';

	late final Translations$assistant$suggest$he suggest = Translations$assistant$suggest$he.internal(_root);

	/// he: 'לאיזו רשימה?'
	String get whichList => 'לאיזו רשימה?';

	/// he: 'הרשימה נוצרה'
	String get listCreated => 'הרשימה נוצרה';

	/// he: 'אני כאן בשביל בישול, מתכונים, תכנון ארוחות וקניות. שאלו אותי כל דבר שקשור למטבח ואני על זה!'
	String get offTopic => 'אני כאן בשביל בישול, מתכונים, תכנון ארוחות וקניות. שאלו אותי כל דבר שקשור למטבח ואני על זה!';

	/// he: 'היי! אני יכול להוסיף לרשימת הקניות, לתכנן את השבוע, לייבא מתכונים מקישורים, להתחיל מצב בישול ועוד. מה עושים?'
	String get welcomeAnon => 'היי! אני יכול להוסיף לרשימת הקניות, לתכנן את השבוע, לייבא מתכונים מקישורים, להתחיל מצב בישול ועוד. מה עושים?';

	/// he: 'מה תרצו לדעת לגבי "$name"?'
	String scopedWelcome({required Object name}) => 'מה תרצו לדעת לגבי "${name}"?';

	/// he: 'כאן אני עוזר רק לגבי "$name". לשאלות אחרות פתחו את שפי מהתפריט.'
	String scopedOffTopic({required Object name}) => 'כאן אני עוזר רק לגבי "${name}". לשאלות אחרות פתחו את שפי מהתפריט.';

	/// he: 'שאלו את שפי על המתכון'
	String get askAboutRecipe => 'שאלו את שפי על המתכון';

	/// he: 'שאלו את שפי על התפריט'
	String get askAboutPlan => 'שאלו את שפי על התפריט';

	/// he: 'שאלו את שפי על הרשימה'
	String get askAboutList => 'שאלו את שפי על הרשימה';

	/// he: 'דברו אל שפי'
	String get listen => 'דברו אל שפי';

	/// he: 'עצירת ההאזנה'
	String get stopListening => 'עצירת ההאזנה';

	/// he: 'הקראת התשובות'
	String get speakReplies => 'הקראת התשובות';

	/// he: 'אי אפשר להשתמש במיקרופון. בדקו את הרשאת המיקרופון וזיהוי הדיבור בהגדרות המכשיר.'
	String get micUnavailable => 'אי אפשר להשתמש במיקרופון. בדקו את הרשאת המיקרופון וזיהוי הדיבור בהגדרות המכשיר.';

	late final Translations$assistant$scopedPrompts$he scopedPrompts = Translations$assistant$scopedPrompts$he.internal(_root);

	/// he: 'מקשיב…'
	String get listening => 'מקשיב…';

	/// he: 'עצירה'
	String get stop => 'עצירה';

	/// he: 'בוטל.'
	String get cancelled => 'בוטל.';
}

// Path: shareCode
class Translations$shareCode$he {
	Translations$shareCode$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'קוד וקישור'
	String get title => 'קוד וקישור';

	/// he: 'איש קשר'
	String get tabContact => 'איש קשר';

	/// he: 'קוד או קישור'
	String get tabCode => 'קוד או קישור';

	/// he: 'כל מי שיש לו את הקוד יכול להצטרף כ$role. הקוד תקף 30 יום.'
	String explain({required Object role}) => 'כל מי שיש לו את הקוד יכול להצטרף כ${role}. הקוד תקף 30 יום.';

	/// he: 'ליצור קוד'
	String get create => 'ליצור קוד';

	/// he: 'קוד'
	String get code => 'קוד';

	/// he: 'קישור'
	String get link => 'קישור';

	/// he: 'העתקה'
	String get copy => 'העתקה';

	/// he: 'הועתק'
	String get copied => 'הועתק';

	/// he: 'שיתוף'
	String get share => 'שיתוף';

	/// he: 'להציג QR'
	String get showQr => 'להציג QR';

	/// he: 'לסרוק QR'
	String get scanQr => 'לסרוק QR';

	/// he: 'להזין קוד'
	String get enterCode => 'להזין קוד';

	/// he: 'הצטרפות'
	String get join => 'הצטרפות';

	/// he: 'הצטרפות עם קוד'
	String get joinTitle => 'הצטרפות עם קוד';

	/// he: 'הדביקו את הקוד שקיבלתם, או סרקו את ה-QR שלו.'
	String get joinHint => 'הדביקו את הקוד שקיבלתם, או סרקו את ה-QR שלו.';

	/// he: 'XXXXXXXX'
	String get joinPlaceholder => 'XXXXXXXX';

	/// he: 'הצטרפתם: $title'
	String joined({required Object title}) => 'הצטרפתם: ${title}';

	/// he: 'זה כבר אצלכם.'
	String get alreadyMember => 'זה כבר אצלכם.';

	/// he: 'הקוד לא תקין.'
	String get invalid => 'הקוד לא תקין.';

	/// he: 'תוקף הקוד פג.'
	String get expired => 'תוקף הקוד פג.';

	/// he: 'הקוד בוטל.'
	String get revoked => 'הקוד בוטל.';

	/// he: 'הקוד נוצל עד תום.'
	String get usedUp => 'הקוד נוצל עד תום.';

	/// he: 'זה הקוד שלכם.'
	String get self => 'זה הקוד שלכם.';

	/// he: 'מה שהקוד שיתף כבר לא קיים.'
	String get gone => 'מה שהקוד שיתף כבר לא קיים.';

	/// he: 'ההצטרפות נכשלה. נסו שוב.'
	String get failed => 'ההצטרפות נכשלה. נסו שוב.';

	/// he: '$name שיתף איתך את "$title" ב-EasyPlate. קוד: $code $link'
	String messageText({required Object name, required Object title, required Object code, required Object link}) => '${name} שיתף איתך את "${title}" ב-EasyPlate. קוד: ${code}\n${link}';

	/// he: 'לבטל קוד'
	String get revoke => 'לבטל קוד';

	/// he: 'חשבון חינמי יכול לשתף עד $count מתכונים בשבוע.'
	String limitRecipes({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} מתכונים בשבוע.';

	/// he: 'חשבון חינמי יכול לשתף עד $count ספרים.'
	String limitBooks({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} ספרים.';

	/// he: 'חשבון חינמי יכול לשתף עד $count תפריטים.'
	String limitPlans({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} תפריטים.';

	/// he: 'לפרימיום'
	String get upgrade => 'לפרימיום';

	/// he: 'כוונו את המצלמה ל-QR של השיתוף'
	String get scanHint => 'כוונו את המצלמה ל-QR של השיתוף';

	/// he: '$name הזמין אתכם לחשבון המשותף שלו ב-EasyPlate. קוד: $code $link'
	String householdMessage({required Object name, required Object code, required Object link}) => '${name} הזמין אתכם לחשבון המשותף שלו ב-EasyPlate. קוד: ${code}\n${link}';

	/// he: 'חשבון חינמי יכול לשתף עד $count רשימות קניות.'
	String limitLists({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} רשימות קניות.';
}

// Path: household
class Translations$household$he {
	Translations$household$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'חשבון משותף'
	String get title => 'חשבון משותף';

	/// he: 'Pro Duo'
	String get duo => 'Pro Duo';

	/// he: 'Pro Family'
	String get family => 'Pro Family';

	/// he: '$used מתוך $total מקומות בשימוש'
	String seats({required Object used, required Object total}) => '${used} מתוך ${total} מקומות בשימוש';

	/// he: 'פתחו חשבון משותף: מתכונים, ספרים, תפריטים ורשימות משתקפים לכל מי שבו, וכולם מקבלים פרימיום יחד איתכם.'
	String get intro => 'פתחו חשבון משותף: מתכונים, ספרים, תפריטים ורשימות משתקפים לכל מי שבו, וכולם מקבלים פרימיום יחד איתכם.';

	/// he: 'לפתוח חשבון משותף'
	String get create => 'לפתוח חשבון משותף';

	/// he: 'שם, למשל משפחת כהן'
	String get nameHint => 'שם, למשל משפחת כהן';

	/// he: 'חשבון משותף מגיע עם Pro Duo (2 חשבונות) או Pro Family (עד 6 חשבונות).'
	String get notEligible => 'חשבון משותף מגיע עם Pro Duo (2 חשבונות) או Pro Family (עד 6 חשבונות).';

	/// he: 'לתוכניות'
	String get seePlans => 'לתוכניות';

	/// he: 'חברים'
	String get members => 'חברים';

	/// he: 'בעלים'
	String get owner => 'בעלים';

	/// he: 'אתם'
	String get you => 'אתם';

	/// he: 'להזמין חבר'
	String get invite => 'להזמין חבר';

	/// he: 'כל מי שיש לו את הקוד מצטרף לחשבון המשותף. נותרו $free מקומות.'
	String inviteExplain({required Object free}) => 'כל מי שיש לו את הקוד מצטרף לחשבון המשותף. נותרו ${free} מקומות.';

	/// he: 'כל המקומות תפוסים.'
	String get noSeats => 'כל המקומות תפוסים.';

	/// he: 'להסיר'
	String get remove => 'להסיר';

	/// he: 'להסיר את $name מהחשבון המשותף? הגישה והפרימיום שלהם יפסקו.'
	String removeConfirm({required Object name}) => 'להסיר את ${name} מהחשבון המשותף? הגישה והפרימיום שלהם יפסקו.';

	/// he: 'לעזוב את החשבון המשותף'
	String get leave => 'לעזוב את החשבון המשותף';

	/// he: 'לעזוב? מה שנשמר כאן נשאר בחשבון המשותף; החשבון שלכם חוזר למה שהיה לכם קודם.'
	String get leaveConfirm => 'לעזוב? מה שנשמר כאן נשאר בחשבון המשותף; החשבון שלכם חוזר למה שהיה לכם קודם.';

	/// he: 'לסגור את החשבון המשותף'
	String get dissolve => 'לסגור את החשבון המשותף';

	/// he: 'לסגור את החשבון המשותף? החברים יאבדו גישה ופרימיום. המידע שלכם חוזר לחשבון האישי.'
	String get dissolveConfirm => 'לסגור את החשבון המשותף? החברים יאבדו גישה ופרימיום. המידע שלכם חוזר לחשבון האישי.';

	/// he: 'ברוכים הבאים לחשבון המשותף!'
	String get joined => 'ברוכים הבאים לחשבון המשותף!';

	/// he: 'הפרימיום מגיע מהמנוי של $name.'
	String inheritedNote({required Object name}) => 'הפרימיום מגיע מהמנוי של ${name}.';

	/// he: 'זה לא הצליח. נסו שוב.'
	String get failed => 'זה לא הצליח. נסו שוב.';

	/// he: 'החשבון המשותף מלא.'
	String get full => 'החשבון המשותף מלא.';

	/// he: 'אתם כבר בחשבון משותף.'
	String get inHousehold => 'אתם כבר בחשבון משותף.';

	/// he: 'התוכנית של הבעלים כבר לא כוללת חשבון משותף.'
	String get notEligibleCode => 'התוכנית של הבעלים כבר לא כוללת חשבון משותף.';

	/// he: 'המנוי של הבעלים הסתיים; הפרימיום של החברים מושהה.'
	String get lapsed => 'המנוי של הבעלים הסתיים; הפרימיום של החברים מושהה.';
}

// Path: feature
class Translations$feature$he {
	Translations$feature$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'בקרוב'
	String get comingSoon => 'בקרוב';

	/// he: 'הפיצ׳ר הזה יגיע בקרוב'
	String get comingSoonMessage => 'הפיצ׳ר הזה יגיע בקרוב';

	/// he: 'הפיצ׳ר הזה לא זמין כרגע'
	String get unavailable => 'הפיצ׳ר הזה לא זמין כרגע';

	/// he: 'לפרימיום'
	String get premiumOnly => 'לפרימיום';

	/// he: 'הפיצ׳ר הזה זמין למנויי פרימיום'
	String get premiumOnlyMessage => 'הפיצ׳ר הזה זמין למנויי פרימיום';

	/// he: 'לפרימיום בלבד'
	String get premiumOnlyTitle => 'לפרימיום בלבד';

	/// he: 'האפשרות "$name" פתוחה רק למשתמשי פרימיום'
	String premiumOnlyFor({required Object name}) => 'האפשרות "${name}" פתוחה רק למשתמשי פרימיום';

	/// he: 'עבור לפרימיום'
	String get goPremium => 'עבור לפרימיום';
}

// Path: featureName
class Translations$featureName$he {
	Translations$featureName$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ספרי מתכונים'
	String get books => 'ספרי מתכונים';

	/// he: 'תפריטים'
	String get mealPlans => 'תפריטים';

	/// he: 'רשימות קניות'
	String get groceryLists => 'רשימות קניות';

	/// he: 'קהילה'
	String get community => 'קהילה';

	/// he: 'הוספת מתכון מטקסט'
	String get ingestText => 'הוספת מתכון מטקסט';

	/// he: 'חיפוש מתכון ברשת'
	String get ingestWebSearch => 'חיפוש מתכון ברשת';

	/// he: 'הוספת מתכון מקישור'
	String get ingestLink => 'הוספת מתכון מקישור';

	/// he: 'הוספת מתכון מסרטון'
	String get ingestSocialVideo => 'הוספת מתכון מסרטון';

	/// he: 'בקשת מתכון מה-AI'
	String get ingestAiRequest => 'בקשת מתכון מה-AI';

	/// he: 'הוספת מתכון מקובץ'
	String get ingestFile => 'הוספת מתכון מקובץ';

	/// he: 'שיתוף מאפליקציה אחרת'
	String get shareIn => 'שיתוף מאפליקציה אחרת';

	/// he: 'שמירה עם AI'
	String get saveWithAi => 'שמירה עם AI';

	/// he: 'מצב בישול'
	String get cookMode => 'מצב בישול';

	/// he: 'טיימרים בבישול'
	String get cookTimers => 'טיימרים בבישול';

	/// he: 'ערכים תזונתיים'
	String get nutrition => 'ערכים תזונתיים';

	/// he: 'יצירת תמונה ב-AI'
	String get recipeImageAi => 'יצירת תמונה ב-AI';

	/// he: 'חיפוש תמונה בגוגל'
	String get recipeImageSearch => 'חיפוש תמונה בגוגל';

	/// he: 'רשימת קניות ממתכון'
	String get groceryFromRecipe => 'רשימת קניות ממתכון';

	/// he: 'מתכונים משותפים'
	String get sharedRecipes => 'מתכונים משותפים';

	/// he: 'פורום'
	String get forum => 'פורום';

	/// he: 'לייקים'
	String get likes => 'לייקים';

	/// he: 'שיתוף מתכונים'
	String get shareRecipes => 'שיתוף מתכונים';

	/// he: 'שיתוף ספרים'
	String get shareBooks => 'שיתוף ספרים';

	/// he: 'שיתוף תפריטים'
	String get sharePlans => 'שיתוף תפריטים';

	/// he: 'שיתוף רשימות קניות'
	String get shareGroceryLists => 'שיתוף רשימות קניות';

	/// he: 'שיתוף בקוד'
	String get shareCodes => 'שיתוף בקוד';

	/// he: 'משק בית'
	String get households => 'משק בית';

	/// he: 'ספר מחירים'
	String get priceBook => 'ספר מחירים';

	/// he: 'סריקת קבלה'
	String get receiptScan => 'סריקת קבלה';

	/// he: 'עלות משוערת'
	String get groceryCost => 'עלות משוערת';

	/// he: 'תזכורת קניות'
	String get shoppingReminder => 'תזכורת קניות';

	/// he: 'שפי (העוזר החכם)'
	String get assistant => 'שפי (העוזר החכם)';

	/// he: 'התראות'
	String get notifications => 'התראות';

	/// he: 'פרימיום'
	String get premium => 'פרימיום';

	/// he: 'תרגום תוכן'
	String get contentTranslation => 'תרגום תוכן';

	/// he: 'מראה'
	String get theming => 'מראה';

	/// he: 'סיור מודרך'
	String get walkthrough => 'סיור מודרך';

	/// he: 'ספר הדרכה'
	String get tutorialBook => 'ספר הדרכה';

	/// he: 'משוב'
	String get feedback => 'משוב';

	/// he: 'שפי בתוך פריט'
	String get assistantScoped => 'שפי בתוך פריט';

	/// he: 'דיבור עם שפי'
	String get assistantVoice => 'דיבור עם שפי';

	/// he: 'מכשיר אחד לחשבון'
	String get singleSession => 'מכשיר אחד לחשבון';
}

// Path: adminConfig
class Translations$adminConfig$he {
	Translations$adminConfig$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'כל ערך כאן הוא ה-Remote Config של Firebase. שינוי מתפרסם מיד לכל המשתמשים (ערכי ברירת המחדל; תנאים בקונסול נשארים כפי שהם).'
	String get intro => 'כל ערך כאן הוא ה-Remote Config של Firebase. שינוי מתפרסם מיד לכל המשתמשים (ערכי ברירת המחדל; תנאים בקונסול נשארים כפי שהם).';

	/// he: 'לא הצלחנו לטעון את התצורה'
	String get loadFailed => 'לא הצלחנו לטעון את התצורה';

	/// he: 'הפרסום נכשל. בדקו את הערך ונסו שוב'
	String get saveFailed => 'הפרסום נכשל. בדקו את הערך ונסו שוב';

	/// he: '״$name״ פורסם'
	String saved({required Object name}) => '״${name}״ פורסם';

	/// he: '$n הגדרות'
	String count({required Object n}) => '${n} הגדרות';

	/// he: 'חיפוש בכל ההגדרות'
	String get searchAll => 'חיפוש בכל ההגדרות';

	/// he: 'חיפוש ב$section'
	String searchIn({required Object section}) => 'חיפוש ב${section}';

	/// he: 'אין הגדרה שמתאימה ל״$query״'
	String noResults({required Object query}) => 'אין הגדרה שמתאימה ל״${query}״';

	/// he: 'הכל'
	String get filterAll => 'הכל';

	/// he: 'ניקוי החיפוש'
	String get clearSearch => 'ניקוי החיפוש';

	/// he: 'אין פיצ׳רים במצב הזה'
	String get noFlagsInState => 'אין פיצ׳רים במצב הזה';

	late final Translations$adminConfig$groups$he groups = Translations$adminConfig$groups$he.internal(_root);
	late final Translations$adminConfig$flag$he flag = Translations$adminConfig$flag$he.internal(_root);
	late final Translations$adminConfig$labels$he labels = Translations$adminConfig$labels$he.internal(_root);
}

// Path: walkthrough.topics
class Translations$walkthrough$topics$he {
	Translations$walkthrough$topics$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$walkthrough$topics$addRecipe$he addRecipe = Translations$walkthrough$topics$addRecipe$he.internal(_root);
	late final Translations$walkthrough$topics$myRecipes$he myRecipes = Translations$walkthrough$topics$myRecipes$he.internal(_root);
	late final Translations$walkthrough$topics$library$he library = Translations$walkthrough$topics$library$he.internal(_root);
	late final Translations$walkthrough$topics$mealPlan$he mealPlan = Translations$walkthrough$topics$mealPlan$he.internal(_root);
	late final Translations$walkthrough$topics$groceries$he groceries = Translations$walkthrough$topics$groceries$he.internal(_root);
	late final Translations$walkthrough$topics$community$he community = Translations$walkthrough$topics$community$he.internal(_root);
	late final Translations$walkthrough$topics$account$he account = Translations$walkthrough$topics$account$he.internal(_root);
	late final Translations$walkthrough$topics$settings$he settings = Translations$walkthrough$topics$settings$he.internal(_root);
}

// Path: walkthrough.demo
class Translations$walkthrough$demo$he {
	Translations$walkthrough$demo$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הדרכה'
	String get bookTitle => 'הדרכה';

	/// he: 'תפריט הדרכה'
	String get planName => 'תפריט הדרכה';

	/// he: 'ארוחת ערב'
	String get mealName => 'ארוחת ערב';

	/// he: 'עגבניות'
	String get groceryItem => 'עגבניות';

	/// he: 'שקשוקה ירושלמית מצרכים: 400 גרם עגבניות מרוסקות 4 ביצים בצל אחד 2 כפות שמן זית כפית פפריקה מתוקה קורט מלח הכנה: 1. מחממים שמן זית במחבת ומטגנים את הבצל עד להזהבה. 2. מוסיפים את העגבניות והפפריקה ומבשלים 10 דקות על אש נמוכה. 3. שוברים את הביצים לתוך הרוטב, מכסים ומבשלים עד שהחלבון מתקשה.'
	String get recipeText => 'שקשוקה ירושלמית\n\nמצרכים:\n400 גרם עגבניות מרוסקות\n4 ביצים\nבצל אחד\n2 כפות שמן זית\nכפית פפריקה מתוקה\nקורט מלח\n\nהכנה:\n1. מחממים שמן זית במחבת ומטגנים את הבצל עד להזהבה.\n2. מוסיפים את העגבניות והפפריקה ומבשלים 10 דקות על אש נמוכה.\n3. שוברים את הביצים לתוך הרוטב, מכסים ומבשלים עד שהחלבון מתקשה.';
}

// Path: assistant.suggest
class Translations$assistant$suggest$he {
	Translations$assistant$suggest$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	List<String> get templates => [
		'תוסיף {food} לרשימת הקניות',
		'תוסיף {food} ו{food2} לרשימה',
		'תתכנן {dish} ל{meal} ביום {day}',
		'תתכנן משהו מהיר ל{meal} ביום {day}',
		'מה אפשר לבשל מ{food} ו{food2}?',
		'תייבא מתכון מ{site}',
		'תמצא מתכון ל{dish} ברשת',
		'תתחיל לבשל {dish}',
		'תפעיל טיימר של {n} דקות לשלב 2',
		'תכין רשימת קניות מ{dish}',
		'תיצור ספר בשם {book}',
		'אילו מהמתכונים שלי {diet}?',
		'תסמן ש{food} נקנה',
		'תוריד {food} מהרשימה',
		'תיצור תוכנית לשבוע הבא',
		'מה מתוכנן ליום {day}?',
		'תשנה את יום הקניות ל{day}',
		'תציע ארוחת ערב {diet} ליום {day}',
		'כמה זמן מבשלים ביצה קשה?',
		'במה אפשר להחליף {food} במתכון?',
		'איך שומרים {food}?',
		'כמה קלוריות יש ב{dish}?',
		'באיזו טמפרטורה אופים {dish}?',
		'איך הופכים {dish} לטבעוני?',
		'כמה זה {n} כפות בגרמים?',
		'למה ה{dish} שלי יצא יבש?',
		'מה מתאים בצד ל{dish}?',
		'אפשר להקפיא {food}?',
		'איך מסמיכים רוטב?',
		'רעיון ל{meal} {diet} מהיר?',
	];
	List<String> get food => [
		'חלב',
		'ביצים',
		'לחם',
		'עגבניות',
		'בצל',
		'שמן זית',
		'אורז',
		'עוף',
		'לימונים',
		'שום',
		'חמאה',
		'קמח',
		'גבינה',
		'יוגורט',
		'מלפפונים',
		'פסטה',
	];
	List<String> get dish => [
		'שקשוקה',
		'מרק עדשים',
		'פסטה פסטו',
		'קארי עוף',
		'סלמון',
		'מוקפץ',
		'פנקייקים',
		'חומוס',
		'ירקות בתנור',
		'לחם בננות',
	];
	List<String> get day => [
		'ראשון',
		'שני',
		'שלישי',
		'רביעי',
		'חמישי',
		'שישי',
		'שבת',
		'מחר',
	];
	List<String> get meal => [
		'ארוחת בוקר',
		'ארוחת צהריים',
		'ארוחת ערב',
	];
	List<String> get n => [
		'5',
		'8',
		'10',
		'12',
		'15',
		'20',
		'25',
		'30',
	];
	List<String> get site => [
		'טיקטוק',
		'אינסטגרם',
		'יוטיוב',
		'בלוג',
	];
	List<String> get book => [
		'ימי חול',
		'שבת',
		'ילדים',
		'קינוחים',
	];
	List<String> get diet => [
		'צמחוניים',
		'טבעוניים',
		'ללא גלוטן',
		'חלביים',
	];
}

// Path: assistant.scopedPrompts
class Translations$assistant$scopedPrompts$he {
	Translations$assistant$scopedPrompts$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	List<String> get recipe => [
		'מה הערכים התזונתיים למנה?',
		'איך מכינים את זה ל-8 סועדים?',
		'במה אפשר להחליף מצרך שאין לי?',
		'הוסיפו את המתכון לתפריט של מחר',
		'צרו רשימת קניות מהמתכון',
	];
	List<String> get mealPlan => [
		'מה אוכלים היום?',
		'הוסיפו ארוחת ערב ליום שלישי',
		'מה חסר בתפריט השבוע?',
		'צרו רשימת קניות מהתפריט',
		'כמה קלוריות ביום רביעי?',
	];
	List<String> get groceryList => [
		'מה נשאר לקנות?',
		'הוסיפו חלב וביצים',
		'סמנו את העגבניות כנקנו',
		'מחקו את מה שכבר קניתי',
		'כמה זה 2 כוסות קמח בגרמים?',
	];
}

// Path: adminConfig.groups
class Translations$adminConfig$groups$he {
	Translations$adminConfig$groups$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'פיצ׳רים'
	String get features => 'פיצ׳רים';

	/// he: 'פרסומות ומכסות'
	String get adsQuotas => 'פרסומות ומכסות';

	/// he: 'שיתוף בחשבון חינמי'
	String get sharing => 'שיתוף בחשבון חינמי';

	/// he: 'הקול של שפי'
	String get voice => 'הקול של שפי';

	/// he: 'גרסאות וסביבה'
	String get versions => 'גרסאות וסביבה';

	/// he: 'שרת ה-AI (דורש deploy)'
	String get gemini => 'שרת ה-AI (דורש deploy)';

	/// he: 'אחר'
	String get other => 'אחר';
}

// Path: adminConfig.flag
class Translations$adminConfig$flag$he {
	Translations$adminConfig$flag$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'לא מוצג'
	String get hidden => 'לא מוצג';

	/// he: 'בקרוב'
	String get comingSoon => 'בקרוב';

	/// he: 'חינמי'
	String get everyone => 'חינמי';

	/// he: 'פרימיום'
	String get premium => 'פרימיום';
}

// Path: adminConfig.labels
class Translations$adminConfig$labels$he {
	Translations$adminConfig$labels$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'פרסומות פעילות'
	String get ads_enabled => 'פרסומות פעילות';

	/// he: 'פתיחה כשאין סרטון'
	String get ads_fail_open => 'פתיחה כשאין סרטון';

	/// he: 'מרווח מודעות בפיד'
	String get ads_feed_interval => 'מרווח מודעות בפיד';

	/// he: 'מתכונים משותפים חינם ביום'
	String get quota_shared_free => 'מתכונים משותפים חינם ביום';

	/// he: 'מתכונים משותפים אחרי סרטון'
	String get quota_shared_rewarded => 'מתכונים משותפים אחרי סרטון';

	/// he: 'חילוצי AI אחרי סרטון ביום'
	String get quota_ai_rewarded => 'חילוצי AI אחרי סרטון ביום';

	/// he: 'שיתופי מתכון בשבוע'
	String get share_free_recipes_weekly => 'שיתופי מתכון בשבוע';

	/// he: 'ספרים משותפים בו-זמנית'
	String get share_free_books_total => 'ספרים משותפים בו-זמנית';

	/// he: 'תפריטים משותפים בו-זמנית'
	String get share_free_plans_total => 'תפריטים משותפים בו-זמנית';

	/// he: 'רשימות קניות משותפות בו-זמנית'
	String get share_free_lists_total => 'רשימות קניות משותפות בו-זמנית';

	/// he: 'קול ענן (Google)'
	String get tts_cloud_enabled => 'קול ענן (Google)';

	/// he: 'קול בעברית'
	String get tts_voice_he => 'קול בעברית';

	/// he: 'קול באנגלית'
	String get tts_voice_en => 'קול באנגלית';

	/// he: 'קול בערבית'
	String get tts_voice_ar => 'קול בערבית';

	/// he: 'קול בצרפתית'
	String get tts_voice_fr => 'קול בצרפתית';

	/// he: 'קול ברוסית'
	String get tts_voice_ru => 'קול ברוסית';

	/// he: 'גרסת פרודקשן'
	String get isProd => 'גרסת פרודקשן';

	/// he: 'גרסה מינימלית'
	String get minimumVersion => 'גרסה מינימלית';

	/// he: 'גרסה אחרונה'
	String get latestVersion => 'גרסה אחרונה';

	/// he: 'מזהה App Store'
	String get iosAppStoreId => 'מזהה App Store';

	/// he: 'מינימום שרתים'
	String get gemini_minInstances => 'מינימום שרתים';

	/// he: 'מקסימום שרתים'
	String get gemini_maxInstances => 'מקסימום שרתים';

	/// he: 'זמן קצוב לקריאה (שניות)'
	String get gemini_timeoutSeconds => 'זמן קצוב לקריאה (שניות)';

	/// he: 'ימי התחברות למכשיר'
	String get session_days => 'ימי התחברות למכשיר';
}

// Path: walkthrough.topics.addRecipe
class Translations$walkthrough$topics$addRecipe$he {
	Translations$walkthrough$topics$addRecipe$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הוספת מתכון'
	String get title => 'הוספת מתכון';

	/// he: 'מכניסים מתכון מכל מקור, וה-AI מסדר אותו לפורמט אחיד: מצרכים, כמויות, שלבים, תגיות, מנות וערכים תזונתיים.'
	String get summary => 'מכניסים מתכון מכל מקור, וה-AI מסדר אותו לפורמט אחיד: מצרכים, כמויות, שלבים, תגיות, מנות וערכים תזונתיים.';

	/// he: 'לחצו על כפתור הניצוץ ליד הכותרת כדי להוסיף מתכון.'
	String get s1 => 'לחצו על כפתור הניצוץ ליד הכותרת כדי להוסיף מתכון.';

	/// he: 'בוחרים מקור: טקסט מודבק, חיפוש באינטרנט, קישור לאתר, סרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק, בקשה חופשית מ-AI, או כתיבה ידנית.'
	String get s2 => 'בוחרים מקור: טקסט מודבק, חיפוש באינטרנט, קישור לאתר, סרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק, בקשה חופשית מ-AI, או כתיבה ידנית.';

	/// he: 'מילאנו כאן מתכון לדוגמה, כמו שמדביקים אותו. הכפתור שמתחת שולח אותו ל-AI, שמחזיר מתכון מסודר לבדיקה, עריכה ושמירה. הניתוח לוקח עד חצי דקה, אז השאירו אותו לאחרי הסיור.'
	String get s3 => 'מילאנו כאן מתכון לדוגמה, כמו שמדביקים אותו. הכפתור שמתחת שולח אותו ל-AI, שמחזיר מתכון מסודר לבדיקה, עריכה ושמירה. הניתוח לוקח עד חצי דקה, אז השאירו אותו לאחרי הסיור.';
}

// Path: walkthrough.topics.myRecipes
class Translations$walkthrough$topics$myRecipes$he {
	Translations$walkthrough$topics$myRecipes$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'המתכונים שלי ושמורים'
	String get title => 'המתכונים שלי ושמורים';

	/// he: 'המתכונים שכתבתם ואלה ששמרתם מהקהילה, עם חיפוש וסינון לפי נושאים.'
	String get summary => 'המתכונים שכתבתם ואלה ששמרתם מהקהילה, עם חיפוש וסינון לפי נושאים.';

	/// he: 'כאן עוברים בין המתכונים שכתבתם לבין מתכונים ששמרתם מהקהילה.'
	String get s1 => 'כאן עוברים בין המתכונים שכתבתם לבין מתכונים ששמרתם מהקהילה.';

	/// he: 'חיפוש לפי שם, וסינון לפי נושאים: בשרי, חלבי, צמחוני, טבעוני, כשר, ללא גלוטן ואלרגיה. בכל מתכון מסומנים גם האלרגנים שבו.'
	String get s2 => 'חיפוש לפי שם, וסינון לפי נושאים: בשרי, חלבי, צמחוני, טבעוני, כשר, ללא גלוטן ואלרגיה. בכל מתכון מסומנים גם האלרגנים שבו.';
}

// Path: walkthrough.topics.library
class Translations$walkthrough$topics$library$he {
	Translations$walkthrough$topics$library$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'ספרי מתכונים'
	String get title => 'ספרי מתכונים';

	/// he: 'מסדרים מתכונים בספרים עם תוכן עניינים, כריכה ודפדוף, ומשתפים ספר שלם עם חשבון אחר.'
	String get summary => 'מסדרים מתכונים בספרים עם תוכן עניינים, כריכה ודפדוף, ומשתפים ספר שלם עם חשבון אחר.';

	/// he: 'לחצו על ״ספרייה״ כדי לעבור לספרים.'
	String get s1 => 'לחצו על ״ספרייה״ כדי לעבור לספרים.';

	/// he: 'לחצו על הפלוס כדי ליצור ספר חדש.'
	String get s2 => 'לחצו על הפלוס כדי ליצור ספר חדש.';

	/// he: 'שם הספר כבר מולא: ״הדרכה״. אפשר ללחוץ על השדה ולשנות אותו, ואז להמשיך.'
	String get s3 => 'שם הספר כבר מולא: ״הדרכה״. אפשר ללחוץ על השדה ולשנות אותו, ואז להמשיך.';

	/// he: 'לחצו ״שמור״ כדי ליצור את הספר.'
	String get s4 => 'לחצו ״שמור״ כדי ליצור את הספר.';

	/// he: 'בוחרים צבע לשדרה, שמבדיל בין הספרים על המדף, ולוחצים ״שמור״. הספר ייפתח מיד.'
	String get s5 => 'בוחרים צבע לשדרה, שמבדיל בין הספרים על המדף, ולוחצים ״שמור״. הספר ייפתח מיד.';

	/// he: 'זהו הספר שיצרתם. מכאן מוסיפים אליו מתכונים, ובספר מדפדפים בין העמודים וקופצים מתוכן העניינים. לחיצה ארוכה על ספר במדף פותחת שיתוף, כריכה, שינוי שם ומחיקה.'
	String get s6 => 'זהו הספר שיצרתם. מכאן מוסיפים אליו מתכונים, ובספר מדפדפים בין העמודים וקופצים מתוכן העניינים. לחיצה ארוכה על ספר במדף פותחת שיתוף, כריכה, שינוי שם ומחיקה.';
}

// Path: walkthrough.topics.mealPlan
class Translations$walkthrough$topics$mealPlan$he {
	Translations$walkthrough$topics$mealPlan$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'תפריט שבועי ותזונה'
	String get title => 'תפריט שבועי ותזונה';

	/// he: 'תוכנית ארוחות לכל השבוע עם סיכום תזונתי לכל יום, שמזינה את רשימת הקניות.'
	String get summary => 'תוכנית ארוחות לכל השבוע עם סיכום תזונתי לכל יום, שמזינה את רשימת הקניות.';

	/// he: 'לחצו על ״תפריטים״ לתכנון הארוחות.'
	String get s1 => 'לחצו על ״תפריטים״ לתכנון הארוחות.';

	/// he: 'לחצו כאן כדי ליצור תוכנית שבועית.'
	String get s2 => 'לחצו כאן כדי ליצור תוכנית שבועית.';

	/// he: 'שם התוכנית כבר מולא. למטה בוחרים תבנית: חופשית, שלוש ארוחות ביום או שש.'
	String get s3 => 'שם התוכנית כבר מולא. למטה בוחרים תבנית: חופשית, שלוש ארוחות ביום או שש.';

	/// he: 'לחצו ״שמור״ כדי ליצור את התוכנית.'
	String get s4 => 'לחצו ״שמור״ כדי ליצור את התוכנית.';

	/// he: 'לכל יום משבצים מתכונים בארוחות. כרטיס התזונה מסכם קלוריות, חלבון, פחמימות ושומן לפי המנות. לחצו על הגרף כדי לפתוח את הדשבורד השבועי.'
	String get s5 => 'לכל יום משבצים מתכונים בארוחות. כרטיס התזונה מסכם קלוריות, חלבון, פחמימות ושומן לפי המנות. לחצו על הגרף כדי לפתוח את הדשבורד השבועי.';

	/// he: 'הדשבורד: ממוצע יומי, סך שבועי, עמודה לכל יום וחלוקת המאקרו. הערכים מוערכים על ידי ה-AI לכל מתכון, לפי מנה.'
	String get s6 => 'הדשבורד: ממוצע יומי, סך שבועי, עמודה לכל יום וחלוקת המאקרו. הערכים מוערכים על ידי ה-AI לכל מתכון, לפי מנה.';

	/// he: 'כפתור השיתוף שולח את התוכנית לחשבון אחר, כעורך או כצופה. עריכה בצד אחד מגיעה לכולם.'
	String get s7 => 'כפתור השיתוף שולח את התוכנית לחשבון אחר, כעורך או כצופה. עריכה בצד אחד מגיעה לכולם.';
}

// Path: walkthrough.topics.groceries
class Translations$walkthrough$topics$groceries$he {
	Translations$walkthrough$topics$groceries$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'רשימת קניות ומחירים'
	String get title => 'רשימת קניות ומחירים';

	/// he: 'רשימה שנבנית מהתפריט, עם סימון מה כבר נאסף, הערכת עלות מהקבלות שלכם, ושיתוף עם מי שקונה איתכם.'
	String get summary => 'רשימה שנבנית מהתפריט, עם סימון מה כבר נאסף, הערכת עלות מהקבלות שלכם, ושיתוף עם מי שקונה איתכם.';

	/// he: 'לחצו על ״קניות״.'
	String get s1 => 'לחצו על ״קניות״.';

	/// he: 'רענון בונה מחדש את הרשימה מכל המתכונים בתפריט השבועי.'
	String get s2 => 'רענון בונה מחדש את הרשימה מכל המתכונים בתפריט השבועי.';

	/// he: 'לחצו על הפלוס כדי להוסיף פריט ביד.'
	String get s3 => 'לחצו על הפלוס כדי להוסיף פריט ביד.';

	/// he: 'שם הפריט כבר מולא. בוחרים כמות ויחידה, או מתחילים ממוצר שהקבלות שלכם כבר מכירות.'
	String get s4 => 'שם הפריט כבר מולא. בוחרים כמות ויחידה, או מתחילים ממוצר שהקבלות שלכם כבר מכירות.';

	/// he: 'לחצו ״הוסף״ והפריט ייכנס לרשימה.'
	String get s5 => 'לחצו ״הוסף״ והפריט ייכנס לרשימה.';

	/// he: 'לחצו כאן כדי לפתוח את ספר המחירים.'
	String get s6 => 'לחצו כאן כדי לפתוח את ספר המחירים.';

	/// he: 'סורקים קבלה, והמחיר של כל מוצר נשמר. מכאן רשימת הקניות מקבלת הערכת עלות, ומחירים חציוניים מהקהילה משלימים מה שעוד לא קניתם.'
	String get s7 => 'סורקים קבלה, והמחיר של כל מוצר נשמר. מכאן רשימת הקניות מקבלת הערכת עלות, ומחירים חציוניים מהקהילה משלימים מה שעוד לא קניתם.';

	/// he: 'שאלו את שפי על הרשימה הזו: מה חסר לארוחה, מה אפשר להחליף, או להוסיף פריטים בדיבור.'
	String get shefi => 'שאלו את שפי על הרשימה הזו: מה חסר לארוחה, מה אפשר להחליף, או להוסיף פריטים בדיבור.';
}

// Path: walkthrough.topics.community
class Translations$walkthrough$topics$community$he {
	Translations$walkthrough$topics$community$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'קהילה'
	String get title => 'קהילה';

	/// he: 'מתכונים משותפים של כל המשתמשים, ופורום לשאלות ותשובות.'
	String get summary => 'מתכונים משותפים של כל המשתמשים, ופורום לשאלות ותשובות.';

	/// he: 'לחצו על ״קהילה״.'
	String get s1 => 'לחצו על ״קהילה״.';

	/// he: 'מתכונים משותפים ופורום. אפשר לעשות לייק למתכון, לשרשור ולתגובה, לשמור מתכון אצלכם, ולצרף מתכון לתגובה בפורום.'
	String get s2 => 'מתכונים משותפים ופורום. אפשר לעשות לייק למתכון, לשרשור ולתגובה, לשמור מתכון אצלכם, ולצרף מתכון לתגובה בפורום.';

	/// he: 'כפתור השיתוף מפרסם מתכון משלכם לקהילה.'
	String get s3 => 'כפתור השיתוף מפרסם מתכון משלכם לקהילה.';
}

// Path: walkthrough.topics.account
class Translations$walkthrough$topics$account$he {
	Translations$walkthrough$topics$account$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'חשבון, פרימיום והגדרות'
	String get title => 'חשבון, פרימיום והגדרות';

	/// he: 'התראות על הזמנות לשיתוף, והחשבון עם פרימיום, גישה משותפת, הגדרות ומצב תצוגה.'
	String get summary => 'התראות על הזמנות לשיתוף, והחשבון עם פרימיום, גישה משותפת, הגדרות ומצב תצוגה.';

	/// he: 'התראות: הזמנות לשיתוף ספרים ותפריטים, ועדכונים.'
	String get s1 => 'התראות: הזמנות לשיתוף ספרים ותפריטים, ועדכונים.';

	/// he: 'לחצו על התמונה כדי לפתוח את החשבון.'
	String get s2 => 'לחצו על התמונה כדי לפתוח את החשבון.';

	/// he: 'פרימיום: ניתוחי AI ללא הגבלה יומית וללא פרסומות. חשבון חינמי מקבל מכסה יומית, ואפשר להרחיב אותה בצפייה בסרטון.'
	String get s3 => 'פרימיום: ניתוחי AI ללא הגבלה יומית וללא פרסומות. חשבון חינמי מקבל מכסה יומית, ואפשר להרחיב אותה בצפייה בסרטון.';

	/// he: 'גישה משותפת: מי חולק איתכם ספרים, תפריטים ורשימות קניות, ומה שיתפתם אתם.'
	String get s4 => 'גישה משותפת: מי חולק איתכם ספרים, תפריטים ורשימות קניות, ומה שיתפתם אתם.';

	/// he: 'לחצו על ״הגדרות״.'
	String get s5 => 'לחצו על ״הגדרות״.';

	/// he: 'מצב תצוגה: בהיר, כהה או לפי המכשיר. בהגדרות גם שפה, העדפות תזונה ואלרגנים. את ההדרכה הזו מפעילים שוב ממסך התמיכה שבחשבון.'
	String get s6 => 'מצב תצוגה: בהיר, כהה או לפי המכשיר. בהגדרות גם שפה, העדפות תזונה ואלרגנים. את ההדרכה הזו מפעילים שוב ממסך התמיכה שבחשבון.';

	/// he: 'שפי, העוזר החכם: הכפתור הצף הזה פותח שיחה. שואלים בכתב או בקול, ושפי עונה, מוסיף לתפריט, בונה רשימה או מפעיל מצב בישול. בתוך מתכון, תפריט או רשימה יש כפתור ״שאלו את שפי״ שמדבר רק על הפריט הזה.'
	String get shefi => 'שפי, העוזר החכם: הכפתור הצף הזה פותח שיחה. שואלים בכתב או בקול, ושפי עונה, מוסיף לתפריט, בונה רשימה או מפעיל מצב בישול. בתוך מתכון, תפריט או רשימה יש כפתור ״שאלו את שפי״ שמדבר רק על הפריט הזה.';
}

// Path: walkthrough.topics.settings
class Translations$walkthrough$topics$settings$he {
	Translations$walkthrough$topics$settings$he.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// he: 'הגדרות והעדפות'
	String get title => 'הגדרות והעדפות';

	/// he: 'כל שורה בהגדרות ובהעדפות: פרופיל, שיתוף, התראות, שפה, מראה, מחיקת חשבון, יום קניות, מחירים, תזונה וספרים.'
	String get summary => 'כל שורה בהגדרות ובהעדפות: פרופיל, שיתוף, התראות, שפה, מראה, מחיקת חשבון, יום קניות, מחירים, תזונה וספרים.';

	/// he: 'לחצו על ״הגדרות״: כאן החשבון והאפליקציה.'
	String get s1 => 'לחצו על ״הגדרות״: כאן החשבון והאפליקציה.';

	/// he: 'פרופיל: השם והתמונה שהשותפים שלכם רואים, ודרכי ההתחברות המקושרות.'
	String get s2 => 'פרופיל: השם והתמונה שהשותפים שלכם רואים, ודרכי ההתחברות המקושרות.';

	/// he: 'גישה משותפת: מי חולק איתכם מתכונים, ספרים, תפריטים ורשימות, ומה שיתפתם אתם. מכאן גם מצטרפים בקוד או ב-QR.'
	String get s3 => 'גישה משותפת: מי חולק איתכם מתכונים, ספרים, תפריטים ורשימות, ומה שיתפתם אתם. מכאן גם מצטרפים בקוד או ב-QR.';

	/// he: 'לחצו על ״הגדרות התראות״.'
	String get s4 => 'לחצו על ״הגדרות התראות״.';

	/// he: 'התראות פוש: המתג הראשי. כשהוא כבוי שום דבר לא נשלח; למטה בוחרים מה כן: תגובות, הזמנות, עדכונים והודעות מהצוות.'
	String get s5 => 'התראות פוש: המתג הראשי. כשהוא כבוי שום דבר לא נשלח; למטה בוחרים מה כן: תגובות, הזמנות, עדכונים והודעות מהצוות.';

	/// he: 'תזכורות יום הקניות: מתי להזכיר לכם לפני הקנייה. מתוזמנות במכשיר, בלי קשר לפוש.'
	String get s6 => 'תזכורות יום הקניות: מתי להזכיר לכם לפני הקנייה. מתוזמנות במכשיר, בלי קשר לפוש.';

	/// he: 'שפה: החלפה מתרגמת גם את המתכונים, הספרים, התפריטים והרשימות שלכם.'
	String get s7 => 'שפה: החלפה מתרגמת גם את המתכונים, הספרים, התפריטים והרשימות שלכם.';

	/// he: 'מראה: בהיר, כהה או לפי המכשיר. הבחירה נשמרת בחשבון ועוברת איתכם למכשיר הבא.'
	String get s8 => 'מראה: בהיר, כהה או לפי המכשיר. הבחירה נשמרת בחשבון ועוברת איתכם למכשיר הבא.';

	/// he: 'מחיקת החשבון: מוחקת לצמיתות את החשבון וכל מה שבו, אחרי אישור. מנוי בחנות מבטלים בנפרד.'
	String get s9 => 'מחיקת החשבון: מוחקת לצמיתות את החשבון וכל מה שבו, אחרי אישור. מנוי בחנות מבטלים בנפרד.';

	/// he: 'חזרה לחשבון: לחצו על ״העדפות״, איך האפליקציה מתנהגת בשבילכם.'
	String get s10 => 'חזרה לחשבון: לחצו על ״העדפות״, איך האפליקציה מתנהגת בשבילכם.';

	/// he: 'יום הקניות: היום שסביבו נבנית רשימת הקניות ומתוזמנות התזכורות.'
	String get s11 => 'יום הקניות: היום שסביבו נבנית רשימת הקניות ומתוזמנות התזכורות.';

	/// he: 'מחירי קהילה: כשדולק, המחירים מהקבלות שלכם מצטרפים באופן אנונימי לממוצעים, ושורות שלא קניתם מוערכות לפיהם.'
	String get s12 => 'מחירי קהילה: כשדולק, המחירים מהקבלות שלכם מצטרפים באופן אנונימי לממוצעים, ושורות שלא קניתם מוערכות לפיהם.';

	/// he: 'העדפות תזונה ואלרגנים: מסמנים כאן, והאפליקציה מדגישה אותם במתכונים ובמתכונים משותפים.'
	String get s13 => 'העדפות תזונה ואלרגנים: מסמנים כאן, והאפליקציה מדגישה אותם במתכונים ובמתכונים משותפים.';

	/// he: 'מעבר מהיר בספר: קפיצה לעמוד רחוק מדפדפת דף אחד בלבד. בכיבוי מדפדפים דרך כל העמודים שבדרך.'
	String get s14 => 'מעבר מהיר בספר: קפיצה לעמוד רחוק מדפדפת דף אחד בלבד. בכיבוי מדפדפים דרך כל העמודים שבדרך.';

	/// he: 'צלילים: אפקטים קוליים בדפדוף ובפעולות. אפשר לכבות.'
	String get s15 => 'צלילים: אפקטים קוליים בדפדוף ובפעולות. אפשר לכבות.';
}

/// The flat map containing all translations for locale <he>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Easy Plate',
			'common.save' => 'שמירה',
			'common.cancel' => 'ביטול',
			'common.ok' => 'הבנתי',
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
			'common.or' => 'או',
			'common.missingInfo' => '[חסר מידע]',
			'common.networkError' => 'אין חיבור לאינטרנט',
			'common.landscapeHint' => 'מומלץ לעבוד עם מסך לרוחב',
			'common.rotateLandscape' => 'סובב לרוחב',
			'common.rotatePortrait' => 'חזרה לאורך',
			'auth.welcome' => 'ברוכים הבאים ל-EasyPlate',
			'auth.subtitle' => 'התחברו כדי לשמור את המתכונים שלכם',
			'auth.signIn' => 'התחברות',
			'auth.signUp' => 'הרשמה',
			'auth.signOut' => 'התנתקות',
			'auth.email' => 'אימייל',
			'auth.emailHint' => 'name@example.com',
			'auth.password' => 'סיסמה',
			'auth.passwordHint' => 'לפחות 6 תווים',
			'auth.continueWithGoogle' => 'המשך עם Google',
			'auth.continueWithPhone' => 'המשך עם טלפון',
			'auth.continueWithEmail' => 'המשך עם אימייל',
			'auth.phoneNumber' => 'מספר טלפון',
			'auth.phoneHint' => '+972501234567',
			'auth.sendCode' => 'שליחת קוד',
			'auth.smsCode' => 'קוד מה-SMS',
			'auth.codeSentTo' => ({required Object phone}) => 'שלחנו קוד אימות אל ${phone}',
			'auth.verify' => 'אימות',
			'auth.resendCode' => 'שליחה מחדש',
			'auth.forgotPassword' => 'שכחתי סיסמה',
			'auth.resetSent' => 'נשלח מייל לאיפוס הסיסמה',
			'auth.noAccount' => 'אין לכם חשבון? הרשמו',
			'auth.haveAccount' => 'יש לכם חשבון? התחברו',
			'auth.invalidEmail' => 'כתובת אימייל לא תקינה',
			'auth.passwordTooShort' => 'הסיסמה חייבת להכיל לפחות 6 תווים',
			'auth.invalidPhone' => 'מספר טלפון לא תקין',
			'auth.codeRequired' => 'יש להזין את הקוד שקיבלתם',
			'auth.errorUnauthorized' => 'הפרטים שהוזנו שגויים',
			'auth.errorNetwork' => 'אין חיבור לאינטרנט',
			'auth.errorUnknown' => 'ההתחברות נכשלה, נסו שוב',
			'auth.signOutTitle' => 'להתנתק?',
			'auth.signOutBody' => 'תצטרכו להתחבר מחדש כדי להגיע למתכונים שלכם.',
			'auth.errorOperationNotAllowed' => 'שיטת ההתחברות הזו אינה זמינה כרגע',
			'auth.errorTooManyRequests' => 'יותר מדי ניסיונות. נסו שוב עוד כמה דקות',
			'auth.errorInvalidPhone' => 'מספר הטלפון אינו תקין',
			'auth.errorEmailInUse' => 'כתובת האימייל כבר רשומה',
			'auth.verifyEmailTitle' => 'אימות כתובת המייל',
			'auth.verifyEmailBody' => ({required Object email}) => 'שלחנו קישור אימות אל ${email}. פתחו אותו ואז חזרו לכאן.',
			'auth.resendEmail' => 'שליחת הקישור מחדש',
			'auth.emailResent' => 'הקישור נשלח שוב',
			'auth.checkVerification' => 'כבר אימתתי',
			'auth.stillNotVerified' => 'הכתובת עדיין לא אומתה',
			'auth.linkPhone' => 'אימות טלפון',
			'auth.phoneLinked' => 'הטלפון אומת',
			'auth.phoneAlreadyUsed' => 'המספר הזה כבר משויך לחשבון אחר',
			'auth.emailAlreadyLinked' => 'לחשבון כבר משויכת כתובת מייל',
			'auth.addEmailPassword' => 'הוספת מייל וסיסמה',
			'auth.verified' => 'מאומת',
			'auth.linkGoogle' => 'קישור חשבון Google',
			'auth.googleLinked' => 'מקושר',
			'auth.googleAlreadyUsed' => 'חשבון Google הזה כבר משויך למשתמש אחר',
			'auth.googleAlreadyLinked' => 'כבר מקושר חשבון Google',
			'auth.phoneGateTitle' => 'אימות מספר טלפון',
			'auth.phoneGateBody' => 'כל חשבון מאומת במספר טלפון. נשלח לכם קוד ב-SMS.',
			'auth.changeNumber' => 'שינוי המספר',
			'auth.signInTitle' => 'כניסה',
			'auth.phoneFirstHint' => 'חדשים כאן? המשיכו עם טלפון.',
			'auth.errorAccountExistsDifferentCredential' => 'כתובת המייל הזו כבר משויכת לחשבון אחר. היכנסו בדרך שבה נרשמתם.',
			'auth.errorCredentialInUse' => 'הפרטים האלה כבר משויכים לחשבון אחר',
			'auth.continueWithApple' => 'המשך עם Apple',
			'auth.linkApple' => 'קישור חשבון Apple',
			'auth.appleLinked' => 'מקושר',
			'auth.appleAlreadyUsed' => 'חשבון Apple הזה כבר משויך למשתמש אחר',
			'auth.appleAlreadyLinked' => 'כבר מקושר חשבון Apple',
			'auth.blockedTitle' => 'החשבון נחסם',
			'auth.blockedBody' => 'החשבון הזה נחסם על ידי מנהל האפליקציה. לפרטים אפשר לפנות אלינו במסך התמיכה.',
			'auth.phoneClaimedTitle' => 'המספר הזה שייך לחשבון קיים',
			'auth.phoneClaimedBody' => ({required Object phone}) => 'המספר ${phone} כבר מחובר לחשבון EasyPlate אחר. כדי להגיע לחשבון הזה ולמתכונים שלו, היכנסו כמו שנכנסתם אליו עד עכשיו (Google, ‏Apple או מייל), ואמתו שם את המספר מחדש.',
			'auth.phoneClaimedSignIn' => 'כניסה לחשבון הקיים שלי',
			'auth.phoneClaimedCreateNew' => 'יצירת חשבון חדש בכל זאת',
			'auth.phoneClaimedCreateNewConfirm' => 'ייפתח חשבון חדש וריק עבור המספר הזה. החשבון הקיים יישאר כמו שהוא, אבל לא יהיה אפשר להגיע אליו יותר עם המספר הזה.',
			'auth.sessionOtherDeviceTitle' => 'החשבון מחובר במכשיר אחר',
			'auth.sessionOtherDeviceBody' => ({required Object platform, required Object since}) => 'החשבון הזה פתוח כרגע ב${platform}${since}. אפשר להשתמש בו במכשיר אחד בכל פעם: התנתקו שם, ואז לחצו ״נסו שוב״.',
			'auth.sessionSince' => ({required Object date}) => ' מאז ${date}',
			'auth.sessionExpiredTitle' => 'ההתחברות פגה',
			'auth.sessionExpiredBody' => 'התחברות נמשכת עד חודש. כדי להמשיך, התחברו מחדש.',
			'auth.sessionRetry' => 'נסו שוב',
			'auth.platformIos' => 'אייפון',
			'auth.platformAndroid' => 'אנדרואיד',
			'auth.platformOther' => 'מכשיר אחר',
			'profile.setupTitle' => 'כמה פרטים אחרונים',
			'profile.setupSubtitle' => 'כדי שנדע איך לפנות אליכם',
			'profile.fullName' => 'שם מלא',
			'profile.fullNameHint' => 'ישראל ישראלי',
			'profile.fullNameRequired' => 'יש להזין שם מלא',
			'profile.photo' => 'תמונת פרופיל',
			'profile.addPhoto' => 'הוספת תמונה',
			'profile.phoneOptional' => 'טלפון (לא חובה)',
			'profile.emailOptional' => 'אימייל (לא חובה)',
			'profile.save' => 'סיום הרשמה',
			'profile.saving' => 'שומר...',
			'profile.saveFailed' => 'לא הצלחנו לשמור את הפרופיל',
			'profile.myProfile' => 'הפרופיל שלי',
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
			'allergens.title' => 'אלרגנים',
			'allergens.pick' => 'סימון אלרגנים',
			'allergens.contains' => 'מכיל',
			'allergens.mayContain' => 'עלול להכיל',
			'allergens.gluten' => 'גלוטן',
			'allergens.milk' => 'חלב',
			'allergens.eggs' => 'ביצים',
			'allergens.fish' => 'דגים',
			'allergens.shellfish' => 'פירות ים',
			'allergens.peanuts' => 'בוטנים',
			'allergens.treeNuts' => 'אגוזים',
			'allergens.sesame' => 'שומשום',
			'allergens.soy' => 'סויה',
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
			'settings.appearance' => 'מראה',
			'settings.themeSystem' => 'לפי המכשיר',
			'settings.themeLight' => 'בהיר',
			'settings.themeDark' => 'כהה',
			'settings.soundEffects' => 'אפקטי קול (דפדוף עמודים)',
			'settings.fastPageTurn' => 'מעבר מהיר בספר',
			'settings.fastPageTurnHint' => 'קפיצה מתוכן העניינים או מהניווט המהיר מדפדפת דף אחד בלבד אל היעד. בכיבוי מדפדפים דרך כל העמודים שבדרך.',
			'settings.sharedAccess' => 'ניהול שיתופים',
			'settings.noSharedAccess' => 'עדיין לא שיתפתם ספרים או רשימות',
			'settings.communityPrices' => 'מחירים לפי ממוצע המשתמשים',
			'settings.communityPricesHint' => 'כשאין לך מחיר משלך למוצר, הצג את המחיר החציוני שאנשים אחרים שיתפו',
			'settings.shoppingReminders' => 'תזכורות ליום הקניות',
			'settings.shoppingRemindersHint' => 'ההתראות נשלחות מהמכשיר, לפי יום הקניות שנבחר',
			'settings.reminderTwoDaysBefore' => 'יומיים לפני (ערב)',
			'settings.reminderDayBefore' => 'יום לפני (ערב)',
			'settings.reminderSameDayMorning' => 'ביום הקניות (בוקר)',
			'settings.reminderSameDayAfternoon' => 'ביום הקניות (אחה״צ)',
			'settings.translatingContent' => 'מתרגם את המתכונים והתפריטים שלך...',
			'settings.translatedContent' => ({required Object count}) => '${count} פריטים תורגמו',
			'settings.translationPartialTitle' => 'התרגום לא הושלם',
			'settings.translationPartial' => ({required Object count}) => '${count} פריטים נשארו בשפת המקור. אפשר לנסות שוב מאוחר יותר.',
			'settings.translationFailed' => 'התרגום נכשל. התוכן נשאר בשפת המקור.',
			'settings.account' => 'חשבון',
			'settings.notifications' => 'התראות',
			'settings.notificationsHint' => 'אילו התראות מגיעות אליך, ואיך',
			'settings.settingsHint' => 'חשבון, התראות, שפה ומראה',
			'settings.dangerZone' => 'אזור מסוכן',
			'settings.deleteAccount' => 'מחיקת החשבון',
			'settings.deleteAccountHint' => 'מחיקה לצמיתות של החשבון וכל המידע שבו',
			'settings.deleteAccountTitle' => 'למחוק את החשבון לצמיתות?',
			'settings.deleteAccountBody' => 'החשבון, המתכונים, הספרים, התפריטים, רשימות הקניות, הקבלות, התמונות, הפוסטים והתגובות שלכם יימחקו לצמיתות משרתינו ומהמכשיר הזה, ואי אפשר יהיה לשחזר אותם. מה ששיתפתם יוסר גם ממי ששיתפתם איתו. מנוי פעיל אינו מתבטל אוטומטית: בטלו אותו ב-App Store או ב-Google Play.',
			'settings.deleteAccountConfirm' => 'מחיקה לצמיתות',
			'settings.deletingAccount' => 'מוחקים את החשבון…',
			'settings.deleteAccountFailed' => 'מחיקת החשבון נכשלה. נסו שוב, או כתבו ל-support@aieasyplate.app.',
			'settings.deleteAccountHousehold' => 'אתם הבעלים של משק בית משותף. סגרו אותו קודם במסך "משק בית" ואז נסו שוב.',
			'notificationSettings.title' => 'הגדרות התראות',
			'notificationSettings.push' => 'התראות דחיפה',
			'notificationSettings.pushHint' => 'התראות במכשיר הזה. בכיבוי, שום דבר לא נשלח לטלפון; תיבת ההתראות ממשיכה להתמלא.',
			'notificationSettings.pushDenied' => 'ההתראות של EasyPlate חסומות בהגדרות המכשיר. כדי לקבל התראות, יש לאפשר אותן שם.',
			'notificationSettings.community' => 'קהילה',
			'notificationSettings.repliesOnMyPosts' => 'תגובות לפוסטים שלי',
			'notificationSettings.repliesOnMyPostsHint' => 'מישהו ענה בדיון שפתחת',
			'notificationSettings.repliesOnThreads' => 'תגובות בדיונים שהשתתפתי בהם',
			'notificationSettings.repliesOnThreadsHint' => 'תגובה חדשה בדיון שהגבת בו',
			'notificationSettings.sharing' => 'שיתוף',
			'notificationSettings.shareInvites' => 'הזמנות לשיתוף',
			'notificationSettings.shareInvitesHint' => 'מישהו שיתף איתך מתכון, ספר או תפריט. ההזמנה תמיד מגיעה לתיבה; כאן נקבע רק אם תישלח התראה.',
			'notificationSettings.sharedRecipeUpdates' => 'עדכונים למתכונים ששמרתי',
			'notificationSettings.sharedRecipeUpdatesHint' => 'הכותב/ת שינה/תה מתכון מהקהילה ששמרת',
			'notificationSettings.easyPlate' => 'מ-EasyPlate',
			'notificationSettings.adminReplies' => 'תשובות לפניות שלי לתמיכה',
			'notificationSettings.announcements' => 'הודעות מהצוות',
			'notificationSettings.announcementsHint' => 'חדשות ועדכונים מצוות EasyPlate',
			'notificationSettings.inApp' => 'כשהאפליקציה פתוחה',
			'notificationSettings.foregroundPopups' => 'הצגת התראות כחלונית',
			'notificationSettings.foregroundPopupsHint' => 'התראה שמגיעה בזמן שהאפליקציה פתוחה נפתחת בכרטיס קטן. בכיבוי, היא מגיעה רק לתיבת ההתראות.',
			'notificationSettings.reminders' => 'תזכורות קניות',
			'preferences.title' => 'העדפות',
			'preferences.hint' => 'קניות, העדפות תזונתיות והתנהגות הספרים',
			'preferences.shopping' => 'קניות',
			'preferences.books' => 'ספרי מתכונים',
			'more.title' => 'עוד',
			'more.settings' => 'הגדרות',
			'more.profile' => 'פרופיל אישי',
			'more.support' => 'תמיכה',
			'more.supportTitle' => 'איך אפשר לעזור?',
			'more.supportBody' => 'כתבו לנו ונחזור אליכם בהקדם.',
			'more.whatsapp' => 'שליחת הודעה בוואטסאפ',
			'more.email' => 'שליחת מייל',
			'more.supportUnavailable' => 'לא הצלחנו לפתוח את האפליקציה',
			'more.preferences' => 'העדפות',
			'more.help' => 'תמיכה ומידע',
			'more.helpHint' => 'תמיכה, מדיניות פרטיות ותנאי שימוש',
			'more.legal' => 'מידע משפטי',
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
			'books.spineColor' => 'צבע הפס',
			'recipe.prepTime' => 'זמן הכנה',
			'recipe.cookTime' => 'זמן בישול',
			'recipe.ingredients' => 'מצרכים',
			'recipe.ingredientsCount' => ({required Object count}) => '${count} מצרכים',
			'recipe.minutes' => ({required Object count}) => '${count} דק׳',
			'recipe.hours' => ({required Object count}) => '${count} שע׳',
			'recipe.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours} שע׳ ו${minutes} דק׳',
			'recipe.instructions' => 'אופן ההכנה',
			'recipe.addToBook' => 'הוסף לספר',
			'recipe.removeFromBook' => 'הסר מהספר',
			'recipe.deleteRecipe' => 'מחיקת מתכון',
			'recipe.photo' => 'תמונת המתכון',
			'recipe.mine' => 'המתכונים שלי',
			'recipe.saved' => 'מתכונים ששמרתי',
			'recipe.noneMine' => 'עדיין לא יצרתם מתכונים',
			'recipe.noneSaved' => 'עדיין לא שמרתם מתכונים מהקהילה',
			'recipe.pendingAnalysis' => 'ממתין לניתוח',
			'recipe.pendingAnalysisHint' => 'המתכון נשמר כטקסט גולמי. אפשר לנתח אותו עכשיו או לערוך ידנית.',
			'recipe.analyzeNow' => 'ניתוח באמצעות AI עכשיו',
			'recipe.analyzing' => 'מנתח את המתכון...',
			'recipe.analyzeFailed' => 'הניתוח נכשל, אפשר לנסות שוב מאוחר יותר',
			'recipe.communityUpdateTitle' => 'המתכון משותף בקהילה',
			'recipe.communityUpdateBody' => 'לעדכן גם את העותק בקהילה, או רק אצלך?',
			'recipe.communityUpdateBoth' => 'גם בקהילה',
			'recipe.communityUpdateLocal' => 'רק אצלי',
			'recipe.communityUpdated' => 'העותק בקהילה עודכן',
			'recipe.communityGone' => 'המתכון כבר לא בקהילה, נשמר רק אצלך',
			'cookMode.title' => 'מצב בישול',
			'cookMode.start' => 'להתחיל לבשל',
			'cookMode.stepOf' => ({required Object n, required Object total}) => 'שלב ${n} מתוך ${total}',
			'cookMode.ingredients' => 'מצרכים',
			'cookMode.inThisStep' => 'בשלב הזה',
			'cookMode.timer' => 'טיימר',
			'cookMode.startTimer' => 'להפעיל טיימר',
			'cookMode.pause' => 'השהיה',
			'cookMode.resume' => 'להמשיך',
			'cookMode.reset' => 'איפוס',
			'cookMode.timeUp' => 'הזמן נגמר!',
			'cookMode.next' => 'לשלב הבא',
			'cookMode.previous' => 'הקודם',
			'cookMode.finish' => 'סיימתי לבשל',
			'cookMode.finishedTitle' => 'בתיאבון!',
			'cookMode.finishedBody' => 'כל השלבים הושלמו. המסך יכול לכבות שוב.',
			'cookMode.screenOn' => 'המסך נשאר דולק בזמן הבישול',
			'cookMode.noSteps' => 'למתכון הזה אין עדיין שלבים',
			'cookMode.runningOnStep' => ({required Object n}) => 'טיימר רץ בשלב ${n}',
			'cookMode.inProgress' => 'באמצע מצב בישול',
			'cookMode.inProgressBody' => ({required Object recipe, required Object n, required Object total}) => '"${recipe}" · שלב ${n} מתוך ${total}',
			'cookMode.resumeCooking' => 'המשך',
			'cookMode.endCooking' => 'סיום',
			'cookMode.stepLabel' => ({required Object n}) => 'שלב ${n}',
			'cookMode.ongoingBody' => ({required Object time, required Object total, required Object n}) => 'מסתיים ב-${time} · ${total} · שלב ${n}',
			'cookMode.timeUpBody' => ({required Object n}) => 'שלב ${n}: הזמן נגמר',
			'cookMode.runningTimers' => 'טיימרים פועלים',
			'cookMode.premiumOnly' => 'מצב בישול הוא חלק מ-EasyPlate Premium',
			'nutrition.title' => 'ערכים תזונתיים',
			'nutrition.perServing' => 'למנה',
			'nutrition.perServingHint' => 'כל הערכים הם למנה אחת. השאירו ריק כדי להוריד את ההערכה.',
			'nutrition.servings' => 'מנות',
			'nutrition.servingsCount' => ({required Object count}) => '${count} מנות',
			'nutrition.calories' => 'קלוריות',
			'nutrition.kcal' => 'קק״ל',
			'nutrition.protein' => 'חלבון',
			'nutrition.carbs' => 'פחמימות',
			'nutrition.fat' => 'שומן',
			'nutrition.gramsShort' => 'ג׳',
			'nutrition.estimate' => 'הערכה עם AI',
			'nutrition.estimating' => 'מעריך ערכים תזונתיים…',
			'nutrition.estimateFailed' => 'ההערכה לא הצליחה, נסו שוב',
			'nutrition.none' => 'עוד אין ערכים תזונתיים למתכון הזה',
			'nutrition.noneHint' => 'ה-AI יכול להעריך קלוריות, חלבון, פחמימות ושומן מרשימת המצרכים',
			'nutrition.estimated' => 'הערכים התזונתיים עודכנו',
			'nutrition.editorServings' => 'מספר מנות',
			'nutrition.editorCalories' => 'קלוריות למנה',
			'nutrition.editorProtein' => 'חלבון (גרם)',
			'nutrition.editorCarbs' => 'פחמימות (גרם)',
			'nutrition.editorFat' => 'שומן (גרם)',
			'nutrition.dashboard' => 'דאשבורד תזונה',
			'nutrition.weekly' => 'השבוע',
			'nutrition.today' => 'היום',
			'nutrition.dayTotal' => 'סה״כ ליום',
			'nutrition.weekTotal' => 'סה״כ לשבוע',
			'nutrition.dailyAverage' => 'ממוצע ליום מתוכנן',
			'nutrition.perMeal' => 'לפי ארוחה',
			'nutrition.perDay' => 'לפי יום',
			'nutrition.noPlanned' => 'עוד לא תוכננו ארוחות עם מתכונים',
			'nutrition.missingCount' => ({required Object count}) => '${count} פריטים בלי ערכים תזונתיים',
			'nutrition.macroSplit' => 'חלוקת קלוריות',
			'nutrition.kcalPerDay' => 'קק״ל ליום',
			'nutrition.openDashboard' => 'דאשבורד שבועי',
			'nutrition.perRecipe' => 'לכל המתכון',
			'nutrition.perRecipeServings' => ({required Object count}) => '${count} מנות',
			'community.title' => 'קהילה',
			'community.forum' => 'פורום',
			'community.sharedRecipes' => 'מתכונים משותפים',
			'community.newPost' => 'פוסט חדש',
			'community.postTitle' => 'כותרת',
			'community.postBody' => 'מה בא לכם לשאול או לספר?',
			'community.postTitleRequired' => 'צריך כותרת לפוסט',
			'community.postBodyRequired' => 'צריך תוכן לפוסט',
			'community.publish' => 'פרסום',
			'community.replies' => ({required Object count}) => '${count} תגובות',
			'community.noReplies' => 'עדיין אין תגובות',
			'community.oneReply' => 'תגובה אחת',
			'community.writeReply' => 'כתבו תגובה...',
			'community.send' => 'שליחה',
			'community.noPosts' => 'אין עדיין פוסטים. תהיו הראשונים!',
			'community.noSharedRecipes' => 'עדיין לא שותפו מתכונים. שתפו את הראשון!',
			'community.shareRecipe' => 'שיתוף מתכון',
			'community.pickRecipeToShare' => 'איזה מתכון לשתף?',
			'community.saveToMyRecipes' => 'שמירה למתכונים שלי',
			'community.savedToMyRecipes' => 'המתכון נשמר אצלכם',
			'community.deletePost' => 'מחיקת פוסט',
			'community.deletePostConfirm' => 'הפוסט והתגובות שלו יימחקו לצמיתות.',
			'community.unshare' => 'הסרת השיתוף',
			'community.unshareConfirm' => 'המתכון יוסר מהפיד המשותף.',
			'community.byAuthor' => ({required Object name}) => 'מאת ${name}',
			'community.loadFailed' => 'לא הצלחנו לטעון את התוכן',
			'community.allRecipes' => 'כל המתכונים',
			'community.myRecipes' => 'המתכונים שלי',
			'community.editShared' => 'עריכת המתכון המשותף',
			'community.sharedUpdated' => 'המתכון המשותף עודכן',
			'community.noneOfMine' => 'עדיין לא שיתפתם מתכונים',
			'community.search' => 'חיפוש',
			'community.searchHint' => 'שם מתכון או שם מפרסם',
			'community.savedOnly' => 'ששמרתי',
			'community.noResults' => 'לא נמצאו תוצאות',
			'community.attachRecipe' => 'צירוף מתכון',
			'community.openRecipe' => 'פתיחת המתכון',
			'community.recipeUnavailable' => 'המתכון הזה כבר לא זמין',
			'community.sortAndFilter' => 'מיון וסינון',
			'community.sort' => 'מיון',
			'community.sortNewest' => 'החדשים ביותר',
			'community.sortOldest' => 'הישנים ביותר',
			'community.sortMostLiked' => 'הכי אהובים',
			'community.topics' => 'נושאים',
			'community.likes' => 'לייקים',
			'community.anyLikes' => 'כל כמות',
			'community.atLeastLikes' => ({required Object count}) => '${count} ומעלה',
			'community.totalTime' => 'זמן הכנה כולל',
			'community.anyTime' => 'כל זמן',
			'community.upTo' => ({required Object duration}) => 'עד ${duration}',
			'community.clearFilters' => 'ניקוי סינונים',
			'community.applyFilters' => 'הצגת התוצאות',
			'community.likesPlus' => ({required Object count}) => '${count}+',
			'community.durationPlus' => ({required Object duration}) => '${duration}+',
			'community.splitTimes' => 'פיצול להכנה ובישול',
			'community.alreadySaved' => 'המתכון כבר שמור אצלכם',
			'community.savedTag' => 'שמור אצלכם',
			'community.removeSaved' => 'הסרה מהמתכונים ששמרתי',
			'community.removeSavedConfirm' => 'המתכון יוסר מהמתכונים ששמרתם. אפשר לשמור אותו שוב מהקהילה.',
			'community.oneNewPost' => 'פוסט חדש אחד',
			'community.newPosts' => ({required Object count}) => '${count} פוסטים חדשים',
			'community.replyFailed' => 'לא הצלחנו לשלוח את התגובה',
			'sharing.title' => 'שיתוף מתכון',
			'sharing.contactLabel' => 'אימייל או טלפון של השותף/ה',
			'sharing.contactHint' => 'name@example.com או 05…',
			'sharing.roleTitle' => 'הרשאה',
			'sharing.roleViewer' => 'צפייה בלבד',
			'sharing.roleViewerHint' => 'רואה את המתכון, לא יכול/ה לשנות אותו',
			'sharing.roleEditor' => 'עריכה',
			'sharing.roleEditorHint' => 'שינויים שלו/ה יופיעו גם אצלכם',
			'sharing.send' => 'שליחת הזמנה',
			'sharing.sent' => 'ההזמנה נשלחה',
			'sharing.invalidContact' => 'יש להזין אימייל או מספר טלפון תקינים',
			'sharing.notFound' => 'לא נמצא חשבון עם הפרטים האלה. ודאו שהאימייל או הטלפון מקושרים לחשבון שלו/ה, ושהאפליקציה נפתחה אצלו/ה לאחרונה.',
			'sharing.self' => 'אי אפשר לשתף עם עצמכם',
			'sharing.failed' => 'השיתוף נכשל, נסו שוב',
			'sharing.pendingInvites' => 'הזמנות ממתינות',
			'sharing.noPendingInvites' => 'אין הזמנות ממתינות',
			'sharing.sharedByMe' => 'מה ששיתפתי',
			'sharing.sharedWithMe' => 'מה ששותף איתי',
			'sharing.nothingSharedByMe' => 'עדיין לא שיתפתם כלום',
			'sharing.nothingSharedWithMe' => 'עדיין לא שותף איתכם כלום',
			'sharing.accept' => 'אישור',
			'sharing.decline' => 'ביטול',
			'sharing.accepted' => 'המתכון נוסף למתכונים שלכם',
			'sharing.declined' => 'ההזמנה נדחתה',
			'sharing.acceptFailed' => 'האישור נכשל, נסו שוב',
			'sharing.members' => 'שותפים',
			'sharing.noMembersYet' => 'עדיין אין שותפים שאישרו',
			'sharing.remove' => 'הסרה',
			'sharing.leave' => 'יציאה מהשיתוף',
			'sharing.removed' => 'השותף/ה הוסר/ה',
			'sharing.left' => 'יצאתם מהשיתוף',
			'sharing.invitedBy' => ({required Object name}) => 'מאת ${name}',
			'sharing.sharedTag' => 'משותף',
			'sharing.viewerTag' => 'צפייה בלבד',
			'sharing.editorTag' => 'עריכה',
			'sharing.ownerTag' => 'בבעלותי',
			'sharing.syncFailed' => 'לא הצלחנו לרענן את המתכון המשותף, מוצגת הגרסה השמורה',
			'sharing.viewerCannotEdit' => 'המתכון שותף איתכם לצפייה בלבד',
			'sharing.shareAction' => 'שיתוף',
			'sharing.directoryUnavailable' => 'השיתוף עדיין לא מוגדר בשרת. נסו לצאת ולהיכנס שוב; אם זה נמשך, יש לפרוס את חוקי Firestore.',
			'sharing.shareBook' => 'שיתוף ספר',
			'sharing.sharePlan' => 'שיתוף תפריט',
			'sharing.acceptedBook' => 'הספר נוסף לספרייה שלכם',
			'sharing.acceptedPlan' => 'התפריט נוסף לתפריטים שלכם',
			'sharing.viewerCannotEditBook' => 'הספר שותף איתכם לצפייה בלבד',
			'sharing.viewerCannotEditPlan' => 'התפריט שותף איתכם לצפייה בלבד',
			'sharing.kindRecipe' => 'מתכון',
			'sharing.kindBook' => 'ספר',
			'sharing.kindPlan' => 'תפריט',
			'sharing.recipesTravel' => 'המתכונים שבפנים ישותפו יחד איתו',
			'sharing.shareList' => 'שיתוף רשימת קניות',
			'sharing.acceptedList' => 'הרשימה נוספה לרשימות הקניות שלכם',
			'sharing.viewerCannotEditList' => 'הרשימה שותפה איתכם לצפייה בלבד',
			'sharing.kindList' => 'רשימת קניות',
			'notifications.title' => 'התראות',
			'notifications.empty' => 'אין התראות',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את "${recipe}"',
			'notifications.asViewer' => 'לצפייה בלבד',
			'notifications.asEditor' => 'לעריכה',
			'notifications.markAllRead' => 'סימון הכל כנקרא',
			'notifications.openRecipe' => 'פתיחת המתכון',
			'notifications.alreadyHandled' => 'ההזמנה כבר טופלה',
			'notifications.recipeUpdated' => ({required Object name, required Object recipe}) => '${name} עדכן/ה את "${recipe}"',
			'notifications.recipeUpdatedHint' => 'יש גרסה חדשה של מתכון ששמרת',
			'notifications.refreshCopy' => 'רענון לגרסה החדשה',
			'notifications.keepCopy' => 'שמירת העותק שלי',
			'notifications.refreshed' => 'העותק שלך עודכן לגרסה החדשה',
			'notifications.keptCopy' => 'העותק שלך נשאר כמו שהוא',
			'notifications.recipeGone' => 'המתכון כבר לא בקהילה',
			'notifications.deleteAll' => 'מחיקת כל ההתראות',
			'notifications.deleteAllBody' => 'כל ההתראות יימחקו.',
			'notifications.openInbox' => 'פתיחת ההתראות',
			'notifications.sharedBook' => ({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את הספר "${recipe}"',
			'notifications.sharedPlan' => ({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את התפריט "${recipe}"',
			'notifications.adminReply' => 'תשובה מצוות EasyPlate לפנייה שלך',
			'notifications.adminReplyQuote' => ({required Object excerpt}) => 'הפנייה שלך: "${excerpt}"',
			'notifications.adminMessage' => 'הודעה מ-EasyPlate',
			'notifications.forumReplyOnMyPost' => ({required Object name, required Object post}) => '${name} הגיב/ה לפוסט שלך "${post}"',
			'notifications.forumReplyOnThread' => ({required Object name, required Object post}) => '${name} הגיב/ה בדיון "${post}"',
			'notifications.openThread' => 'פתיחת הדיון',
			'notifications.threadGone' => 'הדיון הזה נמחק',
			'notifications.settings' => 'הגדרות',
			'notifications.sharedList' => ({required Object name, required Object recipe}) => '${name} שיתף/ה איתך את רשימת הקניות "${recipe}"',
			'editor.title' => 'עריכת מתכון',
			'editor.recipeTitle' => 'שם המתכון',
			'editor.titleHint' => 'לדוגמה: שקשוקה ירושלמית',
			'editor.topics' => 'נושאים',
			'editor.titleRequired' => 'חובה להזין שם למתכון',
			'editor.prepMinutes' => 'זמן הכנה (דק׳)',
			'editor.cookMinutes' => 'זמן בישול (דק׳)',
			'editor.amount' => 'כמות',
			'editor.unit' => 'יחידה',
			'editor.ingredientName' => 'שם המצרך',
			'editor.stepHint' => 'תארו את השלב',
			'editor.addIngredient' => 'הוספת מצרך',
			'editor.addStep' => 'הוספת שלב',
			'editor.removeIngredient' => 'הסרת מצרך',
			'editor.removeStep' => 'הסרת שלב',
			'editor.reorderStep' => 'שינוי סדר השלב',
			'editor.fixSpelling' => 'תיקון שגיאות כתיב',
			'editor.refining' => 'מתקן את המתכון...',
			'editor.refineError' => 'לא הצלחנו לתקן את המתכון',
			'editor.spellingFixed' => 'המתכון תוקן',
			'editor.noChanges' => 'לא נמצאו שגיאות כתיב',
			'editor.timesSynced' => 'הזמנים באופן ההכנה עודכנו לפי הזמנים החדשים',
			'editor.discardTitle' => 'לבטל את השינויים?',
			'editor.discardBody' => 'השינויים שביצעתם לא יישמרו.',
			'editor.discard' => 'בטל שינויים',
			'editor.saveOptionsTitle' => 'איך לשמור?',
			_ => null,
		} ?? switch (path) {
			'editor.savePlainHint' => 'שמירת השינויים כפי שהם, ללא המתנה',
			'editor.saveWithAi' => 'שמירה עם עיבוד AI',
			'editor.saveWithAiHint' => 'תיקון שגיאות כתיב והתאמת הזמנים שבשלבי ההכנה',
			'ingestion.title' => 'הוספת מתכון',
			'ingestion.pasteText' => 'הדבקת טקסט',
			'ingestion.pasteHint' => 'הדביקו כאן מתכון מוואטסאפ או מכל מקור אחר',
			'ingestion.webSearch' => 'חיפוש באינטרנט',
			'ingestion.urlScrape' => 'קישור לאתר',
			'ingestion.socialVideo' => 'סרטון מהרשתות',
			'ingestion.socialVideoHint' => 'הדביקו קישור לסרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק',
			'ingestion.socialUnreadable' => 'לא הצלחנו לקרוא את הסרטון. ייתכן שהחשבון פרטי או שהפלטפורמה חסמה את הגישה. אפשר להעתיק את הטקסט מתיאור הסרטון ולהדביק אותו כטקסט.',
			'ingestion.aiRequest' => 'בקשת מתכון',
			'ingestion.aiRequestHint' => 'תארו מה בא לכם להכין. לדוגמה: מתכון לדייסת סולת לתינוקת בת שנה עם פירות',
			'ingestion.parse' => 'נתח מתכון',
			'ingestion.parsing' => 'מנתח את המתכון...',
			'ingestion.parseError' => 'לא הצלחנו לנתח את המתכון',
			'ingestion.reviewTitle' => 'בדקו לפני שמירה',
			'ingestion.notConfigured' => 'התכונה הזו דורשת חיבור לשירות חיצוני שטרם הוגדר',
			'ingestion.openOptionsTitle' => 'איך לפתוח את המתכון?',
			'ingestion.viewOriginal' => 'הצגת המתכון המקורי',
			'ingestion.viewOriginalHint' => 'הטקסט כפי שמופיע באתר, ללא עיבוד — נטען מיד',
			'ingestion.generateStructured' => 'יצירת מתכון מובנה',
			'ingestion.generateStructuredHint' => 'ניתוח אוטומטי למצרכים, לכמויות ולשלבי ההכנה',
			'ingestion.originalTitle' => 'המתכון המקורי',
			'ingestion.fetchFailed' => 'לא הצלחנו לטעון את העמוד',
			'ingestion.loadingOriginal' => 'טוען את העמוד...',
			'ingestion.structuredFromSite' => 'המתכון נקרא ישירות מהנתונים המובנים של האתר, ללא עיבוד AI',
			'ingestion.useStructured' => 'המשך למתכון המובנה',
			'ingestion.preferAi' => 'עיבוד באמצעות AI במקום',
			'ingestion.analysisTimedOut' => 'הניתוח לא הושלם בזמן',
			'ingestion.analysisFailed' => 'הניתוח נכשל',
			'ingestion.unparsedHint' => 'הטקסט נשמר כפי שהוא. אפשר לנסות שוב, לערוך ידנית, או לשמור ולנתח מאוחר יותר.',
			'ingestion.retryAnalysis' => 'ניסיון נוסף',
			'ingestion.editManually' => 'עריכה ידנית',
			'ingestion.saveForLater' => 'שמירה לניתוח מאוחר יותר',
			'ingestion.untitledRecipe' => 'מתכון ללא שם',
			'ingestion.manual' => 'כתיבה ידנית',
			'ingestion.manualHint' => 'מילוי המתכון בעצמכם בפורמט המובנה — ללא ניתוח AI וללא המתנה.',
			'ingestion.openBlankEditor' => 'פתיחת עורך ריק',
			'ingestion.generate' => 'יצירת מתכון',
			'ingestion.generating' => 'כותב לכם מתכון...',
			'ingestion.file' => 'הקלטה / PDF',
			'ingestion.fileHint' => 'אפשר גם לשתף הקלטה או PDF ישירות מכל אפליקציה אל Easy Plate, דרך כפתור השיתוף הרגיל.',
			'ingestion.chooseFile' => 'בחירת קובץ',
			'ingestion.replaceFile' => 'קובץ אחר',
			'ingestion.fileTooLarge' => 'הקבצים גדולים מדי. הגבול הכולל הוא 10MB — כעשר דקות של הקלטה.',
			'ingestion.fileUnsupported' => 'אפשר לנתח רק קובצי אודיו ו‑PDF.',
			'ingestion.sharedIn' => ({required Object app}) => 'הגיע מ‑${app}',
			'ingestion.addFile' => 'הוספת קובץ',
			'ingestion.filesAsOne' => ({required Object count}) => '${count} קבצים — ינותחו יחד כמתכון אחד, לפי הסדר',
			'ingestion.shareMoreHint' => 'אפשר לחזור לוואטסאפ ולשתף עוד הקלטה — היא תצטרף לרשימה כאן.',
			'ingestion.chooseSource' => 'מאיפה מגיע המתכון?',
			'ingestion.pasteTextDescription' => 'קיבלתם מתכון בוואטסאפ, העתקתם מאתר או מהודעה? הדביקו כאן את הטקסט כמו שהוא. המודל יזהה את שם המנה, המצרכים עם הכמויות ושלבי ההכנה, ויסדר הכול בפורמט אחיד. בלי מגבלה יומית.',
			'ingestion.webSearchDescription' => 'כתבו מה בא לכם להכין, ונחפש בשבילכם מתכונים ברחבי האינטרנט. מתוך התוצאות תוכלו לקרוא את המתכון המקורי כפי שהוא, או לייבא אותו לפורמט המובנה של האפליקציה.',
			'ingestion.webSearchHint' => 'לדוגמה: קובה סלק, שקשוקה, עוגת גבינה',
			'ingestion.urlScrapeDescription' => 'הדביקו קישור לעמוד מתכון באתר או בבלוג. נקרא את העמוד, נתעלם מהפרסומות ומהסיפורים שמסביב, ונחלץ רק את המתכון: מצרכים, כמויות ושלבים. באתרים רבים זה אפילו לא צורך מהמכסה היומית.',
			'ingestion.urlScrapeHint' => 'https://www.example.co.il/recipe/...',
			'ingestion.socialVideoDescription' => 'הדביקו קישור לסרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק. נצפה בסרטון בשבילכם, נקשיב למה שנאמר ונקרא את הכתוביות והתיאור, ונהפוך את זה למתכון כתוב ומסודר. זה לוקח כדקה.',
			'ingestion.aiRequestDescription' => 'אין לכם מתכון, רק רעיון? תארו את המנה, למי היא מיועדת ומה חשוב לכם, והמודל יכתוב לכם מתכון מלא בהתאם להעדפות התזונתיות שהגדרתם.',
			'ingestion.manualDescription' => 'כותבים את המתכון בעצמכם, ישירות בעורך המובנה: שם, מצרכים עם כמויות ויחידות, ושלבי הכנה. בלי AI ובלי המתנה. מתאים למתכון של סבתא שאתם יודעים בעל פה.',
			'ingestion.fileDescription' => 'בחרו קובץ אודיו שבו מישהו מקריא או מספר את המתכון, הודעה קולית מוואטסאפ, או PDF של מתכון. נתמלל ונקרא את הכול ונחלץ ממנו מתכון מסודר. אפשר לצרף כמה קבצים, והם ינותחו יחד כמתכון אחד.',
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
			'mealPlanner.planOptions' => 'אפשרויות תפריט',
			'mealPlanner.deletePlan' => 'מחיקת התפריט',
			'mealPlanner.deletePlanConfirm' => ({required Object name}) => 'למחוק את התפריט "${name}"? הארוחות שבו יימחקו.',
			'mealPlanner.leavePlanConfirm' => ({required Object name}) => 'לצאת מהשיתוף של התפריט "${name}"? הוא יוסר מהרשימה שלך.',
			'mealPlanner.planDeleted' => 'התפריט נמחק',
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
			'groceryList.planFilter' => 'כל התפריטים',
			'groceryList.choosePlans' => 'בחר תפריטים',
			'groceryList.plansSelected' => ({required Object count}) => '${count} תפריטים נבחרו',
			'groceryList.onePlanSelected' => 'תפריט אחד נבחר',
			'groceryList.noPlansToPick' => 'עדיין אין תפריטים לבחור מהם',
			'groceryList.allPlansHint' => 'הרשימה מרוכזת מכל התפריטים',
			'groceryList.selectPlansTitle' => 'אילו תפריטים ייכנסו לרשימה?',
			'groceryList.applySelection' => 'עדכון הרשימה',
			'groceryList.selectAllPlans' => 'כל התפריטים',
			'groceryList.myLists' => 'הרשימות שלי',
			'groceryList.listsCount' => ({required Object count}) => '${count} רשימות',
			'groceryList.oneList' => 'רשימה אחת',
			'groceryList.newList' => 'רשימה חדשה',
			'groceryList.newListTitle' => 'רשימת קניות חדשה',
			'groceryList.listName' => 'שם הרשימה',
			'groceryList.defaultListName' => 'רשימת קניות',
			'groceryList.fromPlans' => 'מהתפריטים',
			'groceryList.fromPlansHint' => 'מרכזת את המתכונים שבתפריטים שלך',
			'groceryList.fromRecipe' => 'ממתכון',
			'groceryList.fromRecipeHint' => 'המצרכים של מתכון אחד',
			'groceryList.emptyList' => 'רשימה ריקה',
			'groceryList.emptyListHint' => 'מוסיפים את הפריטים ידנית',
			'groceryList.sourcePlans' => 'מהתפריטים',
			'groceryList.sourceRecipe' => ({required Object title}) => 'מהמתכון "${title}"',
			'groceryList.sourceManual' => 'רשימה ידנית',
			'groceryList.renameList' => 'שינוי שם הרשימה',
			'groceryList.deleteList' => 'מחיקת הרשימה',
			'groceryList.deleteListConfirm' => ({required Object name}) => '"${name}" וכל הפריטים שבה יימחקו.',
			'groceryList.progress' => ({required Object checked, required Object total}) => '${checked}/${total}',
			'groceryList.servings' => 'מנות',
			'groceryList.timesOver' => 'כמות',
			'groceryList.scaleValue' => ({required Object value}) => '×${value}',
			'groceryList.rebuildFromRecipe' => 'בנייה מחדש מהמתכון',
			'groceryList.createFromRecipe' => 'יצירת רשימת קניות',
			'groceryList.createList' => 'יצירת הרשימה',
			'groceryList.recipeListTitle' => 'רשימת קניות ממתכון',
			'groceryList.recipeListHint' => 'המצרכים של המתכון, לפי הכמות שמכינים',
			'groceryList.listCreated' => ({required Object name}) => 'הרשימה "${name}" נוצרה',
			'groceryList.openList' => 'פתיחת הרשימה',
			'groceryList.stayHere' => 'להישאר כאן',
			'groceryList.noIngredients' => 'אין במתכון הזה מצרכים לקנות',
			'groceryList.addFirstItem' => 'הוספת פריט',
			'groceryList.leaveListConfirm' => ({required Object name}) => 'לצאת מהשיתוף של הרשימה "${name}"? היא תוסר מהרשימות שלך.',
			'receipt.title' => 'סריקת קבלה',
			'receipt.subtitle' => 'צלמו קבלה או העלו PDF, והמחירים יישמרו לרשימת הקניות',
			'receipt.camera' => 'צילום קבלה',
			'receipt.cameraHint' => 'קבלה ארוכה? צלמו כמה תמונות, נאחד אותן',
			'receipt.gallery' => 'בחירה מהגלריה',
			'receipt.pdf' => 'קובץ PDF',
			'receipt.addPhoto' => 'תמונה נוספת',
			'receipt.scan' => 'סרוק',
			'receipt.scanning' => 'קורא את הקבלה…',
			'receipt.pagesCount' => ({required Object count}) => '${count} תמונות',
			'receipt.scanFailed' => 'לא הצלחנו לקרוא את הקבלה. נסו תמונה חדה יותר או PDF.',
			'receipt.reviewTitle' => 'מה נקלט',
			'receipt.reviewSubtitle' => 'אפשר לתקן שמות ומחירים לפני השמירה',
			'receipt.store' => 'חנות',
			'receipt.date' => 'תאריך',
			'receipt.receiptTotal' => 'סה״כ בקבלה',
			'receipt.itemsTotal' => 'סה״כ מוצרים שנקלטו',
			'receipt.captured' => 'מוצרים שנקלטו',
			'receipt.capturedCount' => ({required Object count}) => '${count} מוצרים',
			'receipt.unreadable' => 'לא הצלחנו לקלוט',
			'receipt.unreadableHint' => 'הערות על שורות שלא הצלחנו לקרוא. אפשר להוסיף אותן ידנית למטה.',
			'receipt.addLine' => 'הוספת מוצר',
			'receipt.itemName' => 'שם המוצר',
			'receipt.price' => 'מחיר ליחידה',
			'receipt.quantity' => 'כמות',
			'receipt.removeLine' => 'הסרת שורה',
			'receipt.shareToggle' => 'שיתוף המחירים עם הקהילה',
			'receipt.shareHint' => 'רק שמות מוצרים ומחירים. בלי החנות, התאריך או מי קנה.',
			'receipt.save' => 'שמירת המחירים',
			'receipt.saved' => ({required Object count}) => '${count} מחירים נשמרו',
			'receipt.savedShared' => ({required Object count}) => '${count} מחירים נשמרו ושותפו',
			'receipt.nothingToSave' => 'אין מוצרים לשמירה',
			'receipt.estimated' => 'משוער לפי נתוני עבר',
			'receipt.estimatedTotal' => 'עלות משוערת',
			'receipt.noData' => 'אין נתונים',
			'receipt.fromReceipt' => 'מהקבלה שלך',
			'receipt.fromCommunity' => 'ממוצע המשתמשים',
			'receipt.unpriced' => ({required Object count}) => '${count} פריטים בלי מחיר',
			'receipt.priceBook' => 'המחירים שלי',
			'receipt.priceBookEmpty' => 'עוד לא נסרקו קבלות. סרקו את הראשונה כדי לראות כמה עולה הקנייה.',
			'receipt.deleteRecord' => 'מחיקת מחיר',
			'receipt.cameraGuide' => 'הכניסו את הקבלה למלבן',
			'receipt.cameraHold' => 'החזיקו יציב…',
			'receipt.cameraCaptured' => 'נקלט!',
			'receipt.cameraUnavailable' => 'אין גישה למצלמה',
			'receipt.perUnit' => 'ליח׳',
			'receipt.perKg' => 'לק״ג',
			'receipt.perLiter' => 'לליטר',
			'receipt.printedAs' => ({required Object name}) => 'מודפס: ${name}',
			'receipt.receipts' => 'קבלות',
			'receipt.prices' => 'מחירים',
			'receipt.sortBy' => 'מיון',
			'receipt.sortDate' => 'תאריך',
			'receipt.sortStore' => 'חנות',
			'receipt.sortTotal' => 'סכום',
			'receipt.sortName' => 'שם',
			'receipt.noReceipts' => 'עוד אין קבלות שמורות',
			'receipt.noPrices' => 'עוד אין מחירים שמורים',
			'receipt.deleteReceipt' => 'מחיקת הקבלה',
			'receipt.deleteReceiptBody' => 'הקבלה וכל המחירים שנקלטו ממנה יימחקו.',
			'receipt.addPrice' => 'הוספת מחיר',
			'receipt.addPriceHint' => 'בלי קבלה: מחיר ששילמתם או שאתם יודעים',
			'receipt.manualSource' => 'הוזן ידנית',
			'receipt.lastPaid' => 'שולם לאחרונה',
			'receipt.priceSaved' => 'המחיר נשמר',
			'receipt.itemsInReceipt' => ({required Object count}) => '${count} מוצרים',
			'receipt.search' => 'חיפוש מוצר',
			'receipt.viewImage' => 'תמונת הקבלה',
			'receipt.noImage' => 'לא נשמרה תמונה לקבלה הזו',
			'receipt.pdfFile' => 'קבלה מקובץ PDF',
			'receipt.filter' => 'סינון',
			'receipt.filterAll' => 'הכל',
			'receipt.periodAll' => 'כל התקופה',
			'receipt.period30' => '30 יום',
			'receipt.period90' => '90 יום',
			'receipt.sourceReceipt' => 'מקבלות',
			'receipt.sourceManual' => 'הוזנו ידנית',
			'receipt.deleteProduct' => 'מחיקת המוצר',
			'receipt.deleteProductBody' => 'כל המחירים שנשמרו למוצר הזה יימחקו.',
			'receipt.pickFromPrices' => 'בחירה מהמחירים שלי',
			'receipt.pickerTitle' => 'המוצרים שלי',
			'receipt.existingPrice' => ({required Object price}) => 'כבר קיים: ${price}',
			'receipt.keepNew' => 'המחיר החדש',
			'receipt.keepOld' => 'המחיר הישן',
			'receipt.keepAverage' => 'ממוצע',
			'receipt.deleteReceiptOnly' => 'מחיקת הקבלה בלבד',
			'receipt.deleteReceiptOnlyHint' => 'המחירים שנקלטו ממנה נשארים',
			'receipt.deleteReceiptAndPrices' => 'מחיקת הקבלה והמחירים שלה',
			'receipt.deleteAll' => 'מחיקת כל המחירים',
			'receipt.deleteAllBody' => 'כל המחירים, הקבלות והבחירות יימחקו. אי אפשר לבטל.',
			'receipt.pricingTitle' => 'איזה מחיר להשתמש בו',
			'receipt.pricingLatest' => 'האחרון',
			'receipt.pricingAverage' => 'ממוצע של הכל',
			'receipt.pricingStore' => 'לפי סופר',
			'receipt.pricingReceipts' => 'קבלות נבחרות',
			'receipt.pricingActive' => ({required Object price}) => 'בשימוש: ${price}',
			'receipt.history' => 'היסטוריית מחירים',
			'receipt.noStore' => 'ללא חנות',
			'receipt.pricingSaved' => 'הבחירה נשמרה',
			'receipt.renameStore' => 'שינוי שם החנות',
			'receipt.storeName' => 'שם החנות',
			'receipt.allStores' => 'כל החנויות',
			'receipt.applyFilters' => 'החל סינון',
			'receipt.clearFilters' => 'ניקוי',
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
			'image.generate' => 'צור תמונה ב-AI',
			'image.generating' => 'יוצר תמונה… זה לוקח כמה שניות',
			'image.generateFailed' => 'יצירת התמונה נכשלה, נסו שוב',
			'image.coverTitle' => 'איזו כריכה ליצור?',
			'image.coverHint' => 'בחרו קטגוריה, כתבו משהו, או שניהם',
			'image.coverFreeText' => 'טקסט חופשי, למשל: המבורגר',
			'image.coverRequired' => 'צריך לבחור קטגוריה או לכתוב משהו',
			'image.coverGenerate' => 'צור כריכה',
			'image.themeKids' => 'ילדים',
			'image.themeHealthy' => 'בריא',
			'image.themeIndulgent' => 'שחיתות',
			'image.themeSweets' => 'מתוקים ואפייה',
			'image.themeMeat' => 'בשרים וגריל',
			'image.themeVegan' => 'טבעוני',
			'image.themeHolidays' => 'חגים',
			'image.themeQuick' => 'מהיר ופשוט',
			'image.webSearch' => 'חיפוש תמונה בגוגל',
			'image.webSearchTitle' => 'חיפוש תמונה',
			'image.webSearchHint' => 'מה לחפש? למשל: קובה סלק',
			'image.webSearchEmpty' => 'לא נמצאו תמונות, נסו ניסוח אחר',
			'image.webSearchFailed' => 'החיפוש נכשל, נסו שוב',
			'image.webSearchUnavailable' => 'חיפוש התמונות לא זמין כרגע',
			'image.webSearchEnd' => 'אלה כל התוצאות',
			'image.webSearchDownloadFailed' => 'לא הצלחנו להוריד את התמונה, נסו אחרת',
			'nav.library' => 'ספרייה',
			'nav.recipes' => 'מתכונים',
			'nav.mealPlan' => 'תפריטים',
			'nav.groceries' => 'קניות',
			'nav.settings' => 'הגדרות',
			'nav.community' => 'קהילה',
			'update.forcedTitle' => 'נדרש עדכון',
			'update.forcedBody' => ({required Object version}) => 'הגרסה הזו של EasyPlate כבר לא נתמכת. עדכנו לגרסה ${version} כדי להמשיך.',
			'update.optionalTitle' => 'יש גרסה חדשה',
			'update.optionalBody' => ({required Object version}) => 'גרסה ${version} של EasyPlate כבר בחנות, עם השיפורים האחרונים.',
			'update.updateNow' => 'עדכון עכשיו',
			'update.later' => 'דלג',
			'ads.badge' => 'מודעה',
			'ads.freeViewsLeft' => ({required Object count}) => 'נשארו לך ${count} מתכונים חופשיים להיום',
			'ads.rewardedViewsLeft' => ({required Object count}) => 'נותרו ${count} פתיחות עם סרטון קצר להיום',
			'ads.sharedQuotaReached' => 'הגעת למכסה היומית של מתכונים משותפים. המכסה תתאפס מחר!',
			'ads.unlockRecipeTitle' => 'פתיחת מתכון משותף',
			'ads.unlockRecipeMessage' => ({required Object count}) => 'צפה בסרטון קצר כדי לפתוח מתכון זה (נשארו עוד ${count} להיום)',
			'ads.aiQuotaLeft' => ({required Object remaining, required Object total}) => 'נשארו לך ${remaining}/${total} חילוצי AI להיום',
			'ads.aiQuotaReached' => 'הגעת למכסה היומית של חילוצי AI. האפשרות תיפתח מחר!',
			'ads.aiLockedHint' => 'חילוץ מקישור דורש צפייה בסרטון קצר',
			'ads.unlockAiTitle' => 'חילוץ מתכון עם AI',
			'ads.unlockAiMessage' => ({required Object count}) => 'צפה בסרטון קצר כדי לחלץ את המתכון מהקישור (נשארו עוד ${count} להיום)',
			'ads.watchVideo' => 'צפייה בסרטון',
			'ads.parseWithVideo' => 'צפייה בסרטון וניתוח',
			'ads.blockedForToday' => 'נחסם להיום',
			'ads.loadingVideo' => 'טוען סרטון...',
			'ads.videoNotCompleted' => 'הסרטון לא הושלם, המתכון נשאר נעול',
			'ads.videoUnavailable' => 'אין סרטון זמין כרגע, נסו שוב בעוד רגע',
			'premium.title' => 'איזי-פלייט פרימיום',
			'premium.headline' => 'בלי מודעות, בלי מכסות',
			'premium.subtitle' => 'כל מה שאיזי-פלייט יודעת לעשות, בלי לחכות למחר.',
			'premium.benefitNoAds' => 'בלי מודעות בפידים של הקהילה',
			'premium.benefitShared' => 'מתכונים משותפים ללא הגבלה יומית',
			'premium.benefitAi' => ({required Object count}) => 'חילוץ מתכונים עם AI מכל קישור, עד ${count} ביום',
			'premium.periodWeekly' => 'שבועי',
			'premium.periodMonthly' => 'חודשי',
			'premium.periodTwoMonth' => 'דו-חודשי',
			'premium.periodThreeMonth' => 'רבעוני',
			'premium.periodSixMonth' => 'חצי-שנתי',
			'premium.periodAnnual' => 'שנתי',
			'premium.periodLifetime' => 'לכל החיים',
			'premium.bestValue' => 'הכי משתלם',
			'premium.subscribeFor' => ({required Object price}) => 'הרשמה למנוי ב-${price}',
			'premium.buyFor' => ({required Object price}) => 'רכישה ב-${price}',
			'premium.restore' => 'שחזור רכישות',
			'premium.restored' => 'המנוי שוחזר בהצלחה',
			'premium.nothingToRestore' => 'לא נמצאו רכישות לשחזור',
			'premium.activeTitle' => 'פרימיום פעיל',
			'premium.activeBody' => 'תודה! המודעות והמכסות היומיות כבויות בחשבון הזה.',
			'premium.manage' => 'ניהול המנוי',
			'premium.cancel' => 'ביטול המנוי',
			'premium.cancelNote' => 'הביטול מפסיק את החידוש האוטומטי. הפרימיום נשאר פעיל עד סוף התקופה ששולמה, ללא החזר כספי.',
			'premium.unavailable' => 'המנוי אינו זמין כרגע. נסו שוב מאוחר יותר.',
			'premium.purchaseFailed' => 'הרכישה לא הושלמה',
			'premium.purchased' => 'ברוכים הבאים לפרימיום!',
			'premium.legal' => 'המנוי מתחדש אוטומטית בסוף כל תקופה, אלא אם בוטל לפחות 24 שעות לפני סיומה. החיוב מתבצע דרך חשבון החנות שלך, וניתן לנהל או לבטל אותו בהגדרות החנות.',
			'premium.terms' => 'תנאי שימוש',
			'premium.privacy' => 'מדיניות פרטיות',
			'premium.startFor' => ({required Object price}) => 'מתחילים ב-${price}',
			'premium.startFree' => 'מתחילים בחינם',
			'premium.free' => 'חינם',
			'premium.introDays' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'ליום הראשון', other: 'ל-${n} הימים הראשונים', ), 
			'premium.introWeeks' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'לשבוע הראשון', other: 'ל-${n} השבועות הראשונים', ), 
			'premium.introMonths' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'לחודש הראשון', other: 'ל-${n} החודשים הראשונים', ), 
			'premium.introYears' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('he'))(n, one: 'לשנה הראשונה', other: 'ל-${n} השנים הראשונות', ), 
			'premium.introPaidTerms' => ({required Object price, required Object span, required Object then}) => '${price} ${span}, ולאחר מכן ${then}. המחיר מתעדכן אוטומטית.',
			'premium.introFreeTerms' => ({required Object span, required Object then}) => 'חינם ${span}, ולאחר מכן ${then}. החיוב מתחיל אוטומטית.',
			'premium.redeem' => 'יש לי קוד קופון',
			'premium.redeemTitle' => 'קוד קופון',
			'premium.redeemHint' => 'הקלידו את הקוד שקיבלתם',
			'premium.redeemConfirm' => 'מימוש בחנות',
			'premium.perWeekly' => 'לשבוע',
			'premium.perMonthly' => 'לחודש',
			'premium.perTwoMonth' => 'לחודשיים',
			'premium.perThreeMonth' => 'ל-3 חודשים',
			'premium.perSixMonth' => 'ל-6 חודשים',
			'premium.perAnnual' => 'לשנה',
			'premium.tierPro' => 'Pro',
			'premium.tierDuo' => 'Pro Duo',
			'premium.tierFamily' => 'Pro Family',
			'premium.tierProHint' => 'חשבון אחד',
			'premium.tierDuoHint' => '2 חשבונות, הכל משתקף',
			'premium.tierFamilyHint' => 'עד 6 חשבונות, הכל משתקף',
			'premium.benefitHousehold' => ({required Object n}) => 'חשבון משותף ל-${n} אנשים: מתכונים, תפריטים ורשימות מסונכרנים',
			'walkthrough.title' => 'הדרכה',
			'walkthrough.start' => 'הפעל הדרכה',
			'walkthrough.startHint' => 'סיור מודרך בכל הפעולות באפליקציה, צעד אחר צעד',
			'walkthrough.startFull' => 'התחל הדרכה מלאה',
			'walkthrough.focused' => 'הצג הנחיה ממוקדת',
			'walkthrough.next' => 'הבא',
			'walkthrough.finish' => 'סיום',
			'walkthrough.skipStep' => 'דלג על שלב',
			'walkthrough.close' => 'סגור הדרכה',
			'walkthrough.stepOf' => ({required Object current, required Object total}) => 'שלב ${current} מתוך ${total}',
			'walkthrough.tapHint' => 'לחצו על האזור המודגש, או על ״הבא״',
			'walkthrough.bookTitle' => 'מדריך EasyPlate',
			'walkthrough.bookSubtitle' => 'כל מה שאפשר לעשות באפליקציה, פרק אחר פרק. הדוגמאות בספר לא נשמרות; בסיור החי עושים את הפעולות באמת, עם שדות שכבר מולאו.',
			'walkthrough.contents' => 'תוכן עניינים',
			'walkthrough.chapter' => ({required Object number}) => 'פרק ${number}',
			'walkthrough.backToContents' => 'לתוכן העניינים',
			'walkthrough.stepsTitle' => 'השלבים',
			'walkthrough.welcomeTitle' => 'ברוכים הבאים ל-EasyPlate',
			'walkthrough.welcomeBody' => 'נעבור יחד על הפעולות העיקריות ונעשה אותן באמת: השדות כבר מולאו בשבילכם. אפשר לדלג על כל שלב, או לסגור ולהפעיל שוב ממסך התמיכה.',
			'walkthrough.topics.addRecipe.title' => 'הוספת מתכון',
			'walkthrough.topics.addRecipe.summary' => 'מכניסים מתכון מכל מקור, וה-AI מסדר אותו לפורמט אחיד: מצרכים, כמויות, שלבים, תגיות, מנות וערכים תזונתיים.',
			'walkthrough.topics.addRecipe.s1' => 'לחצו על כפתור הניצוץ ליד הכותרת כדי להוסיף מתכון.',
			'walkthrough.topics.addRecipe.s2' => 'בוחרים מקור: טקסט מודבק, חיפוש באינטרנט, קישור לאתר, סרטון מטיקטוק, אינסטגרם, יוטיוב או פייסבוק, בקשה חופשית מ-AI, או כתיבה ידנית.',
			'walkthrough.topics.addRecipe.s3' => 'מילאנו כאן מתכון לדוגמה, כמו שמדביקים אותו. הכפתור שמתחת שולח אותו ל-AI, שמחזיר מתכון מסודר לבדיקה, עריכה ושמירה. הניתוח לוקח עד חצי דקה, אז השאירו אותו לאחרי הסיור.',
			'walkthrough.topics.myRecipes.title' => 'המתכונים שלי ושמורים',
			'walkthrough.topics.myRecipes.summary' => 'המתכונים שכתבתם ואלה ששמרתם מהקהילה, עם חיפוש וסינון לפי נושאים.',
			'walkthrough.topics.myRecipes.s1' => 'כאן עוברים בין המתכונים שכתבתם לבין מתכונים ששמרתם מהקהילה.',
			'walkthrough.topics.myRecipes.s2' => 'חיפוש לפי שם, וסינון לפי נושאים: בשרי, חלבי, צמחוני, טבעוני, כשר, ללא גלוטן ואלרגיה. בכל מתכון מסומנים גם האלרגנים שבו.',
			'walkthrough.topics.library.title' => 'ספרי מתכונים',
			'walkthrough.topics.library.summary' => 'מסדרים מתכונים בספרים עם תוכן עניינים, כריכה ודפדוף, ומשתפים ספר שלם עם חשבון אחר.',
			'walkthrough.topics.library.s1' => 'לחצו על ״ספרייה״ כדי לעבור לספרים.',
			'walkthrough.topics.library.s2' => 'לחצו על הפלוס כדי ליצור ספר חדש.',
			'walkthrough.topics.library.s3' => 'שם הספר כבר מולא: ״הדרכה״. אפשר ללחוץ על השדה ולשנות אותו, ואז להמשיך.',
			'walkthrough.topics.library.s4' => 'לחצו ״שמור״ כדי ליצור את הספר.',
			'walkthrough.topics.library.s5' => 'בוחרים צבע לשדרה, שמבדיל בין הספרים על המדף, ולוחצים ״שמור״. הספר ייפתח מיד.',
			'walkthrough.topics.library.s6' => 'זהו הספר שיצרתם. מכאן מוסיפים אליו מתכונים, ובספר מדפדפים בין העמודים וקופצים מתוכן העניינים. לחיצה ארוכה על ספר במדף פותחת שיתוף, כריכה, שינוי שם ומחיקה.',
			'walkthrough.topics.mealPlan.title' => 'תפריט שבועי ותזונה',
			'walkthrough.topics.mealPlan.summary' => 'תוכנית ארוחות לכל השבוע עם סיכום תזונתי לכל יום, שמזינה את רשימת הקניות.',
			'walkthrough.topics.mealPlan.s1' => 'לחצו על ״תפריטים״ לתכנון הארוחות.',
			'walkthrough.topics.mealPlan.s2' => 'לחצו כאן כדי ליצור תוכנית שבועית.',
			'walkthrough.topics.mealPlan.s3' => 'שם התוכנית כבר מולא. למטה בוחרים תבנית: חופשית, שלוש ארוחות ביום או שש.',
			'walkthrough.topics.mealPlan.s4' => 'לחצו ״שמור״ כדי ליצור את התוכנית.',
			'walkthrough.topics.mealPlan.s5' => 'לכל יום משבצים מתכונים בארוחות. כרטיס התזונה מסכם קלוריות, חלבון, פחמימות ושומן לפי המנות. לחצו על הגרף כדי לפתוח את הדשבורד השבועי.',
			'walkthrough.topics.mealPlan.s6' => 'הדשבורד: ממוצע יומי, סך שבועי, עמודה לכל יום וחלוקת המאקרו. הערכים מוערכים על ידי ה-AI לכל מתכון, לפי מנה.',
			'walkthrough.topics.mealPlan.s7' => 'כפתור השיתוף שולח את התוכנית לחשבון אחר, כעורך או כצופה. עריכה בצד אחד מגיעה לכולם.',
			'walkthrough.topics.groceries.title' => 'רשימת קניות ומחירים',
			'walkthrough.topics.groceries.summary' => 'רשימה שנבנית מהתפריט, עם סימון מה כבר נאסף, הערכת עלות מהקבלות שלכם, ושיתוף עם מי שקונה איתכם.',
			'walkthrough.topics.groceries.s1' => 'לחצו על ״קניות״.',
			'walkthrough.topics.groceries.s2' => 'רענון בונה מחדש את הרשימה מכל המתכונים בתפריט השבועי.',
			'walkthrough.topics.groceries.s3' => 'לחצו על הפלוס כדי להוסיף פריט ביד.',
			'walkthrough.topics.groceries.s4' => 'שם הפריט כבר מולא. בוחרים כמות ויחידה, או מתחילים ממוצר שהקבלות שלכם כבר מכירות.',
			'walkthrough.topics.groceries.s5' => 'לחצו ״הוסף״ והפריט ייכנס לרשימה.',
			'walkthrough.topics.groceries.s6' => 'לחצו כאן כדי לפתוח את ספר המחירים.',
			'walkthrough.topics.groceries.s7' => 'סורקים קבלה, והמחיר של כל מוצר נשמר. מכאן רשימת הקניות מקבלת הערכת עלות, ומחירים חציוניים מהקהילה משלימים מה שעוד לא קניתם.',
			'walkthrough.topics.groceries.shefi' => 'שאלו את שפי על הרשימה הזו: מה חסר לארוחה, מה אפשר להחליף, או להוסיף פריטים בדיבור.',
			'walkthrough.topics.community.title' => 'קהילה',
			'walkthrough.topics.community.summary' => 'מתכונים משותפים של כל המשתמשים, ופורום לשאלות ותשובות.',
			'walkthrough.topics.community.s1' => 'לחצו על ״קהילה״.',
			'walkthrough.topics.community.s2' => 'מתכונים משותפים ופורום. אפשר לעשות לייק למתכון, לשרשור ולתגובה, לשמור מתכון אצלכם, ולצרף מתכון לתגובה בפורום.',
			'walkthrough.topics.community.s3' => 'כפתור השיתוף מפרסם מתכון משלכם לקהילה.',
			'walkthrough.topics.account.title' => 'חשבון, פרימיום והגדרות',
			'walkthrough.topics.account.summary' => 'התראות על הזמנות לשיתוף, והחשבון עם פרימיום, גישה משותפת, הגדרות ומצב תצוגה.',
			'walkthrough.topics.account.s1' => 'התראות: הזמנות לשיתוף ספרים ותפריטים, ועדכונים.',
			'walkthrough.topics.account.s2' => 'לחצו על התמונה כדי לפתוח את החשבון.',
			'walkthrough.topics.account.s3' => 'פרימיום: ניתוחי AI ללא הגבלה יומית וללא פרסומות. חשבון חינמי מקבל מכסה יומית, ואפשר להרחיב אותה בצפייה בסרטון.',
			'walkthrough.topics.account.s4' => 'גישה משותפת: מי חולק איתכם ספרים, תפריטים ורשימות קניות, ומה שיתפתם אתם.',
			'walkthrough.topics.account.s5' => 'לחצו על ״הגדרות״.',
			'walkthrough.topics.account.s6' => 'מצב תצוגה: בהיר, כהה או לפי המכשיר. בהגדרות גם שפה, העדפות תזונה ואלרגנים. את ההדרכה הזו מפעילים שוב ממסך התמיכה שבחשבון.',
			'walkthrough.topics.account.shefi' => 'שפי, העוזר החכם: הכפתור הצף הזה פותח שיחה. שואלים בכתב או בקול, ושפי עונה, מוסיף לתפריט, בונה רשימה או מפעיל מצב בישול. בתוך מתכון, תפריט או רשימה יש כפתור ״שאלו את שפי״ שמדבר רק על הפריט הזה.',
			'walkthrough.topics.settings.title' => 'הגדרות והעדפות',
			'walkthrough.topics.settings.summary' => 'כל שורה בהגדרות ובהעדפות: פרופיל, שיתוף, התראות, שפה, מראה, מחיקת חשבון, יום קניות, מחירים, תזונה וספרים.',
			'walkthrough.topics.settings.s1' => 'לחצו על ״הגדרות״: כאן החשבון והאפליקציה.',
			'walkthrough.topics.settings.s2' => 'פרופיל: השם והתמונה שהשותפים שלכם רואים, ודרכי ההתחברות המקושרות.',
			'walkthrough.topics.settings.s3' => 'גישה משותפת: מי חולק איתכם מתכונים, ספרים, תפריטים ורשימות, ומה שיתפתם אתם. מכאן גם מצטרפים בקוד או ב-QR.',
			'walkthrough.topics.settings.s4' => 'לחצו על ״הגדרות התראות״.',
			'walkthrough.topics.settings.s5' => 'התראות פוש: המתג הראשי. כשהוא כבוי שום דבר לא נשלח; למטה בוחרים מה כן: תגובות, הזמנות, עדכונים והודעות מהצוות.',
			'walkthrough.topics.settings.s6' => 'תזכורות יום הקניות: מתי להזכיר לכם לפני הקנייה. מתוזמנות במכשיר, בלי קשר לפוש.',
			'walkthrough.topics.settings.s7' => 'שפה: החלפה מתרגמת גם את המתכונים, הספרים, התפריטים והרשימות שלכם.',
			'walkthrough.topics.settings.s8' => 'מראה: בהיר, כהה או לפי המכשיר. הבחירה נשמרת בחשבון ועוברת איתכם למכשיר הבא.',
			'walkthrough.topics.settings.s9' => 'מחיקת החשבון: מוחקת לצמיתות את החשבון וכל מה שבו, אחרי אישור. מנוי בחנות מבטלים בנפרד.',
			'walkthrough.topics.settings.s10' => 'חזרה לחשבון: לחצו על ״העדפות״, איך האפליקציה מתנהגת בשבילכם.',
			'walkthrough.topics.settings.s11' => 'יום הקניות: היום שסביבו נבנית רשימת הקניות ומתוזמנות התזכורות.',
			'walkthrough.topics.settings.s12' => 'מחירי קהילה: כשדולק, המחירים מהקבלות שלכם מצטרפים באופן אנונימי לממוצעים, ושורות שלא קניתם מוערכות לפיהם.',
			'walkthrough.topics.settings.s13' => 'העדפות תזונה ואלרגנים: מסמנים כאן, והאפליקציה מדגישה אותם במתכונים ובמתכונים משותפים.',
			'walkthrough.topics.settings.s14' => 'מעבר מהיר בספר: קפיצה לעמוד רחוק מדפדפת דף אחד בלבד. בכיבוי מדפדפים דרך כל העמודים שבדרך.',
			'walkthrough.topics.settings.s15' => 'צלילים: אפקטים קוליים בדפדוף ובפעולות. אפשר לכבות.',
			'walkthrough.demo.bookTitle' => 'הדרכה',
			'walkthrough.demo.planName' => 'תפריט הדרכה',
			'walkthrough.demo.mealName' => 'ארוחת ערב',
			'walkthrough.demo.groceryItem' => 'עגבניות',
			'walkthrough.demo.recipeText' => 'שקשוקה ירושלמית\n\nמצרכים:\n400 גרם עגבניות מרוסקות\n4 ביצים\nבצל אחד\n2 כפות שמן זית\nכפית פפריקה מתוקה\nקורט מלח\n\nהכנה:\n1. מחממים שמן זית במחבת ומטגנים את הבצל עד להזהבה.\n2. מוסיפים את העגבניות והפפריקה ומבשלים 10 דקות על אש נמוכה.\n3. שוברים את הביצים לתוך הרוטב, מכסים ומבשלים עד שהחלבון מתקשה.',
			'walkthrough.demoRecipes' => 'מתכונים לדוגמה',
			'walkthrough.demoRecipesHint' => 'כך נראים מתכונים באפליקציה. לחצו על מתכון כדי לראות את העמוד המלא: זמנים, נושאים, אלרגנים, מצרכים ושלבים.',
			'walkthrough.demoBooks' => 'ספרים לדוגמה',
			'walkthrough.demoBooksHint' => 'כך נראה ספר מתכונים. לחצו על ספר כדי לפתוח אותו, לדפדף בין העמודים ולקפוץ מתוכן העניינים.',
			'walkthrough.demoOnly' => 'דוגמה בלבד, לא נשמר',
			'feedback.title' => 'דיווח והצעות',
			'feedback.subtitle' => 'מצאתם תקלה? יש רעיון? כתבו לנו כאן, ונקרא כל פנייה.',
			'feedback.bug' => 'תקלה (באג)',
			'feedback.suggestion' => 'הצעה לשיפור',
			'feedback.bugHint' => 'תארו את התקלה: מה עשיתם, מה קרה ומה ציפיתם שיקרה...',
			'feedback.suggestionHint' => 'ספרו לנו מה הייתם רוצים שיהיה באפליקציה, ואיך זה יעזור לכם...',
			'feedback.send' => 'שליחה',
			'feedback.sent' => 'תודה! הפנייה נשלחה.',
			'feedback.failed' => 'השליחה נכשלה, נסו שוב מאוחר יותר',
			'feedback.admin' => 'ניהול פניות',
			'feedback.all' => 'הכל',
			'feedback.bugs' => 'תקלות',
			'feedback.suggestions' => 'הצעות',
			'feedback.none' => 'אין פניות עדיין',
			'feedback.version' => ({required Object version}) => 'גרסה ${version}',
			'feedback.notAllowed' => 'המסך הזה זמין למנהל בלבד',
			'adminBilling.title' => 'מנויים',
			'adminBilling.all' => 'הכל',
			'adminBilling.paying' => 'משלמים',
			'adminBilling.problems' => 'בעיות',
			'adminBilling.searchHint' => 'חיפוש לפי שם, מייל, טלפון או uid',
			'adminBilling.none' => 'אין חשבונות להצגה',
			'adminBilling.premium' => 'פרימיום',
			'adminBilling.free' => 'חינמי',
			'adminBilling.untilDate' => ({required Object date}) => 'עד ${date}',
			'adminBilling.adminLocked' => 'הוגדר ידנית',
			'adminBilling.viaRevenueCat' => 'מ-RevenueCat',
			'adminBilling.sandbox' => 'Sandbox',
			'adminBilling.lastEvent' => ({required Object type, required Object date}) => '${type} · ${date}',
			_ => null,
		} ?? switch (path) {
			'adminBilling.product' => ({required Object id}) => 'מוצר: ${id}',
			'adminBilling.eventsCount' => ({required Object count}) => '${count} אירועים',
			'adminBilling.grant' => 'תן פרימיום',
			'adminBilling.revoke' => 'בטל פרימיום',
			'adminBilling.release' => 'החזר ל-RevenueCat',
			'adminBilling.releaseHint' => 'הוגדר ידנית: האירוע הבא מ-RevenueCat לא ישנה את החשבון עד השחרור.',
			'adminBilling.granted' => 'ניתן פרימיום',
			'adminBilling.revoked' => 'הפרימיום בוטל',
			'adminBilling.released' => 'החשבון חזר לשליטת RevenueCat',
			'adminBilling.revokeConfirm' => ({required Object name}) => 'לבטל את הפרימיום של ${name}?',
			'adminBilling.problemPaidNotPremium' => 'שילם, אבל החשבון לא פרימיום',
			'adminBilling.problemNoEntitlement' => 'הגיעה רכישה בלי ה-entitlement (המוצר לא מחובר ב-RevenueCat)',
			'adminBilling.orphanTitle' => 'רכישות בלי חשבון',
			'adminBilling.orphanBody' => 'קבלות שהגיעו תחת מזהה אנונימי של RevenueCat, בלי משתמש לפתוח לו',
			'adminBilling.summary' => ({required Object premium, required Object problems, required Object total}) => '${premium} פרימיום · ${problems} בעיות · ${total} חשבונות',
			'adminBilling.noEntitlementTag' => 'בלי entitlement',
			'adminDashboard.title' => 'לוח בקרה',
			'adminDashboard.tabDashboard' => 'סקירה',
			'adminDashboard.tabSubscriptions' => 'מנויים',
			'adminDashboard.tabTickets' => 'פניות',
			'adminDashboard.rangeToday' => 'היום',
			'adminDashboard.rangeMonth' => '30 יום',
			'adminDashboard.rangeAll' => 'הכל',
			'adminDashboard.aiCost' => 'עלות AI',
			'adminDashboard.aiCostHint' => 'טוקנים × מחירון',
			'adminDashboard.revenue' => 'הכנסות',
			'adminDashboard.revenueNone' => 'אין תשלומים בטווח',
			'adminDashboard.sandboxNote' => ({required Object count}) => '${count} תשלומי sandbox לא נספרו',
			'adminDashboard.paymentsCount' => ({required Object count}) => '${count} תשלומים',
			'adminDashboard.aiCalls' => 'קריאות AI',
			'adminDashboard.cacheSaved' => ({required Object count}) => '${count} מהמטמון (חינם)',
			'adminDashboard.errorsCount' => ({required Object count}) => '${count} שגיאות',
			'adminDashboard.tokens' => 'טוקנים',
			'adminDashboard.tokensHint' => ({required Object input, required Object output}) => 'קלט ${input} · פלט ${output}',
			'adminDashboard.usersTotal' => 'משתמשים סה"כ',
			'adminDashboard.newUsers' => ({required Object count}) => '${count} חדשים בטווח',
			'adminDashboard.disabledCount' => ({required Object count}) => '${count} חסומים',
			'adminDashboard.premiumUsers' => 'משלמים',
			'adminDashboard.freeCount' => ({required Object count}) => '${count} חינמיים',
			'adminDashboard.freeUsers' => 'חינמיים',
			'adminDashboard.activeUsers' => 'משתמשי AI פעילים',
			'adminDashboard.costPerUser' => 'עלות למשתמש פעיל',
			'adminDashboard.tickets' => 'פניות',
			'adminDashboard.unreadCount' => ({required Object count}) => '${count} חדשות',
			'adminDashboard.chartCost' => 'עלות AI לפי יום',
			'adminDashboard.chartCalls' => 'קריאות AI לפי יום',
			'adminDashboard.chartSignups' => 'הרשמות לפי יום',
			'adminDashboard.chartPlatform' => 'משתמשים לפי פלטפורמה',
			'adminDashboard.chartPlan' => 'חינמי מול משלם',
			'adminDashboard.chartKinds' => 'קריאות לפי פיצ\'ר',
			'adminDashboard.chartModels' => 'עלות לפי מודל',
			'adminDashboard.chartVersions' => 'גרסאות אפליקציה',
			'adminDashboard.platformIos' => 'iOS',
			'adminDashboard.platformAndroid' => 'Android',
			'adminDashboard.platformUnknown' => 'לא ידוע',
			'adminDashboard.noAiUsage' => 'אין שימוש ב-AI בטווח הזה',
			'adminDashboard.unknownModel' => 'לא במחירון',
			'adminDashboard.usersCost' => 'עלות לפי משתמש',
			'adminDashboard.usersCount' => ({required Object count}) => '${count} משתמשים',
			'adminDashboard.searchUser' => 'חיפוש לפי שם, מייל או uid',
			'adminDashboard.showAll' => ({required Object count}) => 'הצגת כל ${count} המשתמשים',
			'adminDashboard.callsCount' => ({required Object count}) => '${count} קריאות',
			'adminDashboard.content' => 'תוכן וקהילה',
			'adminDashboard.sharedRecipes' => 'מתכונים משותפים',
			'adminDashboard.forumPosts' => 'שרשורי פורום',
			'adminDashboard.withPush' => 'מכשירים עם התראות',
			'adminDashboard.cacheEntries' => 'קישורים במטמון',
			'adminDashboard.cacheHits' => 'פגיעות מטמון (קריאות שנחסכו)',
			'adminDashboard.config' => 'הגדרות מרחוק',
			'adminDashboard.environment' => 'סביבה',
			'adminDashboard.prod' => 'Production',
			'adminDashboard.dev' => 'Dev',
			'adminDashboard.adsEnabled' => 'מודעות',
			'adminDashboard.adsFailOpen' => 'פתיחה כשאין מודעה',
			'adminDashboard.on' => 'פעיל',
			'adminDashboard.off' => 'כבוי',
			'adminDashboard.feedInterval' => 'מרווח מודעות בפיד',
			'adminDashboard.quotaSharedFree' => 'צפיות חינם ביום',
			'adminDashboard.quotaSharedRewarded' => 'צפיות בווידאו ביום',
			'adminDashboard.quotaAiRewarded' => 'AI בווידאו ביום',
			'adminDashboard.quotaAiPremium' => 'AI לפרימיום ביום',
			'adminDashboard.minVersion' => 'גרסה מינימלית',
			'adminDashboard.latestVersion' => 'גרסה אחרונה',
			'adminDashboard.thisBuild' => 'הבנייה הזו',
			'adminDashboard.pricing' => 'מחירון טוקנים',
			'adminDashboard.pricingHint' => 'דולר למיליון טוקנים. מחירי ברירת המחדל הם הערכה — כדאי לעדכן לפי המחירון של Google.',
			'adminDashboard.editPricing' => 'עריכת מחירון',
			'adminDashboard.priceInput' => 'קלט',
			'adminDashboard.priceOutput' => 'פלט',
			'adminDashboard.priceCached' => 'קלט מהמטמון',
			'adminDashboard.usdToIls' => 'שער דולר/שקל',
			'adminDashboard.pricingSaved' => 'המחירון נשמר',
			'adminDashboard.loadedAt' => ({required Object date}) => 'עודכן ${date}',
			'adminDashboard.kindText' => 'טקסט',
			'adminDashboard.kindUrl' => 'קישור',
			'adminDashboard.kindSocial' => 'רשת חברתית',
			'adminDashboard.kindSocialVideo' => 'וידאו (שרת)',
			'adminDashboard.kindVideo' => 'וידאו',
			'adminDashboard.kindSearch' => 'חיפוש',
			'adminDashboard.kindImage' => 'תמונה',
			'adminDashboard.kindReceipt' => 'קבלה',
			'adminDashboard.kindNutrition' => 'תזונה',
			'adminDashboard.kindRefine' => 'ליטוש',
			'adminDashboard.kindGenerate' => 'יצירה',
			'adminDashboard.allTime' => 'כל הזמן',
			'adminDashboard.recentCalls' => 'קריאות אחרונות',
			'adminDashboard.noCalls' => 'אין קריאות',
			'adminDashboard.cacheHit' => 'מטמון',
			'adminDashboard.statusOk' => 'תקין',
			'adminDashboard.pushTitle' => 'כותרת (לא חובה)',
			'adminDashboard.pushBody' => 'תוכן ההודעה',
			'adminDashboard.send' => 'שליחה',
			'adminDashboard.blocked' => 'חסומים',
			'adminDashboard.disable' => 'חסימת חשבון',
			'adminDashboard.enable' => 'ביטול חסימה',
			'adminDashboard.blockMessageHint' => 'מה המשתמש יראה כשינסה להתחבר',
			'adminDashboard.disabledDone' => 'החשבון נחסם',
			'adminDashboard.enabledDone' => 'החסימה הוסרה',
			'adminDashboard.deleteAccount' => 'מחיקת חשבון',
			'adminDashboard.deleteAccountConfirm' => ({required Object name}) => 'למחוק את ${name} לצמיתות? המשתמש, המתכונים, הספרים והתפריטים שלו יימחקו ואי אפשר לשחזר.',
			'adminDashboard.deleted' => 'החשבון נמחק',
			'adminDashboard.sendPush' => 'שליחת התראה',
			'adminDashboard.noPush' => 'למכשיר הזה אין טוקן דחיפה — ההודעה תופיע רק במסך ההתראות',
			'adminDashboard.pushSent' => 'ההתראה נשלחה',
			'adminDashboard.sendPushAll' => 'התראה לכל המשתמשים',
			'adminDashboard.broadcastConfirm' => ({required Object count}) => 'לשלוח את ההודעה לכל ${count} המשתמשים?',
			'adminDashboard.broadcastDone' => ({required Object items, required Object sent, required Object failed}) => 'נכתב ל-${items} תיבות · ${sent} דחיפות הצליחו · ${failed} נכשלו',
			'adminDashboard.platformTag' => ({required Object platform, required Object version}) => '${platform} · v${version}',
			'adminDashboard.lastSeen' => ({required Object date}) => 'נראה לאחרונה ${date}',
			'adminDashboard.disabledSince' => ({required Object message}) => 'סיבת החסימה: ${message}',
			'adminDashboard.unread' => 'חדשות',
			'adminDashboard.markAllRead' => 'קראתי הכל',
			'adminDashboard.allRead' => 'כל הפניות סומנו כנקראו',
			'adminDashboard.noUnread' => 'אין פניות חדשות',
			'adminDashboard.deleteTicket' => 'מחיקת פנייה',
			'adminDashboard.deleteTicketConfirm' => ({required Object name}) => 'למחוק את הפנייה של ${name}?',
			'adminDashboard.ticketDeleted' => 'הפנייה נמחקה',
			'adminDashboard.reply' => 'תגובה',
			'adminDashboard.replyHint' => 'התשובה תגיע למשתמש במסך ההתראות (וכדחיפה לטלפון)',
			'adminDashboard.replySent' => 'התשובה נשלחה',
			'adminDashboard.yourReply' => ({required Object date}) => 'התשובה שלך · ${date}',
			'adminDashboard.markRead' => 'סימון כנקרא',
			'adminDashboard.markUnread' => 'סימון כלא נקרא',
			'adminDashboard.pricingSync' => 'סנכרון מחירים מ-Google',
			'adminDashboard.pricingSynced' => ({required Object count}) => '${count} מודלים עודכנו מהמחירון של Google Cloud Billing',
			'adminDashboard.pricingSyncFailed' => ({required Object reason}) => 'הסנכרון נכשל: ${reason}',
			'adminDashboard.pricingSourceCatalog' => ({required Object date}) => 'מקור: Google Cloud Billing (מחירי מחירון אמיתיים) · ${date}',
			'adminDashboard.pricingSourceManual' => ({required Object date}) => 'מקור: הוזן ידנית · ${date}',
			'adminDashboard.pricingSourceDefaults' => 'הערכה בלבד — לחצו על סנכרון כדי למשוך את המחירים האמיתיים מ-Google',
			'adminDashboard.searchPrice' => 'חיפוש Google בהארקה (דולר ל-1,000 שאילתות)',
			'adminDashboard.rateLine' => ({required Object rate, required Object date}) => '${rate} · מתעדכן אוטומטית פעם בשבוע · ${date}',
			'adminDashboard.searchesCount' => ({required Object count}) => '${count} חיפושים',
			'adminDashboard.rangeCustom' => 'בחירה',
			'adminDashboard.customRange' => ({required Object from, required Object to}) => '${from} – ${to} · לחיצה לשינוי',
			'adminDashboard.priceImageOutput' => 'פלט תמונה',
			'adminDashboard.dataSince' => ({required Object date}) => 'הנתונים נאספים מ-${date}. חיובים קודמים בגוגל אינם רשומים כאן.',
			'adminDashboard.grantTitle' => ({required Object name}) => 'פרימיום ל-${name} — לכמה זמן?',
			'adminDashboard.grantForever' => 'לתמיד (עד שאבטל)',
			'adminDashboard.grantWeek' => 'שבוע',
			'adminDashboard.grantMonth' => 'חודש',
			'adminDashboard.grantYear' => 'שנה',
			'adminDashboard.grantRange' => 'טווח תאריכים מדויק',
			'adminDashboard.grantedUntil' => ({required Object date}) => 'ניתן פרימיום עד ${date}',
			'adminDashboard.grantStarts' => ({required Object date}) => 'מתחיל ב-${date}',
			'adminDashboard.tabConfig' => 'תצורה',
			'adminDashboard.releaseSession' => 'ניתוק מהמכשיר המחובר',
			'adminDashboard.releaseSessionDone' => 'המכשיר נותק; המשתמש יתבקש להתחבר מחדש',
			'assistant.title' => 'שפי',
			'assistant.subtitle' => 'הסו-שף שלך: שאלות, תכנון, קניות ובישול',
			'assistant.placeholder' => 'שאלו או אמרו לי מה לעשות…',
			'assistant.send' => 'שליחה',
			'assistant.thinking' => 'חושב…',
			'assistant.working' => ({required Object tool}) => 'מבצע: ${tool}',
			'assistant.welcome' => ({required Object name}) => 'היי ${name}! אני יכול להוסיף לרשימת הקניות, לתכנן את השבוע, לייבא מתכונים מקישורים, להתחיל מצב בישול ועוד. מה עושים?',
			'assistant.error' => 'משהו השתבש. נסו שוב.',
			'assistant.quotaReached' => 'מכסת ה-AI להיום נגמרה. היא נפתחת מחר.',
			'assistant.premiumOnly' => 'שפי הוא חלק מ-EasyPlate Premium',
			'assistant.unlock' => 'לפרימיום',
			'assistant.clear' => 'שיחה חדשה',
			'assistant.openResult' => 'פתיחה',
			'assistant.done' => 'בוצע',
			'assistant.undone' => 'בוטל',
			'assistant.confirmTitle' => 'למחוק?',
			'assistant.confirmBody' => ({required Object what}) => '${what} יימחק.',
			'assistant.notFound' => ({required Object name}) => 'לא מצאתי את "${name}".',
			'assistant.listTitle' => 'רשימת קניות',
			'assistant.addedItems' => ({required Object count}) => 'נוספו ${count} פריטים',
			'assistant.plannedMeal' => ({required Object day, required Object slot}) => 'תוכנן ל${day} · ${slot}',
			'assistant.recipeSaved' => 'המתכון נשמר',
			'assistant.cookStarted' => 'מצב בישול הופעל',
			'assistant.timerSet' => ({required Object n}) => 'טיימר הוגדר לשלב ${n}',
			'assistant.prefSaved' => 'ההעדפה נשמרה',
			'assistant.needsPremium' => 'זה דורש EasyPlate Premium.',
			'assistant.results' => ({required Object count}) => '${count} תוצאות',
			'assistant.suggest.templates.0' => 'תוסיף {food} לרשימת הקניות',
			'assistant.suggest.templates.1' => 'תוסיף {food} ו{food2} לרשימה',
			'assistant.suggest.templates.2' => 'תתכנן {dish} ל{meal} ביום {day}',
			'assistant.suggest.templates.3' => 'תתכנן משהו מהיר ל{meal} ביום {day}',
			'assistant.suggest.templates.4' => 'מה אפשר לבשל מ{food} ו{food2}?',
			'assistant.suggest.templates.5' => 'תייבא מתכון מ{site}',
			'assistant.suggest.templates.6' => 'תמצא מתכון ל{dish} ברשת',
			'assistant.suggest.templates.7' => 'תתחיל לבשל {dish}',
			'assistant.suggest.templates.8' => 'תפעיל טיימר של {n} דקות לשלב 2',
			'assistant.suggest.templates.9' => 'תכין רשימת קניות מ{dish}',
			'assistant.suggest.templates.10' => 'תיצור ספר בשם {book}',
			'assistant.suggest.templates.11' => 'אילו מהמתכונים שלי {diet}?',
			'assistant.suggest.templates.12' => 'תסמן ש{food} נקנה',
			'assistant.suggest.templates.13' => 'תוריד {food} מהרשימה',
			'assistant.suggest.templates.14' => 'תיצור תוכנית לשבוע הבא',
			'assistant.suggest.templates.15' => 'מה מתוכנן ליום {day}?',
			'assistant.suggest.templates.16' => 'תשנה את יום הקניות ל{day}',
			'assistant.suggest.templates.17' => 'תציע ארוחת ערב {diet} ליום {day}',
			'assistant.suggest.templates.18' => 'כמה זמן מבשלים ביצה קשה?',
			'assistant.suggest.templates.19' => 'במה אפשר להחליף {food} במתכון?',
			'assistant.suggest.templates.20' => 'איך שומרים {food}?',
			'assistant.suggest.templates.21' => 'כמה קלוריות יש ב{dish}?',
			'assistant.suggest.templates.22' => 'באיזו טמפרטורה אופים {dish}?',
			'assistant.suggest.templates.23' => 'איך הופכים {dish} לטבעוני?',
			'assistant.suggest.templates.24' => 'כמה זה {n} כפות בגרמים?',
			'assistant.suggest.templates.25' => 'למה ה{dish} שלי יצא יבש?',
			'assistant.suggest.templates.26' => 'מה מתאים בצד ל{dish}?',
			'assistant.suggest.templates.27' => 'אפשר להקפיא {food}?',
			'assistant.suggest.templates.28' => 'איך מסמיכים רוטב?',
			'assistant.suggest.templates.29' => 'רעיון ל{meal} {diet} מהיר?',
			'assistant.suggest.food.0' => 'חלב',
			'assistant.suggest.food.1' => 'ביצים',
			'assistant.suggest.food.2' => 'לחם',
			'assistant.suggest.food.3' => 'עגבניות',
			'assistant.suggest.food.4' => 'בצל',
			'assistant.suggest.food.5' => 'שמן זית',
			'assistant.suggest.food.6' => 'אורז',
			'assistant.suggest.food.7' => 'עוף',
			'assistant.suggest.food.8' => 'לימונים',
			'assistant.suggest.food.9' => 'שום',
			'assistant.suggest.food.10' => 'חמאה',
			'assistant.suggest.food.11' => 'קמח',
			'assistant.suggest.food.12' => 'גבינה',
			'assistant.suggest.food.13' => 'יוגורט',
			'assistant.suggest.food.14' => 'מלפפונים',
			'assistant.suggest.food.15' => 'פסטה',
			'assistant.suggest.dish.0' => 'שקשוקה',
			'assistant.suggest.dish.1' => 'מרק עדשים',
			'assistant.suggest.dish.2' => 'פסטה פסטו',
			'assistant.suggest.dish.3' => 'קארי עוף',
			'assistant.suggest.dish.4' => 'סלמון',
			'assistant.suggest.dish.5' => 'מוקפץ',
			'assistant.suggest.dish.6' => 'פנקייקים',
			'assistant.suggest.dish.7' => 'חומוס',
			'assistant.suggest.dish.8' => 'ירקות בתנור',
			'assistant.suggest.dish.9' => 'לחם בננות',
			'assistant.suggest.day.0' => 'ראשון',
			'assistant.suggest.day.1' => 'שני',
			'assistant.suggest.day.2' => 'שלישי',
			'assistant.suggest.day.3' => 'רביעי',
			'assistant.suggest.day.4' => 'חמישי',
			'assistant.suggest.day.5' => 'שישי',
			'assistant.suggest.day.6' => 'שבת',
			'assistant.suggest.day.7' => 'מחר',
			'assistant.suggest.meal.0' => 'ארוחת בוקר',
			'assistant.suggest.meal.1' => 'ארוחת צהריים',
			'assistant.suggest.meal.2' => 'ארוחת ערב',
			'assistant.suggest.n.0' => '5',
			'assistant.suggest.n.1' => '8',
			'assistant.suggest.n.2' => '10',
			'assistant.suggest.n.3' => '12',
			'assistant.suggest.n.4' => '15',
			'assistant.suggest.n.5' => '20',
			'assistant.suggest.n.6' => '25',
			'assistant.suggest.n.7' => '30',
			'assistant.suggest.site.0' => 'טיקטוק',
			'assistant.suggest.site.1' => 'אינסטגרם',
			'assistant.suggest.site.2' => 'יוטיוב',
			'assistant.suggest.site.3' => 'בלוג',
			'assistant.suggest.book.0' => 'ימי חול',
			'assistant.suggest.book.1' => 'שבת',
			'assistant.suggest.book.2' => 'ילדים',
			'assistant.suggest.book.3' => 'קינוחים',
			'assistant.suggest.diet.0' => 'צמחוניים',
			'assistant.suggest.diet.1' => 'טבעוניים',
			'assistant.suggest.diet.2' => 'ללא גלוטן',
			'assistant.suggest.diet.3' => 'חלביים',
			'assistant.whichList' => 'לאיזו רשימה?',
			'assistant.listCreated' => 'הרשימה נוצרה',
			'assistant.offTopic' => 'אני כאן בשביל בישול, מתכונים, תכנון ארוחות וקניות. שאלו אותי כל דבר שקשור למטבח ואני על זה!',
			'assistant.welcomeAnon' => 'היי! אני יכול להוסיף לרשימת הקניות, לתכנן את השבוע, לייבא מתכונים מקישורים, להתחיל מצב בישול ועוד. מה עושים?',
			'assistant.scopedWelcome' => ({required Object name}) => 'מה תרצו לדעת לגבי "${name}"?',
			'assistant.scopedOffTopic' => ({required Object name}) => 'כאן אני עוזר רק לגבי "${name}". לשאלות אחרות פתחו את שפי מהתפריט.',
			'assistant.askAboutRecipe' => 'שאלו את שפי על המתכון',
			'assistant.askAboutPlan' => 'שאלו את שפי על התפריט',
			'assistant.askAboutList' => 'שאלו את שפי על הרשימה',
			'assistant.listen' => 'דברו אל שפי',
			'assistant.stopListening' => 'עצירת ההאזנה',
			'assistant.speakReplies' => 'הקראת התשובות',
			'assistant.micUnavailable' => 'אי אפשר להשתמש במיקרופון. בדקו את הרשאת המיקרופון וזיהוי הדיבור בהגדרות המכשיר.',
			'assistant.scopedPrompts.recipe.0' => 'מה הערכים התזונתיים למנה?',
			'assistant.scopedPrompts.recipe.1' => 'איך מכינים את זה ל-8 סועדים?',
			'assistant.scopedPrompts.recipe.2' => 'במה אפשר להחליף מצרך שאין לי?',
			'assistant.scopedPrompts.recipe.3' => 'הוסיפו את המתכון לתפריט של מחר',
			'assistant.scopedPrompts.recipe.4' => 'צרו רשימת קניות מהמתכון',
			'assistant.scopedPrompts.mealPlan.0' => 'מה אוכלים היום?',
			'assistant.scopedPrompts.mealPlan.1' => 'הוסיפו ארוחת ערב ליום שלישי',
			'assistant.scopedPrompts.mealPlan.2' => 'מה חסר בתפריט השבוע?',
			'assistant.scopedPrompts.mealPlan.3' => 'צרו רשימת קניות מהתפריט',
			'assistant.scopedPrompts.mealPlan.4' => 'כמה קלוריות ביום רביעי?',
			'assistant.scopedPrompts.groceryList.0' => 'מה נשאר לקנות?',
			'assistant.scopedPrompts.groceryList.1' => 'הוסיפו חלב וביצים',
			'assistant.scopedPrompts.groceryList.2' => 'סמנו את העגבניות כנקנו',
			'assistant.scopedPrompts.groceryList.3' => 'מחקו את מה שכבר קניתי',
			'assistant.scopedPrompts.groceryList.4' => 'כמה זה 2 כוסות קמח בגרמים?',
			'assistant.listening' => 'מקשיב…',
			'assistant.stop' => 'עצירה',
			'assistant.cancelled' => 'בוטל.',
			'shareCode.title' => 'קוד וקישור',
			'shareCode.tabContact' => 'איש קשר',
			'shareCode.tabCode' => 'קוד או קישור',
			'shareCode.explain' => ({required Object role}) => 'כל מי שיש לו את הקוד יכול להצטרף כ${role}. הקוד תקף 30 יום.',
			'shareCode.create' => 'ליצור קוד',
			'shareCode.code' => 'קוד',
			'shareCode.link' => 'קישור',
			'shareCode.copy' => 'העתקה',
			'shareCode.copied' => 'הועתק',
			'shareCode.share' => 'שיתוף',
			'shareCode.showQr' => 'להציג QR',
			'shareCode.scanQr' => 'לסרוק QR',
			'shareCode.enterCode' => 'להזין קוד',
			'shareCode.join' => 'הצטרפות',
			'shareCode.joinTitle' => 'הצטרפות עם קוד',
			'shareCode.joinHint' => 'הדביקו את הקוד שקיבלתם, או סרקו את ה-QR שלו.',
			'shareCode.joinPlaceholder' => 'XXXXXXXX',
			'shareCode.joined' => ({required Object title}) => 'הצטרפתם: ${title}',
			'shareCode.alreadyMember' => 'זה כבר אצלכם.',
			'shareCode.invalid' => 'הקוד לא תקין.',
			'shareCode.expired' => 'תוקף הקוד פג.',
			'shareCode.revoked' => 'הקוד בוטל.',
			'shareCode.usedUp' => 'הקוד נוצל עד תום.',
			'shareCode.self' => 'זה הקוד שלכם.',
			'shareCode.gone' => 'מה שהקוד שיתף כבר לא קיים.',
			'shareCode.failed' => 'ההצטרפות נכשלה. נסו שוב.',
			'shareCode.messageText' => ({required Object name, required Object title, required Object code, required Object link}) => '${name} שיתף איתך את "${title}" ב-EasyPlate. קוד: ${code}\n${link}',
			'shareCode.revoke' => 'לבטל קוד',
			'shareCode.limitRecipes' => ({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} מתכונים בשבוע.',
			'shareCode.limitBooks' => ({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} ספרים.',
			'shareCode.limitPlans' => ({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} תפריטים.',
			'shareCode.upgrade' => 'לפרימיום',
			'shareCode.scanHint' => 'כוונו את המצלמה ל-QR של השיתוף',
			'shareCode.householdMessage' => ({required Object name, required Object code, required Object link}) => '${name} הזמין אתכם לחשבון המשותף שלו ב-EasyPlate. קוד: ${code}\n${link}',
			'shareCode.limitLists' => ({required Object count}) => 'חשבון חינמי יכול לשתף עד ${count} רשימות קניות.',
			'household.title' => 'חשבון משותף',
			'household.duo' => 'Pro Duo',
			'household.family' => 'Pro Family',
			'household.seats' => ({required Object used, required Object total}) => '${used} מתוך ${total} מקומות בשימוש',
			'household.intro' => 'פתחו חשבון משותף: מתכונים, ספרים, תפריטים ורשימות משתקפים לכל מי שבו, וכולם מקבלים פרימיום יחד איתכם.',
			'household.create' => 'לפתוח חשבון משותף',
			'household.nameHint' => 'שם, למשל משפחת כהן',
			'household.notEligible' => 'חשבון משותף מגיע עם Pro Duo (2 חשבונות) או Pro Family (עד 6 חשבונות).',
			'household.seePlans' => 'לתוכניות',
			'household.members' => 'חברים',
			'household.owner' => 'בעלים',
			'household.you' => 'אתם',
			'household.invite' => 'להזמין חבר',
			'household.inviteExplain' => ({required Object free}) => 'כל מי שיש לו את הקוד מצטרף לחשבון המשותף. נותרו ${free} מקומות.',
			'household.noSeats' => 'כל המקומות תפוסים.',
			'household.remove' => 'להסיר',
			'household.removeConfirm' => ({required Object name}) => 'להסיר את ${name} מהחשבון המשותף? הגישה והפרימיום שלהם יפסקו.',
			'household.leave' => 'לעזוב את החשבון המשותף',
			'household.leaveConfirm' => 'לעזוב? מה שנשמר כאן נשאר בחשבון המשותף; החשבון שלכם חוזר למה שהיה לכם קודם.',
			'household.dissolve' => 'לסגור את החשבון המשותף',
			'household.dissolveConfirm' => 'לסגור את החשבון המשותף? החברים יאבדו גישה ופרימיום. המידע שלכם חוזר לחשבון האישי.',
			'household.joined' => 'ברוכים הבאים לחשבון המשותף!',
			'household.inheritedNote' => ({required Object name}) => 'הפרימיום מגיע מהמנוי של ${name}.',
			'household.failed' => 'זה לא הצליח. נסו שוב.',
			'household.full' => 'החשבון המשותף מלא.',
			'household.inHousehold' => 'אתם כבר בחשבון משותף.',
			'household.notEligibleCode' => 'התוכנית של הבעלים כבר לא כוללת חשבון משותף.',
			'household.lapsed' => 'המנוי של הבעלים הסתיים; הפרימיום של החברים מושהה.',
			'feature.comingSoon' => 'בקרוב',
			'feature.comingSoonMessage' => 'הפיצ׳ר הזה יגיע בקרוב',
			'feature.unavailable' => 'הפיצ׳ר הזה לא זמין כרגע',
			'feature.premiumOnly' => 'לפרימיום',
			'feature.premiumOnlyMessage' => 'הפיצ׳ר הזה זמין למנויי פרימיום',
			'feature.premiumOnlyTitle' => 'לפרימיום בלבד',
			'feature.premiumOnlyFor' => ({required Object name}) => 'האפשרות "${name}" פתוחה רק למשתמשי פרימיום',
			'feature.goPremium' => 'עבור לפרימיום',
			'featureName.books' => 'ספרי מתכונים',
			'featureName.mealPlans' => 'תפריטים',
			'featureName.groceryLists' => 'רשימות קניות',
			'featureName.community' => 'קהילה',
			'featureName.ingestText' => 'הוספת מתכון מטקסט',
			'featureName.ingestWebSearch' => 'חיפוש מתכון ברשת',
			'featureName.ingestLink' => 'הוספת מתכון מקישור',
			'featureName.ingestSocialVideo' => 'הוספת מתכון מסרטון',
			'featureName.ingestAiRequest' => 'בקשת מתכון מה-AI',
			'featureName.ingestFile' => 'הוספת מתכון מקובץ',
			'featureName.shareIn' => 'שיתוף מאפליקציה אחרת',
			'featureName.saveWithAi' => 'שמירה עם AI',
			'featureName.cookMode' => 'מצב בישול',
			'featureName.cookTimers' => 'טיימרים בבישול',
			'featureName.nutrition' => 'ערכים תזונתיים',
			'featureName.recipeImageAi' => 'יצירת תמונה ב-AI',
			'featureName.recipeImageSearch' => 'חיפוש תמונה בגוגל',
			'featureName.groceryFromRecipe' => 'רשימת קניות ממתכון',
			'featureName.sharedRecipes' => 'מתכונים משותפים',
			'featureName.forum' => 'פורום',
			'featureName.likes' => 'לייקים',
			'featureName.shareRecipes' => 'שיתוף מתכונים',
			'featureName.shareBooks' => 'שיתוף ספרים',
			'featureName.sharePlans' => 'שיתוף תפריטים',
			'featureName.shareGroceryLists' => 'שיתוף רשימות קניות',
			'featureName.shareCodes' => 'שיתוף בקוד',
			'featureName.households' => 'משק בית',
			'featureName.priceBook' => 'ספר מחירים',
			'featureName.receiptScan' => 'סריקת קבלה',
			'featureName.groceryCost' => 'עלות משוערת',
			'featureName.shoppingReminder' => 'תזכורת קניות',
			'featureName.assistant' => 'שפי (העוזר החכם)',
			'featureName.notifications' => 'התראות',
			'featureName.premium' => 'פרימיום',
			'featureName.contentTranslation' => 'תרגום תוכן',
			'featureName.theming' => 'מראה',
			'featureName.walkthrough' => 'סיור מודרך',
			'featureName.tutorialBook' => 'ספר הדרכה',
			'featureName.feedback' => 'משוב',
			'featureName.assistantScoped' => 'שפי בתוך פריט',
			'featureName.assistantVoice' => 'דיבור עם שפי',
			'featureName.singleSession' => 'מכשיר אחד לחשבון',
			'adminConfig.intro' => 'כל ערך כאן הוא ה-Remote Config של Firebase. שינוי מתפרסם מיד לכל המשתמשים (ערכי ברירת המחדל; תנאים בקונסול נשארים כפי שהם).',
			'adminConfig.loadFailed' => 'לא הצלחנו לטעון את התצורה',
			'adminConfig.saveFailed' => 'הפרסום נכשל. בדקו את הערך ונסו שוב',
			'adminConfig.saved' => ({required Object name}) => '״${name}״ פורסם',
			'adminConfig.count' => ({required Object n}) => '${n} הגדרות',
			'adminConfig.searchAll' => 'חיפוש בכל ההגדרות',
			'adminConfig.searchIn' => ({required Object section}) => 'חיפוש ב${section}',
			'adminConfig.noResults' => ({required Object query}) => 'אין הגדרה שמתאימה ל״${query}״',
			'adminConfig.filterAll' => 'הכל',
			'adminConfig.clearSearch' => 'ניקוי החיפוש',
			'adminConfig.noFlagsInState' => 'אין פיצ׳רים במצב הזה',
			'adminConfig.groups.features' => 'פיצ׳רים',
			'adminConfig.groups.adsQuotas' => 'פרסומות ומכסות',
			'adminConfig.groups.sharing' => 'שיתוף בחשבון חינמי',
			'adminConfig.groups.voice' => 'הקול של שפי',
			'adminConfig.groups.versions' => 'גרסאות וסביבה',
			'adminConfig.groups.gemini' => 'שרת ה-AI (דורש deploy)',
			'adminConfig.groups.other' => 'אחר',
			'adminConfig.flag.hidden' => 'לא מוצג',
			'adminConfig.flag.comingSoon' => 'בקרוב',
			'adminConfig.flag.everyone' => 'חינמי',
			'adminConfig.flag.premium' => 'פרימיום',
			'adminConfig.labels.ads_enabled' => 'פרסומות פעילות',
			'adminConfig.labels.ads_fail_open' => 'פתיחה כשאין סרטון',
			'adminConfig.labels.ads_feed_interval' => 'מרווח מודעות בפיד',
			'adminConfig.labels.quota_shared_free' => 'מתכונים משותפים חינם ביום',
			'adminConfig.labels.quota_shared_rewarded' => 'מתכונים משותפים אחרי סרטון',
			'adminConfig.labels.quota_ai_rewarded' => 'חילוצי AI אחרי סרטון ביום',
			'adminConfig.labels.share_free_recipes_weekly' => 'שיתופי מתכון בשבוע',
			'adminConfig.labels.share_free_books_total' => 'ספרים משותפים בו-זמנית',
			'adminConfig.labels.share_free_plans_total' => 'תפריטים משותפים בו-זמנית',
			'adminConfig.labels.share_free_lists_total' => 'רשימות קניות משותפות בו-זמנית',
			'adminConfig.labels.tts_cloud_enabled' => 'קול ענן (Google)',
			'adminConfig.labels.tts_voice_he' => 'קול בעברית',
			'adminConfig.labels.tts_voice_en' => 'קול באנגלית',
			'adminConfig.labels.tts_voice_ar' => 'קול בערבית',
			'adminConfig.labels.tts_voice_fr' => 'קול בצרפתית',
			'adminConfig.labels.tts_voice_ru' => 'קול ברוסית',
			'adminConfig.labels.isProd' => 'גרסת פרודקשן',
			'adminConfig.labels.minimumVersion' => 'גרסה מינימלית',
			'adminConfig.labels.latestVersion' => 'גרסה אחרונה',
			'adminConfig.labels.iosAppStoreId' => 'מזהה App Store',
			'adminConfig.labels.gemini_minInstances' => 'מינימום שרתים',
			'adminConfig.labels.gemini_maxInstances' => 'מקסימום שרתים',
			'adminConfig.labels.gemini_timeoutSeconds' => 'זמן קצוב לקריאה (שניות)',
			'adminConfig.labels.session_days' => 'ימי התחברות למכשיר',
			_ => null,
		};
	}
}
