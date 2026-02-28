import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ========== 配置区域（老板你可以在这里修改）==========
class Config {
  // 提醒间隔时间（分钟）- 默认45分钟
  static const int REMINDER_INTERVAL_MINUTES = 45;

  // 顾昀台词列表 - 你可以随意添加、修改
  static const List<String> DIALOGUES = [
    "又看手机？眼睛还要不要了？",
    "站起来，活动一下筋骨。",
    "去给我打杯水喝。",
    "盯着屏幕多久了？自己数数。",
    "脖子僵了吧？转两圈。",
    "休息五分钟，不会耽误你大事。",
    "眼睛酸了才想起来我？晚了。",
    "起来走走，别让我说第二遍。",
  ];

  // 弹窗停留时间（秒）- 默认10秒
  static const int POPUP_DURATION = 10;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuYunApp());
}

class GuYunApp extends StatelessWidget {
  const GuYunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '顾昀健康提醒',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
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

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _showReminder();
          _remainingSeconds = Config.REMINDER_INTERVAL_MINUTES * 60;
        }
      });
    });
  }

  void _resetTimer() {
    setState(() {
      _remainingSeconds = Config.REMINDER_INTERVAL_MINUTES * 60;
    });
  }

  void _updateDialogue() {
    final random = Random();
    setState(() {
      _currentDialogue = Config.DIALOGUES[random.nextInt(Config.DIALOGUES.length)];
    });
  }

  Future<void> _showReminder() async {
    _updateDialogue();

    // 显示全屏弹窗
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ReminderDialog(
          dialogue: _currentDialogue,
          onConfirm: () {
            Navigator.of(context).pop();
            _resetTimer();
          },
        ),
      );

      // 自动关闭
      Future.delayed(const Duration(seconds: Config.POPUP_DURATION), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          _resetTimer();
        }
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '顾昀健康提醒',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            // 人物和气泡区域
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 顾昀图片
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Image.asset(
                      'assets/images/guyun.png',
                      width: 200,
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 300,
                          color: Colors.grey[200],
                          child: Icon(Icons.person, size: 100, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),

                  // 对话气泡
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        _currentDialogue,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 倒计时显示
            Text(
              '下次提醒: ${_formatTime(_remainingSeconds)}',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            // 状态标签
            Text(
              _isRunning ? '状态: 运行中' : '状态: 已暂停',
              style: TextStyle(
                fontSize: 14,
                color: _isRunning ? Colors.green : Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // 按钮区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReminder(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('测试提醒', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('重置计时', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 底部提示
            Text(
              '请保持应用在后台运行以确保提醒正常',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[300],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// 提醒弹窗组件
class ReminderDialog extends StatelessWidget {
  final String dialogue;
  final VoidCallback onConfirm;

  const ReminderDialog({
    super.key,
    required this.dialogue,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顾昀图片
            Image.asset(
              'assets/images/guyun.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, size: 100, color: Colors.grey[400]);
              },
            ),

            const SizedBox(height: 20),

            // 提醒文字
            Text(
              dialogue,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // 确认按钮
            ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('知道了，这就去', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
