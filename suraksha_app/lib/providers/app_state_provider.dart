import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';

class AppStateProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _accessLogs = [];
  bool isLoading = false;

  List<Map<String, dynamic>> get devices => _devices;
  List<Map<String, dynamic>> get alerts => _alerts;
  List<Map<String, dynamic>> get accessLogs => _accessLogs;

  // Sync data from Django Backend
  Future<void> syncBackend() async {
    isLoading = true;
    notifyListeners();

    try {
      // If hot restarted/token expired, re-authenticate
      if (!ApiService.isAuthenticated) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          if (token != null) {
            await ApiService.login(token);
            
            // Immediately register the current device's FCM token with Django
            final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              await ApiService.registerFCMToken(fcmToken);
            }
          }
        }
      }

      final fetchedDevices = await ApiService.fetchDevices();
      final fetchedAlerts = await ApiService.fetchAlerts();
      final fetchedAccessLogs = await ApiService.fetchAccessLogs();

      // Convert dynamic list to Map<String, dynamic>
      _devices = fetchedDevices.map((d) => Map<String, dynamic>.from(d)).toList();
      _alerts = fetchedAlerts.map((a) => Map<String, dynamic>.from(a)).toList();
      _accessLogs = fetchedAccessLogs.map((l) => Map<String, dynamic>.from(l)).toList();
    } catch (e) {
      debugPrint("Error syncing backend: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void addDummyDevice() {
    // Scaffold functionality disabled since we are connected to Django natively
    // We would eventually call API post to update Django database here
    debugPrint("Add Dummy Device is disabled in Live DB Mode. Use Post endpoint to add explicitly.");
  }
}
