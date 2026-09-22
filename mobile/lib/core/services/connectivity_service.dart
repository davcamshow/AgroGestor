import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream reactivo de conectividad, para usar en widgets (ej. mostrar un
/// banner "Sin conexión").
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
});

/// Consulta puntual de conectividad, para usar fuera del árbol de widgets
/// (ej. dentro de repositorios/servicios).
///
/// Nota: requiere connectivity_plus ^6.0.0 (checkConnectivity() devuelve
/// List<ConnectivityResult>). Si tu pubspec.yaml usa una versión anterior,
/// cambia a `final result = await Connectivity().checkConnectivity(); return
/// result != ConnectivityResult.none;`.
Future<bool> isOnline() async {
  final results = await Connectivity().checkConnectivity();
  return !results.contains(ConnectivityResult.none);
}
