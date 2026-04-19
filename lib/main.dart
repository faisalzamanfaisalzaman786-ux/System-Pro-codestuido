import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
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

  final allGranted = await _requestAllPermissions();
  if (!allGranted) {
    print('Some permissions denied. App may not work correctly.');
  }

  await _initBackgroundService();
  cameras = await availableCameras();
  runApp(const MyApp());
}

Future<bool> _requestAllPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.notification,
  ].request();

  bool allGranted = statuses.values.every((status) => status.isGranted);
  if (!allGranted) {
    for (var entry in statuses.entries) {
      if (entry.value.isPermanentlyDenied) {
        openAppSettings();
        return false;
      }
    }
  }
  return allGranted;
}

Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'system_pro_channel',
    'System Pro Service',
    description: 'Required for background tasks like uploads or recording.',
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

class _CameraHomePageState extends State<CameraHomePage> {
  CameraController? _cameraController;
  Future<void>? _initializeFuture;
  bool _isRecording = false;
  File? _lastVideo;
  VideoPlayerController? _videoController;
  bool _isCompressing = false;
  bool _backgroundServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _checkBackgroundServiceStatus();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    final camera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(camera, ResolutionPreset.high);
    _initializeFuture = _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _checkBackgroundServiceStatus() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    setState(() => _backgroundServiceRunning = isRunning);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _startVideoRecording() async {
    try {
      await _initializeFuture;
      if (_cameraController != null && !_isRecording) {
        await _cameraController!.startVideoRecording();
        setState(() => _isRecording = true);
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
        final directory = await getTemporaryDirectory();
        final savedPath = path.join(directory.path, '${DateTime.now()}.mp4');
        final savedFile = await File(file.path).copy(savedPath);
        setState(() {
          _isRecording = false;
          _lastVideo = savedFile;
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(savedFile)
            ..initialize().then((_) => setState(() {}));
        });
        _showSnackBar('Video saved to ${savedFile.path}');
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
        'compressed_${DateTime.now()}.mp4',
      );
      final command = '-i "${_lastVideo!.path}" -vf "scale=854:480" -c:v libx264 -crf 28 -preset ultrafast "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        setState(() {
          _lastVideo = File(outputPath);
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(_lastVideo!)
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Pro'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FutureBuilder<void>(
              future: _initializeFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _cameraController != null &&
                    _cameraController!.value.isInitialized) {
                  return CameraPreview(_cameraController!);
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (cameras.isEmpty) {
                  return const Center(child: Text('No camera found'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
