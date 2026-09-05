// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SignInWithEmail value)?  signInWithEmail,TResult Function( _RegisterWithEmail value)?  registerWithEmail,TResult Function( _SignInWithGoogle value)?  signInWithGoogle,TResult Function( _StartPhoneVerification value)?  startPhoneVerification,TResult Function( _ConfirmPhoneCode value)?  confirmPhoneCode,TResult Function( _SendPasswordReset value)?  sendPasswordReset,TResult Function( _SignOut value)?  signOut,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that);case _RegisterWithEmail() when registerWithEmail != null:
return registerWithEmail(_that);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle(_that);case _StartPhoneVerification() when startPhoneVerification != null:
return startPhoneVerification(_that);case _ConfirmPhoneCode() when confirmPhoneCode != null:
return confirmPhoneCode(_that);case _SendPasswordReset() when sendPasswordReset != null:
return sendPasswordReset(_that);case _SignOut() when signOut != null:
return signOut(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SignInWithEmail value)  signInWithEmail,required TResult Function( _RegisterWithEmail value)  registerWithEmail,required TResult Function( _SignInWithGoogle value)  signInWithGoogle,required TResult Function( _StartPhoneVerification value)  startPhoneVerification,required TResult Function( _ConfirmPhoneCode value)  confirmPhoneCode,required TResult Function( _SendPasswordReset value)  sendPasswordReset,required TResult Function( _SignOut value)  signOut,}){
final _that = this;
switch (_that) {
case _SignInWithEmail():
return signInWithEmail(_that);case _RegisterWithEmail():
return registerWithEmail(_that);case _SignInWithGoogle():
return signInWithGoogle(_that);case _StartPhoneVerification():
return startPhoneVerification(_that);case _ConfirmPhoneCode():
return confirmPhoneCode(_that);case _SendPasswordReset():
return sendPasswordReset(_that);case _SignOut():
return signOut(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SignInWithEmail value)?  signInWithEmail,TResult? Function( _RegisterWithEmail value)?  registerWithEmail,TResult? Function( _SignInWithGoogle value)?  signInWithGoogle,TResult? Function( _StartPhoneVerification value)?  startPhoneVerification,TResult? Function( _ConfirmPhoneCode value)?  confirmPhoneCode,TResult? Function( _SendPasswordReset value)?  sendPasswordReset,TResult? Function( _SignOut value)?  signOut,}){
final _that = this;
switch (_that) {
case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that);case _RegisterWithEmail() when registerWithEmail != null:
return registerWithEmail(_that);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle(_that);case _StartPhoneVerification() when startPhoneVerification != null:
return startPhoneVerification(_that);case _ConfirmPhoneCode() when confirmPhoneCode != null:
return confirmPhoneCode(_that);case _SendPasswordReset() when sendPasswordReset != null:
return sendPasswordReset(_that);case _SignOut() when signOut != null:
return signOut(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String email,  String password)?  signInWithEmail,TResult Function( String email,  String password)?  registerWithEmail,TResult Function()?  signInWithGoogle,TResult Function( String phoneNumber)?  startPhoneVerification,TResult Function( String verificationId,  String smsCode)?  confirmPhoneCode,TResult Function( String email)?  sendPasswordReset,TResult Function()?  signOut,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that.email,_that.password);case _RegisterWithEmail() when registerWithEmail != null:
return registerWithEmail(_that.email,_that.password);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle();case _StartPhoneVerification() when startPhoneVerification != null:
return startPhoneVerification(_that.phoneNumber);case _ConfirmPhoneCode() when confirmPhoneCode != null:
return confirmPhoneCode(_that.verificationId,_that.smsCode);case _SendPasswordReset() when sendPasswordReset != null:
return sendPasswordReset(_that.email);case _SignOut() when signOut != null:
return signOut();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String email,  String password)  signInWithEmail,required TResult Function( String email,  String password)  registerWithEmail,required TResult Function()  signInWithGoogle,required TResult Function( String phoneNumber)  startPhoneVerification,required TResult Function( String verificationId,  String smsCode)  confirmPhoneCode,required TResult Function( String email)  sendPasswordReset,required TResult Function()  signOut,}) {final _that = this;
switch (_that) {
case _SignInWithEmail():
return signInWithEmail(_that.email,_that.password);case _RegisterWithEmail():
return registerWithEmail(_that.email,_that.password);case _SignInWithGoogle():
return signInWithGoogle();case _StartPhoneVerification():
return startPhoneVerification(_that.phoneNumber);case _ConfirmPhoneCode():
return confirmPhoneCode(_that.verificationId,_that.smsCode);case _SendPasswordReset():
return sendPasswordReset(_that.email);case _SignOut():
return signOut();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String email,  String password)?  signInWithEmail,TResult? Function( String email,  String password)?  registerWithEmail,TResult? Function()?  signInWithGoogle,TResult? Function( String phoneNumber)?  startPhoneVerification,TResult? Function( String verificationId,  String smsCode)?  confirmPhoneCode,TResult? Function( String email)?  sendPasswordReset,TResult? Function()?  signOut,}) {final _that = this;
switch (_that) {
case _SignInWithEmail() when signInWithEmail != null:
return signInWithEmail(_that.email,_that.password);case _RegisterWithEmail() when registerWithEmail != null:
return registerWithEmail(_that.email,_that.password);case _SignInWithGoogle() when signInWithGoogle != null:
return signInWithGoogle();case _StartPhoneVerification() when startPhoneVerification != null:
return startPhoneVerification(_that.phoneNumber);case _ConfirmPhoneCode() when confirmPhoneCode != null:
return confirmPhoneCode(_that.verificationId,_that.smsCode);case _SendPasswordReset() when sendPasswordReset != null:
return sendPasswordReset(_that.email);case _SignOut() when signOut != null:
return signOut();case _:
  return null;

}
}

}

