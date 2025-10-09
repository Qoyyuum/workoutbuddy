class FoodNutrition {
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String servingSize;

  FoodNutrition({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.servingSize,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    // FatSecret API response format
    final serving = json['servings']?['serving'];
    final servingData = serving is List ? serving[0] : serving;
    
    return FoodNutrition(
      foodName: json['food_name'] ?? servingData['food_description']?.split(' - ')[0] ?? 'Unknown',
      calories: double.tryParse(servingData['calories']?.toString() ?? '0') ?? 0,
      protein: double.tryParse(servingData['protein']?.toString() ?? '0') ?? 0,
      carbs: double.tryParse(servingData['carbohydrate']?.toString() ?? '0') ?? 0,
      fat: double.tryParse(servingData['fat']?.toString() ?? '0') ?? 0,
      fiber: double.tryParse(servingData['fiber']?.toString() ?? '0') ?? 0,
      servingSize: servingData['serving_description'] ?? '1 serving',
    );
  }

  // Calculate if this food is "healthy" based on nutritional profile
  bool get isHealthy {
    // High protein, low sugar, good fiber
    final proteinRatio = calories > 0 ? (protein * 4) / calories : 0;
    final fiberGood = fiber >= 3;
    
    return proteinRatio > 0.25 || fiberGood;
  }

  // Calculate stat impacts on WorkoutBuddy
  Map<String, int> calculateStatImpact() {
    int healthImpact = 0;
    int strengthImpact = 0;
    int happinessImpact = 5; // Eating always makes you a bit happy

    // High protein = strength boost
    if (protein >= 20) {
      strengthImpact += 3;
    } else if (protein >= 10) {
      strengthImpact += 1;
    }

    // Balanced meal = health boost
    if (isHealthy) {
      healthImpact += 5;
      happinessImpact += 5;
    } else {
      // Junk food penalty
      healthImpact -= 3;
    }

    // Very high calorie meal (overeating)
    if (calories > 800) {
      healthImpact -= 5;
      happinessImpact -= 3;
    }

    return {
      'health': healthImpact,
      'strength': strengthImpact,
      'happiness': happinessImpact,
    };
  }

  @override
  String toString() {
    return 'FoodNutrition(name: $foodName, cal: $calories, protein: ${protein}g, carbs: ${carbs}g, fat: ${fat}g)';
  }
}

class FoodSearchResult {
  final String foodId;
  final String foodName;
  final String foodDescription;

  FoodSearchResult({
    required this.foodId,
    required this.foodName,
    required this.foodDescription,
  });

  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      foodId: json['food_id']?.toString() ?? '',
      foodName: json['food_name'] ?? 'Unknown',
      foodDescription: json['food_description'] ?? '',
    );
  }
}
