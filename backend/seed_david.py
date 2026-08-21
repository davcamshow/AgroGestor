import os
import random
from datetime import timedelta, date, datetime
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

import django

django.setup()

from django.db import transaction
from django.utils import timezone
from django.contrib.auth.models import User as AuthUser
from api.models import (
    Usuario, Proveedor, CategoriaInsumo, Insumo, MovimientoInventario,
    Dieta, DietaInsumo, Lote, PesajeLote, AlimentacionDiaria, Animal,
    CicloReproductivo, RegistroNacimiento, RegistroPeso, EventoSanitario,
    AuditoriaLogin, AuditoriaAnimal, PlanSuscripcion, SuscripcionUsuario,
    UsuarioInvitado,
)

EMAIL = 'David@agrogestor.com'
PASSWORD = 'AgroTest2026!'
NOMBRE = 'David Camacho Reyes'
TODAY = date.today()

rnd = random.Random(42)

razas = ['Angus', 'Brangus', 'Brahman', 'Hereford', 'Holstein', 'Charolais',
         'Limousin', 'Simmental', 'Pardo Suizo', 'Criollo']
colores = ['negro', 'blanco', 'café', 'berrendo negro', 'berrendo colorado',
           'gris', 'rojo', 'pinto']
etapas = ['Cría', 'Destete', 'Recría', 'Engorda', 'Reproducción', 'Vaca lactante', 'Toro semental']
nombres_machos = ['Rey', 'Champion', 'Titan', 'Rayo', 'Bronco', 'Apolo', 'Zeus',
                  'Valiente', 'Centurion', 'Diesel', 'Matador', 'Bandido', 'Feroz', 'Trueno']
nombres_hembras = ['Luna', 'Estrella', 'Cielo', 'Blanca', 'Rosita', 'Perla',
                   'Rubia', 'Cacahuate', 'Pinta', 'Golondrina', 'Mariposa', 'Caramelo', 'Paloma']

vacunas = ['Bayovac', 'Bovela', 'Pentogen', 'Hemogen', 'CattleMaster', 'Tasvax']
desparasitantes = ['Ivermectina 1%', 'Fenbendazol 10%', 'Levamisol 10%', 'Moxidectina', 'Closantel + Ivermectina']
antibioticos = ['Oxitetraciclina LA', 'Penicilina + Estreptomicina', 'Enrofloxacina', 'Florfenicol', 'Tilmicosina']
vitaminas = ['ADE Complex', 'Phosphorus ADE', 'Vitamin B Complex', 'Selenio + Vit E']
suplementos = ['Sal mineral 8%', 'Sal mineral 12%', 'Urea 46%', 'Melaza', 'Bicarbonato de sodio', 'Levadura viva']
concentrados = ['Concentrado engorda 14%', 'Concentrado engorda 16%', 'Concentrado lactancia 20%', 'Alimento iniciador']
forrajes = ['Heno de alfalfa', 'Ensilaje de maíz', 'Pasto estrella', 'Pasto brizanta', 'Rastrojo de maíz', 'Sorgo forrajero']

