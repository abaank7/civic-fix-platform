import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';
// import 'config.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filter States
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  // Available Filter Options
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
  ];
  final List<String> _categoryOptions = [
    'All',
    'PWD',
    'JSD',
    'SMC',
    'KPDCL',
    'JKFD',
    'Invalid',
  ];

  @override
  void initState() {
    super.initState();
    _fetchIssues();
  }

  Future<void> _fetchIssues() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/v1/issues/'))
          .timeout(const Duration(seconds: 10));
          print("ATTEMPTING TO FETCH FROM: $response");

      if (response.statusCode == 200) {
        setState(() {
          _issues = jsonDecode(response.body);
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to connect to server.";
        print("CRITICAL API ERROR: $e");
        _isLoading = false;
      });
    }
  }

  // Applies the selected filters to the raw data
  List<dynamic> get _filteredIssues {
    return _issues.where((issue) {
      final matchesStatus =
          _selectedStatus == 'All' ||
          (issue['status'] ?? 'Pending') == _selectedStatus;
      final matchesCategory =
          _selectedCategory == 'All' ||
          (issue['category'] ?? 'Other') == _selectedCategory;
      return matchesStatus && matchesCategory;
    }).toList();
  }

  String _getTimeAgo(String timestamp) {
    DateTime parsedDate = DateTime.parse(timestamp).toLocal();
    Duration diff = DateTime.now().difference(parsedDate);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // Dark Mode Optimized Colors
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return const Color(0xFF10B981);
      case 'In Progress':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF4B5563); // Grey for Pending/Unresolved
    }
  }

  Map<String, dynamic> _getDepartmentUI(String category) {
    switch (category) {
      case 'PWD':
        return {
          'title': 'PWD (Roads)',
          'icon': Icons.add_road,
          'color': Colors.orangeAccent,
        };
      case 'JSD':
        return {
          'title': 'JSD (Water)',
          'icon': Icons.water_drop,
          'color': Colors.lightBlueAccent,
        };
      case 'SMC':
        return {
          'title': 'SMC (Sanitation)',
          'icon': Icons.delete_sweep,
          'color': Colors.greenAccent,
        };
      case 'KPDCL':
        return {
          'title': 'KPDCL (Power)',
          'icon': Icons.electric_bolt,
          'color': Colors.amberAccent,
        };
      case 'JKFD':
        return {
          'title': 'JKFD (Forestry)',
          'icon': Icons.park,
          'color': Colors.tealAccent,
        };
      case 'Invalid':
        return {
          'title': 'Flagged Invalid',
          'icon': Icons.block,
          'color': Colors.redAccent,
        };
      default:
        return {
          'title': 'Unassigned',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }

  // Helper widget to build the sleek filter pills
  Widget _buildFilterPill(
    String label,
    String currentSelection,
    Function(String) onSelect,
  ) {
    final isSelected = currentSelection == label;
    // Map "Pending" to "Unresolved" in the UI to match the reference image
    final displayLabel = label == 'Pending' ? 'Unresolved' : label;

    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B4EFF) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B75FF) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- MINI-MAP BOTTOM SHEET ---
  void _showMiniMap(BuildContext context, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
              0.5, // Takes up half the screen
          decoration: BoxDecoration(
            color: const Color(0xFF09090B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFF27272A), width: 1),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 16.0, // Zoomed in close to the street
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.civicfix.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF6B4EFF), // Vibrant Purple Pin
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Close Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedIssues = _filteredIssues;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Deep Dark Background
      body: SafeArea(
        child: Column(
          children: [
            // --- FILTER SECTION ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1F1F22), width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Row 1: Status Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _statusOptions
                          .map(
                            (status) => _buildFilterPill(
                              status,
                              _selectedStatus,
                              (val) => setState(() => _selectedStatus = val),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Category Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _categoryOptions
                          .map(
                            (cat) => _buildFilterPill(
                              cat,
                              _selectedCategory,
                              (val) => setState(() => _selectedCategory = val),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            // --- FEED CONTENT ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B4EFF),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _fetchIssues,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : displayedIssues.isEmpty
                  ? Center(
                      child: Text(
                        "No issues match these filters.",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF6B4EFF),
                      backgroundColor: const Color(0xFF1F1F22),
                      onRefresh: _fetchIssues,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedIssues.length,
                        itemBuilder: (context, index) {
                          final issue = displayedIssues[index];
                          final deptUI = _getDepartmentUI(
                            issue['category'] ?? 'Other',
                          );
                          final String status = issue['status'] ?? 'Pending';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121214), // Card background
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF27272A),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 1. Image View (Top)
                                if (issue['image_url'] != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    child: Image.network(
                                      issue['image_url'],
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          Container(
                                            height: 200,
                                            color: const Color(0xFF1F1F22),
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                          ),
                                    ),
                                  ),

                                // 2. Info Section (Bottom)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Date & Status Badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getTimeAgo(issue['created_at']),
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                status,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status == 'Pending'
                                                  ? 'Unresolved'
                                                  : status,
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Description
                                      Text(
                                        issue['description']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true
                                            ? issue['description']
                                            : deptUI['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Department & Location Row
                                      Row(
                                        children: [
                                          Icon(
                                            deptUI['icon'],
                                            size: 16,
                                            color: deptUI['color'],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            deptUI['title'],
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const Spacer(),
                                          // Extract coordinates from the database row
                                          if (issue['latitude'] != null &&
                                              issue['longitude'] != null)
                                            GestureDetector(
                                              onTap: () => _showMiniMap(
                                                context,
                                                issue['latitude'],
                                                issue['longitude'],
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 14,
                                                    color: Color(0xFF6B4EFF),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'View Map',
                                                    style: TextStyle(
                                                      color: Color(0xFF6B4EFF),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
