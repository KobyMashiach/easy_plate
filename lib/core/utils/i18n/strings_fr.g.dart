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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'EasyPlate';
	@override late final _Translations$common$fr common = _Translations$common$fr._(_root);
	@override late final _Translations$auth$fr auth = _Translations$auth$fr._(_root);
	@override late final _Translations$profile$fr profile = _Translations$profile$fr._(_root);
	@override late final _Translations$onboarding$fr onboarding = _Translations$onboarding$fr._(_root);
	@override late final _Translations$dietary$fr dietary = _Translations$dietary$fr._(_root);
	@override late final _Translations$weekday$fr weekday = _Translations$weekday$fr._(_root);
	@override late final _Translations$settings$fr settings = _Translations$settings$fr._(_root);
	@override late final _Translations$more$fr more = _Translations$more$fr._(_root);
	@override late final _Translations$language$fr language = _Translations$language$fr._(_root);
	@override late final _Translations$books$fr books = _Translations$books$fr._(_root);
	@override late final _Translations$recipe$fr recipe = _Translations$recipe$fr._(_root);
	@override late final _Translations$community$fr community = _Translations$community$fr._(_root);
	@override late final _Translations$sharing$fr sharing = _Translations$sharing$fr._(_root);
	@override late final _Translations$notifications$fr notifications = _Translations$notifications$fr._(_root);
	@override late final _Translations$editor$fr editor = _Translations$editor$fr._(_root);
	@override late final _Translations$ingestion$fr ingestion = _Translations$ingestion$fr._(_root);
	@override late final _Translations$mealPlanner$fr mealPlanner = _Translations$mealPlanner$fr._(_root);
	@override late final _Translations$groceryList$fr groceryList = _Translations$groceryList$fr._(_root);
	@override late final _Translations$unit$fr unit = _Translations$unit$fr._(_root);
	@override late final _Translations$image$fr image = _Translations$image$fr._(_root);
	@override late final _Translations$nav$fr nav = _Translations$nav$fr._(_root);
}

// Path: common
class _Translations$common$fr extends Translations$common$he {
	_Translations$common$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get save => 'Enregistrer';
	@override String get cancel => 'Annuler';
	@override String get next => 'Suivant';
	@override String get back => 'Retour';
	@override String get done => 'Terminé';
	@override String get add => 'Ajouter';
	@override String get edit => 'Modifier';
	@override String get delete => 'Supprimer';
	@override String get search => 'Rechercher';
	@override String get retry => 'Réessayer';
	@override String get loading => 'Chargement...';
	@override String get error => 'Une erreur est survenue';
	@override String get or => 'ou';
	@override String get missingInfo => '[information manquante]';
}

// Path: auth
class _Translations$auth$fr extends Translations$auth$he {
	_Translations$auth$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'Bienvenue sur EasyPlate';
	@override String get subtitle => 'Connectez-vous pour garder vos recettes';
	@override String get signIn => 'Se connecter';
	@override String get signUp => 'S\'inscrire';
	@override String get signOut => 'Se déconnecter';
	@override String get email => 'E-mail';
	@override String get emailHint => 'nom@exemple.com';
	@override String get password => 'Mot de passe';
	@override String get passwordHint => 'Au moins 6 caractères';
	@override String get continueWithGoogle => 'Continuer avec Google';
	@override String get continueWithPhone => 'Continuer avec le téléphone';
	@override String get continueWithEmail => 'Continuer avec l\'e-mail';
	@override String get phoneNumber => 'Numéro de téléphone';
	@override String get phoneHint => '+33612345678';
	@override String get sendCode => 'Envoyer le code';
	@override String get smsCode => 'Code SMS';
	@override String codeSentTo({required Object phone}) => 'Nous avons envoyé un code à ${phone}';
	@override String get verify => 'Vérifier';
	@override String get resendCode => 'Renvoyer';
	@override String get forgotPassword => 'Mot de passe oublié';
	@override String get resetSent => 'E-mail de réinitialisation envoyé';
	@override String get noAccount => 'Pas de compte ? Inscrivez-vous';
	@override String get haveAccount => 'Déjà un compte ? Connectez-vous';
	@override String get invalidEmail => 'Adresse e-mail invalide';
	@override String get passwordTooShort => 'Le mot de passe doit faire au moins 6 caractères';
	@override String get invalidPhone => 'Numéro de téléphone invalide';
	@override String get codeRequired => 'Saisissez le code reçu';
	@override String get errorUnauthorized => 'Ces informations sont incorrectes';
	@override String get errorNetwork => 'Pas de connexion Internet';
	@override String get errorUnknown => 'Échec de la connexion, réessayez';
	@override String get signOutTitle => 'Se déconnecter ?';
	@override String get signOutBody => 'Vous devrez vous reconnecter pour accéder à vos recettes.';
	@override String get errorOperationNotAllowed => 'Cette méthode de connexion n\'est pas disponible';
	@override String get errorTooManyRequests => 'Trop de tentatives. Réessayez dans quelques minutes';
	@override String get errorInvalidPhone => 'Ce numéro de téléphone n\'est pas valide';
	@override String get errorEmailInUse => 'Cet e-mail est déjà enregistré';
	@override String get verifyEmailTitle => 'Vérifiez votre e-mail';
	@override String verifyEmailBody({required Object email}) => 'Nous avons envoyé un lien à ${email}. Ouvrez-le puis revenez ici.';
	@override String get resendEmail => 'Renvoyer le lien';
	@override String get emailResent => 'Lien renvoyé';
	@override String get checkVerification => 'J\'ai vérifié';
	@override String get stillNotVerified => 'Pas encore vérifié';
	@override String get linkPhone => 'Vérifier le téléphone';
	@override String get phoneLinked => 'Téléphone vérifié';
	@override String get phoneAlreadyUsed => 'Ce numéro appartient déjà à un autre compte';
	@override String get emailAlreadyLinked => 'Ce compte a déjà un e-mail';
	@override String get addEmailPassword => 'Ajouter e-mail et mot de passe';
	@override String get verified => 'Vérifié';
	@override String get linkGoogle => 'Lier un compte Google';
	@override String get googleLinked => 'Lié';
	@override String get googleAlreadyUsed => 'Ce compte Google appartient déjà à un autre utilisateur';
	@override String get googleAlreadyLinked => 'Un compte Google est déjà lié';
}

// Path: profile
class _Translations$profile$fr extends Translations$profile$he {
	_Translations$profile$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get setupTitle => 'Encore quelques détails';
	@override String get setupSubtitle => 'Pour savoir comment vous appeler';
	@override String get fullName => 'Nom complet';
	@override String get fullNameHint => 'Jean Dupont';
	@override String get fullNameRequired => 'Le nom complet est requis';
	@override String get photo => 'Photo de profil';
	@override String get addPhoto => 'Ajouter une photo';
	@override String get phoneOptional => 'Téléphone (facultatif)';
	@override String get emailOptional => 'E-mail (facultatif)';
	@override String get save => 'Terminer l\'inscription';
	@override String get saving => 'Enregistrement...';
	@override String get saveFailed => 'Impossible d\'enregistrer le profil';
	@override String get myProfile => 'Mon profil';
}

