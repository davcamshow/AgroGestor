import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/registro_peso.dart';
import '../../core/models/evento_sanitario.dart';
import '../../core/providers/registros_peso_provider.dart';
import '../../core/providers/eventos_sanitarios_provider.dart';
import '../../core/theme/app_theme.dart';

class AgregarRegistroSheet extends ConsumerStatefulWidget {
  final int animalId;
  final String animalArete;

  const AgregarRegistroSheet({
    super.key,
    required this.animalId,
    required this.animalArete,
  });

  @override
  ConsumerState<AgregarRegistroSheet> createState() => _AgregarRegistroSheetState();
}

class _AgregarRegistroSheetState extends ConsumerState<AgregarRegistroSheet> {
  int _selectedTab = 0;
  final _formKey = GlobalKey<FormState>();

  final _pesoController = TextEditingController();
  DateTime _fechaPeso = DateTime.now();
  int? _condicionCorporal;

  String _tipoEvento = 'vacunacion';
  final _productoController = TextEditingController();
  final _dosisController = TextEditingController();
  DateTime _fechaEvento = DateTime.now();
  DateTime? _fechaProxima;
  final _veterinarioController = TextEditingController();
  final _costoController = TextEditingController();
  final _notasController = TextEditingController();

  @override
  void dispose() {
    _pesoController.dispose();
    _productoController.dispose();
    _dosisController.dispose();
    _veterinarioController.dispose();
    _costoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Agregar Registro - ${widget.animalArete}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _selectedTab = 0),
                  style: TextButton.styleFrom(
                    backgroundColor: _selectedTab == 0 ? AppTheme.primary : null,
                    foregroundColor: _selectedTab == 0 ? Colors.white : AppTheme.primary,
                  ),
                  child: const Text('Pesaje'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _selectedTab = 1),
                  style: TextButton.styleFrom(
                    backgroundColor: _selectedTab == 1 ? AppTheme.info : null,
                    foregroundColor: _selectedTab == 1 ? Colors.white : AppTheme.info,
                  ),
                  child: const Text('Evento Sanitario'),
                ),
              ),
            ],
          ),
          Expanded(
            child: _selectedTab == 0 ? _buildPesajeForm() : _buildEventoForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPesajeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fecha de Pesaje', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaPeso,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _fechaPeso = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_fechaPeso.day}/${_fechaPeso.month}/${_fechaPeso.year}'),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pesoController,
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa el peso';
                if (double.tryParse(value) == null) return 'Peso inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Condición Corporal (1-5)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5].map((n) {
                return GestureDetector(
                  onTap: () => setState(() => _condicionCorporal = n),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _condicionCorporal == n ? AppTheme.primary : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        n.toString(),
                        style: TextStyle(
                          color: _condicionCorporal == n ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarPesaje,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Guardar Pesaje', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventoForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de Evento', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipoEvento,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'vacunacion', child: Text('Vacunación')),
                DropdownMenuItem(value: 'desparasitacion', child: Text('Desparasitación')),
                DropdownMenuItem(value: 'tratamiento', child: Text('Tratamiento')),
                DropdownMenuItem(value: 'cirugia', child: Text('Cirugía')),
              ],
              onChanged: (v) => setState(() => _tipoEvento = v ?? 'vacunacion'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _productoController,
              decoration: const InputDecoration(
                labelText: 'Producto/Medicamento',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa el producto';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosisController,
              decoration: const InputDecoration(
                labelText: 'Dósis (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Fecha de Aplicación', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaEvento,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _fechaEvento = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_fechaEvento.day}/${_fechaEvento.month}/${_fechaEvento.year}'),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Próxima Aplicación (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fechaProxima ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _fechaProxima = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fechaProxima != null
                        ? '${_fechaProxima!.day}/${_fechaProxima!.month}/${_fechaProxima!.year}'
                        : 'Sin fecha'),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _veterinarioController,
              decoration: const InputDecoration(
                labelText: 'Veterinario (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costoController,
              decoration: const InputDecoration(
                labelText: 'Costo (MXN)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarEvento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.info,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Guardar Evento', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPesaje() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(registroPesoNotifierProvider.notifier).createRegistro({
        'animal': widget.animalId,
        'fecha_pesaje': '${_fechaPeso.year}-${_fechaPeso.month.toString().padLeft(2, '0')}-${_fechaPeso.day.toString().padLeft(2, '0')}',
        'peso_kg': _pesoController.text,
        'condicion_corporal': _condicionCorporal,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesaje registrado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final data = {
        'animal': widget.animalId,
        'tipo': _tipoEvento,
        'producto': _productoController.text,
        'dosis': _dosisController.text.isNotEmpty ? _dosisController.text : null,
        'fecha_aplicacion': '${_fechaEvento.year}-${_fechaEvento.month.toString().padLeft(2, '0')}-${_fechaEvento.day.toString().padLeft(2, '0')}',
        'veterinario': _veterinarioController.text.isNotEmpty ? _veterinarioController.text : null,
        'costo': _costoController.text.isNotEmpty ? _costoController.text : '0',
        'notas': _notasController.text.isNotEmpty ? _notasController.text : null,
      };

      if (_fechaProxima != null) {
        data['proxima_aplicacion'] = '${_fechaProxima!.year}-${_fechaProxima!.month.toString().padLeft(2, '0')}-${_fechaProxima!.day.toString().padLeft(2, '0')}';
      }

      await ref.read(eventosSanitariosNotifierProvider.notifier).createEvento(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento sanitario registrado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
