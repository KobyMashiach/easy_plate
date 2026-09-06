// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_recipes_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MyRecipesEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyRecipesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesEvent()';
}


}

/// @nodoc
class $MyRecipesEventCopyWith<$Res>  {
$MyRecipesEventCopyWith(MyRecipesEvent _, $Res Function(MyRecipesEvent) __);
}


/// Adds pattern-matching-related methods to [MyRecipesEvent].
extension MyRecipesEventPatterns on MyRecipesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Init value)?  init,TResult Function( _Search value)?  search,TResult Function( _FilterByDietary value)?  filterByDietary,TResult Function( _DeleteRecipe value)?  deleteRecipe,TResult Function( _RecipesUpdated value)?  recipesUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Search() when search != null:
return search(_that);case _FilterByDietary() when filterByDietary != null:
return filterByDietary(_that);case _DeleteRecipe() when deleteRecipe != null:
return deleteRecipe(_that);case _RecipesUpdated() when recipesUpdated != null:
return recipesUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Init value)  init,required TResult Function( _Search value)  search,required TResult Function( _FilterByDietary value)  filterByDietary,required TResult Function( _DeleteRecipe value)  deleteRecipe,required TResult Function( _RecipesUpdated value)  recipesUpdated,}){
final _that = this;
switch (_that) {
case _Init():
return init(_that);case _Search():
return search(_that);case _FilterByDietary():
return filterByDietary(_that);case _DeleteRecipe():
return deleteRecipe(_that);case _RecipesUpdated():
return recipesUpdated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Init value)?  init,TResult? Function( _Search value)?  search,TResult? Function( _FilterByDietary value)?  filterByDietary,TResult? Function( _DeleteRecipe value)?  deleteRecipe,TResult? Function( _RecipesUpdated value)?  recipesUpdated,}){
final _that = this;
switch (_that) {
case _Init() when init != null:
return init(_that);case _Search() when search != null:
return search(_that);case _FilterByDietary() when filterByDietary != null:
return filterByDietary(_that);case _DeleteRecipe() when deleteRecipe != null:
return deleteRecipe(_that);case _RecipesUpdated() when recipesUpdated != null:
return recipesUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  init,TResult Function( String query)?  search,TResult Function( List<DietaryPreference> preferences)?  filterByDietary,TResult Function( String id)?  deleteRecipe,TResult Function( List<RecipeEntity> recipes)?  recipesUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Search() when search != null:
return search(_that.query);case _FilterByDietary() when filterByDietary != null:
return filterByDietary(_that.preferences);case _DeleteRecipe() when deleteRecipe != null:
return deleteRecipe(_that.id);case _RecipesUpdated() when recipesUpdated != null:
return recipesUpdated(_that.recipes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  init,required TResult Function( String query)  search,required TResult Function( List<DietaryPreference> preferences)  filterByDietary,required TResult Function( String id)  deleteRecipe,required TResult Function( List<RecipeEntity> recipes)  recipesUpdated,}) {final _that = this;
switch (_that) {
case _Init():
return init();case _Search():
return search(_that.query);case _FilterByDietary():
return filterByDietary(_that.preferences);case _DeleteRecipe():
return deleteRecipe(_that.id);case _RecipesUpdated():
return recipesUpdated(_that.recipes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  init,TResult? Function( String query)?  search,TResult? Function( List<DietaryPreference> preferences)?  filterByDietary,TResult? Function( String id)?  deleteRecipe,TResult? Function( List<RecipeEntity> recipes)?  recipesUpdated,}) {final _that = this;
switch (_that) {
case _Init() when init != null:
return init();case _Search() when search != null:
return search(_that.query);case _FilterByDietary() when filterByDietary != null:
return filterByDietary(_that.preferences);case _DeleteRecipe() when deleteRecipe != null:
return deleteRecipe(_that.id);case _RecipesUpdated() when recipesUpdated != null:
return recipesUpdated(_that.recipes);case _:
  return null;

}
}

}

/// @nodoc


class _Init with DiagnosticableTreeMixin implements MyRecipesEvent {
  const _Init();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesEvent.init'))
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
  return 'MyRecipesEvent.init()';
}


}




