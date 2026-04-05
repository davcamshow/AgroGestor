import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/insumos_provider.dart';

class FormulaBuilderScreen extends ConsumerStatefulWidget {
  const FormulaBuilderScreen({super.key});

  @override
  ConsumerState<FormulaBuilderScreen> createState() => _FormulaBuilderScreenState();
}

class _FormulaBuilderScreenState extends ConsumerState<FormulaBuilderScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _objectiveController;
  final Map<int, double> _ingredientPercentages = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _objectiveController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _objectiveController.dispose();
    super.dispose();
  }

  double _getTotalPercentage() {
    return _ingredientPercentages.values.fold(0, (sum, pct) => sum + pct);
  }

  bool _isValid() {
    return (_getTotalPercentage() - 100).abs() < 0.01 &&
        _nameController.text.isNotEmpty &&
        _objectiveController.text.isNotEmpty;
  }

  Future<void> _handleSave() async {
    if (!_isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los ingredientes deben sumar exactamente 100%'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(dietasNotifierProvider.notifier).createDieta({
        'nombre': _nameController.text,
        'objetivo': _objectiveController.text,
        'estado': 'activa',
        'costo_estimado_kg': '0',
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
    final insumosAsync = ref.watch(insumosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Constructor de Fórmula'),
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
                  labelText: 'Nombre de la Fórmula',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _objectiveController,
                decoration: InputDecoration(
                  labelText: 'Objetivo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text(
                'Ingredientes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              insumosAsync.when(
                data: (insumos) => Column(
                  children: [
                    ...insumos.map((insumo) {
                      final pct = _ingredientPercentages[insumo.id] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(insumo.nombre),
                                Text('${pct.toStringAsFixed(2)}%'),
                              ],
                            ),
                            Slider(
                              value: pct,
                              min: 0,
                              max: 100,
                              onChanged: (value) {
                                setState(() {
                                  _ingredientPercentages[insumo.id] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isValid()
                            ? Colors.green[50]
                            : Colors.red[50],
                        border: Border.all(
                          color: _isValid() ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Total: ${_getTotalPercentage().toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: _isValid() ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading || !_isValid() ? null : _handleSave,
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
                    : const Text(
                        'Guardar Fórmula',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
