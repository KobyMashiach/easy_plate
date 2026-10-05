// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroceryListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GroceryListEvent()';
}


}

/// @nodoc
class $GroceryListEventCopyWith<$Res>  {
$GroceryListEventCopyWith(GroceryListEvent _, $Res Function(GroceryListEvent) __);
}


/// Adds pattern-matching-related methods to [GroceryListEvent].
extension GroceryListEventPatterns on GroceryListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _Regenerate value)?  regenerate,TResult Function( _SelectPlans value)?  selectPlans,TResult Function( _ToggleItem value)?  toggleItem,TResult Function( _AddAdHocItem value)?  addAdHocItem,TResult Function( _RemoveItem value)?  removeItem,TResult Function( _AddBuffer value)?  addBuffer,TResult Function( _AdjustSource value)?  adjustSource,TResult Function( _RemoveSource value)?  removeSource,TResult Function( _ChangeUnit value)?  changeUnit,TResult Function( _SetAllChecked value)?  setAllChecked,TResult Function( _DeleteCheckedItems value)?  deleteCheckedItems,TResult Function( _PlansChanged value)?  plansChanged,TResult Function( _SelectList value)?  selectList,TResult Function( _CreateList value)?  createList,TResult Function( _CreateRecipeList value)?  createRecipeList,TResult Function( _RenameList value)?  renameList,TResult Function( _DeleteList value)?  deleteList,TResult Function( _SetRecipeScale value)?  setRecipeScale,TResult Function( _ListsChanged value)?  listsChanged,TResult Function( _ActiveChanged value)?  activeChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Regenerate() when regenerate != null:
return regenerate(_that);case _SelectPlans() when selectPlans != null:
return selectPlans(_that);case _ToggleItem() when toggleItem != null:
return toggleItem(_that);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that);case _RemoveItem() when removeItem != null:
return removeItem(_that);case _AddBuffer() when addBuffer != null:
return addBuffer(_that);case _AdjustSource() when adjustSource != null:
return adjustSource(_that);case _RemoveSource() when removeSource != null:
return removeSource(_that);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems(_that);case _PlansChanged() when plansChanged != null:
return plansChanged(_that);case _SelectList() when selectList != null:
return selectList(_that);case _CreateList() when createList != null:
return createList(_that);case _CreateRecipeList() when createRecipeList != null:
return createRecipeList(_that);case _RenameList() when renameList != null:
return renameList(_that);case _DeleteList() when deleteList != null:
return deleteList(_that);case _SetRecipeScale() when setRecipeScale != null:
return setRecipeScale(_that);case _ListsChanged() when listsChanged != null:
return listsChanged(_that);case _ActiveChanged() when activeChanged != null:
return activeChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _Regenerate value)  regenerate,required TResult Function( _SelectPlans value)  selectPlans,required TResult Function( _ToggleItem value)  toggleItem,required TResult Function( _AddAdHocItem value)  addAdHocItem,required TResult Function( _RemoveItem value)  removeItem,required TResult Function( _AddBuffer value)  addBuffer,required TResult Function( _AdjustSource value)  adjustSource,required TResult Function( _RemoveSource value)  removeSource,required TResult Function( _ChangeUnit value)  changeUnit,required TResult Function( _SetAllChecked value)  setAllChecked,required TResult Function( _DeleteCheckedItems value)  deleteCheckedItems,required TResult Function( _PlansChanged value)  plansChanged,required TResult Function( _SelectList value)  selectList,required TResult Function( _CreateList value)  createList,required TResult Function( _CreateRecipeList value)  createRecipeList,required TResult Function( _RenameList value)  renameList,required TResult Function( _DeleteList value)  deleteList,required TResult Function( _SetRecipeScale value)  setRecipeScale,required TResult Function( _ListsChanged value)  listsChanged,required TResult Function( _ActiveChanged value)  activeChanged,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _Regenerate():
return regenerate(_that);case _SelectPlans():
return selectPlans(_that);case _ToggleItem():
return toggleItem(_that);case _AddAdHocItem():
return addAdHocItem(_that);case _RemoveItem():
return removeItem(_that);case _AddBuffer():
return addBuffer(_that);case _AdjustSource():
return adjustSource(_that);case _RemoveSource():
return removeSource(_that);case _ChangeUnit():
return changeUnit(_that);case _SetAllChecked():
return setAllChecked(_that);case _DeleteCheckedItems():
return deleteCheckedItems(_that);case _PlansChanged():
return plansChanged(_that);case _SelectList():
return selectList(_that);case _CreateList():
return createList(_that);case _CreateRecipeList():
return createRecipeList(_that);case _RenameList():
return renameList(_that);case _DeleteList():
return deleteList(_that);case _SetRecipeScale():
return setRecipeScale(_that);case _ListsChanged():
return listsChanged(_that);case _ActiveChanged():
return activeChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _Regenerate value)?  regenerate,TResult? Function( _SelectPlans value)?  selectPlans,TResult? Function( _ToggleItem value)?  toggleItem,TResult? Function( _AddAdHocItem value)?  addAdHocItem,TResult? Function( _RemoveItem value)?  removeItem,TResult? Function( _AddBuffer value)?  addBuffer,TResult? Function( _AdjustSource value)?  adjustSource,TResult? Function( _RemoveSource value)?  removeSource,TResult? Function( _ChangeUnit value)?  changeUnit,TResult? Function( _SetAllChecked value)?  setAllChecked,TResult? Function( _DeleteCheckedItems value)?  deleteCheckedItems,TResult? Function( _PlansChanged value)?  plansChanged,TResult? Function( _SelectList value)?  selectList,TResult? Function( _CreateList value)?  createList,TResult? Function( _CreateRecipeList value)?  createRecipeList,TResult? Function( _RenameList value)?  renameList,TResult? Function( _DeleteList value)?  deleteList,TResult? Function( _SetRecipeScale value)?  setRecipeScale,TResult? Function( _ListsChanged value)?  listsChanged,TResult? Function( _ActiveChanged value)?  activeChanged,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Regenerate() when regenerate != null:
return regenerate(_that);case _SelectPlans() when selectPlans != null:
return selectPlans(_that);case _ToggleItem() when toggleItem != null:
return toggleItem(_that);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that);case _RemoveItem() when removeItem != null:
return removeItem(_that);case _AddBuffer() when addBuffer != null:
return addBuffer(_that);case _AdjustSource() when adjustSource != null:
return adjustSource(_that);case _RemoveSource() when removeSource != null:
return removeSource(_that);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems(_that);case _PlansChanged() when plansChanged != null:
return plansChanged(_that);case _SelectList() when selectList != null:
return selectList(_that);case _CreateList() when createList != null:
return createList(_that);case _CreateRecipeList() when createRecipeList != null:
return createRecipeList(_that);case _RenameList() when renameList != null:
return renameList(_that);case _DeleteList() when deleteList != null:
return deleteList(_that);case _SetRecipeScale() when setRecipeScale != null:
return setRecipeScale(_that);case _ListsChanged() when listsChanged != null:
return listsChanged(_that);case _ActiveChanged() when activeChanged != null:
return activeChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function()?  regenerate,TResult Function( List<String> planIds)?  selectPlans,TResult Function( String itemId)?  toggleItem,TResult Function( String name,  double amount,  MeasurementUnit unit)?  addAdHocItem,TResult Function( String itemId)?  removeItem,TResult Function( String itemId,  double amount)?  addBuffer,TResult Function( String itemId,  int sourceIndex,  double amount)?  adjustSource,TResult Function( String itemId,  int sourceIndex)?  removeSource,TResult Function( String itemId,  MeasurementUnit unit)?  changeUnit,TResult Function( bool checked)?  setAllChecked,TResult Function()?  deleteCheckedItems,TResult Function( List<MealPlanEntity> plans)?  plansChanged,TResult Function( String listId)?  selectList,TResult Function( String name,  GroceryListSource source)?  createList,TResult Function( RecipeEntity recipe,  String name,  double scale)?  createRecipeList,TResult Function( String listId,  String name)?  renameList,TResult Function( String listId)?  deleteList,TResult Function( double scale)?  setRecipeScale,TResult Function( List<GroceryListEntity> lists)?  listsChanged,TResult Function( String listId)?  activeChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Regenerate() when regenerate != null:
return regenerate();case _SelectPlans() when selectPlans != null:
return selectPlans(_that.planIds);case _ToggleItem() when toggleItem != null:
return toggleItem(_that.itemId);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that.name,_that.amount,_that.unit);case _RemoveItem() when removeItem != null:
return removeItem(_that.itemId);case _AddBuffer() when addBuffer != null:
return addBuffer(_that.itemId,_that.amount);case _AdjustSource() when adjustSource != null:
return adjustSource(_that.itemId,_that.sourceIndex,_that.amount);case _RemoveSource() when removeSource != null:
return removeSource(_that.itemId,_that.sourceIndex);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that.itemId,_that.unit);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that.checked);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems();case _PlansChanged() when plansChanged != null:
return plansChanged(_that.plans);case _SelectList() when selectList != null:
return selectList(_that.listId);case _CreateList() when createList != null:
return createList(_that.name,_that.source);case _CreateRecipeList() when createRecipeList != null:
return createRecipeList(_that.recipe,_that.name,_that.scale);case _RenameList() when renameList != null:
return renameList(_that.listId,_that.name);case _DeleteList() when deleteList != null:
return deleteList(_that.listId);case _SetRecipeScale() when setRecipeScale != null:
return setRecipeScale(_that.scale);case _ListsChanged() when listsChanged != null:
return listsChanged(_that.lists);case _ActiveChanged() when activeChanged != null:
return activeChanged(_that.listId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function()  regenerate,required TResult Function( List<String> planIds)  selectPlans,required TResult Function( String itemId)  toggleItem,required TResult Function( String name,  double amount,  MeasurementUnit unit)  addAdHocItem,required TResult Function( String itemId)  removeItem,required TResult Function( String itemId,  double amount)  addBuffer,required TResult Function( String itemId,  int sourceIndex,  double amount)  adjustSource,required TResult Function( String itemId,  int sourceIndex)  removeSource,required TResult Function( String itemId,  MeasurementUnit unit)  changeUnit,required TResult Function( bool checked)  setAllChecked,required TResult Function()  deleteCheckedItems,required TResult Function( List<MealPlanEntity> plans)  plansChanged,required TResult Function( String listId)  selectList,required TResult Function( String name,  GroceryListSource source)  createList,required TResult Function( RecipeEntity recipe,  String name,  double scale)  createRecipeList,required TResult Function( String listId,  String name)  renameList,required TResult Function( String listId)  deleteList,required TResult Function( double scale)  setRecipeScale,required TResult Function( List<GroceryListEntity> lists)  listsChanged,required TResult Function( String listId)  activeChanged,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _Regenerate():
return regenerate();case _SelectPlans():
return selectPlans(_that.planIds);case _ToggleItem():
return toggleItem(_that.itemId);case _AddAdHocItem():
return addAdHocItem(_that.name,_that.amount,_that.unit);case _RemoveItem():
return removeItem(_that.itemId);case _AddBuffer():
return addBuffer(_that.itemId,_that.amount);case _AdjustSource():
return adjustSource(_that.itemId,_that.sourceIndex,_that.amount);case _RemoveSource():
return removeSource(_that.itemId,_that.sourceIndex);case _ChangeUnit():
return changeUnit(_that.itemId,_that.unit);case _SetAllChecked():
return setAllChecked(_that.checked);case _DeleteCheckedItems():
return deleteCheckedItems();case _PlansChanged():
return plansChanged(_that.plans);case _SelectList():
return selectList(_that.listId);case _CreateList():
return createList(_that.name,_that.source);case _CreateRecipeList():
return createRecipeList(_that.recipe,_that.name,_that.scale);case _RenameList():
return renameList(_that.listId,_that.name);case _DeleteList():
return deleteList(_that.listId);case _SetRecipeScale():
return setRecipeScale(_that.scale);case _ListsChanged():
return listsChanged(_that.lists);case _ActiveChanged():
return activeChanged(_that.listId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function()?  regenerate,TResult? Function( List<String> planIds)?  selectPlans,TResult? Function( String itemId)?  toggleItem,TResult? Function( String name,  double amount,  MeasurementUnit unit)?  addAdHocItem,TResult? Function( String itemId)?  removeItem,TResult? Function( String itemId,  double amount)?  addBuffer,TResult? Function( String itemId,  int sourceIndex,  double amount)?  adjustSource,TResult? Function( String itemId,  int sourceIndex)?  removeSource,TResult? Function( String itemId,  MeasurementUnit unit)?  changeUnit,TResult? Function( bool checked)?  setAllChecked,TResult? Function()?  deleteCheckedItems,TResult? Function( List<MealPlanEntity> plans)?  plansChanged,TResult? Function( String listId)?  selectList,TResult? Function( String name,  GroceryListSource source)?  createList,TResult? Function( RecipeEntity recipe,  String name,  double scale)?  createRecipeList,TResult? Function( String listId,  String name)?  renameList,TResult? Function( String listId)?  deleteList,TResult? Function( double scale)?  setRecipeScale,TResult? Function( List<GroceryListEntity> lists)?  listsChanged,TResult? Function( String listId)?  activeChanged,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Regenerate() when regenerate != null:
return regenerate();case _SelectPlans() when selectPlans != null:
return selectPlans(_that.planIds);case _ToggleItem() when toggleItem != null:
return toggleItem(_that.itemId);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that.name,_that.amount,_that.unit);case _RemoveItem() when removeItem != null:
return removeItem(_that.itemId);case _AddBuffer() when addBuffer != null:
return addBuffer(_that.itemId,_that.amount);case _AdjustSource() when adjustSource != null:
return adjustSource(_that.itemId,_that.sourceIndex,_that.amount);case _RemoveSource() when removeSource != null:
return removeSource(_that.itemId,_that.sourceIndex);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that.itemId,_that.unit);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that.checked);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems();case _PlansChanged() when plansChanged != null:
return plansChanged(_that.plans);case _SelectList() when selectList != null:
return selectList(_that.listId);case _CreateList() when createList != null:
return createList(_that.name,_that.source);case _CreateRecipeList() when createRecipeList != null:
return createRecipeList(_that.recipe,_that.name,_that.scale);case _RenameList() when renameList != null:
return renameList(_that.listId,_that.name);case _DeleteList() when deleteList != null:
return deleteList(_that.listId);case _SetRecipeScale() when setRecipeScale != null:
return setRecipeScale(_that.scale);case _ListsChanged() when listsChanged != null:
return listsChanged(_that.lists);case _ActiveChanged() when activeChanged != null:
return activeChanged(_that.listId);case _:
  return null;

}
}

}

