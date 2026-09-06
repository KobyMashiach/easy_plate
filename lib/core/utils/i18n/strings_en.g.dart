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
	@override String get appName => 'EasyPlate';
	@override late final _Translations$common$en common = _Translations$common$en._(_root);
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
	@override late final _Translations$profile$en profile = _Translations$profile$en._(_root);
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$dietary$en dietary = _Translations$dietary$en._(_root);
	@override late final _Translations$weekday$en weekday = _Translations$weekday$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$more$en more = _Translations$more$en._(_root);
	@override late final _Translations$language$en language = _Translations$language$en._(_root);
	@override late final _Translations$books$en books = _Translations$books$en._(_root);
	@override late final _Translations$recipe$en recipe = _Translations$recipe$en._(_root);
	@override late final _Translations$community$en community = _Translations$community$en._(_root);
	@override late final _Translations$sharing$en sharing = _Translations$sharing$en._(_root);
	@override late final _Translations$notifications$en notifications = _Translations$notifications$en._(_root);
	@override late final _Translations$editor$en editor = _Translations$editor$en._(_root);
	@override late final _Translations$ingestion$en ingestion = _Translations$ingestion$en._(_root);
	@override late final _Translations$mealPlanner$en mealPlanner = _Translations$mealPlanner$en._(_root);
	@override late final _Translations$groceryList$en groceryList = _Translations$groceryList$en._(_root);
	@override late final _Translations$unit$en unit = _Translations$unit$en._(_root);
	@override late final _Translations$image$en image = _Translations$image$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
}

// Path: common
class _Translations$common$en extends Translations$common$he {
	_Translations$common$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
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
	@override String get soundEffects => 'Sound effects (page turns)';
	@override String get fastPageTurn => 'Fast page-through';
	@override String get fastPageTurnHint => 'Jumping from the table of contents or quick navigation riffles through the pages along the way. Turn it off to land on the page instantly.';
	@override String get sharedAccess => 'Manage sharing';
	@override String get noSharedAccess => 'You haven\'t shared any books or lists yet';
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
	@override String get self => 'You cannot share a recipe with yourself';
	@override String get failed => 'Sharing failed, try again';
	@override String get pendingInvites => 'Pending invites';
	@override String get noPendingInvites => 'No pending invites';
	@override String get sharedByMe => 'Recipes I shared';
	@override String get sharedWithMe => 'Recipes shared with me';
	@override String get nothingSharedByMe => 'You have not shared any recipes yet';
	@override String get nothingSharedWithMe => 'No recipes have been shared with you yet';
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
	@override String get socialVideo => 'TikTok / Reels';
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

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'EasyPlate',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
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
			'settings.soundEffects' => 'Sound effects (page turns)',
			'settings.fastPageTurn' => 'Fast page-through',
			'settings.fastPageTurnHint' => 'Jumping from the table of contents or quick navigation riffles through the pages along the way. Turn it off to land on the page instantly.',
			'settings.sharedAccess' => 'Manage sharing',
			'settings.noSharedAccess' => 'You haven\'t shared any books or lists yet',
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
			'sharing.self' => 'You cannot share a recipe with yourself',
			'sharing.failed' => 'Sharing failed, try again',
			'sharing.pendingInvites' => 'Pending invites',
			'sharing.noPendingInvites' => 'No pending invites',
			'sharing.sharedByMe' => 'Recipes I shared',
			'sharing.sharedWithMe' => 'Recipes shared with me',
			'sharing.nothingSharedByMe' => 'You have not shared any recipes yet',
			'sharing.nothingSharedWithMe' => 'No recipes have been shared with you yet',
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
			'notifications.title' => 'Notifications',
			'notifications.empty' => 'No notifications',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => '${name} shared "${recipe}" with you',
			'notifications.asViewer' => 'view only',
			'notifications.asEditor' => 'to edit',
			'notifications.markAllRead' => 'Mark all as read',
			'notifications.openRecipe' => 'Open recipe',
			'notifications.alreadyHandled' => 'This invite was already handled',
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
			'ingestion.socialVideo' => 'TikTok / Reels',
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
			'nav.library' => 'Library',
			'nav.recipes' => 'Recipes',
			'nav.mealPlan' => 'Meals',
			'nav.groceries' => 'Groceries',
			'nav.settings' => 'Settings',
			'nav.community' => 'Community',
			_ => null,
		};
	}
}
