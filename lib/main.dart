// ==============================================================================
// 🚀 LIQUID GLASS SNAP - MAIN ENTRY POINT
// 📅 UPDATED: 2026-02-14 | COMPATIBILITY: API 34+ / FLUTTER 3.27+
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

// -----------------------------------------------------------------------------
// ⚙️ CONFIGURATION & GLOBALS
// -----------------------------------------------------------------------------
const String SERVER_URL = "https://music-download-app.fly.dev";
final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();
final Dio dioClient = Dio();

// -----------------------------------------------------------------------------
// 🚀 ENTRY POINT
// -----------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notifications
  await _initNotifications();
  
  // Configure Dio for High Performance
  _configureDio();
  
  // Set System UI Overlay Style (For Glass Effect)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050505),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const LiquidGlassApp());
}

Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  
  await _notifPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: (details) {
      // Handle notification tap
    },
  );

  // Request Android 13+ Notification Permissions
  if (Platform.isAndroid) {
    await _notifPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }
}

void _configureDio() {
  dioClient.options = BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {'User-Agent': 'LiquidSnap/2.0.0-Ultimate'},
  );
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        useMaterial3: true,
        // Using a modern font family
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF), // Cyber Blue
          secondary: Color(0xFF7000FF), // Neon Purple
          surface: Color(0xFF121212),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}

// -----------------------------------------------------------------------------
// 🏠 MAIN LAYOUT (With Glass Bottom Bar)
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
    const DownloadsPage(),
    const QueuePage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for glass effect behind nav bar
      body: _pages[_index],
      bottomNavigationBar: _buildGlassNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickScanner(context),
        backgroundColor: const Color(0xFF00F0FF),
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(CupertinoIcons.add, color: Colors.black, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildGlassNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(CupertinoIcons.home, 0),
              _navItem(CupertinoIcons.arrow_down_circle, 1),
              const SizedBox(width: 40), // Space for FAB
              _navItem(CupertinoIcons.list_bullet, 2),
              _navItem(CupertinoIcons.settings, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int i) {
    final isSelected = _index == i;
    return GestureDetector(
      onTap: () => setState(() => _index = i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected 
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12)
              ) 
            : null,
        child: Icon(
          icon, 
          color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  void _openQuickScanner(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuickAddSheet(),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔍 HOME PAGE (The Core)
// -----------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _currentData;
  String? _errorMessage;
  bool _isLoading = false;
  
  // 🔥 FIX 1: Updated Connectivity Logic for 2026 (List support)
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  List<ConnectivityResult> _connStatus = [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    _observeConnectivity();
  }

  void _observeConnectivity() async {
    final connectivity = Connectivity();
    
    // Initial check
    try {
      _connStatus = await connectivity.checkConnectivity();
    } catch (e) {
      debugPrint("Connectivity Check Error: $e");
    }

    // Listener
    _connSub = connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (mounted) {
        setState(() => _connStatus = result);
        if (result.contains(ConnectivityResult.none)) {
          _showSnack("No Internet Connection", isError: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showSnack("Please paste a valid link first");
      return;
    }
    
    // Check internet before request
    if (_connStatus.contains(ConnectivityResult.none)) {
      _showSnack("Check your internet connection", isError: true);
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _currentData = null; });
    
    try {
      final uri = Uri.parse('$SERVER_URL/api/v1/extract');
      final resp = await http.post(
        uri, 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }, 
        body: jsonEncode({'url': url, 'include_audio': true})
      ).timeout(const Duration(seconds: 40));

      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body);
        if (json is Map<String, dynamic>) {
          setState(() => _currentData = json);
        } else {
          setState(() => _errorMessage = 'Invalid Data Format');
        }
      } else {
        setState(() => _errorMessage = 'Server Error: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection Failed: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF00F0FF).withOpacity(0.8),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Glow
        Positioned(
          top: -100, 
          right: -100, 
          child: Container(
            width: 300, 
            height: 300, 
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: const Color(0xFF00F0FF).withOpacity(0.15),
              boxShadow: [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.2), blurRadius: 100)],
            ),
          ),
        ),
        
        // Content
        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF7000FF)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Liquid Snap', style: GoogleFonts.audiowide(fontSize: 24, color: Colors.white)),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.link, color: Colors.white38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Paste YouTube/Instagram link...',
                            hintStyle: TextStyle(color: Colors.white24),
                          ),
                          onSubmitted: (_) => _fetchData(),
                        ),
                      ),
                      IconButton(
                        onPressed: _fetchData,
                        icon: const Icon(CupertinoIcons.arrow_right_circle_fill, color: Color(0xFF00F0FF), size: 32),
                      )
                    ],
                  ),
                ),
              ),

              // Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    if (_isLoading) 
                      Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: const Color(0xFF00F0FF)))),
                    
                    if (_errorMessage != null) 
                      ErrorCard(message: _errorMessage!),
                    
                    if (_currentData == null && !_isLoading && _errorMessage == null) 
                      const EmptyStateWidget(),
                    
                    if (_currentData != null) 
                      ResultCard(
                        data: _currentData!,
                        onDownload: (format) async {
                          // Check Permissions first
                          if (await _requestPermissions()) {
                            await DownloadManager.instance.enqueue(format, _currentData!);
                            _showSnack("Added to Download Queue");
                          } else {
                            _showSnack("Permission Denied! Cannot download.", isError: true);
                          }
                        },
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+)
      if (await Permission.photos.request().isGranted || 
          await Permission.videos.request().isGranted) {
        return true;
      }
      // Android 12 and below
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      return false;
    }
    return true; // iOS usually handles this via plist
  }
}

