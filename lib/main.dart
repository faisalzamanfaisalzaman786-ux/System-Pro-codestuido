import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(TestApp(cameras: cameras));
}

class TestApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const TestApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission Test App',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: TestHomePage(cameras: cameras),
    );
  }
}

class TestHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const TestHomePage({super.key, required this.cameras});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  final List<PermissionItem> permissions = [];
  final List<FeatureItem> features = [];
  bool _isLoading = false;
  String _logMessage = 'Ready to test...';

  @override
  void initState() {
    super.initState();
    _initializePermissionList();
    _initializeFeaturesList();
  }

  void _initializePermissionList() {
    permissions.addAll([
      PermissionItem(name: '📷 Camera', permission: Permission.camera, icon: Icons.camera_alt, granted: false),
      PermissionItem(name: '🖼️ Photos', permission: Permission.photos, icon: Icons.photo_library, granted: false),
      PermissionItem(name: '🎤 Microphone', permission: Permission.microphone, icon: Icons.mic, granted: false),
      PermissionItem(name: '📍 Location', permission: Permission.location, icon: Icons.location_on, granted: false),
      PermissionItem(name: '🔵 Bluetooth', permission: Permission.bluetooth, icon: Icons.bluetooth, granted: false),
      PermissionItem(name: '📞 Contacts', permission: Permission.contacts, icon: Icons.contact_phone, granted: false),
      PermissionItem(name: '📅 Calendar', permission: Permission.calendar, icon: Icons.calendar_today, granted: false),
      PermissionItem(name: '💬 SMS', permission: Permission.sms, icon: Icons.sms, granted: false),
      PermissionItem(name: '📱 Phone', permission: Permission.phone, icon: Icons.phone, granted: false),
      PermissionItem(name: '📡 Sensors', permission: Permission.sensors, icon: Icons.sensors, granted: false),
      PermissionItem(name: '🔔 Notifications', permission: Permission.notification, icon: Icons.notifications, granted: false),
      PermissionItem(name: '💾 Storage', permission: Permission.storage, icon: Icons.storage, granted: false),
    ]);
  }

  void _initializeFeaturesList() {
    features.addAll([
      FeatureItem(name: '📸 Take Photo', icon: Icons.camera, action: _takePhoto),
      FeatureItem(name: '🖼️ Pick from Gallery', icon: Icons.photo_library, action: _pickFromGallery),
      FeatureItem(name: '💾 Save to Gallery', icon: Icons.save, action: _saveToGallery),
      FeatureItem(name: '📡 Check Connectivity', icon: Icons.wifi, action: _checkConnectivity),
      FeatureItem(name: '📍 Get Location', icon: Icons.location_on, action: _getLocation),
      FeatureItem(name: '📱 Device Info', icon: Icons.devices, action: _getDeviceInfo),
      FeatureItem(name: '📤 Share Text', icon: Icons.share, action: _shareText),
      FeatureItem(name: '🎯 Test Sensors', icon: Icons.sensors, action: _testSensors),
      FeatureItem(name: '🔵 Test Bluetooth', icon: Icons.bluetooth, action: _testBluetooth),
    ]);
  }

  Future<void> _checkAllPermissions() async {
    setState(() => _isLoading = true);
    _addLog('Checking all permissions...');
    
    for (var item in permissions) {
      final status = await item.permission.status;
      setState(() {
        item.granted = status.isGranted;
      });
      _addLog('${item.name}: ${status.isGranted ? "✅ GRANTED" : "❌ DENIED"}');
    }
    
    setState(() => _isLoading = false);
    _addLog('✅ All permissions checked!');
  }

  Future<void> _requestPermission(PermissionItem item) async {
    setState(() => _isLoading = true);
    _addLog('Requesting ${item.name}...');
    
    final status = await item.permission.request();
    setState(() {
      item.granted = status.isGranted;
    });
    
    _addLog('${item.name}: ${status.isGranted ? "✅ GRANTED" : "❌ DENIED"}');
    setState(() => _isLoading = false);
  }

  Future<void> _takePhoto() async {
    _addLog('Opening camera...');
    
    if (widget.cameras.isEmpty) {
      _addLog('❌ No camera found!');
      return;
    }
    
    final controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    await controller.initialize();
    
    try {
      final image = await controller.takePicture();
      _addLog('✅ Photo taken: ${image.path}');
      
      final bytes = await image.readAsBytes();
      final result = await ImageGallerySaverPlus.saveImage(bytes);
      if (result['isSuccess'] == true) {
        _addLog('✅ Photo saved to gallery!');
      } else {
        _addLog('⚠️ Photo saved locally only');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      await controller.dispose();
    }
  }

  Future<void> _pickFromGallery() async {
    _addLog('Opening gallery...');
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      _addLog('✅ Image picked: ${picked.name}');
    } else {
      _addLog('⚠️ No image selected');
    }
  }

  Future<void> _saveToGallery() async {
    _addLog('Creating test image...');
    final imageData = await _createTestImage();
    final result = await ImageGallerySaverPlus.saveImage(imageData);
    
    if (result['isSuccess'] == true) {
      _addLog('✅ Test image saved to gallery!');
    } else {
      _addLog('❌ Failed to save image');
    }
  }

  Future<Uint8List> _createTestImage() async {
    final List<int> pngBytes = [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x64, 0x00, 0x00, 0x00, 0x64,
      0x08, 0x02, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00,
      0x01, 0x73, 0x52, 0x47, 0x42, 0x00, 0xAE, 0xCE, 0x1C, 0xE9, 0x00, 0x00,
      0x00, 0x04, 0x67, 0x41, 0x4D, 0x41, 0x00, 0x00, 0xB1, 0x8F, 0x0B, 0xFC,
      0x61, 0x05, 0x00, 0x00, 0x00, 0x20, 0x63, 0x48, 0x52, 0x4D, 0x00, 0x00,
      0x7A, 0x26, 0x00, 0x00, 0x80, 0x84, 0x00, 0x00, 0xFA, 0x00, 0x00, 0x00,
      0x80, 0xE8, 0x00, 0x00, 0x75, 0x30, 0x00, 0x00, 0xEA, 0x60, 0x00, 0x00,
      0x3A, 0x98, 0x00, 0x00, 0x17, 0x70, 0x9C, 0xBA, 0x51, 0x3C, 0x00, 0x00,
      0x00, 0x2E, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0xED, 0xC1, 0x01, 0x0D,
      0x00, 0x00, 0x00, 0xC2, 0xA0, 0xF7, 0x4F, 0x6D, 0x0E, 0x37, 0xA0, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0, 0xC0, 0x0A,
      0x34, 0xCA, 0x01, 0x0D, 0x7A, 0x38, 0x3F, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
    ];
    return Uint8List.fromList(pngBytes);
  }

  Future<void> _checkConnectivity() async {
    _addLog('Checking connectivity...');
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _addLog('✅ Connection: ${result.isNotEmpty ? result.first.name : "none"}');
  }

  Future<void> _getLocation() async {
    _addLog('Getting location...');
    
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _addLog('❌ Location services disabled');
      return;
    }
    
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    
    final position = await Geolocator.getCurrentPosition();
    _addLog('✅ Location: ${position.latitude}, ${position.longitude}');
  }

  Future<void> _getDeviceInfo() async {
    _addLog('Getting device info...');
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _addLog('✅ Device: ${androidInfo.model}');
      _addLog('✅ Android: ${androidInfo.version.release}');
      _addLog('✅ SDK: ${androidInfo.version.sdkInt}');
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _addLog('✅ Device: ${iosInfo.model}');
      _addLog('✅ iOS: ${iosInfo.systemVersion}');
    }
  }

  Future<void> _shareText() async {
    _addLog('Sharing text...');
    await Share.share('Test message from Permission Test App!\n\nAll permissions are working correctly!');
    _addLog('✅ Share dialog opened');
  }

  Future<void> _testSensors() async {
    _addLog('Testing accelerometer sensor...');
    _addLog('Shake your device to see sensor data!');
    
    accelerometerEvents.listen((event) {
      _addLog('📊 x=${event.x.toStringAsFixed(2)}, y=${event.y.toStringAsFixed(2)}, z=${event.z.toStringAsFixed(2)}');
    });
    
    _addLog('✅ Accelerometer listener active');
  }

  Future<void> _testBluetooth() async {
    _addLog('Testing Bluetooth...');
    
    if (Platform.isAndroid) {
      final isEnabled = await FlutterBluePlus.isOn;
      _addLog('Bluetooth is ${isEnabled ? "ON ✅" : "OFF ❌"}');
      
      if (isEnabled) {
        await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));
        _addLog('✅ Scanning for devices...');
        
        FlutterBluePlus.scanResults.listen((results) {
          for (var result in results) {
            _addLog('Found: ${result.device.name} - ${result.device.id}');
          }
        });
      }
    } else {
      _addLog('⚠️ Bluetooth test only on Android');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logMessage = message;
    });
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission Test App v1.0'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.refresh),
            onPressed: _isLoading ? null : _checkAllPermissions,
            tooltip: 'Check All Permissions',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.blueGrey[800],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.cyan),
                SizedBox(width: 8),
                Expanded(child: Text(_logMessage, style: TextStyle(fontSize: 12))),
              ],
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'PERMISSIONS (${permissions.where((p) => p.granted).length}/${permissions.length} granted)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: permissions.length,
                    itemBuilder: (context, index) {
                      final item = permissions[index];
                      return Card(
                        color: item.granted ? Colors.green[900] : Colors.grey[800],
                        child: InkWell(
                          onTap: () => _requestPermission(item),
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Row(
                              children: [
                                Icon(item.icon, size: 20, color: item.granted ? Colors.green : Colors.grey),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item.name, style: TextStyle(fontSize: 10)),
                                      Text(
                                        item.granted ? 'GRANTED' : 'DENIED',
                                        style: TextStyle(fontSize: 8, color: item.granted ? Colors.green : Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
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
          ),
          
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'FEATURES TO TEST',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final item = features[index];
                      return Card(
                        color: Colors.blueGrey[800],
                        child: InkWell(
                          onTap: item.action,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(item.icon, size: 20, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(item.name, style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
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

class PermissionItem {
  final String name;
  final Permission permission;
  final IconData icon;
  bool granted;
  
  PermissionItem({
    required this.name,
    required this.permission,
    required this.icon,
    required this.granted,
  });
}

class FeatureItem {
  final String name;
  final IconData icon;
  final VoidCallback action;
  
  FeatureItem({
    required this.name,
    required this.icon,
    required this.action,
  });
}