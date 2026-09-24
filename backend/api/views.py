from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import viewsets, generics, serializers
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.decorators import action
from django.contrib.auth.models import User as AuthUser
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import EmailMultiAlternatives
from django.conf import settings
from django.shortcuts import render
from django.template.loader import render_to_string
from django.utils.encoding import force_bytes, force_str
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.db import connection
from django.db.models import Sum, Count, Q, Case, When, Value, F, IntegerField
from django.db.models.functions import Greatest
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import hashlib
import logging
import random
from django.db import transaction
from rest_framework import status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
logger = logging.getLogger(__name__)

#Importaciones para los viewsets en /api/
from .serializer import UsuarioSerializer, ProveedorSerializer, CategoriaInsumoSerializer, InsumoSerializer, MovimientoInventarioSerializer, DietaSerializer, DietaInsumoSerializer, LoteSerializer, PesajeLoteSerializer, AlimentacionDiariaSerializer, RegisterSerializer, UserProfileSerializer, AnimalSerializer, CicloReproductivoSerializer, RegistroPesoSerializer, EventoSanitarioSerializer, AuditoriaLoginSerializer, RegistroNacimientoSerializer, PlanSuscripcionSerializer, UsuarioInvitadoSerializer, AuditoriaAnimalSerializer, UbicacionClimaSerializer
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal, CicloReproductivo, RegistroPeso, EventoSanitario, AuditoriaLogin, RegistroNacimiento, PlanSuscripcion, SuscripcionUsuario, UsuarioInvitado, AuditoriaAnimal, PasswordResetOtp
from .email_utils import send_html_email
from .services.account_owner import get_account_owner
from .services.weather_service import (
    WeatherProviderError,
    get_current_weather,
    reverse_geocode,
)
from rest_framework.decorators import action
from .models import Notificacion, PreferenciaNotificacion
from .serializer import NotificacionSerializer, PreferenciaNotificacionSerializer


class NotificacionViewSet(viewsets.ModelViewSet):
    serializer_class = NotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Notificacion.objects.filter(usuario=self.request.user.perfil)
        leida = self.request.query_params.get('leida')
        if leida is not None:
            qs = qs.filter(leida=(leida == 'true'))
        return qs

    @action(detail=False, methods=['post'])
    def marcar_todas_leidas(self, request):
        self.get_queryset().update(leida=True)
        return Response({'status': 'ok'})

    @action(detail=True, methods=['patch'])
    def marcar_leida(self, request, pk=None):
        notif = self.get_object()
        notif.leida = True
        notif.save(update_fields=['leida'])
        return Response(self.get_serializer(notif).data)


class PreferenciaNotificacionView(generics.RetrieveUpdateAPIView):
    serializer_class = PreferenciaNotificacionSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        obj, _ = PreferenciaNotificacion.objects.get_or_create(usuario=self.request.user.perfil)
        return obj

