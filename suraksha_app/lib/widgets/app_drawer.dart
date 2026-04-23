import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/alerts/access_logs_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../services/api_service.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    String? email = FirebaseAuth.instance.currentUser?.email;
    final primaryColor = const Color(0xFF00E5FF);

    return Drawer(
      backgroundColor: const Color(0xFF0A0A0E), // Match deep background
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xFF14141B),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            accountName: const Text(
              "SURAKSHA ADMIN",
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
            ),
            accountEmail: Text(
              email ?? "admin@suraksha.sys",
              style: TextStyle(color: primaryColor.withOpacity(0.7), fontWeight: FontWeight.w600),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.shield_rounded, color: primaryColor, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DrawerItem(
            icon: Icons.grid_view_rounded,
            title: "Command Center",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            },
          ),
          _DrawerItem(
            icon: Icons.notifications_active_outlined,
            title: "Security Alerts",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            },
          ),
          _DrawerItem(
            icon: Icons.history_edu_rounded,
            title: "Access History",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccessLogsScreen()));
            },
          ),
          _DrawerItem(
            icon: Icons.videocam_outlined,
            title: "Active Lockers",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeviceListScreen()));
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white10),
          _DrawerItem(
            icon: Icons.power_settings_new_rounded,
            title: "Terminate Session",
            isDestructive: true,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              ApiService.logout(); 
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent.withOpacity(0.8) : Colors.white.withOpacity(0.7);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      onTap: onTap,
    );
  }
}
