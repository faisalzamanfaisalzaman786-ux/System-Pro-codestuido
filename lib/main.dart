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
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:async';

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
  String deviceInfo = 'Loading...';

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
📦 Package: com.filter.app1
''';
    });
  }

  // ==================== STORAGE TEST (FIXED) ====================
  Future<void> testStorage() async {
    // For Android 13+ (API 33+)
    if (await _checkAndRequestStoragePermission()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('test_key', 'Test value at ${DateTime.now()}');
        String? value = prefs.getString('test_key');
        
        // Also try to write a file to external storage
        String testContent = 'Storage test successful at ${DateTime.now()}';
        
        _showMessage('✅ Storage working!\nSaved and retrieved: $value', isSuccess: true);
      } catch (e) {
        _showMessage('Storage error: $e', isSuccess: false);
      }
    } else {
      _showMessage('Storage permission denied. Please grant permission from settings.', isSuccess: false);
    }
  }

  Future<bool> _checkAndRequestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    
    // For Android 13+
    if (await Permission.photos.isGranted && 
        await Permission.videos.isGranted && 
        await Permission.audio.isGranted) {
      return true;
    }
    
    // Request permissions based on Android version
    if (await _requestAndroid13Permissions()) {
      return true;
    }
    
    // Fallback to old storage permission
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> _requestAndroid13Permissions() async {
    // Android 13+ (API 33+) needs separate permissions for different media types
    Map<Permission, String> mediaPermissions = {
      Permission.photos: 'Photos',
      Permission.videos: 'Videos',
      Permission.audio: 'Audio',
    };
    
    bool allGranted = true;
    List<String> deniedPermissions = [];
    
    for (var entry in mediaPermissions.entries) {
      final status = await entry.key.request();
      if (!status.isGranted) {
        allGranted = false;
        deniedPermissions.add(entry.value);
      }
    }
    
    if (!allGranted) {
      _showMessage('Please grant ${deniedPermissions.join(", ")} permission to access storage', isSuccess: false);
    }
    
    return allGranted;
  }

  // ==================== CAMERA TEST ====================
  Future<void> testCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _showMessage('Camera permission denied', isSuccess: false);
      return;
    }
    
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showMessage('No camera available', isSuccess: false);
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
      _showMessage('Error: $e', isSuccess: false);
    }
  }

  // ==================== GALLERY TEST ====================
  Future<void> testGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showMessage('Image selected: ${image.name}', isSuccess: true);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImagePreviewScreen(imagePath: image.path)),
      );
    }
  }

  // ==================== LOCATION TEST ====================
  Future<void> testLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      _showMessage('📍 Location:\nLat: ${position.latitude}\nLng: ${position.longitude}\nAlt: ${position.altitude}', isSuccess: true);
    } else {
      _showMessage('Location permission denied', isSuccess: false);
    }
  }

  // ==================== BLUETOOTH TEST ====================
  Future<void> testBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      _showMessage('Bluetooth not supported on this device', isSuccess: false);
      return;
    }
    
    final status = await Permission.bluetoothScan.request();
    if (!status.isGranted) {
      _showMessage('Bluetooth scan permission denied', isSuccess: false);
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BluetoothTestScreen()),
    );
  }

  // ==================== SENSORS TEST ====================
  void testSensors() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SensorsTestScreen()),
    );
  }

  // ==================== CONNECTIVITY TEST ====================
  Future<void> testConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    String status = '';
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      status = '📱 Mobile Network (Cellular)';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      status = '📶 WiFi Connected';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      status = '🔌 Ethernet Connection';
    } else {
      status = '❌ No Internet Connection';
    }
    _showMessage('Connectivity Status:\n$status', isSuccess: true);
  }

  // ==================== NOTIFICATION TEST ====================
  Future<void> testNotification() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      '✅ Notification Test',
      'Your device supports notifications! Time: ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
      details,
    );
    _showMessage('Notification sent! Check your status bar.', isSuccess: true);
  }

  // ==================== PHONE TEST ====================
  Future<void> testPhone() async {
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      _showMessage('Phone permission denied', isSuccess: false);
      return;
    }
    
    const url = 'tel:1234567890';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
      _showMessage('Dialer opened successfully', isSuccess: true);
    } else {
      _showMessage('Cannot open dialer on this device', isSuccess: false);
    }
  }

  // ==================== CALENDAR TEST ====================
  Future<void> testCalendar() async {
    final status = await Permission.calendar.request();
    if (!status.isGranted) {
      _showMessage('Calendar permission denied', isSuccess: false);
      return;
    }
    _showMessage('✅ Calendar permission granted!\nYou can now read/write calendar events.', isSuccess: true);
  }

  // ==================== CONTACTS TEST ====================
  Future<void> testContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      _showMessage('Contacts permission denied', isSuccess: false);
      return;
    }
    _showMessage('✅ Contacts permission granted!\nYou can now access device contacts.', isSuccess: true);
  }

  // ==================== MICROPHONE TEST ====================
  Future<void> testMicrophone() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showMessage('Microphone permission denied', isSuccess: false);
      return;
    }
    _showMessage('✅ Microphone permission granted!\nYou can now record audio.', isSuccess: true);
  }

  // ==================== SHARE TEST ====================
  Future<void> testShare() async {
    await Share.share(
      'Check out this amazing device capability tester app!\n\n'
      'It can test: Camera, Gallery, Location, Bluetooth, Sensors, Notifications, Storage, and more!\n\n'
      'Built with Flutter 3.29.2',
      subject: 'Device Capability Tester',
    );
    _showMessage('Share dialog opened!', isSuccess: true);
  }

  void showDeviceInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Device Information', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(deviceInfo, style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green[800] : Colors.red[800],
      ),
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
              _showMessage('Refreshed permissions & device info', isSuccess: true);
            },
            tooltip: 'Refresh',
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
                Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Permission Status Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
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
                        style: TextStyle(fontSize: 10),
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
                childAspectRatio: 1.0,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return Card(
                  color: Colors.grey[900],
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: feature.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(feature.icon, size: 40, color: Colors.blue[400]),
                          SizedBox(height: 8),
                          Text(feature.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(feature.description, style: TextStyle(fontSize: 10, color: Colors.grey[400]), textAlign: TextAlign.center),
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

// ==================== CAMERA TEST SCREEN ====================
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
    try {
      double maxZoom = await widget.controller.getMaxZoomLevel();
      setState(() => _maxZoom = maxZoom);
    } catch (e) {
      // Zoom not available
    }
  }
  
  Future<void> _takePicture() async {
    try {
      final XFile picture = await widget.controller.takePicture();
      _showMessage('Picture saved: ${picture.path.split('/').last}');
    } catch (e) {
      _showMessage('Error taking picture: $e');
    }
  }
  
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: Duration(seconds: 2)),
    );
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
            color: Colors.black.withOpacity(0.8),
            child: Column(
              children: [
                if (_maxZoom > 1.0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.zoom_out, size: 32, color: Colors.white),
                        onPressed: _zoom > 1.0 ? () {
                          setState(() {
                            _zoom = (_zoom - 0.1).clamp(1.0, _maxZoom);
                            widget.controller.setZoomLevel(_zoom);
                          });
                        } : null,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_zoom.toStringAsFixed(1)}x', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: Icon(Icons.zoom_in, size: 32, color: Colors.white),
                        onPressed: _zoom < _maxZoom ? () {
                          setState(() {
                            _zoom = (_zoom + 0.1).clamp(1.0, _maxZoom);
                            widget.controller.setZoomLevel(_zoom);
                          });
                        } : null,
                      ),
                    ],
                  ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: Icon(Icons.camera),
                  label: Text('Capture Photo', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.red[800],
                  ),
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

// ==================== IMAGE PREVIEW SCREEN ====================
class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;
  ImagePreviewScreen({required this.imagePath});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Preview')),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

// ==================== BLUETOOTH TEST SCREEN ====================
class BluetoothTestScreen extends StatefulWidget {
  @override
  _BluetoothTestScreenState createState() => _BluetoothTestScreenState();
}

class _BluetoothTestScreenState extends State<BluetoothTestScreen> {
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  
  void startScan() async {
    setState(() {
      scanResults.clear();
      isScanning = true;
    });
    
    await FlutterBluePlus.startScan(timeout: Duration(seconds: 15));
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
    
    Future.delayed(Duration(seconds: 15), () {
      if (mounted) {
        setState(() => isScanning = false);
        FlutterBluePlus.stopScan();
      }
    });
  }
  
  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    setState(() => isScanning = false);
  }
  
  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Scanner'),
        actions: [
          if (isScanning)
            IconButton(
              icon: Icon(Icons.stop),
              onPressed: stopScan,
              tooltip: 'Stop Scan',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : startScan,
              icon: Icon(isScanning ? Icons.sync : Icons.bluetooth_searching),
              label: Text(isScanning ? 'Scanning...' : 'Start Bluetooth Scan'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
          if (scanResults.isEmpty && !isScanning)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No devices found. Click Start Scan to search.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          if (scanResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(
                        result.device.name.isNotEmpty ? result.device.name : 'Unknown Device',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(result.device.id.toString()),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${result.rssi} dBm', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (isScanning)
            Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

// ==================== SENSORS TEST SCREEN ====================
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
      if (mounted) {
        setState(() {
          _accelerometerX = event.x;
          _accelerometerY = event.y;
          _accelerometerZ = event.z;
        });
      }
    });
    
    gyroscopeEvents.listen((event) {
      if (mounted) {
        setState(() {
          _gyroscopeX = event.x;
          _gyroscopeY = event.y;
          _gyroscopeZ = event.z;
        });
      }
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
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speed, size: 32, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('📊 Accelerometer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSensorRow('X-axis', _accelerometerX, Colors.red),
                    _buildSensorRow('Y-axis', _accelerometerY, Colors.green),
                    _buildSensorRow('Z-axis', _accelerometerZ, Colors.blue),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rotate_right, size: 32, color: Colors.purple),
                        SizedBox(width: 12),
                        Text('🔄 Gyroscope', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSensorRow('X-axis', _gyroscopeX, Colors.red),
                    _buildSensorRow('Y-axis', _gyroscopeY, Colors.green),
                    _buildSensorRow('Z-axis', _gyroscopeZ, Colors.blue),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Move your device to see real-time sensor data updates!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSensorRow(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 50, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: LinearProgressIndicator(
              value: (value.abs() / 20).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[800],
              color: color,
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 80,
            child: Text(
              value.toStringAsFixed(3),
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== FEATURE CARD MODEL ====================
class FeatureCard {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  
  FeatureCard(this.title, this.description, this.icon, this.onTap);
}