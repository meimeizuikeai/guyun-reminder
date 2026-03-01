import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class Config {
  static const int REMINDER_INTERVAL_MINUTES = 45;
  static const List<String> DIALOGUES = [
    "又看手机？眼睛还要不要了？",
    "站起来，活动一下筋骨。",
  ];
  static const int POPUP_DURATION = 10;
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayScreen());
  }
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});
  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  String _message = "该喝水了！";
  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null && mounted) setState(() => _message = data.toString());
    });
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('顾昀健康提醒', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400)),
            const SizedBox(height: 12),
            Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: () async => await FlutterOverlayWindow.closeOverlay(),
                child: const Text('知道了，关闭', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await notifications.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const GuYunApp());
}

class GuYunApp extends StatelessWidget {
  const GuYunApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: '顾昀健康提醒', home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _remainingSeconds = Config.REMINDER_INTERVAL_MINUTES * 60;
  Timer? _timer;
  bool _isRunning = false;
  String _currentDialogue = "我在这里盯着你呢。";
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _hasOverlayPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if ((await Permission.notification.status).isDenied) await Permission.notification.request();
    final overlayStatus = await FlutterOverlayWindow.isPermissionGranted();
    if (!overlayStatus) await FlutterOverlayWindow.requestPermission();
    if (mounted) setState(() => _hasOverlayPermission = overlayStatus);
  }

  void _startTimer() {
    _timer?.cancel();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _showReminder();
          _remainingSeconds = Config.REMINDER_INTERVAL_MINUTES * 60;
        }
      });
    });
  }

  void _resetTimer() => setState(() => _remainingSeconds = Config.REMINDER_INTERVAL_MINUTES * 60);

  void _updateDialogue() {
    setState(() => _currentDialogue = Config.DIALOGUES[Random().nextInt(Config.DIALOGUES.length)]);
  }

  Future<void> _showReminder() async {
    _updateDialogue();
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(pattern: [0, 500, 200, 500]);

    const androidDetails = AndroidNotificationDetails('guyun_reminder_channel', '顾昀健康提醒', importance: Importance.max, priority: Priority.high, fullScreenIntent: true);
    await _notifications.show(0, '顾昀健康提醒', _currentDialogue, const NotificationDetails(android: androidDetails));
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.shareData(_currentDialogue);
      } else {
        await FlutterOverlayWindow.showOverlay(height: 300, width: WindowSize.matchParent, alignment: OverlayAlignment.center, flag: OverlayFlag.defaultFlag, overlayTitle: '顾昀', overlayContent: _currentDialogue, enableDrag: true);
        await Future.delayed(const Duration(milliseconds: 300));
        await FlutterOverlayWindow.shareData(_currentDialogue);
      }
    } catch (e) {
      debugPrint('悬浮窗报错: $e');
    }
  }

  String _formatTime(int totalSeconds) => '${(totalSeconds ~/ 60).toString().padLeft(2, '0')}:${(totalSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('顾昀健康提醒', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_currentDialogue, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            Text(_formatTime(_remainingSeconds), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w200)),
            const Text('距下次提醒'),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _resetTimer, child: const Text('重置计时器')),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: _showReminder, child: const Text('立即测试提醒')),
              ],
            ),
            if (!_hasOverlayPermission) const Padding(padding: EdgeInsets.only(top: 20), child: Text('⚠️ 悬浮窗权限未授予，弹窗功能不可用', style: TextStyle(color: Colors.orange))),
          ],
        ),
      ),
    );
  }
}
