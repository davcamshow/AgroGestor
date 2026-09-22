import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/models/ciclo_reproductivo.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/blur_bottom_sheet.dart';

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
        content: const Text(
            '¿Confirmas que el parto ocurrió hoy? Se marcará como "Parió" y se registrará la fecha de parto real.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _registrando.add(cicloId));
    try {
      await ref.read(ciclosNotifierProvider.notifier).registrarParto(cicloId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Parto registrado exitosamente'),
              backgroundColor: Colors.green),
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

  void _mostrarDetalleCiclo(CicloReproductivo ciclo) {
    final theme = Theme.of(context);
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

    showBlurBottomSheet(
      context: context,
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.pets, color: estadoColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Animal #${ciclo.animal}',
                          style: theme.textTheme.titleLarge),
                      Text(estadoLabel,
                          style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            _detalleRow(
              'Tipo de servicio',
              ciclo.tipoServicio == 'natural'
                  ? 'Monta Natural'
                  : 'Inseminación Artificial',
            ),
            _detalleRow(
              'Fecha de servicio',
              DateFormat('dd/MM/yyyy').format(ciclo.fechaServicio),
            ),
            _detalleRow(
              'Fecha estimada de parto',
              ciclo.fechaEstimadaParto != null
                  ? DateFormat('dd/MM/yyyy')
                      .format(ciclo.fechaEstimadaParto!)
                  : '—',
            ),
            _detalleRow(
              'Fecha de parto real',
              ciclo.fechaPartoReal != null
                  ? DateFormat('dd/MM/yyyy')
                      .format(ciclo.fechaPartoReal!)
                  : '—',
            ),
            _detalleRow('Días de gestación', '${ciclo.diasGestacion}'),
            if (ciclo.formato != null && ciclo.formato!.isNotEmpty)
              _detalleRow('Formato', ciclo.formato!),
            if (ciclo.temporada != null && ciclo.temporada!.isNotEmpty)
              _detalleRow('Temporada', ciclo.temporada!),
            if (ciclo.notas != null && ciclo.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notas', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(ciclo.notas!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detalleRow(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ciclosAsync = ref.watch(ciclosNotifierProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title:
              const Text('Reproducción', style: TextStyle(color: Colors.white)),
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.appBarTheme.backgroundColor
              : AppTheme.primary,
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
                backgroundColor: theme.colorScheme.surfaceVariant,
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
                                size: 64,
                                color: theme.brightness == Brightness.dark
                                    ? AppTheme.darkTextSecondary
                                    : Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Sin gestaciones activas',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activos.length,
                        itemBuilder: (context, index) {
                          final ciclo = activos[index];
                          final hoy = DateTime.now();
                          final diasCalculados =
                              ciclo.fechaEstimadaParto != null
                                  ? ciclo.fechaEstimadaParto!
                                      .difference(hoy)
                                      .inDays
                                  : 0;
                          final diasRestantes = diasCalculados < 0
                              ? 0
                              : diasCalculados;
                          final progreso = (283 - diasRestantes) / 283;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                AppTheme.softShadowFor(theme.brightness)
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  context.push('/animales/${ciclo.animal}'),
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
                                                .textTheme
                                                .titleMedium),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: diasRestantes < 15
                                                ? AppTheme.error
                                                    .withValues(alpha: 0.2)
                                                : diasRestantes < 30
                                                    ? AppTheme.warning
                                                        .withValues(alpha: 0.2)
                                                    : AppTheme.success
                                                        .withOpacity(0.2),
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
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 12),
                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progreso.clamp(0, 1),
                                        minHeight: 8,
                                        backgroundColor: theme.dividerColor,
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
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton.icon(
                                        onPressed: _registrando
                                                .contains(ciclo.id)
                                            ? null
                                            : () => _confirmarParto(ciclo.id),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.success,
                                          foregroundColor: Colors.white,
                                          visualDensity:
                                              VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                        ),
                                        icon: _registrando
                                                .contains(ciclo.id)
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : const Icon(Icons.check_circle,
                                                size: 18),
                                        label: const Text(
                                            'Registrar Parto'),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (ciclos) {
                final historial = ciclos
                    .where((c) =>
                        c.estado != 'gestante' && c.estado != 'en_servicio')
                    .toList();
                return historial.isEmpty
                    ? Center(
                        child: Text('Sin historial',
                            style: Theme.of(context).textTheme.bodyMedium),
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
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? AppTheme.darkSurfaceVariant
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _mostrarDetalleCiclo(ciclo),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: ListTile(
                                  title: Text('Animal #${ciclo.animal}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  subtitle: Text(
                                    estadoLabel,
                                    style: TextStyle(
                                      color: estadoColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy')
                                            .format(ciclo.fechaServicio),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const Icon(Icons.chevron_right,
                                          size: 18,
                                          color: Colors.grey),
                                    ],
                                  ),
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
