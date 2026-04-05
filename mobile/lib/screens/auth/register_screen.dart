import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
    _roleController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text,
            password: _passwordController.text,
            nombreCompleto: _nameController.text,
            telefono: _phoneController.text,
            rolProfesional: _roleController.text,
          );
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón atrás
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Título
                    Text(
                      'Crear Cuenta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.displayLarge
                          ?.copyWith(color: Colors.white),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                    const SizedBox(height: 8),
                    Text(
                      'Únete a Bovion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.titleMedium
                          ?.copyWith(color: Colors.white70),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                    const SizedBox(height: 40),
                    // Card blanca con formulario
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [AppTheme.mediumShadow],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.error, width: 1),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ).animate().fadeIn(),
                            const SizedBox(height: 16),
                          ],
                          // Nombre
                          Text('Nombre Completo',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Tu nombre completo',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
                          const SizedBox(height: 16),
                          // Email
                          Text('Email',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'tu@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
                          const SizedBox(height: 16),
                          // Contraseña
                          Text('Contraseña',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outlined),
                            ),
                            obscureText: true,
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
                          const SizedBox(height: 16),
                          // Teléfono
                          Text('Teléfono (opcional)',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: '+1 234 567 8900',
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            keyboardType: TextInputType.phone,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
                          const SizedBox(height: 16),
                          // Rol
                          Text('Rol Profesional (opcional)',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _roleController,
                            decoration: InputDecoration(
                              hintText: 'ej: Veterinario',
                              prefixIcon: const Icon(Icons.work_outline),
                            ),
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5),
                          const SizedBox(height: 32),
                          // Register button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Crear Cuenta'),
                          )
                              .animate()
                              .fadeIn(delay: 700.ms)
                              .slideY(begin: 0.5),
                        ],
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
