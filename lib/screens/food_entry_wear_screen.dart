import 'package:flutter/material.dart';
import '../models/workout_buddy.dart';
import '../models/food_nutrition.dart';
import '../models/food_diary_entry.dart';
import '../services/database_service.dart';
import '../services/food_service.dart';
import '../services/fatsecret_service.dart';
import '../services/mock_food_service.dart';

/// Wear OS optimized food entry screen
/// - Page 1: Search screen
/// - Page 2: Results list (swipe left to see, swipe right to return)
class FoodEntryWearScreen extends StatefulWidget {
  final WorkoutBuddy workoutBuddy;
  final Function(Map<String, int>) onStatUpdate;

  const FoodEntryWearScreen({
    super.key,
    required this.workoutBuddy,
    required this.onStatUpdate,
  });

  @override
  State<FoodEntryWearScreen> createState() => _FoodEntryWearScreenState();
}

class _FoodEntryWearScreenState extends State<FoodEntryWearScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  
  static const bool _useMockData = false;
  late final FoodService _foodService = _useMockData 
      ? MockFoodService() 
      : FatSecretService();
  
  List<FoodSearchResult> _searchResults = [];
  FoodNutrition? _selectedNutrition;
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _searchFood() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _searchResults = [];
    });

    try {
      final results = await _foodService.searchFood(_searchController.text.trim());
      setState(() {
        _searchResults = results;
        _isLoading = false;
        if (results.isEmpty) {
          _message = 'No results';
        } else {
          // Auto-navigate to results page
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
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
        _selectedNutrition = nutrition;
        _isLoading = false;
      });
      
      // Navigate to confirmation page
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _confirmAndFeed() async {
    if (_selectedNutrition == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Save to database
      final entry = FoodDiaryEntry(
        foodName: _selectedNutrition!.foodName,
        calories: _selectedNutrition!.calories,
        protein: _selectedNutrition!.protein,
        carbs: _selectedNutrition!.carbs,
        fat: _selectedNutrition!.fat,
        fiber: _selectedNutrition!.fiber,
        servingSize: _selectedNutrition!.servingSize,
        timestamp: DateTime.now(),
      );
      await DatabaseService.instance.insertFoodEntry(entry);

      // Apply stat changes
      final statChanges = _selectedNutrition!.calculateStatImpact();
      final strengthGain = (statChanges['strength'] as num? ?? 0).toInt();
      final agilityGain = (statChanges['agility'] as num? ?? 0).toInt();
      final enduranceGain = (statChanges['endurance'] as num? ?? 0).toInt();
      
      widget.workoutBuddy.strength += strengthGain;
      widget.workoutBuddy.agility += agilityGain;
      widget.workoutBuddy.endurance += enduranceGain;
      widget.onStatUpdate(statChanges);

      // Show success message
      String feedbackMessage = '';
      if (strengthGain > 0) feedbackMessage += '+STR ';
      if (agilityGain > 0) feedbackMessage += '+AGI ';
      if (enduranceGain > 0) feedbackMessage += '+END ';

      setState(() {
        _isLoading = false;
        _message = 'Fed! $feedbackMessage';
      });

      // Navigate back after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          // Page changed between search (0) and results (1)
        },
        children: [
          // Page 0: Search
          _buildSearchPage(size),
          
          // Page 1: Results
          _buildResultsPage(size),
          
          // Page 2: Confirmation
          _buildConfirmationPage(size),
        ],
      ),
    );
  }

  Widget _buildSearchPage(Size size) {
    return SafeArea(
      child: Column(
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
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'FOOD DIARY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 28), // Balance for back button
              ],
            ),
          ),
          
          SizedBox(height: size.height * 0.05),
          
          // Search box (larger)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF9CB4A8), width: 2),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.045,
                ),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: size.width * 0.045,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF9CB4A8)),
                    onPressed: _searchFood,
                    iconSize: 20,
                  ),
                ),
                onSubmitted: (_) => _searchFood(),
              ),
            ),
          ),
          
          SizedBox(height: size.height * 0.04),
          
          // Loading or message
          if (_isLoading)
            const CircularProgressIndicator(
              color: Color(0xFF9CB4A8),
            )
          else if (_message.isNotEmpty && _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: size.width * 0.035,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          const Spacer(),
          
          // Swipe hint (only if has results)
          if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe for results',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: size.width * 0.03,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsPage(Size size) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'RESULTS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: size.width * 0.06,
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
          
          // Results list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9CB4A8),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No results',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: size.width * 0.04,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return GestureDetector(
                            onTap: () => _selectFood(result),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF9CB4A8).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result.foodName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size.width * 0.04,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          result.foodDescription,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: size.width * 0.028,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Success message
          if (_message.isNotEmpty && _searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                _message,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPage(Size size) {
    if (_selectedNutrition == null) {
      return const Center(child: Text('No food selected'));
    }

    final nutrition = _selectedNutrition!;
    
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'CONFIRM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: size.width * 0.06,
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
          
          // Food details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(
                    nutrition.foodName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nutrition.servingSize,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: size.width * 0.035,
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.03),
                  
                  // Nutrition facts
                  _buildNutritionRow('Calories', '${nutrition.calories.toStringAsFixed(0)} kcal', size),
                  _buildNutritionRow('Protein', '${nutrition.protein.toStringAsFixed(1)}g', size),
                  _buildNutritionRow('Carbs', '${nutrition.carbs.toStringAsFixed(1)}g', size),
                  _buildNutritionRow('Fat', '${nutrition.fat.toStringAsFixed(1)}g', size),
                  _buildNutritionRow('Fiber', '${nutrition.fiber.toStringAsFixed(1)}g', size),
                ],
              ),
            ),
          ),
          
          // Feed button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      _message,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                GestureDetector(
                  onTap: _isLoading ? null : _confirmAndFeed,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isLoading 
                          ? Colors.grey 
                          : const Color(0xFF9CB4A8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Text(
                            'FEED BUDDY',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: size.width * 0.04,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
