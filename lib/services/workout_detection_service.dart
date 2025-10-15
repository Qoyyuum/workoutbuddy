import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
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
  bool _isHealthConnectInitialized = false;
  bool _isPolling = false;

  Stream<WorkoutSession> get workoutStream => _workoutController?.stream ?? const Stream.empty();

  /// Start detecting a specific workout type
  Future<void> startWorkoutDetection(WorkoutType workoutType) async {
    _currentWorkoutType = workoutType;
    _workoutStartTime = DateTime.now();
    _currentReps = 0;
    _isPolling = false;
    
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
    _isPolling = false;


    if (kDebugMode) {
      print('🏁 Workout session completed: ${session.type.displayName} - ${session.reps} reps in ${session.duration.inMinutes}m');
    }

    return session;
  }

  /// Android-specific workout detection using Health Connect
  Future<void> _startAndroidDetection(WorkoutType workoutType) async {
    try {
      // Initialize Health Connect if not already done
      if (!_isHealthConnectInitialized) {
        final isAvailable = await HealthConnectFactory.isAvailable();
        if (!isAvailable) {
          if (kDebugMode) {
            print('⚠️ Health Connect not available, falling back to simulation');
          }
          _simulateWorkoutDetection(workoutType);
          return;
        }
        _isHealthConnectInitialized = true;
      }

      // Request permissions for workout data types
      final dataTypes = _getHealthConnectDataTypes(workoutType);
      final permissionsGranted = await HealthConnectFactory.requestPermissions(
        dataTypes,
        readOnly: true,
      );
      
      if (!permissionsGranted) {
        if (kDebugMode) {
          print('⚠️ Health Connect permissions denied, falling back to simulation');
        }
        _simulateWorkoutDetection(workoutType);
        return;
      }

      if (kDebugMode) {
        print('✅ Health Connect initialized and permissions granted');
      }

      // Start monitoring for exercise data
      await _monitorHealthConnectData(workoutType, dataTypes);
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing Health Connect: $e');
        print('Falling back to simulation mode');
      }
      _simulateWorkoutDetection(workoutType);
    }
  }

  /// Monitor Health Connect for workout data updates
  Future<void> _monitorHealthConnectData(
    WorkoutType workoutType,
    List<HealthConnectDataType> dataTypes,
  ) async {
    // Poll for new exercise data periodically
      // Reentrancy guard: prevent overlapping polls
      if (_isPolling) return;
      
      _isPolling = true;
    _workoutTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final endTime = DateTime.now();
        final startTime = _workoutStartTime ?? endTime.subtract(const Duration(seconds: 30));

        // Process the records based on workout type
        if (_isRepBasedExercise(workoutType)) {
          // For rep-based exercises, check for steps as a proxy
          try {
            final stepsData = await HealthConnectFactory.getRecord(
              type: HealthConnectDataType.Steps,
              startTime: startTime,
              endTime: endTime,
            );
            
            final records = stepsData['data'] as List?;
            if (records != null && records.isNotEmpty) {
              // Sum up steps from the workout period as a proxy for reps
              int totalSteps = 0;
              for (var record in records) {
                totalSteps += (record['count'] as num?)?.toInt() ?? 0;
              }
              // Scale down steps to reasonable rep count (rough estimate)
              _emitCurrentState();
              _currentReps = (totalSteps / 10).round();
              
              if (kDebugMode) {
                print('🔄 Health Connect detected $_currentReps reps for ${workoutType.displayName}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not read steps data: $e');
            }
          }
        } else {
          // For time-based exercises, track duration via heart rate or exercise session
          try {
            final sessionData = await HealthConnectFactory.getRecord(
              type: HealthConnectDataType.ExerciseSession,
              startTime: startTime,
              endTime: endTime,
            );
            
            final sessions = sessionData['data'] as List?;
              _emitCurrentState();
            if (sessions != null && sessions.isNotEmpty) {
              final duration = DateTime.now().difference(_workoutStartTime!);
              if (kDebugMode) {
                print('⏱️ Health Connect tracking ${workoutType.displayName}: ${duration.inSeconds}s');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not read exercise session data: $e');
            }
          }
        
        // Emit final state update at end of polling cycle
        _emitCurrentState();
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error reading Health Connect data: $e');
      } finally {
        _isPolling = false;
        }
      }
    });
  }

  /// Get relevant Health Connect data types for a workout
  List<HealthConnectDataType> _getHealthConnectDataTypes(WorkoutType workoutType) {
    // Common data types for all workouts
    final dataTypes = <HealthConnectDataType>[
      HealthConnectDataType.ExerciseSession,
      HealthConnectDataType.HeartRate,
    ];

    // Add specific data types based on workout
    if (_isRepBasedExercise(workoutType)) {
      dataTypes.add(HealthConnectDataType.Steps);
    } else {
      // Time-based exercises
      dataTypes.add(HealthConnectDataType.Distance);
      dataTypes.add(HealthConnectDataType.Speed);
    }

    return dataTypes;
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
        _emitCurrentState();
        _currentReps++;
        if (kDebugMode) {
          print('🔄 Detected rep #$_currentReps for ${workoutType.displayName}');
        }
      });
    } else {
      // For time-based exercises, just track duration
        _emitCurrentState();
      _workoutTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (kDebugMode) {
          final elapsed = DateTime.now().difference(_workoutStartTime!);
          print('⏱️ ${workoutType.displayName} duration: ${elapsed.inSeconds}s');
        }
      });
    }
  }
  /// Emit current workout state to listeners
  void _emitCurrentState() {
    if (_currentWorkoutType == null || _workoutStartTime == null) return;
    
    final duration = DateTime.now().difference(_workoutStartTime!);
    final session = WorkoutSession.create(
      type: _currentWorkoutType!,
      reps: _currentReps,
      duration: duration,
    );
    _workoutController?.add(session);
  }


  /// Manually add a rep (for manual input mode)
  void addRep() {
    if (_currentWorkoutType != null) {
      _emitCurrentState();
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
    _workoutTimer?.cancel();;
    _isPolling = false
    _workoutController?.close();
  }
}
