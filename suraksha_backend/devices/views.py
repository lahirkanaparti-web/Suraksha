from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.core.mail import send_mail
from django.utils import timezone
from .models import Device, DeviceAccess, UnlockOTP
from alerts.models import Alert
from users.models import UserFCMToken
from core.utils import add_timestamp_to_image
from .serializers import DeviceSerializer, DeviceDetailSerializer
from events.models import AccessLog
import random
import io
from django.core.files.base import ContentFile
from firebase_admin import messaging
import firebase_admin

class DeviceListView(generics.ListCreateAPIView):
    serializer_class = DeviceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Hybrid Filter: Return devices explicitly requested by the Owner OR mapped defensively in DeviceAccess
        return Device.objects.filter(
            Q(owner=user) | Q(access_logs__identity=user)
        ).distinct().order_by('-created_at')

    def perform_create(self, serializer):
        # Automatically assign the logged-in user as the master 'owner' of the new device
        serializer.save(owner=self.request.user)

class DeviceDetailView(generics.RetrieveAPIView):
    serializer_class = DeviceDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Device.objects.filter(
            Q(owner=user) | Q(access_logs__identity=user)
        ).distinct()

@api_view(['POST'])
@permission_classes([AllowAny])
def device_ping(request):
    """
    Unified endpoint for ESP32: Heartbeat + Alert Ingestion + Access Logging.
    Expects X-Device-Token in headers.
    """
    token = request.headers.get('X-Device-Token')
    if not token:
        return Response({'detail': 'Device token required.'}, status=status.HTTP_401_UNAUTHORIZED)
        
    device = get_object_or_404(Device, security_token=token)
    
    # Update Heartbeat
    device.last_seen = timezone.now()
    device.status = "online"
    device.save()

    response_data = {'detail': 'Heartbeat received.'}
    
    # 1. Door Access Logic (Face Detection)
    access_status = request.data.get('access_status')
    if access_status:
        confidence = request.data.get('confidence', 0.0)
        snapshot = request.FILES.get('snapshot')
        
        AccessLog.objects.create(
            device=device,
            access_status=access_status,
            confidence=float(confidence),
            snapshot=snapshot
        )
        response_data['detail'] = f'Access {access_status} recorded.'
    
    # 2. Security Alert Logic (PIR Motion)
    if 'image' in request.FILES:
        # Anti-Spam (30s Cooldown)
        last_alert = Alert.objects.filter(device=device).order_by('-created_at').first()
        if last_alert and (timezone.now() - last_alert.created_at).total_seconds() < 30:
            return Response({'detail': 'Alert ignored due to cooldown.'}, status=status.HTTP_200_OK)
            
        uploaded_image = request.FILES['image']
        
        # Add Timestamp
        processed_img = add_timestamp_to_image(uploaded_image)
        
        # Save processed image to a buffer
        buffer = io.BytesIO()
        processed_img.save(buffer, format='JPEG', quality=85)
        image_content = ContentFile(buffer.getvalue(), name=f"alert_{device.device_id}_{int(timezone.now().timestamp())}.jpg")
        
        # Create Alert
        alert = Alert.objects.create(
            device=device,
            title="Motion Detected",
            severity="critical",
            message=f"PIR Sensor triggered at {device.name}",
            snapshot=image_content
        )
        
        # Trigger Targeted FCM Notifications
        send_targeted_notifications(device, alert)
        
        response_data['detail'] = 'Alert recorded and notifications sent.'
        return Response(response_data, status=status.HTTP_201_CREATED)

    return Response(response_data, status=status.HTTP_200_OK)

def send_targeted_notifications(device, alert):
    """
    Sends FCM notifications to all tokens associated with the owner and managers.
    """
    # Fetch all relevant users (Owner + Shared users)
    recipient_users = [device.owner]
    access_logs = DeviceAccess.objects.filter(device=device)
    for access in access_logs:
        recipient_users.append(access.identity)
        
    # Fetch FCM Tokens
    tokens = list(UserFCMToken.objects.filter(user__in=recipient_users).values_list('token', flat=True))
    
    if tokens and firebase_admin._apps:
        try:
            # Construct and send Multicast message
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=f"🚨 SECURITY ALERT: {alert.title}",
                    body=f"Detected at {device.name}",
                ),
                tokens=tokens,
                data={
                    'alert_id': str(alert.id),
                    'device_id': device.device_id,
                }
            )
            response = messaging.send_multicast(message)
            print(f"Successfully sent {response.success_count} notifications.")
        except Exception as e:
            print(f"Failed to send targeted notifications: {e}")

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def request_unlock(request, pk):
    device = get_object_or_404(Device, pk=pk)
    user = request.user
    role = 'viewer'
    
    if device.owner == user:
        role = 'owner'
    else:
        try:
            access = DeviceAccess.objects.get(device=device, identity=user)
            role = access.role
        except DeviceAccess.DoesNotExist:
            pass
 
    if role == 'manager' or role == 'viewer':
        return Response({'detail': 'Your role does not permit unlocking this device. Only Admins can unlock.'}, status=status.HTTP_403_FORBIDDEN)
        
    # Generate OTP
    code = f"{random.randint(100000, 999999)}"
    UnlockOTP.objects.create(identity=user, device=device, code=code)
    
    send_mail(
        subject="Your Safe Unlock Code",
        message=f"Your one-time passcode to unlock {device.name} is: {code}. It expires in 5 minutes.",
        from_email="no-reply@suraksha.com",
        recipient_list=[user.email],
    )
    
    return Response({'detail': 'OTP sent to your email.'}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def execute_unlock(request, pk):
    device = get_object_or_404(Device, pk=pk)
    code = request.data.get('code')
    
    if not code:
        return Response({'detail': 'OTP code is required.'}, status=status.HTTP_400_BAD_REQUEST)
        
    otp = UnlockOTP.objects.filter(identity=request.user, device=device, code=code).order_by('-created_at').first()
    if not otp or not otp.is_valid():
        return Response({'detail': 'Invalid or expired OTP code.'}, status=status.HTTP_403_FORBIDDEN)
        
    # Proceed to unlock the device physically (Trigger hardware or log event)
    otp.is_used = True
    otp.save()
    
    return Response({'detail': 'Safe successfully unlocked!'}, status=status.HTTP_200_OK)
