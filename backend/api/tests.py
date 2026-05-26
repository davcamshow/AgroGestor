from django.test import TestCase, Client
from django.contrib.auth.models import User as AuthUser
from rest_framework.test import APITestCase
from django.urls import reverse
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Usuario, Lote, Animal, AuditoriaLogin, AuditoriaAnimal


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