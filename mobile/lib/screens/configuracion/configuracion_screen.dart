import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _ranchNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _ranchNameController = TextEditingController();

    final authState = ref.read(authProvider);
    if (authState.user != null) {
      _nameController.text = authState.user!.nombre_completo;
      _phoneController.text = authState.user!.telefono ?? '';
      _ranchNameController.text =
          authState.user!.nombre_rancho ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ranchNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
        nombreCompleto: _nameController.text,
        telefono: _phoneController.text,
        nombreRancho: _ranchNameController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar y nombre
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Text(
                        user?.nombre_completo[0].toUpperCase() ?? 'B',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(),
                  const SizedBox(height: 12),
                  Text(
                    user?.nombre_completo ?? 'Usuario',
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'email@example.com',
                    style: Theme.of(context)
                        .textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.2),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Sección Perfil
            _buildSectionTitle(context, 'Perfil', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Nombre Completo',
              icon: Icons.person_outline,
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneController,
              label: 'Teléfono',
              icon: Icons.phone_outlined,
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),
            const SizedBox(height: 24),
            // Sección Rancho
            _buildSectionTitle(context, 'Mi Rancho', Icons.agriculture),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _ranchNameController,
              label: 'Nombre del Rancho',
              icon: Icons.business_outlined,
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.3),
            const SizedBox(height: 24),
            // Botón guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSave,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Guardar cambios'),
            )
                .animate()
                .fadeIn(delay: 700.ms)
                .slideY(begin: 0.3),
            const SizedBox(height: 24),
            // Divider
            Container(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 24),
            // Sección Información
            _buildSectionTitle(context, 'Información', Icons.info),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Versión', 'Bovion 1.0.0'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Backend', '192.168.0.104:8000'),
                  const SizedBox(height: 12),
                  _buildInfoRow('ID Usuario', (user?.id ?? 'N/A').toString()),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.3),
            const SizedBox(height: 24),
            // Botón logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error, width: 2),
                  foregroundColor: AppTheme.error,
                ),
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Text('Cerrar sesión'),
              ),
            )
                .animate()
                .fadeIn(delay: 900.ms)
                .slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