proveedores_datos = [
    ('Agroinsumos del Bajío', 'Ing. Roberto Aguilar', '462-123-4567', 'ventas@agroinsumosbajio.com'),
    ('Ganadería Integral S.A.', 'Lic. María Fernández', '333-444-5566', 'contacto@ganaderiaintegral.com'),
    ('Nutribovinos México', 'Dr. Héctor Domínguez', '555-221-3344', 'pedidos@nutribovinos.mx'),
    ('Alimentos Balanceados del Norte', 'Sr. Arturo Peña', '614-889-0011', 'info@alimentosnorte.com'),
    ('Veterinaria Rancho Grande', 'MVZ. Laura Soto', '771-345-6789', 'laurasoto@ranchogrande.mx'),
    ('Proveedora Agropecuaria La Salle', 'CP. Jorge Villalba', '844-567-2233', 'ventas@lasalleagro.com'),
    ('Insumos Ganaderos del Pacífico', 'Ing. Carmen Ruiz', '667-123-9900', 'carmen@insumosgpo.com'),
    ('Distribuidora El Toro Bravo', 'Sr. Miguel Ángel Luna', '818-234-5566', 'mtoro@torobravo.com'),
    ('Sanidad Animal del Centro', 'MVZ. Patricia Godoy', '442-778-9911', 'paty@sanidadanimalcentro.com'),
    ('Forrajes y Granos del Valle', 'Sr. Ernesto Lira', '722-345-1188', 'forrajesvalle@gmail.com'),
    ('Agroservicios Campeche', 'Ing. Gerardo Poot', '981-234-5566', 'ventas@agroservicioscampeche.com'),
    ('Genética Bovina Premium', 'Dr. Salvador Ibarra', '449-556-7788', 'genetica@bovinapremium.com'),
    ('Suplementos Minerales del Sureste', 'Quím. Nora Campos', '993-456-1234', 'minerales@surmin.com'),
    ('Ganaderos Unidos Proveedora', 'Sr. Julián Osorio', '477-889-3344', 'ventas@ganaderosunidos.com'),
    ('Bioproductos Veterinarios', 'MVZ. Eduardo Neri', '333-667-8899', 'ebiovet@gmail.com'),
]

categorias = ['Concentrado', 'Forraje', 'Minerales', 'Suplementos', 'Vacunas',
              'Desparasitantes', 'Antibióticos', 'Vitaminas', 'Desinfectantes', 'Herramientas']

insumos_datos = [
    ('Alimento iniciador', 'Concentrado', 8.50),
    ('Concentrado engorda 14%', 'Concentrado', 7.80),
    ('Concentrado engorda 16%', 'Concentrado', 8.10),
    ('Concentrado lactancia 20%', 'Concentrado', 9.20),
    ('Heno de alfalfa', 'Forraje', 4.50),
    ('Ensilaje de maíz', 'Forraje', 3.20),
    ('Pasto estrella', 'Forraje', 2.80),
    ('Pasto brizanta', 'Forraje', 2.60),
    ('Rastrojo de maíz', 'Forraje', 3.00),
    ('Sorgo forrajero', 'Forraje', 3.40),
    ('Sal mineral 8%', 'Minerales', 6.50),
    ('Sal mineral 12%', 'Minerales', 8.00),
    ('Fosfato bicalcico', 'Minerales', 11.00),
    ('Urea 46%', 'Suplementos', 7.20),
    ('Melaza', 'Suplementos', 5.80),
    ('Bicarbonato de sodio', 'Suplementos', 12.00),
    ('Levadura viva', 'Suplementos', 90.00),
    ('Bayovac', 'Vacunas', 45.00),
    ('Pentogen', 'Vacunas', 38.00),
    ('CattleMaster', 'Vacunas', 52.00),
    ('Ivermectina 1%', 'Desparasitantes', 18.00),
    ('Fenbendazol 10%', 'Desparasitantes', 22.00),
    ('Levamisol 10%', 'Desparasitantes', 15.00),
    ('Oxitetraciclina LA', 'Antibióticos', 28.00),
    ('Penicilina + Estreptomicina', 'Antibióticos', 24.00),
    ('Enrofloxacina 10%', 'Antibióticos', 35.00),
    ('ADE Complex', 'Vitaminas', 16.00),
    ('Selenio + Vit E', 'Vitaminas', 14.00),
    ('Cloro desinfectante', 'Desinfectantes', 6.00),
    ('Yodo povidona', 'Desinfectantes', 9.00),
]


def clear_previous():
    print('Limpiando datos previos del usuario David...')
    emails = [EMAIL]
    perfiles = list(Usuario.objects.filter(email__in=emails))
    for p in perfiles:
        if p.auth_user_id:
            AuthUser.objects.filter(pk=p.auth_user_id).delete()
    for p in perfiles:
        p.delete()
    plan = PlanSuscripcion.objects.filter(codigo='empresarial').first()
    if plan:
        plan.delete()
    print('  Limpieza completada.')


