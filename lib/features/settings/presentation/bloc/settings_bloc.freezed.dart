// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsEvent()';
}


}

/// @nodoc
class $SettingsEventCopyWith<$Res>  {
$SettingsEventCopyWith(SettingsEvent _, $Res Function(SettingsEvent) __);
}


/// Adds pattern-matching-related methods to [SettingsEvent].
extension SettingsEventPatterns on SettingsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _UpdateShoppingDay value)?  updateShoppingDay,TResult Function( _ToggleDietaryPreference value)?  toggleDietaryPreference,TResult Function( _ToggleSoundEffects value)?  toggleSoundEffects,TResult Function( _ChangeLanguage value)?  changeLanguage,TResult Function( _ToggleFastPageTurn value)?  toggleFastPageTurn,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _UpdateShoppingDay() when updateShoppingDay != null:
return updateShoppingDay(_that);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that);case _ToggleSoundEffects() when toggleSoundEffects != null:
return toggleSoundEffects(_that);case _ChangeLanguage() when changeLanguage != null:
return changeLanguage(_that);case _ToggleFastPageTurn() when toggleFastPageTurn != null:
return toggleFastPageTurn(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _UpdateShoppingDay value)  updateShoppingDay,required TResult Function( _ToggleDietaryPreference value)  toggleDietaryPreference,required TResult Function( _ToggleSoundEffects value)  toggleSoundEffects,required TResult Function( _ChangeLanguage value)  changeLanguage,required TResult Function( _ToggleFastPageTurn value)  toggleFastPageTurn,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _UpdateShoppingDay():
return updateShoppingDay(_that);case _ToggleDietaryPreference():
return toggleDietaryPreference(_that);case _ToggleSoundEffects():
return toggleSoundEffects(_that);case _ChangeLanguage():
return changeLanguage(_that);case _ToggleFastPageTurn():
return toggleFastPageTurn(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _UpdateShoppingDay value)?  updateShoppingDay,TResult? Function( _ToggleDietaryPreference value)?  toggleDietaryPreference,TResult? Function( _ToggleSoundEffects value)?  toggleSoundEffects,TResult? Function( _ChangeLanguage value)?  changeLanguage,TResult? Function( _ToggleFastPageTurn value)?  toggleFastPageTurn,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _UpdateShoppingDay() when updateShoppingDay != null:
return updateShoppingDay(_that);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that);case _ToggleSoundEffects() when toggleSoundEffects != null:
return toggleSoundEffects(_that);case _ChangeLanguage() when changeLanguage != null:
return changeLanguage(_that);case _ToggleFastPageTurn() when toggleFastPageTurn != null:
return toggleFastPageTurn(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( ShoppingDay day)?  updateShoppingDay,TResult Function( DietaryPreference preference)?  toggleDietaryPreference,TResult Function( bool enabled)?  toggleSoundEffects,TResult Function( AppLanguage language)?  changeLanguage,TResult Function( bool enabled)?  toggleFastPageTurn,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _UpdateShoppingDay() when updateShoppingDay != null:
return updateShoppingDay(_that.day);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that.preference);case _ToggleSoundEffects() when toggleSoundEffects != null:
return toggleSoundEffects(_that.enabled);case _ChangeLanguage() when changeLanguage != null:
return changeLanguage(_that.language);case _ToggleFastPageTurn() when toggleFastPageTurn != null:
return toggleFastPageTurn(_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( ShoppingDay day)  updateShoppingDay,required TResult Function( DietaryPreference preference)  toggleDietaryPreference,required TResult Function( bool enabled)  toggleSoundEffects,required TResult Function( AppLanguage language)  changeLanguage,required TResult Function( bool enabled)  toggleFastPageTurn,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _UpdateShoppingDay():
return updateShoppingDay(_that.day);case _ToggleDietaryPreference():
return toggleDietaryPreference(_that.preference);case _ToggleSoundEffects():
return toggleSoundEffects(_that.enabled);case _ChangeLanguage():
return changeLanguage(_that.language);case _ToggleFastPageTurn():
return toggleFastPageTurn(_that.enabled);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( ShoppingDay day)?  updateShoppingDay,TResult? Function( DietaryPreference preference)?  toggleDietaryPreference,TResult? Function( bool enabled)?  toggleSoundEffects,TResult? Function( AppLanguage language)?  changeLanguage,TResult? Function( bool enabled)?  toggleFastPageTurn,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _UpdateShoppingDay() when updateShoppingDay != null:
return updateShoppingDay(_that.day);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that.preference);case _ToggleSoundEffects() when toggleSoundEffects != null:
return toggleSoundEffects(_that.enabled);case _ChangeLanguage() when changeLanguage != null:
return changeLanguage(_that.language);case _ToggleFastPageTurn() when toggleFastPageTurn != null:
return toggleFastPageTurn(_that.enabled);case _:
  return null;

}
}

}

