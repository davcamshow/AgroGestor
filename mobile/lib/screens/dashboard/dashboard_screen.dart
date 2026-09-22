import 'dart:ui';
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
import '../../core/providers/lotes_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/registros_peso_provider.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/clima_ganado_card.dart';
import '../../core/providers/notificaciones_provider.dart';
import '../../widgets/animal_avatar.dart';

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
    final lotesAsync = ref.watch(lotesNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio', style: TextStyle(color: Colors.white)),
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.appBarTheme.backgroundColor
            : AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final noLeidasAsync = ref.watch(notificacionesNoLeidasProvider);
              final count = noLeidasAsync.valueOrNull ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white),
                    onPressed: () => context.push('/notificaciones'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppTheme.error, shape: BoxShape.circle),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
                    final gestantes =
                        ciclos.where((c) => c.estado == 'gestante').length;
                    final ahora = DateTime.now();
                    final proximos = eventos.where((e) {
                      if (e.proximaAplicacion == null) return false;
                      final dias =
                          e.proximaAplicacion!.difference(ahora).inDays;
                      return dias >= 0 && dias <= 60;
                    }).toList();

                    final totalLotes = lotesAsync.valueOrNull?.length ?? 0;

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
                              )
                                  .animate()
                                  .fadeIn(delay: 100.ms)
                                  .slideX(begin: 0.3),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: KpiCard(
                                title: 'Gestantes',
                                value: gestantes.toString(),
                                icon: Icons.favorite,
                                color: AppTheme.accent,
                              )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideX(begin: 0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _mostrarEventosProximosModal(
                                  context,
                                  proximos,
                                  animales,
                                ),
                                child: KpiCard(
                                  title: 'Eventos Próximos',
                                  value: proximos.length.toString(),
                                  icon: Icons.event,
                                  color: AppTheme.info,
                                )
                                    .animate()
                                    .fadeIn(delay: 300.ms)
                                    .slideX(begin: 0.3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.go('/lotes'),
                                child: KpiCard(
                                  title: 'Lotes',
                                  value: totalLotes.toString(),
                                  icon: Icons.group,
                                  color: AppTheme.warning,
                                )
                                    .animate()
                                    .fadeIn(delay: 400.ms)
                                    .slideX(begin: 0.3),
                              ),
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
            const ClimaGanadoCard(),
            const SizedBox(height: 24),
            animalesAsync.when(
              loading: () => Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
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
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppTheme.softShadow],
                    ),
                    child:
                        const Center(child: Text('Sin animales registrados')),
                  );
                }
                return Container(
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
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
                        Expanded(
                            child: _buildAnimalWeightChart(
                                _animalIdSeleccionado!)),
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
                children: List.generate(
                    3,
                    (_) => Container(
                          height: 70,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
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
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [AppTheme.softShadow],
                        ),
                        child: Row(
                          children: [
                            AnimalAvatar(animal: animal),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal.numeroArete,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    animal.raza ?? 'Sin raza',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
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
            const SizedBox(height: 24),
            Text(
              'Últimos Eventos',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 800.ms),
            const SizedBox(height: 12),
            eventosAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (eventos) {
                if (eventos.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppTheme.softShadow],
                    ),
                    child: const Center(
                      child: Text('Sin eventos registrados',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                final recientes = [...eventos]..sort(
                    (a, b) => b.fechaAplicacion.compareTo(a.fechaAplicacion));
                final ultimos = recientes.take(5).toList();
                return Column(
                  children: ultimos.map((evento) {
                    final animal = animalesAsync.valueOrNull
                        ?.where((a) => a.id == evento.animalId)
                        .firstOrNull;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppTheme.softShadow],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.info.withOpacity(0.15),
                            child: Icon(
                              _getTipoIcon(evento.tipo),
                              size: 18,
                              color: AppTheme.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getTipoLabel(evento.tipo)} - ${evento.producto}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text(
                                  animal?.numeroArete ??
                                      'Animal #${evento.animalId}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatearFecha(evento.fechaAplicacion),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
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
        color: Theme.of(context).cardTheme.color,
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

        final sorted = List.from(registros)
          ..sort((a, b) => a.fechaPesaje.compareTo(b.fechaPesaje));
        final spots = sorted.asMap().entries.map((e) {
          final peso = double.tryParse(e.value.pesoKg) ?? 0;
          return FlSpot(e.key.toDouble(), peso);
        }).toList();

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
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
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  void _mostrarEventosProximosModal(BuildContext context,
      List<EventoSanitario> eventos, List<Animal> animales) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Clave para permitir el blur
      barrierColor: Colors.black.withOpacity(0.35),
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surface.withOpacity(isDark ? 0.8 : 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tirador superior centrado
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Cabecera del modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: AppTheme.info,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Próximos Eventos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.onSurface.withOpacity(0.06),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                  ),
                  const SizedBox(height: 8),

                  // Lista de eventos
                  Flexible(
                    child: eventos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 48,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay eventos próximos',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: eventos.length,
                            itemBuilder: (context, index) {
                              final evento = eventos[index];
                              final animal = animales
                                  .where((a) => a.id == evento.animalId)
                                  .firstOrNull;

                              final diasRestantes =
                                  evento.proximaAplicacion != null
                                      ? evento.proximaAplicacion!
                                          .difference(DateTime.now())
                                          .inDays
                                      : null;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.04),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 4),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        AppTheme.info.withOpacity(0.15),
                                    child: Icon(_getTipoIcon(evento.tipo),
                                        color: AppTheme.info, size: 20),
                                  ),
                                  title: Text(
                                    animal?.numeroArete ??
                                        'Animal #${evento.animalId}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text(
                                          '${_getTipoLabel(evento.tipo)} - ${evento.producto}'),
                                      if (evento.proximaAplicacion != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Próxima: ${_formatearFecha(evento.proximaAplicacion!)}',
                                          style: const TextStyle(
                                            color: AppTheme.info,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: diasRestantes != null
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                AppTheme.info.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$diasRestantes días',
                                            style: const TextStyle(
                                              color: AppTheme.info,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
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
                ],
              ),
            ),
          ),
        );
      },
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
