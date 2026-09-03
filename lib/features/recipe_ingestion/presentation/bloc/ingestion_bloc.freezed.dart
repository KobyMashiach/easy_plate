// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingestion_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IngestionEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent()';
}


}

/// @nodoc
class $IngestionEventCopyWith<$Res>  {
$IngestionEventCopyWith(IngestionEvent _, $Res Function(IngestionEvent) __);
}


/// Adds pattern-matching-related methods to [IngestionEvent].
extension IngestionEventPatterns on IngestionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SelectChannel value)?  selectChannel,TResult Function( _ParseRawText value)?  parseRawText,TResult Function( _SearchWeb value)?  searchWeb,TResult Function( _ParseUrl value)?  parseUrl,TResult Function( _ParseSocialVideo value)?  parseSocialVideo,TResult Function( _UpdateRecipe value)?  updateRecipe,TResult Function( _SaveRecipe value)?  saveRecipe,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectChannel() when selectChannel != null:
return selectChannel(_that);case _ParseRawText() when parseRawText != null:
return parseRawText(_that);case _SearchWeb() when searchWeb != null:
return searchWeb(_that);case _ParseUrl() when parseUrl != null:
return parseUrl(_that);case _ParseSocialVideo() when parseSocialVideo != null:
return parseSocialVideo(_that);case _UpdateRecipe() when updateRecipe != null:
return updateRecipe(_that);case _SaveRecipe() when saveRecipe != null:
return saveRecipe(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SelectChannel value)  selectChannel,required TResult Function( _ParseRawText value)  parseRawText,required TResult Function( _SearchWeb value)  searchWeb,required TResult Function( _ParseUrl value)  parseUrl,required TResult Function( _ParseSocialVideo value)  parseSocialVideo,required TResult Function( _UpdateRecipe value)  updateRecipe,required TResult Function( _SaveRecipe value)  saveRecipe,}){
final _that = this;
switch (_that) {
case _SelectChannel():
return selectChannel(_that);case _ParseRawText():
return parseRawText(_that);case _SearchWeb():
return searchWeb(_that);case _ParseUrl():
return parseUrl(_that);case _ParseSocialVideo():
return parseSocialVideo(_that);case _UpdateRecipe():
return updateRecipe(_that);case _SaveRecipe():
return saveRecipe(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SelectChannel value)?  selectChannel,TResult? Function( _ParseRawText value)?  parseRawText,TResult? Function( _SearchWeb value)?  searchWeb,TResult? Function( _ParseUrl value)?  parseUrl,TResult? Function( _ParseSocialVideo value)?  parseSocialVideo,TResult? Function( _UpdateRecipe value)?  updateRecipe,TResult? Function( _SaveRecipe value)?  saveRecipe,}){
final _that = this;
switch (_that) {
case _SelectChannel() when selectChannel != null:
return selectChannel(_that);case _ParseRawText() when parseRawText != null:
return parseRawText(_that);case _SearchWeb() when searchWeb != null:
return searchWeb(_that);case _ParseUrl() when parseUrl != null:
return parseUrl(_that);case _ParseSocialVideo() when parseSocialVideo != null:
return parseSocialVideo(_that);case _UpdateRecipe() when updateRecipe != null:
return updateRecipe(_that);case _SaveRecipe() when saveRecipe != null:
return saveRecipe(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RecipeIngestionChannel channel)?  selectChannel,TResult Function( String text)?  parseRawText,TResult Function( String query)?  searchWeb,TResult Function( String url)?  parseUrl,TResult Function( String url)?  parseSocialVideo,TResult Function( RecipeEntity recipe)?  updateRecipe,TResult Function( RecipeEntity recipe)?  saveRecipe,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectChannel() when selectChannel != null:
return selectChannel(_that.channel);case _ParseRawText() when parseRawText != null:
return parseRawText(_that.text);case _SearchWeb() when searchWeb != null:
return searchWeb(_that.query);case _ParseUrl() when parseUrl != null:
return parseUrl(_that.url);case _ParseSocialVideo() when parseSocialVideo != null:
return parseSocialVideo(_that.url);case _UpdateRecipe() when updateRecipe != null:
return updateRecipe(_that.recipe);case _SaveRecipe() when saveRecipe != null:
return saveRecipe(_that.recipe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RecipeIngestionChannel channel)  selectChannel,required TResult Function( String text)  parseRawText,required TResult Function( String query)  searchWeb,required TResult Function( String url)  parseUrl,required TResult Function( String url)  parseSocialVideo,required TResult Function( RecipeEntity recipe)  updateRecipe,required TResult Function( RecipeEntity recipe)  saveRecipe,}) {final _that = this;
switch (_that) {
case _SelectChannel():
return selectChannel(_that.channel);case _ParseRawText():
return parseRawText(_that.text);case _SearchWeb():
return searchWeb(_that.query);case _ParseUrl():
return parseUrl(_that.url);case _ParseSocialVideo():
return parseSocialVideo(_that.url);case _UpdateRecipe():
return updateRecipe(_that.recipe);case _SaveRecipe():
return saveRecipe(_that.recipe);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RecipeIngestionChannel channel)?  selectChannel,TResult? Function( String text)?  parseRawText,TResult? Function( String query)?  searchWeb,TResult? Function( String url)?  parseUrl,TResult? Function( String url)?  parseSocialVideo,TResult? Function( RecipeEntity recipe)?  updateRecipe,TResult? Function( RecipeEntity recipe)?  saveRecipe,}) {final _that = this;
switch (_that) {
case _SelectChannel() when selectChannel != null:
return selectChannel(_that.channel);case _ParseRawText() when parseRawText != null:
return parseRawText(_that.text);case _SearchWeb() when searchWeb != null:
return searchWeb(_that.query);case _ParseUrl() when parseUrl != null:
return parseUrl(_that.url);case _ParseSocialVideo() when parseSocialVideo != null:
return parseSocialVideo(_that.url);case _UpdateRecipe() when updateRecipe != null:
return updateRecipe(_that.recipe);case _SaveRecipe() when saveRecipe != null:
return saveRecipe(_that.recipe);case _:
  return null;

}
}

}

