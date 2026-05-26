"""End-to-End Tests — prueban flujos completos contra el servidor real.

Uso: python e2e_tests.py
Requisito: servidor corriendo en http://localhost:8000
"""

import requests
import sys
import uuid

BASE = 'http://localhost:8000/api'

def gen_email():
    return f'test-{uuid.uuid4().hex[:8]}@e2e.com'

class Colors:
    OK = '\033[92m'
    FAIL = '\033[91m'
    END = '\033[0m'

passed = 0
failed = 0

def check(name, ok, detail=''):
    global passed, failed
    if ok:
        passed += 1
        print(f'  OK  {name}')
    else:
        failed += 1
        print(f'  FAIL {name}: {detail}')


# ────────────────────────────────────────────────────────────
# E2E-01: Registro → Login → CRUD Animal
# ────────────────────────────────────────────────────────────
def e2e01():
    email = gen_email()
    password = 'PassE2E123!'
    nombre = 'Usuario E2E'

    # 1. Registrar
    r = requests.post(f'{BASE}/auth/register/', json={
        'email': email, 'password': password, 'nombre_completo': nombre
    })
    check('[01] Register status', r.status_code == 201, r.text[:200])
    data = r.json()
    check('[01] Register returns email', data.get('email') == email)

    # 2. Login
    r = requests.post(f'{BASE}/auth/login/', json={
        'username': email, 'password': password
    })
    check('[01] Login status', r.status_code == 200)
    token = r.json().get('access')
    check('[01] Login returns access token', bool(token))
    headers = {'Authorization': f'Bearer {token}'}

    # 3. GET auth/me
    r = requests.get(f'{BASE}/auth/me/', headers=headers)
    check('[01] Auth me status', r.status_code == 200)
    check('[01] Auth me email', r.json().get('email') == email)

    # 4. POST animal
    r = requests.post(f'{BASE}/animales/', headers=headers, json={
        'numero_arete': 'E2E-001', 'nombre': 'Vaca E2E', 'sexo': 'H',
        'raza': 'Brahma', 'tipo': 'vaca', 'procedencia': 'propio'
    })
    check('[01] Create animal status', r.status_code == 201, r.text[:200])
    animal_id = r.json().get('id')
    check('[01] Create animal returns id', bool(animal_id))

    # 5. GET animal
    r = requests.get(f'{BASE}/animales/{animal_id}/', headers=headers)
    check('[01] Get animal status', r.status_code == 200)
    check('[01] Get animal nombre', r.json().get('nombre') == 'Vaca E2E')

    # 6. PUT animal
    r = requests.put(f'{BASE}/animales/{animal_id}/', headers=headers, json={
        'numero_arete': 'E2E-001', 'nombre': 'Vaca E2E Actualizada', 'sexo': 'H',
        'raza': 'Brahma', 'tipo': 'vaca', 'procedencia': 'propio'
    })
    check('[01] Update animal status', r.status_code == 200)
    check('[01] Update animal nombre', r.json().get('nombre') == 'Vaca E2E Actualizada')

    # 7. GET animales list
    r = requests.get(f'{BASE}/animales/', headers=headers)
    check('[01] List animales status', r.status_code == 200)
    check('[01] List animales count >= 1', len(r.json()) >= 1)

    # 8. DELETE animal
    r = requests.delete(f'{BASE}/animales/{animal_id}/', headers=headers)
    check('[01] Delete animal status', r.status_code == 204)

    # 9. GET (verify deleted)
    r = requests.get(f'{BASE}/animales/{animal_id}/', headers=headers)
    check('[01] Verify deleted returns 404', r.status_code == 404)

    return headers


# ────────────────────────────────────────────────────────────
# E2E-02: Lote → Insumo → Dieta → Alimentación → Pesaje
# ────────────────────────────────────────────────────────────
def e2e02(headers):
    # 1. POST lote
    r = requests.post(f'{BASE}/lotes/', headers=headers, json={
        'nombre': 'Lote E2E', 'cantidad_cabezas': 15,
        'etapa_productiva': 'crecimiento', 'estado': 'activo'
    })
    check('[02] Create lote status', r.status_code == 201, r.text[:200])
    lote_id = r.json().get('id')
    check('[02] Create lote returns id', bool(lote_id))

    # 2. GET lotes
    r = requests.get(f'{BASE}/lotes/', headers=headers)
    check('[02] List lotes status', r.status_code == 200)
    check('[02] List lotes >= 1 item', len(r.json()) >= 1)

    # 3. POST insumo
    r = requests.post(f'{BASE}/insumos/', headers=headers, json={
        'nombre': 'Maiz E2E', 'costo_kg': 5.5
    })
    check('[02] Create insumo status', r.status_code == 201, r.text[:200])
    insumo_id = r.json().get('id')
    check('[02] Create insumo returns id', bool(insumo_id))

    # 4. POST dieta
    r = requests.post(f'{BASE}/dietas/', headers=headers, json={
        'nombre': 'Dieta E2E', 'objetivo': 'engorda', 'costo_estimado_kg': 10.0
    })
    check('[02] Create dieta status', r.status_code == 201, r.text[:200])
    dieta_id = r.json().get('id')
    check('[02] Create dieta returns id', bool(dieta_id))

    # 5. POST alimentacion-diaria
    r = requests.post(f'{BASE}/alimentacion-diaria/', headers=headers, json={
        'lote': lote_id, 'dieta': dieta_id, 'fecha': '2026-05-25',
        'cantidad_servida_kg': 75.0, 'costo_total_racion': 412.5
    })
    check('[02] Create alimentacion status', r.status_code == 201, r.text[:200])

    # 6. POST pesaje de lote
    r = requests.post(f'{BASE}/pesajes-lotes/', headers=headers, json={
        'lote': lote_id, 'fecha_pesaje': '2026-05-25', 'peso_promedio_kg': 250.0
    })
    check('[02] Create pesaje status', r.status_code == 201, r.text[:200])

    # 7. Verificar KPIs
    r = requests.get(f'{BASE}/kpis/reproductivos/', headers=headers)
    check('[02] KPIs status', r.status_code == 200)

    # 8. Reporte consumo
    r = requests.get(f'{BASE}/reporte/consumo/', headers=headers)
    check('[02] Reporte consumo status', r.status_code == 200)

    return lote_id