/// @nodoc


class _SignInWithEmail with DiagnosticableTreeMixin implements AuthEvent {
  const _SignInWithEmail(this.email, this.password);
  

 final  String email;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignInWithEmailCopyWith<_SignInWithEmail> get copyWith => __$SignInWithEmailCopyWithImpl<_SignInWithEmail>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.signInWithEmail'))
    ..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('password', password));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInWithEmail&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.signInWithEmail(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class _$SignInWithEmailCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$SignInWithEmailCopyWith(_SignInWithEmail value, $Res Function(_SignInWithEmail) _then) = __$SignInWithEmailCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class __$SignInWithEmailCopyWithImpl<$Res>
    implements _$SignInWithEmailCopyWith<$Res> {
  __$SignInWithEmailCopyWithImpl(this._self, this._then);

  final _SignInWithEmail _self;
  final $Res Function(_SignInWithEmail) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(_SignInWithEmail(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _RegisterWithEmail with DiagnosticableTreeMixin implements AuthEvent {
  const _RegisterWithEmail(this.email, this.password);
  

 final  String email;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterWithEmailCopyWith<_RegisterWithEmail> get copyWith => __$RegisterWithEmailCopyWithImpl<_RegisterWithEmail>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.registerWithEmail'))
    ..add(DiagnosticsProperty('email', email))..add(DiagnosticsProperty('password', password));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterWithEmail&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,email,password);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.registerWithEmail(email: $email, password: $password)';
}


}

/// @nodoc
abstract mixin class _$RegisterWithEmailCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$RegisterWithEmailCopyWith(_RegisterWithEmail value, $Res Function(_RegisterWithEmail) _then) = __$RegisterWithEmailCopyWithImpl;
@useResult
$Res call({
 String email, String password
});




}
/// @nodoc
class __$RegisterWithEmailCopyWithImpl<$Res>
    implements _$RegisterWithEmailCopyWith<$Res> {
  __$RegisterWithEmailCopyWithImpl(this._self, this._then);

  final _RegisterWithEmail _self;
  final $Res Function(_RegisterWithEmail) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,}) {
  return _then(_RegisterWithEmail(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SignInWithGoogle with DiagnosticableTreeMixin implements AuthEvent {
  const _SignInWithGoogle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.signInWithGoogle'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignInWithGoogle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.signInWithGoogle()';
}


}




/// @nodoc


class _StartPhoneVerification with DiagnosticableTreeMixin implements AuthEvent {
  const _StartPhoneVerification(this.phoneNumber);
  

 final  String phoneNumber;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartPhoneVerificationCopyWith<_StartPhoneVerification> get copyWith => __$StartPhoneVerificationCopyWithImpl<_StartPhoneVerification>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.startPhoneVerification'))
    ..add(DiagnosticsProperty('phoneNumber', phoneNumber));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartPhoneVerification&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}


@override
int get hashCode => Object.hash(runtimeType,phoneNumber);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.startPhoneVerification(phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class _$StartPhoneVerificationCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$StartPhoneVerificationCopyWith(_StartPhoneVerification value, $Res Function(_StartPhoneVerification) _then) = __$StartPhoneVerificationCopyWithImpl;
@useResult
$Res call({
 String phoneNumber
});




}
/// @nodoc
class __$StartPhoneVerificationCopyWithImpl<$Res>
    implements _$StartPhoneVerificationCopyWith<$Res> {
  __$StartPhoneVerificationCopyWithImpl(this._self, this._then);

  final _StartPhoneVerification _self;
  final $Res Function(_StartPhoneVerification) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phoneNumber = null,}) {
  return _then(_StartPhoneVerification(
null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ConfirmPhoneCode with DiagnosticableTreeMixin implements AuthEvent {
  const _ConfirmPhoneCode(this.verificationId, this.smsCode);
  

 final  String verificationId;
 final  String smsCode;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmPhoneCodeCopyWith<_ConfirmPhoneCode> get copyWith => __$ConfirmPhoneCodeCopyWithImpl<_ConfirmPhoneCode>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.confirmPhoneCode'))
    ..add(DiagnosticsProperty('verificationId', verificationId))..add(DiagnosticsProperty('smsCode', smsCode));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfirmPhoneCode&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.smsCode, smsCode) || other.smsCode == smsCode));
}


@override
int get hashCode => Object.hash(runtimeType,verificationId,smsCode);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.confirmPhoneCode(verificationId: $verificationId, smsCode: $smsCode)';
}


}

