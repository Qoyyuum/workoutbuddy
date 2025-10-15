import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../models/workout_type.dart';
import '../models/workout_session.dart';

/// Workout detection service using Health Connect (Android) and HealthKit (iOS)
/// 
/// **Data Limitations & Known Issues:**
/// 
/// 1. **Step-Based Rep Estimation (UNRELIABLE)**
///    - Uses step count as a proxy for exercise reps when workout data unavailable
///    - Not all exercises generate step-like movements (e.g., push-ups, planks)
///    - Conservative multipliers applied but accuracy varies significantly
///    - Minimum threshold of 20 steps required to prevent noise
///    - Recommended: Use manual input for rep-based exercises when accuracy matters
/// 
/// 2. **Workout Session Detection**
///    - Requires user to actively record workouts in health apps (Google Fit, Apple Health)
///    - If no workout session detected: falls back to step estimation or simulation
///    - Workout data may have delay (not real-time on some devices)
///    - Rep-specific metrics not currently parsed from workout data (see TODO at line 249)
/// 
/// 3. **Circuit Breaker Recovery**
///    - Opens after 3 consecutive health API failures (prevents battery drain)
///    - Automatically resets when starting a new workout (provides recovery opportunity)
///    - Falls back to simulation mode when circuit open
///    - Transient network/permission issues get retried on next workout
/// 
/// 4. **Platform Behavior**
///    - iOS: Device must be unlocked to access HealthKit data
///    - Android: Requires Health Connect app installed and permissions granted
///    - Web/Desktop: Falls back to manual input or simulation mode
class WorkoutDetectionService {
  static final WorkoutDetectionService _instance = WorkoutDetectionService._internal();
  factory WorkoutDetectionService() => _instance;
  WorkoutDetectionService._internal();

  // StreamController persists across workout sessions (broadcast stream)
  // Callers are responsible for canceling their stream subscriptions
  StreamController<WorkoutSession>? _workoutController;
  Timer? _workoutTimer;
  WorkoutType? _currentWorkoutType;
  DateTime? _workoutStartTime;
  int _currentReps = 0;
  bool _isHealthInitialized = false;
  bool _isPolling = false;
  
  // Health package instance
  final Health _health = Health();
  
  // Circuit breaker for health API failures
  int _healthFailureCount = 0;
  static const int _maxHealthFailures = 3;
  bool _healthCircuitOpen = false;

  /// Stream of workout session updates
  /// Note: This is a broadcast stream that persists across multiple workout sessions.
  /// Listeners should cancel their subscriptions when no longer needed to prevent memory leaks.
  Stream<WorkoutSession> get workoutStream => _workoutController?.stream ?? const Stream.empty();

