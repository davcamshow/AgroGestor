import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/evento_sanitario.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/providers/eventos_sanitarios_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/registros_peso_provider.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int? _animalIdSeleccionado;

  @override
  Widget build(BuildContext context) {
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
                    print('DEBUG: Total eventos: ${eventos.length}');
                    final ahora = DateTime.now();
                    final proximos = eventos
                        .where((e) {
                          if (e.proximaAplicacion == null) return false;
                          final dias = e.proximaAplicacion!.difference(ahora).inDays;
                          print('DEBUG evento: ${e.producto}, proxima: ${e.proximaAplicacion}, dias: $dias');
                          return dias >= 0 && dias <= 60;
                        })
                        .toList();
                    print('DEBUG: Eventos proximos: ${proximos.length}');

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
                              child: GestureDetector(
                                onTap: () => _mostrarEventosProximosModal(context, proximos, animales),
                                child: KpiCard(
                                  title: 'Eventos Próximos',
                                  value: proximos.length.toString(),
                                  icon: Icons.event,
                                  color: AppTheme.info,
                                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3),
                              ),
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
            animalesAsync.when(
              loading: () => Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (animales) {
                if (animales.isEmpty) {
                  return Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppTheme.softShadow],
                    ),
                    child: const Center(child: Text('Sin animales registrados')),
                  );
                }
                return Container(
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [AppTheme.softShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Evolución de Peso',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _animalIdSeleccionado,
                            hint: const Text('Seleccionar'),
                            underline: const SizedBox(),
                            items: animales.map((animal) {
                              return DropdownMenuItem<int>(
                                value: animal.id,
                                child: Text(
                                  animal.numeroArete,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (id) {
                              setState(() => _animalIdSeleccionado = id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_animalIdSeleccionado != null)
                        Expanded(child: _buildAnimalWeightChart(_animalIdSeleccionado!)),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Últimos Animales Registrados',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 12),
            animalesAsync.when(
              loading: () => Column(
                children: List.generate(3, (_) => Container(
                  height: 70,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (animales) {
                if (animales.isEmpty) {
                  return const Center(child: Text('Sin animales registrados'));
                }
                final recientes = animales.take(5).toList();
                return Column(
                  children: recientes.map((animal) {
                    return GestureDetector(
                      onTap: () => context.go('/animales/${animal.id}'),
                      child: Container(
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

  Widget _buildAnimalWeightChart(int animalId) {
    ref.watch(animalesNotifierProvider);
    final registrosAsync = ref.watch(registrosPesoAnimalProvider(animalId));

    return registrosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (registros) {
        if (registros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.scale, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Sin pesajes registrados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega pesajes desde el detalle del animal',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final sorted = List.from(registros)..sort((a, b) => a.fechaPesaje.compareTo(b.fechaPesaje));
        final spots = sorted.asMap().entries.map((e) {
          final peso = double.tryParse(e.value.pesoKg) ?? 0;
          return FlSpot(e.key.toDouble(), peso);
        }).toList();

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < sorted.length) {
                      final fecha = sorted[idx].fechaPesaje;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${fecha.day}/${fecha.month}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()} kg',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primary.withOpacity(0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarEventosProximosModal(BuildContext context, List<EventoSanitario> eventos, List<Animal> animales) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eventos Próximos'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: eventos.isEmpty
              ? const Center(child: Text('No hay eventos próximos'))
              : ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    final animal = animales.where((a) => a.id == evento.animalId).firstOrNull;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.info.withOpacity(0.2),
                          child: Icon(_getTipoIcon(evento.tipo), color: AppTheme.info),
                        ),
                        title: Text(animal?.numeroArete ?? 'Animal #${evento.animalId}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_getTipoLabel(evento.tipo)} - ${evento.producto}'),
                            if (evento.proximaAplicacion != null)
                              Text(
                                'Próxima: ${_formatearFecha(evento.proximaAplicacion!)}',
                                style: TextStyle(
                                  color: AppTheme.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        trailing: evento.proximaAplicacion != null
                            ? Chip(
                                label: Text(
                                  '${evento.proximaAplicacion!.difference(DateTime.now()).inDays} días',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: AppTheme.info.withOpacity(0.2),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          if (animal != null) {
                            context.go('/animales/${animal.id}');
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return Icons.vaccines;
      case 'desparasitacion':
        return Icons.medication;
      case 'tratamiento':
        return Icons.healing;
      case 'cirugia':
        return Icons.medical_services;
      default:
        return Icons.event;
    }
  }

  String _getTipoLabel(String tipo) {
    switch (tipo) {
      case 'vacunacion':
        return 'Vacunación';
      case 'desparasitacion':
        return 'Desparasitación';
      case 'tratamiento':
        return 'Tratamiento';
      case 'cirugia':
        return 'Cirugía';
      default:
        return tipo;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
