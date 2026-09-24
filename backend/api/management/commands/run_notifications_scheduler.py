import logging

from apscheduler.schedulers.blocking import BlockingScheduler
from django.conf import settings
from django.core.management.base import BaseCommand

from api.services.notification_detector import ejecutar_revision_cron

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Ejecuta periódicamente la revisión de notificaciones.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--once',
            action='store_true',
            help='Ejecuta una sola revisión y termina.',
        )

    def handle(self, *args, **options):
        if options['once']:
            ejecutar_revision_cron()
            self.stdout.write(self.style.SUCCESS('Revisión de notificaciones completada.'))
            return

        def revisar_notificaciones():
            try:
                resumen = ejecutar_revision_cron()
            except Exception:
                logger.exception('Error ejecutando revisar_notificaciones')
                return

            logger.info('Revisión de notificaciones completada: %s', resumen)

        scheduler = BlockingScheduler(timezone=settings.TIME_ZONE)
        scheduler.add_job(
            revisar_notificaciones,
            trigger='interval',
            minutes=30,
            id='bovion_alertas',
            replace_existing=True,
            coalesce=True,
            max_instances=1,
        )

        self.stdout.write('Scheduler de notificaciones iniciado; intervalo: 30 minutos.')
        try:
            scheduler.start()
        except (KeyboardInterrupt, SystemExit):
            scheduler.shutdown(wait=False)
