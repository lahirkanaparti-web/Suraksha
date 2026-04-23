import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> initialDevice;

  const DeviceDetailScreen({super.key, required this.initialDevice});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _deviceData;

  bool _requestingOtp = false;
  bool _codeSent = false;
  String _otp = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    final data = await ApiService.fetchDeviceDetails(widget.initialDevice['id']);
    if (mounted) {
      setState(() {
        _deviceData = data;
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoCard() {
    final owner = _deviceData!['owner_info'];
    final managers = _deviceData!['managers'] as List<dynamic>? ?? [];

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: ExpansionTile(
        title: const Text("Ownership Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: const Icon(Icons.verified_user_rounded, color: Color(0xFF00E5FF)),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow("Hardware ID", _deviceData!['device_id'] ?? "-"),
                _infoRow("Primary Owner", "${owner['first_name']} ${owner['last_name']} (${owner['email']})"),
                const Divider(color: Colors.white12, height: 32),
                const Text("Authorized Managers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                if (managers.isEmpty) const Text("No guest managers assigned", style: TextStyle(color: Colors.white30, fontSize: 12)),
                ...managers.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 14, color: Colors.white38),
                      const SizedBox(width: 8),
                      Text("${m['first_name']} ${m['last_name']}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )).toList()
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38, letterSpacing: 1.1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCameraCard(String type, String title, IconData icon, Color color) {
    final cameras = _deviceData!['cameras'] as List<dynamic>? ?? [];
    final cam = cameras.cast<Map<String,dynamic>>().firstWhere(
      (c) => c['camera_type'] == type, 
      orElse: () => {}
    );

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: Icon(icon, color: color),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: cam.isNotEmpty 
              ? Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white10, size: 48)),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                                child: const Text("LIVE SIMULATION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text("Endpoint: ${cam['stream_url']}", style: const TextStyle(fontSize: 11, color: Colors.white30, fontFamily: 'monospace')),
                  ],
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("Camera configuration missing", style: TextStyle(color: Colors.white24)),
                ),
          )
        ],
      ),
    );
  }

  Widget _buildOpenDeviceCard() {
    final role = _deviceData!['my_role'] ?? 'viewer';
    final hasAccess = role == 'owner' || role == 'user';

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.greenAccent.withOpacity(0.2))),
      child: ExpansionTile(
        title: const Text("Remote Override", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: const Icon(Icons.key_rounded, color: Colors.greenAccent),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: !hasAccess 
              ? const Text("Permission Denied: Only Owners and Users can trigger remote overrides.", style: TextStyle(color: Colors.white38, fontSize: 13))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_codeSent) ...[
                      const Text("To unlock this locker remotely, you must first request a temporary 6-digit passcode.", style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent, 
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: _requestingOtp ? null : () async {
                          setState(() => _requestingOtp = true);
                          bool success = await ApiService.requestUnlock(_deviceData!['id']);
                          if (success) {
                            setState(() { _requestingOtp = false; _codeSent = true; });
                          } else {
                            setState(() => _requestingOtp = false);
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to request OTP. Check backend logs.")));
                          }
                        },
                        child: _requestingOtp ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("REQUEST PASSCODE", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ] else ...[
                      const Text("Passcode sent to your authorized endpoint.", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        onChanged: (val) => _otp = val,
                        decoration: InputDecoration(
                          hintText: "000000",
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, 
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        onPressed: _requestingOtp ? null : () async {
                          if (_otp.length != 6) return;
                          setState(() => _requestingOtp = true);
                          bool success = await ApiService.executeUnlock(_deviceData!['id'], _otp);
                          setState(() => _requestingOtp = false);
                          if (success) {
                            setState(() { _codeSent = false; _otp = ""; });
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ System Unlocked!"), backgroundColor: Colors.green));
                          } else {
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Passcode")));
                          }
                        },
                        child: _requestingOtp ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("EXECUTE UNLOCK", style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
          )
        ],
      ),
    );
  }

  Widget _buildDoorLogsCard() {
    final logs = _deviceData!['door_logs'] as List<dynamic>? ?? [];

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: ExpansionTile(
        title: const Text("Face Recognition History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: const Icon(Icons.face_retouching_natural_rounded, color: Colors.blueAccent),
        children: [
          if (logs.isEmpty)
             const Padding(padding: EdgeInsets.all(24), child: Text("No face detection events recorded yet.", style: TextStyle(color: Colors.white24, fontSize: 13)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                bool isGranted = log['access_status'] == 'granted';
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: isGranted ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                    child: Icon(isGranted ? Icons.check : Icons.close, size: 14, color: isGranted ? Colors.greenAccent : Colors.redAccent),
                  ),
                  title: Text(isGranted ? "Access Granted" : "Unknown Person", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: Text("${(log['confidence'] * 100).toStringAsFixed(1)}% Confidence", style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  trailing: log['snapshot'] != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(log['snapshot'], width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 14)),
                      )
                    : null,
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    final alerts = _deviceData!['alerts'] as List<dynamic>? ?? [];

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: ExpansionTile(
        title: const Text("Security Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
        children: [
          alerts.isEmpty 
            ? const Padding(padding: EdgeInsets.all(24), child: Text("System healthy. No active alerts.", style: TextStyle(color: Colors.white24, fontSize: 13)))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  Color color = alert['severity'] == 'critical' ? Colors.redAccent : Colors.orangeAccent;
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.circle, size: 8, color: color),
                    title: Text(alert['title'] ?? 'Alert', style: const TextStyle(fontSize: 13)),
                    subtitle: Text(alert['description'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  );
                },
              )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialDevice['name'] ?? "Device Details", style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : _deviceData == null 
            ? const Center(child: Text("Connection error. Please try again."))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF00E5FF),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _buildInfoCard(),
                    _buildCameraCard("OUTSIDE", "Entry Point Camera", Icons.camera_outdoor_rounded, Colors.cyanAccent),
                    _buildCameraCard("INSIDE", "Internal Security Cam", Icons.camera_indoor_rounded, Colors.purpleAccent),
                    _buildOpenDeviceCard(),
                    _buildDoorLogsCard(),
                    _buildAlertsCard(),
                  ],
                ),
              ),
    );
  }
}
