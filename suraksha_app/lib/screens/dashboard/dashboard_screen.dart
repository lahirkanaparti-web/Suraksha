import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/app_state_provider.dart';
import '../devices/device_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch real data from Django when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().syncBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch state
    final state = context.watch<AppStateProvider>();
    final activeDevices = state.devices;
    final recentAlerts = state.alerts.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              // Force manual refresh
              context.read<AppStateProvider>().syncBackend();
            },
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemStatusCard(context),
                const SizedBox(height: 32),
                const Text(
                  "Locker Devices",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDevicesHorizontalList(activeDevices),
                const SizedBox(height: 32),
                const Text(
                  "Recent Events",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildRecentEventsSnippet(recentAlerts),
              ],
            ),
          ),
    );
  }

  Widget _buildSystemStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Theme.of(context).primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SYSTEM SECURE",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "All lock systems nominal",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDevicesHorizontalList(List<Map<String, dynamic>> devices) {
    if (devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text("No devices active...", style: TextStyle(color: Colors.white60)),
      );
    }
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final isOnline = device['status'] == 'Online';
          
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeviceDetailScreen(initialDevice: device),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isOnline ? Theme.of(context).primaryColor.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam, 
                    color: isOnline ? Theme.of(context).primaryColor : Colors.redAccent,
                    size: 28,
                  ),
                  const Spacer(),
                  Text(
                    device['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle, color: isOnline ? Colors.greenAccent : Colors.redAccent, size: 10),
                      const SizedBox(width: 6),
                      Text(
                        device['status'],
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentEventsSnippet(List<Map<String, dynamic>> alerts) {
    if (alerts.isEmpty) {
      return const Text("No recent events...", style: TextStyle(color: Colors.white60));
    }
    return Column(
      children: alerts.map((alert) {
        // Parse time to local string or fallback
        String displayTime = alert['time'].toString();
        if (displayTime.length > 10) {
          try {
             DateTime dt = DateTime.parse(displayTime).toLocal();
             displayTime = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
          } catch(e) {}
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: alert['severity'] == 'critical' 
                ? Colors.redAccent.withOpacity(0.2) 
                : Colors.white10,
              child: Icon(
                alert['severity'] == 'critical' ? Icons.gpp_bad : Icons.lock_outline, 
                color: alert['severity'] == 'critical' ? Colors.redAccent : Colors.white70
              ),
            ),
            title: Text(alert['title']),
            subtitle: Text("${alert['locker']} • $displayTime", style: TextStyle(color: Colors.white.withOpacity(0.5))),
            trailing: const Icon(Icons.chevron_right, color: Colors.white30),
          ),
        );
      }).toList(),
    );
  }
}