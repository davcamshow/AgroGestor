import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/dieta.dart';
import '../../core/providers/dietas_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';

class FormulasScreen extends ConsumerWidget {
  const FormulasScreen({super.key});

  Future<void> _eliminar(
      BuildContext context, WidgetRef ref, Dieta dieta) async {
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
    try {
      await ref.read(dietasNotifierProvider.notifier).deleteDieta(dieta.id);
      ref.invalidate(dietaInsumosProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietasAsync = ref.watch(dietasNotifierProvider);
    final dietaInsumosAsync = ref.watch(dietaInsumosProvider);
    final conteoInsumos = dietaInsumosAsync.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietas'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-formulas',
        onPressed: () => context.push('/formulas/builder'),
        backgroundColor: const Color(0xFF064e3b),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dietasNotifierProvider);
          ref.invalidate(dietaInsumosProvider);
        },
        child: dietasAsync.when(
          data: (dietas) {
            if (dietas.isEmpty) {
              return EmptyState(
                icon: Icons.restaurant,
                title: 'Sin dietas',
                description: 'Crea tu primera dieta con insumos del inventario',
                actionLabel: 'Nueva Dieta',
                onActionPressed: () => context.push('/formulas/builder'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dietas.length,
              itemBuilder: (context, index) {
                final dieta = dietas[index];
                final cantidad =
                    conteoInsumos.where((di) => di.dieta == dieta.id).length;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () =>
                        context.push('/formulas/builder', extra: dieta),
                    isThreeLine: true,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dieta.nombre,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusBadge(status: dieta.estado),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Objetivo: ${dieta.objetivo}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _Chip(
                                icon: Icons.repeat,
                                texto: _periodicidad(dieta.periodicidad),
                              ),
                              const SizedBox(width: 8),
                              _Chip(
                                icon: Icons.category,
                                texto:
                                    '${dieta.tipoFormulacion == 'porcentaje' ? '%' : 'kg'} · '
                                    '$cantidad ingredientes',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${dieta.costoEstimadoKg}/kg',
                            style: TextStyle(color: const Color(0xFF064e3b)),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (opcion) {
                        if (opcion == 'editar') {
                          context.push('/formulas/builder', extra: dieta);
                        } else if (opcion == 'eliminar') {
                          _eliminar(context, ref, dieta);
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
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  String _periodicidad(String? p) {
    switch (p) {
      case 'semanal':
        return 'Semanal';
      case 'quincenal':
        return 'Quincenal';
      default:
        return 'Diaria';
    }
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _Chip({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF064e3b).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF064e3b)),
          const SizedBox(width: 4),
          Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
