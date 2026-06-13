import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cameras
  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Camera error: $e');
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
  
  runApp(TBApp());
}

class TBApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB Care Assistant',
      theme: ThemeData(
        primaryColor: Color(0xFF2563EB),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2563EB)),
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
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
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
                child: Icon(Icons.health_and_safety, size: 80, color: Color(0xFF2563EB)),
              ),
              SizedBox(height: 30),
              Text('TB Care Assistant', 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 10),
              Text('Your Partner in TB Treatment', 
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
    {'title': 'Track Your Medication', 'desc': 'Never miss a dose with smart reminders', 
     'icon': Icons.medication, 'color': Color(0xFF3B82F6)},
    {'title': 'Monitor Symptoms', 'desc': 'Log daily symptoms and track recovery', 
     'icon': Icons.favorite, 'color': Color(0xFF10B981)},
    {'title': 'Doctor Appointments', 'desc': 'Schedule and manage medical appointments', 
     'icon': Icons.calendar_today, 'color': Color(0xFFF59E0B)},
    {'title': 'Educational Resources', 'desc': 'Learn about TB treatment and stay informed', 
     'icon': Icons.school, 'color': Color(0xFF8B5CF6)},
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
                      color: _currentPage == index ? Color(0xFF2563EB) : Colors.grey[300],
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
    DashboardScreen(),
    PermissionScreen(),  // Permission status screen from your instruction
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Permissions'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard'), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(),
            SizedBox(height: 20),
            _buildStatsRow(),
            SizedBox(height: 20),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1E40AF)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back!', style: TextStyle(color: Colors.white70, fontSize: 14)),
          SizedBox(height: 5),
          Text('TB Patient', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Stay on track with your treatment', style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Medication', 'On Track', Icons.medication, Color(0xFF10B981))),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Symptoms', 'Monitor', Icons.favorite, Color(0xFFF59E0B))),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Appointments', 'Upcoming', Icons.calendar_today, Color(0xFF3B82F6))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About TB Treatment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text(
            '• Take medications regularly at the same time each day\n'
            '• Complete the full course of treatment (6-9 months)\n'
            '• Attend all follow-up appointments\n'
            '• Report any side effects to your doctor immediately\n'
            '• Maintain good nutrition during treatment',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class PermissionScreen extends StatefulWidget {
  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  Map<Permission, PermissionStatus> _permissionStatus = {};
  List<String> _logs = [];

  final List<Permission> _permissions = [
    Permission.camera,
    Permission.storage,
    Permission.location,
    Permission.notification,
    Permission.microphone,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ];

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    for (var permission in _permissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status;
      _addLog('${permission.toString().split('.').last}: ${status.toString().split('.').last}');
    }
    setState(() {});
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {
      _permissionStatus[permission] = status;
    });
    _addLog('${permission.toString().split('.').last}: Requested -> ${status.toString().split('.').last}');
  }

  Future<void> _requestAllPermissions() async {
    final statuses = await _permissions.request();
    setState(() {
      _permissionStatus = statuses;
    });
    _addLog('All permissions requested');
  }

  void _addLog(String log) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $log');
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.camera: return 'Camera';
      case Permission.storage: return 'Storage';
      case Permission.location: return 'Location';
      case Permission.notification: return 'Notifications';
      case Permission.microphone: return 'Microphone';
      case Permission.bluetooth: return 'Bluetooth';
      case Permission.bluetoothScan: return 'Bluetooth Scan';
      case Permission.bluetoothConnect: return 'Bluetooth Connect';
      default: return permission.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Permissions Status'), elevation: 0),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _requestAllPermissions,
              icon: Icon(Icons.checklist),
              label: Text('Request All Permissions'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF10B981),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _permissions.length,
              itemBuilder: (context, index) {
                final permission = _permissions[index];
                final status = _permissionStatus[permission];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      status?.isGranted ?? false ? Icons.check_circle : Icons.cancel,
                      color: status?.isGranted ?? false ? Colors.green : Colors.red,
                    ),
                    title: Text(_getPermissionName(permission)),
                    trailing: ElevatedButton(
                      onPressed: () => _requestPermission(permission),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status?.isGranted ?? false ? Colors.green : Color(0xFF2563EB),
                      ),
                      child: Text(status?.isGranted ?? false ? 'Granted' : 'Request'),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 200,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Permission Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(_logs[index], style: TextStyle(fontSize: 12)),
                      );
                    },
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

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.person, size: 50, color: Color(0xFF2563EB)),
            ),
            SizedBox(height: 12),
            Text('TB Patient', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('patient@email.com', style: TextStyle(fontSize: 14, color: Colors.grey)),
            SizedBox(height: 20),
            _buildInfoCard(),
            SizedBox(height: 20),
            _buildAboutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildInfoRow('App Version', '1.0.0'),
          Divider(),
          _buildInfoRow('Build Number', '1'),
          Divider(),
          _buildInfoRow('Flutter Version', '3.29.2'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About TB Care Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'This app helps TB patients track their treatment, '
            'manage medications, and stay connected with healthcare providers. '
            'Always consult your doctor for medical advice.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}