/// @nodoc


class _Init implements SettingsEvent {
  const _Init();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Init);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsEvent.init()';
}


}




/// @nodoc


class _UpdateShoppingDay implements SettingsEvent {
  const _UpdateShoppingDay(this.day);
  

 final  ShoppingDay day;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateShoppingDayCopyWith<_UpdateShoppingDay> get copyWith => __$UpdateShoppingDayCopyWithImpl<_UpdateShoppingDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateShoppingDay&&(identical(other.day, day) || other.day == day));
}


@override
int get hashCode => Object.hash(runtimeType,day);

@override
String toString() {
  return 'SettingsEvent.updateShoppingDay(day: $day)';
}


}

/// @nodoc
abstract mixin class _$UpdateShoppingDayCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$UpdateShoppingDayCopyWith(_UpdateShoppingDay value, $Res Function(_UpdateShoppingDay) _then) = __$UpdateShoppingDayCopyWithImpl;
@useResult
$Res call({
 ShoppingDay day
});




}
/// @nodoc
class __$UpdateShoppingDayCopyWithImpl<$Res>
    implements _$UpdateShoppingDayCopyWith<$Res> {
  __$UpdateShoppingDayCopyWithImpl(this._self, this._then);

  final _UpdateShoppingDay _self;
  final $Res Function(_UpdateShoppingDay) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? day = null,}) {
  return _then(_UpdateShoppingDay(
null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as ShoppingDay,
  ));
}


}

/// @nodoc


class _ToggleDietaryPreference implements SettingsEvent {
  const _ToggleDietaryPreference(this.preference);
  

 final  DietaryPreference preference;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleDietaryPreferenceCopyWith<_ToggleDietaryPreference> get copyWith => __$ToggleDietaryPreferenceCopyWithImpl<_ToggleDietaryPreference>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleDietaryPreference&&(identical(other.preference, preference) || other.preference == preference));
}


@override
int get hashCode => Object.hash(runtimeType,preference);

@override
String toString() {
  return 'SettingsEvent.toggleDietaryPreference(preference: $preference)';
}


}

/// @nodoc
abstract mixin class _$ToggleDietaryPreferenceCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$ToggleDietaryPreferenceCopyWith(_ToggleDietaryPreference value, $Res Function(_ToggleDietaryPreference) _then) = __$ToggleDietaryPreferenceCopyWithImpl;
@useResult
$Res call({
 DietaryPreference preference
});




}
/// @nodoc
class __$ToggleDietaryPreferenceCopyWithImpl<$Res>
    implements _$ToggleDietaryPreferenceCopyWith<$Res> {
  __$ToggleDietaryPreferenceCopyWithImpl(this._self, this._then);

  final _ToggleDietaryPreference _self;
  final $Res Function(_ToggleDietaryPreference) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preference = null,}) {
  return _then(_ToggleDietaryPreference(
null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as DietaryPreference,
  ));
}


}

