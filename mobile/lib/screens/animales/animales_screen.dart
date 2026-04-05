import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';
import 'animal_form_sheet.dart';

class AnimalesScreen extends ConsumerWidget {
  const AnimalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final filtros = ref.watch(animalesFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animales'),
        elevation: 0,
      ),
      body: animalesAsync.when(
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => LoadingShimmerListItem(
            padding: const EdgeInsets.all(16),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Error: ${err.toString()}'),
            ],
          ),
        ),
        data: (animales) {
          final filtrados = animales
              .where((a) {
                if (filtros.containsKey('sexo') &&
                    a.sexo != filtros['sexo']) return false;
                if (filtros.containsKey('estado') &&
                    a.estado != filtros['estado']) return false;
                return true;
              })
              .toList();

          return filtrados.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Sin animales registrados',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final animal = filtrados[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppTheme.softShadow],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondary.withOpacity(0.2),
                          child: Text(
                            animal.numeroArete[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(animal.nombre ?? animal.numeroArete,
                            style: Theme.of(context)
                                .textTheme.titleMedium),
                        subtitle: Text(
                            '${animal.raza ?? 'Sin raza'} • ${animal.sexo == 'M' ? 'Macho' : 'Hembra'}'),
                        trailing: Chip(
                          label: Text(animal.estado),
                          backgroundColor: animal.estado == 'activo'
                              ? AppTheme.success.withOpacity(0.2)
                              : Colors.grey[200],
                        ),
                      ),
                    ).animate().fadeIn().slideX();
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AnimalFormSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
