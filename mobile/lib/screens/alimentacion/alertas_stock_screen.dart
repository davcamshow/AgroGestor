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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.success;
    final warningColor = isDark ? AppTheme.darkWarning : AppTheme.warning;
    final errorColor = theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Inventario'),
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
                  Icon(Icons.check_circle, size: 64, color: successColor),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo en orden!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay insumos con stock bajo',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
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
              final actual =
                  double.tryParse(insumo.cantidadActualKg ?? '0') ?? 0;
              final minimo = double.tryParse(insumo.stockMinimoKg ?? '0') ?? 0;
              final porcentaje = minimo > 0 ? (actual / minimo * 100) : 0;

              final isCritical = porcentaje < 50;
              final statusColor = isCritical ? errorColor : warningColor;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.softShadowFor(theme.brightness)],
                  border: Border.all(
                    color: statusColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: statusColor),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${porcentaje.round()}%',
                            style: const TextStyle(
                              color: Colors
                                  .white, // Mantenemos texto blanco para buen contraste sobre error/warning
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (porcentaje / 100).clamp(0, 1),
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation(statusColor),
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
