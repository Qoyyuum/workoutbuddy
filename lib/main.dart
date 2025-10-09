import 'package:flutter/material.dart';
import 'screens/digivice_screen.dart';

void main() {
  runApp(const DigiviceApp());
}

class DigiviceApp extends StatelessWidget {
  const DigiviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digivice',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        fontFamily: 'monospace',
      ),
      home: const DigiviceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