/// @nodoc


class _Init implements GroceryListEvent {
  const _Init();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Init);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GroceryListEvent.init()';
}


}




/// @nodoc


class _Regenerate implements GroceryListEvent {
  const _Regenerate();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Regenerate);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GroceryListEvent.regenerate()';
}


}




/// @nodoc


class _SelectPlans implements GroceryListEvent {
  const _SelectPlans(final  List<String> planIds): _planIds = planIds;
  

 final  List<String> _planIds;
 List<String> get planIds {
  if (_planIds is EqualUnmodifiableListView) return _planIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_planIds);
}


/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectPlansCopyWith<_SelectPlans> get copyWith => __$SelectPlansCopyWithImpl<_SelectPlans>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectPlans&&const DeepCollectionEquality().equals(other._planIds, _planIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_planIds));

@override
String toString() {
  return 'GroceryListEvent.selectPlans(planIds: $planIds)';
}


}

/// @nodoc
abstract mixin class _$SelectPlansCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$SelectPlansCopyWith(_SelectPlans value, $Res Function(_SelectPlans) _then) = __$SelectPlansCopyWithImpl;
@useResult
$Res call({
 List<String> planIds
});




}
/// @nodoc
class __$SelectPlansCopyWithImpl<$Res>
    implements _$SelectPlansCopyWith<$Res> {
  __$SelectPlansCopyWithImpl(this._self, this._then);

  final _SelectPlans _self;
  final $Res Function(_SelectPlans) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? planIds = null,}) {
  return _then(_SelectPlans(
null == planIds ? _self._planIds : planIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class _ToggleItem implements GroceryListEvent {
  const _ToggleItem(this.itemId);
  

 final  String itemId;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleItemCopyWith<_ToggleItem> get copyWith => __$ToggleItemCopyWithImpl<_ToggleItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleItem&&(identical(other.itemId, itemId) || other.itemId == itemId));
}


@override
int get hashCode => Object.hash(runtimeType,itemId);

@override
String toString() {
  return 'GroceryListEvent.toggleItem(itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class _$ToggleItemCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$ToggleItemCopyWith(_ToggleItem value, $Res Function(_ToggleItem) _then) = __$ToggleItemCopyWithImpl;
@useResult
$Res call({
 String itemId
});




}
/// @nodoc
class __$ToggleItemCopyWithImpl<$Res>
    implements _$ToggleItemCopyWith<$Res> {
  __$ToggleItemCopyWithImpl(this._self, this._then);

  final _ToggleItem _self;
  final $Res Function(_ToggleItem) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemId = null,}) {
  return _then(_ToggleItem(
null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddAdHocItem implements GroceryListEvent {
  const _AddAdHocItem(this.name, this.amount, this.unit);
  

 final  String name;
 final  double amount;
 final  MeasurementUnit unit;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddAdHocItemCopyWith<_AddAdHocItem> get copyWith => __$AddAdHocItemCopyWithImpl<_AddAdHocItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddAdHocItem&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,name,amount,unit);

@override
String toString() {
  return 'GroceryListEvent.addAdHocItem(name: $name, amount: $amount, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$AddAdHocItemCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$AddAdHocItemCopyWith(_AddAdHocItem value, $Res Function(_AddAdHocItem) _then) = __$AddAdHocItemCopyWithImpl;
@useResult
$Res call({
 String name, double amount, MeasurementUnit unit
});




}
/// @nodoc
class __$AddAdHocItemCopyWithImpl<$Res>
    implements _$AddAdHocItemCopyWith<$Res> {
  __$AddAdHocItemCopyWithImpl(this._self, this._then);

  final _AddAdHocItem _self;
  final $Res Function(_AddAdHocItem) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? amount = null,Object? unit = null,}) {
  return _then(_AddAdHocItem(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasurementUnit,
  ));
}


}

/// @nodoc


class _RemoveItem implements GroceryListEvent {
  const _RemoveItem(this.itemId);
  

 final  String itemId;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveItemCopyWith<_RemoveItem> get copyWith => __$RemoveItemCopyWithImpl<_RemoveItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveItem&&(identical(other.itemId, itemId) || other.itemId == itemId));
}


@override
int get hashCode => Object.hash(runtimeType,itemId);

@override
String toString() {
  return 'GroceryListEvent.removeItem(itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class _$RemoveItemCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$RemoveItemCopyWith(_RemoveItem value, $Res Function(_RemoveItem) _then) = __$RemoveItemCopyWithImpl;
@useResult
$Res call({
 String itemId
});




}
/// @nodoc
class __$RemoveItemCopyWithImpl<$Res>
    implements _$RemoveItemCopyWith<$Res> {
  __$RemoveItemCopyWithImpl(this._self, this._then);

  final _RemoveItem _self;
  final $Res Function(_RemoveItem) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemId = null,}) {
  return _then(_RemoveItem(
null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddBuffer implements GroceryListEvent {
  const _AddBuffer(this.itemId, this.amount);
  

 final  String itemId;
 final  double amount;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddBufferCopyWith<_AddBuffer> get copyWith => __$AddBufferCopyWithImpl<_AddBuffer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddBuffer&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,amount);

@override
String toString() {
  return 'GroceryListEvent.addBuffer(itemId: $itemId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$AddBufferCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$AddBufferCopyWith(_AddBuffer value, $Res Function(_AddBuffer) _then) = __$AddBufferCopyWithImpl;
@useResult
$Res call({
 String itemId, double amount
});




}
/// @nodoc
class __$AddBufferCopyWithImpl<$Res>
    implements _$AddBufferCopyWith<$Res> {
  __$AddBufferCopyWithImpl(this._self, this._then);

  final _AddBuffer _self;
  final $Res Function(_AddBuffer) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? amount = null,}) {
  return _then(_AddBuffer(
null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class _AdjustSource implements GroceryListEvent {
  const _AdjustSource(this.itemId, this.sourceIndex, this.amount);
  

 final  String itemId;
 final  int sourceIndex;
 final  double amount;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdjustSourceCopyWith<_AdjustSource> get copyWith => __$AdjustSourceCopyWithImpl<_AdjustSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdjustSource&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.sourceIndex, sourceIndex) || other.sourceIndex == sourceIndex)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,sourceIndex,amount);

@override
String toString() {
  return 'GroceryListEvent.adjustSource(itemId: $itemId, sourceIndex: $sourceIndex, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$AdjustSourceCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$AdjustSourceCopyWith(_AdjustSource value, $Res Function(_AdjustSource) _then) = __$AdjustSourceCopyWithImpl;
@useResult
$Res call({
 String itemId, int sourceIndex, double amount
});




}
/// @nodoc
class __$AdjustSourceCopyWithImpl<$Res>
    implements _$AdjustSourceCopyWith<$Res> {
  __$AdjustSourceCopyWithImpl(this._self, this._then);

  final _AdjustSource _self;
  final $Res Function(_AdjustSource) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? sourceIndex = null,Object? amount = null,}) {
  return _then(_AdjustSource(
null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,null == sourceIndex ? _self.sourceIndex : sourceIndex // ignore: cast_nullable_to_non_nullable
as int,null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class _RemoveSource implements GroceryListEvent {
  const _RemoveSource(this.itemId, this.sourceIndex);
  

 final  String itemId;
 final  int sourceIndex;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveSourceCopyWith<_RemoveSource> get copyWith => __$RemoveSourceCopyWithImpl<_RemoveSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveSource&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.sourceIndex, sourceIndex) || other.sourceIndex == sourceIndex));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,sourceIndex);

@override
String toString() {
  return 'GroceryListEvent.removeSource(itemId: $itemId, sourceIndex: $sourceIndex)';
}


}

/// @nodoc
abstract mixin class _$RemoveSourceCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$RemoveSourceCopyWith(_RemoveSource value, $Res Function(_RemoveSource) _then) = __$RemoveSourceCopyWithImpl;
@useResult
$Res call({
 String itemId, int sourceIndex
});




}
/// @nodoc
class __$RemoveSourceCopyWithImpl<$Res>
    implements _$RemoveSourceCopyWith<$Res> {
  __$RemoveSourceCopyWithImpl(this._self, this._then);

  final _RemoveSource _self;
  final $Res Function(_RemoveSource) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? sourceIndex = null,}) {
  return _then(_RemoveSource(
null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,null == sourceIndex ? _self.sourceIndex : sourceIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _ChangeUnit implements GroceryListEvent {
  const _ChangeUnit(this.itemId, this.unit);
  

 final  String itemId;
 final  MeasurementUnit unit;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeUnitCopyWith<_ChangeUnit> get copyWith => __$ChangeUnitCopyWithImpl<_ChangeUnit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangeUnit&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,unit);

@override
String toString() {
  return 'GroceryListEvent.changeUnit(itemId: $itemId, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$ChangeUnitCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$ChangeUnitCopyWith(_ChangeUnit value, $Res Function(_ChangeUnit) _then) = __$ChangeUnitCopyWithImpl;
@useResult
$Res call({
 String itemId, MeasurementUnit unit
});




}
/// @nodoc
class __$ChangeUnitCopyWithImpl<$Res>
    implements _$ChangeUnitCopyWith<$Res> {
  __$ChangeUnitCopyWithImpl(this._self, this._then);

  final _ChangeUnit _self;
  final $Res Function(_ChangeUnit) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? itemId = null,Object? unit = null,}) {
  return _then(_ChangeUnit(
null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasurementUnit,
  ));
}


}

/// @nodoc


class _SetAllChecked implements GroceryListEvent {
  const _SetAllChecked(this.checked);
  

 final  bool checked;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetAllCheckedCopyWith<_SetAllChecked> get copyWith => __$SetAllCheckedCopyWithImpl<_SetAllChecked>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetAllChecked&&(identical(other.checked, checked) || other.checked == checked));
}


