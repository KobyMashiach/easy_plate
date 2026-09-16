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
	@override late final _Translations$more$en more = _Translations$more$en._(_root);
	@override late final _Translations$language$en language = _Translations$language$en._(_root);
	@override late final _Translations$books$en books = _Translations$books$en._(_root);
	@override late final _Translations$recipe$en recipe = _Translations$recipe$en._(_root);
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
	@override String get fastPageTurnHint => 'Jumping from the table of contents or quick navigation riffles through the pages along the way. Turn it off to land on the page instantly.';
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
	@override String get socialVideo => 'Video: TikTok / Instagram / YouTube / Facebook';
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
	@override String get bookSubtitle => 'Everything the app can do, chapter by chapter. A guide only: nothing is saved.';
	@override String get contents => 'Contents';
	@override String chapter({required Object number}) => 'Chapter ${number}';
	@override String get backToContents => 'Back to contents';
	@override String get stepsTitle => 'Steps';
	@override String get welcomeTitle => 'Welcome to EasyPlate';
	@override String get welcomeBody => 'Let\'s walk through the main actions together. Skip any step, or close and start again from the support screen.';
	@override late final _Translations$walkthrough$topics$en topics = _Translations$walkthrough$topics$en._(_root);
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
}

// Path: walkthrough.topics.addRecipe
class _Translations$walkthrough$topics$addRecipe$en extends Translations$walkthrough$topics$addRecipe$he {
	_Translations$walkthrough$topics$addRecipe$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Add a recipe';
	@override String get summary => 'Bring a recipe in from any source and the AI arranges it into one format: ingredients, amounts, steps and tags.';
	@override String get s1 => 'Tap the sparkle button next to the title to add a recipe.';
	@override String get s2 => 'Pick a source: pasted text, a web search, a website link, a TikTok/Reels video, a free request to the AI, or writing by hand. After the analysis you review, edit and save.';
}

// Path: walkthrough.topics.myRecipes
class _Translations$walkthrough$topics$myRecipes$en extends Translations$walkthrough$topics$myRecipes$he {
	_Translations$walkthrough$topics$myRecipes$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'My recipes and saved';
	@override String get summary => 'The recipes you wrote and the ones you saved from the community, with search and topic filters.';
	@override String get s1 => 'Switch here between recipes you wrote and recipes you saved from the community.';
	@override String get s2 => 'Search by name, and filter by topic: meat, dairy, vegetarian, vegan, kosher, gluten-free and allergy.';
}

// Path: walkthrough.topics.library
class _Translations$walkthrough$topics$library$en extends Translations$walkthrough$topics$library$he {
	_Translations$walkthrough$topics$library$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Recipe books';
	@override String get summary => 'Arrange recipes into books with a table of contents, a cover and page turning.';
	@override String get s1 => 'Tap "Library" to go to your books.';
	@override String get s2 => 'Create a new book here. Inside it you add recipes, turn pages and change the cover.';
}

// Path: walkthrough.topics.mealPlan
class _Translations$walkthrough$topics$mealPlan$en extends Translations$walkthrough$topics$mealPlan$he {
	_Translations$walkthrough$topics$mealPlan$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Weekly meal plan';
	@override String get summary => 'A plan for the whole week that feeds the grocery list.';
	@override String get s1 => 'Tap "Meals" to plan the week.';
	@override String get s2 => 'Create a weekly plan and place recipes on each day and meal.';
}

// Path: walkthrough.topics.groceries
class _Translations$walkthrough$topics$groceries$en extends Translations$walkthrough$topics$groceries$he {
	_Translations$walkthrough$topics$groceries$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Grocery list';
	@override String get summary => 'A list built from the plan, with what has already been picked up ticked off.';
	@override String get s1 => 'Tap "Groceries".';
	@override String get s2 => 'Refresh rebuilds the list from every recipe in the weekly plan.';
	@override String get s3 => 'And here you add a free item by hand.';
}

// Path: walkthrough.topics.community
class _Translations$walkthrough$topics$community$en extends Translations$walkthrough$topics$community$he {
	_Translations$walkthrough$topics$community$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Community';
	@override String get summary => 'Recipes shared by everyone, and a forum for questions and answers.';
	@override String get s1 => 'Tap "Community".';
	@override String get s2 => 'Shared recipes and the forum. Like, save a recipe to your own, and attach a recipe to a forum reply.';
	@override String get s3 => 'The share button publishes one of your own recipes to the community.';
}

