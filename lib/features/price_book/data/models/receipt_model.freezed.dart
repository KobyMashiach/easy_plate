// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceiptModel {

@HiveField(0) String get id;@HiveField(1) String? get store;@HiveField(2) DateTime get purchasedAt;@HiveField(3) String get currency;@HiveField(4) double get total;@HiveField(5) int get itemCount;@HiveField(6) DateTime get createdAt;@HiveField(7) List<String> get imageFileNames;
/// Create a copy of ReceiptModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptModelCopyWith<ReceiptModel> get copyWith => _$ReceiptModelCopyWithImpl<ReceiptModel>(this as ReceiptModel, _$identity);

  /// Serializes this ReceiptModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptModel&&(identical(other.id, id) || other.id == id)&&(identical(other.store, store) || other.store == store)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.total, total) || other.total == total)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.imageFileNames, imageFileNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,store,purchasedAt,currency,total,itemCount,createdAt,const DeepCollectionEquality().hash(imageFileNames));

@override
String toString() {
  return 'ReceiptModel(id: $id, store: $store, purchasedAt: $purchasedAt, currency: $currency, total: $total, itemCount: $itemCount, createdAt: $createdAt, imageFileNames: $imageFileNames)';
}


}

/// @nodoc
abstract mixin class $ReceiptModelCopyWith<$Res>  {
  factory $ReceiptModelCopyWith(ReceiptModel value, $Res Function(ReceiptModel) _then) = _$ReceiptModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String? store,@HiveField(2) DateTime purchasedAt,@HiveField(3) String currency,@HiveField(4) double total,@HiveField(5) int itemCount,@HiveField(6) DateTime createdAt,@HiveField(7) List<String> imageFileNames
});




}
/// @nodoc
class _$ReceiptModelCopyWithImpl<$Res>
    implements $ReceiptModelCopyWith<$Res> {
  _$ReceiptModelCopyWithImpl(this._self, this._then);

  final ReceiptModel _self;
  final $Res Function(ReceiptModel) _then;

/// Create a copy of ReceiptModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? store = freezed,Object? purchasedAt = null,Object? currency = null,Object? total = null,Object? itemCount = null,Object? createdAt = null,Object? imageFileNames = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageFileNames: null == imageFileNames ? _self.imageFileNames : imageFileNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptModel].
extension ReceiptModelPatterns on ReceiptModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptModel value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String? store, @HiveField(2)  DateTime purchasedAt, @HiveField(3)  String currency, @HiveField(4)  double total, @HiveField(5)  int itemCount, @HiveField(6)  DateTime createdAt, @HiveField(7)  List<String> imageFileNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptModel() when $default != null:
return $default(_that.id,_that.store,_that.purchasedAt,_that.currency,_that.total,_that.itemCount,_that.createdAt,_that.imageFileNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String? store, @HiveField(2)  DateTime purchasedAt, @HiveField(3)  String currency, @HiveField(4)  double total, @HiveField(5)  int itemCount, @HiveField(6)  DateTime createdAt, @HiveField(7)  List<String> imageFileNames)  $default,) {final _that = this;
switch (_that) {
case _ReceiptModel():
return $default(_that.id,_that.store,_that.purchasedAt,_that.currency,_that.total,_that.itemCount,_that.createdAt,_that.imageFileNames);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String? store, @HiveField(2)  DateTime purchasedAt, @HiveField(3)  String currency, @HiveField(4)  double total, @HiveField(5)  int itemCount, @HiveField(6)  DateTime createdAt, @HiveField(7)  List<String> imageFileNames)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptModel() when $default != null:
return $default(_that.id,_that.store,_that.purchasedAt,_that.currency,_that.total,_that.itemCount,_that.createdAt,_that.imageFileNames);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptModel implements ReceiptModel {
  const _ReceiptModel({@HiveField(0) required this.id, @HiveField(1) this.store, @HiveField(2) required this.purchasedAt, @HiveField(3) this.currency = 'ILS', @HiveField(4) required this.total, @HiveField(5) this.itemCount = 0, @HiveField(6) required this.createdAt, @HiveField(7) final  List<String> imageFileNames = const []}): _imageFileNames = imageFileNames;
  factory _ReceiptModel.fromJson(Map<String, dynamic> json) => _$ReceiptModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String? store;
@override@HiveField(2) final  DateTime purchasedAt;
@override@JsonKey()@HiveField(3) final  String currency;
@override@HiveField(4) final  double total;
@override@JsonKey()@HiveField(5) final  int itemCount;
@override@HiveField(6) final  DateTime createdAt;
 final  List<String> _imageFileNames;
@override@JsonKey()@HiveField(7) List<String> get imageFileNames {
  if (_imageFileNames is EqualUnmodifiableListView) return _imageFileNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imageFileNames);
}


/// Create a copy of ReceiptModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptModelCopyWith<_ReceiptModel> get copyWith => __$ReceiptModelCopyWithImpl<_ReceiptModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptModel&&(identical(other.id, id) || other.id == id)&&(identical(other.store, store) || other.store == store)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.total, total) || other.total == total)&&(identical(other.itemCount, itemCount) || other.itemCount == itemCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._imageFileNames, _imageFileNames));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,store,purchasedAt,currency,total,itemCount,createdAt,const DeepCollectionEquality().hash(_imageFileNames));

@override
String toString() {
  return 'ReceiptModel(id: $id, store: $store, purchasedAt: $purchasedAt, currency: $currency, total: $total, itemCount: $itemCount, createdAt: $createdAt, imageFileNames: $imageFileNames)';
}


}

/// @nodoc
abstract mixin class _$ReceiptModelCopyWith<$Res> implements $ReceiptModelCopyWith<$Res> {
  factory _$ReceiptModelCopyWith(_ReceiptModel value, $Res Function(_ReceiptModel) _then) = __$ReceiptModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String? store,@HiveField(2) DateTime purchasedAt,@HiveField(3) String currency,@HiveField(4) double total,@HiveField(5) int itemCount,@HiveField(6) DateTime createdAt,@HiveField(7) List<String> imageFileNames
});




}
/// @nodoc
class __$ReceiptModelCopyWithImpl<$Res>
    implements _$ReceiptModelCopyWith<$Res> {
  __$ReceiptModelCopyWithImpl(this._self, this._then);

  final _ReceiptModel _self;
  final $Res Function(_ReceiptModel) _then;

/// Create a copy of ReceiptModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? store = freezed,Object? purchasedAt = null,Object? currency = null,Object? total = null,Object? itemCount = null,Object? createdAt = null,Object? imageFileNames = null,}) {
  return _then(_ReceiptModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,itemCount: null == itemCount ? _self.itemCount : itemCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageFileNames: null == imageFileNames ? _self._imageFileNames : imageFileNames // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