@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    return Response({
        'status': 'ok',
        'message': '¡AgroGestor backend funcionando!',
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def readiness_check(request):
    try:
        connection.ensure_connection()
    except Exception:
        logger.exception('Readiness check sin conexión a la base de datos')
        return Response({
            'status': 'error',
            'message': 'La base de datos no está disponible.',
            'database': 'unavailable',
        }, status=status.HTTP_503_SERVICE_UNAVAILABLE)

    return Response({
        'status': 'ok',
        'message': 'La base de datos está disponible.',
        'database': 'ok',
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def user_exists(request):
    """Simple endpoint to verify if a user with the given email/username exists.

    Query params: ?email=...  Returns JSON {"exists": true|false}
    """
    email = request.GET.get('email') or request.query_params.get('email')
    if not email:
        return Response({'detail': 'email parameter is required'}, status=status.HTTP_400_BAD_REQUEST)

    exists = AuthUser.objects.filter(username=email).exists() or AuthUser.objects.filter(email=email).exists()
    return Response({'exists': exists})


def _hash_code(code):
    return hashlib.sha256(code.encode('utf-8')).hexdigest()


def _send_password_reset_otp_email(user, code):
    subject = 'Tu código de verificación en Bovion'
    text_content = (
        f'Hola {user.email},\n\n'
        f'Tu código de verificación es: {code}\n\n'
        'Este código expira en 10 minutos y solo puede usarse una vez.'
    )
    send_html_email(
        subject,
        user.email,
        'emails/password_reset_otp_email.html',
        {'code': code},
        text_content,
    )


@api_view(['POST'])
@permission_classes([AllowAny])
def request_password_reset(request):
    email = (request.data.get('email') or '').strip().lower()
    if not email:
        return Response({'detail': 'El correo es requerido.'}, status=status.HTTP_400_BAD_REQUEST)

    user = AuthUser.objects.filter(email=email).first() or AuthUser.objects.filter(username=email).first()
    if user is None:
        return Response({'detail': 'No existe una cuenta con ese correo.'}, status=status.HTTP_404_NOT_FOUND)

    PasswordResetOtp.objects.filter(user=user, is_active=True).update(is_active=False)

    code = f'{random.randint(100000, 999999)}'
    PasswordResetOtp.objects.create(
        user=user,
        code_hash=_hash_code(code),
        expires_at=timezone.now() + timedelta(minutes=10),
        attempts=0,
        is_active=True,
    )
    _send_password_reset_otp_email(user, code)

    return Response({'detail': 'Se ha enviado un código de verificación a tu correo.'})


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_password_reset_otp(request):
    email = (request.data.get('email') or '').strip().lower()
    code = (request.data.get('code') or '').strip()

    if not email or not code:
        return Response({'detail': 'El correo y el código son requeridos.'}, status=status.HTTP_400_BAD_REQUEST)

    user = AuthUser.objects.filter(email=email).first() or AuthUser.objects.filter(username=email).first()
    if user is None:
        return Response({'detail': 'No existe una cuenta con ese correo.'}, status=status.HTTP_404_NOT_FOUND)

    otp = PasswordResetOtp.objects.filter(user=user, is_active=True).order_by('-created_at').first()
    if otp is None:
        return Response({'detail': 'No hay un código de verificación activo.'}, status=status.HTTP_404_NOT_FOUND)
    if otp.used_at is not None or not otp.is_valid():
        otp.is_active = False
        otp.save(update_fields=['is_active'])
        return Response({'detail': 'El código ha expirado o ya fue usado.'}, status=status.HTTP_400_BAD_REQUEST)
    if otp.attempts >= 5:
        otp.is_active = False
        otp.save(update_fields=['is_active'])
        return Response({'detail': 'Demasiados intentos. Solicita un nuevo código.'}, status=status.HTTP_429_TOO_MANY_REQUESTS)
    if _hash_code(code) != otp.code_hash:
        otp.attempts += 1
        otp.save(update_fields=['attempts'])
        if otp.attempts >= 5:
            otp.is_active = False
            otp.save(update_fields=['is_active'])
            return Response({'detail': 'Demasiados intentos. Solicita un nuevo código.'}, status=status.HTTP_429_TOO_MANY_REQUESTS)
        return Response({'detail': 'El código es incorrecto.'}, status=status.HTTP_400_BAD_REQUEST)

    return Response({'detail': 'Código verificado correctamente.'})


@api_view(['POST'])
@permission_classes([AllowAny])
def confirm_password_reset(request):
    email = (request.data.get('email') or '').strip().lower()
    code = (request.data.get('code') or '').strip()
    password = request.data.get('password') or ''
    password_confirm = request.data.get('password_confirm') or ''

    if not email or not code:
        return Response({'detail': 'El correo y el código son requeridos.'}, status=status.HTTP_400_BAD_REQUEST)
    if not password or password != password_confirm:
        return Response({'detail': 'Las contraseñas no coinciden o están vacías.'}, status=status.HTTP_400_BAD_REQUEST)

    user = AuthUser.objects.filter(email=email).first() or AuthUser.objects.filter(username=email).first()
    if user is None:
        return Response({'detail': 'No existe una cuenta con ese correo.'}, status=status.HTTP_404_NOT_FOUND)

    otp = PasswordResetOtp.objects.filter(user=user, is_active=True).order_by('-created_at').first()
    if otp is None:
        return Response({'detail': 'No hay un código de verificación activo.'}, status=status.HTTP_404_NOT_FOUND)
    if otp.used_at is not None or not otp.is_valid():
        otp.is_active = False
        otp.save(update_fields=['is_active'])
        return Response({'detail': 'El código ha expirado o ya fue usado.'}, status=status.HTTP_400_BAD_REQUEST)
    if _hash_code(code) != otp.code_hash:
        return Response({'detail': 'El código es incorrecto.'}, status=status.HTTP_400_BAD_REQUEST)

    if user.check_password(password):
        return Response(
            {'detail': 'La nueva contraseña no puede ser la misma que la contraseña actual.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        validate_password(password, user=user)
    except Exception as exc:
        return Response({'detail': [str(error) for error in exc.messages]}, status=status.HTTP_400_BAD_REQUEST)

    user.set_password(password)
    user.save(update_fields=['password'])
    otp.used_at = timezone.now()
    otp.is_active = False
    otp.save(update_fields=['used_at', 'is_active'])
    PasswordResetOtp.objects.filter(user=user).exclude(pk=otp.pk).update(is_active=False)

    return Response({'detail': 'Tu contraseña ha sido actualizada correctamente.'})


# Auth views
class RegisterView(generics.CreateAPIView):
    queryset = AuthUser.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            try:
                usuario = serializer.save()
                AuditoriaLogin.objects.create(
                    usuario=usuario.perfil if hasattr(usuario, 'perfil') else None,
                    email=serializer.validated_data.get('email'),
                    ip_address=self.get_client_ip(request),
                    user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
                    resultado='exitoso',
                    mensaje='Usuario registrado exitosamente'
                )
                logger.info(f"Registro exitoso para {usuario.email}")
                return Response(serializer.data, status=201)
            except Exception as e:
                AuditoriaLogin.objects.create(
                    usuario=None,
                    email=serializer.validated_data.get('email'),
                    ip_address=self.get_client_ip(request),
                    user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
                    resultado='fallido',
                    mensaje=f'Error en registro: {str(e)}'
                )
                logger.error(f"Error en registro: {str(e)}")
                return Response({'error': f'Error interno al registrar: {str(e)}'}, status=500)
        return Response(serializer.errors, status=400)

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        return ip


@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def activate_user(request):
    if request.method == 'POST':
        uidb64 = request.data.get('uidb64')
        token = request.data.get('token')
    else:
        uidb64 = request.GET.get('uidb64')
        token = request.GET.get('token')

    if not uidb64 or not token:
        if request.method == 'GET':
            return render(request, 'activation_result.html', context={
                'email': None,
                'message': 'Faltan parámetros de activación en el enlace.',
            })
        return Response({'detail': 'Faltan parámetros de activación.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        uid = force_str(urlsafe_base64_decode(uidb64))
        user = AuthUser.objects.get(pk=uid)
    except (TypeError, ValueError, OverflowError, AuthUser.DoesNotExist):
        if request.method == 'GET':
            return render(request, 'activation_result.html', context={
                'email': None,
                'message': 'El enlace de activación es inválido o caducado.',
            })
        return Response({'detail': 'El enlace de activación es inválido.'}, status=status.HTTP_400_BAD_REQUEST)

    context = {'email': user.email}

    if default_token_generator.check_token(user, token):
        if user.is_active:
            context['message'] = 'La cuenta ya está activada.'
            return render(request, 'activation_result.html', context=context)
        user.is_active = True
        user.save()
        context['message'] = 'Cuenta activada correctamente. Regrese a la aplicación para iniciar sesión.'
        return render(request, 'activation_result.html', context=context)

    context['message'] = 'El enlace de activación es inválido o caducado.'
    return render(request, 'activation_result.html', context=context)


@api_view(['GET', 'PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def me_view(request):
    """Returns and updates the current user's profile."""
    try:
        perfil = request.user.perfil
    except Usuario.DoesNotExist:
        return Response({'error': 'Profile not found'}, status=404)

    if request.method == 'GET':
        serializer = UserProfileSerializer(perfil)
        return Response(serializer.data)
    elif request.method in ['PUT', 'PATCH']:
        partial = request.method == 'PATCH'
        serializer = UserProfileSerializer(perfil, data=request.data, partial=partial)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        else:
            logger.error(serializer.errors)
            print(serializer.errors)
            return Response(serializer.errors, status=400)

# ViewSets para cada modelo
class ProveedorViewSet(viewsets.ModelViewSet):
    serializer_class = ProveedorSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Proveedor.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class CategoriaInsumoViewSet(viewsets.ModelViewSet):
    serializer_class = CategoriaInsumoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return CategoriaInsumo.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class InsumoViewSet(viewsets.ModelViewSet):
    serializer_class = InsumoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Insumo.objects.filter(usuario=self.request.user.perfil).select_related('categoria', 'proveedor_preferido')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class MovimientoInventarioViewSet(viewsets.ModelViewSet):
    serializer_class = MovimientoInventarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return MovimientoInventario.objects.filter(insumo__usuario=self.request.user.perfil).select_related('insumo')

    @staticmethod
    def _factor_tipo(tipo_movimiento):
        return Decimal(1) if tipo_movimiento == 'entrada' else Decimal(-1)

    def _aplicar_delta(self, movimiento, revertir=False):
        factor = self._factor_tipo(movimiento.tipo_movimiento)
        if revertir:
            factor = -factor
        cantidad = Decimal(movimiento.cantidad_kg)

        if not revertir and factor < 0 and cantidad > movimiento.insumo.cantidad_actual_kg:
            raise serializers.ValidationError(
                f'No hay suficiente stock de "{movimiento.insumo.nombre}": '
                f'disponible {movimiento.insumo.cantidad_actual_kg} kg, se pretenden retirar {cantidad} kg.'
            )

        insumo = Insumo.objects.select_for_update().get(pk=movimiento.insumo_id)
        insumo.cantidad_actual_kg += cantidad * factor
        insumo.save(update_fields=['cantidad_actual_kg', 'fecha_actualizacion'])

    @transaction.atomic
    def perform_create(self, serializer):
        movimiento = serializer.save()
        self._aplicar_delta(movimiento)

    @transaction.atomic
    def perform_update(self, serializer):
        viejo = self.get_object()
        movimiento = serializer.save()
        self._aplicar_delta(viejo, revertir=True)
        self._aplicar_delta(movimiento)

    @transaction.atomic
    def perform_destroy(self, instance):
        self._aplicar_delta(instance, revertir=True)
        instance.delete()


class DietaViewSet(viewsets.ModelViewSet):
    serializer_class = DietaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Dieta.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)

    @action(detail=False, methods=['post'], url_path='procesar-consumo')
    def procesar_consumo(self, request):
        """Procesa el consumo pendiente de dietas (lotes y animales).

        Respeta la periodicidad (diaria/semanal/quincenal), calcula la ración
        según cabezas efectivas y descuenta el inventario automáticamente.
        """
        from .services.consumo_dietas import procesar_consumos
        resumen = procesar_consumos(request.user.perfil)
        return Response(resumen, status=status.HTTP_200_OK)


class DietaInsumoViewSet(viewsets.ModelViewSet):
    serializer_class = DietaInsumoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return DietaInsumo.objects.filter(dieta__usuario=self.request.user.perfil).select_related('dieta', 'insumo')


class LoteViewSet(viewsets.ModelViewSet):
    serializer_class = LoteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return (
            Lote.objects.filter(usuario=self.request.user.perfil)
            .select_related('dieta')
            .annotate(
                animales_count=Count('animales'),
                animales_activos=Count('animales', filter=Q(animales__estado='activo')),
                animales_especiales=Count('animales', filter=Q(animales__estado='activo', animales__dieta__isnull=False)),
                cabezas_base=Case(
                    When(animales_activos__gt=0, then=F('animales_activos')),
                    default=F('cantidad_cabezas'),
                    output_field=IntegerField(),
                ),
                cabezas_efectivas=Greatest(F('cabezas_base') - F('animales_especiales'), Value(0)),
            )
        )

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class PesajeLoteViewSet(viewsets.ModelViewSet):
    serializer_class = PesajeLoteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PesajeLote.objects.filter(lote__usuario=self.request.user.perfil).select_related('lote')


class AlimentacionDiariaViewSet(viewsets.ModelViewSet):
    serializer_class = AlimentacionDiariaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        perfil = self.request.user.perfil
        return AlimentacionDiaria.objects.filter(
            Q(lote__usuario=perfil) | (Q(notas__startswith='animal_id:') & Q(usuario_registro=perfil))
        ).select_related('lote', 'dieta', 'usuario_registro')

    @transaction.atomic
    def perform_create(self, serializer):
        registro = serializer.save(usuario_registro=self.request.user.perfil)
        _descontar_racion(registro)


def _descontar_racion(registro):
    """Descuenta del inventario los insumos de una ración (lote o animal)."""
    from .services.consumo_dietas import aplicar_consumo_registro
    aplicar_consumo_registro(registro)


def _recalcular_cabezas_lote(lote):
    """Mantiene persistido `cantidad_cabezas` alineado con los animales
    activos del lote (igual que la anotación de `cabezas_efectivas`). Solo
    se escribe cuando el lote tiene animales registrados."""
    if lote is None:
        return
    activos = lote.animales.filter(estado='activo').count()
    if lote.cantidad_cabezas != activos:
        lote.cantidad_cabezas = activos
        lote.save(update_fields=['cantidad_cabezas'])


CAMPOS_AUDITABLES = [
    'numero_arete', 'nombre', 'raza', 'sexo',
    'fecha_nacimiento', 'color', 'peso_nacimiento_kg',
    'estado', 'lote', 'madre', 'padre',
]
 
def _get_ip(request):
    x_forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded:
        return x_forwarded.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')
 
 
class AnimalViewSet(viewsets.ModelViewSet):
    serializer_class = AnimalSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
 
    def get_queryset(self):
        qs = Animal.objects.filter(usuario=self.request.user.perfil)
        lote_id = self.request.query_params.get('lote')
        sexo = self.request.query_params.get('sexo')
        

        estado = self.request.query_params.get('estado', 'activo')
        
        if lote_id:
            qs = qs.filter(lote_id=lote_id)
        if sexo:
            qs = qs.filter(sexo=sexo)
        if estado and estado != 'todos':  
            qs = qs.filter(estado=estado)
            
        return qs.select_related('lote', 'madre', 'padre').prefetch_related('registros_peso')
 
    def perform_create(self, serializer):
        animal = serializer.save(usuario=self.request.user.perfil)
        _recalcular_cabezas_lote(animal.lote)

    def perform_update(self, serializer):
        animal_antes = self.get_object()

        valores_antes = {}
        for campo in CAMPOS_AUDITABLES:
            valor = getattr(animal_antes, campo, None)
            if hasattr(valor, 'id'):
                valores_antes[campo] = str(valor.id)
            else:
                valores_antes[campo] = str(valor) if valor is not None else ''

        animal = serializer.save()

        _recalcular_cabezas_lote(animal_antes.lote)
        _recalcular_cabezas_lote(animal.lote)

        try:
            perfil = self.request.user.perfil
        except Exception:
            perfil = None

        ip = _get_ip(self.request)

        for campo in CAMPOS_AUDITABLES:
            valor_antes = valores_antes.get(campo, '')
            nuevo_obj = getattr(animal, campo, None)
            valor_despues = str(nuevo_obj.id) if hasattr(nuevo_obj, 'id') else (str(nuevo_obj) if nuevo_obj is not None else '')

            if valor_antes != valor_despues:
                AuditoriaAnimal.objects.create(
                    animal=animal,
                    usuario=perfil,
                    campo=campo,
                    valor_anterior=valor_antes,
                    valor_nuevo=valor_despues,
                    ip_address=ip,
                )

    @action(detail=True, methods=['get'], url_path='auditoria')
    def auditoria(self, request, pk=None):
        """Retorna el historial de cambios de un animal."""
        animal = self.get_object()
        registros = animal.auditoria.all()
        serializer = AuditoriaAnimalSerializer(registros, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='baja')
    def registrar_baja(self, request, pk=None):
        """Registra la baja lógica de un animal (venta, muerte, transferencia)."""
        animal = self.get_object()
        
        # Validar parámetros obligatorios según criterios de aceptación
        causa = request.data.get('causa') # esperado: 'vendido', 'muerto', 'transferido'
        fecha_baja = request.data.get('fecha') # esperado: 'YYYY-MM-DD'
        notas = request.data.get('notas', '')

        if not causa or not fecha_baja:
            return Response(
                {'error': 'La causa (estado) y la fecha de baja son campos obligatorios.'}, 
                status=400
            )
            
        opciones_baja = ['vendido', 'muerto', 'transferido']
        if causa not in opciones_baja:
            return Response(
                {'error': f"Causa no válida. Opciones permitidas: {', '.join(opciones_baja)}"}, 
                status=400
            )

        # Almacenar estado anterior para la auditoría
        estado_anterior = animal.estado
        lote_anterior = animal.lote

        # Cambiar estado del animal y sacarlo de su lote actual si corresponde
        animal.estado = causa
        animal.lote = None # Al darse de baja, deja de pertenecer al flujo activo de un lote
        animal.save()

        # Actualizar el contador del lote que se queda sin este animal
        _recalcular_cabezas_lote(lote_anterior)

        # Registrar de forma explícita en la tabla de auditoría de cambios
        try:
            perfil = self.request.user.perfil
        except Exception:
            perfil = None

        AuditoriaAnimal.objects.create(
            animal=animal,
            usuario=perfil,
            campo='estado',
            valor_anterior=estado_anterior,
            valor_nuevo=causa,
            ip_address=_get_ip(self.request),
        )

        # Registrar las notas de baja y la fecha SIEMPRE, incluso si 'notas' está vacío
        detalle_baja = f"Fecha baja: {fecha_baja}"
        if notas:
            detalle_baja += f" | Notas: {notas}"

        AuditoriaAnimal.objects.create(
            animal=animal,
            usuario=perfil,
            campo='notas_baja',
            valor_anterior='',
            valor_nuevo=detalle_baja,
            ip_address=_get_ip(self.request),
        )

        return Response({
            'mensaje': f'El animal con arete {animal.numero_arete} ha sido dado de baja por motivo: {causa}.',
            'animal_id': animal.id,
            'nuevo_estado': animal.estado
        }, status=200)



    @action(detail=True, methods=['post'], url_path='mover-lote')
    def mover_lote(self, request, pk=None):
        """
        Mueve un animal de un lote origen a un lote destino.
        """
        animal = self.get_object()
        usuario_perfil = request.user.perfil

        lote_origen_id = request.data.get('lote_origen_id')
        lote_destino_id = request.data.get('lote_destino_id')
        fecha_movimiento = request.data.get('fecha_movimiento') # Opcional en el request body, si no se envía se puede usar la de auditoría
        notas = request.data.get('notas', '')

        # 1. Validaciones iniciales de parámetros
        if not lote_destino_id:
            return Response(
                {'error': 'El lote destino (lote_destino_id) es un campo obligatorio.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 2. Validación de existencia de los lotes pertenecientes al usuario
        try:
            lote_destino = Lote.objects.get(id=lote_destino_id, usuario=usuario_perfil)
        except Lote.DoesNotExist:
            return Response(
                {'error': 'El lote destino no existe o no pertenece a tu cuenta.'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Validar si el animal ya se encuentra en el lote destino
        if animal.lote_id == lote_destino.id:
            return Response(
                {'error': 'El animal ya se encuentra registrado en el lote de destino seleccionado.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Verificar lote de origen si es provisto por el frontend
        if lote_origen_id and animal.lote_id != int(lote_origen_id):
            return Response(
                {'error': 'El lote de origen enviado no coincide con el lote actual del animal.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        lote_origen_previo = animal.lote

        # 3. Proceso de actualización seguro con transacciones
        with transaction.atomic():
            # Guardamos el valor previo en formato string para la auditoría de FKs
            valor_anterior_lote = str(lote_origen_previo.id) if lote_origen_previo else ''
            
            # Actualizar el lote del animal
            animal.lote = lote_destino
            animal.save()

            # 4. Registro en AuditoriaAnimal (satisface criterios de aceptación e historial)
            ip_cliente = _get_ip(self.request)
            
            # Auditoría del cambio de lote
            AuditoriaAnimal.objects.create(
                animal=animal,
                usuario=usuario_perfil,
                campo='lote',
                valor_anterior=valor_anterior_lote,
                valor_nuevo=str(lote_destino.id),
                ip_address=ip_cliente,
            )

            # Si el frontend adjunta notas o fecha del movimiento en campo, se guarda en el historial
            if notas or fecha_movimiento:
                info_movimiento = f"Fecha Movimiento: {fecha_movimiento or 'No especificada'}. Notas: {notas}"
                AuditoriaAnimal.objects.create(
                    animal=animal,
                    usuario=usuario_perfil,
                    campo='movimiento_lote_detalles',
                    valor_anterior='',
                    valor_nuevo=info_movimiento,
                    ip_address=ip_cliente,
                )

            # 5. Contadores de animales por lote
            # Como tu LoteViewSet utiliza .annotate(animales_count=Count('animales')) de manera dinámica,
            # no es estrictamente obligatorio alterar campos físicos de contadores, sin embargo,
            # recalculamos aquí para dejar el valor persistido consistente.
            _recalcular_cabezas_lote(lote_destino)
            _recalcular_cabezas_lote(lote_origen_previo)

        return Response({
            'mensaje': f'El animal con arete {animal.numero_arete} se movió exitosamente al lote "{lote_destino.nombre}".',
            'animal_id': animal.id,
            'lote_origen_id': lote_origen_previo.id if lote_origen_previo else None,
            'lote_destino_id': animal.lote.id
        }, status=status.HTTP_200_OK)




class CicloReproductivoViewSet(viewsets.ModelViewSet):
    serializer_class = CicloReproductivoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = CicloReproductivo.objects.filter(animal__usuario=self.request.user.perfil)
        estado = self.request.query_params.get('estado')
        if estado:
            qs = qs.filter(estado=estado)
        return qs.select_related('animal')

    @action(detail=True, methods=['post'], url_path='registrar-parto')
    def registrar_parto(self, request, pk=None):
        """Marca un ciclo como 'pario', establece fecha_parto_real = hoy, y auto-calcula fecha_destete."""
        ciclo = self.get_object()
        if ciclo.estado not in ('gestante', 'en_servicio'):
            return Response(
                {'error': f'No se puede registrar parto en un ciclo con estado "{ciclo.estado}". Debe ser gestante o en_servicio.'},
                status=400,
            )
        from datetime import date
        ciclo.fecha_parto_real = date.today()
        ciclo.estado = 'pario'
        ciclo.save()
        serializer = self.get_serializer(ciclo)
        return Response(serializer.data, status=200)


class RegistroPesoViewSet(viewsets.ModelViewSet):
    serializer_class = RegistroPesoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = RegistroPeso.objects.filter(animal__usuario=self.request.user.perfil)
        animal_id = self.request.query_params.get('animal')
        if animal_id:
            qs = qs.filter(animal_id=animal_id)
        return qs


class EventoSanitarioViewSet(viewsets.ModelViewSet):
    serializer_class = EventoSanitarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = EventoSanitario.objects.filter(animal__usuario=self.request.user.perfil)
        animal_id = self.request.query_params.get('animal')
        tipo = self.request.query_params.get('tipo')
        if animal_id:
            qs = qs.filter(animal_id=animal_id)
        if tipo:
            qs = qs.filter(tipo=tipo)
        return qs


class AuditoriaLoginViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AuditoriaLoginSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = AuditoriaLogin.objects.filter(usuario=self.request.user.perfil)
        resultado = self.request.query_params.get('resultado')
        if resultado:
            qs = qs.filter(resultado=resultado)
        return qs


class RegistroNacimientoViewSet(viewsets.ModelViewSet):
    serializer_class = RegistroNacimientoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = RegistroNacimiento.objects.filter(madre__usuario=self.request.user.perfil)
        ciclo_id = self.request.query_params.get('ciclo')
        if ciclo_id:
            qs = qs.filter(ciclo_id=ciclo_id)
        return qs.select_related('ciclo', 'madre')

    def perform_create(self, serializer):
        serializer.save()


# ==================== KPIs Reproductivos ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def kpis_reproductivos(request):
    from datetime import timedelta
    from django.db.models import Count, Avg, F
    from django.utils import timezone
    
    usuario = request.user.perfil
    
    # Período: últimos 365 días
    fecha_inicio = timezone.now() - timedelta(days=365)
    
    # Total animales hembras
    total_hembras = Animal.objects.filter(usuario=usuario, sexo='H', estado='activo').count()
    
    # Ciclos en el período
    ciclos_periodo = CicloReproductivo.objects.filter(
        animal__usuario=usuario,
        fecha_servicio__gte=fecha_inicio
    )
    
    servicios = ciclos_periodo.count()
    gestaciones = ciclos_periodo.filter(estado='gestante').count()
    partos = ciclos_periodo.filter(estado='parido').count()
    
    # Tasa de concepción = servicios que quedaron gestanes / servicios totales
    tasa_concepcion = (gestaciones / servicios * 100) if servicios > 0 else 0
    
    # Tasa de natalidad = partos / gestaciones
    tasa_natalidad = (partos / gestaciones * 100) if gestaciones > 0 else 0
    
    # Intervalo Entre Partos (IEP) promedio
    ciclos = CicloReproductivo.objects.filter(
        animal__usuario=usuario,
        estado='parido',
        fecha_parto_real__isnull=False
    ).order_by('animal', 'fecha_parto_real')
    
    iep_list = []
    for animal_id in ciclos.values_list('animal', flat=True).distinct():
        animal_ciclos = ciclos.filter(animal_id=animal_id)
        if animal_ciclos.count() > 1:
            for i in range(1, animal_ciclos.count()):
                dias = (animal_ciclos[i].fecha_parto_real - animal_ciclos[i-1].fecha_parto_real).days
                if 180 < dias < 500:  # Filtro outliers
                    iep_list.append(dias)
    
    iep_promedio = sum(iep_list) / len(iep_list) if iep_list else 283
    
    # Nacimientos registrados
    nacimientos = RegistroNacimiento.objects.filter(
        madre__usuario=usuario,
        fecha_registro__gte=fecha_inicio
    )
    
    machos = nacimientos.filter(sexo='M').count()
    hembra = nacimientos.filter(sexo='H').count()
    
    return Response({
        'total_hembras': total_hembras,
        'servicios': servicios,
        'gestaciones': gestaciones,
        'partos': partos,
        'tasa_concepcion': round(tasa_concepcion, 1),
        'tasa_natalidad': round(tasa_natalidad, 1),
        'iep_dias': round(iep_promedio, 0),
        'nacimientos': {
            'total': nacimientos.count(),
            'machos': machos,
            'hembra': hembra,
        },
        'periodo_dias': 365,
    })


# ==================== IA - Calculadora de Gestación ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def calculadora_ia_gestacion(request):
    """
    Versión mejorada: analiza múltiples factores para predecir gestación.
    Usa: raza, historial de ciclos, edad del animal, condición corporal.
    """
    from datetime import timedelta
    from django.utils import timezone
    from django.db.models import Avg, F
    from django.db.models.functions import ExtractDay

    usuario = request.user.perfil
    animal_id = request.query_params.get('animal_id')

    if not animal_id:
        return Response({'error': 'animal_id es requerido'}, status=400)

    try:
        animal = Animal.objects.get(id=animal_id, usuario=usuario)
    except Animal.DoesNotExist:
        return Response({'error': 'Animal no encontrado'}, status=404)

    if animal.sexo != 'H':
        return Response({'error': 'Solo aplica a hembras'}, status=400)

    GESTACION_BASE = 283
    INVOLUCION_BASE = 60

    historial = CicloReproductivo.objects.filter(
        animal=animal,
        estado='pario',
        fecha_parto_real__isnull=False,
        fecha_servicio__isnull=False,
    ).order_by('-fecha_parto_real')

    ajuste_raza = 0
    razas_cortas = {'angus', 'hereford', 'shorthorn', 'aberdeen'}
    razas_largas = {'charoles', 'simmental', 'brahman', 'nelore', 'gir', 'guzera', 'indobrasil'}

    if animal.raza:
        raza_lower = animal.raza.strip().lower()
        if any(r in raza_lower for r in razas_cortas):
            ajuste_raza = -3
        elif any(r in raza_lower for r in razas_largas):
            ajuste_raza = 5

    gestacion_ajustada = GESTACION_BASE + ajuste_raza

    if historial.exists():
        stats = historial.aggregate(
            duracion_promedio=Avg(
                ExtractDay(F('fecha_parto_real') - F('fecha_servicio'))
            ),
        )

        if stats.get('duracion_promedio'):
            gestacion_ajustada = round(
                (stats['duracion_promedio'] * 0.7) + (gestacion_ajustada * 0.3)
            )

        ultimo = historial.first()
        partos_count = historial.count()
        fecha_ia_optima = ultimo.fecha_parto_real + timedelta(days=INVOLUCION_BASE)
        fecha_parto_estimada = fecha_ia_optima + timedelta(days=gestacion_ajustada)
        confianza = 'alta' if partos_count >= 3 else ('media' if partos_count >= 1 else 'baja')

        return Response({
            'animal_id': animal.id,
            'numero_arete': animal.numero_arete,
            'nombre': animal.nombre,
            'raza': animal.raza,
            'edad_dias': (timezone.now().date() - animal.fecha_nacimiento).days if animal.fecha_nacimiento else None,
            'partos_previos': partos_count,
            'fecha_ultimo_parto': ultimo.fecha_parto_real,
            'dias_involucion': INVOLUCION_BASE,
            'dias_gestacion_calculados': gestacion_ajustada,
            'fecha_ia_optima': fecha_ia_optima,
            'fecha_parto_estimada': fecha_parto_estimada,
            'confianza': confianza,
            'factores': {
                'gestacion_base': GESTACION_BASE,
                'ajuste_raza': ajuste_raza,
                'promedio_historial': round(stats.get('duracion_promedio', 0), 1) if stats.get('duracion_promedio') else None,
            },
        })

    fecha_ia_optima = None
    if animal.fecha_ultimo_parto:
        fecha_ia_optima = animal.fecha_ultimo_parto + timedelta(days=INVOLUCION_BASE)

    gestacion_final = GESTACION_BASE + ajuste_raza
    fecha_parto_estimada = (fecha_ia_optima + timedelta(days=gestacion_final)) if fecha_ia_optima else None

    return Response({
        'animal_id': animal.id,
        'numero_arete': animal.numero_arete,
        'nombre': animal.nombre,
        'raza': animal.raza,
        'edad_dias': (timezone.now().date() - animal.fecha_nacimiento).days if animal.fecha_nacimiento else None,
        'partos_previos': 0,
        'fecha_ultimo_parto': animal.fecha_ultimo_parto,
        'dias_involucion': INVOLUCION_BASE,
        'dias_gestacion_calculados': gestacion_final,
        'fecha_ia_optima': fecha_ia_optima,
        'fecha_parto_estimada': fecha_parto_estimada,
        'confianza': 'baja',
        'factores': {
            'gestacion_base': GESTACION_BASE,
            'ajuste_raza': ajuste_raza,
            'promedio_historial': None,
        },
    })


# ==================== Temporadas Reproductivas ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def temporadas_reproductivas(request):
    from datetime import timedelta
    from django.utils import timezone

    usuario = request.user.perfil
    temporada_nombre = request.query_params.get('temporada')

    qs = CicloReproductivo.objects.filter(animal__usuario=usuario)
    if temporada_nombre:
        qs = qs.filter(temporada__iexact=temporada_nombre)

    if not temporada_nombre:
        temporadas_conteo = qs.exclude(temporada__isnull=True).exclude(temporada='').values('temporada').annotate(
            total=Count('id', distinct=True),
            gestantes=Count('id', filter=Q(estado='gestante'), distinct=True),
            partos=Count('id', filter=Q(estado='pario'), distinct=True),
        ).order_by('-temporada')

        return Response([{
            'temporada': t['temporada'],
            'total_animales': t['total'],
            'gestantes': t['gestantes'],
            'partos': t['partos'],
        } for t in temporadas_conteo])

    animales = CicloReproductivo.objects.filter(
        animal__usuario=usuario,
        temporada__iexact=temporada_nombre,
    ).select_related('animal').distinct()

    from .serializer import AnimalSerializer
    animales_data = []
    for ciclo in animales:
        animal = ciclo.animal
        ser = AnimalSerializer(animal, context={'request': request})
        data = ser.data
        data['ciclo_estado'] = ciclo.estado
        data['ciclo_tipo_servicio'] = ciclo.tipo_servicio
        data['ciclo_fecha_servicio'] = ciclo.fecha_servicio
        data['ciclo_fecha_estimada_parto'] = ciclo.fecha_estimada_parto
        animales_data.append(data)

    return Response({
        'temporada': temporada_nombre,
        'animales': animales_data,
    })

# ==================== Árbol Genealógico ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def arbol_genealogico(request, animal_id):
    usuario = request.user.perfil
    
    try:
        animal = Animal.objects.get(id=animal_id, usuario=usuario)
    except Animal.DoesNotExist:
        return Response({'error': 'Animal no encontrado'}, status=404)
    
    # Construir árbol genealógico
    def get_ancestros(a, nivel=0, max_nivel=3):
        if nivel > max_nivel:
            return None
        
        data = {
            'id': a.id,
            'numero_arete': a.numero_arete,
            'nombre': a.nombre,
            'raza': a.raza,
            'sexo': a.sexo,
        }
        
        if a.madre_id:
            try:
                madre = Animal.objects.get(id=a.madre_id)
                data['madre'] = get_ancestros(madre, nivel + 1, max_nivel)
            except Animal.DoesNotExist:
                data['madre'] = None
        else:
            data['madre'] = None
            
        if a.padre_id:
            try:
                padre = Animal.objects.get(id=a.padre_id)
                data['padre'] = get_ancestros(padre, nivel + 1, max_nivel)
            except Animal.DoesNotExist:
                data['padre'] = None
        else:
            data['padre'] = None
            
        return data
    
    # Obtener crías del animal
    crias = Animal.objects.filter(
        usuario=usuario,
        madre_id=animal.id
    ).order_by('-fecha_nacimiento')[:10]
    
    return Response({
        'animal': get_ancestros(animal),
        'crias': [
            {
                'id': c.id,
                'numero_arete': c.numero_arete,
                'nombre': c.nombre,
                'fecha_nacimiento': c.fecha_nacimiento,
                'sexo': c.sexo,
            } for c in crias
        ]
    })


# ==================== Reporte de Consumo ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def reporte_consumo(request):
    from datetime import timedelta
    from django.db.models import Sum, Count
    from django.utils import timezone

    usuario = request.user.perfil
    dias_raw = request.query_params.get('dias', 30)
    try:
        dias = int(dias_raw)
    except (TypeError, ValueError):
        dias = 30
    lote_id = request.query_params.get('lote')
    if lote_id:
        try:
            lote_id = int(lote_id)
        except (TypeError, ValueError):
            lote_id = None

    fecha_inicio = timezone.now() - timedelta(days=dias)

    raciones = AlimentacionDiaria.objects.filter(
        Q(lote__usuario=usuario) | (Q(notas__startswith='animal_id:') & Q(usuario_registro=usuario)),
        fecha__gte=fecha_inicio
    ).select_related('lote', 'dieta')

    if lote_id:
        raciones = raciones.filter(lote_id=lote_id)

    agregados = raciones.aggregate(
        total_kg=Sum('cantidad_servida_kg'),
        costo_total=Sum('costo_total_racion'),
        registros=Count('id'),
    )
    total_kg = agregados['total_kg'] or 0
    costo_total = agregados['costo_total'] or 0
    num_raciones = agregados['registros'] or 0

    # Animales atendidos: cabeza-días alimentados (cabezas efectivas o 1 por ración especial)
    from .services.consumo_dietas import cabezas_efectivas_lote
    lotes_ids_en_raciones = {r.lote_id for r in raciones if r.lote_id}
    cabezas_map = {}
    if lotes_ids_en_raciones:
        lotes_anotados = Lote.objects.filter(pk__in=lotes_ids_en_raciones).annotate(
            activos=Count('animales', filter=Q(animales__estado='activo')),
            especiales=Count('animales', filter=Q(animales__estado='activo', animales__dieta__isnull=False)),
        )
        for lote in lotes_anotados:
            cabezas_map[lote.id] = cabezas_efectivas_lote(
                lote, activos=lote.activos, especiales=lote.especiales
            )

    animales_atendidos = sum((cabezas_map.get(r.lote_id, 0) if r.lote_id else 1) for r in raciones)

    promedio_diario_kg = float(total_kg) / dias if dias > 0 else 0
    costo_promedio_kg = float(costo_total / total_kg) if total_kg > 0 else 0

    # --- Gastos por lote (incluye raciones de dieta especial como "Sin lote") ---
    por_lote = []
    lotes_qs = (
        raciones
        .values('lote', 'lote__nombre', 'lote__cantidad_cabezas')
        .annotate(
            total_kg=Sum('cantidad_servida_kg'),
            costo_total=Sum('costo_total_racion'),
            registros=Count('id'),
        )
        .order_by('-costo_total')
    )
    for fila in lotes_qs:
        es_especial = fila['lote'] is None
        cabezas = cabezas_map.get(fila['lote']) if fila['lote'] else (fila['registros'] if es_especial else 0)
        kg = float(fila['total_kg'] or 0)
        costo = float(fila['costo_total'] or 0)
        por_lote.append({
            'lote_id': fila['lote'],
            'lote_nombre': (fila['lote__nombre'] or 'Animales con dieta especial'),
            'es_dieta_especial': es_especial,
            'cabezas': cabezas,
            'total_kg': kg,
            'costo_total': costo,
            'registros': fila['registros'],
            'costo_por_kg': round(costo / kg, 2) if kg > 0 else 0,
            'costo_por_cabeza': round(costo / cabezas, 2) if cabezas > 0 else 0,
            'kg_por_cabeza': round(kg / cabezas, 2) if cabezas > 0 else 0,
        })

    #insumos gastados
    salidas = MovimientoInventario.objects.filter(
        insumo__usuario=usuario,
        tipo_movimiento='salida',
        fecha_movimiento__gte=fecha_inicio,
    ).select_related('insumo')

    gastados_map = {}
    for m in salidas:
        costo_unit = m.costo_unitario_kg if m.costo_unitario_kg else m.insumo.costo_kg
        if m.cantidad_kg is None or costo_unit is None:
            continue
        entry = gastados_map.get(m.insumo_id)
        if entry is None:
            entry = {
                'insumo_id': m.insumo_id,
                'nombre': m.insumo.nombre,
                'kg': Decimal('0'),
                'costo_total': Decimal('0'),
                'movimientos': 0,
            }
            gastados_map[m.insumo_id] = entry
        kg = Decimal(m.cantidad_kg)
        entry['kg'] += kg
        entry['costo_total'] += kg * Decimal(costo_unit)
        entry['movimientos'] += 1

    insumos_gastados = [
        {
            'insumo_id': e['insumo_id'],
            'nombre': e['nombre'],
            'kg': float(e['kg']),
            'costo_total': float(e['costo_total']),
            'movimientos': e['movimientos'],
        }
        for e in sorted(gastados_map.values(), key=lambda x: x['costo_total'], reverse=True)
    ]

    total_gastado_kg = sum(e['kg'] for e in insumos_gastados)
    total_gastado_costo = sum(e['costo_total'] for e in insumos_gastados)

    # insumos disponibles
    insumos_disponibles = []
    for i in Insumo.objects.filter(usuario=usuario).order_by('nombre'):
        stock = Decimal(i.cantidad_actual_kg) if i.cantidad_actual_kg is not None else Decimal('0')
        minimo = Decimal(i.stock_minimo_kg) if i.stock_minimo_kg is not None else Decimal('0')
        costo = Decimal(i.costo_kg) if i.costo_kg is not None else Decimal('0')
        insumos_disponibles.append({
            'insumo_id': i.id,
            'nombre': i.nombre,
            'stock_kg': float(stock),
            'stock_minimo_kg': float(minimo),
            'costo_kg': float(costo),
            'valor_total': float(stock * costo),
            'bajo_stock': stock < minimo,
        })

    valor_inventario = sum(e['valor_total'] for e in insumos_disponibles)
    alertas = sum(1 for e in insumos_disponibles if e['bajo_stock'])

    return Response({
        'periodo_dias': dias,
        'desde': fecha_inicio.date().isoformat(),
        'hasta': timezone.now().date().isoformat(),
        'actualizado_en': timezone.now().isoformat(),
        'total_kg': float(total_kg),
        'costo_total': float(costo_total),
        'registros': num_raciones,
        'lotes_atendidos': len(por_lote),
        'animales_atendidos': animales_atendidos,
        'kg_por_animal': round(float(total_kg) / animales_atendidos, 2) if animales_atendidos > 0 else 0,
        'costo_por_animal': round(float(costo_total) / animales_atendidos, 2) if animales_atendidos > 0 else 0,
        'promedio_diario_kg': round(promedio_diario_kg, 2),
        'costo_promedio_por_kg': round(costo_promedio_kg, 2),
        'proyeccion_30_dias_kg': round(promedio_diario_kg * 30, 1),
        'proyeccion_30_dias_costo': round(promedio_diario_kg * 30 * costo_promedio_kg, 2),
        'por_lote': por_lote,
        'insumos_gastados': insumos_gastados,
        'insumos_disponibles': insumos_disponibles,
        'total_gastado_kg': float(total_gastado_kg),
        'total_gastado_costo': float(total_gastado_costo),
        'valor_inventario_actual': valor_inventario,
        'alerta_insumos': alertas,
    })


# ==================== Planes de Suscripción ====================
@api_view(['GET'])
@permission_classes([AllowAny])
def listar_planes(request):
    """Lista todos los planes disponibles"""
    planes = PlanSuscripcion.objects.filter(activo=True)
    serializer = PlanSuscripcionSerializer(planes, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def mi_plan(request):
    """Información del plan actual del usuario"""
    usuario = request.user.perfil
    plan = usuario.plan_actual
    animales_actuales = usuario.animales.count()
    usuarios_actuales = usuario.colaboradores.filter(activo=True).count()

    data = {
        'plan': PlanSuscripcionSerializer(plan).data,
        'limite_animales': plan.limite_animales,
        'animales_actuales': animales_actuales,
        'animales_disponibles': max(0, plan.limite_animales - animales_actuales),
        'limite_usuarios': plan.limite_usuarios,
        'usuarios_actuales': usuarios_actuales,
        'usuarios_disponibles': max(0, plan.limite_usuarios - usuarios_actuales),
        'puede_crear_animal': usuario.puede_crear_animal(),
        'puede_invitar': usuario.puede_invitar_usuario(),
        'incluye_modulo_animales': plan.incluye_modulo_animales,
        'incluye_modulo_lotes': plan.incluye_modulo_lotes,
        'incluye_modulo_dietas': plan.incluye_modulo_dietas,
        'incluye_modulo_sanitaria': plan.incluye_modulo_sanitaria,
        'incluye_reportes_avanzados': plan.incluye_reportes_avanzados,
        'incluye_api': plan.incluye_api,
        'soporte_prioritario': plan.soporte_prioritario,
    }

    if hasattr(usuario, 'suscripcion'):
        data['suscripcion'] = {
            'fecha_inicio': usuario.suscripcion.fecha_inicio,
            'fecha_renovacion': usuario.suscripcion.fecha_renovacion,
            'activa': usuario.suscripcion.activa,
        }

    return Response(data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cambiar_plan(request):
    """Cambiar el plan de suscripción del usuario"""
    usuario = request.user.perfil
    plan_codigo = request.data.get('plan_codigo')

    if not plan_codigo:
        return Response({'error': 'Se requiere plan_codigo'}, status=400)

    try:
        plan = PlanSuscripcion.objects.get(codigo=plan_codigo, activo=True)
    except PlanSuscripcion.DoesNotExist:
        return Response({'error': 'Plan no encontrado'}, status=404)

    from datetime import timedelta
    from dateutil.relativedelta import relativedelta
    from django.utils import timezone

    if hasattr(usuario, 'suscripcion'):
        suscripcion = usuario.suscripcion
        suscripcion.plan = plan
        suscripcion.activa = True
        suscripcion.fecha_cancelacion = None
        if plan.precio_mxn > 0:
            suscripcion.fecha_renovacion = timezone.now().date() + relativedelta(months=1)
        suscripcion.save()
    else:
        fecha_renovacion = None
        if plan.precio_mxn > 0:
            fecha_renovacion = timezone.now().date() + relativedelta(months=1)

        SuscripcionUsuario.objects.create(
            usuario=usuario,
            plan=plan,
            fecha_renovacion=fecha_renovacion,
            activa=True
        )

    return Response({
        'mensaje': f'Plan cambiado a {plan.nombre}',
        'plan': PlanSuscripcionSerializer(plan).data
    })


@api_view(['GET', 'POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def gestionar_colaboradores(request, colaborador_id=None):
    """Gestionar colaboradores de la cuenta"""
    usuario = request.user.perfil
    plan = usuario.plan_actual

    if request.method == 'GET':
        colaboradores = usuario.colaboradores.filter(activo=True)
        serializer = UsuarioInvitadoSerializer(colaboradores, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if not plan.limite_usuarios > 1:
            return Response({'error': 'Tu plan no permite invitar colaboradores'}, status=403)

        email_invitado = request.data.get('email')
        rol = request.data.get('rol', 'editor')

        if not email_invitado:
            return Response({'error': 'Se requiere email'}, status=400)

        try:
            usuario_invitado = Usuario.objects.get(email=email_invitado)
        except Usuario.DoesNotExist:
            return Response({'error': 'Usuario no encontrado. Debe registrarse primero en la plataforma.'}, status=404)

        if usuario.colaboradores.filter(activo=True).count() >= plan.limite_usuarios:
            return Response({'error': 'Has alcanzado el límite de usuarios de tu plan'}, status=403)

        if UsuarioInvitado.objects.filter(cuenta_principal=usuario, usuario=usuario_invitado).exists():
            return Response({'error': 'Este usuario ya es colaborador de tu cuenta'}, status=400)

        UsuarioInvitado.objects.create(
            cuenta_principal=usuario,
            usuario=usuario_invitado,
            rol=rol
        )

        return Response({'mensaje': f'Usuario {email_invitado} añadido como colaborador'}, status=201)

    elif request.method == 'DELETE':
        if not colaborador_id:
            return Response({'error': 'Se requiere ID del colaborador'}, status=400)

        try:
            colaborador = UsuarioInvitado.objects.get(id=colaborador_id, cuenta_principal=usuario)
            colaborador.activo = False
            colaborador.save()
            return Response(status=204)
        except UsuarioInvitado.DoesNotExist:
            return Response({'error': 'Colaborador no encontrado'}, status=404)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def verificar_limites(request):
    """Verificar si el usuario puede realizar ciertas acciones"""
    usuario = request.user.perfil
    plan = usuario.plan_actual
    animales_actuales = usuario.animales.count()
    usuarios_actuales = usuario.colaboradores.filter(activo=True).count()

    return Response({
        'puede_crear_animal': usuario.puede_crear_animal(),
        'animales_disponibles': max(0, plan.limite_animales - animales_actuales),
        'limite_animales': plan.limite_animales,
        'puede_invitar': usuario.puede_invitar_usuario(),
        'usuarios_disponibles': max(0, plan.limite_usuarios - usuarios_actuales),
        'limite_usuarios': plan.limite_usuarios,
        'incluye_reportes_avanzados': plan.incluye_reportes_avanzados,
        'incluye_api': plan.incluye_api,
    })


def _location_payload(usuario):
    configured = usuario.latitud_rancho is not None and usuario.longitud_rancho is not None
    return {
        'configurada': configured,
        'latitud': float(usuario.latitud_rancho) if configured else None,
        'longitud': float(usuario.longitud_rancho) if configured else None,
        'direccion': usuario.direccion_rancho if configured else None,
    }


@api_view(['GET', 'PUT'])
@permission_classes([IsAuthenticated])
def ubicacion_clima(request):
    owner = get_account_owner(request.user)
    if request.method == 'GET':
        return Response(_location_payload(owner))

    serializer = UbicacionClimaSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    latitude = serializer.validated_data['latitud']
    longitude = serializer.validated_data['longitud']
    try:
        address = reverse_geocode(latitude, longitude)
    except WeatherProviderError:
        address = owner.direccion_rancho or f'Lat. {latitude}, Long. {longitude}'

    with transaction.atomic():
        owner.latitud_rancho = latitude
        owner.longitud_rancho = longitude
        owner.direccion_rancho = address
        owner.save(update_fields=['latitud_rancho', 'longitud_rancho', 'direccion_rancho'])
    return Response(_location_payload(owner))


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def clima_actual(request):
    owner = get_account_owner(request.user)
    if owner.latitud_rancho is None or owner.longitud_rancho is None:
        return Response(
            {'code': 'LOCATION_REQUIRED', 'message': 'Configura la ubicación de tu rancho.'},
            status=status.HTTP_409_CONFLICT,
        )
    try:
        payload = get_current_weather(
            owner.latitud_rancho,
            owner.longitud_rancho,
            owner.direccion_rancho,
        )
    except WeatherProviderError:
        return Response(
            {'code': 'WEATHER_UNAVAILABLE', 'message': 'No fue posible consultar el clima. Intenta nuevamente.'},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )
    return Response(payload)
