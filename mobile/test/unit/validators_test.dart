import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/utils/validators.dart';

void main() {
  group('PasswordValidator.validatePassword', () {
    test('rechaza contraseña vacía', () {
      expect(PasswordValidator.validatePassword(''), isNotNull);
    });

    test('rechaza contraseña corta', () {
      expect(PasswordValidator.validatePassword('Ab1!'), isNotNull);
    });

    test('rechaza sin mayúscula', () {
      expect(PasswordValidator.validatePassword('abcdef1!@'), isNotNull);
    });

    test('rechaza sin minúscula', () {
      expect(PasswordValidator.validatePassword('ABCDEF1!@'), isNotNull);
    });

    test('rechaza sin número', () {
      expect(PasswordValidator.validatePassword('Abcdefg!@'), isNotNull);
    });

    test('rechaza sin carácter especial', () {
      expect(PasswordValidator.validatePassword('Abcdefg1'), isNotNull);
    });

    test('acepta contraseña válida', () {
      expect(PasswordValidator.validatePassword('Valid1!@#'), isNull);
    });
  });

  group('PasswordValidator.validatePasswordMatch', () {
    test('retorna null cuando coinciden', () {
      expect(
        PasswordValidator.validatePasswordMatch('abc123', 'abc123'),
        isNull,
      );
    });

    test('retorna error cuando no coinciden', () {
      expect(
        PasswordValidator.validatePasswordMatch('abc123', 'xyz789'),
        isNotNull,
      );
    });
  });

  group('EmailValidator.validateEmail', () {
    test('rechaza email vacío', () {
      expect(EmailValidator.validateEmail(''), isNotNull);
    });

    test('rechaza email sin formato', () {
      expect(EmailValidator.validateEmail('not-an-email'), isNotNull);
    });

    test('rechaza email sin dominio', () {
      expect(EmailValidator.validateEmail('user@'), isNotNull);
    });

    test('acepta email válido simple', () {
      expect(EmailValidator.validateEmail('user@example.com'), isNull);
    });

    test('acepta email con subdominio', () {
      expect(EmailValidator.validateEmail('user@sub.example.com'), isNull);
    });

    test('acepta email con puntos y signos', () {
      expect(EmailValidator.validateEmail('user.name+tag@example.co'), isNull);
    });
  });

  group('FieldValidator.validateRequired', () {
    test('rechaza valor vacío', () {
      expect(FieldValidator.validateRequired('', 'Nombre'), isNotNull);
    });

    test('rechaza solo espacios', () {
      expect(FieldValidator.validateRequired('   ', 'Nombre'), isNotNull);
    });

    test('acepta valor válido', () {
      expect(FieldValidator.validateRequired('Juan', 'Nombre'), isNull);
    });
  });

  group('PasswordStrength', () {
    test('isValid es false para débil', () {
      final strength = PasswordStrength(password: 'weak');
      expect(strength.isValid, false);
    });

    test('isValid es true para fuerte', () {
      final strength = PasswordStrength(password: 'Strong1!@#');
      expect(strength.isValid, true);
    });

    test('trackea requisitos individuales', () {
      final strength = PasswordStrength(password: 'Ab1!');
      expect(strength.hasUppercase, true);
      expect(strength.hasLowercase, true);
      expect(strength.hasNumber, true);
      expect(strength.hasSpecialChar, true);
      expect(strength.hasMinLength, false);
    });
  });
}
