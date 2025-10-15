import 'package:flutter/material.dart';
import '../models/workout_buddy.dart';
import '../widgets/animated_workout_buddy.dart';
import '../services/sound_service.dart';
import 'food_entry_wear_screen.dart';
import 'food_stats_wear_screen.dart';
import 'workout_wear_screen.dart';

/// Simplified Wear OS version of the Workout Buddy screen
/// Optimized for small circular screens with swipe navigation
class WorkoutbuddyWearScreen extends StatefulWidget {
  const WorkoutbuddyWearScreen({super.key});

  @override
  State<WorkoutbuddyWearScreen> createState() => _WorkoutbuddyWearScreenState();
}

class _WorkoutbuddyWearScreenState extends State<WorkoutbuddyWearScreen>
    with TickerProviderStateMixin {
  late WorkoutBuddy _currentWorkoutBuddy;
  late AnimationController _animationController;
  late SoundService _soundService;
  late PageController _verticalPageController;
  
  int _currentMenu = 0;
  int _currentPage = 0; // 0 = main, 1 = stats
  final List<String> _menuItems = ['STATUS', 'FOOD', 'TRAIN', 'BATTLE'];
  final List<IconData> _menuIcons = [
    Icons.analytics,
    Icons.restaurant,
    Icons.fitness_center,
    Icons.sports_martial_arts,
  ];

  @override
  void initState() {
    super.initState();
    _currentWorkoutBuddy = WorkoutBuddy.generateRandom();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _soundService = SoundService();
    _verticalPageController = PageController();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _soundService.dispose();
    _verticalPageController.dispose();
    super.dispose();
  }

  void _executeCurrentMenu() {
    _soundService.playBeep();
    
    switch (_currentMenu) {
      case 0: // Status
        _openFoodStats();
        break;
      case 1: // Food
        _openFoodDiary();
        break;
      case 2: // Train
        _openWorkoutScreen();
        break;
      case 3: // Battle
        _currentWorkoutBuddy.battle();
        setState(() {});
        break;
    }
  }

  Future<void> _openFoodStats() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodStatsWearScreen(),
      ),
    );
  }

  Future<void> _openFoodDiary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodEntryWearScreen(
          workoutBuddy: _currentWorkoutBuddy,
          onStatUpdate: (changes) {
            setState(() {
              // Changes are already applied in WorkoutBuddy
            });
          },
        ),
      ),
    );
  }

  Future<void> _openWorkoutScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutWearScreen(
          workoutBuddy: _currentWorkoutBuddy,
          onStatUpdate: (gains) {
            setState(() {
              // Stats are already updated via applyWorkoutGains in WorkoutBuddy
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCircular = size.width / size.height > 0.9 && size.width / size.height < 1.1;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: PageView(
        controller: _verticalPageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          // Page 1: Main view (title, sprite, menu)
          _buildMainView(size, isCircular),
          
          // Page 2: Stats view
          _buildStatsView(size, isCircular),
        ],
      ),
    );
  }
  
  Widget _buildMainView(Size size, bool isCircular) {
    return GestureDetector(
      // Only allow horizontal swipe on main view
      onHorizontalDragEnd: (details) {
        if (_currentPage != 0) return; // Disabled on stats page
        
        final velocity = details.primaryVelocity;
        if (velocity == null) return; // Exit early if velocity is null
        
        if (velocity > 0) {
          // Swipe right - previous menu
          setState(() {
            _currentMenu = (_currentMenu - 1) % _menuItems.length;
            if (_currentMenu < 0) _currentMenu = _menuItems.length - 1;
            _soundService.playMenuSound();
          });
        } else if (velocity < 0) {
          // Swipe left - next menu
          setState(() {
            _currentMenu = (_currentMenu + 1) % _menuItems.length;
            _soundService.playMenuSound();
          });
        }
      },
      // Tap to execute menu
      onTap: () {
        if (_currentPage != 0) return; // Disabled on stats page
        _executeCurrentMenu();
      },
      child: Stack(
          children: [
            // Circular container for round watches
            if (isCircular)
              Center(
                child: Container(
                  width: size.width * 0.95,
                  height: size.width * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF4A4A4A).withValues(alpha: 0.5),
                        const Color(0xFF2C2C2C),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'WORKOUT BUDDY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: size.width * 0.065,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
                
                SizedBox(height: size.height * 0.03),
                
                // Workout Buddy sprite
                SizedBox(
                  height: size.height * 0.42,
                  child: Center(
                    child: Transform.scale(
                      scale: 0.65,
                      child: AnimatedWorkoutBuddy(
                        workoutBuddy: _currentWorkoutBuddy,
                        animationController: _animationController,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.03),
                
                // Menu indicator with navigation arrows
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left arrow button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMenu = (_currentMenu - 1) % _menuItems.length;
                          if (_currentMenu < 0) _currentMenu = _menuItems.length - 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.green.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                    
                    // Menu indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _menuIcons[_currentMenu],
                            color: Colors.green,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _menuItems[_currentMenu],
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: size.width * 0.048,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right arrow button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMenu = (_currentMenu + 1) % _menuItems.length;
                          _soundService.playMenuSound();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.green.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: size.height * 0.02),
                
                // Stats hint
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Stats',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: size.width * 0.028,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsView(Size size, bool isCircular) {
    return Stack(
      children: [
        // Circular container
        if (isCircular)
          Center(
            child: Container(
              width: size.width * 0.95,
              height: size.width * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4A4A4A).withValues(alpha: 0.5),
                    const Color(0xFF2C2C2C),
                  ],
                ),
              ),
            ),
          ),
        
        // Stats content
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'STATS',
                style: TextStyle(
                  color: Colors.green.withValues(alpha: 0.9),
                  fontSize: size.width * 0.07,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              
              SizedBox(height: size.height * 0.05),
              
              // Detailed stats
              _buildDetailedStat('STRENGTH', _currentWorkoutBuddy.strength, Colors.red, size),
              SizedBox(height: size.height * 0.025),
              _buildDetailedStat('AGILITY', _currentWorkoutBuddy.agility, Colors.blue, size),
              SizedBox(height: size.height * 0.025),
              _buildDetailedStat('ENDURANCE', _currentWorkoutBuddy.endurance, Colors.orange, size),
              
              SizedBox(height: size.height * 0.05),
              
              // Swipe down hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 10,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Stats',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: size.width * 0.03,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailedStat(String label, int value, Color color, Size size) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: size.width * 0.04,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: size.width * 0.1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

}
