import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/routing/routing.dart';
import '../domain/entities/recipe_entity.dart';

/// Into cook mode. The route's own redirect waits for the plan verdict and
/// sends a free account on a gated plan to the paywall, so callers never
/// decide that themselves.
void openCookMode(BuildContext context, RecipeEntity recipe) {
  context.pushNamed(Routing.cookMode, extra: recipe);
}
