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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Easy Plate';
	@override late final _Translations$common$ru common = _Translations$common$ru._(_root);
	@override late final _Translations$auth$ru auth = _Translations$auth$ru._(_root);
	@override late final _Translations$profile$ru profile = _Translations$profile$ru._(_root);
	@override late final _Translations$onboarding$ru onboarding = _Translations$onboarding$ru._(_root);
	@override late final _Translations$dietary$ru dietary = _Translations$dietary$ru._(_root);
	@override late final _Translations$allergens$ru allergens = _Translations$allergens$ru._(_root);
	@override late final _Translations$weekday$ru weekday = _Translations$weekday$ru._(_root);
	@override late final _Translations$settings$ru settings = _Translations$settings$ru._(_root);
	@override late final _Translations$more$ru more = _Translations$more$ru._(_root);
	@override late final _Translations$language$ru language = _Translations$language$ru._(_root);
	@override late final _Translations$books$ru books = _Translations$books$ru._(_root);
	@override late final _Translations$recipe$ru recipe = _Translations$recipe$ru._(_root);
	@override late final _Translations$nutrition$ru nutrition = _Translations$nutrition$ru._(_root);
	@override late final _Translations$community$ru community = _Translations$community$ru._(_root);
	@override late final _Translations$sharing$ru sharing = _Translations$sharing$ru._(_root);
	@override late final _Translations$notifications$ru notifications = _Translations$notifications$ru._(_root);
	@override late final _Translations$editor$ru editor = _Translations$editor$ru._(_root);
	@override late final _Translations$ingestion$ru ingestion = _Translations$ingestion$ru._(_root);
	@override late final _Translations$mealPlanner$ru mealPlanner = _Translations$mealPlanner$ru._(_root);
	@override late final _Translations$groceryList$ru groceryList = _Translations$groceryList$ru._(_root);
	@override late final _Translations$unit$ru unit = _Translations$unit$ru._(_root);
	@override late final _Translations$image$ru image = _Translations$image$ru._(_root);
	@override late final _Translations$nav$ru nav = _Translations$nav$ru._(_root);
	@override late final _Translations$update$ru update = _Translations$update$ru._(_root);
	@override late final _Translations$ads$ru ads = _Translations$ads$ru._(_root);
	@override late final _Translations$premium$ru premium = _Translations$premium$ru._(_root);
	@override late final _Translations$walkthrough$ru walkthrough = _Translations$walkthrough$ru._(_root);
	@override late final _Translations$feedback$ru feedback = _Translations$feedback$ru._(_root);
}

// Path: common
class _Translations$common$ru extends Translations$common$he {
	_Translations$common$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get save => 'Сохранить';
	@override String get cancel => 'Отмена';
	@override String get ok => 'ОК';
	@override String get next => 'Далее';
	@override String get back => 'Назад';
	@override String get done => 'Готово';
	@override String get add => 'Добавить';
	@override String get edit => 'Изменить';
	@override String get delete => 'Удалить';
	@override String get search => 'Поиск';
	@override String get retry => 'Повторить';
	@override String get loading => 'Загрузка...';
	@override String get error => 'Произошла ошибка';
	@override String get or => 'или';
	@override String get missingInfo => '[нет данных]';
	@override String get networkError => 'Нет подключения к интернету';
}

// Path: auth
class _Translations$auth$ru extends Translations$auth$he {
	_Translations$auth$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'Добро пожаловать в EasyPlate';
	@override String get subtitle => 'Войдите, чтобы сохранять рецепты';
	@override String get signIn => 'Вход';
	@override String get signUp => 'Регистрация';
	@override String get signOut => 'Выйти';
	@override String get email => 'Эл. почта';
	@override String get emailHint => 'name@example.com';
	@override String get password => 'Пароль';
	@override String get passwordHint => 'Минимум 6 символов';
	@override String get continueWithGoogle => 'Продолжить с Google';
	@override String get continueWithPhone => 'Продолжить по телефону';
	@override String get continueWithEmail => 'Продолжить по почте';
	@override String get phoneNumber => 'Номер телефона';
	@override String get phoneHint => '+79161234567';
	@override String get sendCode => 'Отправить код';
	@override String get smsCode => 'Код из SMS';
	@override String codeSentTo({required Object phone}) => 'Мы отправили код на ${phone}';
	@override String get verify => 'Подтвердить';
	@override String get resendCode => 'Отправить снова';
	@override String get forgotPassword => 'Забыли пароль';
	@override String get resetSent => 'Письмо для сброса отправлено';
	@override String get noAccount => 'Нет аккаунта? Зарегистрируйтесь';
	@override String get haveAccount => 'Есть аккаунт? Войдите';
	@override String get invalidEmail => 'Неверный адрес эл. почты';
	@override String get passwordTooShort => 'Пароль должен содержать минимум 6 символов';
	@override String get invalidPhone => 'Неверный номер телефона';
	@override String get codeRequired => 'Введите полученный код';
	@override String get errorUnauthorized => 'Введённые данные неверны';
	@override String get errorNetwork => 'Нет подключения к интернету';
	@override String get errorUnknown => 'Не удалось войти, попробуйте снова';
	@override String get signOutTitle => 'Выйти?';
	@override String get signOutBody => 'Чтобы вернуться к рецептам, нужно будет войти снова.';
	@override String get errorOperationNotAllowed => 'Этот способ входа сейчас недоступен';
	@override String get errorTooManyRequests => 'Слишком много попыток. Повторите через несколько минут';
	@override String get errorInvalidPhone => 'Неверный номер телефона';
	@override String get errorEmailInUse => 'Эта почта уже зарегистрирована';
	@override String get verifyEmailTitle => 'Подтвердите почту';
	@override String verifyEmailBody({required Object email}) => 'Мы отправили ссылку на ${email}. Откройте её и вернитесь сюда.';
	@override String get resendEmail => 'Отправить ссылку снова';
	@override String get emailResent => 'Ссылка отправлена снова';
	@override String get checkVerification => 'Я подтвердил';
	@override String get stillNotVerified => 'Почта ещё не подтверждена';
	@override String get linkPhone => 'Подтвердить телефон';
	@override String get phoneLinked => 'Телефон подтверждён';
	@override String get phoneAlreadyUsed => 'Этот номер уже привязан к другому аккаунту';
	@override String get emailAlreadyLinked => 'К аккаунту уже привязана почта';
	@override String get addEmailPassword => 'Добавить почту и пароль';
	@override String get verified => 'Подтверждено';
	@override String get linkGoogle => 'Привязать аккаунт Google';
	@override String get googleLinked => 'Привязан';
	@override String get googleAlreadyUsed => 'Этот аккаунт Google уже привязан к другому пользователю';
	@override String get googleAlreadyLinked => 'Аккаунт Google уже привязан';
	@override String get phoneGateTitle => 'Подтвердите телефон';
	@override String get phoneGateBody => 'Каждый аккаунт подтверждается по телефону. Мы отправим вам код в SMS.';
	@override String get changeNumber => 'Изменить номер';
	@override String get signInTitle => 'Вход';
	@override String get phoneFirstHint => 'Впервые здесь? Продолжите с телефоном.';
	@override String get errorAccountExistsDifferentCredential => 'Этот адрес уже принадлежит другому аккаунту. Войдите тем способом, которым регистрировались.';
	@override String get errorCredentialInUse => 'Эти данные уже принадлежат другому аккаунту';
	@override String get continueWithApple => 'Продолжить с Apple';
	@override String get linkApple => 'Привязать аккаунт Apple';
	@override String get appleLinked => 'Привязан';
	@override String get appleAlreadyUsed => 'Этот аккаунт Apple уже принадлежит другому пользователю';
	@override String get appleAlreadyLinked => 'Аккаунт Apple уже привязан';
}

// Path: profile
class _Translations$profile$ru extends Translations$profile$he {
	_Translations$profile$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get setupTitle => 'Последние детали';
	@override String get setupSubtitle => 'Чтобы знать, как к вам обращаться';
	@override String get fullName => 'Полное имя';
	@override String get fullNameHint => 'Иван Иванов';
	@override String get fullNameRequired => 'Укажите полное имя';
	@override String get photo => 'Фото профиля';
	@override String get addPhoto => 'Добавить фото';
	@override String get phoneOptional => 'Телефон (необязательно)';
	@override String get emailOptional => 'Почта (необязательно)';
	@override String get save => 'Завершить регистрацию';
	@override String get saving => 'Сохранение...';
	@override String get saveFailed => 'Не удалось сохранить профиль';
	@override String get myProfile => 'Мой профиль';
}

// Path: onboarding
class _Translations$onboarding$ru extends Translations$onboarding$he {
	_Translations$onboarding$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get welcomeTitle => 'Добро пожаловать в EasyPlate';
	@override String get welcomeSubtitle => 'Планируйте меню, готовьте и делайте покупки — всё в одном месте';
	@override String get shoppingDayTitle => 'Какой у вас день еженедельных покупок?';
	@override String get dietaryTitle => 'Каковы ваши пищевые предпочтения?';
	@override String get dietarySubtitle => 'Можно выбрать несколько';
	@override String get finish => 'Начнём';
}

// Path: dietary
class _Translations$dietary$ru extends Translations$dietary$he {
	_Translations$dietary$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get meat => 'Мясное';
	@override String get dairy => 'Молочное';
	@override String get vegetarian => 'Вегетарианское';
	@override String get vegan => 'Веганское';
	@override String get kosher => 'Кошерное';
	@override String get glutenFree => 'Без глютена';
	@override String get allergy => 'Аллергия';
}

// Path: allergens
class _Translations$allergens$ru extends Translations$allergens$he {
	_Translations$allergens$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Аллергены';
	@override String get pick => 'Отметить аллергены';
	@override String get contains => 'Содержит';
	@override String get mayContain => 'Может содержать';
	@override String get gluten => 'Глютен';
	@override String get milk => 'Молоко';
	@override String get eggs => 'Яйца';
	@override String get fish => 'Рыба';
	@override String get shellfish => 'Морепродукты';
	@override String get peanuts => 'Арахис';
	@override String get treeNuts => 'Орехи';
	@override String get sesame => 'Кунжут';
	@override String get soy => 'Соя';
}

// Path: weekday
class _Translations$weekday$ru extends Translations$weekday$he {
	_Translations$weekday$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get sunday => 'Воскресенье';
	@override String get monday => 'Понедельник';
	@override String get tuesday => 'Вторник';
	@override String get wednesday => 'Среда';
	@override String get thursday => 'Четверг';
	@override String get friday => 'Пятница';
	@override String get saturday => 'Суббота';
}

// Path: settings
class _Translations$settings$ru extends Translations$settings$he {
	_Translations$settings$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Настройки';
	@override String get dietaryPreferences => 'Пищевые предпочтения';
	@override String get shoppingDay => 'День покупок';
	@override String get language => 'Язык';
	@override String get appearance => 'Оформление';
	@override String get themeSystem => 'Как в системе';
	@override String get themeLight => 'Светлая';
	@override String get themeDark => 'Тёмная';
	@override String get soundEffects => 'Звуковые эффекты (перелистывание страниц)';
	@override String get fastPageTurn => 'Быстрое перелистывание';
	@override String get fastPageTurnHint => 'Переход из содержания или быстрой навигации перелистывает страницы по пути. Отключите, чтобы сразу попадать на нужную страницу.';
	@override String get sharedAccess => 'Управление доступом';
	@override String get noSharedAccess => 'Вы ещё не делились книгами или списками';
}

