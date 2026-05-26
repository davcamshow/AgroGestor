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


//validaciones 

class AnimalValidator {
  // Validar que solo contenga letras (incluyendo acentos y espacios)
  static String? validateSoloLetras(String? value, String fieldName) {
    if (value != null && value.trim().isNotEmpty) {
      if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
        return 'El $fieldName solo debe contener letras';
      }
    }
    return null; 
  }

  // Validar números enteros o con decimales
  static String? validateNumeroDecimal(String? value, String fieldName) {
    if (value != null && value.trim().isNotEmpty) {
      if (double.tryParse(value) == null) {
        return 'Introduce un $fieldName numérico válido';
      }
    }
    return null;
  }
  
  // Validar números enteros
  static String? validateNumeroEntero(String? value, String fieldName) {
    if (value != null && value.trim().isNotEmpty) {
      if (int.tryParse(value) == null) {
        return 'El $fieldName debe ser un número entero';
      }
    }
    return null;
  }

  // Validar número de arete 
  static String? validateArete(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El arete es requerido';
    }
    // Permite solo letras (mayúsculas/minúsculas), números y espacios
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value)) {
      return 'Rellena este campo solo de esta forma, no introduzcas caracteres especiales';
    }
    return null;
  }
}