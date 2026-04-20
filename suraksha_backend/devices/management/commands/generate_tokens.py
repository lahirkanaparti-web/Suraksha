from django.core.management.base import BaseCommand
from devices.models import Device

class Command(BaseCommand):
    help = 'Generates and displays security tokens for all devices'

    def handle(self, *args, **options):
        devices = Device.objects.all()
        
        if not devices:
            self.stdout.write(self.style.WARNING("No devices found in the database."))
            return

        self.stdout.write(self.style.SUCCESS("\n--- Suraksha Device Security Tokens ---\n"))
        
        for device in devices:
            # The save() method of Device model auto-generates a token if it's missing
            if not device.security_token:
                device.save()
            
            self.stdout.write(f"Device Name: {device.name}")
            self.stdout.write(f"Device ID:   {device.device_id}")
            self.stdout.write(f"Token:       {device.security_token}")
            self.stdout.write("-" * 40)
            
        self.stdout.write(self.style.SUCCESS("\nCopy these tokens into your ESP32 configuration."))