// -----------------------------------------------------------------------------
// 📥 DOWNLOAD MANAGER (Singleton)
// -----------------------------------------------------------------------------
class DownloadManager {
  DownloadManager._internal();
  static final DownloadManager instance = DownloadManager._internal();

  final List<DownloadTask> _queue = [];
  final StreamController<List<DownloadTask>> _queueController = StreamController.broadcast();
  bool _isRunning = false;

  Stream<List<DownloadTask>> get stream => _queueController.stream;
  List<DownloadTask> get queue => List.unmodifiable(_queue);

  Future<void> enqueue(Map<String, dynamic> format, Map<String, dynamic> meta) async {
    final String url = format['url'] ?? '';
    final String title = meta['title'] ?? 'Unknown_Video';
    final String ext = format['ext'] ?? 'mp4';
    final String safeName = _sanitizeFilename("${title}_${format['resolution'] ?? 'HD'}.$ext");
    
    final dir = await _getDownloadDirectory();
    final savePath = '${dir.path}/$safeName';

    final task = DownloadTask(
      url: url, 
      savePath: savePath, 
      fileName: safeName,
      status: TaskStatus.pending
    );

    _queue.add(task);
    _queueController.add(_queue);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isRunning || _queue.isEmpty) return;
    _isRunning = true;

    while (_queue.isNotEmpty) {
      final task = _queue.first;
      task.status = TaskStatus.downloading;
      _queueController.add(_queue);

      try {
        await dioClient.download(
          task.url, 
          task.savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              task.progress = received / total;
              // Throttle updates slightly if needed
              _queueController.add(_queue); 
            }
          },
        );
        
        task.status = TaskStatus.completed;
        task.progress = 1.0;
        _queueController.add(_queue);
        
        // 🔥 FIX 2: Correct Notification Logic for 2026
        await _sendNotification(task);

        // Remove from queue after success (or move to history list)
        await Future.delayed(const Duration(seconds: 2));
        _queue.remove(task);
        _queueController.add(_queue);

      } catch (e) {
        task.status = TaskStatus.failed;
        _queueController.add(_queue);
        debugPrint("Download Failed: $e");
        await Future.delayed(const Duration(seconds: 3));
        _queue.remove(task); // Remove failed task for now
      }
    }
    _isRunning = false;
  }

  Future<void> _sendNotification(DownloadTask task) async {
    const androidDetails = AndroidNotificationDetails(
      'download_channel', 
      'Downloads',
      channelDescription: 'Notifications for completed downloads',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    
    await _notifPlugin.show(
      Random().nextInt(100000), // ID
      'Download Complete', // Title
      task.fileName, // Body
      const NotificationDetails(android: androidDetails, iOS: iosDetails), // Details
      payload: task.savePath // Payload
    );
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try to get public download folder
      Directory? dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        dir = await getExternalStorageDirectory();
      }
      return dir ?? await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }
}

enum TaskStatus { pending, downloading, completed, failed }

class DownloadTask {
  final String url;
  final String savePath;
  final String fileName;
  double progress;
  TaskStatus status;

