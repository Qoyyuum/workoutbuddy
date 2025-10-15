import 'package:flutter/material.dart';
import '../models/food_nutrition.dart';
import '../models/food_diary_entry.dart';
import '../services/fatsecret_service.dart';
import '../services/mock_food_service.dart';
import '../services/database_service.dart';
import '../models/workout_buddy.dart';

class FoodEntryScreen extends StatefulWidget {
  final WorkoutBuddy workoutBuddy;
  final Function(Map<String, int>) onStatUpdate;

  const FoodEntryScreen({
    super.key,
    required this.workoutBuddy,
    required this.onStatUpdate,
  });

  @override
  State<FoodEntryScreen> createState() => _FoodEntryScreenState();
}

class _FoodEntryScreenState extends State<FoodEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // ⚙️ TOGGLE: Set to false to use real FatSecret API, true for mock data
  static const bool _useMockData = false;
  
  // Food service - automatically switches based on _useMockData
  late final dynamic _foodService = _useMockData 
      ? MockFoodService() 
      : FatSecretService();
  
  List<FoodSearchResult> _searchResults = [];
  FoodNutrition? _selectedFood;
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFood() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _searchResults = [];
      _selectedFood = null;
    });

    try {
      final results = await _foodService.searchFood(_searchController.text.trim());
      setState(() {
        _searchResults = results;
        _isLoading = false;
        if (results.isEmpty) {
          _message = 'No foods found. Try a different search term.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _selectFood(FoodSearchResult food) async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final nutrition = await _foodService.getFoodNutrition(food.foodId);
      setState(() {
        _selectedFood = nutrition;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error loading nutrition: ${e.toString()}';
      });
    }
  }

  Future<void> _feedBuddy() async {
    if (_selectedFood == null) return;

    // Save to database
    final entry = FoodDiaryEntry(
      foodName: _selectedFood!.foodName,
      calories: _selectedFood!.calories,
      protein: _selectedFood!.protein,
      carbs: _selectedFood!.carbs,
      fat: _selectedFood!.fat,
      fiber: _selectedFood!.fiber,
      servingSize: _selectedFood!.servingSize,
      timestamp: DateTime.now(),
    );

    try {
      await DatabaseService.instance.insertFoodEntry(entry);
    } catch (e) {
      debugPrint('❌ Error saving food entry: $e');
    }

    final statChanges = _selectedFood!.calculateStatImpact();
    
    // Apply stat changes
    widget.onStatUpdate(statChanges);

    // Show feedback message
    String feedbackMessage = '';
    if (_selectedFood!.isHealthy) {
      feedbackMessage = '${widget.workoutBuddy.name} feels energized! 💪';
    } else {
      feedbackMessage = '${widget.workoutBuddy.name} feels sluggish... 😓';
    }

    setState(() {
      _message = feedbackMessage;
    });

    // Navigate back after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      appBar: AppBar(
        title: const Text(
          'Food Diary',
          style: TextStyle(
            fontFamily: 'Pixel Digivolve',
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Data source indicator
            if (_useMockData)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.orange, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using MOCK data (toggle in code to use real API)',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontFamily: 'Pixel Digivolve',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9CB4A8), width: 2),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Pixel Digivolve',
                ),
                decoration: InputDecoration(
                  hintText: 'Search food (e.g., "chicken breast")',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontFamily: 'Pixel Digivolve',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF9CB4A8)),
                    onPressed: _searchFood,
                  ),
                ),
                onSubmitted: (_) => _searchFood(),
              ),
            ),
            const SizedBox(height: 16),

            // Message display
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9CB4A8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'Pixel Digivolve',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Loading indicator
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF9CB4A8),
                  ),
                ),
              ),

            // Selected food nutrition details
            if (_selectedFood != null && !_isLoading)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9CB4A8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFood!.foodName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pixel Digivolve',
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Serving: ${_selectedFood!.servingSize}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Pixel Digivolve',
                            color: Colors.black,
                          ),
                        ),
                        const Divider(height: 24, color: Colors.black),
                        _buildNutritionRow('Calories', '${_selectedFood!.calories.toStringAsFixed(0)} kcal'),
                        _buildNutritionRow('Protein', '${_selectedFood!.protein.toStringAsFixed(1)}g'),
                        _buildNutritionRow('Carbs', '${_selectedFood!.carbs.toStringAsFixed(1)}g'),
                        _buildNutritionRow('Fat', '${_selectedFood!.fat.toStringAsFixed(1)}g'),
                        _buildNutritionRow('Fiber', '${_selectedFood!.fiber.toStringAsFixed(1)}g'),
                        const Divider(height: 24, color: Colors.black),
                        Text(
                          _selectedFood!.isHealthy ? '✅ Healthy Choice' : '⚠️ Junk Food',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pixel Digivolve',
                            color: _selectedFood!.isHealthy ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _feedBuddy,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A4A4A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Feed to Buddy',
                              style: TextStyle(
                                fontFamily: 'Pixel Digivolve',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Search results list
            if (_searchResults.isNotEmpty && _selectedFood == null && !_isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final food = _searchResults[index];
                    return Card(
                      color: const Color(0xFF3A3A3A),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          food.foodName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pixel Digivolve',
                          ),
                        ),
                        subtitle: Text(
                          food.foodDescription,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontFamily: 'Pixel Digivolve',
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF9CB4A8), size: 16),
                        onTap: () => _selectFood(food),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pixel Digivolve',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pixel Digivolve',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
