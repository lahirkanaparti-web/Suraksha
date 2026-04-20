from django.urls import path
from .views import DeviceListView, DeviceDetailView, request_unlock, execute_unlock, device_ping

urlpatterns = [
    path('', DeviceListView.as_view(), name='device-list'),
    path('ping/', device_ping, name='device-ping'),
    path('<int:pk>/', DeviceDetailView.as_view(), name='device-detail'),
    path('<int:pk>/request_unlock/', request_unlock, name='device-request-unlock'),
    path('<int:pk>/execute_unlock/', execute_unlock, name='device-execute-unlock'),
]
