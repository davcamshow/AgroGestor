from types import SimpleNamespace
from unittest.mock import patch

from django.core.management import call_command
from django.test import SimpleTestCase

from api.services.push_service import PushService


class PushServiceTests(SimpleTestCase):
    @patch(
        'api.services.push_service.enviar_notificacion_push',
        return_value={'id': 'notification-id', 'recipients': '1'},
    )
    def test_envia_using_profile_id_and_normalizes_response(self, enviar_push):
        usuario = SimpleNamespace(id=42)

        resultado = PushService.enviar_a_usuario(
            usuario,
            'Título',
            'Mensaje',
            {'tipo': 'prueba'},
        )

        enviar_push.assert_called_once_with(
            42,
            'Título',
            'Mensaje',
            {'tipo': 'prueba'},
        )
        self.assertEqual(resultado['enviados'], 1)
        self.assertEqual(resultado['respuesta']['id'], 'notification-id')

    @patch(
        'api.services.push_service.enviar_notificacion_push',
        return_value={'error': 'credenciales ausentes'},
    )
    def test_normaliza_errores(self, _enviar_push):
        resultado = PushService.enviar_a_usuario(
            SimpleNamespace(id=42),
            'Título',
            'Mensaje',
        )

        self.assertEqual(resultado, {
            'enviados': 0,
            'error': 'credenciales ausentes',
        })


class NotificationSchedulerCommandTests(SimpleTestCase):
    @patch(
        'api.management.commands.run_notifications_scheduler.ejecutar_revision_cron'
    )
    def test_once_executes_single_review(self, ejecutar_revision):
        call_command('run_notifications_scheduler', once=True)

        ejecutar_revision.assert_called_once_with()