// Path: more
class _Translations$more$ru extends Translations$more$he {
	_Translations$more$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ещё';
	@override String get settings => 'Настройки';
	@override String get profile => 'Мой профиль';
	@override String get support => 'Поддержка';
	@override String get supportTitle => 'Чем помочь?';
	@override String get supportBody => 'Напишите нам, и мы ответим.';
	@override String get whatsapp => 'Написать в WhatsApp';
	@override String get email => 'Отправить письмо';
	@override String get supportUnavailable => 'Не удалось открыть приложение';
}

// Path: language
class _Translations$language$ru extends Translations$language$he {
	_Translations$language$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get hebrew => 'עברית';
	@override String get english => 'English';
	@override String get arabic => 'العربية';
	@override String get french => 'Français';
	@override String get russian => 'Русский';
}

// Path: books
class _Translations$books$ru extends Translations$books$he {
	_Translations$books$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get myLibrary => 'Моя библиотека';
	@override String get myRecipes => 'Мои рецепты';
	@override String get librarySubtitle => 'Все ваши книги рецептов в одном месте';
	@override String get recipesSubtitle => 'Ищите и фильтруйте все собранные рецепты';
	@override String get collection => 'Коллекция';
	@override String recipesCount({required Object count}) => 'Рецептов: ${count}';
	@override String get newBook => 'Новая книга';
	@override String get newBookTitle => 'Название книги';
	@override String get tableOfContents => 'Содержание';
	@override String get emptyLibrary => 'У вас пока нет книг. Создайте первую!';
	@override String get emptyBook => 'Эта книга пуста. Добавьте первый рецепт';
	@override String get quickNav => 'Быстрый переход';
	@override String get share => 'Поделиться книгой';
	@override String get viewer => 'Читатель';
	@override String get editor => 'Редактор';
	@override String get reorderHint => 'Перетащите, чтобы изменить порядок рецептов';
	@override String get coverImage => 'Обложка';
	@override String get bookOptions => 'Параметры книги';
	@override String get renameBook => 'Переименовать книгу';
	@override String get spineColor => 'Цвет корешка';
}

// Path: recipe
class _Translations$recipe$ru extends Translations$recipe$he {
	_Translations$recipe$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get prepTime => 'Время подготовки';
	@override String get cookTime => 'Время приготовления';
	@override String get ingredients => 'Ингредиенты';
	@override String ingredientsCount({required Object count}) => 'Ингредиентов: ${count}';
	@override String minutes({required Object count}) => '${count} мин';
	@override String hours({required Object count}) => '${count} ч';
	@override String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours} ч ${minutes} мин';
	@override String get instructions => 'Приготовление';
	@override String get addToBook => 'Добавить в книгу';
	@override String get removeFromBook => 'Убрать из книги';
	@override String get deleteRecipe => 'Удалить рецепт';
	@override String get photo => 'Фото рецепта';
	@override String get mine => 'Мои рецепты';
	@override String get saved => 'Сохранённые';
	@override String get noneMine => 'Вы ещё не создали ни одного рецепта';
	@override String get noneSaved => 'Вы ещё ничего не сохранили';
	@override String get pendingAnalysis => 'Ожидает анализа';
	@override String get pendingAnalysisHint => 'Сохранён как сырой текст. Проанализируйте сейчас или отредактируйте вручную.';
	@override String get analyzeNow => 'Проанализировать с AI';
	@override String get analyzing => 'Анализируем рецепт...';
	@override String get analyzeFailed => 'Анализ не удался — попробуйте позже';
}

// Path: nutrition
class _Translations$nutrition$ru extends Translations$nutrition$he {
	_Translations$nutrition$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Пищевая ценность';
	@override String get perServing => 'на порцию';
	@override String get perServingHint => 'Все значения указаны на одну порцию. Оставьте пустым, чтобы убрать оценку.';
	@override String get servings => 'порций';
	@override String servingsCount({required Object count}) => '${count} порций';
	@override String get calories => 'Калории';
	@override String get kcal => 'ккал';
	@override String get protein => 'Белки';
	@override String get carbs => 'Углеводы';
	@override String get fat => 'Жиры';
	@override String get gramsShort => 'г';
	@override String get estimate => 'Оценить с помощью ИИ';
	@override String get estimating => 'Оцениваем пищевую ценность…';
	@override String get estimateFailed => 'Оценка не удалась, попробуйте ещё раз';
	@override String get none => 'Для этого рецепта ещё нет пищевой ценности';
	@override String get noneHint => 'ИИ может оценить калории, белки, углеводы и жиры по списку ингредиентов';
	@override String get estimated => 'Пищевая ценность обновлена';
	@override String get editorServings => 'Количество порций';
	@override String get editorCalories => 'Калорий на порцию';
	@override String get editorProtein => 'Белки (г)';
	@override String get editorCarbs => 'Углеводы (г)';
	@override String get editorFat => 'Жиры (г)';
	@override String get dashboard => 'Панель питания';
	@override String get weekly => 'На этой неделе';
	@override String get today => 'Сегодня';
	@override String get dayTotal => 'Итого за день';
	@override String get weekTotal => 'Итого за неделю';
	@override String get dailyAverage => 'В среднем на запланированный день';
	@override String get perMeal => 'По приёмам пищи';
	@override String get perDay => 'По дням';
	@override String get noPlanned => 'Пока нет запланированных блюд с рецептами';
	@override String missingCount({required Object count}) => '${count} позиций без пищевой ценности';
	@override String get macroSplit => 'Распределение калорий';
	@override String get kcalPerDay => 'ккал в день';
	@override String get openDashboard => 'Недельная панель';
}

// Path: community
class _Translations$community$ru extends Translations$community$he {
	_Translations$community$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сообщество';
	@override String get forum => 'Форум';
	@override String get sharedRecipes => 'Общие рецепты';
	@override String get newPost => 'Новый пост';
	@override String get postTitle => 'Заголовок';
	@override String get postBody => 'О чём хотите спросить или рассказать?';
	@override String get postTitleRequired => 'Нужен заголовок';
	@override String get postBodyRequired => 'Нужен текст';
	@override String get publish => 'Опубликовать';
	@override String replies({required Object count}) => 'Ответов: ${count}';
	@override String get noReplies => 'Ответов пока нет';
	@override String get oneReply => 'Один ответ';
	@override String get writeReply => 'Написать ответ...';
	@override String get send => 'Отправить';
	@override String get noPosts => 'Постов пока нет. Будьте первым!';
	@override String get noSharedRecipes => 'Рецептов пока не публиковали. Поделитесь первым!';
	@override String get shareRecipe => 'Поделиться рецептом';
	@override String get pickRecipeToShare => 'Каким рецептом поделиться?';
	@override String get saveToMyRecipes => 'Сохранить к себе';
	@override String get savedToMyRecipes => 'Рецепт сохранён';
	@override String get deletePost => 'Удалить пост';
	@override String get deletePostConfirm => 'Пост и ответы будут удалены навсегда.';
	@override String get unshare => 'Убрать из ленты';
	@override String get unshareConfirm => 'Рецепт будет убран из общей ленты.';
	@override String byAuthor({required Object name}) => 'от ${name}';
	@override String get loadFailed => 'Не удалось загрузить содержимое';
	@override String get allRecipes => 'Все рецепты';
	@override String get myRecipes => 'Мои рецепты';
	@override String get editShared => 'Редактировать общий рецепт';
	@override String get sharedUpdated => 'Рецепт обновлён';
	@override String get noneOfMine => 'Вы ещё ничего не публиковали';
	@override String get search => 'Поиск';
	@override String get searchHint => 'Название рецепта или автор';
	@override String get savedOnly => 'Сохранённые';
	@override String get noResults => 'Ничего не найдено';
	@override String get attachRecipe => 'Прикрепить рецепт';
	@override String get openRecipe => 'Открыть рецепт';
	@override String get recipeUnavailable => 'Этот рецепт больше недоступен';
	@override String get sortAndFilter => 'Сортировка и фильтр';
	@override String get sort => 'Сортировка';
	@override String get sortNewest => 'Сначала новые';
	@override String get sortOldest => 'Сначала старые';
	@override String get sortMostLiked => 'Самые популярные';
	@override String get topics => 'Темы';
	@override String get likes => 'Лайки';
	@override String get anyLikes => 'Любое';
	@override String atLeastLikes({required Object count}) => 'от ${count}';
	@override String get totalTime => 'Общее время';
	@override String get anyTime => 'Любое время';
	@override String upTo({required Object duration}) => 'До ${duration}';
	@override String get clearFilters => 'Сбросить фильтры';
	@override String get applyFilters => 'Показать результаты';
	@override String likesPlus({required Object count}) => '${count}+';
	@override String durationPlus({required Object duration}) => '${duration}+';
	@override String get splitTimes => 'Разделить на подготовку и готовку';
	@override String get alreadySaved => 'Этот рецепт у вас уже есть';
	@override String get savedTag => 'Сохранено';
	@override String get removeSaved => 'Убрать из сохранённых';
	@override String get removeSavedConfirm => 'Рецепт будет убран из сохранённых. Его можно снова сохранить из сообщества.';
}

// Path: sharing
class _Translations$sharing$ru extends Translations$sharing$he {
	_Translations$sharing$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Поделиться рецептом';
	@override String get contactLabel => 'Почта или телефон человека';
	@override String get contactHint => 'name@example.com или 05…';
	@override String get roleTitle => 'Права';
	@override String get roleViewer => 'Только просмотр';
	@override String get roleViewerHint => 'Видит рецепт, но не может менять';
	@override String get roleEditor => 'Редактирование';
	@override String get roleEditorHint => 'Его изменения появятся и у вас';
	@override String get send => 'Отправить приглашение';
	@override String get sent => 'Приглашение отправлено';
	@override String get invalidContact => 'Введите корректную почту или телефон';
	@override String get notFound => 'Аккаунт с такими данными не найден. Убедитесь, что почта или телефон привязаны к его аккаунту и что приложение недавно открывалось.';
	@override String get self => 'Нельзя поделиться рецептом с самим собой';
	@override String get failed => 'Не удалось поделиться, попробуйте снова';
	@override String get pendingInvites => 'Ожидающие приглашения';
	@override String get noPendingInvites => 'Нет ожидающих приглашений';
	@override String get sharedByMe => 'Рецепты, которыми я поделился';
	@override String get sharedWithMe => 'Рецепты, которыми поделились со мной';
	@override String get nothingSharedByMe => 'Вы ещё ничем не делились';
	@override String get nothingSharedWithMe => 'С вами ещё не делились рецептами';
	@override String get accept => 'Принять';
	@override String get decline => 'Отклонить';
	@override String get accepted => 'Рецепт добавлен к вашим';
	@override String get declined => 'Приглашение отклонено';
	@override String get acceptFailed => 'Не удалось принять, попробуйте снова';
	@override String get members => 'Участники';
	@override String get noMembersYet => 'Пока никто не принял';
	@override String get remove => 'Удалить';
	@override String get leave => 'Покинуть';
	@override String get removed => 'Участник удалён';
	@override String get left => 'Вы вышли из общего доступа';
	@override String invitedBy({required Object name}) => 'от ${name}';
	@override String get sharedTag => 'Общий';
	@override String get viewerTag => 'Только просмотр';
	@override String get editorTag => 'Редактор';
	@override String get ownerTag => 'Мой';
	@override String get syncFailed => 'Не удалось обновить общий рецепт, показана сохранённая версия';
	@override String get viewerCannotEdit => 'Рецепт доступен вам только для просмотра';
	@override String get shareAction => 'Поделиться';
	@override String get directoryUnavailable => 'Общий доступ ещё не настроен на сервере. Выйдите и войдите снова; если не помогает — нужно развернуть правила Firestore.';
}

