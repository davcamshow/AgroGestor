import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/insumos_provider.dart';
import '../../core/theme/app_theme.dart';

class AlertasStockScreen extends ConsumerStatefulWidget {
  const AlertasStockScreen({super.key});

  @override
  ConsumerState<AlertasStockScreen> createState() => _AlertasStockScreenState();
}

class _AlertasStockScreenState extends ConsumerState<AlertasStockScreen> {
  @override
  Widget build(BuildContext context) {
    final insumosAsync = ref.watch(insumosNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Inventario', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: insumosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (insumos) {
          final alertas = insumos.where((i) {
            final actual = double.tryParse(i.cantidadActualKg ?? '0') ?? 0;
            final minimo = double.tryParse(i.stockMinimoKg ?? '0') ?? 0;
            return actual < minimo;
          }).toList();

          if (alertas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo en orden!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No hay insumos con stock bajo',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alertas.length,
            itemBuilder: (context, index) {
              final insumo = alertas[index];
              final actual = double.tryParse(insumo.cantidadActualKg ?? '0') ?? 0;
              final minimo = double.tryParse(insumo.stockMinimoKg ?? '0') ?? 0;
              final porcentaje = minimo > 0 ? (actual / minimo * 100) : 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.softShadow],
                  border: Border.all(
                    color: porcentaje < 50 ? AppTheme.error : AppTheme.warning,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: porcentaje < 50 ? AppTheme.error : AppTheme.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insumo.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: porcentaje < 50 ? AppTheme.error : AppTheme.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${porcentaje.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (porcentaje / 100).clamp(0, 1),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        porcentaje < 50 ? AppTheme.error : AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Actual: ${actual.toStringAsFixed(1)} kg'),
                        Text('Mínimo: ${minimo.toStringAsFixed(1)} kg'),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}