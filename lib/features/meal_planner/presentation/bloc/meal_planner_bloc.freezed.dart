// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_planner_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealPlannerEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlannerEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MealPlannerEvent()';
}


}

/// @nodoc
class $MealPlannerEventCopyWith<$Res>  {
$MealPlannerEventCopyWith(MealPlannerEvent _, $Res Function(MealPlannerEvent) __);
}


/// Adds pattern-matching-related methods to [MealPlannerEvent].
extension MealPlannerEventPatterns on MealPlannerEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _CreatePlan value)?  createPlan,TResult Function( _SelectPlan value)?  selectPlan,TResult Function( _DeletePlan value)?  deletePlan,TResult Function( _AddMeal value)?  addMeal,TResult Function( _RemoveMeal value)?  removeMeal,TResult Function( _AddRecipeItem value)?  addRecipeItem,TResult Function( _AddFreeTextItem value)?  addFreeTextItem,TResult Function( _UpdateFreeTextItem value)?  updateFreeTextItem,TResult Function( _RemoveItem value)?  removeItem,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _CreatePlan() when createPlan != null:
return createPlan(_that);case _SelectPlan() when selectPlan != null:
return selectPlan(_that);case _DeletePlan() when deletePlan != null:
return deletePlan(_that);case _AddMeal() when addMeal != null:
return addMeal(_that);case _RemoveMeal() when removeMeal != null:
return removeMeal(_that);case _AddRecipeItem() when addRecipeItem != null:
return addRecipeItem(_that);case _AddFreeTextItem() when addFreeTextItem != null:
return addFreeTextItem(_that);case _UpdateFreeTextItem() when updateFreeTextItem != null:
return updateFreeTextItem(_that);case _RemoveItem() when removeItem != null:
return removeItem(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _CreatePlan value)  createPlan,required TResult Function( _SelectPlan value)  selectPlan,required TResult Function( _DeletePlan value)  deletePlan,required TResult Function( _AddMeal value)  addMeal,required TResult Function( _RemoveMeal value)  removeMeal,required TResult Function( _AddRecipeItem value)  addRecipeItem,required TResult Function( _AddFreeTextItem value)  addFreeTextItem,required TResult Function( _UpdateFreeTextItem value)  updateFreeTextItem,required TResult Function( _RemoveItem value)  removeItem,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _CreatePlan():
return createPlan(_that);case _SelectPlan():
return selectPlan(_that);case _DeletePlan():
return deletePlan(_that);case _AddMeal():
return addMeal(_that);case _RemoveMeal():
return removeMeal(_that);case _AddRecipeItem():
return addRecipeItem(_that);case _AddFreeTextItem():
return addFreeTextItem(_that);case _UpdateFreeTextItem():
return updateFreeTextItem(_that);case _RemoveItem():
return removeItem(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _CreatePlan value)?  createPlan,TResult? Function( _SelectPlan value)?  selectPlan,TResult? Function( _DeletePlan value)?  deletePlan,TResult? Function( _AddMeal value)?  addMeal,TResult? Function( _RemoveMeal value)?  removeMeal,TResult? Function( _AddRecipeItem value)?  addRecipeItem,TResult? Function( _AddFreeTextItem value)?  addFreeTextItem,TResult? Function( _UpdateFreeTextItem value)?  updateFreeTextItem,TResult? Function( _RemoveItem value)?  removeItem,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _CreatePlan() when createPlan != null:
return createPlan(_that);case _SelectPlan() when selectPlan != null:
return selectPlan(_that);case _DeletePlan() when deletePlan != null:
return deletePlan(_that);case _AddMeal() when addMeal != null:
return addMeal(_that);case _RemoveMeal() when removeMeal != null:
return removeMeal(_that);case _AddRecipeItem() when addRecipeItem != null:
return addRecipeItem(_that);case _AddFreeTextItem() when addFreeTextItem != null:
return addFreeTextItem(_that);case _UpdateFreeTextItem() when updateFreeTextItem != null:
return updateFreeTextItem(_that);case _RemoveItem() when removeItem != null:
return removeItem(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( String name,  MealPlanTemplate template)?  createPlan,TResult Function( String planId)?  selectPlan,TResult Function( String planId)?  deletePlan,TResult Function( int weekday,  String name)?  addMeal,TResult Function( String mealId)?  removeMeal,TResult Function( String mealId,  String recipeId)?  addRecipeItem,TResult Function( String mealId,  String text,  List<RecipeIngredientEntity> ingredients)?  addFreeTextItem,TResult Function( String mealId,  String itemId,  String text,  List<RecipeIngredientEntity> ingredients)?  updateFreeTextItem,TResult Function( String mealId,  String itemId)?  removeItem,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _CreatePlan() when createPlan != null:
return createPlan(_that.name,_that.template);case _SelectPlan() when selectPlan != null:
return selectPlan(_that.planId);case _DeletePlan() when deletePlan != null:
return deletePlan(_that.planId);case _AddMeal() when addMeal != null:
return addMeal(_that.weekday,_that.name);case _RemoveMeal() when removeMeal != null:
return removeMeal(_that.mealId);case _AddRecipeItem() when addRecipeItem != null:
return addRecipeItem(_that.mealId,_that.recipeId);case _AddFreeTextItem() when addFreeTextItem != null:
return addFreeTextItem(_that.mealId,_that.text,_that.ingredients);case _UpdateFreeTextItem() when updateFreeTextItem != null:
return updateFreeTextItem(_that.mealId,_that.itemId,_that.text,_that.ingredients);case _RemoveItem() when removeItem != null:
return removeItem(_that.mealId,_that.itemId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( String name,  MealPlanTemplate template)  createPlan,required TResult Function( String planId)  selectPlan,required TResult Function( String planId)  deletePlan,required TResult Function( int weekday,  String name)  addMeal,required TResult Function( String mealId)  removeMeal,required TResult Function( String mealId,  String recipeId)  addRecipeItem,required TResult Function( String mealId,  String text,  List<RecipeIngredientEntity> ingredients)  addFreeTextItem,required TResult Function( String mealId,  String itemId,  String text,  List<RecipeIngredientEntity> ingredients)  updateFreeTextItem,required TResult Function( String mealId,  String itemId)  removeItem,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _CreatePlan():
return createPlan(_that.name,_that.template);case _SelectPlan():
return selectPlan(_that.planId);case _DeletePlan():
return deletePlan(_that.planId);case _AddMeal():
return addMeal(_that.weekday,_that.name);case _RemoveMeal():
return removeMeal(_that.mealId);case _AddRecipeItem():
return addRecipeItem(_that.mealId,_that.recipeId);case _AddFreeTextItem():
return addFreeTextItem(_that.mealId,_that.text,_that.ingredients);case _UpdateFreeTextItem():
return updateFreeTextItem(_that.mealId,_that.itemId,_that.text,_that.ingredients);case _RemoveItem():
return removeItem(_that.mealId,_that.itemId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( String name,  MealPlanTemplate template)?  createPlan,TResult? Function( String planId)?  selectPlan,TResult? Function( String planId)?  deletePlan,TResult? Function( int weekday,  String name)?  addMeal,TResult? Function( String mealId)?  removeMeal,TResult? Function( String mealId,  String recipeId)?  addRecipeItem,TResult? Function( String mealId,  String text,  List<RecipeIngredientEntity> ingredients)?  addFreeTextItem,TResult? Function( String mealId,  String itemId,  String text,  List<RecipeIngredientEntity> ingredients)?  updateFreeTextItem,TResult? Function( String mealId,  String itemId)?  removeItem,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _CreatePlan() when createPlan != null:
return createPlan(_that.name,_that.template);case _SelectPlan() when selectPlan != null:
return selectPlan(_that.planId);case _DeletePlan() when deletePlan != null:
return deletePlan(_that.planId);case _AddMeal() when addMeal != null:
return addMeal(_that.weekday,_that.name);case _RemoveMeal() when removeMeal != null:
return removeMeal(_that.mealId);case _AddRecipeItem() when addRecipeItem != null:
return addRecipeItem(_that.mealId,_that.recipeId);case _AddFreeTextItem() when addFreeTextItem != null:
return addFreeTextItem(_that.mealId,_that.text,_that.ingredients);case _UpdateFreeTextItem() when updateFreeTextItem != null:
return updateFreeTextItem(_that.mealId,_that.itemId,_that.text,_that.ingredients);case _RemoveItem() when removeItem != null:
return removeItem(_that.mealId,_that.itemId);case _:
  return null;

}
}

}

