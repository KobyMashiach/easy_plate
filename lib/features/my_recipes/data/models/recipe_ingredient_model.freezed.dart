// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_ingredient_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeIngredientModel {

@HiveField(0) String get name;@HiveField(1) double? get amount;@HiveField(2) MeasurementUnit get unit;
/// Create a copy of RecipeIngredientModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeIngredientModelCopyWith<RecipeIngredientModel> get copyWith => _$RecipeIngredientModelCopyWithImpl<RecipeIngredientModel>(this as RecipeIngredientModel, _$identity);

  /// Serializes this RecipeIngredientModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeIngredientModel&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,amount,unit);

@override
String toString() {
  return 'RecipeIngredientModel(name: $name, amount: $amount, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $RecipeIngredientModelCopyWith<$Res>  {
  factory $RecipeIngredientModelCopyWith(RecipeIngredientModel value, $Res Function(RecipeIngredientModel) _then) = _$RecipeIngredientModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String name,@HiveField(1) double? amount,@HiveField(2) MeasurementUnit unit
});




}
/// @nodoc
class _$RecipeIngredientModelCopyWithImpl<$Res>
    implements $RecipeIngredientModelCopyWith<$Res> {
  _$RecipeIngredientModelCopyWithImpl(this._self, this._then);

  final RecipeIngredientModel _self;
  final $Res Function(RecipeIngredientModel) _then;

/// Create a copy of RecipeIngredientModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? amount = freezed,Object? unit = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasurementUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeIngredientModel].
extension RecipeIngredientModelPatterns on RecipeIngredientModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeIngredientModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeIngredientModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeIngredientModel value)  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredientModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeIngredientModel value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeIngredientModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String name, @HiveField(1)  double? amount, @HiveField(2)  MeasurementUnit unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeIngredientModel() when $default != null:
return $default(_that.name,_that.amount,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String name, @HiveField(1)  double? amount, @HiveField(2)  MeasurementUnit unit)  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredientModel():
return $default(_that.name,_that.amount,_that.unit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String name, @HiveField(1)  double? amount, @HiveField(2)  MeasurementUnit unit)?  $default,) {final _that = this;
switch (_that) {
case _RecipeIngredientModel() when $default != null:
return $default(_that.name,_that.amount,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeIngredientModel implements RecipeIngredientModel {
  const _RecipeIngredientModel({@HiveField(0) required this.name, @HiveField(1) this.amount, @HiveField(2) this.unit = MeasurementUnit.unspecified});
  factory _RecipeIngredientModel.fromJson(Map<String, dynamic> json) => _$RecipeIngredientModelFromJson(json);

@override@HiveField(0) final  String name;
@override@HiveField(1) final  double? amount;
@override@JsonKey()@HiveField(2) final  MeasurementUnit unit;

/// Create a copy of RecipeIngredientModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeIngredientModelCopyWith<_RecipeIngredientModel> get copyWith => __$RecipeIngredientModelCopyWithImpl<_RecipeIngredientModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeIngredientModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeIngredientModel&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,amount,unit);

@override
String toString() {
  return 'RecipeIngredientModel(name: $name, amount: $amount, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$RecipeIngredientModelCopyWith<$Res> implements $RecipeIngredientModelCopyWith<$Res> {
  factory _$RecipeIngredientModelCopyWith(_RecipeIngredientModel value, $Res Function(_RecipeIngredientModel) _then) = __$RecipeIngredientModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String name,@HiveField(1) double? amount,@HiveField(2) MeasurementUnit unit
});




}
/// @nodoc
class __$RecipeIngredientModelCopyWithImpl<$Res>
    implements _$RecipeIngredientModelCopyWith<$Res> {
  __$RecipeIngredientModelCopyWithImpl(this._self, this._then);

  final _RecipeIngredientModel _self;
  final $Res Function(_RecipeIngredientModel) _then;

/// Create a copy of RecipeIngredientModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? amount = freezed,Object? unit = null,}) {
  return _then(_RecipeIngredientModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasurementUnit,
  ));
}


}

// dart format on
