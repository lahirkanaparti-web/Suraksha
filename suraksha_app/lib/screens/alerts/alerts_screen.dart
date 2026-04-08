import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch shared state alerts
    final alerts = context.watch<AppStateProvider>().alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Locker Activity", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filter Logs",
            onPressed: () {},
          )
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          
          IconData icon;
          Color color;
          
          switch (alert['severity']) {
            case 'critical':
              icon = Icons.gpp_bad_rounded;
              color = Colors.redAccent;
              break;
            case 'warning':
              icon = Icons.warning_amber_rounded;
              color = Colors.orangeAccent;
              break;
            default:
              icon = Icons.lock_open_rounded;
              color = Theme.of(context).primaryColor;
          }

          String displayTime = alert['time'].toString();
          if (displayTime.length > 10) {
            try {
               DateTime dt = DateTime.parse(displayTime).toLocal();
               displayTime = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
            } catch(e) {}
          }

          return Card(
            color: const Color(0xFF1E1E24),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert['title'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert['locker'].toString(),
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        displayTime,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    alert['description'].toString(),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  if (alert['hasImage'] == true) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              alert['snapshot'].toString().startsWith('http') 
                                  ? alert['snapshot']
                                  : ApiService.baseUrl.replaceAll('/api', '') + alert['snapshot'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 40));
                              },
                            ),
                            Container( // Dark vignette for reading text easily overlaying it
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: Row(
                                children: [
                                  const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Inside Camera Snapshot",
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}