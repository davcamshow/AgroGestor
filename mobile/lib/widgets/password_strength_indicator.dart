import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.passwordStrength});

  final PasswordStrength passwordStrength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strengthColor = _strengthColor(passwordStrength.score);
    final strengthLabel = _strengthLabel(passwordStrength.score);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceVariant : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? theme.dividerColor : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fortaleza: $strengthLabel',
                        style: TextStyle(
                          color: strengthColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: passwordStrength.score / 9.0,
                        color: strengthColor,
                        backgroundColor: theme.dividerColor,
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${passwordStrength.score}/9',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStrengthRow(
                'Mayúscula', passwordStrength.hasUppercase, isDark),
            _buildStrengthRow(
                'Minúscula', passwordStrength.hasLowercase, isDark),
            _buildStrengthRow('Número', passwordStrength.hasNumber, isDark),
            _buildStrengthRow(
                'Carácter especial', passwordStrength.hasSpecialChar, isDark),
            _buildStrengthRow(
                'Mínimo 10 caracteres', passwordStrength.hasMinLength, isDark),
            _buildStrengthRow(
                'Sin espacios', passwordStrength.hasNoSpaces, isDark),
            _buildStrengthRow('Sin contraseñas comunes',
                passwordStrength.hasNoCommonPassword, isDark),
            _buildStrengthRow(
                'Sin repeticiones', passwordStrength.hasNoRepeats, isDark),
            _buildStrengthRow(
                'Sin secuencias', passwordStrength.hasNoSequence, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthRow(String label, bool isValid, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: isValid
                ? Colors.green
                : (isDark ? AppTheme.darkTextSecondary : Colors.grey),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Color _strengthColor(int score) {
    if (score >= 7) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  String _strengthLabel(int score) {
    if (score >= 7) return 'Muy segura';
    if (score >= 5) return 'Segura';
    return 'Débil';
  }
}
