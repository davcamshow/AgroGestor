import hashlib
from datetime import timedelta
from django.test import TestCase, Client
from django.contrib.auth.models import User as AuthUser
from django.utils import timezone
from rest_framework.test import APITestCase
from django.urls import reverse
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from unittest.mock import patch
from django.core.files.uploadedfile import SimpleUploadedFile
from .models import (
    Usuario, Lote, Animal, AuditoriaLogin, AuditoriaAnimal, PasswordResetOtp,
    Insumo, MovimientoInventario, Dieta, DietaInsumo, AlimentacionDiaria,
)


class LoginUnitTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = AuthUser.objects.create_user(
            username='testuser@test.com',
            email='testuser@test.com',
            password='TestPassword123!'
        )
        self.usuario = Usuario.objects.create(
            auth_user=self.user,
            nombre_completo='Test User',
            email='testuser@test.com',
            password_hash='hashed_password'
        )

    def test_credenciales_validas(self):
        from django.contrib.auth import authenticate
        user = authenticate(username='testuser@test.com', password='TestPassword123!')
        self.assertIsNotNone(user)

    def test_credenciales_invalidas(self):
        from django.contrib.auth import authenticate
        user = authenticate(username='testuser@test.com', password='WrongPassword')
        self.assertIsNone(user)

    def test_usuario_activo(self):
        self.assertTrue(self.user.is_active)
        self.assertTrue(AuthUser.objects.get(username='testuser@test.com').is_active)

    def test_usuario_inactivo_no_autentica(self):
        self.user.is_active = False
        self.user.save()
        from django.contrib.auth import authenticate
        user = authenticate(username='testuser@test.com', password='TestPassword123!')
        self.assertIsNone(user)


class LoginIntegrationTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = AuthUser.objects.create_user(
            username='testlogin@test.com',
            email='testlogin@test.com',
            password='TestPassword123!'
        )
        self.usuario = Usuario.objects.create(
            auth_user=self.user,
            nombre_completo='Test Login',
            email='testlogin@test.com',
            password_hash='hashed_password'
        )

    def test_login_exitoso_retorna_token(self):
        response = self.client.post('/api/auth/login/', {
            'username': 'testlogin@test.com',
            'password': 'TestPassword123!'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)

    def test_login_fallido_retorna_error(self):
        response = self.client.post('/api/auth/login/', {
            'username': 'testlogin@test.com',
            'password': 'WrongPassword'
        })
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_registro_intentos_fallidos(self):
        """Validar que un login con usuario inexistente retorne 401"""
        url_login = '/api/auth/login/' 
        data_erronea = {
            'username': 'usuario_fantasma@rancho.com',
            'password': 'ClaveIncorrecta123*'
        }
        response = self.client.post(url_login, data_erronea, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class PasswordResetOtpFlowTests(APITestCase):
    def setUp(self):
        self.user = AuthUser.objects.create_user(
            username='resetuser@test.com',
            email='resetuser@test.com',
            password='TestPassword123!'
        )
        Usuario.objects.create(
            auth_user=self.user,
            nombre_completo='Reset User',
            email='resetuser@test.com',
            password_hash='hashed_password'
        )

    @patch('api.email_utils.EmailMultiAlternatives.send')
    def test_request_password_reset_crea_codigo_otp(self, mock_send):
        response = self.client.post('/api/auth/password-reset/request/', {'email': 'resetuser@test.com'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(PasswordResetOtp.objects.filter(user=self.user).exists())
        mock_send.assert_called_once()

    @patch('api.email_utils.EmailMultiAlternatives.send')
    def test_verificar_y_confirmar_password_reset_con_otp(self, mock_send):
        self.client.post('/api/auth/password-reset/request/', {'email': 'resetuser@test.com'})
        otp_obj = PasswordResetOtp.objects.get(user=self.user)
        code = '123456'
        otp_obj.code_hash = hashlib.sha256(code.encode('utf-8')).hexdigest()
        otp_obj.save(update_fields=['code_hash'])

        verify_response = self.client.post('/api/auth/password-reset/verify/', {
            'email': 'resetuser@test.com',
            'code': code,
        })
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)

        confirm_response = self.client.post('/api/auth/password-reset/confirm/', {
            'email': 'resetuser@test.com',
            'code': code,
            'password': 'NuevaPassword123*',
            'password_confirm': 'NuevaPassword123*',
        })
        self.assertEqual(confirm_response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('NuevaPassword123*'))

    def test_rechaza_la_contrasena_actual_y_mantiene_el_otp_activo(self):
        code = '123456'
        otp_obj = PasswordResetOtp.objects.create(
            user=self.user,
            code_hash=hashlib.sha256(code.encode('utf-8')).hexdigest(),
            expires_at=timezone.now() + timedelta(minutes=10),
            is_active=True,
        )

        response = self.client.post('/api/auth/password-reset/confirm/', {
            'email': 'resetuser@test.com',
            'code': code,
            'password': 'TestPassword123!',
            'password_confirm': 'TestPassword123!',
        })

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data['detail'],
            'La nueva contraseña no puede ser la misma que la contraseña actual.',
        )
        otp_obj.refresh_from_db()
        self.assertTrue(otp_obj.is_active)
        self.assertIsNone(otp_obj.used_at)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('TestPassword123!'))


class LoteModelTest(TestCase):
    def setUp(self):
        self.user = AuthUser.objects.create_user(
            username='testlote@test.com',
            email='testlote@test.com',
            password='TestPassword123!'
        )
        self.usuario = Usuario.objects.create(
            auth_user=self.user,
            nombre_completo='Test Lote',
            email='testlote@test.com',
            password_hash='hashed_password'
        )

    def test_crear_lote(self):
        lote = Lote.objects.create(
            usuario=self.usuario,
            nombre='Lote Prueba',
            cantidad_cabezas=50,
            etapa_productiva='engorda',
            estado='activo'
        )
        self.assertEqual(lote.nombre, 'Lote Prueba')
        self.assertEqual(lote.cantidad_cabezas, 50)

    def test_lote_con_dieta(self):
        from .models import Dieta
        dieta = Dieta.objects.create(
            usuario=self.usuario,
            nombre='Dieta Prueba',
            objetivo='engorda',
            costo_estimado_kg=10.00
        )
        lote = Lote.objects.create(
            usuario=self.usuario,
            nombre='Lote con Dieta',
            cantidad_cabezas=30,
            etapa_productiva='engorda',
            dieta=dieta,
            estado='activo'
        )
        self.assertEqual(lote.dieta.nombre, 'Dieta Prueba')


class LoteSerializerTest(TestCase):
    def setUp(self):
        self.user = AuthUser.objects.create_user(
            username='testserializer@test.com',
            email='testserializer@test.com',
            password='TestPassword123!'
        )
        self.usuario = Usuario.objects.create(
            auth_user=self.user,
            nombre_completo='Test Serializer',
            email='testserializer@test.com',
            password_hash='hashed_password'
        )

    def test_validar_capacidad_maxima(self):
        from .serializer import LoteSerializer
        data = {
            'nombre': 'Lote Exceso',
            'cantidad_cabezas': 500,
            'etapa_productiva': 'engorda',
            'estado': 'activo'
        }
        serializer = LoteSerializer(data=data)
        self.assertFalse(serializer.is_valid())

    def test_validar_capacidad_valida(self):
        from .serializer import LoteSerializer
        data = {
            'nombre': 'Lote Valido',
            'cantidad_cabezas': 50,
            'etapa_productiva': 'engorda',
            'estado': 'activo',
            'usuario': self.usuario.id
        }
        serializer = LoteSerializer(data=data)
        self.assertTrue(serializer.is_valid(), serializer.errors)


class LoteViewSetTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = AuthUser.objects.create_user(
            username='testviewset@test.com',
            email='testviewset@test.com',
            password='TestPassword123!'
        )
        self.usuario = Usuario.objects.create(
            auth_user=self.user,
            nombre_completo='Test ViewSet',
            email='testviewset@test.com',
            password_hash='hashed_password'
        )
        self.lote = Lote.objects.create(
            usuario=self.usuario,
            nombre='Lote ViewSet',
            cantidad_cabezas=25,
            etapa_productiva='crecimiento',
            estado='activo'
        )
        refresh = RefreshToken.for_user(self.user)
        self.token = str(refresh.access_token)

    def test_list_lotes(self):
        response = self.client.get(
            '/api/lotes/',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_create_lote(self):
        response = self.client.post(
            '/api/lotes/',
            data={
                'nombre': 'Nuevo Lote',
                'cantidad_cabezas': 40,
                'etapa_productiva': 'destete',
                'estado': 'activo'
            },
            content_type='application/json',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_update_lote(self):
        response = self.client.put(
            f'/api/lotes/{self.lote.id}/',
            data={
                'nombre': 'Lote Actualizado',
                'cantidad_cabezas': 30,
                'etapa_productiva': 'crecimiento',
                'estado': 'activo'
            },
            content_type='application/json',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_delete_lote(self):
        response = self.client.delete(
            f'/api/lotes/{self.lote.id}/',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)

class AnimalEdicionAuditoriaTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(username='martin@rancho.com', email='martin@rancho.com', password='Password123*')
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Martín Cruz Armas',
            email='martin@rancho.com'
        )
        self.client.force_authenticate(user=self.auth_user)

        self.animal1 = Animal.objects.create(
            usuario=self.usuario_perfil,
            numero_arete='RE-001',
            nombre='Vaca Lola',
            sexo='H',
            estado='activo'
        )
        self.animal2 = Animal.objects.create(
            usuario=self.usuario_perfil,
            numero_arete='RE-002',
            nombre='Toro Ferd',
            sexo='M',
            estado='activo'
        )
        self.url_detalle = reverse('animal-detail', kwargs={'pk': self.animal1.pk})

    def test_edicion_total_put_exitoso(self):
        data = {
            'numero_arete': 'RE-001',
            'nombre': 'Lola Modificada',
            'raza': 'Angus',
            'sexo': 'H',
            'estado': 'activo'
        }
        response = self.client.put(self.url_detalle, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.animal1.refresh_from_db()
        self.assertEqual(self.animal1.nombre, 'Lola Modificada')

    def test_edicion_parcial_patch_y_auditoria(self):
        data = {
            'estado': 'vendido',
            'nombre': 'Lola Vendida'
        }
        response = self.client.patch(self.url_detalle, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        auditorias = AuditoriaAnimal.objects.filter(animal=self.animal1)
        self.assertEqual(auditorias.count(), 2)

    def test_validation_caravana_duplicada_en_edicion(self):
        data = {'numero_arete': 'RE-002'}
        response = self.client.patch(self.url_detalle, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('numero_arete', response.data)

class AnimalBajaTests(APITestCase):

    def setUp(self):
        # 1. Crear usuario de prueba
        self.auth_user = AuthUser.objects.create_user(
            username='test@agrogestor.com',
            email='test@agrogestor.com',
            password='Password123!'
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Martín Cruz',
            email='test@agrogestor.com'
        )
        
        # Autenticar al usuario con JWT (o simular login de la request)
        self.client.force_authenticate(user=self.auth_user)

        # 2. Crear un animal activo para las pruebas de baja
        self.animal = Animal.objects.create(
            usuario=self.usuario_perfil,
            numero_arete='MX-999888',
            nombre='Bailadora',
            sexo='H',
            estado='activo'
        )
        
        # URL dinámica para la baja del animal creado
        self.url_baja = reverse('animal-registrar-baja', kwargs={'pk': self.animal.id})

    def test_baja_por_venta_exitosa(self):
        data = {
            'causa': 'vendido',
            'fecha': '2026-05-25',
            'notas': 'Venta regular a productor local'
        }
        response = self.client.post(self.url_baja, data, format='json')
        
        self.assertEqual(response.status_code, 200)
        self.animal.refresh_from_db()
        self.assertEqual(self.animal.estado, 'vendido')
        
        # Verificar que se creó el registro de auditoría
        audit_exists = AuditoriaAnimal.objects.filter(animal=self.animal, campo='estado', valor_nuevo='vendido').exists()
        self.assertTrue(audit_exists)

    def test_baja_por_muerte_exitosa(self):
        data = {
            'causa': 'muerto',
            'fecha': '2026-05-20',
            'notas': 'Fallecimiento por complicaciones respiratorias'
        }
        response = self.client.post(self.url_baja, data, format='json')
        
        self.assertEqual(response.status_code, 200)
        self.animal.refresh_from_db()
        self.assertEqual(self.animal.estado, 'muerto')

    def test_baja_por_transferencia_exitosa(self):
        data = {
            'causa': 'transferido',
            'fecha': '2026-05-24',
            'notas': 'Transferido a rancho secundario colindante'
        }
        response = self.client.post(self.url_baja, data, format='json')
        
        self.assertEqual(response.status_code, 200)
        self.animal.refresh_from_db()
        self.assertEqual(self.animal.estado, 'transferido')

    def test_baja_falla_por_campos_faltantes(self):
        # Enviar datos incompletos sin fecha
        data = {
            'causa': 'muerto'
        }
        response = self.client.post(self.url_baja, data, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('error', response.data)


_PNG_1X1 = (
    b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01'
    b'\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89'
    b'\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01'
    b'\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82'
)


class AnimalFotoTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(
            username='foto@rancho.com',
            email='foto@rancho.com',
            password='Password123*',
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Foto Tester',
            email='foto@rancho.com',
        )
        self.client.force_authenticate(user=self.auth_user)
        self.animal = Animal.objects.create(
            usuario=self.usuario_perfil,
            numero_arete='FT-001',
            nombre='Luna',
            sexo='H',
            estado='activo',
        )

    def test_subir_foto_multipart_y_url_absoluta(self):
        foto = SimpleUploadedFile('luna.png', _PNG_1X1, content_type='image/png')
        response = self.client.patch(
            reverse('animal-detail', kwargs={'pk': self.animal.pk}),
            {'foto': foto},
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data.get('foto'))
        self.assertIn('/media/', response.data['foto'])
        self.animal.refresh_from_db()
        self.assertTrue(self.animal.foto)

    def test_listado_incluye_foto(self):
        self.animal.foto.save(
            'luna.png',
            SimpleUploadedFile('luna.png', _PNG_1X1, content_type='image/png'),
            save=True,
        )
        response = self.client.get('/api/animales/', {'estado': 'todos'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        animal_data = next(item for item in response.data if item['id'] == self.animal.id)
        self.assertTrue(animal_data.get('foto'))


class MovimientoInventarioStockTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(
            username='inventario@rancho.com',
            email='inventario@rancho.com',
            password='Password123!',
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Inventario Tester',
            email='inventario@rancho.com',
        )
        self.client.force_authenticate(user=self.auth_user)

        self.insumo = Insumo.objects.create(
            usuario=self.usuario_perfil,
            nombre='Maíz',
            cantidad_actual_kg='500',
            stock_minimo_kg='100',
            costo_kg='3.5',
        )

    def _crear_movimiento(self, tipo, cantidad):
        return self.client.post(
            '/api/movimientos-inventario/',
            data={
                'insumo': self.insumo.id,
                'tipo_movimiento': tipo,
                'cantidad_kg': str(cantidad),
            },
            format='json',
        )

    def test_entrada_suma_stock(self):
        response = self._crear_movimiento('entrada', '150')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.insumo.refresh_from_db()
        self.assertEqual(float(self.insumo.cantidad_actual_kg), 650.0)

    def test_salida_resta_stock(self):
        response = self._crear_movimiento('salida', '120')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.insumo.refresh_from_db()
        self.assertEqual(float(self.insumo.cantidad_actual_kg), 380.0)

    def test_salida_mayor_que_stock_rechazada(self):
        response = self._crear_movimiento('salida', '9999')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.insumo.refresh_from_db()
        self.assertEqual(float(self.insumo.cantidad_actual_kg), 500.0)

    def test_tipo_invalido_rechazado(self):
        response = self._crear_movimiento('traspaso', '10')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cantidad_negativa_rechazada(self):
        response = self._crear_movimiento('entrada', '-5')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_eliminar_movimiento_revierte_stock(self):
        self._crear_movimiento('entrada', '100')
        self.insumo.refresh_from_db()
        self.assertEqual(float(self.insumo.cantidad_actual_kg), 600.0)

        movimiento = MovimientoInventario.objects.get(insumo=self.insumo)
        response = self.client.delete(
            f'/api/movimientos-inventario/{movimiento.id}/'
        )
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.insumo.refresh_from_db()
        self.assertEqual(float(self.insumo.cantidad_actual_kg), 500.0)


class AlimentacionDiariaStockTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(
            username='racion@rancho.com',
            email='racion@rancho.com',
            password='Password123!',
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Ración Tester',
            email='racion@rancho.com',
        )
        self.client.force_authenticate(user=self.auth_user)

        self.lote = Lote.objects.create(
            usuario=self.usuario_perfil,
            nombre='Lote A',
            cantidad_cabezas=100,
            etapa_productiva='destete',
            estado='activo',
        )
        self.maiz = Insumo.objects.create(
            usuario=self.usuario_perfil,
            nombre='Maíz',
            cantidad_actual_kg='1000',
            stock_minimo_kg='100',
            costo_kg='3',
        )
        self.sorgo = Insumo.objects.create(
            usuario=self.usuario_perfil,
            nombre='Sorgo',
            cantidad_actual_kg='1000',
            stock_minimo_kg='100',
            costo_kg='2.5',
        )
        self.dieta = Dieta.objects.create(
            usuario=self.usuario_perfil,
            nombre='Dieta Destete',
            objetivo='Destete',
            costo_estimado_kg='3',
            tipo_formulacion='porcentaje',
            periodicidad='diaria',
        )
        DietaInsumo.objects.create(
            dieta=self.dieta,
            insumo=self.maiz,
            porcentaje_inclusion='60',
        )
        DietaInsumo.objects.create(
            dieta=self.dieta,
            insumo=self.sorgo,
            porcentaje_inclusion='40',
        )

    def test_registrar_racion_descuenta_insumos(self):
        respuesta = self.client.post(
            '/api/alimentacion-diaria/',
            data={
                'lote': self.lote.id,
                'dieta': self.dieta.id,
                'fecha': '2026-09-19',
                'cantidad_servida_kg': '1000',
                'costo_total_racion': '3000',
            },
            format='json',
        )
        self.assertEqual(respuesta.status_code, status.HTTP_201_CREATED)
        self.maiz.refresh_from_db()
        self.sorgo.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 400.0)
        self.assertEqual(float(self.sorgo.cantidad_actual_kg), 600.0)

    def test_registrar_racion_crea_movimientos_salida(self):
        respuesta = self.client.post(
            '/api/alimentacion-diaria/',
            data={
                'lote': self.lote.id,
                'dieta': self.dieta.id,
                'fecha': '2026-09-19',
                'cantidad_servida_kg': '500',
                'costo_total_racion': '1500',
            },
            format='json',
        )
        self.assertEqual(respuesta.status_code, status.HTTP_201_CREATED)
        movimientos = MovimientoInventario.objects.filter(insumo=self.maiz)
        self.assertEqual(movimientos.count(), 1)
        self.assertEqual(movimientos.first().tipo_movimiento, 'salida')
        self.assertEqual(float(movimientos.first().cantidad_kg), 300.0)

    def test_racion_sin_dieta_no_descuenta(self):
        respuesta = self.client.post(
            '/api/alimentacion-diaria/',
            data={
                'lote': self.lote.id,
                'fecha': '2026-09-19',
                'cantidad_servida_kg': '500',
                'costo_total_racion': '1500',
            },
            format='json',
        )
        self.assertEqual(respuesta.status_code, status.HTTP_201_CREATED)
        self.maiz.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 1000.0)


class ReporteConsumoTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(
            username='reporte@rancho.com',
            email='reporte@rancho.com',
            password='Password123!',
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Reporte Tester',
            email='reporte@rancho.com',
        )
        self.client.force_authenticate(user=self.auth_user)

        self.lote = Lote.objects.create(
            usuario=self.usuario_perfil,
            nombre='Lote Alpha',
            cantidad_cabezas=50,
            etapa_productiva='engorda',
            estado='activo',
        )
        self.maiz = Insumo.objects.create(
            usuario=self.usuario_perfil,
            nombre='Maíz',
            cantidad_actual_kg='800',
            stock_minimo_kg='200',
            costo_kg='3',
        )
        self.dieta = Dieta.objects.create(
            usuario=self.usuario_perfil,
            nombre='Dieta Engorda',
            objetivo='Engorda',
            costo_estimado_kg='3',
            tipo_formulacion='porcentaje',
            periodicidad='diaria',
        )
        DietaInsumo.objects.create(
            dieta=self.dieta,
            insumo=self.maiz,
            porcentaje_inclusion='100',
        )
        # Ración de 200 kg (descuenta 200 kg de maíz -> stock 600) + movimiento salida
        self.client.post(
            '/api/alimentacion-diaria/',
            data={
                'lote': self.lote.id,
                'dieta': self.dieta.id,
                'fecha': '2026-09-18',
                'cantidad_servida_kg': '200',
                'costo_total_racion': '600',
            },
            format='json',
        )

    def _gett(self):
        return self.client.get('/api/reporte/consumo/?dias=30')

    def test_reporte_agrega_secciones(self):
        r = self._gett()
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        data = r.json()
        self.assertIsInstance(data['por_lote'], list)
        self.assertIsInstance(data['insumos_gastados'], list)
        self.assertIsInstance(data['insumos_disponibles'], list)
        self.assertIn('valor_inventario_actual', data)
        self.assertIn('actualizado_en', data)
        self.assertIn('promedio_diario_kg', data)

    def test_reporte_totales_y_por_lote(self):
        r = self._gett()
        data = r.json()
        self.assertEqual(data['total_kg'], 200.0)
        self.assertEqual(data['costo_total'], 600.0)
        self.assertEqual(data['lotes_atendidos'], 1)
        self.assertEqual(data['por_lote'][0]['lote_nombre'], 'Lote Alpha')
        self.assertEqual(data['por_lote'][0]['total_kg'], 200.0)
        self.assertEqual(data['por_lote'][0]['costo_total'], 600.0)

    def test_reporte_insumos_gastados_y_disponibles(self):
        r = self._gett()
        data = r.json()
        gastado = next(
            e for e in data['insumos_gastados'] if e['nombre'] == 'Maíz'
        )
        self.assertEqual(gastado['kg'], 200.0)
        self.assertEqual(gastado['movimientos'], 1)
        disponible = next(
            e for e in data['insumos_disponibles'] if e['nombre'] == 'Maíz'
        )
        self.assertEqual(disponible['stock_kg'], 600.0)
        self.assertEqual(data['valor_inventario_actual'], 1800.0)

    def test_reporte_suma_salida_manual(self):
        self.client.post(
            '/api/movimientos-inventario/',
            data={
                'insumo': self.maiz.id,
                'tipo_movimiento': 'salida',
                'cantidad_kg': '50',
            },
            format='json',
        )
        r = self._gett()
        data = r.json()
        gastado = next(
            e for e in data['insumos_gastados'] if e['nombre'] == 'Maíz'
        )
        self.assertEqual(gastado['kg'], 250.0)
        self.assertEqual(gastado['movimientos'], 2)
        disponible = next(
            e for e in data['insumos_disponibles'] if e['nombre'] == 'Maíz'
        )
        self.assertEqual(disponible['stock_kg'], 550.0)


class ConsumoDietasTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(
            username='consumo@rancho.com',
            email='consumo@rancho.com',
            password='Password123!',
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Consumo Tester',
            email='consumo@rancho.com',
        )
        self.client.force_authenticate(user=self.auth_user)

        self.maiz = Insumo.objects.create(
            usuario=self.usuario_perfil,
            nombre='Maíz',
            cantidad_actual_kg='1000',
            stock_minimo_kg='100',
            costo_kg='3',
        )
        self.dieta_lote = Dieta.objects.create(
            usuario=self.usuario_perfil,
            nombre='Engorda diaria',
            objetivo='Engorda',
            costo_estimado_kg='3',
            tipo_formulacion='tabla_kg',
            periodicidad='diaria',
            cantidad_kg_cabeza='2',
        )
        DietaInsumo.objects.create(
            dieta=self.dieta_lote,
            insumo=self.maiz,
            cantidad_kg='1.5',
        )
        self.lote = Lote.objects.create(
            usuario=self.usuario_perfil,
            nombre='Lote Engorda',
            cantidad_cabezas=100,
            etapa_productiva='engorda',
            estado='activo',
            dieta=self.dieta_lote,
        )

    def _procesar(self):
        return self.client.post('/api/dietas/procesar-consumo/', format='json')

    def test_lote_diario_calcula_por_cabezas(self):
        respuesta = self._procesar()
        self.assertEqual(respuesta.status_code, status.HTTP_200_OK)
        resumen = respuesta.json()
        self.assertEqual(resumen['raciones_creadas'], 1)
        racion = AlimentacionDiaria.objects.get(lote=self.lote)
        self.assertEqual(racion.fecha, timezone.localdate())
        self.assertEqual(float(racion.cantidad_servida_kg), 150.0)
        self.assertEqual(float(racion.costo_total_racion), 450.0)
        self.maiz.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 850.0)
        mov = MovimientoInventario.objects.get(insumo=self.maiz)
        self.assertEqual(mov.tipo_movimiento, 'salida')
        self.assertEqual(float(mov.cantidad_kg), 150.0)
        self.assertEqual(resumen['lotes_procesados'][0]['lote_id'], self.lote.id)

    def test_no_duplica_el_mismo_periodo(self):
        self._procesar()
        resumen = self._procesar()
        self.assertEqual(resumen.json()['raciones_creadas'], 0)
        self.assertEqual(AlimentacionDiaria.objects.count(), 1)
        self.assertEqual(MovimientoInventario.objects.count(), 1)

    def test_semanal_atrasado_crea_una_racion(self):
        self.dieta_lote.periodicidad = 'semanal'
        self.dieta_lote.save()

        self._procesar()
        r1 = AlimentacionDiaria.objects.get()
        r1.fecha = timezone.localdate() - timedelta(days=10)
        r1.save()

        resumen = self._procesar().json()
        self.assertEqual(resumen['raciones_creadas'], 1)
        self.assertEqual(AlimentacionDiaria.objects.count(), 2)
        nueva = AlimentacionDiaria.objects.order_by('-fecha').first()
        self.assertEqual(nueva.fecha, r1.fecha + timedelta(days=7))

    def test_animal_dieta_especial_excluida_del_lote(self):
        dieta_animal = Dieta.objects.create(
            usuario=self.usuario_perfil,
            nombre='Recuperación',
            objetivo='Enfermo',
            costo_estimado_kg='4',
            tipo_formulacion='tabla_kg',
            periodicidad='diaria',
            cantidad_kg_cabeza='1',
        )
        DietaInsumo.objects.create(
            dieta=dieta_animal,
            insumo=self.maiz,
            cantidad_kg='1',
        )
        self.lote.cantidad_cabezas = 5
        self.lote.dieta = self.dieta_lote
        self.lote.save()

        Animal.objects.create(
            usuario=self.usuario_perfil,
            numero_arete='A-001',
            raza='Cebú',
            sexo='M',
            fecha_nacimiento='2024-03-01',
            peso_nacimiento_kg='25',
            lote=self.lote,
            dieta=dieta_animal,
        )

        resumen = self._procesar().json()
        # El lote solo tiene 1 animal activo registrado: come su dieta especial
        self.assertEqual(resumen['raciones_creadas'], 1)
        self.assertEqual(resumen['animales_procesados'], 1)

        especial = AlimentacionDiaria.objects.get(dieta=dieta_animal)
        self.assertEqual(float(especial.cantidad_servida_kg), 1.0)
        self.assertEqual(float(especial.costo_total_racion), 3.0)
        self.assertTrue(especial.notas.startswith('animal_id:'))
        # Nada se descuenta por la ración grupal (0 cabezas efectivas)
        self.assertEqual(
            AlimentacionDiaria.objects.filter(dieta=self.dieta_lote).count(), 0
        )
        self.maiz.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 999.0)

    def test_cabezas_se_calculan_con_ganado_asignado(self):
        # 50 manuales pero 3 animales activos registrados -> ración para 3
        self.lote.cantidad_cabezas = 50
        self.lote.save()
        for i in range(1, 4):
            Animal.objects.create(
                usuario=self.usuario_perfil,
                numero_arete=f'S-0{i}',
                raza='Cebú',
                sexo='H',
                fecha_nacimiento='2024-04-01',
                peso_nacimiento_kg='24',
                lote=self.lote,
            )
        resumen = self._procesar().json()
        self.assertIn('se calculan con el ganado asignado',
                      resumen['lotes_procesados'][0]['avisos'][0])
        racion = AlimentacionDiaria.objects.get(lote=self.lote)
        self.assertEqual(float(racion.cantidad_servida_kg), 4.5)
        self.maiz.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 995.5)

    def test_stock_insuficiente_avisa_y_no_deja_negativo(self):
        self.lote.cantidad_cabezas = 1000
        self.lote.save()
        resumen = self._procesar().json()
        self.assertEqual(resumen['insumos_agotados'], ['Maíz'])
        self.maiz.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 0.0)
        racion = AlimentacionDiaria.objects.get(lote=self.lote)
        self.assertEqual(float(racion.cantidad_servida_kg), 1000.0)

    def test_dieta_inactiva_no_consume(self):
        self.dieta_lote.estado = 'inactiva'
        self.dieta_lote.save()
        self.lote.dieta = self.dieta_lote
        self.lote.save()
        resumen = self._procesar().json()
        self.assertEqual(resumen['raciones_creadas'], 0)
        self.assertIn('no está activa', resumen['lotes_procesados'][0]['avisos'][0])
        self.maiz.refresh_from_db()
        self.assertEqual(float(self.maiz.cantidad_actual_kg), 1000.0)


class ValidacionesDietasTests(APITestCase):

    def setUp(self):
        self.auth_user = AuthUser.objects.create_user(
            username='validacion@rancho.com',
            email='validacion@rancho.com',
            password='Password123!',
        )
        self.usuario_perfil = Usuario.objects.create(
            auth_user=self.auth_user,
            nombre_completo='Validación Tester',
            email='validacion@rancho.com',
        )
        self.client.force_authenticate(user=self.auth_user)
        self.maiz = Insumo.objects.create(
            usuario=self.usuario_perfil,
            nombre='Maíz',
            cantidad_actual_kg='500',
            stock_minimo_kg='100',
            costo_kg='3',
        )

    def _crear_dieta(self, **extra):
        data = {
            'nombre': 'Engorda',
            'objetivo': 'Engorda',
            'costo_estimado_kg': '3',
            'tipo_formulacion': 'porcentaje',
            'periodicidad': 'diaria',
            **extra,
        }
        return self.client.post('/api/dietas/', data=data, format='json')

    def test_dieta_sin_nombre_rechazada(self):
        r = self._crear_dieta(nombre='')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('nombre', r.json())

    def test_dieta_periodicidad_invalida_rechazada(self):
        r = self._crear_dieta(periodicidad='mensual')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('periodicidad', r.json())

    def test_ingrediente_porcentaje_mayor_100_rechazado(self):
        dieta = self._crear_dieta().json()
        r = self.client.post(
            '/api/dieta-insumos/',
            data={
                'dieta': dieta['id'],
                'insumo': self.maiz.id,
                'porcentaje_inclusion': '150',
            },
            format='json',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('porcentaje_inclusion', r.json())

    def test_ingrediente_duplicado_rechazado(self):
        dieta = self._crear_dieta().json()
        datos = {
            'dieta': dieta['id'],
            'insumo': self.maiz.id,
            'porcentaje_inclusion': '50',
        }
        self.assertEqual(
            self.client.post('/api/dieta-insumos/', data=datos, format='json').status_code,
            status.HTTP_201_CREATED,
        )
        r = self.client.post('/api/dieta-insumos/', data=datos, format='json')
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('insumo', r.json())

    def test_ingrediente_sin_valor_rechazado(self):
        dieta = self._crear_dieta().json()
        r = self.client.post(
            '/api/dieta-insumos/',
            data={'dieta': dieta['id'], 'insumo': self.maiz.id},
            format='json',
        )
        self.assertEqual(r.status_code, status.HTTP_400_BAD_REQUEST)

    def test_asignar_dieta_especial_a_animal(self):
        dieta = self._crear_dieta(tipo_formulacion='tabla_kg', periodicidad='semanal').json()
        lote = Lote.objects.create(
            usuario=self.usuario_perfil,
            nombre='Lote A',
            cantidad_cabezas=10,
            etapa_productiva='engorda',
            estado='activo',
        )
        animal = Animal.objects.create(
            usuario=self.usuario_perfil,
            numero_arete='E-001',
            raza='Cebú',
            sexo='H',
            fecha_nacimiento='2024-05-01',
            peso_nacimiento_kg='22',
            lote=lote,
        )
        r = self.client.patch(
            f'/api/animales/{animal.id}/',
            data={'dieta': dieta['id']},
            format='json',
        )
        self.assertEqual(r.status_code, status.HTTP_200_OK)
        self.assertEqual(r.json()['dieta'], dieta['id'])
        animal.refresh_from_db()
        self.assertEqual(animal.dieta_id, dieta['id'])

        r2 = self.client.get(f'/api/animales/{animal.id}/')
        self.assertEqual(r2.json()['dieta'], dieta['id'])