/// @nodoc


class _Init implements MealPlannerEvent {
  const _Init();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Init);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MealPlannerEvent.init()';
}


}




/// @nodoc


class _CreatePlan implements MealPlannerEvent {
  const _CreatePlan(this.name, this.template);
  

 final  String name;
 final  MealPlanTemplate template;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePlanCopyWith<_CreatePlan> get copyWith => __$CreatePlanCopyWithImpl<_CreatePlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePlan&&(identical(other.name, name) || other.name == name)&&(identical(other.template, template) || other.template == template));
}


@override
int get hashCode => Object.hash(runtimeType,name,template);

@override
String toString() {
  return 'MealPlannerEvent.createPlan(name: $name, template: $template)';
}


}

/// @nodoc
abstract mixin class _$CreatePlanCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$CreatePlanCopyWith(_CreatePlan value, $Res Function(_CreatePlan) _then) = __$CreatePlanCopyWithImpl;
@useResult
$Res call({
 String name, MealPlanTemplate template
});




}
/// @nodoc
class __$CreatePlanCopyWithImpl<$Res>
    implements _$CreatePlanCopyWith<$Res> {
  __$CreatePlanCopyWithImpl(this._self, this._then);

  final _CreatePlan _self;
  final $Res Function(_CreatePlan) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? template = null,}) {
  return _then(_CreatePlan(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as MealPlanTemplate,
  ));
}


}

