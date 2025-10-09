import 'package:flutter/material.dart';
import '../models/workout_buddy.dart';
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
  late WorkoutBuddy _currentWorkoutBuddy;
  late AnimationController _animationController;
  late SoundService _soundService;
  
  int _currentMenu = 0; // 0: Status, 1: Feed, 2: Train, 3: Battle
  final List<String> _menuItems = ['STATUS', 'FEED', 'TRAIN', 'BATTLE'];

  @override
  void initState() {
    super.initState();
    _currentWorkoutBuddy = WorkoutBuddy.generateRandom();
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
    _soundService.dispose();
    super.dispose();
  }

  void _onButtonPressed(String button) {
    debugPrint('🎮 Button pressed: $button');
    setState(() {
      switch (button) {
        case 'A':
          debugPrint('🎮 Executing A button action');
          _soundService.playBeep(); // Action sound
          _executeCurrentMenu();
          break;
        case 'B':
          debugPrint('🎮 Executing B button action');
          _soundService.playMenuSound(); // Menu navigation sound
          _currentMenu = (_currentMenu + 1) % _menuItems.length;
          debugPrint('🎮 Menu changed to: ${_menuItems[_currentMenu]}');
          break;
        case 'C':
          debugPrint('🎮 Executing C button action');
          _soundService.playErrorSound(); // Cancel sound
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
        _currentWorkoutBuddy.feed();
        break;
      case 2: // Train
        _currentWorkoutBuddy.train();
        break;
      case 3: // Battle
        _currentWorkoutBuddy.battle();
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
                    workoutBuddy: _currentWorkoutBuddy,
                    currentMenu: _menuItems[_currentMenu],
                    animationController: _animationController,
                    menuItems: _menuItems,
                    currentMenuIndex: _currentMenu,
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
