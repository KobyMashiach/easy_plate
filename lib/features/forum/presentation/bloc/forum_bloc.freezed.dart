// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forum_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForumEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumEvent()';
}


}

/// @nodoc
class $ForumEventCopyWith<$Res>  {
$ForumEventCopyWith(ForumEvent _, $Res Function(ForumEvent) __);
}


/// Adds pattern-matching-related methods to [ForumEvent].
extension ForumEventPatterns on ForumEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _Refresh value)?  refresh,TResult Function( _CreatePost value)?  createPost,TResult Function( _DeletePost value)?  deletePost,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Refresh() when refresh != null:
return refresh(_that);case _CreatePost() when createPost != null:
return createPost(_that);case _DeletePost() when deletePost != null:
return deletePost(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _Refresh value)  refresh,required TResult Function( _CreatePost value)  createPost,required TResult Function( _DeletePost value)  deletePost,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _Refresh():
return refresh(_that);case _CreatePost():
return createPost(_that);case _DeletePost():
return deletePost(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _Refresh value)?  refresh,TResult? Function( _CreatePost value)?  createPost,TResult? Function( _DeletePost value)?  deletePost,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Refresh() when refresh != null:
return refresh(_that);case _CreatePost() when createPost != null:
return createPost(_that);case _DeletePost() when deletePost != null:
return deletePost(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( Completer<void> done)?  refresh,TResult Function( String title,  String body)?  createPost,TResult Function( String postId)?  deletePost,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Refresh() when refresh != null:
return refresh(_that.done);case _CreatePost() when createPost != null:
return createPost(_that.title,_that.body);case _DeletePost() when deletePost != null:
return deletePost(_that.postId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( Completer<void> done)  refresh,required TResult Function( String title,  String body)  createPost,required TResult Function( String postId)  deletePost,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _Refresh():
return refresh(_that.done);case _CreatePost():
return createPost(_that.title,_that.body);case _DeletePost():
return deletePost(_that.postId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( Completer<void> done)?  refresh,TResult? Function( String title,  String body)?  createPost,TResult? Function( String postId)?  deletePost,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Refresh() when refresh != null:
return refresh(_that.done);case _CreatePost() when createPost != null:
return createPost(_that.title,_that.body);case _DeletePost() when deletePost != null:
return deletePost(_that.postId);case _:
  return null;

}
}

}

/// @nodoc


class _Init with DiagnosticableTreeMixin implements ForumEvent {
  const _Init();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumEvent.init'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Init);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumEvent.init()';
}


}




/// @nodoc


class _Refresh with DiagnosticableTreeMixin implements ForumEvent {
  const _Refresh(this.done);
  

 final  Completer<void> done;

/// Create a copy of ForumEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshCopyWith<_Refresh> get copyWith => __$RefreshCopyWithImpl<_Refresh>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumEvent.refresh'))
    ..add(DiagnosticsProperty('done', done));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Refresh&&(identical(other.done, done) || other.done == done));
}


@override
int get hashCode => Object.hash(runtimeType,done);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumEvent.refresh(done: $done)';
}


}

/// @nodoc
abstract mixin class _$RefreshCopyWith<$Res> implements $ForumEventCopyWith<$Res> {
  factory _$RefreshCopyWith(_Refresh value, $Res Function(_Refresh) _then) = __$RefreshCopyWithImpl;
@useResult
$Res call({
 Completer<void> done
});




}
/// @nodoc
class __$RefreshCopyWithImpl<$Res>
    implements _$RefreshCopyWith<$Res> {
  __$RefreshCopyWithImpl(this._self, this._then);

  final _Refresh _self;
  final $Res Function(_Refresh) _then;

/// Create a copy of ForumEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? done = null,}) {
  return _then(_Refresh(
null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as Completer<void>,
  ));
}


}

/// @nodoc


class _CreatePost with DiagnosticableTreeMixin implements ForumEvent {
  const _CreatePost(this.title, this.body);
  

