import jwt
from django.contrib.auth.models import User
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from .models import UserFCMToken

@api_view(['POST'])
@permission_classes([AllowAny])
def firebase_login(request):
    """
    Receives a Firebase ID token from the mobile app, and returns a Django REST Framework Auth Token.
    For local development, this bypasses strictly verifying the Google signature against a Service Account JSON.
    """
    id_token = request.data.get('idToken') or request.headers.get('Authorization', '').replace('Bearer ', '')

    if not id_token:
        return Response({"error": "No ID token provided"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Decode Firebase JWT (skipping signature verification in local development since we don't have Google Cloud credentials configured)
        decoded_token = jwt.decode(id_token, options={"verify_signature": False}, algorithms=["RS256"])
        # Extract payload identifiers dynamically from Firebase
        email = decoded_token.get('email')
        uid = decoded_token.get('user_id') or decoded_token.get('sub')
        
        if not email:
            email = f"{uid}@suraksha.com" # Fallback if no email is attached natively

        username = email.split('@')[0]
        
        # Dynamically link or create the requested user!
        user, created = User.objects.get_or_create(username=username, defaults={'email': email})
        # Generate or retrieve the DRF Token mapping to the user
        token, _ = Token.objects.get_or_create(user=user)

        return Response({
            "token": token.key,
            "user_id": user.id,
            "email": user.email,
            "message": "User authenticated successfully via local development bypass"
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def register_fcm_token(request):
    """
    Saves or updates the FCM token for the authenticated user.
    """
    fcm_token = request.data.get('fcmToken')
    if not fcm_token:
        return Response({"error": "No fcmToken provided"}, status=status.HTTP_400_BAD_REQUEST)

    UserFCMToken.objects.update_or_create(
        token=fcm_token,
        defaults={'user': request.user}
    )

    return Response({"message": "FCM token registered successfully"}, status=status.HTTP_200_OK)