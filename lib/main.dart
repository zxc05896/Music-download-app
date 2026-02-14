// ==============================================================================
// 🚀 LIQUID SNAP GLASS - ULTIMATE EDITION
// 🎨 DESIGN: PyTgCalls Inspired (Deep Dark & Neon Glow)
// ⚙️ ENGINE: High Performance Dio + Flutter 3.27+ Support
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart'; // تأكد من إضافتها في pubspec

// -----------------------------------------------------------------------------
// ⚙️ CONFIGURATION & GLOBALS
// -----------------------------------------------------------------------------
const String SERVER_URL = "https://music-download-app.fly.dev";
final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();
final Dio dioClient = Dio();

// 🎨 Palette inspired by the image
const Color kDeepBlack = Color(0xFF050505);
const Color kNeonGreen = Color(0xFF00FF94);
const Color kNeonCyan = Color(0xFF00C2FF);
const Color kGlassBorder = Colors.white10;

// -----------------------------------------------------------------------------
// 🚀 ENTRY POINT
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  await _initNotifications();
  
  // Configure Dio
  dioClient.options = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'User-Agent': 'LiquidSnap/Pro'},
  );
  
  // System UI Styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kDeepBlack,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const LiquidGlassApp());
}

Future<void> _initNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _notifPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: (details) {
      if (details.payload != null) OpenFilex.open(details.payload!);
    },
  );
  
  if (Platform.isAndroid) {
    await _notifPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }
}

// -----------------------------------------------------------------------------
// 📱 APP ROOT
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
        scaffoldBackgroundColor: kDeepBlack,
        useMaterial3: true,
        primaryColor: kNeonGreen,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

