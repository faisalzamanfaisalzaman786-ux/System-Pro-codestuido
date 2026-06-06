import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:bluetooth_enable/bluetooth_enable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeviceTesterApp());
}

class DeviceTesterApp extends StatelessWidget {
  const DeviceTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Tester Pro',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const DeviceTesterScreen(),
    );
  }
}

class DeviceTesterScreen extends StatefulWidget {
  const DeviceTesterScreen({super.key});

  @override
  State<DeviceTesterScreen> createState() => _DeviceTesterScreenState();
}

class _DeviceTesterScreenState extends State<DeviceTesterScreen> {
  // Camera
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isTorchOn = false;
  
  // Permissions Status
  Map<String, bool> _permissions = {};
  
  // Device Info
  Map<String, String> _deviceInfo = {};
  
  // Location
  Position? _currentPosition;
  bool _isLocationLoading = false;
  
  // Sensors
  AccelerometerEvent? _accelerometerEvent;
  GyroscopeEvent? _gyroscopeEvent;
  bool _isListeningToSensors = false;
  
  // Network
  String _wifiInfo = "Not checked";
  String _connectivityStatus = "Not checked";
  
  // Bluetooth
  bool _isBluetoothEnabled = false;
  
  // Storage
  int _totalStorage = 0;
  int _freeStorage = 0;
  
