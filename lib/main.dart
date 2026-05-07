import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Pro Ultra',
      theme: FlexThemeData.light(
        scheme: FlexScheme.mango,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.mango,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Pro Ultra')),
      body: const Center(
        child: Text('FlexColorScheme working!'),
      ),
    );
  }
}
