from django.core.management.base import BaseCommand
from api.services.notification_detector import NotificationDetector


class Command(BaseCommand):
    help = 'Revisa eventos próximos y genera notificaciones push'

    def handle(self, *args, **kwargs):
        resumen = NotificationDetector.revisar_todos_los_usuarios()
        self.stdout.write(self.style.SUCCESS(
            f'Usuarios revisados: {resumen["usuarios_revisados"]} — '
            f'Notificaciones creadas: {resumen["notificaciones_creadas"]}'
        ))