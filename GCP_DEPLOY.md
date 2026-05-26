# Deploy a Google Cloud Platform

## Prerequisitos

```bash
gcloud auth login
gcloud config set project NOMBRE_DEL_PROYECTO
```

## 1. Habilitar servicios

```bash
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com
```

## 2. Crear Artifact Registry

```bash
gcloud artifacts repositories create agrogestor \
  --repository-format=docker \
  --location=us-central1
```

## 3. Crear Cloud SQL (PostgreSQL 16)

```bash
gcloud sql instances create agrogestor-db \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=CHANGE_ME

gcloud sql databases create agrogestor --instance=agrogestor-db
gcloud sql users create agrogestor --instance=agrogestor-db --password=CHANGE_ME
```

## 4. Guardar secretos en Secret Manager

```bash
echo -n "CHANGE_ME" | gcloud secrets create agrogestor-db-password --data-file=-
echo -n "django-insecure-..." | gcloud secrets create agrogestor-secret-key --data-file=-
```

## 5. Conectar Cloud Build con Cloud SQL

```bash
# Dar permisos a la cuenta de servicio de Cloud Build
PROJECT_NUM=$(gcloud projects describe $(gcloud config get project) --format='value(projectNumber)')
CLOUD_BUILD_SA="$PROJECT_NUM@cloudbuild.gserviceaccount.com"

gcloud projects add-iam-policy-binding $(gcloud config get project) \
  --member="serviceAccount:$CLOUD_BUILD_SA" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $(gcloud config get project) \
  --member="serviceAccount:$CLOUD_BUILD_SA" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $(gcloud config get project) \
  --member="serviceAccount:$CLOUD_BUILD_SA" \
  --role="roles/iam.serviceAccountUser"
```

## 6. Trigger el deploy

```bash
gcloud builds submit --config=cloudbuild.yaml
```

## 7. Configurar variables de entorno en Cloud Run (si hace falta)

```bash
gcloud run services update agrogestor-backend \
  --region=us-central1 \
  --set-env-vars "DJANGO_ALLOWED_HOSTS=*,DJANGO_DEBUG=False"
```

## Resultado

- Backend: `https://agrogestor-backend-XXXX-uc.a.run.app`
- API docs: `https://agrogestor-backend-XXXX-uc.a.run.app/api/docs/`
- Health: `https://agrogestor-backend-XXXX-uc.a.run.app/api/health/`