/// @nodoc


class _SelectChannel with DiagnosticableTreeMixin implements IngestionEvent {
  const _SelectChannel(this.channel);
  

 final  RecipeIngestionChannel channel;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectChannelCopyWith<_SelectChannel> get copyWith => __$SelectChannelCopyWithImpl<_SelectChannel>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.selectChannel'))
    ..add(DiagnosticsProperty('channel', channel));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectChannel&&(identical(other.channel, channel) || other.channel == channel));
}


@override
int get hashCode => Object.hash(runtimeType,channel);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.selectChannel(channel: $channel)';
}


}

/// @nodoc
abstract mixin class _$SelectChannelCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$SelectChannelCopyWith(_SelectChannel value, $Res Function(_SelectChannel) _then) = __$SelectChannelCopyWithImpl;
@useResult
$Res call({
 RecipeIngestionChannel channel
});




}
/// @nodoc
class __$SelectChannelCopyWithImpl<$Res>
    implements _$SelectChannelCopyWith<$Res> {
  __$SelectChannelCopyWithImpl(this._self, this._then);

  final _SelectChannel _self;
  final $Res Function(_SelectChannel) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? channel = null,}) {
  return _then(_SelectChannel(
null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as RecipeIngestionChannel,
  ));
}


}

/// @nodoc


class _ParseRawText with DiagnosticableTreeMixin implements IngestionEvent {
  const _ParseRawText(this.text);
  

 final  String text;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParseRawTextCopyWith<_ParseRawText> get copyWith => __$ParseRawTextCopyWithImpl<_ParseRawText>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.parseRawText'))
    ..add(DiagnosticsProperty('text', text));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParseRawText&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.parseRawText(text: $text)';
}


}

