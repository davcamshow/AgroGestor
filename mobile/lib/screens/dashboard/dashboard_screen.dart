import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/providers/eventos_sanitarios_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final ciclosAsync = ref.watch(ciclosNotifierProvider);
    final eventosAsync = ref.watch(eventosSanitariosNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            onPressed: () => context.go('/configuracion'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            animalesAsync.when(
              loading: () => Row(
                children: [
                  Expanded(child: _buildShimmerKpi()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildShimmerKpi()),
                ],
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (animales) => ciclosAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (ciclos) => eventosAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => Center(child: Text('Error: $err')),
                  data: (eventos) {
                    final totalAnimales = animales.length;
                    final gestantes = ciclos.where((c) => c.estado == 'gestante').length;
                    int proximos = 0;
                    for (final e in eventos) {
                      if (e.proximaAplicacion != null &&
                          e.proximaAplicacion!.isAfter(DateTime.now()) &&
                          e.proximaAplicacion!.isBefore(DateTime.now().add(const Duration(days: 30)))) {
                        proximos++;
                      }
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: KpiCard(
                                title: 'Animales',
                                value: totalAnimales.toString(),
                                icon: Icons.pets,
                                color: AppTheme.secondary,
                              ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.3),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: KpiCard(
                                title: 'Gestantes',
                                value: gestantes.toString(),
                                icon: Icons.favorite,
                                color: AppTheme.accent,
                              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: KpiCard(
                                title: 'Eventos Próximos',
                                value: proximos.toString(),
                                icon: Icons.event,
                                color: AppTheme.info,
                              ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: KpiCard(
                                title: 'Lotes',
                                value: '0',
                                icon: Icons.group,
                                color: AppTheme.warning,
                              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Peso Promedio',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppTheme.softShadow],
              ),
              child: _buildWeightChart(),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            const SizedBox(height: 24),
            Text(
              'Últimos Animales Registrados',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 12),
            animalesAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (animales) {
                if (animales.isEmpty) {
                  return const Center(child: Text('Sin animales registrados'));
                }
                final recientes = animales.take(5).toList();
                return Column(
                  children: recientes.map((animal) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppTheme.softShadow],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.secondary.withOpacity(0.2),
                            child: Text(
                              animal.numeroArete[0].toUpperCase(),
                              style: const TextStyle(color: AppTheme.secondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animal.numeroArete,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  animal.raza ?? 'Sin raza',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            animal.estado,
                            style: TextStyle(
                              color: animal.estado == 'activo'
                                  ? AppTheme.success
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX();
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerKpi() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildWeightChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 100),
              FlSpot(1, 115),
              FlSpot(2, 130),
              FlSpot(3, 145),
              FlSpot(4, 160),
            ],
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}