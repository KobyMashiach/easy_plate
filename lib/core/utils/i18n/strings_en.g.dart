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
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Easy Plate';
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
	@override late final _Translations$profile$en profile = _Translations$profile$en._(_root);
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$dietary$en dietary = _Translations$dietary$en._(_root);
	@override late final _Translations$allergens$en allergens = _Translations$allergens$en._(_root);
	@override late final _Translations$weekday$en weekday = _Translations$weekday$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$notificationSettings$en notificationSettings = _Translations$notificationSettings$en._(_root);
	@override late final _Translations$preferences$en preferences = _Translations$preferences$en._(_root);
	@override late final _Translations$more$en more = _Translations$more$en._(_root);
	@override late final _Translations$language$en language = _Translations$language$en._(_root);
	@override late final _Translations$books$en books = _Translations$books$en._(_root);
	@override late final _Translations$recipe$en recipe = _Translations$recipe$en._(_root);
	@override late final _Translations$cookMode$en cookMode = _Translations$cookMode$en._(_root);
	@override late final _Translations$nutrition$en nutrition = _Translations$nutrition$en._(_root);
	@override late final _Translations$community$en community = _Translations$community$en._(_root);
	@override late final _Translations$sharing$en sharing = _Translations$sharing$en._(_root);
	@override late final _Translations$notifications$en notifications = _Translations$notifications$en._(_root);
	@override late final _Translations$editor$en editor = _Translations$editor$en._(_root);
	@override late final _Translations$ingestion$en ingestion = _Translations$ingestion$en._(_root);
	@override late final _Translations$mealPlanner$en mealPlanner = _Translations$mealPlanner$en._(_root);
	@override late final _Translations$groceryList$en groceryList = _Translations$groceryList$en._(_root);
	@override late final _Translations$receipt$en receipt = _Translations$receipt$en._(_root);
	@override late final _Translations$unit$en unit = _Translations$unit$en._(_root);
	@override late final _Translations$image$en image = _Translations$image$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$update$en update = _Translations$update$en._(_root);
	@override late final _Translations$ads$en ads = _Translations$ads$en._(_root);
	@override late final _Translations$premium$en premium = _Translations$premium$en._(_root);
	@override late final _Translations$walkthrough$en walkthrough = _Translations$walkthrough$en._(_root);
	@override late final _Translations$feedback$en feedback = _Translations$feedback$en._(_root);
	@override late final _Translations$adminBilling$en adminBilling = _Translations$adminBilling$en._(_root);
	@override late final _Translations$adminDashboard$en adminDashboard = _Translations$adminDashboard$en._(_root);
	@override late final _Translations$assistant$en assistant = _Translations$assistant$en._(_root);
	@override late final _Translations$shareCode$en shareCode = _Translations$shareCode$en._(_root);
	@override late final _Translations$household$en household = _Translations$household$en._(_root);
	@override late final _Translations$feature$en feature = _Translations$feature$en._(_root);
	@override late final _Translations$featureName$en featureName = _Translations$featureName$en._(_root);
	@override late final _Translations$adminConfig$en adminConfig = _Translations$adminConfig$en._(_root);
}

// Path: common
class _Translations$common$en extends Translations$common$he {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
	@override String get ok => 'OK';
	@override String get next => 'Next';
	@override String get back => 'Back';
	@override String get done => 'Done';
	@override String get add => 'Add';
	@override String get edit => 'Edit';
	@override String get delete => 'Delete';
	@override String get search => 'Search';
	@override String get retry => 'Try again';
	@override String get loading => 'Loading...';
	@override String get error => 'Something went wrong';
	@override String get or => 'or';
	@override String get missingInfo => '[missing info]';
	@override String get networkError => 'No internet connection';
	@override String get landscapeHint => 'Works better in landscape';
	@override String get rotateLandscape => 'Rotate';
	@override String get rotatePortrait => 'Back to portrait';
}

// Path: auth
class _Translations$auth$en extends Translations$auth$he {
	_Translations$auth$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'Welcome to EasyPlate';
	@override String get subtitle => 'Sign in to keep your recipes';
	@override String get signIn => 'Sign in';
	@override String get signUp => 'Sign up';
	@override String get signOut => 'Sign out';
	@override String get email => 'Email';
	@override String get emailHint => 'name@example.com';
	@override String get password => 'Password';
	@override String get passwordHint => 'At least 6 characters';
	@override String get continueWithGoogle => 'Continue with Google';
	@override String get continueWithPhone => 'Continue with phone';
	@override String get continueWithEmail => 'Continue with email';
	@override String get phoneNumber => 'Phone number';
	@override String get phoneHint => '+972501234567';
	@override String get sendCode => 'Send code';
	@override String get smsCode => 'SMS code';
	@override String codeSentTo({required Object phone}) => 'We sent a verification code to ${phone}';
	@override String get verify => 'Verify';
	@override String get resendCode => 'Resend';
	@override String get forgotPassword => 'Forgot password';
	@override String get resetSent => 'Password reset email sent';
	@override String get noAccount => 'No account? Sign up';
	@override String get haveAccount => 'Have an account? Sign in';
	@override String get invalidEmail => 'Invalid email address';
	@override String get passwordTooShort => 'Password must be at least 6 characters';
	@override String get invalidPhone => 'Invalid phone number';
	@override String get codeRequired => 'Enter the code you received';
	@override String get errorUnauthorized => 'Those details are incorrect';
	@override String get errorNetwork => 'No internet connection';
	@override String get errorUnknown => 'Sign-in failed, please try again';
	@override String get signOutTitle => 'Sign out?';
	@override String get signOutBody => 'You will need to sign in again to reach your recipes.';
	@override String get errorOperationNotAllowed => 'This sign-in method is not available right now';
	@override String get errorTooManyRequests => 'Too many attempts. Try again in a few minutes';
	@override String get errorInvalidPhone => 'That phone number is not valid';
	@override String get errorEmailInUse => 'That email is already registered';
	@override String get verifyEmailTitle => 'Verify your email';
	@override String verifyEmailBody({required Object email}) => 'We sent a verification link to ${email}. Open it, then come back here.';
	@override String get resendEmail => 'Resend the link';
	@override String get emailResent => 'Link sent again';
	@override String get checkVerification => 'I have verified';
	@override String get stillNotVerified => 'Not verified yet';
	@override String get linkPhone => 'Verify phone';
	@override String get phoneLinked => 'Phone verified';
	@override String get phoneAlreadyUsed => 'That number already belongs to another account';
	@override String get emailAlreadyLinked => 'This account already has an email';
	@override String get addEmailPassword => 'Add email and password';
	@override String get verified => 'Verified';
	@override String get linkGoogle => 'Link Google account';
	@override String get googleLinked => 'Linked';
	@override String get googleAlreadyUsed => 'That Google account already belongs to another user';
	@override String get googleAlreadyLinked => 'A Google account is already linked';
	@override String get phoneGateTitle => 'Verify your phone';
	@override String get phoneGateBody => 'Every account is verified by phone. We\'ll text you a code.';
	@override String get changeNumber => 'Change number';
	@override String get signInTitle => 'Sign in';
	@override String get phoneFirstHint => 'New here? Continue with phone.';
	@override String get errorAccountExistsDifferentCredential => 'That email already belongs to another account. Sign in the way you registered.';
	@override String get errorCredentialInUse => 'Those details already belong to another account';
	@override String get continueWithApple => 'Continue with Apple';
	@override String get linkApple => 'Link Apple account';
	@override String get appleLinked => 'Linked';
	@override String get appleAlreadyUsed => 'That Apple account already belongs to another user';
	@override String get appleAlreadyLinked => 'An Apple account is already linked';
	@override String get blockedTitle => 'Account blocked';
	@override String get blockedBody => 'This account was blocked by the app\'s administrator. Contact us from the support screen for details.';
	@override String get phoneClaimedTitle => 'This number belongs to an existing account';
	@override String phoneClaimedBody({required Object phone}) => '${phone} is already connected to another EasyPlate account. To reach that account and its recipes, sign in the way you did before (Google, Apple or email) and verify the number there again.';
	@override String get phoneClaimedSignIn => 'Sign in to my existing account';
	@override String get phoneClaimedCreateNew => 'Create a new account anyway';
	@override String get phoneClaimedCreateNewConfirm => 'A new, empty account will be opened for this number. The existing account stays as it is, but it will no longer be reachable with this number.';
	@override String get sessionOtherDeviceTitle => 'Signed in on another device';
	@override String sessionOtherDeviceBody({required Object platform, required Object since}) => 'This account is open on ${platform}${since}. It can be used on one device at a time: sign out there, then tap "Try again".';
	@override String sessionSince({required Object date}) => ' since ${date}';
	@override String get sessionExpiredTitle => 'Your session has expired';
	@override String get sessionExpiredBody => 'A sign-in lasts up to a month. Sign in again to continue.';
	@override String get sessionRetry => 'Try again';
	@override String get platformIos => 'an iPhone';
	@override String get platformAndroid => 'an Android phone';
	@override String get platformOther => 'another device';
}

// Path: profile
class _Translations$profile$en extends Translations$profile$he {
	_Translations$profile$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get setupTitle => 'A few last details';
	@override String get setupSubtitle => 'So we know what to call you';
	@override String get fullName => 'Full name';
	@override String get fullNameHint => 'Jane Doe';
	@override String get fullNameRequired => 'A full name is required';
	@override String get photo => 'Profile photo';
	@override String get addPhoto => 'Add photo';
	@override String get phoneOptional => 'Phone (optional)';
	@override String get emailOptional => 'Email (optional)';
	@override String get save => 'Finish signing up';
	@override String get saving => 'Saving...';
	@override String get saveFailed => 'We could not save your profile';
	@override String get myProfile => 'My profile';
}

// Path: onboarding
class _Translations$onboarding$en extends Translations$onboarding$he {
	_Translations$onboarding$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get welcomeTitle => 'Welcome to EasyPlate';
	@override String get welcomeSubtitle => 'Plan meals, cook and shop — all in one place';
	@override String get shoppingDayTitle => 'When is your weekly shopping day?';
	@override String get dietaryTitle => 'What are your dietary preferences?';
	@override String get dietarySubtitle => 'You can pick more than one';
	@override String get finish => 'Let\'s get started';
}

// Path: dietary
class _Translations$dietary$en extends Translations$dietary$he {
	_Translations$dietary$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get meat => 'Meat';
	@override String get dairy => 'Dairy';
	@override String get vegetarian => 'Vegetarian';
	@override String get vegan => 'Vegan';
	@override String get kosher => 'Kosher';
	@override String get glutenFree => 'Gluten-free';
	@override String get allergy => 'Allergy';
}

// Path: allergens
class _Translations$allergens$en extends Translations$allergens$he {
	_Translations$allergens$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Allergens';
	@override String get pick => 'Mark allergens';
	@override String get contains => 'Contains';
	@override String get mayContain => 'May contain';
	@override String get gluten => 'Gluten';
	@override String get milk => 'Milk';
	@override String get eggs => 'Eggs';
	@override String get fish => 'Fish';
	@override String get shellfish => 'Shellfish';
	@override String get peanuts => 'Peanuts';
	@override String get treeNuts => 'Tree nuts';
	@override String get sesame => 'Sesame';
	@override String get soy => 'Soy';
}

// Path: weekday
class _Translations$weekday$en extends Translations$weekday$he {
	_Translations$weekday$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get sunday => 'Sunday';
	@override String get monday => 'Monday';
	@override String get tuesday => 'Tuesday';
	@override String get wednesday => 'Wednesday';
	@override String get thursday => 'Thursday';
	@override String get friday => 'Friday';
	@override String get saturday => 'Saturday';
}

// Path: settings
class _Translations$settings$en extends Translations$settings$he {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get dietaryPreferences => 'Dietary preferences';
	@override String get shoppingDay => 'Shopping day';
	@override String get language => 'Language';
	@override String get appearance => 'Appearance';
	@override String get themeSystem => 'System';
	@override String get themeLight => 'Light';
	@override String get themeDark => 'Dark';
	@override String get soundEffects => 'Sound effects (page turns)';
	@override String get fastPageTurn => 'Fast page-through';
	@override String get fastPageTurnHint => 'Jumping from the table of contents or quick navigation turns a single page to the destination. Turn it off to flip through every page on the way.';
	@override String get sharedAccess => 'Manage sharing';
	@override String get noSharedAccess => 'You haven\'t shared any books or lists yet';
	@override String get communityPrices => 'Community price averages';
	@override String get communityPricesHint => 'When you have no price of your own for a product, show the median price other people shared';
	@override String get shoppingReminders => 'Shopping day reminders';
	@override String get shoppingRemindersHint => 'Sent by the device, around the shopping day you picked';
	@override String get reminderTwoDaysBefore => 'Two days before (evening)';
	@override String get reminderDayBefore => 'Day before (evening)';
	@override String get reminderSameDayMorning => 'Shopping day (morning)';
	@override String get reminderSameDayAfternoon => 'Shopping day (afternoon)';
	@override String get translatingContent => 'Translating your recipes and menus…';
	@override String translatedContent({required Object count}) => '${count} items translated';
	@override String get translationPartialTitle => 'Translation unfinished';
	@override String translationPartial({required Object count}) => '${count} items stayed in their own language. You can try again later.';
	@override String get translationFailed => 'Translation failed. Your content stayed in its own language.';
	@override String get account => 'Account';
	@override String get notifications => 'Notifications';
	@override String get notificationsHint => 'Which alerts reach you, and how';
	@override String get settingsHint => 'Account, notifications, language and appearance';
	@override String get dangerZone => 'Danger zone';
	@override String get deleteAccount => 'Delete account';
	@override String get deleteAccountHint => 'Permanently delete the account and everything in it';
	@override String get deleteAccountTitle => 'Delete the account for good?';
	@override String get deleteAccountBody => 'Your account, recipes, books, meal plans, grocery lists, receipts, photos, posts and replies will be permanently deleted from our servers and from this device and cannot be recovered. What you shared is removed from the people you shared it with. An active subscription is not cancelled automatically: cancel it in the App Store or Google Play.';
	@override String get deleteAccountConfirm => 'Delete permanently';
	@override String get deletingAccount => 'Deleting the account…';
	@override String get deleteAccountFailed => 'Deleting the account failed. Try again, or write to support@aieasyplate.app.';
	@override String get deleteAccountHousehold => 'You own a shared household. Close it first from the Household screen, then try again.';
}

// Path: notificationSettings
class _Translations$notificationSettings$en extends Translations$notificationSettings$he {
	_Translations$notificationSettings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Notification settings';
	@override String get push => 'Push notifications';
	@override String get pushHint => 'Alerts on this device. Off, nothing is pushed; the inbox still fills up.';
	@override String get pushDenied => 'Notifications are blocked for EasyPlate in the device settings. Allow them there to receive alerts.';
	@override String get community => 'Community';
	@override String get repliesOnMyPosts => 'Replies to my posts';
	@override String get repliesOnMyPostsHint => 'Someone answered a thread you opened';
	@override String get repliesOnThreads => 'Replies in threads I joined';
	@override String get repliesOnThreadsHint => 'A new reply in a thread you replied to';
	@override String get sharing => 'Sharing';
	@override String get shareInvites => 'Share invites';
	@override String get shareInvitesHint => 'Someone shared a recipe, book or plan with you. The invite always reaches the inbox; this is the alert.';
	@override String get sharedRecipeUpdates => 'Updates to saved recipes';
	@override String get sharedRecipeUpdatesHint => 'The author changed a community recipe you saved';
	@override String get easyPlate => 'From EasyPlate';
	@override String get adminReplies => 'Replies to my support messages';
	@override String get announcements => 'Announcements';
	@override String get announcementsHint => 'News and updates from the EasyPlate team';
	@override String get inApp => 'While the app is open';
	@override String get foregroundPopups => 'Show alerts as a popup';
	@override String get foregroundPopupsHint => 'A push that arrives while you are in the app opens a small card. Off, it only goes to the inbox.';
	@override String get reminders => 'Shopping reminders';
}

// Path: preferences
class _Translations$preferences$en extends Translations$preferences$he {
	_Translations$preferences$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preferences';
	@override String get hint => 'Shopping, dietary needs and how the books behave';
	@override String get shopping => 'Shopping';
	@override String get books => 'Recipe books';
}

// Path: more
class _Translations$more$en extends Translations$more$he {
	_Translations$more$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'More';
	@override String get settings => 'Settings';
	@override String get profile => 'My profile';
	@override String get support => 'Support';
	@override String get supportTitle => 'How can we help?';
	@override String get supportBody => 'Write to us and we will get back to you.';
	@override String get whatsapp => 'Message us on WhatsApp';
	@override String get email => 'Send an email';
	@override String get supportUnavailable => 'We could not open that app';
	@override String get preferences => 'Preferences';
	@override String get help => 'Support & legal';
	@override String get helpHint => 'Support, privacy policy and terms of service';
	@override String get legal => 'Legal';
}

// Path: language
class _Translations$language$en extends Translations$language$he {
	_Translations$language$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get hebrew => 'עברית';
	@override String get english => 'English';
	@override String get arabic => 'العربية';
	@override String get french => 'Français';
	@override String get russian => 'Русский';
}

// Path: books
class _Translations$books$en extends Translations$books$he {
	_Translations$books$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get myLibrary => 'My library';
	@override String get myRecipes => 'My recipes';
	@override String get librarySubtitle => 'All your recipe books in one place';
	@override String get recipesSubtitle => 'Search and filter every recipe you\'ve collected';
	@override String get collection => 'Collection';
	@override String recipesCount({required Object count}) => '${count} recipes';
	@override String get newBook => 'New book';
	@override String get newBookTitle => 'Book name';
	@override String get tableOfContents => 'Table of contents';
	@override String get emptyLibrary => 'You don\'t have any books yet. Create your first one!';
	@override String get emptyBook => 'This book is empty. Add your first recipe';
	@override String get quickNav => 'Quick navigation';
	@override String get share => 'Share book';
	@override String get viewer => 'Viewer';
	@override String get editor => 'Editor';
	@override String get reorderHint => 'Drag to reorder the recipes';
	@override String get coverImage => 'Cover photo';
	@override String get bookOptions => 'Book options';
	@override String get renameBook => 'Rename book';
	@override String get spineColor => 'Spine colour';
}

// Path: recipe
class _Translations$recipe$en extends Translations$recipe$he {
	_Translations$recipe$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get prepTime => 'Prep time';
	@override String get cookTime => 'Cook time';
	@override String get ingredients => 'Ingredients';
	@override String ingredientsCount({required Object count}) => '${count} ingredients';
	@override String minutes({required Object count}) => '${count} min';
	@override String hours({required Object count}) => '${count} hr';
	@override String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours} hr ${minutes} min';
	@override String get instructions => 'Instructions';
	@override String get addToBook => 'Add to book';
	@override String get removeFromBook => 'Remove from book';
	@override String get deleteRecipe => 'Delete recipe';
	@override String get photo => 'Recipe photo';
	@override String get mine => 'My recipes';
	@override String get saved => 'Saved recipes';
	@override String get noneMine => 'You have not created any recipes yet';
	@override String get noneSaved => 'You have not saved any community recipes yet';
	@override String get pendingAnalysis => 'Awaiting analysis';
	@override String get pendingAnalysisHint => 'Saved as raw text. Analyse it now or edit it by hand.';
	@override String get analyzeNow => 'Analyse with AI now';
	@override String get analyzing => 'Analysing the recipe...';
	@override String get analyzeFailed => 'The analysis failed — you can try again later';
	@override String get communityUpdateTitle => 'This recipe is shared';
	@override String get communityUpdateBody => 'Update the community copy too, or only yours?';
	@override String get communityUpdateBoth => 'Community too';
	@override String get communityUpdateLocal => 'Only mine';
	@override String get communityUpdated => 'The community copy was updated';
	@override String get communityGone => 'The recipe is no longer in the community; saved only for you';
}

// Path: cookMode
class _Translations$cookMode$en extends Translations$cookMode$he {
	_Translations$cookMode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cook mode';
	@override String get start => 'Start cooking';
	@override String stepOf({required Object n, required Object total}) => 'Step ${n} of ${total}';
	@override String get ingredients => 'Ingredients';
	@override String get inThisStep => 'In this step';
	@override String get timer => 'Timer';
	@override String get startTimer => 'Start timer';
	@override String get pause => 'Pause';
	@override String get resume => 'Resume';
	@override String get reset => 'Reset';
	@override String get timeUp => 'Time\'s up!';
	@override String get next => 'Next step';
	@override String get previous => 'Previous';
	@override String get finish => 'Done cooking';
	@override String get finishedTitle => 'Enjoy your meal!';
	@override String get finishedBody => 'Every step is done. The screen can sleep again now.';
	@override String get screenOn => 'The screen stays on while you cook';
	@override String get noSteps => 'This recipe has no steps yet';
	@override String runningOnStep({required Object n}) => 'Timer running on step ${n}';
	@override String get inProgress => 'Cooking in progress';
	@override String inProgressBody({required Object recipe, required Object n, required Object total}) => '"${recipe}" · step ${n} of ${total}';
	@override String get resumeCooking => 'Continue';
	@override String get endCooking => 'End';
	@override String stepLabel({required Object n}) => 'Step ${n}';
	@override String ongoingBody({required Object time, required Object total, required Object n}) => 'Ends at ${time} · ${total} · step ${n}';
	@override String timeUpBody({required Object n}) => 'Step ${n}: time\'s up';
	@override String get runningTimers => 'Running timers';
	@override String get premiumOnly => 'Cook mode is part of EasyPlate Premium';
}

// Path: nutrition
class _Translations$nutrition$en extends Translations$nutrition$he {
	_Translations$nutrition$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nutrition';
	@override String get perServing => 'per serving';
	@override String get perServingHint => 'All values are for one serving. Leave blank to drop the estimate.';
	@override String get servings => 'servings';
	@override String servingsCount({required Object count}) => '${count} servings';
	@override String get calories => 'Calories';
	@override String get kcal => 'kcal';
	@override String get protein => 'Protein';
	@override String get carbs => 'Carbs';
	@override String get fat => 'Fat';
	@override String get gramsShort => 'g';
	@override String get estimate => 'Estimate with AI';
	@override String get estimating => 'Estimating nutrition…';
	@override String get estimateFailed => 'The estimate failed, please try again';
	@override String get none => 'No nutrition values for this recipe yet';
	@override String get noneHint => 'AI can estimate calories, protein, carbs and fat from the ingredient list';
	@override String get estimated => 'Nutrition values updated';
	@override String get editorServings => 'Servings';
	@override String get editorCalories => 'Calories per serving';
	@override String get editorProtein => 'Protein (g)';
	@override String get editorCarbs => 'Carbs (g)';
	@override String get editorFat => 'Fat (g)';
	@override String get dashboard => 'Nutrition dashboard';
	@override String get weekly => 'This week';
	@override String get today => 'Today';
	@override String get dayTotal => 'Day total';
	@override String get weekTotal => 'Week total';
	@override String get dailyAverage => 'Average per planned day';
	@override String get perMeal => 'By meal';
	@override String get perDay => 'By day';
	@override String get noPlanned => 'No meals with recipes planned yet';
	@override String missingCount({required Object count}) => '${count} items without nutrition values';
	@override String get macroSplit => 'Calorie split';
	@override String get kcalPerDay => 'kcal per day';
	@override String get openDashboard => 'Weekly dashboard';
	@override String get perRecipe => 'Whole recipe';
	@override String perRecipeServings({required Object count}) => '${count} servings';
}

