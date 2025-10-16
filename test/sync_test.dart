import 'package:flutter_test/flutter_test.dart';
import 'package:workoutbuddy/models/backup_data.dart';
import 'package:workoutbuddy/models/food_diary_entry.dart';

void main() {
  group('BackupData', () {
    test('creates backup with all required fields', () {
      final entries = [
        FoodDiaryEntry(
          foodName: 'Apple',
          calories: 95,
          protein: 0.5,
          carbs: 25,
          fat: 0.3,
          fiber: 4.4,
          servingSize: '1 medium',
          timestamp: DateTime(2024, 1, 1),
        ),
      ];
      
      final backup = BackupData(
        version: 1,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        foodDiaryEntries: entries,
        userSettings: {'test_key': 'test_value'},
      );

      expect(backup.version, equals(1));
      expect(backup.foodDiaryEntries, hasLength(1));
      expect(backup.userSettings, containsPair('test_key', 'test_value'));
    });

    test('serializes to JSON correctly', () {
      final backup = BackupData(
        version: 1,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        foodDiaryEntries: [],
        userSettings: {'key': 'value'},
      );

      final json = backup.toJson();
      
      expect(json['version'], equals(1));
      expect(json['created_at'], isA<String>());
      expect(json['food_diary_entries'], isA<List>());
      expect(json['user_settings'], isA<Map>());
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'version': 1,
        'created_at': '2024-01-01T12:00:00.000',
        'food_diary_entries': [],
        'user_settings': {'key': 'value'},
        'workout_buddy_data': null,
      };

      final backup = BackupData.fromJson(json);
      
      expect(backup.version, equals(1));
      expect(backup.createdAt, equals(DateTime(2024, 1, 1, 12, 0)));
      expect(backup.userSettings['key'], equals('value'));
    });

    test('round-trip JSON serialization maintains data', () {
      final original = BackupData(
        version: 1,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        foodDiaryEntries: [
          FoodDiaryEntry(
            foodName: 'Apple',
            calories: 95,
            protein: 0.5,
            carbs: 25,
            fat: 0.3,
            fiber: 4.4,
            servingSize: '1 medium',
            timestamp: DateTime(2024, 1, 1),
          ),
        ],
        userSettings: {'test': 'data'},
        workoutBuddyData: '{"name":"Buddy"}',
      );

      final jsonString = original.toJsonString();
      final restored = BackupData.fromJsonString(jsonString);

      expect(restored.version, equals(original.version));
      expect(restored.foodDiaryEntries.length, equals(original.foodDiaryEntries.length));
      expect(restored.userSettings, equals(original.userSettings));
      expect(restored.workoutBuddyData, equals(original.workoutBuddyData));
    });

    test('estimatedSize returns reasonable value', () {
      final backup = BackupData(
        version: 1,
        createdAt: DateTime.now(),
        foodDiaryEntries: [],
        userSettings: {},
      );

      expect(backup.estimatedSize, greaterThan(0));
      expect(backup.estimatedSize, lessThan(10000)); // Empty backup should be small
    });

    test('readableSize formats correctly', () {
      final backup = BackupData(
        version: 1,
        createdAt: DateTime.now(),
        foodDiaryEntries: [],
        userSettings: {},
      );

      final size = backup.readableSize;
      expect(size, contains(RegExp(r'\d+\.?\d*\s+(B|KB|MB)')));
    });

    test('handles large backup with multiple entries', () {
      final entries = List.generate(
        100,
        (i) => FoodDiaryEntry(
          foodName: 'Food $i',
          calories: (100 + i).toDouble(),
          protein: 10,
          carbs: 20,
          fat: 5,
          fiber: 3,
          servingSize: '1 serving',
          timestamp: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      final backup = BackupData(
        version: 1,
        createdAt: DateTime.now(),
        foodDiaryEntries: entries,
        userSettings: {'key1': 'value1', 'key2': 'value2'},
      );

      expect(backup.foodDiaryEntries, hasLength(100));
      expect(backup.estimatedSize, greaterThan(1000));
      
      // Test serialization doesn't fail
      final jsonString = backup.toJsonString();
      expect(jsonString, isNotEmpty);
      
      // Test deserialization
      final restored = BackupData.fromJsonString(jsonString);
      expect(restored.foodDiaryEntries, hasLength(100));
    });
  });

  group('SyncStatus', () {
    test('creates status with required fields', () {
      final status = SyncStatus(isConnected: true);
      
      expect(status.isConnected, isTrue);
      expect(status.lastSyncTime, isNull);
      expect(status.isSyncing, isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = SyncStatus(
        isConnected: true,
        lastSyncTime: DateTime(2024, 1, 1),
        isSyncing: false,
      );

      final updated = original.copyWith(
        isSyncing: true,
        lastSyncError: 'Test error',
      );

      expect(updated.isConnected, equals(original.isConnected));
      expect(updated.lastSyncTime, equals(original.lastSyncTime));
      expect(updated.isSyncing, isTrue);
      expect(updated.lastSyncError, equals('Test error'));
    });

    test('copyWith without parameters returns same values', () {
      final original = SyncStatus(
        isConnected: true,
        lastSyncTime: DateTime(2024, 1, 1),
        userEmail: 'test@example.com',
      );

      final copy = original.copyWith();

      expect(copy.isConnected, equals(original.isConnected));
      expect(copy.lastSyncTime, equals(original.lastSyncTime));
      expect(copy.userEmail, equals(original.userEmail));
    });
  });

  group('SyncConflictResolution', () {
    test('enum has all expected values', () {
      expect(SyncConflictResolution.values, hasLength(3));
      expect(SyncConflictResolution.values, contains(SyncConflictResolution.useLocal));
      expect(SyncConflictResolution.values, contains(SyncConflictResolution.useRemote));
      expect(SyncConflictResolution.values, contains(SyncConflictResolution.merge));
    });
  });

  group('BackupInfo', () {
    test('creates backup info with correct values', () {
      final info = BackupInfo(
        fileName: 'backup.json',
        size: 1024,
        modifiedTime: DateTime(2024, 1, 1),
      );

      expect(info.fileName, equals('backup.json'));
      expect(info.size, equals(1024));
      expect(info.modifiedTime, equals(DateTime(2024, 1, 1)));
    });

    test('readableSize formats bytes correctly', () {
      final small = BackupInfo(
        fileName: 'test',
        size: 500,
        modifiedTime: DateTime.now(),
      );
      expect(small.readableSize, equals('500 B'));

      final kb = BackupInfo(
        fileName: 'test',
        size: 2048,
        modifiedTime: DateTime.now(),
      );
      expect(kb.readableSize, equals('2.0 KB'));

      final mb = BackupInfo(
        fileName: 'test',
        size: 1024 * 1024 * 2,
        modifiedTime: DateTime.now(),
      );
      expect(mb.readableSize, equals('2.0 MB'));
    });
  });

  group('Integration Tests', () {
    test('complete backup and restore cycle preserves data', () {
      // Create original backup
      final originalEntries = [
        FoodDiaryEntry(
          foodName: 'Breakfast',
          calories: 400,
          protein: 20,
          carbs: 50,
          fat: 10,
          fiber: 5,
          servingSize: '1 meal',
          timestamp: DateTime(2024, 1, 1, 8, 0),
        ),
        FoodDiaryEntry(
          foodName: 'Lunch',
          calories: 600,
          protein: 30,
          carbs: 70,
          fat: 15,
          fiber: 8,
          servingSize: '1 meal',
          timestamp: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      final originalBackup = BackupData(
        version: 1,
        createdAt: DateTime.now(),
        foodDiaryEntries: originalEntries,
        userSettings: {
          'calorie_goal': '2000',
          'user_name': 'Test User',
        },
        workoutBuddyData: '{"level":5,"health":100}',
      );

      // Simulate backup to cloud
      final jsonString = originalBackup.toJsonString();
      expect(jsonString, isNotEmpty);

      // Simulate restore from cloud
      final restoredBackup = BackupData.fromJsonString(jsonString);

      // Verify all data is preserved
      expect(restoredBackup.version, equals(originalBackup.version));
      expect(restoredBackup.foodDiaryEntries.length, equals(2));
      expect(restoredBackup.foodDiaryEntries[0].foodName, equals('Breakfast'));
      expect(restoredBackup.foodDiaryEntries[1].foodName, equals('Lunch'));
      expect(restoredBackup.userSettings['calorie_goal'], equals('2000'));
      expect(restoredBackup.workoutBuddyData, contains('level'));
    });

    test('backup with empty data serializes correctly', () {
      final emptyBackup = BackupData(
        version: 1,
        createdAt: DateTime.now(),
        foodDiaryEntries: [],
        userSettings: {},
      );

      final jsonString = emptyBackup.toJsonString();
      final restored = BackupData.fromJsonString(jsonString);

      expect(restored.foodDiaryEntries, isEmpty);
      expect(restored.userSettings, isEmpty);
      expect(restored.workoutBuddyData, isNull);
    });
  });
}