// Path: walkthrough.topics.account
class _Translations$walkthrough$topics$account$en extends Translations$walkthrough$topics$account$he {
	_Translations$walkthrough$topics$account$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Account and notifications';
	@override String get summary => 'Notifications about share invites, and the account with premium, settings and support.';
	@override String get s1 => 'Notifications: invitations to share recipes, and updates.';
	@override String get s2 => 'The account: premium, sharing between accounts, settings, profile and support. That is also where this guide can be started again.';
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
			'settings.fastPageTurnHint' => 'Jumping from the table of contents or quick navigation riffles through the pages along the way. Turn it off to land on the page instantly.',
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
			'more.title' => 'More',
			'more.settings' => 'Settings',
			'more.profile' => 'My profile',
			'more.support' => 'Support',
			'more.supportTitle' => 'How can we help?',
			'more.supportBody' => 'Write to us and we will get back to you.',
			'more.whatsapp' => 'Message us on WhatsApp',
			'more.email' => 'Send an email',
			'more.supportUnavailable' => 'We could not open that app',
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
			'editor.savePlainHint' => 'Save the changes as they are, no waiting',
			'editor.saveWithAi' => 'Save with AI review',
			'editor.saveWithAiHint' => 'Fix spelling and align the times written in the steps',
			'ingestion.title' => 'Add a recipe',
			'ingestion.pasteText' => 'Paste text',
			'ingestion.pasteHint' => 'Paste a recipe here from WhatsApp or any other source',
			'ingestion.webSearch' => 'Search the web',
			'ingestion.urlScrape' => 'Website link',
			'ingestion.socialVideo' => 'Video: TikTok / Instagram / YouTube / Facebook',
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
			'receipt.title' => 'Scan a receipt',
			'receipt.subtitle' => 'Photograph a receipt or upload a PDF, and the prices are kept for your grocery list',
			'receipt.camera' => 'Photograph receipt',
			'receipt.cameraHint' => 'Long receipt? Take several photos, we merge them',
			'receipt.gallery' => 'Pick from gallery',
			'receipt.pdf' => 'PDF file',
			'receipt.addPhoto' => 'Another photo',
			'receipt.scan' => 'Scan',
			_ => null,
		} ?? switch (path) {
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
			'walkthrough.bookSubtitle' => 'Everything the app can do, chapter by chapter. A guide only: nothing is saved.',
			'walkthrough.contents' => 'Contents',
			'walkthrough.chapter' => ({required Object number}) => 'Chapter ${number}',
			'walkthrough.backToContents' => 'Back to contents',
			'walkthrough.stepsTitle' => 'Steps',
			'walkthrough.welcomeTitle' => 'Welcome to EasyPlate',
			'walkthrough.welcomeBody' => 'Let\'s walk through the main actions together. Skip any step, or close and start again from the support screen.',
			'walkthrough.topics.addRecipe.title' => 'Add a recipe',
			'walkthrough.topics.addRecipe.summary' => 'Bring a recipe in from any source and the AI arranges it into one format: ingredients, amounts, steps and tags.',
			'walkthrough.topics.addRecipe.s1' => 'Tap the sparkle button next to the title to add a recipe.',
			'walkthrough.topics.addRecipe.s2' => 'Pick a source: pasted text, a web search, a website link, a TikTok/Reels video, a free request to the AI, or writing by hand. After the analysis you review, edit and save.',
			'walkthrough.topics.myRecipes.title' => 'My recipes and saved',
			'walkthrough.topics.myRecipes.summary' => 'The recipes you wrote and the ones you saved from the community, with search and topic filters.',
			'walkthrough.topics.myRecipes.s1' => 'Switch here between recipes you wrote and recipes you saved from the community.',
			'walkthrough.topics.myRecipes.s2' => 'Search by name, and filter by topic: meat, dairy, vegetarian, vegan, kosher, gluten-free and allergy.',
			'walkthrough.topics.library.title' => 'Recipe books',
			'walkthrough.topics.library.summary' => 'Arrange recipes into books with a table of contents, a cover and page turning.',
			'walkthrough.topics.library.s1' => 'Tap "Library" to go to your books.',
			'walkthrough.topics.library.s2' => 'Create a new book here. Inside it you add recipes, turn pages and change the cover.',
			'walkthrough.topics.mealPlan.title' => 'Weekly meal plan',
			'walkthrough.topics.mealPlan.summary' => 'A plan for the whole week that feeds the grocery list.',
			'walkthrough.topics.mealPlan.s1' => 'Tap "Meals" to plan the week.',
			'walkthrough.topics.mealPlan.s2' => 'Create a weekly plan and place recipes on each day and meal.',
			'walkthrough.topics.groceries.title' => 'Grocery list',
			'walkthrough.topics.groceries.summary' => 'A list built from the plan, with what has already been picked up ticked off.',
			'walkthrough.topics.groceries.s1' => 'Tap "Groceries".',
			'walkthrough.topics.groceries.s2' => 'Refresh rebuilds the list from every recipe in the weekly plan.',
			'walkthrough.topics.groceries.s3' => 'And here you add a free item by hand.',
			'walkthrough.topics.community.title' => 'Community',
			'walkthrough.topics.community.summary' => 'Recipes shared by everyone, and a forum for questions and answers.',
			'walkthrough.topics.community.s1' => 'Tap "Community".',
			'walkthrough.topics.community.s2' => 'Shared recipes and the forum. Like, save a recipe to your own, and attach a recipe to a forum reply.',
			'walkthrough.topics.community.s3' => 'The share button publishes one of your own recipes to the community.',
			'walkthrough.topics.account.title' => 'Account and notifications',
			'walkthrough.topics.account.summary' => 'Notifications about share invites, and the account with premium, settings and support.',
			'walkthrough.topics.account.s1' => 'Notifications: invitations to share recipes, and updates.',
			'walkthrough.topics.account.s2' => 'The account: premium, sharing between accounts, settings, profile and support. That is also where this guide can be started again.',
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
			_ => null,
		};
	}
}
