import 'package:flutter/material.dart';
import '../models/workout_buddy.dart';
import '../widgets/lcd_display.dart';
import '../widgets/digivice_buttons.dart';
import '../services/sound_service.dart';
import 'food_entry_screen.dart';

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
  
  int _currentMenu = 0; // 0: Status, 1: Food, 2: Feed, 3: Train, 4: Battle
  final List<String> _menuItems = ['STATUS', 'FOOD', 'FEED', 'TRAIN', 'BATTLE'];

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
      case 1: // Food - open food diary
        _openFoodDiary();
        break;
      case 2: // Feed
        _currentWorkoutBuddy.feed();
        break;
      case 3: // Train
        _currentWorkoutBuddy.train();
        break;
      case 4: // Battle
        _currentWorkoutBuddy.battle();
        break;
    }
  }

  Future<void> _openFoodDiary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodEntryScreen(
          workoutBuddy: _currentWorkoutBuddy,
          onStatUpdate: (statChanges) {
            setState(() {
              _currentWorkoutBuddy.health = (_currentWorkoutBuddy.health + (statChanges['health'] ?? 0)).clamp(0, _currentWorkoutBuddy.maxHealth).toInt();
              _currentWorkoutBuddy.strength += statChanges['strength'] ?? 0;
              _currentWorkoutBuddy.happiness = (_currentWorkoutBuddy.happiness + (statChanges['happiness'] ?? 0)).clamp(0, 100).toInt();
            });
          },
        ),
      ),
    );
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
