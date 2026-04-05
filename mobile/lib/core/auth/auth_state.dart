import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final Usuario? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.unknown() =>
      const AuthState(status: AuthStatus.unknown);

  factory AuthState.authenticated(Usuario user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated([String? error]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState.unknown()) {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final hasToken = await _repo.hasStoredToken();
    if (hasToken) {
      try {
        final user = await _repo.getProfile();
        state = AuthState.authenticated(user);
      } catch (_) {
        state = AuthState.unauthenticated();
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await _repo.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nombreCompleto,
    String? telefono,
    String? rolProfesional,
  }) async {
    try {
      await _repo.register(
        email: email,
        password: password,
        nombreCompleto: nombreCompleto,
        telefono: telefono,
        rolProfesional: rolProfesional,
      );
      await login(email, password);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
