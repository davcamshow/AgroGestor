import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/insumos_provider.dart';
import '../../widgets/kpi_card.dart';

class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesProvider);
    final dietasAsync = ref.watch(dietasProvider);
    final insumosAsync = ref.watch(insumosProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          backgroundColor: const Color(0xFF064e3b),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Lotes'),
              Tab(text: 'Insumos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // General Summary
            RefreshIndicator(
              onRefresh: () async {
                ref.refresh(lotesProvider);
                ref.refresh(dietasProvider);
                ref.refresh(insumosProvider);
              },
              child: lotesAsync.when(
                data: (lotes) => dietasAsync.when(
                  data: (dietas) => insumosAsync.when(
                    data: (insumos) {
                      final totalCost = dietas.fold<double>(
                        0,
                        (sum, d) {
                          final cost = double.tryParse(d.costoEstimadoKg) ?? 0;
                          return sum + cost;
                        },
                      );
                      final inventoryValue = insumos.fold<double>(0, (sum, i) {
                        final cantidad = double.tryParse(i.cantidadActualKg) ?? 0;
                        final costo = double.tryParse(i.costoKg) ?? 0;
                        return sum + (cantidad * costo);
                      });

                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              KpiCard(
                                title: 'Costo Total Diario',
                                value: '\$${totalCost.toStringAsFixed(2)}',
                                icon: Icons.trending_down,
                              ),
                              const SizedBox(height: 12),
                              KpiCard(
                                title: 'Capital en Inventario',
                                value: '\$${inventoryValue.toStringAsFixed(2)}',
                                icon: Icons.account_balance_wallet,
                              ),
                              const SizedBox(height: 12),
                              KpiCard(
                                title: 'Total Animales',
                                value: lotes.fold<int>(0, (sum, l) => sum + l.cantidadCabezas).toString(),
                                icon: Icons.groups,
                              ),
                              const SizedBox(height: 12),
                              KpiCard(
                                title: 'Dietas Activas',
                                value: dietas.where((d) => d.estado == 'activa').length.toString(),
                                icon: Icons.restaurant,
                              ),
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
            // Lotes Report
            lotesAsync.when(
              data: (lotes) => SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Cabezas')),
                    DataColumn(label: Text('Peso')),
                  ],
                  rows: lotes
                      .map(
                        (lote) => DataRow(cells: [
                          DataCell(Text(lote.nombre)),
                          DataCell(Text(lote.cantidadCabezas.toString())),
                          DataCell(Text('${lote.pesoPromedioActualKg} kg')),
                        ]),
                      )
                      .toList(),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
            // Insumos Report
            insumosAsync.when(
              data: (insumos) => SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Valor')),
                  ],
                  rows: insumos
                      .map(
                        (insumo) {
                          final cantidad = double.tryParse(insumo.cantidadActualKg) ?? 0;
                          final costo = double.tryParse(insumo.costoKg) ?? 0;
                          return DataRow(cells: [
                            DataCell(Text(insumo.nombre)),
                            DataCell(Text('${insumo.cantidadActualKg} kg')),
                            DataCell(Text('\$${(cantidad * costo).toStringAsFixed(2)}')),
                          ]);
                        },
                      )
                      .toList(),
                ),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
