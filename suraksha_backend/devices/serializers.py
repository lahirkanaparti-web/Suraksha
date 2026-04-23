from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Device, DeviceAccess
from cameras.serializers import CameraSerializer
from alerts.serializers import AlertSerializer
import uuid

class UserSimpleSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

class DeviceSerializer(serializers.ModelSerializer):
    type = serializers.SerializerMethodField()
    my_role = serializers.SerializerMethodField()

    class Meta:
        model = Device
        fields = ['id', 'name', 'device_id', 'status', 'type', 'created_at', 'my_role']
        read_only_fields = ['id', 'device_id', 'status', 'created_at', 'my_role']

    def get_type(self, obj):
        return "Camera"
        
    def get_my_role(self, obj):
        request = self.context.get('request')
        if not request or request.user.is_anonymous:
            return 'viewer'
            
        # The Master Owner has supreme 'owner' powers
        if obj.owner == request.user:
            return 'owner'
            
        # Shadow fallback lookup in the DeviceAccess junction table
        try:
            access = DeviceAccess.objects.get(device=obj, identity=request.user)
            return access.role
        except DeviceAccess.DoesNotExist:
            return 'viewer'

    def create(self, validated_data):
        # Generate a unique device ID if one isn't provided
        if 'device_id' not in validated_data:
            validated_data['device_id'] = str(uuid.uuid4())
        return super().create(validated_data)

class DeviceDetailSerializer(DeviceSerializer):
    owner_info = UserSimpleSerializer(source='owner', read_only=True)
    managers = serializers.SerializerMethodField()
    cameras = serializers.SerializerMethodField()
    alerts = serializers.SerializerMethodField()
    door_logs = serializers.SerializerMethodField()

    class Meta(DeviceSerializer.Meta):
        fields = DeviceSerializer.Meta.fields + ['owner_info', 'managers', 'cameras', 'alerts', 'door_logs']

    def get_managers(self, obj):
        access_logs = obj.access_logs.filter(role='manager')
        managers = [access.identity for access in access_logs]
        return UserSimpleSerializer(managers, many=True).data

    def get_cameras(self, obj):
        # We assume the related name is 'camera_set' by default since no related_name was explicitly set
        cameras = obj.camera_set.all()
        return CameraSerializer(cameras, many=True).data

    def get_alerts(self, obj):
        alerts = obj.alert_set.all().order_by('-created_at')[:20]  # Only return the recent 20 alerts
        return AlertSerializer(alerts, many=True).data

    def get_door_logs(self, obj):
        from events.serializers import AccessLogSerializer
        logs = obj.door_access_logs.all().order_by('-timestamp')[:20]
        return AccessLogSerializer(logs, many=True).data
