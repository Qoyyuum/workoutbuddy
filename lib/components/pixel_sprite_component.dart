import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'workout_buddy_component.dart';

class PixelSpriteComponent extends CustomPainterComponent {
  List<List<int>> sprite;
  final double spriteSize;
  
  PixelSpriteComponent({
    required this.sprite,
    required this.spriteSize,
    required Vector2 position,
  }) : super(
          painter: PixelSpritePainter(sprite: sprite, spriteSize: spriteSize),
          size: Vector2.all(spriteSize),
          position: position,
        );

  void updateSprite(List<List<int>> newSprite) {
    sprite = newSprite;
    painter = PixelSpritePainter(sprite: sprite, spriteSize: spriteSize);
  }
}

class PixelSpritePainter extends CustomPainter {
  final List<List<int>> sprite;
  final double spriteSize;
  late final double pixelSize;

  PixelSpritePainter({
    required this.sprite,
    required this.spriteSize,
  }) {
    pixelSize = sprite.isNotEmpty ? spriteSize / sprite.length : 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (sprite.isEmpty) return;
    
    for (int y = 0; y < sprite.length; y++) {
      for (int x = 0; x < sprite[y].length; x++) {
        final colorIndex = sprite[y][x];
        final color = WorkoutBuddyComponent.colorPalette[colorIndex] ?? Colors.transparent;
        
        if (color != Colors.transparent) {
          final paint = Paint()..color = color;
          final rect = Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          );
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PixelSpritePainter) {
      return sprite != oldDelegate.sprite || spriteSize != oldDelegate.spriteSize;
    }
    return true;
  }
}