// Path: community
class _Translations$community$en extends Translations$community$he {
	_Translations$community$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Community';
	@override String get forum => 'Forum';
	@override String get sharedRecipes => 'Shared recipes';
	@override String get newPost => 'New post';
	@override String get postTitle => 'Title';
	@override String get postBody => 'What would you like to ask or share?';
	@override String get postTitleRequired => 'A title is required';
	@override String get postBodyRequired => 'Some content is required';
	@override String get publish => 'Publish';
	@override String replies({required Object count}) => '${count} replies';
	@override String get noReplies => 'No replies yet';
	@override String get oneReply => 'One reply';
	@override String get writeReply => 'Write a reply...';
	@override String get send => 'Send';
	@override String get noPosts => 'No posts yet. Be the first!';
	@override String get noSharedRecipes => 'No shared recipes yet. Share the first one!';
	@override String get shareRecipe => 'Share a recipe';
	@override String get pickRecipeToShare => 'Which recipe would you like to share?';
	@override String get saveToMyRecipes => 'Save to my recipes';
	@override String get savedToMyRecipes => 'Recipe saved to your collection';
	@override String get deletePost => 'Delete post';
	@override String get deletePostConfirm => 'The post and its replies will be permanently deleted.';
	@override String get unshare => 'Remove from feed';
	@override String get unshareConfirm => 'The recipe will be removed from the shared feed.';
	@override String byAuthor({required Object name}) => 'by ${name}';
	@override String get loadFailed => 'We could not load the content';
	@override String get allRecipes => 'All recipes';
	@override String get myRecipes => 'My recipes';
	@override String get editShared => 'Edit shared recipe';
	@override String get sharedUpdated => 'Shared recipe updated';
	@override String get noneOfMine => 'You have not shared any recipes yet';
	@override String get search => 'Search';
	@override String get searchHint => 'Recipe or author name';
	@override String get savedOnly => 'Saved';
	@override String get noResults => 'No results';
	@override String get attachRecipe => 'Attach a recipe';
	@override String get openRecipe => 'Open recipe';
	@override String get recipeUnavailable => 'That recipe is no longer available';
	@override String get sortAndFilter => 'Sort & filter';
	@override String get sort => 'Sort';
	@override String get sortNewest => 'Newest';
	@override String get sortOldest => 'Oldest';
	@override String get sortMostLiked => 'Most liked';
	@override String get topics => 'Topics';
	@override String get likes => 'Likes';
	@override String get anyLikes => 'Any';
	@override String atLeastLikes({required Object count}) => '${count}+';
	@override String get totalTime => 'Total time';
	@override String get anyTime => 'Any time';
	@override String upTo({required Object duration}) => 'Up to ${duration}';
	@override String get clearFilters => 'Clear filters';
	@override String get applyFilters => 'Show results';
	@override String likesPlus({required Object count}) => '${count}+';
	@override String durationPlus({required Object duration}) => '${duration}+';
	@override String get splitTimes => 'Split into prep and cook';
	@override String get alreadySaved => 'You already have this recipe';
	@override String get savedTag => 'Saved';
	@override String get removeSaved => 'Remove from saved recipes';
	@override String get removeSavedConfirm => 'The recipe will be removed from your saved recipes. You can save it again from the community.';
	@override String get oneNewPost => '1 new post';
	@override String newPosts({required Object count}) => '${count} new posts';
	@override String get replyFailed => 'Your reply could not be sent';
}

// Path: sharing
class _Translations$sharing$en extends Translations$sharing$he {
	_Translations$sharing$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Share recipe';
	@override String get contactLabel => 'Email or phone of the person';
	@override String get contactHint => 'name@example.com or 05…';
	@override String get roleTitle => 'Permission';
	@override String get roleViewer => 'View only';
	@override String get roleViewerHint => 'Can see the recipe, not change it';
	@override String get roleEditor => 'Edit';
	@override String get roleEditorHint => 'Their changes show up for you too';
	@override String get send => 'Send invite';
	@override String get sent => 'Invite sent';
	@override String get invalidContact => 'Enter a valid email or phone number';
	@override String get notFound => 'No account matches those details. Make sure the email or phone is linked to their account and that they have opened the app recently.';
	@override String get self => 'You can\'t share with yourself';
	@override String get failed => 'Sharing failed, try again';
	@override String get pendingInvites => 'Pending invites';
	@override String get noPendingInvites => 'No pending invites';
	@override String get sharedByMe => 'Shared by me';
	@override String get sharedWithMe => 'Shared with me';
	@override String get nothingSharedByMe => 'You haven\'t shared anything yet';
	@override String get nothingSharedWithMe => 'Nothing has been shared with you yet';
	@override String get accept => 'Accept';
	@override String get decline => 'Decline';
	@override String get accepted => 'The recipe was added to your recipes';
	@override String get declined => 'Invite declined';
	@override String get acceptFailed => 'Accepting failed, try again';
	@override String get members => 'Members';
	@override String get noMembersYet => 'Nobody has accepted yet';
	@override String get remove => 'Remove';
	@override String get leave => 'Leave';
	@override String get removed => 'Member removed';
	@override String get left => 'You left the share';
	@override String invitedBy({required Object name}) => 'from ${name}';
	@override String get sharedTag => 'Shared';
	@override String get viewerTag => 'View only';
	@override String get editorTag => 'Editor';
	@override String get ownerTag => 'Owner';
	@override String get syncFailed => 'Could not refresh the shared recipe, showing the saved version';
	@override String get viewerCannotEdit => 'This recipe is shared with you view-only';
	@override String get shareAction => 'Share';
	@override String get directoryUnavailable => 'Sharing is not set up on the server yet. Sign out and back in; if it persists, the Firestore rules need deploying.';
	@override String get shareBook => 'Share book';
	@override String get sharePlan => 'Share plan';
	@override String get acceptedBook => 'The book was added to your library';
	@override String get acceptedPlan => 'The plan was added to your plans';
	@override String get viewerCannotEditBook => 'This book was shared with you as view only';
	@override String get viewerCannotEditPlan => 'This plan was shared with you as view only';
	@override String get kindRecipe => 'Recipe';
	@override String get kindBook => 'Book';
	@override String get kindPlan => 'Plan';
	@override String get recipesTravel => 'The recipes inside are shared along with it';
	@override String get shareList => 'Share grocery list';
	@override String get acceptedList => 'The list was added to your grocery lists';
	@override String get viewerCannotEditList => 'This list is shared with you view-only';
	@override String get kindList => 'grocery list';
}

// Path: notifications
class _Translations$notifications$en extends Translations$notifications$he {
	_Translations$notifications$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Notifications';
	@override String get empty => 'No notifications';
	@override String sharedRecipe({required Object name, required Object recipe}) => '${name} shared "${recipe}" with you';
	@override String get asViewer => 'view only';
	@override String get asEditor => 'to edit';
	@override String get markAllRead => 'Mark all as read';
	@override String get openRecipe => 'Open recipe';
	@override String get alreadyHandled => 'This invite was already handled';
	@override String recipeUpdated({required Object name, required Object recipe}) => '${name} updated "${recipe}"';
	@override String get recipeUpdatedHint => 'There is a new version of a recipe you saved';
	@override String get refreshCopy => 'Refresh to new version';
	@override String get keepCopy => 'Keep my copy';
	@override String get refreshed => 'Your copy was updated to the new version';
	@override String get keptCopy => 'Your copy stays as it is';
	@override String get recipeGone => 'The recipe is no longer in the community';
	@override String get deleteAll => 'Delete all notifications';
	@override String get deleteAllBody => 'Every notification will be deleted.';
	@override String get openInbox => 'Open notifications';
	@override String sharedBook({required Object name, required Object recipe}) => '${name} shared the book "${recipe}" with you';
	@override String sharedPlan({required Object name, required Object recipe}) => '${name} shared the plan "${recipe}" with you';
	@override String get adminReply => 'A reply from the EasyPlate team to your message';
	@override String adminReplyQuote({required Object excerpt}) => 'Your message: "${excerpt}"';
	@override String get adminMessage => 'A message from EasyPlate';
	@override String forumReplyOnMyPost({required Object name, required Object post}) => '${name} replied to your post "${post}"';
	@override String forumReplyOnThread({required Object name, required Object post}) => '${name} replied in "${post}"';
	@override String get openThread => 'Open thread';
	@override String get threadGone => 'This thread was deleted';
	@override String get settings => 'Settings';
	@override String sharedList({required Object name, required Object recipe}) => '${name} shared the grocery list "${recipe}" with you';
}

// Path: editor
class _Translations$editor$en extends Translations$editor$he {
	_Translations$editor$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Edit recipe';
	@override String get recipeTitle => 'Recipe name';
	@override String get titleHint => 'For example: Jerusalem shakshuka';
	@override String get topics => 'Topics';
	@override String get titleRequired => 'A recipe name is required';
	@override String get prepMinutes => 'Prep time (min)';
	@override String get cookMinutes => 'Cook time (min)';
	@override String get amount => 'Amount';
	@override String get unit => 'Unit';
	@override String get ingredientName => 'Ingredient name';
	@override String get stepHint => 'Describe the step';
	@override String get addIngredient => 'Add ingredient';
	@override String get addStep => 'Add step';
	@override String get removeIngredient => 'Remove ingredient';
	@override String get removeStep => 'Remove step';
	@override String get reorderStep => 'Reorder step';
	@override String get fixSpelling => 'Fix spelling';
	@override String get refining => 'Correcting the recipe...';
	@override String get refineError => 'We could not correct the recipe';
	@override String get spellingFixed => 'Recipe corrected';
	@override String get noChanges => 'No spelling mistakes found';
	@override String get timesSynced => 'Times in the instructions were updated to match';
	@override String get discardTitle => 'Discard changes?';
	@override String get discardBody => 'Your edits will not be saved.';
	@override String get discard => 'Discard';
	@override String get saveOptionsTitle => 'How would you like to save?';
	@override String get savePlainHint => 'Save the changes as they are, no waiting';
	@override String get saveWithAi => 'Save with AI review';
	@override String get saveWithAiHint => 'Fix spelling and align the times written in the steps';
}

// Path: ingestion
class _Translations$ingestion$en extends Translations$ingestion$he {
	_Translations$ingestion$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Add a recipe';
	@override String get pasteText => 'Paste text';
	@override String get pasteHint => 'Paste a recipe here from WhatsApp or any other source';
	@override String get webSearch => 'Search the web';
	@override String get urlScrape => 'Website link';
	@override String get socialVideo => 'Social video';
	@override String get socialVideoHint => 'Paste a link to a TikTok, Instagram, YouTube or Facebook video';
	@override String get socialUnreadable => 'We could not read this video. The account may be private, or the platform blocked the request. You can copy the caption and paste it as text.';
	@override String get aiRequest => 'Ask for a recipe';
	@override String get aiRequestHint => 'Describe what you want to make. For example: semolina porridge for a one-year-old, with fruit';
	@override String get parse => 'Parse recipe';
	@override String get parsing => 'Parsing the recipe...';
	@override String get parseError => 'We couldn\'t parse the recipe';
	@override String get reviewTitle => 'Review before saving';
	@override String get notConfigured => 'This feature needs an external service that hasn\'t been set up yet';
	@override String get openOptionsTitle => 'How would you like to open this recipe?';
	@override String get viewOriginal => 'View the original';
	@override String get viewOriginalHint => 'The page text as written, unprocessed — loads instantly';
	@override String get generateStructured => 'Create a structured recipe';
	@override String get generateStructuredHint => 'Automatic extraction of ingredients, amounts and steps';
	@override String get originalTitle => 'Original recipe';
	@override String get fetchFailed => 'We could not load the page';
	@override String get loadingOriginal => 'Loading the page...';
	@override String get structuredFromSite => 'Read directly from the site\'s structured data, no AI involved';
	@override String get useStructured => 'Continue with the structured recipe';
	@override String get preferAi => 'Process with AI instead';
	@override String get analysisTimedOut => 'The analysis did not finish in time';
	@override String get analysisFailed => 'The analysis failed';
	@override String get unparsedHint => 'Your text is kept as is. Try again, edit it by hand, or save it and analyse later.';
	@override String get retryAnalysis => 'Try again';
	@override String get editManually => 'Edit manually';
	@override String get saveForLater => 'Save and analyse later';
	@override String get untitledRecipe => 'Untitled recipe';
	@override String get manual => 'Write by hand';
	@override String get manualHint => 'Fill the recipe in yourself, in the structured format — no AI, no waiting.';
	@override String get openBlankEditor => 'Open a blank editor';
	@override String get generate => 'Create recipe';
	@override String get generating => 'Writing your recipe...';
	@override String get file => 'Recording / PDF';
	@override String get fileHint => 'You can also share a recording or a PDF straight into Easy Plate from any app, through the usual share button.';
	@override String get chooseFile => 'Choose a file';
	@override String get replaceFile => 'Another file';
	@override String get fileTooLarge => 'The files are too large. The total limit is 10MB, about ten minutes of recording.';
	@override String get fileUnsupported => 'Only audio files and PDFs can be analysed.';
	@override String sharedIn({required Object app}) => 'From ${app}';
	@override String get addFile => 'Add a file';
	@override String filesAsOne({required Object count}) => '${count} files — analysed together as one recipe, in order';
	@override String get shareMoreHint => 'You can go back to WhatsApp and share another recording — it will join the list here.';
	@override String get chooseSource => 'Where is the recipe coming from?';
	@override String get pasteTextDescription => 'Got a recipe on WhatsApp, or copied one from a site or a message? Paste the text here as it is. The model picks out the dish name, the ingredients with their amounts and the steps, and lays it all out in one format. No daily limit.';
	@override String get webSearchDescription => 'Tell us what you feel like making and we will search the web for recipes. From the results you can read the original page as it is, or import it into the app’s structured format.';
	@override String get webSearchHint => 'For example: shakshuka, cheesecake, beetroot kubbeh';
	@override String get urlScrapeDescription => 'Paste a link to a recipe page on a site or blog. We read the page, skip the ads and the stories around it, and extract only the recipe: ingredients, amounts and steps. On many sites this does not even use your daily allowance.';
	@override String get urlScrapeHint => 'https://www.example.com/recipe/...';
	@override String get socialVideoDescription => 'Paste a link to a TikTok, Instagram, YouTube or Facebook video. We watch it for you, listen to what is said and read the captions and description, and turn it into a written, structured recipe. It takes about a minute.';
	@override String get aiRequestDescription => 'No recipe, just an idea? Describe the dish, who it is for and what matters to you, and the model writes a complete recipe that respects the dietary preferences you set.';
	@override String get manualDescription => 'Write the recipe yourself, straight into the structured editor: name, ingredients with amounts and units, and the steps. No AI, no waiting. Right for grandma’s recipe you know by heart.';
	@override String get fileDescription => 'Pick an audio file in which someone reads or tells the recipe, a WhatsApp voice note, or a recipe PDF. We transcribe and read all of it and extract a tidy recipe. Several files can be attached; they are analysed together as one recipe.';
}

// Path: mealPlanner
class _Translations$mealPlanner$en extends Translations$mealPlanner$he {
	_Translations$mealPlanner$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meal planning';
	@override String get newPlan => 'New plan';
	@override String get planName => 'Plan name';
	@override String get addMeal => 'Add a meal';
	@override String get mealName => 'Meal name';
	@override String get addItem => 'Add an item';
	@override String get pickRecipe => 'Pick a recipe';
	@override String get quickEntry => 'Quick item';
	@override String get noPlans => 'No plans yet. Create your first one!';
	@override String get addMealHint => 'Pick a recipe or add a quick item';
	@override String get breakfast => 'Breakfast';
	@override String get lunch => 'Lunch';
	@override String get dinner => 'Dinner';
	@override String get morningSnack => 'Morning snack';
	@override String get afternoonSnack => 'Afternoon snack';
	@override String get eveningSnack => 'Evening snack';
	@override String get template => 'Starting template';
	@override String get templateFree => 'Start empty';
	@override String get templateThree => '3 meals';
	@override String get templateSix => '6 meals';
	@override String get templateFreeHint => 'An empty plan — add meals yourself';
	@override String get templateThreeHint => 'Breakfast, lunch and dinner every day';
	@override String get templateSixHint => '3 main meals plus snacks every day';
	@override String get nameRequired => 'Give the plan a name';
	@override String get products => 'Products';
	@override String get addProduct => 'Add a product';
	@override String get productName => 'Product name';
	@override String get noProducts => 'With no products the item joins the grocery list as a single line under its own name';
	@override String get itemName => 'Item name';
	@override String get editItem => 'Edit item';
	@override String get planOptions => 'Plan options';
	@override String get deletePlan => 'Delete plan';
	@override String deletePlanConfirm({required Object name}) => 'Delete the plan "${name}"? Its meals will be deleted too.';
	@override String leavePlanConfirm({required Object name}) => 'Leave the shared plan "${name}"? It will be removed from your list.';
	@override String get planDeleted => 'Plan deleted';
}

// Path: groceryList
class _Translations$groceryList$en extends Translations$groceryList$he {
	_Translations$groceryList$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Grocery list';
	@override String get aggregated => 'Combined from all active plans';
	@override String get addItem => 'New item';
	@override String get category => 'Category';
	@override String get breakdownTitle => 'Amount sources';
	@override String get collectionProgress => 'Collection progress';
	@override String itemsCollected({required Object collected, required Object total}) => '${collected} of ${total} items collected';
	@override String get adjustAmounts => 'Adjust amounts';
	@override String get buffer => 'Extra amount';
	@override String get share => 'Share list';
	@override String get empty => 'The list is empty right now';
	@override String get uncheckedSection => 'Still to collect';
	@override String get checkedSection => 'Collected';
	@override String get selectAll => 'Select all';
	@override String get clearAll => 'Clear all';
	@override String get deleteChecked => 'Delete collected';
	@override String get amount => 'Amount';
	@override String get unit => 'Unit';
	@override String get lastSource => 'At least one source must remain';
	@override String get itemName => 'Item name';
	@override String get planFilter => 'All menus';
	@override String get choosePlans => 'Choose menus';
	@override String plansSelected({required Object count}) => '${count} menus selected';
	@override String get onePlanSelected => 'One menu selected';
	@override String get noPlansToPick => 'No menus to choose from yet';
	@override String get allPlansHint => 'Aggregated from every menu';
	@override String get selectPlansTitle => 'Which menus feed this list?';
	@override String get applySelection => 'Update list';
	@override String get selectAllPlans => 'All menus';
	@override String get myLists => 'My lists';
	@override String listsCount({required Object count}) => '${count} lists';
	@override String get oneList => 'One list';
	@override String get newList => 'New list';
	@override String get newListTitle => 'New shopping list';
	@override String get listName => 'List name';
	@override String get defaultListName => 'Shopping list';
	@override String get fromPlans => 'From menus';
	@override String get fromPlansHint => 'Combines the recipes in your meal plans';
	@override String get fromRecipe => 'From a recipe';
	@override String get fromRecipeHint => 'The ingredients of one recipe';
	@override String get emptyList => 'Empty list';
	@override String get emptyListHint => 'You add the items by hand';
	@override String get sourcePlans => 'From menus';
	@override String sourceRecipe({required Object title}) => 'From the recipe "${title}"';
	@override String get sourceManual => 'Hand-made list';
	@override String get renameList => 'Rename list';
	@override String get deleteList => 'Delete list';
	@override String deleteListConfirm({required Object name}) => '"${name}" and all its items will be deleted.';
	@override String progress({required Object checked, required Object total}) => '${checked}/${total}';
	@override String get servings => 'Servings';
	@override String get timesOver => 'Quantity';
	@override String scaleValue({required Object value}) => '×${value}';
	@override String get rebuildFromRecipe => 'Rebuild from the recipe';
	@override String get createFromRecipe => 'Create shopping list';
	@override String get createList => 'Create list';
	@override String get recipeListTitle => 'Shopping list from a recipe';
	@override String get recipeListHint => 'The recipe\'s ingredients, scaled to how much you are making';
	@override String listCreated({required Object name}) => 'The list "${name}" was created';
	@override String get openList => 'Open list';
	@override String get stayHere => 'Stay here';
	@override String get noIngredients => 'This recipe has no ingredients to shop for';
	@override String get addFirstItem => 'Add an item';
	@override String leaveListConfirm({required Object name}) => 'Leave the shared list "${name}"? It will be removed from your lists.';
}

// Path: receipt
class _Translations$receipt$en extends Translations$receipt$he {
	_Translations$receipt$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scan a receipt';
	@override String get subtitle => 'Photograph a receipt or upload a PDF, and the prices are kept for your grocery list';
	@override String get camera => 'Photograph receipt';
	@override String get cameraHint => 'Long receipt? Take several photos, we merge them';
	@override String get gallery => 'Pick from gallery';
	@override String get pdf => 'PDF file';
	@override String get addPhoto => 'Another photo';
	@override String get scan => 'Scan';
	@override String get scanning => 'Reading the receipt…';
	@override String pagesCount({required Object count}) => '${count} photos';
	@override String get scanFailed => 'We could not read the receipt. Try a sharper photo or a PDF.';
	@override String get reviewTitle => 'What was captured';
	@override String get reviewSubtitle => 'Fix names and prices before saving';
	@override String get store => 'Store';
	@override String get date => 'Date';
	@override String get receiptTotal => 'Receipt total';
	@override String get itemsTotal => 'Captured items total';
	@override String get captured => 'Captured products';
	@override String capturedCount({required Object count}) => '${count} products';
	@override String get unreadable => 'Could not capture';
	@override String get unreadableHint => 'Notes on lines we could not read. Add them by hand below if needed.';
	@override String get addLine => 'Add product';
	@override String get itemName => 'Product name';
	@override String get price => 'Unit price';
	@override String get quantity => 'Quantity';
	@override String get removeLine => 'Remove line';
	@override String get shareToggle => 'Share prices with the community';
	@override String get shareHint => 'Product names and prices only. Not the store, the date or who paid.';
	@override String get save => 'Save prices';
	@override String saved({required Object count}) => '${count} prices saved';
	@override String savedShared({required Object count}) => '${count} prices saved and shared';
	@override String get nothingToSave => 'No products to save';
	@override String get estimated => 'Estimated from past data';
	@override String get estimatedTotal => 'Estimated cost';
	@override String get noData => 'No data';
	@override String get fromReceipt => 'From your receipt';
	@override String get fromCommunity => 'Community median';
	@override String unpriced({required Object count}) => '${count} items without a price';
	@override String get priceBook => 'My prices';
	@override String get priceBookEmpty => 'No receipts scanned yet. Scan the first to see what shopping costs.';
	@override String get deleteRecord => 'Delete price';
	@override String get cameraGuide => 'Fit the receipt inside the frame';
	@override String get cameraHold => 'Hold still…';
	@override String get cameraCaptured => 'Captured!';
	@override String get cameraUnavailable => 'No camera access';
	@override String get perUnit => 'per unit';
	@override String get perKg => 'per kg';
	@override String get perLiter => 'per litre';
	@override String printedAs({required Object name}) => 'Printed: ${name}';
	@override String get receipts => 'Receipts';
	@override String get prices => 'Prices';
	@override String get sortBy => 'Sort';
	@override String get sortDate => 'Date';
	@override String get sortStore => 'Store';
	@override String get sortTotal => 'Total';
	@override String get sortName => 'Name';
	@override String get noReceipts => 'No receipts saved yet';
	@override String get noPrices => 'No prices saved yet';
	@override String get deleteReceipt => 'Delete receipt';
	@override String get deleteReceiptBody => 'The receipt and every price read from it will be deleted.';
	@override String get addPrice => 'Add price';
	@override String get addPriceHint => 'Without a receipt: a price you paid or know';
	@override String get manualSource => 'Entered by hand';
	@override String get lastPaid => 'Last paid';
	@override String get priceSaved => 'Price saved';
	@override String itemsInReceipt({required Object count}) => '${count} products';
	@override String get search => 'Search product';
	@override String get viewImage => 'Receipt image';
	@override String get noImage => 'No image was kept for this receipt';
	@override String get pdfFile => 'Receipt from a PDF file';
	@override String get filter => 'Filter';
	@override String get filterAll => 'All';
	@override String get periodAll => 'All time';
	@override String get period30 => '30 days';
	@override String get period90 => '90 days';
	@override String get sourceReceipt => 'From receipts';
	@override String get sourceManual => 'Entered by hand';
	@override String get deleteProduct => 'Delete product';
	@override String get deleteProductBody => 'Every price saved for this product will be deleted.';
	@override String get pickFromPrices => 'Pick from my prices';
	@override String get pickerTitle => 'My products';
	@override String existingPrice({required Object price}) => 'Already known: ${price}';
	@override String get keepNew => 'New price';
	@override String get keepOld => 'Old price';
	@override String get keepAverage => 'Average';
	@override String get deleteReceiptOnly => 'Delete receipt only';
	@override String get deleteReceiptOnlyHint => 'The prices read from it stay';
	@override String get deleteReceiptAndPrices => 'Delete receipt and its prices';
	@override String get deleteAll => 'Delete all prices';
	@override String get deleteAllBody => 'Every price, receipt and choice will be deleted. This cannot be undone.';
	@override String get pricingTitle => 'Which price to use';
	@override String get pricingLatest => 'Latest';
	@override String get pricingAverage => 'Average of all';
	@override String get pricingStore => 'By store';
	@override String get pricingReceipts => 'Chosen receipts';
	@override String pricingActive({required Object price}) => 'In use: ${price}';
	@override String get history => 'Price history';
	@override String get noStore => 'No store';
	@override String get pricingSaved => 'Choice saved';
	@override String get renameStore => 'Rename store';
	@override String get storeName => 'Store name';
	@override String get allStores => 'All stores';
	@override String get applyFilters => 'Apply';
	@override String get clearFilters => 'Clear';
}

// Path: unit
class _Translations$unit$en extends Translations$unit$he {
	_Translations$unit$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get gram => 'g';
	@override String get kilogram => 'kg';
	@override String get milliliter => 'ml';
	@override String get liter => 'L';
	@override String get teaspoon => 'tsp';
	@override String get tablespoon => 'tbsp';
	@override String get cup => 'cup';
	@override String get unit => 'unit';
	@override String get pinch => 'pinch';
	@override String get unspecified => '—';
}

