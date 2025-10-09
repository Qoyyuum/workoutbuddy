import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class ButtonPanelComponent extends PositionComponent with HasGameRef {
  final Function(String) onButtonPressed;
  
  late List<DigiviceButton> buttons;

  ButtonPanelComponent({
    required Vector2 size,
    required Vector2 position,
    required this.onButtonPressed,
  }) : super(size: size, position: position);

  @override
  Future<void> onLoad() async {
    
    // Create three buttons
    final buttonWidth = size.x / 3 - 20;
    final buttonHeight = size.y * 0.6;
    final buttonY = size.y * 0.1;
    
    buttons = [
      DigiviceButton(
        label: 'A',
        description: 'SELECT',
        size: Vector2(buttonWidth, buttonHeight),
        position: Vector2(10, buttonY),
        onPressed: () => onButtonPressed('A'),
      ),
      DigiviceButton(
        label: 'B',
        description: 'MENU',
        size: Vector2(buttonWidth, buttonHeight),
        position: Vector2(size.x / 3 + 10, buttonY),
        onPressed: () => onButtonPressed('B'),
      ),
      DigiviceButton(
        label: 'C',
        description: 'CANCEL',
        size: Vector2(buttonWidth, buttonHeight),
        position: Vector2(size.x * 2 / 3 + 10, buttonY),
        onPressed: () => onButtonPressed('C'),
      ),
    ];
    
    addAll(buttons);
  }
}

class DigiviceButton extends RectangleComponent with TapCallbacks {
  final String label;
  final String description;
  final VoidCallback onPressed;
  
  late TextComponent labelText;
  late TextComponent descriptionText;

  DigiviceButton({
    required this.label,
    required this.description,
    required Vector2 size,
    required Vector2 position,
    required this.onPressed,
  }) : super(
          size: size,
          position: position,
          paint: Paint()..color = const Color(0xFF4A4A4A),
        );

  @override
  Future<void> onLoad() async {
    // Add border effect
    add(RectangleComponent(
      size: size - Vector2.all(4),
      position: Vector2.all(2),
      paint: Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
    
    // Add button label
    labelText = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2 - 10),
    );
    add(labelText);
    
    // Add button description
    descriptionText = TextComponent(
      text: description,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pixel Digivolve',
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y - 15),
    );
    add(descriptionText);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    // Visual feedback - darken button
    paint.color = const Color(0xFF2A2A2A);
    return true;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    // Restore button color
    paint.color = const Color(0xFF4A4A4A);
    onPressed();
    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    // Restore button color if tap is cancelled
    paint.color = const Color(0xFF4A4A4A);
    return true;
  }
}
