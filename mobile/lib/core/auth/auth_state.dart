import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/usuario.dart';
import '../api/api_client.dart';
import 'auth_repository.dart';
import 'google_auth.dart';
import 'token_storage.dart';

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
  final GoogleAuthService _googleAuth;
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._repo, this._googleAuth, this._apiClient, this._tokenStorage) : super(AuthState.unknown()) {
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
      rethrow;
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
      // No hacer login automático - dejar que el usuario vaya al login
      // state sigue siendo unauthenticated
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState.unauthenticated();
  }

  Future<void> loginWithGoogle() async {
    try {
      final result = await _googleAuth.signInWithGoogle();
      
      if (result.user != null && result.user!.email != null && result.googleIdToken != null) {
        String? djangoAccessToken;
        
        try {
          final response = await _apiClient.dio.post(
            'auth/google/',
            data: {'id_token': result.googleIdToken},
          );
          final accessToken = response.data['access'] as String?;
          final refreshToken = response.data['refresh'] as String?;
          
          if (accessToken != null && refreshToken != null) {
            djangoAccessToken = accessToken;
            await _tokenStorage.saveTokens(accessToken, refreshToken);
          }
        } catch (e) {
          print('Error sincronizando con Django: $e');
        }
        
        // Intentar obtener perfil si tenemos token de Django
        if (djangoAccessToken != null) {
          try {
            final profile = await _repo.getProfile();
            state = AuthState.authenticated(profile);
            return;
          } catch (e) {
            print('Error obteniendo perfil: $e');
          }
        }
        
        // Si no tenemos token de Django, crear estado con usuario de Supabase
        // El usuario podrá usar la app pero necesitará configurar perfil después
        state = AuthState.authenticated(
          Usuario(
            id: 0,
            email: result.user!.email ?? '',
            nombre_completo: result.user!.userMetadata?['full_name'] ?? result.user!.email?.split('@')[0] ?? '',
          ),
        );
      }
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      rethrow;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(googleAuthProvider),
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  );
});