def crear_planes():
    planes = {}
    datos = [
        dict(codigo='basico', nombre='Básico', descripcion='Para ganaderías pequeñas.',
             precio_mxn=299, precio_anual=2990, limite_animales=50, limite_usuarios=1,
             incluye_reportes_avanzados=False, incluye_api=False, soporte_prioritario=False),
        dict(codigo='productor', nombre='Productor', descripcion='Para productores en crecimiento.',
             precio_mxn=499, precio_anual=4990, limite_animales=150, limite_usuarios=3,
             incluye_reportes_avanzados=True, incluye_api=False, soporte_prioritario=False),
        dict(codigo='empresarial', nombre='Empresarial', descripcion='Para operaciones grandes.',
             precio_mxn=899, precio_anual=8990, limite_animales=1000, limite_usuarios=10,
             incluye_reportes_avanzados=True, incluye_api=True, soporte_prioritario=True),
    ]
    for d in datos:
        p = PlanSuscripcion.objects.filter(codigo=d['codigo']).first()
        if not p:
            p = PlanSuscripcion(**d)
            p.save()
        planes[d['codigo']] = p
    return planes


def crear_usuario(planes):
    auth_user = AuthUser.objects.filter(username=EMAIL).first()
    if not auth_user:
        auth_user = AuthUser.objects.create_user(
            username=EMAIL, email=EMAIL, password=PASSWORD,
            first_name='David', last_name='Camacho Reyes')
    else:
        auth_user.set_password(PASSWORD)
        auth_user.save()

    usuario = Usuario.objects.filter(email=EMAIL).first()
    if not usuario:
        usuario = Usuario.objects.create(
            auth_user=auth_user,
            nombre_completo=NOMBRE,
            email=EMAIL,
            password_hash='',
            telefono='462-144-7890',
            rol_profesional='Médico Veterinario Zootecnista',
            cedula='Ced. Prof. 12345678',
            nombre_rancho='Rancho San David',
            direccion_rancho='Km 12 carretera León – San Francisco del Rincón, Municipio de León, Guanajuato, México.',
            moneda='MXN',
            unidad_peso='kg',
        )
    else:
        usuario.nombre_completo = NOMBRE
        usuario.telefono = '462-144-7890'
        usuario.rol_profesional = 'Médico Veterinario Zootecnista'
        usuario.cedula = 'Ced. Prof. 12345678'
        usuario.nombre_rancho = 'Rancho San David'
        usuario.direccion_rancho = 'Km 12 carretera León – San Francisco del Rincón, Municipio de León, Guanajuato, México.'
        usuario.save()

    SuscripcionUsuario.objects.filter(usuario=usuario).delete()
    SuscripcionUsuario.objects.create(
        usuario=usuario,
        plan=planes['empresarial'],
        fecha_renovacion=TODAY + timedelta(days=365),
        activa=True,
    )
    return usuario


def crear_proveedores(usuario):
    objs = []
    for nombre, contacto, tel, email in proveedores_datos:
        objs.append(Proveedor(
            usuario=usuario, nombre_empresa=nombre, contacto=contacto,
            telefono=tel, email=email,
            notas='Proveedor de confianza del Rancho San David.' if rnd.random() < 0.5 else '',
        ))
    return Proveedor.objects.bulk_create(objs)


def crear_categorias(usuario):
    objs = [CategoriaInsumo(usuario=usuario, nombre=n) for n in categorias]
    return CategoriaInsumo.objects.bulk_create(objs)


def crear_insumos(usuario, categorias_map, proveedores):
    objs = []
    for nombre, cat, costo in insumos_datos:
        objs.append(Insumo(
            usuario=usuario,
            categoria=categorias_map.get(cat),
            proveedor_preferido=rnd.choice(proveedores),
            nombre=nombre,
            cantidad_actual_kg=Decimal(rnd.uniform(80, 900)).quantize(Decimal('0.01')),
            stock_minimo_kg=Decimal(rnd.uniform(20, 100)).quantize(Decimal('0.01')),
            costo_kg=Decimal(str(costo)),
        ))
    insumos = Insumo.objects.bulk_create(objs)
    return insumos


