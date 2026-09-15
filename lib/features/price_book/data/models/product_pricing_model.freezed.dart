// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_pricing_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductPricingModel {

@HiveField(0) String get key;@HiveField(1) String get mode;@HiveField(2) String? get store;@HiveField(3) List<String> get receiptIds;
/// Create a copy of ProductPricingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductPricingModelCopyWith<ProductPricingModel> get copyWith => _$ProductPricingModelCopyWithImpl<ProductPricingModel>(this as ProductPricingModel, _$identity);

  /// Serializes this ProductPricingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductPricingModel&&(identical(other.key, key) || other.key == key)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.store, store) || other.store == store)&&const DeepCollectionEquality().equals(other.receiptIds, receiptIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,mode,store,const DeepCollectionEquality().hash(receiptIds));

@override
String toString() {
  return 'ProductPricingModel(key: $key, mode: $mode, store: $store, receiptIds: $receiptIds)';
}


}

/// @nodoc
abstract mixin class $ProductPricingModelCopyWith<$Res>  {
  factory $ProductPricingModelCopyWith(ProductPricingModel value, $Res Function(ProductPricingModel) _then) = _$ProductPricingModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String key,@HiveField(1) String mode,@HiveField(2) String? store,@HiveField(3) List<String> receiptIds
});




}
/// @nodoc
class _$ProductPricingModelCopyWithImpl<$Res>
    implements $ProductPricingModelCopyWith<$Res> {
  _$ProductPricingModelCopyWithImpl(this._self, this._then);

  final ProductPricingModel _self;
  final $Res Function(ProductPricingModel) _then;

/// Create a copy of ProductPricingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? mode = null,Object? store = freezed,Object? receiptIds = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,receiptIds: null == receiptIds ? _self.receiptIds : receiptIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductPricingModel].
extension ProductPricingModelPatterns on ProductPricingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductPricingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductPricingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductPricingModel value)  $default,){
final _that = this;
switch (_that) {
case _ProductPricingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductPricingModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProductPricingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String key, @HiveField(1)  String mode, @HiveField(2)  String? store, @HiveField(3)  List<String> receiptIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductPricingModel() when $default != null:
return $default(_that.key,_that.mode,_that.store,_that.receiptIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String key, @HiveField(1)  String mode, @HiveField(2)  String? store, @HiveField(3)  List<String> receiptIds)  $default,) {final _that = this;
switch (_that) {
case _ProductPricingModel():
return $default(_that.key,_that.mode,_that.store,_that.receiptIds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String key, @HiveField(1)  String mode, @HiveField(2)  String? store, @HiveField(3)  List<String> receiptIds)?  $default,) {final _that = this;
switch (_that) {
case _ProductPricingModel() when $default != null:
return $default(_that.key,_that.mode,_that.store,_that.receiptIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductPricingModel implements ProductPricingModel {
  const _ProductPricingModel({@HiveField(0) required this.key, @HiveField(1) this.mode = 'latest', @HiveField(2) this.store, @HiveField(3) final  List<String> receiptIds = const []}): _receiptIds = receiptIds;
  factory _ProductPricingModel.fromJson(Map<String, dynamic> json) => _$ProductPricingModelFromJson(json);

@override@HiveField(0) final  String key;
@override@JsonKey()@HiveField(1) final  String mode;
@override@HiveField(2) final  String? store;
 final  List<String> _receiptIds;
@override@JsonKey()@HiveField(3) List<String> get receiptIds {
  if (_receiptIds is EqualUnmodifiableListView) return _receiptIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_receiptIds);
}


/// Create a copy of ProductPricingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductPricingModelCopyWith<_ProductPricingModel> get copyWith => __$ProductPricingModelCopyWithImpl<_ProductPricingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductPricingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductPricingModel&&(identical(other.key, key) || other.key == key)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.store, store) || other.store == store)&&const DeepCollectionEquality().equals(other._receiptIds, _receiptIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,mode,store,const DeepCollectionEquality().hash(_receiptIds));

@override
String toString() {
  return 'ProductPricingModel(key: $key, mode: $mode, store: $store, receiptIds: $receiptIds)';
}


}

/// @nodoc
abstract mixin class _$ProductPricingModelCopyWith<$Res> implements $ProductPricingModelCopyWith<$Res> {
  factory _$ProductPricingModelCopyWith(_ProductPricingModel value, $Res Function(_ProductPricingModel) _then) = __$ProductPricingModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String key,@HiveField(1) String mode,@HiveField(2) String? store,@HiveField(3) List<String> receiptIds
});




}
/// @nodoc
class __$ProductPricingModelCopyWithImpl<$Res>
    implements _$ProductPricingModelCopyWith<$Res> {
  __$ProductPricingModelCopyWithImpl(this._self, this._then);

  final _ProductPricingModel _self;
  final $Res Function(_ProductPricingModel) _then;

/// Create a copy of ProductPricingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? mode = null,Object? store = freezed,Object? receiptIds = null,}) {
  return _then(_ProductPricingModel(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,receiptIds: null == receiptIds ? _self._receiptIds : receiptIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
