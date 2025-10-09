import '../services/calorie_calculator.dart';

class UserProfile {
  final String? name;
  final double? weightKg;
  final double? heightCm;
  final int? age;
  final bool? isMale;
  final ActivityLevel activityLevel;
  final FitnessGoal fitnessGoal;
  final double? customCalorieGoal;

  UserProfile({
    this.name,
    this.weightKg,
    this.heightCm,
    this.age,
    this.isMale,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.fitnessGoal = FitnessGoal.maintain,
    this.customCalorieGoal,
  });

  // Calculate calorie goal based on profile
  double getCalorieGoal() {
    if (customCalorieGoal != null) {
      return customCalorieGoal!;
    }

    // If we have complete profile data, calculate BMR/TDEE
    if (weightKg != null && heightCm != null && age != null && isMale != null) {
      final bmr = CalorieCalculator.calculateBMR(
        weightKg: weightKg!,
        heightCm: heightCm!,
        age: age!,
        isMale: isMale!,
      );
      final tdee = CalorieCalculator.calculateTDEE(
        bmr: bmr,
        activityLevel: activityLevel,
      );
      return CalorieCalculator.calculateCalorieGoal(
        tdee: tdee,
        goal: fitnessGoal,
      );
    }

    // Default if no profile data
    return CalorieCalculator.getDefaultCalorieGoal();
  }

  // Get recommended macros
  Map<String, double> getMacroGoals() {
    return CalorieCalculator.calculateMacros(
      calorieGoal: getCalorieGoal(),
      goal: fitnessGoal,
    );
  }

  // Check if profile is complete
  bool get isComplete =>
      weightKg != null && heightCm != null && age != null && isMale != null;

  // Convert to Map for database
  Map<String, String> toMap() {
    return {
      if (name != null) 'name': name!,
      if (weightKg != null) 'weight_kg': weightKg!.toString(),
      if (heightCm != null) 'height_cm': heightCm!.toString(),
      if (age != null) 'age': age!.toString(),
      if (isMale != null) 'is_male': isMale!.toString(),
      'activity_level': activityLevel.index.toString(),
      'fitness_goal': fitnessGoal.index.toString(),
      if (customCalorieGoal != null)
        'custom_calorie_goal': customCalorieGoal!.toString(),
    };
  }

  // Create from Map
  factory UserProfile.fromMap(Map<String, String> map) {
    return UserProfile(
      name: map['name'],
      weightKg: map['weight_kg'] != null ? double.tryParse(map['weight_kg']!) : null,
      heightCm: map['height_cm'] != null ? double.tryParse(map['height_cm']!) : null,
      age: map['age'] != null ? int.tryParse(map['age']!) : null,
      isMale: map['is_male'] != null ? map['is_male'] == 'true' : null,
      activityLevel: ActivityLevel.values[int.tryParse(map['activity_level'] ?? '2') ?? 2],
      fitnessGoal: FitnessGoal.values[int.tryParse(map['fitness_goal'] ?? '1') ?? 1],
      customCalorieGoal: map['custom_calorie_goal'] != null
          ? double.tryParse(map['custom_calorie_goal']!)
          : null,
    );
  }

  // Create copy with updated fields
  UserProfile copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    int? age,
    bool? isMale,
    ActivityLevel? activityLevel,
    FitnessGoal? fitnessGoal,
    double? customCalorieGoal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      isMale: isMale ?? this.isMale,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      customCalorieGoal: customCalorieGoal ?? this.customCalorieGoal,
    );
  }
}
