import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class AnimalFormSheet extends ConsumerStatefulWidget {
  const AnimalFormSheet({super.key});

  @override
  ConsumerState<AnimalFormSheet> createState() => _AnimalFormSheetState();
}

class _AnimalFormSheetState extends ConsumerState<AnimalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _areteController;
  late TextEditingController _nombreController;
  late TextEditingController _razaController;
  late TextEditingController _pesoController;

  String _sexoSeleccionado = 'M';
  DateTime? _fechaNacimiento;
  File? _imagenSeleccionada;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _areteController = TextEditingController();
    _nombreController = TextEditingController();
    _razaController = TextEditingController();
    _pesoController = TextEditingController();
  }

  @override
  void dispose() {
    _areteController.dispose();
    _nombreController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? foto =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (foto != null) {
        setState(() => _imagenSeleccionada = File(foto.path));
      }
    } catch (e) {
      print('Error al tomar foto: $e');
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? foto =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (foto != null) {
        setState(() => _imagenSeleccionada = File(foto.path));
      }
    } catch (e) {
      print('Error al seleccionar foto: $e');
    }
  }

  Future<void> _guardarAnimal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'numero_arete': _areteController.text,
        'nombre': _nombreController.text.isNotEmpty
            ? _nombreController.text
            : null,
        'raza': _razaController.text.isNotEmpty ? _razaController.text : null,
        'sexo': _sexoSeleccionado,
        'peso_nacimiento_kg':
            _pesoController.text.isNotEmpty ? _pesoController.text : null,
        'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
        'estado': 'activo',
      };

      await ref.read(animalesNotifierProvider.notifier).createAnimal(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Animal agregado correctamente'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Agregar Animal',
                      style: Theme.of(context).textTheme.headlineSmall,
                    )
                        .animate()
                        .fadeIn()
                        .slideY(begin: -0.2),
                    const SizedBox(height: 20),
                    // Foto
                    _buildFotoSection()
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.2),
                    const SizedBox(height: 24),
                    // Formulario
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Número de arete (requerido)
                          _buildTextField(
                            controller: _areteController,
                            label: 'Número de Arete *',
                            icon: Icons.tag,
                            hint: 'Ej: 001, A024, etc.',
                            validator: (v) => v?.isEmpty ?? true
                                ? 'El arete es requerido'
                                : null,
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Nombre
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre',
                            icon: Icons.pets,
                            hint: 'Ej: Negra, Blanca, etc.',
                          )
                              .animate()
                              .fadeIn(delay: 250.ms)
                              .slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Raza
                          _buildTextField(
                            controller: _razaController,
                            label: 'Raza',
                            icon: Icons.info_outline,
                            hint: 'Ej: Angus, Hereford, etc.',
                          )
                              .animate()
                              .fadeIn(delay: 300.ms)
                              .slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Sexo
                          Text(
                            'Sexo',
                            style: Theme.of(context)
                                .textTheme.labelLarge
                                ?.copyWith(color: AppTheme.primary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSexoButton('M', 'Macho'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child:
                                    _buildSexoButton('H', 'Hembra'),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(delay: 350.ms)
                              .slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Peso
                          _buildTextField(
                            controller: _pesoController,
                            label: 'Peso al Nacer (kg)',
                            icon: Icons.scale,
                            hint: 'Ej: 45.5',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Fecha de Nacimiento
                          Text(
                            'Fecha de Nacimiento',
                            style: Theme.of(context)
                                .textTheme.labelLarge
                                ?.copyWith(color: AppTheme.primary),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _fechaNacimiento = picked);
                              }
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      _fechaNacimiento != null
                                          ? _fechaNacimiento.toString().split(' ')[0]
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _fechaNacimiento != null
                                            ? Colors.black
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(Icons.calendar_today,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 450.ms)
                              .slideX(begin: 0.3),
                          const SizedBox(height: 28),
                          // Botón guardar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _guardarAnimal,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Guardar Animal'),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideY(begin: 0.3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto del Animal',
          style: Theme.of(context)
              .textTheme.labelLarge
              ?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: 12),
        if (_imagenSeleccionada != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imagenSeleccionada!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Colors.black.withOpacity(0.5),
                  ),
                  onPressed: () =>
                      setState(() => _imagenSeleccionada = null),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _tomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _seleccionarFoto,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme.labelLarge
              ?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildSexoButton(String valor, String label) {
    final isSelected = _sexoSeleccionado == valor;
    return InkWell(
      onTap: () => setState(() => _sexoSeleccionado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primary : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}
