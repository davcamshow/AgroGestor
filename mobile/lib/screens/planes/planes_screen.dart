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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/configuracion'),
        ),
        title: const Text('Planes de Suscripción'),
        backgroundColor: AppTheme.primary,
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
              data: (miPlan) => _buildMiPlanCard(context, miPlan),
            ),
            const SizedBox(height: 24),
            // Planes disponibles
            Text(
              'Planes Disponibles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            planesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (planes) => Column(
                children: planes.map((plan) {
                  final miPlan = miPlanAsync.value;
                  final planActual = miPlan?.plan.codigo ?? 'basico';
                  return _buildPlanCard(context, ref, plan, planActual);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiPlanCard(BuildContext context, InfoPlanUsuario miPlan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
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
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  miPlan.plan.nombre,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            miPlan.plan.precioMxn == 0 ? 'Gratis' : '\$${miPlan.plan.precioMxn.toStringAsFixed(0)}/mes',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(Icons.pets, '${_formatearLimite(miPlan.limiteAnimales)} animales'),
              const SizedBox(width: 16),
              _buildStatChip(Icons.people, '${_formatearLimite(miPlan.limiteUsuarios)} usuarios'),
            ],
          ),
          if (miPlan.plan.codigo != 'basico') ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (miPlan.incluyeReportesAvanzados) _buildFeatureChip('Reportes Avanzados'),
                if (miPlan.incluyeApi) _buildFeatureChip('API'),
                if (miPlan.soportePrioritario) _buildFeatureChip('Soporte Prioritario'),
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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  String _formatearLimite(int limite) {
    if (limite >= 999999) return '∞';
    return limite.toString();
  }

  Widget _buildPlanCard(BuildContext context, WidgetRef ref, plan, String planActualCodigo) {
    final esPlanActual = plan.codigo == planActualCodigo;
    final esBasico = plan.codigo == 'basico';
    final esProductor = plan.codigo == 'productor';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: esProductor ? Border.all(color: AppTheme.accent, width: 2) : null,
        boxShadow: [AppTheme.softShadow],
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
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (esProductor) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        plan.precioMxn == 0 ? 'Gratis' : '\$${plan.precioMxn.toStringAsFixed(0)}/mes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: esBasico ? Colors.grey : AppTheme.primary,
                        ),
                      ),
                      if (plan.precioAnual > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '\$${plan.precioAnual.toStringAsFixed(0)}/año',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
          _buildPlanFeature(Icons.pets, 'Hasta ${_formatearLimite(plan.limiteAnimales)} animales'),
          _buildPlanFeature(Icons.people, '${_formatearLimite(plan.limiteUsuarios) == '∞' ? 'Usuarios ilimitados' : 'Hasta ${_formatearLimite(plan.limiteUsuarios)} usuarios'}'),
          if (plan.incluyeModuloAnimales) _buildPlanFeature(Icons.check_circle, 'Módulo Animales'),
          if (plan.incluyeModuloLotes) _buildPlanFeature(Icons.check_circle, 'Módulo Lotes'),
          if (plan.incluyeModuloDietas) _buildPlanFeature(Icons.check_circle, 'Módulo Dietas'),
          if (plan.incluyeModuloSanitaria) _buildPlanFeature(Icons.check_circle, 'Módulo Sanitaria'),
          if (plan.incluyeReportesAvanzados) _buildPlanFeature(Icons.analytics, 'Reportes Avanzados'),
          if (plan.incluyeApi) _buildPlanFeature(Icons.api, 'API de Integración'),
          if (plan.soportePrioritario) _buildPlanFeature(Icons.support_agent, 'Soporte Prioritario'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: esPlanActual ? null : () => _mostrarDialogoUpgrade(context, ref, plan.codigo),
              style: ElevatedButton.styleFrom(
                backgroundColor: esProductor ? AppTheme.accent : AppTheme.primary,
              ),
              child: Text(esPlanActual ? 'Plan Actual' : 'Cambiar a este plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.success),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _mostrarDialogoUpgrade(BuildContext context, WidgetRef ref, String planCodigo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Plan'),
        content: const Text('¿Estás seguro de que quieres cambiar a este plan?'),
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
                await client.post('planes/cambiar/', data: {'plan_codigo': planCodigo});
                ref.invalidate(miPlanProvider);
                ref.invalidate(planesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Plan actualizado correctamente')),
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