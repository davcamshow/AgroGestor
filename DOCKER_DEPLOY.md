# Despliegue Docker del backend

Esta guía despliega AgroGestor en una VM con Docker Compose. La base de datos permanece en Supabase y el backend se publica directamente en el puerto `8000`.

## 1. Requisitos

- Linux con Docker Engine y Docker Compose v2.
- Puerto TCP `8000` disponible.
- Acceso de salida a Supabase por el puerto configurado en `DB_PORT`.
- El repositorio y un archivo `.env` en la raíz.

En AWS EC2 o GCP Compute Engine también debe permitirse el puerto `8000` en el security group o firewall.

## 2. Configuración

Crear la configuración local:

```bash
cp .env.example .env
```

Completar al menos estas variables:

```env
DB_HOST=aws-1-us-east-1.pooler.supabase.com
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres.YOUR_PROJECT_REF
DB_PASSWORD=your-database-password

DJANGO_SECRET_KEY=django-insecure-change-for-poc
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=*

BACKEND_URL=http://SERVER_IP:8000
```

`DB_PORT=5432` en ese host corresponde al Session Pooler de Supabase. También puede usarse `6543` si el panel de Supabase entrega un Transaction Pooler con esa configuración.

Las integraciones de SendGrid, OneSignal, Supabase API y Gemini son opcionales para que la API arranque.

## 3. Respaldo de Supabase

En Windows con PowerShell:

```powershell
./scripts/backup-supabase.ps1
```

El script utilize un contenedor temporal `postgres:17-alpine`, porque `pg_dump` forma parte de las herramientas de PostgreSQL y no necesita instalarse en la máquina. Genera un dump en `backups/`, un checksum SHA-256 y lo valida mediante `pg_restore --list`.

## 4. Inicio

```bash
docker compose up -d --build
```

Compose ejecuta tres servicios:

- `migrate`: aplica migraciones y recopila archivos estáticos una vez.
- `backend`: ejecuta Gunicorn en `0.0.0.0:8000`.
- `scheduler`: revisa notificaciones cada 30 minutos.

El backend y el worker no arrancan si la etapa de migraciones falla.

## 5. Verificación

```bash
docker compose ps
docker compose logs migrate
docker compose logs backend
docker compose logs scheduler
```

Health check:

```bash
curl http://localhost:8000/api/health/
```

Respuesta esperada del chequeo de vida:

```json
{
  "status": "ok",
  "message": "¡AgroGestor backend funcionando!"
}
```

Para comprobar la conexión con Supabase bajo demanda:

```bash
curl http://localhost:8000/api/ready/
```

Documentación interactiva:

```text
http://SERVER_IP:8000/api/docs/
```

## 6. Actualizar el servidor

```bash
git pull
docker compose up -d --build
```

Las nuevas migraciones se ejecutan mediante el servicio `migrate` antes de reiniciar el backend.

## 7. Comandos útiles

```bash
# Ver estado
docker compose ps

# Seguir logs
docker compose logs -f backend scheduler

# Reiniciar la API
docker compose restart backend

# Ejecutar migraciones manualmente
docker compose run --rm migrate

# Crear un superusuario
docker compose exec backend python manage.py createsuperuser

# Detener contenedores sin borrar datos de Supabase
docker compose down
```

## 8. Persistencia

- Datos, usuarios y tablas: Supabase.
- Fotos y archivos subidos: `./backend/media` en la VM.
- Logs: consola de Docker y `./backend/logs`.
- Estáticos recopilados: `./backend/staticfiles`.

Reemplazar la VM puede perder las fotos porque se guardan en su disco local. Para esta POC, la base de datos principal permanece en Supabase.

## 9. Notas para AWS y GCP

- AWS EC2: permitir TCP `8000` en el security group.
- GCP Compute Engine: crear una regla de firewall que permita TCP `8000`.
- Configurar `BACKEND_URL` con la IP o dominio público antes de probar correos y enlaces de activación.
- La aplicación Flutter debe apuntar a `http://IP_DEL_SERVIDOR:8000/api/`.

Este despliegue es para una prueba de concepto y no incluye TLS, proxy inverso ni hardening.
