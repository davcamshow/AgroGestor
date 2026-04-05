from django.urls import path, include
from rest_framework import routers
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views

router = routers.DefaultRouter()

router.register(r'proveedores', views.ProveedorViewSet, basename='proveedor')
router.register(r'categorias-insumos', views.CategoriaInsumoViewSet, basename='categoria-insumo')
router.register(r'insumos', views.InsumoViewSet, basename='insumo')
router.register(r'movimientos-inventario', views.MovimientoInventarioViewSet, basename='movimiento-inventario')
router.register(r'dietas', views.DietaViewSet, basename='dieta')
router.register(r'dieta-insumos', views.DietaInsumoViewSet, basename='dieta-insumo')
router.register(r'lotes', views.LoteViewSet, basename='lote')
router.register(r'pesajes-lotes', views.PesajeLoteViewSet, basename='pesaje-lote')
router.register(r'alimentacion-diaria', views.AlimentacionDiariaViewSet, basename='alimentacion-diaria')

urlpatterns = [
    path('', include(router.urls)),
    path('health/', views.health_check, name='health_check'),
    # Auth endpoints
    path('auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', views.RegisterView.as_view(), name='register'),
    path('auth/me/', views.me_view, name='me'),
]