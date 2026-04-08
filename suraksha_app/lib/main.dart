import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Setup FCM Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const SurakshaApp(),
    ),
  );

  // Defer native Notification dialogues so they don't block the UI loading.
  Future.microtask(() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Force initialization and get token before subscribing to topics
      // This prevents the 'SERVICE_NOT_AVAILABLE' error
      final token = await messaging.getToken();
      debugPrint("FCM Token: $token");
      
      await messaging.subscribeToTopic('alerts');
      debugPrint("Successfully subscribed to alerts topic.");
    } catch (e) {
      debugPrint("FCM Init Error: $e");
    }
  });
}

class SurakshaApp extends StatelessWidget {
  const SurakshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suraksha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0E),
        primaryColor: const Color(0xFF00E5FF), // Electric Teal
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00E5FF),
          secondary: const Color(0xFF00E5FF),
          surface: const Color(0xFF1E1E24),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0E),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isAuthenticatingWithBackend = false;

  Future<void> _authenticateWithBackend(User user) async {
    try {
      final idToken = await user.getIdToken();
      if (idToken != null) {
        final success = await ApiService.login(idToken);
        if (mounted) {
          setState(() {
            _isAuthenticatingWithBackend = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Backend auth execution error: $e");
      if (mounted) {
        setState(() {
          _isAuthenticatingWithBackend = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }
        
        final user = snapshot.data;
        if (user != null) {
          if (ApiService.isAuthenticated) {
            return const DashboardScreen();
          } else if (!_isAuthenticatingWithBackend) {
            _isAuthenticatingWithBackend = true;
            // Schedule the async call
            Future.microtask(() => _authenticateWithBackend(user));
          }
          // Show loading while we authenticate with Django
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
          );
        }

        return const LoginScreen();
      },
    );
  }
}