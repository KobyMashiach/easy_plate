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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _AddReply value)?  addReply,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _AddReply() when addReply != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _AddReply value)  addReply,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _AddReply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _AddReply value)?  addReply,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _AddReply() when addReply != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( String body)?  addReply,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _AddReply() when addReply != null:
return addReply(_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( String body)  addReply,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _AddReply():
return addReply(_that.body);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( String body)?  addReply,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _AddReply() when addReply != null:
return addReply(_that.body);case _:
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


class _AddReply with DiagnosticableTreeMixin implements ForumThreadEvent {
  const _AddReply(this.body);
  

 final  String body;

/// Create a copy of ForumThreadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddReplyCopyWith<_AddReply> get copyWith => __$AddReplyCopyWithImpl<_AddReply>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ForumThreadEvent.addReply'))
    ..add(DiagnosticsProperty('body', body));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddReply&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,body);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ForumThreadEvent.addReply(body: $body)';
}


}

/// @nodoc
abstract mixin class _$AddReplyCopyWith<$Res> implements $ForumThreadEventCopyWith<$Res> {
  factory _$AddReplyCopyWith(_AddReply value, $Res Function(_AddReply) _then) = __$AddReplyCopyWithImpl;
@useResult
$Res call({
 String body
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
@pragma('vm:prefer-inline') $Res call({Object? body = null,}) {
  return _then(_AddReply(
null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
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