// Path: onboarding
class _Translations$onboarding$fr extends Translations$onboarding$he {
	_Translations$onboarding$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get welcomeTitle => 'Bienvenue sur EasyPlate';
	@override String get welcomeSubtitle => 'Planifiez vos repas, cuisinez et faites vos courses — tout au même endroit';
	@override String get shoppingDayTitle => 'Quel est votre jour de courses hebdomadaire ?';
	@override String get dietaryTitle => 'Quelles sont vos préférences alimentaires ?';
	@override String get dietarySubtitle => 'Vous pouvez en choisir plusieurs';
	@override String get finish => 'C\'est parti';
}

// Path: dietary
class _Translations$dietary$fr extends Translations$dietary$he {
	_Translations$dietary$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get meat => 'Viande';
	@override String get dairy => 'Produits laitiers';
	@override String get vegetarian => 'Végétarien';
	@override String get vegan => 'Végétalien';
	@override String get kosher => 'Casher';
	@override String get glutenFree => 'Sans gluten';
	@override String get allergy => 'Allergie';
}

// Path: weekday
class _Translations$weekday$fr extends Translations$weekday$he {
	_Translations$weekday$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get sunday => 'Dimanche';
	@override String get monday => 'Lundi';
	@override String get tuesday => 'Mardi';
	@override String get wednesday => 'Mercredi';
	@override String get thursday => 'Jeudi';
	@override String get friday => 'Vendredi';
	@override String get saturday => 'Samedi';
}

// Path: settings
class _Translations$settings$fr extends Translations$settings$he {
	_Translations$settings$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get dietaryPreferences => 'Préférences alimentaires';
	@override String get shoppingDay => 'Jour de courses';
	@override String get language => 'Langue';
	@override String get soundEffects => 'Effets sonores (tourner les pages)';
	@override String get fastPageTurn => 'Feuilletage rapide';
	@override String get fastPageTurnHint => 'Un saut depuis la table des matières ou la navigation rapide fait défiler les pages intermédiaires. Désactivez cette option pour arriver directement à la page.';
	@override String get sharedAccess => 'Gérer le partage';
	@override String get noSharedAccess => 'Vous n\'avez encore partagé aucun livre ni aucune liste';
}

// Path: more
class _Translations$more$fr extends Translations$more$he {
	_Translations$more$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Plus';
	@override String get settings => 'Paramètres';
	@override String get profile => 'Mon profil';
	@override String get support => 'Assistance';
	@override String get supportTitle => 'Comment pouvons-nous aider ?';
	@override String get supportBody => 'Écrivez-nous et nous reviendrons vers vous.';
	@override String get whatsapp => 'Nous écrire sur WhatsApp';
	@override String get email => 'Envoyer un e-mail';
	@override String get supportUnavailable => 'Impossible d\'ouvrir cette application';
}

// Path: language
class _Translations$language$fr extends Translations$language$he {
	_Translations$language$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hebrew => 'עברית';
	@override String get english => 'English';
	@override String get arabic => 'العربية';
	@override String get french => 'Français';
	@override String get russian => 'Русский';
}

// Path: books
class _Translations$books$fr extends Translations$books$he {
	_Translations$books$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get myLibrary => 'Ma bibliothèque';
	@override String get myRecipes => 'Mes recettes';
	@override String get librarySubtitle => 'Tous vos livres de recettes au même endroit';
	@override String get recipesSubtitle => 'Recherchez et filtrez toutes les recettes que vous avez collectées';
	@override String get collection => 'Collection';
	@override String recipesCount({required Object count}) => '${count} recettes';
	@override String get newBook => 'Nouveau livre';
	@override String get newBookTitle => 'Nom du livre';
	@override String get tableOfContents => 'Table des matières';
	@override String get emptyLibrary => 'Vous n\'avez encore aucun livre. Créez votre premier !';
	@override String get emptyBook => 'Ce livre est vide. Ajoutez votre première recette';
	@override String get quickNav => 'Navigation rapide';
	@override String get share => 'Partager le livre';
	@override String get viewer => 'Lecteur';
	@override String get editor => 'Éditeur';
	@override String get reorderHint => 'Faites glisser pour réorganiser les recettes';
	@override String get coverImage => 'Photo de couverture';
	@override String get bookOptions => 'Options du livre';
	@override String get renameBook => 'Renommer le livre';
}

// Path: recipe
class _Translations$recipe$fr extends Translations$recipe$he {
	_Translations$recipe$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get prepTime => 'Temps de préparation';
	@override String get cookTime => 'Temps de cuisson';
	@override String get ingredients => 'Ingrédients';
	@override String ingredientsCount({required Object count}) => '${count} ingrédients';
	@override String minutes({required Object count}) => '${count} min';
	@override String hours({required Object count}) => '${count} h';
	@override String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours} h ${minutes} min';
	@override String get instructions => 'Préparation';
	@override String get addToBook => 'Ajouter au livre';
	@override String get removeFromBook => 'Retirer du livre';
	@override String get deleteRecipe => 'Supprimer la recette';
	@override String get photo => 'Photo de la recette';
	@override String get mine => 'Mes recettes';
	@override String get saved => 'Recettes enregistrées';
	@override String get noneMine => 'Vous n\'avez pas encore créé de recette';
	@override String get noneSaved => 'Vous n\'avez encore rien enregistré';
	@override String get pendingAnalysis => 'En attente d\'analyse';
	@override String get pendingAnalysisHint => 'Enregistrée en texte brut. Analysez-la maintenant ou modifiez-la à la main.';
	@override String get analyzeNow => 'Analyser avec l\'IA maintenant';
	@override String get analyzing => 'Analyse de la recette...';
	@override String get analyzeFailed => 'L\'analyse a échoué — réessayez plus tard';
}

