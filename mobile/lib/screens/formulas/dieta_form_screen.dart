import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/dieta.dart';
import '../../core/models/dieta_insumo.dart';
import '../../core/providers/dietas_provider.dart';
import '../../core/providers/insumos_provider.dart';

class _Ingrediente {
  final int insumoId;
  final String nombre;
  final int? id;
  final TextEditingController valor;

  _Ingrediente({
    required this.insumoId,
    required this.nombre,
    required this.valor,
    this.id,
  });
}

class DietaFormScreen extends ConsumerStatefulWidget {
  final Dieta? dieta;
  const DietaFormScreen({super.key, this.dieta});

  @override
  ConsumerState<DietaFormScreen> createState() => _DietaFormScreenState();
}

class _DietaFormScreenState extends ConsumerState<DietaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _objetivo;
  late final TextEditingController _costo;
  late final TextEditingController _kgCabeza;
  final List<_Ingrediente> _ingredientes = [];

  String _estado = 'activa';
  String _tipoFormulacion = 'porcentaje';
  String _periodicidad = 'diaria';
  int? _nuevoInsumoId;
  bool _cargando = false;
  bool _listo = false;

  bool get _esEdicion => widget.dieta != null;

  @override
  void initState() {
    super.initState();
    final d = widget.dieta;
    _nombre = TextEditingController(text: d?.nombre ?? '');
    _objetivo = TextEditingController(text: d?.objetivo ?? '');
    _costo = TextEditingController(text: d?.costoEstimadoKg ?? '0');
    _kgCabeza = TextEditingController(text: d?.cantidadKgCabeza ?? '');
    if (d != null) {
      _estado = (d.estado == 'activa' || d.estado == 'inactiva')
          ? d.estado
          : 'inactiva';
      _tipoFormulacion = d.tipoFormulacion ?? 'porcentaje';
      _periodicidad = d.periodicidad ?? 'diaria';
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _objetivo.dispose();
    _costo.dispose();
    _kgCabeza.dispose();
    for (final i in _ingredientes) {
      i.valor.dispose();
    }
    super.dispose();
  }

  double get _totalPorcentaje {
    double total = 0;
    for (final i in _ingredientes) {
      final v = double.tryParse(i.valor.text.replaceAll(',', '.'));
      if (v != null) total += v;
    }
    return total;
  }

  String? _validarValorIngrediente(String? value) {
    final v = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (value == null || value.trim().isEmpty || v == null) {
      return 'Campo obligatorio';
    }
    if (_tipoFormulacion == 'porcentaje' && (v <= 0 || v > 100)) {
      return 'Entre 0 y 100';
    }
    if (_tipoFormulacion == 'tabla_kg' && v <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }

  Future<void> _cargarIngredientes(List<DietaInsumo> todos) async {
    if (!_esEdicion || _listo) return;
    final insumos = ref.read(insumosProvider).valueOrNull ?? const [];
    final mapa = {for (final i in insumos) i.id: i.nombre};
    for (final di in todos) {
      if (di.dieta != widget.dieta!.id) continue;
      final valor = _tipoFormulacion == 'porcentaje'
          ? di.porcentajeInclusion
          : di.cantidadKg;
      final c = TextEditingController(text: valor ?? '');
      _ingredientes.add(_Ingrediente(
        insumoId: di.insumo,
        nombre: mapa[di.insumo] ?? 'Insumo',
        id: di.id,
        valor: c,
      ));
    }
    _listo = true;
    setState(() {});
  }

  void _agregarIngrediente() {
    final insumoId = _nuevoInsumoId;
    if (insumoId == null) {
      _mensaje('Selecciona un insumo para agregar.');
      return;
    }
    final insumos = ref.read(insumosProvider).valueOrNull ?? const [];
    if (insumos.isEmpty) {
      _mensaje('Primero crea insumos en Inventario.');
      return;
    }
    final insumo = insumos.firstWhere((i) => i.id == insumoId);
    if (_ingredientes.any((i) => i.insumoId == insumoId)) {
      _mensaje('Ese insumo ya está en la dieta.');
      return;
    }
    final c = TextEditingController();
    _ingredientes.add(_Ingrediente(insumoId: insumoId, nombre: insumo.nombre, valor: c));
    _nuevoInsumoId = null;
    setState(() {});
  }

  void _quitarIngrediente(int index) {
    _ingredientes[index].valor.dispose();
    _ingredientes.removeAt(index);
    setState(() {});
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  String? _mensajeError(Object e) {
    try {
      final error = e as dynamic;
      final respuesta = error?.response;
      final data = respuesta?.data;
      if (data != null && data is Map) {
        final mensajes = <String>[];
        for (final entry in data.entries) {
          final v = entry.value;
          if (v is String) {
            mensajes.add(v);
          } else if (v is List) {
            mensajes.addAll(v.map((x) => x.toString()));
          } else if (v is Map) {
            for (final sub in v.values) {
              if (sub is List) mensajes.addAll(sub.map((x) => x.toString()));
            }
          }
        }
        if (mensajes.isNotEmpty) return mensajes.join('\n');
      }
    } catch (_) {}
    return null;
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _mensaje('Corrige los campos marcados en rojo.');
      return;
    }

    if (_tipoFormulacion == 'porcentaje' && _ingredientes.isEmpty) {
      _mensaje('Agrega al menos un ingrediente a la dieta.');
      return;
    }
    if (_tipoFormulacion == 'porcentaje' && _totalPorcentaje > 100) {
      _mensaje('Los porcentajes suman más de 100% (actual: ${_totalPorcentaje.toStringAsFixed(2)}%).');
      return;
    }

    setState(() => _cargando = true);
    final notifier = ref.read(dietasNotifierProvider.notifier);
    try {
      final datos = <String, dynamic>{
        'nombre': _nombre.text.trim(),
        'objetivo': _objetivo.text.trim(),
        'estado': _estado,
        'tipo_formulacion': _tipoFormulacion,
        'periodicidad': _periodicidad,
        'costo_estimado_kg': _costo.text.trim().replaceAll(',', '.'),
        if (_kgCabeza.text.trim().isNotEmpty)
          'cantidad_kg_cabeza': _kgCabeza.text.trim().replaceAll(',', '.'),
      };

      final int dietaId;
      if (_esEdicion) {
        await notifier.updateDieta(widget.dieta!.id, datos);
        dietaId = widget.dieta!.id;
      } else {
        dietaId = await notifier.createDieta(datos);
      }

      final originales = widget.dieta != null
          ? (ref.read(dietaInsumosProvider).valueOrNull ??
              const <DietaInsumo>[])
              .where((di) => di.dieta == widget.dieta!.id)
              .toList()
          : const <DietaInsumo>[];
      final originalMap = {for (final o in originales) o.id: o};

      for (final ing in _ingredientes) {
        final v = double.parse(ing.valor.text.trim().replaceAll(',', '.'));
        if (ing.id == null) {
          await notifier.addInsumoToDieta(
            dietaId,
            ing.insumoId,
            porcentaje: _tipoFormulacion == 'porcentaje' ? v : null,
            cantidadKg: _tipoFormulacion == 'tabla_kg' ? v : null,
          );
        } else {
          final original = originalMap[ing.id];
          final coincide = _tipoFormulacion == 'porcentaje'
              ? (double.tryParse(original?.porcentajeInclusion ?? '') == v)
              : (double.tryParse(original?.cantidadKg ?? '') == v);
          if (!coincide) {
            await notifier.updateDietaInsumo(ing.id!, {
              if (_tipoFormulacion == 'porcentaje')
                'porcentaje_inclusion': v.toString()
              else
                'cantidad_kg': v.toString(),
            });
          }
        }
      }

      final idsUsados = _ingredientes.where((i) => i.id != null).map((i) => i.id!).toSet();
      for (final o in originales) {
        if (!idsUsados.contains(o.id)) {
          await notifier.deleteDietaInsumo(o.id);
        }
      }

      ref.invalidate(dietaInsumosProvider);
      if (mounted) {
        _mensaje('Dieta guardada correctamente.');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _mensaje(_mensajeError(e) ?? 'Error al guardar: $e');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumosAsync = ref.watch(insumosProvider);
    final dietaInsumosAsync = ref.watch(dietaInsumosProvider);
    dietaInsumosAsync.when(
      data: (todos) {
        if (!_listo) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _cargarIngredientes(todos));
        }
      },
      error: (e, _) {},
      loading: () {},
    );

    final insumos = insumosAsync.valueOrNull ?? const [];
    final disponibles = insumos
        .where((i) => !_ingredientes.any((ing) => ing.insumoId == i.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Dieta' : 'Nueva Dieta'),
      ),
      body: insumosAsync.when(
        data: (_) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la dieta',
                  hintText: 'Ej. Engorda cebú',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objetivo,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Objetivo',
                  hintText: 'Ej. engorda, lactancia, destete',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Indica el objetivo' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costo,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Costo estimado (\$/kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (d == null || d < 0) return 'Costo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kgCabeza,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Kg por cabeza (ración total)',
                  hintText: 'Opcional. Usado en fórmulas por porcentaje',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final d = double.tryParse(v.trim().replaceAll(',', '.'));
                  if (d == null || d <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _periodicidad,
                decoration: const InputDecoration(
                  labelText: 'Periodicidad',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'diaria', child: Text('Diaria (cada día)')),
                  DropdownMenuItem(value: 'semanal', child: Text('Semanal (cada 7 días)')),
                  DropdownMenuItem(value: 'quincenal', child: Text('Quincenal (cada 15 días)')),
                ],
                onChanged: (v) => setState(() => _periodicidad = v ?? 'diaria'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'porcentaje',
                    label: Text('Porcentaje'),
                    icon: Icon(Icons.percent),
                  ),
                  ButtonSegment(
                    value: 'tabla_kg',
                    label: Text('Tabla kg'),
                    icon: Icon(Icons.monitor_weight_outlined),
                  ),
                ],
                selected: {_tipoFormulacion},
                onSelectionChanged: (sel) {
                  setState(() {
                    _tipoFormulacion = sel.first;
                    _nuevoInsumoId = null;
                  });
                },
              ),
              const SizedBox(height: 4),
              Text(
                _tipoFormulacion == 'porcentaje'
                    ? 'Cada ingrediente se expresa como % del total de la ración.'
                    : 'Cada ingrediente indica los kg que come UNA cabeza en cada oportunidad.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 24),
              Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_ingredientes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Agrega al menos un insumo. La dieta sin ingredientes no puede consumirse.',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                ),
              ..._ingredientes.asMap().entries.map((entry) {
                final idx = entry.key;
                final ing = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ing.nombre,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: ing.valor,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: _tipoFormulacion == 'porcentaje' ? '%' : 'kg/cab',
                            suffixText: _tipoFormulacion == 'porcentaje' ? '%' : 'kg',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validarValorIngrediente,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () => _quitarIngrediente(idx),
                      ),
                    ],
                  ),
                );
              }),
              if (_tipoFormulacion == 'porcentaje' && _ingredientes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _totalPorcentaje > 100
                          ? Colors.red[50]
                          : (_totalPorcentaje < 100
                              ? Colors.amber[50]
                              : Colors.green[50]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _totalPorcentaje > 100
                              ? Icons.error_outline
                              : (_totalPorcentaje < 100
                                  ? Icons.info_outline
                                  : Icons.check_circle_outline),
                          size: 18,
                          color: _totalPorcentaje > 100
                              ? Colors.red
                              : (_totalPorcentaje < 100
                                  ? Colors.amber[900]
                                  : Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _totalPorcentaje > 100
                                ? '¡Más de 100%! Ajusta los ingredientes.'
                                : (_totalPorcentaje < 100
                                    ? 'Total ${_totalPorcentaje.toStringAsFixed(2)}%. El faltante se cubre con forrajes/forraje o agua.'
                                    : 'Total 100%. Ración balanceada.'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _nuevoInsumoId,
                      decoration: const InputDecoration(
                        labelText: 'Agregar insumo',
                        border: OutlineInputBorder(),
                      ),
                      items: disponibles
                          .map((i) => DropdownMenuItem<int?>(
                                value: i.id,
                                child: Text(i.nombre),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _nuevoInsumoId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        disponibles.isEmpty ? null : _agregarIngrediente,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const Divider(height: 24),
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'activa', child: Text('Activa')),
                  DropdownMenuItem(value: 'inactiva', child: Text('Inactiva')),
                ],
                onChanged: (v) => setState(() => _estado = v ?? 'activa'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Guardar Dieta',
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error cargando insumos: $e')),
      ),
    );
  }
}