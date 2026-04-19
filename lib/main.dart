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

  // Request all necessary permissions
  await _requestPermissions();

  // Initialize background service
  await _initBackgroundService();

  // Get available cameras
  cameras = await availableCameras();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
    Permission.photos,
    Permission.videos,
    Permission.notification,
  ];
  Map<Permission, PermissionStatus> statuses = await permissions.request();
  // Optionally check if all granted
  if (statuses[Permission.camera] != PermissionStatus.granted) {
    print('Camera permission denied');
  }
}

Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();

  // Setup notifications for Android
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

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setNotificationContent(
      title: 'System Pro',
      content: 'Background service is active',
    );
  }

  // Periodic task (every 30 seconds)
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setNotificationContent(
        title: 'System Pro',
        content: 'Service running since ${DateTime.now()}',
      );
    }
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
  File? _lastImage;
  VideoPlayerController? _videoController;
  bool _isCompressing = false;
  double _compressionProgress = 0.0; // placeholder, FFmpegKit doesn't provide progress easily

  @override
  void initState() {
    super.initState();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.high,
      );
      _initializeFuture = _cameraController!.initialize();
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeFuture;
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      final XFile file = await _cameraController!.takePicture();
      final directory = await getTemporaryDirectory();
      final savedPath = path.join(directory.path, '${DateTime.now()}.jpg');
      await File(file.path).copy(savedPath);
      setState(() {
        _lastImage = File(savedPath);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved!')),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      await _initializeFuture;
      if (_cameraController != null && !_isRecording && _cameraController!.value.isInitialized) {
        await _cameraController!.startVideoRecording();
        setState(() => _isRecording = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording started...')),
          );
        }
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      if (_cameraController != null && _isRecording && _cameraController!.value.isRecordingVideo) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Video saved: ${savedFile.path.split('/').last}')),
          );
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
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
      // FFmpeg command: scale to 854x480, libx264 with CRF 28, ultrafast preset
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video compressed successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compression failed')),
          );
        }
      }
    } catch (e) {
      print('Compression error: $e');
    } finally {
      setState(() => _isCompressing = false);
    }
  }

  void _shareScreen() {
    // Placeholder: Replace with actual WebRTC screen sharing implementation.
    // You can integrate livekit_client or flutter_webrtc here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen sharing demo - integrate WebRTC')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Pro'), centerTitle: true),
      body: Column(
        children: [
          // Camera preview
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
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          // Controls and preview area
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'photo',
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera_alt),
                      ),
                      FloatingActionButton(
                        heroTag: 'record',
                        onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                        child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                      ),
                      FloatingActionButton(
                        heroTag: 'screen',
                        onPressed: _shareScreen,
                        child: const Icon(Icons.screen_share),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Last image preview
                  if (_lastImage != null)
                    Column(
                      children: [
                        const Text('Last photo:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Image.file(_lastImage!, height: 100),
                      ],
                    ),
                  // Last video preview and controls
                  if (_lastVideo != null) ...[
                    const SizedBox(height: 12),
                    const Text('Last recorded video:', style: TextStyle(fontWeight: FontWeight.bold)),
                    AspectRatio(
                      aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                      child: _videoController != null && _videoController!.value.isInitialized
                          ? VideoPlayer(_videoController!)
                          : const Center(child: Text('No preview')),
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
                  const SizedBox(height: 12),
                  // Background service toggle
                  ElevatedButton(
                    onPressed: () async {
                      final service = FlutterBackgroundService();
                      final isRunning = await service.isRunning();
                      if (isRunning) {
                        service.invoke('stop');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Background service stopped')),
                          );
                        }
                      } else {
                        service.startService();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Background service started')),
                          );
                        }
                      }
                    },
                    child: const Text('Toggle Background Service'),
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