// Path: community
class _Translations$community$fr extends Translations$community$he {
	_Translations$community$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Communauté';
	@override String get forum => 'Forum';
	@override String get sharedRecipes => 'Recettes partagées';
	@override String get newPost => 'Nouveau message';
	@override String get postTitle => 'Titre';
	@override String get postBody => 'Que voulez-vous demander ou partager ?';
	@override String get postTitleRequired => 'Un titre est requis';
	@override String get postBodyRequired => 'Un contenu est requis';
	@override String get publish => 'Publier';
	@override String replies({required Object count}) => '${count} réponses';
	@override String get noReplies => 'Aucune réponse pour l\'instant';
	@override String get oneReply => 'Une réponse';
	@override String get writeReply => 'Écrire une réponse...';
	@override String get send => 'Envoyer';
	@override String get noPosts => 'Aucun message. Soyez le premier !';
	@override String get noSharedRecipes => 'Aucune recette partagée. Partagez la première !';
	@override String get shareRecipe => 'Partager une recette';
	@override String get pickRecipeToShare => 'Quelle recette partager ?';
	@override String get saveToMyRecipes => 'Enregistrer dans mes recettes';
	@override String get savedToMyRecipes => 'Recette enregistrée';
	@override String get deletePost => 'Supprimer le message';
	@override String get deletePostConfirm => 'Le message et ses réponses seront supprimés définitivement.';
	@override String get unshare => 'Retirer du fil';
	@override String get unshareConfirm => 'La recette sera retirée du fil partagé.';
	@override String byAuthor({required Object name}) => 'par ${name}';
	@override String get loadFailed => 'Impossible de charger le contenu';
	@override String get allRecipes => 'Toutes les recettes';
	@override String get myRecipes => 'Mes recettes';
	@override String get editShared => 'Modifier la recette partagée';
	@override String get sharedUpdated => 'Recette mise à jour';
	@override String get noneOfMine => 'Vous n\'avez encore rien partagé';
	@override String get search => 'Recherche';
	@override String get searchHint => 'Nom de recette ou d\'auteur';
	@override String get savedOnly => 'Enregistrées';
	@override String get noResults => 'Aucun résultat';
	@override String get attachRecipe => 'Joindre une recette';
	@override String get openRecipe => 'Ouvrir la recette';
	@override String get recipeUnavailable => 'Cette recette n\'est plus disponible';
	@override String get sortAndFilter => 'Trier et filtrer';
	@override String get sort => 'Tri';
	@override String get sortNewest => 'Plus récentes';
	@override String get sortOldest => 'Plus anciennes';
	@override String get sortMostLiked => 'Plus aimées';
	@override String get topics => 'Thèmes';
	@override String get likes => 'J\'aime';
	@override String get anyLikes => 'Peu importe';
	@override String atLeastLikes({required Object count}) => '${count} et plus';
	@override String get totalTime => 'Temps total';
	@override String get anyTime => 'Toute durée';
	@override String upTo({required Object duration}) => 'Jusqu\'à ${duration}';
	@override String get clearFilters => 'Effacer les filtres';
	@override String get applyFilters => 'Voir les résultats';
	@override String likesPlus({required Object count}) => '${count}+';
	@override String durationPlus({required Object duration}) => '${duration}+';
	@override String get splitTimes => 'Séparer préparation et cuisson';
}

// Path: sharing
class _Translations$sharing$fr extends Translations$sharing$he {
	_Translations$sharing$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Partager la recette';
	@override String get contactLabel => 'E-mail ou téléphone de la personne';
	@override String get contactHint => 'nom@exemple.com ou 05…';
	@override String get roleTitle => 'Autorisation';
	@override String get roleViewer => 'Lecture seule';
	@override String get roleViewerHint => 'Voit la recette sans pouvoir la modifier';
	@override String get roleEditor => 'Modification';
	@override String get roleEditorHint => 'Ses modifications apparaissent aussi chez vous';
	@override String get send => 'Envoyer l\'invitation';
	@override String get sent => 'Invitation envoyée';
	@override String get invalidContact => 'Saisissez un e-mail ou un téléphone valide';
	@override String get notFound => 'Aucun compte avec ces informations';
	@override String get self => 'Impossible de partager une recette avec vous-même';
	@override String get failed => 'Le partage a échoué, réessayez';
	@override String get pendingInvites => 'Invitations en attente';
	@override String get noPendingInvites => 'Aucune invitation en attente';
	@override String get sharedByMe => 'Recettes partagées par moi';
	@override String get sharedWithMe => 'Recettes partagées avec moi';
	@override String get nothingSharedByMe => 'Vous n\'avez encore rien partagé';
	@override String get nothingSharedWithMe => 'Aucune recette ne vous a été partagée';
	@override String get accept => 'Accepter';
	@override String get decline => 'Refuser';
	@override String get accepted => 'La recette a été ajoutée à vos recettes';
	@override String get declined => 'Invitation refusée';
	@override String get acceptFailed => 'L\'acceptation a échoué, réessayez';
	@override String get members => 'Membres';
	@override String get noMembersYet => 'Personne n\'a encore accepté';
	@override String get remove => 'Retirer';
	@override String get leave => 'Quitter';
	@override String get removed => 'Membre retiré';
	@override String get left => 'Vous avez quitté le partage';
	@override String invitedBy({required Object name}) => 'de ${name}';
	@override String get sharedTag => 'Partagée';
	@override String get viewerTag => 'Lecture seule';
	@override String get editorTag => 'Éditeur';
	@override String get ownerTag => 'Propriétaire';
	@override String get syncFailed => 'Impossible d\'actualiser la recette partagée, version enregistrée affichée';
	@override String get viewerCannotEdit => 'Cette recette vous est partagée en lecture seule';
	@override String get shareAction => 'Partager';
}

// Path: notifications
class _Translations$notifications$fr extends Translations$notifications$he {
	_Translations$notifications$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Notifications';
	@override String get empty => 'Aucune notification';
	@override String sharedRecipe({required Object name, required Object recipe}) => '${name} a partagé « ${recipe} » avec vous';
	@override String get asViewer => 'en lecture seule';
	@override String get asEditor => 'en modification';
	@override String get markAllRead => 'Tout marquer comme lu';
	@override String get openRecipe => 'Ouvrir la recette';
	@override String get alreadyHandled => 'Cette invitation a déjà été traitée';
}

// Path: editor
class _Translations$editor$fr extends Translations$editor$he {
	_Translations$editor$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Modifier la recette';
	@override String get recipeTitle => 'Nom de la recette';
	@override String get titleHint => 'Par exemple : shakshuka de Jérusalem';
	@override String get topics => 'Thèmes';
	@override String get titleRequired => 'Un nom de recette est requis';
	@override String get prepMinutes => 'Préparation (min)';
	@override String get cookMinutes => 'Cuisson (min)';
	@override String get amount => 'Quantité';
	@override String get unit => 'Unité';
	@override String get ingredientName => 'Nom de l\'ingrédient';
	@override String get stepHint => 'Décrivez l\'étape';
	@override String get addIngredient => 'Ajouter un ingrédient';
	@override String get addStep => 'Ajouter une étape';
	@override String get removeIngredient => 'Retirer l\'ingrédient';
	@override String get removeStep => 'Retirer l\'étape';
	@override String get reorderStep => 'Réordonner l\'étape';
	@override String get fixSpelling => 'Corriger l\'orthographe';
	@override String get refining => 'Correction de la recette...';
	@override String get refineError => 'Impossible de corriger la recette';
	@override String get spellingFixed => 'Recette corrigée';
	@override String get noChanges => 'Aucune faute d\'orthographe trouvée';
	@override String get timesSynced => 'Les durées des étapes ont été mises à jour';
	@override String get discardTitle => 'Abandonner les modifications ?';
	@override String get discardBody => 'Vos modifications ne seront pas enregistrées.';
	@override String get discard => 'Abandonner';
	@override String get saveOptionsTitle => 'Comment enregistrer ?';
	@override String get savePlainHint => 'Enregistrer tel quel, sans attendre';
	@override String get saveWithAi => 'Enregistrer avec relecture IA';
	@override String get saveWithAiHint => 'Corriger l\'orthographe et aligner les durées des étapes';
}

