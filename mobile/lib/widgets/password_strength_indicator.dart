import 'package:flutter/material.dart';
import '../core/utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.passwordStrength});

  final PasswordStrength passwordStrength;

  @override
  Widget build(BuildContext context) {
    final strengthColor = _strengthColor(passwordStrength.score);
    final strengthLabel = _strengthLabel(passwordStrength.score);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
                        backgroundColor: Colors.grey.shade200,
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${passwordStrength.score}/9',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStrengthRow('Mayúscula', passwordStrength.hasUppercase),
            _buildStrengthRow('Minúscula', passwordStrength.hasLowercase),
            _buildStrengthRow('Número', passwordStrength.hasNumber),
            _buildStrengthRow('Carácter especial', passwordStrength.hasSpecialChar),
            _buildStrengthRow('Mínimo 10 caracteres', passwordStrength.hasMinLength),
            _buildStrengthRow('Sin espacios', passwordStrength.hasNoSpaces),
            _buildStrengthRow('Sin contraseñas comunes', passwordStrength.hasNoCommonPassword),
            _buildStrengthRow('Sin repeticiones', passwordStrength.hasNoRepeats),
            _buildStrengthRow('Sin secuencias', passwordStrength.hasNoSequence),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthRow(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? Colors.green : Colors.grey,
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
