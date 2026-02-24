from django.urls import path, include
from rest_framework import routers
from . import views

router = routers.DefaultRouter()

router.register(r'usuarios', views.UsuarioViewSet)
router.register(r'proveedores', views.ProveedorViewSet)
router.register(r'categorias-insumos', views.CategoriaInsumoViewSet)
router.register(r'insumos', views.InsumoViewSet)
router.register(r'movimientos-inventario', views.MovimientoInventarioViewSet)
router.register(r'dietas', views.DietaViewSet)
router.register(r'dieta-insumos', views.DietaInsumoViewSet)
router.register(r'lotes', views.LoteViewSet)
router.register(r'pesajes-lotes', views.PesajeLoteViewSet)
router.register(r'alimentacion-diaria', views.AlimentacionDiariaViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('health/', views.health_check, name='health_check'),
]