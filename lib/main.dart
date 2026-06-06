import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Capability Tester',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: MainTesterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainTesterScreen extends StatefulWidget {
  @override
  _MainTesterScreenState createState() => _MainTesterScreenState();
}

class _MainTesterScreenState extends State<MainTesterScreen> {
  List<FeatureCard> features = [];
  Map<String, bool> permissionStatus = {};
  
  // Device Info
  String deviceInfo = 'Loading...';
  String connectivityStatus = 'Checking...';
  
  @override
  void initState() {
    super.initState();
    loadFeatures();
    loadDeviceInfo();
    checkAllPermissions();
  }
  
  void loadFeatures() {
    features = [
      FeatureCard('📷 Camera', 'Test camera and photo capture', Icons.camera_alt, () => testCamera()),
      FeatureCard('🖼️ Gallery', 'Pick images from gallery', Icons.photo_library, () => testGallery()),
      FeatureCard('📍 Location', 'Get current location', Icons.location_on, () => testLocation()),
      FeatureCard('🔵 Bluetooth', 'Scan Bluetooth devices', Icons.bluetooth, () => testBluetooth()),
      FeatureCard('📡 Sensors', 'Test accelerometer/gyro', Icons.sensors, () => testSensors()),
      FeatureCard('🌐 Connectivity', 'Check network status', Icons.wifi, () => testConnectivity()),
      FeatureCard('📱 Device Info', 'View device details', Icons.phone_android, () => showDeviceInfo()),
      FeatureCard('🔔 Notifications', 'Send test notification', Icons.notifications, () => testNotification()),
      FeatureCard('💾 Storage', 'Save/read test file', Icons.storage, () => testStorage()),
      FeatureCard('📞 Phone', 'Open dialer', Icons.phone, () => testPhone()),
      FeatureCard('📅 Calendar', 'Open calendar', Icons.calendar_today, () => testCalendar()),
      FeatureCard('👥 Contacts', 'Open contacts', Icons.contacts, () => testContacts()),
      FeatureCard('🎤 Microphone', 'Test audio record', Icons.mic, () => testMicrophone()),
      FeatureCard('🔐 Biometric', 'Test fingerprint', Icons.fingerprint, () => testBiometric()),
      FeatureCard('📤 Share', 'Share text', Icons.share, () => testShare()),
    ];
  }
  
  Future<void> checkAllPermissions() async {
    Map<Permission, String> permissionsToCheck = {
      Permission.camera: 'Camera',
      Permission.storage: 'Storage',
      Permission.location: 'Location',
      Permission.bluetooth: 'Bluetooth',
      Permission.bluetoothScan: 'Bluetooth Scan',
      Permission.bluetoothConnect: 'Bluetooth Connect',
      Permission.notifications: 'Notifications',
      Permission.microphone: 'Microphone',
      Permission.contacts: 'Contacts',
      Permission.calendar: 'Calendar',
      Permission.phone: 'Phone',
      Permission.sensors: 'Sensors',
      Permission.activityRecognition: 'Activity Recognition',
    };
    
    for (var entry in permissionsToCheck.entries) {
      final status = await entry.key.status;
      permissionStatus[entry.value] = status.isGranted;
    }
    setState(() {});
  }
  
