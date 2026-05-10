from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.contrib.auth.models import User as AuthUser


# ==================== Plan de Suscripción ====================
class PlanSuscripcion(models.Model):
    """Planes disponibles en el sistema SaaS"""
    PLANES = [
        ('basico', 'Básico'),
        ('productor', 'Productor'),
        ('empresarial', 'Empresarial'),
    ]

    codigo = models.CharField(max_length=20, unique=True, choices=PLANES)
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True, null=True)
    precio_mxn = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    precio_anual = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    limite_animales = models.IntegerField(default=50)
    limite_usuarios = models.IntegerField(default=1)
    incluye_modulo_animales = models.BooleanField(default=True)
    incluye_modulo_lotes = models.BooleanField(default=True)
    incluye_modulo_dietas = models.BooleanField(default=True)
    incluye_modulo_sanitaria = models.BooleanField(default=True)
    incluye_reportes_avanzados = models.BooleanField(default=False)
    incluye_api = models.BooleanField(default=False)
    soporte_prioritario = models.BooleanField(default=False)
    activo = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.nombre} (${self.precio_mxn}/mes)"

    class Meta:
        ordering = ['precio_mxn']


class SuscripcionUsuario(models.Model):
    """Suscripción activa de cada usuario"""
    usuario = models.OneToOneField(
        'Usuario',
        on_delete=models.CASCADE,
        related_name='suscripcion'
    )
    plan = models.ForeignKey(
        PlanSuscripcion,
        on_delete=models.PROTECT,
        related_name='suscriptores'
    )
    fecha_inicio = models.DateField(auto_now_add=True)
    fecha_renovacion = models.DateField(null=True, blank=True)
    activa = models.BooleanField(default=True)
    fecha_cancelacion = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"{self.usuario.email} - {self.plan.nombre}"


# ==================== Modelo de Usuarios Colaboradores ====================
class UsuarioInvitado(models.Model):
    """Usuarios adicionales que pueden acceder a una cuenta de proveedor"""
    ROLES = [
        ('admin', 'Administrador'),
        ('editor', 'Editor'),
        ('viewer', 'Solo lectura'),
    ]

    cuenta_principal = models.ForeignKey(
        'Usuario',
        on_delete=models.CASCADE,
        related_name='colaboradores'
    )
    usuario = models.ForeignKey(
        'Usuario',
        on_delete=models.CASCADE,
        related_name='cuentas_acceso'
    )
    rol = models.CharField(max_length=20, choices=ROLES, default='editor')
    activo = models.BooleanField(default=True)
    fecha_invitacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('cuenta_principal', 'usuario')

    def __str__(self):
        return f"{self.usuario.email} -> {self.cuenta_principal.email} ({self.rol})"


# 1. Modelo para Usarios
class Usuario(models.Model):
    auth_user = models.OneToOneField(
        AuthUser,
        on_delete=models.CASCADE,
        related_name='perfil',
        null=True,
        blank=True
    )

    MONEDAS = [
        ('MXN', 'Peso Mexicano'),
        ('USD', 'Dólar'),
    ]

    UNIDADES_PESO = [
        ('kg', 'Kilogramo'),
        ('lb', 'Libra'),
    ]

    nombre_completo = models.EmailField()
    email = models.EmailField(unique=True)
    password_hash = models.CharField(max_length=255)
    telefono = models.CharField(max_length=50, blank=True, null=True)
    rol_profesional = models.CharField(max_length=100,blank=True, null=True)
    cedula = models.CharField(max_length=100, blank=True, null=True)
    nombre_rancho = models.CharField(max_length=255, blank=True, null=True)
    direccion_rancho = models.TextField(blank=True, null=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)

    moneda = models.CharField(max_length=10, choices=MONEDAS, default='MXN')
    unidad_peso = models.CharField(max_length=10, choices=UNIDADES_PESO, default='kg')

    def __str__(self):
        return f"{self.nombre_completo} - {self.email}"

    @property
    def tiene_suscripcion_activa(self):
        return hasattr(self, 'suscripcion') and self.suscripcion.activa

    @property
    def plan_actual(self):
        if hasattr(self, 'suscripcion') and self.suscripcion.activa:
            return self.suscripcion.plan
        return PlanSuscripcion.objects.filter(codigo='basico').first()

    def puede_crear_animal(self):
        plan = self.plan_actual
        total_animales = self.animales.count()
        return total_animales < plan.limite_animales

    def puede_invitar_usuario(self):
        plan = self.plan_actual
        total_usuarios = self.colaboradores.filter(activo=True).count()
        return total_usuarios < plan.limite_usuarios
    