// Path: image
class _Translations$image$en extends Translations$image$he {
	_Translations$image$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get add => 'Add a photo';
	@override String get change => 'Change photo';
	@override String get gallery => 'Choose from gallery';
	@override String get camera => 'Take a photo';
	@override String get remove => 'Remove photo';
	@override String get generate => 'Create with AI';
	@override String get generating => 'Creating a picture… this takes a few seconds';
	@override String get generateFailed => 'Creating the picture failed, please try again';
	@override String get coverTitle => 'What cover to create?';
	@override String get coverHint => 'Pick a category, write something, or both';
	@override String get coverFreeText => 'Free text, e.g. burgers';
	@override String get coverRequired => 'Pick a category or write something';
	@override String get coverGenerate => 'Create cover';
	@override String get themeKids => 'Kids';
	@override String get themeHealthy => 'Healthy';
	@override String get themeIndulgent => 'Indulgent';
	@override String get themeSweets => 'Sweets & baking';
	@override String get themeMeat => 'Meat & grill';
	@override String get themeVegan => 'Vegan';
	@override String get themeHolidays => 'Holidays';
	@override String get themeQuick => 'Quick & simple';
	@override String get webSearch => 'Search Google Images';
	@override String get webSearchTitle => 'Image search';
	@override String get webSearchHint => 'What to search for? e.g. beet kubbeh';
	@override String get webSearchEmpty => 'No pictures found, try different words';
	@override String get webSearchFailed => 'The search failed, please try again';
	@override String get webSearchUnavailable => 'Image search is not available right now';
	@override String get webSearchEnd => 'That is all the results';
	@override String get webSearchDownloadFailed => 'Could not download that picture, try another';
}

// Path: nav
class _Translations$nav$en extends Translations$nav$he {
	_Translations$nav$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get library => 'Library';
	@override String get recipes => 'Recipes';
	@override String get mealPlan => 'Meals';
	@override String get groceries => 'Groceries';
	@override String get settings => 'Settings';
	@override String get community => 'Community';
}

// Path: update
class _Translations$update$en extends Translations$update$he {
	_Translations$update$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get forcedTitle => 'Update required';
	@override String forcedBody({required Object version}) => 'This version of EasyPlate is no longer supported. Update to ${version} to continue.';
	@override String get optionalTitle => 'A new version is out';
	@override String optionalBody({required Object version}) => 'EasyPlate ${version} is in the store, with the latest improvements.';
	@override String get updateNow => 'Update now';
	@override String get later => 'Skip';
}

// Path: ads
class _Translations$ads$en extends Translations$ads$he {
	_Translations$ads$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get badge => 'Ad';
	@override String freeViewsLeft({required Object count}) => '${count} free recipes left today';
	@override String rewardedViewsLeft({required Object count}) => '${count} unlocks with a short video left today';
	@override String get sharedQuotaReached => 'You\'ve reached today\'s limit of shared recipes. It resets tomorrow!';
	@override String get unlockRecipeTitle => 'Unlock a shared recipe';
	@override String unlockRecipeMessage({required Object count}) => 'Watch a short video to unlock this recipe (${count} left today)';
	@override String aiQuotaLeft({required Object remaining, required Object total}) => '${remaining}/${total} AI extractions left today';
	@override String get aiQuotaReached => 'You\'ve reached today\'s limit of AI extractions. It reopens tomorrow!';
	@override String get aiLockedHint => 'Extracting from a link requires watching a short video';
	@override String get unlockAiTitle => 'Extract a recipe with AI';
	@override String unlockAiMessage({required Object count}) => 'Watch a short video to extract the recipe from the link (${count} left today)';
	@override String get watchVideo => 'Watch the video';
	@override String get parseWithVideo => 'Watch a video and parse';
	@override String get blockedForToday => 'Locked for today';
	@override String get loadingVideo => 'Loading the video...';
	@override String get videoNotCompleted => 'The video wasn\'t completed, the recipe stays locked';
	@override String get videoUnavailable => 'No video is available right now, try again in a moment';
}

