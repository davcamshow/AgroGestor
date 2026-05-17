import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class AnimalEditSheet extends ConsumerStatefulWidget {
  final Animal animal;

  const AnimalEditSheet({super.key, required this.animal});

  @override
  ConsumerState<AnimalEditSheet> createState() => _AnimalEditSheetState();
}

class _AnimalEditSheetState extends ConsumerState<AnimalEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _areteCtrl;
  late TextEditingController _nombreCtrl;
  late TextEditingController _razaCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _pesoCtrl;
  late String _sexo;
  late String _estado;
  DateTime? _fechaNacimiento;
  bool _isLoading = false;
  String? _areteError;

  static const _estadosDisponibles = ['activo', 'vendido', 'muerto'];
  static const _sexosDisponibles = {'M': 'Macho', 'H': 'Hembra'};

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    _areteCtrl = TextEditingController(text: a.numeroArete);
    _nombreCtrl = TextEditingController(text: a.nombre ?? '');
    _razaCtrl = TextEditingController(text: a.raza ?? '');
    _colorCtrl = TextEditingController(text: a.color ?? '');
    _pesoCtrl = TextEditingController(
        text: a.pesoNacimientoKg != null ? a.pesoNacimientoKg.toString() : '');
    _sexo = a.sexo;
    _estado = a.estado;
    _fechaNacimiento = a.fechaNacimiento;
  }

  @override
  void dispose() {
    _areteCtrl.dispose();
    _nombreCtrl.dispose();
    _razaCtrl.dispose();
    _colorCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  bool get _hayCambios {
    final a = widget.animal;
    return _areteCtrl.text != a.numeroArete ||
        _nombreCtrl.text != (a.nombre ?? '') ||
        _razaCtrl.text != (a.raza ?? '') ||
        _colorCtrl.text != (a.color ?? '') ||
        _pesoCtrl.text != (a.pesoNacimientoKg?.toString() ?? '') ||
        _sexo != a.sexo ||
        _estado != a.estado ||
        _fechaNacimiento != a.fechaNacimiento;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hayCambios) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _areteError = null;
    });

    final data = <String, dynamic>{
      'numero_arete': _areteCtrl.text.trim(),
      'nombre': _nombreCtrl.text.isNotEmpty ? _nombreCtrl.text.trim() : null,
      'raza': _razaCtrl.text.isNotEmpty ? _razaCtrl.text.trim() : null,
      'color': _colorCtrl.text.isNotEmpty ? _colorCtrl.text.trim() : null,
      'sexo': _sexo,
      'estado': _estado,
      'peso_nacimiento_kg':
          _pesoCtrl.text.isNotEmpty ? _pesoCtrl.text.trim() : null,
      'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
    };

    try {
      await ref
          .read(animalesNotifierProvider.notifier)
          .updateAnimal(widget.animal.id, data);

      if (mounted) {
        Navigator.pop(context, true); // true = hubo cambios
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Animal actualizado correctamente'),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      final msg = e.toString();
      // Detectar error de caravana duplicada del backend
      if (msg.contains('numero_arete') || msg.contains('caravana')) {
        setState(() {
          _areteError = 'Esta caravana ya está registrada para otro animal.';
        });
        _formKey.currentState!.validate();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  Future<bool> _confirmarDescarte() async {
    if (!_hayCambios) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
            'Tienes cambios sin guardar. ¿Seguro que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmarDescarte()) {
          if (mounted) Navigator.pop(context);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.97,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Editar Animal',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            Text(
                              'Caravana: ${widget.animal.numeroArete}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (_hayCambios)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.warning.withOpacity(0.5)),
                          ),
                          child: Text(
                            'Sin guardar',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600),
                          ),
                        ).animate().fadeIn(),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        _buildSection('Identificación', Icons.tag),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _areteCtrl,
                          label: 'Número de Caravana *',
                          icon: Icons.tag,
                          hint: 'Ej: 001, A024',
                          externalError: _areteError,
                          validator: (v) {
                            if (_areteError != null) return _areteError;
                            if (v == null || v.trim().isEmpty) {
                              return 'La caravana es requerida';
                            }
                            return null;
                          },
                          onChanged: (_) {
                            if (_areteError != null) {
                              setState(() => _areteError = null);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _nombreCtrl,
                          label: 'Nombre',
                          icon: Icons.pets,
                          hint: 'Ej: Negra, Blanca',
                        ),
                        const SizedBox(height: 20),
                        _buildSection('Características', Icons.info_outline),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _razaCtrl,
                          label: 'Raza',
                          icon: Icons.category_outlined,
                          hint: 'Ej: Angus, Hereford',
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _colorCtrl,
                          label: 'Color',
                          icon: Icons.palette_outlined,
                          hint: 'Ej: Negro, Blanco, Café',
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _pesoCtrl,
                          label: 'Peso al Nacer (kg)',
                          icon: Icons.scale_outlined,
                          hint: 'Ej: 45.5',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              if (double.tryParse(v) == null) {
                                return 'Ingresa un número válido';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildSection('Sexo', Icons.wc),
                        const SizedBox(height: 12),
                        Row(
                          children: _sexosDisponibles.entries.map((e) {
                            final sel = _sexo == e.key;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _sexo = e.key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                      right: e.key == 'M' ? 8 : 0),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppTheme.primary.withOpacity(0.12)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel
                                          ? AppTheme.primary
                                          : Colors.grey[300]!,
                                      width: sel ? 2 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        fontWeight: sel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: sel
                                            ? AppTheme.primary
                                            : Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _buildSection('Estado', Icons.flag_outlined),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _estadosDisponibles.map((est) {
                            final sel = _estado == est;
                            return ChoiceChip(
                              label: Text(est),
                              selected: sel,
                              onSelected: (_) => setState(() => _estado = est),
                              selectedColor: AppTheme.primary.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: sel ? AppTheme.primary : Colors.black87,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color:
                                    sel ? AppTheme.primary : Colors.grey[300]!,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                            'Fecha de Nacimiento', Icons.calendar_today),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _seleccionarFecha,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: Colors.grey[600], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fechaNacimiento != null
                                        ? _fechaNacimiento!
                                            .toIso8601String()
                                            .split('T')[0]
                                        : 'Sin fecha',
                                    style: TextStyle(
                                      color: _fechaNacimiento != null
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                if (_fechaNacimiento != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _fechaNacimiento = null),
                                    child: Icon(Icons.close,
                                        size: 16, color: Colors.grey[500]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Botones
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (await _confirmarDescarte()) {
                                          if (mounted) Navigator.pop(context);
                                        }
                                      },
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _guardar,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text('Guardar cambios'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      helpText: 'Fecha de Nacimiento',
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppTheme.primary)),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    String? externalError,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        errorText: externalError,
      ),
      validator: validator,
    );
  }
}
