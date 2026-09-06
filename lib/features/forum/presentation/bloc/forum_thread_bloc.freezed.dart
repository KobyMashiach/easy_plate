// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forum_thread_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForumThreadEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumThreadEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadEvent()';
}


}

/// @nodoc
class $ForumThreadEventCopyWith<$Res>  {
$ForumThreadEventCopyWith(ForumThreadEvent _, $Res Function(ForumThreadEvent) __);
}


/// Adds pattern-matching-related methods to [ForumThreadEvent].
extension ForumThreadEventPatterns on ForumThreadEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _Refresh value)?  refresh,TResult Function( _AddReply value)?  addReply,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Refresh() when refresh != null:
return refresh(_that);case _AddReply() when addReply != null:
return addReply(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _Refresh value)  refresh,required TResult Function( _AddReply value)  addReply,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _Refresh():
return refresh(_that);case _AddReply():
return addReply(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _Refresh value)?  refresh,TResult? Function( _AddReply value)?  addReply,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Refresh() when refresh != null:
return refresh(_that);case _AddReply() when addReply != null:
return addReply(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( Completer<void> done)?  refresh,TResult Function( String body,  String? sharedRecipeId,  String? sharedRecipeTitle)?  addReply,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Refresh() when refresh != null:
return refresh(_that.done);case _AddReply() when addReply != null:
return addReply(_that.body,_that.sharedRecipeId,_that.sharedRecipeTitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( Completer<void> done)  refresh,required TResult Function( String body,  String? sharedRecipeId,  String? sharedRecipeTitle)  addReply,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _Refresh():
return refresh(_that.done);case _AddReply():
return addReply(_that.body,_that.sharedRecipeId,_that.sharedRecipeTitle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( Completer<void> done)?  refresh,TResult? Function( String body,  String? sharedRecipeId,  String? sharedRecipeTitle)?  addReply,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Refresh() when refresh != null:
return refresh(_that.done);case _AddReply() when addReply != null:
return addReply(_that.body,_that.sharedRecipeId,_that.sharedRecipeTitle);case _:
  return null;

}
}

}

/// @nodoc


class _Init with DiagnosticableTreeMixin implements ForumThreadEvent {
  const _Init();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadEvent.init'))
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
  return 'ForumThreadEvent.init()';
}


}




/// @nodoc


class _Refresh with DiagnosticableTreeMixin implements ForumThreadEvent {
  const _Refresh(this.done);
  

 final  Completer<void> done;

/// Create a copy of ForumThreadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshCopyWith<_Refresh> get copyWith => __$RefreshCopyWithImpl<_Refresh>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadEvent.refresh'))
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
  return 'ForumThreadEvent.refresh(done: $done)';
}


}

/// @nodoc
abstract mixin class _$RefreshCopyWith<$Res> implements $ForumThreadEventCopyWith<$Res> {
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

/// Create a copy of ForumThreadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? done = null,}) {
  return _then(_Refresh(
null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as Completer<void>,
  ));
}


}

/// @nodoc


class _AddReply with DiagnosticableTreeMixin implements ForumThreadEvent {
  const _AddReply(this.body, {this.sharedRecipeId, this.sharedRecipeTitle});
  

 final  String body;
 final  String? sharedRecipeId;
 final  String? sharedRecipeTitle;

/// Create a copy of ForumThreadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddReplyCopyWith<_AddReply> get copyWith => __$AddReplyCopyWithImpl<_AddReply>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadEvent.addReply'))
    ..add(DiagnosticsProperty('body', body))..add(DiagnosticsProperty('sharedRecipeId', sharedRecipeId))..add(DiagnosticsProperty('sharedRecipeTitle', sharedRecipeTitle));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddReply&&(identical(other.body, body) || other.body == body)&&(identical(other.sharedRecipeId, sharedRecipeId) || other.sharedRecipeId == sharedRecipeId)&&(identical(other.sharedRecipeTitle, sharedRecipeTitle) || other.sharedRecipeTitle == sharedRecipeTitle));
}


@override
int get hashCode => Object.hash(runtimeType,body,sharedRecipeId,sharedRecipeTitle);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadEvent.addReply(body: $body, sharedRecipeId: $sharedRecipeId, sharedRecipeTitle: $sharedRecipeTitle)';
}


}

