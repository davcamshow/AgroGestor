class PasswordValidator {
  // Lista pequeña de contraseñas comunes que rechazamos
  static const List<String> _commonPasswords = [
    '123456', '1234567', '12345678', '123456789', '12345', '111111',
    'password', 'password1', 'qwerty', 'admin', '1234'
  ];

  // Validar contraseña robusta para registro
  // Reglas (ordenadas por prioridad):
  // - No nula/vacía
  // - Longitud mínima: 10
  // - Sin espacios
  // - Contiene mayúscula, minúscula, número y carácter especial
  // - No secuencias ascendentes/descendentes de 4 caracteres
  // - No 4 caracteres repetidos consecutivos
  // - No estar en lista de contraseñas comunes
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }

    final trimmed = password.trim();
    if (trimmed.length != password.length) {
      return 'La contraseña no debe empezar ni terminar con espacios';
    }

    const minLen = 10;
    if (password.length < minLen) {
      return 'La contraseña debe tener al menos $minLen caracteres';
    }

    if (RegExp(r'\s').hasMatch(password)) {
      return 'La contraseña no puede contener espacios';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'La contraseña debe contener al menos una letra mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'La contraseña debe contener al menos una letra minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'La contraseña debe contener al menos un número';
    }
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\-_/\\\[\]~`+=;:]').hasMatch(password)) {
      return 'La contraseña debe contener al menos un carácter especial (p. ej. !@#\$%)';
    }

    if (_hasRepeatedChars(password, 4)) {
      return 'La contraseña no puede contener 4 caracteres iguales seguidos';
    }

    if (_hasSequentialChars(password, 4)) {
      return 'La contraseña no puede contener secuencias (ej. 1234 o abcd)';
    }

    if (_commonPasswords.contains(password.toLowerCase())) {
      return 'La contraseña es demasiado común; elige otra más segura';
    }

    return null;
  }

  // Validar que las contraseñas coincidan y no estén vacías
  static String? validatePasswordMatch(String? password, String? confirm) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (confirm == null || confirm.isEmpty) {
      return 'Confirma la contraseña';
    }
    if (password != confirm) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Detecta si existe una repetición de `count` o más del mismo carácter
  static bool _hasRepeatedChars(String s, int count) {
    final re = RegExp(r'(.)\1{' + (count - 1).toString() + r',}');
    return re.hasMatch(s);
  }

  // Detecta secuencias ascendentes o descendentes de longitud `len`
  static bool _hasSequentialChars(String s, int len) {
    if (s.length < len) return false;
    final normalized = s.toLowerCase();
    for (var i = 0; i <= normalized.length - len; i++) {
      var asc = true;
      var desc = true;
      for (var j = 0; j < len - 1; j++) {
        final a = normalized.codeUnitAt(i + j);
        final b = normalized.codeUnitAt(i + j + 1);
        if (b - a != 1) asc = false;
        if (a - b != 1) desc = false;
      }
      if (asc || desc) return true;
    }
    return false;
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
  final bool hasNoSpaces;
  final bool hasNoCommonPassword;
  final bool hasNoRepeats;
  final bool hasNoSequence;

  int get score {
    var s = 0;
    if (hasMinLength) s++;
    if (hasUppercase) s++;
    if (hasLowercase) s++;
    if (hasNumber) s++;
    if (hasSpecialChar) s++;
    if (hasNoSpaces) s++;
    if (hasNoCommonPassword) s++;
    if (hasNoRepeats) s++;
    if (hasNoSequence) s++;
    return s;
  }

  // isValid: al menos 6 de 9 requisitos
  bool get isValid => score >= 6;

  PasswordStrength._({
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.hasMinLength,
    required this.hasNoSpaces,
    required this.hasNoCommonPassword,
    required this.hasNoRepeats,
    required this.hasNoSequence,
  });

  factory PasswordStrength.from(String password) {
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$%\^&\*(),.?":{}|<>\-_/\\\[\]~`+=;:]').hasMatch(password);
    final hasMinLength = password.length >= 10;
    final hasNoSpaces = !RegExp(r'\s').hasMatch(password);
    final hasNoCommonPassword = !PasswordValidator._commonPasswords.contains(password.toLowerCase());
    final hasNoRepeats = !PasswordValidator._hasRepeatedChars(password, 4);
    final hasNoSequence = !PasswordValidator._hasSequentialChars(password, 4);

    return PasswordStrength._(
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
      hasMinLength: hasMinLength,
      hasNoSpaces: hasNoSpaces,
      hasNoCommonPassword: hasNoCommonPassword,
      hasNoRepeats: hasNoRepeats,
      hasNoSequence: hasNoSequence,
    );
  }
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