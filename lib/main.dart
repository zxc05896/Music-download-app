// lib/main.dart
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

// CONFIG
const String SERVER_URL = "https://music-download-app.fly.dev";
final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();
final Dio dioClient = Dio();

// ENTRY
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  _configureDio();
  runApp(const LiquidGlassApp());
}

Future<void> _initNotifications() async {
  const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
  await _notifPlugin.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));
}

void _configureDio() {
  dioClient.options = BaseOptions(
    connectTimeout: 30000,
    receiveTimeout: 30000,
    sendTimeout: 30000,
    headers: {'User-Agent': 'LiquidSnap/1.0.0'},
  );
  dioClient.interceptors.add(InterceptorsWrapper(onError: (e, handler) {
    handler.next(e);
  }));
}

// APP
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
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}

// MAIN LAYOUT
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
      extendBody: true,
      body: _pages[_index],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openQuickScanner(context),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(CupertinoIcons.plus, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 78,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(CupertinoIcons.home, 0),
              _navItem(CupertinoIcons.arrow_down_circle, 1),
              const SizedBox(width: 64),
              _navItem(CupertinoIcons.list_bullet, 2),
              _navItem(CupertinoIcons.settings, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int i) {
    final sel = _index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _index = i),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 10),
          Icon(icon, color: sel ? Colors.cyanAccent : Colors.white38, size: sel ? 28 : 22),
          const SizedBox(height: 6),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: sel ? Colors.cyanAccent : Colors.transparent, shape: BoxShape.circle))
        ]),
      ),
    );
  }

  void _openQuickScanner(BuildContext ctx) {
    showModalBottomSheet(context: ctx, backgroundColor: Colors.transparent, builder: (_) => const QuickAddSheet());
  }
}

// HOME PAGE
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _current;
  String? _error;
  bool _loading = false;
  StreamSubscription<ConnectivityResult>? _connSub;
  ConnectivityResult _connStatus = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();
    _observeConnectivity();
  }

  void _observeConnectivity() async {
    final c = Connectivity();
    _connStatus = await c.checkConnectivity();
    _connSub = c.onConnectivityChanged.listen((event) {
      setState(() => _connStatus = event);
      if (event == ConnectivityResult.none && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Internet")));
      }
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showSnack("Paste a link");
      return;
    }
    setState(() { _loading = true; _error = null; _current = null; });
    try {
      final uri = Uri.parse('$SERVER_URL/api/v1/extract');
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'url': url, 'include_audio': true})).timeout(const Duration(seconds: 40));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        if (j is Map<String, dynamic>) {
          setState(() => _current = j);
        } else {
          setState(() => _error = 'Invalid response');
        }
      } else if (resp.statusCode == 400) {
        final msg = _parseMessage(resp.body) ?? 'Bad request';
        setState(() => _error = msg);
      } else {
        setState(() => _error = 'Server ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _parseMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] != null) return j['error'].toString();
      if (j is Map && j['message'] != null) return j['message'].toString();
    } catch (_) {}
    return null;
  }

  void _showSnack(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(children: [
        Positioned(top: -150, right: -100, child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyan.withOpacity(0.06)))) ,
        Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.bolt_fill, color: Colors.cyanAccent)),
            const SizedBox(width: 12),
            Text('Liquid Snap', style: GoogleFonts.audiowide(fontSize: 22, color: Colors.white)),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.bell, color: Colors.white70)),
            const CircleAvatar(radius: 16, backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white, size: 18))
          ])),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: GlassBox(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(CupertinoIcons.search, color: Colors.white54),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _controller, style: const TextStyle(color: Colors.white), decoration: InputDecoration(border: InputBorder.none, hintText: 'Paste link...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))), onSubmitted: (_) => _fetchData())),
              IconButton(onPressed: _fetchData, icon: const Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.cyanAccent, size: 30))
            ]),
          )),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), children: [
            if (_loading) Center(child: Padding(padding: const EdgeInsets.all(30), child: CircularProgressIndicator(color: Colors.cyanAccent))),
            if (_error != null) ErrorCard(message: _error!),
            if (_current == null && !_loading && _error == null) EmptyState(),
            if (_current != null) ResultCard(data: _current!, onDownload: (format) async {
              await DownloadManager.instance.enqueue(format as Map<String, dynamic>, _current!);
              _showSnack("Queued for download");
            }),
          ]))
        ]),
      ]),
    );
  }
}

