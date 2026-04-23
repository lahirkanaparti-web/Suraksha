from rest_framework import serializers
from .models import AccessLog

class AccessLogSerializer(serializers.ModelSerializer):
    device_name = serializers.ReadOnlyField(source='device.name')

    class ImageUrlField(serializers.ImageField):
        def to_representation(self, value):
            if not value:
                return None
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(value.url)
            return value.url

    snapshot = ImageUrlField()

    class Meta:
        model = AccessLog
        fields = [
            'id', 
            'device', 
            'device_name', 
            'access_status', 
            'confidence', 
            'snapshot', 
            'timestamp'
        ]