/// @nodoc
abstract mixin class _$ParseRawTextCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$ParseRawTextCopyWith(_ParseRawText value, $Res Function(_ParseRawText) _then) = __$ParseRawTextCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class __$ParseRawTextCopyWithImpl<$Res>
    implements _$ParseRawTextCopyWith<$Res> {
  __$ParseRawTextCopyWithImpl(this._self, this._then);

  final _ParseRawText _self;
  final $Res Function(_ParseRawText) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_ParseRawText(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SearchWeb with DiagnosticableTreeMixin implements IngestionEvent {
  const _SearchWeb(this.query);
  

 final  String query;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchWebCopyWith<_SearchWeb> get copyWith => __$SearchWebCopyWithImpl<_SearchWeb>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.searchWeb'))
    ..add(DiagnosticsProperty('query', query));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchWeb&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.searchWeb(query: $query)';
}


}

/// @nodoc
abstract mixin class _$SearchWebCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$SearchWebCopyWith(_SearchWeb value, $Res Function(_SearchWeb) _then) = __$SearchWebCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class __$SearchWebCopyWithImpl<$Res>
    implements _$SearchWebCopyWith<$Res> {
  __$SearchWebCopyWithImpl(this._self, this._then);

  final _SearchWeb _self;
  final $Res Function(_SearchWeb) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(_SearchWeb(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ParseUrl with DiagnosticableTreeMixin implements IngestionEvent {
  const _ParseUrl(this.url);
  

 final  String url;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParseUrlCopyWith<_ParseUrl> get copyWith => __$ParseUrlCopyWithImpl<_ParseUrl>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.parseUrl'))
    ..add(DiagnosticsProperty('url', url));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParseUrl&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,url);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.parseUrl(url: $url)';
}


}

/// @nodoc
abstract mixin class _$ParseUrlCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$ParseUrlCopyWith(_ParseUrl value, $Res Function(_ParseUrl) _then) = __$ParseUrlCopyWithImpl;
@useResult
$Res call({
 String url
});




}
/// @nodoc
class __$ParseUrlCopyWithImpl<$Res>
    implements _$ParseUrlCopyWith<$Res> {
  __$ParseUrlCopyWithImpl(this._self, this._then);

  final _ParseUrl _self;
  final $Res Function(_ParseUrl) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,}) {
  return _then(_ParseUrl(
null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ParseSocialVideo with DiagnosticableTreeMixin implements IngestionEvent {
  const _ParseSocialVideo(this.url);
  

 final  String url;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParseSocialVideoCopyWith<_ParseSocialVideo> get copyWith => __$ParseSocialVideoCopyWithImpl<_ParseSocialVideo>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.parseSocialVideo'))
    ..add(DiagnosticsProperty('url', url));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParseSocialVideo&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,url);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.parseSocialVideo(url: $url)';
}


}

/// @nodoc
abstract mixin class _$ParseSocialVideoCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$ParseSocialVideoCopyWith(_ParseSocialVideo value, $Res Function(_ParseSocialVideo) _then) = __$ParseSocialVideoCopyWithImpl;
@useResult
$Res call({
 String url
});




}
/// @nodoc
class __$ParseSocialVideoCopyWithImpl<$Res>
    implements _$ParseSocialVideoCopyWith<$Res> {
  __$ParseSocialVideoCopyWithImpl(this._self, this._then);

  final _ParseSocialVideo _self;
  final $Res Function(_ParseSocialVideo) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,}) {
  return _then(_ParseSocialVideo(
null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UpdateRecipe with DiagnosticableTreeMixin implements IngestionEvent {
  const _UpdateRecipe(this.recipe);
  

 final  RecipeEntity recipe;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateRecipeCopyWith<_UpdateRecipe> get copyWith => __$UpdateRecipeCopyWithImpl<_UpdateRecipe>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.updateRecipe'))
    ..add(DiagnosticsProperty('recipe', recipe));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateRecipe&&(identical(other.recipe, recipe) || other.recipe == recipe));
}


@override
int get hashCode => Object.hash(runtimeType,recipe);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.updateRecipe(recipe: $recipe)';
}


}

/// @nodoc
abstract mixin class _$UpdateRecipeCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$UpdateRecipeCopyWith(_UpdateRecipe value, $Res Function(_UpdateRecipe) _then) = __$UpdateRecipeCopyWithImpl;
@useResult
$Res call({
 RecipeEntity recipe
});




}
/// @nodoc
class __$UpdateRecipeCopyWithImpl<$Res>
    implements _$UpdateRecipeCopyWith<$Res> {
  __$UpdateRecipeCopyWithImpl(this._self, this._then);

  final _UpdateRecipe _self;
  final $Res Function(_UpdateRecipe) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipe = null,}) {
  return _then(_UpdateRecipe(
null == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as RecipeEntity,
  ));
}


}

/// @nodoc


class _SaveRecipe with DiagnosticableTreeMixin implements IngestionEvent {
  const _SaveRecipe(this.recipe);
  

 final  RecipeEntity recipe;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveRecipeCopyWith<_SaveRecipe> get copyWith => __$SaveRecipeCopyWithImpl<_SaveRecipe>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionEvent.saveRecipe'))
    ..add(DiagnosticsProperty('recipe', recipe));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveRecipe&&(identical(other.recipe, recipe) || other.recipe == recipe));
}


