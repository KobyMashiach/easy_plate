// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryEvent()';
}


}

/// @nodoc
class $LibraryEventCopyWith<$Res>  {
$LibraryEventCopyWith(LibraryEvent _, $Res Function(LibraryEvent) __);
}


/// Adds pattern-matching-related methods to [LibraryEvent].
extension LibraryEventPatterns on LibraryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _CreateBook value)?  createBook,TResult Function( _DeleteBook value)?  deleteBook,TResult Function( _SetCoverImage value)?  setCoverImage,TResult Function( _RenameBook value)?  renameBook,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _CreateBook() when createBook != null:
return createBook(_that);case _DeleteBook() when deleteBook != null:
return deleteBook(_that);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that);case _RenameBook() when renameBook != null:
return renameBook(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _CreateBook value)  createBook,required TResult Function( _DeleteBook value)  deleteBook,required TResult Function( _SetCoverImage value)  setCoverImage,required TResult Function( _RenameBook value)  renameBook,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _CreateBook():
return createBook(_that);case _DeleteBook():
return deleteBook(_that);case _SetCoverImage():
return setCoverImage(_that);case _RenameBook():
return renameBook(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _CreateBook value)?  createBook,TResult? Function( _DeleteBook value)?  deleteBook,TResult? Function( _SetCoverImage value)?  setCoverImage,TResult? Function( _RenameBook value)?  renameBook,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _CreateBook() when createBook != null:
return createBook(_that);case _DeleteBook() when deleteBook != null:
return deleteBook(_that);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that);case _RenameBook() when renameBook != null:
return renameBook(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( String title)?  createBook,TResult Function( String id)?  deleteBook,TResult Function( String id,  String? fileName)?  setCoverImage,TResult Function( String id,  String title)?  renameBook,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _CreateBook() when createBook != null:
return createBook(_that.title);case _DeleteBook() when deleteBook != null:
return deleteBook(_that.id);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that.id,_that.fileName);case _RenameBook() when renameBook != null:
return renameBook(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( String title)  createBook,required TResult Function( String id)  deleteBook,required TResult Function( String id,  String? fileName)  setCoverImage,required TResult Function( String id,  String title)  renameBook,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _CreateBook():
return createBook(_that.title);case _DeleteBook():
return deleteBook(_that.id);case _SetCoverImage():
return setCoverImage(_that.id,_that.fileName);case _RenameBook():
return renameBook(_that.id,_that.title);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( String title)?  createBook,TResult? Function( String id)?  deleteBook,TResult? Function( String id,  String? fileName)?  setCoverImage,TResult? Function( String id,  String title)?  renameBook,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _CreateBook() when createBook != null:
return createBook(_that.title);case _DeleteBook() when deleteBook != null:
return deleteBook(_that.id);case _SetCoverImage() when setCoverImage != null:
return setCoverImage(_that.id,_that.fileName);case _RenameBook() when renameBook != null:
return renameBook(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _Init implements LibraryEvent {
  const _Init();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Init);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryEvent.init()';
}


}




/// @nodoc


class _CreateBook implements LibraryEvent {
  const _CreateBook(this.title);
  

 final  String title;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateBookCopyWith<_CreateBook> get copyWith => __$CreateBookCopyWithImpl<_CreateBook>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateBook&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,title);

@override
String toString() {
  return 'LibraryEvent.createBook(title: $title)';
}


}

