from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.core.mail import send_mail
from .models import Device, DeviceAccess, UnlockOTP
from .serializers import DeviceSerializer, DeviceDetailSerializer
import random

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
