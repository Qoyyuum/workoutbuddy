import 'dart:math';
import 'workout_type.dart';

class WorkoutBuddy {
  String name;
  int level;
  int health;
  int maxHealth;
  int hunger;
  int strength;
  int agility;
  int endurance;
  int happiness;
  int age;
  List<List<int>> sprite;
  
  // Base stats (permanent)
  int baseStrength;
  int baseAgility;
  int baseEndurance;
  
  // Temporary stat buffs (decay over time)
  Map<StatType, StatBuff> activeBuffs;
  
  WorkoutBuddy({
    required this.name,
    this.level = 1,
    this.health = 100,
    this.maxHealth = 100,
    this.hunger = 50,
    this.strength = 10,
    this.agility = 10,
    this.endurance = 10,
    this.happiness = 50,
    this.age = 0,
    required this.sprite,
    int? baseStrength,
    int? baseAgility,
    int? baseEndurance,
    Map<StatType, StatBuff>? activeBuffs,
  }) : baseStrength = baseStrength ?? strength,
       baseAgility = baseAgility ?? agility,
       baseEndurance = baseEndurance ?? endurance,
       activeBuffs = activeBuffs ?? {};

  static WorkoutBuddy generateRandom() {
    final random = Random();
    final names = ['Buddy', 'Sparky', 'Flash', 'Thunder', 'Blaze', 'Storm'];
    final name = names[random.nextInt(names.length)];
    
    return WorkoutBuddy(
      name: name,
      sprite: _generateRandomSprite(random),
    );
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
  }

  void train() {
    strength += 2;
    hunger = (hunger + 15).clamp(0, 100);
    happiness = (happiness + 5).clamp(0, 100);
    
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
    } else {
      health = (health - 10).clamp(0, maxHealth);
      happiness = (happiness - 5).clamp(0, 100);
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

  /// Apply workout gains to stats
  void applyWorkoutGains(Map<StatType, int> gains) {
    for (final entry in gains.entries) {
      final statType = entry.key;
      final amount = entry.value;
      
      // Create temporary buff that lasts 2 hours and decays over time
      final buff = StatBuff(
        amount: amount,
        createdAt: DateTime.now(),
        duration: const Duration(hours: 2),
      );
      
      // Add or stack the buff
      if (activeBuffs.containsKey(statType)) {
        final existingBuff = activeBuffs[statType]!;
        final combinedAmount = existingBuff.currentAmount + amount;
        activeBuffs[statType] = StatBuff(
          amount: combinedAmount,
          createdAt: DateTime.now(),
          duration: const Duration(hours: 2),
        );
      } else {
        activeBuffs[statType] = buff;
      }
      
      // Update current stats
      _updateCurrentStats();
    }
  }

  /// Update current stats based on base stats + active buffs
  void _updateCurrentStats() {
    // Clean up expired buffs first
    activeBuffs.removeWhere((_, buff) => buff.isExpired);
    
    // Calculate current stats
    strength = baseStrength + (activeBuffs[StatType.strength]?.currentAmount ?? 0);
    agility = baseAgility + (activeBuffs[StatType.agility]?.currentAmount ?? 0);
    endurance = baseEndurance + (activeBuffs[StatType.endurance]?.currentAmount ?? 0);
  }

  /// Get current effective stats (base + buffs)
  Map<StatType, int> get currentStats {
    _updateCurrentStats();
    return {
      StatType.strength: strength,
      StatType.agility: agility,
      StatType.endurance: endurance,
      StatType.health: health,
      StatType.happiness: happiness,
    };
  }

  /// Get base stats (permanent)
  Map<StatType, int> get baseStats {
    return {
      StatType.strength: baseStrength,
      StatType.agility: baseAgility,
      StatType.endurance: baseEndurance,
      StatType.health: health,
      StatType.happiness: happiness,
    };
  }
}
