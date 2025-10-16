// Comprehensive test suite for Workout Buddy app
import 'package:flutter_test/flutter_test.dart';
import 'package:workoutbuddy/main.dart';
import 'package:workoutbuddy/models/workout_buddy.dart';
import 'package:workoutbuddy/models/food_nutrition.dart';
import 'package:workoutbuddy/models/user_profile.dart';
import 'package:workoutbuddy/models/food_diary_entry.dart';
import 'package:workoutbuddy/models/workout_type.dart';
import 'package:workoutbuddy/services/calorie_calculator.dart';

void main() {
  // Widget Tests
  group('Widget Tests', () {
    testWidgets('Workout Buddy app can be instantiated', (WidgetTester tester) async {
      // Basic smoke test - just verify app can be instantiated
      // Full rendering tests would require mocking platform channels
      expect(() => const WorkoutBuddyApp(), returnsNormally);
    });
  });

  // CalorieCalculator Service Tests
  group('CalorieCalculator', () {
    group('calculateBMR', () {
      test('calculates BMR correctly for male', () {
        final bmr = CalorieCalculator.calculateBMR(
          weightKg: 80,
          heightCm: 180,
          age: 30,
          isMale: true,
        );
        expect(bmr, equals(1780));
      });

      test('calculates BMR correctly for female', () {
        final bmr = CalorieCalculator.calculateBMR(
          weightKg: 65,
          heightCm: 165,
          age: 25,
          isMale: false,
        );
        expect(bmr, equals(1395.25));
      });

      test('handles edge cases with valid inputs', () {
        final bmr = CalorieCalculator.calculateBMR(
          weightKg: 40,
          heightCm: 150,
          age: 18,
          isMale: true,
        );
        expect(bmr, greaterThan(0));
      });
    });

    group('calculateTDEE', () {
      test('calculates TDEE with sedentary activity level', () {
        final tdee = CalorieCalculator.calculateTDEE(
          bmr: 1500,
          activityLevel: ActivityLevel.sedentary,
        );
        expect(tdee, equals(1500 * 1.2));
      });

      test('calculates TDEE with moderately active level', () {
        final tdee = CalorieCalculator.calculateTDEE(
          bmr: 1500,
          activityLevel: ActivityLevel.moderatelyActive,
        );
        expect(tdee, equals(1500 * 1.55));
      });

      test('calculates TDEE with extremely active level', () {
        final tdee = CalorieCalculator.calculateTDEE(
          bmr: 1500,
          activityLevel: ActivityLevel.extremelyActive,
        );
        expect(tdee, equals(1500 * 1.9));
      });
    });

    group('calculateCalorieGoal', () {
      test('calculates deficit for weight loss goal', () {
        final goal = CalorieCalculator.calculateCalorieGoal(
          tdee: 2000,
          goal: FitnessGoal.lose,
        );
        expect(goal, equals(1500));
      });

      test('maintains TDEE for maintain goal', () {
        final goal = CalorieCalculator.calculateCalorieGoal(
          tdee: 2000,
          goal: FitnessGoal.maintain,
        );
        expect(goal, equals(2000));
      });

      test('calculates surplus for muscle gain goal', () {
        final goal = CalorieCalculator.calculateCalorieGoal(
          tdee: 2000,
          goal: FitnessGoal.gain,
        );
        expect(goal, equals(2300));
      });
    });

    group('calculateMacros', () {
      test('calculates macros for weight loss goal', () {
        final macros = CalorieCalculator.calculateMacros(
          calorieGoal: 2000,
          goal: FitnessGoal.lose,
        );
        expect(macros['protein'], equals(2000 * 0.35 / 4));
        expect(macros['fat'], equals(2000 * 0.30 / 9));
        expect(macros['carbs'], equals(2000 * 0.35 / 4));
      });

      test('ensures all macros are present', () {
        final macros = CalorieCalculator.calculateMacros(
          calorieGoal: 2000,
          goal: FitnessGoal.maintain,
        );
        expect(macros.containsKey('protein'), isTrue);
        expect(macros.containsKey('carbs'), isTrue);
        expect(macros.containsKey('fat'), isTrue);
      });

      test('ensures macros are positive values', () {
        final macros = CalorieCalculator.calculateMacros(
          calorieGoal: 1500,
          goal: FitnessGoal.lose,
        );
        expect(macros['protein']!, greaterThan(0));
        expect(macros['carbs']!, greaterThan(0));
        expect(macros['fat']!, greaterThan(0));
      });
    });

    test('getDefaultCalorieGoal returns 2200', () {
      expect(CalorieCalculator.getDefaultCalorieGoal(), equals(2200));
    });

    test('ActivityLevel enum has correct multipliers', () {
      expect(ActivityLevel.sedentary.multiplier, equals(1.2));
      expect(ActivityLevel.lightlyActive.multiplier, equals(1.375));
      expect(ActivityLevel.moderatelyActive.multiplier, equals(1.55));
      expect(ActivityLevel.veryActive.multiplier, equals(1.725));
      expect(ActivityLevel.extremelyActive.multiplier, equals(1.9));
    });
  });

  // FoodNutrition Model Tests
  group('FoodNutrition', () {
    test('constructor creates instance with correct values', () {
      final food = FoodNutrition(
        foodName: 'Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        fiber: 0,
        servingSize: '100g',
      );
      expect(food.foodName, equals('Chicken Breast'));
      expect(food.calories, equals(165));
      expect(food.protein, equals(31));
    });

    test('isHealthy returns true for high protein food', () {
      final food = FoodNutrition(
        foodName: 'Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        fiber: 0,
        servingSize: '100g',
      );
      expect(food.isHealthy, isTrue);
    });

    test('isHealthy returns true for high fiber food', () {
      final food = FoodNutrition(
        foodName: 'Oatmeal',
        calories: 150,
        protein: 5,
        carbs: 27,
        fat: 2.5,
        fiber: 4,
        servingSize: '1 cup',
      );
      expect(food.isHealthy, isTrue);
    });

    test('isHealthy returns false for low nutrition food', () {
      final food = FoodNutrition(
        foodName: 'Candy',
        calories: 200,
        protein: 0,
        carbs: 50,
        fat: 0,
        fiber: 0,
        servingSize: '1 bar',
      );
      expect(food.isHealthy, isFalse);
    });

    test('calculateStatImpact gives strength boost for high protein', () {
      final food = FoodNutrition(
        foodName: 'Steak',
        calories: 250,
        protein: 25,
        carbs: 0,
        fat: 15,
        fiber: 0,
        servingSize: '100g',
      );
      final impact = food.calculateStatImpact();
      expect(impact['strength'], greaterThan(0));
    });

    test('calculateStatImpact penalizes very high calorie meals', () {
      final food = FoodNutrition(
        foodName: 'Giant Burger',
        calories: 1000,
        protein: 30,
        carbs: 80,
        fat: 50,
        fiber: 2,
        servingSize: '1 burger',
      );
      final impact = food.calculateStatImpact();
      expect(impact['health'], lessThan(0));
    });

    test('calculateStatImpact always provides happiness', () {
      final food = FoodNutrition(
        foodName: 'Any Food',
        calories: 100,
        protein: 5,
        carbs: 10,
        fat: 3,
        fiber: 1,
        servingSize: '1 serving',
      );
      final impact = food.calculateStatImpact();
      expect(impact.containsKey('happiness'), isTrue);
    });
  });

  // StatBuff Model Tests
  group('StatBuff', () {
    test('isExpired returns false for recent buff', () {
      final buff = StatBuff(
        amount: 10,
        createdAt: DateTime.now(),
        duration: const Duration(hours: 2),
      );
      expect(buff.isExpired, isFalse);
    });

    test('isExpired returns true for old buff', () {
      final buff = StatBuff(
        amount: 10,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        duration: const Duration(hours: 2),
      );
      expect(buff.isExpired, isTrue);
    });

    test('decayFactor is close to 1.0 at creation', () {
      final buff = StatBuff(
        amount: 10,
        createdAt: DateTime.now(),
        duration: const Duration(hours: 2),
      );
      expect(buff.decayFactor, closeTo(1.0, 0.01));
    });

    test('decayFactor decreases over time', () {
      final buff = StatBuff(
        amount: 10,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        duration: const Duration(hours: 2),
      );
      expect(buff.decayFactor, lessThan(1.0));
      expect(buff.decayFactor, greaterThan(0.0));
    });

    test('currentAmount decays over time', () {
      final buff = StatBuff(
        amount: 10,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        duration: const Duration(hours: 2),
      );
      expect(buff.currentAmount, lessThan(10));
      expect(buff.currentAmount, greaterThan(0));
    });

    test('currentAmount is 0 when expired', () {
      final buff = StatBuff(
        amount: 10,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        duration: const Duration(hours: 2),
      );
      expect(buff.currentAmount, equals(0));
    });
  });

  // WorkoutBuddy Model Tests
  group('WorkoutBuddy', () {
    test('constructor creates buddy with default values', () {
      final buddy = WorkoutBuddy(
        name: 'Test Buddy',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
      );
      expect(buddy.name, equals('Test Buddy'));
      expect(buddy.level, equals(1));
      expect(buddy.health, equals(100));
      expect(buddy.strength, equals(10));
      expect(buddy.agility, equals(10));
      expect(buddy.endurance, equals(10));
    });

    test('feed decreases hunger and increases happiness', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        hunger: 80,
      );
      final initialHunger = buddy.hunger;
      final initialHappiness = buddy.happiness;
      buddy.feed();
      expect(buddy.hunger, lessThan(initialHunger));
      expect(buddy.happiness, greaterThan(initialHappiness));
    });

    test('feed clamps hunger to minimum 0', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        hunger: 10,
      );
      buddy.feed();
      expect(buddy.hunger, greaterThanOrEqualTo(0));
    });

    test('train increases strength', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
      );
      final initialStrength = buddy.strength;
      buddy.train();
      expect(buddy.strength, greaterThan(initialStrength));
    });

    test('evolve increases level and stats', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        level: 1,
        strength: 100,
      );
      final initialLevel = buddy.level;
      buddy.evolve();
      expect(buddy.level, greaterThan(initialLevel));
      expect(buddy.health, equals(buddy.maxHealth));
    });

    test('evolve does not exceed level 5', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        level: 5,
      );
      buddy.evolve();
      expect(buddy.level, equals(5));
    });

    test('tick increases age and hunger', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        age: 0,
      );
      buddy.tick();
      expect(buddy.age, equals(1));
    });

    test('tick decreases health when very hungry', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        hunger: 85,
        health: 100,
      );
      buddy.tick();
      expect(buddy.health, lessThan(100));
    });

    test('isDead returns true when health is 0', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        health: 0,
      );
      expect(buddy.isDead, isTrue);
    });

    test('isHungry returns true when hunger > 70', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        hunger: 75,
      );
      expect(buddy.isHungry, isTrue);
    });

    test('isHappy returns true when happiness > 70', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        happiness: 80,
      );
      expect(buddy.isHappy, isTrue);
    });

    test('applyWorkoutGains creates buff and updates stats', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
        strength: 10,
      );
      final initialStrength = buddy.strength;
      buddy.applyWorkoutGains({StatType.strength: 5});
      expect(buddy.strength, greaterThan(initialStrength));
      expect(buddy.activeBuffs.containsKey(StatType.strength), isTrue);
    });

    test('generateRandom creates valid buddy', () {
      final buddy = WorkoutBuddy.generateRandom();
      expect(buddy.name, isNotEmpty);
      expect(buddy.level, equals(1));
      expect(buddy.sprite, hasLength(16));
      expect(buddy.sprite[0], hasLength(16));
    });

    test('currentStats returns all stat values', () {
      final buddy = WorkoutBuddy(
        name: 'Test',
        sprite: List.generate(16, (_) => List.filled(16, 0)),
      );
      final stats = buddy.currentStats;
      expect(stats.containsKey(StatType.strength), isTrue);
      expect(stats.containsKey(StatType.agility), isTrue);
      expect(stats.containsKey(StatType.endurance), isTrue);
      expect(stats.containsKey(StatType.health), isTrue);
      expect(stats.containsKey(StatType.happiness), isTrue);
    });
  });

  // UserProfile Model Tests
  group('UserProfile', () {
    test('constructor creates profile with values', () {
      final profile = UserProfile(
        name: 'John',
        weightKg: 80,
        heightCm: 180,
        age: 30,
        isMale: true,
      );
      expect(profile.name, equals('John'));
      expect(profile.weightKg, equals(80));
      expect(profile.heightCm, equals(180));
      expect(profile.age, equals(30));
      expect(profile.isMale, isTrue);
    });

    test('getCalorieGoal returns custom goal when set', () {
      final profile = UserProfile(customCalorieGoal: 2500);
      expect(profile.getCalorieGoal(), equals(2500));
    });

    test('getCalorieGoal calculates from profile data', () {
      final profile = UserProfile(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        isMale: true,
      );
      final goal = profile.getCalorieGoal();
      expect(goal, greaterThan(0));
      expect(goal, lessThan(5000));
    });

    test('getCalorieGoal returns default when incomplete', () {
      final profile = UserProfile();
      expect(profile.getCalorieGoal(), equals(2200));
    });

    test('getMacroGoals returns valid macros', () {
      final profile = UserProfile(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        isMale: true,
      );
      final macros = profile.getMacroGoals();
      expect(macros.containsKey('protein'), isTrue);
      expect(macros.containsKey('carbs'), isTrue);
      expect(macros.containsKey('fat'), isTrue);
      expect(macros['protein']!, greaterThan(0));
    });

    test('isComplete returns true when all data present', () {
      final profile = UserProfile(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        isMale: true,
      );
      expect(profile.isComplete, isTrue);
    });

    test('isComplete returns false when data missing', () {
      final profile = UserProfile(weightKg: 80);
      expect(profile.isComplete, isFalse);
    });

    test('toMap and fromMap roundtrip correctly', () {
      final original = UserProfile(
        name: 'John',
        weightKg: 80,
        heightCm: 180,
        age: 30,
        isMale: true,
      );
      final map = original.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored.name, equals('John'));
      expect(restored.weightKg, equals(80.0));
      expect(restored.age, equals(30));
    });

    test('copyWith creates new instance with updated values', () {
      final original = UserProfile(name: 'John', weightKg: 80);
      final updated = original.copyWith(weightKg: 75);
      expect(updated.name, equals('John'));
      expect(updated.weightKg, equals(75));
      expect(original.weightKg, equals(80));
    });
  });

  // FoodDiaryEntry Model Tests
  group('FoodDiaryEntry', () {
    test('constructor creates entry with values', () {
      final entry = FoodDiaryEntry(
        foodName: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25,
        fat: 0.3,
        fiber: 4.4,
        servingSize: '1 medium',
        timestamp: DateTime(2024, 1, 1),
      );
      expect(entry.foodName, equals('Apple'));
      expect(entry.calories, equals(95));
      expect(entry.protein, equals(0.5));
    });

    test('toMap serializes correctly', () {
      final entry = FoodDiaryEntry(
        id: 1,
        foodName: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25,
        fat: 0.3,
        fiber: 4.4,
        servingSize: '1 medium',
        timestamp: DateTime(2024, 1, 1),
      );
      final map = entry.toMap();
      expect(map['id'], equals(1));
      expect(map['food_name'], equals('Apple'));
      expect(map['calories'], equals(95));
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 1,
        'food_name': 'Apple',
        'calories': 95.0,
        'protein': 0.5,
        'carbs': 25.0,
        'fat': 0.3,
        'fiber': 4.4,
        'serving_size': '1 medium',
        'timestamp': '2024-01-01T12:00:00.000',
      };
      final entry = FoodDiaryEntry.fromMap(map);
      expect(entry.id, equals(1));
      expect(entry.foodName, equals('Apple'));
      expect(entry.calories, equals(95.0));
      expect(entry.timestamp.year, equals(2024));
    });

    test('round-trip serialization maintains data', () {
      final original = FoodDiaryEntry(
        id: 1,
        foodName: 'Test Food',
        calories: 200,
        protein: 10,
        carbs: 30,
        fat: 5,
        fiber: 3,
        servingSize: '1 serving',
        timestamp: DateTime.now(),
      );
      final map = original.toMap();
      final restored = FoodDiaryEntry.fromMap(map);
      expect(restored.foodName, equals(original.foodName));
      expect(restored.calories, equals(original.calories));
    });
  });

  // WorkoutType Extension Tests
  group('WorkoutType Extension', () {
    test('all workout types have display names', () {
      for (final type in WorkoutType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('all workout types have descriptions', () {
      for (final type in WorkoutType.values) {
        expect(type.description, isNotEmpty);
      }
    });

    test('primaryStatGain is positive', () {
      for (final type in WorkoutType.values) {
        expect(type.primaryStatGain, greaterThan(0));
      }
    });

    test('isTimeBased is correctly set', () {
      expect(WorkoutType.running.isTimeBased, isTrue);
      expect(WorkoutType.walking.isTimeBased, isTrue);
      expect(WorkoutType.plank.isTimeBased, isTrue);
      expect(WorkoutType.pushUp.isTimeBased, isFalse);
      expect(WorkoutType.squat.isTimeBased, isFalse);
    });

    test('secondaryStatGain is less than or equal to primary', () {
      for (final type in WorkoutType.values) {
        if (type.secondaryStat != null) {
          expect(type.secondaryStatGain, lessThanOrEqualTo(type.primaryStatGain));
        }
      }
    });
  });

  // StatType Extension Tests
  group('StatType Extension', () {
    test('all stat types have display names', () {
      for (final type in StatType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });

    test('all stat types have emojis', () {
      for (final type in StatType.values) {
        expect(type.emoji, isNotEmpty);
      }
    });
  });
}
