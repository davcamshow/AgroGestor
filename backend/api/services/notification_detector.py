from datetime import timedelta
from django.utils import timezone
from django.db.models import F
from api.models import (
    EventoSanitario, CicloReproductivo, Insumo,
    Notificacion, PreferenciaNotificacion, Usuario,
)
from api.services.push_service import PushService


class NotificationDetector:
    @staticmethod
    def revisar_todos_los_usuarios():
        resumen = {'usuarios_revisados': 0, 'notificaciones_creadas': 0}
        for usuario in Usuario.objects.all():
            pref, _ = PreferenciaNotificacion.objects.get_or_create(usuario=usuario)
            creadas = 0
            if pref.eventos_sanitarios:
                creadas += NotificationDetector._revisar_eventos_sanitarios(usuario, pref)
            if pref.partos_proximos:
                creadas += NotificationDetector._revisar_partos(usuario, pref)
            if pref.stock_bajo:
                creadas += NotificationDetector._revisar_stock(usuario)
            resumen['usuarios_revisados'] += 1
            resumen['notificaciones_creadas'] += creadas
        return resumen

    @staticmethod
    def _crear_si_no_existe(usuario, tipo, titulo, mensaje, ref_tipo, ref_id):
        ya_existe = Notificacion.objects.filter(
            usuario=usuario, tipo=tipo,
            referencia_tipo=ref_tipo, referencia_id=ref_id,
            fecha_creacion__gte=timezone.now() - timedelta(days=1),
        ).exists()
        if ya_existe:
            return False

        notif = Notificacion.objects.create(
            usuario=usuario, tipo=tipo, titulo=titulo, mensaje=mensaje,
            referencia_tipo=ref_tipo, referencia_id=ref_id,
        )
        resultado = PushService.enviar_a_usuario(usuario, titulo, mensaje, {
            'tipo': tipo, 'referencia_id': str(ref_id),
        })
        notif.enviada_push = resultado.get('enviados', 0) > 0
        notif.save(update_fields=['enviada_push'])
        return True

    @staticmethod
    def _revisar_eventos_sanitarios(usuario, pref):
        limite = timezone.now().date() + timedelta(days=pref.dias_anticipacion_sanitario)
        eventos = EventoSanitario.objects.filter(
            animal__usuario=usuario,
            proxima_aplicacion__isnull=False,
            proxima_aplicacion__lte=limite,
            proxima_aplicacion__gte=timezone.now().date(),
        )
        creadas = 0
        for e in eventos:
            if NotificationDetector._crear_si_no_existe(
                usuario, 'evento_sanitario',
                'Evento sanitario próximo',
                f'{e.get_tipo_display()} pendiente para {e.animal.numero_arete} el {e.proxima_aplicacion}',
                'evento_sanitario', e.id,
            ):
                creadas += 1
        return creadas

    @staticmethod
    def _revisar_partos(usuario, pref):
        limite = timezone.now().date() + timedelta(days=pref.dias_anticipacion_parto)
        ciclos = CicloReproductivo.objects.filter(
            animal__usuario=usuario, estado='gestante',
            fecha_estimada_parto__isnull=False,
            fecha_estimada_parto__lte=limite,
            fecha_estimada_parto__gte=timezone.now().date(),
        )
        creadas = 0
        for c in ciclos:
            if NotificationDetector._crear_si_no_existe(
                usuario, 'parto_proximo',
                'Parto próximo',
                f'Parto estimado para {c.animal.numero_arete} el {c.fecha_estimada_parto}',
                'ciclo_reproductivo', c.id,
            ):
                creadas += 1
        return creadas

    @staticmethod
    def _revisar_stock(usuario):
        insumos = Insumo.objects.filter(usuario=usuario, cantidad_actual_kg__lte=F('stock_minimo_kg'))
        creadas = 0
        for i in insumos:
            if NotificationDetector._crear_si_no_existe(
                usuario, 'stock_bajo',
                'Stock bajo',
                f'{i.nombre} está por debajo del mínimo ({i.cantidad_actual_kg}/{i.stock_minimo_kg} kg)',
                'insumo', i.id,
            ):
                creadas += 1
        return creadas


def ejecutar_revision_cron():
    """Entry point para django-crontab y el scheduler de Docker."""
    return NotificationDetector.revisar_todos_los_usuarios()