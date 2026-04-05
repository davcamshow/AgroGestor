import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/registros_peso_provider.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class ReportesScreen extends ConsumerWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrosAsync = ref.watch(registrosPesoNotifierProvider);
    final animalesAsync = ref.watch(animalesNotifierProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Crecimiento'),
              Tab(text: 'Distribución'),
              Tab(text: 'Análisis'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Curva de crecimiento
            registrosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (registros) {
                if (registros.isEmpty) {
                  return const Center(child: Text('Sin datos de pesaje'));
                }
                registros.sort((a, b) =>
                    a.fechaPesaje.compareTo(b.fechaPesaje));

                final spots = registros
                    .asMap()
                    .entries
                    .map((e) => FlSpot(
                          e.key.toDouble(),
                          double.tryParse(e.value.pesoKg) ?? 0,
                        ))
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Curva de Crecimiento',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.softShadow],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) =>
                                      Text(value.toInt().toString(),
                                          style: const TextStyle(
                                              fontSize: 10)),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) =>
                                      Text(value.toInt().toString(),
                                          style: const TextStyle(
                                              fontSize: 10)),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.secondary,
                                  ],
                                ),
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primary.withOpacity(0.3),
                                      AppTheme.secondary.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .slideY(begin: 0.3),
                    ],
                  ),
                );
              },
            ),
            // Tab 2: Distribución por tipo
            animalesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (animales) {
                final maches =
                    animales.where((a) => a.sexo == 'M').length;
                final hembras =
                    animales.where((a) => a.sexo == 'H').length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Distribución por Sexo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [AppTheme.softShadow],
                        ),
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: maches.toDouble(),
                                title: 'Machos\n$maches',
                                color: AppTheme.primary,
                                radius: 100,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              PieChartSectionData(
                                value: hembras.toDouble(),
                                title: 'Hembras\n$hembras',
                                color: AppTheme.secondary,
                                radius: 100,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .scale(),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(
                                'Machos', maches.toString(), AppTheme.primary),
                            const SizedBox(height: 12),
                            _buildLegendItem('Hembras', hembras.toString(),
                                AppTheme.secondary),
                            const SizedBox(height: 12),
                            _buildLegendItem('Total',
                                animales.length.toString(), AppTheme.accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Tab 3: Análisis
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de Rebaño',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  animalesAsync.when(
                    loading: () =>
                        const CircularProgressIndicator(),
                    error: (err, _) =>
                        Center(child: Text('Error: $err')),
                    data: (animales) {
                      final activos = animales
                          .where((a) => a.estado == 'activo')
                          .length;
                      final vendidos = animales
                          .where((a) => a.estado == 'vendido')
                          .length;
                      final muertos = animales
                          .where((a) => a.estado == 'muerto')
                          .length;

                      return Column(
                        children: [
                          _buildStatCard(
                            'Animales Activos',
                            activos.toString(),
                            Icons.pets,
                            AppTheme.success,
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Vendidos',
                            vendidos.toString(),
                            Icons.sell,
                            AppTheme.warning,
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Muertos',
                            muertos.toString(),
                            Icons.close,
                            AppTheme.error,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
