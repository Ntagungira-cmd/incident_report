import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/app_user.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class SignInRequested extends AuthEvent {
  const SignInRequested(this.email, this.password);
  final String email;
  final String password;
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.department,
    required this.location,
  });
  final String name;
  final String email;
  final String password;
  final String department;
  final String location;
}

final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy = false,
    this.error,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool busy;
  final String? error;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthStarted>(
      (event, emit) => emit.forEach<AppUser?>(
        _repo.userChanges(),
        onData: (user) => user == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, user: user),
        onError: (e, _) =>
            AuthState(status: AuthStatus.unauthenticated, error: _message(e)),
      ),
    );
    on<SignInRequested>(
      (e, emit) => _run(emit, () => _repo.signIn(e.email, e.password)),
    );
    on<RegisterRequested>(
      (e, emit) => _run(
        emit,
        () => _repo.register(
          name: e.name,
          email: e.email,
          password: e.password,
          department: e.department,
          location: e.location,
        ),
      ),
    );
    on<SignOutRequested>((_, _) => _repo.signOut());
  }

  final AuthRepository _repo;

  Future<void> _run(
    Emitter<AuthState> emit,
    Future<void> Function() action,
  ) async {
    emit(AuthState(status: state.status, user: state.user, busy: true));
    try {
      await action();
      emit(AuthState(status: state.status, user: state.user));
    } catch (e) {
      emit(
        AuthState(status: state.status, user: state.user, error: _message(e)),
      );
    }
  }

  static String _message(Object e) => e is FirebaseException
      ? (e.message ?? e.code)
      : 'Something went wrong. Please try again.';
}
