import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/animal_avatar.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/blur_bottom_sheet.dart';
import 'animal_form_sheet.dart';

class AnimalesScreen extends ConsumerWidget {
  const AnimalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final filtros = ref.watch(animalesFilterProvider);
    final estadoFiltro = ref.watch(animalesEstadoFiltroProvider);
    final busqueda = ref.watch(animalesBusquedaProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animales', style: TextStyle(color: Colors.white)),
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.appBarTheme.backgroundColor
            : AppTheme.primary,
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
            onPressed: () => context.push('/configuracion'),
          ),
        ],
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
          // Filtrar por estado seleccionado en el cliente
          var filtrados = animales.where((a) {
            if (estadoFiltro != 'todos' && a.estado != estadoFiltro) {
              return false;
            }
            if (filtros.containsKey('sexo') && a.sexo != filtros['sexo']) {
              return false;
            }
            final query = busqueda.trim().toLowerCase();
            if (query.isNotEmpty) {
              final arete = a.numeroArete.toLowerCase();
              final nombre = (a.nombre ?? '').toLowerCase();
              if (!arete.contains(query) && !nombre.contains(query)) {
                return false;
              }
            }
            return true;
          }).toList();

          final hayBusqueda = busqueda.trim().isNotEmpty;

          final Widget contenido = filtrados.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 90),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hayBusqueda ? Icons.search_off : Icons.pets,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hayBusqueda
                              ? 'No se encontraron animales con esa búsqueda'
                              : estadoFiltro == 'activo'
                                  ? 'Sin animales activos'
                                  : 'Sin animales registrados',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 84, bottom: 88),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final animal = filtrados[index];
                    final esInactivo = animal.estado != 'activo';

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppTheme.softShadowFor(theme.brightness)],
                        border: esInactivo
                            ? Border.all(color: Colors.grey[300]!, width: 1)
                            : null,
                      ),
                      child: Material(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          onTap: () => context.push('/animales/${animal.id}'),
                          leading: AnimalAvatar(
                            animal: animal,
                            dimmed: esInactivo,
                            backgroundColor: esInactivo
                                ? Colors.grey[300]
                                : AppTheme.secondary.withOpacity(0.2),
                            foregroundColor: esInactivo
                                ? Colors.grey[600]
                                : AppTheme.secondary,
                          ),
                          title: Text(
                            animal.nombre ?? animal.numeroArete,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: esInactivo ? Colors.grey[600] : null,
                                ),
                          ),
                          subtitle: Text(
                            '${animal.numeroArete} • ${animal.raza ?? 'Sin raza'} • ${animal.sexo == 'M' ? 'Macho' : 'Hembra'}',
                          ),
                          trailing: _EstadoChip(estado: animal.estado),
                        ),
                      ),
                    ).animate().fadeIn().slideX();
                  },
                );

          return Stack(
            children: [
              contenido,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _BarraBusqueda(
                  query: busqueda,
                  onChanged: (v) =>
                      ref.read(animalesBusquedaProvider.notifier).state = v,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-animales',
        onPressed: () {
          // Tu acción de agregar animal
          showBlurBottomSheet(
            context: context,
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
            child: const AnimalFormSheet(),
          );
        },
        backgroundColor:
            AppTheme.primary, // o el verde que uses en Reproducción
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: barra de búsqueda con efecto vidrio esmerilado
// ---------------------------------------------------------------------------
class _BarraBusqueda extends StatefulWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const _BarraBusqueda({required this.query, required this.onChanged});

  @override
  State<_BarraBusqueda> createState() => _BarraBusquedaState();
}

class _BarraBusquedaState extends State<_BarraBusqueda> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _limpiar() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? AppTheme.darkSurface : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: base.withOpacity(isDark ? 0.72 : 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : AppTheme.primary.withOpacity(0.12),
              ),
              boxShadow: [AppTheme.softShadowFor(theme.brightness)],
            ),
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar por arete o nombre...',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary.withOpacity(0.7)
                      : Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.primary.withOpacity(0.6),
                ),
                suffixIcon: widget.query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.black45,
                        ),
                        onPressed: _limpiar,
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
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