/// @nodoc


class _Search with DiagnosticableTreeMixin implements MyRecipesEvent {
  const _Search(this.query);
  

 final  String query;

/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchCopyWith<_Search> get copyWith => __$SearchCopyWithImpl<_Search>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesEvent.search'))
    ..add(DiagnosticsProperty('query', query));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Search&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesEvent.search(query: $query)';
}


}

/// @nodoc
abstract mixin class _$SearchCopyWith<$Res> implements $MyRecipesEventCopyWith<$Res> {
  factory _$SearchCopyWith(_Search value, $Res Function(_Search) _then) = __$SearchCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class __$SearchCopyWithImpl<$Res>
    implements _$SearchCopyWith<$Res> {
  __$SearchCopyWithImpl(this._self, this._then);

  final _Search _self;
  final $Res Function(_Search) _then;

/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(_Search(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _FilterByDietary with DiagnosticableTreeMixin implements MyRecipesEvent {
  const _FilterByDietary(final  List<DietaryPreference> preferences): _preferences = preferences;
  

 final  List<DietaryPreference> _preferences;
 List<DietaryPreference> get preferences {
  if (_preferences is EqualUnmodifiableListView) return _preferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferences);
}


/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilterByDietaryCopyWith<_FilterByDietary> get copyWith => __$FilterByDietaryCopyWithImpl<_FilterByDietary>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesEvent.filterByDietary'))
    ..add(DiagnosticsProperty('preferences', preferences));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FilterByDietary&&const DeepCollectionEquality().equals(other._preferences, _preferences));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_preferences));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesEvent.filterByDietary(preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class _$FilterByDietaryCopyWith<$Res> implements $MyRecipesEventCopyWith<$Res> {
  factory _$FilterByDietaryCopyWith(_FilterByDietary value, $Res Function(_FilterByDietary) _then) = __$FilterByDietaryCopyWithImpl;
@useResult
$Res call({
 List<DietaryPreference> preferences
});




}
/// @nodoc
class __$FilterByDietaryCopyWithImpl<$Res>
    implements _$FilterByDietaryCopyWith<$Res> {
  __$FilterByDietaryCopyWithImpl(this._self, this._then);

  final _FilterByDietary _self;
  final $Res Function(_FilterByDietary) _then;

/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preferences = null,}) {
  return _then(_FilterByDietary(
null == preferences ? _self._preferences : preferences // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,
  ));
}


}

/// @nodoc


class _DeleteRecipe with DiagnosticableTreeMixin implements MyRecipesEvent {
  const _DeleteRecipe(this.id);
  

 final  String id;

/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteRecipeCopyWith<_DeleteRecipe> get copyWith => __$DeleteRecipeCopyWithImpl<_DeleteRecipe>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesEvent.deleteRecipe'))
    ..add(DiagnosticsProperty('id', id));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteRecipe&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesEvent.deleteRecipe(id: $id)';
}


}

/// @nodoc
abstract mixin class _$DeleteRecipeCopyWith<$Res> implements $MyRecipesEventCopyWith<$Res> {
  factory _$DeleteRecipeCopyWith(_DeleteRecipe value, $Res Function(_DeleteRecipe) _then) = __$DeleteRecipeCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$DeleteRecipeCopyWithImpl<$Res>
    implements _$DeleteRecipeCopyWith<$Res> {
  __$DeleteRecipeCopyWithImpl(this._self, this._then);

  final _DeleteRecipe _self;
  final $Res Function(_DeleteRecipe) _then;

/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_DeleteRecipe(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _RecipesUpdated with DiagnosticableTreeMixin implements MyRecipesEvent {
  const _RecipesUpdated(final  List<RecipeEntity> recipes): _recipes = recipes;
  

 final  List<RecipeEntity> _recipes;
 List<RecipeEntity> get recipes {
  if (_recipes is EqualUnmodifiableListView) return _recipes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recipes);
}


/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipesUpdatedCopyWith<_RecipesUpdated> get copyWith => __$RecipesUpdatedCopyWithImpl<_RecipesUpdated>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesEvent.recipesUpdated'))
    ..add(DiagnosticsProperty('recipes', recipes));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipesUpdated&&const DeepCollectionEquality().equals(other._recipes, _recipes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recipes));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesEvent.recipesUpdated(recipes: $recipes)';
}


}