def crear_movimientos(usuario, insumos):
    objs = []
    for ins in insumos:
        n = rnd.randint(14, 24)
        fechas = sorted(TODAY - timedelta(days=rnd.randint(1, 365)) for _ in range(n))
        for f in fechas:
            tipo = 'entrada' if rnd.random() < 0.6 else 'salida'
            cant = Decimal(rnd.uniform(10, 200)).quantize(Decimal('0.01'))
            objs.append(MovimientoInventario(
                insumo=ins, tipo_movimiento=tipo, cantidad_kg=cant,
                costo_unitario_kg=ins.costo_kg,
                notas='Compra a proveedor' if tipo == 'entrada' else 'Consumo en alimentación',
                fecha_movimiento=timezone.make_aware(datetime.combine(f, datetime.min.time())),
            ))
    return MovimientoInventario.objects.bulk_create(objs)


def crear_dietas(usuario, insumos):
    dietas = []
    nombres = [
        ('Dieta engorda final', 'Engorda', 5.20, 'tabla_kg', 'diaria'),
        ('Dieta engorda arranque', 'Engorda', 4.60, 'tabla_kg', 'diaria'),
        ('Dieta vacas lactantes', 'Lactancia', 6.80, 'porcentaje', 'diaria'),
        ('Dieta recría', 'Crecimiento', 3.90, 'porcentaje', 'diaria'),
        ('Dieta destete', 'Destete', 2.40, 'porcentaje', 'diaria'),
        ('Dieta toros reproductores', 'Reproducción', 7.10, 'porcentaje', 'diaria'),
        ('Dieta vaquillas desarrollo', 'Desarrollo', 3.50, 'porcentaje', 'diaria'),
        ('Dieta mantenimiento vacas secas', 'Mantenimiento', 2.90, 'porcentaje', 'diaria'),
        ('Dieta semiestabulado', 'Mixto', 4.10, 'tabla_kg', 'semanal'),
        ('Dieta pradera suplementada', 'Pastoreo', 1.80, 'porcentaje', 'diaria'),
    ]
    for nombre, obj, costo, tipo, per in nombres:
        d = Dieta(
            usuario=usuario, nombre=nombre, objetivo=obj,
            estado=rnd.choices(['activa', 'revision', 'archivada'], [0.7, 0.2, 0.1])[0],
            tipo_formulacion=tipo,
            cantidad_kg_cabeza=Decimal(str(rnd.uniform(1.5, 8))).quantize(Decimal('0.1')),
            periodicidad=per,
            costo_estimado_kg=Decimal(str(costo)),
            observaciones='Fórmula ajustada por nutricionista del rancho.' if rnd.random() < 0.4 else '',
        )
        d.save()
        dietas.append(d)

    d_objs = []
    for d in dietas:
        n = rnd.randint(4, 7)
        seleccion = rnd.sample(insumos, n)
        pesos = [rnd.uniform(5, 40) for _ in seleccion]
        total = sum(pesos)
        for ins, p in zip(seleccion, pesos):
            di = DietaInsumo(
                dieta=d, insumo=ins,
                porcentaje_inclusion=Decimal(str(round(p / total * 100, 2))),
            )
            if d.tipo_formulacion == 'tabla_kg':
                di.cantidad_kg = Decimal(str(round(rnd.uniform(0.3, 2.5), 2)))
            d_objs.append(di)
    DietaInsumo.objects.bulk_create(d_objs)
    return dietas


