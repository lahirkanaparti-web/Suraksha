from rest_framework import serializers
from .models import Alert

class AlertSerializer(serializers.ModelSerializer):
    locker = serializers.CharField(source='device.name', read_only=True)
    time = serializers.DateTimeField(source='created_at', read_only=True)
    description = serializers.CharField(source='message', read_only=True)
    hasImage = serializers.SerializerMethodField()

    class Meta:
        model = Alert
        fields = ['id', 'title', 'locker', 'time', 'severity', 'description', 'hasImage', 'snapshot']

    def get_hasImage(self, obj):
        return bool(obj.snapshot)
