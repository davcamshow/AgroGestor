import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
    final estadoFiltro = ref.watch(animalesEstadoFiltroProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Animales', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Toggle activos / todos
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _EstadoToggle(
              valor: estadoFiltro,
              onChanged: (v) =>
                  ref.read(animalesEstadoFiltroProvider.notifier).state = v,
            ),
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
      body: animalesAsync.when(
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const LoadingShimmerListItem(
            padding: EdgeInsets.all(16),
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text('Error: ${err.toString()}'),
            ],
          ),
        ),
        data: (animales) {
          // Filtrar por estado seleccionado en el cliente
          var filtrados = animales.where((a) {
            if (estadoFiltro != 'todos' && a.estado != estadoFiltro) {
              return false;
            }
            if (filtros.containsKey('sexo') && a.sexo != filtros['sexo']) {
              return false;
            }
            return true;
          }).toList();

          if (filtrados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    estadoFiltro == 'activo'
                        ? 'Sin animales activos'
                        : 'Sin animales registrados',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: filtrados.length,
            itemBuilder: (context, index) {
              final animal = filtrados[index];
              final esInactivo = animal.estado != 'activo';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: esInactivo ? Colors.grey[100] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.softShadow],
                  border: esInactivo
                      ? Border.all(color: Colors.grey[300]!, width: 1)
                      : null,
                ),
                child: ListTile(
                  onTap: () => context.push('/animales/${animal.id}'),
                  leading: CircleAvatar(
                    backgroundColor: esInactivo
                        ? Colors.grey[300]
                        : AppTheme.secondary.withOpacity(0.2),
                    child: Text(
                      animal.numeroArete[0].toUpperCase(),
                      style: TextStyle(
                        color:
                            esInactivo ? Colors.grey[600] : AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    animal.nombre ?? animal.numeroArete,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: esInactivo ? Colors.grey[600] : null,
                        ),
                  ),
                  subtitle: Text(
                    '${animal.raza ?? 'Sin raza'} • ${animal.sexo == 'M' ? 'Macho' : 'Hembra'}',
                  ),
                  trailing: _EstadoChip(estado: animal.estado),
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

// ---------------------------------------------------------------------------
// Widget: toggle Activos / Todos
// ---------------------------------------------------------------------------
class _EstadoToggle extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  const _EstadoToggle({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(valor == 'activo' ? 'todos' : 'activo'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: valor == 'todos'
              ? Colors.white.withOpacity(0.25)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valor == 'todos' ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 15,
            ),
            const SizedBox(width: 4),
            Text(
              valor == 'todos' ? 'Todos' : 'Activos',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: chip de estado con color semántico
// ---------------------------------------------------------------------------
class _EstadoChip extends StatelessWidget {
  final String estado;

  const _EstadoChip({required this.estado});

  Color get _color => switch (estado) {
        'activo' => AppTheme.success,
        'vendido' => Colors.purple,
        'muerto' => AppTheme.error,
        'transferido' => Colors.orange,
        _ => Colors.grey,
      };

  String get _label => switch (estado) {
        'activo' => 'Activo',
        'vendido' => 'Vendido',
        'muerto' => 'Muerto',
        'transferido' => 'Transferido',
        _ => estado,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: _color.withOpacity(0.12),
      side: BorderSide(color: _color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
