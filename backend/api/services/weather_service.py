import threading
import time

import requests
from django.conf import settings
from django.core.cache import cache
from django.utils import timezone

from .cattle_weather_risk import assess_cattle_weather_risk


NOMINATIM_URL = 'https://nominatim.openstreetmap.org/reverse'
OPEN_METEO_URL = 'https://api.open-meteo.com/v1/forecast'
_nominatim_lock = threading.Lock()
_last_nominatim_request = 0.0


class WeatherProviderError(Exception):
    pass


def reverse_geocode(latitude, longitude):
    global _last_nominatim_request
    with _nominatim_lock:
        wait = 1.0 - (time.monotonic() - _last_nominatim_request)
        if wait > 0:
            time.sleep(wait)
        try:
            response = requests.get(
                NOMINATIM_URL,
                params={'format': 'jsonv2', 'lat': latitude, 'lon': longitude, 'zoom': 16, 'addressdetails': 1, 'accept-language': 'es'},
                headers={'User-Agent': settings.BOVION_EXTERNAL_USER_AGENT},
                timeout=settings.WEATHER_HTTP_TIMEOUT_SECONDS,
            )
            _last_nominatim_request = time.monotonic()
            response.raise_for_status()
            payload = response.json()
        except (requests.RequestException, ValueError) as exc:
            raise WeatherProviderError('No fue posible obtener la dirección aproximada.') from exc
    display_name = payload.get('display_name') if isinstance(payload, dict) else None
    if not display_name:
        raise WeatherProviderError('El proveedor no devolvió una dirección válida.')
    return display_name


def _weather_description(code):
    descriptions = {
        0: 'Despejado', 1: 'Mayormente despejado', 2: 'Parcialmente nublado', 3: 'Nublado',
        45: 'Niebla', 48: 'Niebla con escarcha', 51: 'Llovizna ligera', 53: 'Llovizna moderada',
        55: 'Llovizna intensa', 61: 'Lluvia ligera', 63: 'Lluvia moderada', 65: 'Lluvia intensa',
        71: 'Nieve ligera', 73: 'Nieve moderada', 75: 'Nieve intensa', 80: 'Chubascos ligeros',
        81: 'Chubascos moderados', 82: 'Chubascos fuertes', 95: 'Tormenta', 96: 'Tormenta con granizo', 99: 'Tormenta fuerte con granizo',
    }
    return descriptions.get(code, 'Condición meteorológica desconocida')


def get_current_weather(latitude, longitude, address):
    cache_key = f'weather:{float(latitude):.4f}:{float(longitude):.4f}'
    cached = cache.get(cache_key)
    if cached is not None:
        result = dict(cached)
        result['ubicacion'] = {
            'direccion': address,
            'latitud': float(latitude),
            'longitud': float(longitude),
        }
        return result
    params = {
        'latitude': latitude, 'longitude': longitude,
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,wind_speed_10m,wind_gusts_10m,is_day',
        'hourly': 'precipitation_probability,precipitation',
        'forecast_days': 2, 'timezone': 'auto',
    }
    try:
        response = requests.get(OPEN_METEO_URL, params=params, timeout=settings.WEATHER_HTTP_TIMEOUT_SECONDS)
        response.raise_for_status()
        payload = response.json()
        current = payload['current']
        hourly = payload.get('hourly') or {}
    except (requests.RequestException, ValueError, KeyError, TypeError) as exc:
        raise WeatherProviderError('El servicio meteorológico no está disponible temporalmente.') from exc

    times = hourly.get('time') or []
    probabilities = hourly.get('precipitation_probability') or []
    precipitations = hourly.get('precipitation') or []
    current_time = str(current.get('time') or '')
    start = next((index for index, value in enumerate(times) if str(value) >= current_time), 0)
    probability_24h = [value for value in probabilities[start:start + 24] if value is not None]
    precipitation_24h = [value for value in precipitations[start:start + 24] if value is not None]
    normalized_current = {
        'temperatura': current.get('temperature_2m'), 'sensacion_termica': current.get('apparent_temperature'),
        'humedad': current.get('relative_humidity_2m'), 'precipitacion': current.get('precipitation'),
        'lluvia': current.get('rain'), 'viento': current.get('wind_speed_10m'),
        'rafagas': current.get('wind_gusts_10m'), 'codigo_clima': current.get('weather_code'),
        'descripcion': _weather_description(current.get('weather_code')), 'es_dia': current.get('is_day') == 1,
    }
    forecast = {
        'probabilidad_lluvia_maxima': max(probability_24h, default=0),
        'precipitacion_acumulada': round(sum(float(value) for value in precipitation_24h), 1),
    }
    result = {
        'ubicacion': {'direccion': address, 'latitud': float(latitude), 'longitud': float(longitude)},
        'actual': normalized_current,
        'pronostico_24h': forecast,
        'riesgo': assess_cattle_weather_risk(normalized_current, forecast),
        'actualizado_en': timezone.now().isoformat(),
    }
    cache.set(cache_key, result, timeout=600)
    return result
