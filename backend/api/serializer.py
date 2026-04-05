from rest_framework import serializers
from django.contrib.auth.models import User as AuthUser
from django.contrib.auth.password_validation import validate_password
from rest_framework.validators import UniqueValidator
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria

# Auth Serializers
class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        validators=[UniqueValidator(queryset=AuthUser.objects.all())]
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
            password=password
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
        return auth_user

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

class ProveedorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Proveedor
        fields = '__all__'

class CategoriaInsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoriaInsumo
        fields = '__all__'

class InsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Insumo
        fields = '__all__'

class MovimientoInventarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = MovimientoInventario
        fields = '__all__'

class DietaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Dieta
        fields = '__all__'

class DietaInsumoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DietaInsumo
        fields = '__all__'

class LoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Lote
        fields = '__all__'

class PesajeLoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PesajeLote
        fields = '__all__'

class AlimentacionDiariaSerializer(serializers.ModelSerializer):
    class Meta:
        model = AlimentacionDiaria
        fields = '__all__'