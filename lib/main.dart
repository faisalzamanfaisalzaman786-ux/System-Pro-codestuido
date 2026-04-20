import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:livekit_client/livekit_client.dart'; // اسکرین شیئرنگ کے لیے
import 'package:image_picker/image_picker.dart'; // گیلری سے میڈیا لینے کے لیے

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final allGranted = await _requestAllPermissions();
  if (!allGranted) {
    print('⚠️ Some permissions denied. App may not work correctly.');
  }
  cameras = await availableCameras();
  await _initBackgroundService();
  runApp(const MyApp());
}

// ✅ تمام ضروری اجازتیں (Android 13+ کے مطابق)
Future<bool> _requestAllPermissions() async {
  final permissions = [
    Permission.camera,
    Permission.microphone,
    Permission.notification,
    if (await _isBelowAndroid13()) Permission.storage,
    if (await _isBelowAndroid13()) Permission.photos,
    if (await _isBelowAndroid13()) Permission.videos,
    if (!await _isBelowAndroid13()) Permission.photos,
    if (!await _isBelowAndroid13()) Permission.videos,
  ];
  final statuses = await permissions.request();
  bool allGranted = statuses.values.every((s) => s.isGranted);
  if (!allGranted) {
    for (var entry in statuses.entries) {
      if (entry.value.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
    }
  }
  return allGranted;
}

Future<bool> _isBelowAndroid13() async {
  final sdkInt = (await Permission.storage.status).isGranted; // hack, but works
  return sdkInt; // better to use device_info_plus, but for simplicity
}

// ✅ بیک گراؤنڈ سروس کی ترتیب
Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'system_pro_channel',
    'System Pro Service',
    description: 'Required for background tasks like uploading or recording.',
    importance: Importance.high,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'system_pro_channel',
      initialNotificationTitle: 'System Pro',
      initialNotificationContent: 'Background service is running',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onStart: onStart,
      autoStart: true,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  Timer? timer;
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setNotificationContent(
      title: 'System Pro',
      content: 'Background service is active',
    );
    timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service.isForegroundService()) {
        service.setNotificationContent(
          title: 'System Pro',
          content: 'Service running since ${DateTime.now()}',
        );
      }
    });
  }
  service.on('stop').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Pro',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const CameraHomePage(),
    );
  }
}

class CameraHomePage extends StatefulWidget {
  const CameraHomePage({super.key});

  @override
  State<CameraHomePage> createState() => _CameraHomePageState();
}

