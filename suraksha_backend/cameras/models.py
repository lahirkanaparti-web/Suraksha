from django.db import models
from devices.models import Device

class Camera(models.Model):

    CAMERA_TYPES = [
        ("OUTSIDE", "Face Detection Camera"),
        ("INSIDE", "Safe Interior Camera")
    ]

    device = models.ForeignKey(Device, on_delete=models.CASCADE)

    camera_type = models.CharField(
        max_length=10,
        choices=CAMERA_TYPES
    )

    stream_url = models.URLField()

    active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.device.name} - {self.camera_type}"