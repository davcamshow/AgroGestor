import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/ciclos_provider.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class CicloFormScreen extends ConsumerStatefulWidget {
  final String? cicloId;

  const CicloFormScreen({this.cicloId, super.key});

  @override
  ConsumerState<CicloFormScreen> createState() => _CicloFormScreenState();
}

class _CicloFormScreenState extends ConsumerState<CicloFormScreen> {
  late final TextEditingController _fechaServicioController;
  String _tipoServicio = 'inseminacion_artificial';
  String _estado = 'en_servicio';
  String _formato = 'continuo';
  DateTime _fechaServicio = DateTime.now();
  DateTime? _fechaEstimadaParto;
  DateTime? _fechaPartoReal;
  DateTime? _fechaDestete;
  int? _selectedAnimal;
  String? _temporada;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fechaServicioController = TextEditingController();
    if (widget.cicloId != null) {
      _loadCicloData();
    }
  }

  Future<void> _loadCicloData() async {
    final ciclos = await ref.read(ciclosNotifierProvider.future);
    final ciclo = ciclos.firstWhere((c) => c.id.toString() == widget.cicloId);
    setState(() {
      _selectedAnimal = ciclo.animal;
      _tipoServicio = ciclo.tipoServicio;
      _estado = ciclo.estado;
      _formato = ciclo.formato ?? 'continuo';
      _temporada = ciclo.temporada;
      _fechaServicioController.text = ciclo.fechaServicio.toString().split(' ')[0];
      if (ciclo.fechaEstimadaParto != null) {
        _fechaEstimadaParto = ciclo.fechaEstimadaParto;
      }
      if (ciclo.fechaPartoReal != null) {
        _fechaPartoReal = ciclo.fechaPartoReal;
      }
      if (ciclo.fechaDestete != null) {
        _fechaDestete = ciclo.fechaDestete;
      }
    });
  }

  @override
  void dispose() {
    _fechaServicioController.dispose();
    super.dispose();
  }

  Future<void> _selectFecha(BuildContext context, String tipo) async {
    final initial = tipo == 'servicio'
        ? _fechaServicio
        : tipo == 'estimada'
            ? _fechaEstimadaParto ?? DateTime.now()
            : tipo == 'real'
                ? _fechaPartoReal ?? DateTime.now()
                : _fechaDestete ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (tipo == 'servicio') {
          _fechaServicio = picked;
          _fechaServicioController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else if (tipo == 'estimada') {
          _fechaEstimadaParto = picked;
        } else if (tipo == 'real') {
          _fechaPartoReal = picked;
        } else if (tipo == 'destete') {
          _fechaDestete = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (_selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un animal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'animal': _selectedAnimal,
        'tipo_servicio': _tipoServicio,
        'fecha_servicio': _fechaServicio.toIso8601String().split('T')[0],
        'estado': _estado,
        'formato': _formato,
        'temporada': _temporada,
      };

      if (_fechaEstimadaParto != null) {
        data['fecha_estimada_parto'] = _fechaEstimadaParto!.toIso8601String().split('T')[0];
      }
      if (_fechaPartoReal != null) {
        data['fecha_parto_real'] = _fechaPartoReal!.toIso8601String().split('T')[0];
      }
      if (_fechaDestete != null) {
        data['fecha_destete'] = _fechaDestete!.toIso8601String().split('T')[0];
      }

      if (widget.cicloId != null) {
        await ref.read(ciclosNotifierProvider.notifier).updateCiclo(
          int.parse(widget.cicloId!),
          data,
        );
      } else {
        await ref.read(ciclosNotifierProvider.notifier).createCiclo(data);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cicloId == null ? 'Nuevo Ciclo' : 'Editar Ciclo'),
        backgroundColor: AppTheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animal
            Text(
              'Animal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            animalesAsync.when(
              data: (animales) => DropdownButtonFormField<int?>(
                value: _selectedAnimal,
                decoration: const InputDecoration(
                  labelText: 'Seleccionar Animal',
                  border: OutlineInputBorder(),
                ),
                items: animales
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text('${a.numeroArete} - ${a.nombre ?? "Sin nombre"}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAnimal = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error cargando animales'),
            ),
            const SizedBox(height: 16),

            // Tipo de servicio
            Text(
              'Tipo de Servicio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Inseminación Artificial'),
                    value: 'inseminacion_artificial',
                    groupValue: _tipoServicio,
                    onChanged: (v) => setState(() => _tipoServicio = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Monta Natural'),
                    value: 'natural',
                    groupValue: _tipoServicio,
                    onChanged: (v) => setState(() => _tipoServicio = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Formato
            Text(
              'Formato de Reproducción',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Continuo'),
                    value: 'continuo',
                    groupValue: _formato,
                    onChanged: (v) => setState(() => _formato = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Temporada'),
                    value: 'temporada',
                    groupValue: _formato,
                    onChanged: (v) => setState(() => _formato = v!),
                  ),
                ),
              ],
            ),
            if (_formato == 'temporada') ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre de Temporada (ej: "Primavera 2026")',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _temporada = v.isEmpty ? null : v),
              ),
            ],
            const SizedBox(height: 16),

            // Fechas
            Text(
              'Fechas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectFecha(context, 'servicio'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Servicio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_fechaServicio),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectFecha(context, 'estimada'),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha Estimada de Parto',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                  hintText: 'Opcional',
                ),
                child: Text(
                  _fechaEstimadaParto != null
                      ? DateFormat('dd/MM/yyyy').format(_fechaEstimadaParto!)
                      : 'Seleccionar',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_estado == 'pario')
              InkWell(
                onTap: () => _selectFecha(context, 'real'),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Parto Real',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.check_circle),
                  ),
                  child: Text(
                    _fechaPartoReal != null
                        ? DateFormat('dd/MM/yyyy').format(_fechaPartoReal!)
                        : 'Seleccionar',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectFecha(context, 'destete'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha Estimada de Destete',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.child_care),
                  hintText: 'Opcional',
                ),
                child: Text(
                  _fechaDestete != null
                      ? DateFormat('dd/MM/yyyy').format(_fechaDestete!)
                      : 'Seleccionar',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Estado
            Text(
              'Estado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _estado,
              decoration: const InputDecoration(
                labelText: 'Estado del Ciclo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'en_servicio', child: Text('En Servicio')),
                DropdownMenuItem(value: 'gestante', child: Text('Gestante')),
                DropdownMenuItem(value: 'pario', child: Text('Parió')),
                DropdownMenuItem(value: 'fallida', child: Text('Fallida')),
                DropdownMenuItem(value: 'descartada', child: Text('Descartada')),
              ],
              onChanged: (v) => setState(() => _estado = v!),
            ),
            const SizedBox(height: 32),

            // Botón Guardar
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
                  : const Icon(Icons.save),
              label: Text(
                _isLoading ? 'Guardando...' : 'Guardar Ciclo',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}