// Path: notifications
class _Translations$notifications$ru extends Translations$notifications$he {
	_Translations$notifications$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Уведомления';
	@override String get empty => 'Уведомлений нет';
	@override String sharedRecipe({required Object name, required Object recipe}) => '${name} поделился(-ась) с вами «${recipe}»';
	@override String get asViewer => 'только просмотр';
	@override String get asEditor => 'для редактирования';
	@override String get markAllRead => 'Отметить все прочитанными';
	@override String get openRecipe => 'Открыть рецепт';
	@override String get alreadyHandled => 'Приглашение уже обработано';
}

// Path: editor
class _Translations$editor$ru extends Translations$editor$he {
	_Translations$editor$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редактирование рецепта';
	@override String get recipeTitle => 'Название рецепта';
	@override String get titleHint => 'Например: иерусалимская шакшука';
	@override String get topics => 'Темы';
	@override String get titleRequired => 'Укажите название рецепта';
	@override String get prepMinutes => 'Подготовка (мин)';
	@override String get cookMinutes => 'Готовка (мин)';
	@override String get amount => 'Количество';
	@override String get unit => 'Единица';
	@override String get ingredientName => 'Название ингредиента';
	@override String get stepHint => 'Опишите шаг';
	@override String get addIngredient => 'Добавить ингредиент';
	@override String get addStep => 'Добавить шаг';
	@override String get removeIngredient => 'Удалить ингредиент';
	@override String get removeStep => 'Удалить шаг';
	@override String get reorderStep => 'Изменить порядок шага';
	@override String get fixSpelling => 'Исправить орфографию';
	@override String get refining => 'Исправляем рецепт...';
	@override String get refineError => 'Не удалось исправить рецепт';
	@override String get spellingFixed => 'Рецепт исправлен';
	@override String get noChanges => 'Орфографических ошибок не найдено';
	@override String get timesSynced => 'Время в инструкциях обновлено';
	@override String get discardTitle => 'Отменить изменения?';
	@override String get discardBody => 'Ваши правки не будут сохранены.';
	@override String get discard => 'Отменить';
	@override String get saveOptionsTitle => 'Как сохранить?';
	@override String get savePlainHint => 'Сохранить изменения как есть, без ожидания';
	@override String get saveWithAi => 'Сохранить с проверкой AI';
	@override String get saveWithAiHint => 'Исправить орфографию и согласовать время в шагах';
}

// Path: ingestion
class _Translations$ingestion$ru extends Translations$ingestion$he {
	_Translations$ingestion$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Добавить рецепт';
	@override String get pasteText => 'Вставить текст';
	@override String get pasteHint => 'Вставьте сюда рецепт из WhatsApp или любого другого источника';
	@override String get webSearch => 'Поиск в интернете';
	@override String get urlScrape => 'Ссылка на сайт';
	@override String get socialVideo => 'Видео: TikTok / Instagram / YouTube / Facebook';
	@override String get socialVideoHint => 'Вставьте ссылку на видео из TikTok, Instagram, YouTube или Facebook';
	@override String get socialUnreadable => 'Не удалось прочитать это видео. Возможно, аккаунт закрыт или платформа заблокировала запрос. Скопируйте описание и вставьте его как текст.';
	@override String get aiRequest => 'Запросить рецепт';
	@override String get aiRequestHint => 'Опишите, что хотите приготовить. Например: манная каша для годовалого ребёнка с фруктами';
	@override String get parse => 'Разобрать рецепт';
	@override String get parsing => 'Разбираем рецепт...';
	@override String get parseError => 'Не удалось разобрать рецепт';
	@override String get reviewTitle => 'Проверьте перед сохранением';
	@override String get notConfigured => 'Для этой функции нужен внешний сервис, который ещё не настроен';
	@override String get openOptionsTitle => 'Как открыть рецепт?';
	@override String get viewOriginal => 'Показать оригинал';
	@override String get viewOriginalHint => 'Текст страницы как есть, без обработки — мгновенно';
	@override String get generateStructured => 'Создать структурированный рецепт';
	@override String get generateStructuredHint => 'Автоматическое извлечение ингредиентов, количеств и шагов';
	@override String get originalTitle => 'Оригинальный рецепт';
	@override String get fetchFailed => 'Не удалось загрузить страницу';
	@override String get loadingOriginal => 'Загружаем страницу...';
	@override String get structuredFromSite => 'Прочитано напрямую из структурированных данных сайта, без AI';
	@override String get useStructured => 'Продолжить со структурированным рецептом';
	@override String get preferAi => 'Обработать через AI';
	@override String get analysisTimedOut => 'Анализ не завершился вовремя';
	@override String get analysisFailed => 'Анализ не удался';
	@override String get unparsedHint => 'Текст сохранён как есть. Попробуйте снова, отредактируйте вручную или сохраните и проанализируйте позже.';
	@override String get retryAnalysis => 'Попробовать снова';
	@override String get editManually => 'Редактировать вручную';
	@override String get saveForLater => 'Сохранить и проанализировать позже';
	@override String get untitledRecipe => 'Рецепт без названия';
	@override String get manual => 'Написать вручную';
	@override String get manualHint => 'Заполните рецепт сами в структурированном формате — без AI и без ожидания.';
	@override String get openBlankEditor => 'Открыть пустой редактор';
	@override String get generate => 'Создать рецепт';
	@override String get generating => 'Пишем ваш рецепт...';
}

// Path: mealPlanner
class _Translations$mealPlanner$ru extends Translations$mealPlanner$he {
	_Translations$mealPlanner$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Планирование питания';
	@override String get newPlan => 'Новое меню';
	@override String get planName => 'Название меню';
	@override String get addMeal => 'Добавить приём пищи';
	@override String get mealName => 'Название приёма пищи';
	@override String get addItem => 'Добавить позицию';
	@override String get pickRecipe => 'Выбрать рецепт';
	@override String get quickEntry => 'Быстрая позиция';
	@override String get noPlans => 'Меню пока нет. Создайте первое!';
	@override String get addMealHint => 'Выберите рецепт или добавьте быструю позицию';
	@override String get breakfast => 'Завтрак';
	@override String get lunch => 'Обед';
	@override String get dinner => 'Ужин';
	@override String get morningSnack => 'Утренний перекус';
	@override String get afternoonSnack => 'Дневной перекус';
	@override String get eveningSnack => 'Вечерний перекус';
	@override String get template => 'Начальный шаблон';
	@override String get templateFree => 'Начать с пустого';
	@override String get templateThree => '3 приёма пищи';
	@override String get templateSix => '6 приёмов пищи';
	@override String get templateFreeHint => 'Пустое меню — добавьте приёмы пищи сами';
	@override String get templateThreeHint => 'Завтрак, обед и ужин каждый день';
	@override String get templateSixHint => '3 основных приёма пищи и перекусы каждый день';
	@override String get nameRequired => 'Дайте меню название';
	@override String get products => 'Продукты';
	@override String get addProduct => 'Добавить продукт';
	@override String get productName => 'Название продукта';
	@override String get noProducts => 'Без продуктов позиция попадёт в список покупок одной строкой под своим названием';
	@override String get itemName => 'Название позиции';
	@override String get editItem => 'Изменить позицию';
}

// Path: groceryList
class _Translations$groceryList$ru extends Translations$groceryList$he {
	_Translations$groceryList$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Список покупок';
	@override String get aggregated => 'Собран из всех активных меню';
	@override String get addItem => 'Новая позиция';
	@override String get category => 'Категория';
	@override String get breakdownTitle => 'Источники количества';
	@override String get collectionProgress => 'Прогресс сбора';
	@override String itemsCollected({required Object collected, required Object total}) => 'Собрано ${collected} из ${total} позиций';
	@override String get adjustAmounts => 'Изменить количество';
	@override String get buffer => 'Дополнительное количество';
	@override String get share => 'Поделиться списком';
	@override String get empty => 'Список сейчас пуст';
	@override String get uncheckedSection => 'Ещё собрать';
	@override String get checkedSection => 'Собрано';
	@override String get selectAll => 'Выбрать всё';
	@override String get clearAll => 'Снять выбор';
	@override String get deleteChecked => 'Удалить собранные';
	@override String get amount => 'Количество';
	@override String get unit => 'Единица';
	@override String get lastSource => 'Должен остаться хотя бы один источник';
	@override String get itemName => 'Название позиции';
	@override String get planFilter => 'Все меню';
	@override String get choosePlans => 'Выбрать меню';
	@override String plansSelected({required Object count}) => 'Выбрано меню: ${count}';
	@override String get onePlanSelected => 'Выбрано одно меню';
	@override String get noPlansToPick => 'Пока нет меню для выбора';
	@override String get allPlansHint => 'Сводка по всем меню';
	@override String get selectPlansTitle => 'Какие меню входят в список?';
	@override String get applySelection => 'Обновить список';
	@override String get selectAllPlans => 'Все меню';
}

// Path: unit
class _Translations$unit$ru extends Translations$unit$he {
	_Translations$unit$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get gram => 'г';
	@override String get kilogram => 'кг';
	@override String get milliliter => 'мл';
	@override String get liter => 'л';
	@override String get teaspoon => 'ч. л.';
	@override String get tablespoon => 'ст. л.';
	@override String get cup => 'стакан';
	@override String get unit => 'шт.';
	@override String get pinch => 'щепотка';
	@override String get unspecified => '—';
}

// Path: image
class _Translations$image$ru extends Translations$image$he {
	_Translations$image$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get add => 'Добавить фото';
	@override String get change => 'Изменить фото';
	@override String get gallery => 'Выбрать из галереи';
	@override String get camera => 'Сделать фото';
	@override String get remove => 'Удалить фото';
	@override String get generate => 'Создать с помощью ИИ';
	@override String get generating => 'Создаём изображение… это займёт несколько секунд';
	@override String get generateFailed => 'Не удалось создать изображение, попробуйте ещё раз';
	@override String get coverTitle => 'Какую обложку создать?';
	@override String get coverHint => 'Выберите категорию, напишите что-нибудь или и то и другое';
	@override String get coverFreeText => 'Свободный текст, например: бургеры';
	@override String get coverRequired => 'Выберите категорию или напишите что-нибудь';
	@override String get coverGenerate => 'Создать обложку';
	@override String get themeKids => 'Детское';
	@override String get themeHealthy => 'Здоровое';
	@override String get themeIndulgent => 'Вкусное и сытное';
	@override String get themeSweets => 'Сладкое и выпечка';
	@override String get themeMeat => 'Мясо и гриль';
	@override String get themeVegan => 'Веганское';
	@override String get themeHolidays => 'Праздники';
	@override String get themeQuick => 'Быстро и просто';
}

