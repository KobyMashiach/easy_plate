import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../domain/repositories/recipe_sharing_repository.dart';
import '../../domain/usecases/share_recipe_usecase.dart';
import 'share_sheet.dart';

/// Who to share a recipe with and what they may do. Resolves true when an
/// invite went out.
Future<bool?> showRecipeShareSheet(BuildContext context, RecipeEntity recipe) {
  final useCase = ShareRecipeUseCase(
    sharing: context.read<RecipeSharingRepository>(),
    profiles: context.read<UserProfileRepository>(),
    recipes: context.read<RecipesRepository>(),
  );
  return showShareSheet(
    context,
    title: t.sharing.title,
    subject: recipe.title,
    onSend: (contact, {required role, required uid, required senderContacts}) =>
        useCase(
          recipe,
          contact: contact,
          role: role,
          ownerUid: uid,
          senderContacts: senderContacts,
        ),
  );
}
