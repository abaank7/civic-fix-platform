import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../config.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<dynamic> _myIssues = [];
  bool _isLoading = true;
  String _deviceId = "Fetching...";

  // Civic Contribution Stats
  int _totalReported = 0;
  int _resolvedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    try {
      // 1. Get the local Device ID
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final localDeviceId = androidInfo.id; 

      // 2. Fetch all issues 
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/v1/issues/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> allIssues = jsonDecode(response.body);
        
        // 3. Filter to only show issues submitted by THIS phone
        final myFilteredIssues = allIssues.where((issue) => issue['device_id'] == localDeviceId).toList();
        
        setState(() {
          _deviceId = localDeviceId;
          _myIssues = myFilteredIssues;
          
          // Calculate Stats
          _totalReported = myFilteredIssues.length;
          _resolvedCount = myFilteredIssues.where((i) => i['status'] == 'Resolved').length;
          _pendingCount = myFilteredIssues.where((i) => i['status'] != 'Resolved').length;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // --- UI Helpers ---
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved': return const Color(0xFF10B981);
      case 'In Progress': return const Color(0xFFF59E0B);
      default: return const Color(0xFF4B5563); // Dark Grey for Pending
    }
  }

  String _getTimeAgo(String timestamp) {
    DateTime parsedDate = DateTime.parse(timestamp).toLocal();
    Duration diff = DateTime.now().difference(parsedDate);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }

  // --- Profile Stat Builder (Dark Mode Optimized) ---
  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Deep Dark Background
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF6B4EFF),
          backgroundColor: const Color(0xFF1F1F22),
          onRefresh: _fetchMyReports,
          child: Column(
            children: [
              
              // --- PROFILE HEADER ---
              Container(
                color: const Color(0xFF09090B), // Matches Scaffold
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Sleek Dark Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F22),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2A2A2A), width: 2),
                          ),
                          child: const Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Changed "Reported" to White for Dark Mode
                              _buildStatColumn("Reported", _totalReported, Colors.white), 
                              _buildStatColumn("Pending", _pendingCount, Colors.orangeAccent),
                              _buildStatColumn("Resolved", _resolvedCount, Colors.greenAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "Civic Contributor",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "ID: ${_deviceId.length > 5 ? _deviceId.substring(0, 5) : _deviceId}...",
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1, thickness: 1, color: Color(0xFF1F1F22)),
        
              // --- PERSONAL FEED (Grid View) ---
              Expanded(
                child: _myIssues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.grid_off, size: 64, color: Colors.grey.shade800),
                            const SizedBox(height: 16),
                            const Text("No reports yet.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text("Issues you report will appear here.", style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        itemCount: _myIssues.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemBuilder: (context, index) {
                          final issue = _myIssues[index];
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              if (issue['image_url'] != null)
                                Image.network(
                                  issue['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF1F1F22)),
                                )
                              else
                                Container(color: const Color(0xFF1F1F22)),
                              
                              // Tiny Status Indicator overlay
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white12, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 4,
                                        backgroundColor: _getStatusColor(issue['status']),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getTimeAgo(issue['created_at']),
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}