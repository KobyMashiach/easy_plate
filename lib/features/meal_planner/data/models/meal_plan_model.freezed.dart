// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealPlanModel {

@HiveField(0) String get id;@HiveField(1) String get name;@HiveField(2) List<MealModel> get meals;@HiveField(3) DateTime get createdAt;
/// Create a copy of MealPlanModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealPlanModelCopyWith<MealPlanModel> get copyWith => _$MealPlanModelCopyWithImpl<MealPlanModel>(this as MealPlanModel, _$identity);

  /// Serializes this MealPlanModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.meals, meals)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(meals),createdAt);

@override
String toString() {
  return 'MealPlanModel(id: $id, name: $name, meals: $meals, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MealPlanModelCopyWith<$Res>  {
  factory $MealPlanModelCopyWith(MealPlanModel value, $Res Function(MealPlanModel) _then) = _$MealPlanModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) List<MealModel> meals,@HiveField(3) DateTime createdAt
});




}
/// @nodoc
class _$MealPlanModelCopyWithImpl<$Res>
    implements $MealPlanModelCopyWith<$Res> {
  _$MealPlanModelCopyWithImpl(this._self, this._then);

  final MealPlanModel _self;
  final $Res Function(MealPlanModel) _then;

/// Create a copy of MealPlanModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? meals = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as List<MealModel>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MealPlanModel].
extension MealPlanModelPatterns on MealPlanModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealPlanModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealPlanModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealPlanModel value)  $default,){
final _that = this;
switch (_that) {
case _MealPlanModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealPlanModel value)?  $default,){
final _that = this;
switch (_that) {
case _MealPlanModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  List<MealModel> meals, @HiveField(3)  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealPlanModel() when $default != null:
return $default(_that.id,_that.name,_that.meals,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  List<MealModel> meals, @HiveField(3)  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MealPlanModel():
return $default(_that.id,_that.name,_that.meals,_that.createdAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  List<MealModel> meals, @HiveField(3)  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MealPlanModel() when $default != null:
return $default(_that.id,_that.name,_that.meals,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealPlanModel implements MealPlanModel {
  const _MealPlanModel({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) required final  List<MealModel> meals, @HiveField(3) required this.createdAt}): _meals = meals;
  factory _MealPlanModel.fromJson(Map<String, dynamic> json) => _$MealPlanModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String name;
 final  List<MealModel> _meals;
@override@HiveField(2) List<MealModel> get meals {
  if (_meals is EqualUnmodifiableListView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_meals);
}

@override@HiveField(3) final  DateTime createdAt;

/// Create a copy of MealPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealPlanModelCopyWith<_MealPlanModel> get copyWith => __$MealPlanModelCopyWithImpl<_MealPlanModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealPlanModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealPlanModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._meals, _meals)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_meals),createdAt);

@override
String toString() {
  return 'MealPlanModel(id: $id, name: $name, meals: $meals, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MealPlanModelCopyWith<$Res> implements $MealPlanModelCopyWith<$Res> {
  factory _$MealPlanModelCopyWith(_MealPlanModel value, $Res Function(_MealPlanModel) _then) = __$MealPlanModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) List<MealModel> meals,@HiveField(3) DateTime createdAt
});




}
/// @nodoc
class __$MealPlanModelCopyWithImpl<$Res>
    implements _$MealPlanModelCopyWith<$Res> {
  __$MealPlanModelCopyWithImpl(this._self, this._then);

  final _MealPlanModel _self;
  final $Res Function(_MealPlanModel) _then;

/// Create a copy of MealPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? meals = null,Object? createdAt = null,}) {
  return _then(_MealPlanModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,meals: null == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as List<MealModel>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
