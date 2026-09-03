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
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$dietary$en dietary = _Translations$dietary$en._(_root);
	@override late final _Translations$weekday$en weekday = _Translations$weekday$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$language$en language = _Translations$language$en._(_root);
	@override late final _Translations$books$en books = _Translations$books$en._(_root);
	@override late final _Translations$recipe$en recipe = _Translations$recipe$en._(_root);
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
	@override String get missingInfo => '[missing info]';
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
	@override String get instructions => 'Instructions';
	@override String get addToBook => 'Add to book';
	@override String get removeFromBook => 'Remove from book';
	@override String get deleteRecipe => 'Delete recipe';
	@override String get photo => 'Recipe photo';
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
			'common.missingInfo' => '[missing info]',
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
			'recipe.instructions' => 'Instructions',
			'recipe.addToBook' => 'Add to book',
			'recipe.removeFromBook' => 'Remove from book',
			'recipe.deleteRecipe' => 'Delete recipe',
			'recipe.photo' => 'Recipe photo',
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
			_ => null,
		};
	}
}
