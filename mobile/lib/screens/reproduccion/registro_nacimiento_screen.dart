import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/animal.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/genealogia_utils.dart'; // Asegúrate de haber creado este archivo

class RegistroNacimientoScreen extends ConsumerStatefulWidget {
  final String? cicloId;

  const RegistroNacimientoScreen({this.cicloId, super.key});

  @override
  ConsumerState<RegistroNacimientoScreen> createState() =>
      _RegistroNacimientoScreenState();
}

class _RegistroNacimientoScreenState extends ConsumerState<RegistroNacimientoScreen> {
  final _formKey = GlobalKey<FormState>(); 

  final _areteController = TextEditingController();
  final _nombreController = TextEditingController();
  final _pesoController = TextEditingController();
  final _observacionesController = TextEditingController();

  
  String _sexo = 'M';
  DateTime _fechaNacimiento = DateTime.now();
  bool _isLoading = false;


  int? _loteSeleccionadoId;
  int? _madreSeleccionadaId;
  int? _padreSeleccionadoId;

  @override
  void dispose() {
    _areteController.dispose();
    _nombreController.dispose();
    _pesoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    
    if (!_formKey.currentState!.validate()) return;

    if (_madreSeleccionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona la madre de la cría')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await ref.read(ciclosNotifierProvider.notifier).registrarNacimiento({
        'ciclo': widget.cicloId,
        'numero_arete': _areteController.text.toUpperCase(), 
        'nombre': _nombreController.text.isEmpty ? null : _nombreController.text,
        'sexo': _sexo,
        'peso_nacimiento_kg': _pesoController.text.isEmpty ? null : _pesoController.text,
        'fecha_nacimiento': _fechaNacimiento.toIso8601String().split('T')[0],
        'observaciones': _observacionesController.text.isEmpty ? null : _observacionesController.text,
        'madre_id': _madreSeleccionadaId,
        'padre_id': _padreSeleccionadoId,
        'lote_id': _loteSeleccionadoId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nacimiento registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final lotesAsync = ref.watch(lotesNotifierProvider); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nacimiento'),
        backgroundColor: AppTheme.primary,
      ),
      body: animalesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error cargando datos: $err')),
        data: (todosLosAnimales) {
          
          final posiblesMadres = GenealogiaUtils.obtenerPosiblesMadres(
            todosLosAnimales,
            _loteSeleccionadoId,
          );
          final posiblesPadres = GenealogiaUtils.obtenerPosiblesPadres(todosLosAnimales);

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                            'Ubicación y Genealogía',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          
                          // selector de Lote
                          lotesAsync.when(
                            data: (lotes) => DropdownButtonFormField<int>(
                              value: _loteSeleccionadoId,
                              decoration: const InputDecoration(
                                labelText: 'Ubicación (Lote/Potrero)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map),
                              ),
                              items: lotes.map((lote) {
                                return DropdownMenuItem<int>(
                                  value: lote.id,
                                  child: Text(lote.nombre),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _loteSeleccionadoId = value;
                                  // se resetea madre si cambia el potrero para forzar re-selección
                                  _madreSeleccionadaId = null; 
                                });
                              },
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 12),

                          // selector de Madre
                          DropdownButtonFormField<int>(
                            value: _madreSeleccionadaId,
                            decoration: const InputDecoration(
                              labelText: 'Madre *',
                              hintText: 'Selecciona la madre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.female, color: Colors.pink),
                            ),
                            items: posiblesMadres.map((animal) {
                              final esDelLote = animal.loteId == _loteSeleccionadoId;
                              return DropdownMenuItem<int>(
                                value: animal.id,
                                child: Text(
                                  '${animal.numeroArete} - ${animal.nombre ?? "Sin nombre"} ${esDelLote ? "📍" : ""}',
                                  style: TextStyle(
                                    fontWeight: esDelLote ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _madreSeleccionadaId = value),
                            validator: (value) => value == null ? 'Seleccionar la madre es obligatorio' : null,
                          ),
                          const SizedBox(height: 12),

                          // selector de Padre
                          DropdownButtonFormField<int>(
                            value: _padreSeleccionadoId,
                            decoration: const InputDecoration(
                              labelText: 'Padre (Semental/IA)',
                              hintText: 'Opcional',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.male, color: Colors.blue),
                            ),
                            items: posiblesPadres.map((animal) {
                              return DropdownMenuItem<int>(
                                value: animal.id,
                                child: Text('${animal.numeroArete} - ${animal.nombre ?? "Sin nombre"}'),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _padreSeleccionadoId = value),
                          ),
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
                            'Datos de la Cría',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField( // Cambiado de TextField a TextFormField para usar validator
                            controller: _areteController,
                            decoration: const InputDecoration(
                              labelText: 'Número de Arete *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El arete es requerido';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                                return 'Solo números y letras sin espacios';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pets),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sexo *',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Macho'),
                                  value: 'M',
                                  groupValue: _sexo,
                                  onChanged: (v) => setState(() => _sexo = v!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Hembra'),
                                  value: 'H',
                                  groupValue: _sexo,
                                  onChanged: (v) => setState(() => _sexo = v!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pesoController,
                            decoration: const InputDecoration(
                              labelText: 'Peso al nacimiento (kg) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale),
                              hintText: 'Ej: 35.5',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) => (value == null || value.isEmpty) ? 'El peso es requerido' : null,
                          ),
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
                            'Información Adicional',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _selectFecha(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Nacimiento *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_fechaNacimiento.day}/${_fechaNacimiento.month}/${_fechaNacimiento.year}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _observacionesController,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones (opcional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                              hintText: 'Anomalías, complicaciones, etc.',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _isLoading ? 'Guardando...' : 'Registrar Nacimiento',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}