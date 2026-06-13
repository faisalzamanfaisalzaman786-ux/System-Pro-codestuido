import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(VoiceAssistantApp());
}

class VoiceAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Assistant',
      theme: ThemeData(
        primaryColor: Color(0xFF00A86B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF00A86B),
          primary: Color(0xFF00A86B),
        ),
        scaffoldBackgroundColor: Color(0xFF0A1A0F),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    await Future.delayed(Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isFirstTime ? OnboardingScreen() : HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00A86B), Color(0xFF006633)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chat, size: 80, color: Color(0xFF00A86B)),
              ),
              SizedBox(height: 30),
              Text('Command Assistant',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text('Type commands to control your phone',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 40),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {'title': 'Type Commands', 'desc': 'Type commands to control your phone', 
     'icon': Icons.keyboard, 'color': Color(0xFF00A86B)},
    {'title': 'Hardware Control', 'desc': 'Control Camera, Flashlight and more', 
     'icon': Icons.settings_remote, 'color': Color(0xFF00A86B)},
    {'title': 'Smart Responses', 'desc': 'Get intelligent responses to your commands', 
     'icon': Icons.chat, 'color': Color(0xFF00A86B)},
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => HomeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: page['color'].withOpacity(0.1), 
                          shape: BoxShape.circle
                        ),
                        child: Icon(page['icon'], size: 100, color: page['color']),
                      ),
                      SizedBox(height: 48),
                      Text(page['title'], 
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      Text(page['desc'], 
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, 
                      color: _currentPage == index ? Color(0xFF00A86B) : Colors.grey[300],
                    ),
                  )),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _currentPage == _pages.length - 1 
                      ? _complete() 
                      : _pageController.nextPage(
                          duration: Duration(milliseconds: 300), 
                          curve: Curves.easeInOut
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00A86B),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    AssistantScreen(),
    HardwareControlScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF00A86B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Hardware'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class AssistantScreen extends StatefulWidget {
  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, String>> _chatHistory = [];
  bool _isProcessing = false;
  
  final List<String> _suggestions = [
    'open camera', 'flash on', 'flash off', 'hello', 'time', 'date', 'help'
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _chatHistory.insert(0, {
      'role': 'assistant', 
      'message': '👋 Assalamu Alaikum! I am your command assistant.\n\n'
                 '✨ Try these commands:\n'
                 '• "open camera" - Launch camera\n'
                 '• "flash on/off" - Control flashlight\n'
                 '• "time" - Current time\n'
                 '• "date" - Today\'s date\n'
                 '• "help" - Show all commands\n\n'
                 '💡 Tap on any suggestion below or type your command!'
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
    ].request();
  }

  Future<void> _processCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _chatHistory.insert(0, {'role': 'user', 'message': command});
      _textController.clear();
    });
    
    await Future.delayed(Duration(milliseconds: 300));
    String response = await _executeCommand(command.toLowerCase());
    
    setState(() {
      _chatHistory.insert(0, {'role': 'assistant', 'message': response});
      _isProcessing = false;
    });
  }

  Future<String> _executeCommand(String command) async {
    // Camera Control
    if (command.contains('camera') || command.contains('کیمرہ')) {
      if (command.contains('open') || command.contains('chalao') || command.contains('آن')) {
        await _openCamera();
        return '📷 Opening camera...';
      }
      return '📷 Say "open camera" to launch camera.';
    }
    
    // Flashlight Control
    if (command.contains('flash') || command.contains('torch') || command.contains('ٹارچ')) {
      if (command.contains('on') || command.contains('chalao') || command.contains('آن')) {
        await _toggleFlashlight(true);
        return '🔦 Flashlight turned ON';
      } else if (command.contains('off') || command.contains('band') || command.contains('بند')) {
        await _toggleFlashlight(false);
        return '🔦 Flashlight turned OFF';
      }
      return '🔦 Say "flash on" or "flash off"';
    }
    
    // Time
    if (command.contains('time') || command.contains('وقت')) {
      final now = DateTime.now();
      return '⏰ Time is ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    }
    
    // Date
    if (command.contains('date') || command.contains('تاریخ')) {
      final now = DateTime.now();
      return '📅 Today is ${now.day}/${now.month}/${now.year}';
    }
    
    // Greetings
    if (command.contains('hello') || command.contains('hi') || command.contains('assalam') || command.contains('السلام')) {
      return '🌙 Assalamu Alaikum! How can I help you?';
    }
    
    // How are you
    if (command.contains('how are you') || command.contains('کیا حال')) {
      return '😊 I am doing great, thank you for asking!';
    }
    
    // Thanks
    if (command.contains('thank') || command.contains('شکریہ')) {
      return '🌟 You are welcome!';
    }
    
    // Help
    if (command.contains('help') || command.contains('commands') || command.contains('مدد')) {
      return '📋 Available Commands:\n\n'
             '📷 CAMERA\n• "open camera"\n\n'
             '🔦 FLASHLIGHT\n• "flash on"\n• "flash off"\n\n'
             '⏰ INFO\n• "time"\n• "date"\n\n'
             '💬 GREETINGS\n• "hello"\n• "how are you"\n• "thank you"\n\n'
             '❓ "help" - Show this menu';
    }
    
    return '🤔 I heard: "$command"\n\nSay "help" to see all available commands.';
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening camera...'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _toggleFlashlight(bool turnOn) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(turnOn ? 'Flashlight ON' : 'Flashlight OFF'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Assistant'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _chatHistory.clear();
                _addWelcomeMessage();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat History
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                final isUser = chat['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF00A86B) : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SelectableText(
                      chat['message']!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Suggestions
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(_suggestions[index]),
                    onPressed: () => _processCommand(_suggestions[index]),
                    backgroundColor: const Color(0xFF1E2A1E),
                    labelStyle: const TextStyle(color: Color(0xFF00A86B)),
                  ),
                );
              },
            ),
          ),
          
          // Processing Indicator
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Processing...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          
          // Text Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your command...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (value) => _processCommand(value),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A86B),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _processCommand(_textController.text),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HardwareControlScreen extends StatefulWidget {
  @override
  _HardwareControlScreenState createState() => _HardwareControlScreenState();
}

