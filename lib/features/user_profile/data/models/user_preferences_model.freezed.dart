// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPreferencesModel {

@HiveField(0) ShoppingDay get shoppingDay;@HiveField(1) List<DietaryPreference> get dietaryPreferences;@HiveField(2) bool get soundEffectsEnabled;@HiveField(3) bool get onboardingComplete;
/// Create a copy of UserPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPreferencesModelCopyWith<UserPreferencesModel> get copyWith => _$UserPreferencesModelCopyWithImpl<UserPreferencesModel>(this as UserPreferencesModel, _$identity);

  /// Serializes this UserPreferencesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferencesModel&&(identical(other.shoppingDay, shoppingDay) || other.shoppingDay == shoppingDay)&&const DeepCollectionEquality().equals(other.dietaryPreferences, dietaryPreferences)&&(identical(other.soundEffectsEnabled, soundEffectsEnabled) || other.soundEffectsEnabled == soundEffectsEnabled)&&(identical(other.onboardingComplete, onboardingComplete) || other.onboardingComplete == onboardingComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shoppingDay,const DeepCollectionEquality().hash(dietaryPreferences),soundEffectsEnabled,onboardingComplete);

@override
String toString() {
  return 'UserPreferencesModel(shoppingDay: $shoppingDay, dietaryPreferences: $dietaryPreferences, soundEffectsEnabled: $soundEffectsEnabled, onboardingComplete: $onboardingComplete)';
}


}

