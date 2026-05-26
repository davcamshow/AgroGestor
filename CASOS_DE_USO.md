# Casos de Uso — AgroGestor / Bovion

## Actor: Productor / Administrador del Rancho

### CU-01: Registrar cuenta
- **Descripción:** El productor crea una cuenta con email, password y datos del rancho.
- **Flujo:** Formulario de registro → validación → creación de AuthUser + perfil Usuario → redirección a login.
- **REST:** `POST /api/auth/register/`

### CU-02: Iniciar sesión
- **Descripción:** El usuario autentica con email y password, recibe JWT.
- **Flujo:** Login → validación de credenciales → retorna access/refresh tokens.
- **REST:** `POST /api/auth/login/`

### CU-03: Ver perfil propio
- **Descripción:** El usuario consulta sus datos personales y de rancho.
- **REST:** `GET /api/auth/me/` (requiere JWT)

### CU-04: Gestionar animales (CRUD)
- **Descripción:** El usuario registra, consulta, actualiza y elimina animales del hato.
- **Campos:** arete, nombre, raza, sexo, fecha nacimiento, peso, madre, lote, etc.
- **REST:** `GET/POST/PUT/DELETE /api/animales/` (requiere JWT)

### CU-05: Gestionar lotes
- **Descripción:** Agrupa animales en lotes con capacidad máxima según etapa productiva.
- **Validación:** Capacidad máxima por etapa (destete=50, crecimiento=100, engorda=200, etc.).
- **REST:** `GET/POST/PUT/DELETE /api/lotes/` (requiere JWT)

### CU-06: Gestionar insumos
- **Descripción:** Registra insumos (granos, forrajes, suplementos) con costo y stock.
- **REST:** `GET/POST/PUT/DELETE /api/insumos/` (requiere JWT)

### CU-07: Gestionar dietas
- **Descripción:** Crea raciones alimenticias con insumos, formato porcentaje o tabla kg.
- **REST:** `GET/POST/PUT/DELETE /api/dietas/` (requiere JWT)

### CU-08: Registrar movimiento de inventario
- **Descripción:** Registra entradas o salidas de insumos del almacén.
- **REST:** `GET/POST /api/movimientos-inventario/` (requiere JWT)

### CU-09: Registrar alimentación diaria
- **Descripción:** Asigna raciones a lotes por fecha.
- **REST:** `GET/POST /api/alimentacion-diaria/` (requiere JWT)

### CU-10: Registrar pesaje de lote
- **Descripción:** Registra peso promedio del lote para seguimiento de engorda.
- **REST:** `GET/POST /api/pesajes-lotes/` (requiere JWT)

### CU-11: Gestionar ciclo reproductivo
- **Descripción:** Registra servicios, gestaciones, partos y destetes por animal.
- **REST:** `GET/POST/PUT/DELETE /api/ciclos-reproductivos/` (requiere JWT)

### CU-12: Registrar nacimiento
- **Descripción:** Registra crías con sexo, peso y fecha de nacimiento.
- **REST:** `GET/POST /api/nacimientos/` (requiere JWT)

### CU-13: Registrar evento sanitario
- **Descripción:** Vacunaciones, desparasitaciones, diagnósticos y tratamientos.
- **REST:** `GET/POST /api/eventos-sanitarios/` (requiere JWT)

### CU-14: Ver KPIs reproductivos
- **Descripción:** Dashboard con indicadores: tasa de concepción, natalidad, IEP, partos.
- **REST:** `GET /api/kpis/reproductivos/` (requiere JWT)

### CU-15: Ver árbol genealógico
- **Descripción:** Consulta ancestros (madre, padre) de un animal.
- **REST:** `GET /api/arbol-genealogico/{id}/` (requiere JWT)

### CU-16: Ver reporte de consumo
- **Descripción:** Reporte de consumo de insumos por período.
- **REST:** `GET /api/reporte/consumo/` (requiere JWT)

### CU-17: Gestionar suscripción
- **Descripción:** Consulta y cambia de plan (Básico, Profesional, Productor, Empresarial).
- **REST:** `GET /api/planes/`, `GET /api/planes/mi-plan/`, `POST /api/planes/cambiar/` (requiere JWT)

### CU-18: Gestionar colaboradores
- **Descripción:** Invita usuarios a compartir la cuenta del rancho.
- **REST:** `GET/POST /api/colaboradores/`, `DELETE /api/colaboradores/{id}/` (requiere JWT)

---

## Actor: Sistema

### CU-19: Refrescar token JWT
- **Descripción:** El cliente renueva el access token usando el refresh token.
- **REST:** `POST /api/auth/refresh/`

### CU-20: Auditoría de login
- **Descripción:** El sistema registra cada intento de login (exitoso/fallido) con IP y user-agent.
- **REST:** `GET /api/auditoria-login/` (requiere JWT)

### CU-21: Health check
- **Descripción:** Endpoint de verificación de estado del backend.
- **REST:** `GET /api/health/`

### CU-22: Autenticación con Google
- **Descripción:** Inicia sesión o registra usando cuenta de Google.
- **REST:** `POST /api/auth/google/`