/// @nodoc
abstract mixin class _$RecipesUpdatedCopyWith<$Res> implements $MyRecipesEventCopyWith<$Res> {
  factory _$RecipesUpdatedCopyWith(_RecipesUpdated value, $Res Function(_RecipesUpdated) _then) = __$RecipesUpdatedCopyWithImpl;
@useResult
$Res call({
 List<RecipeEntity> recipes
});




}
/// @nodoc
class __$RecipesUpdatedCopyWithImpl<$Res>
    implements _$RecipesUpdatedCopyWith<$Res> {
  __$RecipesUpdatedCopyWithImpl(this._self, this._then);

  final _RecipesUpdated _self;
  final $Res Function(_RecipesUpdated) _then;

/// Create a copy of MyRecipesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipes = null,}) {
  return _then(_RecipesUpdated(
null == recipes ? _self._recipes : recipes // ignore: cast_nullable_to_non_nullable
as List<RecipeEntity>,
  ));
}


}

/// @nodoc
mixin _$MyRecipesState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyRecipesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesState()';
}


}

/// @nodoc
class $MyRecipesStateCopyWith<$Res>  {
$MyRecipesStateCopyWith(MyRecipesState _, $Res Function(MyRecipesState) __);
}


/// Adds pattern-matching-related methods to [MyRecipesState].
extension MyRecipesStatePatterns on MyRecipesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MyRecipesLoading value)?  loading,TResult Function( MyRecipesLoaded value)?  loaded,TResult Function( MyRecipesError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MyRecipesLoading() when loading != null:
return loading(_that);case MyRecipesLoaded() when loaded != null:
return loaded(_that);case MyRecipesError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MyRecipesLoading value)  loading,required TResult Function( MyRecipesLoaded value)  loaded,required TResult Function( MyRecipesError value)  errorMessage,}){
final _that = this;
switch (_that) {
case MyRecipesLoading():
return loading(_that);case MyRecipesLoaded():
return loaded(_that);case MyRecipesError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MyRecipesLoading value)?  loading,TResult? Function( MyRecipesLoaded value)?  loaded,TResult? Function( MyRecipesError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case MyRecipesLoading() when loading != null:
return loading(_that);case MyRecipesLoaded() when loaded != null:
return loaded(_that);case MyRecipesError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<RecipeEntity> recipes,  String query,  List<DietaryPreference> dietaryFilters)?  loaded,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MyRecipesLoading() when loading != null:
return loading();case MyRecipesLoaded() when loaded != null:
return loaded(_that.recipes,_that.query,_that.dietaryFilters);case MyRecipesError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<RecipeEntity> recipes,  String query,  List<DietaryPreference> dietaryFilters)  loaded,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case MyRecipesLoading():
return loading();case MyRecipesLoaded():
return loaded(_that.recipes,_that.query,_that.dietaryFilters);case MyRecipesError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<RecipeEntity> recipes,  String query,  List<DietaryPreference> dietaryFilters)?  loaded,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case MyRecipesLoading() when loading != null:
return loading();case MyRecipesLoaded() when loaded != null:
return loaded(_that.recipes,_that.query,_that.dietaryFilters);case MyRecipesError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class MyRecipesLoading with DiagnosticableTreeMixin implements MyRecipesState {
  const MyRecipesLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyRecipesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesState.loading()';
}


}




