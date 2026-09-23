from django.core.management.base import BaseCommand
from django.utils import timezone
from api.services.push_service import enviar_notificacion_push
from api.models import EventoSanitario, Notificacion

class Command(BaseCommand):
    help = 'Revisa eventos sanitarios cuya proxima_aplicacion sea hoy o este vencida y envia notificaciones push'

    def handle(self, *args, **options):
        hoy = timezone.localdate()
        self.stdout.write(self.style.NOTICE(f"[{timezone.now()}] Revisando eventos sanitarios para fecha <= {hoy}"))

        # 1. Consultar eventos con fecha alcanzada
        eventos_pendientes = EventoSanitario.objects.filter(
            proxima_aplicacion__isnull=False,
            proxima_aplicacion__lte=hoy
        ).select_related('animal')

        total_eventos = eventos_pendientes.count()
        if total_eventos == 0:
            self.stdout.write(self.style.SUCCESS("No hay aplicaciones sanitarias pendientes para alertar hoy."))
            return

        self.stdout.write(f"Se encontraron {total_eventos} eventos con fecha alcanzada.")

        enviadas = 0
        omitidas = 0
        sin_dispositivo = 0

        for evento in eventos_pendientes:
            animal = evento.animal
            if not animal:
                continue

            # Obtener el usuario responsable (directamente o por finca)
            usuario_destino = getattr(animal, 'usuario', None)
            if not usuario_destino and hasattr(animal, 'finca'):
                usuario_destino = getattr(animal.finca, 'usuario', None)

            if not usuario_destino:
                self.stdout.write(self.style.WARNING("Animal sin usuario asociado encontrado. Omitiendo."))
                continue

            user_id = str(usuario_destino.id)

            # Nombre legible del animal sin exponer IDs numéricos
            identificador_animal = (
                getattr(animal, 'nombre', None)
                or getattr(animal, 'numero_arete', None)
                or getattr(animal, 'arete', None)
                or getattr(animal, 'codigo', None)
                or "Bovino"
            )

            producto = evento.producto or "Tratamiento programado"
            tipo_evento = evento.tipo or "Atención sanitaria"

            titulo = f"Tratamiento pendiente: {identificador_animal}"
            cuerpo = f"{tipo_evento}: {producto} programado para {evento.proxima_aplicacion}."

            # Evitar enviar la misma notificación más de una vez en el día
            ya_notificado = Notificacion.objects.filter(
                usuario=usuario_destino,
                titulo=titulo,
                fecha_creacion__date=hoy
            ).exists()

            if ya_notificado:
                omitidas += 1
                continue

            # Enviar el push a OneSignal
            resultado = enviar_notificacion_push(
                user_ids=user_id,
                titulo=titulo,
                cuerpo=cuerpo,
                datos={
                    "tipo": "evento_sanitario"
                }
            )

            recipients = resultado.get("recipients", 0)

            nombre_usuario = (
                getattr(usuario_destino, 'nombre', None)
                or getattr(usuario_destino, 'email', None)
                or "Usuario"
            )

            if recipients > 0:
                Notificacion.objects.create(
                    usuario=usuario_destino,
                    titulo=titulo,
                    mensaje=cuerpo,
                    leida=False,
                    fecha_creacion=timezone.now()
                )
                enviadas += 1
                self.stdout.write(self.style.SUCCESS(f"✓ Push enviado a {nombre_usuario}"))
            else:
                sin_dispositivo += 1
                self.stdout.write(
                    self.style.WARNING(f"⚠ Usuario {nombre_usuario} sin app activa o suscripción: {resultado.get('errors', resultado)}")
                )

        self.stdout.write(
            self.style.SUCCESS(
                f"\n--- Resumen de ejecución ---\n"
                f"Enviadas con éxito: {enviadas}\n"
                f"Omitidas (ya notificadas hoy): {omitidas}\n"
                f"Sin dispositivo registrado: {sin_dispositivo}\n"
            )
        )