/// @nodoc


class _SelectPlan implements MealPlannerEvent {
  const _SelectPlan(this.planId);
  

 final  String planId;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectPlanCopyWith<_SelectPlan> get copyWith => __$SelectPlanCopyWithImpl<_SelectPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectPlan&&(identical(other.planId, planId) || other.planId == planId));
}


@override
int get hashCode => Object.hash(runtimeType,planId);

@override
String toString() {
  return 'MealPlannerEvent.selectPlan(planId: $planId)';
}


}

/// @nodoc
abstract mixin class _$SelectPlanCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$SelectPlanCopyWith(_SelectPlan value, $Res Function(_SelectPlan) _then) = __$SelectPlanCopyWithImpl;
@useResult
$Res call({
 String planId
});




}
/// @nodoc
class __$SelectPlanCopyWithImpl<$Res>
    implements _$SelectPlanCopyWith<$Res> {
  __$SelectPlanCopyWithImpl(this._self, this._then);

  final _SelectPlan _self;
  final $Res Function(_SelectPlan) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? planId = null,}) {
  return _then(_SelectPlan(
null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeletePlan implements MealPlannerEvent {
  const _DeletePlan(this.planId);
  

 final  String planId;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletePlanCopyWith<_DeletePlan> get copyWith => __$DeletePlanCopyWithImpl<_DeletePlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletePlan&&(identical(other.planId, planId) || other.planId == planId));
}


@override
int get hashCode => Object.hash(runtimeType,planId);

@override
String toString() {
  return 'MealPlannerEvent.deletePlan(planId: $planId)';
}


}

/// @nodoc
abstract mixin class _$DeletePlanCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$DeletePlanCopyWith(_DeletePlan value, $Res Function(_DeletePlan) _then) = __$DeletePlanCopyWithImpl;
@useResult
$Res call({
 String planId
});




}
/// @nodoc
class __$DeletePlanCopyWithImpl<$Res>
    implements _$DeletePlanCopyWith<$Res> {
  __$DeletePlanCopyWithImpl(this._self, this._then);

  final _DeletePlan _self;
  final $Res Function(_DeletePlan) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? planId = null,}) {
  return _then(_DeletePlan(
null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddMeal implements MealPlannerEvent {
  const _AddMeal(this.weekday, this.name);
  

 final  int weekday;
 final  String name;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddMealCopyWith<_AddMeal> get copyWith => __$AddMealCopyWithImpl<_AddMeal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddMeal&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,weekday,name);

@override
String toString() {
  return 'MealPlannerEvent.addMeal(weekday: $weekday, name: $name)';
}


}

/// @nodoc
abstract mixin class _$AddMealCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$AddMealCopyWith(_AddMeal value, $Res Function(_AddMeal) _then) = __$AddMealCopyWithImpl;
@useResult
$Res call({
 int weekday, String name
});




}
/// @nodoc
class __$AddMealCopyWithImpl<$Res>
    implements _$AddMealCopyWith<$Res> {
  __$AddMealCopyWithImpl(this._self, this._then);

  final _AddMeal _self;
  final $Res Function(_AddMeal) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? weekday = null,Object? name = null,}) {
  return _then(_AddMeal(
null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _RemoveMeal implements MealPlannerEvent {
  const _RemoveMeal(this.mealId);
  

 final  String mealId;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveMealCopyWith<_RemoveMeal> get copyWith => __$RemoveMealCopyWithImpl<_RemoveMeal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveMeal&&(identical(other.mealId, mealId) || other.mealId == mealId));
}


@override
int get hashCode => Object.hash(runtimeType,mealId);

@override
String toString() {
  return 'MealPlannerEvent.removeMeal(mealId: $mealId)';
}


}

/// @nodoc
abstract mixin class _$RemoveMealCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$RemoveMealCopyWith(_RemoveMeal value, $Res Function(_RemoveMeal) _then) = __$RemoveMealCopyWithImpl;
@useResult
$Res call({
 String mealId
});




}
/// @nodoc
class __$RemoveMealCopyWithImpl<$Res>
    implements _$RemoveMealCopyWith<$Res> {
  __$RemoveMealCopyWithImpl(this._self, this._then);

  final _RemoveMeal _self;
  final $Res Function(_RemoveMeal) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mealId = null,}) {
  return _then(_RemoveMeal(
null == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddRecipeItem implements MealPlannerEvent {
  const _AddRecipeItem(this.mealId, this.recipeId);
  

 final  String mealId;
 final  String recipeId;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddRecipeItemCopyWith<_AddRecipeItem> get copyWith => __$AddRecipeItemCopyWithImpl<_AddRecipeItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddRecipeItem&&(identical(other.mealId, mealId) || other.mealId == mealId)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId));
}


@override
int get hashCode => Object.hash(runtimeType,mealId,recipeId);

@override
String toString() {
  return 'MealPlannerEvent.addRecipeItem(mealId: $mealId, recipeId: $recipeId)';
}


}