@override
int get hashCode => Object.hash(runtimeType,checked);

@override
String toString() {
  return 'GroceryListEvent.setAllChecked(checked: $checked)';
}


}

/// @nodoc
abstract mixin class _$SetAllCheckedCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$SetAllCheckedCopyWith(_SetAllChecked value, $Res Function(_SetAllChecked) _then) = __$SetAllCheckedCopyWithImpl;
@useResult
$Res call({
 bool checked
});




}
/// @nodoc
class __$SetAllCheckedCopyWithImpl<$Res>
    implements _$SetAllCheckedCopyWith<$Res> {
  __$SetAllCheckedCopyWithImpl(this._self, this._then);

  final _SetAllChecked _self;
  final $Res Function(_SetAllChecked) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? checked = null,}) {
  return _then(_SetAllChecked(
null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _DeleteCheckedItems implements GroceryListEvent {
  const _DeleteCheckedItems();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteCheckedItems);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GroceryListEvent.deleteCheckedItems()';
}


}




/// @nodoc


class _PlansChanged implements GroceryListEvent {
  const _PlansChanged(final  List<MealPlanEntity> plans): _plans = plans;
  

 final  List<MealPlanEntity> _plans;
 List<MealPlanEntity> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}


/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlansChangedCopyWith<_PlansChanged> get copyWith => __$PlansChangedCopyWithImpl<_PlansChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlansChanged&&const DeepCollectionEquality().equals(other._plans, _plans));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_plans));

