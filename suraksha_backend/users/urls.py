from django.urls import path
from .views import firebase_login

urlpatterns = [
    path("login/", firebase_login),
]