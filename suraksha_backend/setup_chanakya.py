import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User
from devices.models import Device, DeviceAccess

def run():
    email = "lahirchowdary31@gmail.com"
    username = email.split('@')[0]

    user, created = User.objects.get_or_create(username=username, defaults={'email': email})
    print(f"User {email} ensured in DB.")

    inside = Device.objects.filter(name__icontains="Inside").first()
    outside = Device.objects.filter(name__icontains="Outside").first()

    if inside:
        acc, _ = DeviceAccess.objects.get_or_create(identity=user, device=inside, defaults={'role': 'manager'})
        acc.role = 'manager'
        acc.save()
        print(f"Mapped {email} to {inside.name} as Manager")
    else:
        print("Could not find a device named Inside!")

    if outside:
        acc, _ = DeviceAccess.objects.get_or_create(identity=user, device=outside, defaults={'role': 'manager'})
        acc.role = 'manager'
        acc.save()
        print(f"Mapped {email} to {outside.name} as Manager")
    else:
        print("Could not find a device named Outside!")

if __name__ == '__main__':
    run()