// Path: ingestion
class _Translations$ingestion$fr extends Translations$ingestion$he {
	_Translations$ingestion$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ajouter une recette';
	@override String get pasteText => 'Coller du texte';
	@override String get pasteHint => 'Collez ici une recette venant de WhatsApp ou de toute autre source';
	@override String get webSearch => 'Rechercher sur le web';
	@override String get urlScrape => 'Lien vers un site';
	@override String get socialVideo => 'TikTok / Reels';
	@override String get parse => 'Analyser la recette';
	@override String get parsing => 'Analyse de la recette...';
	@override String get parseError => 'Nous n\'avons pas pu analyser la recette';
	@override String get reviewTitle => 'Vérifiez avant d\'enregistrer';
	@override String get notConfigured => 'Cette fonctionnalité nécessite un service externe qui n\'est pas encore configuré';
	@override String get openOptionsTitle => 'Comment ouvrir cette recette ?';
	@override String get viewOriginal => 'Voir l\'original';
	@override String get viewOriginalHint => 'Le texte de la page tel quel, sans traitement — immédiat';
	@override String get generateStructured => 'Créer une recette structurée';
	@override String get generateStructuredHint => 'Extraction automatique des ingrédients, quantités et étapes';
	@override String get originalTitle => 'Recette originale';
	@override String get fetchFailed => 'Impossible de charger la page';
	@override String get loadingOriginal => 'Chargement de la page...';
	@override String get structuredFromSite => 'Lue directement depuis les données structurées du site, sans IA';
	@override String get useStructured => 'Continuer avec la recette structurée';
	@override String get preferAi => 'Traiter avec l\'IA à la place';
	@override String get analysisTimedOut => 'L\'analyse n\'a pas abouti à temps';
	@override String get analysisFailed => 'L\'analyse a échoué';
	@override String get unparsedHint => 'Votre texte est conservé tel quel. Réessayez, modifiez-le à la main, ou enregistrez-le pour l\'analyser plus tard.';
	@override String get retryAnalysis => 'Réessayer';
	@override String get editManually => 'Modifier manuellement';
	@override String get saveForLater => 'Enregistrer et analyser plus tard';
	@override String get untitledRecipe => 'Recette sans titre';
	@override String get manual => 'Saisie manuelle';
	@override String get manualHint => 'Remplissez la recette vous-même, au format structuré — sans IA, sans attente.';
	@override String get openBlankEditor => 'Ouvrir un éditeur vide';
}

// Path: mealPlanner
class _Translations$mealPlanner$fr extends Translations$mealPlanner$he {
	_Translations$mealPlanner$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planification des repas';
	@override String get newPlan => 'Nouveau menu';
	@override String get planName => 'Nom du menu';
	@override String get addMeal => 'Ajouter un repas';
	@override String get mealName => 'Nom du repas';
	@override String get addItem => 'Ajouter un élément';
	@override String get pickRecipe => 'Choisir une recette';
	@override String get quickEntry => 'Élément rapide';
	@override String get noPlans => 'Aucun menu pour l\'instant. Créez votre premier !';
	@override String get addMealHint => 'Choisissez une recette ou ajoutez un élément rapide';
	@override String get breakfast => 'Petit-déjeuner';
	@override String get lunch => 'Déjeuner';
	@override String get dinner => 'Dîner';
	@override String get morningSnack => 'Collation du matin';
	@override String get afternoonSnack => 'Collation de l\'après-midi';
	@override String get eveningSnack => 'Collation du soir';
	@override String get template => 'Modèle de départ';
	@override String get templateFree => 'Commencer à vide';
	@override String get templateThree => '3 repas';
	@override String get templateSix => '6 repas';
	@override String get templateFreeHint => 'Un menu vide — ajoutez les repas vous-même';
	@override String get templateThreeHint => 'Petit-déjeuner, déjeuner et dîner chaque jour';
	@override String get templateSixHint => '3 repas principaux et des collations chaque jour';
	@override String get nameRequired => 'Donnez un nom au menu';
	@override String get products => 'Produits';
	@override String get addProduct => 'Ajouter un produit';
	@override String get productName => 'Nom du produit';
	@override String get noProducts => 'Sans produits, l\'élément rejoint la liste de courses comme une seule ligne à son nom';
	@override String get itemName => 'Nom de l\'élément';
	@override String get editItem => 'Modifier l\'élément';
}

// Path: groceryList
class _Translations$groceryList$fr extends Translations$groceryList$he {
	_Translations$groceryList$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Liste de courses';
	@override String get aggregated => 'Regroupée à partir de tous les menus actifs';
	@override String get addItem => 'Nouvel élément';
	@override String get category => 'Catégorie';
	@override String get breakdownTitle => 'Origine des quantités';
	@override String get collectionProgress => 'Progression de la collecte';
	@override String itemsCollected({required Object collected, required Object total}) => '${collected} sur ${total} articles collectés';
	@override String get adjustAmounts => 'Ajuster les quantités';
	@override String get buffer => 'Quantité supplémentaire';
	@override String get share => 'Partager la liste';
	@override String get empty => 'La liste est vide pour le moment';
	@override String get uncheckedSection => 'À collecter';
	@override String get checkedSection => 'Collectés';
	@override String get selectAll => 'Tout sélectionner';
	@override String get clearAll => 'Tout désélectionner';
	@override String get deleteChecked => 'Supprimer les collectés';
	@override String get amount => 'Quantité';
	@override String get unit => 'Unité';
	@override String get lastSource => 'Au moins une source doit rester';
	@override String get itemName => 'Nom de l\'article';
	@override String get planFilter => 'Tous les menus';
	@override String get choosePlans => 'Choisir les menus';
	@override String plansSelected({required Object count}) => '${count} menus sélectionnés';
	@override String get onePlanSelected => 'Un menu sélectionné';
	@override String get noPlansToPick => 'Aucun menu à choisir pour l\'instant';
	@override String get allPlansHint => 'Agrégé depuis tous les menus';
	@override String get selectPlansTitle => 'Quels menus alimentent cette liste ?';
	@override String get applySelection => 'Mettre à jour';
	@override String get selectAllPlans => 'Tous les menus';
}

