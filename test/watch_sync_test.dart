import 'package:flutter_test/flutter_test.dart';
import 'package:workoutbuddy/models/watch_data.dart';

void main() {
  group('WatchSyncData', () {
    test('creates sync data with all required fields', () {
      final syncData = WatchSyncData(
        todayCalories: 1500.0,
        calorieGoal: 2000.0,
        todayMacros: {'protein': 100, 'carbs': 150, 'fat': 50},
        recentMeals: [],
        lastSync: DateTime(2024, 1, 1, 12, 0),
      );

      expect(syncData.todayCalories, equals(1500.0));
      expect(syncData.calorieGoal, equals(2000.0));
      expect(syncData.todayMacros['protein'], equals(100));
    });

    test('calculates progress percentage correctly', () {
      final syncData = WatchSyncData(
        todayCalories: 1000.0,
        calorieGoal: 2000.0,
        todayMacros: {},
        recentMeals: [],
        lastSync: DateTime.now(),
      );

      expect(syncData.progressPercentage, equals(50.0));
    });

    test('calculates calories remaining correctly', () {
      final syncData = WatchSyncData(
        todayCalories: 1500.0,
        calorieGoal: 2000.0,
        todayMacros: {},
        recentMeals: [],
        lastSync: DateTime.now(),
      );

      expect(syncData.caloriesRemaining, equals(500.0));
    });

    test('handles over-goal calories correctly', () {
      final syncData = WatchSyncData(
        todayCalories: 2500.0,
        calorieGoal: 2000.0,
        todayMacros: {},
        recentMeals: [],
        lastSync: DateTime.now(),
      );

      expect(syncData.progressPercentage, equals(100.0)); // Clamped
      expect(syncData.caloriesRemaining, equals(0.0)); // Clamped to 0
    });

    test('serializes to compact JSON correctly', () {
      final syncData = WatchSyncData(
        todayCalories: 1500.0,
        calorieGoal: 2000.0,
        todayMacros: {'protein': 100, 'carbs': 150, 'fat': 50},
        recentMeals: [],
        lastSync: DateTime(2024, 1, 1, 12, 0),
      );

      final json = syncData.toJson();

      expect(json['cal'], equals(1500));
      expect(json['goal'], equals(2000));
      expect(json['prot'], equals(100));
      expect(json['carb'], equals(150));
      expect(json['fat'], equals(50));
      expect(json['sync'], isA<int>());
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'cal': 1500,
        'goal': 2000,
        'prot': 100,
        'carb': 150,
        'fat': 50,
        'meals': [],
        'buddy': null,
        'sync': DateTime(2024, 1, 1, 12, 0).millisecondsSinceEpoch,
      };

      final syncData = WatchSyncData.fromJson(json);

      expect(syncData.todayCalories, equals(1500.0));
      expect(syncData.calorieGoal, equals(2000.0));
      expect(syncData.todayMacros['protein'], equals(100.0));
    });

    test('round-trip JSON serialization maintains data', () {
      final original = WatchSyncData(
        todayCalories: 1800.0,
        calorieGoal: 2200.0,
        todayMacros: {'protein': 120, 'carbs': 180, 'fat': 60},
        recentMeals: [],
        lastSync: DateTime.now(),
      );

      final json = original.toJson();
      final restored = WatchSyncData.fromJson(json);

      expect(restored.todayCalories, equals(original.todayCalories));
      expect(restored.calorieGoal, equals(original.calorieGoal));
      expect(restored.todayMacros['protein'], equals(original.todayMacros['protein']));
    });

    test('estimated size is reasonable', () {
      final syncData = WatchSyncData(
        todayCalories: 1500.0,
        calorieGoal: 2000.0,
        todayMacros: {'protein': 100, 'carbs': 150, 'fat': 50},
        recentMeals: [],
        lastSync: DateTime.now(),
      );

      expect(syncData.estimatedSize, greaterThan(0));
      expect(syncData.estimatedSize, lessThan(1000)); // Should be very small
    });
  });

  group('WatchMealEntry', () {
    test('creates meal entry with correct values', () {
      final meal = WatchMealEntry(
        name: 'Apple',
        calories: 95,
        timestamp: DateTime(2024, 1, 1, 12, 0),
      );

      expect(meal.name, equals('Apple'));
      expect(meal.calories, equals(95));
      expect(meal.timestamp, equals(DateTime(2024, 1, 1, 12, 0)));
    });

    test('truncates long names to 20 characters', () {
      final meal = WatchMealEntry(
        name: 'This is a very long food name that exceeds twenty characters',
        calories: 200,
        timestamp: DateTime.now(),
      );

      final json = meal.toCompactJson();
      final name = json['n'] as String;

      expect(name.length, lessThanOrEqualTo(20));
    });

    test('compact JSON uses shortened keys', () {
      final meal = WatchMealEntry(
        name: 'Chicken',
        calories: 165,
        timestamp: DateTime(2024, 1, 1, 12, 0),
      );

      final json = meal.toCompactJson();

      expect(json.containsKey('n'), isTrue);
      expect(json.containsKey('c'), isTrue);
      expect(json.containsKey('t'), isTrue);
    });

    test('round-trip serialization maintains data', () {
      final original = WatchMealEntry(
        name: 'Salmon',
        calories: 250,
        timestamp: DateTime(2024, 1, 1, 12, 0),
      );

      final json = original.toCompactJson();
      final restored = WatchMealEntry.fromCompactJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.calories, equals(original.calories));
      expect(restored.timestamp, equals(original.timestamp));
    });
  });

  group('WatchBuddyState', () {
    test('creates buddy state with correct values', () {
      final state = WatchBuddyState(
        level: 3,
        health: 80,
        maxHealth: 100,
        hunger: 40,
        happiness: 75,
      );

      expect(state.level, equals(3));
      expect(state.health, equals(80));
      expect(state.maxHealth, equals(100));
    });

    test('calculates health percentage correctly', () {
      final state = WatchBuddyState(
        level: 1,
        health: 75,
        maxHealth: 100,
        hunger: 50,
        happiness: 60,
      );

      expect(state.healthPercentage, equals(75.0));
    });

    test('compact JSON uses shortened keys', () {
      final state = WatchBuddyState(
        level: 2,
        health: 90,
        maxHealth: 100,
        hunger: 30,
        happiness: 80,
      );

      final json = state.toCompactJson();

      expect(json.containsKey('l'), isTrue);
      expect(json.containsKey('h'), isTrue);
      expect(json.containsKey('mh'), isTrue);
    });

    test('round-trip serialization maintains data', () {
      final original = WatchBuddyState(
        level: 4,
        health: 95,
        maxHealth: 120,
        hunger: 25,
        happiness: 85,
      );

      final json = original.toCompactJson();
      final restored = WatchBuddyState.fromCompactJson(json);

      expect(restored.level, equals(original.level));
      expect(restored.health, equals(original.health));
      expect(restored.maxHealth, equals(original.maxHealth));
    });
  });

  group('WatchMessage', () {
    test('creates quick meal log message', () {
      final message = WatchMessage.quickMealLog(
        foodName: 'Banana',
        calories: 105,
        protein: 1,
        carbs: 27,
        fat: 0.3,
      );

      expect(message.type, equals(WatchMessageType.quickMeal));
      expect(message.data['name'], equals('Banana'));
      expect(message.data['calories'], equals(105));
    });

    test('creates sync request message', () {
      final message = WatchMessage.syncRequest();

      expect(message.type, equals(WatchMessageType.syncRequest));
      expect(message.data, isEmpty);
    });

    test('serializes to JSON correctly', () {
      final message = WatchMessage.quickMealLog(
        foodName: 'Apple',
        calories: 95,
      );

      final json = message.toJson();

      expect(json['type'], equals('quickMeal'));
      expect(json['data'], isA<Map<String, dynamic>>());
      expect(json['timestamp'], isA<int>());
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'type': 'quickMeal',
        'data': {
          'name': 'Orange',
          'calories': 62.0,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final message = WatchMessage.fromJson(json);

      expect(message.type, equals(WatchMessageType.quickMeal));
      expect(message.data['name'], equals('Orange'));
    });
  });

  group('WatchConnectivityStatus', () {
    test('creates status with correct values', () {
      final status = WatchConnectivityStatus(
        isSupported: true,
        isPaired: true,
        isReachable: true,
      );

      expect(status.isSupported, isTrue);
      expect(status.isPaired, isTrue);
      expect(status.isReachable, isTrue);
    });

    test('canSync is true when all conditions met', () {
      final status = WatchConnectivityStatus(
        isSupported: true,
        isPaired: true,
        isReachable: true,
      );

      expect(status.canSync, isTrue);
    });

    test('canSync is false when not reachable', () {
      final status = WatchConnectivityStatus(
        isSupported: true,
        isPaired: true,
        isReachable: false,
      );

      expect(status.canSync, isFalse);
    });

    test('statusMessage reflects current state', () {
      final connected = WatchConnectivityStatus(
        isSupported: true,
        isPaired: true,
        isReachable: true,
      );
      expect(connected.statusMessage, equals('Watch connected'));

      final notSupported = WatchConnectivityStatus(
        isSupported: false,
        isPaired: false,
        isReachable: false,
      );
      expect(notSupported.statusMessage, equals('Watch not supported on this device'));
    });

    test('copyWith creates new instance with updated values', () {
      final original = WatchConnectivityStatus(
        isSupported: true,
        isPaired: true,
        isReachable: false,
      );

      final updated = original.copyWith(isReachable: true);

      expect(updated.isSupported, equals(original.isSupported));
      expect(updated.isPaired, equals(original.isPaired));
      expect(updated.isReachable, isTrue);
    });
  });

  group('Integration Tests', () {
    test('complete sync data package is compact', () {
      final meals = List.generate(
        5,
        (i) => WatchMealEntry(
          name: 'Meal $i',
          calories: 200 + i * 50,
          timestamp: DateTime.now().subtract(Duration(hours: i)),
        ),
      );

      final buddyState = WatchBuddyState(
        level: 3,
        health: 85,
        maxHealth: 100,
        hunger: 35,
        happiness: 78,
      );

      final syncData = WatchSyncData(
        todayCalories: 1650.0,
        calorieGoal: 2000.0,
        todayMacros: {'protein': 110, 'carbs': 170, 'fat': 55},
        recentMeals: meals,
        buddyState: buddyState,
        lastSync: DateTime.now(),
      );

      // Verify the complete package is still small
      expect(syncData.estimatedSize, lessThan(5000)); // < 5KB
    });

    test('watch message types are handled correctly', () {
      final types = [
        WatchMessageType.quickMeal,
        WatchMessageType.syncRequest,
        WatchMessageType.buddyFeed,
        WatchMessageType.buddyTrain,
        WatchMessageType.unknown,
      ];

      for (final type in types) {
        expect(type.name, isNotEmpty);
      }
    });
  });
}