@override
String toString() {
  return 'GroceryListEvent.plansChanged(plans: $plans)';
}


}

/// @nodoc
abstract mixin class _$PlansChangedCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$PlansChangedCopyWith(_PlansChanged value, $Res Function(_PlansChanged) _then) = __$PlansChangedCopyWithImpl;
@useResult
$Res call({
 List<MealPlanEntity> plans
});




}
/// @nodoc
class __$PlansChangedCopyWithImpl<$Res>
    implements _$PlansChangedCopyWith<$Res> {
  __$PlansChangedCopyWithImpl(this._self, this._then);

  final _PlansChanged _self;
  final $Res Function(_PlansChanged) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? plans = null,}) {
  return _then(_PlansChanged(
null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<MealPlanEntity>,
  ));
}


}

/// @nodoc


class _SelectList implements GroceryListEvent {
  const _SelectList(this.listId);
  

 final  String listId;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectListCopyWith<_SelectList> get copyWith => __$SelectListCopyWithImpl<_SelectList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectList&&(identical(other.listId, listId) || other.listId == listId));
}


@override
int get hashCode => Object.hash(runtimeType,listId);

@override
String toString() {
  return 'GroceryListEvent.selectList(listId: $listId)';
}


}

/// @nodoc
abstract mixin class _$SelectListCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$SelectListCopyWith(_SelectList value, $Res Function(_SelectList) _then) = __$SelectListCopyWithImpl;
@useResult
$Res call({
 String listId
});




}
/// @nodoc
class __$SelectListCopyWithImpl<$Res>
    implements _$SelectListCopyWith<$Res> {
  __$SelectListCopyWithImpl(this._self, this._then);

  final _SelectList _self;
  final $Res Function(_SelectList) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? listId = null,}) {
  return _then(_SelectList(
null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _CreateList implements GroceryListEvent {
  const _CreateList(this.name, this.source);
  

 final  String name;
 final  GroceryListSource source;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateListCopyWith<_CreateList> get copyWith => __$CreateListCopyWithImpl<_CreateList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateList&&(identical(other.name, name) || other.name == name)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode => Object.hash(runtimeType,name,source);

@override
String toString() {
  return 'GroceryListEvent.createList(name: $name, source: $source)';
}


}

/// @nodoc
abstract mixin class _$CreateListCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$CreateListCopyWith(_CreateList value, $Res Function(_CreateList) _then) = __$CreateListCopyWithImpl;
@useResult
$Res call({
 String name, GroceryListSource source
});




}
/// @nodoc
class __$CreateListCopyWithImpl<$Res>
    implements _$CreateListCopyWith<$Res> {
  __$CreateListCopyWithImpl(this._self, this._then);

  final _CreateList _self;
  final $Res Function(_CreateList) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? source = null,}) {
  return _then(_CreateList(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as GroceryListSource,
  ));
}


}

