import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/models/lote.dart';
import '../../core/providers/lotes_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';

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
  DateTime? _ultimaActualizacion;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReporte());
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isLoading) _loadReporte();
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _loadReporte() async {
    try {
      String endpoint = '/reporte/consumo/?dias=$_dias';
      if (_loteId != null) {
        endpoint += '&lote=$_loteId';
      }
      final api = ref.read(apiClientProvider);
      try {
        final response = await api.get(endpoint, forceRefresh: true);
        _aplicarReporte(response);
      } catch (_) {
        // Si la red no está disponible (o el refresh falla), se intenta
        // servir la última respuesta en caché para no terminar en pantalla
        // de error.
        final cached = await api.get(endpoint);
        _aplicarReporte(cached);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _aplicarReporte(dynamic response) {
    if (mounted) {
      setState(() {
        _reporte = response as Map<String, dynamic>;
        _isLoading = false;
        _error = null;
        _ultimaActualizacion = DateTime.now();
      });
    }
  }

  void _cambiarPeriodo(int dias) {
    setState(() => _isLoading = true);
    _dias = dias;
    _loadReporte();
  }

  double _num(String key, {double def = 0}) {
    final v = _reporte?[key];
    return _d(v, def: def);
  }

  double _d(dynamic v, {double def = 0}) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  int _i(dynamic v, {int def = 0}) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final n = double.tryParse(v);
      return n != null ? n.toInt() : def;
    }
    return def;
  }

  @override
  Widget build(BuildContext context) {
    final lotesAsync = ref.watch(lotesNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.success;
    final warningColor = isDark ? AppTheme.darkWarning : AppTheme.warning;
    final errorColor = theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Consumo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReporte,
            tooltip: 'Actualizar ahora',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(theme, lotesAsync, warningColor, primaryColor),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    itemCount: 6,
                    itemBuilder: (_, i) => LoadingShimmerListItem(),
                  )
                : _error != null
                    ? _buildError(errorColor)
                    : RefreshIndicator(
                        onRefresh: _loadReporte,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildActualizadoEn(theme, successColor),
                            const SizedBox(height: 12),
                            _buildKpis(theme, primaryColor, successColor,
                                warningColor, errorColor),
                            if (_num('alerta_insumos') > 0) ...[
                              const SizedBox(height: 12),
                              _buildAlertaStrip(theme, warningColor),
                            ],
                            const SizedBox(height: 24),
                            _buildSectionHeader(theme, 'Gastos por Lote',
                                Icons.warehouse, primaryColor),
                            const SizedBox(height: 8),
                            _buildGastosPorLote(theme, primaryColor),
                            const SizedBox(height: 24),
                            _buildSectionHeader(theme, 'Insumos Gastados',
                                Icons.trending_down, errorColor),
                            const SizedBox(height: 8),
                            _buildInsumosGastados(theme, errorColor),
                            const SizedBox(height: 24),
                            _buildSectionHeader(theme, 'Insumos Disponibles',
                                Icons.inventory_2, successColor),
                            const SizedBox(height: 8),
                            _buildInsumosDisponibles(theme, successColor,
                                warningColor),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(ThemeData theme, AsyncValue<List<Lote>> lotesAsync,
      Color warningColor, Color primary) {
    return Container(
      color: theme.appBarTheme.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Período',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodoChip(7, '7 días', theme, warningColor),
                _buildPeriodoChip(15, '15 días', theme, warningColor),
                _buildPeriodoChip(30, '30 días', theme, warningColor),
                _buildPeriodoChip(60, '60 días', theme, warningColor),
                _buildPeriodoChip(90, '90 días', theme, warningColor),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Filtrar por Lote',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          lotesAsync.when(
            data: (lotes) => DropdownButtonFormField<int?>(
              value: _loteId,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text('Todos los lotes'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Todos los lotes'),
                ),
                ...lotes.map(
                  (l) => DropdownMenuItem(
                    value: l.id,
                    child: Text('${l.nombre} (${l.cabezasEfectivas} cab.)'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _isLoading = true);
                _loteId = value;
                _loadReporte();
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) =>
                Text('Error al cargar lotes', style: TextStyle(color: warningColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoChip(int dias, String label, ThemeData theme, Color warningColor) {
    final selected = _dias == dias;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _cambiarPeriodo(dias),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        labelStyle: TextStyle(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActualizadoEn(ThemeData theme, Color successColor) {
    final hora = _ultimaActualizacion == null
        ? '--:--'
        : DateFormat('HH:mm:ss').format(_ultimaActualizacion!);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: successColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Datos en tiempo real · actualizado $hora',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          icon: const Icon(Icons.refresh),
          tooltip: 'Recargar',
          onPressed: _isLoading ? null : _loadReporte,
        ),
      ],
    );
  }

  Widget _buildKpis(ThemeData theme, Color primary, Color success,
      Color warning, Color error) {
    final totalKg = _num('total_kg');
    final costoTotal = _num('costo_total');
    final promDiario = _num('promedio_diario_kg');
    final valorInv = _num('valor_inventario_actual');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                theme,
                Icons.scale,
                'Consumo Total',
                '${totalKg.toStringAsFixed(1)} kg',
                primary,
                '$promDiario kg/día promedio',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                theme,
                Icons.payments,
                'Gasto en alimento',
                '\$${costoTotal.toStringAsFixed(2)}',
                success,
                '${_num('registros')} raciones',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                theme,
                Icons.pets,
                'Animales atendidos',
                '${_num('animales_atendidos', def: 0).round()}',
                warning,
                'cabeza-días en $diasLabel()',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                theme,
                Icons.savings,
                'Valor inventario',
                '\$${valorInv.toStringAsFixed(2)}',
                error,
                '${_num('alerta_insumos', def: 0).round()} con bajo stock',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                theme,
                Icons.calendar_view_month,
                'Proyección 30 días',
                '${_num('proyeccion_30_dias_kg').toStringAsFixed(0)} kg',
                theme.colorScheme.secondary,
                '\$${_num('proyeccion_30_dias_costo').toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                theme,
                Icons.analytics,
                'Costo / kg promedio',
                '\$${_num('costo_promedio_por_kg').toStringAsFixed(2)}',
                primary,
                'kg/cabeza ${_num('kg_por_animal').toStringAsFixed(2)} · '
                '\$${_num('costo_por_animal').toStringAsFixed(2)}/cab.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String diasLabel() => '$_dias días';

  Widget _kpiCard(
    ThemeData theme,
    IconData icon,
    String titulo,
    String valor,
    Color color, [
    String? subtitulo,
  ]) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [AppTheme.softShadowFor(theme.brightness)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertaStrip(ThemeData theme, Color warningColor) {
    final alertas = _num('alerta_insumos', def: 0).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$alertas insumo(s) por debajo del stock mínimo. '
              'Revisa la sección de disponibles.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String titulo, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGastosPorLote(ThemeData theme, Color primary) {
    final porLote = (_reporte?['por_lote'] as List?) ?? [];
    if (porLote.isEmpty) {
      return _emptyCard(theme, Icons.warehouse_outlined,
          'Sin raciones registradas en el período');
    }
    return Column(
      children: porLote.map((lote) {
        final nombre = lote['lote_nombre'] as String? ?? 'Lote';
        final cabezas = _i(lote['cabezas']);
        final kg = _d(lote['total_kg']);
        final costo = _d(lote['costo_total']);
        final costoPorCabeza = _d(lote['costo_por_cabeza']);
        final costoPorKg = _d(lote['costo_por_kg']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withOpacity(0.35)),
            boxShadow: [AppTheme.softShadowFor(theme.brightness)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text('$cabezas cab.'),
                    backgroundColor: primary.withOpacity(0.12),
                    labelStyle: TextStyle(color: primary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _gastoMini(theme, 'Kg consumidos', '${kg.toStringAsFixed(1)} kg', primary),
                  ),
                  Expanded(
                    child: _gastoMini(theme, 'Gasto total', '\$${costo.toStringAsFixed(2)}', theme.colorScheme.secondary),
                  ),
                  Expanded(
                    child: _gastoMini(theme, 'Gasto / cabeza', '\$${costoPorCabeza.toStringAsFixed(2)}', theme.colorScheme.tertiary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Costo por kg: \$${costoPorKg.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _gastoMini(
      ThemeData theme, String titulo, String valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInsumosGastados(ThemeData theme, Color errorColor) {
    final gastados = (_reporte?['insumos_gastados'] as List?) ?? [];
    if (gastados.isEmpty) {
      return _emptyCard(theme, Icons.trending_down,
          'Aún no hay salidas registradas en el período');
    }
    final maxKg = gastados
        .map((e) => _d(e['kg']))
        .fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: gastados.map((entry) {
        final nombre = entry['nombre'] as String? ?? 'Insumo';
        final kg = _d(entry['kg']);
        final costo = _d(entry['costo_total']);
        final movs = _i(entry['movimientos']);
        final progreso = maxKg > 0 ? kg / maxKg : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [AppTheme.softShadowFor(theme.brightness)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${kg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progreso.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation(errorColor),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${costo.toStringAsFixed(2)} en $movs salida(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsumosDisponibles(
      ThemeData theme, Color successColor, Color warningColor) {
    final disponibles = (_reporte?['insumos_disponibles'] as List?) ?? [];
    if (disponibles.isEmpty) {
      return _emptyCard(theme, Icons.inventory_2,
          'Sin insumos registrados en tu inventario');
    }
    return Column(
      children: disponibles.map((entry) {
        final nombre = entry['nombre'] as String? ?? 'Insumo';
        final stock = _d(entry['stock_kg']);
        final minimo = _d(entry['stock_minimo_kg']);
        final costo = _d(entry['costo_kg']);
        final valor = _d(entry['valor_total']);
        final bajo = entry['bajo_stock'] == true;
        final color = bajo ? warningColor : successColor;
        final progreso = minimo > 0 ? stock / minimo : 1.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bajo
                ? warningColor.withOpacity(0.1)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bajo ? warningColor : theme.dividerColor),
            boxShadow: [AppTheme.softShadowFor(theme.brightness)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      bajo ? 'Bajo stock' : 'Disponible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stock.toStringAsFixed(1)} / ${minimo.toStringAsFixed(0)} kg mín.',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '\$${valor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (progreso / 2).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${costo.toStringAsFixed(2)}/kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyCard(ThemeData theme, IconData icon, String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color errorColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: errorColor),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el reporte'),
            const SizedBox(height: 8),
            Text(
              'Verifica tu conexión y vuelve a intentarlo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadReporte,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}