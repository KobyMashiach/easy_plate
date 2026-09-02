// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroceryItemModel {

@HiveField(0) String get id;@HiveField(1) String get name;@HiveField(2) MeasurementUnit get unit;@HiveField(3) List<GroceryItemSourceModel> get sources;@HiveField(4) bool get isChecked;@HiveField(5) String get category;@HiveField(6) bool get isAdHoc;
/// Create a copy of GroceryItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryItemModelCopyWith<GroceryItemModel> get copyWith => _$GroceryItemModelCopyWithImpl<GroceryItemModel>(this as GroceryItemModel, _$identity);

  /// Serializes this GroceryItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.category, category) || other.category == category)&&(identical(other.isAdHoc, isAdHoc) || other.isAdHoc == isAdHoc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,unit,const DeepCollectionEquality().hash(sources),isChecked,category,isAdHoc);

@override
String toString() {
  return 'GroceryItemModel(id: $id, name: $name, unit: $unit, sources: $sources, isChecked: $isChecked, category: $category, isAdHoc: $isAdHoc)';
}


}

/// @nodoc
abstract mixin class $GroceryItemModelCopyWith<$Res>  {
  factory $GroceryItemModelCopyWith(GroceryItemModel value, $Res Function(GroceryItemModel) _then) = _$GroceryItemModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) MeasurementUnit unit,@HiveField(3) List<GroceryItemSourceModel> sources,@HiveField(4) bool isChecked,@HiveField(5) String category,@HiveField(6) bool isAdHoc
});




}
/// @nodoc
class _$GroceryItemModelCopyWithImpl<$Res>
    implements $GroceryItemModelCopyWith<$Res> {
  _$GroceryItemModelCopyWithImpl(this._self, this._then);

  final GroceryItemModel _self;
  final $Res Function(GroceryItemModel) _then;

/// Create a copy of GroceryItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? unit = null,Object? sources = null,Object? isChecked = null,Object? category = null,Object? isAdHoc = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasurementUnit,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<GroceryItemSourceModel>,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isAdHoc: null == isAdHoc ? _self.isAdHoc : isAdHoc // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroceryItemModel].
extension GroceryItemModelPatterns on GroceryItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroceryItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroceryItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroceryItemModel value)  $default,){
final _that = this;
switch (_that) {
case _GroceryItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroceryItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _GroceryItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  MeasurementUnit unit, @HiveField(3)  List<GroceryItemSourceModel> sources, @HiveField(4)  bool isChecked, @HiveField(5)  String category, @HiveField(6)  bool isAdHoc)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroceryItemModel() when $default != null:
return $default(_that.id,_that.name,_that.unit,_that.sources,_that.isChecked,_that.category,_that.isAdHoc);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  MeasurementUnit unit, @HiveField(3)  List<GroceryItemSourceModel> sources, @HiveField(4)  bool isChecked, @HiveField(5)  String category, @HiveField(6)  bool isAdHoc)  $default,) {final _that = this;
switch (_that) {
case _GroceryItemModel():
return $default(_that.id,_that.name,_that.unit,_that.sources,_that.isChecked,_that.category,_that.isAdHoc);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  MeasurementUnit unit, @HiveField(3)  List<GroceryItemSourceModel> sources, @HiveField(4)  bool isChecked, @HiveField(5)  String category, @HiveField(6)  bool isAdHoc)?  $default,) {final _that = this;
switch (_that) {
case _GroceryItemModel() when $default != null:
return $default(_that.id,_that.name,_that.unit,_that.sources,_that.isChecked,_that.category,_that.isAdHoc);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroceryItemModel implements GroceryItemModel {
  const _GroceryItemModel({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) this.unit = MeasurementUnit.unspecified, @HiveField(3) required final  List<GroceryItemSourceModel> sources, @HiveField(4) this.isChecked = false, @HiveField(5) this.category = 'כללי', @HiveField(6) this.isAdHoc = false}): _sources = sources;
  factory _GroceryItemModel.fromJson(Map<String, dynamic> json) => _$GroceryItemModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String name;
@override@JsonKey()@HiveField(2) final  MeasurementUnit unit;
 final  List<GroceryItemSourceModel> _sources;
@override@HiveField(3) List<GroceryItemSourceModel> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

@override@JsonKey()@HiveField(4) final  bool isChecked;
@override@JsonKey()@HiveField(5) final  String category;
@override@JsonKey()@HiveField(6) final  bool isAdHoc;

/// Create a copy of GroceryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroceryItemModelCopyWith<_GroceryItemModel> get copyWith => __$GroceryItemModelCopyWithImpl<_GroceryItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroceryItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroceryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.category, category) || other.category == category)&&(identical(other.isAdHoc, isAdHoc) || other.isAdHoc == isAdHoc));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,unit,const DeepCollectionEquality().hash(_sources),isChecked,category,isAdHoc);

@override
String toString() {
  return 'GroceryItemModel(id: $id, name: $name, unit: $unit, sources: $sources, isChecked: $isChecked, category: $category, isAdHoc: $isAdHoc)';
}


}

/// @nodoc
abstract mixin class _$GroceryItemModelCopyWith<$Res> implements $GroceryItemModelCopyWith<$Res> {
  factory _$GroceryItemModelCopyWith(_GroceryItemModel value, $Res Function(_GroceryItemModel) _then) = __$GroceryItemModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) MeasurementUnit unit,@HiveField(3) List<GroceryItemSourceModel> sources,@HiveField(4) bool isChecked,@HiveField(5) String category,@HiveField(6) bool isAdHoc
});




}
/// @nodoc
class __$GroceryItemModelCopyWithImpl<$Res>
    implements _$GroceryItemModelCopyWith<$Res> {
  __$GroceryItemModelCopyWithImpl(this._self, this._then);

  final _GroceryItemModel _self;
  final $Res Function(_GroceryItemModel) _then;

/// Create a copy of GroceryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? unit = null,Object? sources = null,Object? isChecked = null,Object? category = null,Object? isAdHoc = null,}) {
  return _then(_GroceryItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as MeasurementUnit,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<GroceryItemSourceModel>,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isAdHoc: null == isAdHoc ? _self.isAdHoc : isAdHoc // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