  /// Start detecting a specific workout type
  Future<void> startWorkoutDetection(WorkoutType workoutType) async {
    // If a workout is already active, stop it first to preserve session data
    if (_currentWorkoutType != null && _workoutStartTime != null) {
      if (kDebugMode) {
        debugPrint('⚠️ Stopping active workout before starting new one');
      }
      final previousSession = stopWorkoutDetection();
      if (previousSession != null && kDebugMode) {
        debugPrint('💾 Saved previous session: ${previousSession.type.displayName} - ${previousSession.reps} reps');
      }
    }
    
    // Initialize workout state
    _currentWorkoutType = workoutType;
    _workoutStartTime = DateTime.now();
    _currentReps = 0;
    _isPolling = false;
    
    // Reset circuit breaker for new workout (provides recovery opportunity)
    // This allows health API to be retried after temporary failures
    _healthFailureCount = 0;
    _healthCircuitOpen = false;
    
    _workoutController ??= StreamController<WorkoutSession>.broadcast();
    
    // Emit initial state snapshot so listeners receive first data immediately
    final initialSession = WorkoutSession.create(
      type: workoutType,
      reps: 0,
      duration: Duration.zero,
    );
    _workoutController?.add(initialSession);
    
    if (kDebugMode) {
      debugPrint('🏋️ Started detecting ${workoutType.displayName}');
    }

    // For now, we'll use platform-specific detection methods
    if (kIsWeb) {
      // Web - manual input mode
      await _startManualDetection(workoutType);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _startAndroidDetection(workoutType);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _startIOSDetection(workoutType);
    } else {
      // Desktop - manual input mode
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

    // Emit final session to stream so all listeners receive the completed state
    _workoutController?.add(session);

    _workoutTimer?.cancel();
    _currentWorkoutType = null;
    _workoutStartTime = null;
    _currentReps = 0;
    _isPolling = false;

    if (kDebugMode) {
      debugPrint('🏁 Workout session completed: ${session.type.displayName} - ${session.reps} reps in ${session.duration.inMinutes}m');
    }

    return session;
  }

  /// Android/iOS workout detection using health package (Health Connect/HealthKit)
  Future<void> _startAndroidDetection(WorkoutType workoutType) async {
    try {
      // Request permissions for workout data types
      final dataTypes = _getHealthDataTypes(workoutType);
      
      if (!_isHealthInitialized) {
        // Create permissions list matching dataTypes length (required by health package API)
        final permissions = List<HealthDataAccess>.filled(
          dataTypes.length,
          HealthDataAccess.READ,
        );
        
        final permissionsGranted = await _health.requestAuthorization(
          dataTypes,
          permissions: permissions,
        );
        
        if (!permissionsGranted) {
          if (kDebugMode) {
            debugPrint('⚠️ Health permissions denied, falling back to simulation');
          }
          _simulateWorkoutDetection(workoutType);
          return;
        }
        _isHealthInitialized = true;
      }

      if (kDebugMode) {
        debugPrint('✅ Health API initialized and permissions granted');
      }

      // Start monitoring for exercise data
      await _monitorHealthData(workoutType, dataTypes);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing health API: $e');
        debugPrint('Falling back to simulation mode');
      }
      _simulateWorkoutDetection(workoutType);
    }
  }

