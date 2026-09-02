// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_viewer_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookViewerEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookViewerEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookViewerEvent()';
}


}

/// @nodoc
class $BookViewerEventCopyWith<$Res>  {
$BookViewerEventCopyWith(BookViewerEvent _, $Res Function(BookViewerEvent) __);
}


/// Adds pattern-matching-related methods to [BookViewerEvent].
extension BookViewerEventPatterns on BookViewerEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _AddRecipe value)?  addRecipe,TResult Function( _RemoveRecipe value)?  removeRecipe,TResult Function( _ReorderRecipes value)?  reorderRecipes,TResult Function( _SetCoverImage value)?  setCoverImage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _AddRecipe() when addRecipe != null:
return addRecipe(_that);case _RemoveRecipe() when removeRecipe != null:
return removeRecipe(_that);case _ReorderRecipes() when reorderRecipes != null:
return reorderRecipes(_that);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _AddRecipe value)  addRecipe,required TResult Function( _RemoveRecipe value)  removeRecipe,required TResult Function( _ReorderRecipes value)  reorderRecipes,required TResult Function( _SetCoverImage value)  setCoverImage,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _AddRecipe():
return addRecipe(_that);case _RemoveRecipe():
return removeRecipe(_that);case _ReorderRecipes():
return reorderRecipes(_that);case _SetCoverImage():
return setCoverImage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _AddRecipe value)?  addRecipe,TResult? Function( _RemoveRecipe value)?  removeRecipe,TResult? Function( _ReorderRecipes value)?  reorderRecipes,TResult? Function( _SetCoverImage value)?  setCoverImage,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _AddRecipe() when addRecipe != null:
return addRecipe(_that);case _RemoveRecipe() when removeRecipe != null:
return removeRecipe(_that);case _ReorderRecipes() when reorderRecipes != null:
return reorderRecipes(_that);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String bookId)?  init,TResult Function( String recipeId)?  addRecipe,TResult Function( String recipeId)?  removeRecipe,TResult Function( int oldIndex,  int newIndex)?  reorderRecipes,TResult Function( String? fileName)?  setCoverImage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that.bookId);case _AddRecipe() when addRecipe != null:
return addRecipe(_that.recipeId);case _RemoveRecipe() when removeRecipe != null:
return removeRecipe(_that.recipeId);case _ReorderRecipes() when reorderRecipes != null:
return reorderRecipes(_that.oldIndex,_that.newIndex);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that.fileName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String bookId)  init,required TResult Function( String recipeId)  addRecipe,required TResult Function( String recipeId)  removeRecipe,required TResult Function( int oldIndex,  int newIndex)  reorderRecipes,required TResult Function( String? fileName)  setCoverImage,}) {final _that = this;
switch (_that) {
case _Init():
return init(_that.bookId);case _AddRecipe():
return addRecipe(_that.recipeId);case _RemoveRecipe():
return removeRecipe(_that.recipeId);case _ReorderRecipes():
return reorderRecipes(_that.oldIndex,_that.newIndex);case _SetCoverImage():
return setCoverImage(_that.fileName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String bookId)?  init,TResult? Function( String recipeId)?  addRecipe,TResult? Function( String recipeId)?  removeRecipe,TResult? Function( int oldIndex,  int newIndex)?  reorderRecipes,TResult? Function( String? fileName)?  setCoverImage,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that.bookId);case _AddRecipe() when addRecipe != null:
return addRecipe(_that.recipeId);case _RemoveRecipe() when removeRecipe != null:
return removeRecipe(_that.recipeId);case _ReorderRecipes() when reorderRecipes != null:
return reorderRecipes(_that.oldIndex,_that.newIndex);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that.fileName);case _:
  return null;

}
}

}

/// @nodoc


class _Init implements BookViewerEvent {
  const _Init(this.bookId);
  

 final  String bookId;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InitCopyWith<_Init> get copyWith => __$InitCopyWithImpl<_Init>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Init&&(identical(other.bookId, bookId) || other.bookId == bookId));
}


@override
int get hashCode => Object.hash(runtimeType,bookId);

@override
String toString() {
  return 'BookViewerEvent.init(bookId: $bookId)';
}


}

/// @nodoc
abstract mixin class _$InitCopyWith<$Res> implements $BookViewerEventCopyWith<$Res> {
  factory _$InitCopyWith(_Init value, $Res Function(_Init) _then) = __$InitCopyWithImpl;
@useResult
$Res call({
 String bookId
});




}
/// @nodoc
class __$InitCopyWithImpl<$Res>
    implements _$InitCopyWith<$Res> {
  __$InitCopyWithImpl(this._self, this._then);

  final _Init _self;
  final $Res Function(_Init) _then;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? bookId = null,}) {
  return _then(_Init(
null == bookId ? _self.bookId : bookId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddRecipe implements BookViewerEvent {
  const _AddRecipe(this.recipeId);
  

 final  String recipeId;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddRecipeCopyWith<_AddRecipe> get copyWith => __$AddRecipeCopyWithImpl<_AddRecipe>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddRecipe&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId));
}


@override
int get hashCode => Object.hash(runtimeType,recipeId);

@override
String toString() {
  return 'BookViewerEvent.addRecipe(recipeId: $recipeId)';
}


}

