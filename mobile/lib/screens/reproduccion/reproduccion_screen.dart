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
    final confirm = await showBlurConfirmSheet(
      context: context,
      title: 'Registrar Parto',
      message:
          '¿Confirmas que el parto ocurrió hoy? Se marcará como "Parió" y se registrará la fecha de parto real.',
      confirmLabel: 'Confirmar',
      icon: Icons.pets,
      iconColor: AppTheme.success,
      confirmColor: AppTheme.success,
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
                              color: estadoColor, fontWeight: FontWeight.bold)),
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
                  ? DateFormat('dd/MM/yyyy').format(ciclo.fechaEstimadaParto!)
                  : '—',
            ),
            _detalleRow(
              'Fecha de parto real',
              ciclo.fechaPartoReal != null
                  ? DateFormat('dd/MM/yyyy').format(ciclo.fechaPartoReal!)
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

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.secondary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.darkTextSecondary : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'pario':
        return Icons.check_circle_rounded;
      case 'fallida':
        return Icons.cancel_rounded;
      case 'descartada':
        return Icons.remove_circle_outline;
      default:
        return Icons.history_rounded;
    }
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
              onPressed: () => context.push('/configuracion'),
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
          heroTag: 'fab-reproduccion',
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
                          final diasCalculados = ciclo.fechaEstimadaParto !=
                                  null
                              ? ciclo.fechaEstimadaParto!.difference(hoy).inDays
                              : 0;
                          final diasRestantes =
                              diasCalculados < 0 ? 0 : diasCalculados;
                          final progreso = (283 - diasRestantes) / 283;
                          final isDark = theme.brightness == Brightness.dark;
                          final diasColor = diasRestantes < 15
                              ? AppTheme.error
                              : diasRestantes < 30
                                  ? AppTheme.warning
                                  : AppTheme.success;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                AppTheme.softShadowFor(theme.brightness)
                              ],
                            ),
                            child: Material(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () =>
                                    context.push('/animales/${ciclo.animal}'),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.headerGradientFor(
                                            theme.brightness),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.pets,
                                                color: Colors.white, size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Animal #${ciclo.animal}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const Text(
                                                  'Gestación en curso',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: diasColor.withValues(
                                                  alpha: isDark ? 1.0 : 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              '$diasRestantes días',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _infoRow(
                                            Icons.favorite_border,
                                            'Servicio',
                                            ciclo.tipoServicio == 'natural'
                                                ? 'Monta Natural'
                                                : 'Inseminación Artificial',
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 8),
                                          _infoRow(
                                            Icons.event_available_outlined,
                                            'Parto estimado',
                                            ciclo.fechaEstimadaParto != null
                                                ? DateFormat('dd/MM/yyyy')
                                                    .format(ciclo
                                                        .fechaEstimadaParto!)
                                                : 'N/A',
                                            isDark: isDark,
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Progreso de gestación',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              Text(
                                                '${(progreso * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  color: diasColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: progreso.clamp(0, 1),
                                              minHeight: 10,
                                              backgroundColor:
                                                  theme.dividerColor,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                diasColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                              onPressed: _registrando
                                                      .contains(ciclo.id)
                                                  ? null
                                                  : () =>
                                                      _confirmarParto(ciclo.id),
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.success,
                                                foregroundColor: Colors.white,
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
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
                                                  : const Icon(
                                                      Icons.check_circle,
                                                      size: 18),
                                              label:
                                                  const Text('Registrar Parto'),
                                            ),
                                          ),
                                        ],
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
                          final isDark = theme.brightness == Brightness.dark;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                AppTheme.softShadowFor(theme.brightness)
                              ],
                              border: Border.all(
                                color: estadoColor.withValues(
                                    alpha: isDark ? 0.4 : 0.22),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(14),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _mostrarDetalleCiclo(ciclo),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              estadoColor.withValues(
                                                  alpha: 0.85),
                                              estadoColor,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _iconoEstado(ciclo.estado),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Animal #${ciclo.animal}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        estadoColor.withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    estadoLabel,
                                                    style: TextStyle(
                                                      color: estadoColor,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  size: 12,
                                                  color: isDark
                                                      ? AppTheme
                                                          .darkTextSecondary
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('dd/MM/yyyy')
                                                      .format(
                                                          ciclo.fechaServicio),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn().slideX();
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