class _HardwareControlScreenState extends State<HardwareControlScreen> {
  bool _isFlashOn = false;
  
  Future<void> _toggleFlashlight() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isFlashOn = !_isFlashOn);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFlashOn ? 'Flashlight ON' : 'Flashlight OFF'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening camera...')));
    }
  }

  void _showCommands() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commands', style: TextStyle(color: Color(0xFF00A86B))),
        content: const Text(
          '• "open camera" - Open camera\n'
          '• "flash on" - Flashlight ON\n'
          '• "flash off" - Flashlight OFF\n'
          '• "time" - Current time\n'
          '• "date" - Today\'s date\n'
          '• "hello" - Greeting\n'
          '• "help" - Show commands',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hardware Control'), elevation: 0),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildControlCard('Flashlight', Icons.flashlight_on, _isFlashOn, _toggleFlashlight, Colors.amber),
          _buildControlCard('Camera', Icons.camera_alt, false, _openCamera, Colors.purple),
          _buildControlCard('Commands', Icons.chat, false, () {
            final homeState = context.findAncestorStateOfType<_HomeScreenState>();
            if (homeState != null) {
              homeState.setState(() => homeState._currentIndex = 0);
            }
          }, Colors.green),
          _buildControlCard('Help', Icons.help, false, _showCommands, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildControlCard(String title, IconData icon, bool isOn, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isOn ? color : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: Colors.white),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
            if (title == 'Flashlight')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(isOn ? 'ON' : 'OFF', style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _deviceName = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      setState(() => _deviceName = androidInfo.model);
    } catch (e) {
      setState(() => _deviceName = 'Unknown Device');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: const Icon(Icons.devices, color: Color(0xFF00A86B)),
              title: const Text('Device'),
              subtitle: Text(_deviceName),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive app notifications'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
              activeColor: const Color(0xFF00A86B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF00A86B)),
                  title: const Text('Camera Permission'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openAppSettings(),
                ),
                Divider(height: 1, color: Colors.grey[800]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text(
                  'Command Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00A86B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 2.0.0\nType commands to control your phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}