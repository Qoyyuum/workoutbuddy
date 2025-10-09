import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'workout_buddy_component.dart';
import 'pixel_sprite_component.dart';

class LCDDisplayComponent extends RectangleComponent {
  final WorkoutBuddyComponent workoutBuddy;
  final List<String> menuItems;
  int currentMenuIndex;
  
  late TextComponent menuText;
  late TextComponent digimonNameText;
  late TextComponent statsText;
  late PixelSpriteComponent workoutBuddySprite;
  late RectangleComponent menuBackground;
  late TextComponent prevMenuText;
  late TextComponent nextMenuText;
  
  LCDDisplayComponent({
    required this.workoutBuddy,
    required this.menuItems,
    required this.currentMenuIndex,
    required Vector2 size,
    required Vector2 position,
  }) : super(
          size: size,
          position: position,
          paint: Paint()..color = const Color(0xFF9CB4A8),
        );

  @override
  Future<void> onLoad() async {
    // Create LCD border
    add(RectangleComponent(
      size: size - Vector2.all(6),
      position: Vector2.all(3),
      paint: Paint()..color = const Color(0xFF8BA888),
    ));
    
    // Create menu navigation area
    await _createMenuNavigation();
    
    // Create main display area
    await _createMainDisplay();
    
    // Start floating animation for Digimon sprite
    _startSpriteAnimation();
  }

  Future<void> _createMenuNavigation() async {
    // Menu background with border
    menuBackground = RectangleComponent(
      size: Vector2(size.x - 20, 70),
      position: Vector2(10, 10),
      paint: Paint()..color = const Color(0xFF7A8B7D),
    );
    add(menuBackground);
    
    // Menu border
    add(RectangleComponent(
      size: Vector2(size.x - 24, 66),
      position: Vector2(12, 12),
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
    
    // Previous menu indicator (left arrow)
    add(TextComponent(
      text: '◀',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A6B5D),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      position: Vector2(20, 25),
    ));
    
    // Previous menu text
    prevMenuText = TextComponent(
      text: _getPreviousMenu(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A6B5D),
          fontSize: 10,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      position: Vector2(40, 30),
    );
    add(prevMenuText);
    
    // Current menu (center, highlighted)
    final currentMenuBg = RectangleComponent(
      size: Vector2(120, 40),
      position: Vector2(size.x / 2 - 60, 20),
      paint: Paint()..color = const Color(0xFF6A7B6D),
    );
    add(currentMenuBg);
    
    // Current menu border
    add(RectangleComponent(
      size: Vector2(116, 36),
      position: Vector2(size.x / 2 - 58, 22),
      paint: Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    ));
    
    // Current menu text
    menuText = TextComponent(
      text: menuItems[currentMenuIndex],
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 40),
    );
    add(menuText);
    
    // Next menu text
    nextMenuText = TextComponent(
      text: _getNextMenu(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A6B5D),
          fontSize: 10,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      position: Vector2(size.x - 80, 30),
    );
    add(nextMenuText);
    
    // Next menu indicator (right arrow)
    add(TextComponent(
      text: '▶',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF5A6B5D),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      position: Vector2(size.x - 35, 25),
    ));
  }

  Future<void> _createMainDisplay() async {
    // WorkoutBuddy sprite
    workoutBuddySprite = PixelSpriteComponent(
      sprite: workoutBuddy.sprite,
      spriteSize: 80,
      position: Vector2(size.x * 0.25, size.y * 0.4),
    );
    add(workoutBuddySprite);
    
    // Stats display
    statsText = TextComponent(
      text: _getStatsText(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      position: Vector2(size.x * 0.6, size.y * 0.3),
    );
    add(statsText);
    
    // WorkoutBuddy name
    digimonNameText = TextComponent(
      text: workoutBuddy.name,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      position: Vector2(20, size.y - 40),
    );
    add(digimonNameText);
    
    // Status indicators
    await _createStatusIndicators();
  }

  Future<void> _createStatusIndicators() async {
    double iconY = size.y - 40;
    double iconX = size.x - 100;
    
    if (workoutBuddy.isHungry) {
      add(TextComponent(
        text: '🍴',
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 16),
        ),
        position: Vector2(iconX, iconY),
      ));
      iconX += 25;
    }
    
    if (workoutBuddy.isHappy) {
      add(TextComponent(
        text: '❤️',
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 16),
        ),
        position: Vector2(iconX, iconY),
      ));
      iconX += 25;
    }
    
    if (workoutBuddy.isDead) {
      add(TextComponent(
        text: '✖️',
        textRenderer: TextPaint(
          style: const TextStyle(fontSize: 16),
        ),
        position: Vector2(iconX, iconY),
      ));
    }
  }

  void _startSpriteAnimation() {
    // Add floating animation to the WorkoutBuddy sprite
    workoutBuddySprite.add(
      MoveEffect.by(
        Vector2(0, -4),
        EffectController(
          duration: 1.0,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  String _getPreviousMenu() {
    if (menuItems.isEmpty) return '';
    int prevIndex = (currentMenuIndex - 1 + menuItems.length) % menuItems.length;
    return menuItems[prevIndex];
  }
  
  String _getNextMenu() {
    if (menuItems.isEmpty) return '';
    int nextIndex = (currentMenuIndex + 1) % menuItems.length;
    return menuItems[nextIndex];
  }
  

  String _getStatsText() {
    return '''LV: ${workoutBuddy.level}
HP: ${workoutBuddy.health}
STR: ${workoutBuddy.strength}
AGE: ${workoutBuddy.age}''';
  }

  void updateMenu(String newMenu, int newIndex) {
    currentMenuIndex = newIndex;
    
    // Update all menu text components directly
    menuText.text = menuItems[currentMenuIndex];
    prevMenuText.text = _getPreviousMenu();
    nextMenuText.text = _getNextMenu();
  }

  void updateWorkoutBuddy() {
    // Update all WorkoutBuddy-related displays
    statsText.text = _getStatsText();
    digimonNameText.text = workoutBuddy.name;
    workoutBuddySprite.updateSprite(workoutBuddy.sprite);
    
    // Clear and recreate status indicators
    removeWhere((component) => component is TextComponent && 
        (component.text == '🍴' || component.text == '❤️' || component.text == '✖️'));
    _createStatusIndicators();
  }
}