/// @nodoc


class _CreateRecipeList implements GroceryListEvent {
  const _CreateRecipeList(this.recipe, this.name, this.scale);
  

 final  RecipeEntity recipe;
 final  String name;
 final  double scale;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateRecipeListCopyWith<_CreateRecipeList> get copyWith => __$CreateRecipeListCopyWithImpl<_CreateRecipeList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateRecipeList&&(identical(other.recipe, recipe) || other.recipe == recipe)&&(identical(other.name, name) || other.name == name)&&(identical(other.scale, scale) || other.scale == scale));
}


@override
int get hashCode => Object.hash(runtimeType,recipe,name,scale);

@override
String toString() {
  return 'GroceryListEvent.createRecipeList(recipe: $recipe, name: $name, scale: $scale)';
}


}

/// @nodoc
abstract mixin class _$CreateRecipeListCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$CreateRecipeListCopyWith(_CreateRecipeList value, $Res Function(_CreateRecipeList) _then) = __$CreateRecipeListCopyWithImpl;
@useResult
$Res call({
 RecipeEntity recipe, String name, double scale
});




}
/// @nodoc
class __$CreateRecipeListCopyWithImpl<$Res>
    implements _$CreateRecipeListCopyWith<$Res> {
  __$CreateRecipeListCopyWithImpl(this._self, this._then);

  final _CreateRecipeList _self;
  final $Res Function(_CreateRecipeList) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipe = null,Object? name = null,Object? scale = null,}) {
  return _then(_CreateRecipeList(
null == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as RecipeEntity,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class _RenameList implements GroceryListEvent {
  const _RenameList(this.listId, this.name);
  

 final  String listId;
 final  String name;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RenameListCopyWith<_RenameList> get copyWith => __$RenameListCopyWithImpl<_RenameList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RenameList&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,listId,name);

@override
String toString() {
  return 'GroceryListEvent.renameList(listId: $listId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$RenameListCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$RenameListCopyWith(_RenameList value, $Res Function(_RenameList) _then) = __$RenameListCopyWithImpl;
@useResult
$Res call({
 String listId, String name
});




}
/// @nodoc
class __$RenameListCopyWithImpl<$Res>
    implements _$RenameListCopyWith<$Res> {
  __$RenameListCopyWithImpl(this._self, this._then);

  final _RenameList _self;
  final $Res Function(_RenameList) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? listId = null,Object? name = null,}) {
  return _then(_RenameList(
null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeleteList implements GroceryListEvent {
  const _DeleteList(this.listId);
  

 final  String listId;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteListCopyWith<_DeleteList> get copyWith => __$DeleteListCopyWithImpl<_DeleteList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteList&&(identical(other.listId, listId) || other.listId == listId));
}


@override
int get hashCode => Object.hash(runtimeType,listId);

@override
String toString() {
  return 'GroceryListEvent.deleteList(listId: $listId)';
}


}

/// @nodoc
abstract mixin class _$DeleteListCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$DeleteListCopyWith(_DeleteList value, $Res Function(_DeleteList) _then) = __$DeleteListCopyWithImpl;
@useResult
$Res call({
 String listId
});




}
/// @nodoc
class __$DeleteListCopyWithImpl<$Res>
    implements _$DeleteListCopyWith<$Res> {
  __$DeleteListCopyWithImpl(this._self, this._then);

  final _DeleteList _self;
  final $Res Function(_DeleteList) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? listId = null,}) {
  return _then(_DeleteList(
null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SetRecipeScale implements GroceryListEvent {
  const _SetRecipeScale(this.scale);
  

 final  double scale;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetRecipeScaleCopyWith<_SetRecipeScale> get copyWith => __$SetRecipeScaleCopyWithImpl<_SetRecipeScale>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetRecipeScale&&(identical(other.scale, scale) || other.scale == scale));
}


@override
int get hashCode => Object.hash(runtimeType,scale);

@override
String toString() {
  return 'GroceryListEvent.setRecipeScale(scale: $scale)';
}


}

/// @nodoc
abstract mixin class _$SetRecipeScaleCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$SetRecipeScaleCopyWith(_SetRecipeScale value, $Res Function(_SetRecipeScale) _then) = __$SetRecipeScaleCopyWithImpl;
@useResult
$Res call({
 double scale
});




}
/// @nodoc
class __$SetRecipeScaleCopyWithImpl<$Res>
    implements _$SetRecipeScaleCopyWith<$Res> {
  __$SetRecipeScaleCopyWithImpl(this._self, this._then);

  final _SetRecipeScale _self;
  final $Res Function(_SetRecipeScale) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? scale = null,}) {
  return _then(_SetRecipeScale(
null == scale ? _self.scale : scale // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc


class _ListsChanged implements GroceryListEvent {
  const _ListsChanged(final  List<GroceryListEntity> lists): _lists = lists;
  

 final  List<GroceryListEntity> _lists;
 List<GroceryListEntity> get lists {
  if (_lists is EqualUnmodifiableListView) return _lists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lists);
}


/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListsChangedCopyWith<_ListsChanged> get copyWith => __$ListsChangedCopyWithImpl<_ListsChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListsChanged&&const DeepCollectionEquality().equals(other._lists, _lists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_lists));

@override
String toString() {
  return 'GroceryListEvent.listsChanged(lists: $lists)';
}


}

/// @nodoc
abstract mixin class _$ListsChangedCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$ListsChangedCopyWith(_ListsChanged value, $Res Function(_ListsChanged) _then) = __$ListsChangedCopyWithImpl;
@useResult
$Res call({
 List<GroceryListEntity> lists
});




}
/// @nodoc
class __$ListsChangedCopyWithImpl<$Res>
    implements _$ListsChangedCopyWith<$Res> {
  __$ListsChangedCopyWithImpl(this._self, this._then);

  final _ListsChanged _self;
  final $Res Function(_ListsChanged) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? lists = null,}) {
  return _then(_ListsChanged(
null == lists ? _self._lists : lists // ignore: cast_nullable_to_non_nullable
as List<GroceryListEntity>,
  ));
}


}

