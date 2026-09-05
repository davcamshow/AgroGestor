from django.db import migrations, models

import api.models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0019_usuario_ubicacion_rancho'),
    ]

    operations = [
        migrations.AddField(
            model_name='animal',
            name='foto',
            field=models.ImageField(blank=True, null=True, upload_to=api.models.animal_foto_upload_to),
        ),
    ]