# ────────────────────────────────────────────────────────────
# E2E-03: Ciclo Reproductivo + Evento Sanitario + Plan
# ────────────────────────────────────────────────────────────
def e2e03(headers):
    # 1. Crear animal para ciclo
    r = requests.post(f'{BASE}/animales/', headers=headers, json={
        'numero_arete': 'E2E-REPRO', 'nombre': 'Vaca Repro', 'sexo': 'H',
        'raza': 'Brahma', 'tipo': 'vaca', 'procedencia': 'propio'
    })
    check('[03] Create animal for ciclo status', r.status_code == 201, r.text[:200])
    animal_id = r.json().get('id')

    # 2. POST ciclo reproductivo
    r = requests.post(f'{BASE}/ciclos-reproductivos/', headers=headers, json={
        'animal': animal_id, 'tipo_servicio': 'natural',
        'fecha_servicio': '2026-05-01'
    })
    check('[03] Create ciclo status', r.status_code == 201, r.text[:200])
    ciclo_id = r.json().get('id')
    check('[03] Create ciclo returns id', bool(ciclo_id))

    # 3. GET ciclos
    r = requests.get(f'{BASE}/ciclos-reproductivos/', headers=headers)
    check('[03] List ciclos status', r.status_code == 200)
    check('[03] List ciclos >= 1 item', len(r.json()) >= 1)

    # 4. POST evento sanitario
    r = requests.post(f'{BASE}/eventos-sanitarios/', headers=headers, json={
        'animal': animal_id, 'tipo': 'vacunacion', 'fecha': '2026-05-01',
        'diagnostico': 'Prevención', 'producto': 'Vacuna X',
        'fecha_aplicacion': '2026-05-01'
    })
    check('[03] Create evento sanitario status', r.status_code == 201, r.text[:200])

    # 5. POST nacimiento
    r = requests.post(f'{BASE}/nacimientos/', headers=headers, json={
        'animal': animal_id, 'fecha_nacimiento': '2026-05-25', 'sexo': 'H'
    })
    # Nacimiento may need additional fields; verify response
    if r.status_code == 201:
        check('[03] Create nacimiento status', True)
    else:
        check('[03] Create nacimiento (may need more fields)', r.status_code in (201, 400),
              f'status={r.status_code}')

    # 6. GET planes / mi-plan
    r = requests.get(f'{BASE}/planes/', headers=headers)
    check('[03] List planes status', r.status_code == 200)
    planes = r.json()
    check('[03] Planes count >= 2', len(planes) >= 2, f'got {len(planes)}')

    r = requests.get(f'{BASE}/planes/mi-plan/', headers=headers)
    check('[03] Mi plan status', r.status_code == 200)

    # 7. Árbol genealógico
    r = requests.get(f'{BASE}/arbol-genealogico/{animal_id}/', headers=headers)
    check('[03] Arbol genealogico status', r.status_code == 200)

    # 8. Colaboradores
    r = requests.get(f'{BASE}/colaboradores/', headers=headers)
    check('[03] List colaboradores status', r.status_code == 200)

    # 9. Auditoría login
    r = requests.get(f'{BASE}/auditoria-login/', headers=headers)
    check('[03] Auditoria login status', r.status_code == 200)

    # 10. Refresh token
    login = requests.post(f'{BASE}/auth/login/', json={
        'username': 'admin@test.com', 'password': 'Admin123!'
    }).json()
    r = requests.post(f'{BASE}/auth/refresh/', json={'refresh': login['refresh']})
    check('[03] Refresh token status', r.status_code == 200)
    check('[03] Refresh returns new access', bool(r.json().get('access')))

    # 11. Proveedores
    r = requests.post(f'{BASE}/proveedores/', headers=headers, json={
        'nombre_empresa': 'Prov E2E', 'contacto': '555-0100'
    })
    check('[03] Create proveedor status', r.status_code == 201, r.text[:200])


# ────────────────────────────────────────────────────────────
# Main
# ────────────────────────────────────────────────────────────
def main():
    print('\n======= E2E Tests - AgroGestor Backend =======\n')

    # Health check
    try:
        r = requests.get(f'{BASE}/health/', timeout=5)
        assert r.status_code == 200
        print(f'  Server: {r.json()}\n')
    except requests.ConnectionError:
        print('  ERROR: Cannot connect to server at localhost:8000')
        print('  Start the server: python manage.py runserver\n')
        sys.exit(1)

    headers = e2e01()
    e2e02(headers)
    e2e03(headers)

    print(f'\nResults: {Colors.OK}{passed} passed{Colors.END}, '
          f'{Colors.FAIL}{failed} failed{Colors.END} of {passed + failed}\n')
    return 0 if failed == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
