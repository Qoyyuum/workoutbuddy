import 'dart:convert';
import 'food_diary_entry.dart';

/// Model representing a complete backup of all user data
class BackupData {
  final int version;
  final DateTime createdAt;
  final List<FoodDiaryEntry> foodDiaryEntries;
  final Map<String, String> userSettings;
  final String? workoutBuddyData; // JSON string of buddy data
  
  BackupData({
    required this.version,
    required this.createdAt,
    required this.foodDiaryEntries,
    required this.userSettings,
    this.workoutBuddyData,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'food_diary_entries': foodDiaryEntries.map((e) => e.toMap()).toList(),
      'user_settings': userSettings,
      'workout_buddy_data': workoutBuddyData,
    };
  }

  /// Create from JSON
  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      foodDiaryEntries: (json['food_diary_entries'] as List)
          .map((e) => FoodDiaryEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      userSettings: Map<String, String>.from(json['user_settings'] as Map),
      workoutBuddyData: json['workout_buddy_data'] as String?,
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory BackupData.fromJsonString(String jsonString) {
    return BackupData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Get backup file size estimate in bytes
  int get estimatedSize {
    return toJsonString().length;
  }

  /// Get human-readable size
  String get readableSize {
    final bytes = estimatedSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Model representing sync status
class SyncStatus {
  final bool isConnected;
  final DateTime? lastSyncTime;
  final String? lastSyncError;
  final bool isSyncing;
  final String? userEmail;
  
  SyncStatus({
    required this.isConnected,
    this.lastSyncTime,
    this.lastSyncError,
    this.isSyncing = false,
    this.userEmail,
  });

  SyncStatus copyWith({
    bool? isConnected,
    DateTime? lastSyncTime,
    String? lastSyncError,
    bool? isSyncing,
    String? userEmail,
  }) {
    return SyncStatus(
      isConnected: isConnected ?? this.isConnected,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      isSyncing: isSyncing ?? this.isSyncing,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

/// Sync conflict resolution strategies
enum SyncConflictResolution {
  useLocal,  // Keep local data
  useRemote, // Use cloud data
  merge,     // Merge both (newest wins per entry)
}

/// Info about a backup file
class BackupInfo {
  final String fileName;
  final int size;
  final DateTime modifiedTime;
  
  BackupInfo({
    required this.fileName,
    required this.size,
    required this.modifiedTime,
  });

  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
