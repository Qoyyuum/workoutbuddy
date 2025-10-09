import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/digivice_game.dart';

void main() {
  runApp(const DigiviceFlameApp());
}

class DigiviceFlameApp extends StatelessWidget {
  const DigiviceFlameApp({super.key});

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