/// @nodoc
abstract mixin class _$ConfirmPhoneCodeCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$ConfirmPhoneCodeCopyWith(_ConfirmPhoneCode value, $Res Function(_ConfirmPhoneCode) _then) = __$ConfirmPhoneCodeCopyWithImpl;
@useResult
$Res call({
 String verificationId, String smsCode
});




}
/// @nodoc
class __$ConfirmPhoneCodeCopyWithImpl<$Res>
    implements _$ConfirmPhoneCodeCopyWith<$Res> {
  __$ConfirmPhoneCodeCopyWithImpl(this._self, this._then);

  final _ConfirmPhoneCode _self;
  final $Res Function(_ConfirmPhoneCode) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? verificationId = null,Object? smsCode = null,}) {
  return _then(_ConfirmPhoneCode(
null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,null == smsCode ? _self.smsCode : smsCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SendPasswordReset with DiagnosticableTreeMixin implements AuthEvent {
  const _SendPasswordReset(this.email);
  

 final  String email;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendPasswordResetCopyWith<_SendPasswordReset> get copyWith => __$SendPasswordResetCopyWithImpl<_SendPasswordReset>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.sendPasswordReset'))
    ..add(DiagnosticsProperty('email', email));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendPasswordReset&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.sendPasswordReset(email: $email)';
}


}

/// @nodoc
abstract mixin class _$SendPasswordResetCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory _$SendPasswordResetCopyWith(_SendPasswordReset value, $Res Function(_SendPasswordReset) _then) = __$SendPasswordResetCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class __$SendPasswordResetCopyWithImpl<$Res>
    implements _$SendPasswordResetCopyWith<$Res> {
  __$SendPasswordResetCopyWithImpl(this._self, this._then);

  final _SendPasswordReset _self;
  final $Res Function(_SendPasswordReset) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_SendPasswordReset(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SignOut with DiagnosticableTreeMixin implements AuthEvent {
  const _SignOut();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthEvent.signOut'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthEvent.signOut()';
}


}




/// @nodoc
mixin _$AuthState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthIdle value)?  idle,TResult Function( AuthLoading value)?  loading,TResult Function( AuthCodeSent value)?  codeSent,TResult Function( AuthAuthenticated value)?  authenticated,TResult Function( AuthPasswordResetSent value)?  passwordResetSent,TResult Function( AuthError value)?  errorMessage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthIdle() when idle != null:
return idle(_that);case AuthLoading() when loading != null:
return loading(_that);case AuthCodeSent() when codeSent != null:
return codeSent(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent(_that);case AuthError() when errorMessage != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthIdle value)  idle,required TResult Function( AuthLoading value)  loading,required TResult Function( AuthCodeSent value)  codeSent,required TResult Function( AuthAuthenticated value)  authenticated,required TResult Function( AuthPasswordResetSent value)  passwordResetSent,required TResult Function( AuthError value)  errorMessage,}){
final _that = this;
switch (_that) {
case AuthIdle():
return idle(_that);case AuthLoading():
return loading(_that);case AuthCodeSent():
return codeSent(_that);case AuthAuthenticated():
return authenticated(_that);case AuthPasswordResetSent():
return passwordResetSent(_that);case AuthError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthIdle value)?  idle,TResult? Function( AuthLoading value)?  loading,TResult? Function( AuthCodeSent value)?  codeSent,TResult? Function( AuthAuthenticated value)?  authenticated,TResult? Function( AuthPasswordResetSent value)?  passwordResetSent,TResult? Function( AuthError value)?  errorMessage,}){
final _that = this;
switch (_that) {
case AuthIdle() when idle != null:
return idle(_that);case AuthLoading() when loading != null:
return loading(_that);case AuthCodeSent() when codeSent != null:
return codeSent(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent(_that);case AuthError() when errorMessage != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  loading,TResult Function( String verificationId,  String phoneNumber)?  codeSent,TResult Function()?  authenticated,TResult Function()?  passwordResetSent,TResult Function( String error)?  errorMessage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthIdle() when idle != null:
return idle();case AuthLoading() when loading != null:
return loading();case AuthCodeSent() when codeSent != null:
return codeSent(_that.verificationId,_that.phoneNumber);case AuthAuthenticated() when authenticated != null:
return authenticated();case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent();case AuthError() when errorMessage != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  loading,required TResult Function( String verificationId,  String phoneNumber)  codeSent,required TResult Function()  authenticated,required TResult Function()  passwordResetSent,required TResult Function( String error)  errorMessage,}) {final _that = this;
switch (_that) {
case AuthIdle():
return idle();case AuthLoading():
return loading();case AuthCodeSent():
return codeSent(_that.verificationId,_that.phoneNumber);case AuthAuthenticated():
return authenticated();case AuthPasswordResetSent():
return passwordResetSent();case AuthError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  loading,TResult? Function( String verificationId,  String phoneNumber)?  codeSent,TResult? Function()?  authenticated,TResult? Function()?  passwordResetSent,TResult? Function( String error)?  errorMessage,}) {final _that = this;
switch (_that) {
case AuthIdle() when idle != null:
return idle();case AuthLoading() when loading != null:
return loading();case AuthCodeSent() when codeSent != null:
return codeSent(_that.verificationId,_that.phoneNumber);case AuthAuthenticated() when authenticated != null:
return authenticated();case AuthPasswordResetSent() when passwordResetSent != null:
return passwordResetSent();case AuthError() when errorMessage != null:
return errorMessage(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class AuthIdle with DiagnosticableTreeMixin implements AuthState {
  const AuthIdle();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState.idle'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState.idle()';
}


}




/// @nodoc


class AuthLoading with DiagnosticableTreeMixin implements AuthState {
  const AuthLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState.loading()';
}


}




/// @nodoc


class AuthCodeSent with DiagnosticableTreeMixin implements AuthState {
  const AuthCodeSent(this.verificationId, this.phoneNumber);
  

 final  String verificationId;
 final  String phoneNumber;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthCodeSentCopyWith<AuthCodeSent> get copyWith => _$AuthCodeSentCopyWithImpl<AuthCodeSent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState.codeSent'))
    ..add(DiagnosticsProperty('verificationId', verificationId))..add(DiagnosticsProperty('phoneNumber', phoneNumber));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthCodeSent&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}


@override
int get hashCode => Object.hash(runtimeType,verificationId,phoneNumber);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState.codeSent(verificationId: $verificationId, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $AuthCodeSentCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthCodeSentCopyWith(AuthCodeSent value, $Res Function(AuthCodeSent) _then) = _$AuthCodeSentCopyWithImpl;
@useResult
$Res call({
 String verificationId, String phoneNumber
});




}
/// @nodoc
class _$AuthCodeSentCopyWithImpl<$Res>
    implements $AuthCodeSentCopyWith<$Res> {
  _$AuthCodeSentCopyWithImpl(this._self, this._then);

  final AuthCodeSent _self;
  final $Res Function(AuthCodeSent) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? verificationId = null,Object? phoneNumber = null,}) {
  return _then(AuthCodeSent(
null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthAuthenticated with DiagnosticableTreeMixin implements AuthState {
  const AuthAuthenticated();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState.authenticated'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAuthenticated);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState.authenticated()';
}


}




/// @nodoc


class AuthPasswordResetSent with DiagnosticableTreeMixin implements AuthState {
  const AuthPasswordResetSent();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState.passwordResetSent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthPasswordResetSent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState.passwordResetSent()';
}


}




/// @nodoc


class AuthError with DiagnosticableTreeMixin implements AuthState {
  const AuthError(this.error);
  

 final  String error;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthErrorCopyWith<AuthError> get copyWith => _$AuthErrorCopyWithImpl<AuthError>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'AuthState.errorMessage'))
    ..add(DiagnosticsProperty('error', error));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthError&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'AuthState.errorMessage(error: $error)';
}


}

/// @nodoc
abstract mixin class $AuthErrorCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthErrorCopyWith(AuthError value, $Res Function(AuthError) _then) = _$AuthErrorCopyWithImpl;
@useResult
$Res call({
 String error
});




}
/// @nodoc
class _$AuthErrorCopyWithImpl<$Res>
    implements $AuthErrorCopyWith<$Res> {
  _$AuthErrorCopyWithImpl(this._self, this._then);

  final AuthError _self;
  final $Res Function(AuthError) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(AuthError(
null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
