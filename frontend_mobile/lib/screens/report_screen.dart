import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:native_exif/native_exif.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _image;
  
  // Unified Location State
  double? _selectedLat;
  double? _selectedLng;
  String _locationStatus = "Pending image selection...";
  bool _isLocationWarning = false;
  
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  // 1. Helper to fetch live GPS silently
  Future<Position?> _fetchDeviceLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // 2. Show Bottom Sheet for Camera vs Gallery
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)))),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 3. Handle Image Capture and EXIF Extraction
  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _selectedLat = null;
        _selectedLng = null;
        _isLocationWarning = false;
        _locationStatus = "Analyzing location data...";
      });

      if (source == ImageSource.gallery) {
        try {
          final exif = await Exif.fromPath(pickedFile.path);
          final latLong = await exif.getLatLong();
          await exif.close();

          if (latLong != null) {
            setState(() {
              _selectedLat = latLong.latitude;
              _selectedLng = latLong.longitude;
              _locationStatus = "📍 Using photo's original location";
              _isLocationWarning = false;
            });
          } else {
            setState(() => _locationStatus = "⚠️ No photo location found. Fetching current GPS...");
            Position? pos = await _fetchDeviceLocation();
            setState(() {
              _selectedLat = pos?.latitude;
              _selectedLng = pos?.longitude;
              _locationStatus = "⚠️ No photo location found. Will use current GPS.";
              _isLocationWarning = true;
            });
          }
        } catch (e) {
          Position? pos = await _fetchDeviceLocation();
          setState(() {
            _selectedLat = pos?.latitude;
            _selectedLng = pos?.longitude;
            _locationStatus = "⚠️ Could not read photo data. Will use current GPS.";
            _isLocationWarning = true;
          });
        }
      } else {
        Position? pos = await _fetchDeviceLocation();
        setState(() {
          _selectedLat = pos?.latitude;
          _selectedLng = pos?.longitude;
          _locationStatus = "📍 Using live device location";
          _isLocationWarning = false;
        });
      }
    }
  }

  // 4. Interactive Map Picker with Nominatim Search
  void _openMapPicker() {
    LatLng currentCenter = LatLng(_selectedLat ?? 34.0837, _selectedLng ?? 74.7973);
    final MapController mapController = MapController();
    final TextEditingController searchController = TextEditingController();
    
    List<dynamic> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF09090B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            
            // Free Nominatim Geocoding API
            Future<void> searchAddress(String query) async {
              if (query.isEmpty) {
                setModalState(() => searchResults = []);
                return;
              }
              setModalState(() => isSearching = true);
              try {
                final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5');
                final response = await http.get(url, headers: {'User-Agent': 'CivicFixApp/1.0'});
                if (response.statusCode == 200) {
                  setModalState(() {
                    searchResults = jsonDecode(response.body);
                    isSearching = false;
                  });
                }
              } catch (e) {
                setModalState(() => isSearching = false);
              }
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  // Modal Header
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10))),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text("Pinpoint the Issue", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  
                  // Map & Search Area
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FlutterMap(
                          mapController: mapController,
                          options: MapOptions(
                            initialCenter: currentCenter,
                            initialZoom: 15.0,
                            onPositionChanged: (camera, hasGesture) {
                              if (hasGesture) currentCenter = camera.center;
                            }
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.civicfix.app',
                            ),
                          ],
                        ),
                        // Static Center Pin
                        const Icon(Icons.location_on, size: 50, color: Color(0xFF6B4EFF)),
                        const Padding(padding: EdgeInsets.only(top: 25.0), child: Icon(Icons.circle, size: 8, color: Colors.black)),
                        
                        // Floating Search Bar & Results
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            children: [
                              TextField(
                                controller: searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Search city, neighborhood, or street...",
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: const Color(0xFF1A1A1C).withOpacity(0.95),
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: isSearching 
                                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B4EFF)))
                                    : IconButton(
                                        icon: const Icon(Icons.clear, color: Colors.grey),
                                        onPressed: () {
                                          searchController.clear();
                                          setModalState(() => searchResults = []);
                                        },
                                      ),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                                onSubmitted: searchAddress,
                              ),
                              if (searchResults.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: (8.0)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1C).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF2A2A2A))
                                  ),
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: searchResults.length,
                                    separatorBuilder: (ctx, idx) => Divider(color: Colors.grey.shade800, height: 1),
                                    itemBuilder: (context, index) {
                                      final place = searchResults[index];
                                      return ListTile(
                                        title: Text(place['display_name'], style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        leading: const Icon(Icons.place, color: Color(0xFF6B4EFF)),
                                        onTap: () {
                                          // Fly to new location
                                          final lat = double.parse(place['lat']);
                                          final lon = double.parse(place['lon']);
                                          mapController.move(LatLng(lat, lon), 16.0);
                                          currentCenter = LatLng(lat, lon);
                                          
                                          // Clear search UI
                                          FocusScope.of(context).unfocus();
                                          setModalState(() {
                                            searchResults = [];
                                            searchController.text = place['name'] ?? "Selected Location";
                                          });
                                        },
                                      );
                                    },
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Confirm Button
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: const Color(0xFF09090B),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EFF),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedLat = currentCenter.latitude;
                          _selectedLng = currentCenter.longitude;
                          _locationStatus = "📍 Custom location selected";
                          _isLocationWarning = false;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Confirm Issue Location", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  // 5. Main Submit Pipeline
  Future<void> _submitIssue() async {
    if (_image == null) return;
    setState(() => _isLoading = true);

    try {
      if (_selectedLat == null || _selectedLng == null) {
        Position? pos = await _fetchDeviceLocation();
        if (pos == null) throw Exception("Could not determine location. Please adjust on map.");
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage.from('issue-images').upload(fileName, _image!);
      final String imageUrl = Supabase.instance.client.storage.from('issue-images').getPublicUrl(fileName);

      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final String deviceId = androidInfo.id;

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/issues/'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descController.text,
          'latitude': _selectedLat,
          'longitude': _selectedLng,
          'image_url': imageUrl,
          'device_id': deviceId
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue Reported Successfully! AI is assigning it...', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white)
        );
        setState(() {
          _image = null;
          _descController.clear();
          _selectedLat = null;
          _selectedLng = null;
        });
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image != null) ...[
              
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 280, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isLocationWarning ? Colors.amberAccent.withOpacity(0.5) : const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _locationStatus,
                        style: TextStyle(
                          color: _isLocationWarning ? Colors.amberAccent : Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map, size: 16, color: Colors.white),
                      label: const Text("Adjust", style: TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Add a note (Optional)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1C),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitIssue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                    : const Text('Submit to CivicFix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              
              TextButton(
                onPressed: _showPickerOptions,
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
                child: const Text('Change Photo', style: TextStyle(fontSize: 15)),
              )
              
            ] else ...[
              
              GestureDetector(
                onTap: _showPickerOptions,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.add_a_photo, size: 40, color: Colors.black), 
                      ),
                      const SizedBox(height: 20),
                      const Text('Upload Photo Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('Camera or Gallery', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}