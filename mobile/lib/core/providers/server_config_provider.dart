import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _key = 'server_url';

String get _defaultUrl => dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api/';

final serverUrlProvider = StateNotifierProvider<ServerUrlNotifier, String>((ref) {
  return ServerUrlNotifier();
});

class ServerUrlNotifier extends StateNotifier<String> {
  ServerUrlNotifier() : super(_defaultUrl) {
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> saveUrl(String url) async {
    if (url.isEmpty) return;

    String finalUrl = url;
    if (!finalUrl.endsWith('/')) finalUrl += '/';
    if (!finalUrl.endsWith('api/')) {
      finalUrl += 'api/';
    }

    await _storage.write(key: _key, value: finalUrl);
    state = finalUrl;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    state = _defaultUrl;
  }
}
