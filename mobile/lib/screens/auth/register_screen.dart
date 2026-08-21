import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late PasswordStrength _passwordStrength;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
    _roleController = TextEditingController();
    _passwordStrength = PasswordStrength.from('');
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = PasswordStrength.from(_passwordController.text);
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('✅ ¡Registro Exitoso!'),
        content: const Text(
          'Tu cuenta ha sido creada correctamente.\nTe hemos enviado un correo para activar tu cuenta. ' 
          'Solo podrás iniciar sesión después de confirmar el email.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Ir al Login'),
          ),
        ],
      ),
    );
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).register(
            email: _emailController.text,
            password: _passwordController.text,
            nombreCompleto: _nameController.text,
            telefono: _phoneController.text.isNotEmpty ? _phoneController.text : null,
            rolProfesional: _roleController.text.isNotEmpty ? _roleController.text : null,
          );
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al registrar: $e');
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
                              color: Colors.white.withValues(alpha: 0.2),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Nombre
                            const Text('Nombre Completo *',
                                style: TextStyle(color: AppTheme.primary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Tu nombre completo',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  FieldValidator.validateRequired(value, 'Nombre'),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
                            const SizedBox(height: 16),
                            // Email
                            const Text('Email *',
                                style: TextStyle(color: AppTheme.primary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'tu@email.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: EmailValidator.validateEmail,
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
                            const SizedBox(height: 16),
                            // Contraseña
                            const Text('Contraseña *',
                                style: TextStyle(color: AppTheme.primary)),
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
                                errorMaxLines: 4, // Permite hasta 4 líneas mostrando errores de validación
                              ),
                              obscureText: _obscurePassword,
                              validator: PasswordValidator.validatePassword,
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),

                            // Indicador de fortaleza
                            if (_passwordController.text.isNotEmpty)
                              PasswordStrengthIndicator(passwordStrength: _passwordStrength)
                                  .animate()
                                  .fadeIn(),

                            const SizedBox(height: 16),
                            // Repetir Contraseña
                            const Text('Repetir Contraseña *',
                                style: TextStyle(color: AppTheme.primary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscureConfirmPassword = !_obscureConfirmPassword);
                                  },
                                ),
                              ),
                              obscureText: _obscureConfirmPassword,
                              validator: (value) =>
                                  PasswordValidator.validatePasswordMatch(
                                    _passwordController.text,
                                    value,
                                  ),
                            ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.5),
                            const SizedBox(height: 16),
                            // Teléfono (opcional)
                            const Text('Teléfono (opcional)',
                                style: TextStyle(color: AppTheme.primary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                hintText: '+1 234 567 8900',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              keyboardType: TextInputType.phone,
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),
                            const SizedBox(height: 16),
                            // Rol (opcional)
                            const Text('Rol Profesional (opcional)',
                                style: TextStyle(color: AppTheme.primary)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _roleController,
                              decoration: const InputDecoration(
                                hintText: 'ej: Veterinario',
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                            ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.5),
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
                                .fadeIn(delay: 600.ms)
                                .slideY(begin: 0.5),
                            const SizedBox(height: 16),
                          ],
                        ),
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
