# This is a no-op migration: 0011 was a duplicate of 0009.
# All columns (fecha_ultimo_peso, ultimo_peso_kg, total_eventos_sanitarios)
# were already added by migration 0009, and later by the manual schema fix.
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0010_plansuscripcion_precio_anual'),
    ]

    operations = [
    ]
