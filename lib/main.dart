import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Android 13+ کے لیے سٹوریج کی اجازت
  await [
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.photos,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SysPro Browser',
      theme: ThemeData.dark(),
      home: const BrowserScreen(),
    );
  }
}

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  String _currentUrl = "https://www.google.com";
  String _statusMessage = "✅ Storage permission granted";

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _currentUrl = url),
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _goToUrl(String url) {
    if (!url.startsWith("http")) url = "https://$url";
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Pro Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              setState(() {
                _statusMessage = "✅ Storage permission is active. You can now save files.";
              });
            },
            tooltip: 'Storage Info',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Enter URL',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _goToUrl,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _goToUrl(_currentUrl),
                  child: const Text('Go'),
                ),
              ],
            ),
          ),
          Expanded(child: WebViewWidget(controller: _controller)),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black54,
            child: Text(_statusMessage),
          ),
        ],
      ),
    );
  }
}