@override
int get hashCode => Object.hash(runtimeType,recipe);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionEvent.saveRecipe(recipe: $recipe)';
}


}

/// @nodoc
abstract mixin class _$SaveRecipeCopyWith<$Res> implements $IngestionEventCopyWith<$Res> {
  factory _$SaveRecipeCopyWith(_SaveRecipe value, $Res Function(_SaveRecipe) _then) = __$SaveRecipeCopyWithImpl;
@useResult
$Res call({
 RecipeEntity recipe
});




}
/// @nodoc
class __$SaveRecipeCopyWithImpl<$Res>
    implements _$SaveRecipeCopyWith<$Res> {
  __$SaveRecipeCopyWithImpl(this._self, this._then);

  final _SaveRecipe _self;
  final $Res Function(_SaveRecipe) _then;

/// Create a copy of IngestionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipe = null,}) {
  return _then(_SaveRecipe(
null == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as RecipeEntity,
  ));
}


}

/// @nodoc
mixin _$IngestionState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState()';
}


}

/// @nodoc
class $IngestionStateCopyWith<$Res>  {
$IngestionStateCopyWith(IngestionState _, $Res Function(IngestionState) __);
}


/// Adds pattern-matching-related methods to [IngestionState].
extension IngestionStatePatterns on IngestionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IngestionIdle value)?  idle,TResult Function( IngestionParsing value)?  parsing,TResult Function( IngestionSearchResults value)?  searchResults,TResult Function( IngestionReview value)?  review,TResult Function( IngestionSaved value)?  saved,TResult Function( IngestionError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IngestionIdle() when idle != null:
return idle(_that);case IngestionParsing() when parsing != null:
return parsing(_that);case IngestionSearchResults() when searchResults != null:
return searchResults(_that);case IngestionReview() when review != null:
return review(_that);case IngestionSaved() when saved != null:
return saved(_that);case IngestionError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IngestionIdle value)  idle,required TResult Function( IngestionParsing value)  parsing,required TResult Function( IngestionSearchResults value)  searchResults,required TResult Function( IngestionReview value)  review,required TResult Function( IngestionSaved value)  saved,required TResult Function( IngestionError value)  errorMessage,}){
final _that = this;
switch (_that) {
case IngestionIdle():
return idle(_that);case IngestionParsing():
return parsing(_that);case IngestionSearchResults():
return searchResults(_that);case IngestionReview():
return review(_that);case IngestionSaved():
return saved(_that);case IngestionError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IngestionIdle value)?  idle,TResult? Function( IngestionParsing value)?  parsing,TResult? Function( IngestionSearchResults value)?  searchResults,TResult? Function( IngestionReview value)?  review,TResult? Function( IngestionSaved value)?  saved,TResult? Function( IngestionError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case IngestionIdle() when idle != null:
return idle(_that);case IngestionParsing() when parsing != null:
return parsing(_that);case IngestionSearchResults() when searchResults != null:
return searchResults(_that);case IngestionReview() when review != null:
return review(_that);case IngestionSaved() when saved != null:
return saved(_that);case IngestionError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( RecipeIngestionChannel channel)?  idle,TResult Function( RecipeIngestionChannel channel)?  parsing,TResult Function( RecipeIngestionChannel channel,  List<WebSearchResultEntity> results)?  searchResults,TResult Function( RecipeIngestionChannel channel,  RecipeEntity recipe)?  review,TResult Function()?  saved,TResult Function( RecipeIngestionChannel channel,  String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IngestionIdle() when idle != null:
return idle(_that.channel);case IngestionParsing() when parsing != null:
return parsing(_that.channel);case IngestionSearchResults() when searchResults != null:
return searchResults(_that.channel,_that.results);case IngestionReview() when review != null:
return review(_that.channel,_that.recipe);case IngestionSaved() when saved != null:
return saved();case IngestionError() when errorMessage != null:
return errorMessage(_that.channel,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( RecipeIngestionChannel channel)  idle,required TResult Function( RecipeIngestionChannel channel)  parsing,required TResult Function( RecipeIngestionChannel channel,  List<WebSearchResultEntity> results)  searchResults,required TResult Function( RecipeIngestionChannel channel,  RecipeEntity recipe)  review,required TResult Function()  saved,required TResult Function( RecipeIngestionChannel channel,  String error)  errorMessage,}) {final _that = this;
switch (_that) {
case IngestionIdle():
return idle(_that.channel);case IngestionParsing():
return parsing(_that.channel);case IngestionSearchResults():
return searchResults(_that.channel,_that.results);case IngestionReview():
return review(_that.channel,_that.recipe);case IngestionSaved():
return saved();case IngestionError():
return errorMessage(_that.channel,_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( RecipeIngestionChannel channel)?  idle,TResult? Function( RecipeIngestionChannel channel)?  parsing,TResult? Function( RecipeIngestionChannel channel,  List<WebSearchResultEntity> results)?  searchResults,TResult? Function( RecipeIngestionChannel channel,  RecipeEntity recipe)?  review,TResult? Function()?  saved,TResult? Function( RecipeIngestionChannel channel,  String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case IngestionIdle() when idle != null:
return idle(_that.channel);case IngestionParsing() when parsing != null:
return parsing(_that.channel);case IngestionSearchResults() when searchResults != null:
return searchResults(_that.channel,_that.results);case IngestionReview() when review != null:
return review(_that.channel,_that.recipe);case IngestionSaved() when saved != null:
return saved();case IngestionError() when errorMessage != null:
return errorMessage(_that.channel,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class IngestionIdle with DiagnosticableTreeMixin implements IngestionState {
  const IngestionIdle(this.channel);
  

 final  RecipeIngestionChannel channel;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngestionIdleCopyWith<IngestionIdle> get copyWith => _$IngestionIdleCopyWithImpl<IngestionIdle>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState.idle'))
    ..add(DiagnosticsProperty('channel', channel));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionIdle&&(identical(other.channel, channel) || other.channel == channel));
}


@override
int get hashCode => Object.hash(runtimeType,channel);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState.idle(channel: $channel)';
}


}

/// @nodoc
abstract mixin class $IngestionIdleCopyWith<$Res> implements $IngestionStateCopyWith<$Res> {
  factory $IngestionIdleCopyWith(IngestionIdle value, $Res Function(IngestionIdle) _then) = _$IngestionIdleCopyWithImpl;
@useResult
$Res call({
 RecipeIngestionChannel channel
});




}
/// @nodoc
class _$IngestionIdleCopyWithImpl<$Res>
    implements $IngestionIdleCopyWith<$Res> {
  _$IngestionIdleCopyWithImpl(this._self, this._then);

  final IngestionIdle _self;
  final $Res Function(IngestionIdle) _then;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? channel = null,}) {
  return _then(IngestionIdle(
null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as RecipeIngestionChannel,
  ));
}


}

/// @nodoc


class IngestionParsing with DiagnosticableTreeMixin implements IngestionState {
  const IngestionParsing(this.channel);
  

 final  RecipeIngestionChannel channel;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngestionParsingCopyWith<IngestionParsing> get copyWith => _$IngestionParsingCopyWithImpl<IngestionParsing>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState.parsing'))
    ..add(DiagnosticsProperty('channel', channel));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionParsing&&(identical(other.channel, channel) || other.channel == channel));
}


@override
int get hashCode => Object.hash(runtimeType,channel);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState.parsing(channel: $channel)';
}


}

