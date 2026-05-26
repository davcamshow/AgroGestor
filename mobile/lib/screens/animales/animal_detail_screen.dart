import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'animal_form_sheet.dart';

// ---------------------------------------------------------------------------
// Provider de auditoría por animal
// ---------------------------------------------------------------------------
final auditoriaAnimalProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, animalId) async {
  final client = ref.read(apiClientProvider);
  final response = await client.dio.get('animales/$animalId/auditoria/');
  return (response.data as List).cast<Map<String, dynamic>>();
});

// ---------------------------------------------------------------------------
// Pantalla principal
// ---------------------------------------------------------------------------
class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);

    return animalesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (animales) {
        final animal = animales
            .where((a) => a.id.toString() == widget.animalId)
            .firstOrNull;

        if (animal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Animal no encontrado')),
            body: const Center(child: Text('Animal no encontrado')),
          );
        }

        final esActivo = animal.estado == 'activo';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(animal.nombre ?? animal.numeroArete),
            actions: [
              if (esActivo)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar',
                  onPressed: () => _showEditSheet(context, animal),
                ),
              if (esActivo)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Dar de baja',
                  color: AppTheme.error,
                  onPressed: () => _showBajaDialog(context, animal),
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              indicatorColor: AppTheme.primary,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Genealogía'),
                Tab(text: 'Auditoría'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 0: Información
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeader(animal).animate().fadeIn().slideY(begin: -0.2),
                    const SizedBox(height: 24),
                    _buildInfoCard(animal)
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildRegistrosCard(animal)
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideX(),
                  ],
                ),
              ),

              // Tab 1: Genealogía
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildGenealogiaCard(animal)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideX(),
              ),

              // Tab 2: Auditoría
              _AuditoriaTab(animalId: animal.id),
            ],
          ),
        );
      },
    );
  }

  // --- Diálogo de baja ---
  Future<void> _showBajaDialog(BuildContext context, Animal animal) async {
    final causaOptions = [
      ('vendido', 'Venta', Icons.sell_outlined, Colors.purple),
      ('muerto', 'Muerte', Icons.close_outlined, AppTheme.error),
      ('transferido', 'Transferencia', Icons.swap_horiz, Colors.orange),
    ];

    String causaSeleccionada = 'vendido';
    DateTime fechaSeleccionada = DateTime.now();
    final notasCtrl = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.remove_circle_outline, color: AppTheme.error),
              const SizedBox(width: 8),
              const Text('Dar de baja'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal: ${animal.nombre ?? animal.numeroArete}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Selector de causa
                const Text('Motivo de baja',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: causaOptions.map((opt) {
                    final (valor, label, icon, color) = opt;
                    final seleccionado = causaSeleccionada == valor;
                    return FilterChip(
                      avatar: Icon(icon,
                          size: 16, color: seleccionado ? Colors.white : color),
                      label: Text(label),
                      selected: seleccionado,
                      onSelected: (_) =>
                          setDialogState(() => causaSeleccionada = valor),
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: seleccionado ? Colors.white : null,
                        fontWeight: FontWeight.w500,
                      ),
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selector de fecha
                const Text('Fecha de baja',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => fechaSeleccionada = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                            DateFormat('dd/MM/yyyy').format(fechaSeleccionada)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notas opcionales
                const Text('Notas (opcional)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: notasCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Detalle adicional...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      setDialogState(() => isLoading = true);
                      try {
                        await ref
                            .read(animalesNotifierProvider.notifier)
                            .registrarBaja(
                              animalId: animal.id,
                              causa: causaSeleccionada,
                              fecha: DateFormat('yyyy-MM-dd')
                                  .format(fechaSeleccionada),
                              notas: notasCtrl.text.trim(),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Animal dado de baja: $causaSeleccionada'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          context.pop(); // Volver al listado
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('Confirmar baja'),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI helpers ---

  Widget _buildHeader(Animal animal) {
    final esActivo = animal.estado == 'activo';
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: esActivo
                      ? AppTheme.primaryGradient
                      : const LinearGradient(
                          colors: [Colors.grey, Color(0xFF9E9E9E)]),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    animal.numeroArete[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!esActivo)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_circle,
                      color: _estadoColor(animal.estado),
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            animal.numeroArete,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          _EstadoBadge(estado: animal.estado),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Animal animal) {
    return _Card(
      title: 'Información',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _Row('Número de Arete', animal.numeroArete),
          _Row('Nombre', animal.nombre ?? 'Sin nombre'),
          _Row('Raza', animal.raza ?? 'No especificada'),
          _Row('Sexo', animal.sexo == 'M' ? 'Macho' : 'Hembra'),
          _Row('Color', animal.color ?? 'No especificado'),
          _Row('Peso Nac. (kg)', animal.pesoNacimientoKg?.toString() ?? 'N/A'),
          _Row('Fecha Nac.',
              animal.fechaNacimiento?.toString().split(' ')[0] ?? 'N/A'),
          _Row('Lote', animal.loteId?.toString() ?? 'Sin lote'),
        ],
      ),
    );
  }

  Widget _buildGenealogiaCard(Animal animal) {
    return _Card(
      title: 'Genealogía',
      icon: Icons.family_restroom,
      child: Column(
        children: [
          _Row('Madre', animal.madreId?.toString() ?? 'Sin registrar'),
          _Row('Padre', animal.padreId?.toString() ?? 'Sin registrar'),
        ],
      ),
    );
  }

  Widget _buildRegistrosCard(Animal animal) {
    return _Card(
      title: 'Últimos Registros',
      icon: Icons.history,
      child: Column(
        children: [
          _Row('Último peso', animal.ultimoPeso?.toString() ?? 'Sin registro'),
          _Row('Fecha último peso',
              animal.fechaUltimoPeso?.toString().split(' ')[0] ?? 'N/A'),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalFormSheet(animalToEdit: animal),
    );
  }

  Color _estadoColor(String estado) => switch (estado) {
        'activo' => AppTheme.success,
        'vendido' => Colors.purple,
        'muerto' => AppTheme.error,
        'transferido' => Colors.orange,
        _ => Colors.grey,
      };
}

// ---------------------------------------------------------------------------
// Tab de Auditoría
// ---------------------------------------------------------------------------
class _AuditoriaTab extends ConsumerWidget {
  final int animalId;
  const _AuditoriaTab({required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditoriaAsync = ref.watch(auditoriaAnimalProvider(animalId));

    return auditoriaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (registros) {
        if (registros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Sin cambios registrados',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        // Más reciente primero
        final ordenados = [...registros]..sort((a, b) =>
            (b['fecha_cambio'] as String)
                .compareTo(a['fecha_cambio'] as String));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ordenados.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = ordenados[index];
            final campo = r['campo'] as String? ?? '';
            final antes = r['valor_anterior'] as String? ?? '-';
            final despues = r['valor_nuevo'] as String? ?? '-';
            final fechaRaw = r['fecha_cambio'] as String? ?? '';
            final fecha = fechaRaw.isNotEmpty
                ? DateFormat('dd/MM/yyyy HH:mm').format(
                    DateTime.tryParse(fechaRaw)?.toLocal() ?? DateTime.now())
                : '';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              leading: _campoIcon(campo),
              title: Text(
                _campoLabel(campo),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 13,
                          ),
                      children: [
                        TextSpan(
                          text: antes.isEmpty ? '(vacío)' : antes,
                          style: const TextStyle(
                            color: Colors.red,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const TextSpan(text: '  →  '),
                        TextSpan(
                          text: despues.isEmpty ? '(vacío)' : despues,
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fecha,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 50).ms);
          },
        );
      },
    );
  }

  Widget _campoIcon(String campo) {
    final icon = switch (campo) {
      'estado' => Icons.swap_horiz,
      'nombre' => Icons.badge_outlined,
      'raza' => Icons.pets,
      'lote' => Icons.group_outlined,
      'notas_baja' => Icons.note_outlined,
      _ => Icons.edit_outlined,
    };
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.primary.withOpacity(0.1),
      child: Icon(icon, size: 16, color: AppTheme.primary),
    );
  }

  String _campoLabel(String campo) => switch (campo) {
        'estado' => 'Estado',
        'nombre' => 'Nombre',
        'raza' => 'Raza',
        'lote' => 'Lote',
        'numero_arete' => 'Número de arete',
        'sexo' => 'Sexo',
        'color' => 'Color',
        'fecha_nacimiento' => 'Fecha de nacimiento',
        'peso_nacimiento_kg' => 'Peso nacimiento',
        'notas_baja' => 'Notas de baja',
        _ => campo,
      };
}

// ---------------------------------------------------------------------------
// Widgets auxiliares reutilizables
// ---------------------------------------------------------------------------
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [AppTheme.softShadow],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  Color get _color => switch (estado) {
        'activo' => AppTheme.success,
        'vendido' => Colors.purple,
        'muerto' => AppTheme.error,
        'transferido' => Colors.orange,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        estado[0].toUpperCase() + estado.substring(1),
        style:
            TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 13),
      ),
      backgroundColor: _color.withOpacity(0.15),
      side: BorderSide(color: _color.withOpacity(0.4)),
    );
  }
}