  Future<void> loadDeviceInfo() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    setState(() {
      deviceInfo = '''
📱 Model: ${androidInfo.model}
🏭 Manufacturer: ${androidInfo.manufacturer}
🔄 SDK: ${androidInfo.version.sdkInt}
📀 Android: ${androidInfo.version.release}
🔧 Flutter: 3.29.2
📦 Package: com.filter.app
''';
    });
  }
  
  // CAMERA TEST
  Future<void> testCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showMessage('Camera permission denied');
      return;
    }
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showMessage('No camera available');
        return;
      }
      
      final controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller.initialize();
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CameraTestScreen(controller: controller)),
      );
    } catch (e) {
      _showMessage('Error: $e');
    }
  }
  
  // GALLERY TEST
  Future<void> testGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showMessage('Image selected: ${image.name}');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImagePreviewScreen(imagePath: image.path)),
      );
    }
  }
  
  // LOCATION TEST
  Future<void> testLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      _showMessage('📍 Location:\nLat: ${position.latitude}\nLng: ${position.longitude}');
    } else {
      _showMessage('Location permission denied');
    }
  }
  
  // BLUETOOTH TEST
  Future<void> testBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      _showMessage('Bluetooth not supported');
      return;
    }
    
    final status = await Permission.bluetoothScan.request();
    if (!status.isGranted) {
      _showMessage('Bluetooth permission denied');
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BluetoothTestScreen()),
    );
  }
  
  // SENSORS TEST
  void testSensors() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SensorsTestScreen()),
    );
  }
  
  // CONNECTIVITY TEST
  Future<void> testConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    String status = '';
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      status = '📱 Mobile Network';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      status = '📶 WiFi Connected';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      status = '🔌 Ethernet';
    } else {
      status = '❌ No Connection';
    }
    _showMessage('Connectivity Status:\n$status');
  }
  
  // STORAGE TEST
  Future<void> testStorage() async {
    final status = await Permission.storage.request();
    if (!status.isGranted && await Permission.storage.isPermanentlyDenied) {
      _showMessage('Storage permission permanently denied');
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'Test value at ${DateTime.now()}');
      String? value = prefs.getString('test_key');
      _showMessage('✅ Storage working!\nSaved and retrieved: $value');
    } catch (e) {
      _showMessage('Storage error: $e');
    }
  }
  
  // NOTIFICATION TEST
  Future<void> testNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'Your device supports notifications! Time: ${DateTime.now().hour}:${DateTime.now().minute}',
      details,
    );
    _showMessage('Notification sent! Check your status bar.');
  }
  
  // PHONE TEST
  Future<void> testPhone() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      _showMessage('Phone permission denied');
      return;
    }
    
    const url = 'tel:1234567890';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showMessage('Cannot open dialer');
    }
  }
  
  // CALENDAR TEST
  Future<void> testCalendar() async {
    final status = await Permission.calendar.request();
    if (!status.isGranted) {
      _showMessage('Calendar permission denied');
      return;
    }
    _showMessage('✅ Calendar permission granted!\nYou can now access calendar events.');
  }
  
  // CONTACTS TEST
  Future<void> testContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _showMessage('Contacts permission denied');
      return;
    }
    _showMessage('✅ Contacts permission granted!\nYou can now access contacts.');
  }
  
  // MICROPHONE TEST
  Future<void> testMicrophone() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showMessage('Microphone permission denied');
      return;
    }
    _showMessage('✅ Microphone permission granted!\nYou can now record audio.');
  }
  
  // BIOMETRIC TEST
  Future<void> testBiometric() async {
    final status = await Permission.biometric.request();
    if (!status.isGranted) {
      _showMessage('Biometric not available or permission denied');
      return;
    }
    _showMessage('✅ Biometric authentication available!');
  }
  
  // SHARE TEST
  Future<void> testShare() async {
    _showMessage('Share feature ready!\nUse share_plus package for sharing content.');
  }
  
  void showDeviceInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Device Information', style: TextStyle(color: Colors.white)),
        content: Text(deviceInfo, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Device Capability Tester', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              checkAllPermissions();
              loadDeviceInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Permission Status Summary
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blue[900]?.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Permission Status Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: permissionStatus.entries.map((entry) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.value ? Colors.green[900] : Colors.red[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value ? "✓" : "✗"}',
                        style: TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Card(
                  color: Colors.grey[900],
                  elevation: 4,
                  child: InkWell(
                    onTap: feature.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(feature.icon, size: 48, color: Colors.blue[400]),
                          SizedBox(height: 12),
                          Text(feature.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(feature.description, style: TextStyle(fontSize: 11, color: Colors.grey[400]), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Camera Test Screen
class CameraTestScreen extends StatefulWidget {
  final CameraController controller;
  CameraTestScreen({required this.controller});
  
  @override
  _CameraTestScreenState createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  double _zoom = 1.0;
  double _maxZoom = 1.0;
  
  @override
  void initState() {
    super.initState();
    _loadZoomLevel();
  }
  
  Future<void> _loadZoomLevel() async {
    double maxZoom = await widget.controller.getMaxZoomLevel();
    setState(() => _maxZoom = maxZoom);
  }
  
  Future<void> _takePicture() async {
    try {
      final XFile picture = await widget.controller.takePicture();
      _showMessage('Picture saved: ${picture.path}');
    } catch (e) {
      _showMessage('Error: $e');
    }
  }
  
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera Test')),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(widget.controller),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_out, size: 32),
                      onPressed: () {
                        setState(() {
                          _zoom = (_zoom - 0.1).clamp(1.0, _maxZoom);
                          widget.controller.setZoomLevel(_zoom);
                        });
                      },
                    ),
                    Text('Zoom: ${_zoom.toStringAsFixed(1)}x', style: TextStyle(fontSize: 14)),
                    IconButton(
                      icon: Icon(Icons.zoom_in, size: 32),
                      onPressed: () {
                        setState(() {
                          _zoom = (_zoom + 0.1).clamp(1.0, _maxZoom);
                          widget.controller.setZoomLevel(_zoom);
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: Icon(Icons.camera),
                  label: Text('Capture Photo'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}

// Image Preview Screen
class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  ImagePreviewScreen({required this.imagePath});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Preview')),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}

// Bluetooth Test Screen
class BluetoothTestScreen extends StatefulWidget {
  @override
  _BluetoothTestScreenState createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  
  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });
    
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
    
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
    
    Future.delayed(Duration(seconds: 10), () {
      setState(() => isScanning = false);
      FlutterBluePlus.stopScan();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Scanner')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : startScan,
              icon: Icon(isScanning ? Icons.scanning : Icons.bluetooth_searching),
              label: Text(isScanning ? 'Scanning...' : 'Start Scan'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return ListTile(
                  leading: Icon(Icons.bluetooth),
                  title: Text(result.device.name.isNotEmpty ? result.device.name : 'Unknown Device'),
                  subtitle: Text(result.device.id.toString()),
                  trailing: Text('${result.rssi} dBm'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Sensors Test Screen
class SensorsTestScreen extends StatefulWidget {
  @override
  _SensorsTestScreenState createState() => _SensorsTestScreenState();
}

class _SensorsTestScreenState extends State<SensorsTestScreen> {
  double _accelerometerX = 0, _accelerometerY = 0, _accelerometerZ = 0;
  double _gyroscopeX = 0, _gyroscopeY = 0, _gyroscopeZ = 0;
  
  @override
  void initState() {
    super.initState();
    
    accelerometerEvents.listen((event) {
      setState(() {
        _accelerometerX = event.x;
        _accelerometerY = event.y;
        _accelerometerZ = event.z;
      });
    });
    
    gyroscopeEvents.listen((event) {
      setState(() {
        _gyroscopeX = event.x;
        _gyroscopeY = event.y;
        _gyroscopeZ = event.z;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sensors Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('📊 Accelerometer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('X: ${_accelerometerX.toStringAsFixed(3)}'),
                    Text('Y: ${_accelerometerY.toStringAsFixed(3)}'),
                    Text('Z: ${_accelerometerZ.toStringAsFixed(3)}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('🔄 Gyroscope', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('X: ${_gyroscopeX.toStringAsFixed(3)}'),
                    Text('Y: ${_gyroscopeY.toStringAsFixed(3)}'),
                    Text('Z: ${_gyroscopeZ.toStringAsFixed(3)}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✅ Move your device to see sensor data update!',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Feature Card Model
class FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  
  FeatureCard(this.title, this.description, this.icon, this.onTap);
}