 final  String title;
 final  String body;

/// Create a copy of ForumEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePostCopyWith<_CreatePost> get copyWith => __$CreatePostCopyWithImpl<_CreatePost>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumEvent.createPost'))
    ..add(DiagnosticsProperty('title', title))..add(DiagnosticsProperty('body', body));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePost&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,title,body);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumEvent.createPost(title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$CreatePostCopyWith<$Res> implements $ForumEventCopyWith<$Res> {
  factory _$CreatePostCopyWith(_CreatePost value, $Res Function(_CreatePost) _then) = __$CreatePostCopyWithImpl;
@useResult
$Res call({
 String title, String body
});




}
/// @nodoc
class __$CreatePostCopyWithImpl<$Res>
    implements _$CreatePostCopyWith<$Res> {
  __$CreatePostCopyWithImpl(this._self, this._then);

  final _CreatePost _self;
  final $Res Function(_CreatePost) _then;

/// Create a copy of ForumEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,}) {
  return _then(_CreatePost(
null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeletePost with DiagnosticableTreeMixin implements ForumEvent {
  const _DeletePost(this.postId);
  

 final  String postId;

/// Create a copy of ForumEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletePostCopyWith<_DeletePost> get copyWith => __$DeletePostCopyWithImpl<_DeletePost>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumEvent.deletePost'))
    ..add(DiagnosticsProperty('postId', postId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletePost&&(identical(other.postId, postId) || other.postId == postId));
}


@override
int get hashCode => Object.hash(runtimeType,postId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumEvent.deletePost(postId: $postId)';
}


}

/// @nodoc
abstract mixin class _$DeletePostCopyWith<$Res> implements $ForumEventCopyWith<$Res> {
  factory _$DeletePostCopyWith(_DeletePost value, $Res Function(_DeletePost) _then) = __$DeletePostCopyWithImpl;
@useResult
$Res call({
 String postId
});




}
/// @nodoc
class __$DeletePostCopyWithImpl<$Res>
    implements _$DeletePostCopyWith<$Res> {
  __$DeletePostCopyWithImpl(this._self, this._then);

  final _DeletePost _self;
  final $Res Function(_DeletePost) _then;

/// Create a copy of ForumEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? postId = null,}) {
  return _then(_DeletePost(
null == postId ? _self.postId : postId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ForumState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumState()';
}


}

/// @nodoc
class $ForumStateCopyWith<$Res>  {
$ForumStateCopyWith(ForumState _, $Res Function(ForumState) __);
}


/// Adds pattern-matching-related methods to [ForumState].
extension ForumStatePatterns on ForumState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForumLoading value)?  loading,TResult Function( ForumLoaded value)?  loaded,TResult Function( ForumError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForumLoading() when loading != null:
return loading(_that);case ForumLoaded() when loaded != null:
return loaded(_that);case ForumError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForumLoading value)  loading,required TResult Function( ForumLoaded value)  loaded,required TResult Function( ForumError value)  errorMessage,}){
final _that = this;
switch (_that) {
case ForumLoading():
return loading(_that);case ForumLoaded():
return loaded(_that);case ForumError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForumLoading value)?  loading,TResult? Function( ForumLoaded value)?  loaded,TResult? Function( ForumError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case ForumLoading() when loading != null:
return loading(_that);case ForumLoaded() when loaded != null:
return loaded(_that);case ForumError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<ForumPostEntity> posts)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForumLoading() when loading != null:
return loading();case ForumLoaded() when loaded != null:
return loaded(_that.posts);case ForumError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<ForumPostEntity> posts)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case ForumLoading():
return loading();case ForumLoaded():
return loaded(_that.posts);case ForumError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<ForumPostEntity> posts)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case ForumLoading() when loading != null:
return loading();case ForumLoaded() when loaded != null:
return loaded(_that.posts);case ForumError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ForumLoading with DiagnosticableTreeMixin implements ForumState {
  const ForumLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumState.loading()';
}


}




/// @nodoc


class ForumLoaded with DiagnosticableTreeMixin implements ForumState {
  const ForumLoaded(final  List<ForumPostEntity> posts): _posts = posts;
  

 final  List<ForumPostEntity> _posts;
 List<ForumPostEntity> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}


/// Create a copy of ForumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForumLoadedCopyWith<ForumLoaded> get copyWith => _$ForumLoadedCopyWithImpl<ForumLoaded>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumState.loaded'))
    ..add(DiagnosticsProperty('posts', posts));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumLoaded&&const DeepCollectionEquality().equals(other._posts, _posts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumState.loaded(posts: $posts)';
}


}

/// @nodoc
abstract mixin class $ForumLoadedCopyWith<$Res> implements $ForumStateCopyWith<$Res> {
  factory $ForumLoadedCopyWith(ForumLoaded value, $Res Function(ForumLoaded) _then) = _$ForumLoadedCopyWithImpl;
@useResult
$Res call({
 List<ForumPostEntity> posts
});




}
/// @nodoc
class _$ForumLoadedCopyWithImpl<$Res>
    implements $ForumLoadedCopyWith<$Res> {
  _$ForumLoadedCopyWithImpl(this._self, this._then);

  final ForumLoaded _self;
  final $Res Function(ForumLoaded) _then;

/// Create a copy of ForumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? posts = null,}) {
  return _then(ForumLoaded(
null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<ForumPostEntity>,
  ));
}


}

/// @nodoc


class ForumError with DiagnosticableTreeMixin implements ForumState {
  const ForumError(this.error);
  

 final  String error;

/// Create a copy of ForumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForumErrorCopyWith<ForumError> get copyWith => _$ForumErrorCopyWithImpl<ForumError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumState.errorMessage'))
    ..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $ForumErrorCopyWith<$Res> implements $ForumStateCopyWith<$Res> {
  factory $ForumErrorCopyWith(ForumError value, $Res Function(ForumError) _then) = _$ForumErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$ForumErrorCopyWithImpl<$Res>
    implements $ForumErrorCopyWith<$Res> {
  _$ForumErrorCopyWithImpl(this._self, this._then);

  final ForumError _self;
  final $Res Function(ForumError) _then;

/// Create a copy of ForumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ForumError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