/// @nodoc
abstract mixin class $IngestionParsingCopyWith<$Res> implements $IngestionStateCopyWith<$Res> {
  factory $IngestionParsingCopyWith(IngestionParsing value, $Res Function(IngestionParsing) _then) = _$IngestionParsingCopyWithImpl;
@useResult
$Res call({
 RecipeIngestionChannel channel
});




}
/// @nodoc
class _$IngestionParsingCopyWithImpl<$Res>
    implements $IngestionParsingCopyWith<$Res> {
  _$IngestionParsingCopyWithImpl(this._self, this._then);

  final IngestionParsing _self;
  final $Res Function(IngestionParsing) _then;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? channel = null,}) {
  return _then(IngestionParsing(
null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as RecipeIngestionChannel,
  ));
}


}

/// @nodoc


class IngestionSearchResults with DiagnosticableTreeMixin implements IngestionState {
  const IngestionSearchResults(this.channel, final  List<WebSearchResultEntity> results): _results = results;
  

 final  RecipeIngestionChannel channel;
 final  List<WebSearchResultEntity> _results;
 List<WebSearchResultEntity> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngestionSearchResultsCopyWith<IngestionSearchResults> get copyWith => _$IngestionSearchResultsCopyWithImpl<IngestionSearchResults>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState.searchResults'))
    ..add(DiagnosticsProperty('channel', channel))..add(DiagnosticsProperty('results', results));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionSearchResults&&(identical(other.channel, channel) || other.channel == channel)&&const DeepCollectionEquality().equals(other._results, _results));
}


