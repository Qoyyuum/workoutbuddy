import 'dart:convert';

/// Lightweight data model for syncing to smartwatch
/// Keeps data minimal for fast Bluetooth transfer
class WatchSyncData {
  final double todayCalories;
  final double calorieGoal;
  final Map<String, double> todayMacros;
  final List<WatchMealEntry> recentMeals;
  final WatchBuddyState? buddyState;
  final DateTime lastSync;
  
  WatchSyncData({
    required this.todayCalories,
    required this.calorieGoal,
    required this.todayMacros,
    required this.recentMeals,
    this.buddyState,
    required this.lastSync,
  });

  /// Calculate progress percentage
  double get progressPercentage {
    if (calorieGoal == 0) return 0;
    return (todayCalories / calorieGoal * 100).clamp(0, 100);
  }

  /// Calories remaining
  double get caloriesRemaining {
    return (calorieGoal - todayCalories).clamp(0, double.infinity);
  }

  /// Convert to JSON for watch transfer (optimized for size)
  Map<String, dynamic> toJson() {
    return {
      'cal': todayCalories.toInt(),
      'goal': calorieGoal.toInt(),
      'prot': todayMacros['protein']?.toInt() ?? 0,
      'carb': todayMacros['carbs']?.toInt() ?? 0,
      'fat': todayMacros['fat']?.toInt() ?? 0,
      'meals': recentMeals.map((m) => m.toCompactJson()).toList(),
      'buddy': buddyState?.toCompactJson(),
      'sync': lastSync.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory WatchSyncData.fromJson(Map<String, dynamic> json) {
    return WatchSyncData(
      todayCalories: (json['cal'] as num).toDouble(),
      calorieGoal: (json['goal'] as num).toDouble(),
      todayMacros: {
        'protein': (json['prot'] as num).toDouble(),
        'carbs': (json['carb'] as num).toDouble(),
        'fat': (json['fat'] as num).toDouble(),
      },
      recentMeals: (json['meals'] as List?)
          ?.map((m) => WatchMealEntry.fromCompactJson(m as Map<String, dynamic>))
          .toList() ?? [],
      buddyState: json['buddy'] != null 
          ? WatchBuddyState.fromCompactJson(json['buddy'] as Map<String, dynamic>)
          : null,
      lastSync: DateTime.fromMillisecondsSinceEpoch(json['sync'] as int),
    );
  }

  /// Estimate size in bytes
  int get estimatedSize {
    return jsonEncode(toJson()).length;
  }
}

/// Lightweight meal entry for watch display
class WatchMealEntry {
  final String name;
  final int calories;
  final DateTime timestamp;
  
  WatchMealEntry({
    required this.name,
    required this.calories,
    required this.timestamp,
  });

  /// Compact JSON (shortened keys to reduce size)
  Map<String, dynamic> toCompactJson() {
    return {
      'n': name.length > 20 ? name.substring(0, 20) : name, // Truncate long names
      'c': calories,
      't': timestamp.millisecondsSinceEpoch,
    };
  }

  factory WatchMealEntry.fromCompactJson(Map<String, dynamic> json) {
    return WatchMealEntry(
      name: json['n'] as String,
      calories: json['c'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
    );
  }
}

/// Lightweight buddy state for watch display
class WatchBuddyState {
  final int level;
  final int health;
  final int maxHealth;
  final int hunger;
  final int happiness;
  
  WatchBuddyState({
    required this.level,
    required this.health,
    required this.maxHealth,
    required this.hunger,
    required this.happiness,
  });

  /// Health percentage
  double get healthPercentage => (health / maxHealth * 100).clamp(0, 100);

  /// Compact JSON
  Map<String, dynamic> toCompactJson() {
    return {
      'l': level,
      'h': health,
      'mh': maxHealth,
      'hu': hunger,
      'ha': happiness,
    };
  }

  factory WatchBuddyState.fromCompactJson(Map<String, dynamic> json) {
    return WatchBuddyState(
      level: json['l'] as int,
      health: json['h'] as int,
      maxHealth: json['mh'] as int,
      hunger: json['hu'] as int,
      happiness: json['ha'] as int,
    );
  }
}

/// Message from watch to phone (user action on watch)
class WatchMessage {
  final WatchMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  WatchMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory WatchMessage.fromJson(Map<String, dynamic> json) {
    return WatchMessage(
      type: WatchMessageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => WatchMessageType.unknown,
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  /// Create a quick meal log message from watch
  factory WatchMessage.quickMealLog({
    required String foodName,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) {
    return WatchMessage(
      type: WatchMessageType.quickMeal,
      data: {
        'name': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      },
    );
  }

  /// Create a sync request message from watch
  factory WatchMessage.syncRequest() {
    return WatchMessage(
      type: WatchMessageType.syncRequest,
      data: {},
    );
  }
}

/// Types of messages that can be sent from watch
enum WatchMessageType {
  quickMeal,      // User logged a meal on watch
  syncRequest,    // Watch requesting latest data
  buddyFeed,      // User fed buddy on watch
  buddyTrain,     // User trained buddy on watch
  unknown,
}

/// Watch connectivity status
class WatchConnectivityStatus {
  final bool isSupported;
  final bool isPaired;
  final bool isReachable;
  final DateTime? lastSync;
  final String? error;
  
  WatchConnectivityStatus({
    required this.isSupported,
    required this.isPaired,
    required this.isReachable,
    this.lastSync,
    this.error,
  });

  bool get canSync => isSupported && isPaired && isReachable;

  String get statusMessage {
    if (!isSupported) return 'Watch not supported on this device';
    if (!isPaired) return 'No watch paired';
    if (!isReachable) return 'Watch not connected';
    return 'Watch connected';
  }

  WatchConnectivityStatus copyWith({
    bool? isSupported,
    bool? isPaired,
    bool? isReachable,
    DateTime? lastSync,
    String? error,
  }) {
    return WatchConnectivityStatus(
      isSupported: isSupported ?? this.isSupported,
      isPaired: isPaired ?? this.isPaired,
      isReachable: isReachable ?? this.isReachable,
      lastSync: lastSync ?? this.lastSync,
      error: error ?? this.error,
    );
  }
}
