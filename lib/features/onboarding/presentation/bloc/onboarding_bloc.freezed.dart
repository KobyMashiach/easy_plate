// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent()';
}


}

/// @nodoc
class $OnboardingEventCopyWith<$Res>  {
$OnboardingEventCopyWith(OnboardingEvent _, $Res Function(OnboardingEvent) __);
}


/// Adds pattern-matching-related methods to [OnboardingEvent].
extension OnboardingEventPatterns on OnboardingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SelectShoppingDay value)?  selectShoppingDay,TResult Function( _ToggleDietaryPreference value)?  toggleDietaryPreference,TResult Function( _Finish value)?  finish,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectShoppingDay() when selectShoppingDay != null:
return selectShoppingDay(_that);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that);case _Finish() when finish != null:
return finish(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SelectShoppingDay value)  selectShoppingDay,required TResult Function( _ToggleDietaryPreference value)  toggleDietaryPreference,required TResult Function( _Finish value)  finish,}){
final _that = this;
switch (_that) {
case _SelectShoppingDay():
return selectShoppingDay(_that);case _ToggleDietaryPreference():
return toggleDietaryPreference(_that);case _Finish():
return finish(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SelectShoppingDay value)?  selectShoppingDay,TResult? Function( _ToggleDietaryPreference value)?  toggleDietaryPreference,TResult? Function( _Finish value)?  finish,}){
final _that = this;
switch (_that) {
case _SelectShoppingDay() when selectShoppingDay != null:
return selectShoppingDay(_that);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that);case _Finish() when finish != null:
return finish(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ShoppingDay day)?  selectShoppingDay,TResult Function( DietaryPreference preference)?  toggleDietaryPreference,TResult Function()?  finish,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectShoppingDay() when selectShoppingDay != null:
return selectShoppingDay(_that.day);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that.preference);case _Finish() when finish != null:
return finish();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ShoppingDay day)  selectShoppingDay,required TResult Function( DietaryPreference preference)  toggleDietaryPreference,required TResult Function()  finish,}) {final _that = this;
switch (_that) {
case _SelectShoppingDay():
return selectShoppingDay(_that.day);case _ToggleDietaryPreference():
return toggleDietaryPreference(_that.preference);case _Finish():
return finish();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ShoppingDay day)?  selectShoppingDay,TResult? Function( DietaryPreference preference)?  toggleDietaryPreference,TResult? Function()?  finish,}) {final _that = this;
switch (_that) {
case _SelectShoppingDay() when selectShoppingDay != null:
return selectShoppingDay(_that.day);case _ToggleDietaryPreference() when toggleDietaryPreference != null:
return toggleDietaryPreference(_that.preference);case _Finish() when finish != null:
return finish();case _:
  return null;

}
}

}

/// @nodoc


class _SelectShoppingDay implements OnboardingEvent {
  const _SelectShoppingDay(this.day);
  

 final  ShoppingDay day;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectShoppingDayCopyWith<_SelectShoppingDay> get copyWith => __$SelectShoppingDayCopyWithImpl<_SelectShoppingDay>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectShoppingDay&&(identical(other.day, day) || other.day == day));
}


@override
int get hashCode => Object.hash(runtimeType,day);

@override
String toString() {
  return 'OnboardingEvent.selectShoppingDay(day: $day)';
}


}

/// @nodoc
abstract mixin class _$SelectShoppingDayCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
  factory _$SelectShoppingDayCopyWith(_SelectShoppingDay value, $Res Function(_SelectShoppingDay) _then) = __$SelectShoppingDayCopyWithImpl;
@useResult
$Res call({
 ShoppingDay day
});




}
/// @nodoc
class __$SelectShoppingDayCopyWithImpl<$Res>
    implements _$SelectShoppingDayCopyWith<$Res> {
  __$SelectShoppingDayCopyWithImpl(this._self, this._then);

  final _SelectShoppingDay _self;
  final $Res Function(_SelectShoppingDay) _then;

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? day = null,}) {
  return _then(_SelectShoppingDay(
null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as ShoppingDay,
  ));
}


}

/// @nodoc


class _ToggleDietaryPreference implements OnboardingEvent {
  const _ToggleDietaryPreference(this.preference);
  

 final  DietaryPreference preference;

/// Create a copy of OnboardingEvent
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
  return 'OnboardingEvent.toggleDietaryPreference(preference: $preference)';
}


}

/// @nodoc
abstract mixin class _$ToggleDietaryPreferenceCopyWith<$Res> implements $OnboardingEventCopyWith<$Res> {
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

/// Create a copy of OnboardingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preference = null,}) {
  return _then(_ToggleDietaryPreference(
null == preference ? _self.preference : preference // ignore: cast_nullable_to_non_nullable
as DietaryPreference,
  ));
}


}

/// @nodoc


class _Finish implements OnboardingEvent {
  const _Finish();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Finish);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingEvent.finish()';
}


}




/// @nodoc
mixin _$OnboardingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState()';
}


}

