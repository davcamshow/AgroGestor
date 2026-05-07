import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/providers/insumos_provider.dart';
import '../../core/theme/app_theme.dart';

class CalculadoraScreen extends ConsumerStatefulWidget {
  const CalculadoraScreen({super.key});

  @override
  ConsumerState<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends ConsumerState<CalculadoraScreen> {
  final _animalesController = TextEditingController(text: '10');
  final _pesoController = TextEditingController(text: '300');
  final _diasController = TextEditingController(text: '7');
  int? _selectedLoteId;
  String _tipoFormulacion = 'porcentaje';
  bool _showResult = false;

  final Map<int, TextEditingController> _kgControllers = {};

  @override
  void dispose() {
    _animalesController.dispose();
    _pesoController.dispose();
    _diasController.dispose();
    for (var c in _kgControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _calcularPorcentaje({
    required double kgTotal,
    required int animales,
    required double pesoPromedio,
    required int dias,
  }) {
    return (pesoPromedio * 0.03 * animales * dias) / 100;
  }

  void _calcular() {
    setState(() {
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lotesAsync = ref.watch(lotesNotifierProvider);
    final insumosAsync = ref.watch(insumosProvider);

    final animales = int.tryParse(_animalesController.text) ?? 0;
    final pesoProm = double.tryParse(_pesoController.text) ?? 0;
    final dias = int.tryParse(_diasController.text) ?? 7;

    final consumoDiario = animales * pesoProm * 0.03;
    final consumoTotal = consumoDiario * dias;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Raciones'),
        backgroundColor: AppTheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del Lote',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    lotesAsync.when(
                      data: (lotes) => DropdownButtonFormField<int>(
                        value: _selectedLoteId,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Lote',
                          border: OutlineInputBorder(),
                        ),
                        items: lotes.map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text('${l.nombre} (${l.cantidadCabezas} cab)'),
                        )).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedLoteId = v;
                            final lote = lotes.firstWhere((l) => l.id == v);
                            _animalesController.text = lote.cantidadCabezas.toString();
                            if (lote.pesoPromedioActualKg.isNotEmpty) {
                              _pesoController.text = lote.pesoPromedioActualKg;
                            }
                          });
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _animalesController,
                            decoration: const InputDecoration(
                              labelText: '# Animales',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _showResult = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _pesoController,
                            decoration: const InputDecoration(
                              labelText: 'Peso Prom (kg)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _showResult = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _diasController,
                            decoration: const InputDecoration(
                              labelText: 'Días',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() => _showResult = false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _tipoFormulacion,
                            decoration: const InputDecoration(
                              labelText: 'Formato',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'porcentaje', child: Text('% Porcentaje')),
                              DropdownMenuItem(value: 'tabla_kg', child: Text('Tabla kg')),
                            ],
                            onChanged: (v) => setState(() {
                              _tipoFormulacion = v ?? 'porcentaje';
                              _showResult = false;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_showResult) ...[
              Card(
                color: AppTheme.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildResultadoRow('Consumo diario por animal', '${(consumoDiario / animales).toStringAsFixed(2)} kg'),
                      _buildResultadoRow('Consumo diario total', '${consumoDiario.toStringAsFixed(2)} kg'),
                      _buildResultadoRow('Consumo total ($dias días)', '${consumoTotal.toStringAsFixed(2)} kg'),
                      _buildResultadoRow('Costo estimado', '\$${(consumoTotal * 2.5).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desglose por Insumo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      insumosAsync.when(
                        data: (insumos) {
                          final insumosMostrar = insumos.take(5).toList();
                          return Column(
                            children: insumosMostrar.map((insumo) {
                              final pct = 100 / insumosMostrar.length;
                              final kg = (consumoTotal * pct / 100);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(insumo.nombre),
                                    Text('${kg.toStringAsFixed(2)} kg'),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _calcular,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}