/// @nodoc
abstract mixin class $UserPreferencesModelCopyWith<$Res>  {
  factory $UserPreferencesModelCopyWith(UserPreferencesModel value, $Res Function(UserPreferencesModel) _then) = _$UserPreferencesModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) ShoppingDay shoppingDay,@HiveField(1) List<DietaryPreference> dietaryPreferences,@HiveField(2) bool soundEffectsEnabled,@HiveField(3) bool onboardingComplete
});




}
/// @nodoc
class _$UserPreferencesModelCopyWithImpl<$Res>
    implements $UserPreferencesModelCopyWith<$Res> {
  _$UserPreferencesModelCopyWithImpl(this._self, this._then);

  final UserPreferencesModel _self;
  final $Res Function(UserPreferencesModel) _then;

/// Create a copy of UserPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shoppingDay = null,Object? dietaryPreferences = null,Object? soundEffectsEnabled = null,Object? onboardingComplete = null,}) {
  return _then(_self.copyWith(
shoppingDay: null == shoppingDay ? _self.shoppingDay : shoppingDay // ignore: cast_nullable_to_non_nullable
as ShoppingDay,dietaryPreferences: null == dietaryPreferences ? _self.dietaryPreferences : dietaryPreferences // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,soundEffectsEnabled: null == soundEffectsEnabled ? _self.soundEffectsEnabled : soundEffectsEnabled // ignore: cast_nullable_to_non_nullable
as bool,onboardingComplete: null == onboardingComplete ? _self.onboardingComplete : onboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPreferencesModel].
extension UserPreferencesModelPatterns on UserPreferencesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPreferencesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPreferencesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPreferencesModel value)  $default,){
final _that = this;
switch (_that) {
case _UserPreferencesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPreferencesModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserPreferencesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  ShoppingDay shoppingDay, @HiveField(1)  List<DietaryPreference> dietaryPreferences, @HiveField(2)  bool soundEffectsEnabled, @HiveField(3)  bool onboardingComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPreferencesModel() when $default != null:
return $default(_that.shoppingDay,_that.dietaryPreferences,_that.soundEffectsEnabled,_that.onboardingComplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  ShoppingDay shoppingDay, @HiveField(1)  List<DietaryPreference> dietaryPreferences, @HiveField(2)  bool soundEffectsEnabled, @HiveField(3)  bool onboardingComplete)  $default,) {final _that = this;
switch (_that) {
case _UserPreferencesModel():
return $default(_that.shoppingDay,_that.dietaryPreferences,_that.soundEffectsEnabled,_that.onboardingComplete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  ShoppingDay shoppingDay, @HiveField(1)  List<DietaryPreference> dietaryPreferences, @HiveField(2)  bool soundEffectsEnabled, @HiveField(3)  bool onboardingComplete)?  $default,) {final _that = this;
switch (_that) {
case _UserPreferencesModel() when $default != null:
return $default(_that.shoppingDay,_that.dietaryPreferences,_that.soundEffectsEnabled,_that.onboardingComplete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPreferencesModel implements UserPreferencesModel {
  const _UserPreferencesModel({@HiveField(0) required this.shoppingDay, @HiveField(1) required final  List<DietaryPreference> dietaryPreferences, @HiveField(2) this.soundEffectsEnabled = true, @HiveField(3) this.onboardingComplete = false}): _dietaryPreferences = dietaryPreferences;
  factory _UserPreferencesModel.fromJson(Map<String, dynamic> json) => _$UserPreferencesModelFromJson(json);

@override@HiveField(0) final  ShoppingDay shoppingDay;
 final  List<DietaryPreference> _dietaryPreferences;
@override@HiveField(1) List<DietaryPreference> get dietaryPreferences {
  if (_dietaryPreferences is EqualUnmodifiableListView) return _dietaryPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryPreferences);
}

@override@JsonKey()@HiveField(2) final  bool soundEffectsEnabled;
@override@JsonKey()@HiveField(3) final  bool onboardingComplete;

/// Create a copy of UserPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesModelCopyWith<_UserPreferencesModel> get copyWith => __$UserPreferencesModelCopyWithImpl<_UserPreferencesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPreferencesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferencesModel&&(identical(other.shoppingDay, shoppingDay) || other.shoppingDay == shoppingDay)&&const DeepCollectionEquality().equals(other._dietaryPreferences, _dietaryPreferences)&&(identical(other.soundEffectsEnabled, soundEffectsEnabled) || other.soundEffectsEnabled == soundEffectsEnabled)&&(identical(other.onboardingComplete, onboardingComplete) || other.onboardingComplete == onboardingComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,shoppingDay,const DeepCollectionEquality().hash(_dietaryPreferences),soundEffectsEnabled,onboardingComplete);

@override
String toString() {
  return 'UserPreferencesModel(shoppingDay: $shoppingDay, dietaryPreferences: $dietaryPreferences, soundEffectsEnabled: $soundEffectsEnabled, onboardingComplete: $onboardingComplete)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesModelCopyWith<$Res> implements $UserPreferencesModelCopyWith<$Res> {
  factory _$UserPreferencesModelCopyWith(_UserPreferencesModel value, $Res Function(_UserPreferencesModel) _then) = __$UserPreferencesModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) ShoppingDay shoppingDay,@HiveField(1) List<DietaryPreference> dietaryPreferences,@HiveField(2) bool soundEffectsEnabled,@HiveField(3) bool onboardingComplete
});




}
/// @nodoc
class __$UserPreferencesModelCopyWithImpl<$Res>
    implements _$UserPreferencesModelCopyWith<$Res> {
  __$UserPreferencesModelCopyWithImpl(this._self, this._then);

  final _UserPreferencesModel _self;
  final $Res Function(_UserPreferencesModel) _then;

/// Create a copy of UserPreferencesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shoppingDay = null,Object? dietaryPreferences = null,Object? soundEffectsEnabled = null,Object? onboardingComplete = null,}) {
  return _then(_UserPreferencesModel(
shoppingDay: null == shoppingDay ? _self.shoppingDay : shoppingDay // ignore: cast_nullable_to_non_nullable
as ShoppingDay,dietaryPreferences: null == dietaryPreferences ? _self._dietaryPreferences : dietaryPreferences // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,soundEffectsEnabled: null == soundEffectsEnabled ? _self.soundEffectsEnabled : soundEffectsEnabled // ignore: cast_nullable_to_non_nullable
as bool,onboardingComplete: null == onboardingComplete ? _self.onboardingComplete : onboardingComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
