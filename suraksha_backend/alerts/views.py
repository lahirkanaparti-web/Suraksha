from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import Alert
from .serializers import AlertSerializer

class AlertListView(generics.ListAPIView):
    serializer_class = AlertSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Return alerts belonging to devices owned by the authenticated user
        return Alert.objects.filter(device__owner=self.request.user).order_by('-created_at')
