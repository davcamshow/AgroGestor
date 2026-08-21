import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/animales_provider.dart';
import '../../core/theme/app_theme.dart';

class CalculadoraIAScreen extends ConsumerStatefulWidget {
  const CalculadoraIAScreen({super.key});

  @override
  ConsumerState<CalculadoraIAScreen> createState() =>
      _CalculadoraIAScreenState();
}

class _CalculadoraIAScreenState extends ConsumerState<CalculadoraIAScreen> {
  int? _selectedAnimalId;
  Map<String, dynamic>? _resultado;
  bool _isLoading = false;
  String? _error;
  dynamic _animal;
  DateTime? _fechaUltimoParto;
  int _diasInvolution = 45;
  int _diasGestacion = 283;

  Future<void> _calcularConIA(int animalId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _resultado = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.get('ia/calculadora-gestacion/?animal_id=$animalId');
      setState(() {
        _resultado = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha));
    } catch (_) {
      return fecha.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalesAsync = ref.watch(animalesNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de IA',
            style: TextStyle(color: Colors.white)),
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? AppTheme.info.withOpacity(0.15) : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'La fecha óptima de IA se calcula sumando:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Calculadora de Gestación con IA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Analiza el historial del animal, raza y ciclos previos\npara calcular la fecha óptima de IA',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Seleccionar Animal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            animalesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error: $err'),
              data: (animales) {
                final hembras = animales
                    .where((a) => a.sexo == 'H' && a.estado == 'activo')
                    .toList();
                return DropdownButtonFormField<int>(
                  value: _selectedAnimalId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seleccionar vaca',
                  ),
                  items: hembras
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                                '${a.numeroArete} - ${a.nombre ?? a.raza ?? "Sin nombre"}'),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      final api = ref.read(apiClientProvider);
                      final animalData = await api.get('/animales/$value/');
                      setState(() {
                        _selectedAnimalId = value;
                        _animal = animalData;
                        if (animalData['fecha_ultimo_parto'] != null) {
                          _fechaUltimoParto =
                              DateTime.parse(animalData['fecha_ultimo_parto']);
                        }
                      });
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [AppTheme.softShadowFor(theme.brightness)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Error: $_error')),
                  ],
                ),
              ),
            if (_resultado != null && !_isLoading) ...[
              if (_resultado!['fecha_ia_optima'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.success, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.pets, color: AppTheme.success, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Fecha Óptima para Inseminación:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFecha(_resultado!['fecha_ia_optima']),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(${_diasInvolution} días involución + ${_diasGestacion} días gestión)',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.warning.withOpacity(0.15)
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Fecha Estimada de Parto:',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFecha(_resultado!['fecha_parto_estimada']),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.darkSurfaceVariant : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.warning,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No hay registro de último parto',
                        style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : Colors.grey),
                      ),
                      Text(
                        'No se puede calcular la fecha óptima',
                        style: TextStyle(
                          color:
                              isDark ? AppTheme.darkTextSecondary : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles del Cálculo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Animal',
                        '${_resultado!['numero_arete']} - ${_resultado!['nombre'] ?? ''}'),
                    _buildDetailRow('Raza', _resultado!['raza'] ?? 'N/A'),
                    _buildDetailRow('Partos previos',
                        '${_resultado!['partos_previos'] ?? 0}'),
                    _buildDetailRow('Último parto',
                        _formatFecha(_resultado!['fecha_ultimo_parto'])),
                    _buildDetailRow('Días gestación',
                        '${_resultado!['dias_gestacion_calculados']}'),
                    _buildDetailRow(
                        'Días involución', '${_resultado!['dias_involucion']}'),
                    if (_resultado!['factores'] != null) ...[
                      const Divider(height: 16),
                      const Text('Factores considerados:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                      _buildDetailRow('Gestación base',
                          '${_resultado!['factores']['gestacion_base']} días'),
                      _buildDetailRow('Ajuste por raza',
                          '${_resultado!['factores']['ajuste_raza']} días'),
                      if (_resultado!['factores']['promedio_historial'] != null)
                        _buildDetailRow('Promedio historial',
                            '${_resultado!['factores']['promedio_historial']} días'),
                    ],
                  ],
                ),
              ),
            ] else if (!_isLoading && _error == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppTheme.darkSurfaceVariant : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Selecciona un animal para calcular',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  DateTime _calcularFechaParto() {
    return _fechaUltimoParto!
        .add(Duration(days: _diasInvolution + _diasGestacion));
  }
}
