import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  void _showAddDeviceModal(BuildContext context) {
    String deviceName = "";
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Add Secure Locker",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                onChanged: (val) => deviceName = val,
                decoration: InputDecoration(
                  labelText: "Locker Name (e.g. Vault Door)",
                  filled: true,
                  fillColor: Colors.black12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (deviceName.trim().isEmpty) return;
                  
                  // Dismiss modal
                  Navigator.pop(context);
                  
                  // Post to Django API securely
                  final success = await ApiService.addDevice(deviceName, "Camera");
                  
                  if (success) {
                    // Force refresh to pull down the newly committed device across the app
                    context.read<AppStateProvider>().syncBackend();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to save device online."))
                    );
                  }
                },
                child: const Text("Deploy Device", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    // Watch shared state devices
    final devices = context.watch<AppStateProvider>().devices;
    final isLoading = context.watch<AppStateProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Locker Cameras", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      drawer: const AppDrawer(),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isOnline = device['status'] == "Online";
              final role = device['my_role'] ?? 'viewer';
              
              IconData icon;
              switch (device['type']) {
                case 'Camera':
                  icon = Icons.videocam;
                  break;
                default:
                  icon = Icons.videocam;
              }

              return Card(
                color: const Color(0xFF1E1E24),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => DeviceDetailScreen(initialDevice: device),
                       ),
                     );
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOnline ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isOnline ? Theme.of(context).primaryColor : Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      device['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "Role: ${role.toString().toUpperCase()}",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: isOnline ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device['status']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDeviceModal(context),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Add Device", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