#Modelos para Proveedores e Inventarios
class Proveedor(models.Model):
    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='proveedores'
    )
    nombre_empresa = models.CharField(max_length=255)
    contacto = models.CharField(max_length=255, blank=True, null=True)
    telefono = models.CharField(max_length=50, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.nombre_empresa
    

class CategoriaInsumo(models.Model):
    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='categorias'
    )
    nombre = models.CharField(max_length=100)

    def __str__(self):
        return self.nombre
    

class Insumo(models.Model):
    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='insumos'
    )
    categoria = models.ForeignKey(
        CategoriaInsumo,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    proveedor_preferido = models.ForeignKey(
        Proveedor,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    nombre = models.CharField(max_length=255)
    cantidad_actual_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    stock_minimo_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    costo_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['usuario']),
        ]

    def __str__(self):
        return self.nombre
    

class MovimientoInventario(models.Model):
    insumo = models.ForeignKey(
        Insumo,
        on_delete=models.CASCADE,
        related_name='movimientos'
    )
    tipo_movimiento = models.CharField(max_length=20)
    cantidad_kg = models.DecimalField(max_digits=10, decimal_places=2)
    costo_unitario_kg = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    fecha_movimiento = models.DateTimeField(auto_now_add=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=['insumo']),
            models.Index(fields=['fecha_movimiento']),
        ]


# 3. Modelos para Nutricion (Formulas y Dietas)
class Dieta(models.Model):

    ESTADOS = [
        ('activa', 'Activa'),
        ('revision', 'En revisión'),
        ('archivada', 'Archivada'),
    ]

    TIPOS_FORMULACION = [
        ('porcentaje', 'Porcentaje'),
        ('tabla_kg', 'Tabla kg'),
    ]

    PERIODICIDADES = [
        ('diaria', 'Diaria'),
        ('semanal', 'Semanal'),
        ('quincenal', 'Quincenal'),
    ]

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='dietas'
    )
    nombre = models.CharField(max_length=255)
    objetivo = models.CharField(max_length=100)
    estado = models.CharField(max_length=50, choices=ESTADOS, default='activa')
    tipo_formulacion = models.CharField(max_length=20, choices=TIPOS_FORMULACION, default='porcentaje')
    cantidad_kg_cabeza = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True, help_text='Kg por cabeza por período')
    periodicidad = models.CharField(max_length=20, choices=PERIODICIDADES, default='diaria')
    costo_estimado_kg = models.DecimalField(max_digits=10, decimal_places=2)
    observaciones = models.TextField(blank=True, null=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    ultima_modificacion = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['usuario']),
        ]

    def __str__(self):
        return self.nombre
    

class DietaInsumo(models.Model):
    dieta = models.ForeignKey(Dieta, on_delete=models.CASCADE)
    insumo = models.ForeignKey(Insumo, on_delete=models.CASCADE)

    porcentaje_inclusion = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[
            MinValueValidator(0.01),
            MaxValueValidator(100)
        ],
        help_text='Porcentaje de inclusión (formato porcentaje)'
    )
    cantidad_kg = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        help_text='Cantidad en kg por cabeza (formato tabla_kg)'
    )

    class Meta:
        unique_together = ('dieta', 'insumo')


# 4. Modelos para Lotes y Producción
class Lote(models.Model):

    ESTADOS = [
        ('activo', 'Activo'),
        ('vendido', 'Vendido'),
        ('cuarentena', 'Cuarentena'),
    ]

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='lotes'
    )
    dieta = models.ForeignKey(
        Dieta,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    nombre = models.CharField(max_length=255)
    cantidad_cabezas = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    peso_promedio_actual_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    etapa_productiva = models.CharField(max_length=100)
    estado = models.CharField(max_length=50, choices=ESTADOS, default='activo')
    fecha_registro = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['usuario']),
        ]

    def __str__(self):
        return self.nombre
    

class PesajeLote(models.Model):
    lote = models.ForeignKey(
        Lote,
        on_delete=models.CASCADE,
        related_name='pesajes'
    )
    fecha_pesaje = models.DateField()
    peso_promedio_kg = models.DecimalField(max_digits=10, decimal_places=2)
    ganancia_diaria_promedio = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=['lote']),
        ]


