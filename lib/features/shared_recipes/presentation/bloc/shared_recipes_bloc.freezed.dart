// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shared_recipes_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SharedRecipesEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedRecipesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesEvent()';
}


}

/// @nodoc
class $SharedRecipesEventCopyWith<$Res>  {
$SharedRecipesEventCopyWith(SharedRecipesEvent _, $Res Function(SharedRecipesEvent) __);
}


/// Adds pattern-matching-related methods to [SharedRecipesEvent].
extension SharedRecipesEventPatterns on SharedRecipesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _Refresh value)?  refresh,TResult Function( _Share value)?  share,TResult Function( _ToggleLike value)?  toggleLike,TResult Function( _UpdateShared value)?  updateShared,TResult Function( _Unshare value)?  unshare,TResult Function( _Import value)?  importToMyRecipes,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Refresh() when refresh != null:
return refresh(_that);case _Share() when share != null:
return share(_that);case _ToggleLike() when toggleLike != null:
return toggleLike(_that);case _UpdateShared() when updateShared != null:
return updateShared(_that);case _Unshare() when unshare != null:
return unshare(_that);case _Import() when importToMyRecipes != null:
return importToMyRecipes(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _Refresh value)  refresh,required TResult Function( _Share value)  share,required TResult Function( _ToggleLike value)  toggleLike,required TResult Function( _UpdateShared value)  updateShared,required TResult Function( _Unshare value)  unshare,required TResult Function( _Import value)  importToMyRecipes,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _Refresh():
return refresh(_that);case _Share():
return share(_that);case _ToggleLike():
return toggleLike(_that);case _UpdateShared():
return updateShared(_that);case _Unshare():
return unshare(_that);case _Import():
return importToMyRecipes(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _Refresh value)?  refresh,TResult? Function( _Share value)?  share,TResult? Function( _ToggleLike value)?  toggleLike,TResult? Function( _UpdateShared value)?  updateShared,TResult? Function( _Unshare value)?  unshare,TResult? Function( _Import value)?  importToMyRecipes,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Refresh() when refresh != null:
return refresh(_that);case _Share() when share != null:
return share(_that);case _ToggleLike() when toggleLike != null:
return toggleLike(_that);case _UpdateShared() when updateShared != null:
return updateShared(_that);case _Unshare() when unshare != null:
return unshare(_that);case _Import() when importToMyRecipes != null:
return importToMyRecipes(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( Completer<void> done)?  refresh,TResult Function( RecipeEntity recipe)?  share,TResult Function( String id)?  toggleLike,TResult Function( String id,  RecipeEntity recipe)?  updateShared,TResult Function( String id)?  unshare,TResult Function( SharedRecipeEntity shared)?  importToMyRecipes,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Refresh() when refresh != null:
return refresh(_that.done);case _Share() when share != null:
return share(_that.recipe);case _ToggleLike() when toggleLike != null:
return toggleLike(_that.id);case _UpdateShared() when updateShared != null:
return updateShared(_that.id,_that.recipe);case _Unshare() when unshare != null:
return unshare(_that.id);case _Import() when importToMyRecipes != null:
return importToMyRecipes(_that.shared);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( Completer<void> done)  refresh,required TResult Function( RecipeEntity recipe)  share,required TResult Function( String id)  toggleLike,required TResult Function( String id,  RecipeEntity recipe)  updateShared,required TResult Function( String id)  unshare,required TResult Function( SharedRecipeEntity shared)  importToMyRecipes,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _Refresh():
return refresh(_that.done);case _Share():
return share(_that.recipe);case _ToggleLike():
return toggleLike(_that.id);case _UpdateShared():
return updateShared(_that.id,_that.recipe);case _Unshare():
return unshare(_that.id);case _Import():
return importToMyRecipes(_that.shared);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( Completer<void> done)?  refresh,TResult? Function( RecipeEntity recipe)?  share,TResult? Function( String id)?  toggleLike,TResult? Function( String id,  RecipeEntity recipe)?  updateShared,TResult? Function( String id)?  unshare,TResult? Function( SharedRecipeEntity shared)?  importToMyRecipes,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Refresh() when refresh != null:
return refresh(_that.done);case _Share() when share != null:
return share(_that.recipe);case _ToggleLike() when toggleLike != null:
return toggleLike(_that.id);case _UpdateShared() when updateShared != null:
return updateShared(_that.id,_that.recipe);case _Unshare() when unshare != null:
return unshare(_that.id);case _Import() when importToMyRecipes != null:
return importToMyRecipes(_that.shared);case _:
  return null;

}
}

}

