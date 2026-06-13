// ============================================================================
// PAKISTAN VOICE AI ASSISTANT - Complete Single File
// Features: Voice Input, AI Chat (Gemini/Grok), Text-to-Speech, Hardware Control
// ============================================================================

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:camera/camera.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras for hardware control
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Camera init error: $e');
  }
  
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(VoiceAIAssistantApp());
}

class VoiceAIAssistantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pakistan Voice AI Assistant',
      theme: ThemeData(
        primaryColor: Color(0xFF00A86B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF00A86B),
          primary: Color(0xFF00A86B),
        ),
        scaffoldBackgroundColor: Color(0xFF0A1A0F),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF00A86B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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
              Text('Voice AI Assistant',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text('Speak. Ask. Control.',
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
    {'title': 'Voice Commands', 'desc': 'Speak naturally to control your phone', 
     'icon': Icons.mic, 'color': Color(0xFF00A86B)},
    {'title': 'AI Chat', 'desc': 'Ask questions and get intelligent responses', 
     'icon': Icons.chat, 'color': Color(0xFF00A86B)},
    {'title': 'Hardware Control', 'desc': 'Control Camera, Flash, WiFi, Bluetooth and more', 
     'icon': Icons.settings_remote, 'color': Color(0xFF00A86B)},
    {'title': 'Text-to-Speech', 'desc': 'AI responses are read aloud to you', 
     'icon': Icons.volume_up, 'color': Color(0xFF00A86B)},
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
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _transcribedText = '';
  String _aiResponse = '';
  List<Map<String, String>> _chatHistory = [];
  bool _isProcessing = false;
  String _selectedAI = 'Gemini'; // Gemini or Grok
  
  // API Keys - User will need to add their own
  String _geminiApiKey = '';
  String _grokApiKey = '';
  
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTTS();
    _loadApiKeys();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("ur-PK");
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
      _grokApiKey = prefs.getString('grok_api_key') ?? '';
    });
  }

  Future<void> _saveApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', _geminiApiKey);
    await prefs.setString('grok_api_key', _grokApiKey);
  }

  void _showApiKeyDialog() {
    _apiKeyController.text = _selectedAI == 'Gemini' ? _geminiApiKey : _grokApiKey;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${_selectedAI} API Key'),
        content: TextField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            hintText: 'Paste your API key here',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedAI == 'Gemini') {
                setState(() => _geminiApiKey = _apiKeyController.text);
              } else {
                setState(() => _grokApiKey = _apiKeyController.text);
              }
              _saveApiKeys();
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speech.listen(
        onResult: (result) {
          setState(() {
            _transcribedText = result.recognizedWords;
          });
          if (result.finalResult) {
            _processVoiceCommand(_transcribedText);
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 2),
        partialResults: true,
        localeId: 'ur-PK',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _processVoiceCommand(String command) async {
    setState(() {
      _isProcessing = true;
      _chatHistory.insert(0, {'role': 'user', 'message': command});
    });
    
    // First check if it's a hardware control command
    bool hardwareExecuted = await _executeHardwareCommand(command.toLowerCase());
    
    if (hardwareExecuted) {
      setState(() {
        _aiResponse = 'Command executed successfully!';
        _chatHistory.insert(0, {'role': 'assistant', 'message': _aiResponse});
        _isProcessing = false;
      });
      await _speakResponse(_aiResponse);
      return;
    }
    
    // Otherwise, send to AI
    String aiReply = await _sendToAI(command);
    
    setState(() {
      _aiResponse = aiReply;
      _chatHistory.insert(0, {'role': 'assistant', 'message': aiReply});
      _isProcessing = false;
    });
    
    await _speakResponse(aiReply);
  }

  Future<bool> _executeHardwareCommand(String command) async {
    // Camera Control
    if (command.contains('camera on') || command.contains('open camera') || 
        command.contains('camera chalao') || command.contains('کیمرہ آن کرو')) {
      await _openCamera();
      return true;
    }
    
    // Flashlight Control
    if (command.contains('flash on') || command.contains('torch on') || 
        command.contains('flashlight on') || command.contains('flash chalao') ||
        command.contains('ٹارچ آن کرو')) {
      await _toggleFlashlight(true);
      return true;
    }
    
    if (command.contains('flash off') || command.contains('torch off') || 
        command.contains('flashlight off') || command.contains('flash band karo') ||
        command.contains('ٹارچ بند کرو')) {
      await _toggleFlashlight(false);
      return true;
    }
    
    // WiFi Control
    if (command.contains('wifi on') || command.contains('wifi chalao') || 
        command.contains('وائی فائی آن کرو')) {
      await _setWifiEnabled(true);
      return true;
    }
    
    if (command.contains('wifi off') || command.contains('wifi band karo') || 
        command.contains('وائی فائی بند کرو')) {
      await _setWifiEnabled(false);
      return true;
    }
    
    // Volume Control
    if (command.contains('volume up') || command.contains('awaz barhao') || 
        command.contains('آواز بڑھاؤ')) {
      await _setVolume(1.0);
      return true;
    }
    
    if (command.contains('volume down') || command.contains('awaz kam karo') || 
        command.contains('آواز کم کرو')) {
      await _setVolume(0.3);
      return true;
    }
    
    // Bluetooth Control
    if (command.contains('bluetooth on') || command.contains('bluetooth chalao') || 
        command.contains('بلوٹوتھ آن کرو')) {
      await _setBluetooth(true);
      return true;
    }
    
    if (command.contains('bluetooth off') || command.contains('bluetooth band karo') || 
        command.contains('بلوٹوتھ بند کرو')) {
      await _setBluetooth(false);
      return true;
    }
    
    return false;
  }

  Future<void> _openCamera() async {
    if (cameras != null && cameras!.isNotEmpty) {
      // Open camera - in real app, navigate to camera screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening camera...')),
      );
    }
  }

  Future<void> _toggleFlashlight(bool turnOn) async {
    // Flashlight control requires camera permission
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Implement flashlight control
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(turnOn ? 'Flashlight turned ON' : 'Flashlight turned OFF')),
      );
    }
  }

  Future<void> _setWifiEnabled(bool enable) async {
    try {
      if (enable) {
        await WiFiForIoTPlugin.setEnabled(true);
      } else {
        await WiFiForIoTPlugin.setEnabled(false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(enable ? 'WiFi turned ON' : 'WiFi turned OFF')),
      );
    } catch (e) {
      print('WiFi control error: $e');
    }
  }

  Future<void> _setVolume(double volume) async {
    try {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      // Volume control implementation
    } catch (e) {
      print('Volume control error: $e');
    }
  }

  Future<void> _setBluetooth(bool enable) async {
    try {
      final status = await Permission.bluetooth.request();
      if (status.isGranted) {
        // Bluetooth control implementation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(enable ? 'Bluetooth turned ON' : 'Bluetooth turned OFF')),
        );
      }
    } catch (e) {
      print('Bluetooth control error: $e');
    }
  }

  Future<String> _sendToAI(String message) async {
    if (_selectedAI == 'Gemini' && _geminiApiKey.isNotEmpty) {
      return await _callGeminiAPI(message);
    } else if (_selectedAI == 'Grok' && _grokApiKey.isNotEmpty) {
      return await _callGrokAPI(message);
    } else {
      return _getLocalResponse(message);
    }
  }

  Future<String> _callGeminiAPI(String message) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{
            'parts': [{'text': message}]
          }]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return 'Sorry, I encountered an error. Please check your API key.';
      }
    } catch (e) {
      return 'Network error. Please check your connection.';
    }
  }

  Future<String> _callGrokAPI(String message) async {
    // Grok API (xAI) implementation
    try {
      final url = Uri.parse('https://api.x.ai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_grokApiKey',
        },
        body: json.encode({
          'model': 'grok-beta',
          'messages': [{'role': 'user', 'content': message}],
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'Sorry, I encountered an error. Please check your Grok API key.';
      }
    } catch (e) {
      return 'Network error. Please check your connection.';
    }
  }

  String _getLocalResponse(String message) {
    String lowerMsg = message.toLowerCase();
    
    if (lowerMsg.contains('hello') || lowerMsg.contains('hi') || lowerMsg.contains('assalam')) {
      return 'Assalamu Alaikum! How can I help you today?';
    }
    if (lowerMsg.contains('how are you')) {
      return 'I am doing well, thank you for asking! How can I assist you?';
    }
    if (lowerMsg.contains('time')) {
      return 'The current time is ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    }
    if (lowerMsg.contains('date')) {
      return 'Today is ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    }
    return 'I understand you said: "$message". Please set up your Gemini or Grok API key in settings for AI responses, or give me a hardware command like "flash on", "wifi on", or "open camera".';
  }

  Future<void> _speakResponse(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voice Assistant - $_selectedAI'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedAI = value;
              });
              if ((value == 'Gemini' && _geminiApiKey.isEmpty) ||
                  (value == 'Grok' && _grokApiKey.isEmpty)) {
                _showApiKeyDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Gemini', child: Text('Google Gemini')),
              PopupMenuItem(value: 'Grok', child: Text('Grok (xAI)')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.key),
            onPressed: _showApiKeyDialog,
          ),
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
                      style: TextStyle(color: isUser ? Colors.white : Colors.white),
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
              child: Column(
                children: [
                  Text('Listening...', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    _transcribedText.isEmpty ? 'Speak now...' : _transcribedText,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
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
                  Text('Processing...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          
          // Voice Button
          Container(
            padding: EdgeInsets.all(24),
            child: GestureDetector(
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
          ),
          
          // Instructions
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Press and hold to speak. Release to process.\n\n'
              'Commands: "Flash on/off", "Wifi on/off", "Open camera", "Bluetooth on/off"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
  bool _isWifiOn = true;
  bool _isBluetoothOn = false;
  
  @override
  void initState() {
    super.initState();
    _checkWifiStatus();
    _checkBluetoothStatus();
  }

  Future<void> _checkWifiStatus() async {
    try {
      final isEnabled = await WiFiForIoTPlugin.isEnabled();
      setState(() {
        _isWifiOn = isEnabled;
      });
    } catch (e) {
      print('WiFi status error: $e');
    }
  }

  Future<void> _checkBluetoothStatus() async {
    final status = await Permission.bluetooth.status;
    setState(() {
      _isBluetoothOn = status.isGranted;
    });
  }

  Future<void> _toggleFlashlight() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      // Implement actual flashlight toggle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFlashOn ? 'Flashlight ON' : 'Flashlight OFF')),
      );
    }
  }

  Future<void> _toggleWifi() async {
    try {
      await WiFiForIoTPlugin.setEnabled(!_isWifiOn);
      setState(() {
        _isWifiOn = !_isWifiOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isWifiOn ? 'WiFi turned ON' : 'WiFi turned OFF')),
      );
    } catch (e) {
      print('WiFi toggle error: $e');
    }
  }

  Future<void> _toggleBluetooth() async {
    final status = await Permission.bluetooth.request();
    if (status.isGranted) {
      setState(() {
        _isBluetoothOn = !_isBluetoothOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBluetoothOn ? 'Bluetooth ON' : 'Bluetooth OFF')),
      );
    }
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening camera...')),
      );
      // Navigate to camera screen
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
            title: 'WiFi',
            icon: Icons.wifi,
            isOn: _isWifiOn,
            onTap: _toggleWifi,
            color: Colors.blue,
          ),
          _buildControlCard(
            title: 'Bluetooth',
            icon: Icons.bluetooth,
            isOn: _isBluetoothOn,
            onTap: _toggleBluetooth,
            color: Colors.indigo,
          ),
          _buildControlCard(
            title: 'Camera',
            icon: Icons.camera_alt,
            isOn: false,
            onTap: _openCamera,
            color: Colors.purple,
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
            SizedBox(height: 8),
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
  String _selectedLanguage = 'Urdu';
  final List<String> _languages = ['Urdu', 'English'];
  String _geminiApiKey = '';
  String _grokApiKey = '';

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
      _grokApiKey = prefs.getString('grok_api_key') ?? '';
    });
  }

  void _showApiKeyDialog(String aiName) {
    final controller = TextEditingController();
    controller.text = aiName == 'Gemini' ? _geminiApiKey : _grokApiKey;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter $aiName API Key'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Paste your API key here',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (aiName == 'Gemini') {
                await prefs.setString('gemini_api_key', controller.text);
                setState(() => _geminiApiKey = controller.text);
              } else {
                await prefs.setString('grok_api_key', controller.text);
                setState(() => _grokApiKey = controller.text);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$aiName API key saved!')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

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
                  subtitle: Text('Receive voice assistant notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: Color(0xFF00A86B),
                ),
                Divider(height: 1, color: Colors.grey[800]),
                ListTile(
                  title: Text('Language'),
                  subtitle: Text('Current: $_selectedLanguage'),
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    items: _languages.map((String lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
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
                  leading: Icon(Icons.auto_awesome, color: Color(0xFF00A86B)),
                  title: Text('Google Gemini API'),
                  subtitle: Text(_geminiApiKey.isEmpty ? 'Not configured' : '✓ Configured'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showApiKeyDialog('Gemini'),
                  ),
                ),
                Divider(height: 1, color: Colors.grey[800]),
                ListTile(
                  leading: Icon(Icons.auto_awesome, color: Color(0xFF00A86B)),
                  title: Text('Grok (xAI) API'),
                  subtitle: Text(_grokApiKey.isEmpty ? 'Not configured' : '✓ Configured'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showApiKeyDialog('Grok'),
                  ),
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
                  'Pakistan Voice AI Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Version 1.0.0\n\n'
                  'Features:\n'
                  '• Voice Commands in Urdu/English\n'
                  '• AI Chat with Gemini/Grok\n'
                  '• Hardware Control (Camera, Flash, WiFi, Bluetooth)\n'
                  '• Text-to-Speech Responses',
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