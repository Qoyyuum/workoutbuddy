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
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton('A', 'SELECT'),
          _buildButton('B', 'MENU'),
          _buildButton('C', 'CANCEL'),
        ],
      ),
    );
  }

  Widget _buildButton(String label, String description) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onButtonPressed(label),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF4A4A4A),
              border: Border.all(color: Colors.grey, width: 2),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
