import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import '../components/digimon_component.dart';
import '../components/lcd_display_component.dart';
import '../components/button_panel_component.dart';
import '../services/flame_sound_service.dart';

class DigiviceGame extends FlameGame {
  late DigimonComponent digimon;
  late LCDDisplayComponent lcdDisplay;
  late ButtonPanelComponent buttonPanel;
  late FlameSoundService soundService;
  
  // Game state
  int currentMenu = 0;
  final List<String> menuItems = ['STATUS', 'FEED', 'TRAIN', 'BATTLE'];

  @override
  Color backgroundColor() => const Color(0xFF2C2C2C);

  @override
  Future<void> onLoad() async {
    print('🎮 DigiviceGame: Loading...');
    
    // Initialize sound service
    soundService = FlameSoundService();
    
    // Create Digimon
    digimon = DigimonComponent();
    
    // Create LCD Display (takes up most of the screen)
    lcdDisplay = LCDDisplayComponent(
      digimon: digimon,
      menuItems: menuItems,
      currentMenuIndex: currentMenu,
      size: Vector2(size.x * 0.9, size.y * 0.7),
      position: Vector2(size.x * 0.05, size.y * 0.1),
    );
    
    // Create Button Panel (bottom of screen)
    buttonPanel = ButtonPanelComponent(
      size: Vector2(size.x * 0.9, size.y * 0.2),
      position: Vector2(size.x * 0.05, size.y * 0.75),
      onButtonPressed: _onButtonPressed,
    );
    
    // Add components to the game
    add(lcdDisplay);
    add(buttonPanel);
    
    print('🎮 DigiviceGame: Loaded successfully');
  }

  void _onButtonPressed(String button) {
    print('🎮 Button pressed: $button');
    
    switch (button) {
      case 'A':
        print('🎮 Executing A button action');
        soundService.playBeep();
        _executeCurrentMenu();
        break;
      case 'B':
        print('🎮 Executing B button action');
        soundService.playMenuSound();
        currentMenu = (currentMenu + 1) % menuItems.length;
        lcdDisplay.updateMenu(menuItems[currentMenu], currentMenu);
        print('🎮 Menu changed to: ${menuItems[currentMenu]}');
        break;
      case 'C':
        print('🎮 Executing C button action');
        soundService.playErrorSound();
        // Cancel/Back action
        break;
    }
  }

  void _executeCurrentMenu() {
    switch (currentMenu) {
      case 0: // Status - just show current stats
        break;
      case 1: // Feed
        digimon.feed();
        lcdDisplay.updateDigimon();
        break;
      case 2: // Train
        digimon.train();
        lcdDisplay.updateDigimon();
        break;
      case 3: // Battle
        digimon.battle();
        lcdDisplay.updateDigimon();
        break;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    
    // Update component sizes and positions when screen resizes
    if (isLoaded) {
      lcdDisplay.size = Vector2(size.x * 0.9, size.y * 0.7);
      lcdDisplay.position = Vector2(size.x * 0.05, size.y * 0.1);
      
      buttonPanel.size = Vector2(size.x * 0.9, size.y * 0.2);
      buttonPanel.position = Vector2(size.x * 0.05, size.y * 0.75);
    }
  }

  @override
  void onRemove() {
    soundService.dispose();
    super.onRemove();
  }
}
