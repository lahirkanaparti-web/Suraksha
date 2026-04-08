from django.urls import path
from .views import DeviceListView, DeviceDetailView, request_unlock, execute_unlock

urlpatterns = [
    path('', DeviceListView.as_view(), name='device-list'),
    path('<int:pk>/', DeviceDetailView.as_view(), name='device-detail'),
    path('<int:pk>/request_unlock/', request_unlock, name='device-request-unlock'),
    path('<int:pk>/execute_unlock/', execute_unlock, name='device-execute-unlock'),
]