/// @nodoc


class _Init with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _Init();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.init'))
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
  return 'SharedRecipesEvent.init()';
}


}




/// @nodoc


class _Refresh with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _Refresh(this.done);
  

 final  Completer<void> done;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshCopyWith<_Refresh> get copyWith => __$RefreshCopyWithImpl<_Refresh>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.refresh'))
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
  return 'SharedRecipesEvent.refresh(done: $done)';
}


}

/// @nodoc
abstract mixin class _$RefreshCopyWith<$Res> implements $SharedRecipesEventCopyWith<$Res> {
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

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? done = null,}) {
  return _then(_Refresh(
null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as Completer<void>,
  ));
}


}

/// @nodoc


class _Share with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _Share(this.recipe);
  

 final  RecipeEntity recipe;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShareCopyWith<_Share> get copyWith => __$ShareCopyWithImpl<_Share>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.share'))
    ..add(DiagnosticsProperty('recipe', recipe));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Share&&(identical(other.recipe, recipe) || other.recipe == recipe));
}


@override
int get hashCode => Object.hash(runtimeType,recipe);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesEvent.share(recipe: $recipe)';
}


}

/// @nodoc
abstract mixin class _$ShareCopyWith<$Res> implements $SharedRecipesEventCopyWith<$Res> {
  factory _$ShareCopyWith(_Share value, $Res Function(_Share) _then) = __$ShareCopyWithImpl;
@useResult
$Res call({
 RecipeEntity recipe
});




}
/// @nodoc
class __$ShareCopyWithImpl<$Res>
    implements _$ShareCopyWith<$Res> {
  __$ShareCopyWithImpl(this._self, this._then);

  final _Share _self;
  final $Res Function(_Share) _then;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipe = null,}) {
  return _then(_Share(
null == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as RecipeEntity,
  ));
}


}

/// @nodoc


class _ToggleLike with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _ToggleLike(this.id);
  

 final  String id;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleLikeCopyWith<_ToggleLike> get copyWith => __$ToggleLikeCopyWithImpl<_ToggleLike>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.toggleLike'))
    ..add(DiagnosticsProperty('id', id));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleLike&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesEvent.toggleLike(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ToggleLikeCopyWith<$Res> implements $SharedRecipesEventCopyWith<$Res> {
  factory _$ToggleLikeCopyWith(_ToggleLike value, $Res Function(_ToggleLike) _then) = __$ToggleLikeCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$ToggleLikeCopyWithImpl<$Res>
    implements _$ToggleLikeCopyWith<$Res> {
  __$ToggleLikeCopyWithImpl(this._self, this._then);

  final _ToggleLike _self;
  final $Res Function(_ToggleLike) _then;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ToggleLike(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UpdateShared with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _UpdateShared(this.id, this.recipe);
  

 final  String id;
 final  RecipeEntity recipe;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateSharedCopyWith<_UpdateShared> get copyWith => __$UpdateSharedCopyWithImpl<_UpdateShared>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.updateShared'))
    ..add(DiagnosticsProperty('id', id))..add(DiagnosticsProperty('recipe', recipe));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateShared&&(identical(other.id, id) || other.id == id)&&(identical(other.recipe, recipe) || other.recipe == recipe));
}


@override
int get hashCode => Object.hash(runtimeType,id,recipe);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesEvent.updateShared(id: $id, recipe: $recipe)';
}


}

/// @nodoc
abstract mixin class _$UpdateSharedCopyWith<$Res> implements $SharedRecipesEventCopyWith<$Res> {
  factory _$UpdateSharedCopyWith(_UpdateShared value, $Res Function(_UpdateShared) _then) = __$UpdateSharedCopyWithImpl;
@useResult
$Res call({
 String id, RecipeEntity recipe
});




}
/// @nodoc
class __$UpdateSharedCopyWithImpl<$Res>
    implements _$UpdateSharedCopyWith<$Res> {
  __$UpdateSharedCopyWithImpl(this._self, this._then);

  final _UpdateShared _self;
  final $Res Function(_UpdateShared) _then;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recipe = null,}) {
  return _then(_UpdateShared(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,null == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as RecipeEntity,
  ));
}


}

