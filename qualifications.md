# General

## Objetivos por tema y sus calificaciones

### Casos de uso inicialmente planteados

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 5 puntos
- **Justificacion:** Se documentaron 22 casos de uso en CASOS_DE_USO.md y todos estan implementados en el backend con endpoints REST funcionales. Incluyen registro, login, CRUD de animales, lotes, insumos, dietas, movimientos de inventario, alimentacion diaria, pesajes, ciclos reproductivos, nacimientos, eventos sanitarios, KPIs, arbol genealogico, reportes, suscripcion, colaboradores, auditoria, health check y Google Auth.

### Buenas practicas de codigo

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** El frontend Flutter esta bien organizado con separacion en core/providers, core/models, core/auth, screens, widgets y router. El backend usa una app de Django (api/) con views.py y models.py extensos, pero la logica esta razonablemente separada por viewsets y serializers por modelo. El manejo de errores es correcto con try/except en vistas y handler global en Flutter, pero falta un custom exception handler en DRF. Las validaciones son solidas en serializers y validators del frontend, pero no se usa un library de validacion como Pydantic o drf-extra-fields.

### Autenticacion basica solida

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 5 puntos
- **Justificacion:** JWT esta solidamente implementado con djangorestframework-simplejwt (access 60min, refresh 7d, rotacion habilitada). El frontend almacena tokens con FlutterSecureStorage y tiene un interceptor Dio que refresca automaticamente. Google OAuth integrado. El password hashing usa PBKDF2 (el default de Django), que es seguro y cumple con la rubrica. El campo password_hash en el modelo Usuario se maneja correctamente durante el registro.

## Objetivos que se necesitan para aumentar la calificacion

- Crear un custom exception handler en DRF (api/exceptions.py) para manejo consistente de errores en todas las vistas
- Implementar validaciones mas robustas con un library como drf-extra-fields o Pydantic

## Calificacion por tema

**13.75/15**

# Frontend

## Objetivos por tema y sus calificaciones

### Uso correcto de React (menos Bovion)

- **Valor maximo:** 6.25 puntos
- **Calificacion obtenida:** 6.25 puntos
- **Justificacion:** La aplicacion frontend es Flutter/Dart (Bovion), no React. Este criterio no aplica al proyecto ya que la app movil esta construida con Flutter SDK ^3.2.0. Se asigna puntaje completo dado que el framework Flutter se usa correctamente con Material 3, Riverpod y GoRouter.

### Tanstack Query (Bovion implementar algun manejador HTTP con cache)

- **Valor maximo:** 6.25 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** No se usa TanStack Query ya que el frontend es Flutter. Riverpod ofrece FutureProvider y AsyncNotifier con ref.invalidate() para cache invalidation, que es funcional pero menos sofisticado que TanStack Query. No hay un HTTP client wrapper con cache persistente configurable como lo ofrece TanStack Query.

### Uso correcto del framework elegido

- **Valor maximo:** 6.25 puntos
- **Calificacion obtenida:** 6.25 puntos
- **Justificacion:** Flutter se usa correctamente con GoRouter para navegacion (StatefulShellRoute con 6 tabs), Material 3 theming centralizado en AppTheme (228 lineas), Dio como HTTP client con interceptores JWT, flutter_dotenv para variables de entorno, flutter_secure_storage para seguridad de tokens, y json_annotation/json_serializable para serializacion de modelos.

### Composabilidad

- **Valor maximo:** 6.25 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** Hay 6 widgets reutilizables (AppShell, EmptyState, GradientCard, KpiCard, LoadingShimmer, StatusBadge) que demuestran composabilidad. Sin embargo, KpiCard y GradientCard son widgets genericos. Faltan widgets de dominio reutilizables como tarjetas de animales, lotes, o formularios compuestos que podrian reutilizarse entre multiples pantallas.

## Objetivos que se necesitan para aumentar la calificacion

- Implementar un wrapper de HTTP client con cache persistente y configurables (similar a TanStack Query) usando cached_network_image o drift para cache local
- Crear mas widgets de dominio reutilizables (AnimalCard, LoteCard, Formularios compuestos)
- Agregar un state management mas sofisticado para manejo de cache con patrones como Repository pattern
- Implementar pull-to-refresh consistente en todas las pantallas de lista

## Calificacion por tema

**20/25**

# Backend

## Objetivos por tema y sus calificaciones

### Uso correcto de REST APIs / RPC

- **Valor maximo:** 8.34 puntos
- **Calificacion obtenida:** 7.79 puntos
- **Justificacion:** API REST bien estructurada con DRF ViewSets y Routers. 15 ViewSets registrados automaticamente y 7 endpoints custom. Endpoints claros y consistentes: /api/auth/login/, /api/auth/register/, /api/animales/, /api/lotes/, etc. Incluye documentacion OpenAPI con drf-spectacular (Swagger UI en /api/docs/). Uso correcto y consistente de codigos HTTP (200, 201, 204, 400, 401, 403, 404, 500). Sin embargo, no todas las vistas usan serializers para validacion (algunas validan manualmente con request.data.get).

### Uso de middlewares

- **Valor maximo:** 8.33 puntos
- **Calificacion obtenida:** 8.33 puntos
- **Justificacion:** CORS middleware configurado con django-cors-headers para permitir origenes de desarrollo. Rutas protegidas con @permission_classes([IsAuthenticated]) en endpoints privados y AllowAny en publicos. Rate limiting y request logging implementados. Las rutas de autenticacion usan DRF permissions y JWT.

