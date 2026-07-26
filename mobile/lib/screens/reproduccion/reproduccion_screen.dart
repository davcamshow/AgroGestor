import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

class ReproduccionScreen extends ConsumerStatefulWidget {
  const ReproduccionScreen({super.key});

  @override
  ConsumerState<ReproduccionScreen> createState() => _ReproduccionScreenState();
}

class _ReproduccionScreenState extends ConsumerState<ReproduccionScreen> {
  final Set<int> _registrando = {};

  Future<void> _confirmarParto(int cicloId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Parto'),
        content: const Text('¿Confirmas que el parto ocurrió hoy? Se marcará como "Parió" y se registrará la fecha de parto real.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _registrando.add(cicloId));
    try {
      await ref.read(ciclosNotifierProvider.notifier).registrarParto(cicloId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parto registrado exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _registrando.remove(cicloId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ciclosAsync = ref.watch(ciclosNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reproducción', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.calculate, color: Colors.white),
              onPressed: () => context.push('/reproduccion/calculadora-ia'),
              tooltip: 'Calculadora de IA',
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onPressed: () => context.push('/reproduccion/temporadas'),
              tooltip: 'Panel de Temporadas',
            ),
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.white),
              onPressed: () => context.push('/reproduccion/kpis'),
              tooltip: 'KPIs Reproductivos',
            ),
            IconButton(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
              onPressed: () => context.go('/configuracion'),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Activos'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/reproduccion/ciclo/new'),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Gestaciones activas
            ciclosAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, i) => const LoadingShimmerListItem(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
              data: (ciclos) {
                final activos =
                    ciclos.where((c) => c.estado == 'gestante').toList();
                return activos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Sin gestaciones activas',
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activos.length,
                        itemBuilder: (context, index) {
                          final ciclo = activos[index];
                          final hoy = DateTime.now();
                          final diasRestantes = ciclo.fechaEstimadaParto != null
                              ? ciclo.fechaEstimadaParto!.difference(hoy).inDays
                              : 0;
                          final progreso = (283 - diasRestantes) / 283;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [AppTheme.softShadow],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push(
                                  '/animales/${ciclo.animal}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Animal #${ciclo.animal}',
                                        style: Theme.of(context)
                                            .textTheme.titleMedium),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: diasRestantes < 15
                                            ? AppTheme.error.withValues(alpha: 0.2)
                                            : diasRestantes < 30
                                                ? AppTheme.warning
                                                    .withValues(alpha: 0.2)
                                                : AppTheme.success
                                                    .withValues(alpha: 0.2),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$diasRestantes días',
                                        style: TextStyle(
                                          color: diasRestantes < 15
                                              ? AppTheme.error
                                              : diasRestantes < 30
                                                  ? AppTheme.warning
                                                  : AppTheme.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tipo: ${ciclo.tipoServicio == 'natural' ? 'Monta Natural' : 'Inseminación Artificial'}',
                                  style: Theme.of(context)
                                      .textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progreso.clamp(0, 1),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(
                                      diasRestantes < 15
                                          ? AppTheme.error
                                          : AppTheme.secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Parto estimado: ${ciclo.fechaEstimadaParto != null ? DateFormat('dd/MM/yyyy').format(ciclo.fechaEstimadaParto!) : 'N/A'}',
                                  style: Theme.of(context)
                                      .textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _registrando.contains(ciclo.id)
                                        ? null
                                        : () => _confirmarParto(ciclo.id),
                                    icon: _registrando.contains(ciclo.id)
                                        ? const SizedBox(
                                            width: 18, height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check_circle, size: 20),
                                    label: const Text('Listo — Registrar Parto'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                          ).animate().fadeIn().slideX();
                        },
                      );
              },
            ),
            // Tab 2: Historial
            ciclosAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error: $err')),
              data: (ciclos) {
                final historial = ciclos
                    .where((c) =>
                        c.estado != 'gestante' &&
                        c.estado != 'en_servicio')
                    .toList();
                return historial.isEmpty
                    ? Center(
                        child: Text('Sin historial',
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: historial.length,
                        itemBuilder: (context, index) {
                          final ciclo = historial[index];
                          final estadoColor = switch (ciclo.estado) {
                            'pario' => AppTheme.success,
                            'fallida' => AppTheme.error,
                            'descartada' => AppTheme.warning,
                            _ => Colors.grey,
                          };
                          final estadoLabel = switch (ciclo.estado) {
                            'pario' => 'Parió',
                            'fallida' => 'Fallida',
                            'descartada' => 'Descartada',
                            _ => ciclo.estado,
                          };
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [AppTheme.softShadow],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push(
                                  '/reproduccion/ciclo/${ciclo.id}/edit'),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Animal #${ciclo.animal}',
                                            style: Theme.of(context)
                                                .textTheme.titleSmall),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: estadoColor
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            estadoLabel,
                                            style: TextStyle(
                                              color: estadoColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Servicio: ${DateFormat('dd/MM/yyyy').format(ciclo.fechaServicio)}',
                                      style: Theme.of(context)
                                          .textTheme.bodySmall,
                                    ),
                                    if (ciclo.fechaPartoReal != null)
                                      Text(
                                        'Parto real: ${DateFormat('dd/MM/yyyy').format(ciclo.fechaPartoReal!)}',
                                        style: Theme.of(context)
                                            .textTheme.bodySmall,
                                      ),
                                    if (ciclo.fechaEstimadaParto != null)
                                      Text(
                                        'Parto estimado: ${DateFormat('dd/MM/yyyy').format(ciclo.fechaEstimadaParto!)}',
                                        style: Theme.of(context)
                                            .textTheme.bodySmall,
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.favorite_border,
                                            size: 14,
                                            color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Text(
                                          ciclo.tipoServicio == 'natural' ? 'Monta Natural' : 'Inseminación Artificial',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (ciclo.formato != null) ...[
                                          const SizedBox(width: 12),
                                          Icon(Icons.event,
                                              size: 14,
                                              color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            ciclo.formato == 'temporada'
                                                ? 'Temporada'
                                                : 'Continuo',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
