import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/digivice_game.dart';

// Original Flutter version is available in main_flutter.dart
// This is now the Flame-based version

void main() {
  runApp(const DigiviceApp());
}

class DigiviceApp extends StatelessWidget {
  const DigiviceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digivice - Flame Edition',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        fontFamily: 'Pixel Digivolve',
      ),
      home: GameWidget<DigiviceGame>.controlled(
        gameFactory: DigiviceGame.new,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
