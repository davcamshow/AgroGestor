import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/models/plan_suscripcion.dart';
import '../../core/providers/planes_provider.dart';
import '../../core/theme/app_theme.dart';

class PlanesScreen extends ConsumerWidget {
  const PlanesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planesAsync = ref.watch(planesProvider);
    final miPlanAsync = ref.watch(miPlanProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/configuracion'),
        ),
        title: const Text('Planes de Suscripción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mi plan actual
            miPlanAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (miPlan) => _buildMiPlanCard(context, miPlan, theme),
            ),
            const SizedBox(height: 24),
            // Planes disponibles
            Text(
              'Planes Disponibles',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            planesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (planes) => Column(
                children: planes.map((plan) {
                  final miPlan = miPlanAsync.value;
                  final planActual = miPlan?.plan.codigo ?? 'basico';
                  return _buildPlanCard(context, ref, plan, planActual, theme);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiPlanCard(
      BuildContext context, InfoPlanUsuario miPlan, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradientFor(theme.brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi Plan Actual',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  miPlan.plan.nombre,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            miPlan.plan.precioMxn == 0
                ? 'Gratis'
                : '\$${miPlan.plan.precioMxn.toStringAsFixed(0)}/mes',
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(Icons.pets,
                  '${_formatearLimite(miPlan.limiteAnimales)} animales'),
              const SizedBox(width: 16),
              _buildStatChip(Icons.people,
                  '${_formatearLimite(miPlan.limiteUsuarios)} usuarios'),
            ],
          ),
          if (miPlan.plan.codigo != 'basico') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (miPlan.incluyeReportesAvanzados)
                  _buildFeatureChip('Reportes Avanzados'),
                if (miPlan.incluyeApi) _buildFeatureChip('API'),
                if (miPlan.soportePrioritario)
                  _buildFeatureChip('Soporte Prioritario'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  String _formatearLimite(int limite) {
    if (limite >= 999999) return '∞';
    return limite.toString();
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, plan,
      String planActualCodigo, ThemeData theme) {
    final esPlanActual = plan.codigo == planActualCodigo;
    final esBasico = plan.codigo == 'basico';
    final esProductor = plan.codigo == 'productor';
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppTheme.darkSuccess : AppTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: esProductor
            ? Border.all(color: theme.colorScheme.secondary, width: 2)
            : null,
        boxShadow: [AppTheme.softShadowFor(theme.brightness)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.nombre,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (esProductor) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'POPULAR',
                            style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkBackground
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        plan.precioMxn == 0
                            ? 'Gratis'
                            : '\$${plan.precioMxn.toStringAsFixed(0)}/mes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: esBasico
                              ? theme.textTheme.bodySmall?.color
                              : theme.colorScheme.primary,
                        ),
                      ),
                      if (plan.precioAnual > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '\$${plan.precioAnual.toStringAsFixed(0)}/año',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPlanFeature(
              Icons.pets,
              'Hasta ${_formatearLimite(plan.limiteAnimales)} animales',
              successColor),
          _buildPlanFeature(
              Icons.people,
              '${_formatearLimite(plan.limiteUsuarios) == '∞' ? 'Usuarios ilimitados' : 'Hasta ${_formatearLimite(plan.limiteUsuarios)} usuarios'}',
              successColor),
          if (plan.incluyeModuloAnimales)
            _buildPlanFeature(
                Icons.check_circle, 'Módulo Animales', successColor),
          if (plan.incluyeModuloLotes)
            _buildPlanFeature(Icons.check_circle, 'Módulo Lotes', successColor),
          if (plan.incluyeModuloDietas)
            _buildPlanFeature(
                Icons.check_circle, 'Módulo Dietas', successColor),
          if (plan.incluyeModuloSanitaria)
            _buildPlanFeature(
                Icons.check_circle, 'Módulo Sanitaria', successColor),
          if (plan.incluyeReportesAvanzados)
            _buildPlanFeature(
                Icons.analytics, 'Reportes Avanzados', successColor),
          if (plan.incluyeApi)
            _buildPlanFeature(Icons.api, 'API de Integración', successColor),
          if (plan.soportePrioritario)
            _buildPlanFeature(
                Icons.support_agent, 'Soporte Prioritario', successColor),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: esPlanActual
                  ? null
                  : () => _mostrarDialogoUpgrade(context, ref, plan.codigo),
              style: ElevatedButton.styleFrom(
                backgroundColor: esProductor
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                foregroundColor: esProductor && isDark
                    ? AppTheme.darkBackground
                    : Colors.white,
              ),
              child: Text(esPlanActual ? 'Plan Actual' : 'Cambiar a este plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, String text, Color successColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: successColor),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _mostrarDialogoUpgrade(
      BuildContext context, WidgetRef ref, String planCodigo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Plan'),
        content:
            const Text('¿Estás seguro de que quieres cambiar a este plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final client = ref.read(apiClientProvider);
                await client
                    .post('planes/cambiar/', data: {'plan_codigo': planCodigo});
                ref.invalidate(miPlanProvider);
                ref.invalidate(planesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Plan actualizado correctamente')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
