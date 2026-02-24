from rest_framework.decorators import api_view
from rest_framework.response import Response

#Importaciones para los viewsets en /api/
from rest_framework import viewsets
from .serializer import UsuarioSerializer, ProveedorSerializer, CategoriaInsumoSerializer, InsumoSerializer, MovimientoInventarioSerializer, DietaSerializer, DietaInsumoSerializer, LoteSerializer, PesajeLoteSerializer, AlimentacionDiariaSerializer
from .models import Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria

@api_view(['GET'])
def health_check(request):
    return Response({
        'status': 'ok', 
        'message': '¡AgroGestor backend funcionando!'
    })

# ViewSets para cada modelo
class UsuarioViewSet(viewsets.ModelViewSet):
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer

class ProveedorViewSet(viewsets.ModelViewSet):
    queryset = Proveedor.objects.all()
    serializer_class = ProveedorSerializer

class CategoriaInsumoViewSet(viewsets.ModelViewSet):
    queryset = CategoriaInsumo.objects.all()
    serializer_class = CategoriaInsumoSerializer

class InsumoViewSet(viewsets.ModelViewSet):
    queryset = Insumo.objects.all()
    serializer_class = InsumoSerializer

class MovimientoInventarioViewSet(viewsets.ModelViewSet):
    queryset = MovimientoInventario.objects.all()
    serializer_class = MovimientoInventarioSerializer

class DietaViewSet(viewsets.ModelViewSet):
    queryset = Dieta.objects.all()
    serializer_class = DietaSerializer

class DietaInsumoViewSet(viewsets.ModelViewSet):
    queryset = DietaInsumo.objects.all()
    serializer_class = DietaInsumoSerializer

class LoteViewSet(viewsets.ModelViewSet):
    queryset = Lote.objects.all()
    serializer_class = LoteSerializer

class PesajeLoteViewSet(viewsets.ModelViewSet):
    queryset = PesajeLote.objects.all()
    serializer_class = PesajeLoteSerializer

class AlimentacionDiariaViewSet(viewsets.ModelViewSet):
    queryset = AlimentacionDiaria.objects.all()
    serializer_class = AlimentacionDiariaSerializer