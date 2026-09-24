from unittest.mock import patch

from django.db.utils import OperationalError
from django.test import TestCase


class HealthCheckTests(TestCase):
    def test_health_is_a_fast_liveness_check(self):
        with patch('api.views.connection.ensure_connection') as ensure_connection:
            response = self.client.get('/api/health/')

        ensure_connection.assert_not_called()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {
            'status': 'ok',
            'message': '¡AgroGestor backend funcionando!',
        })

    def test_readiness_reports_database_as_available(self):
        with patch('api.views.connection.ensure_connection'):
            response = self.client.get('/api/ready/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {
            'status': 'ok',
            'message': 'La base de datos está disponible.',
            'database': 'ok',
        })

    def test_readiness_returns_unavailable_when_database_fails(self):
        with patch(
            'api.views.connection.ensure_connection',
            side_effect=OperationalError('database unavailable'),
        ):
            response = self.client.get('/api/ready/')

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json(), {
            'status': 'error',
            'message': 'La base de datos no está disponible.',
            'database': 'unavailable',
        })