def crear_lotes(usuario, dietas):
    objs = []
    nombres = ['Lote A1', 'Lote A2', 'Lote B1', 'Lote B2', 'Lote C1', 'Lote C2',
               'Lote D1', 'Lote D2', 'Lote E1', 'Lote E2', 'Lote F1', 'Lote F2',
               'Lote G1', 'Lote G2', 'Lote H1', 'Lote H2', 'Lote I1', 'Lote I2',
               'Lote J1', 'Lote J2']
    for i, nombre in enumerate(nombres):
        estado = rnd.choices(['activo', 'vendido', 'cuarentena'], [0.8, 0.15, 0.05])[0]
        etapa = rnd.choice(etapas)
        objs.append(Lote(
            usuario=usuario,
            dieta=rnd.choice(dietas) if rnd.random() < 0.8 else None,
            nombre=nombre,
            cantidad_cabezas=rnd.randint(8, 25),
            peso_promedio_actual_kg=Decimal(str(rnd.uniform(180, 420))).quantize(Decimal('0.1')),
            etapa_productiva=etapa,
            estado=estado,
        ))
    return Lote.objects.bulk_create(objs)


def crear_pesajes_lote(lotes):
    objs = []
    for l in lotes:
        n = rnd.randint(8, 14)
        fechas = sorted(TODAY - timedelta(days=rnd.randint(10, 365)) for _ in range(n))
        peso = 180.0
        for f in fechas:
            peso += rnd.uniform(0.3, 1.1)
            objs.append(PesajeLote(
                lote=l, fecha_pesaje=f,
                peso_promedio_kg=Decimal(str(round(peso, 1))),
                ganancia_diaria_promedio=Decimal(str(round(rnd.uniform(0.3, 1.1), 2))),
                notas='' if rnd.random() < 0.7 else 'Pesaje de rutina',
            ))
    return PesajeLote.objects.bulk_create(objs)


def crear_alimentacion(usuario, lotes, dietas):
    objs = []
    for l in lotes:
        for dias_atras in range(75, -1, -1):
            f = TODAY - timedelta(days=dias_atras)
            if rnd.random() < 0.04:
                continue
            dieta = rnd.choice(dietas) if rnd.random() < 0.7 else None
            kg = Decimal(str(round(rnd.uniform(20, 250), 1)))
            objs.append(AlimentacionDiaria(
                lote=l, dieta=dieta, fecha=f,
                cantidad_servida_kg=kg,
                costo_total_racion=Decimal(str(round(float(kg) * rnd.uniform(3.0, 5.0), 2))),
                usuario_registro=usuario,
            ))
    return AlimentacionDiaria.objects.bulk_create(objs)


def crear_animales(usuario, lotes):
    animales = []
    total = 200
    for i in range(1, total + 1):
        arete = f'DV-{i:04d}'
        sexo = 'H' if i % 2 == 0 else 'M'
        anios_atras = rnd.uniform(0.1, 6.0)
        fecha_nac = TODAY - timedelta(days=int(anios_atras * 365))
        lote = rnd.choice(lotes) if rnd.random() < 0.75 else None
        estado = rnd.choices(['activo', 'vendido', 'muerto', 'transferido'], [0.72, 0.15, 0.08, 0.05])[0]
        nombre = None
        if rnd.random() < 0.6:
            nombre = rnd.choice(nombres_machos if sexo == 'M' else nombres_hembras)
            if rnd.random() < 0.3:
                nombre = f'{nombre} {rnd.randint(2, 99)}'
        a = Animal(
            usuario=usuario, lote=lote,
            numero_arete=arete, nombre=nombre,
            raza=rnd.choice(razas), sexo=sexo,
            fecha_nacimiento=fecha_nac,
            color=rnd.choice(colores),
            peso_nacimiento_kg=Decimal(str(round(rnd.uniform(28, 42), 1))),
            estado=estado,
            fecha_ultimo_parto=None, partos_count=0, dias_lactancia=None,
            total_eventos_sanitarios=0,
        )
        if sexo == 'H' and anios_atras > 1.5:
            a.partos_count = rnd.randint(1, 5)
            a.fecha_ultimo_parto = fecha_nac + timedelta(days=int(a.partos_count * 400))
            if a.fecha_ultimo_parto > TODAY:
                a.fecha_ultimo_parto = TODAY - timedelta(days=rnd.randint(5, 300))
            a.dias_lactancia = (TODAY - a.fecha_ultimo_parto).days
        animales.append(a)

    Animal.objects.bulk_create(animales)
    animales = list(Animal.objects.filter(usuario=usuario).order_by('id'))

    # Genealogía
    hembras = [a for a in animales if a.sexo == 'H']
    machos = [a for a in animales if a.sexo == 'M']
    for a in animales:
        if a.sexo == 'M' and rnd.random() < 0.3:
            continue
        madres_disponibles = [h for h in hembras if h.fecha_nacimiento < a.fecha_nacimiento - timedelta(days=730)]
        if madres_disponibles and rnd.random() < 0.6:
            a.madre = rnd.choice(madres_disponibles)
        if rnd.random() < 0.35 and machos:
            padres = [m for m in machos if m != a and m.fecha_nacimiento < a.fecha_nacimiento - timedelta(days=730)]
            if padres:
                a.padre = rnd.choice(padres)
    Animal.objects.bulk_update([a for a in animales if a.madre_id or a.padre_id], ['madre', 'padre'])
    return animales


