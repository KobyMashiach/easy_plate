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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _Regenerate value)?  regenerate,TResult Function( _ToggleItem value)?  toggleItem,TResult Function( _AddAdHocItem value)?  addAdHocItem,TResult Function( _RemoveItem value)?  removeItem,TResult Function( _AddBuffer value)?  addBuffer,TResult Function( _AdjustSource value)?  adjustSource,TResult Function( _RemoveSource value)?  removeSource,TResult Function( _ChangeUnit value)?  changeUnit,TResult Function( _SetAllChecked value)?  setAllChecked,TResult Function( _DeleteCheckedItems value)?  deleteCheckedItems,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Regenerate() when regenerate != null:
return regenerate(_that);case _ToggleItem() when toggleItem != null:
return toggleItem(_that);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that);case _RemoveItem() when removeItem != null:
return removeItem(_that);case _AddBuffer() when addBuffer != null:
return addBuffer(_that);case _AdjustSource() when adjustSource != null:
return adjustSource(_that);case _RemoveSource() when removeSource != null:
return removeSource(_that);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _Regenerate value)  regenerate,required TResult Function( _ToggleItem value)  toggleItem,required TResult Function( _AddAdHocItem value)  addAdHocItem,required TResult Function( _RemoveItem value)  removeItem,required TResult Function( _AddBuffer value)  addBuffer,required TResult Function( _AdjustSource value)  adjustSource,required TResult Function( _RemoveSource value)  removeSource,required TResult Function( _ChangeUnit value)  changeUnit,required TResult Function( _SetAllChecked value)  setAllChecked,required TResult Function( _DeleteCheckedItems value)  deleteCheckedItems,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _Regenerate():
return regenerate(_that);case _ToggleItem():
return toggleItem(_that);case _AddAdHocItem():
return addAdHocItem(_that);case _RemoveItem():
return removeItem(_that);case _AddBuffer():
return addBuffer(_that);case _AdjustSource():
return adjustSource(_that);case _RemoveSource():
return removeSource(_that);case _ChangeUnit():
return changeUnit(_that);case _SetAllChecked():
return setAllChecked(_that);case _DeleteCheckedItems():
return deleteCheckedItems(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _Regenerate value)?  regenerate,TResult? Function( _ToggleItem value)?  toggleItem,TResult? Function( _AddAdHocItem value)?  addAdHocItem,TResult? Function( _RemoveItem value)?  removeItem,TResult? Function( _AddBuffer value)?  addBuffer,TResult? Function( _AdjustSource value)?  adjustSource,TResult? Function( _RemoveSource value)?  removeSource,TResult? Function( _ChangeUnit value)?  changeUnit,TResult? Function( _SetAllChecked value)?  setAllChecked,TResult? Function( _DeleteCheckedItems value)?  deleteCheckedItems,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Regenerate() when regenerate != null:
return regenerate(_that);case _ToggleItem() when toggleItem != null:
return toggleItem(_that);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that);case _RemoveItem() when removeItem != null:
return removeItem(_that);case _AddBuffer() when addBuffer != null:
return addBuffer(_that);case _AdjustSource() when adjustSource != null:
return adjustSource(_that);case _RemoveSource() when removeSource != null:
return removeSource(_that);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function()?  regenerate,TResult Function( String itemId)?  toggleItem,TResult Function( String name,  double amount,  MeasurementUnit unit)?  addAdHocItem,TResult Function( String itemId)?  removeItem,TResult Function( String itemId,  double amount)?  addBuffer,TResult Function( String itemId,  int sourceIndex,  double amount)?  adjustSource,TResult Function( String itemId,  int sourceIndex)?  removeSource,TResult Function( String itemId,  MeasurementUnit unit)?  changeUnit,TResult Function( bool checked)?  setAllChecked,TResult Function()?  deleteCheckedItems,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Regenerate() when regenerate != null:
return regenerate();case _ToggleItem() when toggleItem != null:
return toggleItem(_that.itemId);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that.name,_that.amount,_that.unit);case _RemoveItem() when removeItem != null:
return removeItem(_that.itemId);case _AddBuffer() when addBuffer != null:
return addBuffer(_that.itemId,_that.amount);case _AdjustSource() when adjustSource != null:
return adjustSource(_that.itemId,_that.sourceIndex,_that.amount);case _RemoveSource() when removeSource != null:
return removeSource(_that.itemId,_that.sourceIndex);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that.itemId,_that.unit);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that.checked);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function()  regenerate,required TResult Function( String itemId)  toggleItem,required TResult Function( String name,  double amount,  MeasurementUnit unit)  addAdHocItem,required TResult Function( String itemId)  removeItem,required TResult Function( String itemId,  double amount)  addBuffer,required TResult Function( String itemId,  int sourceIndex,  double amount)  adjustSource,required TResult Function( String itemId,  int sourceIndex)  removeSource,required TResult Function( String itemId,  MeasurementUnit unit)  changeUnit,required TResult Function( bool checked)  setAllChecked,required TResult Function()  deleteCheckedItems,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _Regenerate():
return regenerate();case _ToggleItem():
return toggleItem(_that.itemId);case _AddAdHocItem():
return addAdHocItem(_that.name,_that.amount,_that.unit);case _RemoveItem():
return removeItem(_that.itemId);case _AddBuffer():
return addBuffer(_that.itemId,_that.amount);case _AdjustSource():
return adjustSource(_that.itemId,_that.sourceIndex,_that.amount);case _RemoveSource():
return removeSource(_that.itemId,_that.sourceIndex);case _ChangeUnit():
return changeUnit(_that.itemId,_that.unit);case _SetAllChecked():
return setAllChecked(_that.checked);case _DeleteCheckedItems():
return deleteCheckedItems();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function()?  regenerate,TResult? Function( String itemId)?  toggleItem,TResult? Function( String name,  double amount,  MeasurementUnit unit)?  addAdHocItem,TResult? Function( String itemId)?  removeItem,TResult? Function( String itemId,  double amount)?  addBuffer,TResult? Function( String itemId,  int sourceIndex,  double amount)?  adjustSource,TResult? Function( String itemId,  int sourceIndex)?  removeSource,TResult? Function( String itemId,  MeasurementUnit unit)?  changeUnit,TResult? Function( bool checked)?  setAllChecked,TResult? Function()?  deleteCheckedItems,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Regenerate() when regenerate != null:
return regenerate();case _ToggleItem() when toggleItem != null:
return toggleItem(_that.itemId);case _AddAdHocItem() when addAdHocItem != null:
return addAdHocItem(_that.name,_that.amount,_that.unit);case _RemoveItem() when removeItem != null:
return removeItem(_that.itemId);case _AddBuffer() when addBuffer != null:
return addBuffer(_that.itemId,_that.amount);case _AdjustSource() when adjustSource != null:
return adjustSource(_that.itemId,_that.sourceIndex,_that.amount);case _RemoveSource() when removeSource != null:
return removeSource(_that.itemId,_that.sourceIndex);case _ChangeUnit() when changeUnit != null:
return changeUnit(_that.itemId,_that.unit);case _SetAllChecked() when setAllChecked != null:
return setAllChecked(_that.checked);case _DeleteCheckedItems() when deleteCheckedItems != null:
return deleteCheckedItems();case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( GroceryListEntity list)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GroceryListLoading() when loading != null:
return loading();case GroceryListLoaded() when loaded != null:
return loaded(_that.list);case GroceryListError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( GroceryListEntity list)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case GroceryListLoading():
return loading();case GroceryListLoaded():
return loaded(_that.list);case GroceryListError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( GroceryListEntity list)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case GroceryListLoading() when loading != null:
return loading();case GroceryListLoaded() when loaded != null:
return loaded(_that.list);case GroceryListError() when errorMessage != null:
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
  const GroceryListLoaded(this.list);
  

 final  GroceryListEntity list;

/// Create a copy of GroceryListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryListLoadedCopyWith<GroceryListLoaded> get copyWith => _$GroceryListLoadedCopyWithImpl<GroceryListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListLoaded&&(identical(other.list, list) || other.list == list));
}


@override
int get hashCode => Object.hash(runtimeType,list);

@override
String toString() {
  return 'GroceryListState.loaded(list: $list)';
}


}

/// @nodoc
abstract mixin class $GroceryListLoadedCopyWith<$Res> implements $GroceryListStateCopyWith<$Res> {
  factory $GroceryListLoadedCopyWith(GroceryListLoaded value, $Res Function(GroceryListLoaded) _then) = _$GroceryListLoadedCopyWithImpl;
@useResult
$Res call({
 GroceryListEntity list
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
@pragma('vm:prefer-inline') $Res call({Object? list = null,}) {
  return _then(GroceryListLoaded(
null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as GroceryListEntity,
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
