import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('[LOGIN] Iniciando login...');
      await ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      print('[LOGIN] Login exitoso, navegando a dashboard');
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      print('[LOGIN] Error: $e');
      if (mounted) {
        _showErrorDialog('Usuario o contraseña incorrectos');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    // Logo/Título
                    Text(
                      'Bovion',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.displayLarge
                          ?.copyWith(color: Colors.white),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                    const SizedBox(height: 8),
                    Text(
                      'Gestor Ganadero Bovina',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme.titleMedium
                          ?.copyWith(color: Colors.white70),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
                    const SizedBox(height: 60),
                    // Card blanca con formulario
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [AppTheme.mediumShadow],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email field
                            Text(
                              'Email',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'tu@email.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: EmailValidator.validateEmail,
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
                            const SizedBox(height: 20),
                            // Password field
                            Text(
                              'Contraseña',
                              style: Theme.of(context)
                                  .textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'La contraseña es requerida'
                                  : null,
                            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.5),
                            const SizedBox(height: 24),
                            // Login button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
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
                                  : const Text('Iniciar sesión'),
                            )
                                .animate()
                                .fadeIn(delay: 500.ms)
                                .slideY(begin: 0.5),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
                    const SizedBox(height: 24),
                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/register'),
                          child: Text(
                            'Registrate',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 700.ms)
                        .slideY(begin: 0.5),
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
