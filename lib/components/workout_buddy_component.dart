import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WorkoutBuddyComponent extends Component {
  String name;
  int level;
  int health;
  int maxHealth;
  int hunger;
  int strength;
  int happiness;
  int age;
  List<List<int>> sprite;
  
  WorkoutBuddyComponent({
    this.name = '',
    this.level = 1,
    this.health = 100,
    this.maxHealth = 100,
    this.hunger = 50,
    this.strength = 10,
    this.happiness = 50,
    this.age = 0,
    List<List<int>>? sprite,
  }) : sprite = sprite ?? [] {
    if (name.isEmpty || this.sprite.isEmpty) {
      _generateRandom();
    }
  }

  void _generateRandom() {
    final random = Random();
    final names = ['Buddy', 'Sparky', 'Flash', 'Thunder', 'Blaze', 'Storm'];
    name = names[random.nextInt(names.length)];
    sprite = _generateRandomSprite(random);
  }

  static List<List<int>> _generateRandomSprite(Random random) {
    // Generate a 16x16 pixel sprite
    List<List<int>> sprite = [];
    
    for (int y = 0; y < 16; y++) {
      List<int> row = [];
      for (int x = 0; x < 16; x++) {
        // Create a simple creature-like pattern
        if (_isInCreatureShape(x, y)) {
          // Use different colors for different parts
          if (y < 4) {
            row.add(random.nextInt(3) + 1); // Head colors (1-3)
          } else if (y < 10) {
            row.add(random.nextInt(2) + 4); // Body colors (4-5)
          } else {
            row.add(random.nextInt(2) + 6); // Leg colors (6-7)
          }
        } else {
          row.add(0); // Transparent
        }
      }
      sprite.add(row);
    }
    
    return sprite;
  }

  static bool _isInCreatureShape(int x, int y) {
    // Define a simple creature silhouette
    if (y < 4) {
      // Head - circular shape
      int centerX = 8, centerY = 2;
      double distance = ((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY)).toDouble();
      return distance <= 9; // Radius of 3
    } else if (y < 10) {
      // Body - rectangular
      return x >= 5 && x <= 10;
    } else if (y < 14) {
      // Legs
      return (x >= 5 && x <= 6) || (x >= 9 && x <= 10);
    } else {
      // Feet
      return (x >= 4 && x <= 7) || (x >= 8 && x <= 11);
    }
  }

  void feed() {
    hunger = (hunger - 20).clamp(0, 100);
    happiness = (happiness + 10).clamp(0, 100);
    health = (health + 5).clamp(0, maxHealth);
    debugPrint('🍖 $name was fed! Hunger: $hunger, Happiness: $happiness');
  }

  void train() {
    strength += 2;
    hunger = (hunger + 15).clamp(0, 100);
    happiness = (happiness + 5).clamp(0, 100);
    
    debugPrint('💪 $name trained! Strength: $strength');
    
    if (strength > level * 20) {
      evolve();
    }
  }

  void battle() {
    final random = Random();
    bool won = random.nextBool();
    
    if (won) {
      strength += 5;
      happiness = (happiness + 15).clamp(0, 100);
      debugPrint('⚔️ $name won the battle! Strength: $strength');
    } else {
      health = (health - 10).clamp(0, maxHealth);
      happiness = (happiness - 5).clamp(0, 100);
      debugPrint('💥 $name lost the battle. Health: $health');
    }
    
    hunger = (hunger + 10).clamp(0, 100);
  }

  void evolve() {
    if (level < 5) {
      level++;
      maxHealth += 20;
      health = maxHealth;
      strength += 10;
      
      // Generate new sprite for evolution
      final random = Random();
      sprite = _generateRandomSprite(random);
      
      // Update name to show evolution
      name = '$name${level > 2 ? ' II' : ''}';
      
      debugPrint('✨ $name evolved to level $level!');
    }
  }

  void tick() {
    // Called periodically to simulate time passing
    age++;
    hunger = (hunger + 1).clamp(0, 100);
    
    if (hunger > 80) {
      happiness = (happiness - 1).clamp(0, 100);
      health = (health - 1).clamp(0, maxHealth);
    }
  }

  bool get isDead => health <= 0;
  bool get isHungry => hunger > 70;
  bool get isHappy => happiness > 70;

  // Color palette for sprite rendering
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
}
