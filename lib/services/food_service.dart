// Provides both FoodNutrition and FoodSearchResult
import '../models/food_nutrition.dart';

/// Abstract interface for food search and nutrition services
/// Implemented by MockFoodService and FatSecretService
abstract class FoodService {
  /// Search for foods matching the given query
  /// Returns a list of food search results
  Future<List<FoodSearchResult>> searchFood(String query);
  
  /// Get detailed nutrition information for a specific food
  /// Returns nutrition data or null if not found
  Future<FoodNutrition?> getFoodNutrition(String foodId);
}