/// @nodoc


class _ActiveChanged implements GroceryListEvent {
  const _ActiveChanged(this.listId);
  

 final  String listId;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveChangedCopyWith<_ActiveChanged> get copyWith => __$ActiveChangedCopyWithImpl<_ActiveChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveChanged&&(identical(other.listId, listId) || other.listId == listId));
}


@override
int get hashCode => Object.hash(runtimeType,listId);

@override
String toString() {
  return 'GroceryListEvent.activeChanged(listId: $listId)';
}


}

/// @nodoc
abstract mixin class _$ActiveChangedCopyWith<$Res> implements $GroceryListEventCopyWith<$Res> {
  factory _$ActiveChangedCopyWith(_ActiveChanged value, $Res Function(_ActiveChanged) _then) = __$ActiveChangedCopyWithImpl;
@useResult
$Res call({
 String listId
});




}
/// @nodoc
class __$ActiveChangedCopyWithImpl<$Res>
    implements _$ActiveChangedCopyWith<$Res> {
  __$ActiveChangedCopyWithImpl(this._self, this._then);

  final _ActiveChanged _self;
  final $Res Function(_ActiveChanged) _then;

/// Create a copy of GroceryListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? listId = null,}) {
  return _then(_ActiveChanged(
null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$GroceryListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GroceryListState()';
}


}

/// @nodoc
class $GroceryListStateCopyWith<$Res>  {
$GroceryListStateCopyWith(GroceryListState _, $Res Function(GroceryListState) __);
}


/// Adds pattern-matching-related methods to [GroceryListState].
extension GroceryListStatePatterns on GroceryListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GroceryListLoading value)?  loading,TResult Function( GroceryListLoaded value)?  loaded,TResult Function( GroceryListError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GroceryListLoading() when loading != null:
return loading(_that);case GroceryListLoaded() when loaded != null:
return loaded(_that);case GroceryListError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GroceryListLoading value)  loading,required TResult Function( GroceryListLoaded value)  loaded,required TResult Function( GroceryListError value)  errorMessage,}){
final _that = this;
switch (_that) {
case GroceryListLoading():
return loading(_that);case GroceryListLoaded():
return loaded(_that);case GroceryListError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GroceryListLoading value)?  loading,TResult? Function( GroceryListLoaded value)?  loaded,TResult? Function( GroceryListError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case GroceryListLoading() when loading != null:
return loading(_that);case GroceryListLoaded() when loaded != null:
return loaded(_that);case GroceryListError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( GroceryListEntity list,  List<MealPlanEntity> plans,  List<GroceryListEntity> lists)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GroceryListLoading() when loading != null:
return loading();case GroceryListLoaded() when loaded != null:
return loaded(_that.list,_that.plans,_that.lists);case GroceryListError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( GroceryListEntity list,  List<MealPlanEntity> plans,  List<GroceryListEntity> lists)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case GroceryListLoading():
return loading();case GroceryListLoaded():
return loaded(_that.list,_that.plans,_that.lists);case GroceryListError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( GroceryListEntity list,  List<MealPlanEntity> plans,  List<GroceryListEntity> lists)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case GroceryListLoading() when loading != null:
return loading();case GroceryListLoaded() when loaded != null:
return loaded(_that.list,_that.plans,_that.lists);case GroceryListError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class GroceryListLoading implements GroceryListState {
  const GroceryListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GroceryListState.loading()';
}


}




/// @nodoc


class GroceryListLoaded implements GroceryListState {
  const GroceryListLoaded(this.list, {final  List<MealPlanEntity> plans = const <MealPlanEntity>[], final  List<GroceryListEntity> lists = const <GroceryListEntity>[]}): _plans = plans,_lists = lists;
  

 final  GroceryListEntity list;
 final  List<MealPlanEntity> _plans;
@JsonKey() List<MealPlanEntity> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}

 final  List<GroceryListEntity> _lists;
@JsonKey() List<GroceryListEntity> get lists {
  if (_lists is EqualUnmodifiableListView) return _lists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lists);
}


