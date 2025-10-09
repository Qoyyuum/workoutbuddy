import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_diary_entry.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('workout_buddy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    // Food diary table
    await db.execute('''
      CREATE TABLE food_diary (
        id $idType,
        food_name $textType,
        calories $realType,
        protein $realType,
        carbs $realType,
        fat $realType,
        fiber $realType,
        serving_size $textType,
        timestamp $textType
      )
    ''');

    // User settings table (for calorie goals, etc.)
    await db.execute('''
      CREATE TABLE user_settings (
        id $idType,
        key $textType UNIQUE,
        value $textType
      )
    ''');
  }

  // Insert food diary entry
  Future<int> insertFoodEntry(FoodDiaryEntry entry) async {
    final db = await database;
    return await db.insert('food_diary', entry.toMap());
  }

  // Get today's food entries
  Future<List<FoodDiaryEntry>> getTodaysFoodEntries() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'food_diary',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => FoodDiaryEntry.fromMap(map)).toList();
  }

  // Get food entries for a date range
  Future<List<FoodDiaryEntry>> getFoodEntriesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'food_diary',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => FoodDiaryEntry.fromMap(map)).toList();
  }

  // Calculate today's total calories
  Future<double> getTodaysTotalCalories() async {
    final entries = await getTodaysFoodEntries();
    return entries.fold<double>(0.0, (sum, entry) => sum + entry.calories);
  }

  // Calculate today's macros
  Future<Map<String, double>> getTodaysMacros() async {
    final entries = await getTodaysFoodEntries();
    return {
      'calories': entries.fold<double>(0.0, (sum, e) => sum + e.calories),
      'protein': entries.fold<double>(0.0, (sum, e) => sum + e.protein),
      'carbs': entries.fold<double>(0.0, (sum, e) => sum + e.carbs),
      'fat': entries.fold<double>(0.0, (sum, e) => sum + e.fat),
      'fiber': entries.fold<double>(0.0, (sum, e) => sum + e.fiber),
    };
  }

  // Delete food entry
  Future<int> deleteFoodEntry(int id) async {
    final db = await database;
    return await db.delete(
      'food_diary',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save user setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get user setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