// Path: unit
class _Translations$unit$fr extends Translations$unit$he {
	_Translations$unit$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get gram => 'g';
	@override String get kilogram => 'kg';
	@override String get milliliter => 'ml';
	@override String get liter => 'L';
	@override String get teaspoon => 'c. à c.';
	@override String get tablespoon => 'c. à s.';
	@override String get cup => 'tasse';
	@override String get unit => 'unité';
	@override String get pinch => 'pincée';
	@override String get unspecified => '—';
}

// Path: image
class _Translations$image$fr extends Translations$image$he {
	_Translations$image$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get add => 'Ajouter une photo';
	@override String get change => 'Changer la photo';
	@override String get gallery => 'Choisir dans la galerie';
	@override String get camera => 'Prendre une photo';
	@override String get remove => 'Supprimer la photo';
}

// Path: nav
class _Translations$nav$fr extends Translations$nav$he {
	_Translations$nav$fr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get library => 'Livres';
	@override String get recipes => 'Recettes';
	@override String get mealPlan => 'Repas';
	@override String get groceries => 'Courses';
	@override String get settings => 'Réglages';
	@override String get community => 'Communauté';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'EasyPlate',
			'common.save' => 'Enregistrer',
			'common.cancel' => 'Annuler',
			'common.next' => 'Suivant',
			'common.back' => 'Retour',
			'common.done' => 'Terminé',
			'common.add' => 'Ajouter',
			'common.edit' => 'Modifier',
			'common.delete' => 'Supprimer',
			'common.search' => 'Rechercher',
			'common.retry' => 'Réessayer',
			'common.loading' => 'Chargement...',
			'common.error' => 'Une erreur est survenue',
			'common.or' => 'ou',
			'common.missingInfo' => '[information manquante]',
			'auth.welcome' => 'Bienvenue sur EasyPlate',
			'auth.subtitle' => 'Connectez-vous pour garder vos recettes',
			'auth.signIn' => 'Se connecter',
			'auth.signUp' => 'S\'inscrire',
			'auth.signOut' => 'Se déconnecter',
			'auth.email' => 'E-mail',
			'auth.emailHint' => 'nom@exemple.com',
			'auth.password' => 'Mot de passe',
			'auth.passwordHint' => 'Au moins 6 caractères',
			'auth.continueWithGoogle' => 'Continuer avec Google',
			'auth.continueWithPhone' => 'Continuer avec le téléphone',
			'auth.continueWithEmail' => 'Continuer avec l\'e-mail',
			'auth.phoneNumber' => 'Numéro de téléphone',
			'auth.phoneHint' => '+33612345678',
			'auth.sendCode' => 'Envoyer le code',
			'auth.smsCode' => 'Code SMS',
			'auth.codeSentTo' => ({required Object phone}) => 'Nous avons envoyé un code à ${phone}',
			'auth.verify' => 'Vérifier',
			'auth.resendCode' => 'Renvoyer',
			'auth.forgotPassword' => 'Mot de passe oublié',
			'auth.resetSent' => 'E-mail de réinitialisation envoyé',
			'auth.noAccount' => 'Pas de compte ? Inscrivez-vous',
			'auth.haveAccount' => 'Déjà un compte ? Connectez-vous',
			'auth.invalidEmail' => 'Adresse e-mail invalide',
			'auth.passwordTooShort' => 'Le mot de passe doit faire au moins 6 caractères',
			'auth.invalidPhone' => 'Numéro de téléphone invalide',
			'auth.codeRequired' => 'Saisissez le code reçu',
			'auth.errorUnauthorized' => 'Ces informations sont incorrectes',
			'auth.errorNetwork' => 'Pas de connexion Internet',
			'auth.errorUnknown' => 'Échec de la connexion, réessayez',
			'auth.signOutTitle' => 'Se déconnecter ?',
			'auth.signOutBody' => 'Vous devrez vous reconnecter pour accéder à vos recettes.',
			'auth.errorOperationNotAllowed' => 'Cette méthode de connexion n\'est pas disponible',
			'auth.errorTooManyRequests' => 'Trop de tentatives. Réessayez dans quelques minutes',
			'auth.errorInvalidPhone' => 'Ce numéro de téléphone n\'est pas valide',
			'auth.errorEmailInUse' => 'Cet e-mail est déjà enregistré',
			'auth.verifyEmailTitle' => 'Vérifiez votre e-mail',
			'auth.verifyEmailBody' => ({required Object email}) => 'Nous avons envoyé un lien à ${email}. Ouvrez-le puis revenez ici.',
			'auth.resendEmail' => 'Renvoyer le lien',
			'auth.emailResent' => 'Lien renvoyé',
			'auth.checkVerification' => 'J\'ai vérifié',
			'auth.stillNotVerified' => 'Pas encore vérifié',
			'auth.linkPhone' => 'Vérifier le téléphone',
			'auth.phoneLinked' => 'Téléphone vérifié',
			'auth.phoneAlreadyUsed' => 'Ce numéro appartient déjà à un autre compte',
			'auth.emailAlreadyLinked' => 'Ce compte a déjà un e-mail',
			'auth.addEmailPassword' => 'Ajouter e-mail et mot de passe',
			'auth.verified' => 'Vérifié',
			'auth.linkGoogle' => 'Lier un compte Google',
			'auth.googleLinked' => 'Lié',
			'auth.googleAlreadyUsed' => 'Ce compte Google appartient déjà à un autre utilisateur',
			'auth.googleAlreadyLinked' => 'Un compte Google est déjà lié',
			'profile.setupTitle' => 'Encore quelques détails',
			'profile.setupSubtitle' => 'Pour savoir comment vous appeler',
			'profile.fullName' => 'Nom complet',
			'profile.fullNameHint' => 'Jean Dupont',
			'profile.fullNameRequired' => 'Le nom complet est requis',
			'profile.photo' => 'Photo de profil',
			'profile.addPhoto' => 'Ajouter une photo',
			'profile.phoneOptional' => 'Téléphone (facultatif)',
			'profile.emailOptional' => 'E-mail (facultatif)',
			'profile.save' => 'Terminer l\'inscription',
			'profile.saving' => 'Enregistrement...',
			'profile.saveFailed' => 'Impossible d\'enregistrer le profil',
			'profile.myProfile' => 'Mon profil',
			'onboarding.welcomeTitle' => 'Bienvenue sur EasyPlate',
			'onboarding.welcomeSubtitle' => 'Planifiez vos repas, cuisinez et faites vos courses — tout au même endroit',
			'onboarding.shoppingDayTitle' => 'Quel est votre jour de courses hebdomadaire ?',
			'onboarding.dietaryTitle' => 'Quelles sont vos préférences alimentaires ?',
			'onboarding.dietarySubtitle' => 'Vous pouvez en choisir plusieurs',
			'onboarding.finish' => 'C\'est parti',
			'dietary.meat' => 'Viande',
			'dietary.dairy' => 'Produits laitiers',
			'dietary.vegetarian' => 'Végétarien',
			'dietary.vegan' => 'Végétalien',
			'dietary.kosher' => 'Casher',
			'dietary.glutenFree' => 'Sans gluten',
			'dietary.allergy' => 'Allergie',
			'weekday.sunday' => 'Dimanche',
			'weekday.monday' => 'Lundi',
			'weekday.tuesday' => 'Mardi',
			'weekday.wednesday' => 'Mercredi',
			'weekday.thursday' => 'Jeudi',
			'weekday.friday' => 'Vendredi',
			'weekday.saturday' => 'Samedi',
			'settings.title' => 'Paramètres',
			'settings.dietaryPreferences' => 'Préférences alimentaires',
			'settings.shoppingDay' => 'Jour de courses',
			'settings.language' => 'Langue',
			'settings.soundEffects' => 'Effets sonores (tourner les pages)',
			'settings.fastPageTurn' => 'Feuilletage rapide',
			'settings.fastPageTurnHint' => 'Un saut depuis la table des matières ou la navigation rapide fait défiler les pages intermédiaires. Désactivez cette option pour arriver directement à la page.',
			'settings.sharedAccess' => 'Gérer le partage',
			'settings.noSharedAccess' => 'Vous n\'avez encore partagé aucun livre ni aucune liste',
			'more.title' => 'Plus',
			'more.settings' => 'Paramètres',
			'more.profile' => 'Mon profil',
			'more.support' => 'Assistance',
			'more.supportTitle' => 'Comment pouvons-nous aider ?',
			'more.supportBody' => 'Écrivez-nous et nous reviendrons vers vous.',
			'more.whatsapp' => 'Nous écrire sur WhatsApp',
			'more.email' => 'Envoyer un e-mail',
			'more.supportUnavailable' => 'Impossible d\'ouvrir cette application',
			'language.hebrew' => 'עברית',
			'language.english' => 'English',
			'language.arabic' => 'العربية',
			'language.french' => 'Français',
			'language.russian' => 'Русский',
			'books.myLibrary' => 'Ma bibliothèque',
			'books.myRecipes' => 'Mes recettes',
			'books.librarySubtitle' => 'Tous vos livres de recettes au même endroit',
			'books.recipesSubtitle' => 'Recherchez et filtrez toutes les recettes que vous avez collectées',
			'books.collection' => 'Collection',
			'books.recipesCount' => ({required Object count}) => '${count} recettes',
			'books.newBook' => 'Nouveau livre',
			'books.newBookTitle' => 'Nom du livre',
			'books.tableOfContents' => 'Table des matières',
			'books.emptyLibrary' => 'Vous n\'avez encore aucun livre. Créez votre premier !',
			'books.emptyBook' => 'Ce livre est vide. Ajoutez votre première recette',
			'books.quickNav' => 'Navigation rapide',
			'books.share' => 'Partager le livre',
			'books.viewer' => 'Lecteur',
			'books.editor' => 'Éditeur',
			'books.reorderHint' => 'Faites glisser pour réorganiser les recettes',
			'books.coverImage' => 'Photo de couverture',
			'books.bookOptions' => 'Options du livre',
			'books.renameBook' => 'Renommer le livre',
			'recipe.prepTime' => 'Temps de préparation',
			'recipe.cookTime' => 'Temps de cuisson',
			'recipe.ingredients' => 'Ingrédients',
			'recipe.ingredientsCount' => ({required Object count}) => '${count} ingrédients',
			'recipe.minutes' => ({required Object count}) => '${count} min',
			'recipe.hours' => ({required Object count}) => '${count} h',
			'recipe.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours} h ${minutes} min',
			'recipe.instructions' => 'Préparation',
			'recipe.addToBook' => 'Ajouter au livre',
			'recipe.removeFromBook' => 'Retirer du livre',
			'recipe.deleteRecipe' => 'Supprimer la recette',
			'recipe.photo' => 'Photo de la recette',
			'recipe.mine' => 'Mes recettes',
			'recipe.saved' => 'Recettes enregistrées',
			'recipe.noneMine' => 'Vous n\'avez pas encore créé de recette',
			'recipe.noneSaved' => 'Vous n\'avez encore rien enregistré',
			'recipe.pendingAnalysis' => 'En attente d\'analyse',
			'recipe.pendingAnalysisHint' => 'Enregistrée en texte brut. Analysez-la maintenant ou modifiez-la à la main.',
			'recipe.analyzeNow' => 'Analyser avec l\'IA maintenant',
			'recipe.analyzing' => 'Analyse de la recette...',
			'recipe.analyzeFailed' => 'L\'analyse a échoué — réessayez plus tard',
			'community.title' => 'Communauté',
			'community.forum' => 'Forum',
			'community.sharedRecipes' => 'Recettes partagées',
			'community.newPost' => 'Nouveau message',
			'community.postTitle' => 'Titre',
			'community.postBody' => 'Que voulez-vous demander ou partager ?',
			'community.postTitleRequired' => 'Un titre est requis',
			'community.postBodyRequired' => 'Un contenu est requis',
			'community.publish' => 'Publier',
			'community.replies' => ({required Object count}) => '${count} réponses',
			'community.noReplies' => 'Aucune réponse pour l\'instant',
			'community.oneReply' => 'Une réponse',
			'community.writeReply' => 'Écrire une réponse...',
			'community.send' => 'Envoyer',
			'community.noPosts' => 'Aucun message. Soyez le premier !',
			'community.noSharedRecipes' => 'Aucune recette partagée. Partagez la première !',
			'community.shareRecipe' => 'Partager une recette',
			'community.pickRecipeToShare' => 'Quelle recette partager ?',
			'community.saveToMyRecipes' => 'Enregistrer dans mes recettes',
			'community.savedToMyRecipes' => 'Recette enregistrée',
			'community.deletePost' => 'Supprimer le message',
			'community.deletePostConfirm' => 'Le message et ses réponses seront supprimés définitivement.',
			'community.unshare' => 'Retirer du fil',
			'community.unshareConfirm' => 'La recette sera retirée du fil partagé.',
			'community.byAuthor' => ({required Object name}) => 'par ${name}',
			'community.loadFailed' => 'Impossible de charger le contenu',
			'community.allRecipes' => 'Toutes les recettes',
			'community.myRecipes' => 'Mes recettes',
			'community.editShared' => 'Modifier la recette partagée',
			'community.sharedUpdated' => 'Recette mise à jour',
			'community.noneOfMine' => 'Vous n\'avez encore rien partagé',
			'community.search' => 'Recherche',
			'community.searchHint' => 'Nom de recette ou d\'auteur',
			'community.savedOnly' => 'Enregistrées',
			'community.noResults' => 'Aucun résultat',
			'community.attachRecipe' => 'Joindre une recette',
			'community.openRecipe' => 'Ouvrir la recette',
			'community.recipeUnavailable' => 'Cette recette n\'est plus disponible',
			'community.sortAndFilter' => 'Trier et filtrer',
			'community.sort' => 'Tri',
			'community.sortNewest' => 'Plus récentes',
			'community.sortOldest' => 'Plus anciennes',
			'community.sortMostLiked' => 'Plus aimées',
			'community.topics' => 'Thèmes',
			'community.likes' => 'J\'aime',
			'community.anyLikes' => 'Peu importe',
			'community.atLeastLikes' => ({required Object count}) => '${count} et plus',
			'community.totalTime' => 'Temps total',
			'community.anyTime' => 'Toute durée',
			'community.upTo' => ({required Object duration}) => 'Jusqu\'à ${duration}',
			'community.clearFilters' => 'Effacer les filtres',
			'community.applyFilters' => 'Voir les résultats',
			'community.likesPlus' => ({required Object count}) => '${count}+',
			'community.durationPlus' => ({required Object duration}) => '${duration}+',
			'community.splitTimes' => 'Séparer préparation et cuisson',
			'sharing.title' => 'Partager la recette',
			'sharing.contactLabel' => 'E-mail ou téléphone de la personne',
			'sharing.contactHint' => 'nom@exemple.com ou 05…',
			'sharing.roleTitle' => 'Autorisation',
			'sharing.roleViewer' => 'Lecture seule',
			'sharing.roleViewerHint' => 'Voit la recette sans pouvoir la modifier',
			'sharing.roleEditor' => 'Modification',
			'sharing.roleEditorHint' => 'Ses modifications apparaissent aussi chez vous',
			'sharing.send' => 'Envoyer l\'invitation',
			'sharing.sent' => 'Invitation envoyée',
			'sharing.invalidContact' => 'Saisissez un e-mail ou un téléphone valide',
			'sharing.notFound' => 'Aucun compte avec ces informations',
			'sharing.self' => 'Impossible de partager une recette avec vous-même',
			'sharing.failed' => 'Le partage a échoué, réessayez',
			'sharing.pendingInvites' => 'Invitations en attente',
			'sharing.noPendingInvites' => 'Aucune invitation en attente',
			'sharing.sharedByMe' => 'Recettes partagées par moi',
			'sharing.sharedWithMe' => 'Recettes partagées avec moi',
			'sharing.nothingSharedByMe' => 'Vous n\'avez encore rien partagé',
			'sharing.nothingSharedWithMe' => 'Aucune recette ne vous a été partagée',
			'sharing.accept' => 'Accepter',
			'sharing.decline' => 'Refuser',
			'sharing.accepted' => 'La recette a été ajoutée à vos recettes',
			'sharing.declined' => 'Invitation refusée',
			'sharing.acceptFailed' => 'L\'acceptation a échoué, réessayez',
			'sharing.members' => 'Membres',
			'sharing.noMembersYet' => 'Personne n\'a encore accepté',
			'sharing.remove' => 'Retirer',
			'sharing.leave' => 'Quitter',
			'sharing.removed' => 'Membre retiré',
			'sharing.left' => 'Vous avez quitté le partage',
			'sharing.invitedBy' => ({required Object name}) => 'de ${name}',
			'sharing.sharedTag' => 'Partagée',
			'sharing.viewerTag' => 'Lecture seule',
			'sharing.editorTag' => 'Éditeur',
			'sharing.ownerTag' => 'Propriétaire',
			'sharing.syncFailed' => 'Impossible d\'actualiser la recette partagée, version enregistrée affichée',
			'sharing.viewerCannotEdit' => 'Cette recette vous est partagée en lecture seule',
			'sharing.shareAction' => 'Partager',
			'notifications.title' => 'Notifications',
			'notifications.empty' => 'Aucune notification',
			'notifications.sharedRecipe' => ({required Object name, required Object recipe}) => '${name} a partagé « ${recipe} » avec vous',
			'notifications.asViewer' => 'en lecture seule',
			'notifications.asEditor' => 'en modification',
			'notifications.markAllRead' => 'Tout marquer comme lu',
			'notifications.openRecipe' => 'Ouvrir la recette',
			'notifications.alreadyHandled' => 'Cette invitation a déjà été traitée',
			'editor.title' => 'Modifier la recette',
			'editor.recipeTitle' => 'Nom de la recette',
			'editor.titleHint' => 'Par exemple : shakshuka de Jérusalem',
			'editor.topics' => 'Thèmes',
			'editor.titleRequired' => 'Un nom de recette est requis',
			'editor.prepMinutes' => 'Préparation (min)',
			'editor.cookMinutes' => 'Cuisson (min)',
			'editor.amount' => 'Quantité',
			'editor.unit' => 'Unité',
			'editor.ingredientName' => 'Nom de l\'ingrédient',
			'editor.stepHint' => 'Décrivez l\'étape',
			'editor.addIngredient' => 'Ajouter un ingrédient',
			'editor.addStep' => 'Ajouter une étape',
			'editor.removeIngredient' => 'Retirer l\'ingrédient',
			'editor.removeStep' => 'Retirer l\'étape',
			'editor.reorderStep' => 'Réordonner l\'étape',
			'editor.fixSpelling' => 'Corriger l\'orthographe',
			'editor.refining' => 'Correction de la recette...',
			'editor.refineError' => 'Impossible de corriger la recette',
			'editor.spellingFixed' => 'Recette corrigée',
			'editor.noChanges' => 'Aucune faute d\'orthographe trouvée',
			'editor.timesSynced' => 'Les durées des étapes ont été mises à jour',
			'editor.discardTitle' => 'Abandonner les modifications ?',
			'editor.discardBody' => 'Vos modifications ne seront pas enregistrées.',
			'editor.discard' => 'Abandonner',
			'editor.saveOptionsTitle' => 'Comment enregistrer ?',
			'editor.savePlainHint' => 'Enregistrer tel quel, sans attendre',
			'editor.saveWithAi' => 'Enregistrer avec relecture IA',
			'editor.saveWithAiHint' => 'Corriger l\'orthographe et aligner les durées des étapes',
			'ingestion.title' => 'Ajouter une recette',
			'ingestion.pasteText' => 'Coller du texte',
			'ingestion.pasteHint' => 'Collez ici une recette venant de WhatsApp ou de toute autre source',
			'ingestion.webSearch' => 'Rechercher sur le web',
			'ingestion.urlScrape' => 'Lien vers un site',
			'ingestion.socialVideo' => 'TikTok / Reels',
			'ingestion.parse' => 'Analyser la recette',
			'ingestion.parsing' => 'Analyse de la recette...',
			'ingestion.parseError' => 'Nous n\'avons pas pu analyser la recette',
			'ingestion.reviewTitle' => 'Vérifiez avant d\'enregistrer',
			'ingestion.notConfigured' => 'Cette fonctionnalité nécessite un service externe qui n\'est pas encore configuré',
			'ingestion.openOptionsTitle' => 'Comment ouvrir cette recette ?',
			'ingestion.viewOriginal' => 'Voir l\'original',
			'ingestion.viewOriginalHint' => 'Le texte de la page tel quel, sans traitement — immédiat',
			'ingestion.generateStructured' => 'Créer une recette structurée',
			'ingestion.generateStructuredHint' => 'Extraction automatique des ingrédients, quantités et étapes',
			'ingestion.originalTitle' => 'Recette originale',
			'ingestion.fetchFailed' => 'Impossible de charger la page',
			'ingestion.loadingOriginal' => 'Chargement de la page...',
			'ingestion.structuredFromSite' => 'Lue directement depuis les données structurées du site, sans IA',
			'ingestion.useStructured' => 'Continuer avec la recette structurée',
			'ingestion.preferAi' => 'Traiter avec l\'IA à la place',
			'ingestion.analysisTimedOut' => 'L\'analyse n\'a pas abouti à temps',
			'ingestion.analysisFailed' => 'L\'analyse a échoué',
			'ingestion.unparsedHint' => 'Votre texte est conservé tel quel. Réessayez, modifiez-le à la main, ou enregistrez-le pour l\'analyser plus tard.',
			'ingestion.retryAnalysis' => 'Réessayer',
			'ingestion.editManually' => 'Modifier manuellement',
			'ingestion.saveForLater' => 'Enregistrer et analyser plus tard',
			'ingestion.untitledRecipe' => 'Recette sans titre',
			'ingestion.manual' => 'Saisie manuelle',
			'ingestion.manualHint' => 'Remplissez la recette vous-même, au format structuré — sans IA, sans attente.',
			'ingestion.openBlankEditor' => 'Ouvrir un éditeur vide',
			'mealPlanner.title' => 'Planification des repas',
			'mealPlanner.newPlan' => 'Nouveau menu',
			'mealPlanner.planName' => 'Nom du menu',
			'mealPlanner.addMeal' => 'Ajouter un repas',
			'mealPlanner.mealName' => 'Nom du repas',
			'mealPlanner.addItem' => 'Ajouter un élément',
			'mealPlanner.pickRecipe' => 'Choisir une recette',
			'mealPlanner.quickEntry' => 'Élément rapide',
			'mealPlanner.noPlans' => 'Aucun menu pour l\'instant. Créez votre premier !',
			'mealPlanner.addMealHint' => 'Choisissez une recette ou ajoutez un élément rapide',
			'mealPlanner.breakfast' => 'Petit-déjeuner',
			'mealPlanner.lunch' => 'Déjeuner',
			'mealPlanner.dinner' => 'Dîner',
			'mealPlanner.morningSnack' => 'Collation du matin',
			'mealPlanner.afternoonSnack' => 'Collation de l\'après-midi',
			'mealPlanner.eveningSnack' => 'Collation du soir',
			'mealPlanner.template' => 'Modèle de départ',
			'mealPlanner.templateFree' => 'Commencer à vide',
			'mealPlanner.templateThree' => '3 repas',
			'mealPlanner.templateSix' => '6 repas',
			'mealPlanner.templateFreeHint' => 'Un menu vide — ajoutez les repas vous-même',
			'mealPlanner.templateThreeHint' => 'Petit-déjeuner, déjeuner et dîner chaque jour',
			'mealPlanner.templateSixHint' => '3 repas principaux et des collations chaque jour',
			'mealPlanner.nameRequired' => 'Donnez un nom au menu',
			'mealPlanner.products' => 'Produits',
			'mealPlanner.addProduct' => 'Ajouter un produit',
			'mealPlanner.productName' => 'Nom du produit',
			'mealPlanner.noProducts' => 'Sans produits, l\'élément rejoint la liste de courses comme une seule ligne à son nom',
			'mealPlanner.itemName' => 'Nom de l\'élément',
			'mealPlanner.editItem' => 'Modifier l\'élément',
			'groceryList.title' => 'Liste de courses',
			'groceryList.aggregated' => 'Regroupée à partir de tous les menus actifs',
			'groceryList.addItem' => 'Nouvel élément',
			'groceryList.category' => 'Catégorie',
			'groceryList.breakdownTitle' => 'Origine des quantités',
			'groceryList.collectionProgress' => 'Progression de la collecte',
			'groceryList.itemsCollected' => ({required Object collected, required Object total}) => '${collected} sur ${total} articles collectés',
			'groceryList.adjustAmounts' => 'Ajuster les quantités',
			'groceryList.buffer' => 'Quantité supplémentaire',
			'groceryList.share' => 'Partager la liste',
			'groceryList.empty' => 'La liste est vide pour le moment',
			'groceryList.uncheckedSection' => 'À collecter',
			'groceryList.checkedSection' => 'Collectés',
			'groceryList.selectAll' => 'Tout sélectionner',
			'groceryList.clearAll' => 'Tout désélectionner',
			'groceryList.deleteChecked' => 'Supprimer les collectés',
			'groceryList.amount' => 'Quantité',
			'groceryList.unit' => 'Unité',
			'groceryList.lastSource' => 'Au moins une source doit rester',
			'groceryList.itemName' => 'Nom de l\'article',
			'groceryList.planFilter' => 'Tous les menus',
			'groceryList.choosePlans' => 'Choisir les menus',
			'groceryList.plansSelected' => ({required Object count}) => '${count} menus sélectionnés',
			'groceryList.onePlanSelected' => 'Un menu sélectionné',
			'groceryList.noPlansToPick' => 'Aucun menu à choisir pour l\'instant',
			'groceryList.allPlansHint' => 'Agrégé depuis tous les menus',
			'groceryList.selectPlansTitle' => 'Quels menus alimentent cette liste ?',
			'groceryList.applySelection' => 'Mettre à jour',
			'groceryList.selectAllPlans' => 'Tous les menus',
			'unit.gram' => 'g',
			'unit.kilogram' => 'kg',
			'unit.milliliter' => 'ml',
			'unit.liter' => 'L',
			'unit.teaspoon' => 'c. à c.',
			'unit.tablespoon' => 'c. à s.',
			'unit.cup' => 'tasse',
			'unit.unit' => 'unité',
			'unit.pinch' => 'pincée',
			'unit.unspecified' => '—',
			'image.add' => 'Ajouter une photo',
			'image.change' => 'Changer la photo',
			'image.gallery' => 'Choisir dans la galerie',
			'image.camera' => 'Prendre une photo',
			'image.remove' => 'Supprimer la photo',
			'nav.library' => 'Livres',
			'nav.recipes' => 'Recettes',
			'nav.mealPlan' => 'Repas',
			'nav.groceries' => 'Courses',
			'nav.settings' => 'Réglages',
			'nav.community' => 'Communauté',
			_ => null,
		};
	}
}
