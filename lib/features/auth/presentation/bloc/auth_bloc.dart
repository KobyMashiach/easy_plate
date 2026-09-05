import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../domain/entities/app_user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/confirm_phone_code_usecase.dart';
import '../../domain/usecases/register_with_email_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/start_phone_verification_usecase.dart';

part 'auth_bloc.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.signInWithEmail(String email, String password) = _SignInWithEmail;
  const factory AuthEvent.registerWithEmail(String email, String password) = _RegisterWithEmail;
  const factory AuthEvent.signInWithGoogle() = _SignInWithGoogle;
  const factory AuthEvent.startPhoneVerification(String phoneNumber) = _StartPhoneVerification;
  const factory AuthEvent.confirmPhoneCode(String verificationId, String smsCode) =
      _ConfirmPhoneCode;
  const factory AuthEvent.sendPasswordReset(String email) = _SendPasswordReset;
  const factory AuthEvent.signOut() = _SignOut;
}

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.idle() = AuthIdle;
  const factory AuthState.loading() = AuthLoading;

  /// The SMS is out; the UI moves on to the code screen with this id.
  const factory AuthState.codeSent(String verificationId, String phoneNumber) = AuthCodeSent;

  /// Firebase accepted the credentials. Routing is driven by
  /// [AuthSessionService], so this only tells the screen to stop spinning.
  const factory AuthState.authenticated() = AuthAuthenticated;
  const factory AuthState.passwordResetSent() = AuthPasswordResetSent;
  const factory AuthState.errorMessage(String error) = AuthError;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmailUseCase signInWithEmailUseCase;
  final RegisterWithEmailUseCase registerWithEmailUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final StartPhoneVerificationUseCase startPhoneVerificationUseCase;
  final ConfirmPhoneCodeUseCase confirmPhoneCodeUseCase;
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final SignOutUseCase signOutUseCase;

  /// The account as Firebase currently sees it. Read after a link, where the
  /// stream has not fired but the user's identities have changed.
  final AuthRepository authRepository;

  AppUserEntity? get currentUser => authRepository.currentUser;

  AuthBloc({
    required this.authRepository,
    required this.signInWithEmailUseCase,
    required this.registerWithEmailUseCase,
    required this.signInWithGoogleUseCase,
    required this.startPhoneVerificationUseCase,
    required this.confirmPhoneCodeUseCase,
    required this.sendPasswordResetUseCase,
    required this.signOutUseCase,
  }) : super(const AuthState.idle()) {
    on<_SignInWithEmail>(_signInWithEmail);
    on<_RegisterWithEmail>(_registerWithEmail);
    on<_SignInWithGoogle>(_signInWithGoogle);
    on<_StartPhoneVerification>(_startPhoneVerification);
    on<_ConfirmPhoneCode>(_confirmPhoneCode);
    on<_SendPasswordReset>(_sendPasswordReset);
    on<_SignOut>(_signOut);
  }

  factory AuthBloc.fromContext(BuildContext context) {
    return AuthBloc(
      authRepository: context.read(),
      signInWithEmailUseCase: SignInWithEmailUseCase(context.read()),
      registerWithEmailUseCase: RegisterWithEmailUseCase(context.read()),
      signInWithGoogleUseCase: SignInWithGoogleUseCase(context.read()),
      startPhoneVerificationUseCase: StartPhoneVerificationUseCase(context.read()),
      confirmPhoneCodeUseCase: ConfirmPhoneCodeUseCase(context.read()),
      sendPasswordResetUseCase: SendPasswordResetUseCase(context.read()),
      signOutUseCase: SignOutUseCase(context.read()),
    );
  }

  /// Cancelling a Google or Apple sheet is a normal gesture, not a failure, so
  /// it returns the form to rest instead of showing an error.
  Future<void> _run(Emitter<AuthState> emit, Future<void> Function() action) async {
    emit(const AuthState.loading());
    try {
      await action();
    } on AppException catch (e) {
      debugPrint('Auth error: $e');
      // The Firebase code when there is one, else the error type — the screen
      // translates either.
      emit(e.type == AppErrorType.cancelled
          ? const AuthState.idle()
          : AuthState.errorMessage(e.message.isNotEmpty ? e.message : e.type.name));
    } catch (e) {
      debugPrint('Auth error: $e');
      emit(AuthState.errorMessage(e.toString()));
    }
  }

  Future<void> _signInWithEmail(_SignInWithEmail event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      await signInWithEmailUseCase(event.email, event.password);
      emit(const AuthState.authenticated());
    });
  }

  Future<void> _registerWithEmail(_RegisterWithEmail event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      await registerWithEmailUseCase(event.email, event.password);
      emit(const AuthState.authenticated());
    });
  }

  Future<void> _signInWithGoogle(_SignInWithGoogle event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      await signInWithGoogleUseCase();
      emit(const AuthState.authenticated());
    });
  }

  Future<void> _startPhoneVerification(_StartPhoneVerification event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      final verificationId = await startPhoneVerificationUseCase(event.phoneNumber);
      emit(AuthState.codeSent(verificationId, event.phoneNumber));
    });
  }

  Future<void> _confirmPhoneCode(_ConfirmPhoneCode event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      await confirmPhoneCodeUseCase(event.verificationId, event.smsCode);
      emit(const AuthState.authenticated());
    });
  }

  Future<void> _sendPasswordReset(_SendPasswordReset event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      await sendPasswordResetUseCase(event.email);
      emit(const AuthState.passwordResetSent());
    });
  }

  Future<void> _signOut(_SignOut event, Emitter<AuthState> emit) {
    return _run(emit, () async {
      await signOutUseCase();
      // The next account may not have finished onboarding on this device.
      await AuthSessionService().reloadPreferences();
      emit(const AuthState.idle());
    });
  }
}
