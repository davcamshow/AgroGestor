import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/insumos_provider.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/empty_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesProvider);
    final dietasAsync = ref.watch(dietasProvider);
    final insumosAsync = ref.watch(insumosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(lotesProvider);
          ref.refresh(dietasProvider);
          ref.refresh(insumosProvider);
        },
        child: lotesAsync.when(
          data: (lotes) => dietasAsync.when(
            data: (dietas) => insumosAsync.when(
              data: (insumos) {
                // Calculate metrics
                final totalAnimals = lotes.fold<int>(
                  0,
                  (sum, lote) => sum + lote.cantidadCabezas,
                );
                final activeDiets = dietas.where((d) => d.estado == 'activa').length;
                final inventoryValue = insumos.fold<double>(0, (sum, insumo) {
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
                        KpiCard(
                          title: 'Total Animales',
                          value: totalAnimals.toString(),
                          icon: Icons.groups,
                        ),
                        const SizedBox(height: 12),
                        KpiCard(
                          title: 'Dietas Activas',
                          value: activeDiets.toString(),
                          icon: Icons.restaurant,
                        ),
                        const SizedBox(height: 12),
                        KpiCard(
                          title: 'Valor Inventario',
                          value: '\$${inventoryValue.toStringAsFixed(2)}',
                          icon: Icons.inventory,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Lotes Recientes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (lotes.isEmpty)
                          const EmptyState(
                            icon: Icons.groups,
                            title: 'Sin lotes',
                            description: 'Crea tu primer lote en la sección de Lotes',
                          )
                        else
                          ...lotes.take(3).map((lote) {
                            return Card(
                              child: ListTile(
                                title: Text(lote.nombre),
                                subtitle: Text('${lote.cantidadCabezas} cabezas'),
                                trailing: Text(lote.etapaProductiva),
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
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
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
