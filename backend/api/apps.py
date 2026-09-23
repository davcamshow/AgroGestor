import os
from django.apps import AppConfig

class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'

    def ready(self):
        # Evitar que el auto-reloader de runserver ejecute el scheduler dos veces
        if os.environ.get('RUN_MAIN') != 'true':
            return

        from apscheduler.schedulers.background import BackgroundScheduler
        from django.core.management import call_command

        def tarea_revisar():
            try:
                call_command('revisar_notificaciones')
            except Exception as e:
                print(f"Error ejecutando revisar_notificaciones: {e}")

        scheduler = BackgroundScheduler()
        # Se ejecuta cada hora (puedes cambiar 'hours=1' por 'minutes=30' o programar una hora fija)
        scheduler.add_job(tarea_revisar, 'interval', hours=1, id='bovion_alertas', replace_existing=True)
        scheduler.start()