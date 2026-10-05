// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroceryListModel {

@HiveField(0) String get id;@HiveField(1) String get name;@HiveField(2) List<GroceryItemModel> get items;@HiveField(3) Map<String, String> get collaborators;@HiveField(4) DateTime get createdAt;// Appended, never reordered: lists written before this existed decode with
// the default and keep meaning "all plans".
@HiveField(5) List<String> get selectedPlanIds;/// The language the list name and the item names are written in.
@HiveField(6) String? get contentLang;/// See [RecipeModel.contentVersion].
@HiveField(7) int get contentVersion;// Appended for multiple lists. A list written before them decodes as a
// meal-plan list, which is what the one list there was always was.
/// A [GroceryListSource] name.
@HiveField(8) String get source;@HiveField(9) String? get recipeId;@HiveField(10) double get recipeScale;@HiveField(11) int? get recipeServings;@HiveField(12) String? get recipeTitle;
/// Create a copy of GroceryListModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroceryListModelCopyWith<GroceryListModel> get copyWith => _$GroceryListModelCopyWithImpl<GroceryListModel>(this as GroceryListModel, _$identity);

  /// Serializes this GroceryListModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroceryListModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.collaborators, collaborators)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.selectedPlanIds, selectedPlanIds)&&(identical(other.contentLang, contentLang) || other.contentLang == contentLang)&&(identical(other.contentVersion, contentVersion) || other.contentVersion == contentVersion)&&(identical(other.source, source) || other.source == source)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.recipeScale, recipeScale) || other.recipeScale == recipeScale)&&(identical(other.recipeServings, recipeServings) || other.recipeServings == recipeServings)&&(identical(other.recipeTitle, recipeTitle) || other.recipeTitle == recipeTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(collaborators),createdAt,const DeepCollectionEquality().hash(selectedPlanIds),contentLang,contentVersion,source,recipeId,recipeScale,recipeServings,recipeTitle);

@override
String toString() {
  return 'GroceryListModel(id: $id, name: $name, items: $items, collaborators: $collaborators, createdAt: $createdAt, selectedPlanIds: $selectedPlanIds, contentLang: $contentLang, contentVersion: $contentVersion, source: $source, recipeId: $recipeId, recipeScale: $recipeScale, recipeServings: $recipeServings, recipeTitle: $recipeTitle)';
}


}