// WIDGETS
class GlassBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  const GlassBox({super.key, required this.child, this.radius = 20, this.padding});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: Container(padding: padding, decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white.withOpacity(0.06))), child: child)));
  }
}

class ErrorCard extends StatelessWidget {
  final String message;
  const ErrorCard({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(top: 18), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.withOpacity(0.18))), child: Row(children: [const Icon(Icons.error_outline, color: Colors.redAccent), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent)))]));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [const SizedBox(height: 80), Icon(CupertinoIcons.link, size: 80, color: Colors.white10), const SizedBox(height: 20), Text('Ready to download?', style: GoogleFonts.inter(fontSize: 20, color: Colors.white24)), Text('Paste a link above to start', style: GoogleFonts.inter(fontSize: 14, color: Colors.white12))]);
  }
}

class ResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onDownload;
  const ResultCard({super.key, required this.data, required this.onDownload});
  @override
  Widget build(BuildContext context) {
    final formats = (data['formats'] as List?) ?? [];
    final title = data['title'] ?? 'Unknown';
    final thumb = data['thumbnail'] ?? '';
    final duration = data['duration'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 10),
      const Padding(padding: EdgeInsets.only(left: 6, bottom: 8), child: Text('RESULT', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12))),
      GlassBox(radius: 18, padding: EdgeInsets.zero, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(alignment: Alignment.center, children: [
          if (thumb.isNotEmpty) Image.network(thumb, width: double.infinity, height: 220, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 220, color: Colors.grey[900])),
          Container(width: double.infinity, height: 220, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.72)]))),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.45))), child: const Icon(CupertinoIcons.play_fill, color: Colors.white, size: 30))
        ]),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [const Icon(CupertinoIcons.time, color: Colors.white54, size: 14), const SizedBox(width: 6), Text(_fmtDur(duration), style: const TextStyle(color: Colors.white54))])
        ])),
        const Divider(color: Colors.white10, height: 1),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AVAILABLE FORMATS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: formats.mapIndexed((i, f) {
            final m = Map<String, dynamic>.from(f as Map);
            return FormatChip(format: m, onTap: () => onDownload(m));
          }).toList())
        ]))
      ]))
    ]);
  }

  static String _fmtDur(dynamic s) {
    if (s == null) return '--:--';
    final int sec = (s is int) ? s : int.tryParse(s.toString()) ?? 0;
    final d = Duration(seconds: sec);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

class FormatChip extends StatelessWidget {
  final Map<String, dynamic> format;
  final VoidCallback onTap;
  const FormatChip({super.key, required this.format, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final bool audio = (format['resolution']?.toString().toLowerCase().contains('audio') ?? false);
    final Color base = audio ? Colors.orangeAccent : Colors.cyanAccent;
    final String label = '${format['resolution'] ?? 'Audio'} • ${(format['ext'] ?? '').toString().toUpperCase()}';
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: base.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: base.withOpacity(0.25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(audio ? CupertinoIcons.music_note_2 : CupertinoIcons.videocam_fill, color: base, size: 16), const SizedBox(width: 8), Text(label, style: TextStyle(color: base, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Icon(CupertinoIcons.cloud_download, size: 16, color: base.withOpacity(0.8))])));
  }
}

// DOWNLOAD MANAGER (singleton)
class DownloadManager {
  DownloadManager._internal();
  static final DownloadManager instance = DownloadManager._internal();

  final List<_DownloadTask> _queue = [];
  final StreamController<List<_DownloadTask>> _queueController = StreamController.broadcast();
  bool _running = false;

  Stream<List<_DownloadTask>> get stream => _queueController.stream;

  Future<void> enqueue(Map<String, dynamic> format, Map<String, dynamic> meta) async {
    final String url = format['url'] ?? '';
    final String fname = _sanitizeFilename('${meta['title'] ?? 'file'}_${format['resolution'] ?? 'format'}.${(format['ext'] ?? 'mp4')}');
    final dir = await _defaultDir();
    final path = '${dir.path}/$fname';
    final task = _DownloadTask(url: url, path: path, meta: meta, format: format);
    _queue.add(task);
    _queueController.add(_queue);
    _processQueue();
  }

  Future<Directory> _defaultDir() async {
    if (Platform.isAndroid) {
      final d = await getExternalStorageDirectory();
      if (d != null) {
        final downloads = Directory('${d.path}/Download');
        if (!downloads.existsSync()) downloads.createSync(recursive: true);
        return downloads;
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  void _processQueue() {
    if (_running) return;
    _running = true;
    _runLoop();
  }

  Future<void> _runLoop() async {
    while (_queue.isNotEmpty) {
      final task = _queue.first;
      try {
        await _performDownload(task);
        _queue.removeAt(0);
        _queueController.add(_queue);
      } catch (e) {
        task.attempts += 1;
        if (task.attempts >= 3) {
          _queue.removeAt(0);
          _queueController.add(_queue);
        } else {
          await Future.delayed(Duration(seconds: 2 * task.attempts));
        }
      }
    }
    _running = false;
  }

  Future<void> _performDownload(_DownloadTask task) async {
    final CancelToken cancelToken = CancelToken();
    final r = await dioClient.download(task.url, task.path, cancelToken: cancelToken, onReceiveProgress: (r, t) {
      task.progress = (t == 0) ? 0 : (r / t);
      _queueController.add(_queue);
    });
    if (r.statusCode == 200 || r.statusCode == 206) {
      await _notifyComplete(task);
    } else {
      throw Exception('Bad status ${r.statusCode}');
    }
  }

  Future<void> _notifyComplete(_DownloadTask task) async {
    final android = AndroidNotificationDetails('dl', 'Downloads', importance: Importance.high, priority: Priority.high);
    const ios = DarwinNotificationDetails();
    await _notifPlugin.show(Random().nextInt(9999), 'Download complete', task.path.split('/').last, NotificationDetails(android: android, iOS: ios), payload: task.path);
  }

  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  List<_DownloadTask> get queue => List.unmodifiable(_queue);
}

class _DownloadTask {
  final String url;
  final String path;
  final Map<String, dynamic> meta;
  final Map<String, dynamic> format;
  double progress = 0;
  int attempts = 0;
  _DownloadTask({required this.url, required this.path, required this.meta, required this.format});
}

// DOWNLOADS PAGE
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<FileSystemEntity> _files = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = DownloadManager.instance._queueController.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    final dir = await _getDir();
    if (!dir.existsSync()) return;
    final list = dir.listSync().whereType<File>().toList().reversed.toList();
    setState(() => _files = list);
  }

  Future<Directory> _getDir() async {
    if (Platform.isAndroid) {
      final d = await getExternalStorageDirectory();
      final downloads = Directory('${d!.path}/Download');
      if (!downloads.existsSync()) downloads.createSync(recursive: true);
      return downloads;
    }
    return await getApplicationDocumentsDirectory();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = DownloadManager.instance.queue;
    return SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [Text('Downloads', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer(), IconButton(onPressed: _load, icon: const Icon(CupertinoIcons.refresh))]),
      const SizedBox(height: 12),
      if (queue.isNotEmpty) GlassBox(radius: 12, padding: const EdgeInsets.all(12), child: Column(children: queue.map((t) => ListTile(leading: const Icon(CupertinoIcons.cloud_download), title: Text(t.path.split('/').last, style: const TextStyle(color: Colors.white)), subtitle: LinearProgressIndicator(value: t.progress, color: Colors.cyanAccent, backgroundColor: Colors.white10))).toList())),
      const SizedBox(height: 12),
      Expanded(child: _files.isEmpty ? Center(child: Text('No downloads yet', style: TextStyle(color: Colors.white24))) : ListView.builder(itemCount: _files.length, itemBuilder: (c, i) {
        final f = _files[i];
        final name = f.path.split('/').last;
        return ListTile(leading: const Icon(CupertinoIcons.doc), title: Text(name, style: const TextStyle(color: Colors.white)), trailing: PopupMenuButton(itemBuilder: (_) => [const PopupMenuItem(value: 'open', child: Text('Open')), const PopupMenuItem(value: 'share', child: Text('Share')), const PopupMenuItem(value: 'delete', child: Text('Delete'))], onSelected: (v) async {
          if (v == 'delete') { await File(f.path).delete(); _load(); }
          if (v == 'open') { await _openFile(f.path); }
          if (v == 'share') { /* implement share if needed */ }
        }));
      })),
    ])));
  }

  Future<void> _openFile(String path) async {
    final uri = Uri.file(path);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// QUEUE PAGE
class QueuePage extends StatefulWidget {
  const QueuePage({super.key});
  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  @override
  Widget build(BuildContext context) {
    final q = DownloadManager.instance.queue;
    return SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [Text('Queue', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer()]),
      const SizedBox(height: 12),
      if (q.isEmpty) Expanded(child: Center(child: Text('Queue empty', style: TextStyle(color: Colors.white24)))),
      if (q.isNotEmpty) Expanded(child: ListView.builder(itemCount: q.length, itemBuilder: (c, i) {
        final t = q[i];
        return ListTile(leading: const Icon(CupertinoIcons.cloud_download), title: Text(t.path.split('/').last, style: const TextStyle(color: Colors.white)), subtitle: LinearProgressIndicator(value: t.progress, color: Colors.cyanAccent, backgroundColor: Colors.white10), trailing: IconButton(icon: const Icon(CupertinoIcons.trash), onPressed: () {
          // simple cancel emulation
          DownloadManager.instance._queue.removeAt(i);
          setState(() {});
        }));
      })),
    ])));
  }
}