/// Create a copy of GroceryListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryListLoadedCopyWith<GroceryListLoaded> get copyWith => _$GroceryListLoadedCopyWithImpl<GroceryListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListLoaded&&(identical(other.list, list) || other.list == list)&&const DeepCollectionEquality().equals(other._plans, _plans)&&const DeepCollectionEquality().equals(other._lists, _lists));
}


@override
int get hashCode => Object.hash(runtimeType,list,const DeepCollectionEquality().hash(_plans),const DeepCollectionEquality().hash(_lists));

@override
String toString() {
  return 'GroceryListState.loaded(list: $list, plans: $plans, lists: $lists)';
}


}

/// @nodoc
abstract mixin class $GroceryListLoadedCopyWith<$Res> implements $GroceryListStateCopyWith<$Res> {
  factory $GroceryListLoadedCopyWith(GroceryListLoaded value, $Res Function(GroceryListLoaded) _then) = _$GroceryListLoadedCopyWithImpl;
@useResult
$Res call({
 GroceryListEntity list, List<MealPlanEntity> plans, List<GroceryListEntity> lists
});




}
/// @nodoc
class _$GroceryListLoadedCopyWithImpl<$Res>
    implements $GroceryListLoadedCopyWith<$Res> {
  _$GroceryListLoadedCopyWithImpl(this._self, this._then);

  final GroceryListLoaded _self;
  final $Res Function(GroceryListLoaded) _then;

/// Create a copy of GroceryListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? list = null,Object? plans = null,Object? lists = null,}) {
  return _then(GroceryListLoaded(
null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as GroceryListEntity,plans: null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<MealPlanEntity>,lists: null == lists ? _self._lists : lists // ignore: cast_nullable_to_non_nullable
as List<GroceryListEntity>,
  ));
}


}

/// @nodoc


class GroceryListError implements GroceryListState {
  const GroceryListError(this.error);
  

 final  String error;

/// Create a copy of GroceryListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryListErrorCopyWith<GroceryListError> get copyWith => _$GroceryListErrorCopyWithImpl<GroceryListError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'GroceryListState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $GroceryListErrorCopyWith<$Res> implements $GroceryListStateCopyWith<$Res> {
  factory $GroceryListErrorCopyWith(GroceryListError value, $Res Function(GroceryListError) _then) = _$GroceryListErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$GroceryListErrorCopyWithImpl<$Res>
    implements $GroceryListErrorCopyWith<$Res> {
  _$GroceryListErrorCopyWithImpl(this._self, this._then);

  final GroceryListError _self;
  final $Res Function(GroceryListError) _then;

/// Create a copy of GroceryListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(GroceryListError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
