import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/usuario.dart';
import 'token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  return AuthRepository(apiClient, tokenStorage);
});

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<bool> hasStoredToken() async {
    return await _tokenStorage.hasTokens();
  }

  Future<Usuario> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        'auth/login/',
        data: {
          'username': email,
          'password': password,
        },
      );

      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

      await _tokenStorage.saveTokens(accessToken, refreshToken);

      return await getProfile();
    } catch (e) {
      throw Exception('Login failed: $e');
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
      await _apiClient.dio.post(
        'auth/register/',
        data: {
          'email': email,
          'password': password,
          'nombre_completo': nombreCompleto,
          'telefono': telefono ?? '',
          'rol_profesional': rolProfesional ?? '',
        },
      );
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<Usuario> getProfile() async {
    try {
      final response = await _apiClient.dio.get('auth/me/');
      return Usuario.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<void> updateProfile({
    String? nombreCompleto,
    String? telefono,
    String? rolProfesional,
    String? cedula,
    String? nombreRancho,
    String? direccionRancho,
    String? moneda,
    String? unidadPeso,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nombreCompleto != null) data['nombre_completo'] = nombreCompleto;
      if (telefono != null) data['telefono'] = telefono;
      if (rolProfesional != null) data['rol_profesional'] = rolProfesional;
      if (cedula != null) data['cedula'] = cedula;
      if (nombreRancho != null) data['nombre_rancho'] = nombreRancho;
      if (direccionRancho != null) data['direccion_rancho'] = direccionRancho;
      if (moneda != null) data['moneda'] = moneda;
      if (unidadPeso != null) data['unidad_peso'] = unidadPeso;

      await _apiClient.dio.patch('auth/me/', data: data);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }
}
