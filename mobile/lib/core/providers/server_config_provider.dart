import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _key = 'server_url';

final serverUrlProvider = StateNotifierProvider<ServerUrlNotifier, String>((ref) {
  return ServerUrlNotifier();
});

class ServerUrlNotifier extends StateNotifier<String> {
  ServerUrlNotifier() : super('http://192.168.101.14:8000/api/') {
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> saveUrl(String url) async {
    // Validar que no esté vacío y tenga formato correcto
    if (url.isEmpty) return;

    // Asegurar que termine con /api/
    String finalUrl = url;
    if (!finalUrl.endsWith('/')) finalUrl += '/';
    if (!finalUrl.endsWith('api/')) {
      if (finalUrl.endsWith('api/')) {
        // Ya está bien
      } else {
        finalUrl += 'api/';
      }
    }

    await _storage.write(key: _key, value: finalUrl);
    state = finalUrl;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    state = 'http://192.168.101.14:8000/api/';
  }
}