// -----------------------------------------------------------------------------
// 🏠 MAIN LAYOUT (With Background Glows)
// -----------------------------------------------------------------------------
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;
  final _pages = <Widget>[
    const HomePage(),
    const QueuePage(), // Active Downloads
    const DownloadsPage(), // History
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: kDeepBlack,
      body: Stack(
        children: [
          // 🌟 Background Glows (The Secret Sauce)
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowBlob(kNeonGreen, 400),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: _buildGlowBlob(kNeonCyan, 350),
          ),
          
          // Page Content
          _pages[_index],
        ],
      ),
      bottomNavigationBar: _buildGlassNavBar(),
    );
  }

  Widget _buildGlowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 120,
            spreadRadius: 40,
          )
        ],
      ),
    ).animate().scale(duration: 3.seconds, curve: Curves.easeInOut).then().scale(begin: const Offset(1, 1), end: const Offset(0.9, 0.9));
  }

  Widget _buildGlassNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 75,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: -5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(CupertinoIcons.home, 0, "Home"),
              _navItem(CupertinoIcons.cloud_download, 1, "Queue"),
              _navItem(CupertinoIcons.folder, 2, "Library"),
              _navItem(CupertinoIcons.settings, 3, "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int i, String label) {
    final isSelected = _index == i;
    return GestureDetector(
      onTap: () => setState(() => _index = i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected 
          ? BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16))
          : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? kNeonGreen : Colors.white38, size: 26),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: kNeonGreen, shape: BoxShape.circle))
            ]
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔍 HOME PAGE (The Design Centerpiece)
// -----------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isLoading = false;

  // Connectivity
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      return;
    }
    if (!mounted) return;
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    setState(() => _connectionStatus = result);
  }

  Future<void> _analyzeLink() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Internet Connection"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final uri = Uri.parse('$SERVER_URL/api/v1/extract');
      final resp = await http.post(
        uri, 
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({'url': url, 'include_audio': true})
      ).timeout(const Duration(seconds: 40));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) _showResultSheet(context, data);
      } else {
        throw "Server Error: ${resp.statusCode}";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 120),
      children: [
        // Badge
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: const Text("Liquid Snap v2.0", style: TextStyle(fontSize: 12, color: kNeonCyan, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

        // Title
        Text("The Industry\nStandard.", style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.bold, height: 1.1, letterSpacing: -1.5)),
        const SizedBox(height: 10),
        Text("Download content from YouTube, Instagram & more with seamless glass precision.", style: GoogleFonts.outfit(fontSize: 16, color: Colors.white54)),
        
        const SizedBox(height: 40),

        // Stats Cards (Visual Appeal)
        Row(
          children: [
            Expanded(child: _buildStatCard("20M+", "Downloads", 0)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("4K", "Quality", 100)),
          ],
        ),
        
        const SizedBox(height: 40),

        // Search Bar
        Text("Start Downloading", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(CupertinoIcons.link, color: Colors.white38),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Paste link here...",
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : _analyzeLink,
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.white10 : kNeonGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isLoading ? [] : [BoxShadow(color: kNeonGreen.withOpacity(0.4), blurRadius: 20)],
                  ),
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2))
                    : const Icon(CupertinoIcons.arrow_right, color: Colors.black),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, int delay) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }

  void _showResultSheet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // Thumbnail
            if (data['thumbnail'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(data['thumbnail'], height: 180, width: 300, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            Text(data['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: (data['formats'] as List).length,
                itemBuilder: (ctx, i) {
                  final fmt = data['formats'][i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(fmt['resolution'].toString().contains('Audio') ? CupertinoIcons.music_note : CupertinoIcons.film, color: kNeonCyan),
                      title: Text("${fmt['resolution']} • ${fmt['ext']?.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(CupertinoIcons.cloud_download, color: kNeonGreen),
                      onTap: () {
                        Navigator.pop(context);
                        DownloadManager.instance.startDownload(fmt['url'], data['title'], fmt['ext']);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Download Started 🚀")));
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📥 DOWNLOAD MANAGER (Singleton Engine)
// -----------------------------------------------------------------------------
class DownloadManager {
  DownloadManager._internal();
  static final DownloadManager instance = DownloadManager._internal();

  final List<DownloadTask> _queue = [];
  final StreamController<List<DownloadTask>> _streamController = StreamController.broadcast();
  Stream<List<DownloadTask>> get queueStream => _streamController.stream;
  bool _isProcessing = false;

  Future<void> startDownload(String url, String title, String ext) async {
    // Request Permissions
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isDenied) {
        if (await Permission.manageExternalStorage.request().isDenied) return;
      }
    }

    final dir = await _getDir();
    final fileName = "${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext";
    final savePath = "${dir.path}/$fileName";

    final task = DownloadTask(url: url, savePath: savePath, fileName: fileName);
    _queue.add(task);
    _streamController.add(_queue);
    
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.any((t) => t.status == TaskStatus.pending)) {
      final task = _queue.firstWhere((t) => t.status == TaskStatus.pending);
      task.status = TaskStatus.downloading;
      _streamController.add(_queue);

      try {
        await dioClient.download(task.url, task.savePath, onReceiveProgress: (rec, total) {
          if (total != -1) {
            task.progress = rec / total;
            _streamController.add(_queue); // Update UI
          }
        });
        
        task.status = TaskStatus.completed;
        task.progress = 1.0;
        _sendNotification(task);
      } catch (e) {
        task.status = TaskStatus.failed;
        debugPrint("DL Error: $e");
      }
      _streamController.add(_queue);
    }
    _isProcessing = false;
  }

  Future<Directory> _getDir() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _sendNotification(DownloadTask task) async {
    const android = AndroidNotificationDetails('dl_channel', 'Downloads', importance: Importance.high);
    const ios = DarwinNotificationDetails();
    await _notifPlugin.show(
      Random().nextInt(9999), 
      'Download Complete', 
      task.fileName, 
      const NotificationDetails(android: android, iOS: ios),
      payload: task.savePath
    );
  }
}

class DownloadTask {
  final String url, savePath, fileName;
  double progress;
  TaskStatus status;
  DownloadTask({required this.url, required this.savePath, required this.fileName, this.progress = 0, this.status = TaskStatus.pending});
}
enum TaskStatus { pending, downloading, completed, failed }

// -----------------------------------------------------------------------------
// ⏳ QUEUE PAGE (Active Downloads)
// -----------------------------------------------------------------------------
class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DownloadTask>>(
      stream: DownloadManager.instance.queueStream,
      initialData: const [],
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(children: [Text("Active Queue", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold))]),
              ),
              Expanded(
                child: tasks.isEmpty 
                  ? Center(child: Text("No active downloads", style: GoogleFonts.outfit(color: Colors.white24)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: tasks.length,
                      itemBuilder: (ctx, i) {
                        final task = tasks[i];
                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(value: task.progress, backgroundColor: Colors.white10, color: kNeonGreen, borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${(task.progress * 100).toInt()}%", style: const TextStyle(color: kNeonGreen, fontSize: 12)),
                                  Text(task.status.name.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              )
                            ],
                          ),
                        ).animate().fadeIn();
                      },
                    ),
              )
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 📂 DOWNLOADS PAGE (History)
// -----------------------------------------------------------------------------
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> _files = [];
  
  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final dir = await DownloadManager.instance._getDir();
    if (dir.existsSync()) {
      setState(() {
        _files = dir.listSync().where((e) => e.path.endsWith('.mp4') || e.path.endsWith('.mp3')).toList().reversed.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Library", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _loadFiles, icon: const Icon(CupertinoIcons.refresh, color: kNeonCyan))
              ],
            ),
          ),
          Expanded(
            child: _files.isEmpty
              ? Center(child: Text("Library is empty", style: GoogleFonts.outfit(color: Colors.white24)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _files.length,
                  itemBuilder: (ctx, i) {
                    final file = _files[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(CupertinoIcons.play_arrow_solid, color: Colors.white)),
                        title: Text(file.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                          onPressed: () { file.deleteSync(); _loadFiles(); },
                        ),
                        onTap: () => OpenFilex.open(file.path),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ⚙️ SETTINGS PAGE
// -----------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text("Settings", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _item(CupertinoIcons.delete, "Clear Cache", () async {
            final dir = await getTemporaryDirectory();
            if (dir.existsSync()) dir.deleteSync(recursive: true);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cache Cleared")));
          }),
          _item(CupertinoIcons.info, "About LiquidSnap", () {}),
          _item(CupertinoIcons.lock, "Privacy Policy", () {}),
          const SizedBox(height: 50),
          Center(child: Text("v2.0.0 Ultimate • Powered by Flutter", style: GoogleFonts.outfit(color: Colors.white24))),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title),
        trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.white24, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🧊 GLASS CARD WIDGET (The Core Component)
// -----------------------------------------------------------------------------
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: kGlassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
