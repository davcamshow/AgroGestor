# AgroGestor - Aplicación Móvil (Flutter)

Aplicación de gestión agrícola para ganadería disponible en Android e iOS.

## Requisitos

- **Flutter**: 3.2.0 o superior
- **Android SDK**: API 21+ (Android 5.0)
- **iOS**: 11.0+
- **Dart**: 3.2.0+

## Instalación

### 1. Instalar Flutter

Si no tienes Flutter instalado:
```bash
# Windows
# Descarga desde https://flutter.dev/docs/get-started/install/windows

# macOS
brew install flutter

# Linux
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PWD/flutter/bin:$PATH"
```

### 2. Clonar el proyecto y acceder al directorio

```bash
cd C:\Users\david\AgroGestor\mobile
```

### 3. Obtener dependencias

```bash
flutter pub get
```

### 4. Generar archivos `.g.dart` (serialización JSON)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Este comando genera los archivos `.g.dart` para todos los modelos que usan `@JsonSerializable()`.

## Configuración del Backend

Asegúrate de que Django esté ejecutándose en:

```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

### Nota sobre URLs

- **Android Emulator**: `http://10.0.2.2:8000/api/`
- **iOS Simulator**: `http://127.0.0.1:8000/api/`
- **Dispositivo físico**: `http://<TU_IP_LOCAL>:8000/api/` (edita en `lib/core/api/api_client.dart`)

## Ejecutar la Aplicación

### Android Emulator
```bash
flutter emulators --launch <emulator_name>
flutter run
```

### iOS Simulator
```bash
open -a Simulator
flutter run
```

### Dispositivo Físico
```bash
flutter run -d <device_id>
```

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── core/
│   ├── api/
│   │   └── api_client.dart  # Cliente HTTP con JWT
│   ├── auth/
│   │   ├── auth_state.dart  # Estado de autenticación
│   │   ├── auth_repository.dart
│   │   └── token_storage.dart
│   ├── models/              # Modelos Dart (con .g.dart generados)
│   └── providers/           # Riverpod providers
├── router/
│   └── app_router.dart      # go_router configuration
├── screens/                 # Pantallas de la app
│   ├── auth/
│   ├── dashboard/
│   ├── lotes/
│   ├── formulas/
│   ├── insumos/
│   ├── reportes/
│   └── configuracion/
└── widgets/                 # Componentes compartidos
```

## Features Principales

- ✅ Autenticación JWT con Django
- ✅ Gestión de Lotes (CRUD)
- ✅ Constructor de Fórmulas con validación de porcentajes
- ✅ Inventario de Insumos
- ✅ Dashboard con KPI cards
- ✅ Reportes en 4 pestañas
- ✅ Configuración de perfil y rancho
- ✅ Token refresh automático
- ✅ Material 3 design

## Notas Importantes

### Generación de Código

Después de agregar nuevos modelos o cambiar los existentes, ejecuta:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Autenticación

El sistema usa JWT tokens almacenados de forma segura con `flutter_secure_storage`:
- **Android**: `EncryptedSharedPreferences`
- **iOS**: `Keychain`

El interceptor de `dio` maneja automáticamente:
- Adjuntar tokens a las requests
- Renovar tokens cuando expiran (401)
- Reintentar requests después de refresh

### Testing

Para probar con datos reales:

1. Registra una nueva cuenta en `/register`
2. O inicia sesión con una cuenta existente
3. Los datos se cargan desde el backend Django

## Troubleshooting

### Error: "flutter: command not found"
Agrega Flutter a tu PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Error de conexión al backend
- Verifica que Django esté corriendo: `http://localhost:8000/api/health/`
- Revisa la URL base en `lib/core/api/api_client.dart`
- En dispositivos físicos, usa la IP local de tu máquina

### Error en build_runner
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Token expirado
El app maneja automáticamente la renovación de tokens. Si hay problemas, cierra sesión y vuelve a ingresar.

## Build para Producción

### Android
```bash
flutter build apk --release
# O para Google Play:
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# O:
flutter build ipa --release
```

## API Endpoints Usados

- `POST /api/auth/login/` - Login
- `POST /api/auth/register/` - Registro
- `POST /api/auth/refresh/` - Renovar token
- `GET /api/auth/me/` - Obtener perfil
- `GET/POST /api/lotes/` - Gestionar lotes
- `GET/POST /api/dietas/` - Gestionar dietas
- `GET/POST /api/insumos/` - Gestionar insumos
- `GET/POST /api/reportes/` - Reportes (pendiente)

## Contacto

Para soporte o reportar bugs, revisa el backend en:
`C:\Users\david\AgroGestor\backend`
