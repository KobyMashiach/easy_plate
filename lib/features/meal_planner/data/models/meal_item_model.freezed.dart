// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MealItemModel {

@HiveField(0) String get id;@HiveField(1) String? get recipeId;@HiveField(2) String? get freeText;
/// Create a copy of MealItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealItemModelCopyWith<MealItemModel> get copyWith => _$MealItemModelCopyWithImpl<MealItemModel>(this as MealItemModel, _$identity);

  /// Serializes this MealItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.freeText, freeText) || other.freeText == freeText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recipeId,freeText);

@override
String toString() {
  return 'MealItemModel(id: $id, recipeId: $recipeId, freeText: $freeText)';
}


}

/// @nodoc
abstract mixin class $MealItemModelCopyWith<$Res>  {
  factory $MealItemModelCopyWith(MealItemModel value, $Res Function(MealItemModel) _then) = _$MealItemModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String? recipeId,@HiveField(2) String? freeText
});




}
/// @nodoc
class _$MealItemModelCopyWithImpl<$Res>
    implements $MealItemModelCopyWith<$Res> {
  _$MealItemModelCopyWithImpl(this._self, this._then);

  final MealItemModel _self;
  final $Res Function(MealItemModel) _then;

/// Create a copy of MealItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recipeId = freezed,Object? freeText = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,freeText: freezed == freeText ? _self.freeText : freeText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MealItemModel].
extension MealItemModelPatterns on MealItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealItemModel value)  $default,){
final _that = this;
switch (_that) {
case _MealItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _MealItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String? recipeId, @HiveField(2)  String? freeText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealItemModel() when $default != null:
return $default(_that.id,_that.recipeId,_that.freeText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String? recipeId, @HiveField(2)  String? freeText)  $default,) {final _that = this;
switch (_that) {
case _MealItemModel():
return $default(_that.id,_that.recipeId,_that.freeText);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String? recipeId, @HiveField(2)  String? freeText)?  $default,) {final _that = this;
switch (_that) {
case _MealItemModel() when $default != null:
return $default(_that.id,_that.recipeId,_that.freeText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MealItemModel implements MealItemModel {
  const _MealItemModel({@HiveField(0) required this.id, @HiveField(1) this.recipeId, @HiveField(2) this.freeText});
  factory _MealItemModel.fromJson(Map<String, dynamic> json) => _$MealItemModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String? recipeId;
@override@HiveField(2) final  String? freeText;

/// Create a copy of MealItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealItemModelCopyWith<_MealItemModel> get copyWith => __$MealItemModelCopyWithImpl<_MealItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MealItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.freeText, freeText) || other.freeText == freeText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,recipeId,freeText);

@override
String toString() {
  return 'MealItemModel(id: $id, recipeId: $recipeId, freeText: $freeText)';
}


}

/// @nodoc
abstract mixin class _$MealItemModelCopyWith<$Res> implements $MealItemModelCopyWith<$Res> {
  factory _$MealItemModelCopyWith(_MealItemModel value, $Res Function(_MealItemModel) _then) = __$MealItemModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String? recipeId,@HiveField(2) String? freeText
});




}
/// @nodoc
class __$MealItemModelCopyWithImpl<$Res>
    implements _$MealItemModelCopyWith<$Res> {
  __$MealItemModelCopyWithImpl(this._self, this._then);

  final _MealItemModel _self;
  final $Res Function(_MealItemModel) _then;

/// Create a copy of MealItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recipeId = freezed,Object? freeText = freezed,}) {
  return _then(_MealItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,freeText: freezed == freeText ? _self.freeText : freeText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
