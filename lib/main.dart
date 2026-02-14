// ==============================================================================
// 📱 Project Name: Liquid Glass Snap (Ultimate Matte Edition)
// 📂 File Name: lib/main.dart
// 👤 Author: Gemini Pro (Your AI Partner)
// 📅 Date: 2026-02-14
// ------------------------------------------------------------------------------
// 📝 DESCRIPTION:
// This is the main entry point for the Liquid Snap application.
// It implements a sophisticated "Matte Glassmorphism" design language
// inspired by YouTube's layout but with a futuristic, translucent twist.
//
// 🔧 FEATURES INCLUDED:
// 1. YouTube-style Top Bar & Navigation.
// 2. Advanced HTTP Error Handling (Fixes 400 Bad Request).
// 3. Custom Glass Engine (BackdropFilter Implementation).
// 4. iOS-style Squircle Buttons & Inputs.
// 5. Smooth Animations & Transitions.
// ==============================================================================

import 'dart:convert'; // For JSON encoding/decoding
import 'dart:ui';      // For ImageFilter (Blur effects)
import 'package:flutter/material.dart'; // Core Flutter framework
import 'package:flutter/cupertino.dart'; // iOS styled icons
import 'package:http/http.dart' as http; // Networking
import 'package:url_launcher/url_launcher.dart'; // Opening URLs
import 'package:google_fonts/google_fonts.dart'; // Custom Typography
import 'package:flutter_animate/flutter_animate.dart'; // Smooth Animations

// -----------------------------------------------------------------------------
// 🌍 GLOBAL CONFIGURATION
// -----------------------------------------------------------------------------
// The backend server URL deployed on Fly.io
const String SERVER_URL = "https://music-download-app.fly.dev";

// -----------------------------------------------------------------------------
// 🚀 APPLICATION ENTRY POINT
// -----------------------------------------------------------------------------
void main() {
  // Ensures widgets are bound before running the app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiquidGlassApp());
}

// -----------------------------------------------------------------------------
// 🎨 APP THEME & ROOT WIDGET
// -----------------------------------------------------------------------------
class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Snap',
      debugShowCheckedModeBanner: false, // Removes the debug banner
      
      // --- THEME CONFIGURATION ---
      theme: ThemeData(
        brightness: Brightness.dark,
        // The signature "Matte Black" background color
        scaffoldBackgroundColor: const Color(0xFF050505), 
        primaryColor: Colors.white,
        useMaterial3: true,
        // Using 'Inter' font for a clean, modern look
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const MainLayoutScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 🏠 MAIN LAYOUT (Bottom Navigation & Page Management)
// -----------------------------------------------------------------------------
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0; // Tracks the currently active tab

  // List of screens for navigation
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(), // The main functionality
    const PlaceholderScreen(title: "Downloads Library", icon: CupertinoIcons.arrow_down_circle),
    const PlaceholderScreen(title: "Settings", icon: CupertinoIcons.settings),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody allows content to flow behind the glass bottom bar
      extendBody: true, 
      body: _pages[_selectedIndex],
      
      // --- FLOATING GLASS BOTTOM NAVIGATION ---
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 75,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6), // Semi-transparent base
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The Blur Effect
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(CupertinoIcons.house_fill, "Home", 0),
                _buildNavItem(CupertinoIcons.arrow_down_circle_fill, "My Files", 1),
                _buildNavItem(CupertinoIcons.slider_horizontal_3, "Settings", 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build navigation items
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon, 
                color: isSelected ? Colors.cyanAccent : Colors.white38,
                size: 24,
              ),
            ),
            if (isSelected) 
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 4, 
                  height: 4, 
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent, 
                    shape: BoxShape.circle
                  )
                ),
              )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔍 HOME SCREEN (Search Logic & UI)
// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _videoData;
  String? _errorMessage;

  // --- CORE LOGIC: FETCH VIDEO DATA ---
  Future<void> _analyzeLink() async {
    final url = _urlController.text.trim(); // Remove whitespace
    
    // Validation
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please paste a link first!"))
      );
      return;
    }
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
    });

    try {
      // Sending POST request to backend
      // IMPORTANT: Headers must be exactly 'application/json' to avoid 400 Error
      final response = await http.post(
        Uri.parse('$SERVER_URL/api/v1/extract'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": url, 
          "include_audio": true
        }),
      ).timeout(const Duration(seconds: 40)); // Timeout safety

      if (response.statusCode == 200) {
        // Success: Parse the JSON
        setState(() {
          _videoData = jsonDecode(response.body);
        });
      } else {
        // Failure: Handle Server Errors
        throw Exception("Server Error (${response.statusCode}): ${response.reasonPhrase}");
      }
    } catch (e) {
      // Network/Logic Errors
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- CORE LOGIC: DOWNLOAD HANDLER ---
  Future<void> _launchDownload(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      // 'externalApplication' mode is crucial for Android 11+ to open browser
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch download link"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Layer (Ambient Light Blob)
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyan.withOpacity(0.08), // Subtle cyan glow
              backgroundBlendMode: BlendMode.screen,
            ),
          ).animate().scale(duration: 3.seconds, curve: Curves.easeInOut).fadeIn(),
        ),

        // 2. Foreground Content
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              _buildSearchBar(),
              
              // 3. Scrollable Content Area
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Padding for bottom nav
                  children: [
                    // Loading State
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50), 
                          child: CircularProgressIndicator(color: Colors.cyanAccent)
                        )
                      ),

                    // Error State
                    if (_errorMessage != null)
                      _buildErrorCard(),

                    // Empty State
                    if (_videoData == null && !_isLoading && _errorMessage == null)
                      _buildEmptyState(),

                    // Result State
                    if (_videoData != null) 
                      _buildVideoResult(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        children: [
          // Logo Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.bolt_fill, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(width: 12),
          // App Title
          Text(
            "Liquid Snap", 
            style: GoogleFonts.audiowide(fontSize: 24, color: Colors.white)
          ),
          const Spacer(),
          // Profile/Notification Icons
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.bell, color: Colors.white70),
          ),
          const CircleAvatar(
            backgroundColor: Colors.white12,
            radius: 16,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassContainer(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.cyanAccent,
          decoration: InputDecoration(
            hintText: "Paste YouTube link here...",
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            border: InputBorder.none,
            icon: Icon(CupertinoIcons.search, color: Colors.white.withOpacity(0.5)),
            suffixIcon: IconButton(
              icon: const Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.cyanAccent, size: 30),
              onPressed: _analyzeLink,
            ),
          ),
          onSubmitted: (_) => _analyzeLink(),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              _errorMessage!, 
              style: const TextStyle(color: Colors.redAccent)
            ),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(CupertinoIcons.link, size: 80, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 20),
        Text(
          "Ready to download?", 
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white24)
        ),
        Text(
          "Paste a link above to start.", 
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white12)
        ),
      ],
    );
  }

  Widget _buildVideoResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Section Title
        const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 10),
          child: Text("RESULT", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        
        // Video Card
        GlassContainer(
          radius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    _videoData!['thumbnail'] ?? "",
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(height: 220, color: Colors.grey[900]),
                  ),
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)]
                      )
                    ),
                  ),
                  // Play Button Decoration
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5))
                    ),
                    child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 30),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                ],
              ),
              
              // 2. Info Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _videoData!['title'] ?? "Unknown Title",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.time, size: 14, color: Colors.white54),
                        const SizedBox(width: 5),
                        Text(
                          _formatDuration(_videoData!['duration']),
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(width: 15),
                        const Icon(CupertinoIcons.eye, size: 14, color: Colors.white54),
                        const SizedBox(width: 5),
                        const Text("Views: --", style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white10, height: 1),

              // 3. Download Options (Chips)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("AVAILABLE FORMATS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: (_videoData!['formats'] as List).map((format) {
                        return _buildDownloadChip(format);
                      }).toList(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
      ],
    );
  }

  Widget _buildDownloadChip(Map<String, dynamic> format) {
    bool isAudio = format['resolution'] == "Audio Only";
    Color baseColor = isAudio ? Colors.orangeAccent : Colors.cyanAccent;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchDownload(format['url']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: baseColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAudio ? CupertinoIcons.music_note_2 : CupertinoIcons.videocam_fill, 
                size: 16, 
                color: baseColor
              ),
              const SizedBox(width: 8),
              Text(
                "${format['resolution']} • ${format['ext'].toString().toUpperCase()}",
                style: TextStyle(color: baseColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Icon(CupertinoIcons.cloud_download, size: 16, color: baseColor.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return "--:--";
    final d = Duration(seconds: seconds);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}

// -----------------------------------------------------------------------------
// 🧊 CUSTOM GLASS ENGINE WIDGET
// -----------------------------------------------------------------------------
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key, 
    required this.child, 
    this.radius = 20, 
    this.padding
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        // The strength of the blur
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), 
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // The "Matte" transparency color (Very low opacity white)
            color: Colors.white.withOpacity(0.06), 
            borderRadius: BorderRadius.circular(radius),
            // Subtle gradient border for 3D effect
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🚧 PLACEHOLDER SCREEN (For Future Tabs)
// -----------------------------------------------------------------------------
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 20)),
          const SizedBox(height: 5),
          const Text("Coming Soon", style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
        ],
      ),
    );
  }
}
