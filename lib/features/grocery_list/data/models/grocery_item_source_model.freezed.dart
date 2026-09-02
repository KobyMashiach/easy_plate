// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_item_source_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroceryItemSourceModel {

@HiveField(0) String? get recipeId;@HiveField(1) String get label;@HiveField(2) double get amount;
/// Create a copy of GroceryItemSourceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryItemSourceModelCopyWith<GroceryItemSourceModel> get copyWith => _$GroceryItemSourceModelCopyWithImpl<GroceryItemSourceModel>(this as GroceryItemSourceModel, _$identity);

  /// Serializes this GroceryItemSourceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryItemSourceModel&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recipeId,label,amount);

@override
String toString() {
  return 'GroceryItemSourceModel(recipeId: $recipeId, label: $label, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $GroceryItemSourceModelCopyWith<$Res>  {
  factory $GroceryItemSourceModelCopyWith(GroceryItemSourceModel value, $Res Function(GroceryItemSourceModel) _then) = _$GroceryItemSourceModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String? recipeId,@HiveField(1) String label,@HiveField(2) double amount
});




}
/// @nodoc
class _$GroceryItemSourceModelCopyWithImpl<$Res>
    implements $GroceryItemSourceModelCopyWith<$Res> {
  _$GroceryItemSourceModelCopyWithImpl(this._self, this._then);

  final GroceryItemSourceModel _self;
  final $Res Function(GroceryItemSourceModel) _then;

/// Create a copy of GroceryItemSourceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recipeId = freezed,Object? label = null,Object? amount = null,}) {
  return _then(_self.copyWith(
recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GroceryItemSourceModel].
extension GroceryItemSourceModelPatterns on GroceryItemSourceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroceryItemSourceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroceryItemSourceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroceryItemSourceModel value)  $default,){
final _that = this;
switch (_that) {
case _GroceryItemSourceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroceryItemSourceModel value)?  $default,){
final _that = this;
switch (_that) {
case _GroceryItemSourceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String? recipeId, @HiveField(1)  String label, @HiveField(2)  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroceryItemSourceModel() when $default != null:
return $default(_that.recipeId,_that.label,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String? recipeId, @HiveField(1)  String label, @HiveField(2)  double amount)  $default,) {final _that = this;
switch (_that) {
case _GroceryItemSourceModel():
return $default(_that.recipeId,_that.label,_that.amount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String? recipeId, @HiveField(1)  String label, @HiveField(2)  double amount)?  $default,) {final _that = this;
switch (_that) {
case _GroceryItemSourceModel() when $default != null:
return $default(_that.recipeId,_that.label,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroceryItemSourceModel implements GroceryItemSourceModel {
  const _GroceryItemSourceModel({@HiveField(0) this.recipeId, @HiveField(1) required this.label, @HiveField(2) required this.amount});
  factory _GroceryItemSourceModel.fromJson(Map<String, dynamic> json) => _$GroceryItemSourceModelFromJson(json);

@override@HiveField(0) final  String? recipeId;
@override@HiveField(1) final  String label;
@override@HiveField(2) final  double amount;

/// Create a copy of GroceryItemSourceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroceryItemSourceModelCopyWith<_GroceryItemSourceModel> get copyWith => __$GroceryItemSourceModelCopyWithImpl<_GroceryItemSourceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroceryItemSourceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroceryItemSourceModel&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recipeId,label,amount);

@override
String toString() {
  return 'GroceryItemSourceModel(recipeId: $recipeId, label: $label, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$GroceryItemSourceModelCopyWith<$Res> implements $GroceryItemSourceModelCopyWith<$Res> {
  factory _$GroceryItemSourceModelCopyWith(_GroceryItemSourceModel value, $Res Function(_GroceryItemSourceModel) _then) = __$GroceryItemSourceModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String? recipeId,@HiveField(1) String label,@HiveField(2) double amount
});




}
/// @nodoc
class __$GroceryItemSourceModelCopyWithImpl<$Res>
    implements _$GroceryItemSourceModelCopyWith<$Res> {
  __$GroceryItemSourceModelCopyWithImpl(this._self, this._then);

  final _GroceryItemSourceModel _self;
  final $Res Function(_GroceryItemSourceModel) _then;

/// Create a copy of GroceryItemSourceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recipeId = freezed,Object? label = null,Object? amount = null,}) {
  return _then(_GroceryItemSourceModel(
recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