// Path: premium
class _Translations$premium$en extends Translations$premium$he {
	_Translations$premium$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'EasyPlate Premium';
	@override String get headline => 'No ads, no limits';
	@override String get subtitle => 'Everything EasyPlate can do, without waiting for tomorrow.';
	@override String get benefitNoAds => 'No ads in the community feeds';
	@override String get benefitShared => 'Shared recipes with no daily limit';
	@override String benefitAi({required Object count}) => 'AI recipe extraction from any link, up to ${count} a day';
	@override String get periodWeekly => 'Weekly';
	@override String get periodMonthly => 'Monthly';
	@override String get periodTwoMonth => 'Every 2 months';
	@override String get periodThreeMonth => 'Quarterly';
	@override String get periodSixMonth => 'Every 6 months';
	@override String get periodAnnual => 'Yearly';
	@override String get periodLifetime => 'Lifetime';
	@override String get bestValue => 'Best value';
	@override String subscribeFor({required Object price}) => 'Subscribe for ${price}';
	@override String buyFor({required Object price}) => 'Buy for ${price}';
	@override String get restore => 'Restore purchases';
	@override String get restored => 'Your subscription was restored';
	@override String get nothingToRestore => 'No purchases to restore';
	@override String get activeTitle => 'Premium is active';
	@override String get activeBody => 'Thank you! Ads and daily limits are off for this account.';
	@override String get manage => 'Manage subscription';
	@override String get cancel => 'Cancel subscription';
	@override String get cancelNote => 'Cancelling turns off auto-renewal. Premium stays active until the end of the period already paid for. No refunds.';
	@override String get unavailable => 'Subscriptions are not available right now. Please try again later.';
	@override String get purchaseFailed => 'The purchase did not go through';
	@override String get purchased => 'Welcome to Premium!';
	@override String get legal => 'The subscription renews automatically at the end of each period unless cancelled at least 24 hours before it ends. Payment is charged to your store account and can be managed or cancelled in the store\'s settings.';
	@override String get terms => 'Terms of Use';
	@override String get privacy => 'Privacy Policy';
	@override String startFor({required Object price}) => 'Start for ${price}';
	@override String get startFree => 'Start free';
	@override String get free => 'Free';
	@override String introDays({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'for the first day',
		other: 'for the first ${n} days',
	);
	@override String introWeeks({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'for the first week',
		other: 'for the first ${n} weeks',
	);
	@override String introMonths({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'for the first month',
		other: 'for the first ${n} months',
	);
	@override String introYears({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'for the first year',
		other: 'for the first ${n} years',
	);
	@override String introPaidTerms({required Object price, required Object span, required Object then}) => '${price} ${span}, then ${then}. The price updates automatically.';
	@override String introFreeTerms({required Object span, required Object then}) => 'Free ${span}, then ${then}. Billing starts automatically.';
	@override String get redeem => 'I have a coupon code';
	@override String get redeemTitle => 'Coupon code';
	@override String get redeemHint => 'Type the code you received';
	@override String get redeemConfirm => 'Redeem in the store';
	@override String get perWeekly => 'per week';
	@override String get perMonthly => 'per month';
	@override String get perTwoMonth => 'every 2 months';
	@override String get perThreeMonth => 'every 3 months';
	@override String get perSixMonth => 'every 6 months';
	@override String get perAnnual => 'per year';
	@override String get tierPro => 'Pro';
	@override String get tierDuo => 'Pro Duo';
	@override String get tierFamily => 'Pro Family';
	@override String get tierProHint => 'One account';
	@override String get tierDuoHint => '2 accounts, everything mirrored';
	@override String get tierFamilyHint => 'Up to 6 accounts, everything mirrored';
	@override String benefitHousehold({required Object n}) => 'Shared account for ${n} people: recipes, plans and lists in sync';
}

// Path: walkthrough
class _Translations$walkthrough$en extends Translations$walkthrough$he {
	_Translations$walkthrough$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guide';
	@override String get start => 'Start the guide';
	@override String get startHint => 'A guided tour of everything in the app, step by step';
	@override String get startFull => 'Start the full tour';
	@override String get focused => 'Show focused guidance';
	@override String get next => 'Next';
	@override String get finish => 'Done';
	@override String get skipStep => 'Skip step';
	@override String get close => 'Close guide';
	@override String stepOf({required Object current, required Object total}) => 'Step ${current} of ${total}';
	@override String get tapHint => 'Tap the highlighted area, or "Next"';
	@override String get bookTitle => 'EasyPlate guide';
	@override String get bookSubtitle => 'Everything the app can do, chapter by chapter. The samples in this book are never saved; the live tour does the real actions, with the fields already filled in.';
	@override String get contents => 'Contents';
	@override String chapter({required Object number}) => 'Chapter ${number}';
	@override String get backToContents => 'Back to contents';
	@override String get stepsTitle => 'Steps';
	@override String get welcomeTitle => 'Welcome to EasyPlate';
	@override String get welcomeBody => 'Let\'s walk through the main actions together and really do them: the fields are already filled in for you. Skip any step, or close and start again from the support screen.';
	@override late final _Translations$walkthrough$topics$en topics = _Translations$walkthrough$topics$en._(_root);
	@override late final _Translations$walkthrough$demo$en demo = _Translations$walkthrough$demo$en._(_root);
	@override String get demoRecipes => 'Sample recipes';
	@override String get demoRecipesHint => 'This is what recipes look like in the app. Tap one to see its full page: times, topics, allergens, ingredients and steps.';
	@override String get demoBooks => 'Sample books';
	@override String get demoBooksHint => 'This is what a recipe book looks like. Tap one to open it, turn its pages and jump from the contents.';
	@override String get demoOnly => 'Sample only, not saved';
}

// Path: feedback
class _Translations$feedback$en extends Translations$feedback$he {
	_Translations$feedback$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Report and suggest';
	@override String get subtitle => 'Found a bug? Have an idea? Write to us here; every message is read.';
	@override String get bug => 'Bug';
	@override String get suggestion => 'Suggestion';
	@override String get bugHint => 'Describe the bug: what you did, what happened, and what you expected...';
	@override String get suggestionHint => 'Tell us what you would like the app to do, and how it would help you...';
	@override String get send => 'Send';
	@override String get sent => 'Thanks! Your message was sent.';
	@override String get failed => 'Sending failed, please try again later';
	@override String get admin => 'Feedback inbox';
	@override String get all => 'All';
	@override String get bugs => 'Bugs';
	@override String get suggestions => 'Suggestions';
	@override String get none => 'No messages yet';
	@override String version({required Object version}) => 'Version ${version}';
	@override String get notAllowed => 'This screen is for the administrator only';
}

// Path: adminBilling
class _Translations$adminBilling$en extends Translations$adminBilling$he {
	_Translations$adminBilling$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Subscriptions';
	@override String get all => 'All';
	@override String get paying => 'Paying';
	@override String get problems => 'Problems';
	@override String get searchHint => 'Search by name, email, phone or uid';
	@override String get none => 'No accounts to show';
	@override String get premium => 'Premium';
	@override String get free => 'Free';
	@override String untilDate({required Object date}) => 'Until ${date}';
	@override String get adminLocked => 'Set by admin';
	@override String get viaRevenueCat => 'From RevenueCat';
	@override String get sandbox => 'Sandbox';
	@override String lastEvent({required Object type, required Object date}) => '${type} · ${date}';
	@override String product({required Object id}) => 'Product: ${id}';
	@override String eventsCount({required Object count}) => '${count} events';
	@override String get grant => 'Grant premium';
	@override String get revoke => 'Revoke premium';
	@override String get release => 'Return to RevenueCat';
	@override String get releaseHint => 'Set by hand: RevenueCat\'s next event is ignored until released.';
	@override String get granted => 'Premium granted';
	@override String get revoked => 'Premium revoked';
	@override String get released => 'Back under RevenueCat';
	@override String revokeConfirm({required Object name}) => 'Revoke premium for ${name}?';
	@override String get problemPaidNotPremium => 'Paid, but the account is not premium';
	@override String get problemNoEntitlement => 'A purchase arrived without the entitlement (product not attached in RevenueCat)';
	@override String get orphanTitle => 'Purchases without an account';
	@override String get orphanBody => 'Receipts that arrived under an anonymous RevenueCat id, with no user to unlock';
	@override String summary({required Object premium, required Object problems, required Object total}) => '${premium} premium · ${problems} problems · ${total} accounts';
	@override String get noEntitlementTag => 'No entitlement';
}

// Path: adminDashboard
class _Translations$adminDashboard$en extends Translations$adminDashboard$he {
	_Translations$adminDashboard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Admin dashboard';
	@override String get tabDashboard => 'Overview';
	@override String get tabSubscriptions => 'Subscriptions';
	@override String get tabTickets => 'Tickets';
	@override String get rangeToday => 'Today';
	@override String get rangeMonth => '30 days';
	@override String get rangeAll => 'All';
	@override String get aiCost => 'AI cost';
	@override String get aiCostHint => 'tokens × price list';
	@override String get revenue => 'Revenue';
	@override String get revenueNone => 'No payments in range';
	@override String sandboxNote({required Object count}) => '${count} sandbox payments not counted';
	@override String paymentsCount({required Object count}) => '${count} payments';
	@override String get aiCalls => 'AI calls';
	@override String cacheSaved({required Object count}) => '${count} from cache (free)';
	@override String errorsCount({required Object count}) => '${count} errors';
	@override String get tokens => 'Tokens';
	@override String tokensHint({required Object input, required Object output}) => 'in ${input} · out ${output}';
	@override String get usersTotal => 'Total users';
	@override String newUsers({required Object count}) => '${count} new in range';
	@override String disabledCount({required Object count}) => '${count} blocked';
	@override String get premiumUsers => 'Paying';
	@override String freeCount({required Object count}) => '${count} free';
	@override String get freeUsers => 'Free';
	@override String get activeUsers => 'Active AI users';
	@override String get costPerUser => 'Cost per active user';
	@override String get tickets => 'Tickets';
	@override String unreadCount({required Object count}) => '${count} new';
	@override String get chartCost => 'AI cost per day';
	@override String get chartCalls => 'AI calls per day';
	@override String get chartSignups => 'Sign-ups per day';
	@override String get chartPlatform => 'Users by platform';
	@override String get chartPlan => 'Free vs paying';
	@override String get chartKinds => 'Calls by feature';
	@override String get chartModels => 'Cost by model';
	@override String get chartVersions => 'App versions';
	@override String get platformIos => 'iOS';
	@override String get platformAndroid => 'Android';
	@override String get platformUnknown => 'Unknown';
	@override String get noAiUsage => 'No AI usage in this range';
	@override String get unknownModel => 'not in price list';
	@override String get usersCost => 'Cost per user';
	@override String usersCount({required Object count}) => '${count} users';
	@override String get searchUser => 'Search by name, email or uid';
	@override String showAll({required Object count}) => 'Show all ${count} users';
	@override String callsCount({required Object count}) => '${count} calls';
	@override String get content => 'Content and community';
	@override String get sharedRecipes => 'Shared recipes';
	@override String get forumPosts => 'Forum threads';
	@override String get withPush => 'Devices with push';
	@override String get cacheEntries => 'Cached links';
	@override String get cacheHits => 'Cache hits (calls saved)';
	@override String get config => 'Remote config';
	@override String get environment => 'Environment';
	@override String get prod => 'Production';
	@override String get dev => 'Dev';
	@override String get adsEnabled => 'Ads';
	@override String get adsFailOpen => 'Fail open with no ad';
	@override String get on => 'On';
	@override String get off => 'Off';
	@override String get feedInterval => 'Feed ad interval';
	@override String get quotaSharedFree => 'Free views per day';
	@override String get quotaSharedRewarded => 'Video views per day';
	@override String get quotaAiRewarded => 'Video AI per day';
	@override String get quotaAiPremium => 'Premium AI per day';
	@override String get minVersion => 'Minimum version';
	@override String get latestVersion => 'Latest version';
	@override String get thisBuild => 'This build';
	@override String get pricing => 'Token price list';
	@override String get pricingHint => 'US dollars per million tokens. The defaults are an estimate — update them from Google\'s price list.';
	@override String get editPricing => 'Edit price list';
	@override String get priceInput => 'Input';
	@override String get priceOutput => 'Output';
	@override String get priceCached => 'Cached input';
	@override String get usdToIls => 'USD/ILS rate';
	@override String get pricingSaved => 'Price list saved';
	@override String loadedAt({required Object date}) => 'Updated ${date}';
	@override String get kindText => 'Text';
	@override String get kindUrl => 'Link';
	@override String get kindSocial => 'Social';
	@override String get kindSocialVideo => 'Video (server)';
	@override String get kindVideo => 'Video';
	@override String get kindSearch => 'Search';
	@override String get kindImage => 'Image';
	@override String get kindReceipt => 'Receipt';
	@override String get kindNutrition => 'Nutrition';
	@override String get kindRefine => 'Refine';
	@override String get kindGenerate => 'Generate';
	@override String get allTime => 'all time';
	@override String get recentCalls => 'Recent calls';
	@override String get noCalls => 'No calls';
	@override String get cacheHit => 'cache';
	@override String get statusOk => 'ok';
	@override String get pushTitle => 'Title (optional)';
	@override String get pushBody => 'Message';
	@override String get send => 'Send';
	@override String get blocked => 'Blocked';
	@override String get disable => 'Block account';
	@override String get enable => 'Unblock';
	@override String get blockMessageHint => 'What the user sees when they try to sign in';
	@override String get disabledDone => 'Account blocked';
	@override String get enabledDone => 'Block removed';
	@override String get deleteAccount => 'Delete account';
	@override String deleteAccountConfirm({required Object name}) => 'Delete ${name} for good? The user, their recipes, books and plans will be removed and cannot be restored.';
	@override String get deleted => 'Account deleted';
	@override String get sendPush => 'Send notification';
	@override String get noPush => 'This device has no push token — the message will only show in the notifications screen';
	@override String get pushSent => 'Notification sent';
	@override String get sendPushAll => 'Notify all users';
	@override String broadcastConfirm({required Object count}) => 'Send this message to all ${count} users?';
	@override String broadcastDone({required Object items, required Object sent, required Object failed}) => 'Written to ${items} inboxes · ${sent} pushes sent · ${failed} failed';
	@override String platformTag({required Object platform, required Object version}) => '${platform} · v${version}';
	@override String lastSeen({required Object date}) => 'Last seen ${date}';
	@override String disabledSince({required Object message}) => 'Block reason: ${message}';
	@override String get unread => 'New';
	@override String get markAllRead => 'Read all';
	@override String get allRead => 'All tickets marked read';
	@override String get noUnread => 'No new tickets';
	@override String get deleteTicket => 'Delete ticket';
	@override String deleteTicketConfirm({required Object name}) => 'Delete the ticket from ${name}?';
	@override String get ticketDeleted => 'Ticket deleted';
	@override String get reply => 'Reply';
	@override String get replyHint => 'The reply lands in the user\'s notifications (and as a push)';
	@override String get replySent => 'Reply sent';
	@override String yourReply({required Object date}) => 'Your reply · ${date}';
	@override String get markRead => 'Mark read';
	@override String get markUnread => 'Mark unread';
	@override String get pricingSync => 'Sync prices from Google';
	@override String pricingSynced({required Object count}) => '${count} models updated from the Google Cloud Billing catalog';
	@override String pricingSyncFailed({required Object reason}) => 'Sync failed: ${reason}';
	@override String pricingSourceCatalog({required Object date}) => 'Source: Google Cloud Billing (real list prices) · ${date}';
	@override String pricingSourceManual({required Object date}) => 'Source: entered by hand · ${date}';
	@override String get pricingSourceDefaults => 'Estimate only — tap sync to pull the real prices from Google';
	@override String get searchPrice => 'Google Search grounding (\$ per 1,000 queries)';
	@override String rateLine({required Object rate, required Object date}) => '${rate} · refreshed weekly · ${date}';
	@override String searchesCount({required Object count}) => '${count} searches';
	@override String get rangeCustom => 'Pick';
	@override String customRange({required Object from, required Object to}) => '${from} – ${to} · tap to change';
	@override String get priceImageOutput => 'Image output';
	@override String dataSince({required Object date}) => 'Data is collected from ${date}. Earlier Google charges are not recorded here.';
	@override String grantTitle({required Object name}) => 'Premium for ${name} — for how long?';
	@override String get grantForever => 'Forever (until I revoke)';
	@override String get grantWeek => 'A week';
	@override String get grantMonth => 'A month';
	@override String get grantYear => 'A year';
	@override String get grantRange => 'Exact date range';
	@override String grantedUntil({required Object date}) => 'Premium granted until ${date}';
	@override String grantStarts({required Object date}) => 'Starts ${date}';
	@override String get tabConfig => 'Config';
	@override String get releaseSession => 'Disconnect the signed-in device';
	@override String get releaseSessionDone => 'Device disconnected; the user will be asked to sign in again';
}

// Path: assistant
class _Translations$assistant$en extends Translations$assistant$he {
	_Translations$assistant$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shefi';
	@override String get subtitle => 'Your sous-chef: ask, plan, shop, cook';
	@override String get placeholder => 'Ask or tell me what to do…';
	@override String get send => 'Send';
	@override String get thinking => 'Thinking…';
	@override String working({required Object tool}) => 'Working: ${tool}';
	@override String welcome({required Object name}) => 'Hi ${name}! I can add groceries, plan your week, import recipes from links, start cook mode and more. What shall we do?';
	@override String get error => 'Something went wrong. Try again.';
	@override String get quotaReached => 'Today\'s AI allowance is used up. It reopens tomorrow.';
	@override String get premiumOnly => 'Shefi is part of EasyPlate Premium';
	@override String get unlock => 'See Premium';
	@override String get clear => 'New conversation';
	@override String get openResult => 'Open';
	@override String get done => 'Done';
	@override String get undone => 'Reverted';
	@override String get confirmTitle => 'Delete?';
	@override String confirmBody({required Object what}) => '${what} will be deleted.';
	@override String notFound({required Object name}) => 'I couldn\'t find "${name}".';
	@override String get listTitle => 'Grocery list';
	@override String addedItems({required Object count}) => 'Added ${count} items';
	@override String plannedMeal({required Object day, required Object slot}) => 'Planned for ${day} · ${slot}';
	@override String get recipeSaved => 'Recipe saved';
	@override String get cookStarted => 'Cook mode started';
	@override String timerSet({required Object n}) => 'Timer set for step ${n}';
	@override String get prefSaved => 'Preference saved';
	@override String get needsPremium => 'That needs EasyPlate Premium.';
	@override String results({required Object count}) => '${count} results';
	@override late final _Translations$assistant$suggest$en suggest = _Translations$assistant$suggest$en._(_root);
	@override String get whichList => 'Which list?';
	@override String get listCreated => 'List created';
	@override String get offTopic => 'I\'m here for cooking, recipes, meal plans and groceries. Ask me anything in the kitchen and I\'m on it!';
	@override String get welcomeAnon => 'Hi! I can add groceries, plan your week, import recipes from links, start cook mode and more. What shall we do?';
	@override String scopedWelcome({required Object name}) => 'What would you like to know about "${name}"?';
	@override String scopedOffTopic({required Object name}) => 'Here I only help with "${name}". For anything else, open Shefi from the menu.';
	@override String get askAboutRecipe => 'Ask Shefi about this recipe';
	@override String get askAboutPlan => 'Ask Shefi about this plan';
	@override String get askAboutList => 'Ask Shefi about this list';
	@override String get listen => 'Talk to Shefi';
	@override String get stopListening => 'Stop listening';
	@override String get speakReplies => 'Read replies aloud';
	@override String get micUnavailable => 'The microphone cannot be used. Check the microphone and speech recognition permissions in the device settings.';
	@override late final _Translations$assistant$scopedPrompts$en scopedPrompts = _Translations$assistant$scopedPrompts$en._(_root);
	@override String get listening => 'Listening…';
	@override String get stop => 'Stop';
	@override String get cancelled => 'Cancelled.';
}

// Path: shareCode
class _Translations$shareCode$en extends Translations$shareCode$he {
	_Translations$shareCode$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Code & link';
	@override String get tabContact => 'Contact';
	@override String get tabCode => 'Code or link';
	@override String explain({required Object role}) => 'Anyone with this code can join as ${role}. It works for 30 days.';
	@override String get create => 'Create code';
	@override String get code => 'Code';
	@override String get link => 'Link';
	@override String get copy => 'Copy';
	@override String get copied => 'Copied';
	@override String get share => 'Share';
	@override String get showQr => 'Show QR';
	@override String get scanQr => 'Scan QR';
	@override String get enterCode => 'Enter a code';
	@override String get join => 'Join';
	@override String get joinTitle => 'Join with a code';
	@override String get joinHint => 'Paste the code you received, or scan its QR.';
	@override String get joinPlaceholder => 'XXXXXXXX';
	@override String joined({required Object title}) => 'Joined: ${title}';
	@override String get alreadyMember => 'You already have this.';
	@override String get invalid => 'That code is not valid.';
	@override String get expired => 'This code has expired.';
	@override String get revoked => 'This code was cancelled.';
	@override String get usedUp => 'This code has been used up.';
	@override String get self => 'That is your own code.';
	@override String get gone => 'What this code shared no longer exists.';
	@override String get failed => 'Could not join. Try again.';
	@override String messageText({required Object name, required Object title, required Object code, required Object link}) => '${name} shared "${title}" with you on EasyPlate. Code: ${code}\n${link}';
	@override String get revoke => 'Cancel code';
	@override String limitRecipes({required Object count}) => 'Free accounts can share up to ${count} recipes a week.';
	@override String limitBooks({required Object count}) => 'Free accounts can share up to ${count} books.';
	@override String limitPlans({required Object count}) => 'Free accounts can share up to ${count} meal plans.';
	@override String get upgrade => 'See Premium';
	@override String get scanHint => 'Point the camera at a share QR';
	@override String householdMessage({required Object name, required Object code, required Object link}) => '${name} invited you to their shared EasyPlate account. Code: ${code}\n${link}';
	@override String limitLists({required Object count}) => 'Free accounts can share up to ${count} grocery lists.';
}

// Path: household
class _Translations$household$en extends Translations$household$he {
	_Translations$household$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Shared account';
	@override String get duo => 'Pro Duo';
	@override String get family => 'Pro Family';
	@override String seats({required Object used, required Object total}) => '${used} of ${total} seats in use';
	@override String get intro => 'Open a shared account: recipes, books, plans and lists are mirrored for everyone in it, and they get Premium with you.';
	@override String get create => 'Open shared account';
	@override String get nameHint => 'Name, e.g. the Cohens';
	@override String get notEligible => 'A shared account comes with Pro Duo (2 accounts) or Pro Family (up to 6 accounts).';
	@override String get seePlans => 'See plans';
	@override String get members => 'Members';
	@override String get owner => 'Owner';
	@override String get you => 'You';
	@override String get invite => 'Invite a member';
	@override String inviteExplain({required Object free}) => 'Anyone with this code joins the shared account. ${free} seats left.';
	@override String get noSeats => 'All seats are taken.';
	@override String get remove => 'Remove';
	@override String removeConfirm({required Object name}) => 'Remove ${name} from the shared account? They lose access and Premium.';
	@override String get leave => 'Leave shared account';
	@override String get leaveConfirm => 'Leave? What was saved here stays with the shared account; your own account goes back to what you had before.';
	@override String get dissolve => 'Close shared account';
	@override String get dissolveConfirm => 'Close the shared account? Members lose access and Premium. Your data comes back to your own account.';
	@override String get joined => 'Welcome to the shared account!';
	@override String inheritedNote({required Object name}) => 'Premium comes from ${name}\'s subscription.';
	@override String get failed => 'That did not work. Try again.';
	@override String get full => 'The shared account is full.';
	@override String get inHousehold => 'You are already in a shared account.';
	@override String get notEligibleCode => 'The owner\'s plan no longer includes a shared account.';
	@override String get lapsed => 'The owner\'s subscription has ended; Premium is paused for members.';
}

// Path: feature
class _Translations$feature$en extends Translations$feature$he {
	_Translations$feature$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get comingSoon => 'Coming soon';
	@override String get comingSoonMessage => 'This feature is coming soon';
	@override String get unavailable => 'This feature is not available right now';
	@override String get premiumOnly => 'Premium';
	@override String get premiumOnlyMessage => 'This feature is for Premium subscribers';
	@override String get premiumOnlyTitle => 'Premium only';
	@override String premiumOnlyFor({required Object name}) => '"${name}" is open to Premium subscribers only';
	@override String get goPremium => 'Go Premium';
}

// Path: featureName
class _Translations$featureName$en extends Translations$featureName$he {
	_Translations$featureName$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get books => 'Recipe books';
	@override String get mealPlans => 'Meal plans';
	@override String get groceryLists => 'Grocery lists';
	@override String get community => 'Community';
	@override String get ingestText => 'Recipe from text';
	@override String get ingestWebSearch => 'Recipe web search';
	@override String get ingestLink => 'Recipe from a link';
	@override String get ingestSocialVideo => 'Recipe from a video';
	@override String get ingestAiRequest => 'Ask AI for a recipe';
	@override String get ingestFile => 'Recipe from a file';
	@override String get shareIn => 'Share from another app';
	@override String get saveWithAi => 'Save with AI';
	@override String get cookMode => 'Cook mode';
	@override String get cookTimers => 'Cooking timers';
	@override String get nutrition => 'Nutrition';
	@override String get recipeImageAi => 'AI picture';
	@override String get recipeImageSearch => 'Google image search';
	@override String get groceryFromRecipe => 'Grocery list from a recipe';
	@override String get sharedRecipes => 'Shared recipes';
	@override String get forum => 'Forum';
	@override String get likes => 'Likes';
	@override String get shareRecipes => 'Recipe sharing';
	@override String get shareBooks => 'Book sharing';
	@override String get sharePlans => 'Meal plan sharing';
	@override String get shareGroceryLists => 'Grocery list sharing';
	@override String get shareCodes => 'Share codes';
	@override String get households => 'Household';
	@override String get priceBook => 'Price book';
	@override String get receiptScan => 'Receipt scan';
	@override String get groceryCost => 'Estimated cost';
	@override String get shoppingReminder => 'Shopping reminder';
	@override String get assistant => 'Shefi (the assistant)';
	@override String get notifications => 'Notifications';
	@override String get premium => 'Premium';
	@override String get contentTranslation => 'Content translation';
	@override String get theming => 'Appearance';
	@override String get walkthrough => 'Guided tour';
	@override String get tutorialBook => 'Tutorial book';
	@override String get feedback => 'Feedback';
	@override String get assistantScoped => 'Shefi inside an item';
	@override String get assistantVoice => 'Voice with Shefi';
	@override String get singleSession => 'One device per account';
}

// Path: adminConfig
class _Translations$adminConfig$en extends Translations$adminConfig$he {
	_Translations$adminConfig$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get intro => 'Every value here is Firebase Remote Config. A change is published to all users at once (default values; console conditions are left as they are).';
	@override String get loadFailed => 'Could not load the configuration';
	@override String get saveFailed => 'Publishing failed. Check the value and try again';
	@override String saved({required Object name}) => '"${name}" published';
	@override String count({required Object n}) => '${n} settings';
	@override String get searchAll => 'Search all settings';
	@override String searchIn({required Object section}) => 'Search in ${section}';
	@override String noResults({required Object query}) => 'No setting matches "${query}"';
	@override String get filterAll => 'All';
	@override String get clearSearch => 'Clear search';
	@override String get noFlagsInState => 'No features in this state';
	@override late final _Translations$adminConfig$groups$en groups = _Translations$adminConfig$groups$en._(_root);
	@override late final _Translations$adminConfig$flag$en flag = _Translations$adminConfig$flag$en._(_root);
	@override late final _Translations$adminConfig$labels$en labels = _Translations$adminConfig$labels$en._(_root);
}

// Path: walkthrough.topics
class _Translations$walkthrough$topics$en extends Translations$walkthrough$topics$he {
	_Translations$walkthrough$topics$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$walkthrough$topics$addRecipe$en addRecipe = _Translations$walkthrough$topics$addRecipe$en._(_root);
	@override late final _Translations$walkthrough$topics$myRecipes$en myRecipes = _Translations$walkthrough$topics$myRecipes$en._(_root);
	@override late final _Translations$walkthrough$topics$library$en library = _Translations$walkthrough$topics$library$en._(_root);
	@override late final _Translations$walkthrough$topics$mealPlan$en mealPlan = _Translations$walkthrough$topics$mealPlan$en._(_root);
	@override late final _Translations$walkthrough$topics$groceries$en groceries = _Translations$walkthrough$topics$groceries$en._(_root);
	@override late final _Translations$walkthrough$topics$community$en community = _Translations$walkthrough$topics$community$en._(_root);
	@override late final _Translations$walkthrough$topics$account$en account = _Translations$walkthrough$topics$account$en._(_root);
	@override late final _Translations$walkthrough$topics$settings$en settings = _Translations$walkthrough$topics$settings$en._(_root);
}

// Path: walkthrough.demo
class _Translations$walkthrough$demo$en extends Translations$walkthrough$demo$he {
	_Translations$walkthrough$demo$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get bookTitle => 'Tutorial';
	@override String get planName => 'Tutorial plan';
	@override String get mealName => 'Dinner';
	@override String get groceryItem => 'Tomatoes';
	@override String get recipeText => 'Jerusalem shakshuka\n\nIngredients:\n400 g crushed tomatoes\n4 eggs\n1 onion\n2 tbsp olive oil\n1 tsp sweet paprika\nA pinch of salt\n\nMethod:\n1. Heat the olive oil in a pan and fry the onion until golden.\n2. Add the tomatoes and paprika and simmer for 10 minutes.\n3. Crack the eggs into the sauce, cover, and cook until the whites set.';
}

// Path: assistant.suggest
class _Translations$assistant$suggest$en extends Translations$assistant$suggest$he {
	_Translations$assistant$suggest$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override List<String> get templates => [
		'Add {food} to my grocery list',
		'Add {food} and {food2} to the list',
		'Plan {dish} for {day} {meal}',
		'Plan something quick for {day} {meal}',
		'What can I cook with {food} and {food2}?',
		'Import a recipe from {site}',
		'Find a recipe for {dish} online',
		'Start cooking {dish}',
		'Set a {n}-minute timer for step 2',
		'Make a grocery list from {dish}',
		'Create a book called {book}',
		'Which of my recipes are {diet}?',
		'Mark {food} as bought',
		'Remove {food} from the list',
		'Create a plan for next week',
		'Show me what\'s planned for {day}',
		'Change my shopping day to {day}',
		'Suggest a {diet} dinner for {day}',
		'How long do I boil an egg?',
		'What can replace {food} in a recipe?',
		'How do I store {food}?',
		'How many calories are in {dish}?',
		'What\'s the right oven temperature for {dish}?',
		'How do I make {dish} vegan?',
		'How much is {n} tablespoons in grams?',
		'Why did my {dish} come out dry?',
		'What goes well with {dish}?',
		'Is {food} safe to freeze?',
		'How do I thicken a sauce?',
		'What\'s a quick {diet} lunch idea?',
	];
	@override List<String> get food => [
		'milk',
		'eggs',
		'bread',
		'tomatoes',
		'onions',
		'olive oil',
		'rice',
		'chicken',
		'lemons',
		'garlic',
		'butter',
		'flour',
		'cheese',
		'yogurt',
		'cucumbers',
		'pasta',
	];
	@override List<String> get dish => [
		'shakshuka',
		'lentil soup',
		'pasta pesto',
		'chicken curry',
		'salmon',
		'stir-fry',
		'pancakes',
		'hummus',
		'roast vegetables',
		'banana bread',
	];
	@override List<String> get day => [
		'Sunday',
		'Monday',
		'Tuesday',
		'Wednesday',
		'Thursday',
		'Friday',
		'Saturday',
		'tomorrow',
	];
	@override List<String> get meal => [
		'breakfast',
		'lunch',
		'dinner',
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
		'TikTok',
		'Instagram',
		'YouTube',
		'a blog',
	];
	@override List<String> get book => [
		'Weeknights',
		'Shabbat',
		'Kids',
		'Desserts',
	];
	@override List<String> get diet => [
		'vegetarian',
		'vegan',
		'gluten-free',
		'dairy',
	];
}

// Path: assistant.scopedPrompts
class _Translations$assistant$scopedPrompts$en extends Translations$assistant$scopedPrompts$he {
	_Translations$assistant$scopedPrompts$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override List<String> get recipe => [
		'What is the nutrition per serving?',
		'How do I make it for 8 people?',
		'What can I substitute for an ingredient I lack?',
		'Add this recipe to tomorrow’s plan',
		'Create a grocery list from this recipe',
	];
	@override List<String> get mealPlan => [
		'What are we eating today?',
		'Add a dinner on Tuesday',
		'What is missing this week?',
		'Create a grocery list from this plan',
		'How many calories on Wednesday?',
	];
	@override List<String> get groceryList => [
		'What is left to buy?',
		'Add milk and eggs',
		'Mark the tomatoes as bought',
		'Remove what I already bought',
		'How much is 2 cups of flour in grams?',
	];
}

// Path: adminConfig.groups
class _Translations$adminConfig$groups$en extends Translations$adminConfig$groups$he {
	_Translations$adminConfig$groups$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get features => 'Features';
	@override String get adsQuotas => 'Ads and quotas';
	@override String get sharing => 'Sharing on a free account';
	@override String get voice => 'Shefi\'s voice';
	@override String get versions => 'Versions and environment';
	@override String get gemini => 'AI server (needs a deploy)';
	@override String get other => 'Other';
}

// Path: adminConfig.flag
class _Translations$adminConfig$flag$en extends Translations$adminConfig$flag$he {
	_Translations$adminConfig$flag$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get hidden => 'Hidden';
	@override String get comingSoon => 'Coming soon';
	@override String get everyone => 'Free';
	@override String get premium => 'Premium';
}

// Path: adminConfig.labels
class _Translations$adminConfig$labels$en extends Translations$adminConfig$labels$he {
	_Translations$adminConfig$labels$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ads_enabled => 'Ads enabled';
	@override String get ads_fail_open => 'Open when no video';
	@override String get ads_feed_interval => 'Ad interval in feeds';
	@override String get quota_shared_free => 'Free shared recipes per day';
	@override String get quota_shared_rewarded => 'Shared recipes after a video';
	@override String get quota_ai_rewarded => 'AI imports after a video per day';
	@override String get share_free_recipes_weekly => 'Recipe shares per week';
	@override String get share_free_books_total => 'Shared books at once';
	@override String get share_free_plans_total => 'Shared plans at once';
	@override String get share_free_lists_total => 'Shared grocery lists at once';
	@override String get tts_cloud_enabled => 'Cloud voice (Google)';
	@override String get tts_voice_he => 'Hebrew voice';
	@override String get tts_voice_en => 'English voice';
	@override String get tts_voice_ar => 'Arabic voice';
	@override String get tts_voice_fr => 'French voice';
	@override String get tts_voice_ru => 'Russian voice';
	@override String get isProd => 'Production version';
	@override String get minimumVersion => 'Minimum version';
	@override String get latestVersion => 'Latest version';
	@override String get iosAppStoreId => 'App Store ID';
	@override String get gemini_minInstances => 'Minimum instances';
	@override String get gemini_maxInstances => 'Maximum instances';
	@override String get gemini_timeoutSeconds => 'Call timeout (seconds)';
	@override String get session_days => 'Session length (days)';
	@override String get presence_heartbeat_seconds => 'Presence heartbeat (seconds)';
}

// Path: walkthrough.topics.addRecipe
class _Translations$walkthrough$topics$addRecipe$en extends Translations$walkthrough$topics$addRecipe$he {
	_Translations$walkthrough$topics$addRecipe$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Add a recipe';
	@override String get summary => 'Bring a recipe in from any source and the AI arranges it into one format: ingredients, amounts, steps, tags, servings and nutrition.';
	@override String get s1 => 'Tap the sparkle button next to the title to add a recipe.';
	@override String get s2 => 'Pick a source: pasted text, a web search, a website link, a video from TikTok, Instagram, YouTube or Facebook, a free request to the AI, or writing by hand.';
	@override String get s3 => 'A sample recipe is filled in here, just as you would paste one. The button below sends it to the AI, which returns a tidy recipe to review, edit and save. The analysis takes up to half a minute, so leave it for after the tour.';
}

// Path: walkthrough.topics.myRecipes
class _Translations$walkthrough$topics$myRecipes$en extends Translations$walkthrough$topics$myRecipes$he {
	_Translations$walkthrough$topics$myRecipes$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'My recipes and saved';
	@override String get summary => 'The recipes you wrote and the ones you saved from the community, with search and topic filters.';
	@override String get s1 => 'Switch here between recipes you wrote and recipes you saved from the community.';
	@override String get s2 => 'Search by name, and filter by topic: meat, dairy, vegetarian, vegan, kosher, gluten-free and allergy. Every recipe also marks the allergens in it.';
}

// Path: walkthrough.topics.library
class _Translations$walkthrough$topics$library$en extends Translations$walkthrough$topics$library$he {
	_Translations$walkthrough$topics$library$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Recipe books';
	@override String get summary => 'Arrange recipes into books with a table of contents, a cover and page turning, and share a whole book with another account.';
	@override String get s1 => 'Tap "Library" to go to your books.';
	@override String get s2 => 'Tap the plus to create a new book.';
	@override String get s3 => 'The book\'s name is already filled in: "Tutorial". Tap the field to change it, then carry on.';
	@override String get s4 => 'Tap "Save" to create the book.';
	@override String get s5 => 'Pick a spine colour, which tells the books apart on the shelf, and tap "Save". The book opens straight away.';
	@override String get s6 => 'This is the book you made. Add recipes to it from here; inside, turn the pages and jump from the contents. A long press on a book on the shelf opens sharing, cover, rename and delete.';
}

// Path: walkthrough.topics.mealPlan
class _Translations$walkthrough$topics$mealPlan$en extends Translations$walkthrough$topics$mealPlan$he {
	_Translations$walkthrough$topics$mealPlan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Weekly plan and nutrition';
	@override String get summary => 'A plan for the whole week with a nutrition summary for each day, which feeds the grocery list.';
	@override String get s1 => 'Tap "Meals" to plan the week.';
	@override String get s2 => 'Tap here to create a weekly plan.';
	@override String get s3 => 'The plan\'s name is already filled in. Below, pick a template: free, three meals a day or six.';
	@override String get s4 => 'Tap "Save" to create the plan.';
	@override String get s5 => 'Place recipes on each day\'s meals. The nutrition card adds up calories, protein, carbs and fat by servings. Tap the chart to open the weekly dashboard.';
	@override String get s6 => 'The dashboard: daily average, weekly total, a bar per day and the macro split. The values are estimated by the AI for every recipe, per serving.';
	@override String get s7 => 'The share button sends the plan to another account, as an editor or a viewer. An edit on one side reaches everyone.';
}

// Path: walkthrough.topics.groceries
class _Translations$walkthrough$topics$groceries$en extends Translations$walkthrough$topics$groceries$he {
	_Translations$walkthrough$topics$groceries$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Grocery list and prices';
	@override String get summary => 'A list built from the plan, with what has been picked up ticked off, a cost estimate from your receipts, and sharing with whoever shops with you.';
	@override String get s1 => 'Tap "Groceries".';
	@override String get s2 => 'Refresh rebuilds the list from every recipe in the weekly plan.';
	@override String get s3 => 'Tap the plus to add an item by hand.';
	@override String get s4 => 'The item\'s name is already filled in. Pick an amount and a unit, or start from a product your receipts already know.';
	@override String get s5 => 'Tap "Add" and the item joins the list.';
	@override String get s6 => 'Tap here to open the price book.';
	@override String get s7 => 'Scan a receipt and the price of every product is kept. From there the grocery list gets a cost estimate, and community median prices fill in what you have not bought yet.';
	@override String get shefi => 'Ask Shefi about this list: what is missing for a meal, what to swap, or add items by voice.';
}

// Path: walkthrough.topics.community
class _Translations$walkthrough$topics$community$en extends Translations$walkthrough$topics$community$he {
	_Translations$walkthrough$topics$community$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Community';
	@override String get summary => 'Recipes shared by everyone, and a forum for questions and answers.';
	@override String get s1 => 'Tap "Community".';
	@override String get s2 => 'Shared recipes and the forum. Like a recipe, a thread or a reply, save a recipe to your own, and attach a recipe to a forum reply.';
	@override String get s3 => 'The share button publishes one of your own recipes to the community.';
}

// Path: walkthrough.topics.account
class _Translations$walkthrough$topics$account$en extends Translations$walkthrough$topics$account$he {
	_Translations$walkthrough$topics$account$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Account, premium and settings';
	@override String get summary => 'Notifications about share invites, and the account with premium, shared access, settings and the display mode.';
	@override String get s1 => 'Notifications: invitations to share books and plans, and updates.';
	@override String get s2 => 'Tap the picture to open your account.';
	@override String get s3 => 'Premium: AI analyses with no daily limit and no ads. A free account gets a daily allowance, which a short video extends.';
	@override String get s4 => 'Shared access: who shares books, plans and grocery lists with you, and what you have shared.';
	@override String get s5 => 'Tap "Settings".';
	@override String get s6 => 'Display mode: light, dark or as the device. Settings also hold the language, dietary preferences and allergens. This guide can be started again from the support screen in the account.';
	@override String get shefi => 'Shefi, the smart assistant: this floating button opens a chat. Ask in writing or out loud, and Shefi answers, adds to the plan, builds a list or starts Cook Mode. Inside a recipe, plan or list, the "Ask Shefi" button talks about that item only.';
}

// Path: walkthrough.topics.settings
class _Translations$walkthrough$topics$settings$en extends Translations$walkthrough$topics$settings$he {
	_Translations$walkthrough$topics$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings and preferences';
	@override String get summary => 'Every row of the settings and the preferences: profile, sharing, notifications, language, look, account deletion, shopping day, prices, diet and books.';
	@override String get s1 => 'Tap "Settings": the account and the app live here.';
	@override String get s2 => 'Profile: the name and photo the people you share with see, and the linked sign-in methods.';
	@override String get s3 => 'Shared access: who shares recipes, books, plans and lists with you, and what you shared. Joining by code or QR starts here too.';
	@override String get s4 => 'Tap "Notification settings".';
	@override String get s5 => 'Push notifications: the master switch. Off, nothing is sent; below it you pick what is: replies, invites, updates and messages from the team.';
	@override String get s6 => 'Shopping-day reminders: when to remind you before the shop. Scheduled on the device, apart from push.';
	@override String get s7 => 'Language: switching also translates your recipes, books, plans and lists.';
	@override String get s8 => 'Appearance: light, dark or follow the device. The choice is saved on the account and follows you to the next device.';
	@override String get s9 => 'Delete account: permanently removes the account and everything in it, after a confirmation. A store subscription is cancelled separately.';
	@override String get s10 => 'Back on the account: tap "Preferences", how the app behaves for you.';
	@override String get s11 => 'Shopping day: the day the grocery list is built around and the reminders are timed to.';
	@override String get s12 => 'Community prices: when on, prices from your receipts join anonymous averages, and lines you never bought are estimated from them.';
	@override String get s13 => 'Dietary preferences and allergens: mark them here and the app highlights them in recipes and shared recipes.';
	@override String get s14 => 'Fast page turn in books: jumping to a distant page turns a single page. Off, it flips through every page on the way.';
	@override String get s15 => 'Sounds: sound effects on page turns and actions. Can be switched off.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Easy Plate',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.ok' => 'OK',
			'common.next' => 'Next',
			'common.back' => 'Back',
			'common.done' => 'Done',
			'common.add' => 'Add',
			'common.edit' => 'Edit',
			'common.delete' => 'Delete',
			'common.search' => 'Search',
			'common.retry' => 'Try again',
			'common.loading' => 'Loading...',
			'common.error' => 'Something went wrong',
			'common.or' => 'or',
			'common.missingInfo' => '[missing info]',
			'common.networkError' => 'No internet connection',
			'common.landscapeHint' => 'Works better in landscape',
			'common.rotateLandscape' => 'Rotate',
			'common.rotatePortrait' => 'Back to portrait',
			'auth.welcome' => 'Welcome to EasyPlate',
			'auth.subtitle' => 'Sign in to keep your recipes',
			'auth.signIn' => 'Sign in',
			'auth.signUp' => 'Sign up',
			'auth.signOut' => 'Sign out',
			'auth.email' => 'Email',
			'auth.emailHint' => 'name@example.com',
			'auth.password' => 'Password',
			'auth.passwordHint' => 'At least 6 characters',
			'auth.continueWithGoogle' => 'Continue with Google',
			'auth.continueWithPhone' => 'Continue with phone',
			'auth.continueWithEmail' => 'Continue with email',
			'auth.phoneNumber' => 'Phone number',
			'auth.phoneHint' => '+972501234567',
			'auth.sendCode' => 'Send code',
			'auth.smsCode' => 'SMS code',
			'auth.codeSentTo' => ({required Object phone}) => 'We sent a verification code to ${phone}',
			'auth.verify' => 'Verify',
			'auth.resendCode' => 'Resend',
			'auth.forgotPassword' => 'Forgot password',
			'auth.resetSent' => 'Password reset email sent',
			'auth.noAccount' => 'No account? Sign up',
			'auth.haveAccount' => 'Have an account? Sign in',
			'auth.invalidEmail' => 'Invalid email address',
			'auth.passwordTooShort' => 'Password must be at least 6 characters',
			'auth.invalidPhone' => 'Invalid phone number',
			'auth.codeRequired' => 'Enter the code you received',
			'auth.errorUnauthorized' => 'Those details are incorrect',
			'auth.errorNetwork' => 'No internet connection',
			'auth.errorUnknown' => 'Sign-in failed, please try again',
			'auth.signOutTitle' => 'Sign out?',
			'auth.signOutBody' => 'You will need to sign in again to reach your recipes.',
			'auth.errorOperationNotAllowed' => 'This sign-in method is not available right now',
			'auth.errorTooManyRequests' => 'Too many attempts. Try again in a few minutes',
			'auth.errorInvalidPhone' => 'That phone number is not valid',
			'auth.errorEmailInUse' => 'That email is already registered',
			'auth.verifyEmailTitle' => 'Verify your email',
			'auth.verifyEmailBody' => ({required Object email}) => 'We sent a verification link to ${email}. Open it, then come back here.',
			'auth.resendEmail' => 'Resend the link',
			'auth.emailResent' => 'Link sent again',
			'auth.checkVerification' => 'I have verified',
			'auth.stillNotVerified' => 'Not verified yet',
			'auth.linkPhone' => 'Verify phone',
			'auth.phoneLinked' => 'Phone verified',
			'auth.phoneAlreadyUsed' => 'That number already belongs to another account',
			'auth.emailAlreadyLinked' => 'This account already has an email',
			'auth.addEmailPassword' => 'Add email and password',
			'auth.verified' => 'Verified',
			'auth.linkGoogle' => 'Link Google account',
			'auth.googleLinked' => 'Linked',
			'auth.googleAlreadyUsed' => 'That Google account already belongs to another user',
			'auth.googleAlreadyLinked' => 'A Google account is already linked',
			'auth.phoneGateTitle' => 'Verify your phone',
			'auth.phoneGateBody' => 'Every account is verified by phone. We\'ll text you a code.',
			'auth.changeNumber' => 'Change number',
			'auth.signInTitle' => 'Sign in',
			'auth.phoneFirstHint' => 'New here? Continue with phone.',
			'auth.errorAccountExistsDifferentCredential' => 'That email already belongs to another account. Sign in the way you registered.',
			'auth.errorCredentialInUse' => 'Those details already belong to another account',
			'auth.continueWithApple' => 'Continue with Apple',
			'auth.linkApple' => 'Link Apple account',
			'auth.appleLinked' => 'Linked',
			'auth.appleAlreadyUsed' => 'That Apple account already belongs to another user',
			'auth.appleAlreadyLinked' => 'An Apple account is already linked',
			'auth.blockedTitle' => 'Account blocked',
			'auth.blockedBody' => 'This account was blocked by the app\'s administrator. Contact us from the support screen for details.',
			'auth.phoneClaimedTitle' => 'This number belongs to an existing account',
			'auth.phoneClaimedBody' => ({required Object phone}) => '${phone} is already connected to another EasyPlate account. To reach that account and its recipes, sign in the way you did before (Google, Apple or email) and verify the number there again.',
			'auth.phoneClaimedSignIn' => 'Sign in to my existing account',
			'auth.phoneClaimedCreateNew' => 'Create a new account anyway',
			'auth.phoneClaimedCreateNewConfirm' => 'A new, empty account will be opened for this number. The existing account stays as it is, but it will no longer be reachable with this number.',
			'auth.sessionOtherDeviceTitle' => 'Signed in on another device',
			'auth.sessionOtherDeviceBody' => ({required Object platform, required Object since}) => 'This account is open on ${platform}${since}. It can be used on one device at a time: sign out there, then tap "Try again".',
			'auth.sessionSince' => ({required Object date}) => ' since ${date}',
			'auth.sessionExpiredTitle' => 'Your session has expired',
			'auth.sessionExpiredBody' => 'A sign-in lasts up to a month. Sign in again to continue.',
			'auth.sessionRetry' => 'Try again',
			'auth.platformIos' => 'an iPhone',
			'auth.platformAndroid' => 'an Android phone',
			'auth.platformOther' => 'another device',
			'profile.setupTitle' => 'A few last details',
			'profile.setupSubtitle' => 'So we know what to call you',
			'profile.fullName' => 'Full name',
			'profile.fullNameHint' => 'Jane Doe',
			'profile.fullNameRequired' => 'A full name is required',
			'profile.photo' => 'Profile photo',
			'profile.addPhoto' => 'Add photo',
			'profile.phoneOptional' => 'Phone (optional)',
			'profile.emailOptional' => 'Email (optional)',
			'profile.save' => 'Finish signing up',
			'profile.saving' => 'Saving...',
			'profile.saveFailed' => 'We could not save your profile',
			'profile.myProfile' => 'My profile',
			'onboarding.welcomeTitle' => 'Welcome to EasyPlate',
			'onboarding.welcomeSubtitle' => 'Plan meals, cook and shop — all in one place',
			'onboarding.shoppingDayTitle' => 'When is your weekly shopping day?',
			'onboarding.dietaryTitle' => 'What are your dietary preferences?',
			'onboarding.dietarySubtitle' => 'You can pick more than one',
			'onboarding.finish' => 'Let\'s get started',
			'dietary.meat' => 'Meat',
			'dietary.dairy' => 'Dairy',
			'dietary.vegetarian' => 'Vegetarian',
			'dietary.vegan' => 'Vegan',
			'dietary.kosher' => 'Kosher',
			'dietary.glutenFree' => 'Gluten-free',
			'dietary.allergy' => 'Allergy',
			'allergens.title' => 'Allergens',
			'allergens.pick' => 'Mark allergens',
			'allergens.contains' => 'Contains',
			'allergens.mayContain' => 'May contain',
			'allergens.gluten' => 'Gluten',
			'allergens.milk' => 'Milk',
			'allergens.eggs' => 'Eggs',
			'allergens.fish' => 'Fish',
			'allergens.shellfish' => 'Shellfish',
			'allergens.peanuts' => 'Peanuts',
			'allergens.treeNuts' => 'Tree nuts',
			'allergens.sesame' => 'Sesame',
			'allergens.soy' => 'Soy',
			'weekday.sunday' => 'Sunday',
			'weekday.monday' => 'Monday',
			'weekday.tuesday' => 'Tuesday',
			'weekday.wednesday' => 'Wednesday',
			'weekday.thursday' => 'Thursday',
			'weekday.friday' => 'Friday',
			'weekday.saturday' => 'Saturday',
			'settings.title' => 'Settings',
			'settings.dietaryPreferences' => 'Dietary preferences',
			'settings.shoppingDay' => 'Shopping day',
			'settings.language' => 'Language',
			'settings.appearance' => 'Appearance',
			'settings.themeSystem' => 'System',
			'settings.themeLight' => 'Light',
			'settings.themeDark' => 'Dark',
			'settings.soundEffects' => 'Sound effects (page turns)',
			'settings.fastPageTurn' => 'Fast page-through',
			'settings.fastPageTurnHint' => 'Jumping from the table of contents or quick navigation turns a single page to the destination. Turn it off to flip through every page on the way.',
			'settings.sharedAccess' => 'Manage sharing',
			'settings.noSharedAccess' => 'You haven\'t shared any books or lists yet',
			'settings.communityPrices' => 'Community price averages',
			'settings.communityPricesHint' => 'When you have no price of your own for a product, show the median price other people shared',
			'settings.shoppingReminders' => 'Shopping day reminders',
			'settings.shoppingRemindersHint' => 'Sent by the device, around the shopping day you picked',
			'settings.reminderTwoDaysBefore' => 'Two days before (evening)',
			'settings.reminderDayBefore' => 'Day before (evening)',
			'settings.reminderSameDayMorning' => 'Shopping day (morning)',
			'settings.reminderSameDayAfternoon' => 'Shopping day (afternoon)',
			'settings.translatingContent' => 'Translating your recipes and menus…',
			'settings.translatedContent' => ({required Object count}) => '${count} items translated',
			'settings.translationPartialTitle' => 'Translation unfinished',
			'settings.translationPartial' => ({required Object count}) => '${count} items stayed in their own language. You can try again later.',
			'settings.translationFailed' => 'Translation failed. Your content stayed in its own language.',
			'settings.account' => 'Account',
			'settings.notifications' => 'Notifications',
			'settings.notificationsHint' => 'Which alerts reach you, and how',
			'settings.settingsHint' => 'Account, notifications, language and appearance',
			'settings.dangerZone' => 'Danger zone',
			'settings.deleteAccount' => 'Delete account',
			'settings.deleteAccountHint' => 'Permanently delete the account and everything in it',
			'settings.deleteAccountTitle' => 'Delete the account for good?',
			'settings.deleteAccountBody' => 'Your account, recipes, books, meal plans, grocery lists, receipts, photos, posts and replies will be permanently deleted from our servers and from this device and cannot be recovered. What you shared is removed from the people you shared it with. An active subscription is not cancelled automatically: cancel it in the App Store or Google Play.',
			'settings.deleteAccountConfirm' => 'Delete permanently',
			'settings.deletingAccount' => 'Deleting the account…',
			'settings.deleteAccountFailed' => 'Deleting the account failed. Try again, or write to support@aieasyplate.app.',
			'settings.deleteAccountHousehold' => 'You own a shared household. Close it first from the Household screen, then try again.',
			'notificationSettings.title' => 'Notification settings',
			'notificationSettings.push' => 'Push notifications',
			'notificationSettings.pushHint' => 'Alerts on this device. Off, nothing is pushed; the inbox still fills up.',
			'notificationSettings.pushDenied' => 'Notifications are blocked for EasyPlate in the device settings. Allow them there to receive alerts.',
			'notificationSettings.community' => 'Community',
			'notificationSettings.repliesOnMyPosts' => 'Replies to my posts',
			'notificationSettings.repliesOnMyPostsHint' => 'Someone answered a thread you opened',
			'notificationSettings.repliesOnThreads' => 'Replies in threads I joined',
			'notificationSettings.repliesOnThreadsHint' => 'A new reply in a thread you replied to',
			'notificationSettings.sharing' => 'Sharing',
			'notificationSettings.shareInvites' => 'Share invites',
			'notificationSettings.shareInvitesHint' => 'Someone shared a recipe, book or plan with you. The invite always reaches the inbox; this is the alert.',
			'notificationSettings.sharedRecipeUpdates' => 'Updates to saved recipes',
			'notificationSettings.sharedRecipeUpdatesHint' => 'The author changed a community recipe you saved',
			'notificationSettings.easyPlate' => 'From EasyPlate',
			'notificationSettings.adminReplies' => 'Replies to my support messages',
			'notificationSettings.announcements' => 'Announcements',
			'notificationSettings.announcementsHint' => 'News and updates from the EasyPlate team',
			'notificationSettings.inApp' => 'While the app is open',
			'notificationSettings.foregroundPopups' => 'Show alerts as a popup',
			'notificationSettings.foregroundPopupsHint' => 'A push that arrives while you are in the app opens a small card. Off, it only goes to the inbox.',
			'notificationSettings.reminders' => 'Shopping reminders',
			'preferences.title' => 'Preferences',
			'preferences.hint' => 'Shopping, dietary needs and how the books behave',
			'preferences.shopping' => 'Shopping',
			'preferences.books' => 'Recipe books',
			'more.title' => 'More',
			'more.settings' => 'Settings',
			'more.profile' => 'My profile',
			'more.support' => 'Support',
			'more.supportTitle' => 'How can we help?',
			'more.supportBody' => 'Write to us and we will get back to you.',
			'more.whatsapp' => 'Message us on WhatsApp',
			'more.email' => 'Send an email',
			'more.supportUnavailable' => 'We could not open that app',
			'more.preferences' => 'Preferences',
			'more.help' => 'Support & legal',
			'more.helpHint' => 'Support, privacy policy and terms of service',
			'more.legal' => 'Legal',
			'language.hebrew' => 'עברית',
			'language.english' => 'English',
			'language.arabic' => 'العربية',
			'language.french' => 'Français',
			'language.russian' => 'Русский',
			'books.myLibrary' => 'My library',
			'books.myRecipes' => 'My recipes',
			'books.librarySubtitle' => 'All your recipe books in one place',
			'books.recipesSubtitle' => 'Search and filter every recipe you\'ve collected',
			'books.collection' => 'Collection',
			'books.recipesCount' => ({required Object count}) => '${count} recipes',
			'books.newBook' => 'New book',
			'books.newBookTitle' => 'Book name',
			'books.tableOfContents' => 'Table of contents',
			'books.emptyLibrary' => 'You don\'t have any books yet. Create your first one!',
			'books.emptyBook' => 'This book is empty. Add your first recipe',
			'books.quickNav' => 'Quick navigation',
			'books.share' => 'Share book',
			'books.viewer' => 'Viewer',
			'books.editor' => 'Editor',
			'books.reorderHint' => 'Drag to reorder the recipes',
			'books.coverImage' => 'Cover photo',
			'books.bookOptions' => 'Book options',
			'books.renameBook' => 'Rename book',
			'books.spineColor' => 'Spine colour',
			'recipe.prepTime' => 'Prep time',
			'recipe.cookTime' => 'Cook time',
			'recipe.ingredients' => 'Ingredients',
			'recipe.ingredientsCount' => ({required Object count}) => '${count} ingredients',
			'recipe.minutes' => ({required Object count}) => '${count} min',
			'recipe.hours' => ({required Object count}) => '${count} hr',
			'recipe.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours} hr ${minutes} min',
			'recipe.instructions' => 'Instructions',
			'recipe.addToBook' => 'Add to book',
			'recipe.removeFromBook' => 'Remove from book',
			'recipe.deleteRecipe' => 'Delete recipe',
			'recipe.photo' => 'Recipe photo',
			'recipe.mine' => 'My recipes',
			'recipe.saved' => 'Saved recipes',
			'recipe.noneMine' => 'You have not created any recipes yet',
			'recipe.noneSaved' => 'You have not saved any community recipes yet',
			'recipe.pendingAnalysis' => 'Awaiting analysis',
			'recipe.pendingAnalysisHint' => 'Saved as raw text. Analyse it now or edit it by hand.',
			'recipe.analyzeNow' => 'Analyse with AI now',
			'recipe.analyzing' => 'Analysing the recipe...',
			'recipe.analyzeFailed' => 'The analysis failed — you can try again later',
			'recipe.communityUpdateTitle' => 'This recipe is shared',
			'recipe.communityUpdateBody' => 'Update the community copy too, or only yours?',
			'recipe.communityUpdateBoth' => 'Community too',
			'recipe.communityUpdateLocal' => 'Only mine',
			'recipe.communityUpdated' => 'The community copy was updated',
			'recipe.communityGone' => 'The recipe is no longer in the community; saved only for you',
			'cookMode.title' => 'Cook mode',
			'cookMode.start' => 'Start cooking',
			'cookMode.stepOf' => ({required Object n, required Object total}) => 'Step ${n} of ${total}',
			'cookMode.ingredients' => 'Ingredients',
			'cookMode.inThisStep' => 'In this step',
			'cookMode.timer' => 'Timer',
			'cookMode.startTimer' => 'Start timer',
			'cookMode.pause' => 'Pause',
			'cookMode.resume' => 'Resume',
			'cookMode.reset' => 'Reset',
			'cookMode.timeUp' => 'Time\'s up!',
			'cookMode.next' => 'Next step',
			'cookMode.previous' => 'Previous',
			'cookMode.finish' => 'Done cooking',
			'cookMode.finishedTitle' => 'Enjoy your meal!',
			'cookMode.finishedBody' => 'Every step is done. The screen can sleep again now.',
			'cookMode.screenOn' => 'The screen stays on while you cook',
			'cookMode.noSteps' => 'This recipe has no steps yet',
			'cookMode.runningOnStep' => ({required Object n}) => 'Timer running on step ${n}',
			'cookMode.inProgress' => 'Cooking in progress',
			'cookMode.inProgressBody' => ({required Object recipe, required Object n, required Object total}) => '"${recipe}" · step ${n} of ${total}',
			'cookMode.resumeCooking' => 'Continue',
			'cookMode.endCooking' => 'End',
			'cookMode.stepLabel' => ({required Object n}) => 'Step ${n}',
			'cookMode.ongoingBody' => ({required Object time, required Object total, required Object n}) => 'Ends at ${time} · ${total} · step ${n}',
			'cookMode.timeUpBody' => ({required Object n}) => 'Step ${n}: time\'s up',
			'cookMode.runningTimers' => 'Running timers',
			'cookMode.premiumOnly' => 'Cook mode is part of EasyPlate Premium',
			'nutrition.title' => 'Nutrition',
			'nutrition.perServing' => 'per serving',
			'nutrition.perServingHint' => 'All values are for one serving. Leave blank to drop the estimate.',
			'nutrition.servings' => 'servings',
			'nutrition.servingsCount' => ({required Object count}) => '${count} servings',
			'nutrition.calories' => 'Calories',
			'nutrition.kcal' => 'kcal',
			'nutrition.protein' => 'Protein',
			'nutrition.carbs' => 'Carbs',
			'nutrition.fat' => 'Fat',
			'nutrition.gramsShort' => 'g',
			'nutrition.estimate' => 'Estimate with AI',
			'nutrition.estimating' => 'Estimating nutrition…',
			'nutrition.estimateFailed' => 'The estimate failed, please try again',
			'nutrition.none' => 'No nutrition values for this recipe yet',
			'nutrition.noneHint' => 'AI can estimate calories, protein, carbs and fat from the ingredient list',
			'nutrition.estimated' => 'Nutrition values updated',
			'nutrition.editorServings' => 'Servings',
			'nutrition.editorCalories' => 'Calories per serving',
			'nutrition.editorProtein' => 'Protein (g)',
			'nutrition.editorCarbs' => 'Carbs (g)',
			'nutrition.editorFat' => 'Fat (g)',
			'nutrition.dashboard' => 'Nutrition dashboard',
			'nutrition.weekly' => 'This week',
			'nutrition.today' => 'Today',
			'nutrition.dayTotal' => 'Day total',
			'nutrition.weekTotal' => 'Week total',
			'nutrition.dailyAverage' => 'Average per planned day',
			'nutrition.perMeal' => 'By meal',
			'nutrition.perDay' => 'By day',
			'nutrition.noPlanned' => 'No meals with recipes planned yet',
			'nutrition.missingCount' => ({required Object count}) => '${count} items without nutrition values',
			'nutrition.macroSplit' => 'Calorie split',
			'nutrition.kcalPerDay' => 'kcal per day',
			'nutrition.openDashboard' => 'Weekly dashboard',
			'nutrition.perRecipe' => 'Whole recipe',
			'nutrition.perRecipeServings' => ({required Object count}) => '${count} servings',
			'community.title' => 'Community',
			'community.forum' => 'Forum',
			'community.sharedRecipes' => 'Shared recipes',
			'community.newPost' => 'New post',
			'community.postTitle' => 'Title',
			'community.postBody' => 'What would you like to ask or share?',
			'community.postTitleRequired' => 'A title is required',
			'community.postBodyRequired' => 'Some content is required',
			'community.publish' => 'Publish',
			'community.replies' => ({required Object count}) => '${count} replies',
			'community.noReplies' => 'No replies yet',
			'community.oneReply' => 'One reply',
			'community.writeReply' => 'Write a reply...',
			'community.send' => 'Send',
			'community.noPosts' => 'No posts yet. Be the first!',
			'community.noSharedRecipes' => 'No shared recipes yet. Share the first one!',
			'community.shareRecipe' => 'Share a recipe',
			'community.pickRecipeToShare' => 'Which recipe would you like to share?',
			'community.saveToMyRecipes' => 'Save to my recipes',
			'community.savedToMyRecipes' => 'Recipe saved to your collection',
			'community.deletePost' => 'Delete post',
			'community.deletePostConfirm' => 'The post and its replies will be permanently deleted.',
			'community.unshare' => 'Remove from feed',
			'community.unshareConfirm' => 'The recipe will be removed from the shared feed.',
			'community.byAuthor' => ({required Object name}) => 'by ${name}',
			'community.loadFailed' => 'We could not load the content',
			'community.allRecipes' => 'All recipes',
			'community.myRecipes' => 'My recipes',
			'community.editShared' => 'Edit shared recipe',
			'community.sharedUpdated' => 'Shared recipe updated',
			'community.noneOfMine' => 'You have not shared any recipes yet',
			'community.search' => 'Search',
			'community.searchHint' => 'Recipe or author name',
			'community.savedOnly' => 'Saved',
			'community.noResults' => 'No results',
			'community.attachRecipe' => 'Attach a recipe',
			'community.openRecipe' => 'Open recipe',
			'community.recipeUnavailable' => 'That recipe is no longer available',
			'community.sortAndFilter' => 'Sort & filter',
			'community.sort' => 'Sort',
			'community.sortNewest' => 'Newest',
			'community.sortOldest' => 'Oldest',
			'community.sortMostLiked' => 'Most liked',
			'community.topics' => 'Topics',
			'community.likes' => 'Likes',
			'community.anyLikes' => 'Any',
			'community.atLeastLikes' => ({required Object count}) => '${count}+',
			'community.totalTime' => 'Total time',
			'community.anyTime' => 'Any time',
			'community.upTo' => ({required Object duration}) => 'Up to ${duration}',
			'community.clearFilters' => 'Clear filters',
			'community.applyFilters' => 'Show results',
			'community.likesPlus' => ({required Object count}) => '${count}+',
			'community.durationPlus' => ({required Object duration}) => '${duration}+',
			'community.splitTimes' => 'Split into prep and cook',
			'community.alreadySaved' => 'You already have this recipe',
			'community.savedTag' => 'Saved',
			'community.removeSaved' => 'Remove from saved recipes',
			'community.removeSavedConfirm' => 'The recipe will be removed from your saved recipes. You can save it again from the community.',
			'community.oneNewPost' => '1 new post',
			'community.newPosts' => ({required Object count}) => '${count} new posts',
			'community.replyFailed' => 'Your reply could not be sent',
			'sharing.title' => 'Share recipe',
			'sharing.contactLabel' => 'Email or phone of the person',
			'sharing.contactHint' => 'name@example.com or 05…',
			'sharing.roleTitle' => 'Permission',
			'sharing.roleViewer' => 'View only',
			'sharing.roleViewerHint' => 'Can see the recipe, not change it',
			'sharing.roleEditor' => 'Edit',
			'sharing.roleEditorHint' => 'Their changes show up for you too',
			'sharing.send' => 'Send invite',
			'sharing.sent' => 'Invite sent',
			'sharing.invalidContact' => 'Enter a valid email or phone number',
			'sharing.notFound' => 'No account matches those details. Make sure the email or phone is linked to their account and that they have opened the app recently.',
			'sharing.self' => 'You can\'t share with yourself',
			'sharing.failed' => 'Sharing failed, try again',
			'sharing.pendingInvites' => 'Pending invites',
			'sharing.noPendingInvites' => 'No pending invites',
			'sharing.sharedByMe' => 'Shared by me',
			'sharing.sharedWithMe' => 'Shared with me',
			'sharing.nothingSharedByMe' => 'You haven\'t shared anything yet',
			'sharing.nothingSharedWithMe' => 'Nothing has been shared with you yet',
			'sharing.accept' => 'Accept',
			'sharing.decline' => 'Decline',
			'sharing.accepted' => 'The recipe was added to your recipes',
			'sharing.declined' => 'Invite declined',
			'sharing.acceptFailed' => 'Accepting failed, try again',
			'sharing.members' => 'Members',
			'sharing.noMembersYet' => 'Nobody has accepted yet',
			'sharing.remove' => 'Remove',
			'sharing.leave' => 'Leave',
			'sharing.removed' => 'Member removed',
			'sharing.left' => 'You left the share',
			'sharing.invitedBy' => ({required Object name}) => 'from ${name}',
			'sharing.sharedTag' => 'Shared',
			'sharing.viewerTag' => 'View only',
			'sharing.editorTag' => 'Editor',
			'sharing.ownerTag' => 'Owner',
			'sharing.syncFailed' => 'Could not refresh the shared recipe, showing the saved version',
			'sharing.viewerCannotEdit' => 'This recipe is shared with you view-only',
			'sharing.shareAction' => 'Share',
			'sharing.directoryUnavailable' => 'Sharing is not set up on the server yet. Sign out and back in; if it persists, the Firestore rules need deploying.',
			'sharing.shareBook' => 'Share book',
			'sharing.sharePlan' => 'Share plan',
			'sharing.acceptedBook' => 'The book was added to your library',
			'sharing.acceptedPlan' => 'The plan was added to your plans',
			'sharing.viewerCannotEditBook' => 'This book was shared with you as view only',
			'sharing.viewerCannotEditPlan' => 'This plan was shared with you as view only',
			'sharing.kindRecipe' => 'Recipe',
			'sharing.kindBook' => 'Book',
			'sharing.kindPlan' => 'Plan',
			'sharing.recipesTravel' => 'The recipes inside are shared along with it',
			'sharing.shareList' => 'Share grocery list',
			'sharing.acceptedList' => 'The list was added to your grocery lists',
			'sharing.viewerCannotEditList' => 'This list is shared with you view-only',
			'sharing.kindList' => 'grocery list',
			'notifications.title' => 'Notifications',
			'notifications.empty' => 'No notifications',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => '${name} shared "${recipe}" with you',
			'notifications.asViewer' => 'view only',
			'notifications.asEditor' => 'to edit',
			'notifications.markAllRead' => 'Mark all as read',
			'notifications.openRecipe' => 'Open recipe',
			'notifications.alreadyHandled' => 'This invite was already handled',
			'notifications.recipeUpdated' => ({required Object name, required Object recipe}) => '${name} updated "${recipe}"',
			'notifications.recipeUpdatedHint' => 'There is a new version of a recipe you saved',
			'notifications.refreshCopy' => 'Refresh to new version',
			'notifications.keepCopy' => 'Keep my copy',
			'notifications.refreshed' => 'Your copy was updated to the new version',
			'notifications.keptCopy' => 'Your copy stays as it is',
			'notifications.recipeGone' => 'The recipe is no longer in the community',
			'notifications.deleteAll' => 'Delete all notifications',
			'notifications.deleteAllBody' => 'Every notification will be deleted.',
			'notifications.openInbox' => 'Open notifications',
			'notifications.sharedBook' => ({required Object name, required Object recipe}) => '${name} shared the book "${recipe}" with you',
			'notifications.sharedPlan' => ({required Object name, required Object recipe}) => '${name} shared the plan "${recipe}" with you',
			'notifications.adminReply' => 'A reply from the EasyPlate team to your message',
			'notifications.adminReplyQuote' => ({required Object excerpt}) => 'Your message: "${excerpt}"',
			'notifications.adminMessage' => 'A message from EasyPlate',
			'notifications.forumReplyOnMyPost' => ({required Object name, required Object post}) => '${name} replied to your post "${post}"',
			'notifications.forumReplyOnThread' => ({required Object name, required Object post}) => '${name} replied in "${post}"',
			'notifications.openThread' => 'Open thread',
			'notifications.threadGone' => 'This thread was deleted',
			'notifications.settings' => 'Settings',
			'notifications.sharedList' => ({required Object name, required Object recipe}) => '${name} shared the grocery list "${recipe}" with you',
			'editor.title' => 'Edit recipe',
			'editor.recipeTitle' => 'Recipe name',
			'editor.titleHint' => 'For example: Jerusalem shakshuka',
			'editor.topics' => 'Topics',
			'editor.titleRequired' => 'A recipe name is required',
			'editor.prepMinutes' => 'Prep time (min)',
			'editor.cookMinutes' => 'Cook time (min)',
			'editor.amount' => 'Amount',
			'editor.unit' => 'Unit',
			'editor.ingredientName' => 'Ingredient name',
			'editor.stepHint' => 'Describe the step',
			'editor.addIngredient' => 'Add ingredient',
			'editor.addStep' => 'Add step',
			'editor.removeIngredient' => 'Remove ingredient',
			'editor.removeStep' => 'Remove step',
			'editor.reorderStep' => 'Reorder step',
			'editor.fixSpelling' => 'Fix spelling',
			'editor.refining' => 'Correcting the recipe...',
			'editor.refineError' => 'We could not correct the recipe',
			'editor.spellingFixed' => 'Recipe corrected',
			'editor.noChanges' => 'No spelling mistakes found',
			'editor.timesSynced' => 'Times in the instructions were updated to match',
			'editor.discardTitle' => 'Discard changes?',
			'editor.discardBody' => 'Your edits will not be saved.',
			'editor.discard' => 'Discard',
			'editor.saveOptionsTitle' => 'How would you like to save?',
			_ => null,
		} ?? switch (path) {
			'editor.savePlainHint' => 'Save the changes as they are, no waiting',
			'editor.saveWithAi' => 'Save with AI review',
			'editor.saveWithAiHint' => 'Fix spelling and align the times written in the steps',
			'ingestion.title' => 'Add a recipe',
			'ingestion.pasteText' => 'Paste text',
			'ingestion.pasteHint' => 'Paste a recipe here from WhatsApp or any other source',
			'ingestion.webSearch' => 'Search the web',
			'ingestion.urlScrape' => 'Website link',
			'ingestion.socialVideo' => 'Social video',
			'ingestion.socialVideoHint' => 'Paste a link to a TikTok, Instagram, YouTube or Facebook video',
			'ingestion.socialUnreadable' => 'We could not read this video. The account may be private, or the platform blocked the request. You can copy the caption and paste it as text.',
			'ingestion.aiRequest' => 'Ask for a recipe',
			'ingestion.aiRequestHint' => 'Describe what you want to make. For example: semolina porridge for a one-year-old, with fruit',
			'ingestion.parse' => 'Parse recipe',
			'ingestion.parsing' => 'Parsing the recipe...',
			'ingestion.parseError' => 'We couldn\'t parse the recipe',
			'ingestion.reviewTitle' => 'Review before saving',
			'ingestion.notConfigured' => 'This feature needs an external service that hasn\'t been set up yet',
			'ingestion.openOptionsTitle' => 'How would you like to open this recipe?',
			'ingestion.viewOriginal' => 'View the original',
			'ingestion.viewOriginalHint' => 'The page text as written, unprocessed — loads instantly',
			'ingestion.generateStructured' => 'Create a structured recipe',
			'ingestion.generateStructuredHint' => 'Automatic extraction of ingredients, amounts and steps',
			'ingestion.originalTitle' => 'Original recipe',
			'ingestion.fetchFailed' => 'We could not load the page',
			'ingestion.loadingOriginal' => 'Loading the page...',
			'ingestion.structuredFromSite' => 'Read directly from the site\'s structured data, no AI involved',
			'ingestion.useStructured' => 'Continue with the structured recipe',
			'ingestion.preferAi' => 'Process with AI instead',
			'ingestion.analysisTimedOut' => 'The analysis did not finish in time',
			'ingestion.analysisFailed' => 'The analysis failed',
			'ingestion.unparsedHint' => 'Your text is kept as is. Try again, edit it by hand, or save it and analyse later.',
			'ingestion.retryAnalysis' => 'Try again',
			'ingestion.editManually' => 'Edit manually',
			'ingestion.saveForLater' => 'Save and analyse later',
			'ingestion.untitledRecipe' => 'Untitled recipe',
			'ingestion.manual' => 'Write by hand',
			'ingestion.manualHint' => 'Fill the recipe in yourself, in the structured format — no AI, no waiting.',
			'ingestion.openBlankEditor' => 'Open a blank editor',
			'ingestion.generate' => 'Create recipe',
			'ingestion.generating' => 'Writing your recipe...',
			'ingestion.file' => 'Recording / PDF',
			'ingestion.fileHint' => 'You can also share a recording or a PDF straight into Easy Plate from any app, through the usual share button.',
			'ingestion.chooseFile' => 'Choose a file',
			'ingestion.replaceFile' => 'Another file',
			'ingestion.fileTooLarge' => 'The files are too large. The total limit is 10MB, about ten minutes of recording.',
			'ingestion.fileUnsupported' => 'Only audio files and PDFs can be analysed.',
			'ingestion.sharedIn' => ({required Object app}) => 'From ${app}',
			'ingestion.addFile' => 'Add a file',
			'ingestion.filesAsOne' => ({required Object count}) => '${count} files — analysed together as one recipe, in order',
			'ingestion.shareMoreHint' => 'You can go back to WhatsApp and share another recording — it will join the list here.',
			'ingestion.chooseSource' => 'Where is the recipe coming from?',
			'ingestion.pasteTextDescription' => 'Got a recipe on WhatsApp, or copied one from a site or a message? Paste the text here as it is. The model picks out the dish name, the ingredients with their amounts and the steps, and lays it all out in one format. No daily limit.',
			'ingestion.webSearchDescription' => 'Tell us what you feel like making and we will search the web for recipes. From the results you can read the original page as it is, or import it into the app’s structured format.',
			'ingestion.webSearchHint' => 'For example: shakshuka, cheesecake, beetroot kubbeh',
			'ingestion.urlScrapeDescription' => 'Paste a link to a recipe page on a site or blog. We read the page, skip the ads and the stories around it, and extract only the recipe: ingredients, amounts and steps. On many sites this does not even use your daily allowance.',
			'ingestion.urlScrapeHint' => 'https://www.example.com/recipe/...',
			'ingestion.socialVideoDescription' => 'Paste a link to a TikTok, Instagram, YouTube or Facebook video. We watch it for you, listen to what is said and read the captions and description, and turn it into a written, structured recipe. It takes about a minute.',
			'ingestion.aiRequestDescription' => 'No recipe, just an idea? Describe the dish, who it is for and what matters to you, and the model writes a complete recipe that respects the dietary preferences you set.',
			'ingestion.manualDescription' => 'Write the recipe yourself, straight into the structured editor: name, ingredients with amounts and units, and the steps. No AI, no waiting. Right for grandma’s recipe you know by heart.',
			'ingestion.fileDescription' => 'Pick an audio file in which someone reads or tells the recipe, a WhatsApp voice note, or a recipe PDF. We transcribe and read all of it and extract a tidy recipe. Several files can be attached; they are analysed together as one recipe.',
			'mealPlanner.title' => 'Meal planning',
			'mealPlanner.newPlan' => 'New plan',
			'mealPlanner.planName' => 'Plan name',
			'mealPlanner.addMeal' => 'Add a meal',
			'mealPlanner.mealName' => 'Meal name',
			'mealPlanner.addItem' => 'Add an item',
			'mealPlanner.pickRecipe' => 'Pick a recipe',
			'mealPlanner.quickEntry' => 'Quick item',
			'mealPlanner.noPlans' => 'No plans yet. Create your first one!',
			'mealPlanner.addMealHint' => 'Pick a recipe or add a quick item',
			'mealPlanner.breakfast' => 'Breakfast',
			'mealPlanner.lunch' => 'Lunch',
			'mealPlanner.dinner' => 'Dinner',
			'mealPlanner.morningSnack' => 'Morning snack',
			'mealPlanner.afternoonSnack' => 'Afternoon snack',
			'mealPlanner.eveningSnack' => 'Evening snack',
			'mealPlanner.template' => 'Starting template',
			'mealPlanner.templateFree' => 'Start empty',
			'mealPlanner.templateThree' => '3 meals',
			'mealPlanner.templateSix' => '6 meals',
			'mealPlanner.templateFreeHint' => 'An empty plan — add meals yourself',
			'mealPlanner.templateThreeHint' => 'Breakfast, lunch and dinner every day',
			'mealPlanner.templateSixHint' => '3 main meals plus snacks every day',
			'mealPlanner.nameRequired' => 'Give the plan a name',
			'mealPlanner.products' => 'Products',
			'mealPlanner.addProduct' => 'Add a product',
			'mealPlanner.productName' => 'Product name',
			'mealPlanner.noProducts' => 'With no products the item joins the grocery list as a single line under its own name',
			'mealPlanner.itemName' => 'Item name',
			'mealPlanner.editItem' => 'Edit item',
			'mealPlanner.planOptions' => 'Plan options',
			'mealPlanner.deletePlan' => 'Delete plan',
			'mealPlanner.deletePlanConfirm' => ({required Object name}) => 'Delete the plan "${name}"? Its meals will be deleted too.',
			'mealPlanner.leavePlanConfirm' => ({required Object name}) => 'Leave the shared plan "${name}"? It will be removed from your list.',
			'mealPlanner.planDeleted' => 'Plan deleted',
			'groceryList.title' => 'Grocery list',
			'groceryList.aggregated' => 'Combined from all active plans',
			'groceryList.addItem' => 'New item',
			'groceryList.category' => 'Category',
			'groceryList.breakdownTitle' => 'Amount sources',
			'groceryList.collectionProgress' => 'Collection progress',
			'groceryList.itemsCollected' => ({required Object collected, required Object total}) => '${collected} of ${total} items collected',
			'groceryList.adjustAmounts' => 'Adjust amounts',
			'groceryList.buffer' => 'Extra amount',
			'groceryList.share' => 'Share list',
			'groceryList.empty' => 'The list is empty right now',
			'groceryList.uncheckedSection' => 'Still to collect',
			'groceryList.checkedSection' => 'Collected',
			'groceryList.selectAll' => 'Select all',
			'groceryList.clearAll' => 'Clear all',
			'groceryList.deleteChecked' => 'Delete collected',
			'groceryList.amount' => 'Amount',
			'groceryList.unit' => 'Unit',
			'groceryList.lastSource' => 'At least one source must remain',
			'groceryList.itemName' => 'Item name',
			'groceryList.planFilter' => 'All menus',
			'groceryList.choosePlans' => 'Choose menus',
			'groceryList.plansSelected' => ({required Object count}) => '${count} menus selected',
			'groceryList.onePlanSelected' => 'One menu selected',
			'groceryList.noPlansToPick' => 'No menus to choose from yet',
			'groceryList.allPlansHint' => 'Aggregated from every menu',
			'groceryList.selectPlansTitle' => 'Which menus feed this list?',
			'groceryList.applySelection' => 'Update list',
			'groceryList.selectAllPlans' => 'All menus',
			'groceryList.myLists' => 'My lists',
			'groceryList.listsCount' => ({required Object count}) => '${count} lists',
			'groceryList.oneList' => 'One list',
			'groceryList.newList' => 'New list',
			'groceryList.newListTitle' => 'New shopping list',
			'groceryList.listName' => 'List name',
			'groceryList.defaultListName' => 'Shopping list',
			'groceryList.fromPlans' => 'From menus',
			'groceryList.fromPlansHint' => 'Combines the recipes in your meal plans',
			'groceryList.fromRecipe' => 'From a recipe',
			'groceryList.fromRecipeHint' => 'The ingredients of one recipe',
			'groceryList.emptyList' => 'Empty list',
			'groceryList.emptyListHint' => 'You add the items by hand',
			'groceryList.sourcePlans' => 'From menus',
			'groceryList.sourceRecipe' => ({required Object title}) => 'From the recipe "${title}"',
			'groceryList.sourceManual' => 'Hand-made list',
			'groceryList.renameList' => 'Rename list',
			'groceryList.deleteList' => 'Delete list',
			'groceryList.deleteListConfirm' => ({required Object name}) => '"${name}" and all its items will be deleted.',
			'groceryList.progress' => ({required Object checked, required Object total}) => '${checked}/${total}',
			'groceryList.servings' => 'Servings',
			'groceryList.timesOver' => 'Quantity',
			'groceryList.scaleValue' => ({required Object value}) => '×${value}',
			'groceryList.rebuildFromRecipe' => 'Rebuild from the recipe',
			'groceryList.createFromRecipe' => 'Create shopping list',
			'groceryList.createList' => 'Create list',
			'groceryList.recipeListTitle' => 'Shopping list from a recipe',
			'groceryList.recipeListHint' => 'The recipe\'s ingredients, scaled to how much you are making',
			'groceryList.listCreated' => ({required Object name}) => 'The list "${name}" was created',
			'groceryList.openList' => 'Open list',
			'groceryList.stayHere' => 'Stay here',
			'groceryList.noIngredients' => 'This recipe has no ingredients to shop for',
			'groceryList.addFirstItem' => 'Add an item',
			'groceryList.leaveListConfirm' => ({required Object name}) => 'Leave the shared list "${name}"? It will be removed from your lists.',
			'receipt.title' => 'Scan a receipt',
			'receipt.subtitle' => 'Photograph a receipt or upload a PDF, and the prices are kept for your grocery list',
			'receipt.camera' => 'Photograph receipt',
			'receipt.cameraHint' => 'Long receipt? Take several photos, we merge them',
			'receipt.gallery' => 'Pick from gallery',
			'receipt.pdf' => 'PDF file',
			'receipt.addPhoto' => 'Another photo',
			'receipt.scan' => 'Scan',
			'receipt.scanning' => 'Reading the receipt…',
			'receipt.pagesCount' => ({required Object count}) => '${count} photos',
			'receipt.scanFailed' => 'We could not read the receipt. Try a sharper photo or a PDF.',
			'receipt.reviewTitle' => 'What was captured',
			'receipt.reviewSubtitle' => 'Fix names and prices before saving',
			'receipt.store' => 'Store',
			'receipt.date' => 'Date',
			'receipt.receiptTotal' => 'Receipt total',
			'receipt.itemsTotal' => 'Captured items total',
			'receipt.captured' => 'Captured products',
			'receipt.capturedCount' => ({required Object count}) => '${count} products',
			'receipt.unreadable' => 'Could not capture',
			'receipt.unreadableHint' => 'Notes on lines we could not read. Add them by hand below if needed.',
			'receipt.addLine' => 'Add product',
			'receipt.itemName' => 'Product name',
			'receipt.price' => 'Unit price',
			'receipt.quantity' => 'Quantity',
			'receipt.removeLine' => 'Remove line',
			'receipt.shareToggle' => 'Share prices with the community',
			'receipt.shareHint' => 'Product names and prices only. Not the store, the date or who paid.',
			'receipt.save' => 'Save prices',
			'receipt.saved' => ({required Object count}) => '${count} prices saved',
			'receipt.savedShared' => ({required Object count}) => '${count} prices saved and shared',
			'receipt.nothingToSave' => 'No products to save',
			'receipt.estimated' => 'Estimated from past data',
			'receipt.estimatedTotal' => 'Estimated cost',
			'receipt.noData' => 'No data',
			'receipt.fromReceipt' => 'From your receipt',
			'receipt.fromCommunity' => 'Community median',
			'receipt.unpriced' => ({required Object count}) => '${count} items without a price',
			'receipt.priceBook' => 'My prices',
			'receipt.priceBookEmpty' => 'No receipts scanned yet. Scan the first to see what shopping costs.',
			'receipt.deleteRecord' => 'Delete price',
			'receipt.cameraGuide' => 'Fit the receipt inside the frame',
			'receipt.cameraHold' => 'Hold still…',
			'receipt.cameraCaptured' => 'Captured!',
			'receipt.cameraUnavailable' => 'No camera access',
			'receipt.perUnit' => 'per unit',
			'receipt.perKg' => 'per kg',
			'receipt.perLiter' => 'per litre',
			'receipt.printedAs' => ({required Object name}) => 'Printed: ${name}',
			'receipt.receipts' => 'Receipts',
			'receipt.prices' => 'Prices',
			'receipt.sortBy' => 'Sort',
			'receipt.sortDate' => 'Date',
			'receipt.sortStore' => 'Store',
			'receipt.sortTotal' => 'Total',
			'receipt.sortName' => 'Name',
			'receipt.noReceipts' => 'No receipts saved yet',
			'receipt.noPrices' => 'No prices saved yet',
			'receipt.deleteReceipt' => 'Delete receipt',
			'receipt.deleteReceiptBody' => 'The receipt and every price read from it will be deleted.',
			'receipt.addPrice' => 'Add price',
			'receipt.addPriceHint' => 'Without a receipt: a price you paid or know',
			'receipt.manualSource' => 'Entered by hand',
			'receipt.lastPaid' => 'Last paid',
			'receipt.priceSaved' => 'Price saved',
			'receipt.itemsInReceipt' => ({required Object count}) => '${count} products',
			'receipt.search' => 'Search product',
			'receipt.viewImage' => 'Receipt image',
			'receipt.noImage' => 'No image was kept for this receipt',
			'receipt.pdfFile' => 'Receipt from a PDF file',
			'receipt.filter' => 'Filter',
			'receipt.filterAll' => 'All',
			'receipt.periodAll' => 'All time',
			'receipt.period30' => '30 days',
			'receipt.period90' => '90 days',
			'receipt.sourceReceipt' => 'From receipts',
			'receipt.sourceManual' => 'Entered by hand',
			'receipt.deleteProduct' => 'Delete product',
			'receipt.deleteProductBody' => 'Every price saved for this product will be deleted.',
			'receipt.pickFromPrices' => 'Pick from my prices',
			'receipt.pickerTitle' => 'My products',
			'receipt.existingPrice' => ({required Object price}) => 'Already known: ${price}',
			'receipt.keepNew' => 'New price',
			'receipt.keepOld' => 'Old price',
			'receipt.keepAverage' => 'Average',
			'receipt.deleteReceiptOnly' => 'Delete receipt only',
			'receipt.deleteReceiptOnlyHint' => 'The prices read from it stay',
			'receipt.deleteReceiptAndPrices' => 'Delete receipt and its prices',
			'receipt.deleteAll' => 'Delete all prices',
			'receipt.deleteAllBody' => 'Every price, receipt and choice will be deleted. This cannot be undone.',
			'receipt.pricingTitle' => 'Which price to use',
			'receipt.pricingLatest' => 'Latest',
			'receipt.pricingAverage' => 'Average of all',
			'receipt.pricingStore' => 'By store',
			'receipt.pricingReceipts' => 'Chosen receipts',
			'receipt.pricingActive' => ({required Object price}) => 'In use: ${price}',
			'receipt.history' => 'Price history',
			'receipt.noStore' => 'No store',
			'receipt.pricingSaved' => 'Choice saved',
			'receipt.renameStore' => 'Rename store',
			'receipt.storeName' => 'Store name',
			'receipt.allStores' => 'All stores',
			'receipt.applyFilters' => 'Apply',
			'receipt.clearFilters' => 'Clear',
			'unit.gram' => 'g',
			'unit.kilogram' => 'kg',
			'unit.milliliter' => 'ml',
			'unit.liter' => 'L',
			'unit.teaspoon' => 'tsp',
			'unit.tablespoon' => 'tbsp',
			'unit.cup' => 'cup',
			'unit.unit' => 'unit',
			'unit.pinch' => 'pinch',
			'unit.unspecified' => '—',
			'image.add' => 'Add a photo',
			'image.change' => 'Change photo',
			'image.gallery' => 'Choose from gallery',
			'image.camera' => 'Take a photo',
			'image.remove' => 'Remove photo',
			'image.generate' => 'Create with AI',
			'image.generating' => 'Creating a picture… this takes a few seconds',
			'image.generateFailed' => 'Creating the picture failed, please try again',
			'image.coverTitle' => 'What cover to create?',
			'image.coverHint' => 'Pick a category, write something, or both',
			'image.coverFreeText' => 'Free text, e.g. burgers',
			'image.coverRequired' => 'Pick a category or write something',
			'image.coverGenerate' => 'Create cover',
			'image.themeKids' => 'Kids',
			'image.themeHealthy' => 'Healthy',
			'image.themeIndulgent' => 'Indulgent',
			'image.themeSweets' => 'Sweets & baking',
			'image.themeMeat' => 'Meat & grill',
			'image.themeVegan' => 'Vegan',
			'image.themeHolidays' => 'Holidays',
			'image.themeQuick' => 'Quick & simple',
			'image.webSearch' => 'Search Google Images',
			'image.webSearchTitle' => 'Image search',
			'image.webSearchHint' => 'What to search for? e.g. beet kubbeh',
			'image.webSearchEmpty' => 'No pictures found, try different words',
			'image.webSearchFailed' => 'The search failed, please try again',
			'image.webSearchUnavailable' => 'Image search is not available right now',
			'image.webSearchEnd' => 'That is all the results',
			'image.webSearchDownloadFailed' => 'Could not download that picture, try another',
			'nav.library' => 'Library',
			'nav.recipes' => 'Recipes',
			'nav.mealPlan' => 'Meals',
			'nav.groceries' => 'Groceries',
			'nav.settings' => 'Settings',
			'nav.community' => 'Community',
			'update.forcedTitle' => 'Update required',
			'update.forcedBody' => ({required Object version}) => 'This version of EasyPlate is no longer supported. Update to ${version} to continue.',
			'update.optionalTitle' => 'A new version is out',
			'update.optionalBody' => ({required Object version}) => 'EasyPlate ${version} is in the store, with the latest improvements.',
			'update.updateNow' => 'Update now',
			'update.later' => 'Skip',
			'ads.badge' => 'Ad',
			'ads.freeViewsLeft' => ({required Object count}) => '${count} free recipes left today',
			'ads.rewardedViewsLeft' => ({required Object count}) => '${count} unlocks with a short video left today',
			'ads.sharedQuotaReached' => 'You\'ve reached today\'s limit of shared recipes. It resets tomorrow!',
			'ads.unlockRecipeTitle' => 'Unlock a shared recipe',
			'ads.unlockRecipeMessage' => ({required Object count}) => 'Watch a short video to unlock this recipe (${count} left today)',
			'ads.aiQuotaLeft' => ({required Object remaining, required Object total}) => '${remaining}/${total} AI extractions left today',
			'ads.aiQuotaReached' => 'You\'ve reached today\'s limit of AI extractions. It reopens tomorrow!',
			'ads.aiLockedHint' => 'Extracting from a link requires watching a short video',
			'ads.unlockAiTitle' => 'Extract a recipe with AI',
			'ads.unlockAiMessage' => ({required Object count}) => 'Watch a short video to extract the recipe from the link (${count} left today)',
			'ads.watchVideo' => 'Watch the video',
			'ads.parseWithVideo' => 'Watch a video and parse',
			'ads.blockedForToday' => 'Locked for today',
			'ads.loadingVideo' => 'Loading the video...',
			'ads.videoNotCompleted' => 'The video wasn\'t completed, the recipe stays locked',
			'ads.videoUnavailable' => 'No video is available right now, try again in a moment',
			'premium.title' => 'EasyPlate Premium',
			'premium.headline' => 'No ads, no limits',
			'premium.subtitle' => 'Everything EasyPlate can do, without waiting for tomorrow.',
			'premium.benefitNoAds' => 'No ads in the community feeds',
			'premium.benefitShared' => 'Shared recipes with no daily limit',
			'premium.benefitAi' => ({required Object count}) => 'AI recipe extraction from any link, up to ${count} a day',
			'premium.periodWeekly' => 'Weekly',
			'premium.periodMonthly' => 'Monthly',
			'premium.periodTwoMonth' => 'Every 2 months',
			'premium.periodThreeMonth' => 'Quarterly',
			'premium.periodSixMonth' => 'Every 6 months',
			'premium.periodAnnual' => 'Yearly',
			'premium.periodLifetime' => 'Lifetime',
			'premium.bestValue' => 'Best value',
			'premium.subscribeFor' => ({required Object price}) => 'Subscribe for ${price}',
			'premium.buyFor' => ({required Object price}) => 'Buy for ${price}',
			'premium.restore' => 'Restore purchases',
			'premium.restored' => 'Your subscription was restored',
			'premium.nothingToRestore' => 'No purchases to restore',
			'premium.activeTitle' => 'Premium is active',
			'premium.activeBody' => 'Thank you! Ads and daily limits are off for this account.',
			'premium.manage' => 'Manage subscription',
			'premium.cancel' => 'Cancel subscription',
			'premium.cancelNote' => 'Cancelling turns off auto-renewal. Premium stays active until the end of the period already paid for. No refunds.',
			'premium.unavailable' => 'Subscriptions are not available right now. Please try again later.',
			'premium.purchaseFailed' => 'The purchase did not go through',
			'premium.purchased' => 'Welcome to Premium!',
			'premium.legal' => 'The subscription renews automatically at the end of each period unless cancelled at least 24 hours before it ends. Payment is charged to your store account and can be managed or cancelled in the store\'s settings.',
			'premium.terms' => 'Terms of Use',
			'premium.privacy' => 'Privacy Policy',
			'premium.startFor' => ({required Object price}) => 'Start for ${price}',
			'premium.startFree' => 'Start free',
			'premium.free' => 'Free',
			'premium.introDays' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'for the first day', other: 'for the first ${n} days', ), 
			'premium.introWeeks' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'for the first week', other: 'for the first ${n} weeks', ), 
			'premium.introMonths' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'for the first month', other: 'for the first ${n} months', ), 
			'premium.introYears' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'for the first year', other: 'for the first ${n} years', ), 
			'premium.introPaidTerms' => ({required Object price, required Object span, required Object then}) => '${price} ${span}, then ${then}. The price updates automatically.',
			'premium.introFreeTerms' => ({required Object span, required Object then}) => 'Free ${span}, then ${then}. Billing starts automatically.',
			'premium.redeem' => 'I have a coupon code',
			'premium.redeemTitle' => 'Coupon code',
			'premium.redeemHint' => 'Type the code you received',
			'premium.redeemConfirm' => 'Redeem in the store',
			'premium.perWeekly' => 'per week',
			'premium.perMonthly' => 'per month',
			'premium.perTwoMonth' => 'every 2 months',
			'premium.perThreeMonth' => 'every 3 months',
			'premium.perSixMonth' => 'every 6 months',
			'premium.perAnnual' => 'per year',
			'premium.tierPro' => 'Pro',
			'premium.tierDuo' => 'Pro Duo',
			'premium.tierFamily' => 'Pro Family',
			'premium.tierProHint' => 'One account',
			'premium.tierDuoHint' => '2 accounts, everything mirrored',
			'premium.tierFamilyHint' => 'Up to 6 accounts, everything mirrored',
			'premium.benefitHousehold' => ({required Object n}) => 'Shared account for ${n} people: recipes, plans and lists in sync',
			'walkthrough.title' => 'Guide',
			'walkthrough.start' => 'Start the guide',
			'walkthrough.startHint' => 'A guided tour of everything in the app, step by step',
			'walkthrough.startFull' => 'Start the full tour',
			'walkthrough.focused' => 'Show focused guidance',
			'walkthrough.next' => 'Next',
			'walkthrough.finish' => 'Done',
			'walkthrough.skipStep' => 'Skip step',
			'walkthrough.close' => 'Close guide',
			'walkthrough.stepOf' => ({required Object current, required Object total}) => 'Step ${current} of ${total}',
			'walkthrough.tapHint' => 'Tap the highlighted area, or "Next"',
			'walkthrough.bookTitle' => 'EasyPlate guide',
			'walkthrough.bookSubtitle' => 'Everything the app can do, chapter by chapter. The samples in this book are never saved; the live tour does the real actions, with the fields already filled in.',
			'walkthrough.contents' => 'Contents',
			'walkthrough.chapter' => ({required Object number}) => 'Chapter ${number}',
			'walkthrough.backToContents' => 'Back to contents',
			'walkthrough.stepsTitle' => 'Steps',
			'walkthrough.welcomeTitle' => 'Welcome to EasyPlate',
			'walkthrough.welcomeBody' => 'Let\'s walk through the main actions together and really do them: the fields are already filled in for you. Skip any step, or close and start again from the support screen.',
			'walkthrough.topics.addRecipe.title' => 'Add a recipe',
			'walkthrough.topics.addRecipe.summary' => 'Bring a recipe in from any source and the AI arranges it into one format: ingredients, amounts, steps, tags, servings and nutrition.',
			'walkthrough.topics.addRecipe.s1' => 'Tap the sparkle button next to the title to add a recipe.',
			'walkthrough.topics.addRecipe.s2' => 'Pick a source: pasted text, a web search, a website link, a video from TikTok, Instagram, YouTube or Facebook, a free request to the AI, or writing by hand.',
			'walkthrough.topics.addRecipe.s3' => 'A sample recipe is filled in here, just as you would paste one. The button below sends it to the AI, which returns a tidy recipe to review, edit and save. The analysis takes up to half a minute, so leave it for after the tour.',
			'walkthrough.topics.myRecipes.title' => 'My recipes and saved',
			'walkthrough.topics.myRecipes.summary' => 'The recipes you wrote and the ones you saved from the community, with search and topic filters.',
			'walkthrough.topics.myRecipes.s1' => 'Switch here between recipes you wrote and recipes you saved from the community.',
			'walkthrough.topics.myRecipes.s2' => 'Search by name, and filter by topic: meat, dairy, vegetarian, vegan, kosher, gluten-free and allergy. Every recipe also marks the allergens in it.',
			'walkthrough.topics.library.title' => 'Recipe books',
			'walkthrough.topics.library.summary' => 'Arrange recipes into books with a table of contents, a cover and page turning, and share a whole book with another account.',
			'walkthrough.topics.library.s1' => 'Tap "Library" to go to your books.',
			'walkthrough.topics.library.s2' => 'Tap the plus to create a new book.',
			'walkthrough.topics.library.s3' => 'The book\'s name is already filled in: "Tutorial". Tap the field to change it, then carry on.',
			'walkthrough.topics.library.s4' => 'Tap "Save" to create the book.',
			'walkthrough.topics.library.s5' => 'Pick a spine colour, which tells the books apart on the shelf, and tap "Save". The book opens straight away.',
			'walkthrough.topics.library.s6' => 'This is the book you made. Add recipes to it from here; inside, turn the pages and jump from the contents. A long press on a book on the shelf opens sharing, cover, rename and delete.',
			'walkthrough.topics.mealPlan.title' => 'Weekly plan and nutrition',
			'walkthrough.topics.mealPlan.summary' => 'A plan for the whole week with a nutrition summary for each day, which feeds the grocery list.',
			'walkthrough.topics.mealPlan.s1' => 'Tap "Meals" to plan the week.',
			'walkthrough.topics.mealPlan.s2' => 'Tap here to create a weekly plan.',
			'walkthrough.topics.mealPlan.s3' => 'The plan\'s name is already filled in. Below, pick a template: free, three meals a day or six.',
			'walkthrough.topics.mealPlan.s4' => 'Tap "Save" to create the plan.',
			'walkthrough.topics.mealPlan.s5' => 'Place recipes on each day\'s meals. The nutrition card adds up calories, protein, carbs and fat by servings. Tap the chart to open the weekly dashboard.',
			'walkthrough.topics.mealPlan.s6' => 'The dashboard: daily average, weekly total, a bar per day and the macro split. The values are estimated by the AI for every recipe, per serving.',
			'walkthrough.topics.mealPlan.s7' => 'The share button sends the plan to another account, as an editor or a viewer. An edit on one side reaches everyone.',
			'walkthrough.topics.groceries.title' => 'Grocery list and prices',
			'walkthrough.topics.groceries.summary' => 'A list built from the plan, with what has been picked up ticked off, a cost estimate from your receipts, and sharing with whoever shops with you.',
			'walkthrough.topics.groceries.s1' => 'Tap "Groceries".',
			'walkthrough.topics.groceries.s2' => 'Refresh rebuilds the list from every recipe in the weekly plan.',
			'walkthrough.topics.groceries.s3' => 'Tap the plus to add an item by hand.',
			'walkthrough.topics.groceries.s4' => 'The item\'s name is already filled in. Pick an amount and a unit, or start from a product your receipts already know.',
			'walkthrough.topics.groceries.s5' => 'Tap "Add" and the item joins the list.',
			'walkthrough.topics.groceries.s6' => 'Tap here to open the price book.',
			'walkthrough.topics.groceries.s7' => 'Scan a receipt and the price of every product is kept. From there the grocery list gets a cost estimate, and community median prices fill in what you have not bought yet.',
			'walkthrough.topics.groceries.shefi' => 'Ask Shefi about this list: what is missing for a meal, what to swap, or add items by voice.',
			'walkthrough.topics.community.title' => 'Community',
			'walkthrough.topics.community.summary' => 'Recipes shared by everyone, and a forum for questions and answers.',
			'walkthrough.topics.community.s1' => 'Tap "Community".',
			'walkthrough.topics.community.s2' => 'Shared recipes and the forum. Like a recipe, a thread or a reply, save a recipe to your own, and attach a recipe to a forum reply.',
			'walkthrough.topics.community.s3' => 'The share button publishes one of your own recipes to the community.',
			'walkthrough.topics.account.title' => 'Account, premium and settings',
			'walkthrough.topics.account.summary' => 'Notifications about share invites, and the account with premium, shared access, settings and the display mode.',
			'walkthrough.topics.account.s1' => 'Notifications: invitations to share books and plans, and updates.',
			'walkthrough.topics.account.s2' => 'Tap the picture to open your account.',
			'walkthrough.topics.account.s3' => 'Premium: AI analyses with no daily limit and no ads. A free account gets a daily allowance, which a short video extends.',
			'walkthrough.topics.account.s4' => 'Shared access: who shares books, plans and grocery lists with you, and what you have shared.',
			'walkthrough.topics.account.s5' => 'Tap "Settings".',
			'walkthrough.topics.account.s6' => 'Display mode: light, dark or as the device. Settings also hold the language, dietary preferences and allergens. This guide can be started again from the support screen in the account.',
			'walkthrough.topics.account.shefi' => 'Shefi, the smart assistant: this floating button opens a chat. Ask in writing or out loud, and Shefi answers, adds to the plan, builds a list or starts Cook Mode. Inside a recipe, plan or list, the "Ask Shefi" button talks about that item only.',
			'walkthrough.topics.settings.title' => 'Settings and preferences',
			'walkthrough.topics.settings.summary' => 'Every row of the settings and the preferences: profile, sharing, notifications, language, look, account deletion, shopping day, prices, diet and books.',
			'walkthrough.topics.settings.s1' => 'Tap "Settings": the account and the app live here.',
			'walkthrough.topics.settings.s2' => 'Profile: the name and photo the people you share with see, and the linked sign-in methods.',
			'walkthrough.topics.settings.s3' => 'Shared access: who shares recipes, books, plans and lists with you, and what you shared. Joining by code or QR starts here too.',
			'walkthrough.topics.settings.s4' => 'Tap "Notification settings".',
			'walkthrough.topics.settings.s5' => 'Push notifications: the master switch. Off, nothing is sent; below it you pick what is: replies, invites, updates and messages from the team.',
			'walkthrough.topics.settings.s6' => 'Shopping-day reminders: when to remind you before the shop. Scheduled on the device, apart from push.',
			'walkthrough.topics.settings.s7' => 'Language: switching also translates your recipes, books, plans and lists.',
			'walkthrough.topics.settings.s8' => 'Appearance: light, dark or follow the device. The choice is saved on the account and follows you to the next device.',
			'walkthrough.topics.settings.s9' => 'Delete account: permanently removes the account and everything in it, after a confirmation. A store subscription is cancelled separately.',
			'walkthrough.topics.settings.s10' => 'Back on the account: tap "Preferences", how the app behaves for you.',
			'walkthrough.topics.settings.s11' => 'Shopping day: the day the grocery list is built around and the reminders are timed to.',
			'walkthrough.topics.settings.s12' => 'Community prices: when on, prices from your receipts join anonymous averages, and lines you never bought are estimated from them.',
			'walkthrough.topics.settings.s13' => 'Dietary preferences and allergens: mark them here and the app highlights them in recipes and shared recipes.',
			'walkthrough.topics.settings.s14' => 'Fast page turn in books: jumping to a distant page turns a single page. Off, it flips through every page on the way.',
			'walkthrough.topics.settings.s15' => 'Sounds: sound effects on page turns and actions. Can be switched off.',
			'walkthrough.demo.bookTitle' => 'Tutorial',
			'walkthrough.demo.planName' => 'Tutorial plan',
			'walkthrough.demo.mealName' => 'Dinner',
			'walkthrough.demo.groceryItem' => 'Tomatoes',
			'walkthrough.demo.recipeText' => 'Jerusalem shakshuka\n\nIngredients:\n400 g crushed tomatoes\n4 eggs\n1 onion\n2 tbsp olive oil\n1 tsp sweet paprika\nA pinch of salt\n\nMethod:\n1. Heat the olive oil in a pan and fry the onion until golden.\n2. Add the tomatoes and paprika and simmer for 10 minutes.\n3. Crack the eggs into the sauce, cover, and cook until the whites set.',
			'walkthrough.demoRecipes' => 'Sample recipes',
			'walkthrough.demoRecipesHint' => 'This is what recipes look like in the app. Tap one to see its full page: times, topics, allergens, ingredients and steps.',
			'walkthrough.demoBooks' => 'Sample books',
			'walkthrough.demoBooksHint' => 'This is what a recipe book looks like. Tap one to open it, turn its pages and jump from the contents.',
			'walkthrough.demoOnly' => 'Sample only, not saved',
			'feedback.title' => 'Report and suggest',
			'feedback.subtitle' => 'Found a bug? Have an idea? Write to us here; every message is read.',
			'feedback.bug' => 'Bug',
			'feedback.suggestion' => 'Suggestion',
			'feedback.bugHint' => 'Describe the bug: what you did, what happened, and what you expected...',
			'feedback.suggestionHint' => 'Tell us what you would like the app to do, and how it would help you...',
			'feedback.send' => 'Send',
			'feedback.sent' => 'Thanks! Your message was sent.',
			'feedback.failed' => 'Sending failed, please try again later',
			'feedback.admin' => 'Feedback inbox',
			'feedback.all' => 'All',
			'feedback.bugs' => 'Bugs',
			'feedback.suggestions' => 'Suggestions',
			'feedback.none' => 'No messages yet',
			'feedback.version' => ({required Object version}) => 'Version ${version}',
			'feedback.notAllowed' => 'This screen is for the administrator only',
			'adminBilling.title' => 'Subscriptions',
			'adminBilling.all' => 'All',
			'adminBilling.paying' => 'Paying',
			'adminBilling.problems' => 'Problems',
			'adminBilling.searchHint' => 'Search by name, email, phone or uid',
			'adminBilling.none' => 'No accounts to show',
			'adminBilling.premium' => 'Premium',
			'adminBilling.free' => 'Free',
			'adminBilling.untilDate' => ({required Object date}) => 'Until ${date}',
			'adminBilling.adminLocked' => 'Set by admin',
			'adminBilling.viaRevenueCat' => 'From RevenueCat',
			'adminBilling.sandbox' => 'Sandbox',
			'adminBilling.lastEvent' => ({required Object type, required Object date}) => '${type} · ${date}',
			_ => null,
		} ?? switch (path) {
			'adminBilling.product' => ({required Object id}) => 'Product: ${id}',
			'adminBilling.eventsCount' => ({required Object count}) => '${count} events',
			'adminBilling.grant' => 'Grant premium',
			'adminBilling.revoke' => 'Revoke premium',
			'adminBilling.release' => 'Return to RevenueCat',
			'adminBilling.releaseHint' => 'Set by hand: RevenueCat\'s next event is ignored until released.',
			'adminBilling.granted' => 'Premium granted',
			'adminBilling.revoked' => 'Premium revoked',
			'adminBilling.released' => 'Back under RevenueCat',
			'adminBilling.revokeConfirm' => ({required Object name}) => 'Revoke premium for ${name}?',
			'adminBilling.problemPaidNotPremium' => 'Paid, but the account is not premium',
			'adminBilling.problemNoEntitlement' => 'A purchase arrived without the entitlement (product not attached in RevenueCat)',
			'adminBilling.orphanTitle' => 'Purchases without an account',
			'adminBilling.orphanBody' => 'Receipts that arrived under an anonymous RevenueCat id, with no user to unlock',
			'adminBilling.summary' => ({required Object premium, required Object problems, required Object total}) => '${premium} premium · ${problems} problems · ${total} accounts',
			'adminBilling.noEntitlementTag' => 'No entitlement',
			'adminDashboard.title' => 'Admin dashboard',
			'adminDashboard.tabDashboard' => 'Overview',
			'adminDashboard.tabSubscriptions' => 'Subscriptions',
			'adminDashboard.tabTickets' => 'Tickets',
			'adminDashboard.rangeToday' => 'Today',
			'adminDashboard.rangeMonth' => '30 days',
			'adminDashboard.rangeAll' => 'All',
			'adminDashboard.aiCost' => 'AI cost',
			'adminDashboard.aiCostHint' => 'tokens × price list',
			'adminDashboard.revenue' => 'Revenue',
			'adminDashboard.revenueNone' => 'No payments in range',
			'adminDashboard.sandboxNote' => ({required Object count}) => '${count} sandbox payments not counted',
			'adminDashboard.paymentsCount' => ({required Object count}) => '${count} payments',
			'adminDashboard.aiCalls' => 'AI calls',
			'adminDashboard.cacheSaved' => ({required Object count}) => '${count} from cache (free)',
			'adminDashboard.errorsCount' => ({required Object count}) => '${count} errors',
			'adminDashboard.tokens' => 'Tokens',
			'adminDashboard.tokensHint' => ({required Object input, required Object output}) => 'in ${input} · out ${output}',
			'adminDashboard.usersTotal' => 'Total users',
			'adminDashboard.newUsers' => ({required Object count}) => '${count} new in range',
			'adminDashboard.disabledCount' => ({required Object count}) => '${count} blocked',
			'adminDashboard.premiumUsers' => 'Paying',
			'adminDashboard.freeCount' => ({required Object count}) => '${count} free',
			'adminDashboard.freeUsers' => 'Free',
			'adminDashboard.activeUsers' => 'Active AI users',
			'adminDashboard.costPerUser' => 'Cost per active user',
			'adminDashboard.tickets' => 'Tickets',
			'adminDashboard.unreadCount' => ({required Object count}) => '${count} new',
			'adminDashboard.chartCost' => 'AI cost per day',
			'adminDashboard.chartCalls' => 'AI calls per day',
			'adminDashboard.chartSignups' => 'Sign-ups per day',
			'adminDashboard.chartPlatform' => 'Users by platform',
			'adminDashboard.chartPlan' => 'Free vs paying',
			'adminDashboard.chartKinds' => 'Calls by feature',
			'adminDashboard.chartModels' => 'Cost by model',
			'adminDashboard.chartVersions' => 'App versions',
			'adminDashboard.platformIos' => 'iOS',
			'adminDashboard.platformAndroid' => 'Android',
			'adminDashboard.platformUnknown' => 'Unknown',
			'adminDashboard.noAiUsage' => 'No AI usage in this range',
			'adminDashboard.unknownModel' => 'not in price list',
			'adminDashboard.usersCost' => 'Cost per user',
			'adminDashboard.usersCount' => ({required Object count}) => '${count} users',
			'adminDashboard.searchUser' => 'Search by name, email or uid',
			'adminDashboard.showAll' => ({required Object count}) => 'Show all ${count} users',
			'adminDashboard.callsCount' => ({required Object count}) => '${count} calls',
			'adminDashboard.content' => 'Content and community',
			'adminDashboard.sharedRecipes' => 'Shared recipes',
			'adminDashboard.forumPosts' => 'Forum threads',
			'adminDashboard.withPush' => 'Devices with push',
			'adminDashboard.cacheEntries' => 'Cached links',
			'adminDashboard.cacheHits' => 'Cache hits (calls saved)',
			'adminDashboard.config' => 'Remote config',
			'adminDashboard.environment' => 'Environment',
			'adminDashboard.prod' => 'Production',
			'adminDashboard.dev' => 'Dev',
			'adminDashboard.adsEnabled' => 'Ads',
			'adminDashboard.adsFailOpen' => 'Fail open with no ad',
			'adminDashboard.on' => 'On',
			'adminDashboard.off' => 'Off',
			'adminDashboard.feedInterval' => 'Feed ad interval',
			'adminDashboard.quotaSharedFree' => 'Free views per day',
			'adminDashboard.quotaSharedRewarded' => 'Video views per day',
			'adminDashboard.quotaAiRewarded' => 'Video AI per day',
			'adminDashboard.quotaAiPremium' => 'Premium AI per day',
			'adminDashboard.minVersion' => 'Minimum version',
			'adminDashboard.latestVersion' => 'Latest version',
			'adminDashboard.thisBuild' => 'This build',
			'adminDashboard.pricing' => 'Token price list',
			'adminDashboard.pricingHint' => 'US dollars per million tokens. The defaults are an estimate — update them from Google\'s price list.',
			'adminDashboard.editPricing' => 'Edit price list',
			'adminDashboard.priceInput' => 'Input',
			'adminDashboard.priceOutput' => 'Output',
			'adminDashboard.priceCached' => 'Cached input',
			'adminDashboard.usdToIls' => 'USD/ILS rate',
			'adminDashboard.pricingSaved' => 'Price list saved',
			'adminDashboard.loadedAt' => ({required Object date}) => 'Updated ${date}',
			'adminDashboard.kindText' => 'Text',
			'adminDashboard.kindUrl' => 'Link',
			'adminDashboard.kindSocial' => 'Social',
			'adminDashboard.kindSocialVideo' => 'Video (server)',
			'adminDashboard.kindVideo' => 'Video',
			'adminDashboard.kindSearch' => 'Search',
			'adminDashboard.kindImage' => 'Image',
			'adminDashboard.kindReceipt' => 'Receipt',
			'adminDashboard.kindNutrition' => 'Nutrition',
			'adminDashboard.kindRefine' => 'Refine',
			'adminDashboard.kindGenerate' => 'Generate',
			'adminDashboard.allTime' => 'all time',
			'adminDashboard.recentCalls' => 'Recent calls',
			'adminDashboard.noCalls' => 'No calls',
			'adminDashboard.cacheHit' => 'cache',
			'adminDashboard.statusOk' => 'ok',
			'adminDashboard.pushTitle' => 'Title (optional)',
			'adminDashboard.pushBody' => 'Message',
			'adminDashboard.send' => 'Send',
			'adminDashboard.blocked' => 'Blocked',
			'adminDashboard.disable' => 'Block account',
			'adminDashboard.enable' => 'Unblock',
			'adminDashboard.blockMessageHint' => 'What the user sees when they try to sign in',
			'adminDashboard.disabledDone' => 'Account blocked',
			'adminDashboard.enabledDone' => 'Block removed',
			'adminDashboard.deleteAccount' => 'Delete account',
			'adminDashboard.deleteAccountConfirm' => ({required Object name}) => 'Delete ${name} for good? The user, their recipes, books and plans will be removed and cannot be restored.',
			'adminDashboard.deleted' => 'Account deleted',
			'adminDashboard.sendPush' => 'Send notification',
			'adminDashboard.noPush' => 'This device has no push token — the message will only show in the notifications screen',
			'adminDashboard.pushSent' => 'Notification sent',
			'adminDashboard.sendPushAll' => 'Notify all users',
			'adminDashboard.broadcastConfirm' => ({required Object count}) => 'Send this message to all ${count} users?',
			'adminDashboard.broadcastDone' => ({required Object items, required Object sent, required Object failed}) => 'Written to ${items} inboxes · ${sent} pushes sent · ${failed} failed',
			'adminDashboard.platformTag' => ({required Object platform, required Object version}) => '${platform} · v${version}',
			'adminDashboard.lastSeen' => ({required Object date}) => 'Last seen ${date}',
			'adminDashboard.disabledSince' => ({required Object message}) => 'Block reason: ${message}',
			'adminDashboard.unread' => 'New',
			'adminDashboard.markAllRead' => 'Read all',
			'adminDashboard.allRead' => 'All tickets marked read',
			'adminDashboard.noUnread' => 'No new tickets',
			'adminDashboard.deleteTicket' => 'Delete ticket',
			'adminDashboard.deleteTicketConfirm' => ({required Object name}) => 'Delete the ticket from ${name}?',
			'adminDashboard.ticketDeleted' => 'Ticket deleted',
			'adminDashboard.reply' => 'Reply',
			'adminDashboard.replyHint' => 'The reply lands in the user\'s notifications (and as a push)',
			'adminDashboard.replySent' => 'Reply sent',
			'adminDashboard.yourReply' => ({required Object date}) => 'Your reply · ${date}',
			'adminDashboard.markRead' => 'Mark read',
			'adminDashboard.markUnread' => 'Mark unread',
			'adminDashboard.pricingSync' => 'Sync prices from Google',
			'adminDashboard.pricingSynced' => ({required Object count}) => '${count} models updated from the Google Cloud Billing catalog',
			'adminDashboard.pricingSyncFailed' => ({required Object reason}) => 'Sync failed: ${reason}',
			'adminDashboard.pricingSourceCatalog' => ({required Object date}) => 'Source: Google Cloud Billing (real list prices) · ${date}',
			'adminDashboard.pricingSourceManual' => ({required Object date}) => 'Source: entered by hand · ${date}',
			'adminDashboard.pricingSourceDefaults' => 'Estimate only — tap sync to pull the real prices from Google',
			'adminDashboard.searchPrice' => 'Google Search grounding (\$ per 1,000 queries)',
			'adminDashboard.rateLine' => ({required Object rate, required Object date}) => '${rate} · refreshed weekly · ${date}',
			'adminDashboard.searchesCount' => ({required Object count}) => '${count} searches',
			'adminDashboard.rangeCustom' => 'Pick',
			'adminDashboard.customRange' => ({required Object from, required Object to}) => '${from} – ${to} · tap to change',
			'adminDashboard.priceImageOutput' => 'Image output',
			'adminDashboard.dataSince' => ({required Object date}) => 'Data is collected from ${date}. Earlier Google charges are not recorded here.',
			'adminDashboard.grantTitle' => ({required Object name}) => 'Premium for ${name} — for how long?',
			'adminDashboard.grantForever' => 'Forever (until I revoke)',
			'adminDashboard.grantWeek' => 'A week',
			'adminDashboard.grantMonth' => 'A month',
			'adminDashboard.grantYear' => 'A year',
			'adminDashboard.grantRange' => 'Exact date range',
			'adminDashboard.grantedUntil' => ({required Object date}) => 'Premium granted until ${date}',
			'adminDashboard.grantStarts' => ({required Object date}) => 'Starts ${date}',
			'adminDashboard.tabConfig' => 'Config',
			'adminDashboard.releaseSession' => 'Disconnect the signed-in device',
			'adminDashboard.releaseSessionDone' => 'Device disconnected; the user will be asked to sign in again',
			'assistant.title' => 'Shefi',
			'assistant.subtitle' => 'Your sous-chef: ask, plan, shop, cook',
			'assistant.placeholder' => 'Ask or tell me what to do…',
			'assistant.send' => 'Send',
			'assistant.thinking' => 'Thinking…',
			'assistant.working' => ({required Object tool}) => 'Working: ${tool}',
			'assistant.welcome' => ({required Object name}) => 'Hi ${name}! I can add groceries, plan your week, import recipes from links, start cook mode and more. What shall we do?',
			'assistant.error' => 'Something went wrong. Try again.',
			'assistant.quotaReached' => 'Today\'s AI allowance is used up. It reopens tomorrow.',
			'assistant.premiumOnly' => 'Shefi is part of EasyPlate Premium',
			'assistant.unlock' => 'See Premium',
			'assistant.clear' => 'New conversation',
			'assistant.openResult' => 'Open',
			'assistant.done' => 'Done',
			'assistant.undone' => 'Reverted',
			'assistant.confirmTitle' => 'Delete?',
			'assistant.confirmBody' => ({required Object what}) => '${what} will be deleted.',
			'assistant.notFound' => ({required Object name}) => 'I couldn\'t find "${name}".',
			'assistant.listTitle' => 'Grocery list',
			'assistant.addedItems' => ({required Object count}) => 'Added ${count} items',
			'assistant.plannedMeal' => ({required Object day, required Object slot}) => 'Planned for ${day} · ${slot}',
			'assistant.recipeSaved' => 'Recipe saved',
			'assistant.cookStarted' => 'Cook mode started',
			'assistant.timerSet' => ({required Object n}) => 'Timer set for step ${n}',
			'assistant.prefSaved' => 'Preference saved',
			'assistant.needsPremium' => 'That needs EasyPlate Premium.',
			'assistant.results' => ({required Object count}) => '${count} results',
			'assistant.suggest.templates.0' => 'Add {food} to my grocery list',
			'assistant.suggest.templates.1' => 'Add {food} and {food2} to the list',
			'assistant.suggest.templates.2' => 'Plan {dish} for {day} {meal}',
			'assistant.suggest.templates.3' => 'Plan something quick for {day} {meal}',
			'assistant.suggest.templates.4' => 'What can I cook with {food} and {food2}?',
			'assistant.suggest.templates.5' => 'Import a recipe from {site}',
			'assistant.suggest.templates.6' => 'Find a recipe for {dish} online',
			'assistant.suggest.templates.7' => 'Start cooking {dish}',
			'assistant.suggest.templates.8' => 'Set a {n}-minute timer for step 2',
			'assistant.suggest.templates.9' => 'Make a grocery list from {dish}',
			'assistant.suggest.templates.10' => 'Create a book called {book}',
			'assistant.suggest.templates.11' => 'Which of my recipes are {diet}?',
			'assistant.suggest.templates.12' => 'Mark {food} as bought',
			'assistant.suggest.templates.13' => 'Remove {food} from the list',
			'assistant.suggest.templates.14' => 'Create a plan for next week',
			'assistant.suggest.templates.15' => 'Show me what\'s planned for {day}',
			'assistant.suggest.templates.16' => 'Change my shopping day to {day}',
			'assistant.suggest.templates.17' => 'Suggest a {diet} dinner for {day}',
			'assistant.suggest.templates.18' => 'How long do I boil an egg?',
			'assistant.suggest.templates.19' => 'What can replace {food} in a recipe?',
			'assistant.suggest.templates.20' => 'How do I store {food}?',
			'assistant.suggest.templates.21' => 'How many calories are in {dish}?',
			'assistant.suggest.templates.22' => 'What\'s the right oven temperature for {dish}?',
			'assistant.suggest.templates.23' => 'How do I make {dish} vegan?',
			'assistant.suggest.templates.24' => 'How much is {n} tablespoons in grams?',
			'assistant.suggest.templates.25' => 'Why did my {dish} come out dry?',
			'assistant.suggest.templates.26' => 'What goes well with {dish}?',
			'assistant.suggest.templates.27' => 'Is {food} safe to freeze?',
			'assistant.suggest.templates.28' => 'How do I thicken a sauce?',
			'assistant.suggest.templates.29' => 'What\'s a quick {diet} lunch idea?',
			'assistant.suggest.food.0' => 'milk',
			'assistant.suggest.food.1' => 'eggs',
			'assistant.suggest.food.2' => 'bread',
			'assistant.suggest.food.3' => 'tomatoes',
			'assistant.suggest.food.4' => 'onions',
			'assistant.suggest.food.5' => 'olive oil',
			'assistant.suggest.food.6' => 'rice',
			'assistant.suggest.food.7' => 'chicken',
			'assistant.suggest.food.8' => 'lemons',
			'assistant.suggest.food.9' => 'garlic',
			'assistant.suggest.food.10' => 'butter',
			'assistant.suggest.food.11' => 'flour',
			'assistant.suggest.food.12' => 'cheese',
			'assistant.suggest.food.13' => 'yogurt',
			'assistant.suggest.food.14' => 'cucumbers',
			'assistant.suggest.food.15' => 'pasta',
			'assistant.suggest.dish.0' => 'shakshuka',
			'assistant.suggest.dish.1' => 'lentil soup',
			'assistant.suggest.dish.2' => 'pasta pesto',
			'assistant.suggest.dish.3' => 'chicken curry',
			'assistant.suggest.dish.4' => 'salmon',
			'assistant.suggest.dish.5' => 'stir-fry',
			'assistant.suggest.dish.6' => 'pancakes',
			'assistant.suggest.dish.7' => 'hummus',
			'assistant.suggest.dish.8' => 'roast vegetables',
			'assistant.suggest.dish.9' => 'banana bread',
			'assistant.suggest.day.0' => 'Sunday',
			'assistant.suggest.day.1' => 'Monday',
			'assistant.suggest.day.2' => 'Tuesday',
			'assistant.suggest.day.3' => 'Wednesday',
			'assistant.suggest.day.4' => 'Thursday',
			'assistant.suggest.day.5' => 'Friday',
			'assistant.suggest.day.6' => 'Saturday',
			'assistant.suggest.day.7' => 'tomorrow',
			'assistant.suggest.meal.0' => 'breakfast',
			'assistant.suggest.meal.1' => 'lunch',
			'assistant.suggest.meal.2' => 'dinner',
			'assistant.suggest.n.0' => '5',
			'assistant.suggest.n.1' => '8',
			'assistant.suggest.n.2' => '10',
			'assistant.suggest.n.3' => '12',
			'assistant.suggest.n.4' => '15',
			'assistant.suggest.n.5' => '20',
			'assistant.suggest.n.6' => '25',
			'assistant.suggest.n.7' => '30',
			'assistant.suggest.site.0' => 'TikTok',
			'assistant.suggest.site.1' => 'Instagram',
			'assistant.suggest.site.2' => 'YouTube',
			'assistant.suggest.site.3' => 'a blog',
			'assistant.suggest.book.0' => 'Weeknights',
			'assistant.suggest.book.1' => 'Shabbat',
			'assistant.suggest.book.2' => 'Kids',
			'assistant.suggest.book.3' => 'Desserts',
			'assistant.suggest.diet.0' => 'vegetarian',
			'assistant.suggest.diet.1' => 'vegan',
			'assistant.suggest.diet.2' => 'gluten-free',
			'assistant.suggest.diet.3' => 'dairy',
			'assistant.whichList' => 'Which list?',
			'assistant.listCreated' => 'List created',
			'assistant.offTopic' => 'I\'m here for cooking, recipes, meal plans and groceries. Ask me anything in the kitchen and I\'m on it!',
			'assistant.welcomeAnon' => 'Hi! I can add groceries, plan your week, import recipes from links, start cook mode and more. What shall we do?',
			'assistant.scopedWelcome' => ({required Object name}) => 'What would you like to know about "${name}"?',
			'assistant.scopedOffTopic' => ({required Object name}) => 'Here I only help with "${name}". For anything else, open Shefi from the menu.',
			'assistant.askAboutRecipe' => 'Ask Shefi about this recipe',
			'assistant.askAboutPlan' => 'Ask Shefi about this plan',
			'assistant.askAboutList' => 'Ask Shefi about this list',
			'assistant.listen' => 'Talk to Shefi',
			'assistant.stopListening' => 'Stop listening',
			'assistant.speakReplies' => 'Read replies aloud',
			'assistant.micUnavailable' => 'The microphone cannot be used. Check the microphone and speech recognition permissions in the device settings.',
			'assistant.scopedPrompts.recipe.0' => 'What is the nutrition per serving?',
			'assistant.scopedPrompts.recipe.1' => 'How do I make it for 8 people?',
			'assistant.scopedPrompts.recipe.2' => 'What can I substitute for an ingredient I lack?',
			'assistant.scopedPrompts.recipe.3' => 'Add this recipe to tomorrow’s plan',
			'assistant.scopedPrompts.recipe.4' => 'Create a grocery list from this recipe',
			'assistant.scopedPrompts.mealPlan.0' => 'What are we eating today?',
			'assistant.scopedPrompts.mealPlan.1' => 'Add a dinner on Tuesday',
			'assistant.scopedPrompts.mealPlan.2' => 'What is missing this week?',
			'assistant.scopedPrompts.mealPlan.3' => 'Create a grocery list from this plan',
			'assistant.scopedPrompts.mealPlan.4' => 'How many calories on Wednesday?',
			'assistant.scopedPrompts.groceryList.0' => 'What is left to buy?',
			'assistant.scopedPrompts.groceryList.1' => 'Add milk and eggs',
			'assistant.scopedPrompts.groceryList.2' => 'Mark the tomatoes as bought',
			'assistant.scopedPrompts.groceryList.3' => 'Remove what I already bought',
			'assistant.scopedPrompts.groceryList.4' => 'How much is 2 cups of flour in grams?',
			'assistant.listening' => 'Listening…',
			'assistant.stop' => 'Stop',
			'assistant.cancelled' => 'Cancelled.',
			'shareCode.title' => 'Code & link',
			'shareCode.tabContact' => 'Contact',
			'shareCode.tabCode' => 'Code or link',
			'shareCode.explain' => ({required Object role}) => 'Anyone with this code can join as ${role}. It works for 30 days.',
			'shareCode.create' => 'Create code',
			'shareCode.code' => 'Code',
			'shareCode.link' => 'Link',
			'shareCode.copy' => 'Copy',
			'shareCode.copied' => 'Copied',
			'shareCode.share' => 'Share',
			'shareCode.showQr' => 'Show QR',
			'shareCode.scanQr' => 'Scan QR',
			'shareCode.enterCode' => 'Enter a code',
			'shareCode.join' => 'Join',
			'shareCode.joinTitle' => 'Join with a code',
			'shareCode.joinHint' => 'Paste the code you received, or scan its QR.',
			'shareCode.joinPlaceholder' => 'XXXXXXXX',
			'shareCode.joined' => ({required Object title}) => 'Joined: ${title}',
			'shareCode.alreadyMember' => 'You already have this.',
			'shareCode.invalid' => 'That code is not valid.',
			'shareCode.expired' => 'This code has expired.',
			'shareCode.revoked' => 'This code was cancelled.',
			'shareCode.usedUp' => 'This code has been used up.',
			'shareCode.self' => 'That is your own code.',
			'shareCode.gone' => 'What this code shared no longer exists.',
			'shareCode.failed' => 'Could not join. Try again.',
			'shareCode.messageText' => ({required Object name, required Object title, required Object code, required Object link}) => '${name} shared "${title}" with you on EasyPlate. Code: ${code}\n${link}',
			'shareCode.revoke' => 'Cancel code',
			'shareCode.limitRecipes' => ({required Object count}) => 'Free accounts can share up to ${count} recipes a week.',
			'shareCode.limitBooks' => ({required Object count}) => 'Free accounts can share up to ${count} books.',
			'shareCode.limitPlans' => ({required Object count}) => 'Free accounts can share up to ${count} meal plans.',
			'shareCode.upgrade' => 'See Premium',
			'shareCode.scanHint' => 'Point the camera at a share QR',
			'shareCode.householdMessage' => ({required Object name, required Object code, required Object link}) => '${name} invited you to their shared EasyPlate account. Code: ${code}\n${link}',
			'shareCode.limitLists' => ({required Object count}) => 'Free accounts can share up to ${count} grocery lists.',
			'household.title' => 'Shared account',
			'household.duo' => 'Pro Duo',
			'household.family' => 'Pro Family',
			'household.seats' => ({required Object used, required Object total}) => '${used} of ${total} seats in use',
			'household.intro' => 'Open a shared account: recipes, books, plans and lists are mirrored for everyone in it, and they get Premium with you.',
			'household.create' => 'Open shared account',
			'household.nameHint' => 'Name, e.g. the Cohens',
			'household.notEligible' => 'A shared account comes with Pro Duo (2 accounts) or Pro Family (up to 6 accounts).',
			'household.seePlans' => 'See plans',
			'household.members' => 'Members',
			'household.owner' => 'Owner',
			'household.you' => 'You',
			'household.invite' => 'Invite a member',
			'household.inviteExplain' => ({required Object free}) => 'Anyone with this code joins the shared account. ${free} seats left.',
			'household.noSeats' => 'All seats are taken.',
			'household.remove' => 'Remove',
			'household.removeConfirm' => ({required Object name}) => 'Remove ${name} from the shared account? They lose access and Premium.',
			'household.leave' => 'Leave shared account',
			'household.leaveConfirm' => 'Leave? What was saved here stays with the shared account; your own account goes back to what you had before.',
			'household.dissolve' => 'Close shared account',
			'household.dissolveConfirm' => 'Close the shared account? Members lose access and Premium. Your data comes back to your own account.',
			'household.joined' => 'Welcome to the shared account!',
			'household.inheritedNote' => ({required Object name}) => 'Premium comes from ${name}\'s subscription.',
			'household.failed' => 'That did not work. Try again.',
			'household.full' => 'The shared account is full.',
			'household.inHousehold' => 'You are already in a shared account.',
			'household.notEligibleCode' => 'The owner\'s plan no longer includes a shared account.',
			'household.lapsed' => 'The owner\'s subscription has ended; Premium is paused for members.',
			'feature.comingSoon' => 'Coming soon',
			'feature.comingSoonMessage' => 'This feature is coming soon',
			'feature.unavailable' => 'This feature is not available right now',
			'feature.premiumOnly' => 'Premium',
			'feature.premiumOnlyMessage' => 'This feature is for Premium subscribers',
			'feature.premiumOnlyTitle' => 'Premium only',
			'feature.premiumOnlyFor' => ({required Object name}) => '"${name}" is open to Premium subscribers only',
			'feature.goPremium' => 'Go Premium',
			'featureName.books' => 'Recipe books',
			'featureName.mealPlans' => 'Meal plans',
			'featureName.groceryLists' => 'Grocery lists',
			'featureName.community' => 'Community',
			'featureName.ingestText' => 'Recipe from text',
			'featureName.ingestWebSearch' => 'Recipe web search',
			'featureName.ingestLink' => 'Recipe from a link',
			'featureName.ingestSocialVideo' => 'Recipe from a video',
			'featureName.ingestAiRequest' => 'Ask AI for a recipe',
			'featureName.ingestFile' => 'Recipe from a file',
			'featureName.shareIn' => 'Share from another app',
			'featureName.saveWithAi' => 'Save with AI',
			'featureName.cookMode' => 'Cook mode',
			'featureName.cookTimers' => 'Cooking timers',
			'featureName.nutrition' => 'Nutrition',
			'featureName.recipeImageAi' => 'AI picture',
			'featureName.recipeImageSearch' => 'Google image search',
			'featureName.groceryFromRecipe' => 'Grocery list from a recipe',
			'featureName.sharedRecipes' => 'Shared recipes',
			'featureName.forum' => 'Forum',
			'featureName.likes' => 'Likes',
			'featureName.shareRecipes' => 'Recipe sharing',
			'featureName.shareBooks' => 'Book sharing',
			'featureName.sharePlans' => 'Meal plan sharing',
			'featureName.shareGroceryLists' => 'Grocery list sharing',
			'featureName.shareCodes' => 'Share codes',
			'featureName.households' => 'Household',
			'featureName.priceBook' => 'Price book',
			'featureName.receiptScan' => 'Receipt scan',
			'featureName.groceryCost' => 'Estimated cost',
			'featureName.shoppingReminder' => 'Shopping reminder',
			'featureName.assistant' => 'Shefi (the assistant)',
			'featureName.notifications' => 'Notifications',
			'featureName.premium' => 'Premium',
			'featureName.contentTranslation' => 'Content translation',
			'featureName.theming' => 'Appearance',
			'featureName.walkthrough' => 'Guided tour',
			'featureName.tutorialBook' => 'Tutorial book',
			'featureName.feedback' => 'Feedback',
			'featureName.assistantScoped' => 'Shefi inside an item',
			'featureName.assistantVoice' => 'Voice with Shefi',
			'featureName.singleSession' => 'One device per account',
			'adminConfig.intro' => 'Every value here is Firebase Remote Config. A change is published to all users at once (default values; console conditions are left as they are).',
			'adminConfig.loadFailed' => 'Could not load the configuration',
			'adminConfig.saveFailed' => 'Publishing failed. Check the value and try again',
			'adminConfig.saved' => ({required Object name}) => '"${name}" published',
			'adminConfig.count' => ({required Object n}) => '${n} settings',
			'adminConfig.searchAll' => 'Search all settings',
			'adminConfig.searchIn' => ({required Object section}) => 'Search in ${section}',
			'adminConfig.noResults' => ({required Object query}) => 'No setting matches "${query}"',
			'adminConfig.filterAll' => 'All',
			'adminConfig.clearSearch' => 'Clear search',
			'adminConfig.noFlagsInState' => 'No features in this state',
			'adminConfig.groups.features' => 'Features',
			'adminConfig.groups.adsQuotas' => 'Ads and quotas',
			'adminConfig.groups.sharing' => 'Sharing on a free account',
			'adminConfig.groups.voice' => 'Shefi\'s voice',
			'adminConfig.groups.versions' => 'Versions and environment',
			'adminConfig.groups.gemini' => 'AI server (needs a deploy)',
			'adminConfig.groups.other' => 'Other',
			'adminConfig.flag.hidden' => 'Hidden',
			'adminConfig.flag.comingSoon' => 'Coming soon',
			'adminConfig.flag.everyone' => 'Free',
			'adminConfig.flag.premium' => 'Premium',
			'adminConfig.labels.ads_enabled' => 'Ads enabled',
			'adminConfig.labels.ads_fail_open' => 'Open when no video',
			'adminConfig.labels.ads_feed_interval' => 'Ad interval in feeds',
			'adminConfig.labels.quota_shared_free' => 'Free shared recipes per day',
			'adminConfig.labels.quota_shared_rewarded' => 'Shared recipes after a video',
			'adminConfig.labels.quota_ai_rewarded' => 'AI imports after a video per day',
			'adminConfig.labels.share_free_recipes_weekly' => 'Recipe shares per week',
			'adminConfig.labels.share_free_books_total' => 'Shared books at once',
			'adminConfig.labels.share_free_plans_total' => 'Shared plans at once',
			'adminConfig.labels.share_free_lists_total' => 'Shared grocery lists at once',
			'adminConfig.labels.tts_cloud_enabled' => 'Cloud voice (Google)',
			'adminConfig.labels.tts_voice_he' => 'Hebrew voice',
			'adminConfig.labels.tts_voice_en' => 'English voice',
			'adminConfig.labels.tts_voice_ar' => 'Arabic voice',
			'adminConfig.labels.tts_voice_fr' => 'French voice',
			'adminConfig.labels.tts_voice_ru' => 'Russian voice',
			'adminConfig.labels.isProd' => 'Production version',
			'adminConfig.labels.minimumVersion' => 'Minimum version',
			'adminConfig.labels.latestVersion' => 'Latest version',
			'adminConfig.labels.iosAppStoreId' => 'App Store ID',
			'adminConfig.labels.gemini_minInstances' => 'Minimum instances',
			'adminConfig.labels.gemini_maxInstances' => 'Maximum instances',
			'adminConfig.labels.gemini_timeoutSeconds' => 'Call timeout (seconds)',
			'adminConfig.labels.session_days' => 'Session length (days)',
			'adminConfig.labels.presence_heartbeat_seconds' => 'Presence heartbeat (seconds)',
			_ => null,
		};
	}
}
