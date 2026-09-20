from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User as AuthUser
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import EmailMultiAlternatives
import os
from email.mime.image import MIMEImage
from django.template.loader import render_to_string
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework import serializers
from rest_framework.validators import UniqueValidator
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal, CicloReproductivo, RegistroPeso, EventoSanitario, AuditoriaLogin, RegistroNacimiento, PlanSuscripcion, SuscripcionUsuario, UsuarioInvitado, AuditoriaAnimal
from django.utils import timezone
from decimal import Decimal, InvalidOperation
import math


class FiniteCoordinateField(serializers.DecimalField):
    """Decimal estricto que rechaza booleanos, NaN e infinitos."""

    def to_internal_value(self, data):
        if isinstance(data, bool):
            self.fail('invalid')
        if isinstance(data, float) and not math.isfinite(data):
            self.fail('invalid')
        try:
            value = Decimal(str(data))
        except (InvalidOperation, TypeError, ValueError):
            self.fail('invalid')
        if not value.is_finite():
            self.fail('invalid')
        try:
            # Los mapas entregan doubles que pueden serializar residuos como
            # 19.432608000000002. Normalizamos a la precisión persistida.
            value = value.quantize(Decimal('0.000001'))
        except InvalidOperation:
            self.fail('invalid')
        return super().to_internal_value(format(value, 'f'))


class UbicacionClimaSerializer(serializers.Serializer):
    latitud = FiniteCoordinateField(
        max_digits=9,
        decimal_places=6,
        min_value=Decimal('-90'),
        max_value=Decimal('90'),
    )
    longitud = FiniteCoordinateField(
        max_digits=9,
        decimal_places=6,
        min_value=Decimal('-180'),
        max_value=Decimal('180'),
    )

    def validate(self, attrs):
        unexpected = set(self.initial_data) - {'latitud', 'longitud'}
        if unexpected:
            raise serializers.ValidationError(
                {'non_field_errors': ['La solicitud contiene campos no permitidos.']}
            )
        return attrs

# Auth Serializers
class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        validators=[UniqueValidator(queryset=AuthUser.objects.all())],
        error_messages={
            'unique': 'Este correo ya existe.',
            'invalid': 'Introduce un correo válido.',
            'required': 'El correo es requerido.',
        },
    )
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    nombre_completo = serializers.CharField(required=True)
    telefono = serializers.CharField(required=False, allow_blank=True)
    rol_profesional = serializers.CharField(required=False, allow_blank=True)

    def create(self, validated_data):
        email = validated_data['email']
        password = validated_data['password']
        nombre = validated_data.get('nombre_completo', '')
        telefono = validated_data.get('telefono', '')
        rol = validated_data.get('rol_profesional', '')

        # Create AuthUser with email as username
        auth_user = AuthUser.objects.create_user(
            username=email,
            email=email,
            password=password,
            is_active=False,
        )

        # Create the linked profile
        Usuario.objects.create(
            auth_user=auth_user,
            nombre_completo=nombre,
            email=email,
            telefono=telefono,
            rol_profesional=rol,
            password_hash=''
        )

        self._send_activation_email(auth_user)
        return auth_user

    def _send_activation_email(self, auth_user):
        uid = urlsafe_base64_encode(force_bytes(auth_user.pk))
        token = default_token_generator.make_token(auth_user)

        backend_base = getattr(settings, 'BACKEND_URL', 'http://localhost:8000').rstrip('/')
        activation_link = (
            f"{backend_base}/api/auth/activate/?uidb64={uid}&token={token}"
        )

        subject = 'Activa tu cuenta en Bovion'

        # Intentar usar logo local en static/images como CID inline
        base_dir = getattr(settings, 'BASE_DIR', None)
        static_logo_path = None
        logo_cid = None
        if base_dir:
            static_logo_path = os.path.join(str(base_dir), 'static', 'images', 'bovion-logo.png')

        # URL pública como fallback (configurable)
        logo_url = getattr(
            settings,
            'LOGO_URL',
            'https://vcxdtkekiweomnemfwdk.supabase.co/storage/v1/object/public/imagenes/bovion-logo.png'
        )

        if static_logo_path and os.path.exists(static_logo_path):
            logo_cid = 'bovion_logo'

        # Renderizar HTML indicando si usaremos CID
        html_content = render_to_string('emails/activation_email.html', {
            'email': auth_user.email,
            'activation_link': activation_link,
            'logo_url': logo_url,
            'logo_cid': logo_cid,
        })

        text_content = (
            f'Hola {auth_user.email},\n\n'
            'Gracias por registrarte en Bovion. Usa el enlace de activación a continuación:\n\n'
            f'{activation_link}\n\n'
            'Si no solicitaste esta cuenta, ignora este correo.\n'
        )

        email_message = EmailMultiAlternatives(
            subject,
            text_content,
            settings.DEFAULT_FROM_EMAIL,
            [auth_user.email],
        )
        email_message.attach_alternative(html_content, 'text/html')

        # Adjuntar inline si encontramos el logo local
        if logo_cid and static_logo_path and os.path.exists(static_logo_path):
            try:
                with open(static_logo_path, 'rb') as f:
                    img_data = f.read()
                image = MIMEImage(img_data)
                image.add_header('Content-ID', f'<{logo_cid}>')
                image.add_header('Content-Disposition', 'inline')
                image.add_header('X-Attachment-Id', logo_cid)
                email_message.attach(image)
            except Exception:
                pass

        email_message.send(fail_silently=False)

    def save(self):
        return self.create(self.validated_data)


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ('id', 'nombre_completo', 'email', 'telefono', 'rol_profesional',
                  'cedula', 'nombre_rancho', 'direccion_rancho', 'moneda', 'unidad_peso')

