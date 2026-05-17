import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/auditoria_provider.dart';
import '../../core/theme/app_theme.dart';
import 'animal_edit_sheet.dart';

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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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
            appBar: AppBar(title: const Text('No encontrado')),
            body: const Center(child: Text('Animal no encontrado')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(animal.nombre ?? animal.numeroArete),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
                onPressed: () => _abrirEdicion(context, animal),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Info'),
                Tab(text: 'Registros'),
                Tab(text: 'Auditoría'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _InfoTab(animal: animal),
              _RegistrosTab(animal: animal),
              _AuditoriaTab(animalId: animal.id),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirEdicion(BuildContext context, Animal animal) async {
    final cambio = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AnimalEditSheet(animal: animal),
    );
    if (cambio == true) {
      ref.invalidate(animalesNotifierProvider);
    }
  }
}

// ─────────────────────── Tab Info ───────────────────────
class _InfoTab extends StatelessWidget {
  final Animal animal;
  const _InfoTab({required this.animal});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context, animal).animate().fadeIn().slideY(begin: -0.2),
          const SizedBox(height: 20),
          _buildCard(context, 'Información General', Icons.info_outline, [
            _row('Caravana', animal.numeroArete),
            _row('Nombre', animal.nombre ?? '—'),
            _row('Raza', animal.raza ?? '—'),
            _row('Sexo', animal.sexo == 'M' ? 'Macho' : 'Hembra'),
            _row('Color', animal.color ?? '—'),
            _row('Estado', animal.estado),
          ]).animate().fadeIn(delay: 100.ms).slideX(),
          const SizedBox(height: 12),
          _buildCard(context, 'Nacimiento & Peso', Icons.cake_outlined, [
            _row('Fecha nacimiento',
                animal.fechaNacimiento?.toString().split(' ')[0] ?? '—'),
            _row('Edad (días)', animal.edadDias?.toString() ?? '—'),
            _row('Peso al nacer (kg)',
                animal.pesoNacimientoKg?.toString() ?? '—'),
          ]).animate().fadeIn(delay: 200.ms).slideX(),
          const SizedBox(height: 12),
          _buildCard(context, 'Genealogía', Icons.family_restroom, [
            _row('Madre', animal.madreId?.toString() ?? '—'),
            _row('Padre', animal.padreId?.toString() ?? '—'),
            _row('Lote', animal.loteId?.toString() ?? '—'),
          ]).animate().fadeIn(delay: 300.ms).slideX(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Animal animal) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(45),
            ),
            child: Center(
              child: Text(
                animal.numeroArete[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(animal.numeroArete,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Chip(
            label: Text(animal.estado),
            backgroundColor: animal.estado == 'activo'
                ? AppTheme.success.withOpacity(0.15)
                : Colors.grey[200],
            labelStyle: TextStyle(
              color: animal.estado == 'activo'
                  ? AppTheme.success
                  : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String title, IconData icon, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────── Tab Registros ───────────────────────
class _RegistrosTab extends StatelessWidget {
  final Animal animal;
  const _RegistrosTab({required this.animal});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow(context, 'Último peso (kg)',
            animal.ultimoPeso?.toString() ?? '—', Icons.scale),
        const SizedBox(height: 8),
        _infoRow(
            context,
            'Fecha último peso',
            animal.fechaUltimoPeso?.toString().split(' ')[0] ?? '—',
            Icons.calendar_today),
      ],
    );
  }

  Widget _infoRow(BuildContext ctx, String label, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────── Tab Auditoría ───────────────────────
class _AuditoriaTab extends ConsumerWidget {
  final int animalId;
  const _AuditoriaTab({required this.animalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditoriaAsync = ref.watch(auditoriaAnimalProvider(animalId));

    return auditoriaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text('No se pudo cargar la auditoría',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(auditoriaAnimalProvider(animalId)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
      data: (registros) {
        if (registros.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Sin cambios registrados',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: registros.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reg = registros[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [AppTheme.softShadow],
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _labelCampo(reg.campo),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(reg.fechaCambio.toLocal()),
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _valorChip(
                          label: 'Antes',
                          valor: reg.valorAnterior ?? '—',
                          color: AppTheme.error,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            size: 16, color: Colors.grey),
                      ),
                      Expanded(
                        child: _valorChip(
                          label: 'Después',
                          valor: reg.valorNuevo ?? '—',
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: index * 40));
          },
        );
      },
    );
  }

  String _labelCampo(String campo) {
    const etiquetas = {
      'numero_arete': 'Caravana',
      'nombre': 'Nombre',
      'raza': 'Raza',
      'sexo': 'Sexo',
      'fecha_nacimiento': 'F. Nacimiento',
      'color': 'Color',
      'peso_nacimiento_kg': 'Peso Nacer',
      'estado': 'Estado',
      'lote': 'Lote',
      'madre': 'Madre',
      'padre': 'Padre',
    };
    return etiquetas[campo] ?? campo;
  }

  Widget _valorChip(
      {required String label, required String valor, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
