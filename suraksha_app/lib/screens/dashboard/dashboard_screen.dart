import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/app_state_provider.dart';
import '../devices/device_detail_screen.dart';
import '../alerts/alerts_screen.dart';
import '../alerts/access_logs_screen.dart';
import '../devices/device_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation for the security shield
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().syncBackend();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final activeDevices = state.devices;
    
    // Merge Alerts and AccessLogs into a single Unified Feed
    final List<Map<String, dynamic>> combinedActivity = [
      ...state.alerts.map((a) => {...a, 'type': 'alert'}),
      ...state.accessLogs.map((l) => {...l, 'type': 'access'}),
    ];
    
    // Sort by timestamp (descending)
    combinedActivity.sort((a, b) {
      DateTime timeA = DateTime.tryParse(a['time'] ?? a['timestamp'] ?? "") ?? DateTime(2000);
      DateTime timeB = DateTime.tryParse(b['time'] ?? b['timestamp'] ?? "") ?? DateTime(2000);
      return timeB.compareTo(timeA);
    });

    final recentActivity = combinedActivity.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Suraksha Home", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AppStateProvider>().syncBackend(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : RefreshIndicator(
            onRefresh: () => state.syncBackend(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemStatusCard(context),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _headerRow("Active Lockers", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceListScreen()))),
                  const SizedBox(height: 16),
                  _buildDevicesHorizontalList(activeDevices),
                  const SizedBox(height: 32),
                  _headerRow("Recent Activity", () {}), // Could link to a combined feed screen later
                  const SizedBox(height: 16),
                  _buildUnifiedActivityFeed(recentActivity),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _headerRow(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(onPressed: onSeeAll, child: const Text("See All", style: TextStyle(color: Color(0xFF00E5FF)))),
      ],
    );
  }

  Widget _buildSystemStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00E5FF).withOpacity(0.15), const Color(0xFF00E5FF).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: Color(0xFF00E5FF), size: 36),
            ),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SYSTEM SECURE",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              SizedBox(height: 4),
              Text(
                "Integrity Monitoring Active",
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _quickActionItem(context, Icons.history_rounded, "Door Logs", Colors.blueAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessLogsScreen()));
        }),
        _quickActionItem(context, Icons.notifications_none_rounded, "Alerts", Colors.orangeAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
        }),
        _quickActionItem(context, Icons.lock_open_rounded, "Override", Colors.greenAccent, () {
           // Direct to device selection or last active device
        }),
        _quickActionItem(context, Icons.settings_outlined, "Config", Colors.white30, () {}),
      ],
    );
  }

  Widget _quickActionItem(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesHorizontalList(List<Map<String, dynamic>> devices) {
    if (devices.isEmpty) return const Text("No active lockers.", style: TextStyle(color: Colors.white30));
    
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final isOnline = device['status'] == 'online';
          
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceDetailScreen(initialDevice: device))),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isOnline ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.door_front_door_rounded, color: isOnline ? const Color(0xFF00E5FF) : Colors.redAccent, size: 24),
                  const Spacer(),
                  Text(device['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                  Text(isOnline ? "Online" : "Offline", style: TextStyle(fontSize: 11, color: isOnline ? Colors.greenAccent : Colors.redAccent)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnifiedActivityFeed(List<Map<String, dynamic>> activity) {
    if (activity.isEmpty) return const Text("No recent activity.", style: TextStyle(color: Colors.white30));
    
    return Column(
      children: activity.map((item) {
        bool isAlert = item['type'] == 'alert';
        IconData icon = isAlert ? Icons.warning_amber_rounded : Icons.person_search_rounded;
        Color color = isAlert ? Colors.orangeAccent : Colors.blueAccent;
        String title = item['title'] ?? (item['access_status'] == 'granted' ? "Face Recognized" : "Unknown Person");
        String subtitle = isAlert ? (item['locker'] ?? "Motion Trigger") : (item['device_name'] ?? "Door Access");
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white38)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white24),
            onTap: () {
               // Future: Navigate to specific event detail or log list
            },
          ),
        );
      }).toList(),
    );
  }
}