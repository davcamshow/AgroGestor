from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User as AuthUser
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework import serializers
from rest_framework.validators import UniqueValidator
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal, CicloReproductivo, RegistroPeso, EventoSanitario, AuditoriaLogin, RegistroNacimiento, PlanSuscripcion, SuscripcionUsuario, UsuarioInvitado, AuditoriaAnimal
from django.utils import timezone

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
        activation_link = (
            f"http://localhost:8000/api/auth/activate/"
            f"?uidb64={uid}&token={token}"
        )

        subject = 'Activa tu cuenta en Bovion'
        message = (
            f'Hola {auth_user.email},\n\n'
            'Gracias por registrarte en Bovion. Para activar tu cuenta, haz clic en el siguiente enlace:\n\n'
            f'{activation_link}\n\n'
            'Si no solicitaste esta cuenta, ignora este correo.\n'
        )

        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [auth_user.email],
            fail_silently=False,
        )

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

class DietaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dieta
        fields = '__all__'
        read_only_fields = ('usuario', 'fecha_creacion', 'ultima_modificacion')

class DietaInsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DietaInsumo
        fields = '__all__'

class LoteSerializer(serializers.ModelSerializer):
    capacidad_maxima = serializers.IntegerField(read_only=True)
    animales_count = serializers.IntegerField(read_only=True)

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