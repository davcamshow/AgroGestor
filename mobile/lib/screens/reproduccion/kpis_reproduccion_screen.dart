import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class KPIsReproduccionScreen extends ConsumerStatefulWidget {
  const KPIsReproduccionScreen({super.key});

  @override
  ConsumerState<KPIsReproduccionScreen> createState() => _KPIsReproduccionScreenState();
}

class _KPIsReproduccionScreenState extends ConsumerState<KPIsReproduccionScreen> {
  Map<String, dynamic>? _kpis;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadKPIs());
  }

  Future<void> _loadKPIs() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/kpis/reproductivos/');
      setState(() {
        _kpis = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KPIs Reproductivos', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadKPIs,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadKPIs,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCard(
                          'Tasa de Concepción',
                          '${_kpis?['tasa_concepcion'] ?? 0}%',
                          'Servicios que resultaron en gestación',
                          Icons.favorite,
                          _getColorTasa(_kpis?['tasa_concepcion'] ?? 0, 50),
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          'Tasa de Natalidad',
                          '${_kpis?['tasa_natalidad'] ?? 0}%',
                          'Gestaciones que resultaron en parto',
                          Icons.child_friendly,
                          _getColorTasa(_kpis?['tasa_natalidad'] ?? 0, 80),
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          'Intervalo Entre Partos',
                          '${(_kpis?['iep_dias'] ?? 283).toString().split('.')[0]} días',
                          'Promedio de días entre partos',
                          Icons.calendar_month,
                          AppTheme.secondary,
                        ),
                        const SizedBox(height: 12),
                        _buildCard(
                          'Total Hembras',
                          '${_kpis?['total_hembras'] ?? 0}',
                          'Vacas activas en edad reproductiva',
                          Icons.pets,
                          AppTheme.primary,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Resumen del Período',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildResumenRow(),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadKPIs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCard(String titulo, String valor, String descripcion, IconData icono, Color color) {
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
            child: Icon(icono, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow() {
    final nacimientos = _kpis?['nacimientos'] ?? {};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildResumenItem('Servicios', _kpis?['servicios'] ?? 0),
          _buildResumenItem('Gestaciones', _kpis?['gestaciones'] ?? 0),
          _buildResumenItem('Partos', _kpis?['partos'] ?? 0),
          _buildResumenItem('Nacimientos', nacimientos['total'] ?? 0),
          _buildResumenItem('  - Machos', nacimientos['machos'] ?? 0),
          _buildResumenItem('  - Hembra', nacimientos['hembra'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, int valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '$valor',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getColorTasa(num valor, num objetivo) {
    if (valor >= objetivo) return AppTheme.success;
    if (valor >= objetivo * 0.8) return AppTheme.warning;
    return AppTheme.error;
  }
}