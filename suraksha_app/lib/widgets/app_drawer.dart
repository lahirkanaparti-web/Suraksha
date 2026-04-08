import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../services/api_service.dart';
import '../main.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    String? email = FirebaseAuth.instance.currentUser?.email;

    return Drawer(
      backgroundColor: const Color(0xFF1E1E24), // Surface color
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0E), // Background color
            ),
            accountName: const Text(
              "Administrator",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            accountEmail: Text(
              email ?? "admin@suraksha.sys",
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).primaryColor,
                size: 32,
              ),
            ),
          ),
          _DrawerItem(
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            },
          ),
          _DrawerItem(
            icon: Icons.warning_amber_rounded,
            title: "Alerts Log",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            },
          ),
          _DrawerItem(
            icon: Icons.router_outlined,
            title: "Locker Cameras",
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeviceListScreen()));
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white12),
          _DrawerItem(
            icon: Icons.logout,
            title: "Sign Out",
            isDestructive: true,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              ApiService.logout(); // Clear internal Django Auth Token natively
              
              // Evict the app framework and aggressively restart the navigation route from AuthGate
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
    final color = isDestructive ? Colors.redAccent : Colors.white.withOpacity(0.8);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