class AlimentacionDiaria(models.Model):
    lote = models.ForeignKey(Lote, on_delete=models.CASCADE)
    dieta = models.ForeignKey(Dieta, on_delete=models.SET_NULL, null=True, blank=True)
    fecha = models.DateField()
    cantidad_servida_kg = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    costo_total_racion = models.DecimalField(max_digits=10, decimal_places=2,  validators=[MinValueValidator(0)])
    usuario_registro = models.ForeignKey(
        Usuario,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    class Meta:
        indexes = [
            models.Index(fields=['fecha']),
        ]


# 5. Modelos Bovion - Gestión de animales individuales
class Animal(models.Model):
    SEXOS = [('M', 'Macho'), ('H', 'Hembra')]
    ESTADOS = [
        ('activo', 'Activo'),
        ('vendido', 'Vendido'),
        ('muerto', 'Muerto'),
    ]

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='animales'
    )
    lote = models.ForeignKey(
        Lote,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='animales'
    )
    madre = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='crias_madre'
    )
    padre = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='crias_padre'
    )

    numero_arete = models.CharField(max_length=100)
    nombre = models.CharField(max_length=100, blank=True, null=True)
    raza = models.CharField(max_length=100, blank=True, null=True)
    sexo = models.CharField(max_length=1, choices=SEXOS)
    fecha_nacimiento = models.DateField(null=True, blank=True)
    color = models.CharField(max_length=50, blank=True, null=True)
    peso_nacimiento_kg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADOS, default='activo')
    
    # Campos adicionales para reproducción
    fecha_ultimo_parto = models.DateField(null=True, blank=True, help_text='Fecha del último parto')
    partos_count = models.IntegerField(default=0, help_text='Número de partos registrados')
    dias_lactancia = models.IntegerField(null=True, blank=True, help_text='Días actuales de lactation')
    ultimo_peso_kg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    fecha_ultimo_peso = models.DateField(null=True, blank=True)
    total_eventos_sanitarios = models.IntegerField(default=0)
    
    fecha_registro = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('usuario', 'numero_arete')
        indexes = [
            models.Index(fields=['usuario']),
            models.Index(fields=['lote']),
        ]

    def __str__(self):
        return f"{self.numero_arete} - {self.nombre or 'Sin nombre'}"


class CicloReproductivo(models.Model):
    TIPOS_SERVICIO = [
        ('natural', 'Monta Natural'),
        ('inseminacion_artificial', 'Inseminación Artificial'),
    ]
    ESTADOS = [
        ('en_servicio', 'En Servicio'),
        ('gestante', 'Gestante'),
        ('pario', 'Parió'),
        ('fallida', 'Fallida'),
        ('descartada', 'Descartada'),
    ]
    FORMATOS = [
        ('temporada', 'Temporada'),
        ('continuo', 'Continuo'),
    ]

    animal = models.ForeignKey(
        Animal,
        on_delete=models.CASCADE,
        related_name='ciclos_reproductivos'
    )
    tipo_servicio = models.CharField(max_length=30, choices=TIPOS_SERVICIO)
    formato = models.CharField(max_length=20, choices=FORMATOS, default='continuo', help_text='Cómo se maneja: por temporada o continuo')
    temporada = models.CharField(max_length=100, blank=True, null=True, help_text='Nombre de temporada ej: "Primavera 2026"')
    fecha_servicio = models.DateField()
    dias_gestacion = models.IntegerField(default=283)
    fecha_estimada_parto = models.DateField(null=True, blank=True)
    fecha_parto_real = models.DateField(null=True, blank=True)
    fecha_destete = models.DateField(null=True, blank=True, help_text='Fecha estimada de destete')
    estado = models.CharField(max_length=20, choices=ESTADOS, default='en_servicio')
    notas = models.TextField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=['animal']),
            models.Index(fields=['estado']),
        ]

    def save(self, *args, **kwargs):
        if self.fecha_servicio and not self.fecha_estimada_parto:
            from datetime import timedelta
            self.fecha_estimada_parto = self.fecha_servicio + timedelta(days=self.dias_gestacion)
        super().save(*args, **kwargs)


