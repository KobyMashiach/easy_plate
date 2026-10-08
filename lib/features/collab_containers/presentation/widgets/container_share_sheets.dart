import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/i18n/strings.g.dart';
import '../../../grocery_list/domain/entities/grocery_list_entity.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../../../recipe_books/domain/entities/recipe_book_entity.dart';
import '../../../recipe_sharing/presentation/widgets/share_sheet.dart';
import '../../../share_codes/presentation/share_code_hooks.dart';
import '../../domain/container_sharing_service.dart';

/// Share a book: the same sheet as a recipe, sending through the container
/// service. Resolves true when an invite went out.
Future<bool?> showBookShareSheet(BuildContext context, RecipeBookEntity book) {
  final service = context.read<ContainerSharingService>();
  return showShareSheet(
    context,
    title: t.sharing.shareBook,
    subject: book.title,
    note: t.sharing.recipesTravel,
    onSend: (contact, {required role, required uid, required senderContacts}) =>
        service.books.share(
          book,
          contact: contact,
          role: role,
          ownerUid: uid,
          senderContacts: senderContacts,
        ),
    codes: ShareCodeHooks.book(context, book),
  );
}

Future<bool?> showPlanShareSheet(BuildContext context, MealPlanEntity plan) {
  final service = context.read<ContainerSharingService>();
  return showShareSheet(
    context,
    title: t.sharing.sharePlan,
    subject: plan.name,
    note: t.sharing.recipesTravel,
    onSend: (contact, {required role, required uid, required senderContacts}) =>
        service.plans.share(
          plan,
          contact: contact,
          role: role,
          ownerUid: uid,
          senderContacts: senderContacts,
        ),
    codes: ShareCodeHooks.plan(context, plan),
  );
}

/// Share a grocery list: the lines travel as written, nothing else does.
Future<bool?> showListShareSheet(BuildContext context, GroceryListEntity list) {
  final service = context.read<ContainerSharingService>();
  return showShareSheet(
    context,
    title: t.sharing.shareList,
    subject: list.name,
    onSend: (contact, {required role, required uid, required senderContacts}) =>
        service.lists.share(
          list,
          contact: contact,
          role: role,
          ownerUid: uid,
          senderContacts: senderContacts,
        ),
    codes: ShareCodeHooks.list(context, list),
  );
}
