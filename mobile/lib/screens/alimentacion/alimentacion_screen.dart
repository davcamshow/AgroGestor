import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/dieta.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/providers/insumos_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';
import '../insumos/registro_movimiento_sheet.dart';

class AlimentacionScreen extends ConsumerStatefulWidget {
  const AlimentacionScreen({super.key});

  @override
  ConsumerState<AlimentacionScreen> createState() =>
      _AlimentacionScreenState();
}

class _AlimentacionScreenState extends ConsumerState<AlimentacionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    switch (_tabController.index) {
      case 0:
        context.push('/formulas/builder');
        break;
      case 1:
        context.push('/lotes/new');
        break;
      default:
        context.push('/insumos');
    }
  }

  String get _fabTooltip => switch (_tabController.index) {
        0 => 'Nueva dieta',
        1 => 'Nuevo lote',
        _ => 'Gestionar insumos',
      };

  Future<void> _eliminarDieta(Dieta dieta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar dieta'),
        content: Text('¿Eliminar "${dieta.nombre}"? '
            'Los lotes y animales que la usan dejarán de consumirla automáticamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(dietasNotifierProvider.notifier).deleteDieta(dieta.id);
      ref.invalidate(dietaInsumosProvider);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Future<void> _procesarConsumo() async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(dietasNotifierProvider.notifier);
    try {
      final resumen = await notifier.procesarConsumo();
      ref.invalidate(insumosNotifierProvider);
      ref.invalidate(dietasNotifierProvider);

      if (!context.mounted) return;
      final raciones = resumen['raciones_creadas'] as int? ?? 0;
      final movimientos = resumen['movimientos_creados'] as int? ?? 0;
      final animales = resumen['animales_procesados'] as int? ?? 0;
      final lotesProcesados = (resumen['lotes_procesados'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      final insumosAgotados = (resumen['insumos_agotados'] as List? ?? const [])
          .cast<String>();
      final avisos = <String>[];
      for (final lote in lotesProcesados) {
        final avisosLote = (lote['avisos'] as List? ?? const [])
            .cast<String>();
        for (final a in avisosLote) {
          avisos.add('${lote['lote_nombre']}: $a');
        }
      }

      final siConsumio = raciones > 0;
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(
                siConsumio ? Icons.check_circle : Icons.info_outline,
                color: siConsumio
                    ? AppTheme.success
                    : Theme.of(dialogContext).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Consumo procesado'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (raciones > 0) ...[
                  Text('$raciones ración(es) registrada(s).'),
                  Text('$movimientos salida(s) de inventario.'),
                  if (animales > 0) Text('$animales animal(es) con dieta especial.'),
                ] else
                  const Text(
                      'Sin consumo pendiente: las dietas ya están al día.'),
                if (insumosAgotados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Insumos agotados:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...insumosAgotados.map((i) => Text('• $i')),
                ],
                if (avisos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Avisos:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...avisos.map((a) => Text('• $a')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error al procesar consumo: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietasAsync = ref.watch(dietasNotifierProvider);
    final lotesAsync = ref.watch(lotesNotifierProvider);
    final insumosAsync = ref.watch(insumosNotifierProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.success;
    final errorColor = theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/alimentacion/reporte'),
            tooltip: 'Reporte de Consumo',
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber),
            onPressed: () => context.push('/alimentacion/alertas'),
            tooltip: 'Alertas de Stock',
          ),
          // El apartado de usuario ahora es el último elemento,
          // por lo que se renderizará totalmente a la derecha.
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
              child: Icon(Icons.person,
                  color: theme.appBarTheme.foregroundColor, size: 18),
            ),
            onPressed: () => context.go('/configuracion'),
            tooltip: 'Perfil de Usuario',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.appBarTheme.foregroundColor,
          unselectedLabelColor:
              theme.appBarTheme.foregroundColor?.withOpacity(0.7),
          indicatorColor: theme.appBarTheme.foregroundColor,
          tabs: const [
            Tab(text: 'Dietas'),
            Tab(text: 'Lotes'),
            Tab(text: 'Insumos'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        tooltip: _fabTooltip,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
          children: [
            // dietas
            dietasAsync.when(
              loading: () => ListView.builder(
                itemCount: 3,
                itemBuilder: (_, i) => LoadingShimmerListItem(),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (dietas) {
                final activas =
                    dietas.where((d) => d.estado == 'activa').toList();
                return RefreshIndicator(
                  onRefresh: _procesarConsumo,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Gestionar dietas',
                            onPressed: () => context.push('/formulas'),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ),
                      ),
                      Expanded(
                        child: activas.isEmpty
                            ? const Center(
                                child: Text(
                                    'Sin dietas activas. Crea una para alimentar tus lotes.'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: activas.length,
                                itemBuilder: (context, index) {
                                  final dieta = activas[index];
                                  return GestureDetector(
                                    onTap: () => context.push(
                                        '/formulas/builder',
                                        extra: dieta),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: theme.cardTheme.color,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              theme.colorScheme.secondary,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          AppTheme.softShadowFor(
                                              theme.brightness)
                                        ],
                                      ),
                                      child: ListTile(
                                        title: Text(dieta.nombre),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                                'Objetivo: ${dieta.objetivo}'),
                                            Text(
                                                'Costo: \$${dieta.costoEstimadoKg}/kg'),
                                          ],
                                        ),
                                        trailing: PopupMenuButton<String>(
                                          onSelected: (opcion) {
                                            if (opcion == 'editar') {
                                              context.push(
                                                  '/formulas/builder',
                                                  extra: dieta);
                                            } else if (opcion == 'eliminar') {
                                              _eliminarDieta(dieta);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'editar',
                                              child: Text('Editar'),
                                            ),
                                            PopupMenuItem(
                                              value: 'eliminar',
                                              child: Text('Eliminar',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ).animate().fadeIn().slideX();
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // lotes
            lotesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (lotes) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Las cabezas se calculan con el ganado activo del lote.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Gestionar lotes',
                            onPressed: () => context.push('/lotes'),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: lotes.isEmpty
                          ? const Center(child: Text('Sin lotes'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: lotes.length,
                              itemBuilder: (context, index) {
                                final lote = lotes[index];
                                return GestureDetector(
                                  onTap: () =>
                                      context.push('/lotes/${lote.id}/edit'),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.cardTheme.color,
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: theme.dividerColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(lote.nombre,
                                                  style: theme
                                                      .textTheme.labelLarge,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                            PopupMenuButton<String>(
                                              onSelected: (opcion) {
                                                if (opcion == 'editar') {
                                                  context.push(
                                                      '/lotes/${lote.id}/edit');
                                                } else if (opcion ==
                                                    'eliminar') {
                                                  ref
                                                      .read(lotesNotifierProvider
                                                          .notifier)
                                                      .deleteLote(lote.id);
                                                }
                                              },
                                              itemBuilder: (_) => const [
                                                PopupMenuItem(
                                                  value: 'editar',
                                                  child: Text('Editar'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'eliminar',
                                                  child: Text('Eliminar',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${lote.cabezasEfectivas} cabezas',
                                              style:
                                                  theme.textTheme.bodySmall,
                                            ),
                                            Chip(
                                              label: Text(lote.estado),
                                              backgroundColor: theme
                                                  .colorScheme.primary
                                                  .withOpacity(0.2),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),

            // insumos
            insumosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (insumos) {
                return insumos.isEmpty
                    ? const Center(child: Text('Sin insumos'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: insumos.length,
                        itemBuilder: (context, index) {
                          final insumo = insumos[index];
                          final actual =
                              double.tryParse(insumo.cantidadActualKg) ?? 0;
                          final minimo =
                              double.tryParse(insumo.stockMinimoKg) ?? 0;
                          final alerta = actual < minimo;
                          final progreso = (minimo > 0
                              ? (actual / minimo).clamp(0.0, 1.0)
                              : 1.0);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: alerta
                                  ? errorColor.withOpacity(0.1)
                                  : theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: alerta ? errorColor : theme.dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(insumo.nombre,
                                          style: theme.textTheme.labelLarge,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    if (alerta)
                                      Chip(
                                        label: const Text('Bajo stock'),
                                        backgroundColor:
                                            errorColor.withOpacity(0.3),
                                      ),
                                    IconButton(
                                      tooltip: 'Registrar entrada/salida',
                                      icon: const Icon(Icons.swap_vert),
                                      onPressed: () => showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) => RegistroMovimientoSheet(
                                            insumo: insumo),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progreso,
                                    minHeight: 6,
                                    backgroundColor: theme.dividerColor,
                                    valueColor: AlwaysStoppedAnimation(
                                      alerta ? errorColor : successColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${actual.toStringAsFixed(1)}/${minimo.toStringAsFixed(1)} kg',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        },
                      );
              },
            ),
          ],
        ),
    );
  }
}
