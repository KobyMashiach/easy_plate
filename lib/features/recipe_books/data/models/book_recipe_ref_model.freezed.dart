// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_recipe_ref_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookRecipeRefModel {

@HiveField(0) String get recipeId;@HiveField(1) int get order;
/// Create a copy of BookRecipeRefModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookRecipeRefModelCopyWith<BookRecipeRefModel> get copyWith => _$BookRecipeRefModelCopyWithImpl<BookRecipeRefModel>(this as BookRecipeRefModel, _$identity);

  /// Serializes this BookRecipeRefModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookRecipeRefModel&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recipeId,order);

@override
String toString() {
  return 'BookRecipeRefModel(recipeId: $recipeId, order: $order)';
}


}

/// @nodoc
abstract mixin class $BookRecipeRefModelCopyWith<$Res>  {
  factory $BookRecipeRefModelCopyWith(BookRecipeRefModel value, $Res Function(BookRecipeRefModel) _then) = _$BookRecipeRefModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String recipeId,@HiveField(1) int order
});




}
/// @nodoc
class _$BookRecipeRefModelCopyWithImpl<$Res>
    implements $BookRecipeRefModelCopyWith<$Res> {
  _$BookRecipeRefModelCopyWithImpl(this._self, this._then);

  final BookRecipeRefModel _self;
  final $Res Function(BookRecipeRefModel) _then;

/// Create a copy of BookRecipeRefModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recipeId = null,Object? order = null,}) {
  return _then(_self.copyWith(
recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BookRecipeRefModel].
extension BookRecipeRefModelPatterns on BookRecipeRefModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookRecipeRefModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookRecipeRefModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookRecipeRefModel value)  $default,){
final _that = this;
switch (_that) {
case _BookRecipeRefModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookRecipeRefModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookRecipeRefModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String recipeId, @HiveField(1)  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookRecipeRefModel() when $default != null:
return $default(_that.recipeId,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String recipeId, @HiveField(1)  int order)  $default,) {final _that = this;
switch (_that) {
case _BookRecipeRefModel():
return $default(_that.recipeId,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String recipeId, @HiveField(1)  int order)?  $default,) {final _that = this;
switch (_that) {
case _BookRecipeRefModel() when $default != null:
return $default(_that.recipeId,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookRecipeRefModel implements BookRecipeRefModel {
  const _BookRecipeRefModel({@HiveField(0) required this.recipeId, @HiveField(1) required this.order});
  factory _BookRecipeRefModel.fromJson(Map<String, dynamic> json) => _$BookRecipeRefModelFromJson(json);

@override@HiveField(0) final  String recipeId;
@override@HiveField(1) final  int order;

/// Create a copy of BookRecipeRefModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookRecipeRefModelCopyWith<_BookRecipeRefModel> get copyWith => __$BookRecipeRefModelCopyWithImpl<_BookRecipeRefModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookRecipeRefModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookRecipeRefModel&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,recipeId,order);

@override
String toString() {
  return 'BookRecipeRefModel(recipeId: $recipeId, order: $order)';
}


}

/// @nodoc
abstract mixin class _$BookRecipeRefModelCopyWith<$Res> implements $BookRecipeRefModelCopyWith<$Res> {
  factory _$BookRecipeRefModelCopyWith(_BookRecipeRefModel value, $Res Function(_BookRecipeRefModel) _then) = __$BookRecipeRefModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String recipeId,@HiveField(1) int order
});




}
/// @nodoc
class __$BookRecipeRefModelCopyWithImpl<$Res>
    implements _$BookRecipeRefModelCopyWith<$Res> {
  __$BookRecipeRefModelCopyWithImpl(this._self, this._then);

  final _BookRecipeRefModel _self;
  final $Res Function(_BookRecipeRefModel) _then;

/// Create a copy of BookRecipeRefModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recipeId = null,Object? order = null,}) {
  return _then(_BookRecipeRefModel(
recipeId: null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
