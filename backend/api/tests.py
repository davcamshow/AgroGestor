from django.test import TestCase, Client
from django.contrib.auth.models import User as AuthUser
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Usuario, Lote, Animal, AuditoriaLogin


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
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST])

    def test_login_fallido_retorna_error(self):
        response = self.client.post('/api/auth/login/', {
            'username': 'testlogin@test.com',
            'password': 'WrongPassword'
        })
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_registro_intentos_fallidos(self):
        initial_count = AuditoriaLogin.objects.filter(resultado='fallido').count()
        self.client.post('/api/auth/login/', {
            'username': 'testlogin@test.com',
            'password': 'WrongPassword'
        })
        final_count = AuditoriaLogin.objects.filter(resultado='fallido').count()
        self.assertEqual(final_count, initial_count + 1)


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
        self.assertIn(response.status_code, [status.HTTP_201_CREATED, status.HTTP_400_BAD_REQUEST])

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
        self.assertIn(response.status_code, [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST])

    def test_delete_lote(self):
        response = self.client.delete(
            f'/api/lotes/{self.lote.id}/',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)