def crear_registros_peso(animales):
    objs = []
    for a in animales:
        n = rnd.randint(8, 16)
        fechas = sorted(TODAY - timedelta(days=rnd.randint(5, max(15, (TODAY - a.fecha_nacimiento).days))) for _ in range(n))
        peso = float(a.peso_nacimiento_kg)
        prev = None
        for f in fechas:
            peso += rnd.uniform(0.3, 1.0)
            gan = None
            if prev:
                dias = (f - prev[0]).days
                if dias > 0:
                    gan = Decimal(str(round((peso - prev[1]) / dias, 3)))
            objs.append(RegistroPeso(
                animal=a, fecha_pesaje=f,
                peso_kg=Decimal(str(round(peso, 1))),
                condicion_corporal=rnd.randint(1, 5) if rnd.random() < 0.5 else None,
                ganancia_diaria_kg=gan,
                notas='' if rnd.random() < 0.7 else 'Pesaje mensual de control',
            ))
            prev = (f, peso)
    return RegistroPeso.objects.bulk_create(objs)


def actualizar_ultimo_peso(animales):
    import collections
    ultimos = collections.defaultdict(list)
    for rp in RegistroPeso.objects.filter(animal__usuario__email=EMAIL).order_by('fecha_pesaje'):
        ultimos[rp.animal_id].append((rp.fecha_pesaje, rp.peso_kg))
    updates = []
    for a in animales:
        lista = ultimos.get(a.id, [])
        if lista:
            a.ultimo_peso_kg = lista[-1][1]
            a.fecha_ultimo_peso = lista[-1][0]
            updates.append(a)
    Animal.objects.bulk_update(updates, ['ultimo_peso_kg', 'fecha_ultimo_peso'])


def crear_ciclos(animales):
    hembras = [a for a in animales if a.sexo == 'H' and a.estado == 'activo' and a.partos_count >= 0]
    temporadas = ['Primavera 2025', 'Otoño 2025', 'Invierno 2025', 'Primavera 2026', 'Otoño 2026']
    objs = []
    for a in hembras:
        n = rnd.randint(1, 3)
        for j in range(n):
            f_serv = TODAY - timedelta(days=rnd.randint(30, 500))
            estado = rnd.choices(['en_servicio', 'gestante', 'pario', 'fallida', 'descartada'], [0.2, 0.25, 0.35, 0.15, 0.05])[0]
            dias_gest = 283
            f_parto = f_serv + timedelta(days=dias_gest)
            objs.append(CicloReproductivo(
                animal=a,
                tipo_servicio=rnd.choices(['natural', 'inseminacion_artificial'], [0.4, 0.6])[0],
                formato=rnd.choice(['temporada', 'continuo']),
                temporada=rnd.choice(temporadas) if rnd.random() < 0.5 else None,
                fecha_servicio=f_serv,
                dias_gestacion=dias_gest,
                fecha_estimada_parto=f_parto,
                fecha_parto_real=f_parto if estado == 'pario' else None,
                fecha_destete=(f_parto + timedelta(days=60)) if estado == 'pario' else None,
                estado=estado,
                notas='' if rnd.random() < 0.7 else 'Seguimiento rutinario de gestación',
            ))
    return CicloReproductivo.objects.bulk_create(objs)


