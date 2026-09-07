// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeModel {

@HiveField(0) String get id;@HiveField(1) String get title;@HiveField(2) int? get prepTimeMinutes;@HiveField(3) int? get cookTimeMinutes;@HiveField(4) List<RecipeIngredientModel> get ingredients;@HiveField(5) List<String> get steps;@HiveField(6) List<DietaryPreference> get dietaryTags;@HiveField(7) String? get sourceChannel;@HiveField(8) String? get sourceUrl;@HiveField(9) DateTime get createdAt;@HiveField(10) String? get imageFileName;// Appended, never reordered: recipes written before this existed decode
// as null, which correctly reads as "mine".
@HiveField(11) String? get savedFromSharedId;@HiveField(12) bool get pendingAnalysis;@HiveField(13) String? get collabId;// Enum name as a string, like `sourceChannel`, so no adapter is needed.
@HiveField(14) String? get collabRole;// Appended like the fields above it: a recipe stored before photos could
// travel decodes as null, which correctly reads as "never uploaded".
@HiveField(15) String? get imageStoragePath;
/// Create a copy of RecipeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeModelCopyWith<RecipeModel> get copyWith => _$RecipeModelCopyWithImpl<RecipeModel>(this as RecipeModel, _$identity);

  /// Serializes this RecipeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.prepTimeMinutes, prepTimeMinutes) || other.prepTimeMinutes == prepTimeMinutes)&&(identical(other.cookTimeMinutes, cookTimeMinutes) || other.cookTimeMinutes == cookTimeMinutes)&&const DeepCollectionEquality().equals(other.ingredients, ingredients)&&const DeepCollectionEquality().equals(other.steps, steps)&&const DeepCollectionEquality().equals(other.dietaryTags, dietaryTags)&&(identical(other.sourceChannel, sourceChannel) || other.sourceChannel == sourceChannel)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.imageFileName, imageFileName) || other.imageFileName == imageFileName)&&(identical(other.savedFromSharedId, savedFromSharedId) || other.savedFromSharedId == savedFromSharedId)&&(identical(other.pendingAnalysis, pendingAnalysis) || other.pendingAnalysis == pendingAnalysis)&&(identical(other.collabId, collabId) || other.collabId == collabId)&&(identical(other.collabRole, collabRole) || other.collabRole == collabRole)&&(identical(other.imageStoragePath, imageStoragePath) || other.imageStoragePath == imageStoragePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,prepTimeMinutes,cookTimeMinutes,const DeepCollectionEquality().hash(ingredients),const DeepCollectionEquality().hash(steps),const DeepCollectionEquality().hash(dietaryTags),sourceChannel,sourceUrl,createdAt,imageFileName,savedFromSharedId,pendingAnalysis,collabId,collabRole,imageStoragePath);

@override
String toString() {
  return 'RecipeModel(id: $id, title: $title, prepTimeMinutes: $prepTimeMinutes, cookTimeMinutes: $cookTimeMinutes, ingredients: $ingredients, steps: $steps, dietaryTags: $dietaryTags, sourceChannel: $sourceChannel, sourceUrl: $sourceUrl, createdAt: $createdAt, imageFileName: $imageFileName, savedFromSharedId: $savedFromSharedId, pendingAnalysis: $pendingAnalysis, collabId: $collabId, collabRole: $collabRole, imageStoragePath: $imageStoragePath)';
}


}