/// @nodoc
abstract mixin class _$AddRecipeItemCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$AddRecipeItemCopyWith(_AddRecipeItem value, $Res Function(_AddRecipeItem) _then) = __$AddRecipeItemCopyWithImpl;
@useResult
$Res call({
 String mealId, String recipeId
});




}
/// @nodoc
class __$AddRecipeItemCopyWithImpl<$Res>
    implements _$AddRecipeItemCopyWith<$Res> {
  __$AddRecipeItemCopyWithImpl(this._self, this._then);

  final _AddRecipeItem _self;
  final $Res Function(_AddRecipeItem) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mealId = null,Object? recipeId = null,}) {
  return _then(_AddRecipeItem(
null == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String,null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddFreeTextItem implements MealPlannerEvent {
  const _AddFreeTextItem(this.mealId, this.text, final  List<RecipeIngredientEntity> ingredients): _ingredients = ingredients;
  

 final  String mealId;
 final  String text;
 final  List<RecipeIngredientEntity> _ingredients;
 List<RecipeIngredientEntity> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}


/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddFreeTextItemCopyWith<_AddFreeTextItem> get copyWith => __$AddFreeTextItemCopyWithImpl<_AddFreeTextItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddFreeTextItem&&(identical(other.mealId, mealId) || other.mealId == mealId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients));
}


@override
int get hashCode => Object.hash(runtimeType,mealId,text,const DeepCollectionEquality().hash(_ingredients));

@override
String toString() {
  return 'MealPlannerEvent.addFreeTextItem(mealId: $mealId, text: $text, ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class _$AddFreeTextItemCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$AddFreeTextItemCopyWith(_AddFreeTextItem value, $Res Function(_AddFreeTextItem) _then) = __$AddFreeTextItemCopyWithImpl;
@useResult
$Res call({
 String mealId, String text, List<RecipeIngredientEntity> ingredients
});




}
/// @nodoc
class __$AddFreeTextItemCopyWithImpl<$Res>
    implements _$AddFreeTextItemCopyWith<$Res> {
  __$AddFreeTextItemCopyWithImpl(this._self, this._then);

  final _AddFreeTextItem _self;
  final $Res Function(_AddFreeTextItem) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mealId = null,Object? text = null,Object? ingredients = null,}) {
  return _then(_AddFreeTextItem(
null == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String,null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredientEntity>,
  ));
}


}

/// @nodoc


class _UpdateFreeTextItem implements MealPlannerEvent {
  const _UpdateFreeTextItem(this.mealId, this.itemId, this.text, final  List<RecipeIngredientEntity> ingredients): _ingredients = ingredients;
  

 final  String mealId;
 final  String itemId;
 final  String text;
 final  List<RecipeIngredientEntity> _ingredients;
 List<RecipeIngredientEntity> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}


