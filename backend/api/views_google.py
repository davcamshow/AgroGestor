from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework import status
import requests
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


class GoogleAuthView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')

        if not id_token:
            return Response(
                {'error': 'Token no proporcionado'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            google_verify_url = 'https://oauth2.googleapis.com/tokeninfo'
            params = {'id_token': id_token}

            google_response = requests.get(google_verify_url, params=params)

            if google_response.status_code != 200:
                return Response(
                    {'error': 'Token de Google inválido'},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            google_data = google_response.json()
            email = google_data.get('email')
            name = google_data.get('name', '')
            picture = google_data.get('picture', '')

            if not email:
                return Response(
                    {'error': 'Email no encontrado en token'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': email.split('@')[0],
                }
            )

            if created:
                parts = name.split(' ', 1)
                user.first_name = parts[0] if parts else ''
                user.last_name = parts[1] if len(parts) > 1 else ''
                user.save()

            refresh = RefreshToken.for_user(user)

            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'nombre_completo': user.get_full_name() or email.split('@')[0],
                    'nombre_rancho': user.nombre_rancho or '',
                    'telefono': user.telefono or '',
                }
            })

        except requests.RequestException as e:
            return Response(
                {'error': f'Error de conexión: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )