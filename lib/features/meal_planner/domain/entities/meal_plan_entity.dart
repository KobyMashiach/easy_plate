import '../../../../core/constants/app_enums.dart';
import 'meal_entity.dart';

class MealPlanEntity {
  final String id;
  final String name;
  final List<MealEntity> meals;
  final DateTime createdAt;

  /// The shared document this plan is a cache of, when it is shared between
  /// accounts, and what this account may do with it. Same pair as on a recipe.
  final String? collabId;
  final CollabRole? collabRole;

  /// The language this record's text is written in, as an [AppLanguage]
  /// name. Null for records saved before translation existed.
  final String? contentLang;

  /// Bumped when the text is edited; see the model's field of the same
  /// name. A translation made from this version stays good until it moves.
  final int contentVersion;

  const MealPlanEntity({
    required this.id,
    required this.name,
    required this.meals,
    required this.createdAt,
    this.collabId,
    this.collabRole,
    this.contentLang,
    this.contentVersion = 0,
  });

  bool get isShared => collabId != null;
  bool get canEdit => collabRole != CollabRole.viewer;

  /// Only the owner may share a plan on; a member cannot hand it further.
  bool get isMine => collabRole == null || collabRole == CollabRole.owner;

  List<MealEntity> mealsForWeekday(int weekday) {
    final dayMeals = meals.where((m) => m.weekday == weekday).toList();
    dayMeals.sort((a, b) => a.order.compareTo(b.order));
    return dayMeals;
  }

  MealPlanEntity copyWith({
    String? name,
    List<MealEntity>? meals,
    String? collabId,
    CollabRole? collabRole,
    // Both are null for "unchanged", so dropping the share needs a flag.
    bool clearCollab = false,
    String? contentLang,
    int? contentVersion,
  }) {
    return MealPlanEntity(
      id: id,
      name: name ?? this.name,
      meals: meals ?? this.meals,
      collabId: clearCollab ? null : (collabId ?? this.collabId),
      collabRole: clearCollab ? null : (collabRole ?? this.collabRole),
      createdAt: createdAt,
      contentLang: contentLang ?? this.contentLang,
      contentVersion: contentVersion ?? this.contentVersion,
    );
  }
}
