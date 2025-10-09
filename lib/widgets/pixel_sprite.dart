import 'package:flutter/material.dart';

class PixelSprite extends StatelessWidget {
  final List<List<int>> sprite;
  final double size;

  const PixelSprite({
    super.key,
    required this.sprite,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (sprite.isEmpty) {
      return SizedBox(width: size, height: size);
    }

    return CustomPaint(
      size: Size(size, size),
      painter: _PixelSpritePainter(sprite: sprite),
    );
  }
}

class _PixelSpritePainter extends CustomPainter {
  final List<List<int>> sprite;

  _PixelSpritePainter({required this.sprite});

  // Color palette matching WorkoutBuddy
  static const Map<int, Color> colorPalette = {
    0: Colors.transparent,
    1: Color(0xFF8B4513), // Brown (head)
    2: Color(0xFFFFE4B5), // Light brown (head)
    3: Color(0xFF000000), // Black (eyes/details)
    4: Color(0xFF32CD32), // Green (body)
    5: Color(0xFF228B22), // Dark green (body)
    6: Color(0xFF4169E1), // Blue (legs)
    7: Color(0xFF191970), // Dark blue (legs)
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (sprite.isEmpty) return;

    final pixelSize = size.width / sprite.length;

    for (int y = 0; y < sprite.length; y++) {
      for (int x = 0; x < sprite[y].length; x++) {
        final colorIndex = sprite[y][x];
        final color = colorPalette[colorIndex] ?? Colors.transparent;

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