def crear_nacimientos(animales, ciclos):
    paridos = [c for c in ciclos if c.estado == 'pario']
    madre_por_id = {a.id: a for a in animales}
    usados = set()
    objs = []
    for c in paridos:
        madre = madre_por_id.get(c.animal_id)
        if not madre:
            continue
        key = (madre.id, c.fecha_parto_real)
        if key in usados:
            continue
        usados.add(key)
        sexo = 'M' if rnd.random() < 0.5 else 'H'
        fnac = c.fecha_parto_real
        objs.append(RegistroNacimiento(
            ciclo=c, madre=madre,
            numero_arete=f'DV-{rnd.randint(9000, 9999)}',
            nombre=rnd.choice(nombres_machos if sexo == 'M' else nombres_hembras),
            sexo=sexo,
            peso_nacimiento_kg=Decimal(str(round(rnd.uniform(28, 42), 1))),
            fecha_nacimiento=fnac,
            fecha_destete=fnac + timedelta(days=70),
            anomalies='' if rnd.random() < 0.9 else 'Ninguna complicación reportada',
            observaciones='Parto atendido por el equipo del rancho.' if rnd.random() < 0.4 else '',
        ))
    return RegistroNacimiento.objects.bulk_create(objs)


def crear_eventos_sanitarios(animales):
    objs = []
    for a in animales:
        n = rnd.randint(1, 3)
        for _ in range(n):
            tipo = rnd.choice(['vacunacion', 'desparasitacion', 'tratamiento', 'cirugia'])
            if tipo == 'vacunacion':
                prod = rnd.choice(vacunas)
            elif tipo == 'desparasitacion':
                prod = rnd.choice(desparasitantes)
            elif tipo == 'tratamiento':
                prod = rnd.choice(antibioticos + vitaminas)
            else:
                prod = 'Cirugía menor'
            f = TODAY - timedelta(days=rnd.randint(1, 365))
            prox = None
            if tipo == 'vacunacion':
                prox = f + timedelta(days=180)
            elif tipo == 'desparasitacion':
                prox = f + timedelta(days=90)
            costo = Decimal(str(round(rnd.uniform(10, 600), 2)))
            objs.append(EventoSanitario(
                animal=a, tipo=tipo, producto=prod,
                dosis=rnd.choice(['5 ml', '10 ml', '3 ml', '2.5 ml']) if rnd.random() < 0.7 else None,
                fecha_aplicacion=f, proxima_aplicacion=prox,
                veterinario=rnd.choice(['MVZ. Laura Soto', 'MVZ. Patricia Godoy', 'Dr. Héctor Domínguez', 'David Camacho']),
                costo=costo,
                notas='' if rnd.random() < 0.6 else 'Aplicación rutinaria',
            ))
    return EventoSanitario.objects.bulk_create(objs)


def crear_auditorias(usuario):
    logins = []
    for i in range(45):
        exito = rnd.random() < 0.85
        f = timezone.make_aware(datetime.combine(TODAY - timedelta(days=rnd.randint(0, 180)), datetime.min.time()))
        logins.append(AuditoriaLogin(
            usuario=usuario if exito else None,
            email=EMAIL,
            ip_address=rnd.choice(['189.146.20.15', '201.174.180.9', '10.0.0.24', '192.168.1.7']),
            user_agent='Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
            resultado='exitoso' if exito else 'fallido',
            mensaje='Inicio de sesión exitoso' if exito else 'Contraseña incorrecta',
            fecha_intento=f,
        ))
    AuditoriaLogin.objects.bulk_create(logins)

    audit = []
    for a in Animal.objects.filter(usuario=usuario).order_by('?')[:40]:
        f = timezone.make_aware(datetime.combine(TODAY - timedelta(days=rnd.randint(1, 120)), datetime.min.time()))
        audit.append(AuditoriaAnimal(
            animal=a, usuario=usuario, campo=rnd.choice(['peso', 'estado', 'lote', 'color', 'raza']),
            valor_anterior='Valor anterior',
            valor_nuevo='Valor actualizado',
            fecha_cambio=f,
            ip_address='189.146.20.15',
        ))
    AuditoriaAnimal.objects.bulk_create(audit)


