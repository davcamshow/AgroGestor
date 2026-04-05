# 🐄 BOVION - Configuración Supabase

## Paso 1: Crear las tablas en Supabase

1. Ve a **Supabase Dashboard** → Tu proyecto `xpmtapqogmmtzaknobzg`
2. Haz clic en **SQL Editor** (en la barra lateral izquierda)
3. Haz clic en **New Query**
4. Copia TODO el contenido del archivo `backend/supabase_init.sql`
5. Pégalo en el editor SQL
6. Haz clic en **Run** (o presiona Ctrl+Enter)

✅ Las tablas se crearán automáticamente en Supabase.

---

## Paso 2: Obtener la contraseña de la BD

1. En Supabase Dashboard, ve a **Project Settings** → **Database**
2. Busca la sección **Database Password** y copia la contraseña
3. Ve al archivo `backend/.env`
4. Reemplaza `your_password_here` con la contraseña real:

```env
DB_PASSWORD=tu_contraseña_aquí
```

---

## Paso 3: Instalar dependencias en backend

```bash
cd backend
pip install -r requirements.txt
```

---

## Paso 4: Crear superuser Django

```bash
python manage.py migrate  # Aplicar migraciones de Django auth

python manage.py createsuperuser
# Ejemplo:
# Username: admin
# Email: admin@bovion.local
# Password: tu_contraseña
```

---

## Paso 5: Verificar conexión

Ejecuta el servidor:

```bash
python manage.py runserver 0.0.0.0:8000
```

Si todo está bien, verás:
```
Starting development server at http://0.0.0.0:8000/
```

Prueba un endpoint:
```bash
curl http://localhost:8000/api/health/
# Debería responder: {"status": "ok"}
```

---

## Paso 6: Usar la app Flutter

En la app móvil, la URL del servidor sigue siendo la misma:
- Backend: `http://192.168.101.14:8000` (o tu IP)
- BD: Supabase (automático vía Django)

---

## 📝 Archivos modificados

- ✅ `backend/backend/settings.py` — Configurado para PostgreSQL (Supabase)
- ✅ `backend/.env` — Credenciales de Supabase
- ✅ `backend/requirements.txt` — Agregado `psycopg2-binary` y `python-dotenv`
- ✅ `backend/supabase_init.sql` — Script para crear todas las tablas

---

## 🆘 Si algo sale mal

### Error: "could not translate host name"
→ Verifica que `DB_HOST` sea correcto en `.env`

### Error: "password authentication failed"
→ Verifica que `DB_PASSWORD` sea la contraseña correcta

### Error: "relation does not exist"
→ El script SQL no se ejecutó. Vuelve al Paso 1 y asegúrate de ejecutar TODO el SQL

### Error: "psycopg2 not found"
```bash
pip install psycopg2-binary
```

---

## 🔐 Credenciales (guardadas en .env, no las compartas)

```
Proyecto: xpmtapqogmmtzaknobzg
Host: aws-1-us-east-2.pooler.supabase.com
User: postgres.xpmtapqogmmtzaknobzg
```

✅ Listo! Tu app Bovion ahora usa Supabase 🚀
