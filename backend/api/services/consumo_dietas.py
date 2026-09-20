"""Motor de consumo automático de dietas.

Reglas de negocio (alimentación bovina):
- La ración de un lote se calcula según las cabezas activas del lote.
- Se excluyen del lote los animales con dieta especial (enfermos, condición,
  tratamiento distinto) porque comen su propia ración.
- La periodicidad se respeta: diaria (cada día), semanal (cada 7 días),
  quincenal (cada 15 días).
- Si el stock no alcanza, se descuenta lo disponible (nunca en negativo) y se
  reporta el faltante como aviso.
- Dietas o lotes mal configurados generan avisos, nunca bloquean el resto.
"""
from datetime import timedelta
from decimal import Decimal
from django.db import transaction
from django.utils import timezone

from ..models import (
    AlimentacionDiaria, DietaInsumo, Insumo, MovimientoInventario,
    Lote, Animal,
)

PERIODOS_DIAS = {'diaria': 1, 'semanal': 7, 'quincenal': 15}
NOTA_MARCA_ANIMAL = 'animal_id:'


def cabezas_efectivas_lote(lote, *, activos=None, especiales=None):
    """Cabezas que comen la ración grupal de un lote.

    Regla (recomendada):
    - Si el lote tiene animales registrados, la cantidad de cabezas se calcula
      automáticamente con los animales activos asignados (nunca en manual).
    - Si el lote se administra por grupos sin registrar animales, se usa el
      valor manual `cantidad_cabezas` como respaldo.
    - Se excluyen los animales con dieta especial, porque comen su propia ración.
    """
    if activos is None:
        activos = lote.animales.filter(estado='activo').count()
    if especiales is None:
        especiales = lote.animales.filter(estado='activo', dieta__isnull=False).count()
    base = activos if activos > 0 else (lote.cantidad_cabezas or 0)
    return max(int(base) - especiales, 0)


def _cabezas_efectivas(lote):
    return cabezas_efectivas_lote(lote)


def _dosis_insumos(dieta, cabezas):
    """Lista [{insumo, kg}] de la ración para `cabezas` según la dieta."""
    items = []
    ingredientes = DietaInsumo.objects.filter(dieta=dieta).select_related('insumo')
    for di in ingredientes:
        kg = None
        if dieta.tipo_formulacion == 'tabla_kg' and di.cantidad_kg:
            kg = Decimal(di.cantidad_kg) * Decimal(cabezas)
        elif di.porcentaje_inclusion:
            total_cabeza = Decimal(dieta.cantidad_kg_cabeza or 0)
            pct = Decimal(di.porcentaje_inclusion) / Decimal(100)
            kg = total_cabeza * pct * Decimal(cabezas)
        if kg is not None and kg > 0:
            items.append({'insumo': di.insumo, 'kg': kg})
    return items


@transaction.atomic
def _aplicar_salida(insumo, kg, notas, costo_unitario=None):
    """Descuenta stock y registra movimiento de salida. Nunca deja negativo."""
    insumo = Insumo.objects.select_for_update().get(pk=insumo.pk)
    costo_unitario = Decimal(costo_unitario) if costo_unitario is not None else Decimal(insumo.costo_kg)
    guardado = min(kg, insumo.cantidad_actual_kg)
    insumo.cantidad_actual_kg -= guardado
    insumo.save(update_fields=['cantidad_actual_kg', 'fecha_actualizacion'])
    if guardado > 0:
        MovimientoInventario.objects.create(
            insumo=insumo,
            tipo_movimiento='salida',
            cantidad_kg=guardado,
            costo_unitario_kg=costo_unitario,
            notas=notas,
        )
    costo = guardado * costo_unitario
    return Decimal(guardado), costo


@transaction.atomic
def _crear_racion(lote, animal, dieta, fecha, cabezas, notas, usuario_registro):
    """Convierte la dosis de la dieta en una AlimentacionDiaria + salidas."""
    dosis = _dosis_insumos(dieta, cabezas)
    if not dosis:
        return None, []

    if animal:
        notas_marca = f'{NOTA_MARCA_ANIMAL}{animal.id} · {animal.numero_arete}'
    else:
        notas_marca = notas
    base_notas = f'Ración {fecha.isoformat()}'
    if notas_marca:
        base_notas += f' · {notas_marca}'

    total_kg = Decimal('0')
    costo_total = Decimal('0')
    agotados = set()
    for d in dosis:
        guardado, costo = _aplicar_salida(d['insumo'], d['kg'], base_notas)
        total_kg += guardado
        costo_total += costo
        if guardado < d['kg']:
            agotados.add(d['insumo'].nombre)

    if total_kg <= 0:
        return None, list(agotados)

    registro = AlimentacionDiaria.objects.create(
        lote=lote,
        dieta=dieta,
        fecha=fecha,
        cantidad_servida_kg=total_kg,
        costo_total_racion=costo_total,
        usuario_registro=usuario_registro,
        notas=notas_marca,
    )
    return registro, list(agotados)


def _ultima_fecha_consumo(lote, animal):
    qs = AlimentacionDiaria.objects.filter(dieta__isnull=False)
    if animal:
        qs = qs.filter(notas__startswith=f'{NOTA_MARCA_ANIMAL}{animal.id}')
    else:
        qs = qs.filter(lote=lote)
    return qs.order_by('-fecha').values_list('fecha', flat=True).first()


