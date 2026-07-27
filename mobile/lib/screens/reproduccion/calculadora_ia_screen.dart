import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class CalculadoraIAScreen extends ConsumerStatefulWidget {
  const CalculadoraIAScreen({super.key});

  @override
  ConsumerState<CalculadoraIAScreen> createState() => _CalculadoraIAScreenState();
}

class _CalculadoraIAScreenState extends ConsumerState<CalculadoraIAScreen> {
  DateTime? _fechaUltimoParto;
  int _diasGestacion = 283;
  int _diasInvolution = 60;
  int? _selectedAnimalId;
  Map<String, dynamic>? _animal;

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de IA', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info, color: AppTheme.primary, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'La fecha óptima de IA se calcula sumando:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Fecha último parto + $_diasInvolution días (involución) + $_diasGestacion días (gestación)',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleccionar Animal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            animalesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
              data: (animales) {
                final hembras = animales.where((a) => a.sexo == 'M').toList();
                return DropdownButtonFormField<int>(
                  value: _selectedAnimalId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seleccionar vaca',
                  ),
                  items: hembras.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.numeroArete} - ${a.nombre ?? a.raza ?? "Sin nombre"}'),
                  )).toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      final api = ref.read(apiClientProvider);
                      final animalData = await api.get('/animales/$value/');
                      setState(() {
                        _selectedAnimalId = value;
                        _animal = animalData;
                        if (animalData['fecha_ultimo_parto'] != null) {
                          _fechaUltimoParto = DateTime.parse(animalData['fecha_ultimo_parto']);
                        }
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if (_animal != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.softShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animal: ${_animal!['numero_arete']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_animal!['nombre'] != null)
                      Text('Nombre: ${_animal!['nombre']}'),
                    Text('Raza: ${_animal!['raza'] ?? "No registrada"}'),
                    const SizedBox(height: 12),
                    Text(
                      'Último Parto: ${_fechaUltimoParto != null ? _fechaUltimoParto!.toString().split(' ')[0] : "No registrado"}',
                    ),
                    Text('Partos: ${_animal!['partos_count'] ?? 0}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_fechaUltimoParto != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Fecha Óptima para IA:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calcularFechaIA().toString().split(' ')[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(${_diasInvolution} días involución + ${_diasGestacion} días gestión)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Fecha Estimada de Parto:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calcularFechaParto().toString().split(' ')[0],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No hay registro de último parto',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'No se puede calcular la fecha óptima',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Selecciona un animal para calcular',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DateTime _calcularFechaIA() {
    return _fechaUltimoParto!.add(Duration(days: _diasInvolution));
  }

  DateTime _calcularFechaParto() {
    return _fechaUltimoParto!.add(Duration(days: _diasInvolution + _diasGestacion));
  }
}