// SETTINGS PAGE
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String server = SERVER_URL;
  bool notifications = true;
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Row(children: [Text('Settings', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)), const Spacer()]),
      const SizedBox(height: 12),
      GlassBox(radius: 12, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        Expanded(child: TextFormField(initialValue: server, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Server URL', hintStyle: TextStyle(color: Colors.white24)), onChanged: (v) => server = v)),
        IconButton(onPressed: () async { if (await canLaunchUrl(Uri.parse(server))) await launchUrl(Uri.parse(server)); }, icon: const Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.cyanAccent))
      ])),
      const SizedBox(height: 12),
      ListTile(leading: const Icon(CupertinoIcons.bell), title: const Text('Notifications'), trailing: Switch(value: notifications, onChanged: (v) => setState(() => notifications = v))),
      ListTile(leading: const Icon(CupertinoIcons.cloud), title: const Text('Clear cache'), onTap: () async { await _clearCache(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared'))); }),
      const Spacer(),
      Text('Liquid Snap • build 1.0.0', style: TextStyle(color: Colors.white24)),
      const SizedBox(height: 20),
    ])));
  }

  Future<void> _clearCache() async {
    final dir = await getTemporaryDirectory();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

// QUICK ADD SHEET
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
      height: 220,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 18),
        Text('Quick add', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassBox(radius: 12, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [Expanded(child: TextField(controller: _c, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Paste link...'))), IconButton(onPressed: () async {
          final link = _c.text.trim();
          if (link.isEmpty) return;
          Navigator.of(context).pop();
        }, icon: const Icon(CupertinoIcons.arrow_right_circle_fill, color: Colors.cyanAccent))])),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(context).pop(), style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent), child: const Text('Add', style: TextStyle(color: Colors.black)))]),
      ]),
    );
  }
}

// UTILITIES
String safeFileName(String s) {
  return s.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}

Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
  return true;
}

// SIMPLE MOCKED SERVICE FOR TESTING
class ApiService {
  final String base;
  ApiService({required this.base});
  Future<Map<String, dynamic>> extract(String url) async {
    final uri = Uri.parse('$base/api/v1/extract');
    final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'url': url, 'include_audio': true}));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('API ${resp.statusCode}');
    }
  }
}

// EXTRA: Helpers for testing and debug
class DevTools {
  static Future<void> seedMockFile(String path, int kb) async {
    final file = File(path);
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    final sink = file.openWrite();
    final chunk = List<int>.filled(1024, 0);
    for (int i = 0; i < kb; i++) sink.add(chunk);
    await sink.close();
  }
  static String fmtBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// END OF FILE (partial big bundle)