  DownloadTask({
    required this.url,
    required this.savePath,
    required this.fileName,
    this.progress = 0.0,
    this.status = TaskStatus.pending,
  });
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
    final dir = await DownloadManager.instance._getDownloadDirectory();
    if (dir.existsSync()) {
      setState(() {
        _files = dir.listSync()
            .where((e) => e.path.endsWith('.mp4') || e.path.endsWith('.mp3'))
            .toList().reversed.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Downloads', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _loadFiles, icon: const Icon(CupertinoIcons.refresh, color: Color(0xFF00F0FF)))
              ],
            ),
          ),
          Expanded(
            child: _files.isEmpty
              ? const Center(child: Text("No downloads yet", style: TextStyle(color: Colors.white24)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final name = file.path.split('/').last;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        leading: const Icon(CupertinoIcons.play_circle_fill, color: Colors.white, size: 30),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                          onPressed: () {
                            file.deleteSync();
                            _loadFiles();
                          },
                        ),
                        onTap: () => _openFile(file.path),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  void _openFile(String path) {
    // Implement file opening logic (e.g., open_filex)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening: $path")));
  }
}

// -----------------------------------------------------------------------------
// ⏳ QUEUE PAGE
// -----------------------------------------------------------------------------
class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DownloadTask>>(
      stream: DownloadManager.instance.stream,
      initialData: DownloadManager.instance.queue,
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [Text('Active Queue', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold))],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                  ? const Center(child: Text("Queue is empty", style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.fileName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: task.progress,
                                backgroundColor: Colors.white10,
                                color: const Color(0xFF00F0FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(task.progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12)),
                                  Text(task.status.name.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
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
        padding: const EdgeInsets.all(20),
        children: [
          Text('Settings', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSettingItem(CupertinoIcons.cloud, "Clear Cache", () async {
            final cacheDir = await getTemporaryDirectory();
            if (cacheDir.existsSync()) {
              cacheDir.deleteSync(recursive: true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cache Cleared")));
            }
          }),
          _buildSettingItem(CupertinoIcons.info, "About LiquidSnap", () {}),
          _buildSettingItem(CupertinoIcons.lock, "Privacy Policy", () {}),
          const SizedBox(height: 40),
          Center(child: Text("Version 2.0.0 (Ultimate)", style: GoogleFonts.jetBrainsMono(color: Colors.white24))),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ⚡ QUICK ADD SHEET
// -----------------------------------------------------------------------------
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});
  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final TextEditingController _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Quick Download', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _c,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              hintText: 'Paste link here...',
              hintStyle: const TextStyle(color: Colors.white30),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(CupertinoIcons.doc_on_clipboard, color: Color(0xFF00F0FF)),
                onPressed: () async {
                   final data = await Clipboard.getData(Clipboard.kTextPlain);
                   if (data?.text != null) _c.text = data!.text!;
                },
              )
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Handle Add Logic (e.g. pass back to Home)
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Analyze & Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🧊 UI COMPONENTS (Glass & Cards)
// -----------------------------------------------------------------------------
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GlassContainer({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDownload;

  const ResultCard({super.key, required this.data, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final List formats = data['formats'] ?? [];
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (data['thumbnail'] != null)
            Image.network(
              data['thumbnail'], 
              height: 200, 
              width: double.infinity, 
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(height: 200, color: Colors.grey[900]),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Unknown Title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(CupertinoIcons.time, size: 14, color: Color(0xFF00F0FF)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(data['duration']),
                      style: const TextStyle(color: Color(0xFF00F0FF)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('AVAILABLE QUALITY', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: formats.map((f) => _buildFormatChip(f)).toList(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFormatChip(dynamic format) {
    final Map<String, dynamic> f = format;
    final bool isAudio = f['resolution'].toString().contains('Audio');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDownload(f),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isAudio ? Colors.orange.withOpacity(0.1) : Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isAudio ? Colors.orange.withOpacity(0.3) : Colors.cyan.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isAudio ? CupertinoIcons.music_note_2 : CupertinoIcons.film, size: 14, color: isAudio ? Colors.orange : Colors.cyan),
              const SizedBox(width: 6),
              Text(
                "${f['resolution']} • ${f['ext']?.toUpperCase()}",
                style: TextStyle(color: isAudio ? Colors.orange : Colors.cyan, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return "0:00";
    final int sec = duration is int ? duration : int.tryParse(duration.toString()) ?? 0;
    final d = Duration(seconds: sec);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(CupertinoIcons.link_circle, size: 80, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 20),
        Text("Ready to Snap?", style: GoogleFonts.outfit(fontSize: 22, color: Colors.white24)),
        const SizedBox(height: 8),
        const Text("Paste a link above to start downloading", style: TextStyle(color: Colors.white12)),
      ],
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}
