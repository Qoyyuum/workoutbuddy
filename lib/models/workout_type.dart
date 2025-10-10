enum WorkoutType {
  pushUp,
  sitUp,
  squat,
  running,
  walking,
  jumping,
  plank,
  burpee,
  pullUp,
  lunges,
}

extension WorkoutTypeExtension on WorkoutType {
  String get displayName {
    switch (this) {
      case WorkoutType.pushUp:
        return 'Push-ups';
      case WorkoutType.sitUp:
        return 'Sit-ups';
      case WorkoutType.squat:
        return 'Squats';
      case WorkoutType.running:
        return 'Running';
      case WorkoutType.walking:
        return 'Walking';
      case WorkoutType.jumping:
        return 'Jumping Jacks';
      case WorkoutType.plank:
        return 'Plank';
      case WorkoutType.burpee:
        return 'Burpees';
      case WorkoutType.pullUp:
        return 'Pull-ups';
      case WorkoutType.lunges:
        return 'Lunges';
    }
  }

  String get description {
    switch (this) {
      case WorkoutType.pushUp:
        return 'Upper body strength exercise';
      case WorkoutType.sitUp:
        return 'Core strengthening exercise';
      case WorkoutType.squat:
        return 'Lower body strength exercise';
      case WorkoutType.running:
        return 'Cardio endurance exercise';
      case WorkoutType.walking:
        return 'Light cardio exercise';
      case WorkoutType.jumping:
        return 'Full body cardio exercise';
      case WorkoutType.plank:
        return 'Core stability exercise';
      case WorkoutType.burpee:
        return 'Full body conditioning';
      case WorkoutType.pullUp:
        return 'Upper body pulling exercise';
      case WorkoutType.lunges:
        return 'Lower body strength exercise';
    }
  }

  /// Primary stat that this workout affects
  StatType get primaryStat {
    switch (this) {
      case WorkoutType.pushUp:
      case WorkoutType.pullUp:
        return StatType.strength;
      case WorkoutType.running:
      case WorkoutType.jumping:
        return StatType.agility;
      case WorkoutType.walking:
      case WorkoutType.plank:
        return StatType.endurance;
      case WorkoutType.sitUp:
        return StatType.strength;
      case WorkoutType.squat:
      case WorkoutType.lunges:
        return StatType.strength;
      case WorkoutType.burpee:
        return StatType.endurance;
    }
  }

  /// Secondary stat that gets a smaller boost
  StatType? get secondaryStat {
    switch (this) {
      case WorkoutType.pushUp:
        return StatType.endurance;
      case WorkoutType.running:
        return StatType.endurance;
      case WorkoutType.jumping:
        return StatType.strength;
      case WorkoutType.burpee:
        return StatType.agility;
      case WorkoutType.squat:
        return StatType.agility;
      case WorkoutType.lunges:
        return StatType.agility;
      default:
        return null;
    }
  }

  /// Points gained per rep/minute for primary stat
  int get primaryStatGain {
    switch (this) {
      case WorkoutType.pushUp:
      case WorkoutType.pullUp:
      case WorkoutType.sitUp:
      case WorkoutType.squat:
      case WorkoutType.lunges:
        return 1; // 1 point per rep
      case WorkoutType.running:
      case WorkoutType.walking:
      case WorkoutType.plank:
        return 1; // 1 point per minute
      case WorkoutType.jumping:
      case WorkoutType.burpee:
        return 2; // 2 points per rep (more intense)
    }
  }

  /// Points gained per rep/minute for secondary stat
  int get secondaryStatGain => (primaryStatGain * 0.5).round();
}

enum StatType {
  strength,
  agility,
  endurance,
  health,
  happiness,
}

extension StatTypeExtension on StatType {
  String get displayName {
    switch (this) {
      case StatType.strength:
        return 'Strength';
      case StatType.agility:
        return 'Agility';
      case StatType.endurance:
        return 'Endurance';
      case StatType.health:
        return 'Health';
      case StatType.happiness:
        return 'Happiness';
    }
  }

  String get emoji {
    switch (this) {
      case StatType.strength:
        return '💪';
      case StatType.agility:
        return '⚡';
      case StatType.endurance:
        return '🏃';
      case StatType.health:
        return '❤️';
      case StatType.happiness:
        return '😊';
    }
  }
}

class StatBuff {
  final int amount;
  final DateTime createdAt;
  final Duration duration;

  StatBuff({
    required this.amount,
    required this.createdAt,
    required this.duration,
  });

  bool get isExpired => DateTime.now().isAfter(createdAt.add(duration));
  
  double get decayFactor {
    final elapsed = DateTime.now().difference(createdAt);
    final progress = elapsed.inMilliseconds / duration.inMilliseconds;
    return (1.0 - progress).clamp(0.0, 1.0);
  }
  
  int get currentAmount => (amount * decayFactor).round();
}
