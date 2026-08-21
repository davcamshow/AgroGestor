from decimal import Decimal
from unittest.mock import Mock, patch

from django.contrib.auth.models import User as AuthUser
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Usuario, UsuarioInvitado
from .services.cattle_weather_risk import assess_cattle_weather_risk, calculate_thi
from .services.weather_service import WeatherProviderError, get_current_weather


def open_meteo_payload():
    return {
        'current': {
            'time': '2026-08-19T12:00', 'temperature_2m': 31.2,
            'relative_humidity_2m': 78, 'apparent_temperature': 34.1,
            'precipitation': 0, 'rain': 0, 'weather_code': 2,
            'wind_speed_10m': 14.2, 'wind_gusts_10m': 23.5, 'is_day': 1,
        },
        'hourly': {
            'time': [f'2026-08-19T{hour:02d}:00' for hour in range(12, 24)],
            'precipitation_probability': [70] * 12,
            'precipitation': [1.0] * 12,
        },
    }


class WeatherApiTests(TestCase):
    def setUp(self):
        cache.clear()
        self.auth_user = AuthUser.objects.create_user('owner@example.com', password='secret')
        self.owner = Usuario.objects.create(
            auth_user=self.auth_user, nombre_completo='Owner', email='owner@example.com', password_hash=''
        )
        self.client = APIClient()

    def authenticate(self, auth_user=None):
        self.client.force_authenticate(auth_user or self.auth_user)

    def test_weather_endpoints_require_authentication(self):
        self.assertEqual(self.client.get('/api/clima/ubicacion/').status_code, 401)
        self.assertEqual(self.client.get('/api/clima/actual/').status_code, 401)

    def test_get_unconfigured_location(self):
        self.authenticate()
        response = self.client.get('/api/clima/ubicacion/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {'configurada': False, 'latitud': None, 'longitud': None, 'direccion': None})

    def test_rejects_invalid_coordinates(self):
        self.authenticate()
        invalid_values = [
            {'latitud': True, 'longitud': -100}, {'latitud': 91, 'longitud': -100},
            {'latitud': 25, 'longitud': 181}, {'latitud': 'NaN', 'longitud': -100},
            {'latitude': 25, 'longitude': -100},
        ]
        for payload in invalid_values:
            with self.subTest(payload=payload):
                self.assertEqual(self.client.put('/api/clima/ubicacion/', payload, format='json').status_code, 400)

    @patch('api.views.reverse_geocode', return_value='Monterrey, Nuevo León, México')
    def test_saves_valid_coordinates(self, reverse_geocode):
        self.authenticate()
        response = self.client.put('/api/clima/ubicacion/', {'latitud': 25.686614, 'longitud': -100.316113}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['configurada'])
        self.owner.refresh_from_db()
        self.assertEqual(self.owner.latitud_rancho, Decimal('25.686614'))
        self.assertEqual(self.owner.direccion_rancho, 'Monterrey, Nuevo León, México')
        reverse_geocode.assert_called_once()

    @patch('api.views.reverse_geocode', return_value='Ciudad de México, México')
    def test_normalizes_map_floating_point_precision(self, _):
        self.authenticate()
        response = self.client.put(
            '/api/clima/ubicacion/',
            {
                'latitud': 19.432608000000002,
                'longitud': -99.13320900000001,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.owner.refresh_from_db()
        self.assertEqual(self.owner.latitud_rancho, Decimal('19.432608'))
        self.assertEqual(self.owner.longitud_rancho, Decimal('-99.133209'))

    @patch('api.views.reverse_geocode', side_effect=WeatherProviderError())
    def test_geocoding_failure_preserves_existing_address(self, _):
        self.owner.direccion_rancho = 'Dirección anterior'
        self.owner.save(update_fields=['direccion_rancho'])
        self.authenticate()
        response = self.client.put('/api/clima/ubicacion/', {'latitud': 20, 'longitud': -99}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['direccion'], 'Dirección anterior')

    def test_weather_requires_location(self):
        self.authenticate()
        response = self.client.get('/api/clima/actual/')
        self.assertEqual(response.status_code, 409)
        self.assertEqual(response.data['code'], 'LOCATION_REQUIRED')

    @patch('api.views.get_current_weather')
    def test_weather_with_location(self, weather):
        self.owner.latitud_rancho = Decimal('25.686614')
        self.owner.longitud_rancho = Decimal('-100.316113')
        self.owner.save()
        weather.return_value = {'actual': {'temperatura': 31.2}}
        self.authenticate()
        response = self.client.get('/api/clima/actual/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['actual']['temperatura'], 31.2)

    @patch('api.views.reverse_geocode', return_value='Rancho principal')
    def test_collaborator_reads_and_updates_owner_location(self, _):
        collaborator_auth = AuthUser.objects.create_user('guest@example.com', password='secret')
        collaborator = Usuario.objects.create(auth_user=collaborator_auth, nombre_completo='Guest', email='guest@example.com', password_hash='')
        UsuarioInvitado.objects.create(cuenta_principal=self.owner, usuario=collaborator, activo=True)
        self.authenticate(collaborator_auth)
        response = self.client.put('/api/clima/ubicacion/', {'latitud': 19.432608, 'longitud': -99.133209}, format='json')
        self.assertEqual(response.status_code, 200)
        self.owner.refresh_from_db()
        collaborator.refresh_from_db()
        self.assertEqual(self.owner.latitud_rancho, Decimal('19.432608'))
        self.assertIsNone(collaborator.latitud_rancho)


class WeatherServiceTests(TestCase):
    def setUp(self):
        cache.clear()

    def test_thi_calculation(self):
        self.assertAlmostEqual(calculate_thi(31.2, 78), 84.5, places=1)

    def test_selects_highest_severity_and_deduplicates_recommendations(self):
        risk = assess_cattle_weather_risk(
            {'temperatura': 36, 'humedad': 90, 'precipitacion': 20, 'viento': 20, 'rafagas': 80},
            {'probabilidad_lluvia_maxima': 100, 'precipitacion_acumulada': 60},
        )
        self.assertEqual(risk['nivel'], 'critico')
        self.assertEqual(len(risk['recomendaciones']), len(set(risk['recomendaciones'])))

    @patch('api.services.weather_service.requests.get')
    def test_weather_response_is_cached_by_coordinates(self, get):
        response = Mock()
        response.json.return_value = open_meteo_payload()
        response.raise_for_status.return_value = None
        get.return_value = response
        first = get_current_weather(25.686614, -100.316113, 'Monterrey')
        second = get_current_weather(25.686614, -100.316113, 'Monterrey')
        self.assertEqual(first, second)
        self.assertEqual(get.call_count, 1)
