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
  const ClimaGanadoCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(climaProvider);
    return state.when(
      loading: () => const _LoadingCard(),
      error: (_, __) =>
          _ErrorCard(onRetry: () => ref.read(climaProvider.notifier).load()),
      data: (value) {
        if (value is ClimaSinUbicacion) {
          return const _NoLocationCard();
        }
        if (value is ClimaError) {
          return _ErrorCard(
              message: value.mensaje,
              onRetry: () => ref.read(climaProvider.notifier).load());
        }
        return _WeatherCard(
            clima: (value as ClimaDisponible).clima,
            onRefresh: () => ref.read(climaProvider.notifier).load());
      },
    );
  }
}

class _NoLocationCard extends StatelessWidget {
  const _NoLocationCard();
  @override
  Widget build(BuildContext context) => GradientCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.location_on_outlined, color: Colors.white, size: 30),
            SizedBox(width: 12),
            Expanded(
                child: Text('Clima del rancho',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)))
          ]),
          const SizedBox(height: 12),
          const Text(
              'Configura la ubicación de tu rancho para recibir información del clima y alertas preventivas.',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
              onPressed: () => context.push('/clima/ubicacion'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Establecer ubicación')),
        ]),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const GradientCard(
        child: SizedBox(
            height: 150,
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text('Consultando clima del rancho...',
                  style: TextStyle(color: Colors.white))
            ]))),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard(
      {this.message = 'No fue posible consultar el clima.',
      required this.onRetry});
  @override
  Widget build(BuildContext context) => GradientCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 10),
            Text('Clima del rancho',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar')),
        ]),
      );
}

class _WeatherCard extends StatelessWidget {
  final ClimaRancho clima;
  final VoidCallback onRefresh;
  const _WeatherCard({required this.clima, required this.onRefresh});

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Clima del rancho',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold))),
          IconButton(
              tooltip: 'Actualizar clima',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: Colors.white)),
          IconButton(
              tooltip: 'Cambiar ubicación',
              onPressed: () => context.push('/clima/ubicacion'),
              icon: const Icon(Icons.edit_location_alt_outlined,
                  color: Colors.white)),
        ]),
        Text(clima.ubicacion.direccion ?? 'Ubicación del rancho',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 16),
        Wrap(
            spacing: 18,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(_weatherIcon(current.codigoClima),
                  color: Colors.white, size: 46),
              Text(
                  current.temperatura == null
                      ? '--°'
                      : '${current.temperatura!.toStringAsFixed(1)}°',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w600)),
              _Metric(
                  label: 'Sensación',
                  value: current.sensacionTermica == null
                      ? '--'
                      : '${current.sensacionTermica!.toStringAsFixed(1)}°'),
              _Metric(
                  label: 'Humedad',
                  value:
                      current.humedad == null ? '--' : '${current.humedad}%'),
              _Metric(
                  label: 'Lluvia',
                  value: clima.pronostico.probabilidadLluviaMaxima == null
                      ? '--'
                      : '${clima.pronostico.probabilidadLluviaMaxima}%'),
              _Metric(
                  label: 'Viento',
                  value: current.viento == null
                      ? '--'
                      : '${current.viento!.toStringAsFixed(1)} km/h'),
            ]),
        const SizedBox(height: 10),
        Text(current.descripcion,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        const Divider(color: Colors.white30, height: 26),
        Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(status: clima.riesgo.nivel),
              Text(clima.riesgo.titulo,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))
            ]),
        const SizedBox(height: 8),
        Text(clima.riesgo.mensaje,
            style: const TextStyle(color: Colors.white70)),
        if (clima.riesgo.recomendaciones.isNotEmpty)
          TextButton.icon(
              onPressed: () => _showRecommendations(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('Ver recomendaciones')),
        if (clima.actualizadoEn != null)
          Text(
              'Actualizado ${DateFormat('dd/MM, HH:mm').format(clima.actualizadoEn!.toLocal())}',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600))
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
