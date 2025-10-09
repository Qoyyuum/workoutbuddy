import 'package:flutter/material.dart';

class PixelSprite extends StatelessWidget {
  final List<List<int>> sprite;
  final double size;

  const PixelSprite({
    super.key,
    required this.sprite,
    required this.size,
  });

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
  Widget build(BuildContext context) {
    final pixelSize = size / sprite.length;
    
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PixelPainter(sprite: sprite, pixelSize: pixelSize),
      ),
    );
  }
}

class PixelPainter extends CustomPainter {
  final List<List<int>> sprite;
  final double pixelSize;

  PixelPainter({required this.sprite, required this.pixelSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (int y = 0; y < sprite.length; y++) {
      for (int x = 0; x < sprite[y].length; x++) {
        final colorIndex = sprite[y][x];
        final color = PixelSprite.colorPalette[colorIndex] ?? Colors.transparent;
        
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
