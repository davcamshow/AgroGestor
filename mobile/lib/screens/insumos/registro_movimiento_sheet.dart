import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/insumo.dart';
import '../../core/providers/insumos_provider.dart';
import '../../core/theme/app_theme.dart';

class RegistroMovimientoSheet extends ConsumerStatefulWidget {
  final Insumo insumo;

  const RegistroMovimientoSheet({super.key, required this.insumo});

  @override
  ConsumerState<RegistroMovimientoSheet> createState() =>
      _RegistroMovimientoSheetState();
}

class _RegistroMovimientoSheetState
    extends ConsumerState<RegistroMovimientoSheet> {
  String _tipo = 'entrada';
  final _cantidadCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _costoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final cantidad = double.tryParse(_cantidadCtrl.text.trim().replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad válida mayor a 0'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final costo = double.tryParse(_costoCtrl.text.trim().replaceAll(',', '.'));
    setState(() => _isLoading = true);
    try {
      await ref.read(insumosNotifierProvider.notifier).addMovimiento(
            widget.insumo.id,
            _tipo,
            cantidad,
            costoUnitario: costo != null && costo > 0 ? costo : null,
            notas: _notasCtrl.text.trim(),
          );
      if (mounted) {
        final verbo = _tipo == 'entrada' ? 'agregado' : 'retirado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock $verbo correctamente'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar movimiento: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Registrar Movimiento',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.insumo.nombre} — '
              'Stock actual: ${widget.insumo.cantidadActualKg} kg',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'entrada',
                  label: Text('Entrada'),
                  icon: Icon(Icons.add_circle_outline),
                ),
                ButtonSegment(
                  value: 'salida',
                  label: Text('Salida'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: _isLoading
                  ? null
                  : (selection) => setState(() => _tipo = selection.first),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _cantidadCtrl,
              enabled: !_isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad (kg)',
                prefixIcon: const Icon(Icons.scale),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _costoCtrl,
              enabled: !_isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Costo unitario (opcional)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notasCtrl,
              enabled: !_isLoading,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Ej. Compra proveedor, consumo semanal...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _confirmar,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}