import requests
from django.conf import settings

def enviar_notificacion_push(user_ids, titulo, cuerpo, datos=None):
    """
    Envía notificaciones push a uno o varios usuarios a través de OneSignal
    utilizando el external_id asociado a su cuenta.
    """
    if not user_ids:
        return {"error": "user_ids requerido"}

    if isinstance(user_ids, (int, str)):
        user_ids = [str(user_ids)]
    else:
        user_ids = [str(uid) for uid in user_ids]

    api_key = str(getattr(settings, 'ONESIGNAL_REST_API_KEY', '')).strip().strip("'\"")
    app_id = str(getattr(settings, 'ONESIGNAL_APP_ID', '')).strip().strip("'\"")

    if not api_key or not app_id:
        return {"error": "Credenciales de OneSignal no configuradas en Django"}

    url = "https://onesignal.com/api/v1/notifications"
    prefijo = "Key" if api_key.startswith("os_v2_") else "Basic"

    payload = {
        "app_id": app_id,
        "include_aliases": {
            "external_id": user_ids
        },
        "target_channel": "push",
        "headings": {"en": titulo, "es": titulo},
        "contents": {"en": cuerpo, "es": cuerpo},
        "data": datos or {},
        "priority": 10
    }

    try:
        headers = {
            "Authorization": f"{prefijo} {api_key}",
            "Content-Type": "application/json; charset=utf-8"
        }
        response = requests.post(url, json=payload, headers=headers, timeout=10)

        # Fallback de esquema de autenticación si OneSignal rechaza por cabecera
        if response.status_code in [401, 403]:
            prefijo_alt = "Basic" if prefijo == "Key" else "Key"
            headers["Authorization"] = f"{prefijo_alt} {api_key}"
            response = requests.post(url, json=payload, headers=headers, timeout=10)

        return response.json()
    except Exception as e:
        return {"error": str(e)}