from django.urls import path
from .views import AccessLogListView

urlpatterns = [
    path('access-logs/', AccessLogListView.as_view(), name='access-log-list'),
]