/// @nodoc
abstract mixin class _$AddReplyCopyWith<$Res> implements $ForumThreadEventCopyWith<$Res> {
  factory _$AddReplyCopyWith(_AddReply value, $Res Function(_AddReply) _then) = __$AddReplyCopyWithImpl;
@useResult
$Res call({
 String body, String? sharedRecipeId, String? sharedRecipeTitle
});




}
/// @nodoc
class __$AddReplyCopyWithImpl<$Res>
    implements _$AddReplyCopyWith<$Res> {
  __$AddReplyCopyWithImpl(this._self, this._then);

  final _AddReply _self;
  final $Res Function(_AddReply) _then;

/// Create a copy of ForumThreadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? body = null,Object? sharedRecipeId = freezed,Object? sharedRecipeTitle = freezed,}) {
  return _then(_AddReply(
null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sharedRecipeId: freezed == sharedRecipeId ? _self.sharedRecipeId : sharedRecipeId // ignore: cast_nullable_to_non_nullable
as String?,sharedRecipeTitle: freezed == sharedRecipeTitle ? _self.sharedRecipeTitle : sharedRecipeTitle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ForumThreadState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumThreadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadState()';
}


}

/// @nodoc
class $ForumThreadStateCopyWith<$Res>  {
$ForumThreadStateCopyWith(ForumThreadState _, $Res Function(ForumThreadState) __);
}


/// Adds pattern-matching-related methods to [ForumThreadState].
extension ForumThreadStatePatterns on ForumThreadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForumThreadLoading value)?  loading,TResult Function( ForumThreadLoaded value)?  loaded,TResult Function( ForumThreadError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForumThreadLoading() when loading != null:
return loading(_that);case ForumThreadLoaded() when loaded != null:
return loaded(_that);case ForumThreadError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForumThreadLoading value)  loading,required TResult Function( ForumThreadLoaded value)  loaded,required TResult Function( ForumThreadError value)  errorMessage,}){
final _that = this;
switch (_that) {
case ForumThreadLoading():
return loading(_that);case ForumThreadLoaded():
return loaded(_that);case ForumThreadError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForumThreadLoading value)?  loading,TResult? Function( ForumThreadLoaded value)?  loaded,TResult? Function( ForumThreadError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case ForumThreadLoading() when loading != null:
return loading(_that);case ForumThreadLoaded() when loaded != null:
return loaded(_that);case ForumThreadError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<ForumReplyEntity> replies,  bool sending)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForumThreadLoading() when loading != null:
return loading();case ForumThreadLoaded() when loaded != null:
return loaded(_that.replies,_that.sending);case ForumThreadError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<ForumReplyEntity> replies,  bool sending)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case ForumThreadLoading():
return loading();case ForumThreadLoaded():
return loaded(_that.replies,_that.sending);case ForumThreadError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<ForumReplyEntity> replies,  bool sending)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case ForumThreadLoading() when loading != null:
return loading();case ForumThreadLoaded() when loaded != null:
return loaded(_that.replies,_that.sending);case ForumThreadError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ForumThreadLoading with DiagnosticableTreeMixin implements ForumThreadState {
  const ForumThreadLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumThreadLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadState.loading()';
}


}




/// @nodoc


class ForumThreadLoaded with DiagnosticableTreeMixin implements ForumThreadState {
  const ForumThreadLoaded(final  List<ForumReplyEntity> replies, {this.sending = false}): _replies = replies;
  

 final  List<ForumReplyEntity> _replies;
 List<ForumReplyEntity> get replies {
  if (_replies is EqualUnmodifiableListView) return _replies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_replies);
}

@JsonKey() final  bool sending;

/// Create a copy of ForumThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForumThreadLoadedCopyWith<ForumThreadLoaded> get copyWith => _$ForumThreadLoadedCopyWithImpl<ForumThreadLoaded>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadState.loaded'))
    ..add(DiagnosticsProperty('replies', replies))..add(DiagnosticsProperty('sending', sending));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumThreadLoaded&&const DeepCollectionEquality().equals(other._replies, _replies)&&(identical(other.sending, sending) || other.sending == sending));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_replies),sending);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadState.loaded(replies: $replies, sending: $sending)';
}


}

/// @nodoc
abstract mixin class $ForumThreadLoadedCopyWith<$Res> implements $ForumThreadStateCopyWith<$Res> {
  factory $ForumThreadLoadedCopyWith(ForumThreadLoaded value, $Res Function(ForumThreadLoaded) _then) = _$ForumThreadLoadedCopyWithImpl;
@useResult
$Res call({
 List<ForumReplyEntity> replies, bool sending
});




}
/// @nodoc
class _$ForumThreadLoadedCopyWithImpl<$Res>
    implements $ForumThreadLoadedCopyWith<$Res> {
  _$ForumThreadLoadedCopyWithImpl(this._self, this._then);

  final ForumThreadLoaded _self;
  final $Res Function(ForumThreadLoaded) _then;

/// Create a copy of ForumThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? replies = null,Object? sending = null,}) {
  return _then(ForumThreadLoaded(
null == replies ? _self._replies : replies // ignore: cast_nullable_to_non_nullable
as List<ForumReplyEntity>,sending: null == sending ? _self.sending : sending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class ForumThreadError with DiagnosticableTreeMixin implements ForumThreadState {
  const ForumThreadError(this.error);
  

 final  String error;

/// Create a copy of ForumThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForumThreadErrorCopyWith<ForumThreadError> get copyWith => _$ForumThreadErrorCopyWithImpl<ForumThreadError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadState.errorMessage'))
    ..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForumThreadError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $ForumThreadErrorCopyWith<$Res> implements $ForumThreadStateCopyWith<$Res> {
  factory $ForumThreadErrorCopyWith(ForumThreadError value, $Res Function(ForumThreadError) _then) = _$ForumThreadErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$ForumThreadErrorCopyWithImpl<$Res>
    implements $ForumThreadErrorCopyWith<$Res> {
  _$ForumThreadErrorCopyWithImpl(this._self, this._then);

  final ForumThreadError _self;
  final $Res Function(ForumThreadError) _then;

/// Create a copy of ForumThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ForumThreadError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
