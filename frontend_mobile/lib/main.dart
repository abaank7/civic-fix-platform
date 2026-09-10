import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/report_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/map_screen.dart';
import 'screens/my_reports_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized before doing async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for direct image uploads to your bucket
  await Supabase.initialize(
    url: 'https://uzkmqubzotbuifnjktnu.supabase.co',
    anonKey: 'sb_publishable_MH1lVrUBwgczb4_kH7D73w_pny_1265', 
  );

  runApp(const CivicFixApp());
}

class CivicFixApp extends StatelessWidget {
  const CivicFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicFix',
      debugShowCheckedModeBanner: false,
      // Global Dark Theme Configuration
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090B), // Deep Dark Background
        primaryColor: const Color(0xFF6B4EFF), // Vibrant Purple
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF09090B),
          foregroundColor: Colors.white,
          elevation: 0, // Removes the default shadow for a flatter, modern look
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Screens for our 4 tabs
  final List<Widget> _screens = [
    const FeedScreen(),
    const MapScreen(),
    const ReportScreen(),
    const MyReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CivicFix', 
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
        centerTitle: true,
        // Adds a sleek, subtle bottom border to the AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF1F1F22), 
            height: 1.0,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        // Adds a top border to the bottom navigation bar
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1F1F22), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF09090B), // Matches the scaffold
          selectedItemColor: const Color(0xFF6B4EFF), // Vibrant Purple active state
          unselectedItemColor: Colors.grey.shade600, // Dimmed inactive state
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}