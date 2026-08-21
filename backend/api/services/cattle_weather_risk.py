"""Reglas preventivas generales de clima para ganado.

Los umbrales iniciales son orientativos. En el futuro deben configurarse por
tipo de ganado (carne o lechero), raza, edad y condiciones de manejo.
"""

from dataclasses import dataclass


SEVERITY = {'normal': 0, 'precaucion': 1, 'alto': 2, 'critico': 3}
DISCLAIMER = 'Alertas orientativas; no sustituyen la valoración veterinaria.'


@dataclass(frozen=True)
class RiskRuleResult:
    level: str
    risk_type: str
    title: str
    message: str
    recommendations: tuple[str, ...]


def calculate_thi(temperature_c, relative_humidity):
    temperature = float(temperature_c)
    humidity = float(relative_humidity)
    return round(
        (1.8 * temperature + 32)
        - (0.55 - 0.0055 * humidity) * (1.8 * temperature - 26),
        1,
    )


def _matched_rules(current, forecast, thi):
    temperature = float(current.get('temperatura') or 0)
    humidity = float(current.get('humedad') or 0)
    precipitation = float(current.get('precipitacion') or 0)
    wind = float(current.get('viento') or 0)
    gusts = float(current.get('rafagas') or 0)
    accumulated = float(forecast.get('precipitacion_acumulada') or 0)
    probability = float(forecast.get('probabilidad_lluvia_maxima') or 0)
    risks = []

    if thi >= 84:
        risks.append(RiskRuleResult('critico', 'estres_calor', 'Riesgo crítico por estrés térmico', 'La combinación de temperatura y humedad puede afectar gravemente al ganado.', ('Mantén agua limpia y suficiente disponible.', 'Proporciona sombra y ventilación.', 'Vigila jadeo, salivación o reducción del consumo.')))
    elif thi >= 79:
        risks.append(RiskRuleResult('alto', 'estres_calor', 'Riesgo alto por estrés térmico', 'Las condiciones pueden favorecer estrés térmico en el ganado.', ('Evita movimientos y manejo en las horas más calurosas.', 'Mantén agua limpia y suficiente disponible.', 'Proporciona sombra y ventilación.')))
    elif thi >= 72:
        risks.append(RiskRuleResult('precaucion', 'estres_calor', 'Precaución por estrés térmico', 'La combinación de temperatura y humedad puede afectar al ganado.', ('Mantén agua limpia y suficiente disponible.', 'Proporciona sombra y ventilación.', 'Vigila jadeo, salivación o reducción del consumo.')))

    if accumulated >= 50 or precipitation >= 15:
        risks.append(RiskRuleResult('alto', 'lluvia_intensa', 'Riesgo alto por lluvia', 'La lluvia intensa puede afectar corrales, caminos y zonas de descanso.', ('Revisa drenajes y zonas de resguardo.', 'Evita que el ganado permanezca en áreas inundables.')))
    elif accumulated >= 20 or (probability >= 80 and accumulated >= 10):
        risks.append(RiskRuleResult('precaucion', 'lluvia', 'Precaución por lluvia', 'Se prevén condiciones húmedas que pueden afectar el manejo del rancho.', ('Revisa drenajes y zonas de resguardo.', 'Protege alimento y suministros de la humedad.')))

    if humidity >= 85 and (precipitation > 0 or accumulated >= 5):
        risks.append(RiskRuleResult('precaucion', 'humedad_precipitacion', 'Humedad elevada y lluvia', 'Condiciones que pueden favorecer lodo y deterioro de las áreas de descanso.', ('Mantén camas y áreas de descanso lo más secas posible.', 'Vigila la condición de corrales y pezuñas.')))

    if temperature <= 5 and (precipitation > 0 or accumulated >= 3 or wind >= 25):
        level = 'alto' if temperature <= 0 or wind >= 40 else 'precaucion'
        risks.append(RiskRuleResult(level, 'frio_humedo', 'Frío con lluvia o viento', 'El frío combinado con humedad o viento puede incrementar la pérdida de calor.', ('Proporciona resguardo seco contra viento y lluvia.', 'Vigila especialmente crías y animales vulnerables.')))

    if gusts >= 70:
        risks.append(RiskRuleResult('alto', 'rafagas_fuertes', 'Ráfagas fuertes', 'Las ráfagas pueden representar riesgo por objetos sueltos o infraestructura.', ('Asegura láminas, cercos y objetos sueltos.', 'Mantén al ganado lejos de árboles o estructuras inestables.')))
    elif gusts >= 45:
        risks.append(RiskRuleResult('precaucion', 'rafagas_fuertes', 'Precaución por ráfagas', 'Se recomienda vigilar estructuras y zonas expuestas al viento.', ('Asegura objetos sueltos y revisa cercos.',)))
    return risks


def assess_cattle_weather_risk(current, forecast):
    thi = calculate_thi(current.get('temperatura') or 0, current.get('humedad') or 0)
    risks = _matched_rules(current, forecast, thi)
    if not risks:
        risks = [RiskRuleResult('normal', 'condiciones_normales', 'Condiciones normales', 'No se identifican condiciones meteorológicas adversas relevantes.', ('Continúa con la vigilancia y el manejo habitual.',))]
    principal = max(risks, key=lambda risk: SEVERITY[risk.level])
    recommendations = list(dict.fromkeys(item for risk in risks for item in risk.recommendations))
    return {
        'nivel': principal.level,
        'tipo': principal.risk_type,
        'titulo': principal.title,
        'mensaje': principal.message,
        'recomendaciones': recommendations,
        'thi': thi,
        'advertencia': DISCLAIMER,
    }
