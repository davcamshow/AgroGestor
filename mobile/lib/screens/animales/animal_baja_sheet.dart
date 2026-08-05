import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/models/animal.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class AnimalBajaSheet extends ConsumerStatefulWidget {
  final Animal animal;

  const AnimalBajaSheet({super.key, required this.animal});

  @override
  ConsumerState<AnimalBajaSheet> createState() => _AnimalBajaSheetState();
}

class _AnimalBajaSheetState extends ConsumerState<AnimalBajaSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _causaSeleccionada;
  late DateTime _fechaBaja;
  late TextEditingController _notasCtrl;
  bool _isLoading = false;

  static const List<(String, String, IconData)> _causaOptions = [
    ('vendido', 'Venta', Icons.sell_outlined),
    ('muerto', 'Muerte', Icons.close_outlined),
    ('transferido', 'Transferencia', Icons.swap_horiz),
  ];

  @override
  void initState() {
    super.initState();
    _causaSeleccionada = 'vendido'; // Valor por defecto
    _fechaBaja = DateTime.now();
    _notasCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrarBaja() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(animalesNotifierProvider.notifier).registrarBaja(
            animalId: widget.animal.id,
            causa: _causaSeleccionada,
            fecha: DateFormat('yyyy-MM-dd').format(_fechaBaja),
            notas: _notasCtrl.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context, true); // true = baja registrada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'Animal dado de baja: ${_causaSeleccionada.capitalize()}',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar baja: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isLoading, // Evita cerrar si está cargando
      onPopInvoked: (didPop) {
        if (didPop) return;
        // No hay cambios complejos que descartar en esta hoja, solo permite cerrar si no está cargando
        if (!_isLoading) {
          Navigator.pop(context);
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7, // Ajusta el tamaño inicial según sea necesario
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
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
                            Text(
                              'Dar de Baja Animal',
                              style: theme.textTheme.headlineSmall,
                            ),
                            Text(
                              'Animal: ${widget.animal.nombre ?? widget.animal.numeroArete}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        _buildSection(
                            'Motivo de Baja', Icons.info_outline, theme),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _causaOptions.map((opt) {
                            final (valor, label, icon) = opt;
                            final seleccionado = _causaSeleccionada == valor;

                            return FilterChip(
                              elevation: seleccionado ? 2 : 0,
                              pressElevation: 4,
                              avatar: Icon(
                                icon,
                                size: 16,
                                color: seleccionado
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                              label: Text(label),
                              selected: seleccionado,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _causaSeleccionada = valor);
                                }
                              },
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              shadowColor:
                                  theme.colorScheme.primary.withOpacity(0.4),
                              checkmarkColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: seleccionado
                                      ? theme.colorScheme.primary
                                      : theme.dividerColor,
                                  width: seleccionado ? 1.5 : 1,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: seleccionado
                                    ? theme.colorScheme.onPrimary
                                    : theme.textTheme.bodyMedium?.color,
                                fontWeight: seleccionado
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                            'Fecha de Baja', Icons.calendar_today, theme),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaBaja,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: theme.copyWith(
                                    colorScheme: theme.colorScheme.copyWith(
                                      primary: theme.colorScheme
                                          .primary, // Color de fondo del encabezado
                                      onPrimary: theme.colorScheme
                                          .onPrimary, // Color del texto del encabezado
                                      surface: theme.colorScheme
                                          .surface, // Color de fondo del calendario
                                      onSurface: theme.colorScheme
                                          .onSurface, // Color del texto del calendario
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: theme.colorScheme
                                            .primary, // Color de los botones OK/Cancelar
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _fechaBaja = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_fechaBaja),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSection(
                            'Notas (opcional)', Icons.notes_outlined, theme),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notasCtrl,
                          maxLines: 3,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Detalle adicional sobre la baja...',
                            hintStyle: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 13),
                            filled: true,
                            fillColor:
                                theme.colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(12),
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
                                    : () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _registrarBaja,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              theme.colorScheme.onError),
                                        ),
                                      )
                                    : const Text('Confirmar Baja'),
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

  Widget _buildSection(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