/// @nodoc


class MyRecipesLoaded with DiagnosticableTreeMixin implements MyRecipesState {
  const MyRecipesLoaded(final  List<RecipeEntity> recipes, {this.query = '', final  List<DietaryPreference> dietaryFilters = const []}): _recipes = recipes,_dietaryFilters = dietaryFilters;
  

 final  List<RecipeEntity> _recipes;
 List<RecipeEntity> get recipes {
  if (_recipes is EqualUnmodifiableListView) return _recipes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recipes);
}

@JsonKey() final  String query;
 final  List<DietaryPreference> _dietaryFilters;
@JsonKey() List<DietaryPreference> get dietaryFilters {
  if (_dietaryFilters is EqualUnmodifiableListView) return _dietaryFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dietaryFilters);
}


/// Create a copy of MyRecipesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyRecipesLoadedCopyWith<MyRecipesLoaded> get copyWith => _$MyRecipesLoadedCopyWithImpl<MyRecipesLoaded>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesState.loaded'))
    ..add(DiagnosticsProperty('recipes', recipes))..add(DiagnosticsProperty('query', query))..add(DiagnosticsProperty('dietaryFilters', dietaryFilters));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyRecipesLoaded&&const DeepCollectionEquality().equals(other._recipes, _recipes)&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._dietaryFilters, _dietaryFilters));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recipes),query,const DeepCollectionEquality().hash(_dietaryFilters));

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesState.loaded(recipes: $recipes, query: $query, dietaryFilters: $dietaryFilters)';
}


}

/// @nodoc
abstract mixin class $MyRecipesLoadedCopyWith<$Res> implements $MyRecipesStateCopyWith<$Res> {
  factory $MyRecipesLoadedCopyWith(MyRecipesLoaded value, $Res Function(MyRecipesLoaded) _then) = _$MyRecipesLoadedCopyWithImpl;
@useResult
$Res call({
 List<RecipeEntity> recipes, String query, List<DietaryPreference> dietaryFilters
});




}
/// @nodoc
class _$MyRecipesLoadedCopyWithImpl<$Res>
    implements $MyRecipesLoadedCopyWith<$Res> {
  _$MyRecipesLoadedCopyWithImpl(this._self, this._then);

  final MyRecipesLoaded _self;
  final $Res Function(MyRecipesLoaded) _then;

/// Create a copy of MyRecipesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recipes = null,Object? query = null,Object? dietaryFilters = null,}) {
  return _then(MyRecipesLoaded(
null == recipes ? _self._recipes : recipes // ignore: cast_nullable_to_non_nullable
as List<RecipeEntity>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,dietaryFilters: null == dietaryFilters ? _self._dietaryFilters : dietaryFilters // ignore: cast_nullable_to_non_nullable
as List<DietaryPreference>,
  ));
}


}

/// @nodoc


class MyRecipesError with DiagnosticableTreeMixin implements MyRecipesState {
  const MyRecipesError(this.error);
  

 final  String error;

/// Create a copy of MyRecipesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyRecipesErrorCopyWith<MyRecipesError> get copyWith => _$MyRecipesErrorCopyWithImpl<MyRecipesError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MyRecipesState.errorMessage'))
    ..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyRecipesError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MyRecipesState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $MyRecipesErrorCopyWith<$Res> implements $MyRecipesStateCopyWith<$Res> {
  factory $MyRecipesErrorCopyWith(MyRecipesError value, $Res Function(MyRecipesError) _then) = _$MyRecipesErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$MyRecipesErrorCopyWithImpl<$Res>
    implements $MyRecipesErrorCopyWith<$Res> {
  _$MyRecipesErrorCopyWithImpl(this._self, this._then);

  final MyRecipesError _self;
  final $Res Function(MyRecipesError) _then;

/// Create a copy of MyRecipesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(MyRecipesError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
