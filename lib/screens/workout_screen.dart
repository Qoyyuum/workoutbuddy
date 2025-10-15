import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout_buddy.dart';
import '../models/workout_type.dart';
import '../models/workout_session.dart';
import '../services/workout_detection_service.dart';
import '../widgets/animated_workout_buddy.dart';
import '../widgets/stat_gain_animation.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutBuddy workoutBuddy;
  final Function(Map<StatType, int>) onStatUpdate;

  const WorkoutScreen({
    super.key,
    required this.workoutBuddy,
    required this.onStatUpdate,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with TickerProviderStateMixin {
  final WorkoutDetectionService _detectionService = WorkoutDetectionService();
  
  WorkoutType? _selectedWorkout;
  bool _isWorkoutActive = false;
  int _currentReps = 0;
  Duration _workoutDuration = Duration.zero;
  Timer? _uiTimer;
  
  late AnimationController _buddyAnimationController;
  late AnimationController _statAnimationController;
  
  StreamSubscription<WorkoutSession>? _workoutSubscription;
  
  // For stat gain animations
  final List<StatGainWidget> _activeStatGains = [];

  @override
  void initState() {
    super.initState();
    
    _buddyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _statAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _workoutSubscription = _detectionService.workoutStream.listen(_onWorkoutCompleted);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _workoutSubscription?.cancel();
    _buddyAnimationController.dispose();
    _statAnimationController.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  void _onWorkoutCompleted(WorkoutSession session) {
    // Cancel UI timer to stop further ticks
    _uiTimer?.cancel();
    _uiTimer = null;
    
    if (!mounted) return;
    
    setState(() {
      _isWorkoutActive = false;
      _selectedWorkout = null;
    });
    
    // Apply stat gains to workout buddy
    widget.workoutBuddy.applyWorkoutGains(session.statGains);
    widget.onStatUpdate(session.statGains);
    
    if (!mounted) return;
    
    // Show stat gain animations
    _showStatGainAnimations(session.statGains);
    
    // Show completion dialog
    _showWorkoutCompletionDialog(session);
  }

  void _showStatGainAnimations(Map<StatType, int> gains) {
    for (final entry in gains.entries) {
      final statGain = StatGainWidget(
        statType: entry.key,
        amount: entry.value,
        animationController: _statAnimationController,
      );
      
      if (mounted) {
        setState(() {
          _activeStatGains.add(statGain);
        });
      }
      
      // Remove after animation completes
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _activeStatGains.remove(statGain);
          });
        }
      });
    }
    
    _statAnimationController.forward().then((_) {
      if (mounted) {
        _statAnimationController.reset();
      }
    });
  }

  void _showWorkoutCompletionDialog(WorkoutSession session) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Workout Complete! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.type.displayName),
            Text('Reps: ${session.reps}'),
            Text('Duration: ${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s'),
            const SizedBox(height: 16),
            const Text('Stat Gains:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...session.statGains.entries.map((entry) => 
              Text('${entry.key.emoji} ${entry.key.displayName}: +${entry.value}')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _startWorkout(WorkoutType workoutType) async {
    setState(() {
      _selectedWorkout = workoutType;
      _isWorkoutActive = true;
      _currentReps = 0;
      _workoutDuration = Duration.zero;
    });
    
    // Start buddy animation
    _buddyAnimationController.repeat();
    
    // Start workout detection
    await _detectionService.startWorkoutDetection(workoutType);
    
    if (!mounted) return;
    
    // Start UI update timer
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final status = _detectionService.currentStatus;
      setState(() {
        _currentReps = status['reps'] ?? 0;
        _workoutDuration = Duration(seconds: status['duration'] ?? 0);
      });
    });
  }

  void _stopWorkout() {
    final session = _detectionService.stopWorkoutDetection();
    _uiTimer?.cancel();
    _uiTimer = null;
    _buddyAnimationController.stop();
    
    if (session != null) {
      _onWorkoutCompleted(session);
    } else {
      if (mounted) {
        setState(() {
          _isWorkoutActive = false;
          _selectedWorkout = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Time! 💪'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Workout Buddy Animation Area
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Workout Buddy
                      AnimatedWorkoutBuddy(
                        workoutBuddy: widget.workoutBuddy,
                        workoutType: _selectedWorkout,
                        animationController: _buddyAnimationController,
                        isActive: _isWorkoutActive,
                      ),
                      
                      // Stat gain animations overlay
                      ..._activeStatGains,
                    ],
                  ),
                ),
              ),
              
              // Workout Status
              if (_isWorkoutActive) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedWorkout?.displayName ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$_currentReps',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text('Reps'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${_workoutDuration.inMinutes}:${(_workoutDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text('Time'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stop button centered (no manual rep cheating allowed!)
                      Center(
                        child: ElevatedButton(
                          onPressed: _stopWorkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                          ),
                          child: const Text(
                            'Stop Workout',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Workout Selection
              if (!_isWorkoutActive) ...[
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Choose Your Workout',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: WorkoutType.values.length,
                            itemBuilder: (context, index) {
                              final workoutType = WorkoutType.values[index];
                              return ElevatedButton(
                                onPressed: () => _startWorkout(workoutType),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      workoutType.primaryStat.emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    Text(
                                      workoutType.displayName,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
