import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/insumos_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';

class InsumosScreen extends ConsumerWidget {
  const InsumosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumosAsync = ref.watch(insumosNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insumos'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(insumosNotifierProvider);
        },
        child: insumosAsync.when(
          data: (insumos) {
            if (insumos.isEmpty) {
              return EmptyState(
                icon: Icons.inventory,
                title: 'Sin insumos',
                description: 'Agrega tu primer insumo',
              );
            }

            final criticalCount = insumos
                .where((i) {
                  final actual = double.tryParse(i.cantidadActualKg) ?? 0;
                  final minimo = double.tryParse(i.stockMinimoKg) ?? 0;
                  return actual <= minimo;
                })
                .length;

            final totalValue = insumos.fold<double>(0, (sum, insumo) {
              final cantidad = double.tryParse(insumo.cantidadActualKg) ?? 0;
              final costo = double.tryParse(insumo.costoKg) ?? 0;
              return sum + (cantidad * costo);
            });

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Insumos',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Text(
                                    insumos.length.toString(),
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Críticos',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.red,
                                        ),
                                  ),
                                  Text(
                                    criticalCount.toString(),
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          color: Colors.red,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor Total',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '\$${totalValue.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Insumos List
                    ...insumos.map((insumo) {
                      final actual = double.tryParse(insumo.cantidadActualKg) ?? 0;
                      final minimo = double.tryParse(insumo.stockMinimoKg) ?? 0;
                      final isCritical = actual <= minimo;

                      return Card(
                        color: isCritical ? Colors.red[50] : null,
                        child: ListTile(
                          title: Text(insumo.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Stock: ${insumo.cantidadActualKg} / ${insumo.stockMinimoKg} kg'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (actual / (minimo * 2)).clamp(0.0, 1.0),
                                minHeight: 6,
                              ),
                              const SizedBox(height: 4),
                              Text('\$${insumo.costoKg}/kg'),
                            ],
                          ),
                          trailing: StatusBadge(
                            status: isCritical ? 'Crítico' : 'Adecuado',
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
