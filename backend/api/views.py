from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import viewsets, generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth.models import User as AuthUser

#Importaciones para los viewsets en /api/
from .serializer import UsuarioSerializer, ProveedorSerializer, CategoriaInsumoSerializer, InsumoSerializer, MovimientoInventarioSerializer, DietaSerializer, DietaInsumoSerializer, LoteSerializer, PesajeLoteSerializer, AlimentacionDiariaSerializer, RegisterSerializer, UserProfileSerializer, AnimalSerializer, CicloReproductivoSerializer, RegistroPesoSerializer, EventoSanitarioSerializer
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal, CicloReproductivo, RegistroPeso, EventoSanitario

@api_view(['GET'])
def health_check(request):
    return Response({
        'status': 'ok',
        'message': '¡AgroGestor backend funcionando!'
    })

# Auth views
class RegisterView(generics.CreateAPIView):
    queryset = AuthUser.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer


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
        return Insumo.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class MovimientoInventarioViewSet(viewsets.ModelViewSet):
    serializer_class = MovimientoInventarioSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return MovimientoInventario.objects.filter(insumo__usuario=self.request.user.perfil)


class DietaViewSet(viewsets.ModelViewSet):
    serializer_class = DietaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Dieta.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class DietaInsumoViewSet(viewsets.ModelViewSet):
    serializer_class = DietaInsumoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return DietaInsumo.objects.filter(dieta__usuario=self.request.user.perfil)


class LoteViewSet(viewsets.ModelViewSet):
    serializer_class = LoteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Lote.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class PesajeLoteViewSet(viewsets.ModelViewSet):
    serializer_class = PesajeLoteSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PesajeLote.objects.filter(lote__usuario=self.request.user.perfil)


class AlimentacionDiariaViewSet(viewsets.ModelViewSet):
    serializer_class = AlimentacionDiariaSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return AlimentacionDiaria.objects.filter(lote__usuario=self.request.user.perfil)


# ViewSets Bovion
class AnimalViewSet(viewsets.ModelViewSet):
    serializer_class = AnimalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Animal.objects.filter(usuario=self.request.user.perfil)
        lote_id = self.request.query_params.get('lote')
        sexo = self.request.query_params.get('sexo')
        estado = self.request.query_params.get('estado')
        if lote_id:
            qs = qs.filter(lote_id=lote_id)
        if sexo:
            qs = qs.filter(sexo=sexo)
        if estado:
            qs = qs.filter(estado=estado)
        return qs.select_related('lote', 'madre', 'padre').prefetch_related('registros_peso')

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class CicloReproductivoViewSet(viewsets.ModelViewSet):
    serializer_class = CicloReproductivoSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = CicloReproductivo.objects.filter(animal__usuario=self.request.user.perfil)
        estado = self.request.query_params.get('estado')
        if estado:
            qs = qs.filter(estado=estado)
        return qs.select_related('animal')


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