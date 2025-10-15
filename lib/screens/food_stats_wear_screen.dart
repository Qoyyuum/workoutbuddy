import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/calorie_calculator.dart';
import '../models/user_profile.dart';
import 'settings_wear_screen.dart';

/// Wear OS optimized food stats screen
/// Shows today's calories and macros in a compact view
class FoodStatsWearScreen extends StatefulWidget {
  const FoodStatsWearScreen({super.key});

  @override
  State<FoodStatsWearScreen> createState() => _FoodStatsWearScreenState();
}

class _FoodStatsWearScreenState extends State<FoodStatsWearScreen> {
  Map<String, double> _todaysMacros = {};
  double _calorieGoal = CalorieCalculator.getDefaultCalorieGoal();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final macros = await DatabaseService.instance.getTodaysMacros();
      
      // Load user profile to get calorie goal
      final db = DatabaseService.instance;
      final profileData = <String, String>{};
      
      final keys = [
        'weight_kg', 'height_cm', 'age', 'is_male',
        'activity_level', 'fitness_goal', 'custom_calorie_goal'
      ];
      
      for (final key in keys) {
        final value = await db.getSetting(key);
        if (value != null && value.isNotEmpty) {
          profileData[key] = value;
        }
      }

      double goal = _calorieGoal;
      if (profileData.isNotEmpty) {
        final profile = UserProfile.fromMap(profileData);
        goal = profile.getCalorieGoal();
      }

      if (!mounted) return;
      setState(() {
        _todaysMacros = macros;
        _calorieGoal = goal;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalCalories = _todaysMacros['calories'] ?? 0.0;
    final caloriesRemaining = _calorieGoal - totalCalories;
    final isOver = totalCalories > _calorieGoal;
    final progressPercent = _calorieGoal <= 0 
        ? 0.0 
        : (totalCalories / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF9CB4A8)),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'FOOD STATS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: size.width * 0.055,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        children: [
                          // Calories Today
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF9CB4A8),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'CALORIES',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: size.width * 0.04,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: size.width * 0.04,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  totalCalories.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: const Color(0xFF9CB4A8),
                                    fontSize: size.width * 0.15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'of ${_calorieGoal.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: size.width * 0.035,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isOver
                                          ? Colors.red
                                          : const Color(0xFF9CB4A8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  !isOver
                                      ? '${caloriesRemaining.toStringAsFixed(0)} left'
                                      : '${(-caloriesRemaining).toStringAsFixed(0)} over',
                                  style: TextStyle(
                                    color: !isOver
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: size.width * 0.035,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: size.height * 0.02),
                          
                          // Macros (compact)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF9CB4A8).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'MACROS',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: size.width * 0.04,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildMacroRow(
                                  'Protein',
                                  _todaysMacros['protein'] ?? 0.0,
                                  Colors.red,
                                  size,
                                ),
                                const SizedBox(height: 6),
                                _buildMacroRow(
                                  'Carbs',
                                  _todaysMacros['carbs'] ?? 0.0,
                                  Colors.blue,
                                  size,
                                ),
                                const SizedBox(height: 6),
                                _buildMacroRow(
                                  'Fat',
                                  _todaysMacros['fat'] ?? 0.0,
                                  Colors.orange,
                                  size,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: size.height * 0.02),
                          
                          // Settings button
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsWearScreen(),
                                ),
                              );
                              _loadData(); // Reload after settings change
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF9CB4A8).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: const Color(0xFF9CB4A8),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SETTINGS',
                                    style: TextStyle(
                                      color: const Color(0xFF9CB4A8),
                                      fontSize: size.width * 0.045,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMacroRow(String label, double value, Color color, Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: size.width * 0.04,
              ),
            ),
          ],
        ),
        Text(
          '${value.toStringAsFixed(0)}g',
          style: TextStyle(
            color: color,
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
