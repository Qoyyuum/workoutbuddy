class FoodDiaryEntry {
  final int? id;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String servingSize;
  final DateTime timestamp;

  FoodDiaryEntry({
    this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.servingSize,
    required this.timestamp,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'serving_size': servingSize,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from Map
  factory FoodDiaryEntry.fromMap(Map<String, dynamic> map) {
    return FoodDiaryEntry(
      id: map['id'] as int?,
      foodName: map['food_name'] as String,
      calories: map['calories'] as double,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
      fiber: map['fiber'] as double,
      servingSize: map['serving_size'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
