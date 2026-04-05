-- ========================================
-- BOVION - Script de inicialización Supabase
-- ========================================

-- 1. Tabla de Usuarios (Django Auth)
CREATE TABLE IF NOT EXISTS auth_user (
    id BIGSERIAL PRIMARY KEY,
    password VARCHAR(128) NOT NULL,
    last_login TIMESTAMP NULL,
    is_superuser BOOLEAN NOT NULL DEFAULT FALSE,
    username VARCHAR(150) UNIQUE NOT NULL,
    first_name VARCHAR(150) NOT NULL DEFAULT '',
    last_name VARCHAR(150) NOT NULL DEFAULT '',
    email VARCHAR(254) NOT NULL UNIQUE,
    is_staff BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    date_joined TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Perfiles de Usuario (Usuario personalizado)
CREATE TABLE IF NOT EXISTS api_usuario (
    id BIGSERIAL PRIMARY KEY,
    auth_user_id BIGINT UNIQUE REFERENCES auth_user(id) ON DELETE CASCADE,
    nombre_completo VARCHAR(255) NOT NULL,
    email VARCHAR(254) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    telefono VARCHAR(50),
    rol_profesional VARCHAR(100),
    cedula VARCHAR(100),
    nombre_rancho VARCHAR(255),
    direccion_rancho TEXT,
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    moneda VARCHAR(10) NOT NULL DEFAULT 'MXN',
    unidad_peso VARCHAR(10) NOT NULL DEFAULT 'kg'
);

-- 3. Tabla de Proveedores
CREATE TABLE IF NOT EXISTS api_proveedor (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES api_usuario(id) ON DELETE CASCADE,
    nombre_empresa VARCHAR(255) NOT NULL,
    contacto VARCHAR(255),
    telefono VARCHAR(50),
    email VARCHAR(254),
    notas TEXT
);

CREATE INDEX idx_proveedor_usuario ON api_proveedor(usuario_id);

-- 4. Tabla de Categorías de Insumo
CREATE TABLE IF NOT EXISTS api_categoriainsumo (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES api_usuario(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL
);

CREATE INDEX idx_categoriainsumo_usuario ON api_categoriainsumo(usuario_id);

-- 5. Tabla de Insumos
CREATE TABLE IF NOT EXISTS api_insumo (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES api_usuario(id) ON DELETE CASCADE,
    categoria_id BIGINT REFERENCES api_categoriainsumo(id) ON DELETE SET NULL,
    proveedor_preferido_id BIGINT REFERENCES api_proveedor(id) ON DELETE SET NULL,
    nombre VARCHAR(255) NOT NULL,
    cantidad_actual_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
    stock_minimo_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
    costo_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_insumo_usuario ON api_insumo(usuario_id);

-- 6. Tabla de Movimientos de Inventario
CREATE TABLE IF NOT EXISTS api_movimientoinventario (
    id BIGSERIAL PRIMARY KEY,
    insumo_id BIGINT NOT NULL REFERENCES api_insumo(id) ON DELETE CASCADE,
    tipo_movimiento VARCHAR(20) NOT NULL,
    cantidad_kg NUMERIC(10, 2) NOT NULL,
    costo_unitario_kg NUMERIC(10, 2),
    fecha_movimiento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notas TEXT
);

CREATE INDEX idx_movimientoinventario_insumo ON api_movimientoinventario(insumo_id);
CREATE INDEX idx_movimientoinventario_fecha ON api_movimientoinventario(fecha_movimiento);

-- 7. Tabla de Dietas
CREATE TABLE IF NOT EXISTS api_dieta (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES api_usuario(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    objetivo VARCHAR(100) NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'activa',
    costo_estimado_kg NUMERIC(10, 2) NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultima_modificacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dieta_usuario ON api_dieta(usuario_id);

-- 8. Tabla de Relación Dieta-Insumo
CREATE TABLE IF NOT EXISTS api_dietainsumo (
    id BIGSERIAL PRIMARY KEY,
    dieta_id BIGINT NOT NULL REFERENCES api_dieta(id) ON DELETE CASCADE,
    insumo_id BIGINT NOT NULL REFERENCES api_insumo(id) ON DELETE CASCADE,
    porcentaje_inclusion NUMERIC(5, 2) NOT NULL,
    UNIQUE(dieta_id, insumo_id)
);

-- 9. Tabla de Lotes
CREATE TABLE IF NOT EXISTS api_lote (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES api_usuario(id) ON DELETE CASCADE,
    dieta_id BIGINT REFERENCES api_dieta(id) ON DELETE SET NULL,
    nombre VARCHAR(255) NOT NULL,
    cantidad_cabezas INTEGER NOT NULL DEFAULT 0,
    peso_promedio_actual_kg NUMERIC(10, 2) NOT NULL DEFAULT 0,
    etapa_productiva VARCHAR(100) NOT NULL,
    estado VARCHAR(50) NOT NULL DEFAULT 'activo',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lote_usuario ON api_lote(usuario_id);

-- 10. Tabla de Pesaje de Lotes
CREATE TABLE IF NOT EXISTS api_pesajelote (
    id BIGSERIAL PRIMARY KEY,
    lote_id BIGINT NOT NULL REFERENCES api_lote(id) ON DELETE CASCADE,
    fecha_pesaje DATE NOT NULL,
    peso_promedio_kg NUMERIC(10, 2) NOT NULL,
    ganancia_diaria_promedio NUMERIC(10, 2),
    notas TEXT
);

CREATE INDEX idx_pesajelote_lote ON api_pesajelote(lote_id);

-- 11. Tabla de Alimentación Diaria
CREATE TABLE IF NOT EXISTS api_alimentaciondiaria (
    id BIGSERIAL PRIMARY KEY,
    lote_id BIGINT NOT NULL REFERENCES api_lote(id) ON DELETE CASCADE,
    dieta_id BIGINT REFERENCES api_dieta(id) ON DELETE SET NULL,
    fecha DATE NOT NULL,
    cantidad_servida_kg NUMERIC(10, 2) NOT NULL,
    costo_total_racion NUMERIC(10, 2) NOT NULL,
    usuario_registro_id BIGINT REFERENCES api_usuario(id) ON DELETE SET NULL
);

CREATE INDEX idx_alimentaciondiaria_fecha ON api_alimentaciondiaria(fecha);

-- 12. Tabla de Animales (Bovion)
CREATE TABLE IF NOT EXISTS api_animal (
    id BIGSERIAL PRIMARY KEY,
    usuario_id BIGINT NOT NULL REFERENCES api_usuario(id) ON DELETE CASCADE,
    lote_id BIGINT REFERENCES api_lote(id) ON DELETE SET NULL,
    madre_id BIGINT REFERENCES api_animal(id) ON DELETE SET NULL,
    padre_id BIGINT REFERENCES api_animal(id) ON DELETE SET NULL,
    numero_arete VARCHAR(100) NOT NULL,
    nombre VARCHAR(100),
    raza VARCHAR(100),
    sexo VARCHAR(1) NOT NULL,
    fecha_nacimiento DATE,
    color VARCHAR(50),
    peso_nacimiento_kg NUMERIC(8, 2),
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(usuario_id, numero_arete)
);

CREATE INDEX idx_animal_usuario ON api_animal(usuario_id);
CREATE INDEX idx_animal_lote ON api_animal(lote_id);

-- 13. Tabla de Ciclos Reproductivos
CREATE TABLE IF NOT EXISTS api_cicloreproductivo (
    id BIGSERIAL PRIMARY KEY,
    animal_id BIGINT NOT NULL REFERENCES api_animal(id) ON DELETE CASCADE,
    tipo_servicio VARCHAR(30) NOT NULL,
    fecha_servicio DATE NOT NULL,
    dias_gestacion INTEGER NOT NULL DEFAULT 283,
    fecha_estimada_parto DATE,
    fecha_parto_real DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'en_servicio',
    notas TEXT
);

CREATE INDEX idx_cicloreproductivo_animal ON api_cicloreproductivo(animal_id);
CREATE INDEX idx_cicloreproductivo_estado ON api_cicloreproductivo(estado);

-- 14. Tabla de Registros de Peso
CREATE TABLE IF NOT EXISTS api_registropeso (
    id BIGSERIAL PRIMARY KEY,
    animal_id BIGINT NOT NULL REFERENCES api_animal(id) ON DELETE CASCADE,
    fecha_pesaje DATE NOT NULL,
    peso_kg NUMERIC(8, 2) NOT NULL,
    condicion_corporal INTEGER,
    ganancia_diaria_kg NUMERIC(6, 3),
    notas TEXT
);

CREATE INDEX idx_registropeso_animal ON api_registropeso(animal_id);
CREATE INDEX idx_registropeso_fecha ON api_registropeso(fecha_pesaje);

-- 15. Tabla de Eventos Sanitarios
CREATE TABLE IF NOT EXISTS api_eventosanitario (
    id BIGSERIAL PRIMARY KEY,
    animal_id BIGINT NOT NULL REFERENCES api_animal(id) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL,
    producto VARCHAR(255) NOT NULL,
    dosis VARCHAR(100),
    fecha_aplicacion DATE NOT NULL,
    proxima_aplicacion DATE,
    veterinario VARCHAR(255),
    costo NUMERIC(10, 2) NOT NULL DEFAULT 0,
    notas TEXT
);

CREATE INDEX idx_eventosanitario_animal ON api_eventosanitario(animal_id);
CREATE INDEX idx_eventosanitario_fecha ON api_eventosanitario(fecha_aplicacion);
CREATE INDEX idx_eventosanitario_proxima ON api_eventosanitario(proxima_aplicacion);

-- ========================================
-- FIN DE TABLAS
-- ========================================
