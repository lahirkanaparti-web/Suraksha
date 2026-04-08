import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const String baseUrl = "http://10.0.2.2:8000/api";
  
  // Store the Django REST Token in memory for session
  static String? _authToken;

  // Check if we already have the Django token cached
  static bool get isAuthenticated => _authToken != null;

  /// Send Firebase JWT to Django to get authenticated and retrieve DRF Token
  static Future<bool> login(String firebaseToken) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login/"), // Matches Django's users/urls.py
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "idToken": firebaseToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        debugPrint("Successfully authenticated with Django. Token: $_authToken");
        return true;
      } else {
        debugPrint("Django Auth Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("API Service Error: $e");
      return false;
    }
  }

  static void logout() {
    _authToken = null;
    debugPrint("Cleared Django DRF Authentication Token.");
  }

  /// Helper to get authenticated headers for future API calls
  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_authToken != null) "Authorization": "Token $_authToken",
    };
  }

  static Future<List<dynamic>> fetchDevices() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/devices/"), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Fetch Devices Failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Fetch Devices Error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchDeviceDetails(int deviceId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/devices/$deviceId/"), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Fetch Device Details Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Fetch Device Details Error: $e");
      return null;
    }
  }

  static Future<List<dynamic>> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/alerts/"), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Fetch Alerts Failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Fetch Alerts Error: $e");
      return [];
    }
  }
  
  static Future<bool> addDevice(String name, String type) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/devices/"), 
        headers: headers,
        body: jsonEncode({
          "name": name,
          "type": type // Ignored by backend natively but provides schema flexibility
        })
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint("Add Device Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Add Device Error: $e");
      return false;
    }
  }
  
  static Future<bool> requestUnlock(int deviceId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/devices/$deviceId/request_unlock/"), 
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Request Unlock Error: $e");
      return false;
    }
  }

  static Future<bool> executeUnlock(int deviceId, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/devices/$deviceId/execute_unlock/"), 
        headers: headers,
        body: jsonEncode({"code": otp})
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Execute Unlock Error: $e");
      return false;
    }
  }
}