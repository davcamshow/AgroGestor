# 🐄 BOVION - Setup para Desarrolladores

## Después de hacer `git pull`

### 1️⃣ Backend (Django + PostgreSQL)

```bash
cd backend

# Instalar dependencias
pip install -r requirements.txt

# Aplicar migraciones
python manage.py migrate

# Correr servidor
python manage.py runserver 0.0.0.0:8000
```

**Notas:**
- Las credenciales de Supabase están en `.env` (no commitar)
- El '.env' debe de ir en la carpeta AGROGESTOR/backend
- Si es primera vez, ejecutar: `python manage.py createsuperuser`
- El servidor debe estar en `http://0.0.0.0:8000`

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
- El servidor Flask debe estar corriendo

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
│   ├── .env          # Credenciales (NO commitar)
│   └── manage.py
├── mobile/           # Flutter
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
└── SETUP.md          # Este archivo
```

---

**¡Listo! Solo ejecuta los comandos y ya funciona todo.** 🚀