  // Logs
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
    _getDeviceInfo();
    _checkStorage();
    _checkConnectivity();
    _checkWifiInfo();
    _checkBluetooth();
  }

  void addLog(String msg) {
    setState(() {
      _logs.insert(0, "[${DateTime.now().toString().substring(11, 19)}] $msg");
      if (_logs.length > 50) _logs.removeLast();
    });
    print(msg);
  }

  Future<void> _checkAllPermissions() async {
    addLog("🔍 Checking all permissions...");
    
    Map<String, Permission> allPerms = {
      "Camera": Permission.camera,
      "Storage": Permission.storage,
      "Location": Permission.location,
      "Location (Always)": Permission.locationAlways,
      "Location (When in Use)": Permission.locationWhenInUse,
      "Microphone": Permission.microphone,
      "Contacts": Permission.contacts,
      "Calendar": Permission.calendar,
      "SMS": Permission.sms,
      "Phone": Permission.phone,
      "Bluetooth": Permission.bluetooth,
      "Bluetooth (Connect)": Permission.bluetoothConnect,
      "Bluetooth (Scan)": Permission.bluetoothScan,
      "Nearby Wifi": Permission.nearbyWifiDevices,
      "Ignore Battery": Permission.ignoreBatteryOptimizations,
      "Notification": Permission.notification,
    };
    
    for (var entry in allPerms.entries) {
      final status = await entry.value.status;
      _permissions[entry.key] = status.isGranted;
      addLog("  📱 ${entry.key}: ${status.isGranted ? '✅ Granted' : '❌ Not granted'}");
    }
  }

  Future<void> _requestPermission(Permission permission, String name) async {
    final status = await permission.request();
    setState(() {
      _permissions[name] = status.isGranted;
    });
    addLog("${status.isGranted ? '✅' : '❌'} $name permission: ${status.isGranted ? 'Granted' : 'Denied'}");
  }

  Future<void> _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceInfo = {
            "Model": androidInfo.model,
            "Manufacturer": androidInfo.manufacturer,
            "Device": androidInfo.device,
            "Product": androidInfo.product,
            "Android Version": androidInfo.version.release,
            "SDK Version": androidInfo.version.sdkInt.toString(),
            "Board": androidInfo.board,
            "Bootloader": androidInfo.bootloader,
            "Brand": androidInfo.brand,
            "Hardware": androidInfo.hardware,
            "Host": androidInfo.host,
            "ID": androidInfo.id,
            "Tags": androidInfo.tags,
            "Type": androidInfo.type,
            "Is Physical Device": androidInfo.isPhysicalDevice.toString(),
          };
        });
        addLog("✅ Device info fetched (${androidInfo.model})");
      }
    } catch (e) {
      addLog("❌ Failed to get device info: $e");
    }
  }

  Future<void> _checkStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final totalSpace = directory.stat.totalSpace;
      final freeSpace = directory.stat.freeSpace;
      setState(() {
        _totalStorage = totalSpace;
        _freeStorage = freeSpace;
      });
      addLog("💾 Storage: ${(_freeStorage / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB free / ${(_totalStorage / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB total");
    } catch (e) {
      addLog("❌ Failed to get storage info: $e");
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    setState(() {
      _connectivityStatus = result.toString();
    });
    addLog("📡 Connectivity: $result");
    
    connectivity.onConnectivityChanged.listen((event) {
      addLog("📡 Connectivity changed: $event");
      setState(() {
        _connectivityStatus = event.toString();
      });
    });
  }

  Future<void> _checkWifiInfo() async {
    try {
      final wifiInfo = WifiInfoFlutter();
      final ssid = await wifiInfo.getWifiName();
      final bssid = await wifiInfo.getWifiBSSID();
      final ip = await wifiInfo.getWifiIP();
      setState(() {
        _wifiInfo = "SSID: $ssid\nBSSID: $bssid\nIP: $_formatIp(ip)";
      });
      addLog("📶 WiFi: $ssid");
    } catch (e) {
      setState(() {
        _wifiInfo = "WiFi info not available: $e";
      });
      addLog("❌ Failed to get WiFi info: $e");
    }
  }

  String _formatIp(int ip) {
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }

  Future<void> _checkBluetooth() async {
    try {
      final bluetooth = BluetoothEnable();
      bool isEnabled = await bluetooth.checkBluetooth();
      setState(() {
        _isBluetoothEnabled = isEnabled;
      });
      addLog("🔵 Bluetooth: ${isEnabled ? 'Enabled' : 'Disabled'}");
    } catch (e) {
      addLog("❌ Failed to check Bluetooth: $e");
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      final bluetooth = BluetoothEnable();
      bool enabled = await bluetooth.requestEnable();
      setState(() {
        _isBluetoothEnabled = enabled;
      });
      addLog("🔵 Bluetooth enable request: ${enabled ? 'Enabled' : 'Failed'}");
    } catch (e) {
      addLog("❌ Failed to enable Bluetooth: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });
    
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      addLog("📍 Location services disabled");
      setState(() { _isLocationLoading = false; });
      return;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        addLog("📍 Location permission denied");
        setState(() { _isLocationLoading = false; });
        return;
      }
    }
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLocationLoading = false;
      });
      addLog("📍 Location: ${position.latitude}, ${position.longitude} (Accuracy: ${position.accuracy}m)");
    } catch (e) {
      addLog("❌ Failed to get location: $e");
      setState(() { _isLocationLoading = false; });
    }
  }

  void _startSensors() {
    setState(() {
      _isListeningToSensors = true;
    });
    
    accelerometerEvents.listen((event) {
      setState(() {
        _accelerometerEvent = event;
      });
    });
    
    gyroscopeEvents.listen((event) {
      setState(() {
        _gyroscopeEvent = event;
      });
    });
    
    addLog("🌀 Sensors started listening");
  }

  void _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        addLog("❌ No camera found");
        return;
      }
      
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraReady = true;
      });
      addLog("📷 Camera initialized (${cameras[0].lensDirection})");
    } catch (e) {
      addLog("❌ Camera init failed: $e");
    }
  }

  void _toggleTorch() async {
    if (!_isCameraReady || _cameraController == null) {
      addLog("❌ Camera not ready");
      return;
    }
    try {
      if (_isTorchOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() => _isTorchOn = false);
        addLog("🔦 Torch OFF");
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() => _isTorchOn = true);
        addLog("🔦 Torch ON");
      }
    } catch (e) {
      addLog("❌ Torch failed: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || _cameraController == null) {
      addLog("❌ Camera not ready");
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      addLog("📸 Picture taken: ${image.path}");
    } catch (e) {
      addLog("❌ Failed to take picture: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        addLog("🖼️ Image picked: ${image.path}");
      } else {
        addLog("🖼️ Image pick cancelled");
      }
    } catch (e) {
      addLog("❌ Failed to pick image: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Tester Pro'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkAllPermissions();
              _getDeviceInfo();
              _checkStorage();
              _checkConnectivity();
              _checkWifiInfo();
              addLog("🔄 Refreshed all checks");
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.security), text: "Permissions"),
                Tab(icon: Icon(Icons.phone_android), text: "Device"),
                Tab(icon: Icon(Icons.location_on), text: "Location"),
                Tab(icon: Icon(Icons.sensors), text: "Sensors"),
                Tab(icon: Icon(Icons.terminal), text: "Logs"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Permissions Tab
                  _buildPermissionsTab(),
                  
                  // Device Info Tab
                  _buildDeviceInfoTab(),
                  
                  // Location Tab
                  _buildLocationTab(),
                  
                  // Sensors Tab
                  _buildSensorsTab(),
                  
                  // Logs Tab
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Camera Preview
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isCameraReady && _cameraController != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CameraPreview(_cameraController!),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _initCamera,
                          child: const Text("Initialize Camera"),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          
          // Camera Controls
          if (_isCameraReady)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleTorch,
                    icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                    label: Text(_isTorchOn ? "Turn OFF" : "Turn ON"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTorchOn ? Colors.amber : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Photo"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Pick Image"),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          
          // Permissions List
          const Text("Permissions Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._permissions.entries.map((entry) => Card(
            child: ListTile(
              leading: Icon(
                entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? Colors.green : Colors.red,
              ),
              title: Text(entry.key),
              trailing: ElevatedButton(
                onPressed: () {
                  Permission? perm;
                  switch (entry.key) {
                    case "Camera": perm = Permission.camera; break;
                    case "Storage": perm = Permission.storage; break;
                    case "Location": perm = Permission.location; break;
                    case "Microphone": perm = Permission.microphone; break;
                    default: return;
                  }
                  if (perm != null) _requestPermission(perm, entry.key);
                },
                child: const Text("Request"),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage),
            title: const Text("Storage"),
            subtitle: Text("Free: ${(_freeStorage / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB\nTotal: ${(_totalStorage / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB"),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text("WiFi & Network"),
            subtitle: Text(_wifiInfo),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.signal_cellular_alt),
            title: const Text("Connectivity"),
            subtitle: Text(_connectivityStatus),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(_isBluetoothEnabled ? Icons.bluetooth : Icons.bluetooth_disabled),
            title: const Text("Bluetooth"),
            subtitle: Text(_isBluetoothEnabled ? "Enabled" : "Disabled"),
            trailing: !_isBluetoothEnabled
                ? ElevatedButton(
                    onPressed: _enableBluetooth,
                    child: const Text("Enable"),
                  )
                : null,
          ),
        ),
        const Divider(),
        const Text("Hardware Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._deviceInfo.entries.map((entry) => ListTile(
          dense: true,
          leading: const Icon(Icons.info, size: 20),
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text(entry.value, style: const TextStyle(fontSize: 12)),
        )).toList(),
      ],
    );
  }

  Widget _buildLocationTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, size: 64, color: Colors.cyan),
            const SizedBox(height: 24),
            if (_currentPosition != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Latitude: ${_currentPosition!.latitude}"),
                      Text("Longitude: ${_currentPosition!.longitude}"),
                      Text("Accuracy: ${_currentPosition!.accuracy}m"),
                      Text("Altitude: ${_currentPosition!.altitude}m"),
                    ],
                  ),
                ),
              )
            else
              const Text("No location data"),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLocationLoading ? null : _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: Text(_isLocationLoading ? "Getting Location..." : "Get Current Location"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorsTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isListeningToSensors)
              ElevatedButton.icon(
                onPressed: _startSensors,
                icon: const Icon(Icons.sensors),
                label: const Text("Start Sensors"),
              )
            else
              Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Accelerometer", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("X: ${_accelerometerEvent?.x.toStringAsFixed(3) ?? '--'}"),
                          Text("Y: ${_accelerometerEvent?.y.toStringAsFixed(3) ?? '--'}"),
                          Text("Z: ${_accelerometerEvent?.z.toStringAsFixed(3) ?? '--'}"),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Gyroscope", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("X: ${_gyroscopeEvent?.x.toStringAsFixed(3) ?? '--'}"),
                          Text("Y: ${_gyroscopeEvent?.y.toStringAsFixed(3) ?? '--'}"),
                          Text("Z: ${_gyroscopeEvent?.z.toStringAsFixed(3) ?? '--'}"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      reverse: true,
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: _logs[index].contains('❌') ? Colors.red.shade900 : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _logs[index],
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        );
      },
    );
  }
}