// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriceRecordModel {

@HiveField(0) String get id;@HiveField(1) String get name;@HiveField(2) String get normalizedName;@HiveField(3) double get unitPrice;@HiveField(4) double get quantity;@HiveField(5) String get currency;@HiveField(6) String? get store;@HiveField(7) DateTime get purchasedAt;@HiveField(8) String get receiptId;// Appended: the printed line and the price unit by name.
@HiveField(9) String? get printedName;@HiveField(10) String get unit;
/// Create a copy of PriceRecordModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceRecordModelCopyWith<PriceRecordModel> get copyWith => _$PriceRecordModelCopyWithImpl<PriceRecordModel>(this as PriceRecordModel, _$identity);

  /// Serializes this PriceRecordModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceRecordModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.normalizedName, normalizedName) || other.normalizedName == normalizedName)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.store, store) || other.store == store)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.printedName, printedName) || other.printedName == printedName)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,normalizedName,unitPrice,quantity,currency,store,purchasedAt,receiptId,printedName,unit);

@override
String toString() {
  return 'PriceRecordModel(id: $id, name: $name, normalizedName: $normalizedName, unitPrice: $unitPrice, quantity: $quantity, currency: $currency, store: $store, purchasedAt: $purchasedAt, receiptId: $receiptId, printedName: $printedName, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $PriceRecordModelCopyWith<$Res>  {
  factory $PriceRecordModelCopyWith(PriceRecordModel value, $Res Function(PriceRecordModel) _then) = _$PriceRecordModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) String normalizedName,@HiveField(3) double unitPrice,@HiveField(4) double quantity,@HiveField(5) String currency,@HiveField(6) String? store,@HiveField(7) DateTime purchasedAt,@HiveField(8) String receiptId,@HiveField(9) String? printedName,@HiveField(10) String unit
});




}
/// @nodoc
class _$PriceRecordModelCopyWithImpl<$Res>
    implements $PriceRecordModelCopyWith<$Res> {
  _$PriceRecordModelCopyWithImpl(this._self, this._then);

  final PriceRecordModel _self;
  final $Res Function(PriceRecordModel) _then;

/// Create a copy of PriceRecordModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? normalizedName = null,Object? unitPrice = null,Object? quantity = null,Object? currency = null,Object? store = freezed,Object? purchasedAt = null,Object? receiptId = null,Object? printedName = freezed,Object? unit = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,normalizedName: null == normalizedName ? _self.normalizedName : normalizedName // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime,receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,printedName: freezed == printedName ? _self.printedName : printedName // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceRecordModel].
extension PriceRecordModelPatterns on PriceRecordModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceRecordModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceRecordModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceRecordModel value)  $default,){
final _that = this;
switch (_that) {
case _PriceRecordModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceRecordModel value)?  $default,){
final _that = this;
switch (_that) {
case _PriceRecordModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  String normalizedName, @HiveField(3)  double unitPrice, @HiveField(4)  double quantity, @HiveField(5)  String currency, @HiveField(6)  String? store, @HiveField(7)  DateTime purchasedAt, @HiveField(8)  String receiptId, @HiveField(9)  String? printedName, @HiveField(10)  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceRecordModel() when $default != null:
return $default(_that.id,_that.name,_that.normalizedName,_that.unitPrice,_that.quantity,_that.currency,_that.store,_that.purchasedAt,_that.receiptId,_that.printedName,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  String normalizedName, @HiveField(3)  double unitPrice, @HiveField(4)  double quantity, @HiveField(5)  String currency, @HiveField(6)  String? store, @HiveField(7)  DateTime purchasedAt, @HiveField(8)  String receiptId, @HiveField(9)  String? printedName, @HiveField(10)  String unit)  $default,) {final _that = this;
switch (_that) {
case _PriceRecordModel():
return $default(_that.id,_that.name,_that.normalizedName,_that.unitPrice,_that.quantity,_that.currency,_that.store,_that.purchasedAt,_that.receiptId,_that.printedName,_that.unit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  String normalizedName, @HiveField(3)  double unitPrice, @HiveField(4)  double quantity, @HiveField(5)  String currency, @HiveField(6)  String? store, @HiveField(7)  DateTime purchasedAt, @HiveField(8)  String receiptId, @HiveField(9)  String? printedName, @HiveField(10)  String unit)?  $default,) {final _that = this;
switch (_that) {
case _PriceRecordModel() when $default != null:
return $default(_that.id,_that.name,_that.normalizedName,_that.unitPrice,_that.quantity,_that.currency,_that.store,_that.purchasedAt,_that.receiptId,_that.printedName,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceRecordModel implements PriceRecordModel {
  const _PriceRecordModel({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) required this.normalizedName, @HiveField(3) required this.unitPrice, @HiveField(4) this.quantity = 1, @HiveField(5) this.currency = 'ILS', @HiveField(6) this.store, @HiveField(7) required this.purchasedAt, @HiveField(8) required this.receiptId, @HiveField(9) this.printedName, @HiveField(10) this.unit = 'unit'});
  factory _PriceRecordModel.fromJson(Map<String, dynamic> json) => _$PriceRecordModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String name;
@override@HiveField(2) final  String normalizedName;
@override@HiveField(3) final  double unitPrice;
@override@JsonKey()@HiveField(4) final  double quantity;
@override@JsonKey()@HiveField(5) final  String currency;
@override@HiveField(6) final  String? store;
@override@HiveField(7) final  DateTime purchasedAt;
@override@HiveField(8) final  String receiptId;
// Appended: the printed line and the price unit by name.
@override@HiveField(9) final  String? printedName;
@override@JsonKey()@HiveField(10) final  String unit;

/// Create a copy of PriceRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceRecordModelCopyWith<_PriceRecordModel> get copyWith => __$PriceRecordModelCopyWithImpl<_PriceRecordModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceRecordModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceRecordModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.normalizedName, normalizedName) || other.normalizedName == normalizedName)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.store, store) || other.store == store)&&(identical(other.purchasedAt, purchasedAt) || other.purchasedAt == purchasedAt)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.printedName, printedName) || other.printedName == printedName)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,normalizedName,unitPrice,quantity,currency,store,purchasedAt,receiptId,printedName,unit);

@override
String toString() {
  return 'PriceRecordModel(id: $id, name: $name, normalizedName: $normalizedName, unitPrice: $unitPrice, quantity: $quantity, currency: $currency, store: $store, purchasedAt: $purchasedAt, receiptId: $receiptId, printedName: $printedName, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$PriceRecordModelCopyWith<$Res> implements $PriceRecordModelCopyWith<$Res> {
  factory _$PriceRecordModelCopyWith(_PriceRecordModel value, $Res Function(_PriceRecordModel) _then) = __$PriceRecordModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) String normalizedName,@HiveField(3) double unitPrice,@HiveField(4) double quantity,@HiveField(5) String currency,@HiveField(6) String? store,@HiveField(7) DateTime purchasedAt,@HiveField(8) String receiptId,@HiveField(9) String? printedName,@HiveField(10) String unit
});




}
/// @nodoc
class __$PriceRecordModelCopyWithImpl<$Res>
    implements _$PriceRecordModelCopyWith<$Res> {
  __$PriceRecordModelCopyWithImpl(this._self, this._then);

  final _PriceRecordModel _self;
  final $Res Function(_PriceRecordModel) _then;

/// Create a copy of PriceRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? normalizedName = null,Object? unitPrice = null,Object? quantity = null,Object? currency = null,Object? store = freezed,Object? purchasedAt = null,Object? receiptId = null,Object? printedName = freezed,Object? unit = null,}) {
  return _then(_PriceRecordModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,normalizedName: null == normalizedName ? _self.normalizedName : normalizedName // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,store: freezed == store ? _self.store : store // ignore: cast_nullable_to_non_nullable
as String?,purchasedAt: null == purchasedAt ? _self.purchasedAt : purchasedAt // ignore: cast_nullable_to_non_nullable
as DateTime,receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,printedName: freezed == printedName ? _self.printedName : printedName // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
