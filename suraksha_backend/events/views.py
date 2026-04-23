from rest_framework import generics, permissions
from django.db.models import Q
from .models import AccessLog
from .serializers import AccessLogSerializer

class AccessLogListView(generics.ListAPIView):
    """
    Returns the history of face detection events for devices the user owns or manages.
    """
    serializer_class = AccessLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Return logs for devices where the user is either the owner or has shared access
        return AccessLog.objects.filter(
            Q(device__owner=user) | Q(device__access_logs__identity=user)
        ).distinct().order_by('-timestamp')
