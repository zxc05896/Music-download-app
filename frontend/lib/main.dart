// ==============================================================================
// Project: Liquid Glass Snap Application
// File: frontend/lib/main.dart
// Architecture: MVVM (Simplified for Single File)
// Design System: Liquid Glass (Glassmorphism)
// Author: Gemini (Your AI Assistant)
// ==============================================================================

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// -----------------------------------------------------------------------------
// 1. CONFIGURATION (ربط التطبيق بالسيرفر)
// -----------------------------------------------------------------------------
// استبدل هذا العنوان بـ IP السيرفر الخاص بك أو localhost إذا كنت تجرب محلياً
const String SERVER_URL = "http://10.0.2.2:8000"; // 10.0.2.2 هو localhost للأندرويد

void main() {
  runApp(const LiquidGlassApp());
}

// -----------------------------------------------------------------------------
// 2. MAIN APP STRUCTURE
// -----------------------------------------------------------------------------
class LiquidGlassApp extends StatelessWidget {
  const LiquidGlassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Snap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. HOME SCREEN (واجهة المستخدم الرئيسية)
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

  // --- Logic: الاتصال بالسيرفر ---
  Future<void> _fetchVideoInfo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
    });

    try {
      // إرسال الطلب لملف main.py في السيرفر
      final response = await http.post(
        Uri.parse('$SERVER_URL/api/v1/extract'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "url": url,
          "include_audio": true
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() {
          _videoData = jsonDecode(response.body);
        });
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "فشل الاتصال بالسيرفر: تأكد من تشغيل الـ Backend.\n$e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Logic: بدء التحميل ---
  Future<void> _launchDownload(String? url) async {
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("لا يمكن فتح رابط التحميل")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // خلفية متدرجة تعطي إيحاء العمق (Depth)
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Layer (Abstract Gradient)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F2027), // Deep Blue
                    Color(0xFF203A43), // Forest
                    Color(0xFF2C5364), // Teal
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Content Layer
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // App Title
                  Text(
                    "Liquid Snap",
                    style: GoogleFonts.audiowide(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(),
                  
                  const SizedBox(height: 5),
                  Text(
                    "Paste any link, get any quality.",
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),

                  const SizedBox(height: 40),

                  // Input Field (Glass Style)
                  GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Paste YouTube/Facebook Link here...",
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste, color: Colors.cyanAccent),
                            onPressed: () async {
                              // Paste logic can be added here
                            },
                          ),
                        ),
                      ),
                    ),
                  ).animate().scale(delay: 200.ms),

                  const SizedBox(height: 20),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _fetchVideoInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                        foregroundColor: Colors.cyanAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.cyanAccent)
                          : const Text("ANALYZE LINK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Results Section ---
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    ).animate().shake(),

                  if (_videoData != null) ...[
                    // Video Metadata Card
                    GlassContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              _videoData!['thumbnail'] ?? "",
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                const Center(child: Icon(Icons.error, color: Colors.white)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _videoData!['title'] ?? "Unknown Title",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Duration: ${_formatDuration(_videoData!['duration'])}",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 20),
                    const Text("Available Formats", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Format List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (_videoData!['formats'] as List).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final format = _videoData!['formats'][index];
                        return _buildFormatCard(format);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildFormatCard(Map<String, dynamic> format) {
    bool isAudio = format['resolution'] == "Audio Only";
    
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAudio ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAudio ? Icons.audiotrack : Icons.videocam,
              color: isAudio ? Colors.orangeAccent : Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  format['resolution'] ?? "Unknown",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "${format['ext'].toString().toUpperCase()} • ${_formatBytes(format['filesize'])}",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.cyanAccent),
            onPressed: () => _launchDownload(format['url']),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * 1)); // Staggered animation
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return "--:--";
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return "Unknown Size";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }
}

// -----------------------------------------------------------------------------
// 4. CUSTOM WIDGETS (Liquid Glass Engine)
// -----------------------------------------------------------------------------
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // The Blur Effect
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08), // Transparency
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12), // Subtle border
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
