import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/lotes_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';

class LotesScreen extends ConsumerWidget {
  const LotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotes'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/lotes/new'),
        backgroundColor: const Color(0xFF064e3b),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(lotesNotifierProvider);
        },
        child: lotesAsync.when(
          data: (lotes) {
            if (lotes.isEmpty) {
              return EmptyState(
                icon: Icons.groups,
                title: 'Sin lotes',
                description: 'Crea tu primer lote para comenzar',
                actionLabel: 'Crear Lote',
                onActionPressed: () => context.go('/lotes/new'),
              );
            }

            return ListView.builder(
              itemCount: lotes.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final lote = lotes[index];
                return Card(
                  child: ListTile(
                    title: Text(lote.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${lote.cantidadCabezas} cabezas • ${lote.pesoPromedioActualKg} kg'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatusBadge(status: lote.etapaProductiva),
                            const SizedBox(width: 8),
                            StatusBadge(status: lote.estado),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Editar'),
                          onTap: () => context.go('/lotes/${lote.id}/edit'),
                        ),
                        PopupMenuItem(
                          child: const Text('Eliminar'),
                          onTap: () {
                            ref.read(lotesNotifierProvider.notifier).deleteLote(lote.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
