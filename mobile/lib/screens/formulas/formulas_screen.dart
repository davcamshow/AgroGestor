import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/dietas_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';

class FormulasScreen extends ConsumerWidget {
  const FormulasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dietasAsync = ref.watch(dietasNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fórmulas'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/formulas/builder'),
        backgroundColor: const Color(0xFF064e3b),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(dietasNotifierProvider);
        },
        child: dietasAsync.when(
          data: (dietas) {
            if (dietas.isEmpty) {
              return EmptyState(
                icon: Icons.restaurant,
                title: 'Sin fórmulas',
                description: 'Crea tu primera fórmula nutricional',
                actionLabel: 'Nueva Fórmula',
                onActionPressed: () => context.go('/formulas/builder'),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
              ),
              padding: const EdgeInsets.all(16),
              itemCount: dietas.length,
              itemBuilder: (context, index) {
                final dieta = dietas[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dieta.nombre,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(status: dieta.estado),
                        const SizedBox(height: 8),
                        Text(
                          'Objetivo: ${dieta.objetivo}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '\$${dieta.costoEstimadoKg}/kg',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF064e3b),
                              ),
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
