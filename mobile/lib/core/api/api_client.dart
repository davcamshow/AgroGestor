import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_storage.dart';

// ⚠️ CAMBIAR ESTA IP AL CONECTAR A DIFERENTE RED
//const String _baseUrl = 'http:// 192.168.0.8:8000/api/';
<<<<<<< HEAD
const String _baseUrl = 'http://192.168.0.8:8000';
=======
const String _baseUrl = 'http://192.168.0.111:8000/api/';
>>>>>>> 2eaa8b7094b2c2341f023c82526bd2f2bf97e24f

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return ApiClient(tokenStorage);
});

class ApiClient {
  late final Dio _dio;
  final TokenStorage _tokenStorage;
  bool _isRefreshing = false;

  ApiClient(this._tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_jwtInterceptor());
  }

  Interceptor _jwtInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth header for auth endpoints
        if (options.path.contains('/auth/')) {
          return handler.next(options);
        }

        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // 401 means access token expired — try to refresh
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await _tokenStorage.getRefreshToken();
            if (refreshToken == null) {
              // No refresh token — user must log in again
              await _tokenStorage.clearTokens();
              return handler.reject(error);
            }

            // Call Django's refresh endpoint
            final refreshResponse = await _dio.post(
              'auth/refresh/',
              data: {'refresh': refreshToken},
              options: Options(headers: {}),
            );

            final newAccessToken = refreshResponse.data['access'];
            final newRefreshToken = refreshResponse.data['refresh'];
            await _tokenStorage.saveTokens(newAccessToken, newRefreshToken);

            // Retry the original failed request with new token
            final retryOptions = error.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            // Refresh failed — force logout
            await _tokenStorage.clearTokens();
            return handler.reject(error);
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(error);
      },
    );
  }

  Dio get dio => _dio;

  Future<dynamic> get(String path) async {
    final response = await _dio.get(path);
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return response.data;
  }
}
