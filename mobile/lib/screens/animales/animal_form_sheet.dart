import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/services/bovino_recognition_service.dart';
import '../../core/theme/app_theme.dart';

class AnimalFormSheet extends ConsumerStatefulWidget {
  final Animal? animalToEdit;

  const AnimalFormSheet({super.key, this.animalToEdit});

  @override
  ConsumerState<AnimalFormSheet> createState() => _AnimalFormSheetState();
}

class _AnimalFormSheetState extends ConsumerState<AnimalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _areteController;
  late TextEditingController _nombreController;
  late TextEditingController _razaController;
  late TextEditingController _pesoController;
  late TextEditingController _colorController;

  String _sexoSeleccionado = 'M';
  DateTime? _fechaNacimiento;
  File? _imagenSeleccionada;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  bool get _isEditing => widget.animalToEdit != null;

  @override
  void initState() {
    super.initState();
    _areteController = TextEditingController();
    _nombreController = TextEditingController();
    _razaController = TextEditingController();
    _pesoController = TextEditingController();
    _colorController = TextEditingController();

    if (_isEditing) {
      final a = widget.animalToEdit!;
      _areteController.text = a.numeroArete;
      _nombreController.text = a.nombre ?? '';
      _razaController.text = a.raza ?? '';
      _colorController.text = a.color ?? '';
      _pesoController.text = a.pesoNacimientoKg?.toString() ?? '';
      _sexoSeleccionado = a.sexo;
      _fechaNacimiento = a.fechaNacimiento;
    }
  }

  @override
  void dispose() {
    _areteController.dispose();
    _nombreController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? foto =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (foto != null) {
        setState(() => _imagenSeleccionada = File(foto.path));
        _analizarImagen(File(foto.path));
      }
    } catch (e) {
      print('Error al tomar foto: $e');
    }
  }

  Future<void> _analizarImagen(File imageFile) async {
    try {
      final recognitionService = BovinoRecognitionService();
      final result = await recognitionService.recognizeBovino(imageFile);

      setState(() {
        if (result['color_detectado'] != null &&
            result['color_detectado'] != 'No determinado') {
          _colorController.text = result['color_detectado']!;
        }
        if (result['raza_sugerida'] != null) {
          _razaController.text = result['raza_sugerida']!;
        }
      });

      if (mounted && result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['mensaje']}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Aceptar',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      print('Error en análisis: $e');
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
        'nombre':
            _nombreController.text.isNotEmpty ? _nombreController.text : null,
        'raza': _razaController.text.isNotEmpty ? _razaController.text : null,
        'color':
            _colorController.text.isNotEmpty ? _colorController.text : null,
        'sexo': _sexoSeleccionado,
        'peso_nacimiento_kg':
            _pesoController.text.isNotEmpty ? _pesoController.text : null,
        'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
        'estado': 'activo',
      };

      late final int animalId;
      if (_isEditing) {
        animalId = widget.animalToEdit!.id;
        await ref
            .read(animalesNotifierProvider.notifier)
            .updateAnimal(animalId, data);
      } else {
        animalId = await ref
            .read(animalesNotifierProvider.notifier)
            .createAnimal(data);
      }

      if (mounted) {
        Navigator.pop(context);

        if (!_isEditing) {
          final shouldNavigate = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success),
                  SizedBox(width: 8),
                  Text('¡Animal guardado!'),
                ],
              ),
              content: const Text(
                  '¿Deseas ver los detalles del animal o seguir agregando más?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Agregar otro'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Ver detalles'),
                ),
              ],
            ),
          );

          if (shouldNavigate == true && mounted) {
            context.push('/animales/$animalId');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Animal actualizado'),
              duration: Duration(seconds: 2),
            ),
          );
        }
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
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
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
                  color: theme.dividerColor,
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
                      style: theme.textTheme.headlineSmall,
                    ).animate().fadeIn().slideY(begin: -0.2),
                    const SizedBox(height: 20),
                    // Foto
                    _buildFotoSection(theme)
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
                            theme: theme,
                            controller: _areteController,
                            label: 'Número de Arete *',
                            icon: Icons.tag,
                            hint: 'Ej: 001, A024, etc.',
                            validator: (v) => v?.isEmpty ?? true
                                ? 'El arete es requerido'
                                : null,
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Nombre
                          _buildTextField(
                            theme: theme,
                            controller: _nombreController,
                            label: 'Nombre',
                            icon: Icons.pets,
                            hint: 'Ej: Negra, Blanca, etc.',
                          ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Raza
                          _buildTextField(
                            theme: theme,
                            controller: _razaController,
                            label: 'Raza',
                            icon: Icons.info_outline,
                            hint: 'Ej: Angus, Hereford, etc.',
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Color
                          _buildTextField(
                            theme: theme,
                            controller: _colorController,
                            label: 'Color',
                            icon: Icons.palette,
                            hint: 'Ej: Negro, Blanco, Cafe, etc.',
                          ).animate().fadeIn(delay: 320.ms).slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Sexo
                          Text(
                            'Sexo',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSexoButton(theme, 'M', 'Macho'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSexoButton(theme, 'H', 'Hembra'),
                              ),
                            ],
                          ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Peso
                          _buildTextField(
                            theme: theme,
                            controller: _pesoController,
                            label: 'Peso al Nacer (kg)',
                            icon: Icons.scale,
                            hint: 'Ej: 45.5',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
                          const SizedBox(height: 16),
                          // Fecha de Nacimiento
                          Text(
                            'Fecha de Nacimiento',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
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
                                          ? _fechaNacimiento
                                              .toString()
                                              .split(' ')[0]
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        color: _fechaNacimiento != null
                                            ? theme.textTheme.bodyMedium?.color
                                            : theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 450.ms).slideX(begin: 0.3),
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
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
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

  Widget _buildFotoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto del Animal',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
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
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: () => setState(() => _imagenSeleccionada = null),
                ),
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: theme.textTheme.bodySmall?.color,
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
    required ThemeData theme,
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
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
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

  Widget _buildSexoButton(ThemeData theme, String valor, String label) {
    final isSelected = _sexoSeleccionado == valor;
    return InkWell(
      onTap: () => setState(() => _sexoSeleccionado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }
}
