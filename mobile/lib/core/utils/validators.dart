class PasswordValidator {
  // Validar contraseña: mayúscula, minúscula, número, carácter especial
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Debe contener mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Debe contener minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Debe contener número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Debe contener carácter especial (!@#\$%^&*)';
    }
    return null;
  }

  // Validar que las contraseñas coincidan
  static String? validatePasswordMatch(String? password, String? confirm) {
    if (password != confirm) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}

class EmailValidator {
  // Validar email con extensión válida
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El email es requerido';
    }
    // Expresión regular mejorada para validar email
    const emailPattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      return 'Email inválido (ej: usuario@ejemplo.com)';
    }
    return null;
  }
}

class FieldValidator {
  // Validar campo no vacío
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
}

// Clase para rastrear requisitos de contraseña en tiempo real
class PasswordStrength {
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool hasMinLength;

  bool get isValid =>
      hasUppercase &&
      hasLowercase &&
      hasNumber &&
      hasSpecialChar &&
      hasMinLength;

  PasswordStrength({
    required String password,
  })  : hasUppercase = RegExp(r'[A-Z]').hasMatch(password),
        hasLowercase = RegExp(r'[a-z]').hasMatch(password),
        hasNumber = RegExp(r'[0-9]').hasMatch(password),
        hasSpecialChar =
            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
        hasMinLength = password.length >= 8;
}