class _CameraHomePageState extends State<CameraHomePage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  bool _isRecording = false;
  File? _lastVideo;
  VideoPlayerController? _videoController;
  bool _isCompressing = false;
  bool _backgroundServiceRunning = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  double _zoomLevel = 0.0;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  String _quality = 'High'; // Low, Medium, High
  List<File> _recordedVideos = [];
  Room? _liveKitRoom;
  bool _isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _checkBackgroundServiceStatus();
    _loadRecordedVideos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _cameraController != null && !_cameraController!.value.isInitialized) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    final camera = cameras[_selectedCameraIndex.clamp(0, cameras.length - 1)];
    _cameraController = CameraController(camera, _getResolutionPreset(), enableAudio: true);
    _cameraController!.setFlashMode(_flashMode);
    _initializeFuture = _cameraController!.initialize().then((_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  ResolutionPreset _getResolutionPreset() {
    switch (_quality) {
      case 'Low': return ResolutionPreset.low;
      case 'Medium': return ResolutionPreset.medium;
      default: return ResolutionPreset.high;
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    setState(() => _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length);
    await _cameraController?.dispose();
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    final newMode = {
      FlashMode.off: FlashMode.auto,
      FlashMode.auto: FlashMode.always,
      FlashMode.always: FlashMode.off,
    }[_flashMode]!;
    setState(() => _flashMode = newMode);
    await _cameraController?.setFlashMode(_flashMode);
  }

  Future<void> _setZoom(double value) async {
    setState(() => _zoomLevel = value);
    await _cameraController?.setZoomLevel(value);
  }

  Future<void> _startVideoRecording() async {
    try {
      await _initializeFuture;
      if (_cameraController != null && !_isRecording) {
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        });
        _showSnackBar('Recording started...');
      }
    } catch (e) {
      _showSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      if (_cameraController != null && _isRecording) {
        final XFile file = await _cameraController!.stopVideoRecording();
        _recordTimer?.cancel();
        final directory = await getApplicationDocumentsDirectory();
        final videosDir = Directory('${directory.path}/videos');
        if (!await videosDir.exists()) await videosDir.create(recursive: true);
        final savedPath = path.join(videosDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');
        final savedFile = await File(file.path).copy(savedPath);
        setState(() {
          _isRecording = false;
          _lastVideo = savedFile;
          _recordedVideos.insert(0, savedFile);
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(savedFile)
            ..initialize().then((_) => setState(() {}));
        });
        _showSnackBar('Video saved to ${savedFile.path}');
        await _scanMedia(savedFile.path);
      }
    } catch (e) {
      _showSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _scanMedia(String filePath) async {
    // Android کے لیے میڈیا اسکین کرنا
    if (Platform.isAndroid) {
      // یہاں آپ MethodChannel استعمال کر سکتے ہیں یا صرف اگلے اسٹیپ میں چھوڑ دیں
    }
  }

  Future<void> _compressVideo() async {
    if (_lastVideo == null) return;
    setState(() => _isCompressing = true);
    try {
      final outputPath = path.join(
        (await getTemporaryDirectory()).path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      final command = '-i "${_lastVideo!.path}" -vf "scale=854:480" -c:v libx264 -crf 28 -preset ultrafast "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        final compressedFile = File(outputPath);
        setState(() {
          _lastVideo = compressedFile;
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(compressedFile)
            ..initialize().then((_) => setState(() {}));
        });
        _showSnackBar('Video compressed successfully!');
      } else {
        _showSnackBar('Compression failed. Return code: $returnCode');
      }
    } catch (e) {
      _showSnackBar('Compression error: $e');
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_lastVideo == null) return;
    try {
      final directory = await getExternalStorageDirectory();
      final savedPath = path.join(directory!.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');
      await _lastVideo!.copy(savedPath);
      _showSnackBar('Video saved to gallery: $savedPath');
    } catch (e) {
      _showSnackBar('Error saving to gallery: $e');
    }
  }

  Future<void> _loadRecordedVideos() async {
    final directory = Directory('${(await getApplicationDocumentsDirectory()).path}/videos');
    if (await directory.exists()) {
      final files = directory.listSync().whereType<File>().toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() => _recordedVideos = files);
    }
  }

  Future<void> _pickVideoFromGallery() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      final savedFile = await File(picked.path).copy('${(await getTemporaryDirectory()).path}/${DateTime.now()}.mp4');
      setState(() {
        _lastVideo = savedFile;
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(savedFile)
          ..initialize().then((_) => setState(() {}));
      });
    }
  }

  // اسکرین شیئرنگ (LiveKit)
  Future<void> _startScreenSharing() async {
    try {
      final token = 'YOUR_LIVEKIT_TOKEN'; // اپنا ٹوکن یہاں لگائیں
      final room = await LiveKitClient.connect(
        'wss://your-livekit-server.com',
        token,
        const ConnectOptions(autoSubscribe: true),
        const RoomOptions(),
      );
      _liveKitRoom = room;
      final localParticipant = room.localParticipant;
      // Screen share track publish کرنا
      final screenShareTrack = await createLocalScreenShareTrack();
      if (screenShareTrack != null) {
        await localParticipant.publishTrack(screenShareTrack, TrackPublishOptions());
        setState(() => _isScreenSharing = true);
        _showSnackBar('Screen sharing started');
      }
    } catch (e) {
      _showSnackBar('Screen sharing error: $e');
    }
  }

  Future<void> _stopScreenSharing() async {
    await _liveKitRoom?.disconnect();
    setState(() => _isScreenSharing = false);
    _showSnackBar('Screen sharing stopped');
  }

  Future<LocalVideoTrack?> createLocalScreenShareTrack() async {
    // یہاں flutter_webrtc کا getDisplayMedia استعمال ہوگا
    // سادگی کے لیے null return کر رہے ہیں
    _showSnackBar('Screen share not fully implemented. Add your WebRTC logic.');
    return null;
  }

  Future<void> _toggleBackgroundService() async {
    final service = FlutterBackgroundService();
    if (_backgroundServiceRunning) {
      service.invoke('stop');
      _showSnackBar('Stopping background service...');
      await Future.delayed(const Duration(seconds: 1));
    } else {
      await service.startService();
      _showSnackBar('Starting background service...');
    }
    await _checkBackgroundServiceStatus();
  }

  Future<void> _checkBackgroundServiceStatus() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    setState(() => _backgroundServiceRunning = isRunning);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _cameraController?.dispose();
    _videoController?.dispose();
    _liveKitRoom?.disconnect();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_flashMode == FlashMode.off ? Icons.flash_off : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_on)),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _quality = value);
              _initCamera();
            },
            itemBuilder: (context) => ['Low', 'Medium', 'High'].map((q) => PopupMenuItem(value: q, child: Text('Quality: $q'))).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && _cameraController != null && _cameraController!.value.isInitialized) {
                  return Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      if (_isRecording)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_recordDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Slider(
                          value: _zoomLevel,
                          min: 1.0,
                          max: _cameraController!.maxZoomLevel,
                          onChanged: _setZoom,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: 'record',
                          onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                          backgroundColor: _isRecording ? Colors.red : Colors.blue,
                          child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                        ),
                        FloatingActionButton(
                          heroTag: 'gallery',
                          onPressed: _pickVideoFromGallery,
                          child: const Icon(Icons.photo_library),
                        ),
                        FloatingActionButton(
                          heroTag: 'screen',
                          onPressed: _isScreenSharing ? _stopScreenSharing : _startScreenSharing,
                          backgroundColor: _isScreenSharing ? Colors.green : Colors.grey,
                          child: Icon(_isScreenSharing ? Icons.screen_share : Icons.share),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lastVideo != null) ...[
                      const Text('Last recorded video:', style: TextStyle(fontWeight: FontWeight.bold)),
                      AspectRatio(
                        aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                        child: _videoController != null && _videoController!.value.isInitialized
                            ? VideoPlayer(_videoController!)
                            : const Center(child: Text('Loading preview...')),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(_videoController?.value.isPlaying == true ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isCompressing ? null : _compressVideo,
                            icon: const Icon(Icons.compress),
                            label: Text(_isCompressing ? 'Compressing...' : 'Compress'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _saveToGallery,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _toggleBackgroundService,
                      icon: Icon(_backgroundServiceRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(_backgroundServiceRunning ? 'Stop Background Service' : 'Start Background Service'),
                      style: ElevatedButton.styleFrom(backgroundColor: _backgroundServiceRunning ? Colors.red : Colors.green),
                    ),
                    const SizedBox(height: 8),
                    const Text('Recorded Videos:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recordedVideos.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _lastVideo = _recordedVideos[index];
                                _videoController?.dispose();
                                _videoController = VideoPlayerController.file(_recordedVideos[index])
                                  ..initialize().then((_) => setState(() {}));
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: FutureBuilder(
                                future: _videoThumbnail(_recordedVideos[index].path),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(File(snapshot.data!), fit: BoxFit.cover),
                                    );
                                  }
                                  return const Center(child: Icon(Icons.videocam));
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _videoThumbnail(String videoPath) async {
    // یہاں video_thumbnail پیکیج استعمال کر سکتے ہیں، سادگی کے لیے null
    return null;
  }
}
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // سب سے پہلے تمام ضروری اجازتیں مانگیں
  final allPermissionsGranted = await _requestAllPermissions();

  if (!allPermissionsGranted) {
    // اگر کوئی اجازت نہیں ملی تو ایپ بند کر دیں یا صارف کو مطلع کریں
    runApp(const PermissionDeniedApp());
    return;
  }

  // اجازتیں ملنے کے بعد کیمرے انیشیلائز کریں
  cameras = await availableCameras();

  // بیک گراؤنڈ سروس شروع کریں
  await _initBackgroundService();

  runApp(const MyApp());
}

/// تمام خطرناک اجازتوں کی درخواست ایک ساتھ
Future<bool> _requestAllPermissions() async {
  // اینڈرائیڈ ورژن کے مطابق سٹوریج کی اجازتیں
  final List<Permission> permissions = [
    Permission.camera,
    Permission.microphone,
    Permission.notification,
  ];

  // اینڈرائیڈ 13 سے پہلے کے لیے
  if (await _isBelowAndroid13()) {
    permissions.add(Permission.storage);
  } else {
    // اینڈرائیڈ 13+ کے لیے مخصوص میڈیا اجازتیں
    permissions.add(Permission.photos);
    permissions.add(Permission.videos);
    permissions.add(Permission.audio);
  }

  // تمام اجازتوں کی درخواست
  final Map<Permission, PermissionStatus> statuses = await permissions.request();

  // کیا سب Granted ہیں؟
  bool allGranted = statuses.values.every((status) => status.isGranted);

  if (!allGranted) {
    // چیک کریں کہ کوئی اجازت مستقل طور پر denied تو نہیں
    for (var entry in statuses.entries) {
      if (entry.value.isPermanentlyDenied) {
        // صارف کو سیٹنگز کھولنے کا آپشن دیں
        final bool opened = await openAppSettings();
        if (opened) {
          // دوبارہ چیک کریں
          return await _requestAllPermissions();
        }
        return false;
      }
    }
    // اگر صرف عارضی طور پر deny کیا ہے تو دوبارہ مانگ سکتے ہیں (صارف خود مانگے گا)
  }
  return allGranted;
}

Future<bool> _isBelowAndroid13() async {
  // سادہ طریقہ: device_info_plus استعمال کریں یا permission_handler کے ورژن سے اندازہ لگائیں
  // یہاں ہم فرض کر رہے ہیں کہ WRITE_EXTERNAL_STORAGE کی اجازت صرف Android 12 اور اس سے پہلے موجود ہے
  final status = await Permission.storage.status;
  return status != PermissionStatus.permanentlyDenied; // ایک ہیک
  // بہتر ہے device_info_plus استعمال کریں
}

/// بیک گراؤنڈ سروس کی ترتیب
Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'system_pro_channel',
    'System Pro Service',
    description: 'Required for background tasks like uploading or recording.',
    importance: Importance.high,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'system_pro_channel',
      initialNotificationTitle: 'System Pro',
      initialNotificationContent: 'Background service is running',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onStart: onStart,
      autoStart: true,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  Timer? timer;
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setNotificationContent(
      title: 'System Pro',
      content: 'Background service is active',
    );
    timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service.isForegroundService()) {
        service.setNotificationContent(
          title: 'System Pro',
          content: 'Service running since ${DateTime.now()}',
        );
      }
    });
  }
  service.on('stop').listen((event) {
    timer?.cancel();
    service.stopSelf();
  });
}

