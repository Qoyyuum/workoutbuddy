import 'workout_type.dart';

class WorkoutSession {
  final String id;
  final WorkoutType type;
  final int reps;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final Map<StatType, int> statGains;

  WorkoutSession({
    required this.id,
    required this.type,
    required this.reps,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.statGains,
  });

  factory WorkoutSession.create({
    required WorkoutType type,
    required int reps,
    required Duration duration,
  }) {
    final now = DateTime.now();
    final statGains = <StatType, int>{};
    
    // Calculate stat gains based on workout type
    if (type.isTimeBased) {
      // Time-based exercises (running, walking, plank)
      final minutes = duration.inSeconds / 60.0;
      statGains[type.primaryStat] = (minutes * type.primaryStatGain).round();
      if (type.secondaryStat != null) {
        statGains[type.secondaryStat!] = (minutes * type.secondaryStatGain).round();
      }
    } else {
      // Rep-based exercises (burpees, push-ups, etc.)
      statGains[type.primaryStat] = reps * type.primaryStatGain;
      if (type.secondaryStat != null) {
        statGains[type.secondaryStat!] = reps * type.secondaryStatGain;
      }
    }

    return WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      reps: reps,
      duration: duration,
      startTime: now.subtract(duration),
      endTime: now,
      statGains: statGains,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'reps': reps,
      'duration': duration.inSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'statGains': statGains.map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      type: WorkoutType.values.firstWhere((e) => e.name == json['type']),
      reps: json['reps'],
      duration: Duration(seconds: json['duration']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      statGains: (json['statGains'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          StatType.values.firstWhere((e) => e.name == key),
          value as int,
        ),
      ),
    );
  }
}
