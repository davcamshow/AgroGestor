from .settings import *

# Reemplazamos la conexión por un SQLite local automático para los tests
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db_tests.sqlite3',
    }
}

# Desactivar las migraciones durante los tests para evitar conflictos de columnas
class DisableMigrations:
    def __contains__(self, item):
        return True
    def __getitem__(self, item):
        return None

MIGRATION_MODULES = DisableMigrations()