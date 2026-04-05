import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/providers/insumos_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class AlimentacionScreen extends ConsumerWidget {
  const AlimentacionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietasAsync = ref.watch(dietasProvider);
    final lotesAsync = ref.watch(lotesNotifierProvider);
    final insumosAsync = ref.watch(insumosNotifierProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alimentación'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dietas'),
              Tab(text: 'Lotes'),
              Tab(text: 'Insumos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Dietas
            dietasAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, i) => LoadingShimmerListItem(),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (dietas) {
                final activas =
                    dietas.where((d) => d.estado == 'activa').toList();
                return activas.isEmpty
                    ? const Center(child: Text('Sin dietas activas'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activas.length,
                        itemBuilder: (context, index) {
                          final dieta = activas[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.secondary,
                                width: 2,
                              ),
                              boxShadow: [AppTheme.softShadow],
                            ),
                            child: ListTile(
                              title: Text(dieta.nombre),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      'Objetivo: ${dieta.objetivo}'),
                                  Text(
                                      'Costo: ${dieta.costoEstimadoKg}/kg'),
                                ],
                              ),
                              trailing: Icon(Icons.check_circle,
                                  color: AppTheme.success),
                            ),
                          )
                              .animate()
                              .fadeIn()
                              .slideX();
                        },
                      );
              },
            ),
            // Tab 2: Lotes
            lotesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error: $err')),
              data: (lotes) {
                return lotes.isEmpty
                    ? const Center(child: Text('Sin lotes'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lotes.length,
                        itemBuilder: (context, index) {
                          final lote = lotes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(lote.nombre,
                                    style: Theme.of(context)
                                        .textTheme.labelLarge),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(
                                      '${lote.cantidadCabezas} cabezas',
                                      style: Theme.of(context)
                                          .textTheme.bodySmall,
                                    ),
                                    Chip(
                                      label: Text(lote.estado),
                                      backgroundColor: AppTheme.primary
                                          .withOpacity(0.2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
              },
            ),
            // Tab 3: Insumos
            insumosAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error: $err')),
              data: (insumos) {
                return insumos.isEmpty
                    ? const Center(child: Text('Sin insumos'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: insumos.length,
                        itemBuilder: (context, index) {
                          final insumo = insumos[index];
                          final actual =
                              double.tryParse(insumo.cantidadActualKg) ?? 0;
                          final minimo =
                              double.tryParse(insumo.stockMinimoKg) ?? 0;
                          final alerta = actual < minimo;
                          final progreso = (minimo > 0
                              ? (actual / minimo).clamp(0.0, 1.0)
                              : 1.0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: alerta
                                  ? AppTheme.error.withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: alerta
                                    ? AppTheme.error
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    Text(insumo.nombre,
                                        style: Theme.of(context)
                                            .textTheme.labelLarge),
                                    if (alerta)
                                      Chip(
                                        label: const Text('Bajo stock'),
                                        backgroundColor: AppTheme.error
                                            .withOpacity(0.3),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child:
                                      LinearProgressIndicator(
                                    value: progreso,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(
                                      alerta
                                          ? AppTheme.error
                                          : AppTheme.success,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${actual.toStringAsFixed(1)}/${minimo.toStringAsFixed(1)} kg',
                                  style: Theme.of(context)
                                      .textTheme.bodySmall,
                                ),
                              ],
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
