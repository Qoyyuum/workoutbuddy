import 'package:flutter/material.dart';
import '../models/digimon.dart';
import 'pixel_sprite.dart';

class LCDDisplay extends StatelessWidget {
  final Digimon digimon;
  final String currentMenu;
  final AnimationController animationController;

  const LCDDisplay({
    super.key,
    required this.digimon,
    required this.currentMenu,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF9CB4A8), // Classic LCD green
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8BA888),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu indicator
              Text(
                '> $currentMenu',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              
              // Main display area
              Expanded(
                child: Row(
                  children: [
                    // Digimon sprite
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, animationController.value * 2),
                              child: PixelSprite(
                                sprite: digimon.sprite,
                                size: 80,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Stats panel
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatText('LV: ${digimon.level}'),
                          _buildStatText('HP: ${digimon.health}'),
                          _buildStatText('STR: ${digimon.strength}'),
                          _buildStatText('AGE: ${digimon.age}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    digimon.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Row(
                    children: [
                      if (digimon.isHungry) 
                        const Icon(Icons.restaurant, size: 12, color: Colors.red),
                      if (digimon.isHappy) 
                        const Icon(Icons.favorite, size: 12, color: Colors.red),
                      if (digimon.isDead) 
                        const Icon(Icons.close, size: 12, color: Colors.black),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 8,
        fontFamily: 'monospace',
      ),
    );
  }
}