/// @nodoc
abstract mixin class $RecipeModelCopyWith<$Res>  {
  factory $RecipeModelCopyWith(RecipeModel value, $Res Function(RecipeModel) _then) = _$RecipeModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String title,@HiveField(2) int? prepTimeMinutes,@HiveField(3) int? cookTimeMinutes,@HiveField(4) List<RecipeIngredientModel> ingredients,@HiveField(5) List<String> steps,@HiveField(6) List<DietaryPreference> dietaryTags,@HiveField(7) String? sourceChannel,@HiveField(8) String? sourceUrl,@HiveField(9) DateTime createdAt,@HiveField(10) String? imageFileName,@HiveField(11) String? savedFromSharedId,@HiveField(12) bool pendingAnalysis,@HiveField(13) String? collabId,@HiveField(14) String? collabRole,@HiveField(15) String? imageStoragePath
});




}
/// @nodoc
class _$RecipeModelCopyWithImpl<$Res>
    implements $RecipeModelCopyWith<$Res> {
  _$RecipeModelCopyWithImpl(this._self, this._then);

  final RecipeModel _self;
  final $Res Function(RecipeModel) _then;

/// Create a copy of RecipeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? prepTimeMinutes = freezed,Object? cookTimeMinutes = freezed,Object? ingredients = null,Object? steps = null,Object? dietaryTags = null,Object? sourceChannel = freezed,Object? sourceUrl = freezed,Object? createdAt = null,Object? imageFileName = freezed,Object? savedFromSharedId = freezed,Object? pendingAnalysis = null,Object? collabId = freezed,Object? collabRole = freezed,Object? imageStoragePath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,prepTimeMinutes: freezed == prepTimeMinutes ? _self.prepTimeMinutes : prepTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookTimeMinutes: freezed == cookTimeMinutes ? _self.cookTimeMinutes : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,ingredients: null == ingredients ? _self.ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredientModel>,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,dietaryTags: null == dietaryTags ? _self.dietaryTags : dietaryTags // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,sourceChannel: freezed == sourceChannel ? _self.sourceChannel : sourceChannel // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageFileName: freezed == imageFileName ? _self.imageFileName : imageFileName // ignore: cast_nullable_to_non_nullable
as String?,savedFromSharedId: freezed == savedFromSharedId ? _self.savedFromSharedId : savedFromSharedId // ignore: cast_nullable_to_non_nullable
as String?,pendingAnalysis: null == pendingAnalysis ? _self.pendingAnalysis : pendingAnalysis // ignore: cast_nullable_to_non_nullable
as bool,collabId: freezed == collabId ? _self.collabId : collabId // ignore: cast_nullable_to_non_nullable
as String?,collabRole: freezed == collabRole ? _self.collabRole : collabRole // ignore: cast_nullable_to_non_nullable
as String?,imageStoragePath: freezed == imageStoragePath ? _self.imageStoragePath : imageStoragePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeModel].
extension RecipeModelPatterns on RecipeModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeModel value)  $default,){
final _that = this;
switch (_that) {
case _RecipeModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeModel value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  int? prepTimeMinutes, @HiveField(3)  int? cookTimeMinutes, @HiveField(4)  List<RecipeIngredientModel> ingredients, @HiveField(5)  List<String> steps, @HiveField(6)  List<DietaryPreference> dietaryTags, @HiveField(7)  String? sourceChannel, @HiveField(8)  String? sourceUrl, @HiveField(9)  DateTime createdAt, @HiveField(10)  String? imageFileName, @HiveField(11)  String? savedFromSharedId, @HiveField(12)  bool pendingAnalysis, @HiveField(13)  String? collabId, @HiveField(14)  String? collabRole, @HiveField(15)  String? imageStoragePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeModel() when $default != null:
return $default(_that.id,_that.title,_that.prepTimeMinutes,_that.cookTimeMinutes,_that.ingredients,_that.steps,_that.dietaryTags,_that.sourceChannel,_that.sourceUrl,_that.createdAt,_that.imageFileName,_that.savedFromSharedId,_that.pendingAnalysis,_that.collabId,_that.collabRole,_that.imageStoragePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  int? prepTimeMinutes, @HiveField(3)  int? cookTimeMinutes, @HiveField(4)  List<RecipeIngredientModel> ingredients, @HiveField(5)  List<String> steps, @HiveField(6)  List<DietaryPreference> dietaryTags, @HiveField(7)  String? sourceChannel, @HiveField(8)  String? sourceUrl, @HiveField(9)  DateTime createdAt, @HiveField(10)  String? imageFileName, @HiveField(11)  String? savedFromSharedId, @HiveField(12)  bool pendingAnalysis, @HiveField(13)  String? collabId, @HiveField(14)  String? collabRole, @HiveField(15)  String? imageStoragePath)  $default,) {final _that = this;
switch (_that) {
case _RecipeModel():
return $default(_that.id,_that.title,_that.prepTimeMinutes,_that.cookTimeMinutes,_that.ingredients,_that.steps,_that.dietaryTags,_that.sourceChannel,_that.sourceUrl,_that.createdAt,_that.imageFileName,_that.savedFromSharedId,_that.pendingAnalysis,_that.collabId,_that.collabRole,_that.imageStoragePath);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  int? prepTimeMinutes, @HiveField(3)  int? cookTimeMinutes, @HiveField(4)  List<RecipeIngredientModel> ingredients, @HiveField(5)  List<String> steps, @HiveField(6)  List<DietaryPreference> dietaryTags, @HiveField(7)  String? sourceChannel, @HiveField(8)  String? sourceUrl, @HiveField(9)  DateTime createdAt, @HiveField(10)  String? imageFileName, @HiveField(11)  String? savedFromSharedId, @HiveField(12)  bool pendingAnalysis, @HiveField(13)  String? collabId, @HiveField(14)  String? collabRole, @HiveField(15)  String? imageStoragePath)?  $default,) {final _that = this;
switch (_that) {
case _RecipeModel() when $default != null:
return $default(_that.id,_that.title,_that.prepTimeMinutes,_that.cookTimeMinutes,_that.ingredients,_that.steps,_that.dietaryTags,_that.sourceChannel,_that.sourceUrl,_that.createdAt,_that.imageFileName,_that.savedFromSharedId,_that.pendingAnalysis,_that.collabId,_that.collabRole,_that.imageStoragePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeModel implements RecipeModel {
  const _RecipeModel({@HiveField(0) required this.id, @HiveField(1) required this.title, @HiveField(2) this.prepTimeMinutes, @HiveField(3) this.cookTimeMinutes, @HiveField(4) required final  List<RecipeIngredientModel> ingredients, @HiveField(5) required final  List<String> steps, @HiveField(6) final  List<DietaryPreference> dietaryTags = const [], @HiveField(7) this.sourceChannel, @HiveField(8) this.sourceUrl, @HiveField(9) required this.createdAt, @HiveField(10) this.imageFileName, @HiveField(11) this.savedFromSharedId, @HiveField(12) this.pendingAnalysis = false, @HiveField(13) this.collabId, @HiveField(14) this.collabRole, @HiveField(15) this.imageStoragePath}): _ingredients = ingredients,_steps = steps,_dietaryTags = dietaryTags;
  factory _RecipeModel.fromJson(Map<String, dynamic> json) => _$RecipeModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String title;
@override@HiveField(2) final  int? prepTimeMinutes;
@override@HiveField(3) final  int? cookTimeMinutes;
 final  List<RecipeIngredientModel> _ingredients;
@override@HiveField(4) List<RecipeIngredientModel> get ingredients {
  if (_ingredients is EqualUnmodifiableListView) return _ingredients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredients);
}

 final  List<String> _steps;
@override@HiveField(5) List<String> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<DietaryPreference> _dietaryTags;
@override@JsonKey()@HiveField(6) List<DietaryPreference> get dietaryTags {
  if (_dietaryTags is EqualUnmodifiableListView) return _dietaryTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryTags);
}

@override@HiveField(7) final  String? sourceChannel;
@override@HiveField(8) final  String? sourceUrl;
@override@HiveField(9) final  DateTime createdAt;
@override@HiveField(10) final  String? imageFileName;
// Appended, never reordered: recipes written before this existed decode
// as null, which correctly reads as "mine".
@override@HiveField(11) final  String? savedFromSharedId;
@override@JsonKey()@HiveField(12) final  bool pendingAnalysis;
@override@HiveField(13) final  String? collabId;
// Enum name as a string, like `sourceChannel`, so no adapter is needed.
@override@HiveField(14) final  String? collabRole;
// Appended like the fields above it: a recipe stored before photos could
// travel decodes as null, which correctly reads as "never uploaded".
@override@HiveField(15) final  String? imageStoragePath;

/// Create a copy of RecipeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeModelCopyWith<_RecipeModel> get copyWith => __$RecipeModelCopyWithImpl<_RecipeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.prepTimeMinutes, prepTimeMinutes) || other.prepTimeMinutes == prepTimeMinutes)&&(identical(other.cookTimeMinutes, cookTimeMinutes) || other.cookTimeMinutes == cookTimeMinutes)&&const DeepCollectionEquality().equals(other._ingredients, _ingredients)&&const DeepCollectionEquality().equals(other._steps, _steps)&&const DeepCollectionEquality().equals(other._dietaryTags, _dietaryTags)&&(identical(other.sourceChannel, sourceChannel) || other.sourceChannel == sourceChannel)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.imageFileName, imageFileName) || other.imageFileName == imageFileName)&&(identical(other.savedFromSharedId, savedFromSharedId) || other.savedFromSharedId == savedFromSharedId)&&(identical(other.pendingAnalysis, pendingAnalysis) || other.pendingAnalysis == pendingAnalysis)&&(identical(other.collabId, collabId) || other.collabId == collabId)&&(identical(other.collabRole, collabRole) || other.collabRole == collabRole)&&(identical(other.imageStoragePath, imageStoragePath) || other.imageStoragePath == imageStoragePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,prepTimeMinutes,cookTimeMinutes,const DeepCollectionEquality().hash(_ingredients),const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_dietaryTags),sourceChannel,sourceUrl,createdAt,imageFileName,savedFromSharedId,pendingAnalysis,collabId,collabRole,imageStoragePath);

@override
String toString() {
  return 'RecipeModel(id: $id, title: $title, prepTimeMinutes: $prepTimeMinutes, cookTimeMinutes: $cookTimeMinutes, ingredients: $ingredients, steps: $steps, dietaryTags: $dietaryTags, sourceChannel: $sourceChannel, sourceUrl: $sourceUrl, createdAt: $createdAt, imageFileName: $imageFileName, savedFromSharedId: $savedFromSharedId, pendingAnalysis: $pendingAnalysis, collabId: $collabId, collabRole: $collabRole, imageStoragePath: $imageStoragePath)';
}


}

/// @nodoc
abstract mixin class _$RecipeModelCopyWith<$Res> implements $RecipeModelCopyWith<$Res> {
  factory _$RecipeModelCopyWith(_RecipeModel value, $Res Function(_RecipeModel) _then) = __$RecipeModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String title,@HiveField(2) int? prepTimeMinutes,@HiveField(3) int? cookTimeMinutes,@HiveField(4) List<RecipeIngredientModel> ingredients,@HiveField(5) List<String> steps,@HiveField(6) List<DietaryPreference> dietaryTags,@HiveField(7) String? sourceChannel,@HiveField(8) String? sourceUrl,@HiveField(9) DateTime createdAt,@HiveField(10) String? imageFileName,@HiveField(11) String? savedFromSharedId,@HiveField(12) bool pendingAnalysis,@HiveField(13) String? collabId,@HiveField(14) String? collabRole,@HiveField(15) String? imageStoragePath
});




}
/// @nodoc
class __$RecipeModelCopyWithImpl<$Res>
    implements _$RecipeModelCopyWith<$Res> {
  __$RecipeModelCopyWithImpl(this._self, this._then);

  final _RecipeModel _self;
  final $Res Function(_RecipeModel) _then;

/// Create a copy of RecipeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? prepTimeMinutes = freezed,Object? cookTimeMinutes = freezed,Object? ingredients = null,Object? steps = null,Object? dietaryTags = null,Object? sourceChannel = freezed,Object? sourceUrl = freezed,Object? createdAt = null,Object? imageFileName = freezed,Object? savedFromSharedId = freezed,Object? pendingAnalysis = null,Object? collabId = freezed,Object? collabRole = freezed,Object? imageStoragePath = freezed,}) {
  return _then(_RecipeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,prepTimeMinutes: freezed == prepTimeMinutes ? _self.prepTimeMinutes : prepTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,cookTimeMinutes: freezed == cookTimeMinutes ? _self.cookTimeMinutes : cookTimeMinutes // ignore: cast_nullable_to_non_nullable
as int?,ingredients: null == ingredients ? _self._ingredients : ingredients // ignore: cast_nullable_to_non_nullable
as List<RecipeIngredientModel>,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<String>,dietaryTags: null == dietaryTags ? _self._dietaryTags : dietaryTags // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,sourceChannel: freezed == sourceChannel ? _self.sourceChannel : sourceChannel // ignore: cast_nullable_to_non_nullable
as String?,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,imageFileName: freezed == imageFileName ? _self.imageFileName : imageFileName // ignore: cast_nullable_to_non_nullable
as String?,savedFromSharedId: freezed == savedFromSharedId ? _self.savedFromSharedId : savedFromSharedId // ignore: cast_nullable_to_non_nullable
as String?,pendingAnalysis: null == pendingAnalysis ? _self.pendingAnalysis : pendingAnalysis // ignore: cast_nullable_to_non_nullable
as bool,collabId: freezed == collabId ? _self.collabId : collabId // ignore: cast_nullable_to_non_nullable
as String?,collabRole: freezed == collabRole ? _self.collabRole : collabRole // ignore: cast_nullable_to_non_nullable
as String?,imageStoragePath: freezed == imageStoragePath ? _self.imageStoragePath : imageStoragePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
