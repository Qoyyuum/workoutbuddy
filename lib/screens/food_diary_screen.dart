import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_diary_entry.dart';
import '../models/user_profile.dart';
import '../models/workout_buddy.dart';
import '../services/database_service.dart';
import 'food_entry_screen.dart';

class FoodDiaryScreen extends StatefulWidget {
  final WorkoutBuddy workoutBuddy;
  final Function(Map<String, int>) onStatUpdate;

  const FoodDiaryScreen({
    super.key,
    required this.workoutBuddy,
    required this.onStatUpdate,
  });

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  final DatabaseService _db = DatabaseService.instance;
  List<FoodDiaryEntry> _entries = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  int _selectedDays = 7; // Default to 7 days view

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load user profile for calorie goals
      final profileData = <String, String>{};
      final keys = [
        'name', 'weight_kg', 'height_cm', 'age', 'is_male',
        'activity_level', 'fitness_goal', 'custom_calorie_goal'
      ];
      
      for (final key in keys) {
        final value = await _db.getSetting(key);
        if (value != null) {
          profileData[key] = value;
        }
      }

      if (profileData.isNotEmpty) {
        _userProfile = UserProfile.fromMap(profileData);
      }
      
      // Load food entries for selected period
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _selectedDays));
      _entries = await _db.getFoodEntriesByDateRange(startDate, endDate);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading food diary: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Group entries by date
  Map<String, List<FoodDiaryEntry>> _groupEntriesByDate() {
    final Map<String, List<FoodDiaryEntry>> grouped = {};
    
    for (var entry in _entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    
    return grouped;
  }

  // Calculate daily totals
  Map<String, double> _calculateDailyTotals(List<FoodDiaryEntry> entries) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    
    for (var entry in entries) {
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
      totalFiber += entry.fiber;
    }
    
    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
    };
  }

  // Get calorie status color and message
  Map<String, dynamic> _getCalorieStatus(double consumed, double goal) {
    final difference = consumed - goal;
    
    if (difference < -100) {
      // Significant deficit
      return {
        'color': Colors.orange[700]!,
        'icon': Icons.trending_down,
        'message': 'Deficit: ${difference.abs().toStringAsFixed(0)} cal',
        'status': 'Under'
      };
    } else if (difference > 100) {
      // Significant surplus
      return {
        'color': Colors.red[700]!,
        'icon': Icons.trending_up,
        'message': 'Surplus: +${difference.toStringAsFixed(0)} cal',
        'status': 'Over'
      };
    } else {
      // Maintenance (within 100 cal)
      return {
        'color': Colors.green[700]!,
        'icon': Icons.check_circle,
        'message': 'On target',
        'status': 'Good'
      };
    }
  }

  Widget _buildDateHeader(String dateStr, List<FoodDiaryEntry> entries) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);
    
    final String displayDate;
    if (entryDate == today) {
      displayDate = 'Today';
    } else if (entryDate == yesterday) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('EEEE, MMM d').format(date);
    }
    
    final totals = _calculateDailyTotals(entries);
    final calorieGoal = _userProfile?.getCalorieGoal() ?? 2000;
    final status = _getCalorieStatus(totals['calories']!, calorieGoal);
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            status['color'].withValues(alpha: 0.1),
            status['color'].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status['color'].withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayDate,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  Icon(status['icon'], color: status['color'], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    status['message'],
                    style: TextStyle(
                      color: status['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Calorie progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${totals['calories']!.toStringAsFixed(0)} / ${calorieGoal.toStringAsFixed(0)} cal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${entries.length} items',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: calorieGoal <= 0 
                      ? 0.0 
                      : (totals['calories']! / calorieGoal).clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(status['color']),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Macro breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroChip(
                '💪 Protein',
                totals['protein']!,
                Colors.red[600]!,
              ),
              _buildMacroChip(
                '🍞 Carbs',
                totals['carbs']!,
                Colors.orange[600]!,
              ),
              _buildMacroChip(
                '🥑 Fat',
                totals['fat']!,
                Colors.blue[600]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildFoodEntryCard(FoodDiaryEntry entry) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            entry.calories.toStringAsFixed(0),
            style: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          entry.foodName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${entry.servingSize} • ${DateFormat('h:mm a').format(entry.timestamp)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
          onPressed: () => _deleteFoodEntry(entry),
        ),
      ),
    );
  }

  Future<void> _deleteFoodEntry(FoodDiaryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove "${entry.foodName}" from food diary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && entry.id != null) {
      await _db.deleteFoodEntry(entry.id!);
      _loadData(); // Refresh
    }
  }

  Future<void> _navigateToFoodEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodEntryScreen(
          workoutBuddy: widget.workoutBuddy,
          onStatUpdate: widget.onStatUpdate,
        ),
      ),
    );

    // Refresh if food was added
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Food Diary 📖'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final groupedEntries = _groupEntriesByDate();
    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Diary 📖'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          // Period selector
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('Today')),
              const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 Days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
            ],
          ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No food logged yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start tracking your meals!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedDates[index];
                  final entries = groupedEntries[dateKey]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateHeader(dateKey, entries),
                      ...entries.map((entry) => _buildFoodEntryCard(entry)),
                    ],
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToFoodEntry,
        backgroundColor: Colors.green[600],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Log Food',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
