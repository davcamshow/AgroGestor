import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
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
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'tu@email.com',
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
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
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outlined),
                            ),
                            obscureText: true,
                          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.5),
                          const SizedBox(height: 24),
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppTheme.error, width: 1),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ).animate().fadeIn(),
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
