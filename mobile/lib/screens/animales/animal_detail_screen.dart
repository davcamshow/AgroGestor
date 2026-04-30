import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';
import 'animal_form_sheet.dart';

class AnimalDetailScreen extends ConsumerStatefulWidget {
  final String animalId;

  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  ConsumerState<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends ConsumerState<AnimalDetailScreen> {
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
        final animal = animales.where((a) => a.id.toString() == widget.animalId).firstOrNull;
        
        if (animal == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Animal no encontrado')),
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
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditSheet(context, animal),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con avatar
                _buildHeader(animal).animate().fadeIn().slideY(begin: -0.2),
                const SizedBox(height: 24),
                
                // Info básica
                _buildSection('Información', Icons.info_outline, [
                  _buildInfoCard(animal),
                ]).animate().fadeIn(delay: 200.ms).slideX(),
                const SizedBox(height: 16),
                
                // Genealogía
                _buildSection('Genealogía', Icons.family_restroom, [
                  _buildGenealogiaCard(animal),
                ]).animate().fadeIn(delay: 300.ms).slideX(),
                const SizedBox(height: 16),
                
                // Registros
                _buildSection('Registros', Icons.history, [
                  _buildRegistrosCard(animal),
                ]).animate().fadeIn(delay: 400.ms).slideX(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Animal animal) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
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
          const SizedBox(height: 12),
          Text(
            animal.numeroArete,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Chip(
            label: Text(animal.estado ?? 'activo'),
            backgroundColor: AppTheme.success.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
        ...children,
      ],
    );
  }

  Widget _buildInfoCard(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          _buildRow('Número de Arete', animal.numeroArete),
          _buildRow('Nombre', animal.nombre ?? 'Sin nombre'),
          _buildRow('Raza', animal.raza ?? 'No especificada'),
          _buildRow('Sexo', animal.sexo == 'M' ? 'Macho' : 'Hembra'),
          _buildRow('Color', animal.color ?? 'No especificado'),
          _buildRow('Peso Nac. (kg)', animal.pesoNacimientoKg?.toString() ?? 'N/A'),
          _buildRow('Fecha Nac.', animal.fechaNacimiento?.toString().split(' ')[0] ?? 'N/A'),
          _buildRow('Lote', animal.loteId?.toString() ?? 'Sin lote'),
        ],
      ),
    );
  }

  Widget _buildGenealogiaCard(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          _buildRow('Madre', animal.madreId?.toString() ?? 'Sin registrar'),
          _buildRow('Padre', animal.padreId?.toString() ?? 'Sin registrar'),
        ],
      ),
    );
  }

  Widget _buildRegistrosCard(Animal animal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          _buildRow('Último peso', animal.ultimoPeso?.toString() ?? 'Sin registro'),
          _buildRow('Fecha último peso', animal.fechaUltimoPeso?.toString().split(' ')[0] ?? 'N/A'),
          _buildRow('Total eventos sanitarios', '0'),
          _buildRow('Último evento', 'N/A'),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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
}