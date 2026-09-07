// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_book_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeBookModel {

@HiveField(0) String get id;@HiveField(1) String get title;@HiveField(2) List<BookRecipeRefModel> get recipeRefs;@HiveField(3) Map<String, String> get collaborators;@HiveField(4) DateTime get createdAt;@HiveField(5) String? get coverImageFileName;@HiveField(6) String? get coverImageStoragePath;
/// Create a copy of RecipeBookModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeBookModelCopyWith<RecipeBookModel> get copyWith => _$RecipeBookModelCopyWithImpl<RecipeBookModel>(this as RecipeBookModel, _$identity);

  /// Serializes this RecipeBookModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeBookModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.recipeRefs, recipeRefs)&&const DeepCollectionEquality().equals(other.collaborators, collaborators)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.coverImageFileName, coverImageFileName) || other.coverImageFileName == coverImageFileName)&&(identical(other.coverImageStoragePath, coverImageStoragePath) || other.coverImageStoragePath == coverImageStoragePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(recipeRefs),const DeepCollectionEquality().hash(collaborators),createdAt,coverImageFileName,coverImageStoragePath);

@override
String toString() {
  return 'RecipeBookModel(id: $id, title: $title, recipeRefs: $recipeRefs, collaborators: $collaborators, createdAt: $createdAt, coverImageFileName: $coverImageFileName, coverImageStoragePath: $coverImageStoragePath)';
}


}