/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateFreeTextItemCopyWith<_UpdateFreeTextItem> get copyWith => __$UpdateFreeTextItemCopyWithImpl<_UpdateFreeTextItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateFreeTextItem&&(identical(other.mealId, mealId) || other.mealId == mealId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients));
}


@override
int get hashCode => Object.hash(runtimeType,mealId,itemId,text,const DeepCollectionEquality().hash(_ingredients));

@override
String toString() {
  return 'MealPlannerEvent.updateFreeTextItem(mealId: $mealId, itemId: $itemId, text: $text, ingredients: $ingredients)';
}


}

/// @nodoc
abstract mixin class _$UpdateFreeTextItemCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$UpdateFreeTextItemCopyWith(_UpdateFreeTextItem value, $Res Function(_UpdateFreeTextItem) _then) = __$UpdateFreeTextItemCopyWithImpl;
@useResult
$Res call({
 String mealId, String itemId, String text, List<RecipeIngredientEntity> ingredients
});




}
/// @nodoc
class __$UpdateFreeTextItemCopyWithImpl<$Res>
    implements _$UpdateFreeTextItemCopyWith<$Res> {
  __$UpdateFreeTextItemCopyWithImpl(this._self, this._then);

  final _UpdateFreeTextItem _self;
  final $Res Function(_UpdateFreeTextItem) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mealId = null,Object? itemId = null,Object? text = null,Object? ingredients = null,}) {
  return _then(_UpdateFreeTextItem(
null == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String,null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredientEntity>,
  ));
}


}

/// @nodoc


class _RemoveItem implements MealPlannerEvent {
  const _RemoveItem(this.mealId, this.itemId);
  

 final  String mealId;
 final  String itemId;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveItemCopyWith<_RemoveItem> get copyWith => __$RemoveItemCopyWithImpl<_RemoveItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveItem&&(identical(other.mealId, mealId) || other.mealId == mealId)&&(identical(other.itemId, itemId) || other.itemId == itemId));
}


@override
int get hashCode => Object.hash(runtimeType,mealId,itemId);

@override
String toString() {
  return 'MealPlannerEvent.removeItem(mealId: $mealId, itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class _$RemoveItemCopyWith<$Res> implements $MealPlannerEventCopyWith<$Res> {
  factory _$RemoveItemCopyWith(_RemoveItem value, $Res Function(_RemoveItem) _then) = __$RemoveItemCopyWithImpl;
@useResult
$Res call({
 String mealId, String itemId
});




}
/// @nodoc
class __$RemoveItemCopyWithImpl<$Res>
    implements _$RemoveItemCopyWith<$Res> {
  __$RemoveItemCopyWithImpl(this._self, this._then);

  final _RemoveItem _self;
  final $Res Function(_RemoveItem) _then;

/// Create a copy of MealPlannerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mealId = null,Object? itemId = null,}) {
  return _then(_RemoveItem(
null == mealId ? _self.mealId : mealId // ignore: cast_nullable_to_non_nullable
as String,null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MealPlannerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlannerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MealPlannerState()';
}


}

/// @nodoc
class $MealPlannerStateCopyWith<$Res>  {
$MealPlannerStateCopyWith(MealPlannerState _, $Res Function(MealPlannerState) __);
}


/// Adds pattern-matching-related methods to [MealPlannerState].
extension MealPlannerStatePatterns on MealPlannerState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MealPlannerLoading value)?  loading,TResult Function( MealPlannerLoaded value)?  loaded,TResult Function( MealPlannerError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MealPlannerLoading() when loading != null:
return loading(_that);case MealPlannerLoaded() when loaded != null:
return loaded(_that);case MealPlannerError() when errorMessage != null:
return errorMessage(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MealPlannerLoading value)  loading,required TResult Function( MealPlannerLoaded value)  loaded,required TResult Function( MealPlannerError value)  errorMessage,}){
final _that = this;
switch (_that) {
case MealPlannerLoading():
return loading(_that);case MealPlannerLoaded():
return loaded(_that);case MealPlannerError():
return errorMessage(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MealPlannerLoading value)?  loading,TResult? Function( MealPlannerLoaded value)?  loaded,TResult? Function( MealPlannerError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case MealPlannerLoading() when loading != null:
return loading(_that);case MealPlannerLoaded() when loaded != null:
return loaded(_that);case MealPlannerError() when errorMessage != null:
return errorMessage(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<MealPlanEntity> plans,  MealPlanEntity? selectedPlan,  Map<String, String> recipeTitles)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MealPlannerLoading() when loading != null:
return loading();case MealPlannerLoaded() when loaded != null:
return loaded(_that.plans,_that.selectedPlan,_that.recipeTitles);case MealPlannerError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<MealPlanEntity> plans,  MealPlanEntity? selectedPlan,  Map<String, String> recipeTitles)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case MealPlannerLoading():
return loading();case MealPlannerLoaded():
return loaded(_that.plans,_that.selectedPlan,_that.recipeTitles);case MealPlannerError():
return errorMessage(_that.error);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<MealPlanEntity> plans,  MealPlanEntity? selectedPlan,  Map<String, String> recipeTitles)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case MealPlannerLoading() when loading != null:
return loading();case MealPlannerLoaded() when loaded != null:
return loaded(_that.plans,_that.selectedPlan,_that.recipeTitles);case MealPlannerError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class MealPlannerLoading implements MealPlannerState {
  const MealPlannerLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlannerLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MealPlannerState.loading()';
}


}




