from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('api', '0018_passwordresetotp')]
    operations = [
        migrations.AddField(model_name='usuario', name='latitud_rancho', field=models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
        migrations.AddField(model_name='usuario', name='longitud_rancho', field=models.DecimalField(blank=True, decimal_places=6, max_digits=9, null=True)),
    ]