/// @nodoc
abstract mixin class _$CreateBookCopyWith<$Res> implements $LibraryEventCopyWith<$Res> {
  factory _$CreateBookCopyWith(_CreateBook value, $Res Function(_CreateBook) _then) = __$CreateBookCopyWithImpl;
@useResult
$Res call({
 String title
});




}
/// @nodoc
class __$CreateBookCopyWithImpl<$Res>
    implements _$CreateBookCopyWith<$Res> {
  __$CreateBookCopyWithImpl(this._self, this._then);

  final _CreateBook _self;
  final $Res Function(_CreateBook) _then;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,}) {
  return _then(_CreateBook(
null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeleteBook implements LibraryEvent {
  const _DeleteBook(this.id);
  

 final  String id;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteBookCopyWith<_DeleteBook> get copyWith => __$DeleteBookCopyWithImpl<_DeleteBook>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteBook&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'LibraryEvent.deleteBook(id: $id)';
}


}

/// @nodoc
abstract mixin class _$DeleteBookCopyWith<$Res> implements $LibraryEventCopyWith<$Res> {
  factory _$DeleteBookCopyWith(_DeleteBook value, $Res Function(_DeleteBook) _then) = __$DeleteBookCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$DeleteBookCopyWithImpl<$Res>
    implements _$DeleteBookCopyWith<$Res> {
  __$DeleteBookCopyWithImpl(this._self, this._then);

  final _DeleteBook _self;
  final $Res Function(_DeleteBook) _then;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_DeleteBook(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SetCoverImage implements LibraryEvent {
  const _SetCoverImage(this.id, this.fileName);
  

 final  String id;
 final  String? fileName;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetCoverImageCopyWith<_SetCoverImage> get copyWith => __$SetCoverImageCopyWithImpl<_SetCoverImage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetCoverImage&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName));
}


@override
int get hashCode => Object.hash(runtimeType,id,fileName);

@override
String toString() {
  return 'LibraryEvent.setCoverImage(id: $id, fileName: $fileName)';
}


}

/// @nodoc
abstract mixin class _$SetCoverImageCopyWith<$Res> implements $LibraryEventCopyWith<$Res> {
  factory _$SetCoverImageCopyWith(_SetCoverImage value, $Res Function(_SetCoverImage) _then) = __$SetCoverImageCopyWithImpl;
@useResult
$Res call({
 String id, String? fileName
});




}
/// @nodoc
class __$SetCoverImageCopyWithImpl<$Res>
    implements _$SetCoverImageCopyWith<$Res> {
  __$SetCoverImageCopyWithImpl(this._self, this._then);

  final _SetCoverImage _self;
  final $Res Function(_SetCoverImage) _then;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = freezed,}) {
  return _then(_SetCoverImage(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _RenameBook implements LibraryEvent {
  const _RenameBook(this.id, this.title);
  

 final  String id;
 final  String title;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RenameBookCopyWith<_RenameBook> get copyWith => __$RenameBookCopyWithImpl<_RenameBook>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RenameBook&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'LibraryEvent.renameBook(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$RenameBookCopyWith<$Res> implements $LibraryEventCopyWith<$Res> {
  factory _$RenameBookCopyWith(_RenameBook value, $Res Function(_RenameBook) _then) = __$RenameBookCopyWithImpl;
@useResult
$Res call({
 String id, String title
});




}
/// @nodoc
class __$RenameBookCopyWithImpl<$Res>
    implements _$RenameBookCopyWith<$Res> {
  __$RenameBookCopyWithImpl(this._self, this._then);

  final _RenameBook _self;
  final $Res Function(_RenameBook) _then;

/// Create a copy of LibraryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_RenameBook(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LibraryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryState()';
}


}

/// @nodoc
class $LibraryStateCopyWith<$Res>  {
$LibraryStateCopyWith(LibraryState _, $Res Function(LibraryState) __);
}


/// Adds pattern-matching-related methods to [LibraryState].
extension LibraryStatePatterns on LibraryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LibraryLoading value)?  loading,TResult Function( LibraryLoaded value)?  loaded,TResult Function( LibraryError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LibraryLoading() when loading != null:
return loading(_that);case LibraryLoaded() when loaded != null:
return loaded(_that);case LibraryError() when errorMessage != null:
return errorMessage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LibraryLoading value)  loading,required TResult Function( LibraryLoaded value)  loaded,required TResult Function( LibraryError value)  errorMessage,}){
final _that = this;
switch (_that) {
case LibraryLoading():
return loading(_that);case LibraryLoaded():
return loaded(_that);case LibraryError():
return errorMessage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LibraryLoading value)?  loading,TResult? Function( LibraryLoaded value)?  loaded,TResult? Function( LibraryError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case LibraryLoading() when loading != null:
return loading(_that);case LibraryLoaded() when loaded != null:
return loaded(_that);case LibraryError() when errorMessage != null:
return errorMessage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<RecipeBookEntity> books)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LibraryLoading() when loading != null:
return loading();case LibraryLoaded() when loaded != null:
return loaded(_that.books);case LibraryError() when errorMessage != null:
return errorMessage(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<RecipeBookEntity> books)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case LibraryLoading():
return loading();case LibraryLoaded():
return loaded(_that.books);case LibraryError():
return errorMessage(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<RecipeBookEntity> books)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case LibraryLoading() when loading != null:
return loading();case LibraryLoaded() when loaded != null:
return loaded(_that.books);case LibraryError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class LibraryLoading implements LibraryState {
  const LibraryLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LibraryState.loading()';
}


}




/// @nodoc


class LibraryLoaded implements LibraryState {
  const LibraryLoaded(final  List<RecipeBookEntity> books): _books = books;
  

 final  List<RecipeBookEntity> _books;
 List<RecipeBookEntity> get books {
  if (_books is EqualUnmodifiableListView) return _books;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_books);
}


/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryLoadedCopyWith<LibraryLoaded> get copyWith => _$LibraryLoadedCopyWithImpl<LibraryLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryLoaded&&const DeepCollectionEquality().equals(other._books, _books));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_books));

@override
String toString() {
  return 'LibraryState.loaded(books: $books)';
}


}

/// @nodoc
abstract mixin class $LibraryLoadedCopyWith<$Res> implements $LibraryStateCopyWith<$Res> {
  factory $LibraryLoadedCopyWith(LibraryLoaded value, $Res Function(LibraryLoaded) _then) = _$LibraryLoadedCopyWithImpl;
@useResult
$Res call({
 List<RecipeBookEntity> books
});




}
/// @nodoc
class _$LibraryLoadedCopyWithImpl<$Res>
    implements $LibraryLoadedCopyWith<$Res> {
  _$LibraryLoadedCopyWithImpl(this._self, this._then);

  final LibraryLoaded _self;
  final $Res Function(LibraryLoaded) _then;

/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? books = null,}) {
  return _then(LibraryLoaded(
null == books ? _self._books : books // ignore: cast_nullable_to_non_nullable
as List<RecipeBookEntity>,
  ));
}


}

/// @nodoc


class LibraryError implements LibraryState {
  const LibraryError(this.error);
  

 final  String error;

/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryErrorCopyWith<LibraryError> get copyWith => _$LibraryErrorCopyWithImpl<LibraryError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'LibraryState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $LibraryErrorCopyWith<$Res> implements $LibraryStateCopyWith<$Res> {
  factory $LibraryErrorCopyWith(LibraryError value, $Res Function(LibraryError) _then) = _$LibraryErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$LibraryErrorCopyWithImpl<$Res>
    implements $LibraryErrorCopyWith<$Res> {
  _$LibraryErrorCopyWithImpl(this._self, this._then);

  final LibraryError _self;
  final $Res Function(LibraryError) _then;

/// Create a copy of LibraryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(LibraryError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
