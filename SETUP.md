# 🐄 BOVION - Setup para Desarrolladores

## Después de hacer `git pull`

### 1️⃣ Backend con Docker (recomendado)

```bash
# Crear la configuración local una sola vez
cp .env.example .env

# Construir y levantar API, migraciones y scheduler
docker compose up -d --build

# Verificar
curl http://localhost:8000/api/health/
```

La base de datos se configura en el `.env` de la raíz y utiliza Supabase. Consulta `DOCKER_DEPLOY.md` para el procedimiento completo de despliegue y respaldo.

### 1.1 Backend local sin Docker

```bash
cd backend
python -m venv .venv
source .venv/Scripts/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

**Notas:**
- No versionar `.env`, SQLite, `media/` ni respaldos.
- Si es la primera vez, ejecutar `python manage.py createsuperuser`.

---

### 2️⃣ Mobile (Flutter)

```bash
cd mobile

# Actualizar dependencias
flutter pub get

# Correr app
flutter run
```

**Notas:**
- La IP del backend está en `lib/core/api/api_client.dart` (línea 6)
- Cambiar `192.168.101.14` a tu IP local si es necesario
- El servidor Django debe estar corriendo

---

## 🔗 Conexión

| Servicio | URL | Estado |
|----------|-----|--------|
| Backend | `http://192.168.101.14:8000` | Debe estar corriendo |
| BD | Supabase (automático) | PostgreSQL remoto |
| App | Flutter en dispositivo | Conéctate a la IP del backend |

---

## 🆘 Problemas comunes

**Error: "could not translate host name"**
→ Verifica que `.env` tenga la contraseña correcta

**Error: "relation does not exist"**
→ Ejecuta: `python manage.py migrate`

**Flutter no conecta al backend**
→ Cambia la IP en `api_client.dart` a tu máquina local

**Port 8000 en uso**
→ `python manage.py runserver 0.0.0.0:9000`

---

## 📚 Estructura

```
AgroGestor/
├── backend/          # Django + DRF + Supabase
│   ├── api/          # Modelos, views, serializers
│   └── manage.py
├── .env.example     # Plantilla de configuración (NO contiene secretos)
├── backups/         # Dumps locales ignorados por Git
├── mobile/           # Flutter
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
└── SETUP.md          # Este archivo
```

---
## COMANDO PARA INICIAR PRUEBAS EN EL BACK
python manage.py test api.tests --settings=backend.test_settings --noinput

**¡Listo! Solo ejecuta los comandos y ya funciona todo.** 🚀
