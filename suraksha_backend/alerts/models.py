from django.db import models
from devices.models import Device
from django.db.models.signals import post_save
from django.dispatch import receiver
import firebase_admin
from firebase_admin import messaging

class Alert(models.Model):

    SEVERITY_CHOICES = [
        ('info', 'Information'),
        ('warning', 'Warning'),
        ('critical', 'Critical'),
        ('success', 'Success'),
    ]

    device = models.ForeignKey(Device, on_delete=models.CASCADE)
    
    title = models.CharField(max_length=150, default="Locker Alert")
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='info')
    
    message = models.CharField(max_length=255) # used as description
    
    # Store snapshots from the inside camera
    snapshot = models.ImageField(upload_to='alert_snapshots/', null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    resolved = models.BooleanField(default=False)

    def __str__(self):
        return f"[{self.severity.upper()}] {self.title} - {self.device.name}"

@receiver(post_save, sender=Alert)
def send_alert_push_notification(sender, instance, created, **kwargs):
    if created and instance.severity == 'critical':
        try:
            if firebase_admin._apps:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=f"🚨 SECURITY ALERT: {instance.title}",
                        body=f"Detected at {instance.device.name}",
                    ),
                    topic='alerts'
                )
                messaging.send(message)
                print("Push notification sent via FCM!")
        except Exception as e:
            print(f"Failed to send Push Notification: {e}")