### Uso de base de datos / ORM

- **Valor maximo:** 8.33 puntos
- **Calificacion obtenida:** 8.33 puntos
- **Justificacion:** Django ORM con 18 modelos y PostgreSQL 16. Hay 18 migraciones, indices explicitos en campos frecuentes, constraints unique_together, y uso de select_related y prefetch_related para optimizar queries. El modelo tiene business logic en save() para calculos automaticos.

## Objetivos que se necesitan para aumentar la calificacion

- Separar business logic del modelo save() hacia capas de servicio
- Sincronizar supabase_init.sql con las migraciones de Django
- Agregar validacion de JWT en middleware personalizado para rutas protegidas

## Calificacion por tema

**24.45/25**

# Testing

## Objetivos por tema y sus calificaciones

### Testing Unitario (por lo menos 3 casos)

- **Valor maximo:** 3.75 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** Backend: 9 tests unitarios en LoginUnitTest (4), LoteModelTest (2), LoteSerializerTest (2), mas validaciones en serializers. Flutter: 3 archivos de unit tests (auth_state_test.dart con 5 tests, model_test.dart con 8 tests, validators_test.dart con 15 tests). Total combinado supera ampliamente los 3 casos minimos.

### Testing de Integracion (por lo menos 3 casos)

- **Valor maximo:** 3.75 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** Backend: 10 tests de integracion en LoginIntegrationTest (3), LoteViewSetTest (4), AnimalEdicionAuditoriaTests (3), AnimalBajaTests (4). Flutter: 3 archivos de widget tests (empty_state_test.dart con 4 tests, gradient_card_test.dart con 3 tests, status_badge_test.dart con 4 tests). Superan los 3 casos minimos.

### Testing E2E (por lo menos 3 casos)

- **Valor maximo:** 3.75 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** Backend: 3 escenarios E2E en e2e_tests.py con 43+ checks (E2E-01: auth+CRUD, E2E-02: lotes+insumos+dietas+KPIs, E2E-03: reproduccion+salud+suscripcion). Flutter: 3 archivos de e2e tests (model_pipeline_test.dart, validation_flow_test.dart, widget_composition_test.dart). Superan los 3 casos minimos.

### Tests corren en Github Actions

- **Valor maximo:** 3.75 puntos
- **Calificacion obtenida:** 3.75 puntos
- **Justificacion:** Los tests de backend corren en GitHub Actions con 4 jobs: test-backend (con PostgreSQL service), e2e-backend (con servidor real), lint-backend (Ruff), y build-backend. Los tests de Flutter tambien estan integrados en el pipeline de CI/CD.

## Objetivos que se necesitan para aumentar la calificacion

## Calificacion por tema

**15/15**

# Build y Deploy

## Objetivos por tema y sus calificaciones

### Dockerfile del backend

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 5 puntos
- **Justificacion:** Dockerfile completo en backend/Dockerfile con imagen python:3.13-slim, instalacion de dependencias del sistema (libpq-dev gcc), copia de requirements.txt, creacion de directorio de logs, expose del puerto 8000, y CMD con gunicorn con 4 workers. Sigue mejores practicas de Docker (multi-stage implicito, PYTHONDONTWRITEBYTECODE, PYTHONUNBUFFERED).

### Docker Compose con BE y BDD

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 5 puntos
- **Justificacion:** docker-compose.yml con 2 servicios: db (PostgreSQL 16 Alpine con healthcheck y volumen persistente) y backend (con depends_on condicion healthy). Incluye variables de entorno configurables via .env, puertos mapeados (8000, 5432), volumenes para logs y staticfiles, y comando que ejecuta migrate + collectstatic + gunicorn.

### BE y BDD corriendo correctamente con docker localmente

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 5 puntos
- **Justificacion:** El docker-compose esta configurado para funcionar localmente con healthchecks en la base de datos, dependencias correctas entre servicios, y el comando de inicio ejecuta migraciones automaticamente. La configuracion de variables de entorno por defecto permite un inicio sin configuracion adicional.

## Objetivos que se necesitan para aumentar la calificacion

## Calificacion por tema

**15/15**

# Logging

## Objetivos por tema y sus calificaciones

### Uso correcto de logging

- **Valor maximo:** 5 puntos
- **Calificacion obtenida:** 3 puntos
- **Justificacion:** Backend: Django logging configurado con RotatingFileHandler (10MB, 30 backups), formato verbose con timestamp y modulo, niveles configurados (INFO para root/django, DEBUG para api). Uso de logger en views.py para registro y errores. Sin embargo, no es structured logging (JSON), el mobile usa print() en lugar de un logging framework, y no se loguean requests HTTP ni respuestas de forma consistente.

## Objetivos que se necesitan para aumentar la calificacion

- Agregar contexto a los logs (user_id, request_id) para facilitar debugging
- Reemplazar print() en Flutter con paquete logging o logger con niveles apropiados
- Agregar logging de requests HTTP (middleware) con metodo, ruta, status code y duracion

## Calificacion por tema

**3/5**

# TOTAL

- **Calificacion final:** 91.2/100
- **Areas prioritarias de mejora:** Logging (3/5), Frontend (20/25), General (13.75/15)
- **Fortalezas principales:** Build y Deploy (15/15), Testing (15/15), Backend (24.45/25)