/// @nodoc
abstract mixin class _$AddRecipeCopyWith<$Res> implements $BookViewerEventCopyWith<$Res> {
  factory _$AddRecipeCopyWith(_AddRecipe value, $Res Function(_AddRecipe) _then) = __$AddRecipeCopyWithImpl;
@useResult
$Res call({
 String recipeId
});




}
/// @nodoc
class __$AddRecipeCopyWithImpl<$Res>
    implements _$AddRecipeCopyWith<$Res> {
  __$AddRecipeCopyWithImpl(this._self, this._then);

  final _AddRecipe _self;
  final $Res Function(_AddRecipe) _then;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipeId = null,}) {
  return _then(_AddRecipe(
null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _RemoveRecipe implements BookViewerEvent {
  const _RemoveRecipe(this.recipeId);
  

 final  String recipeId;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveRecipeCopyWith<_RemoveRecipe> get copyWith => __$RemoveRecipeCopyWithImpl<_RemoveRecipe>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveRecipe&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId));
}


@override
int get hashCode => Object.hash(runtimeType,recipeId);

@override
String toString() {
  return 'BookViewerEvent.removeRecipe(recipeId: $recipeId)';
}


}

/// @nodoc
abstract mixin class _$RemoveRecipeCopyWith<$Res> implements $BookViewerEventCopyWith<$Res> {
  factory _$RemoveRecipeCopyWith(_RemoveRecipe value, $Res Function(_RemoveRecipe) _then) = __$RemoveRecipeCopyWithImpl;
@useResult
$Res call({
 String recipeId
});




}
/// @nodoc
class __$RemoveRecipeCopyWithImpl<$Res>
    implements _$RemoveRecipeCopyWith<$Res> {
  __$RemoveRecipeCopyWithImpl(this._self, this._then);

  final _RemoveRecipe _self;
  final $Res Function(_RemoveRecipe) _then;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipeId = null,}) {
  return _then(_RemoveRecipe(
null == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ReorderRecipes implements BookViewerEvent {
  const _ReorderRecipes(this.oldIndex, this.newIndex);
  

 final  int oldIndex;
 final  int newIndex;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReorderRecipesCopyWith<_ReorderRecipes> get copyWith => __$ReorderRecipesCopyWithImpl<_ReorderRecipes>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReorderRecipes&&(identical(other.oldIndex, oldIndex) || other.oldIndex == oldIndex)&&(identical(other.newIndex, newIndex) || other.newIndex == newIndex));
}


@override
int get hashCode => Object.hash(runtimeType,oldIndex,newIndex);

@override
String toString() {
  return 'BookViewerEvent.reorderRecipes(oldIndex: $oldIndex, newIndex: $newIndex)';
}


}

/// @nodoc
abstract mixin class _$ReorderRecipesCopyWith<$Res> implements $BookViewerEventCopyWith<$Res> {
  factory _$ReorderRecipesCopyWith(_ReorderRecipes value, $Res Function(_ReorderRecipes) _then) = __$ReorderRecipesCopyWithImpl;
@useResult
$Res call({
 int oldIndex, int newIndex
});




}
/// @nodoc
class __$ReorderRecipesCopyWithImpl<$Res>
    implements _$ReorderRecipesCopyWith<$Res> {
  __$ReorderRecipesCopyWithImpl(this._self, this._then);

  final _ReorderRecipes _self;
  final $Res Function(_ReorderRecipes) _then;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? oldIndex = null,Object? newIndex = null,}) {
  return _then(_ReorderRecipes(
null == oldIndex ? _self.oldIndex : oldIndex // ignore: cast_nullable_to_non_nullable
as int,null == newIndex ? _self.newIndex : newIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _SetCoverImage implements BookViewerEvent {
  const _SetCoverImage(this.fileName);
  

 final  String? fileName;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetCoverImageCopyWith<_SetCoverImage> get copyWith => __$SetCoverImageCopyWithImpl<_SetCoverImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetCoverImage&&(identical(other.fileName, fileName) || other.fileName == fileName));
}


@override
int get hashCode => Object.hash(runtimeType,fileName);

@override
String toString() {
  return 'BookViewerEvent.setCoverImage(fileName: $fileName)';
}


}

/// @nodoc
abstract mixin class _$SetCoverImageCopyWith<$Res> implements $BookViewerEventCopyWith<$Res> {
  factory _$SetCoverImageCopyWith(_SetCoverImage value, $Res Function(_SetCoverImage) _then) = __$SetCoverImageCopyWithImpl;
@useResult
$Res call({
 String? fileName
});




}
/// @nodoc
class __$SetCoverImageCopyWithImpl<$Res>
    implements _$SetCoverImageCopyWith<$Res> {
  __$SetCoverImageCopyWithImpl(this._self, this._then);

  final _SetCoverImage _self;
  final $Res Function(_SetCoverImage) _then;

/// Create a copy of BookViewerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fileName = freezed,}) {
  return _then(_SetCoverImage(
freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$BookViewerState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookViewerState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookViewerState()';
}


}

/// @nodoc
class $BookViewerStateCopyWith<$Res>  {
$BookViewerStateCopyWith(BookViewerState _, $Res Function(BookViewerState) __);
}


/// Adds pattern-matching-related methods to [BookViewerState].
extension BookViewerStatePatterns on BookViewerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BookViewerLoading value)?  loading,TResult Function( BookViewerLoaded value)?  loaded,TResult Function( BookViewerNotFound value)?  notFound,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BookViewerLoading() when loading != null:
return loading(_that);case BookViewerLoaded() when loaded != null:
return loaded(_that);case BookViewerNotFound() when notFound != null:
return notFound(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BookViewerLoading value)  loading,required TResult Function( BookViewerLoaded value)  loaded,required TResult Function( BookViewerNotFound value)  notFound,}){
final _that = this;
switch (_that) {
case BookViewerLoading():
return loading(_that);case BookViewerLoaded():
return loaded(_that);case BookViewerNotFound():
return notFound(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BookViewerLoading value)?  loading,TResult? Function( BookViewerLoaded value)?  loaded,TResult? Function( BookViewerNotFound value)?  notFound,}){
final _that = this;
switch (_that) {
case BookViewerLoading() when loading != null:
return loading(_that);case BookViewerLoaded() when loaded != null:
return loaded(_that);case BookViewerNotFound() when notFound != null:
return notFound(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( RecipeBookEntity book,  List<RecipeEntity> recipes)?  loaded,TResult Function()?  notFound,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BookViewerLoading() when loading != null:
return loading();case BookViewerLoaded() when loaded != null:
return loaded(_that.book,_that.recipes);case BookViewerNotFound() when notFound != null:
return notFound();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( RecipeBookEntity book,  List<RecipeEntity> recipes)  loaded,required TResult Function()  notFound,}) {final _that = this;
switch (_that) {
case BookViewerLoading():
return loading();case BookViewerLoaded():
return loaded(_that.book,_that.recipes);case BookViewerNotFound():
return notFound();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( RecipeBookEntity book,  List<RecipeEntity> recipes)?  loaded,TResult? Function()?  notFound,}) {final _that = this;
switch (_that) {
case BookViewerLoading() when loading != null:
return loading();case BookViewerLoaded() when loaded != null:
return loaded(_that.book,_that.recipes);case BookViewerNotFound() when notFound != null:
return notFound();case _:
  return null;

}
}

}

