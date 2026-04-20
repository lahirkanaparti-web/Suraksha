from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone

class Device(models.Model):

    name = models.CharField(max_length=100)
    device_id = models.CharField(max_length=100, unique=True)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_devices')

    status = models.CharField(
        max_length=20,
        default="offline"
    )

    # Security & Tracking
    security_token = models.CharField(max_length=64, unique=True, null=True, blank=True)
    last_seen = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.security_token:
            import secrets
            self.security_token = secrets.token_hex(16) # 32 chars
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class DeviceAccess(models.Model):
    ROLE_CHOICES = [
        ('user', 'User Mapping (Manage & Unlock)'), 
        ('manager', 'Manager Mapping (View Only)'),   
    ]
    identity = models.ForeignKey(User, on_delete=models.CASCADE)
    device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name='access_logs')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='manager')
    
    class Meta:
        unique_together = ('identity', 'device')

class UnlockOTP(models.Model):
    identity = models.ForeignKey(User, on_delete=models.CASCADE)
    device = models.ForeignKey(Device, on_delete=models.CASCADE)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)
    
    def is_valid(self):
        # Expires instantly if used, or naturally within 5 minutes
        return not self.is_used and (timezone.now() - self.created_at).total_seconds() < 300