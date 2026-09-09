// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_usage_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyUsageModel {

/// `yyyy-MM-dd` in the device's timezone, from [TrustedClock].
@HiveField(0) String get day;/// Shared recipes opened today, by feed id. A set rather than a count so
/// re-opening a recipe already paid for costs nothing.
@HiveField(1) List<String> get viewedSharedIds;/// AI extractions from a link started today.
@HiveField(2) int get aiExtractions;
/// Create a copy of DailyUsageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyUsageModelCopyWith<DailyUsageModel> get copyWith => _$DailyUsageModelCopyWithImpl<DailyUsageModel>(this as DailyUsageModel, _$identity);

  /// Serializes this DailyUsageModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyUsageModel&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other.viewedSharedIds, viewedSharedIds)&&(identical(other.aiExtractions, aiExtractions) || other.aiExtractions == aiExtractions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,const DeepCollectionEquality().hash(viewedSharedIds),aiExtractions);

@override
String toString() {
  return 'DailyUsageModel(day: $day, viewedSharedIds: $viewedSharedIds, aiExtractions: $aiExtractions)';
}


}

/// @nodoc
abstract mixin class $DailyUsageModelCopyWith<$Res>  {
  factory $DailyUsageModelCopyWith(DailyUsageModel value, $Res Function(DailyUsageModel) _then) = _$DailyUsageModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String day,@HiveField(1) List<String> viewedSharedIds,@HiveField(2) int aiExtractions
});




}
/// @nodoc
class _$DailyUsageModelCopyWithImpl<$Res>
    implements $DailyUsageModelCopyWith<$Res> {
  _$DailyUsageModelCopyWithImpl(this._self, this._then);

  final DailyUsageModel _self;
  final $Res Function(DailyUsageModel) _then;

/// Create a copy of DailyUsageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? day = null,Object? viewedSharedIds = null,Object? aiExtractions = null,}) {
  return _then(_self.copyWith(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,viewedSharedIds: null == viewedSharedIds ? _self.viewedSharedIds : viewedSharedIds // ignore: cast_nullable_to_non_nullable
as List<String>,aiExtractions: null == aiExtractions ? _self.aiExtractions : aiExtractions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyUsageModel].
extension DailyUsageModelPatterns on DailyUsageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyUsageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyUsageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyUsageModel value)  $default,){
final _that = this;
switch (_that) {
case _DailyUsageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyUsageModel value)?  $default,){
final _that = this;
switch (_that) {
case _DailyUsageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String day, @HiveField(1)  List<String> viewedSharedIds, @HiveField(2)  int aiExtractions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyUsageModel() when $default != null:
return $default(_that.day,_that.viewedSharedIds,_that.aiExtractions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String day, @HiveField(1)  List<String> viewedSharedIds, @HiveField(2)  int aiExtractions)  $default,) {final _that = this;
switch (_that) {
case _DailyUsageModel():
return $default(_that.day,_that.viewedSharedIds,_that.aiExtractions);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String day, @HiveField(1)  List<String> viewedSharedIds, @HiveField(2)  int aiExtractions)?  $default,) {final _that = this;
switch (_that) {
case _DailyUsageModel() when $default != null:
return $default(_that.day,_that.viewedSharedIds,_that.aiExtractions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyUsageModel extends DailyUsageModel {
  const _DailyUsageModel({@HiveField(0) required this.day, @HiveField(1) final  List<String> viewedSharedIds = const [], @HiveField(2) this.aiExtractions = 0}): _viewedSharedIds = viewedSharedIds,super._();
  factory _DailyUsageModel.fromJson(Map<String, dynamic> json) => _$DailyUsageModelFromJson(json);

/// `yyyy-MM-dd` in the device's timezone, from [TrustedClock].
@override@HiveField(0) final  String day;
/// Shared recipes opened today, by feed id. A set rather than a count so
/// re-opening a recipe already paid for costs nothing.
 final  List<String> _viewedSharedIds;
/// Shared recipes opened today, by feed id. A set rather than a count so
/// re-opening a recipe already paid for costs nothing.
@override@JsonKey()@HiveField(1) List<String> get viewedSharedIds {
  if (_viewedSharedIds is EqualUnmodifiableListView) return _viewedSharedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_viewedSharedIds);
}

/// AI extractions from a link started today.
@override@JsonKey()@HiveField(2) final  int aiExtractions;

/// Create a copy of DailyUsageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyUsageModelCopyWith<_DailyUsageModel> get copyWith => __$DailyUsageModelCopyWithImpl<_DailyUsageModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyUsageModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyUsageModel&&(identical(other.day, day) || other.day == day)&&const DeepCollectionEquality().equals(other._viewedSharedIds, _viewedSharedIds)&&(identical(other.aiExtractions, aiExtractions) || other.aiExtractions == aiExtractions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,day,const DeepCollectionEquality().hash(_viewedSharedIds),aiExtractions);

@override
String toString() {
  return 'DailyUsageModel(day: $day, viewedSharedIds: $viewedSharedIds, aiExtractions: $aiExtractions)';
}


}

/// @nodoc
abstract mixin class _$DailyUsageModelCopyWith<$Res> implements $DailyUsageModelCopyWith<$Res> {
  factory _$DailyUsageModelCopyWith(_DailyUsageModel value, $Res Function(_DailyUsageModel) _then) = __$DailyUsageModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String day,@HiveField(1) List<String> viewedSharedIds,@HiveField(2) int aiExtractions
});




}
/// @nodoc
class __$DailyUsageModelCopyWithImpl<$Res>
    implements _$DailyUsageModelCopyWith<$Res> {
  __$DailyUsageModelCopyWithImpl(this._self, this._then);

  final _DailyUsageModel _self;
  final $Res Function(_DailyUsageModel) _then;

/// Create a copy of DailyUsageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? day = null,Object? viewedSharedIds = null,Object? aiExtractions = null,}) {
  return _then(_DailyUsageModel(
day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as String,viewedSharedIds: null == viewedSharedIds ? _self._viewedSharedIds : viewedSharedIds // ignore: cast_nullable_to_non_nullable
as List<String>,aiExtractions: null == aiExtractions ? _self.aiExtractions : aiExtractions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
