import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/clima_provider.dart';
import '../../core/theme/app_theme.dart';

class UbicacionRanchoScreen extends ConsumerStatefulWidget {
  const UbicacionRanchoScreen({super.key});
  @override
  ConsumerState<UbicacionRanchoScreen> createState() =>
      _UbicacionRanchoScreenState();
}

class _UbicacionRanchoScreenState extends ConsumerState<UbicacionRanchoScreen> {
  LatLng? _selected;
  bool _saving = false;

  Future<void> _save() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    try {
      final location = await ref
          .read(climaProvider.notifier)
          .saveLocation(_selected!.latitude, _selected!.longitude);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Ubicación guardada: ${location.direccion ?? 'coordenadas seleccionadas'}')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'No se pudo guardar la ubicación. Revisa tu conexión e intenta nuevamente.')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación del rancho')),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(23.6345, -102.5528),
                initialZoom: 4.8,
                onTap: (_, point) => setState(() => _selected = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bovion.app',
                  maxZoom: 19,
                ),
                if (_selected != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_pin,
                          color: AppTheme.error, size: 48),
                    ),
                  ]),
              ],
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                color: Colors.white.withValues(alpha: .85),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: const Text('© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10)),
              ),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _selected == null
                        ? 'Toca el mapa para marcar la ubicación del rancho.'
                        : 'Punto seleccionado: ${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}\nLa dirección aproximada se obtendrá al guardar.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _selected == null || _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Guardando...' : 'Guardar ubicación'),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }
}
