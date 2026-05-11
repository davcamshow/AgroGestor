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

  // Campos de reproducción
  DateTime? _fechaUltimoParto;
  int _partosCount = 0;
  int? _diasLactancia;

  // Campos de genealogía
  int? _madreId;
  int? _padreId;
  String? _madreArete;
  String? _padreArete;

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
      _fechaUltimoParto = a.fechaUltimoParto;
      _partosCount = a.partosCount ?? 0;
      _diasLactancia = a.diasLactancia;
      _madreId = a.madreId;
      _padreId = a.padreId;
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
        if (result['color_detectado'] != null && result['color_detectado'] != 'No determinado') {
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
        'nombre': _nombreController.text.isNotEmpty ? _nombreController.text : null,
        'raza': _razaController.text.isNotEmpty ? _razaController.text : null,
        'color': _colorController.text.isNotEmpty ? _colorController.text : null,
        'sexo': _sexoSeleccionado,
        'peso_nacimiento_kg': _pesoController.text.isNotEmpty ? _pesoController.text : null,
        'fecha_nacimiento': _fechaNacimiento?.toIso8601String().split('T')[0],
        'estado': 'activo',
        if (_fechaUltimoParto != null) 'fecha_ultimo_parto': _fechaUltimoParto!.toIso8601String().split('T')[0],
        if (_partosCount > 0) 'partos_count': _partosCount,
        if (_diasLactancia != null && _diasLactancia! > 0) 'dias_lactancia': _diasLactancia,
        'madre': _madreId,
        'padre': _padreId,
      };

      late final int animalId;
      if (_isEditing) {
        animalId = widget.animalToEdit!.id;
        await ref.read(animalesNotifierProvider.notifier).updateAnimal(animalId, data);
      } else {
        animalId = await ref.read(animalesNotifierProvider.notifier).createAnimal(data);
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
              content: const Text('¿Deseas ver los detalles del animal o seguir agregando más?'),
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
                          // Color
                          _buildTextField(
                            controller: _colorController,
                            label: 'Color',
                            icon: Icons.palette,
                            hint: 'Ej: Negro, Blanco, Cafe, etc.',
                          )
                              .animate()
                              .fadeIn(delay: 320.ms)
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
                          // Sección Reproducción
                          if (_sexoSeleccionado == 'M') ...[
                            const Text(
                              'Datos de Reproducción',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Fecha último parto
                            const Text('Fecha Último Parto'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fechaUltimoParto ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _fechaUltimoParto = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text(
                                        _fechaUltimoParto != null
                                            ? _fechaUltimoParto.toString().split(' ')[0]
                                            : 'Seleccionar fecha',
                                        style: TextStyle(
                                          color: _fechaUltimoParto != null
                                              ? Colors.black
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Icon(Icons.calendar_today, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Contador de partos
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Número de Partos'),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (_partosCount > 0) {
                                      setState(() => _partosCount--);
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '$_partosCount',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _partosCount++);
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Días de lactancia
                            TextFormField(
                              initialValue: _diasLactancia?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Días de Lactancia',
                                hintText: 'Ej: 70',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _diasLactancia = int.tryParse(value);
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                          const SizedBox(height: 20),
                          // Sección Genealogía
                          const Text(
                            'Genealogía',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Madre
                          const Text('Madre'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _seleccionarAnimal(context, true),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.female, color: Colors.pink[300]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _madreArete ?? (_madreId != null ? 'Madre asignada' : 'Seleccionar madre'),
                                      style: TextStyle(
                                        color: _madreId != null ? Colors.black : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  if (_madreId != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() {
                                        _madreId = null;
                                        _madreArete = null;
                                      }),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Padre
                          const Text('Padre'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _seleccionarAnimal(context, false),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.male, color: Colors.blue[300]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _padreArete ?? (_padreId != null ? 'Padre asignado' : 'Seleccionar padre'),
                                      style: TextStyle(
                                        color: _padreId != null ? Colors.black : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  if (_padreId != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() {
                                        _padreId = null;
                                        _padreArete = null;
                                      }),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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

  Future<void> _seleccionarAnimal(BuildContext context, bool esMadre) async {
    final animales = await ref.read(animalesNotifierProvider.future);
    final sexosFiltrar = esMadre ? 'H' : 'M';
    final disponibles = animales.where((a) => a.sexo == sexosFiltrar && a.id != widget.animalToEdit?.id).toList();

    if (disponibles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay animales ${esMadre ? "hembra" : "macho"} disponibles')),
        );
      }
      return;
    }

    if (!mounted) return;

    final seleccionado = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Seleccionar ${esMadre ? "Madre" : "Padre"}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: disponibles.length,
            itemBuilder: (context, index) {
              final animal = disponibles[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: esMadre ? Colors.pink[100] : Colors.blue[100],
                  child: Icon(esMadre ? Icons.female : Icons.male, color: esMadre ? Colors.pink : Colors.blue),
                ),
                title: Text(animal.numeroArete),
                subtitle: Text(animal.nombre ?? animal.raza ?? ''),
                onTap: () => Navigator.pop(ctx, animal),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (seleccionado != null) {
      setState(() {
        if (esMadre) {
          _madreId = seleccionado.id;
          _madreArete = seleccionado.numeroArete;
        } else {
          _padreId = seleccionado.id;
          _padreArete = seleccionado.numeroArete;
        }
      });
    }
  }
}
