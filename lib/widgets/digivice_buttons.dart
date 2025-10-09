import 'package:flutter/material.dart';

class DigiviceButtons extends StatelessWidget {
  final Function(String) onButtonPressed;

  const DigiviceButtons({
    super.key,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton('A', 'SELECT', Colors.red),
          _buildButton('B', 'MENU', Colors.blue),
          _buildButton('C', 'CANCEL', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildButton(String label, String sublabel, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => onButtonPressed(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 8,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sublabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontFamily: 'Pixel Digivolve',
          ),
        ),
      ],
    );
  }
}
