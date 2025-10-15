import 'package:flutter/material.dart';
import 'dart:async';
import '../models/workout_buddy.dart';
import '../models/workout_type.dart';
import '../models/workout_session.dart';
import '../services/workout_detection_service.dart';

/// Wear OS optimized workout screen
/// Simplified UI for small circular screens
class WorkoutWearScreen extends StatefulWidget {
  final WorkoutBuddy workoutBuddy;
  final Function(Map<StatType, int>) onStatUpdate;

  const WorkoutWearScreen({
    super.key,
    required this.workoutBuddy,
    required this.onStatUpdate,
  });

  @override
  State<WorkoutWearScreen> createState() => _WorkoutWearScreenState();
}

class _WorkoutWearScreenState extends State<WorkoutWearScreen>
    with TickerProviderStateMixin {
  final WorkoutDetectionService _detectionService = WorkoutDetectionService();
  
  WorkoutType? _selectedWorkout;
  bool _isWorkoutActive = false;
  int _currentReps = 0;
  Duration _workoutDuration = Duration.zero;
  Timer? _uiTimer;
  
  late AnimationController _buddyAnimationController;
  
  StreamSubscription<WorkoutSession>? _workoutSubscription;

  @override
  void initState() {
    super.initState();
    
    _buddyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _workoutSubscription = _detectionService.workoutStream.listen(_onWorkoutCompleted);
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _workoutSubscription?.cancel();
    _buddyAnimationController.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  void _onWorkoutCompleted(WorkoutSession session) {
    _uiTimer?.cancel();
    _uiTimer = null;
    
    if (!mounted) return;
    
    setState(() {
      _isWorkoutActive = false;
      _selectedWorkout = null;
    });
    
    // Apply gains
    widget.workoutBuddy.applyWorkoutGains(session.statGains);
    widget.onStatUpdate(session.statGains);
    
    // Navigate back after showing results
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _startWorkout(WorkoutType workoutType) async {
    setState(() {
      _selectedWorkout = workoutType;
      _isWorkoutActive = true;
      _currentReps = 0;
      _workoutDuration = Duration.zero;
    });
    
    _buddyAnimationController.repeat();
    await _detectionService.startWorkoutDetection(workoutType);
    
    if (!mounted) return;
    
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
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: _isWorkoutActive
            ? _buildActiveWorkout(size)
            : _buildWorkoutSelection(size),
      ),
    );
  }

  Widget _buildWorkoutSelection(Size size) {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.blue[900],
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'WORKOUT',
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontSize: size.width * 0.07,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 28),
            ],
          ),
        ),
        
        // Workout type buttons (full screen list)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: WorkoutType.values.map((type) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _startWorkout(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _getWorkoutColor(type),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue[900]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getWorkoutIcon(type),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.048,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveWorkout(Size size) {
    return SafeArea(
      child: Column(
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: Colors.blue[900],
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Text(
                    _selectedWorkout?.displayName.toUpperCase() ?? '',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Stats (large)
          _buildStatColumn('REPS', _currentReps.toString(), Colors.blue, size),
          SizedBox(height: size.height * 0.03),
          _buildStatColumn(
            'TIME',
            '${_workoutDuration.inMinutes}:${(_workoutDuration.inSeconds % 60).toString().padLeft(2, '0')}',
            Colors.green,
            size,
          ),
          
          const Spacer(),
          
          // Stop button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GestureDetector(
              onTap: _stopWorkout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[900]!, width: 2),
                ),
                child: Text(
                  'STOP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.05,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color, Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: size.width * 0.04,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: size.width * 0.13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getWorkoutColor(WorkoutType type) {
    switch (type) {
      case WorkoutType.pushUp:
        return Colors.red[400]!;
      case WorkoutType.sitUp:
        return Colors.purple[400]!;
      case WorkoutType.squat:
        return Colors.orange[400]!;
      case WorkoutType.running:
        return Colors.blue[400]!;
      case WorkoutType.walking:
        return Colors.lightBlue[400]!;
      case WorkoutType.jumping:
        return Colors.green[400]!;
      case WorkoutType.plank:
        return Colors.teal[400]!;
      case WorkoutType.burpee:
        return Colors.pink[400]!;
      case WorkoutType.pullUp:
        return Colors.red[600]!;
      case WorkoutType.lunges:
        return Colors.amber[400]!;
    }
  }

  IconData _getWorkoutIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.pushUp:
      case WorkoutType.pullUp:
        return Icons.fitness_center;
      case WorkoutType.sitUp:
        return Icons.airline_seat_recline_extra;
      case WorkoutType.squat:
      case WorkoutType.lunges:
        return Icons.airline_seat_legroom_normal;
      case WorkoutType.running:
      case WorkoutType.walking:
        return Icons.directions_run;
      case WorkoutType.jumping:
        return Icons.sports_gymnastics;
      case WorkoutType.plank:
        return Icons.self_improvement;
      case WorkoutType.burpee:
        return Icons.sports_kabaddi;
    }
  }
}
