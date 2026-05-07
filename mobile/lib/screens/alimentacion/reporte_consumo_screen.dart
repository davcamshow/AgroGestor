import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/theme/app_theme.dart';

class ReporteConsumoScreen extends ConsumerStatefulWidget {
  const ReporteConsumoScreen({super.key});

  @override
  ConsumerState<ReporteConsumoScreen> createState() => _ReporteConsumoScreenState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Consumo', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Período',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodoChip(7, '7 días'),
                      _buildPeriodoChip(15, '15 días'),
                      _buildPeriodoChip(30, '30 días'),
                      _buildPeriodoChip(60, '60 días'),
                      _buildPeriodoChip(90, '90 días'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Filtrar por Lote',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                lotesAsync.when(
                  data: (lotes) => DropdownButtonFormField<int?>(
                    value: _loteId,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  loading: () => const Text('Cargando...', style: TextStyle(color: Colors.white)),
                  error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
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
                                AppTheme.primary,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'Costo Total',
                                '\$${_reporte?['costo_total']?.toStringAsFixed(2) ?? 0}',
                                Icons.attach_money,
                                AppTheme.success,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'Animales Atendidos',
                                '${_reporte?['animales_atendidos'] ?? 0}',
                                Icons.pets,
                                AppTheme.secondary,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'kg por Animal',
                                '${_reporte?['kg_por_animal']?.toStringAsFixed(1) ?? 0} kg',
                                Icons.analytics,
                                Colors.orange,
                              ),
                              const SizedBox(height: 12),
                              _buildMetricaCard(
                                'Costo por Animal',
                                '\$${_reporte?['costo_por_animal']?.toStringAsFixed(2) ?? 0}',
                                Icons.monetization_on,
                                Colors.purple,
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

  Widget _buildPeriodoChip(int dias, String label) {
    final selected = _dias == dias;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _cambiarPeriodo(dias),
        selectedColor: Colors.white,
        checkmarkColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: selected ? AppTheme.primary : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.softShadow],
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
                    color: Colors.grey[600],
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