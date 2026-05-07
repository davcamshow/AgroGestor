import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/theme/app_theme.dart';

class RegistroNacimientoScreen extends ConsumerStatefulWidget {
  final String? cicloId;

  const RegistroNacimientoScreen({this.cicloId, super.key});

  @override
  ConsumerState<RegistroNacimientoScreen> createState() => _RegistroNacimientoScreenState();
}

class _RegistroNacimientoScreenState extends ConsumerState<RegistroNacimientoScreen> {
  final _areteController = TextEditingController();
  final _nombreController = TextEditingController();
  final _pesoController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  String _sexo = 'M';
  DateTime _fechaNacimiento = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _areteController.dispose();
    _nombreController.dispose();
    _pesoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_areteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El arete es requerido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(ciclosNotifierProvider.notifier).registrarNacimiento({
        'ciclo': widget.cicloId,
        'numero_arete': _areteController.text,
        'nombre': _nombreController.text.isEmpty ? null : _nombreController.text,
        'sexo': _sexo,
        'peso_nacimiento_kg': _pesoController.text.isEmpty ? null : _pesoController.text,
        'fecha_nacimiento': _fechaNacimiento.toIso8601String().split('T')[0],
        'observaciones': _observacionesController.text.isEmpty ? null : _observacionesController.text,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nacimiento'),
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
                      'Datos de la Cría',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _areteController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Arete *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
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
                    TextField(
                      controller: _pesoController,
                      decoration: const InputDecoration(
                        labelText: 'Peso al nacimiento (kg)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                        hintText: '30-40 kg típico',
                      ),
                      keyboardType: TextInputType.number,
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
                          labelText: 'Fecha de Nacimiento',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_fechaNacimiento.day}/${_fechaNacimiento.month}/${_fechaNacimiento.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _observacionesController,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                        hintText: 'Anomalías, complications, etc.',
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
  }
}