import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/models/clima.dart';
import '../core/providers/clima_provider.dart';
import '../core/theme/app_theme.dart';
import 'gradient_card.dart';
import 'status_badge.dart';

class ClimaGanadoCard extends ConsumerWidget {
  /// Modo compacto: menos padding, tipografía e iconos más pequeños.
  final bool compact;

  const ClimaGanadoCard({this.compact = false, super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(climaProvider);
    return state.when(
      loading: () => _LoadingCard(compact: compact),
      error: (_, __) => _ErrorCard(
          compact: compact,
          onRetry: () => ref.read(climaProvider.notifier).load()),
      data: (value) {
        if (value is ClimaSinUbicacion) {
          return _NoLocationCard(compact: compact);
        }
        if (value is ClimaError) {
          return _ErrorCard(
              message: value.mensaje,
              compact: compact,
              onRetry: () => ref.read(climaProvider.notifier).load());
        }
        return _WeatherCard(
            clima: (value as ClimaDisponible).clima,
            compact: compact,
            onRefresh: () => ref.read(climaProvider.notifier).load());
      },
    );
  }
}

class _NoLocationCard extends StatelessWidget {
  final bool compact;
  const _NoLocationCard({this.compact = false});
  @override
  Widget build(BuildContext context) => GradientCard(
        padding: EdgeInsets.all(compact ? 14 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.location_on_outlined,
                color: Colors.white, size: compact ? 22 : 30),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
                child: Text('Clima del rancho',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.bold)))
          ]),
          SizedBox(height: compact ? 8 : 12),
          Text(
              'Configura la ubicación de tu rancho para recibir información del clima y alertas preventivas.',
              style: TextStyle(
                  color: Colors.white70, fontSize: compact ? 12 : 14)),
          SizedBox(height: compact ? 10 : 16),
          FilledButton.tonalIcon(
              onPressed: () => context.push('/clima/ubicacion'),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Establecer ubicación')),
        ]),
      );
}

class _LoadingCard extends StatelessWidget {
  final bool compact;
  const _LoadingCard({this.compact = false});
  @override
  Widget build(BuildContext context) => GradientCard(
        padding: EdgeInsets.all(compact ? 14 : 20),
        child: SizedBox(
            height: compact ? 90 : 150,
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 12),
              Text('Consultando clima del rancho...',
                  style: TextStyle(
                      color: Colors.white, fontSize: compact ? 12 : 14))
            ]))),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;
  const _ErrorCard(
      {this.message = 'No fue posible consultar el clima.',
      required this.onRetry,
      this.compact = false});
  @override
  Widget build(BuildContext context) => GradientCard(
        padding: EdgeInsets.all(compact ? 14 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.cloud_off, color: Colors.white, size: compact ? 20 : 24),
            SizedBox(width: 10),
            Text('Clima del rancho',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 15 : 18,
                    fontWeight: FontWeight.bold))
          ]),
          SizedBox(height: compact ? 8 : 12),
          Text(message,
              style: TextStyle(
                  color: Colors.white70, fontSize: compact ? 12 : 14)),
          SizedBox(height: compact ? 10 : 12),
          FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar')),
        ]),
      );
}

class _WeatherCard extends StatelessWidget {
  final ClimaRancho clima;
  final VoidCallback onRefresh;
  final bool compact;
  const _WeatherCard(
      {required this.clima, required this.onRefresh, this.compact = false});

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clima.riesgo.titulo,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...clima.riesgo.recomendaciones.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 18, color: AppTheme.secondary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item))
                            ]))),
                    if (clima.riesgo.advertencia != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(clima.riesgo.advertencia!,
                              style: Theme.of(context).textTheme.bodySmall)),
                  ]),
            )));
  }

  @override
  Widget build(BuildContext context) {
    final current = clima.actual;
    return GradientCard(
      gradient: const LinearGradient(
          colors: [Color(0xFF256D85), Color(0xFF47B5A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Clima del rancho',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 15 : 18,
                      fontWeight: FontWeight.bold))),
          IconButton(
              tooltip: 'Actualizar clima',
              onPressed: onRefresh,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.refresh,
                  color: Colors.white, size: compact ? 18 : 24)),
          IconButton(
              tooltip: 'Cambiar ubicación',
              onPressed: () => context.push('/clima/ubicacion'),
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_location_alt_outlined,
                  color: Colors.white, size: compact ? 18 : 24)),
        ]),
        Text(clima.ubicacion.direccion ?? 'Ubicación del rancho',
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style:
                TextStyle(color: Colors.white70, fontSize: compact ? 11 : 14)),
        SizedBox(height: compact ? 10 : 16),
        Wrap(
            spacing: compact ? 12 : 18,
            runSpacing: compact ? 8 : 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(_weatherIcon(current.codigoClima),
                  color: Colors.white, size: compact ? 28 : 46),
              Text(
                  current.temperatura == null
                      ? '--°'
                      : '${current.temperatura!.toStringAsFixed(1)}°',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 24 : 38,
                      fontWeight: FontWeight.w600)),
              _Metric(
                  label: 'Sensación',
                  compact: compact,
                  value: current.sensacionTermica == null
                      ? '--'
                      : '${current.sensacionTermica!.toStringAsFixed(1)}°'),
              _Metric(
                  label: 'Humedad',
                  compact: compact,
                  value:
                      current.humedad == null ? '--' : '${current.humedad}%'),
              _Metric(
                  label: 'Lluvia',
                  compact: compact,
                  value: clima.pronostico.probabilidadLluviaMaxima == null
                      ? '--'
                      : '${clima.pronostico.probabilidadLluviaMaxima}%'),
              _Metric(
                  label: 'Viento',
                  compact: compact,
                  value: current.viento == null
                      ? '--'
                      : '${current.viento!.toStringAsFixed(1)} km/h'),
            ]),
        SizedBox(height: compact ? 8 : 10),
        Text(current.descripcion,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: compact ? 12 : 14)),
        Divider(color: Colors.white30, height: compact ? 18 : 26),
        Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(status: clima.riesgo.nivel),
              Text(clima.riesgo.titulo,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 12 : 14))
            ]),
        SizedBox(height: compact ? 4 : 8),
        Text(clima.riesgo.mensaje,
            style:
                TextStyle(color: Colors.white70, fontSize: compact ? 11 : 14)),
        if (clima.riesgo.recomendaciones.isNotEmpty)
          TextButton.icon(
              onPressed: () => _showRecommendations(context),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.health_and_safety_outlined, size: 18),
              label: Text('Ver recomendaciones',
                  style: TextStyle(fontSize: compact ? 11 : 14))),
        if (clima.actualizadoEn != null)
          Text(
              'Actualizado ${DateFormat('dd/MM, HH:mm').format(clima.actualizadoEn!.toLocal())}',
              style: TextStyle(
                  color: Colors.white60, fontSize: compact ? 10 : 11)),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;
  const _Metric(
      {required this.label, required this.value, this.compact = false});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                TextStyle(color: Colors.white60, fontSize: compact ? 9 : 11)),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 14))
      ]);
}

IconData _weatherIcon(int? code) {
  if (code == 0 || code == 1) return Icons.wb_sunny_outlined;
  if (code == 2 || code == 3) return Icons.cloud_outlined;
  if (code == 45 || code == 48) return Icons.foggy;
  if (code != null &&
      ((code >= 51 && code <= 65) || (code >= 80 && code <= 82))) {
    return Icons.water_drop_outlined;
  }
  if (code != null && code >= 95) return Icons.thunderstorm_outlined;
  if (code != null && code >= 71 && code <= 75) return Icons.ac_unit;
  return Icons.cloud_queue;
}
