from django.db import models
from devices.models import Device

class SafeEvent(models.Model):

    EVENT_TYPES = [
        ("FACE_OK", "Authorized Face"),
        ("FACE_UNKNOWN", "Unknown Face"),
        ("PASSCODE_OK", "Passcode Accepted"),
        ("PASSCODE_FAIL", "Passcode Rejected"),
        ("SAFE_OPENED", "Safe Opened"),
        ("SAFE_CLOSED", "Safe Closed"),
        ("FORCED_ENTRY", "Forced Entry Detected")
    ]

    device = models.ForeignKey(Device, on_delete=models.CASCADE)

    event_type = models.CharField(
        max_length=20,
        choices=EVENT_TYPES
    )

    timestamp = models.DateTimeField(auto_now_add=True)

    description = models.TextField(blank=True)

    def __str__(self):
        return self.event_type

class AccessLog(models.Model):
    ACCESS_STATUS_CHOICES = [
        ("granted", "Access Granted"),
        ("denied", "Access Denied"),
    ]

    device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name="door_access_logs")
    access_status = models.CharField(max_length=10, choices=ACCESS_STATUS_CHOICES)
    confidence = models.FloatField(default=0.0)
    snapshot = models.ImageField(upload_to="access_logs/", null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.device.name} - {self.access_status} ({self.confidence})"