@override
int get hashCode => Object.hash(runtimeType,channel,const DeepCollectionEquality().hash(_results));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState.searchResults(channel: $channel, results: $results)';
}


}

/// @nodoc
abstract mixin class $IngestionSearchResultsCopyWith<$Res> implements $IngestionStateCopyWith<$Res> {
  factory $IngestionSearchResultsCopyWith(IngestionSearchResults value, $Res Function(IngestionSearchResults) _then) = _$IngestionSearchResultsCopyWithImpl;
@useResult
$Res call({
 RecipeIngestionChannel channel, List<WebSearchResultEntity> results
});




}
/// @nodoc
class _$IngestionSearchResultsCopyWithImpl<$Res>
    implements $IngestionSearchResultsCopyWith<$Res> {
  _$IngestionSearchResultsCopyWithImpl(this._self, this._then);

  final IngestionSearchResults _self;
  final $Res Function(IngestionSearchResults) _then;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? results = null,}) {
  return _then(IngestionSearchResults(
null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as RecipeIngestionChannel,null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<WebSearchResultEntity>,
  ));
}


}

/// @nodoc


class IngestionReview with DiagnosticableTreeMixin implements IngestionState {
  const IngestionReview(this.channel, this.recipe);
  

 final  RecipeIngestionChannel channel;
 final  RecipeEntity recipe;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngestionReviewCopyWith<IngestionReview> get copyWith => _$IngestionReviewCopyWithImpl<IngestionReview>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState.review'))
    ..add(DiagnosticsProperty('channel', channel))..add(DiagnosticsProperty('recipe', recipe));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionReview&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.recipe, recipe) || other.recipe == recipe));
}


@override
int get hashCode => Object.hash(runtimeType,channel,recipe);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState.review(channel: $channel, recipe: $recipe)';
}


}

/// @nodoc
abstract mixin class $IngestionReviewCopyWith<$Res> implements $IngestionStateCopyWith<$Res> {
  factory $IngestionReviewCopyWith(IngestionReview value, $Res Function(IngestionReview) _then) = _$IngestionReviewCopyWithImpl;
@useResult
$Res call({
 RecipeIngestionChannel channel, RecipeEntity recipe
});




}
/// @nodoc
class _$IngestionReviewCopyWithImpl<$Res>
    implements $IngestionReviewCopyWith<$Res> {
  _$IngestionReviewCopyWithImpl(this._self, this._then);

  final IngestionReview _self;
  final $Res Function(IngestionReview) _then;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? recipe = null,}) {
  return _then(IngestionReview(
null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as RecipeIngestionChannel,null == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as RecipeEntity,
  ));
}


}

/// @nodoc


class IngestionSaved with DiagnosticableTreeMixin implements IngestionState {
  const IngestionSaved();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState.saved'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionSaved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState.saved()';
}


}




/// @nodoc


class IngestionError with DiagnosticableTreeMixin implements IngestionState {
  const IngestionError(this.channel, this.error);
  

 final  RecipeIngestionChannel channel;
 final  String error;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IngestionErrorCopyWith<IngestionError> get copyWith => _$IngestionErrorCopyWithImpl<IngestionError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'IngestionState.errorMessage'))
    ..add(DiagnosticsProperty('channel', channel))..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IngestionError&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,channel,error);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'IngestionState.errorMessage(channel: $channel, error: $error)';
}


}

/// @nodoc
abstract mixin class $IngestionErrorCopyWith<$Res> implements $IngestionStateCopyWith<$Res> {
  factory $IngestionErrorCopyWith(IngestionError value, $Res Function(IngestionError) _then) = _$IngestionErrorCopyWithImpl;
@useResult
$Res call({
 RecipeIngestionChannel channel, String error
});




}
/// @nodoc
class _$IngestionErrorCopyWithImpl<$Res>
    implements $IngestionErrorCopyWith<$Res> {
  _$IngestionErrorCopyWithImpl(this._self, this._then);

  final IngestionError _self;
  final $Res Function(IngestionError) _then;

/// Create a copy of IngestionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? error = null,}) {
  return _then(IngestionError(
null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as RecipeIngestionChannel,null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