/// @nodoc


class _ToggleSoundEffects implements SettingsEvent {
  const _ToggleSoundEffects(this.enabled);
  

 final  bool enabled;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleSoundEffectsCopyWith<_ToggleSoundEffects> get copyWith => __$ToggleSoundEffectsCopyWithImpl<_ToggleSoundEffects>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleSoundEffects&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'SettingsEvent.toggleSoundEffects(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ToggleSoundEffectsCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$ToggleSoundEffectsCopyWith(_ToggleSoundEffects value, $Res Function(_ToggleSoundEffects) _then) = __$ToggleSoundEffectsCopyWithImpl;
@useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class __$ToggleSoundEffectsCopyWithImpl<$Res>
    implements _$ToggleSoundEffectsCopyWith<$Res> {
  __$ToggleSoundEffectsCopyWithImpl(this._self, this._then);

  final _ToggleSoundEffects _self;
  final $Res Function(_ToggleSoundEffects) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? enabled = null,}) {
  return _then(_ToggleSoundEffects(
null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _ChangeLanguage implements SettingsEvent {
  const _ChangeLanguage(this.language);
  

 final  AppLanguage language;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeLanguageCopyWith<_ChangeLanguage> get copyWith => __$ChangeLanguageCopyWithImpl<_ChangeLanguage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangeLanguage&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode => Object.hash(runtimeType,language);

@override
String toString() {
  return 'SettingsEvent.changeLanguage(language: $language)';
}


}

/// @nodoc
abstract mixin class _$ChangeLanguageCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$ChangeLanguageCopyWith(_ChangeLanguage value, $Res Function(_ChangeLanguage) _then) = __$ChangeLanguageCopyWithImpl;
@useResult
$Res call({
 AppLanguage language
});




}
/// @nodoc
class __$ChangeLanguageCopyWithImpl<$Res>
    implements _$ChangeLanguageCopyWith<$Res> {
  __$ChangeLanguageCopyWithImpl(this._self, this._then);

  final _ChangeLanguage _self;
  final $Res Function(_ChangeLanguage) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? language = null,}) {
  return _then(_ChangeLanguage(
null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,
  ));
}


}

/// @nodoc


class _ToggleFastPageTurn implements SettingsEvent {
  const _ToggleFastPageTurn(this.enabled);
  