/// @nodoc


class BookViewerLoading implements BookViewerState {
  const BookViewerLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookViewerLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookViewerState.loading()';
}


}




/// @nodoc


class BookViewerLoaded implements BookViewerState {
  const BookViewerLoaded(this.book, final  List<RecipeEntity> recipes): _recipes = recipes;
  

 final  RecipeBookEntity book;
 final  List<RecipeEntity> _recipes;
 List<RecipeEntity> get recipes {
  if (_recipes is EqualUnmodifiableListView) return _recipes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recipes);
}


/// Create a copy of BookViewerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookViewerLoadedCopyWith<BookViewerLoaded> get copyWith => _$BookViewerLoadedCopyWithImpl<BookViewerLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookViewerLoaded&&(identical(other.book, book) || other.book == book)&&const DeepCollectionEquality().equals(other._recipes, _recipes));
}


@override
int get hashCode => Object.hash(runtimeType,book,const DeepCollectionEquality().hash(_recipes));

@override
String toString() {
  return 'BookViewerState.loaded(book: $book, recipes: $recipes)';
}


}

/// @nodoc
abstract mixin class $BookViewerLoadedCopyWith<$Res> implements $BookViewerStateCopyWith<$Res> {
  factory $BookViewerLoadedCopyWith(BookViewerLoaded value, $Res Function(BookViewerLoaded) _then) = _$BookViewerLoadedCopyWithImpl;
@useResult
$Res call({
 RecipeBookEntity book, List<RecipeEntity> recipes
});




}
/// @nodoc
class _$BookViewerLoadedCopyWithImpl<$Res>
    implements $BookViewerLoadedCopyWith<$Res> {
  _$BookViewerLoadedCopyWithImpl(this._self, this._then);

  final BookViewerLoaded _self;
  final $Res Function(BookViewerLoaded) _then;

/// Create a copy of BookViewerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? book = null,Object? recipes = null,}) {
  return _then(BookViewerLoaded(
null == book ? _self.book : book // ignore: cast_nullable_to_non_nullable
as RecipeBookEntity,null == recipes ? _self._recipes : recipes // ignore: cast_nullable_to_non_nullable
as List<RecipeEntity>,
  ));
}


}

/// @nodoc


class BookViewerNotFound implements BookViewerState {
  const BookViewerNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookViewerNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BookViewerState.notFound()';
}


}




// dart format on
