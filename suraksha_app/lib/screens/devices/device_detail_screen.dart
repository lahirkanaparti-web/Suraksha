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
    setState(() => _isLoading = true);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: const Text("Info", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoRow("Device ID", _deviceData!['device_id'] ?? "-"),
                _infoRow("Owner", "${owner['first_name']} ${owner['last_name']} (${owner['email']})"),
                const SizedBox(height: 8),
                const Text("Managers:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                if (managers.isEmpty) const Text("No managers assigned", style: TextStyle(color: Colors.white54)),
                ...managers.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text("- ${m['first_name']} ${m['last_name']} (${m['email']})", style: const TextStyle(color: Colors.white70)),
                )).toList()
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
          children: [
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.white))
          ]
        ),
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: Icon(icon, color: color),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: cam.isNotEmpty 
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Center(child: Text("Streaming from:\n${cam['stream_url']}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38))),
                )
              : const Text("Not Configured", style: TextStyle(color: Colors.white54)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: const Text("Open Device", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.lock_open, color: Colors.greenAccent),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: !hasAccess 
              ? const Text("Access Denied: You do not have permission to physically alter this system.", style: TextStyle(color: Colors.redAccent))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_codeSent) ...[
                      const Text("Executing an override requires an OTP validation.", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, 
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: _requestingOtp ? null : () async {
                          setState(() => _requestingOtp = true);
                          bool success = await ApiService.requestUnlock(_deviceData!['id']);
                          if (success) {
                            setState(() { _requestingOtp = false; _codeSent = true; });
                          } else {
                            setState(() => _requestingOtp = false);
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to request OTP.")));
                          }
                        },
                        child: _requestingOtp ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black)) : const Text("Request Passcode"),
                      )
                    ] else ...[
                      TextField(
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (val) => _otp = val,
                        decoration: InputDecoration(
                          labelText: "Enter 6-Digit OTP",
                          filled: true,
                          fillColor: Colors.black12,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent, 
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: _requestingOtp ? null : () async {
                          if (_otp.length != 6) return;
                          setState(() => _requestingOtp = true);
                          bool success = await ApiService.executeUnlock(_deviceData!['id'], _otp);
                          setState(() => _requestingOtp = false);
                          if (success) {
                            setState(() { _codeSent = false; _otp = ""; });
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ System Unlocked successfully!"), backgroundColor: Colors.green));
                          } else {
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid or expired OTP.")));
                          }
                        },
                        child: _requestingOtp ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black)) : const Text("Execute Override"),
                      )
                    ]
                  ],
                ),
          )
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    final alerts = _deviceData!['alerts'] as List<dynamic>? ?? [];

    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: const Text("Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
        children: [
          alerts.isEmpty 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No recent alerts found for this device.", style: TextStyle(color: Colors.white54)),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alerts.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  Color severityColor = Colors.grey;
                  if (alert['severity'] == 'critical') severityColor = Colors.redAccent;
                  if (alert['severity'] == 'warning') severityColor = Colors.orangeAccent;
                  if (alert['severity'] == 'success') severityColor = Colors.greenAccent;
                  if (alert['severity'] == 'info') severityColor = Colors.blueAccent;
                  
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: severityColor.withOpacity(0.2), child: Icon(Icons.notifications, color: severityColor, size: 16)),
                    title: Text(alert['title'] ?? 'Alert', style: const TextStyle(fontSize: 14)),
                    subtitle: Text(alert['description'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white54)),
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
        title: Text(widget.initialDevice['name'] ?? "Device Details"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
        : _deviceData == null 
            ? const Center(child: Text("Error loading device details."))
            : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF00E5FF),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoCard(),
                    _buildCameraCard("OUTSIDE", "Outside Cam", Icons.camera_outdoor, Colors.cyan),
                    _buildCameraCard("INSIDE", "Inside Cam", Icons.camera_indoor, Colors.purpleAccent),
                    _buildOpenDeviceCard(),
                    _buildAlertsCard(),
                  ],
                ),
              ),
    );
  }
}