// Path: nav
class _Translations$nav$ru extends Translations$nav$he {
	_Translations$nav$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get library => 'Книги';
	@override String get recipes => 'Рецепты';
	@override String get mealPlan => 'Меню';
	@override String get groceries => 'Покупки';
	@override String get settings => 'Настройки';
	@override String get community => 'Сообщество';
}

// Path: update
class _Translations$update$ru extends Translations$update$he {
	_Translations$update$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get forcedTitle => 'Требуется обновление';
	@override String forcedBody({required Object version}) => 'Эта версия EasyPlate больше не поддерживается. Обновитесь до версии ${version}, чтобы продолжить.';
	@override String get optionalTitle => 'Вышла новая версия';
	@override String optionalBody({required Object version}) => 'EasyPlate ${version} уже в магазине — с последними улучшениями.';
	@override String get updateNow => 'Обновить';
	@override String get later => 'Пропустить';
}

// Path: ads
class _Translations$ads$ru extends Translations$ads$he {
	_Translations$ads$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get badge => 'Реклама';
	@override String freeViewsLeft({required Object count}) => 'На сегодня осталось бесплатных рецептов: ${count}';
	@override String rewardedViewsLeft({required Object count}) => 'На сегодня осталось открытий за короткое видео: ${count}';
	@override String get sharedQuotaReached => 'Вы достигли дневного лимита общих рецептов. Завтра он обнулится!';
	@override String get unlockRecipeTitle => 'Открыть общий рецепт';
	@override String unlockRecipeMessage({required Object count}) => 'Посмотрите короткое видео, чтобы открыть этот рецепт (осталось на сегодня: ${count})';
	@override String aiQuotaLeft({required Object remaining, required Object total}) => 'На сегодня осталось ИИ-извлечений: ${remaining}/${total}';
	@override String get aiQuotaReached => 'Вы достигли дневного лимита ИИ-извлечений. Завтра снова откроется!';
	@override String get aiLockedHint => 'Для извлечения по ссылке нужно посмотреть короткое видео';
	@override String get unlockAiTitle => 'Извлечь рецепт с помощью ИИ';
	@override String unlockAiMessage({required Object count}) => 'Посмотрите короткое видео, чтобы извлечь рецепт по ссылке (осталось на сегодня: ${count})';
	@override String get watchVideo => 'Смотреть видео';
	@override String get parseWithVideo => 'Посмотреть видео и разобрать';
	@override String get blockedForToday => 'Закрыто на сегодня';
	@override String get loadingVideo => 'Загрузка видео...';
	@override String get videoNotCompleted => 'Видео не досмотрено, рецепт остаётся закрытым';
	@override String get videoUnavailable => 'Сейчас нет доступного видео, попробуйте через минуту';
}

// Path: premium
class _Translations$premium$ru extends Translations$premium$he {
	_Translations$premium$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'EasyPlate Premium';
	@override String get headline => 'Без рекламы, без ограничений';
	@override String get subtitle => 'Всё, что умеет EasyPlate, не дожидаясь завтра.';
	@override String get benefitNoAds => 'Без рекламы в лентах сообщества';
	@override String get benefitShared => 'Общие рецепты без дневного лимита';
	@override String benefitAi({required Object count}) => 'Извлечение рецептов с помощью ИИ из любой ссылки, до ${count} в день';
	@override String get periodWeekly => 'Еженедельно';
	@override String get periodMonthly => 'Ежемесячно';
	@override String get periodTwoMonth => 'Раз в 2 месяца';
	@override String get periodThreeMonth => 'Ежеквартально';
	@override String get periodSixMonth => 'Раз в 6 месяцев';
	@override String get periodAnnual => 'Ежегодно';
	@override String get periodLifetime => 'Навсегда';
	@override String get bestValue => 'Выгоднее всего';
	@override String subscribeFor({required Object price}) => 'Оформить за ${price}';
	@override String buyFor({required Object price}) => 'Купить за ${price}';
	@override String get restore => 'Восстановить покупки';
	@override String get restored => 'Подписка восстановлена';
	@override String get nothingToRestore => 'Покупок для восстановления не найдено';
	@override String get activeTitle => 'Premium активен';
	@override String get activeBody => 'Спасибо! Реклама и дневные лимиты отключены для этого аккаунта.';
	@override String get manage => 'Управление подпиской';
	@override String get cancel => 'Отменить подписку';
	@override String get cancelNote => 'Отмена отключает автопродление. Премиум остаётся активным до конца уже оплаченного периода. Возврат средств не производится.';
	@override String get unavailable => 'Подписки сейчас недоступны. Попробуйте позже.';
	@override String get purchaseFailed => 'Покупка не завершена';
	@override String get purchased => 'Добро пожаловать в Premium!';
	@override String get legal => 'Подписка продлевается автоматически в конце каждого периода, если не отменить её минимум за 24 часа до окончания. Оплата списывается с аккаунта магазина; управлять подпиской или отменить её можно в настройках магазина.';
	@override String get terms => 'Условия использования';
	@override String get privacy => 'Политика конфиденциальности';
}

// Path: walkthrough
class _Translations$walkthrough$ru extends Translations$walkthrough$he {
	_Translations$walkthrough$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Обучение';
	@override String get start => 'Запустить обучение';
	@override String get startHint => 'Пошаговая экскурсия по всем возможностям приложения';
	@override String get startFull => 'Начать полную экскурсию';
	@override String get focused => 'Показать подсказку по действию';
	@override String get next => 'Далее';
	@override String get finish => 'Готово';
	@override String get skipStep => 'Пропустить шаг';
	@override String get close => 'Закрыть обучение';
	@override String stepOf({required Object current, required Object total}) => 'Шаг ${current} из ${total}';
	@override String get tapHint => 'Нажмите на выделенную область или «Далее»';
	@override String get bookTitle => 'Справочник EasyPlate';
	@override String get bookSubtitle => 'Всё, что умеет приложение, глава за главой. Это только справочник: ничего не сохраняется.';
	@override String get contents => 'Оглавление';
	@override String chapter({required Object number}) => 'Глава ${number}';
	@override String get backToContents => 'К оглавлению';
	@override String get stepsTitle => 'Шаги';
	@override String get welcomeTitle => 'Добро пожаловать в EasyPlate';
	@override String get welcomeBody => 'Пройдём вместе по основным действиям. Любой шаг можно пропустить, а обучение закрыть и запустить снова с экрана поддержки.';
	@override late final _Translations$walkthrough$topics$ru topics = _Translations$walkthrough$topics$ru._(_root);
	@override String get demoRecipes => 'Примеры рецептов';
	@override String get demoRecipesHint => 'Так выглядят рецепты в приложении. Нажмите на рецепт, чтобы увидеть его страницу целиком: время, темы, аллергены, ингредиенты и шаги.';
	@override String get demoBooks => 'Примеры книг';
	@override String get demoBooksHint => 'Так выглядит книга рецептов. Нажмите на книгу, чтобы открыть её, листать страницы и переходить из оглавления.';
	@override String get demoOnly => 'Только пример, не сохраняется';
}

// Path: feedback
class _Translations$feedback$ru extends Translations$feedback$he {
	_Translations$feedback$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сообщить и предложить';
	@override String get subtitle => 'Нашли ошибку? Есть идея? Напишите нам здесь; мы читаем каждое сообщение.';
	@override String get bug => 'Ошибка';
	@override String get suggestion => 'Предложение';
	@override String get bugHint => 'Опишите ошибку: что вы сделали, что произошло и чего ожидали...';
	@override String get suggestionHint => 'Расскажите, что вы хотели бы видеть в приложении и чем это поможет...';
	@override String get send => 'Отправить';
	@override String get sent => 'Спасибо! Сообщение отправлено.';
	@override String get failed => 'Не удалось отправить, попробуйте позже';
	@override String get admin => 'Обращения';
	@override String get all => 'Все';
	@override String get bugs => 'Ошибки';
	@override String get suggestions => 'Предложения';
	@override String get none => 'Обращений пока нет';
	@override String version({required Object version}) => 'Версия ${version}';
	@override String get notAllowed => 'Этот экран только для администратора';
}

// Path: walkthrough.topics
class _Translations$walkthrough$topics$ru extends Translations$walkthrough$topics$he {
	_Translations$walkthrough$topics$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _Translations$walkthrough$topics$addRecipe$ru addRecipe = _Translations$walkthrough$topics$addRecipe$ru._(_root);
	@override late final _Translations$walkthrough$topics$myRecipes$ru myRecipes = _Translations$walkthrough$topics$myRecipes$ru._(_root);
	@override late final _Translations$walkthrough$topics$library$ru library = _Translations$walkthrough$topics$library$ru._(_root);
	@override late final _Translations$walkthrough$topics$mealPlan$ru mealPlan = _Translations$walkthrough$topics$mealPlan$ru._(_root);
	@override late final _Translations$walkthrough$topics$groceries$ru groceries = _Translations$walkthrough$topics$groceries$ru._(_root);
	@override late final _Translations$walkthrough$topics$community$ru community = _Translations$walkthrough$topics$community$ru._(_root);
	@override late final _Translations$walkthrough$topics$account$ru account = _Translations$walkthrough$topics$account$ru._(_root);
}

// Path: walkthrough.topics.addRecipe
class _Translations$walkthrough$topics$addRecipe$ru extends Translations$walkthrough$topics$addRecipe$he {
	_Translations$walkthrough$topics$addRecipe$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Добавить рецепт';
	@override String get summary => 'Добавьте рецепт из любого источника, и ИИ приведёт его к единому формату: ингредиенты, количества, шаги и теги.';
	@override String get s1 => 'Нажмите кнопку с искрой рядом с заголовком, чтобы добавить рецепт.';
	@override String get s2 => 'Выберите источник: вставленный текст, поиск в интернете, ссылка на сайт, видео TikTok/Reels, свободный запрос к ИИ или ввод вручную. После разбора проверьте, отредактируйте и сохраните.';
}

// Path: walkthrough.topics.myRecipes
class _Translations$walkthrough$topics$myRecipes$ru extends Translations$walkthrough$topics$myRecipes$he {
	_Translations$walkthrough$topics$myRecipes$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Мои и сохранённые рецепты';
	@override String get summary => 'Рецепты, которые вы написали, и сохранённые из сообщества, с поиском и фильтрами по темам.';
	@override String get s1 => 'Здесь переключаются между написанными вами рецептами и сохранёнными из сообщества.';
	@override String get s2 => 'Поиск по названию и фильтр по темам: мясное, молочное, вегетарианское, веганское, кошерное, без глютена и аллергены.';
}

// Path: walkthrough.topics.library
class _Translations$walkthrough$topics$library$ru extends Translations$walkthrough$topics$library$he {
	_Translations$walkthrough$topics$library$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Книги рецептов';
	@override String get summary => 'Собирайте рецепты в книги с оглавлением, обложкой и перелистыванием.';
	@override String get s1 => 'Нажмите «Библиотека», чтобы перейти к книгам.';
	@override String get s2 => 'Здесь создают новую книгу. Внутри добавляют рецепты, листают страницы и меняют обложку.';
}

