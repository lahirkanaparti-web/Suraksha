from django.urls import path
from .views import firebase_login, register_fcm_token

urlpatterns = [
    path("login/", firebase_login),
    path("register-fcm/", register_fcm_token),
]