import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/providers/dietas_provider.dart';

class LoteFormScreen extends ConsumerStatefulWidget {
  final String? loteId;

  const LoteFormScreen({this.loteId, super.key});

  @override
  ConsumerState<LoteFormScreen> createState() => _LoteFormScreenState();
}

class _LoteFormScreenState extends ConsumerState<LoteFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _headCountController;
  late final TextEditingController _avgWeightController;
  String _selectedStage = 'Engorda';
  int? _selectedDiet;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _headCountController = TextEditingController();
    _avgWeightController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headCountController.dispose();
    _avgWeightController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(lotesNotifierProvider.notifier).createLote({
        'nombre': _nameController.text,
        'cantidad_cabezas': int.parse(_headCountController.text),
        'peso_promedio_actual_kg': _avgWeightController.text,
        'etapa_productiva': _selectedStage,
        'dieta': _selectedDiet,
        'estado': 'activo',
      });
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietasAsync = ref.watch(dietasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loteId == null ? 'Nuevo Lote' : 'Editar Lote'),
        backgroundColor: const Color(0xFF064e3b),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Lote',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _headCountController,
                decoration: InputDecoration(
                  labelText: 'Cantidad de Cabezas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _avgWeightController,
                decoration: InputDecoration(
                  labelText: 'Peso Promedio (kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStage,
                decoration: InputDecoration(
                  labelText: 'Etapa Productiva',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Engorda', 'Destete', 'Mantenimiento', 'Lactancia']
                    .map((stage) => DropdownMenuItem(
                          value: stage,
                          child: Text(stage),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedStage = value ?? 'Engorda'),
              ),
              const SizedBox(height: 16),
              dietasAsync.when(
                data: (dietas) => DropdownButtonFormField<int?>(
                  value: _selectedDiet,
                  decoration: InputDecoration(
                    labelText: 'Dieta (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin dieta'),
                    ),
                    ...dietas.map((dieta) => DropdownMenuItem(
                          value: dieta.id,
                          child: Text(dieta.nombre),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedDiet = value),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064e3b),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Guardar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
