import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Bovion', style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.headerGradient,
                ),
              ),
            ),
            backgroundColor: AppTheme.primary,
          ),
          // Contenido
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KPIs
                    animalesAsync.when(
                      loading: () => Row(
                        children: [
                          Expanded(child: _buildShimmerKpi()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildShimmerKpi()),
                        ],
                      ),
                      error: (err, _) => const SizedBox.shrink(),
                      data: (animales) => ciclosAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (err, _) => const SizedBox.shrink(),
                        data: (ciclos) => eventosAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (err, _) => const SizedBox.shrink(),
                          data: (eventos) {
                            final totalAnimales = animales.length;
                            final gestantes = ciclos
                                .where((c) => c.estado == 'gestante')
                                .length;
                            final eventosProximos = eventos
                                .where((e) =>
                                    e.proximaAplicacion != null &&
                                    e.proximaAplicacion!
                                        .isAfter(DateTime.now()) &&
                                    e.proximaAplicacion!.isBefore(
                                        DateTime.now()
                                            .add(const Duration(days: 30))))
                                .length;

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
                                KpiCard(
                                  title: 'Eventos Próximos',
                                  value: eventosProximos.toString(),
                                  subtitle: 'próximos 30 días',
                                  icon: Icons.health_and_safety,
                                  color: AppTheme.warning,
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms)
                                    .slideX(begin: 0.3),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Gráfico de peso por lote
                    Text(
                      'Últimos Pesajes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [AppTheme.softShadow],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _buildWeightChart(),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: 28),
                    // Próximos partos
                    ciclosAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                      data: (ciclos) {
                        final proximosPartos = ciclos
                            .where((c) =>
                                c.estado == 'gestante' &&
                                (c.diasRestantesParto ?? 0) < 30)
                            .toList();
                        return proximosPartos.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Partos Próximos',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  ...proximosPartos.take(3).map((ciclo) {
                                    final diasRestantes =
                                        ciclo.diasRestantesParto ?? 0;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: diasRestantes < 7
                                            ? AppTheme.error.withOpacity(0.1)
                                            : AppTheme.warning
                                                .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: diasRestantes < 7
                                              ? AppTheme.error
                                              : AppTheme.warning,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Animal #${ciclo.animal}',
                                                  style: Theme.of(context)
                                                      .textTheme.labelLarge,
                                                ),
                                                Text(
                                                  'Parto: ${DateFormat('dd/MM/yyyy').format(ciclo.fechaEstimadaParto ?? DateTime.now())}',
                                                  style: Theme.of(context)
                                                      .textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Chip(
                                            label: Text('$diasRestantes días'),
                                            backgroundColor: diasRestantes < 7
                                                ? AppTheme.error
                                                    .withOpacity(0.3)
                                                : AppTheme.warning
                                                    .withOpacity(0.3),
                                          ),
                                        ],
                                      ),
                                    )
                                        .animate()
                                        .fadeIn()
                                        .slideX();
                                  }).toList(),
                                ],
                              );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            spots: [
              const FlSpot(0, 100),
              const FlSpot(1, 115),
              const FlSpot(2, 130),
              const FlSpot(3, 145),
              const FlSpot(4, 160),
            ],
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.3),
                  AppTheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
