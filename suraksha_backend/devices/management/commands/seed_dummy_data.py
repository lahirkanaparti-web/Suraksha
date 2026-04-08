from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from devices.models import Device
from alerts.models import Alert
import uuid

class Command(BaseCommand):
    help = 'Seeds the database with dummy data matching the Flutter app state'

    def handle(self, *args, **options):
        # 1. Provide Context User
        user, created = User.objects.get_or_create(
            username='dummy_user',
            defaults={'email': 'lahir@gmail.com'}
        )
        if created:
            user.set_password('password123')
            user.save()
            self.stdout.write(self.style.SUCCESS('Created dummy user.'))

        # Clear existing data
        Device.objects.filter(owner=user).delete()
        
        self.stdout.write('Seeding Devices...')
        d1 = Device.objects.create(name="Locker #1 - Inside", device_id=str(uuid.uuid4()), owner=user, status="Online")
        d2 = Device.objects.create(name="Locker #1 - Outside", device_id=str(uuid.uuid4()), owner=user, status="Online")
        d3 = Device.objects.create(name="Locker #2 - Inside", device_id=str(uuid.uuid4()), owner=user, status="Offline")
        d4 = Device.objects.create(name="Locker #2 - Outside", device_id=str(uuid.uuid4()), owner=user, status="Online")

        self.stdout.write('Seeding Alerts...')
        Alert.objects.create(
            device=d1,
            title="Failed Access Attempt",
            severity="critical",
            message="3 incorrect passcode attempts."
        )
        Alert.objects.create(
            device=d3,
            title="Locker Opened",
            severity="info",
            message="Authorized entry via keypad."
        )
        Alert.objects.create(
            device=d1,
            title="Extended Open Warning",
            severity="warning",
            message="Locker door left open for over 5 minutes."
        )

        self.stdout.write(self.style.SUCCESS('Successfully seeded dummy data!'))
