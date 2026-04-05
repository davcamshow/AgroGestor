import 'package:dio/dio.dart';

class ServerDiscovery {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 1500),
    receiveTimeout: const Duration(milliseconds: 1500),
  ));

  /// Intenta detectar automáticamente el servidor en la red local
  static Future<String?> discoverServer() async {
    print('[DISCOVERY] Iniciando búsqueda del servidor...');

    // 1. Intentar con mDNS (bovion.local)
    final mDnsUrl = await _tryUrl('http://bovion.local:8000/api/health/');
    if (mDnsUrl != null) {
      print('[DISCOVERY] ✅ Encontrado en mDNS: bovion.local');
      return 'http://bovion.local:8000/api/';
    }

    // 2. Intentar con hostname.local
    final hostnameUrl = await _tryUrl('http://agrogestor.local:8000/api/health/');
    if (hostnameUrl != null) {
      print('[DISCOVERY] ✅ Encontrado hostname: agrogestor.local');
      return 'http://agrogestor.local:8000/api/';
    }

    // 3. Scan de red local (192.168.x.x y 10.0.x.x)
    final commonSubnets = [
      '192.168.1',
      '192.168.0',
      '192.168.101',
      '10.0.0',
    ];

    for (final subnet in commonSubnets) {
      print('[DISCOVERY] Escaneando $subnet.x...');
      final found = await _scanSubnet(subnet);
      if (found != null) {
        print('[DISCOVERY] ✅ Encontrado en: $found');
        return found;
      }
    }

    print('[DISCOVERY] ❌ Servidor no encontrado');
    return null;
  }

  /// Intenta conectar a una URL específica
  static Future<String?> _tryUrl(String url) async {
    try {
      print('[DISCOVERY] Intentando: $url');
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        return url;
      }
    } catch (e) {
      // Silenciosamente fallar
    }
    return null;
  }

  /// Escanea un subnet de red (ej: 192.168.1.x)
  static Future<String?> _scanSubnet(String subnet) async {
    // Escanear IPs aleatorias primero (más rápido que todas)
    final randomIps = [50, 100, 1, 254, 10, 200];

    for (final ip in randomIps) {
      final url = 'http://$subnet.$ip:8000/api/health/';
      final found = await _tryUrl(url);
      if (found != null) {
        return 'http://$subnet.$ip:8000/api/';
      }
    }

    return null;
  }
}