/// @nodoc


class _Unshare with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _Unshare(this.id);
  

 final  String id;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnshareCopyWith<_Unshare> get copyWith => __$UnshareCopyWithImpl<_Unshare>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.unshare'))
    ..add(DiagnosticsProperty('id', id));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Unshare&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesEvent.unshare(id: $id)';
}


}

/// @nodoc
abstract mixin class _$UnshareCopyWith<$Res> implements $SharedRecipesEventCopyWith<$Res> {
  factory _$UnshareCopyWith(_Unshare value, $Res Function(_Unshare) _then) = __$UnshareCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$UnshareCopyWithImpl<$Res>
    implements _$UnshareCopyWith<$Res> {
  __$UnshareCopyWithImpl(this._self, this._then);

  final _Unshare _self;
  final $Res Function(_Unshare) _then;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_Unshare(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Import with DiagnosticableTreeMixin implements SharedRecipesEvent {
  const _Import(this.shared);
  

 final  SharedRecipeEntity shared;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportCopyWith<_Import> get copyWith => __$ImportCopyWithImpl<_Import>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesEvent.importToMyRecipes'))
    ..add(DiagnosticsProperty('shared', shared));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Import&&(identical(other.shared, shared) || other.shared == shared));
}


@override
int get hashCode => Object.hash(runtimeType,shared);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesEvent.importToMyRecipes(shared: $shared)';
}


}

/// @nodoc
abstract mixin class _$ImportCopyWith<$Res> implements $SharedRecipesEventCopyWith<$Res> {
  factory _$ImportCopyWith(_Import value, $Res Function(_Import) _then) = __$ImportCopyWithImpl;
@useResult
$Res call({
 SharedRecipeEntity shared
});




}
/// @nodoc
class __$ImportCopyWithImpl<$Res>
    implements _$ImportCopyWith<$Res> {
  __$ImportCopyWithImpl(this._self, this._then);

  final _Import _self;
  final $Res Function(_Import) _then;

/// Create a copy of SharedRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shared = null,}) {
  return _then(_Import(
null == shared ? _self.shared : shared // ignore: cast_nullable_to_non_nullable
as SharedRecipeEntity,
  ));
}


}

/// @nodoc
mixin _$SharedRecipesState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedRecipesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesState()';
}


}

/// @nodoc
class $SharedRecipesStateCopyWith<$Res>  {
$SharedRecipesStateCopyWith(SharedRecipesState _, $Res Function(SharedRecipesState) __);
}


/// Adds pattern-matching-related methods to [SharedRecipesState].
extension SharedRecipesStatePatterns on SharedRecipesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SharedRecipesLoading value)?  loading,TResult Function( SharedRecipesLoaded value)?  loaded,TResult Function( SharedRecipesError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SharedRecipesLoading() when loading != null:
return loading(_that);case SharedRecipesLoaded() when loaded != null:
return loaded(_that);case SharedRecipesError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SharedRecipesLoading value)  loading,required TResult Function( SharedRecipesLoaded value)  loaded,required TResult Function( SharedRecipesError value)  errorMessage,}){
final _that = this;
switch (_that) {
case SharedRecipesLoading():
return loading(_that);case SharedRecipesLoaded():
return loaded(_that);case SharedRecipesError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SharedRecipesLoading value)?  loading,TResult? Function( SharedRecipesLoaded value)?  loaded,TResult? Function( SharedRecipesError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case SharedRecipesLoading() when loading != null:
return loading(_that);case SharedRecipesLoaded() when loaded != null:
return loaded(_that);case SharedRecipesError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<SharedRecipeEntity> recipes,  bool imported,  Set<String> savedIds)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SharedRecipesLoading() when loading != null:
return loading();case SharedRecipesLoaded() when loaded != null:
return loaded(_that.recipes,_that.imported,_that.savedIds);case SharedRecipesError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<SharedRecipeEntity> recipes,  bool imported,  Set<String> savedIds)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case SharedRecipesLoading():
return loading();case SharedRecipesLoaded():
return loaded(_that.recipes,_that.imported,_that.savedIds);case SharedRecipesError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<SharedRecipeEntity> recipes,  bool imported,  Set<String> savedIds)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case SharedRecipesLoading() when loading != null:
return loading();case SharedRecipesLoaded() when loaded != null:
return loaded(_that.recipes,_that.imported,_that.savedIds);case SharedRecipesError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class SharedRecipesLoading with DiagnosticableTreeMixin implements SharedRecipesState {
  const SharedRecipesLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedRecipesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesState.loading()';
}


}




