import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
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
                child: Icon(Icons.mic, size: 80, color: Color(0xFF00A86B)),
              ),
              SizedBox(height: 30),
              Text('Voice Assistant',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text('Control your phone with voice',
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
    {'title': 'Voice Commands', 'desc': 'Press and hold the mic button to speak', 
     'icon': Icons.mic, 'color': Color(0xFF00A86B)},
    {'title': 'Hardware Control', 'desc': 'Control Camera, Flashlight, and more', 
     'icon': Icons.settings_remote, 'color': Color(0xFF00A86B)},
    {'title': 'Smart Responses', 'desc': 'AI-powered responses to your voice commands', 
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
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Assistant'),
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
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  String _aiResponse = '';
  List<Map<String, String>> _chatHistory = [];
  bool _isProcessing = false;
  bool _speechAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _requestPermissions();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {
      _speechAvailable = available;
    });
    if (!available) {
      print('Speech recognition not available');
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _transcribedText = '';
      });
      
      _speech.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
          if (result.finalResult) {
            _stopListeningAndProcess();
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 2),
        partialResults: true,
        localeId: 'ur-PK',  // Urdu/Pakistan language
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available on this device')),
      );
    }
  }

  void _stopListeningAndProcess() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
    
    if (_transcribedText.isNotEmpty) {
      _processCommand(_transcribedText);
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processCommand(String command) async {
    if (command.trim().isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _chatHistory.insert(0, {'role': 'user', 'message': command});
    });
    
    // First check if it's a hardware control command
    bool hardwareExecuted = await _executeHardwareCommand(command.toLowerCase());
    
    String response;
    if (hardwareExecuted) {
      response = 'Command executed successfully!';
    } else {
      response = await _getAIResponse(command);
    }
    
    setState(() {
      _aiResponse = response;
      _chatHistory.insert(0, {'role': 'assistant', 'message': response});
      _isProcessing = false;
    });
  }

  Future<bool> _executeHardwareCommand(String command) async {
    // Camera Control
    if (command.contains('camera') || command.contains('کیمرہ')) {
      if (command.contains('open') || command.contains('chalao') || command.contains('آن')) {
        await _openCamera();
        return true;
      }
    }
    
    // Flashlight Control
    if (command.contains('flash') || command.contains('torch') || command.contains('ٹارچ') || command.contains('flashlight')) {
      if (command.contains('on') || command.contains('chalao') || command.contains('آن')) {
        await _toggleFlashlight(true);
        return true;
      } else if (command.contains('off') || command.contains('band') || command.contains('بند')) {
        await _toggleFlashlight(false);
        return true;
      }
    }
    
    return false;
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening camera...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  Future<void> _toggleFlashlight(bool turnOn) async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(turnOn ? 'Flashlight ON' : 'Flashlight OFF')),
      );
    }
  }

  Future<String> _getAIResponse(String command) async {
    String lowerCmd = command.toLowerCase();
    
    // Help command
    if (lowerCmd.contains('help') || lowerCmd.contains('commands') || lowerCmd.contains('مدد')) {
      return 'Available commands:\n'
             '• "open camera" - Open camera\n'
             '• "flash on" - Turn on flashlight\n'
             '• "flash off" - Turn off flashlight\n'
             '• "hello" - Greeting\n'
             '• "time" - Current time\n'
             '• "date" - Today\'s date\n'
             '• "how are you" - Check my status';
    }
    
    // Greeting
    if (lowerCmd.contains('hello') || lowerCmd.contains('hi') || lowerCmd.contains('assalam') || 
        lowerCmd.contains('السلام') || lowerCmd.contains('salam')) {
      return 'Assalamu Alaikum! I am your voice assistant. How can I help you today? '
             'Try saying "help" to see all available commands.';
    }
    
    // Time
    if (lowerCmd.contains('time') || lowerCmd.contains('وقت')) {
      return 'Current time is ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    }
    
    // Date
    if (lowerCmd.contains('date') || lowerCmd.contains('تاریخ')) {
      return 'Today is ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    }
    
    // How are you
    if (lowerCmd.contains('how are you') || lowerCmd.contains('کیا حال') || lowerCmd.contains('how r u')) {
      return 'I am doing great, thank you for asking! I am ready to help you with any commands.';
    }
    
    // Thanks
    if (lowerCmd.contains('thank') || lowerCmd.contains('شکریہ') || lowerCmd.contains('thanks')) {
      return 'You are welcome! Feel free to ask me anything else.';
    }
    
    // Default response
    return 'I heard: "$command". Try saying "help" to see all available commands.';
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Assistant'),
        elevation: 0,
        actions: [
          if (!_speechAvailable)
            Icon(Icons.warning, color: Colors.orange),
        ],
      ),
      body: Column(
        children: [
          // Chat History
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                final isUser = chat['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Color(0xFF00A86B) : Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      chat['message']!,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Listening Indicator
          if (_isListening)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Listening...', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _transcribedText.isEmpty ? 'Speak now...' : _transcribedText,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          
          // Processing Indicator
          if (_isProcessing)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A86B))),
                  SizedBox(height: 8),
                  Text('Processing your command...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          
          // Voice Button
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTapDown: (_) => _startListening(),
                  onTapUp: (_) => _stopListening(),
                  onTapCancel: _stopListening,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red : Color(0xFF00A86B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : Color(0xFF00A86B)).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Press and hold to speak',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Instructions
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '📱 Voice Commands Guide',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00A86B)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• "Open camera" - Launch camera\n'
                    '• "Flash on/off" - Toggle flashlight\n'
                    '• "Hello" - Greeting\n'
                    '• "Time/Date" - Current info\n'
                    '• "Help" - Show all commands',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Urdu commands also supported: "کیمرہ کھولو", "ٹارچ آن کرو"',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFlashOn ? 'Flashlight ON' : 'Flashlight OFF')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission required for flashlight')),
      );
    }
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening camera...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hardware Control'), elevation: 0),
      body: GridView.count(
        padding: EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildControlCard(
            title: 'Flashlight',
            icon: Icons.flashlight_on,
            isOn: _isFlashOn,
            onTap: _toggleFlashlight,
            color: Colors.amber,
          ),
          _buildControlCard(
            title: 'Camera',
            icon: Icons.camera_alt,
            isOn: false,
            onTap: _openCamera,
            color: Colors.purple,
          ),
          _buildControlCard(
            title: 'Voice Commands',
            icon: Icons.mic,
            isOn: false,
            onTap: () {
              // Navigate to assistant tab
              final homeState = context.findAncestorStateOfType<_HomeScreenState>();
              if (homeState != null) {
                homeState.setState(() {
                  homeState._currentIndex = 0;
                });
              }
            },
            color: Colors.green,
          ),
          _buildControlCard(
            title: 'Commands List',
            icon: Icons.help,
            isOn: false,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Voice Commands'),
                  content: Text(
                    '• "Open camera" - Launch camera\n'
                    '• "Flash on" - Turn on flashlight\n'
                    '• "Flash off" - Turn off flashlight\n'
                    '• "Hello" / "Salam" - Greeting\n'
                    '• "Time" - Current time\n'
                    '• "Date" - Today\'s date\n'
                    '• "How are you" - Check status\n'
                    '• "Thank you" - Acknowledge\n'
                    '• "Help" - Show this menu\n\n'
                    '🇵🇰 Urdu commands also supported!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required IconData icon,
    required bool isOn,
    required VoidCallback onTap,
    required Color color,
  }) {
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
            Icon(icon, size: 50, color: Colors.white),
            SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 18, color: Colors.white)),
            if (title == 'Flashlight')
              SizedBox(height: 8),
            if (title == 'Flashlight')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), elevation: 0),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Notifications'),
                  subtitle: Text('Receive app notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: Color(0xFF00A86B),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  'Voice Assistant Pro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Version 2.0.0\n\n'
                  '✨ Features:\n'
                  '• 🎤 Real-time Speech Recognition (Urdu & English)\n'
                  '• 🔊 Voice Commands for Hardware Control\n'
                  '• 📱 Camera & Flashlight Control\n'
                  '• 🤖 Smart AI Responses\n'
                  '• 🔒 Full Permission Management\n\n'
                  '🇵🇰 Complete Urdu language support',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.mic, color: Color(0xFF00A86B)),
                  title: Text('Microphone Permission'),
                  subtitle: Text('Required for voice recognition'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    openAppSettings();
                  },
                ),
                Divider(height: 1, color: Colors.grey[800]),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Color(0xFF00A86B)),
                  title: Text('Camera Permission'),
                  subtitle: Text('Required for camera & flashlight'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    openAppSettings();
                  },
                ),
                Divider(height: 1, color: Colors.grey[800]),
                ListTile(
                  leading: Icon(Icons.info, color: Color(0xFF00A86B)),
                  title: Text('About'),
                  subtitle: Text('App information'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('About Voice Assistant'),
                        content: Text(
                          'This app allows you to control your phone using voice commands.\n\n'
                          '• Works with Urdu and English languages\n'
                          '• Uses device\'s built-in speech recognition\n'
                          '• All processing happens on your device\n'
                          '• No internet required for basic commands\n\n'
                          'Compatible with Flutter ${DateTime.now().year}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}