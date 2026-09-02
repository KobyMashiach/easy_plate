// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealModel {

@HiveField(0) String get id;@HiveField(1) int get weekday;@HiveField(2) String get name;@HiveField(3) int get order;@HiveField(4) List<MealItemModel> get items;
/// Create a copy of MealModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealModelCopyWith<MealModel> get copyWith => _$MealModelCopyWithImpl<MealModel>(this as MealModel, _$identity);

  /// Serializes this MealModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealModel&&(identical(other.id, id) || other.id == id)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,weekday,name,order,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'MealModel(id: $id, weekday: $weekday, name: $name, order: $order, items: $items)';
}


}

/// @nodoc
abstract mixin class $MealModelCopyWith<$Res>  {
  factory $MealModelCopyWith(MealModel value, $Res Function(MealModel) _then) = _$MealModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) int weekday,@HiveField(2) String name,@HiveField(3) int order,@HiveField(4) List<MealItemModel> items
});




}
/// @nodoc
class _$MealModelCopyWithImpl<$Res>
    implements $MealModelCopyWith<$Res> {
  _$MealModelCopyWithImpl(this._self, this._then);

  final MealModel _self;
  final $Res Function(MealModel) _then;

/// Create a copy of MealModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? weekday = null,Object? name = null,Object? order = null,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealItemModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [MealModel].
extension MealModelPatterns on MealModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealModel value)  $default,){
final _that = this;
switch (_that) {
case _MealModel():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealModel value)?  $default,){
final _that = this;
switch (_that) {
case _MealModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  int weekday, @HiveField(2)  String name, @HiveField(3)  int order, @HiveField(4)  List<MealItemModel> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealModel() when $default != null:
return $default(_that.id,_that.weekday,_that.name,_that.order,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  int weekday, @HiveField(2)  String name, @HiveField(3)  int order, @HiveField(4)  List<MealItemModel> items)  $default,) {final _that = this;
switch (_that) {
case _MealModel():
return $default(_that.id,_that.weekday,_that.name,_that.order,_that.items);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  int weekday, @HiveField(2)  String name, @HiveField(3)  int order, @HiveField(4)  List<MealItemModel> items)?  $default,) {final _that = this;
switch (_that) {
case _MealModel() when $default != null:
return $default(_that.id,_that.weekday,_that.name,_that.order,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealModel implements MealModel {
  const _MealModel({@HiveField(0) required this.id, @HiveField(1) required this.weekday, @HiveField(2) required this.name, @HiveField(3) required this.order, @HiveField(4) required final  List<MealItemModel> items}): _items = items;
  factory _MealModel.fromJson(Map<String, dynamic> json) => _$MealModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  int weekday;
@override@HiveField(2) final  String name;
@override@HiveField(3) final  int order;
 final  List<MealItemModel> _items;
@override@HiveField(4) List<MealItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MealModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealModelCopyWith<_MealModel> get copyWith => __$MealModelCopyWithImpl<_MealModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealModel&&(identical(other.id, id) || other.id == id)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,weekday,name,order,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'MealModel(id: $id, weekday: $weekday, name: $name, order: $order, items: $items)';
}


}

/// @nodoc
abstract mixin class _$MealModelCopyWith<$Res> implements $MealModelCopyWith<$Res> {
  factory _$MealModelCopyWith(_MealModel value, $Res Function(_MealModel) _then) = __$MealModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) int weekday,@HiveField(2) String name,@HiveField(3) int order,@HiveField(4) List<MealItemModel> items
});




}
/// @nodoc
class __$MealModelCopyWithImpl<$Res>
    implements _$MealModelCopyWith<$Res> {
  __$MealModelCopyWithImpl(this._self, this._then);

  final _MealModel _self;
  final $Res Function(_MealModel) _then;

/// Create a copy of MealModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? weekday = null,Object? name = null,Object? order = null,Object? items = null,}) {
  return _then(_MealModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealItemModel>,
  ));
}


}

// dart format on
