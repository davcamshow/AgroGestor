import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/utils/validators.dart';

void main() {
  group('E2E: Flujo completo de validación de registro', () {
    test('Escenario 1: registro exitoso con todos los campos válidos', () {
      const email = 'usuario@ejemplo.com';
      const password = 'MiPassword1!@';
      const nombre = 'Juan Pérez';

      final emailResult = EmailValidator.validateEmail(email);
      final passwordResult = PasswordValidator.validatePassword(password);
      final nombreResult = FieldValidator.validateRequired(nombre, 'Nombre');
      final matchResult =
          PasswordValidator.validatePasswordMatch(password, password);

      expect(emailResult, isNull);
      expect(passwordResult, isNull);
      expect(nombreResult, isNull);
      expect(matchResult, isNull);
    });

    test('Escenario 2: registro falla por email inválido y contraseña débil', () {
      const email = 'invalido';
      const password = '123';
      const nombre = '';

      final emailResult = EmailValidator.validateEmail(email);
      final passwordResult = PasswordValidator.validatePassword(password);
      final nombreResult = FieldValidator.validateRequired(nombre, 'Nombre');

      expect(emailResult, isNotNull);
      expect(passwordResult, isNotNull);
      expect(nombreResult, isNotNull);
    });

    test('Escenario 3: contraseñas no coinciden', () {
      const password = 'Valid1!@#';
      const confirm = 'Diferente1!@';

      final passwordResult = PasswordValidator.validatePassword(password);
      final matchResult =
          PasswordValidator.validatePasswordMatch(password, confirm);

      expect(passwordResult, isNull);
      expect(matchResult, isNotNull);
    });

    test('Escenario 4: PasswordStrength tracking en tiempo real', () {
      final strength = PasswordStrength(password: 'Abc1!');

      expect(strength.hasUppercase, true);
      expect(strength.hasLowercase, true);
      expect(strength.hasNumber, true);
      expect(strength.hasSpecialChar, true);
      expect(strength.hasMinLength, false);
      expect(strength.isValid, false);
    });
  });
}