/// @nodoc


class SharedRecipesLoaded with DiagnosticableTreeMixin implements SharedRecipesState {
  const SharedRecipesLoaded(final  List<SharedRecipeEntity> recipes, {this.imported = false, final  Set<String> savedIds = const <String>{}}): _recipes = recipes,_savedIds = savedIds;
  

 final  List<SharedRecipeEntity> _recipes;
 List<SharedRecipeEntity> get recipes {
  if (_recipes is EqualUnmodifiableListView) return _recipes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recipes);
}

@JsonKey() final  bool imported;
/// Feed ids the user already has a local copy of, so the saved filter and
/// the save button can reflect it.
 final  Set<String> _savedIds;
/// Feed ids the user already has a local copy of, so the saved filter and
/// the save button can reflect it.
@JsonKey() Set<String> get savedIds {
  if (_savedIds is EqualUnmodifiableSetView) return _savedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_savedIds);
}


/// Create a copy of SharedRecipesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedRecipesLoadedCopyWith<SharedRecipesLoaded> get copyWith => _$SharedRecipesLoadedCopyWithImpl<SharedRecipesLoaded>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesState.loaded'))
    ..add(DiagnosticsProperty('recipes', recipes))..add(DiagnosticsProperty('imported', imported))..add(DiagnosticsProperty('savedIds', savedIds));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedRecipesLoaded&&const DeepCollectionEquality().equals(other._recipes, _recipes)&&(identical(other.imported, imported) || other.imported == imported)&&const DeepCollectionEquality().equals(other._savedIds, _savedIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recipes),imported,const DeepCollectionEquality().hash(_savedIds));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesState.loaded(recipes: $recipes, imported: $imported, savedIds: $savedIds)';
}


}

/// @nodoc
abstract mixin class $SharedRecipesLoadedCopyWith<$Res> implements $SharedRecipesStateCopyWith<$Res> {
  factory $SharedRecipesLoadedCopyWith(SharedRecipesLoaded value, $Res Function(SharedRecipesLoaded) _then) = _$SharedRecipesLoadedCopyWithImpl;
@useResult
$Res call({
 List<SharedRecipeEntity> recipes, bool imported, Set<String> savedIds
});




}
/// @nodoc
class _$SharedRecipesLoadedCopyWithImpl<$Res>
    implements $SharedRecipesLoadedCopyWith<$Res> {
  _$SharedRecipesLoadedCopyWithImpl(this._self, this._then);

  final SharedRecipesLoaded _self;
  final $Res Function(SharedRecipesLoaded) _then;

/// Create a copy of SharedRecipesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipes = null,Object? imported = null,Object? savedIds = null,}) {
  return _then(SharedRecipesLoaded(
null == recipes ? _self._recipes : recipes // ignore: cast_nullable_to_non_nullable
as List<SharedRecipeEntity>,imported: null == imported ? _self.imported : imported // ignore: cast_nullable_to_non_nullable
as bool,savedIds: null == savedIds ? _self._savedIds : savedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

/// @nodoc


class SharedRecipesError with DiagnosticableTreeMixin implements SharedRecipesState {
  const SharedRecipesError(this.error);
  

 final  String error;

/// Create a copy of SharedRecipesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SharedRecipesErrorCopyWith<SharedRecipesError> get copyWith => _$SharedRecipesErrorCopyWithImpl<SharedRecipesError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SharedRecipesState.errorMessage'))
    ..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SharedRecipesError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SharedRecipesState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $SharedRecipesErrorCopyWith<$Res> implements $SharedRecipesStateCopyWith<$Res> {
  factory $SharedRecipesErrorCopyWith(SharedRecipesError value, $Res Function(SharedRecipesError) _then) = _$SharedRecipesErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$SharedRecipesErrorCopyWithImpl<$Res>
    implements $SharedRecipesErrorCopyWith<$Res> {
  _$SharedRecipesErrorCopyWithImpl(this._self, this._then);

  final SharedRecipesError _self;
  final $Res Function(SharedRecipesError) _then;

/// Create a copy of SharedRecipesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(SharedRecipesError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