class RegistroNacimiento(models.Model):
    SEXOS = [('M', 'Macho'), ('H', 'Hembra')]

    ciclo = models.ForeignKey(
        CicloReproductivo,
        on_delete=models.CASCADE,
        related_name='nacimientos'
    )
    madre = models.ForeignKey(
        Animal,
        on_delete=models.CASCADE,
        related_name='nacimientos'
    )
    numero_arete = models.CharField(max_length=100, blank=True, null=True, help_text='Número de arete de la cria')
    nombre = models.CharField(max_length=100, blank=True, null=True)
    sexo = models.CharField(max_length=1, choices=SEXOS)
    peso_nacimiento_kg = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    fecha_nacimiento = models.DateField(null=True, blank=True)
    fecha_destete = models.DateField(null=True, blank=True, help_text='Fecha de destete')
    anomalies = models.TextField(blank=True, null=True, help_text='Anomalías o complicaciones al nacimiento')
    observaciones = models.TextField(blank=True, null=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['madre']),
            models.Index(fields=['fecha_nacimiento']),
        ]

    def __str__(self):
        return f"{self.madre.numero_arete} - {self.sexo} ({self.fecha_nacimiento})"

    def save(self, *args, **kwargs):
        from datetime import timedelta
        if self.fecha_nacimiento:
            self.madre.fecha_ultimo_parto = self.fecha_nacimiento
            self.madre.partos_count = (self.madre.partos_count or 0) + 1
            self.madre.dias_lactancia = 0
            self.madre.save(update_fields=['fecha_ultimo_parto', 'partos_count', 'dias_lactancia'])
            if not self.fecha_destete:
                self.fecha_destete = self.fecha_nacimiento + timedelta(days=70)
        super().save(*args, **kwargs)

    class Meta:
        indexes = [
            models.Index(fields=['madre']),
            models.Index(fields=['fecha_nacimiento']),
        ]

    def __str__(self):
        return f"{self.madre.numero_arete} - {self.sexo} ({self.fecha_nacimiento})"


class RegistroPeso(models.Model):
    animal = models.ForeignKey(
        Animal,
        on_delete=models.CASCADE,
        related_name='registros_peso'
    )
    fecha_pesaje = models.DateField()
    peso_kg = models.DecimalField(max_digits=8, decimal_places=2)
    condicion_corporal = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True,
        blank=True
    )
    ganancia_diaria_kg = models.DecimalField(max_digits=6, decimal_places=3, null=True, blank=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=['animal']),
            models.Index(fields=['fecha_pesaje']),
        ]
        ordering = ['-fecha_pesaje']

    def save(self, *args, **kwargs):
        Animal = self.animal.__class__
        pesaje_anterior = RegistroPeso.objects.filter(
            animal=self.animal,
            fecha_pesaje__lt=self.fecha_pesaje
        ).order_by('-fecha_pesaje').first()
        if pesaje_anterior:
            dias = (self.fecha_pesaje - pesaje_anterior.fecha_pesaje).days
            if dias > 0:
                self.ganancia_diaria_kg = (self.peso_kg - pesaje_anterior.peso_kg) / dias
        super().save(*args, **kwargs)
        Animal.objects.filter(pk=self.animal.pk).update(
            ultimo_peso_kg=self.peso_kg,
            fecha_ultimo_peso=self.fecha_pesaje
        )


class EventoSanitario(models.Model):
    TIPOS = [
        ('vacunacion', 'Vacunación'),
        ('desparasitacion', 'Desparasitación'),
        ('tratamiento', 'Tratamiento'),
        ('cirugia', 'Cirugía'),
    ]

    animal = models.ForeignKey(
        Animal,
        on_delete=models.CASCADE,
        related_name='eventos_sanitarios'
    )
    tipo = models.CharField(max_length=20, choices=TIPOS)
    producto = models.CharField(max_length=255)
    dosis = models.CharField(max_length=100, blank=True, null=True)
    fecha_aplicacion = models.DateField()
    proxima_aplicacion = models.DateField(null=True, blank=True)
    veterinario = models.CharField(max_length=255, blank=True, null=True)
    costo = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        indexes = [
            models.Index(fields=['animal']),
            models.Index(fields=['fecha_aplicacion']),
            models.Index(fields=['proxima_aplicacion']),
        ]
        ordering = ['-fecha_aplicacion']


# 6. Modelo de Auditoría de Autenticación
class AuditoriaLogin(models.Model):
    TIPOS_RESULTADO = [
        ('exitoso', 'Exitoso'),
        ('fallido', 'Fallido'),
    ]

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='auditorias_login'
    )
    email = models.EmailField()
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=500, blank=True, null=True)
    resultado = models.CharField(max_length=20, choices=TIPOS_RESULTADO)
    mensaje = models.TextField(blank=True, null=True)
    fecha_intento = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['usuario']),
            models.Index(fields=['fecha_intento']),
            models.Index(fields=['resultado']),
        ]
        ordering = ['-fecha_intento']

    def __str__(self):
        return f"{self.email} - {self.resultado} - {self.fecha_intento}"
