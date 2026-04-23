from django.contrib import admin
from .models import SafeEvent, AccessLog

admin.site.register(SafeEvent)
admin.site.register(AccessLog)