// Path: walkthrough.topics.mealPlan
class _Translations$walkthrough$topics$mealPlan$ru extends Translations$walkthrough$topics$mealPlan$he {
	_Translations$walkthrough$topics$mealPlan$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Меню на неделю';
	@override String get summary => 'План приёмов пищи на всю неделю, из которого строится список покупок.';
	@override String get s1 => 'Нажмите «Меню», чтобы спланировать неделю.';
	@override String get s2 => 'Создайте недельный план и расставьте рецепты по дням и приёмам пищи.';
}

// Path: walkthrough.topics.groceries
class _Translations$walkthrough$topics$groceries$ru extends Translations$walkthrough$topics$groceries$he {
	_Translations$walkthrough$topics$groceries$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Список покупок';
	@override String get summary => 'Список, собранный из меню, с отметками о том, что уже куплено.';
	@override String get s1 => 'Нажмите «Покупки».';
	@override String get s2 => 'Обновление заново собирает список из всех рецептов недельного меню.';
	@override String get s3 => 'А здесь добавляют произвольный пункт вручную.';
}

// Path: walkthrough.topics.community
class _Translations$walkthrough$topics$community$ru extends Translations$walkthrough$topics$community$he {
	_Translations$walkthrough$topics$community$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Сообщество';
	@override String get summary => 'Рецепты, которыми делятся все, и форум вопросов и ответов.';
	@override String get s1 => 'Нажмите «Сообщество».';
	@override String get s2 => 'Общие рецепты и форум. Ставьте лайки, сохраняйте рецепты себе и прикрепляйте рецепт к ответу на форуме.';
	@override String get s3 => 'Кнопка «поделиться» публикует ваш рецепт в сообществе.';
}

// Path: walkthrough.topics.account
class _Translations$walkthrough$topics$account$ru extends Translations$walkthrough$topics$account$he {
	_Translations$walkthrough$topics$account$ru._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Аккаунт и уведомления';
	@override String get summary => 'Уведомления о приглашениях поделиться и аккаунт с премиумом, настройками и поддержкой.';
	@override String get s1 => 'Уведомления: приглашения поделиться рецептами и обновления.';
	@override String get s2 => 'Аккаунт: премиум, обмен между аккаунтами, настройки, профиль и поддержка. Оттуда же можно запустить это обучение снова.';
}

