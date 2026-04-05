import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class ReproduccionScreen extends ConsumerWidget {
  const ReproduccionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ciclosAsync = ref.watch(ciclosNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reproducción'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Gestaciones activas
            ciclosAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, i) => LoadingShimmerListItem(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
              data: (ciclos) {
                final activos =
                    ciclos.where((c) => c.estado == 'gestante').toList();
                return activos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Sin gestaciones activas',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activos.length,
                        itemBuilder: (context, index) {
                          final ciclo = activos[index];
                          final diasRestantes = ciclo.diasRestantesParto ?? 0;
                          final progreso = (283 - diasRestantes) / 283;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [AppTheme.softShadow],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Animal #${ciclo.animal}',
                                        style: Theme.of(context)
                                            .textTheme.titleMedium),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: diasRestantes < 15
                                            ? AppTheme.error.withOpacity(0.2)
                                            : diasRestantes < 30
                                                ? AppTheme.warning
                                                    .withOpacity(0.2)
                                                : AppTheme.success
                                                    .withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$diasRestantes días',
                                        style: TextStyle(
                                          color: diasRestantes < 15
                                              ? AppTheme.error
                                              : diasRestantes < 30
                                                  ? AppTheme.warning
                                                  : AppTheme.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tipo: ${ciclo.tipoServicio == 'natural' ? 'Monta Natural' : 'Inseminación Artificial'}',
                                  style: Theme.of(context)
                                      .textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progreso.clamp(0, 1),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(
                                      diasRestantes < 15
                                          ? AppTheme.error
                                          : AppTheme.secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Parto estimado: ${ciclo.fechaEstimadaParto != null ? DateFormat('dd/MM/yyyy').format(ciclo.fechaEstimadaParto!) : 'N/A'}',
                                  style: Theme.of(context)
                                      .textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideX();
                        },
                      );
              },
            ),
            // Tab 2: Historial
            ciclosAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error: $err')),
              data: (ciclos) {
                final historial = ciclos
                    .where((c) =>
                        c.estado != 'gestante' &&
                        c.estado != 'en_servicio')
                    .toList();
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
                          final ciclo = historial[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: Text('Animal #${ciclo.animal}',
                                  style: Theme.of(context)
                                      .textTheme.labelLarge),
                              subtitle: Text(ciclo.estado),
                              trailing: Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(ciclo.fechaServicio),
                                style: Theme.of(context)
                                    .textTheme.bodySmall,
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
