import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/theme/app_theme.dart';

class ReporteConsumoScreen extends ConsumerStatefulWidget {
  const ReporteConsumoScreen({super.key});

  @override
  ConsumerState<ReporteConsumoScreen> createState() =>
      _ReporteConsumoScreenState();
}

class _ReporteConsumoScreenState extends ConsumerState<ReporteConsumoScreen> {
  Map<String, dynamic>? _reporte;
  bool _isLoading = true;
  String? _error;
  int _dias = 30;
  int? _loteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReporte());
  }

  Future<void> _loadReporte() async {
    try {
      String endpoint = '/reporte/consumo/?dias=$_dias';
      if (_loteId != null) {
        endpoint += '&lote=$_loteId';
      }
      final api = ref.read(apiClientProvider);
      final response = await api.get(endpoint);
      setState(() {
        _reporte = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _cambiarPeriodo(int dias) {
    setState(() {
      _dias = dias;
      _isLoading = true;
    });
    _loadReporte();
  }

  @override
  Widget build(BuildContext context) {
    final lotesAsync = ref.watch(lotesNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.success;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Consumo'),
      ),
      body: Column(
        children: [
          Container(
            color: theme.appBarTheme.backgroundColor,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período',
                  style: TextStyle(
                      color:
                          theme.appBarTheme.foregroundColor?.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodoChip(7, '7 días', theme),
                      _buildPeriodoChip(15, '15 días', theme),
                      _buildPeriodoChip(30, '30 días', theme),
                      _buildPeriodoChip(60, '60 días', theme),
                      _buildPeriodoChip(90, '90 días', theme),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Filtrar por Lote',
                  style: TextStyle(
                      color:
                          theme.appBarTheme.foregroundColor?.withOpacity(0.7)),
                ),
                const SizedBox(height: 8),
                lotesAsync.when(
                  data: (lotes) => DropdownButtonFormField<int?>(
                    value: _loteId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    hint: const Text('Todos los lotes'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos los lotes'),
                      ),
                      ...lotes.map((l) => DropdownMenuItem(
                            value: l.id,
                            child: Text('${l.nombre} (${l.cantidadCabezas})'),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _loteId = value;
                        _isLoading = true;
                      });
                      _loadReporte();
                    },
                  ),
                  loading: () => Text('Cargando...',
                      style:
                          TextStyle(color: theme.appBarTheme.foregroundColor)),
                  error: (_, __) => Text('Error',
                      style:
                          TextStyle(color: theme.appBarTheme.foregroundColor)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : RefreshIndicator(
                        onRefresh: _loadReporte,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMetricaCard(
                                'Total kg Suministrados',
                                '${_reporte?['total_kg']?.toStringAsFixed(1) ?? 0} kg',
                                Icons.scale,
                                primaryColor,
                                theme,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'Costo Total',
                                '\$${_reporte?['costo_total']?.toStringAsFixed(2) ?? 0}',
                                Icons.attach_money,
                                successColor,
                                theme,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'Animales Atendidos',
                                '${_reporte?['animales_atendidos'] ?? 0}',
                                Icons.pets,
                                theme.colorScheme.secondary,
                                theme,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'kg por Animal',
                                '${_reporte?['kg_por_animal']?.toStringAsFixed(1) ?? 0} kg',
                                Icons.analytics,
                                isDark ? Colors.orange[300]! : Colors.orange,
                                theme,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'Costo por Animal',
                                '\$${_reporte?['costo_por_animal']?.toStringAsFixed(2) ?? 0}',
                                Icons.monetization_on,
                                isDark ? Colors.purple[300]! : Colors.purple,
                                theme,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadReporte,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar'),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoChip(int dias, String label, ThemeData theme) {
    final selected = _dias == dias;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _cambiarPeriodo(dias),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        labelStyle: TextStyle(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.appBarTheme.foregroundColor,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, IconData icono,
      Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadowFor(theme.brightness)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
