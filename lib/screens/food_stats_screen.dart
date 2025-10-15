import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/calorie_calculator.dart';
import '../models/food_diary_entry.dart';
import '../models/user_profile.dart';
import 'settings_screen.dart';

class FoodStatsScreen extends StatefulWidget {
  const FoodStatsScreen({super.key});

  @override
  State<FoodStatsScreen> createState() => _FoodStatsScreenState();
}

class _FoodStatsScreenState extends State<FoodStatsScreen> {
  List<FoodDiaryEntry> _todaysEntries = [];
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
      final entries = await DatabaseService.instance.getTodaysFoodEntries();
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

      setState(() {
        _todaysEntries = entries;
        _todaysMacros = macros;
        _calorieGoal = goal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(int id) async {
    await DatabaseService.instance.deleteFoodEntry(id);
    _loadData(); // Refresh
  }

  @override
  Widget build(BuildContext context) {
    final totalCalories = _todaysMacros['calories'] ?? 0.0;
    final caloriesRemaining = _calorieGoal - totalCalories;
    final progressPercent = _calorieGoal <= 0 
        ? 0.0 
        : (totalCalories / _calorieGoal).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        title: const Text(
          'Food Diary - Today',
          style: TextStyle(
            fontFamily: 'Pixel Digivolve',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              _loadData(); // Reload data after settings change
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9CB4A8)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Calorie Summary Card
                    _buildCalorieCard(totalCalories, caloriesRemaining, progressPercent),
                    const SizedBox(height: 16),
                    
                    // Macros Card
                    _buildMacrosCard(),
                    const SizedBox(height: 16),
                    
                    // Food List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Meals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pixel Digivolve',
                          ),
                        ),
                        Text(
                          '${_todaysEntries.length} items',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontFamily: 'Pixel Digivolve',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Food Entries List
                    if (_todaysEntries.isEmpty)
                      _buildEmptyState()
                    else
                      ..._todaysEntries.map((entry) => _buildFoodEntryCard(entry)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCalorieCard(double total, double remaining, double progress) {
    final isOverLimit = remaining < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverLimit ? Colors.red : const Color(0xFF9CB4A8),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Calories Today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${total.toInt()}',
            style: TextStyle(
              color: isOverLimit ? Colors.red : Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
          Text(
            'of ${_calorieGoal.toInt()} goal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation(
                isOverLimit ? Colors.red : const Color(0xFF9CB4A8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            isOverLimit 
                ? '${remaining.abs().toInt()} cal over limit!'
                : '${remaining.toInt()} cal remaining',
            style: TextStyle(
              color: isOverLimit ? Colors.red : const Color(0xFF9CB4A8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard() {
    final protein = _todaysMacros['protein'] ?? 0.0;
    final carbs = _todaysMacros['carbs'] ?? 0.0;
    final fat = _todaysMacros['fat'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9CB4A8), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem('Protein', protein, Colors.blue),
          _buildMacroItem('Carbs', carbs, Colors.orange),
          _buildMacroItem('Fat', fat, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontFamily: 'Pixel Digivolve',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toInt()}g',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pixel Digivolve',
          ),
        ),
      ],
    );
  }

  Widget _buildFoodEntryCard(FoodDiaryEntry entry) {
    final timeFormat = DateFormat('h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
      ),
      child: Row(
        children: [
          // Food icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9CB4A8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Color(0xFF9CB4A8), size: 28),
          ),
          const SizedBox(width: 12),
          
          // Food info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pixel Digivolve',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.calories.toInt()} cal • ${entry.servingSize}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontFamily: 'Pixel Digivolve',
                  ),
                ),
                Text(
                  timeFormat.format(entry.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontFamily: 'Pixel Digivolve',
                  ),
                ),
              ],
            ),
          ),
          
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _showDeleteConfirmation(entry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No meals logged today',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add food from the FOOD menu!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontFamily: 'Pixel Digivolve',
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FoodDiaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3A3A),
        title: const Text(
          'Delete Entry?',
          style: TextStyle(color: Colors.white, fontFamily: 'Pixel Digivolve'),
        ),
        content: Text(
          'Remove ${entry.foodName} from your diary?',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontFamily: 'Pixel Digivolve',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
