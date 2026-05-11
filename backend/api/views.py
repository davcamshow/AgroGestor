from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import viewsets, generics, serializers
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth.models import User as AuthUser
from django.contrib.auth import authenticate
from django.db.models import Sum
import logging

logger = logging.getLogger(__name__)

#Importaciones para los viewsets en /api/
from .serializer import UsuarioSerializer, FarmSerializer, ProveedorSerializer, CategoriaInsumoSerializer, InsumoSerializer, MovimientoInventarioSerializer, DietaSerializer, DietaInsumoSerializer, LoteSerializer, PesajeLoteSerializer, AlimentacionDiariaSerializer, RegisterSerializer, UserProfileSerializer, AnimalSerializer, CicloReproductivoSerializer, RegistroPesoSerializer, EventoSanitarioSerializer, AuditoriaLoginSerializer, RegistroNacimientoSerializer, PlanSuscripcionSerializer, UsuarioInvitadoSerializer
from .models import Usuario, Farm, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario, Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal, CicloReproductivo, RegistroPeso, EventoSanitario, AuditoriaLogin, RegistroNacimiento, PlanSuscripcion, SuscripcionUsuario, UsuarioInvitado
from .permissions import IsVeterinario, IsNutricionista, IsOperarioCampo, IsGerenteProduccion, IsContador, IsAdministrador, IsGerenteOrContador, IsGerenteReadOnlyOrNutricionista, IsContadorReadOnlyOrGerenteOrOperario, IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinario, IsOperarioReadOnlyOrGerenteReadOnlyOrContador, IsGerenteOrOperarioOrVeterinarioOrNutricionista, IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinarioOrNutricionista, AnyoneExceptContador, AnyoneReadOnlyExceptContador, IsGerenteOrContadorOrOperario, IsGerenteOrVeterinarioOrOperario, CanAccessFarm, IsFarmOwner