 final  bool enabled;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleFastPageTurnCopyWith<_ToggleFastPageTurn> get copyWith => __$ToggleFastPageTurnCopyWithImpl<_ToggleFastPageTurn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleFastPageTurn&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'SettingsEvent.toggleFastPageTurn(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$ToggleFastPageTurnCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory _$ToggleFastPageTurnCopyWith(_ToggleFastPageTurn value, $Res Function(_ToggleFastPageTurn) _then) = __$ToggleFastPageTurnCopyWithImpl;
@useResult
$Res call({
 bool enabled
});




}
/// @nodoc
class __$ToggleFastPageTurnCopyWithImpl<$Res>
    implements _$ToggleFastPageTurnCopyWith<$Res> {
  __$ToggleFastPageTurnCopyWithImpl(this._self, this._then);

  final _ToggleFastPageTurn _self;
  final $Res Function(_ToggleFastPageTurn) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? enabled = null,}) {
  return _then(_ToggleFastPageTurn(
null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState()';
}


}

/// @nodoc
class $SettingsStateCopyWith<$Res>  {
$SettingsStateCopyWith(SettingsState _, $Res Function(SettingsState) __);
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsLoading value)?  loading,TResult Function( SettingsLoaded value)?  loaded,TResult Function( SettingsError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading(_that);case SettingsLoaded() when loaded != null:
return loaded(_that);case SettingsError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsLoading value)  loading,required TResult Function( SettingsLoaded value)  loaded,required TResult Function( SettingsError value)  errorMessage,}){
final _that = this;
switch (_that) {
case SettingsLoading():
return loading(_that);case SettingsLoaded():
return loaded(_that);case SettingsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsLoading value)?  loading,TResult? Function( SettingsLoaded value)?  loaded,TResult? Function( SettingsError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading(_that);case SettingsLoaded() when loaded != null:
return loaded(_that);case SettingsError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( UserPreferencesEntity preferences,  int sharedBooksCount,  int sharedListsCount)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading();case SettingsLoaded() when loaded != null:
return loaded(_that.preferences,_that.sharedBooksCount,_that.sharedListsCount);case SettingsError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( UserPreferencesEntity preferences,  int sharedBooksCount,  int sharedListsCount)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case SettingsLoading():
return loading();case SettingsLoaded():
return loaded(_that.preferences,_that.sharedBooksCount,_that.sharedListsCount);case SettingsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( UserPreferencesEntity preferences,  int sharedBooksCount,  int sharedListsCount)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading();case SettingsLoaded() when loaded != null:
return loaded(_that.preferences,_that.sharedBooksCount,_that.sharedListsCount);case SettingsError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class SettingsLoading implements SettingsState {
  const SettingsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState.loading()';
}


}




/// @nodoc


class SettingsLoaded implements SettingsState {
  const SettingsLoaded(this.preferences, {this.sharedBooksCount = 0, this.sharedListsCount = 0});
  

 final  UserPreferencesEntity preferences;
@JsonKey() final  int sharedBooksCount;
@JsonKey() final  int sharedListsCount;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsLoadedCopyWith<SettingsLoaded> get copyWith => _$SettingsLoadedCopyWithImpl<SettingsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoaded&&(identical(other.preferences, preferences) || other.preferences == preferences)&&(identical(other.sharedBooksCount, sharedBooksCount) || other.sharedBooksCount == sharedBooksCount)&&(identical(other.sharedListsCount, sharedListsCount) || other.sharedListsCount == sharedListsCount));
}


@override
int get hashCode => Object.hash(runtimeType,preferences,sharedBooksCount,sharedListsCount);

@override
String toString() {
  return 'SettingsState.loaded(preferences: $preferences, sharedBooksCount: $sharedBooksCount, sharedListsCount: $sharedListsCount)';
}


}

/// @nodoc
abstract mixin class $SettingsLoadedCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsLoadedCopyWith(SettingsLoaded value, $Res Function(SettingsLoaded) _then) = _$SettingsLoadedCopyWithImpl;
@useResult
$Res call({
 UserPreferencesEntity preferences, int sharedBooksCount, int sharedListsCount
});




}
/// @nodoc
class _$SettingsLoadedCopyWithImpl<$Res>
    implements $SettingsLoadedCopyWith<$Res> {
  _$SettingsLoadedCopyWithImpl(this._self, this._then);

  final SettingsLoaded _self;
  final $Res Function(SettingsLoaded) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preferences = null,Object? sharedBooksCount = null,Object? sharedListsCount = null,}) {
  return _then(SettingsLoaded(
null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as UserPreferencesEntity,sharedBooksCount: null == sharedBooksCount ? _self.sharedBooksCount : sharedBooksCount // ignore: cast_nullable_to_non_nullable
as int,sharedListsCount: null == sharedListsCount ? _self.sharedListsCount : sharedListsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SettingsError implements SettingsState {
  const SettingsError(this.error);
  

 final  String error;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsErrorCopyWith<SettingsError> get copyWith => _$SettingsErrorCopyWithImpl<SettingsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'SettingsState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $SettingsErrorCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsErrorCopyWith(SettingsError value, $Res Function(SettingsError) _then) = _$SettingsErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$SettingsErrorCopyWithImpl<$Res>
    implements $SettingsErrorCopyWith<$Res> {
  _$SettingsErrorCopyWithImpl(this._self, this._then);

  final SettingsError _self;
  final $Res Function(SettingsError) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(SettingsError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
