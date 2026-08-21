import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';

enum _ResetStep { email, verify, password }

class PasswordResetRequestScreen extends ConsumerStatefulWidget {
  const PasswordResetRequestScreen({super.key});

  @override
  ConsumerState<PasswordResetRequestScreen> createState() => _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState extends ConsumerState<PasswordResetRequestScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late PasswordStrength _passwordStrength;

  _ResetStep _step = _ResetStep.email;

  @override
  void initState() {
    super.initState();
    _passwordStrength = PasswordStrength.from('');
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() => _passwordStrength = PasswordStrength.from(_passwordController.text));
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _message = null; _success = false; });

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_emailController.text);
      setState(() {
        _step = _ResetStep.verify;
        _message = 'Te hemos enviado un código de 6 dígitos a tu correo.';
        _success = true;
      });
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _message = null; _success = false; });

    try {
      await ref.read(authRepositoryProvider).verifyPasswordResetOtp(
        _emailController.text,
        _otpController.text,
      );
      setState(() {
        _step = _ResetStep.password;
        _message = 'Código verificado. Ahora define tu nueva contraseña.';
        _success = true;
      });
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _message = null; _success = false; });

    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
        email: _emailController.text,
        code: _otpController.text,
        password: _passwordController.text,
        passwordConfirm: _confirmController.text,
      );
      setState(() {
        _message = 'Tu contraseña se actualizó correctamente.';
        _success = true;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _step == _ResetStep.email
              ? '¿Olvidaste tu contraseña?'
              : _step == _ResetStep.verify
                  ? 'Código de verificación'
                  : 'Nueva contraseña',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _step == _ResetStep.email
              ? 'Ingresa tu correo para recibir un código de verificación.'
              : _step == _ResetStep.verify
                  ? 'Ingresa el código recibido por correo para continuar.'
                  : 'Crea una nueva contraseña segura para tu cuenta.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_step == _ResetStep.email) {
      return Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: EmailValidator.validateEmail,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitEmail,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar código'),
            ),
          ],
        ),
      );
    }

    if (_step == _ResetStep.verify) {
      return Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Código de verificación',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) => value == null || value.trim().length != 6 ? 'Ingresa el código de 6 dígitos' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _step = _ResetStep.email),
                  child: const Text('Cambiar correo'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isLoading ? null : _submitEmail,
                  child: const Text('Reenviar código'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOtp,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verificar código'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: PasswordValidator.validatePassword,
          ),
          if (_passwordController.text.isNotEmpty) PasswordStrengthIndicator(passwordStrength: _passwordStrength),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) => PasswordValidator.validatePasswordMatch(_passwordController.text, value),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitNewPassword,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar contraseña'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildBody(),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _success ? AppTheme.primary : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
