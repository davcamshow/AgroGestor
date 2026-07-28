import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/providers/lotes_provider.dart'; // Asegúrate de apuntar a tu provider de lotes real
import '../../core/theme/app_theme.dart';

class MoverLoteSheet extends ConsumerStatefulWidget {
  final Animal animal;

  const MoverLoteSheet({super.key, required this.animal});

  @override
  ConsumerState<MoverLoteSheet> createState() => _MoverLoteSheetState();
}

class _MoverLoteSheetState extends ConsumerState<MoverLoteSheet> {
  int? _loteDestinoId;
  DateTime _fechaMovimiento = DateTime.now();
  final _notasCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el provider de lotes para llenar el dropdown
    final lotesAsync = ref.watch(lotesNotifierProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ), // Ajusta el padding para el teclado
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mover de Lote',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Animal: ${widget.animal.nombre ?? widget.animal.numeroArete} (Arete: ${widget.animal.numeroArete})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Dropdown de Lotes con manejo de estados asíncronos
            lotesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text(
                  'Error al cargar lotes: $err', // Considerar usar un TextTheme para esto
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              data: (lotes) {
                // Filtramos el listado para omitir el lote en el que ya se encuentra
                final destinosDisponibles =
                    lotes.where((l) => l.id != widget.animal.loteId).toList();

                if (destinosDisponibles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No hay otros lotes creados para elegir como destino.', // Considerar usar un TextTheme para esto
                      style: TextStyle(
                          color: AppTheme.warning,
                          fontWeight: FontWeight
                              .w500), // Mantener AppTheme.warning para este caso específico
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Lote Destino',
                    prefixIcon: Icon(Icons.group_work_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  value: _loteDestinoId,
                  items: destinosDisponibles.map((lote) {
                    return DropdownMenuItem<int>(
                      value: lote.id,
                      child: Text(lote.nombre),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _loteDestinoId = val),
                );
              },
            ),
            const SizedBox(height: 16),

            // Selector de Fecha
            const Text('Fecha del Cambio de Corral',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaMovimiento,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _fechaMovimiento = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd/MM/yyyy').format(_fechaMovimiento),
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notas de Campo
            const Text('Notas de Manejo en Campo',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _notasCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej. Traslado por inicio de etapa de engorda...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de Acción
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: (_loteDestinoId == null || _isLoading)
                      ? null
                      : _ejecutarMovimiento,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary),
                        )
                      : const Icon(Icons.swap_horiz),
                  label: const Text('Confirmar Cambio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ejecutarMovimiento() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(animalesNotifierProvider.notifier).moverLote(
            animalId: widget.animal.id,
            loteOrigenId: widget.animal.loteId,
            loteDestinoId: _loteDestinoId!,
            fechaMovimiento: DateFormat('yyyy-MM-dd').format(_fechaMovimiento),
            notas: _notasCtrl.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                '✅ El animal ha sido movido de lote de manera exitosa.'), // Considerar usar un TextTheme para esto
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context); // Cerrar Modal
      }
    } catch (e) {
      setState(() =>
          _isLoading = false); // Asegurarse de resetear el estado de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error al cambiar de lote: $e'), // Considerar usar un TextTheme para esto
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
