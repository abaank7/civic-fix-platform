import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../config.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _image;
  final TextEditingController _descController = TextEditingController();
  bool _isLoading = false;

  // 1. Open the Camera
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, 
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // 2. Main Submit Pipeline
  Future<void> _submitIssue() async {
    if (_image == null) return;
    
    setState(() => _isLoading = true);

    try {
      // A. Get GPS Location[cite: 3]
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("GPS is disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("GPS permission denied.");
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // B. Upload Photo to Supabase[cite: 3]
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('issue-images')
          .upload(fileName, _image!);
          
      final String imageUrl = Supabase.instance.client.storage
          .from('issue-images')
          .getPublicUrl(fileName);

      // C. Get Unique Device ID[cite: 3]
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      final String deviceId = androidInfo.id;

      // D. Send to FastAPI Backend[cite: 3]
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/issues/'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descController.text,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'image_url': imageUrl,
          'device_id': deviceId
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue Reported Successfully! AI is assigning it...', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
          )
        );
        setState(() {
          _image = null;
          _descController.clear();
        });
      } else {
        throw Exception("Server Error: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        )
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null) ...[
            
            // --- IMAGE PREVIEW ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(_image!, height: 320, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            
            // --- DESCRIPTION TEXT FIELD (Monochrome) ---
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white, fontSize: 16), // White typed text
              decoration: InputDecoration(
                labelText: 'Add a note (Optional)',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFF1A1A1C), // Elevated charcoal grey so it doesn't blend into the background
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 1.5), // High contrast white focus
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // --- SUBMIT BUTTON (High Contrast White) ---
            ElevatedButton(
              onPressed: _isLoading ? null : _submitIssue,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white, // Replaced BlueAccent[cite: 3] with stark white
                foregroundColor: Colors.black, // Black text for maximum B&W contrast
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const SizedBox(
                      height: 24, 
                      width: 24, 
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5)
                    )
                  : const Text('Submit to CivicFix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            
            // --- RETAKE BUTTON ---
            TextButton(
              onPressed: () => setState(() => _image = null),
              style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
              child: const Text('Retake Photo', style: TextStyle(fontSize: 15)),
            )
            
          ] else ...[
            
            // --- CAMERA PLACEHOLDER (Charcoal Box) ---
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1C), // Slightly lighter than pure black to stand out
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5), // Replaced Grey.shade300[cite: 3]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      // Replaced BlueAccent camera[cite: 3] with a sleek black-on-white icon
                      child: const Icon(Icons.camera_alt, size: 40, color: Colors.black), 
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tap to Snap a Photo', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'GPS location will be attached automatically', 
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)
                    ),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}