#Serializadores para cada modelo
class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = '__all__'
        read_only_fields = ('fecha_registro',)

class ProveedorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Proveedor
        fields = '__all__'
        read_only_fields = ('usuario',)

class CategoriaInsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoriaInsumo
        fields = '__all__'
        read_only_fields = ('usuario',)

class InsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Insumo
        fields = '__all__'
        read_only_fields = ('usuario', 'fecha_actualizacion')

class MovimientoInventarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = MovimientoInventario
        fields = '__all__'
        read_only_fields = ('fecha_movimiento',)

    def validate_tipo_movimiento(self, value):
        value = (value or '').strip().lower()
        if value not in {'entrada', 'salida'}:
            raise serializers.ValidationError(
                'El tipo de movimiento debe ser "entrada" o "salida".'
            )
        return value

    def validate_cantidad_kg(self, value):
        if value is not None and value <= 0:
            raise serializers.ValidationError('La cantidad debe ser mayor a 0.')
        return value

class DietaSerializer(serializers.ModelSerializer):
    ingredientes_count = serializers.SerializerMethodField()

    class Meta:
        model = Dieta
        fields = '__all__'
        read_only_fields = ('usuario', 'fecha_creacion', 'ultima_modificacion', 'ingredientes_count')

    def get_ingredientes_count(self, obj):
        return obj.dietainsumo_set.count()

    def validate_nombre(self, value):
        value = (value or '').strip()
        if not value:
            raise serializers.ValidationError('El nombre de la dieta es obligatorio.')
        return value

    def validate_objetivo(self, value):
        value = (value or '').strip()
        if not value:
            raise serializers.ValidationError('Indica el objetivo de la dieta (ej. engorda, lactancia, destete).')
        return value

    def validate_estado(self, value):
        if value not in dict(Dieta.ESTADOS):
            raise serializers.ValidationError(f'Estado inválido. Usa: {", ".join(dict(Dieta.ESTADOS))}')
        return value

    def validate_tipo_formulacion(self, value):
        if value not in dict(Dieta.TIPOS_FORMULACION):
            raise serializers.ValidationError('Tipo de formulación inválido (porcentaje o tabla_kg).')
        return value

    def validate_periodicidad(self, value):
        if value not in dict(Dieta.PERIODICIDADES):
            raise serializers.ValidationError('Periodicidad inválida (diaria, semanal o quincenal).')
        return value

    def validate_costo_estimado_kg(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError('El costo por kg no puede ser negativo.')
        return value

    def validate_cantidad_kg_cabeza(self, value):
        if value is not None and value <= 0:
            raise serializers.ValidationError('La cantidad de kg por cabeza debe ser mayor a 0.')
        return value

class DietaInsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DietaInsumo
        fields = '__all__'
        # La duplicidad (dieta, insumo) se valida a mano con mensaje amigable
        validators = []

    def validate(self, attrs):
        attrs = super().validate(attrs)
        usuario = self.context['request'].user.perfil

        dieta = attrs.get('dieta') or (self.instance.dieta if self.instance else None)
        insumo = attrs.get('insumo') or (self.instance.insumo if self.instance else None)

        if dieta and dieta.usuario_id != usuario.id:
            raise serializers.ValidationError({'dieta': 'La dieta no pertenece a tu cuenta.'})
        if insumo and insumo.usuario_id != usuario.id:
            raise serializers.ValidationError({'insumo': 'El insumo no pertenece a tu cuenta.'})

        porcentaje = attrs.get('porcentaje_inclusion') or (self.instance.porcentaje_inclusion if self.instance else None)
        cantidad_kg = attrs.get('cantidad_kg') or (self.instance.cantidad_kg if self.instance else None)

        if not porcentaje and not cantidad_kg:
            raise serializers.ValidationError(
                'Indica el porcentaje de inclusión o la cantidad en kg por cabeza.'
            )
        if porcentaje is not None:
            if porcentaje <= 0:
                raise serializers.ValidationError({'porcentaje_inclusion': 'El porcentaje debe ser mayor a 0.'})
            if porcentaje > 100:
                raise serializers.ValidationError({'porcentaje_inclusion': 'El porcentaje máximo es 100%.'})
        if cantidad_kg is not None and cantidad_kg <= 0:
            raise serializers.ValidationError({'cantidad_kg': 'La cantidad debe ser mayor a 0.'})

        if dieta and insumo:
            qs = DietaInsumo.objects.filter(dieta=dieta, insumo=insumo)
            if self.instance:
                qs = qs.exclude(pk=self.instance.pk)
            if qs.exists():
                raise serializers.ValidationError(
                    {'insumo': 'Ese insumo ya está agregado a la dieta. Edítalo o agrégalo una sola vez.'}
                )
        return attrs

class LoteSerializer(serializers.ModelSerializer):
    capacidad_maxima = serializers.IntegerField(read_only=True)
    animales_count = serializers.IntegerField(read_only=True, default=0)
    animales_activos = serializers.IntegerField(read_only=True, default=0)
    cabezas_efectivas = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Lote
        fields = '__all__'
        read_only_fields = ('usuario',)

    def validate(self, attrs):
        attrs = super().validate(attrs)
        if attrs.get('cantidad_cabezas'):
            cantidad = attrs['cantidad_cabezas']
            etapa = attrs.get('etapa_productiva')
            
            CAPACIDADES = {
                'destete': 50,
                'crecimiento': 100,
                'engorda': 200,
                'produccion': 150,
                'vigilancia': 30,
            }
            
            capacidad_max = CAPACIDADES.get(etapa.lower() if etapa else '', 100)
            capacidad_min = 1
            
            if cantidad > capacidad_max:
                raise serializers.ValidationError({
                    'cantidad_cabezas': f'La capacidad máxima para etapa {etapa} es de {capacidad_max} cabezas'
                })
            if cantidad < capacidad_min:
                raise serializers.ValidationError({
                    'cantidad_cabezas': f'La capacidad mínima es de {capacidad_min} cabeza(s)'
                })
        return attrs

class PesajeLoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PesajeLote
        fields = '__all__'

class AlimentacionDiariaSerializer(serializers.ModelSerializer):
    class Meta:
        model = AlimentacionDiaria
        fields = '__all__'

    def validate(self, attrs):
        attrs = super().validate(attrs)
        usuario = self.context['request'].user.perfil

        lote = attrs.get('lote') or (self.instance.lote if self.instance else None)
        dieta = attrs.get('dieta') or (self.instance.dieta if self.instance else None)

        if lote and lote.usuario_id != usuario.id:
            raise serializers.ValidationError({'lote': 'El lote no pertenece a tu cuenta.'})
        if dieta and dieta.usuario_id != usuario.id:
            raise serializers.ValidationError({'dieta': 'La dieta no pertenece a tu cuenta.'})

        cantidad = attrs.get('cantidad_servida_kg')
        if cantidad is not None and cantidad < 0:
            raise serializers.ValidationError({'cantidad_servida_kg': 'La cantidad no puede ser negativa.'})
        costo = attrs.get('costo_total_racion')
        if costo is not None and costo < 0:
            raise serializers.ValidationError({'costo_total_racion': 'El costo no puede ser negativo.'})

        if not attrs.get('lote') and not attrs.get('notas'):
            raise serializers.ValidationError(
                'Una ración debe pertenecer a un lote o llevar el marcador de animal (notas).'
            )
        return attrs


class AuditoriaAnimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditoriaAnimal
        fields = '__all__'
 
 
class AnimalSerializer(serializers.ModelSerializer):
    edad_dias = serializers.SerializerMethodField()
    ultimo_peso_kg = serializers.SerializerMethodField()
    ultimo_peso = serializers.SerializerMethodField()
    fecha_ultimo_peso = serializers.SerializerMethodField()
 
    class Meta:
        model = Animal
        fields = '__all__'
        read_only_fields = ('usuario', 'fecha_registro')
        extra_kwargs = {
            'foto': {'required': False, 'allow_null': True},
            'dieta': {'required': False, 'allow_null': True},
            'lote': {'required': False, 'allow_null': True},
        }

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        if instance.foto:
            url = instance.foto.url
            data['foto'] = request.build_absolute_uri(url) if request else url
        else:
            data['foto'] = None
        return data

    def validate_foto(self, value):
        if not value:
            return value
        if value.size > 8 * 1024 * 1024:
            raise serializers.ValidationError('La foto no puede superar 8 MB.')
        content_type = getattr(value, 'content_type', '') or ''
        if content_type and content_type not in {
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/webp',
        }:
            raise serializers.ValidationError(
                'Formato de imagen no válido. Usa JPG, PNG o WEBP.'
            )
        return value
 
    def get_edad_dias(self, obj):
        if obj.fecha_nacimiento:
            return (timezone.now().date() - obj.fecha_nacimiento).days
        return None
 
    def get_ultimo_peso_kg(self, obj):
        ultimo = obj.registros_peso.first()
        return str(ultimo.peso_kg) if ultimo else None
 
    def get_ultimo_peso(self, obj):
        ultimo = obj.registros_peso.first()
        return float(ultimo.peso_kg) if ultimo else None
 
    def get_fecha_ultimo_peso(self, obj):
        ultimo = obj.registros_peso.first()
        return ultimo.fecha_pesaje if ultimo else None
 
    def validate_numero_arete(self, value):
        """Asegura que la caravana sea única por usuario, excluyendo la instancia actual."""
        request = self.context.get('request')
        usuario = None
        if request and hasattr(request.user, 'perfil'):
            usuario = request.user.perfil
 
        qs = Animal.objects.filter(usuario=usuario, numero_arete=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError(
                f"Ya existe un animal con el número de caravana '{value}'."
            )
        return value


class CicloReproductivoSerializer(serializers.ModelSerializer):
    dias_restantes_parto = serializers.SerializerMethodField()

    class Meta:
        model = CicloReproductivo
        fields = '__all__'

    def get_dias_restantes_parto(self, obj):
        if obj.fecha_estimada_parto and obj.estado == 'gestante':
            delta = obj.fecha_estimada_parto - timezone.now().date()
            return delta.days
        return None


class RegistroPesoSerializer(serializers.ModelSerializer):
    class Meta:
        model = RegistroPeso
        fields = '__all__'
        read_only_fields = ('ganancia_diaria_kg',)


class EventoSanitarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventoSanitario
        fields = '__all__'


class AuditoriaLoginSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditoriaLogin
        fields = '__all__'
        read_only_fields = ('fecha_intento',)


class RegistroNacimientoSerializer(serializers.ModelSerializer):
    class Meta:
        model = RegistroNacimiento
        fields = '__all__'
        read_only_fields = ('fecha_registro',)


# ==================== Serializers de Planes ====================
class PlanSuscripcionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlanSuscripcion
        fields = '__all__'


class SuscripcionUsuarioSerializer(serializers.ModelSerializer):
    plan = PlanSuscripcionSerializer(read_only=True)
    plan_id = serializers.PrimaryKeyRelatedField(
        queryset=PlanSuscripcion.objects.all(),
        source='plan',
        write_only=True
    )

    class Meta:
        model = SuscripcionUsuario
        fields = ['id', 'plan', 'plan_id', 'fecha_inicio', 'fecha_renovacion', 'activa', 'fecha_cancelacion']
        read_only_fields = ('fecha_inicio',)


class UsuarioInvitadoSerializer(serializers.ModelSerializer):
    usuario_nombre = serializers.CharField(source='usuario.nombre_completo', read_only=True)
    usuario_email = serializers.CharField(source='usuario.email', read_only=True)

    class Meta:
        model = UsuarioInvitado
        fields = ['id', 'usuario', 'usuario_nombre', 'usuario_email', 'rol', 'activo', 'fecha_invitacion']
        read_only_fields = ('fecha_invitacion',)


class InfoPlanUsuarioSerializer(serializers.Serializer):
    """Serializer con la información completa del plan del usuario"""
    plan = PlanSuscripcionSerializer()
    suscripcion = SuscripcionUsuarioSerializer()
    limite_animales = serializers.IntegerField()
    animales_actuales = serializers.IntegerField()
    animales_disponibles = serializers.IntegerField()
    limite_usuarios = serializers.IntegerField()
    usuarios_actuales = serializers.IntegerField()
    usuarios_disponibles = serializers.IntegerField()
    puede_crear_animal = serializers.BooleanField()
    puede_invitar = serializers.BooleanField()
