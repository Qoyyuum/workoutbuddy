import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/workout_type.dart';
import '../models/workout_session.dart';

class WorkoutDetectionService {
  static final WorkoutDetectionService _instance = WorkoutDetectionService._internal();
  factory WorkoutDetectionService() => _instance;
  WorkoutDetectionService._internal();

  StreamController<WorkoutSession>? _workoutController;
  Timer? _workoutTimer;
  WorkoutType? _currentWorkoutType;
  DateTime? _workoutStartTime;
  int _currentReps = 0;

  Stream<WorkoutSession> get workoutStream => _workoutController?.stream ?? const Stream.empty();

  /// Start detecting a specific workout type
  Future<void> startWorkoutDetection(WorkoutType workoutType) async {
    _currentWorkoutType = workoutType;
    _workoutStartTime = DateTime.now();
    _currentReps = 0;
    
    _workoutController ??= StreamController<WorkoutSession>.broadcast();
    
    if (kDebugMode) {
      print('🏋️ Started detecting ${workoutType.displayName}');
    }

    // For now, we'll use platform-specific detection methods
    if (Platform.isAndroid) {
      await _startAndroidDetection(workoutType);
    } else if (Platform.isIOS) {
      await _startIOSDetection(workoutType);
    } else {
      // Web/Desktop - manual input mode
      await _startManualDetection(workoutType);
    }
  }

  /// Stop current workout detection and return session
  WorkoutSession? stopWorkoutDetection() {
    if (_currentWorkoutType == null || _workoutStartTime == null) {
      return null;
    }

    final duration = DateTime.now().difference(_workoutStartTime!);
    final session = WorkoutSession.create(
      type: _currentWorkoutType!,
      reps: _currentReps,
      duration: duration,
    );

    _workoutTimer?.cancel();
    _currentWorkoutType = null;
    _workoutStartTime = null;
    _currentReps = 0;

    if (kDebugMode) {
      print('🏁 Workout session completed: ${session.type.displayName} - ${session.reps} reps in ${session.duration.inMinutes}m');
    }

    return session;
  }

  /// Android-specific workout detection using Health Connect
  Future<void> _startAndroidDetection(WorkoutType workoutType) async {
    // TODO: Implement Health Connect integration
    // For now, simulate detection with timer
    _simulateWorkoutDetection(workoutType);
  }

  /// iOS-specific workout detection using HealthKit
  Future<void> _startIOSDetection(WorkoutType workoutType) async {
    // TODO: Implement HealthKit integration
    // For now, simulate detection with timer
    _simulateWorkoutDetection(workoutType);
  }

  /// Manual detection for web/desktop platforms
  Future<void> _startManualDetection(WorkoutType workoutType) async {
    // For manual mode, we'll provide a UI for users to log reps
    _simulateWorkoutDetection(workoutType);
  }

  /// Simulate workout detection for development/testing
  void _simulateWorkoutDetection(WorkoutType workoutType) {
    // Simulate rep detection every 2-5 seconds for rep-based exercises
    if (_isRepBasedExercise(workoutType)) {
      _workoutTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _currentReps++;
        if (kDebugMode) {
          print('🔄 Detected rep #$_currentReps for ${workoutType.displayName}');
        }
      });
    } else {
      // For time-based exercises, just track duration
      _workoutTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (kDebugMode) {
          final elapsed = DateTime.now().difference(_workoutStartTime!);
          print('⏱️ ${workoutType.displayName} duration: ${elapsed.inSeconds}s');
        }
      });
    }
  }

  /// Manually add a rep (for manual input mode)
  void addRep() {
    if (_currentWorkoutType != null) {
      _currentReps++;
      if (kDebugMode) {
        print('➕ Manual rep added: $_currentReps');
      }
    }
  }

  /// Check if exercise is rep-based or time-based
  bool _isRepBasedExercise(WorkoutType workoutType) {
    switch (workoutType) {
      case WorkoutType.pushUp:
      case WorkoutType.sitUp:
      case WorkoutType.squat:
      case WorkoutType.jumping:
      case WorkoutType.burpee:
      case WorkoutType.pullUp:
      case WorkoutType.lunges:
        return true;
      case WorkoutType.running:
      case WorkoutType.walking:
      case WorkoutType.plank:
        return false;
    }
  }

  /// Get current workout status
  Map<String, dynamic> get currentStatus {
    if (_currentWorkoutType == null) {
      return {'isActive': false};
    }

    final duration = _workoutStartTime != null 
        ? DateTime.now().difference(_workoutStartTime!)
        : Duration.zero;

    return {
      'isActive': true,
      'workoutType': _currentWorkoutType!.displayName,
      'reps': _currentReps,
      'duration': duration.inSeconds,
      'isRepBased': _isRepBasedExercise(_currentWorkoutType!),
    };
  }

  void dispose() {
    _workoutTimer?.cancel();
    _workoutController?.close();
  }
}