@api_view(['GET'])
@permission_classes([AllowAny])
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
                raise
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR', '')
        return ip


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
    permission_classes = [IsAuthenticated, IsGerenteOrContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return Proveedor.objects.all()
        return Proveedor.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class FarmViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestionar Farms (granjas).
    - GET /farms/ : Lista todas las farms a las que el usuario tiene acceso
    - POST /farms/ : Crear una nueva farm (solo propietario)
    - GET /farms/{id}/ : Obtener detalle de una farm
    - PUT/PATCH /farms/{id}/ : Actualizar farm (solo propietario)
    - DELETE /farms/{id}/ : Eliminar farm (solo propietario)
    - POST /farms/{id}/add_user/ : Agregar usuario a la farm (solo propietario)
    - POST /farms/{id}/remove_user/ : Remover usuario de la farm (solo propietario)
    """
    serializer_class = FarmSerializer
    permission_classes = [IsAuthenticated, CanAccessFarm]

    def get_queryset(self):
        """
        Retorna solo las farms a las que el usuario tiene acceso:
        - Farms que es propietario
        - Farms donde tiene acceso (está en la relación ManyToMany)
        """
        user_profile = self.request.user.perfil
        
        if self.request.user.groups.filter(name='Administrador').exists():
            return Farm.objects.all()
        
        # Farms donde el usuario es propietario O tiene acceso
        from django.db.models import Q
        return Farm.objects.filter(
            Q(usuario_propietario=user_profile) | Q(usuarios=user_profile)
        ).distinct()

    def perform_create(self, serializer):
        """Al crear una farm, el usuario actual se establece como propietario"""
        farm = serializer.save(usuario_propietario=self.request.user.perfil)
        # Agregar el propietario a la lista de usuarios con acceso
        farm.usuarios.add(self.request.user.perfil)

    def get_permissions(self):
        """
        Permisos personalizados por acción:
        - create: Solo usuarios autenticados
        - destroy, update, partial_update: Solo propietario (IsFarmOwner)
        - list, retrieve: CanAccessFarm
        """
        if self.action in ['destroy', 'update', 'partial_update']:
            self.permission_classes = [IsAuthenticated, IsFarmOwner]
        return super().get_permissions()

    def get_object(self):
        """
        Obtiene el objeto farm y valida permisos.
        """
        obj = super().get_object()
        # Validar permisos a nivel de objeto
        self.check_object_permissions(self.request, obj)
        return obj


class FarmFilteredViewSetMixin:
    """
    Mixin que filtra querysets por farm si se proporciona farm_id en query params.
    También valida que el usuario tenga acceso a la farm.
    """
    def filter_by_farm(self, queryset):
        """Filtra el queryset por farm si se proporciona farm_id"""
        farm_id = self.request.query_params.get('farm_id')
        if farm_id:
            try:
                farm = Farm.objects.get(id=farm_id)
                # Verificar que el usuario tenga acceso a la farm
                if not (farm.usuario_propietario == self.request.user.perfil or 
                        farm.usuarios.filter(id=self.request.user.perfil.id).exists()):
                    return queryset.none()
                return queryset.filter(farm=farm)
            except Farm.DoesNotExist:
                return queryset.none()
        return queryset


class CategoriaInsumoViewSet(FarmFilteredViewSetMixin, viewsets.ModelViewSet):
    serializer_class = CategoriaInsumoSerializer
    permission_classes = [IsAuthenticated, IsGerenteOrContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return CategoriaInsumo.objects.all()
        return CategoriaInsumo.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class InsumoViewSet(viewsets.ModelViewSet):
    serializer_class = InsumoSerializer
    permission_classes = [IsAuthenticated, IsGerenteOrContadorOrOperario]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return Insumo.objects.all()
        return Insumo.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class MovimientoInventarioViewSet(viewsets.ModelViewSet):
    serializer_class = MovimientoInventarioSerializer
    permission_classes = [IsAuthenticated, IsContadorReadOnlyOrGerenteOrOperario]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return MovimientoInventario.objects.all()
        return MovimientoInventario.objects.filter(insumo__usuario=self.request.user.perfil)


class DietaViewSet(viewsets.ModelViewSet):
    serializer_class = DietaSerializer
    permission_classes = [IsAuthenticated, IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinario]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return Dieta.objects.all()
        return Dieta.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class DietaInsumoViewSet(viewsets.ModelViewSet):
    serializer_class = DietaInsumoSerializer
    permission_classes = [IsAuthenticated, IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinario]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return DietaInsumo.objects.all()
        return DietaInsumo.objects.filter(dieta__usuario=self.request.user.perfil)


class LoteViewSet(viewsets.ModelViewSet):
    serializer_class = LoteSerializer
    permission_classes = [IsAuthenticated, IsOperarioReadOnlyOrGerenteReadOnlyOrContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return Lote.objects.all()
        return Lote.objects.filter(usuario=self.request.user.perfil)

    def perform_create(self, serializer):
        serializer.save(usuario=self.request.user.perfil)


class PesajeLoteViewSet(viewsets.ModelViewSet):
    serializer_class = PesajeLoteSerializer
    permission_classes = [IsAuthenticated, IsGerenteOrOperarioOrVeterinarioOrNutricionista]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return PesajeLote.objects.all()
        return PesajeLote.objects.filter(lote__usuario=self.request.user.perfil)


class AlimentacionDiariaViewSet(viewsets.ModelViewSet):
    serializer_class = AlimentacionDiariaSerializer
    permission_classes = [IsAuthenticated, IsGerenteReadOnlyOrOperarioReadOnlyOrVeterinarioOrNutricionista]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            return AlimentacionDiaria.objects.all()
        return AlimentacionDiaria.objects.filter(lote__usuario=self.request.user.perfil)


# ViewSets Bovion
class AnimalViewSet(viewsets.ModelViewSet):
    serializer_class = AnimalSerializer
    permission_classes = [IsAuthenticated, AnyoneExceptContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            qs = Animal.objects.all()
        else:
            try:
                qs = Animal.objects.filter(usuario=self.request.user.perfil)
            except Usuario.DoesNotExist:
                return Animal.objects.none()
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
        usuario = self.request.user.perfil
        if not usuario.puede_crear_animal():
            plan = usuario.plan_actual
            raise serializers.ValidationError({
                'limite': f'Has alcanzado el límite de {plan.limite_animales} animales de tu plan {plan.nombre}. Upgrade tu plan para agregar más.'
            })
        serializer.save(usuario=usuario)


class CicloReproductivoViewSet(viewsets.ModelViewSet):
    serializer_class = CicloReproductivoSerializer
    permission_classes = [IsAuthenticated, AnyoneExceptContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            qs = CicloReproductivo.objects.all()
        else:
            try:
                qs = CicloReproductivo.objects.filter(animal__usuario=self.request.user.perfil)
            except Usuario.DoesNotExist:
                return CicloReproductivo.objects.none()
        estado = self.request.query_params.get('estado')
        if estado:
            qs = qs.filter(estado=estado)
        return qs.select_related('animal')


class RegistroPesoViewSet(viewsets.ModelViewSet):
    serializer_class = RegistroPesoSerializer
    permission_classes = [IsAuthenticated, AnyoneExceptContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            qs = RegistroPeso.objects.all()
        else:
            qs = RegistroPeso.objects.filter(animal__usuario=self.request.user.perfil)
        animal_id = self.request.query_params.get('animal')
        if animal_id:
            qs = qs.filter(animal_id=animal_id)
        return qs


class EventoSanitarioViewSet(viewsets.ModelViewSet):
    serializer_class = EventoSanitarioSerializer
    permission_classes = [IsAuthenticated, AnyoneExceptContador]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            qs = EventoSanitario.objects.all()
        else:
            try:
                qs = EventoSanitario.objects.filter(animal__usuario=self.request.user.perfil)
            except Usuario.DoesNotExist:
                return EventoSanitario.objects.none()
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
        if self.request.user.groups.filter(name='Administrador').exists():
            qs = AuditoriaLogin.objects.all()
        else:
            try:
                qs = AuditoriaLogin.objects.filter(usuario=self.request.user.perfil)
            except Usuario.DoesNotExist:
                return AuditoriaLogin.objects.none()
        resultado = self.request.query_params.get('resultado')
        if resultado:
            qs = qs.filter(resultado=resultado)
        return qs


class RegistroNacimientoViewSet(viewsets.ModelViewSet):
    serializer_class = RegistroNacimientoSerializer
    permission_classes = [IsAuthenticated, IsGerenteOrVeterinarioOrOperario]

    def get_queryset(self):
        if self.request.user.groups.filter(name='Administrador').exists():
            qs = RegistroNacimiento.objects.all()
        else:
            try:
                qs = RegistroNacimiento.objects.filter(madre__usuario=self.request.user.perfil)
            except Usuario.DoesNotExist:
                return RegistroNacimiento.objects.none()
        ciclo_id = self.request.query_params.get('ciclo')
        if ciclo_id:
            qs = qs.filter(ciclo_id=ciclo_id)
        return qs.select_related('ciclo', 'madre')

    def perform_create(self, serializer):
        serializer.save()


# ==================== KPIs Reproductivos ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated, AnyoneExceptContador])
def kpis_reproductivos(request):
    from datetime import timedelta
    from django.db.models import Count, Avg, F
    from django.utils import timezone
    
    usuario = request.user.perfil
    
    # Período: últimos 365 días
    fecha_inicio = timezone.now() - timedelta(days=365)
    
    # Total animales hembras
    total_hembras = Animal.objects.filter(usuario=usuario, sexo='M', estado='activo').count()
    
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


# ==================== Árbol Genealógico ====================
@api_view(['GET'])
@permission_classes([IsAuthenticated, AnyoneExceptContador])
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
@permission_classes([IsAuthenticated, AnyoneReadOnlyExceptContador])
def reporte_consumo(request):
    from datetime import timedelta
    from django.db.models import Sum, Avg
    from django.utils import timezone

    usuario = request.user.perfil
    dias = int(request.query_params.get('dias', 30))
    lote_id = request.query_params.get('lote')

    fecha_inicio = timezone.now() - timedelta(days=dias)

    query = AlimentacionDiaria.objects.filter(
        lote__usuario=usuario,
        fecha__gte=fecha_inicio
    )

    if lote_id:
        query = query.filter(lote_id=lote_id)

    total_kg = query.aggregate(Sum('cantidad_servida_kg'))['cantidad_servida_kg__sum'] or 0
    costo_total = query.aggregate(Sum('costo_total_racion'))['costo_total_racion__sum'] or 0

    animales_alimentados = query.values('lote').distinct().count()

    return Response({
        'periodo_dias': dias,
        'total_kg': float(total_kg),
        'costo_total': float(costo_total),
        'animales_atendidos': animales_alimentados,
        'kg_por_animal': float(total_kg / animales_alimentados) if animales_alimentados > 0 else 0,
        'costo_por_animal': float(costo_total / animales_alimentados) if animales_alimentados > 0 else 0,
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
    from django.utils import timezone

    if hasattr(usuario, 'suscripcion'):
        suscripcion = usuario.suscripcion
        suscripcion.plan = plan
        suscripcion.activa = True
        suscripcion.fecha_cancelacion = None
        if plan.precio_mxn > 0:
            suscripcion.fecha_renovacion = timezone.now().date() + timedelta(days=30)
        suscripcion.save()
    else:
        fecha_renovacion = None
        if plan.precio_mxn > 0:
            fecha_renovacion = timezone.now().date() + timedelta(days=30)

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


@api_view(['GET', 'POST', 'DELETE', 'PUT', 'PATCH'])
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

        return Response({'mensaje': f'Usuario {email_invitado} añadido como colaborador'})

    elif request.method in ['PUT', 'PATCH']:
        if not colaborador_id:
            return Response({'error': 'Se requiere ID del colaborador'}, status=400)

        rol = request.data.get('rol')
        if not rol:
            return Response({'error': 'Se requiere el nuevo rol del colaborador'}, status=400)

        valid_roles = dict(UsuarioInvitado.ROLES).keys()
        if rol not in valid_roles:
            return Response({'error': f'Rol inválido. Los valores válidos son: {", ".join(valid_roles)}'}, status=400)

        try:
            colaborador = UsuarioInvitado.objects.get(id=colaborador_id, cuenta_principal=usuario)
            colaborador.rol = rol
            colaborador.save()
            serializer = UsuarioInvitadoSerializer(colaborador)
            return Response(serializer.data)
        except UsuarioInvitado.DoesNotExist:
            return Response({'error': 'Colaborador no encontrado'}, status=404)

    elif request.method == 'DELETE':
        if not colaborador_id:
            return Response({'error': 'Se requiere ID del colaborador'}, status=400)

        try:
            colaborador = UsuarioInvitado.objects.get(id=colaborador_id, cuenta_principal=usuario)
            colaborador.activo = False
            colaborador.save()
            return Response({'mensaje': 'Colaborador eliminado'})
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