def crear_colaboradores(usuario):
    candidatos = Usuario.objects.exclude(email=EMAIL).exclude(nombre_completo='')[:4]
    creados = 0
    for cand in candidatos:
        if UsuarioInvitado.objects.filter(cuenta_principal=usuario, usuario=cand).exists():
            continue
        UsuarioInvitado.objects.create(
            cuenta_principal=usuario, usuario=cand,
            rol=rnd.choice(['editor', 'viewer', 'admin']),
        )
        creados += 1
    return creados


@transaction.atomic
def main():
    clear_previous()
    planes = crear_planes()
    usuario = crear_usuario(planes)

    proveedores = crear_proveedores(usuario)
    cat_objs = crear_categorias(usuario)
    categorias_map = {c.nombre: c for c in cat_objs}

    insumos = crear_insumos(usuario, categorias_map, proveedores)
    crear_movimientos(usuario, insumos)
    dietas = crear_dietas(usuario, insumos)
    lotes = crear_lotes(usuario, dietas)
    crear_pesajes_lote(lotes)
    crear_alimentacion(usuario, lotes, dietas)
    animales = crear_animales(usuario, lotes)
    crear_registros_peso(animales)
    actualizar_ultimo_peso(animales)
    ciclos = crear_ciclos(animales)
    crear_nacimientos(animales, ciclos)
    crear_eventos_sanitarios(animales)
    crear_auditorias(usuario)
    colaboradores = crear_colaboradores(usuario)

    print('=' * 60)
    print('SEED COMPLETADO')
    print('=' * 60)
    print(f'Email:    {EMAIL}')
    print(f'Password: {PASSWORD}')
    print(f'Plan:     {usuario.suscripcion.plan.nombre}')
    print('-' * 60)
    print(f'Proveedores:          {Proveedor.objects.filter(usuario=usuario).count()}')
    print(f'Categorías:           {CategoriaInsumo.objects.filter(usuario=usuario).count()}')
    print(f'Insumos:              {Insumo.objects.filter(usuario=usuario).count()}')
    print(f'Movimientos inv.:     {MovimientoInventario.objects.filter(insumo__usuario=usuario).count()}')
    print(f'Dietas:               {Dieta.objects.filter(usuario=usuario).count()}')
    print(f'Dieta-insumos:        {DietaInsumo.objects.filter(dieta__usuario=usuario).count()}')
    print(f'Lotes:                {Lote.objects.filter(usuario=usuario).count()}')
    print(f'Pesajes lote:         {PesajeLote.objects.filter(lote__usuario=usuario).count()}')
    print(f'Alimentación diaria:  {AlimentacionDiaria.objects.filter(lote__usuario=usuario).count()}')
    print(f'Animales:             {Animal.objects.filter(usuario=usuario).count()}')
    print(f'Registros de peso:    {RegistroPeso.objects.filter(animal__usuario=usuario).count()}')
    print(f'Ciclos reproductivos: {CicloReproductivo.objects.filter(animal__usuario=usuario).count()}')
    print(f'Nacimientos:          {RegistroNacimiento.objects.filter(madre__usuario=usuario).count()}')
    print(f'Eventos sanitarios:   {EventoSanitario.objects.filter(animal__usuario=usuario).count()}')
    print(f'Auditorías login:     {AuditoriaLogin.objects.filter(usuario=usuario).count()}')
    print(f'Auditorías animal:    {AuditoriaAnimal.objects.filter(usuario=usuario).count()}')
    print(f'Colaboradores:        {colaboradores}')


if __name__ == '__main__':
    main()
