import 'package:flutter/foundation.dart';
import '../models/food_nutrition.dart';
import 'food_service.dart';

/// Mock food service for testing without FatSecret API
class MockFoodService implements FoodService {
  // Mock food database
  static final List<Map<String, dynamic>> _mockFoods = [
    {
      'food_id': '1',
      'food_name': 'Chicken Breast',
      'food_description': 'Per 100g - Calories: 165kcal | Fat: 3.6g | Carbs: 0g | Protein: 31g',
      'calories': 165,
      'protein': 31.0,
      'carbohydrate': 0.0,
      'fat': 3.6,
      'fiber': 0.0,
      'sugar': 0.0,
    },
    {
      'food_id': '2',
      'food_name': 'Brown Rice',
      'food_description': 'Per 100g - Calories: 111kcal | Fat: 0.9g | Carbs: 23g | Protein: 2.6g',
      'calories': 111,
      'protein': 2.6,
      'carbohydrate': 23.0,
      'fat': 0.9,
      'fiber': 1.8,
      'sugar': 0.4,
    },
    {
      'food_id': '3',
      'food_name': 'Egg (Large)',
      'food_description': 'Per 1 egg - Calories: 72kcal | Fat: 5g | Carbs: 0.4g | Protein: 6.3g',
      'calories': 72,
      'protein': 6.3,
      'carbohydrate': 0.4,
      'fat': 5.0,
      'fiber': 0.0,
      'sugar': 0.4,
    },
    {
      'food_id': '4',
      'food_name': 'Salmon Fillet',
      'food_description': 'Per 100g - Calories: 206kcal | Fat: 13g | Carbs: 0g | Protein: 22g',
      'calories': 206,
      'protein': 22.0,
      'carbohydrate': 0.0,
      'fat': 13.0,
      'fiber': 0.0,
      'sugar': 0.0,
    },
    {
      'food_id': '5',
      'food_name': 'Broccoli',
      'food_description': 'Per 100g - Calories: 34kcal | Fat: 0.4g | Carbs: 7g | Protein: 2.8g',
      'calories': 34,
      'protein': 2.8,
      'carbohydrate': 7.0,
      'fat': 0.4,
      'fiber': 2.6,
      'sugar': 1.7,
    },
    {
      'food_id': '6',
      'food_name': 'Sweet Potato',
      'food_description': 'Per 100g - Calories: 86kcal | Fat: 0.1g | Carbs: 20g | Protein: 1.6g',
      'calories': 86,
      'protein': 1.6,
      'carbohydrate': 20.0,
      'fat': 0.1,
      'fiber': 3.0,
      'sugar': 4.2,
    },
    {
      'food_id': '7',
      'food_name': 'Greek Yogurt',
      'food_description': 'Per 100g - Calories: 97kcal | Fat: 5g | Carbs: 3.6g | Protein: 10g',
      'calories': 97,
      'protein': 10.0,
      'carbohydrate': 3.6,
      'fat': 5.0,
      'fiber': 0.0,
      'sugar': 3.6,
    },
    {
      'food_id': '8',
      'food_name': 'Banana',
      'food_description': 'Per 100g - Calories: 89kcal | Fat: 0.3g | Carbs: 23g | Protein: 1.1g',
      'calories': 89,
      'protein': 1.1,
      'carbohydrate': 23.0,
      'fat': 0.3,
      'fiber': 2.6,
      'sugar': 12.2,
    },
    {
      'food_id': '9',
      'food_name': 'Almonds',
      'food_description': 'Per 100g - Calories: 579kcal | Fat: 50g | Carbs: 22g | Protein: 21g',
      'calories': 579,
      'protein': 21.0,
      'carbohydrate': 22.0,
      'fat': 50.0,
      'fiber': 12.5,
      'sugar': 4.4,
    },
    {
      'food_id': '10',
      'food_name': 'Oatmeal',
      'food_description': 'Per 100g - Calories: 389kcal | Fat: 6.9g | Carbs: 66g | Protein: 17g',
      'calories': 389,
      'protein': 17.0,
      'carbohydrate': 66.0,
      'fat': 6.9,
      'fiber': 10.6,
      'sugar': 0.0,
    },
    {
      'food_id': '11',
      'food_name': 'Pizza (Pepperoni)',
      'food_description': 'Per slice - Calories: 298kcal | Fat: 12g | Carbs: 36g | Protein: 12g',
      'calories': 298,
      'protein': 12.0,
      'carbohydrate': 36.0,
      'fat': 12.0,
      'fiber': 2.0,
      'sugar': 4.0,
    },
    {
      'food_id': '12',
      'food_name': 'French Fries',
      'food_description': 'Per 100g - Calories: 312kcal | Fat: 15g | Carbs: 41g | Protein: 3.4g',
      'calories': 312,
      'protein': 3.4,
      'carbohydrate': 41.0,
      'fat': 15.0,
      'fiber': 3.8,
      'sugar': 0.2,
    },
    {
      'food_id': '13',
      'food_name': 'Chicken Rice',
      'food_description': 'Per serving - Calories: 450kcal | Fat: 14g | Carbs: 52g | Protein: 28g',
      'calories': 450,
      'protein': 28.0,
      'carbohydrate': 52.0,
      'fat': 14.0,
      'fiber': 2.0,
      'sugar': 1.5,
    },
    {
      'food_id': '14',
      'food_name': 'Protein Shake',
      'food_description': 'Per scoop - Calories: 120kcal | Fat: 2g | Carbs: 3g | Protein: 24g',
      'calories': 120,
      'protein': 24.0,
      'carbohydrate': 3.0,
      'fat': 2.0,
      'fiber': 1.0,
      'sugar': 1.0,
    },
    {
      'food_id': '15',
      'food_name': 'Burger (Fast Food)',
      'food_description': 'Per burger - Calories: 540kcal | Fat: 26g | Carbs: 48g | Protein: 25g',
      'calories': 540,
      'protein': 25.0,
      'carbohydrate': 48.0,
      'fat': 26.0,
      'fiber': 2.5,
      'sugar': 9.0,
    },
  ];

  @override
  Future<List<FoodSearchResult>> searchFood(String query) async {
    debugPrint('🔍 [MOCK] Searching for food: "$query"');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Filter foods based on query
    final lowerQuery = query.toLowerCase();
    final results = _mockFoods
        .where((food) => food['food_name'].toString().toLowerCase().contains(lowerQuery))
        .map((food) => FoodSearchResult(
              foodId: food['food_id'] as String,
              foodName: food['food_name'] as String,
              foodDescription: food['food_description'] as String,
            ))
        .toList();

    debugPrint('✅ [MOCK] Found ${results.length} foods');
    return results;
  }

  @override
  Future<FoodNutrition?> getFoodNutrition(String foodId) async {
    debugPrint('🔍 [MOCK] Getting nutrition for food ID: $foodId');
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final food = _mockFoods.firstWhere(
      (f) => f['food_id'] == foodId,
      orElse: () => {},
    );

    if (food.isEmpty) {
      debugPrint('❌ [MOCK] Food not found');
      return null;
    }

    debugPrint('✅ [MOCK] Nutrition data retrieved');
    return FoodNutrition(
      foodName: food['food_name'] as String,
      calories: (food['calories'] as num).toDouble(),
      protein: food['protein'] as double,
      carbs: food['carbohydrate'] as double,
      fat: food['fat'] as double,
      fiber: food['fiber'] as double,
      servingSize: '100g',
    );
  }
}