  /// Monitor health data updates (Health Connect on Android, HealthKit on iOS)
  /// 
  /// **Polling Behavior:**
  /// - Polls every 5 seconds for new health data
  /// - Queries entire workout window (from start to now) on each poll
  /// - 10-second timeout per API call to prevent hanging
  /// - Reentrancy guard prevents overlapping polls
  /// 
  /// **Fallback Strategy (Priority Order):**
  /// 1. Workout/Exercise session data (preferred, contains structured metrics)
  /// 2. Step count data (unreliable for reps, see class-level docs)
  /// 3. Circuit breaker opens → falls back to simulation mode
  /// 
  /// **When No Data Detected:**
  /// - No workout session: Continues polling, may use step fallback
  /// - No steps detected: No rep updates, waits for next poll cycle
  /// - Time-based exercises: Duration tracked regardless of health data
  /// - After 3 consecutive failures: Circuit breaker opens, simulation starts
  /// 
  /// TODO: Consider using change tokens for more efficient polling
  /// This would reduce API load and improve efficiency for longer workouts
  Future<void> _monitorHealthData(
    WorkoutType workoutType,
    List<HealthDataType> dataTypes,
  ) async {
    // Poll for new exercise data periodically
    _workoutTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Reentrancy guard: prevent overlapping polls
      if (_isPolling) return;
      
      // Circuit breaker: stop polling if health API consistently fails
      if (_healthCircuitOpen) {
        if (kDebugMode) {
          debugPrint('🔌 Circuit breaker open - Health API polling disabled');
          debugPrint('   Falling back to simulation mode');
        }
        // Clean transition: cancel this timer before starting simulation timer
        timer.cancel();
        _simulateWorkoutDetection(workoutType);
        // Note: Circuit breaker will reset on next workout via startWorkoutDetection
        return;
      }
      
      _isPolling = true;
      // successfulPoll tracks whether we got valid data this cycle
      // Only set to true when actual workout data is retrieved and processed
      bool successfulPoll = false;
      try {
        final endTime = DateTime.now();
        final startTime = _workoutStartTime ?? endTime.subtract(const Duration(seconds: 30));

        // Process the records based on workout type
        if (_isRepBasedExercise(workoutType)) {
          // For rep-based exercises, try to get exercise-specific data first
          bool repsDetected = false;
          
          // Priority 1: Try to get Exercise/Workout data which may contain rep counts
          try {
            final workoutData = await _health.getHealthDataFromTypes(
              types: [HealthDataType.WORKOUT],
              startTime: startTime,
              endTime: endTime,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Workout query timed out'),
            );
            
            if (workoutData.isNotEmpty) {
              // TODO: Parse workout data for rep-specific metrics if available
              // For now, this is a placeholder for future enhancement
              if (kDebugMode) {
                debugPrint('📊 Workout data available but rep parsing not yet implemented');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Could not read workout data: $e');
            }
          }
          
          // Priority 2: Fallback to steps (UNRELIABLE - use with caution)
          // See class-level documentation for step-based estimation limitations
          // This is a heuristic fallback when proper workout data is unavailable
          if (!repsDetected) {
            try {
              final stepsData = await _health.getHealthDataFromTypes(
                types: [HealthDataType.STEPS],
                startTime: startTime,
                endTime: endTime,
              ).timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw TimeoutException('Steps query timed out'),
              );
              
              if (stepsData.isNotEmpty) {
                int totalSteps = 0;
                for (var point in stepsData) {
                  if (point.value is NumericHealthValue) {
                    totalSteps += (point.value as NumericHealthValue).numericValue.toInt();
                  }
                }
                
                // Apply minimum threshold to filter out sensor noise and minor movements
                const int minStepsThreshold = 20;
                if (totalSteps >= minStepsThreshold) {
                  // Apply workout-specific multiplier (conservative estimates)
                  final multiplier = _getStepToRepMultiplier(workoutType);
                  final estimatedReps = (totalSteps * multiplier).round();
                  
                  // Only update if estimate is reasonable (prevent wild fluctuations)
                  if (estimatedReps > 0 && estimatedReps < 1000) {
                    _currentReps = estimatedReps;
                    _emitCurrentState();
                    // Mark as successful - we got valid data
                    successfulPoll = true;
                    
                    if (kDebugMode) {
                      debugPrint('⚠️ WARNING: Using step count as rep proxy (UNRELIABLE)');
                      debugPrint('   Steps: $totalSteps -> Estimated reps: $_currentReps (multiplier: $multiplier)');
                      debugPrint('   ${workoutType.displayName} may not generate step-like movements');
                      debugPrint('   Consider manual input for accuracy');
                    }
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Could not read steps data: $e');
              }
            }
          }
        } else {
          // For time-based exercises, track duration via workout data
          try {
            final workoutData = await _health.getHealthDataFromTypes(
              types: [HealthDataType.WORKOUT],
              startTime: startTime,
              endTime: endTime,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('Workout query timed out'),
            );
            
            if (workoutData.isNotEmpty) {
              final duration = DateTime.now().difference(_workoutStartTime!);
              _emitCurrentState();
              // Mark as successful - we got valid session data
              successfulPoll = true;
              if (kDebugMode) {
                debugPrint('⏱️ Health tracking ${workoutType.displayName}: ${duration.inSeconds}s');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Could not read workout data: $e');
            }
          }
        }
        
        // Reset failure count on successful poll (prevents circuit breaker from opening)
        // successfulPoll is only true if we retrieved and processed valid health data
        if (successfulPoll) {
          _healthFailureCount = 0;
        }
      } catch (e) {
        // Increment failure count on error
        _healthFailureCount++;
        
        if (kDebugMode) {
          debugPrint('❌ Error reading health data: $e');
          debugPrint('   Failure count: $_healthFailureCount/$_maxHealthFailures');
        }
        
        // Open circuit breaker if threshold reached (prevents battery drain from repeated failures)
        // Recovery: Circuit automatically resets when user starts next workout (see startWorkoutDetection)
        if (_healthFailureCount >= _maxHealthFailures) {
          _healthCircuitOpen = true;
          if (kDebugMode) {
            debugPrint('🔌 Circuit breaker opened after $_healthFailureCount consecutive failures');
            debugPrint('   Health API polling will stop and fall back to simulation');
            debugPrint('   Will retry on next workout session');
          }
        }
      } finally {
        _isPolling = false;
      }
    });
  }

  /// Get relevant health data types for a workout (cross-platform)
  List<HealthDataType> _getHealthDataTypes(WorkoutType workoutType) {
    // Common data types for all workouts
    final dataTypes = <HealthDataType>[
      HealthDataType.WORKOUT,
      HealthDataType.HEART_RATE,
    ];

    // Add specific data types based on workout
    if (_isRepBasedExercise(workoutType)) {
      dataTypes.add(HealthDataType.STEPS);
    } else {
      // Time-based exercises
      dataTypes.add(HealthDataType.DISTANCE_DELTA);
      dataTypes.add(HealthDataType.ACTIVE_ENERGY_BURNED);
    }

    return dataTypes;
  }

  /// iOS-specific workout detection using HealthKit (via health package)
  Future<void> _startIOSDetection(WorkoutType workoutType) async {
    // The health package provides unified API for both iOS HealthKit and Android Health Connect
    // Use the same implementation as Android
    await _startAndroidDetection(workoutType);
  }

  /// Manual detection for web/desktop platforms
  Future<void> _startManualDetection(WorkoutType workoutType) async {
    // Manual mode uses simulation for demonstration/testing
    // Note: addRep() method exists but is NOT exposed in UI to prevent cheating
    _simulateWorkoutDetection(workoutType);
  }

  /// Simulate workout detection for development/testing
  void _simulateWorkoutDetection(WorkoutType workoutType) {
    // Simulate rep detection every 2-5 seconds for rep-based exercises
    if (_isRepBasedExercise(workoutType)) {
      _workoutTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _currentReps++;
        _emitCurrentState();
        if (kDebugMode) {
          debugPrint('🔄 Detected rep #$_currentReps for ${workoutType.displayName}');
        }
      });
    } else {
      // For time-based exercises, just track duration
      _workoutTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _emitCurrentState();
        if (kDebugMode) {
          final elapsed = DateTime.now().difference(_workoutStartTime!);
          debugPrint('⏱️ ${workoutType.displayName} duration: ${elapsed.inSeconds}s');
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


  /// Manually add a rep (internal method, not exposed in UI)
  /// 
  /// **Note:** This method is intentionally NOT exposed in the workout UI to prevent
  /// users from cheating their workouts by manually inflating rep counts.
  /// 
  /// Kept for potential future use in:
  /// - Debug/testing mode
  /// - Accessibility features
  /// - Web/desktop fallback when health APIs unavailable
  /// 
  /// Do NOT add UI buttons that call this method during normal workouts.
  void addRep() {
    if (_currentWorkoutType != null) {
      _currentReps++;
      _emitCurrentState();
      if (kDebugMode) {
        debugPrint('➕ Manual rep added: $_currentReps');
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

  /// Get conservative step-to-rep multiplier for each workout type
  /// These are rough heuristics and should be used only as fallback estimates
  double _getStepToRepMultiplier(WorkoutType workoutType) {
    switch (workoutType) {
      case WorkoutType.pushUp:
      case WorkoutType.sitUp:
      case WorkoutType.pullUp:
        // Upper body exercises generate minimal steps - very unreliable
        return 0.05; // 20 steps ≈ 1 rep (extremely conservative)
      
      case WorkoutType.squat:
      case WorkoutType.lunges:
        // Lower body exercises may register as steps
        return 0.5; // 2 steps ≈ 1 rep
      
      case WorkoutType.burpee:
        // Full-body movement, generates more motion
        return 0.3; // ~3 steps ≈ 1 rep
      
      case WorkoutType.jumping:
        // Jumping jacks generate vertical motion
        return 0.4; // ~2.5 steps ≈ 1 rep
      
      case WorkoutType.running:
      case WorkoutType.walking:
      case WorkoutType.plank:
        // Time-based exercises shouldn't use this
        return 0.0;
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
    _isPolling = false;
    _workoutController?.close();
  }
}
