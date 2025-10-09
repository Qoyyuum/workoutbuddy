class CalorieCalculator {
  // Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    if (isMale) {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  // Calculate Total Daily Energy Expenditure (TDEE)
  static double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    return bmr * activityLevel.multiplier;
  }

  // Calculate calorie goal based on fitness goal
  static double calculateCalorieGoal({
    required double tdee,
    required FitnessGoal goal,
  }) {
    switch (goal) {
      case FitnessGoal.lose:
        return tdee - 500; // 500 calorie deficit for ~0.5kg/week loss
      case FitnessGoal.maintain:
        return tdee;
      case FitnessGoal.gain:
        return tdee + 300; // 300 calorie surplus for lean muscle gain
    }
  }

  // Calculate recommended macros based on goal
  static Map<String, double> calculateMacros({
    required double calorieGoal,
    required FitnessGoal goal,
  }) {
    double proteinGrams;
    double fatGrams;
    double carbsGrams;

    switch (goal) {
      case FitnessGoal.lose:
        // High protein, moderate fat, lower carbs
        proteinGrams = calorieGoal * 0.35 / 4; // 35% protein (4 cal/g)
        fatGrams = calorieGoal * 0.30 / 9; // 30% fat (9 cal/g)
        carbsGrams = calorieGoal * 0.35 / 4; // 35% carbs (4 cal/g)
        break;
      case FitnessGoal.maintain:
        // Balanced macros
        proteinGrams = calorieGoal * 0.30 / 4; // 30% protein
        fatGrams = calorieGoal * 0.30 / 9; // 30% fat
        carbsGrams = calorieGoal * 0.40 / 4; // 40% carbs
        break;
      case FitnessGoal.gain:
        // High carbs, moderate protein, lower fat
        proteinGrams = calorieGoal * 0.25 / 4; // 25% protein
        fatGrams = calorieGoal * 0.25 / 9; // 25% fat
        carbsGrams = calorieGoal * 0.50 / 4; // 50% carbs
        break;
    }

    return {
      'protein': proteinGrams,
      'carbs': carbsGrams,
      'fat': fatGrams,
    };
  }

  // Get default calorie goal (if no user profile set)
  static double getDefaultCalorieGoal() {
    // Average male TDEE for moderate activity
    return 2200;
  }
}

enum ActivityLevel {
  sedentary(1.2, 'Sedentary (little or no exercise)'),
  lightlyActive(1.375, 'Lightly Active (1-3 days/week)'),
  moderatelyActive(1.55, 'Moderately Active (3-5 days/week)'),
  veryActive(1.725, 'Very Active (6-7 days/week)'),
  extremelyActive(1.9, 'Extremely Active (athlete)');

  final double multiplier;
  final String description;
  const ActivityLevel(this.multiplier, this.description);
}

enum FitnessGoal {
  lose('Lose Weight'),
  maintain('Maintain Weight'),
  gain('Gain Muscle');

  final String description;
  const FitnessGoal(this.description);
}
