import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(TorchApp(cameras: cameras));
}

class TorchApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const TorchApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torch Tester',
      theme: ThemeData.dark(),
      home: TorchScreen(cameras: cameras),
    );
  }
}

class TorchScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const TorchScreen({super.key, required this.cameras});

  @override
  State<TorchScreen> createState() => _TorchScreenState();
}

class _TorchScreenState extends State<TorchScreen> {
  CameraController? _controller;
  bool _isTorchOn = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    final camera = widget.cameras.first;
    _controller = CameraController(camera, ResolutionPreset.medium);
    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) { print("Camera error: $e"); }
  }

  Future<void> _toggleTorch() async {
    if (!_isCameraReady || _controller == null) return;
    try {
      if (_isTorchOn) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() => _isTorchOn = false);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        setState(() => _isTorchOn = true);
      }
    } catch (e) { print("Torch error: $e"); }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Torch Tester'), centerTitle: true, backgroundColor: Colors.black),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: _isTorchOn ? Colors.yellow : Colors.grey,
            boxShadow: _isTorchOn ? [BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 100, spreadRadius: 50)] : []),
            child: Icon(Icons.lightbulb, size: 100, color: _isTorchOn ? Colors.white : Colors.black54)),
          const SizedBox(height: 60),
          GestureDetector(onTap: _toggleTorch, child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _isTorchOn ? Colors.amber : Colors.blueGrey,
              boxShadow: [BoxShadow(color: (_isTorchOn ? Colors.amber : Colors.blueGrey).withOpacity(0.5), blurRadius: 20, spreadRadius: 5)]),
            child: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, size: 60, color: Colors.white))),
          const SizedBox(height: 40),
          Text(_isTorchOn ? 'TORCH ON' : 'TORCH OFF', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
            child: Text(_isCameraReady ? '✅ Camera Ready' : '⏳ Initializing Camera...', style: const TextStyle(color: Colors.white70))),
        ]),
      ),
    );
  }
}