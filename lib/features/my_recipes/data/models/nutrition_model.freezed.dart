// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NutritionModel {

@HiveField(0) int get calories;@HiveField(1) double get proteinGrams;@HiveField(2) double get carbsGrams;@HiveField(3) double get fatGrams;
/// Create a copy of NutritionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NutritionModelCopyWith<NutritionModel> get copyWith => _$NutritionModelCopyWithImpl<NutritionModel>(this as NutritionModel, _$identity);

  /// Serializes this NutritionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NutritionModel&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteinGrams, proteinGrams) || other.proteinGrams == proteinGrams)&&(identical(other.carbsGrams, carbsGrams) || other.carbsGrams == carbsGrams)&&(identical(other.fatGrams, fatGrams) || other.fatGrams == fatGrams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,calories,proteinGrams,carbsGrams,fatGrams);

@override
String toString() {
  return 'NutritionModel(calories: $calories, proteinGrams: $proteinGrams, carbsGrams: $carbsGrams, fatGrams: $fatGrams)';
}


}

/// @nodoc
abstract mixin class $NutritionModelCopyWith<$Res>  {
  factory $NutritionModelCopyWith(NutritionModel value, $Res Function(NutritionModel) _then) = _$NutritionModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) int calories,@HiveField(1) double proteinGrams,@HiveField(2) double carbsGrams,@HiveField(3) double fatGrams
});




}
/// @nodoc
class _$NutritionModelCopyWithImpl<$Res>
    implements $NutritionModelCopyWith<$Res> {
  _$NutritionModelCopyWithImpl(this._self, this._then);

  final NutritionModel _self;
  final $Res Function(NutritionModel) _then;

/// Create a copy of NutritionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? calories = null,Object? proteinGrams = null,Object? carbsGrams = null,Object? fatGrams = null,}) {
  return _then(_self.copyWith(
calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as int,proteinGrams: null == proteinGrams ? _self.proteinGrams : proteinGrams // ignore: cast_nullable_to_non_nullable
as double,carbsGrams: null == carbsGrams ? _self.carbsGrams : carbsGrams // ignore: cast_nullable_to_non_nullable
as double,fatGrams: null == fatGrams ? _self.fatGrams : fatGrams // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [NutritionModel].
extension NutritionModelPatterns on NutritionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NutritionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NutritionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NutritionModel value)  $default,){
final _that = this;
switch (_that) {
case _NutritionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NutritionModel value)?  $default,){
final _that = this;
switch (_that) {
case _NutritionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  int calories, @HiveField(1)  double proteinGrams, @HiveField(2)  double carbsGrams, @HiveField(3)  double fatGrams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NutritionModel() when $default != null:
return $default(_that.calories,_that.proteinGrams,_that.carbsGrams,_that.fatGrams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  int calories, @HiveField(1)  double proteinGrams, @HiveField(2)  double carbsGrams, @HiveField(3)  double fatGrams)  $default,) {final _that = this;
switch (_that) {
case _NutritionModel():
return $default(_that.calories,_that.proteinGrams,_that.carbsGrams,_that.fatGrams);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  int calories, @HiveField(1)  double proteinGrams, @HiveField(2)  double carbsGrams, @HiveField(3)  double fatGrams)?  $default,) {final _that = this;
switch (_that) {
case _NutritionModel() when $default != null:
return $default(_that.calories,_that.proteinGrams,_that.carbsGrams,_that.fatGrams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NutritionModel implements NutritionModel {
  const _NutritionModel({@HiveField(0) required this.calories, @HiveField(1) this.proteinGrams = 0, @HiveField(2) this.carbsGrams = 0, @HiveField(3) this.fatGrams = 0});
  factory _NutritionModel.fromJson(Map<String, dynamic> json) => _$NutritionModelFromJson(json);

@override@HiveField(0) final  int calories;
@override@JsonKey()@HiveField(1) final  double proteinGrams;
@override@JsonKey()@HiveField(2) final  double carbsGrams;
@override@JsonKey()@HiveField(3) final  double fatGrams;

/// Create a copy of NutritionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NutritionModelCopyWith<_NutritionModel> get copyWith => __$NutritionModelCopyWithImpl<_NutritionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NutritionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NutritionModel&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteinGrams, proteinGrams) || other.proteinGrams == proteinGrams)&&(identical(other.carbsGrams, carbsGrams) || other.carbsGrams == carbsGrams)&&(identical(other.fatGrams, fatGrams) || other.fatGrams == fatGrams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,calories,proteinGrams,carbsGrams,fatGrams);

@override
String toString() {
  return 'NutritionModel(calories: $calories, proteinGrams: $proteinGrams, carbsGrams: $carbsGrams, fatGrams: $fatGrams)';
}


}

/// @nodoc
abstract mixin class _$NutritionModelCopyWith<$Res> implements $NutritionModelCopyWith<$Res> {
  factory _$NutritionModelCopyWith(_NutritionModel value, $Res Function(_NutritionModel) _then) = __$NutritionModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) int calories,@HiveField(1) double proteinGrams,@HiveField(2) double carbsGrams,@HiveField(3) double fatGrams
});




}
/// @nodoc
class __$NutritionModelCopyWithImpl<$Res>
    implements _$NutritionModelCopyWith<$Res> {
  __$NutritionModelCopyWithImpl(this._self, this._then);

  final _NutritionModel _self;
  final $Res Function(_NutritionModel) _then;

/// Create a copy of NutritionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? calories = null,Object? proteinGrams = null,Object? carbsGrams = null,Object? fatGrams = null,}) {
  return _then(_NutritionModel(
calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as int,proteinGrams: null == proteinGrams ? _self.proteinGrams : proteinGrams // ignore: cast_nullable_to_non_nullable
as double,carbsGrams: null == carbsGrams ? _self.carbsGrams : carbsGrams // ignore: cast_nullable_to_non_nullable
as double,fatGrams: null == fatGrams ? _self.fatGrams : fatGrams // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