/// @nodoc


class MealPlannerLoaded implements MealPlannerState {
  const MealPlannerLoaded(final  List<MealPlanEntity> plans, {this.selectedPlan, final  Map<String, String> recipeTitles = const {}}): _plans = plans,_recipeTitles = recipeTitles;
  

 final  List<MealPlanEntity> _plans;
 List<MealPlanEntity> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}

 final  MealPlanEntity? selectedPlan;
 final  Map<String, String> _recipeTitles;
@JsonKey() Map<String, String> get recipeTitles {
  if (_recipeTitles is EqualUnmodifiableMapView) return _recipeTitles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_recipeTitles);
}


/// Create a copy of MealPlannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealPlannerLoadedCopyWith<MealPlannerLoaded> get copyWith => _$MealPlannerLoadedCopyWithImpl<MealPlannerLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlannerLoaded&&const DeepCollectionEquality().equals(other._plans, _plans)&&(identical(other.selectedPlan, selectedPlan) || other.selectedPlan == selectedPlan)&&const DeepCollectionEquality().equals(other._recipeTitles, _recipeTitles));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_plans),selectedPlan,const DeepCollectionEquality().hash(_recipeTitles));

@override
String toString() {
  return 'MealPlannerState.loaded(plans: $plans, selectedPlan: $selectedPlan, recipeTitles: $recipeTitles)';
}


}

/// @nodoc
abstract mixin class $MealPlannerLoadedCopyWith<$Res> implements $MealPlannerStateCopyWith<$Res> {
  factory $MealPlannerLoadedCopyWith(MealPlannerLoaded value, $Res Function(MealPlannerLoaded) _then) = _$MealPlannerLoadedCopyWithImpl;
@useResult
$Res call({
 List<MealPlanEntity> plans, MealPlanEntity? selectedPlan, Map<String, String> recipeTitles
});




}
/// @nodoc
class _$MealPlannerLoadedCopyWithImpl<$Res>
    implements $MealPlannerLoadedCopyWith<$Res> {
  _$MealPlannerLoadedCopyWithImpl(this._self, this._then);

  final MealPlannerLoaded _self;
  final $Res Function(MealPlannerLoaded) _then;

/// Create a copy of MealPlannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? plans = null,Object? selectedPlan = freezed,Object? recipeTitles = null,}) {
  return _then(MealPlannerLoaded(
null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<MealPlanEntity>,selectedPlan: freezed == selectedPlan ? _self.selectedPlan : selectedPlan // ignore: cast_nullable_to_non_nullable
as MealPlanEntity?,recipeTitles: null == recipeTitles ? _self._recipeTitles : recipeTitles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

/// @nodoc


class MealPlannerError implements MealPlannerState {
  const MealPlannerError(this.error);
  

 final  String error;

/// Create a copy of MealPlannerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealPlannerErrorCopyWith<MealPlannerError> get copyWith => _$MealPlannerErrorCopyWithImpl<MealPlannerError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlannerError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'MealPlannerState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $MealPlannerErrorCopyWith<$Res> implements $MealPlannerStateCopyWith<$Res> {
  factory $MealPlannerErrorCopyWith(MealPlannerError value, $Res Function(MealPlannerError) _then) = _$MealPlannerErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$MealPlannerErrorCopyWithImpl<$Res>
    implements $MealPlannerErrorCopyWith<$Res> {
  _$MealPlannerErrorCopyWithImpl(this._self, this._then);

  final MealPlannerError _self;
  final $Res Function(MealPlannerError) _then;

/// Create a copy of MealPlannerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(MealPlannerError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
