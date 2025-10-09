import 'package:flutter/material.dart';
import '../models/digimon.dart';
import '../widgets/lcd_display.dart';
import '../widgets/digivice_buttons.dart';
import '../services/sound_service.dart';

class DigiviceScreen extends StatefulWidget {
  const DigiviceScreen({super.key});

  @override
  State<DigiviceScreen> createState() => _DigiviceScreenState();
}

class _DigiviceScreenState extends State<DigiviceScreen>
    with TickerProviderStateMixin {
  late Digimon _currentDigimon;
  late AnimationController _animationController;
  late SoundService _soundService;
  
  int _currentMenu = 0; // 0: Status, 1: Feed, 2: Train, 3: Battle
  final List<String> _menuItems = ['STATUS', 'FEED', 'TRAIN', 'BATTLE'];

  @override
  void initState() {
    super.initState();
    _currentDigimon = Digimon.generateRandom();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _soundService = SoundService();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String button) {
    _soundService.playBeep();
    
    setState(() {
      switch (button) {
        case 'A':
          _executeCurrentMenu();
          break;
        case 'B':
          _currentMenu = (_currentMenu + 1) % _menuItems.length;
          break;
        case 'C':
          // Cancel/Back
          break;
      }
    });
  }

  void _executeCurrentMenu() {
    switch (_currentMenu) {
      case 0: // Status - just show current stats
        break;
      case 1: // Feed
        _currentDigimon.feed();
        break;
      case 2: // Train
        _currentDigimon.train();
        break;
      case 3: // Battle
        _currentDigimon.battle();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Digivice Header
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'DIGIVICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              // LCD Display
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: LCDDisplay(
                    digimon: _currentDigimon,
                    currentMenu: _menuItems[_currentMenu],
                    animationController: _animationController,
                  ),
                ),
              ),
              
              // Control Buttons
              Expanded(
                flex: 1,
                child: DigiviceButtons(
                  onButtonPressed: _onButtonPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