/// اگر اجازتیں نہ ملیں تو یہ اسکرین دکھائیں
class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('System Pro')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Permissions Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This app needs camera, microphone, storage, and notification permissions to function properly.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  final granted = await _requestAllPermissions();
                  if (granted) {
                    // ایپ دوبارہ شروع کریں
                    exit(0);
                  }
                },
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings & Grant Permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Pro',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const CameraHomePage(),
    );
  }
}

class CameraHomePage extends StatefulWidget {
  const CameraHomePage({super.key});

  @override
  State<CameraHomePage> createState() => _CameraHomePageState();
}

class _CameraHomePageState extends State<CameraHomePage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  bool _isRecording = false;
  File? _lastVideo;
  VideoPlayerController? _videoController;
  bool _isCompressing = false;
  bool _backgroundServiceRunning = false;
  int _selectedCameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  double _zoomLevel = 0.0;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  String _quality = 'High';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _checkBackgroundServiceStatus();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    final camera = cameras[_selectedCameraIndex.clamp(0, cameras.length - 1)];
    _cameraController = CameraController(camera, _getResolutionPreset(), enableAudio: true);
    _cameraController!.setFlashMode(_flashMode);
    _initializeFuture = _cameraController!.initialize().then((_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  ResolutionPreset _getResolutionPreset() {
    switch (_quality) {
      case 'Low': return ResolutionPreset.low;
      case 'Medium': return ResolutionPreset.medium;
      default: return ResolutionPreset.high;
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    setState(() => _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length);
    await _cameraController?.dispose();
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    final newMode = {
      FlashMode.off: FlashMode.auto,
      FlashMode.auto: FlashMode.always,
      FlashMode.always: FlashMode.off,
    }[_flashMode]!;
    setState(() => _flashMode = newMode);
    await _cameraController?.setFlashMode(_flashMode);
  }

  Future<void> _setZoom(double value) async {
    setState(() => _zoomLevel = value);
    await _cameraController?.setZoomLevel(value);
  }

  Future<void> _startVideoRecording() async {
    try {
      await _initializeFuture;
      if (_cameraController != null && !_isRecording) {
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordDuration = Duration.zero;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration += const Duration(seconds: 1));
        });
        _showSnackBar('Recording started...');
      }
    } catch (e) {
      _showSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      if (_cameraController != null && _isRecording) {
        final XFile file = await _cameraController!.stopVideoRecording();
        _recordTimer?.cancel();
        final directory = await getApplicationDocumentsDirectory();
        final videosDir = Directory('${directory.path}/videos');
        if (!await videosDir.exists()) await videosDir.create(recursive: true);
        final savedPath = path.join(videosDir.path, '${DateTime.now().millisecondsSinceEpoch}.mp4');
        final savedFile = await File(file.path).copy(savedPath);
        setState(() {
          _isRecording = false;
          _lastVideo = savedFile;
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(savedFile)
            ..initialize().then((_) => setState(() {}));
        });
        _showSnackBar('Video saved');
      }
    } catch (e) {
      _showSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _compressVideo() async {
    if (_lastVideo == null) return;
    setState(() => _isCompressing = true);
    try {
      final outputPath = path.join(
        (await getTemporaryDirectory()).path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      final command = '-i "${_lastVideo!.path}" -vf "scale=854:480" -c:v libx264 -crf 28 -preset ultrafast "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        final compressedFile = File(outputPath);
        setState(() {
          _lastVideo = compressedFile;
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(compressedFile)
            ..initialize().then((_) => setState(() {}));
        });
        _showSnackBar('Video compressed successfully!');
      } else {
        _showSnackBar('Compression failed.');
      }
    } catch (e) {
      _showSnackBar('Compression error: $e');
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  Future<void> _toggleBackgroundService() async {
    final service = FlutterBackgroundService();
    if (_backgroundServiceRunning) {
      service.invoke('stop');
      _showSnackBar('Stopping background service...');
      await Future.delayed(const Duration(seconds: 1));
    } else {
      await service.startService();
      _showSnackBar('Starting background service...');
    }
    await _checkBackgroundServiceStatus();
  }

  Future<void> _checkBackgroundServiceStatus() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    setState(() => _backgroundServiceRunning = isRunning);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _shareScreenPlaceholder() {
    _showSnackBar('Screen sharing is not implemented in this demo. Add your WebRTC logic.');
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _cameraController?.dispose();
    _videoController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_flashMode == FlashMode.off ? Icons.flash_off : (_flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_on)),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: _switchCamera,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _quality = value);
              _initCamera();
            },
            itemBuilder: (context) => ['Low', 'Medium', 'High'].map((q) => PopupMenuItem(value: q, child: Text('Quality: $q'))).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && _cameraController != null && _cameraController!.value.isInitialized) {
                  return Stack(
                    children: [
                      CameraPreview(_cameraController!),
                      if (_isRecording)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_recordDuration.inMinutes.toString().padLeft(2, '0')}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Slider(
                          value: _zoomLevel,
                          min: 0.0,
                          max: _cameraController!.maxZoomLevel,
                          onChanged: _setZoom,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: 'record',
                          onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                          backgroundColor: _isRecording ? Colors.red : Colors.blue,
                          child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                        ),
                        FloatingActionButton(
                          heroTag: 'screen',
                          onPressed: _shareScreenPlaceholder,
                          child: const Icon(Icons.screen_share),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lastVideo != null) ...[
                      const Text('Last recorded video:', style: TextStyle(fontWeight: FontWeight.bold)),
                      AspectRatio(
                        aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                        child: _videoController != null && _videoController!.value.isInitialized
                            ? VideoPlayer(_videoController!)
                            : const Center(child: Text('Loading preview...')),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(_videoController?.value.isPlaying == true ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _isCompressing ? null : _compressVideo,
                            icon: const Icon(Icons.compress),
                            label: Text(_isCompressing ? 'Compressing...' : 'Compress Video'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _toggleBackgroundService,
                      icon: Icon(_backgroundServiceRunning ? Icons.stop : Icons.play_arrow),
                      label: Text(_backgroundServiceRunning ? 'Stop Background Service' : 'Start Background Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _backgroundServiceRunning ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