/// @nodoc
class $OnboardingStateCopyWith<$Res>  {
$OnboardingStateCopyWith(OnboardingState _, $Res Function(OnboardingState) __);
}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Editing value)?  editing,TResult Function( Saving value)?  saving,TResult Function( Complete value)?  complete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Editing() when editing != null:
return editing(_that);case Saving() when saving != null:
return saving(_that);case Complete() when complete != null:
return complete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Editing value)  editing,required TResult Function( Saving value)  saving,required TResult Function( Complete value)  complete,}){
final _that = this;
switch (_that) {
case Editing():
return editing(_that);case Saving():
return saving(_that);case Complete():
return complete(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Editing value)?  editing,TResult? Function( Saving value)?  saving,TResult? Function( Complete value)?  complete,}){
final _that = this;
switch (_that) {
case Editing() when editing != null:
return editing(_that);case Saving() when saving != null:
return saving(_that);case Complete() when complete != null:
return complete(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ShoppingDay shoppingDay,  List<DietaryPreference> selectedPreferences)?  editing,TResult Function( ShoppingDay shoppingDay,  List<DietaryPreference> selectedPreferences)?  saving,TResult Function()?  complete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Editing() when editing != null:
return editing(_that.shoppingDay,_that.selectedPreferences);case Saving() when saving != null:
return saving(_that.shoppingDay,_that.selectedPreferences);case Complete() when complete != null:
return complete();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ShoppingDay shoppingDay,  List<DietaryPreference> selectedPreferences)  editing,required TResult Function( ShoppingDay shoppingDay,  List<DietaryPreference> selectedPreferences)  saving,required TResult Function()  complete,}) {final _that = this;
switch (_that) {
case Editing():
return editing(_that.shoppingDay,_that.selectedPreferences);case Saving():
return saving(_that.shoppingDay,_that.selectedPreferences);case Complete():
return complete();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ShoppingDay shoppingDay,  List<DietaryPreference> selectedPreferences)?  editing,TResult? Function( ShoppingDay shoppingDay,  List<DietaryPreference> selectedPreferences)?  saving,TResult? Function()?  complete,}) {final _that = this;
switch (_that) {
case Editing() when editing != null:
return editing(_that.shoppingDay,_that.selectedPreferences);case Saving() when saving != null:
return saving(_that.shoppingDay,_that.selectedPreferences);case Complete() when complete != null:
return complete();case _:
  return null;

}
}

}

/// @nodoc


class Editing implements OnboardingState {
  const Editing(this.shoppingDay, final  List<DietaryPreference> selectedPreferences): _selectedPreferences = selectedPreferences;
  

 final  ShoppingDay shoppingDay;
 final  List<DietaryPreference> _selectedPreferences;
 List<DietaryPreference> get selectedPreferences {
  if (_selectedPreferences is EqualUnmodifiableListView) return _selectedPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedPreferences);
}


/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditingCopyWith<Editing> get copyWith => _$EditingCopyWithImpl<Editing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Editing&&(identical(other.shoppingDay, shoppingDay) || other.shoppingDay == shoppingDay)&&const DeepCollectionEquality().equals(other._selectedPreferences, _selectedPreferences));
}


@override
int get hashCode => Object.hash(runtimeType,shoppingDay,const DeepCollectionEquality().hash(_selectedPreferences));

@override
String toString() {
  return 'OnboardingState.editing(shoppingDay: $shoppingDay, selectedPreferences: $selectedPreferences)';
}


}

/// @nodoc
abstract mixin class $EditingCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $EditingCopyWith(Editing value, $Res Function(Editing) _then) = _$EditingCopyWithImpl;
@useResult
$Res call({
 ShoppingDay shoppingDay, List<DietaryPreference> selectedPreferences
});




}
/// @nodoc
class _$EditingCopyWithImpl<$Res>
    implements $EditingCopyWith<$Res> {
  _$EditingCopyWithImpl(this._self, this._then);

  final Editing _self;
  final $Res Function(Editing) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shoppingDay = null,Object? selectedPreferences = null,}) {
  return _then(Editing(
null == shoppingDay ? _self.shoppingDay : shoppingDay // ignore: cast_nullable_to_non_nullable
as ShoppingDay,null == selectedPreferences ? _self._selectedPreferences : selectedPreferences // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,
  ));
}


}

/// @nodoc


class Saving implements OnboardingState {
  const Saving(this.shoppingDay, final  List<DietaryPreference> selectedPreferences): _selectedPreferences = selectedPreferences;
  

 final  ShoppingDay shoppingDay;
 final  List<DietaryPreference> _selectedPreferences;
 List<DietaryPreference> get selectedPreferences {
  if (_selectedPreferences is EqualUnmodifiableListView) return _selectedPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedPreferences);
}


/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavingCopyWith<Saving> get copyWith => _$SavingCopyWithImpl<Saving>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Saving&&(identical(other.shoppingDay, shoppingDay) || other.shoppingDay == shoppingDay)&&const DeepCollectionEquality().equals(other._selectedPreferences, _selectedPreferences));
}


@override
int get hashCode => Object.hash(runtimeType,shoppingDay,const DeepCollectionEquality().hash(_selectedPreferences));

@override
String toString() {
  return 'OnboardingState.saving(shoppingDay: $shoppingDay, selectedPreferences: $selectedPreferences)';
}


}

/// @nodoc
abstract mixin class $SavingCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory $SavingCopyWith(Saving value, $Res Function(Saving) _then) = _$SavingCopyWithImpl;
@useResult
$Res call({
 ShoppingDay shoppingDay, List<DietaryPreference> selectedPreferences
});




}
/// @nodoc
class _$SavingCopyWithImpl<$Res>
    implements $SavingCopyWith<$Res> {
  _$SavingCopyWithImpl(this._self, this._then);

  final Saving _self;
  final $Res Function(Saving) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shoppingDay = null,Object? selectedPreferences = null,}) {
  return _then(Saving(
null == shoppingDay ? _self.shoppingDay : shoppingDay // ignore: cast_nullable_to_non_nullable
as ShoppingDay,null == selectedPreferences ? _self._selectedPreferences : selectedPreferences // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,
  ));
}


}

/// @nodoc


class Complete implements OnboardingState {
  const Complete();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Complete);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OnboardingState.complete()';
}


}




// dart format on