def _fechas_pendientes(dieta, ultima, hoy):
    """Fechas en las que corresponde consumo según periodicidad (con rezago)."""
    periodo = PERIODOS_DIAS.get(dieta.periodicidad or 'diaria', 1)
    if ultima is None:
        return [hoy]
    inicio = ultima + timedelta(days=periodo)
    fechas = []
    d = inicio
    while d <= hoy:
        fechas.append(d)
        d += timedelta(days=periodo)
    return fechas


def _procesar_animal(animal, usuario, resumen, hoy):
    dieta = animal.dieta
    if dieta is None or dieta.estado != 'activa':
        return
    fechas = _fechas_pendientes(dieta, _ultima_fecha_consumo(None, animal), hoy)
    for f in fechas:
        registro, agotados = _crear_racion(
            animal.lote, animal, dieta, f, 1, None, usuario
        )
        if registro is None:
            resumen['avisos'].append(
                f'El animal {animal.numero_arete}: la dieta "{dieta.nombre}" no tiene ingredientes ({f}).'
            )
            continue
        resumen['raciones_creadas'] += 1
        resumen['movimientos_creados'] += len(_dosis_insumos(dieta, 1))
        for insumo in agotados:
            resumen['insumos_agotados'].add(insumo)


@transaction.atomic
def procesar_consumos(usuario, lote_id=None):
    """Procesa el consumo pendiente de todos los lotes y animales con dieta.

    Devuelve un resumen con raciones creadas, movimientos generados y avisos
    (para que el ganadero detecte errores de configuración).
    """
    hoy = timezone.localdate()
    resumen = {
        'raciones_creadas': 0,
        'movimientos_creados': 0,
        'lotes_procesados': [],
        'animales_procesados': 0,
        'insumos_agotados': set(),
        'avisos': [],
    }

    lotes = Lote.objects.filter(
        usuario=usuario, estado='activo', dieta__isnull=False
    ).select_related('dieta')
    if lote_id:
        lotes = lotes.filter(id=lote_id)

    for lote in lotes:
        plan = {
            'lote_id': lote.id,
            'lote_nombre': lote.nombre,
            'fechas': [],
            'avisos': [],
        }
        dieta = lote.dieta
        if dieta.estado != 'activa':
            plan['avisos'].append(f'La dieta "{dieta.nombre}" no está activa.')
        else:
            activos = lote.animales.filter(estado='activo').count()
            manual = int(lote.cantidad_cabezas or 0)
            if activos > 0 and manual != activos:
                plan['avisos'].append(
                    f'Las cabezas ahora se calculan con el ganado asignado: '
                    f'{activos} animales activos (la cantidad manual era {manual}).'
                )
            cabezas = cabezas_efectivas_lote(lote, activos=activos)
            if cabezas <= 0:
                plan['avisos'].append(
                    'Ninguna cabeza activa come la ración grupal (0 animales o todas con dieta especial).'
                )
            else:
                for f in _fechas_pendientes(dieta, _ultima_fecha_consumo(lote, None), hoy):
                    registro, agotados = _crear_racion(lote, None, dieta, f, cabezas, None, usuario)
                    if registro is None:
                        plan['avisos'].append(
                            f'La dieta "{dieta.nombre}" no tiene ingredientes ({f}).'
                        )
                        continue
                    resumen['raciones_creadas'] += 1
                    resumen['movimientos_creados'] += len(_dosis_insumos(dieta, cabezas))
                    for insumo in agotados:
                        resumen['insumos_agotados'].add(insumo)
                    plan['fechas'].append(str(f))

        # Animales del lote con dieta especial
        animales = Animal.objects.filter(
            usuario=usuario, estado='activo', lote=lote, dieta__isnull=False
        ).select_related('dieta')
        for animal in animales:
            _procesar_animal(animal, usuario, resumen, hoy)
            resumen['animales_procesados'] += 1

        resumen['lotes_procesados'].append(plan)

    # Animales con dieta especial que no están en ningún lote
    animales_sin_lote = Animal.objects.filter(
        usuario=usuario, estado='activo', lote__isnull=True, dieta__isnull=False
    ).select_related('dieta')
    for animal in animales_sin_lote:
        _procesar_animal(animal, usuario, resumen, hoy)
        resumen['animales_procesados'] += 1

    resumen['insumos_agotados'] = sorted(resumen['insumos_agotados'])
    return resumen


def aplicar_consumo_registro(registro):
    """Aplica el descuento de inventario a una ración ya creada (API manual)."""
    if not registro.dieta_id:
        return 0, []

    if registro.notas and registro.notas.startswith(NOTA_MARCA_ANIMAL):
        cabezas = 1
    elif registro.lote:
        cabezas = registro.lote.cantidad_cabezas or 0
    else:
        cabezas = 1

    total_meta = Decimal(registro.cantidad_servida_kg)
    movimientos = 0
    agotados = set()
    for di in DietaInsumo.objects.filter(dieta_id=registro.dieta_id).select_related('insumo'):
        if di.porcentaje_inclusion:
            kg = total_meta * (Decimal(di.porcentaje_inclusion) / Decimal(100))
        elif di.cantidad_kg:
            kg = Decimal(di.cantidad_kg) * cabezas
        else:
            continue
        if kg <= 0:
            continue
        notas = f'Consumo de ración {registro.fecha}'
        if registro.notas:
            notas += f' · {registro.notas}'
        guardado, _costo = _aplicar_salida(di.insumo, kg, notas)
        movimientos += 1
        if guardado < kg:
            agotados.add(di.insumo.nombre)
    return movimientos, sorted(agotados)