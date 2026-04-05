import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/providers/eventos_sanitarios_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class SaludScreen extends ConsumerWidget {
  const SaludScreen({super.key});

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return AppTheme.success;
      case 'desparasitacion':
        return AppTheme.warning;
      case 'tratamiento':
        return AppTheme.error;
      case 'cirugia':
        return AppTheme.info;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return Icons.vaccines_outlined;
      case 'desparasitacion':
        return Icons.bug_report_outlined;
      case 'tratamiento':
        return Icons.healing;
      case 'cirugia':
        return Icons.medical_services_outlined;
      default:
        return Icons.health_and_safety;
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return 'Vacunación';
      case 'desparasitacion':
        return 'Desparasitación';
      case 'tratamiento':
        return 'Tratamiento';
      case 'cirugia':
        return 'Cirugía';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventosAsync = ref.watch(eventosSanitariosNotifierProvider);
    final proximosAsync = ref.watch(eventosProximosProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salud'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Próximos'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Próximos eventos
            proximosAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, i) => LoadingShimmerListItem(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
              data: (proximos) {
                return proximos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Todo al día',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: proximos.length,
                        itemBuilder: (context, index) {
                          final evento = proximos[index];
                          final diasRestantes = evento.proximaAplicacion
                              ?.difference(DateTime.now())
                              .inDays ??
                              0;
                          final urgencia = diasRestantes < 7
                              ? 'Urgente'
                              : diasRestantes < 14
                                  ? 'Pronto'
                                  : 'Próximo';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getTipoColor(evento.tipo),
                                width: 2,
                              ),
                              boxShadow: [AppTheme.softShadow],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getTipoColor(evento.tipo)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getTipoIcon(evento.tipo),
                                  color: _getTipoColor(evento.tipo),
                                ),
                              ),
                              title: Text(
                                _getTipoLabel(evento.tipo),
                                style: Theme.of(context)
                                    .textTheme.titleMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      'Animal #${evento.animal} • ${evento.producto}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$diasRestantes días restantes',
                                    style: TextStyle(
                                      color: diasRestantes < 7
                                          ? AppTheme.error
                                          : AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(urgencia),
                                backgroundColor: diasRestantes < 7
                                    ? AppTheme.error.withOpacity(0.2)
                                    : AppTheme.warning.withOpacity(0.2),
                              ),
                            ),
                          ).animate().fadeIn().slideX();
                        },
                      );
              },
            ),
            // Tab 2: Historial
            eventosAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error: $err')),
              data: (eventos) {
                final historial = eventos
                    .where((e) => e.fechaAplicacion.isBefore(DateTime.now()))
                    .toList();
                historial.sort((a, b) =>
                    b.fechaAplicacion.compareTo(a.fechaAplicacion));

                return historial.isEmpty
                    ? Center(
                        child: Text('Sin historial',
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: historial.length,
                        itemBuilder: (context, index) {
                          final evento = historial[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                _getTipoIcon(evento.tipo),
                                color: _getTipoColor(evento.tipo),
                              ),
                              title: Text(
                                evento.producto,
                                style: Theme.of(context)
                                    .textTheme.labelLarge,
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      'Animal #${evento.animal}'),
                                  Text(DateFormat('dd/MM/yyyy')
                                      .format(evento.fechaAplicacion)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
