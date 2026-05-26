import 'package:flutter_test/flutter_test.dart';
import 'package:bovion/core/auth/auth_state.dart';
import 'package:bovion/core/models/usuario.dart';

void main() {
  group('AuthState', () {
    test('unknown() crea status unknown sin usuario ni error', () {
      final state = AuthState.unknown();
      expect(state.status, AuthStatus.unknown);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('authenticated() crea status authenticated con usuario', () {
      final user = Usuario(
        id: 1,
        nombre_completo: 'Juan Pérez',
        email: 'juan@ejemplo.com',
      );
      final state = AuthState.authenticated(user);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(state.user!.id, 1);
      expect(state.user!.email, 'juan@ejemplo.com');
    });

    test('unauthenticated() sin mensaje', () {
      final state = AuthState.unauthenticated();
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('unauthenticated() con mensaje de error', () {
      final state = AuthState.unauthenticated('Credenciales inválidas');
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, 'Credenciales inválidas');
    });

    test('usuario mantiene valores por defecto', () {
      final user = Usuario(
        id: 2,
        nombre_completo: 'María García',
        email: 'maria@ejemplo.com',
      );
      expect(user.moneda, 'MXN');
      expect(user.unidad_peso, 'kg');
    });
  });
}
