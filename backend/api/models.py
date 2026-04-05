from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.contrib.auth.models import User as AuthUser

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

    nombre_completo = models.CharField(max_length=255)
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

    usuario = models.ForeignKey(
        Usuario,
        on_delete=models.CASCADE,
        related_name='dietas'
    )
    nombre = models.CharField(max_length=255)
    objetivo = models.CharField(max_length=100)
    estado = models.CharField(max_length=50, choices=ESTADOS, default='activa')
    costo_estimado_kg = models.DecimalField(max_digits=10, decimal_places=2)
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
        validators=[
            MinValueValidator(0.01),
            MaxValueValidator(100)
        ]
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

    animal = models.ForeignKey(
        Animal,
        on_delete=models.CASCADE,
        related_name='ciclos_reproductivos'
    )
    tipo_servicio = models.CharField(max_length=30, choices=TIPOS_SERVICIO)
    fecha_servicio = models.DateField()
    dias_gestacion = models.IntegerField(default=283)
    fecha_estimada_parto = models.DateField(null=True, blank=True)
    fecha_parto_real = models.DateField(null=True, blank=True)
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
        # Calcular GMD respecto al pesaje anterior
        pesaje_anterior = RegistroPeso.objects.filter(
            animal=self.animal,
            fecha_pesaje__lt=self.fecha_pesaje
        ).order_by('-fecha_pesaje').first()
        if pesaje_anterior:
            dias = (self.fecha_pesaje - pesaje_anterior.fecha_pesaje).days
            if dias > 0:
                self.ganancia_diaria_kg = (self.peso_kg - pesaje_anterior.peso_kg) / dias
        super().save(*args, **kwargs)


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