/// The flat map containing all translations for locale <ru>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Easy Plate',
			'common.save' => 'Сохранить',
			'common.cancel' => 'Отмена',
			'common.ok' => 'ОК',
			'common.next' => 'Далее',
			'common.back' => 'Назад',
			'common.done' => 'Готово',
			'common.add' => 'Добавить',
			'common.edit' => 'Изменить',
			'common.delete' => 'Удалить',
			'common.search' => 'Поиск',
			'common.retry' => 'Повторить',
			'common.loading' => 'Загрузка...',
			'common.error' => 'Произошла ошибка',
			'common.or' => 'или',
			'common.missingInfo' => '[нет данных]',
			'common.networkError' => 'Нет подключения к интернету',
			'auth.welcome' => 'Добро пожаловать в EasyPlate',
			'auth.subtitle' => 'Войдите, чтобы сохранять рецепты',
			'auth.signIn' => 'Вход',
			'auth.signUp' => 'Регистрация',
			'auth.signOut' => 'Выйти',
			'auth.email' => 'Эл. почта',
			'auth.emailHint' => 'name@example.com',
			'auth.password' => 'Пароль',
			'auth.passwordHint' => 'Минимум 6 символов',
			'auth.continueWithGoogle' => 'Продолжить с Google',
			'auth.continueWithPhone' => 'Продолжить по телефону',
			'auth.continueWithEmail' => 'Продолжить по почте',
			'auth.phoneNumber' => 'Номер телефона',
			'auth.phoneHint' => '+79161234567',
			'auth.sendCode' => 'Отправить код',
			'auth.smsCode' => 'Код из SMS',
			'auth.codeSentTo' => ({required Object phone}) => 'Мы отправили код на ${phone}',
			'auth.verify' => 'Подтвердить',
			'auth.resendCode' => 'Отправить снова',
			'auth.forgotPassword' => 'Забыли пароль',
			'auth.resetSent' => 'Письмо для сброса отправлено',
			'auth.noAccount' => 'Нет аккаунта? Зарегистрируйтесь',
			'auth.haveAccount' => 'Есть аккаунт? Войдите',
			'auth.invalidEmail' => 'Неверный адрес эл. почты',
			'auth.passwordTooShort' => 'Пароль должен содержать минимум 6 символов',
			'auth.invalidPhone' => 'Неверный номер телефона',
			'auth.codeRequired' => 'Введите полученный код',
			'auth.errorUnauthorized' => 'Введённые данные неверны',
			'auth.errorNetwork' => 'Нет подключения к интернету',
			'auth.errorUnknown' => 'Не удалось войти, попробуйте снова',
			'auth.signOutTitle' => 'Выйти?',
			'auth.signOutBody' => 'Чтобы вернуться к рецептам, нужно будет войти снова.',
			'auth.errorOperationNotAllowed' => 'Этот способ входа сейчас недоступен',
			'auth.errorTooManyRequests' => 'Слишком много попыток. Повторите через несколько минут',
			'auth.errorInvalidPhone' => 'Неверный номер телефона',
			'auth.errorEmailInUse' => 'Эта почта уже зарегистрирована',
			'auth.verifyEmailTitle' => 'Подтвердите почту',
			'auth.verifyEmailBody' => ({required Object email}) => 'Мы отправили ссылку на ${email}. Откройте её и вернитесь сюда.',
			'auth.resendEmail' => 'Отправить ссылку снова',
			'auth.emailResent' => 'Ссылка отправлена снова',
			'auth.checkVerification' => 'Я подтвердил',
			'auth.stillNotVerified' => 'Почта ещё не подтверждена',
			'auth.linkPhone' => 'Подтвердить телефон',
			'auth.phoneLinked' => 'Телефон подтверждён',
			'auth.phoneAlreadyUsed' => 'Этот номер уже привязан к другому аккаунту',
			'auth.emailAlreadyLinked' => 'К аккаунту уже привязана почта',
			'auth.addEmailPassword' => 'Добавить почту и пароль',
			'auth.verified' => 'Подтверждено',
			'auth.linkGoogle' => 'Привязать аккаунт Google',
			'auth.googleLinked' => 'Привязан',
			'auth.googleAlreadyUsed' => 'Этот аккаунт Google уже привязан к другому пользователю',
			'auth.googleAlreadyLinked' => 'Аккаунт Google уже привязан',
			'auth.phoneGateTitle' => 'Подтвердите телефон',
			'auth.phoneGateBody' => 'Каждый аккаунт подтверждается по телефону. Мы отправим вам код в SMS.',
			'auth.changeNumber' => 'Изменить номер',
			'auth.signInTitle' => 'Вход',
			'auth.phoneFirstHint' => 'Впервые здесь? Продолжите с телефоном.',
			'auth.errorAccountExistsDifferentCredential' => 'Этот адрес уже принадлежит другому аккаунту. Войдите тем способом, которым регистрировались.',
			'auth.errorCredentialInUse' => 'Эти данные уже принадлежат другому аккаунту',
			'auth.continueWithApple' => 'Продолжить с Apple',
			'auth.linkApple' => 'Привязать аккаунт Apple',
			'auth.appleLinked' => 'Привязан',
			'auth.appleAlreadyUsed' => 'Этот аккаунт Apple уже принадлежит другому пользователю',
			'auth.appleAlreadyLinked' => 'Аккаунт Apple уже привязан',
			'profile.setupTitle' => 'Последние детали',
			'profile.setupSubtitle' => 'Чтобы знать, как к вам обращаться',
			'profile.fullName' => 'Полное имя',
			'profile.fullNameHint' => 'Иван Иванов',
			'profile.fullNameRequired' => 'Укажите полное имя',
			'profile.photo' => 'Фото профиля',
			'profile.addPhoto' => 'Добавить фото',
			'profile.phoneOptional' => 'Телефон (необязательно)',
			'profile.emailOptional' => 'Почта (необязательно)',
			'profile.save' => 'Завершить регистрацию',
			'profile.saving' => 'Сохранение...',
			'profile.saveFailed' => 'Не удалось сохранить профиль',
			'profile.myProfile' => 'Мой профиль',
			'onboarding.welcomeTitle' => 'Добро пожаловать в EasyPlate',
			'onboarding.welcomeSubtitle' => 'Планируйте меню, готовьте и делайте покупки — всё в одном месте',
			'onboarding.shoppingDayTitle' => 'Какой у вас день еженедельных покупок?',
			'onboarding.dietaryTitle' => 'Каковы ваши пищевые предпочтения?',
			'onboarding.dietarySubtitle' => 'Можно выбрать несколько',
			'onboarding.finish' => 'Начнём',
			'dietary.meat' => 'Мясное',
			'dietary.dairy' => 'Молочное',
			'dietary.vegetarian' => 'Вегетарианское',
			'dietary.vegan' => 'Веганское',
			'dietary.kosher' => 'Кошерное',
			'dietary.glutenFree' => 'Без глютена',
			'dietary.allergy' => 'Аллергия',
			'allergens.title' => 'Аллергены',
			'allergens.pick' => 'Отметить аллергены',
			'allergens.contains' => 'Содержит',
			'allergens.mayContain' => 'Может содержать',
			'allergens.gluten' => 'Глютен',
			'allergens.milk' => 'Молоко',
			'allergens.eggs' => 'Яйца',
			'allergens.fish' => 'Рыба',
			'allergens.shellfish' => 'Морепродукты',
			'allergens.peanuts' => 'Арахис',
			'allergens.treeNuts' => 'Орехи',
			'allergens.sesame' => 'Кунжут',
			'allergens.soy' => 'Соя',
			'weekday.sunday' => 'Воскресенье',
			'weekday.monday' => 'Понедельник',
			'weekday.tuesday' => 'Вторник',
			'weekday.wednesday' => 'Среда',
			'weekday.thursday' => 'Четверг',
			'weekday.friday' => 'Пятница',
			'weekday.saturday' => 'Суббота',
			'settings.title' => 'Настройки',
			'settings.dietaryPreferences' => 'Пищевые предпочтения',
			'settings.shoppingDay' => 'День покупок',
			'settings.language' => 'Язык',
			'settings.appearance' => 'Оформление',
			'settings.themeSystem' => 'Как в системе',
			'settings.themeLight' => 'Светлая',
			'settings.themeDark' => 'Тёмная',
			'settings.soundEffects' => 'Звуковые эффекты (перелистывание страниц)',
			'settings.fastPageTurn' => 'Быстрое перелистывание',
			'settings.fastPageTurnHint' => 'Переход из содержания или быстрой навигации перелистывает страницы по пути. Отключите, чтобы сразу попадать на нужную страницу.',
			'settings.sharedAccess' => 'Управление доступом',
			'settings.noSharedAccess' => 'Вы ещё не делились книгами или списками',
			'more.title' => 'Ещё',
			'more.settings' => 'Настройки',
			'more.profile' => 'Мой профиль',
			'more.support' => 'Поддержка',
			'more.supportTitle' => 'Чем помочь?',
			'more.supportBody' => 'Напишите нам, и мы ответим.',
			'more.whatsapp' => 'Написать в WhatsApp',
			'more.email' => 'Отправить письмо',
			'more.supportUnavailable' => 'Не удалось открыть приложение',
			'language.hebrew' => 'עברית',
			'language.english' => 'English',
			'language.arabic' => 'العربية',
			'language.french' => 'Français',
			'language.russian' => 'Русский',
			'books.myLibrary' => 'Моя библиотека',
			'books.myRecipes' => 'Мои рецепты',
			'books.librarySubtitle' => 'Все ваши книги рецептов в одном месте',
			'books.recipesSubtitle' => 'Ищите и фильтруйте все собранные рецепты',
			'books.collection' => 'Коллекция',
			'books.recipesCount' => ({required Object count}) => 'Рецептов: ${count}',
			'books.newBook' => 'Новая книга',
			'books.newBookTitle' => 'Название книги',
			'books.tableOfContents' => 'Содержание',
			'books.emptyLibrary' => 'У вас пока нет книг. Создайте первую!',
			'books.emptyBook' => 'Эта книга пуста. Добавьте первый рецепт',
			'books.quickNav' => 'Быстрый переход',
			'books.share' => 'Поделиться книгой',
			'books.viewer' => 'Читатель',
			'books.editor' => 'Редактор',
			'books.reorderHint' => 'Перетащите, чтобы изменить порядок рецептов',
			'books.coverImage' => 'Обложка',
			'books.bookOptions' => 'Параметры книги',
			'books.renameBook' => 'Переименовать книгу',
			'books.spineColor' => 'Цвет корешка',
			'recipe.prepTime' => 'Время подготовки',
			'recipe.cookTime' => 'Время приготовления',
			'recipe.ingredients' => 'Ингредиенты',
			'recipe.ingredientsCount' => ({required Object count}) => 'Ингредиентов: ${count}',
			'recipe.minutes' => ({required Object count}) => '${count} мин',
			'recipe.hours' => ({required Object count}) => '${count} ч',
			'recipe.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours} ч ${minutes} мин',
			'recipe.instructions' => 'Приготовление',
			'recipe.addToBook' => 'Добавить в книгу',
			'recipe.removeFromBook' => 'Убрать из книги',
			'recipe.deleteRecipe' => 'Удалить рецепт',
			'recipe.photo' => 'Фото рецепта',
			'recipe.mine' => 'Мои рецепты',
			'recipe.saved' => 'Сохранённые',
			'recipe.noneMine' => 'Вы ещё не создали ни одного рецепта',
			'recipe.noneSaved' => 'Вы ещё ничего не сохранили',
			'recipe.pendingAnalysis' => 'Ожидает анализа',
			'recipe.pendingAnalysisHint' => 'Сохранён как сырой текст. Проанализируйте сейчас или отредактируйте вручную.',
			'recipe.analyzeNow' => 'Проанализировать с AI',
			'recipe.analyzing' => 'Анализируем рецепт...',
			'recipe.analyzeFailed' => 'Анализ не удался — попробуйте позже',
			'nutrition.title' => 'Пищевая ценность',
			'nutrition.perServing' => 'на порцию',
			'nutrition.perServingHint' => 'Все значения указаны на одну порцию. Оставьте пустым, чтобы убрать оценку.',
			'nutrition.servings' => 'порций',
			'nutrition.servingsCount' => ({required Object count}) => '${count} порций',
			'nutrition.calories' => 'Калории',
			'nutrition.kcal' => 'ккал',
			'nutrition.protein' => 'Белки',
			'nutrition.carbs' => 'Углеводы',
			'nutrition.fat' => 'Жиры',
			'nutrition.gramsShort' => 'г',
			'nutrition.estimate' => 'Оценить с помощью ИИ',
			'nutrition.estimating' => 'Оцениваем пищевую ценность…',
			'nutrition.estimateFailed' => 'Оценка не удалась, попробуйте ещё раз',
			'nutrition.none' => 'Для этого рецепта ещё нет пищевой ценности',
			'nutrition.noneHint' => 'ИИ может оценить калории, белки, углеводы и жиры по списку ингредиентов',
			'nutrition.estimated' => 'Пищевая ценность обновлена',
			'nutrition.editorServings' => 'Количество порций',
			'nutrition.editorCalories' => 'Калорий на порцию',
			'nutrition.editorProtein' => 'Белки (г)',
			'nutrition.editorCarbs' => 'Углеводы (г)',
			'nutrition.editorFat' => 'Жиры (г)',
			'nutrition.dashboard' => 'Панель питания',
			'nutrition.weekly' => 'На этой неделе',
			'nutrition.today' => 'Сегодня',
			'nutrition.dayTotal' => 'Итого за день',
			'nutrition.weekTotal' => 'Итого за неделю',
			'nutrition.dailyAverage' => 'В среднем на запланированный день',
			'nutrition.perMeal' => 'По приёмам пищи',
			'nutrition.perDay' => 'По дням',
			'nutrition.noPlanned' => 'Пока нет запланированных блюд с рецептами',
			'nutrition.missingCount' => ({required Object count}) => '${count} позиций без пищевой ценности',
			'nutrition.macroSplit' => 'Распределение калорий',
			'nutrition.kcalPerDay' => 'ккал в день',
			'nutrition.openDashboard' => 'Недельная панель',
			'community.title' => 'Сообщество',
			'community.forum' => 'Форум',
			'community.sharedRecipes' => 'Общие рецепты',
			'community.newPost' => 'Новый пост',
			'community.postTitle' => 'Заголовок',
			'community.postBody' => 'О чём хотите спросить или рассказать?',
			'community.postTitleRequired' => 'Нужен заголовок',
			'community.postBodyRequired' => 'Нужен текст',
			'community.publish' => 'Опубликовать',
			'community.replies' => ({required Object count}) => 'Ответов: ${count}',
			'community.noReplies' => 'Ответов пока нет',
			'community.oneReply' => 'Один ответ',
			'community.writeReply' => 'Написать ответ...',
			'community.send' => 'Отправить',
			'community.noPosts' => 'Постов пока нет. Будьте первым!',
			'community.noSharedRecipes' => 'Рецептов пока не публиковали. Поделитесь первым!',
			'community.shareRecipe' => 'Поделиться рецептом',
			'community.pickRecipeToShare' => 'Каким рецептом поделиться?',
			'community.saveToMyRecipes' => 'Сохранить к себе',
			'community.savedToMyRecipes' => 'Рецепт сохранён',
			'community.deletePost' => 'Удалить пост',
			'community.deletePostConfirm' => 'Пост и ответы будут удалены навсегда.',
			'community.unshare' => 'Убрать из ленты',
			'community.unshareConfirm' => 'Рецепт будет убран из общей ленты.',
			'community.byAuthor' => ({required Object name}) => 'от ${name}',
			'community.loadFailed' => 'Не удалось загрузить содержимое',
			'community.allRecipes' => 'Все рецепты',
			'community.myRecipes' => 'Мои рецепты',
			'community.editShared' => 'Редактировать общий рецепт',
			'community.sharedUpdated' => 'Рецепт обновлён',
			'community.noneOfMine' => 'Вы ещё ничего не публиковали',
			'community.search' => 'Поиск',
			'community.searchHint' => 'Название рецепта или автор',
			'community.savedOnly' => 'Сохранённые',
			'community.noResults' => 'Ничего не найдено',
			'community.attachRecipe' => 'Прикрепить рецепт',
			'community.openRecipe' => 'Открыть рецепт',
			'community.recipeUnavailable' => 'Этот рецепт больше недоступен',
			'community.sortAndFilter' => 'Сортировка и фильтр',
			'community.sort' => 'Сортировка',
			'community.sortNewest' => 'Сначала новые',
			'community.sortOldest' => 'Сначала старые',
			'community.sortMostLiked' => 'Самые популярные',
			'community.topics' => 'Темы',
			'community.likes' => 'Лайки',
			'community.anyLikes' => 'Любое',
			'community.atLeastLikes' => ({required Object count}) => 'от ${count}',
			'community.totalTime' => 'Общее время',
			'community.anyTime' => 'Любое время',
			'community.upTo' => ({required Object duration}) => 'До ${duration}',
			'community.clearFilters' => 'Сбросить фильтры',
			'community.applyFilters' => 'Показать результаты',
			'community.likesPlus' => ({required Object count}) => '${count}+',
			'community.durationPlus' => ({required Object duration}) => '${duration}+',
			'community.splitTimes' => 'Разделить на подготовку и готовку',
			'community.alreadySaved' => 'Этот рецепт у вас уже есть',
			'community.savedTag' => 'Сохранено',
			'community.removeSaved' => 'Убрать из сохранённых',
			'community.removeSavedConfirm' => 'Рецепт будет убран из сохранённых. Его можно снова сохранить из сообщества.',
			'sharing.title' => 'Поделиться рецептом',
			'sharing.contactLabel' => 'Почта или телефон человека',
			'sharing.contactHint' => 'name@example.com или 05…',
			'sharing.roleTitle' => 'Права',
			'sharing.roleViewer' => 'Только просмотр',
			'sharing.roleViewerHint' => 'Видит рецепт, но не может менять',
			'sharing.roleEditor' => 'Редактирование',
			'sharing.roleEditorHint' => 'Его изменения появятся и у вас',
			'sharing.send' => 'Отправить приглашение',
			'sharing.sent' => 'Приглашение отправлено',
			'sharing.invalidContact' => 'Введите корректную почту или телефон',
			'sharing.notFound' => 'Аккаунт с такими данными не найден. Убедитесь, что почта или телефон привязаны к его аккаунту и что приложение недавно открывалось.',
			'sharing.self' => 'Нельзя поделиться рецептом с самим собой',
			'sharing.failed' => 'Не удалось поделиться, попробуйте снова',
			'sharing.pendingInvites' => 'Ожидающие приглашения',
			'sharing.noPendingInvites' => 'Нет ожидающих приглашений',
			'sharing.sharedByMe' => 'Рецепты, которыми я поделился',
			'sharing.sharedWithMe' => 'Рецепты, которыми поделились со мной',
			'sharing.nothingSharedByMe' => 'Вы ещё ничем не делились',
			'sharing.nothingSharedWithMe' => 'С вами ещё не делились рецептами',
			'sharing.accept' => 'Принять',
			'sharing.decline' => 'Отклонить',
			'sharing.accepted' => 'Рецепт добавлен к вашим',
			'sharing.declined' => 'Приглашение отклонено',
			'sharing.acceptFailed' => 'Не удалось принять, попробуйте снова',
			'sharing.members' => 'Участники',
			'sharing.noMembersYet' => 'Пока никто не принял',
			'sharing.remove' => 'Удалить',
			'sharing.leave' => 'Покинуть',
			'sharing.removed' => 'Участник удалён',
			'sharing.left' => 'Вы вышли из общего доступа',
			'sharing.invitedBy' => ({required Object name}) => 'от ${name}',
			'sharing.sharedTag' => 'Общий',
			'sharing.viewerTag' => 'Только просмотр',
			'sharing.editorTag' => 'Редактор',
			'sharing.ownerTag' => 'Мой',
			'sharing.syncFailed' => 'Не удалось обновить общий рецепт, показана сохранённая версия',
			'sharing.viewerCannotEdit' => 'Рецепт доступен вам только для просмотра',
			'sharing.shareAction' => 'Поделиться',
			'sharing.directoryUnavailable' => 'Общий доступ ещё не настроен на сервере. Выйдите и войдите снова; если не помогает — нужно развернуть правила Firestore.',
			'notifications.title' => 'Уведомления',
			'notifications.empty' => 'Уведомлений нет',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => '${name} поделился(-ась) с вами «${recipe}»',
			'notifications.asViewer' => 'только просмотр',
			'notifications.asEditor' => 'для редактирования',
			'notifications.markAllRead' => 'Отметить все прочитанными',
			'notifications.openRecipe' => 'Открыть рецепт',
			'notifications.alreadyHandled' => 'Приглашение уже обработано',
			'editor.title' => 'Редактирование рецепта',
			'editor.recipeTitle' => 'Название рецепта',
			'editor.titleHint' => 'Например: иерусалимская шакшука',
			'editor.topics' => 'Темы',
			'editor.titleRequired' => 'Укажите название рецепта',
			'editor.prepMinutes' => 'Подготовка (мин)',
			'editor.cookMinutes' => 'Готовка (мин)',
			'editor.amount' => 'Количество',
			'editor.unit' => 'Единица',
			'editor.ingredientName' => 'Название ингредиента',
			'editor.stepHint' => 'Опишите шаг',
			'editor.addIngredient' => 'Добавить ингредиент',
			'editor.addStep' => 'Добавить шаг',
			'editor.removeIngredient' => 'Удалить ингредиент',
			'editor.removeStep' => 'Удалить шаг',
			'editor.reorderStep' => 'Изменить порядок шага',
			'editor.fixSpelling' => 'Исправить орфографию',
			'editor.refining' => 'Исправляем рецепт...',
			'editor.refineError' => 'Не удалось исправить рецепт',
			'editor.spellingFixed' => 'Рецепт исправлен',
			'editor.noChanges' => 'Орфографических ошибок не найдено',
			'editor.timesSynced' => 'Время в инструкциях обновлено',
			'editor.discardTitle' => 'Отменить изменения?',
			'editor.discardBody' => 'Ваши правки не будут сохранены.',
			'editor.discard' => 'Отменить',
			'editor.saveOptionsTitle' => 'Как сохранить?',
			'editor.savePlainHint' => 'Сохранить изменения как есть, без ожидания',
			'editor.saveWithAi' => 'Сохранить с проверкой AI',
			'editor.saveWithAiHint' => 'Исправить орфографию и согласовать время в шагах',
			'ingestion.title' => 'Добавить рецепт',
			'ingestion.pasteText' => 'Вставить текст',
			'ingestion.pasteHint' => 'Вставьте сюда рецепт из WhatsApp или любого другого источника',
			'ingestion.webSearch' => 'Поиск в интернете',
			'ingestion.urlScrape' => 'Ссылка на сайт',
			'ingestion.socialVideo' => 'Видео: TikTok / Instagram / YouTube / Facebook',
			'ingestion.socialVideoHint' => 'Вставьте ссылку на видео из TikTok, Instagram, YouTube или Facebook',
			'ingestion.socialUnreadable' => 'Не удалось прочитать это видео. Возможно, аккаунт закрыт или платформа заблокировала запрос. Скопируйте описание и вставьте его как текст.',
			'ingestion.aiRequest' => 'Запросить рецепт',
			'ingestion.aiRequestHint' => 'Опишите, что хотите приготовить. Например: манная каша для годовалого ребёнка с фруктами',
			'ingestion.parse' => 'Разобрать рецепт',
			'ingestion.parsing' => 'Разбираем рецепт...',
			'ingestion.parseError' => 'Не удалось разобрать рецепт',
			'ingestion.reviewTitle' => 'Проверьте перед сохранением',
			'ingestion.notConfigured' => 'Для этой функции нужен внешний сервис, который ещё не настроен',
			'ingestion.openOptionsTitle' => 'Как открыть рецепт?',
			'ingestion.viewOriginal' => 'Показать оригинал',
			'ingestion.viewOriginalHint' => 'Текст страницы как есть, без обработки — мгновенно',
			'ingestion.generateStructured' => 'Создать структурированный рецепт',
			'ingestion.generateStructuredHint' => 'Автоматическое извлечение ингредиентов, количеств и шагов',
			'ingestion.originalTitle' => 'Оригинальный рецепт',
			'ingestion.fetchFailed' => 'Не удалось загрузить страницу',
			'ingestion.loadingOriginal' => 'Загружаем страницу...',
			'ingestion.structuredFromSite' => 'Прочитано напрямую из структурированных данных сайта, без AI',
			'ingestion.useStructured' => 'Продолжить со структурированным рецептом',
			'ingestion.preferAi' => 'Обработать через AI',
			'ingestion.analysisTimedOut' => 'Анализ не завершился вовремя',
			'ingestion.analysisFailed' => 'Анализ не удался',
			'ingestion.unparsedHint' => 'Текст сохранён как есть. Попробуйте снова, отредактируйте вручную или сохраните и проанализируйте позже.',
			'ingestion.retryAnalysis' => 'Попробовать снова',
			'ingestion.editManually' => 'Редактировать вручную',
			'ingestion.saveForLater' => 'Сохранить и проанализировать позже',
			'ingestion.untitledRecipe' => 'Рецепт без названия',
			'ingestion.manual' => 'Написать вручную',
			'ingestion.manualHint' => 'Заполните рецепт сами в структурированном формате — без AI и без ожидания.',
			'ingestion.openBlankEditor' => 'Открыть пустой редактор',
			'ingestion.generate' => 'Создать рецепт',
			'ingestion.generating' => 'Пишем ваш рецепт...',
			'mealPlanner.title' => 'Планирование питания',
			'mealPlanner.newPlan' => 'Новое меню',
			'mealPlanner.planName' => 'Название меню',
			'mealPlanner.addMeal' => 'Добавить приём пищи',
			'mealPlanner.mealName' => 'Название приёма пищи',
			'mealPlanner.addItem' => 'Добавить позицию',
			'mealPlanner.pickRecipe' => 'Выбрать рецепт',
			'mealPlanner.quickEntry' => 'Быстрая позиция',
			'mealPlanner.noPlans' => 'Меню пока нет. Создайте первое!',
			'mealPlanner.addMealHint' => 'Выберите рецепт или добавьте быструю позицию',
			'mealPlanner.breakfast' => 'Завтрак',
			'mealPlanner.lunch' => 'Обед',
			'mealPlanner.dinner' => 'Ужин',
			'mealPlanner.morningSnack' => 'Утренний перекус',
			'mealPlanner.afternoonSnack' => 'Дневной перекус',
			'mealPlanner.eveningSnack' => 'Вечерний перекус',
			'mealPlanner.template' => 'Начальный шаблон',
			'mealPlanner.templateFree' => 'Начать с пустого',
			'mealPlanner.templateThree' => '3 приёма пищи',
			'mealPlanner.templateSix' => '6 приёмов пищи',
			'mealPlanner.templateFreeHint' => 'Пустое меню — добавьте приёмы пищи сами',
			'mealPlanner.templateThreeHint' => 'Завтрак, обед и ужин каждый день',
			'mealPlanner.templateSixHint' => '3 основных приёма пищи и перекусы каждый день',
			'mealPlanner.nameRequired' => 'Дайте меню название',
			'mealPlanner.products' => 'Продукты',
			'mealPlanner.addProduct' => 'Добавить продукт',
			'mealPlanner.productName' => 'Название продукта',
			'mealPlanner.noProducts' => 'Без продуктов позиция попадёт в список покупок одной строкой под своим названием',
			'mealPlanner.itemName' => 'Название позиции',
			'mealPlanner.editItem' => 'Изменить позицию',
			'groceryList.title' => 'Список покупок',
			'groceryList.aggregated' => 'Собран из всех активных меню',
			'groceryList.addItem' => 'Новая позиция',
			'groceryList.category' => 'Категория',
			'groceryList.breakdownTitle' => 'Источники количества',
			'groceryList.collectionProgress' => 'Прогресс сбора',
			'groceryList.itemsCollected' => ({required Object collected, required Object total}) => 'Собрано ${collected} из ${total} позиций',
			'groceryList.adjustAmounts' => 'Изменить количество',
			'groceryList.buffer' => 'Дополнительное количество',
			'groceryList.share' => 'Поделиться списком',
			'groceryList.empty' => 'Список сейчас пуст',
			'groceryList.uncheckedSection' => 'Ещё собрать',
			'groceryList.checkedSection' => 'Собрано',
			'groceryList.selectAll' => 'Выбрать всё',
			'groceryList.clearAll' => 'Снять выбор',
			'groceryList.deleteChecked' => 'Удалить собранные',
			'groceryList.amount' => 'Количество',
			'groceryList.unit' => 'Единица',
			'groceryList.lastSource' => 'Должен остаться хотя бы один источник',
			'groceryList.itemName' => 'Название позиции',
			'groceryList.planFilter' => 'Все меню',
			'groceryList.choosePlans' => 'Выбрать меню',
			'groceryList.plansSelected' => ({required Object count}) => 'Выбрано меню: ${count}',
			'groceryList.onePlanSelected' => 'Выбрано одно меню',
			'groceryList.noPlansToPick' => 'Пока нет меню для выбора',
			'groceryList.allPlansHint' => 'Сводка по всем меню',
			'groceryList.selectPlansTitle' => 'Какие меню входят в список?',
			'groceryList.applySelection' => 'Обновить список',
			'groceryList.selectAllPlans' => 'Все меню',
			'unit.gram' => 'г',
			'unit.kilogram' => 'кг',
			'unit.milliliter' => 'мл',
			'unit.liter' => 'л',
			'unit.teaspoon' => 'ч. л.',
			'unit.tablespoon' => 'ст. л.',
			'unit.cup' => 'стакан',
			'unit.unit' => 'шт.',
			'unit.pinch' => 'щепотка',
			'unit.unspecified' => '—',
			'image.add' => 'Добавить фото',
			'image.change' => 'Изменить фото',
			'image.gallery' => 'Выбрать из галереи',
			'image.camera' => 'Сделать фото',
			'image.remove' => 'Удалить фото',
			'image.generate' => 'Создать с помощью ИИ',
			'image.generating' => 'Создаём изображение… это займёт несколько секунд',
			'image.generateFailed' => 'Не удалось создать изображение, попробуйте ещё раз',
			'image.coverTitle' => 'Какую обложку создать?',
			'image.coverHint' => 'Выберите категорию, напишите что-нибудь или и то и другое',
			'image.coverFreeText' => 'Свободный текст, например: бургеры',
			'image.coverRequired' => 'Выберите категорию или напишите что-нибудь',
			'image.coverGenerate' => 'Создать обложку',
			'image.themeKids' => 'Детское',
			'image.themeHealthy' => 'Здоровое',
			'image.themeIndulgent' => 'Вкусное и сытное',
			'image.themeSweets' => 'Сладкое и выпечка',
			'image.themeMeat' => 'Мясо и гриль',
			'image.themeVegan' => 'Веганское',
			'image.themeHolidays' => 'Праздники',
			'image.themeQuick' => 'Быстро и просто',
			'nav.library' => 'Книги',
			'nav.recipes' => 'Рецепты',
			'nav.mealPlan' => 'Меню',
			'nav.groceries' => 'Покупки',
			'nav.settings' => 'Настройки',
			'nav.community' => 'Сообщество',
			'update.forcedTitle' => 'Требуется обновление',
			'update.forcedBody' => ({required Object version}) => 'Эта версия EasyPlate больше не поддерживается. Обновитесь до версии ${version}, чтобы продолжить.',
			'update.optionalTitle' => 'Вышла новая версия',
			'update.optionalBody' => ({required Object version}) => 'EasyPlate ${version} уже в магазине — с последними улучшениями.',
			'update.updateNow' => 'Обновить',
			'update.later' => 'Пропустить',
			'ads.badge' => 'Реклама',
			'ads.freeViewsLeft' => ({required Object count}) => 'На сегодня осталось бесплатных рецептов: ${count}',
			'ads.rewardedViewsLeft' => ({required Object count}) => 'На сегодня осталось открытий за короткое видео: ${count}',
			'ads.sharedQuotaReached' => 'Вы достигли дневного лимита общих рецептов. Завтра он обнулится!',
			'ads.unlockRecipeTitle' => 'Открыть общий рецепт',
			'ads.unlockRecipeMessage' => ({required Object count}) => 'Посмотрите короткое видео, чтобы открыть этот рецепт (осталось на сегодня: ${count})',
			_ => null,
		} ?? switch (path) {
			'ads.aiQuotaLeft' => ({required Object remaining, required Object total}) => 'На сегодня осталось ИИ-извлечений: ${remaining}/${total}',
			'ads.aiQuotaReached' => 'Вы достигли дневного лимита ИИ-извлечений. Завтра снова откроется!',
			'ads.aiLockedHint' => 'Для извлечения по ссылке нужно посмотреть короткое видео',
			'ads.unlockAiTitle' => 'Извлечь рецепт с помощью ИИ',
			'ads.unlockAiMessage' => ({required Object count}) => 'Посмотрите короткое видео, чтобы извлечь рецепт по ссылке (осталось на сегодня: ${count})',
			'ads.watchVideo' => 'Смотреть видео',
			'ads.parseWithVideo' => 'Посмотреть видео и разобрать',
			'ads.blockedForToday' => 'Закрыто на сегодня',
			'ads.loadingVideo' => 'Загрузка видео...',
			'ads.videoNotCompleted' => 'Видео не досмотрено, рецепт остаётся закрытым',
			'ads.videoUnavailable' => 'Сейчас нет доступного видео, попробуйте через минуту',
			'premium.title' => 'EasyPlate Premium',
			'premium.headline' => 'Без рекламы, без ограничений',
			'premium.subtitle' => 'Всё, что умеет EasyPlate, не дожидаясь завтра.',
			'premium.benefitNoAds' => 'Без рекламы в лентах сообщества',
			'premium.benefitShared' => 'Общие рецепты без дневного лимита',
			'premium.benefitAi' => ({required Object count}) => 'Извлечение рецептов с помощью ИИ из любой ссылки, до ${count} в день',
			'premium.periodWeekly' => 'Еженедельно',
			'premium.periodMonthly' => 'Ежемесячно',
			'premium.periodTwoMonth' => 'Раз в 2 месяца',
			'premium.periodThreeMonth' => 'Ежеквартально',
			'premium.periodSixMonth' => 'Раз в 6 месяцев',
			'premium.periodAnnual' => 'Ежегодно',
			'premium.periodLifetime' => 'Навсегда',
			'premium.bestValue' => 'Выгоднее всего',
			'premium.subscribeFor' => ({required Object price}) => 'Оформить за ${price}',
			'premium.buyFor' => ({required Object price}) => 'Купить за ${price}',
			'premium.restore' => 'Восстановить покупки',
			'premium.restored' => 'Подписка восстановлена',
			'premium.nothingToRestore' => 'Покупок для восстановления не найдено',
			'premium.activeTitle' => 'Premium активен',
			'premium.activeBody' => 'Спасибо! Реклама и дневные лимиты отключены для этого аккаунта.',
			'premium.manage' => 'Управление подпиской',
			'premium.cancel' => 'Отменить подписку',
			'premium.cancelNote' => 'Отмена отключает автопродление. Премиум остаётся активным до конца уже оплаченного периода. Возврат средств не производится.',
			'premium.unavailable' => 'Подписки сейчас недоступны. Попробуйте позже.',
			'premium.purchaseFailed' => 'Покупка не завершена',
			'premium.purchased' => 'Добро пожаловать в Premium!',
			'premium.legal' => 'Подписка продлевается автоматически в конце каждого периода, если не отменить её минимум за 24 часа до окончания. Оплата списывается с аккаунта магазина; управлять подпиской или отменить её можно в настройках магазина.',
			'premium.terms' => 'Условия использования',
			'premium.privacy' => 'Политика конфиденциальности',
			'walkthrough.title' => 'Обучение',
			'walkthrough.start' => 'Запустить обучение',
			'walkthrough.startHint' => 'Пошаговая экскурсия по всем возможностям приложения',
			'walkthrough.startFull' => 'Начать полную экскурсию',
			'walkthrough.focused' => 'Показать подсказку по действию',
			'walkthrough.next' => 'Далее',
			'walkthrough.finish' => 'Готово',
			'walkthrough.skipStep' => 'Пропустить шаг',
			'walkthrough.close' => 'Закрыть обучение',
			'walkthrough.stepOf' => ({required Object current, required Object total}) => 'Шаг ${current} из ${total}',
			'walkthrough.tapHint' => 'Нажмите на выделенную область или «Далее»',
			'walkthrough.bookTitle' => 'Справочник EasyPlate',
			'walkthrough.bookSubtitle' => 'Всё, что умеет приложение, глава за главой. Это только справочник: ничего не сохраняется.',
			'walkthrough.contents' => 'Оглавление',
			'walkthrough.chapter' => ({required Object number}) => 'Глава ${number}',
			'walkthrough.backToContents' => 'К оглавлению',
			'walkthrough.stepsTitle' => 'Шаги',
			'walkthrough.welcomeTitle' => 'Добро пожаловать в EasyPlate',
			'walkthrough.welcomeBody' => 'Пройдём вместе по основным действиям. Любой шаг можно пропустить, а обучение закрыть и запустить снова с экрана поддержки.',
			'walkthrough.topics.addRecipe.title' => 'Добавить рецепт',
			'walkthrough.topics.addRecipe.summary' => 'Добавьте рецепт из любого источника, и ИИ приведёт его к единому формату: ингредиенты, количества, шаги и теги.',
			'walkthrough.topics.addRecipe.s1' => 'Нажмите кнопку с искрой рядом с заголовком, чтобы добавить рецепт.',
			'walkthrough.topics.addRecipe.s2' => 'Выберите источник: вставленный текст, поиск в интернете, ссылка на сайт, видео TikTok/Reels, свободный запрос к ИИ или ввод вручную. После разбора проверьте, отредактируйте и сохраните.',
			'walkthrough.topics.myRecipes.title' => 'Мои и сохранённые рецепты',
			'walkthrough.topics.myRecipes.summary' => 'Рецепты, которые вы написали, и сохранённые из сообщества, с поиском и фильтрами по темам.',
			'walkthrough.topics.myRecipes.s1' => 'Здесь переключаются между написанными вами рецептами и сохранёнными из сообщества.',
			'walkthrough.topics.myRecipes.s2' => 'Поиск по названию и фильтр по темам: мясное, молочное, вегетарианское, веганское, кошерное, без глютена и аллергены.',
			'walkthrough.topics.library.title' => 'Книги рецептов',
			'walkthrough.topics.library.summary' => 'Собирайте рецепты в книги с оглавлением, обложкой и перелистыванием.',
			'walkthrough.topics.library.s1' => 'Нажмите «Библиотека», чтобы перейти к книгам.',
			'walkthrough.topics.library.s2' => 'Здесь создают новую книгу. Внутри добавляют рецепты, листают страницы и меняют обложку.',
			'walkthrough.topics.mealPlan.title' => 'Меню на неделю',
			'walkthrough.topics.mealPlan.summary' => 'План приёмов пищи на всю неделю, из которого строится список покупок.',
			'walkthrough.topics.mealPlan.s1' => 'Нажмите «Меню», чтобы спланировать неделю.',
			'walkthrough.topics.mealPlan.s2' => 'Создайте недельный план и расставьте рецепты по дням и приёмам пищи.',
			'walkthrough.topics.groceries.title' => 'Список покупок',
			'walkthrough.topics.groceries.summary' => 'Список, собранный из меню, с отметками о том, что уже куплено.',
			'walkthrough.topics.groceries.s1' => 'Нажмите «Покупки».',
			'walkthrough.topics.groceries.s2' => 'Обновление заново собирает список из всех рецептов недельного меню.',
			'walkthrough.topics.groceries.s3' => 'А здесь добавляют произвольный пункт вручную.',
			'walkthrough.topics.community.title' => 'Сообщество',
			'walkthrough.topics.community.summary' => 'Рецепты, которыми делятся все, и форум вопросов и ответов.',
			'walkthrough.topics.community.s1' => 'Нажмите «Сообщество».',
			'walkthrough.topics.community.s2' => 'Общие рецепты и форум. Ставьте лайки, сохраняйте рецепты себе и прикрепляйте рецепт к ответу на форуме.',
			'walkthrough.topics.community.s3' => 'Кнопка «поделиться» публикует ваш рецепт в сообществе.',
			'walkthrough.topics.account.title' => 'Аккаунт и уведомления',
			'walkthrough.topics.account.summary' => 'Уведомления о приглашениях поделиться и аккаунт с премиумом, настройками и поддержкой.',
			'walkthrough.topics.account.s1' => 'Уведомления: приглашения поделиться рецептами и обновления.',
			'walkthrough.topics.account.s2' => 'Аккаунт: премиум, обмен между аккаунтами, настройки, профиль и поддержка. Оттуда же можно запустить это обучение снова.',
			'walkthrough.demoRecipes' => 'Примеры рецептов',
			'walkthrough.demoRecipesHint' => 'Так выглядят рецепты в приложении. Нажмите на рецепт, чтобы увидеть его страницу целиком: время, темы, аллергены, ингредиенты и шаги.',
			'walkthrough.demoBooks' => 'Примеры книг',
			'walkthrough.demoBooksHint' => 'Так выглядит книга рецептов. Нажмите на книгу, чтобы открыть её, листать страницы и переходить из оглавления.',
			'walkthrough.demoOnly' => 'Только пример, не сохраняется',
			'feedback.title' => 'Сообщить и предложить',
			'feedback.subtitle' => 'Нашли ошибку? Есть идея? Напишите нам здесь; мы читаем каждое сообщение.',
			'feedback.bug' => 'Ошибка',
			'feedback.suggestion' => 'Предложение',
			'feedback.bugHint' => 'Опишите ошибку: что вы сделали, что произошло и чего ожидали...',
			'feedback.suggestionHint' => 'Расскажите, что вы хотели бы видеть в приложении и чем это поможет...',
			'feedback.send' => 'Отправить',
			'feedback.sent' => 'Спасибо! Сообщение отправлено.',
			'feedback.failed' => 'Не удалось отправить, попробуйте позже',
			'feedback.admin' => 'Обращения',
			'feedback.all' => 'Все',
			'feedback.bugs' => 'Ошибки',
			'feedback.suggestions' => 'Предложения',
			'feedback.none' => 'Обращений пока нет',
			'feedback.version' => ({required Object version}) => 'Версия ${version}',
			'feedback.notAllowed' => 'Этот экран только для администратора',
			_ => null,
		};
	}
}