/// @nodoc
abstract mixin class $RecipeBookModelCopyWith<$Res>  {
  factory $RecipeBookModelCopyWith(RecipeBookModel value, $Res Function(RecipeBookModel) _then) = _$RecipeBookModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String title,@HiveField(2) List<BookRecipeRefModel> recipeRefs,@HiveField(3) Map<String, String> collaborators,@HiveField(4) DateTime createdAt,@HiveField(5) String? coverImageFileName,@HiveField(6) String? coverImageStoragePath
});




}
/// @nodoc
class _$RecipeBookModelCopyWithImpl<$Res>
    implements $RecipeBookModelCopyWith<$Res> {
  _$RecipeBookModelCopyWithImpl(this._self, this._then);

  final RecipeBookModel _self;
  final $Res Function(RecipeBookModel) _then;

/// Create a copy of RecipeBookModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? recipeRefs = null,Object? collaborators = null,Object? createdAt = null,Object? coverImageFileName = freezed,Object? coverImageStoragePath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,recipeRefs: null == recipeRefs ? _self.recipeRefs : recipeRefs // ignore: cast_nullable_to_non_nullable
as List<BookRecipeRefModel>,collaborators: null == collaborators ? _self.collaborators : collaborators // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,coverImageFileName: freezed == coverImageFileName ? _self.coverImageFileName : coverImageFileName // ignore: cast_nullable_to_non_nullable
as String?,coverImageStoragePath: freezed == coverImageStoragePath ? _self.coverImageStoragePath : coverImageStoragePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeBookModel].
extension RecipeBookModelPatterns on RecipeBookModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeBookModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeBookModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeBookModel value)  $default,){
final _that = this;
switch (_that) {
case _RecipeBookModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeBookModel value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeBookModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  List<BookRecipeRefModel> recipeRefs, @HiveField(3)  Map<String, String> collaborators, @HiveField(4)  DateTime createdAt, @HiveField(5)  String? coverImageFileName, @HiveField(6)  String? coverImageStoragePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeBookModel() when $default != null:
return $default(_that.id,_that.title,_that.recipeRefs,_that.collaborators,_that.createdAt,_that.coverImageFileName,_that.coverImageStoragePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  List<BookRecipeRefModel> recipeRefs, @HiveField(3)  Map<String, String> collaborators, @HiveField(4)  DateTime createdAt, @HiveField(5)  String? coverImageFileName, @HiveField(6)  String? coverImageStoragePath)  $default,) {final _that = this;
switch (_that) {
case _RecipeBookModel():
return $default(_that.id,_that.title,_that.recipeRefs,_that.collaborators,_that.createdAt,_that.coverImageFileName,_that.coverImageStoragePath);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  List<BookRecipeRefModel> recipeRefs, @HiveField(3)  Map<String, String> collaborators, @HiveField(4)  DateTime createdAt, @HiveField(5)  String? coverImageFileName, @HiveField(6)  String? coverImageStoragePath)?  $default,) {final _that = this;
switch (_that) {
case _RecipeBookModel() when $default != null:
return $default(_that.id,_that.title,_that.recipeRefs,_that.collaborators,_that.createdAt,_that.coverImageFileName,_that.coverImageStoragePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeBookModel implements RecipeBookModel {
  const _RecipeBookModel({@HiveField(0) required this.id, @HiveField(1) required this.title, @HiveField(2) required final  List<BookRecipeRefModel> recipeRefs, @HiveField(3) final  Map<String, String> collaborators = const {}, @HiveField(4) required this.createdAt, @HiveField(5) this.coverImageFileName, @HiveField(6) this.coverImageStoragePath}): _recipeRefs = recipeRefs,_collaborators = collaborators;
  factory _RecipeBookModel.fromJson(Map<String, dynamic> json) => _$RecipeBookModelFromJson(json);

@override@HiveField(0) final  String id;
@override@HiveField(1) final  String title;
 final  List<BookRecipeRefModel> _recipeRefs;
@override@HiveField(2) List<BookRecipeRefModel> get recipeRefs {
  if (_recipeRefs is EqualUnmodifiableListView) return _recipeRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recipeRefs);
}

 final  Map<String, String> _collaborators;
@override@JsonKey()@HiveField(3) Map<String, String> get collaborators {
  if (_collaborators is EqualUnmodifiableMapView) return _collaborators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_collaborators);
}

@override@HiveField(4) final  DateTime createdAt;
@override@HiveField(5) final  String? coverImageFileName;
@override@HiveField(6) final  String? coverImageStoragePath;

/// Create a copy of RecipeBookModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeBookModelCopyWith<_RecipeBookModel> get copyWith => __$RecipeBookModelCopyWithImpl<_RecipeBookModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeBookModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeBookModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._recipeRefs, _recipeRefs)&&const DeepCollectionEquality().equals(other._collaborators, _collaborators)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.coverImageFileName, coverImageFileName) || other.coverImageFileName == coverImageFileName)&&(identical(other.coverImageStoragePath, coverImageStoragePath) || other.coverImageStoragePath == coverImageStoragePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_recipeRefs),const DeepCollectionEquality().hash(_collaborators),createdAt,coverImageFileName,coverImageStoragePath);

@override
String toString() {
  return 'RecipeBookModel(id: $id, title: $title, recipeRefs: $recipeRefs, collaborators: $collaborators, createdAt: $createdAt, coverImageFileName: $coverImageFileName, coverImageStoragePath: $coverImageStoragePath)';
}


}

/// @nodoc
abstract mixin class _$RecipeBookModelCopyWith<$Res> implements $RecipeBookModelCopyWith<$Res> {
  factory _$RecipeBookModelCopyWith(_RecipeBookModel value, $Res Function(_RecipeBookModel) _then) = __$RecipeBookModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String title,@HiveField(2) List<BookRecipeRefModel> recipeRefs,@HiveField(3) Map<String, String> collaborators,@HiveField(4) DateTime createdAt,@HiveField(5) String? coverImageFileName,@HiveField(6) String? coverImageStoragePath
});




}
/// @nodoc
class __$RecipeBookModelCopyWithImpl<$Res>
    implements _$RecipeBookModelCopyWith<$Res> {
  __$RecipeBookModelCopyWithImpl(this._self, this._then);

  final _RecipeBookModel _self;
  final $Res Function(_RecipeBookModel) _then;

/// Create a copy of RecipeBookModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? recipeRefs = null,Object? collaborators = null,Object? createdAt = null,Object? coverImageFileName = freezed,Object? coverImageStoragePath = freezed,}) {
  return _then(_RecipeBookModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,recipeRefs: null == recipeRefs ? _self._recipeRefs : recipeRefs // ignore: cast_nullable_to_non_nullable
as List<BookRecipeRefModel>,collaborators: null == collaborators ? _self._collaborators : collaborators // ignore: cast_nullable_to_non_nullable
as Map<String, String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,coverImageFileName: freezed == coverImageFileName ? _self.coverImageFileName : coverImageFileName // ignore: cast_nullable_to_non_nullable
as String?,coverImageStoragePath: freezed == coverImageStoragePath ? _self.coverImageStoragePath : coverImageStoragePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
