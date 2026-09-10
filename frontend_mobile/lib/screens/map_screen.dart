import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../config.dart';

// --- PRO FEATURE: OFFLINE TILE CACHING PROVIDER ---
// This class intercepts map images and saves them permanently to local storage.
class CachedTileProvider extends TileProvider {
   CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      // OpenStreetMap strictly requires a User-Agent to avoid being blocked
      headers: const {'User-Agent': 'com.civicfix.app'}, 
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<dynamic> _issues = [];
  LatLng? _currentUserLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    await Future.wait([
      _fetchIssues(),
      _locateUser(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchIssues() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/v1/issues/'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        _issues = jsonDecode(response.body);
      }
    } catch (_) {}
  }

  Future<void> _locateUser() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentUserLocation = userLatLng;
        });
        // Smoothly fly to the user's location
        // _mapController.move(userLatLng, 14.5);
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
    }
  }

  // Dark Mode Optimized Marker Colors
  Color _getMarkerColor(String category) {
    switch (category) {
      case 'PWD': return Colors.orangeAccent;
      case 'JSD': return Colors.lightBlueAccent;
      case 'SMC': return Colors.greenAccent;
      case 'KPDCL': return Colors.amberAccent;
      case 'JKFD': return Colors.tealAccent;
      default: return Colors.redAccent;
    }
  }
  
  String _getTimeAgo(String timestamp) {
    DateTime parsedDate = DateTime.parse(timestamp).toLocal();
    Duration diff = DateTime.now().difference(parsedDate);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // --- DARK MODE POP-UP PREVIEW ---
  void _showIssuePreview(dynamic issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allows the dark card to float smoothly
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121214), // Matches the Dark Theme Feed Cards
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF27272A), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMarkerColor(issue['category'] ?? '').withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue['category'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _getMarkerColor(issue['category'] ?? ''),
                      ),
                    ),
                  ),
                  Text(
                    _getTimeAgo(issue['created_at']),
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Edge-to-Edge Image
              if (issue['image_url'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    issue['image_url'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 160,
                      color: const Color(0xFF1F1F22),
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              
              // Description Text
              Text(
                issue['description']?.toString().isNotEmpty == true
                    ? issue['description']
                    : "No description provided.",
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = _issues
        .where((issue) => issue['latitude'] != null && issue['longitude'] != null)
        .map((issue) {
      return Marker(
        point: LatLng(issue['latitude'], issue['longitude']),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showIssuePreview(issue),
          child: Icon(
            Icons.location_on,
            color: _getMarkerColor(issue['category'] ?? ''),
            size: 45,
            shadows: const [
              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(0, 4)),
            ],
          ),
        ),
      );
    }).toList();

    // Vibrant Purple GPS dot for the user
    if (_currentUserLocation != null) {
      markers.add(
        Marker(
          point: _currentUserLocation!,
          width: 28,
          height: 28,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EFF), 
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4EFF).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Scaffold matches the app's Dark Mode
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EFF)))
          : Stack(
              children: [
                // MAP ENGINE
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentUserLocation ?? const LatLng(34.0837, 74.7973),
                    initialZoom: 14.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.civicfix.app',
                      
                      // --- WIRING UP THE OFFLINE CACHE PROVIDER ---
                      tileProvider:  CachedTileProvider(), 
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),

                // GPS RE-CENTER BUTTON (Dark Theme)
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_gps_btn',
                    backgroundColor: const Color(0xFF1F1F22),
                    elevation: 4,
                    onPressed: (){
                      if (_currentUserLocation != null) {
                        _mapController.move(_currentUserLocation!, 14.5);
                      } else {
                        _locateUser(); // Fetch if we don't have it yet
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}