/// @nodoc
abstract mixin class $GroceryListModelCopyWith<$Res>  {
  factory $GroceryListModelCopyWith(GroceryListModel value, $Res Function(GroceryListModel) _then) = _$GroceryListModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) List<GroceryItemModel> items,@HiveField(3) Map<String, String> collaborators,@HiveField(4) DateTime createdAt,@HiveField(5) List<String> selectedPlanIds,@HiveField(6) String? contentLang,@HiveField(7) int contentVersion,@HiveField(8) String source,@HiveField(9) String? recipeId,@HiveField(10) double recipeScale,@HiveField(11) int? recipeServings,@HiveField(12) String? recipeTitle
});




}
/// @nodoc
class _$GroceryListModelCopyWithImpl<$Res>
    implements $GroceryListModelCopyWith<$Res> {
  _$GroceryListModelCopyWithImpl(this._self, this._then);

  final GroceryListModel _self;
  final $Res Function(GroceryListModel) _then;

/// Create a copy of GroceryListModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? items = null,Object? collaborators = null,Object? createdAt = null,Object? selectedPlanIds = null,Object? contentLang = freezed,Object? contentVersion = null,Object? source = null,Object? recipeId = freezed,Object? recipeScale = null,Object? recipeServings = freezed,Object? recipeTitle = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GroceryItemModel>,collaborators: null == collaborators ? _self.collaborators : collaborators // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,selectedPlanIds: null == selectedPlanIds ? _self.selectedPlanIds : selectedPlanIds // ignore: cast_nullable_to_non_nullable
as List<String>,contentLang: freezed == contentLang ? _self.contentLang : contentLang // ignore: cast_nullable_to_non_nullable
as String?,contentVersion: null == contentVersion ? _self.contentVersion : contentVersion // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,recipeScale: null == recipeScale ? _self.recipeScale : recipeScale // ignore: cast_nullable_to_non_nullable
as double,recipeServings: freezed == recipeServings ? _self.recipeServings : recipeServings // ignore: cast_nullable_to_non_nullable
as int?,recipeTitle: freezed == recipeTitle ? _self.recipeTitle : recipeTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroceryListModel].
extension GroceryListModelPatterns on GroceryListModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroceryListModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroceryListModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroceryListModel value)  $default,){
final _that = this;
switch (_that) {
case _GroceryListModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroceryListModel value)?  $default,){
final _that = this;
switch (_that) {
case _GroceryListModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  List<GroceryItemModel> items, @HiveField(3)  Map<String, String> collaborators, @HiveField(4)  DateTime createdAt, @HiveField(5)  List<String> selectedPlanIds, @HiveField(6)  String? contentLang, @HiveField(7)  int contentVersion, @HiveField(8)  String source, @HiveField(9)  String? recipeId, @HiveField(10)  double recipeScale, @HiveField(11)  int? recipeServings, @HiveField(12)  String? recipeTitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroceryListModel() when $default != null:
return $default(_that.id,_that.name,_that.items,_that.collaborators,_that.createdAt,_that.selectedPlanIds,_that.contentLang,_that.contentVersion,_that.source,_that.recipeId,_that.recipeScale,_that.recipeServings,_that.recipeTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  List<GroceryItemModel> items, @HiveField(3)  Map<String, String> collaborators, @HiveField(4)  DateTime createdAt, @HiveField(5)  List<String> selectedPlanIds, @HiveField(6)  String? contentLang, @HiveField(7)  int contentVersion, @HiveField(8)  String source, @HiveField(9)  String? recipeId, @HiveField(10)  double recipeScale, @HiveField(11)  int? recipeServings, @HiveField(12)  String? recipeTitle)  $default,) {final _that = this;
switch (_that) {
case _GroceryListModel():
return $default(_that.id,_that.name,_that.items,_that.collaborators,_that.createdAt,_that.selectedPlanIds,_that.contentLang,_that.contentVersion,_that.source,_that.recipeId,_that.recipeScale,_that.recipeServings,_that.recipeTitle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String name, @HiveField(2)  List<GroceryItemModel> items, @HiveField(3)  Map<String, String> collaborators, @HiveField(4)  DateTime createdAt, @HiveField(5)  List<String> selectedPlanIds, @HiveField(6)  String? contentLang, @HiveField(7)  int contentVersion, @HiveField(8)  String source, @HiveField(9)  String? recipeId, @HiveField(10)  double recipeScale, @HiveField(11)  int? recipeServings, @HiveField(12)  String? recipeTitle)?  $default,) {final _that = this;
switch (_that) {
case _GroceryListModel() when $default != null:
return $default(_that.id,_that.name,_that.items,_that.collaborators,_that.createdAt,_that.selectedPlanIds,_that.contentLang,_that.contentVersion,_that.source,_that.recipeId,_that.recipeScale,_that.recipeServings,_that.recipeTitle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroceryListModel implements GroceryListModel {
  const _GroceryListModel({@HiveField(0) required this.id, @HiveField(1) required this.name, @HiveField(2) required final  List<GroceryItemModel> items, @HiveField(3) final  Map<String, String> collaborators = const {}, @HiveField(4) required this.createdAt, @HiveField(5) final  List<String> selectedPlanIds = const <String>[], @HiveField(6) this.contentLang, @HiveField(7) this.contentVersion = 0, @HiveField(8) this.source = 'plans', @HiveField(9) this.recipeId, @HiveField(10) this.recipeScale = 1.0, @HiveField(11) this.recipeServings, @HiveField(12) this.recipeTitle}): _items = items,_collaborators = collaborators,_selectedPlanIds = selectedPlanIds;
  factory _GroceryListModel.fromJson(Map<String, dynamic> json) => _$GroceryListModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String name;
 final  List<GroceryItemModel> _items;
@override@HiveField(2) List<GroceryItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  Map<String, String> _collaborators;
@override@JsonKey()@HiveField(3) Map<String, String> get collaborators {
  if (_collaborators is EqualUnmodifiableMapView) return _collaborators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collaborators);
}

@override@HiveField(4) final  DateTime createdAt;
// Appended, never reordered: lists written before this existed decode with
// the default and keep meaning "all plans".
 final  List<String> _selectedPlanIds;
// Appended, never reordered: lists written before this existed decode with
// the default and keep meaning "all plans".
@override@JsonKey()@HiveField(5) List<String> get selectedPlanIds {
  if (_selectedPlanIds is EqualUnmodifiableListView) return _selectedPlanIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedPlanIds);
}

/// The language the list name and the item names are written in.
@override@HiveField(6) final  String? contentLang;
/// See [RecipeModel.contentVersion].
@override@JsonKey()@HiveField(7) final  int contentVersion;
// Appended for multiple lists. A list written before them decodes as a
// meal-plan list, which is what the one list there was always was.
/// A [GroceryListSource] name.
@override@JsonKey()@HiveField(8) final  String source;
@override@HiveField(9) final  String? recipeId;
@override@JsonKey()@HiveField(10) final  double recipeScale;
@override@HiveField(11) final  int? recipeServings;
@override@HiveField(12) final  String? recipeTitle;

/// Create a copy of GroceryListModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroceryListModelCopyWith<_GroceryListModel> get copyWith => __$GroceryListModelCopyWithImpl<_GroceryListModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroceryListModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroceryListModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._collaborators, _collaborators)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._selectedPlanIds, _selectedPlanIds)&&(identical(other.contentLang, contentLang) || other.contentLang == contentLang)&&(identical(other.contentVersion, contentVersion) || other.contentVersion == contentVersion)&&(identical(other.source, source) || other.source == source)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.recipeScale, recipeScale) || other.recipeScale == recipeScale)&&(identical(other.recipeServings, recipeServings) || other.recipeServings == recipeServings)&&(identical(other.recipeTitle, recipeTitle) || other.recipeTitle == recipeTitle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_collaborators),createdAt,const DeepCollectionEquality().hash(_selectedPlanIds),contentLang,contentVersion,source,recipeId,recipeScale,recipeServings,recipeTitle);

@override
String toString() {
  return 'GroceryListModel(id: $id, name: $name, items: $items, collaborators: $collaborators, createdAt: $createdAt, selectedPlanIds: $selectedPlanIds, contentLang: $contentLang, contentVersion: $contentVersion, source: $source, recipeId: $recipeId, recipeScale: $recipeScale, recipeServings: $recipeServings, recipeTitle: $recipeTitle)';
}


}

/// @nodoc
abstract mixin class _$GroceryListModelCopyWith<$Res> implements $GroceryListModelCopyWith<$Res> {
  factory _$GroceryListModelCopyWith(_GroceryListModel value, $Res Function(_GroceryListModel) _then) = __$GroceryListModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String name,@HiveField(2) List<GroceryItemModel> items,@HiveField(3) Map<String, String> collaborators,@HiveField(4) DateTime createdAt,@HiveField(5) List<String> selectedPlanIds,@HiveField(6) String? contentLang,@HiveField(7) int contentVersion,@HiveField(8) String source,@HiveField(9) String? recipeId,@HiveField(10) double recipeScale,@HiveField(11) int? recipeServings,@HiveField(12) String? recipeTitle
});




}
/// @nodoc
class __$GroceryListModelCopyWithImpl<$Res>
    implements _$GroceryListModelCopyWith<$Res> {
  __$GroceryListModelCopyWithImpl(this._self, this._then);

  final _GroceryListModel _self;
  final $Res Function(_GroceryListModel) _then;

/// Create a copy of GroceryListModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? items = null,Object? collaborators = null,Object? createdAt = null,Object? selectedPlanIds = null,Object? contentLang = freezed,Object? contentVersion = null,Object? source = null,Object? recipeId = freezed,Object? recipeScale = null,Object? recipeServings = freezed,Object? recipeTitle = freezed,}) {
  return _then(_GroceryListModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GroceryItemModel>,collaborators: null == collaborators ? _self._collaborators : collaborators // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,selectedPlanIds: null == selectedPlanIds ? _self._selectedPlanIds : selectedPlanIds // ignore: cast_nullable_to_non_nullable
as List<String>,contentLang: freezed == contentLang ? _self.contentLang : contentLang // ignore: cast_nullable_to_non_nullable
as String?,contentVersion: null == contentVersion ? _self.contentVersion : contentVersion // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,recipeScale: null == recipeScale ? _self.recipeScale : recipeScale // ignore: cast_nullable_to_non_nullable
as double,recipeServings: freezed == recipeServings ? _self.recipeServings : recipeServings // ignore: cast_nullable_to_non_nullable
as int?,recipeTitle: freezed == recipeTitle ? _self.recipeTitle : recipeTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
