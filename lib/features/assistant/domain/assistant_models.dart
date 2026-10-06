import '../../grocery_list/domain/entities/grocery_item_entity.dart';
import '../../my_recipes/domain/entities/recipe_entity.dart';
import '../../recipe_ingestion/domain/entities/web_search_result_entity.dart';

/// One function call the model asked for.
class ToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

/// What a tool hands back: the structured result the model reads, and an
/// optional card the chat renders instead of (or beside) plain text.
class ToolResult {
  final Map<String, dynamic> data;
  final AssistantCard? card;

  const ToolResult(this.data, {this.card});

  factory ToolResult.ok(Map<String, dynamic> data, {AssistantCard? card}) =>
      ToolResult({'ok': true, ...data}, card: card);

  factory ToolResult.error(String code, String message) =>
      ToolResult({'ok': false, 'error': code, 'message': message});
}

/// A rich block in the conversation: the model's words stay text, the
/// things it did are shown as the app shows them.
sealed class AssistantCard {
  const AssistantCard();
}

class RecipeCard extends AssistantCard {
  final RecipeEntity recipe;
  final String? caption;
  const RecipeCard(this.recipe, {this.caption});
}

class RecipeListCard extends AssistantCard {
  final String title;
  final List<RecipeEntity> recipes;
  const RecipeListCard(this.title, this.recipes);
}

/// A live checklist: toggles write straight to the grocery list.
class GroceryCard extends AssistantCard {
  final String listId;
  final String listName;
  final List<GroceryItemEntity> items;
  const GroceryCard({
    required this.listId,
    required this.listName,
    required this.items,
  });
}

class PlannedMealCard extends AssistantCard {
  final String planName;
  final String dayLabel;
  final String mealName;
  final String title;
  final RecipeEntity? recipe;
  const PlannedMealCard({
    required this.planName,
    required this.dayLabel,
    required this.mealName,
    required this.title,
    this.recipe,
  });
}

class WebResultsCard extends AssistantCard {
  final List<WebSearchResultEntity> results;
  const WebResultsCard(this.results);
}

/// A short status line with an icon (timer set, preference saved …).
class StatusCard extends AssistantCard {
  final String text;
  final String icon;
  const StatusCard(this.text, {this.icon = 'check'});
}

/// Lines of plain information (a plan's days, the week's meals …).
class LinesCard extends AssistantCard {
  final String title;
  final List<String> lines;
  const LinesCard(this.title, this.lines);
}

enum AssistantRole { user, assistant, tool }

/// One entry in the transcript the chat shows.
class AssistantMessage {
  final String id;
  final AssistantRole role;
  final String text;
  final AssistantCard? card;
  final bool pending;
  final bool error;

  const AssistantMessage({
    required this.id,
    required this.role,
    this.text = '',
    this.card,
    this.pending = false,
    this.error = false,
  });

  AssistantMessage copyWith({String? text, bool? pending, bool? error}) =>
      AssistantMessage(
        id: id,
        role: role,
        text: text ?? this.text,
        card: card,
        pending: pending ?? this.pending,
        error: error ?? this.error,
      );
}

/// A model turn as the Interactions API returns it.
class AssistantTurn {
  final String interactionId;
  final String text;
  final List<ToolCall> toolCalls;

  const AssistantTurn({
    required this.interactionId,
    required this.text,
    required this.toolCalls,
  });

  bool get requiresAction => toolCalls.isNotEmpty;
}
