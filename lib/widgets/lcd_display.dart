import 'package:flutter/material.dart';
import '../models/workout_buddy.dart';
import 'pixel_sprite.dart';

class LCDDisplay extends StatelessWidget {
  final WorkoutBuddy workoutBuddy;
  final String currentMenu;
  final AnimationController animationController;
  final List<String> menuItems;
  final int currentMenuIndex;

  const LCDDisplay({
    super.key,
    required this.workoutBuddy,
    required this.currentMenu,
    required this.animationController,
    required this.menuItems,
    required this.currentMenuIndex,
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
              // Menu navigation display
              _buildMenuNavigation(),
              const SizedBox(height: 8),
              
              // Main display area
              Expanded(
                child: Row(
                  children: [
                    // WorkoutBuddy sprite
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: animationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, animationController.value * 2),
                              child: PixelSprite(
                                sprite: workoutBuddy.sprite,
                                size: 80,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Stats display
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatText('LV: ${workoutBuddy.level} | HP: ${workoutBuddy.health} | STR: ${workoutBuddy.strength} | AGE: ${workoutBuddy.age}'),
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
                    workoutBuddy.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pixel Digivolve',
                    ),
                  ),
                  Row(
                    children: [
                      if (workoutBuddy.isHungry) 
                        const Icon(Icons.restaurant, size: 16, color: Colors.red),
                      if (workoutBuddy.isHappy) 
                        const Icon(Icons.favorite, size: 16, color: Colors.red),
                      if (workoutBuddy.isDead) 
                        const Icon(Icons.close, size: 16, color: Colors.black),
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

  Widget _buildMenuNavigation() {
    String prevMenu = '';
    String nextMenu = '';
    
    if (menuItems.isNotEmpty) {
      int prevIndex = (currentMenuIndex - 1 + menuItems.length) % menuItems.length;
      int nextIndex = (currentMenuIndex + 1) % menuItems.length;
      prevMenu = menuItems[prevIndex];
      nextMenu = menuItems[nextIndex];
    }
    
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous menu (left side, faded)
          Expanded(
            child: Text(
              '< $prevMenu',
              style: const TextStyle(
                color: Color(0xFF5A6B5D),
                fontSize: 12,
                fontFamily: 'Pixel Digivolve',
              ),
            ),
          ),
          
          // Current menu (center, highlighted)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7A8B7D),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Text(
                  currentMenu,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pixel Digivolve',
                  ),
                ),
              ),
            ),
          ),
          
          // Next menu (right side, faded)
          Expanded(
            child: Text(
              '$nextMenu >',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF5A6B5D),
                fontSize: 12,
                fontFamily: 'Pixel Digivolve',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'Pixel Digivolve',
      ),
    );
  }
}
