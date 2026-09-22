import requests
from django.conf import settings


class PushService:
    ONESIGNAL_URL = 'https://onesignal.com/api/v1/notifications'

    @staticmethod
    def enviar_a_usuario(usuario, titulo, mensaje, data=None):
        payload = {
            'app_id': settings.ONESIGNAL_APP_ID,
            'include_external_user_ids': [str(usuario.id)],
            'headings': {'en': titulo, 'es': titulo},
            'contents': {'en': mensaje, 'es': mensaje},
            'data': data or {},
        }
        headers = {
            'Authorization': f'Basic {settings.ONESIGNAL_REST_API_KEY}',
            'Content-Type': 'application/json',
        }
        try:
            resp = requests.post(PushService.ONESIGNAL_URL, json=payload, headers=headers, timeout=10)
            resp.raise_for_status()
            body = resp.json()
            return {'enviados': body.get('recipients', 0), 'id': body.get('id')}
        except requests.RequestException as e:
            return {'enviados': 0, 'error': str(e)}