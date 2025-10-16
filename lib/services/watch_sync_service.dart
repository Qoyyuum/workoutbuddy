import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import '../models/watch_data.dart';
import '../models/food_diary_entry.dart';
import 'database_service.dart';

/// Service for syncing data between phone and smartwatch
/// Uses Bluetooth for fast, battery-efficient communication
class WatchSyncService extends ChangeNotifier {
  static final WatchSyncService instance = WatchSyncService._init();
  
  final WatchConnectivity _watch = WatchConnectivity();
  WatchConnectivityStatus _status = WatchConnectivityStatus(
    isSupported: false,
    isPaired: false,
    isReachable: false,
  );
  
  StreamSubscription? _messageSubscription;
  StreamSubscription? _contextSubscription;
  bool _isInitialized = false;
  
  WatchSyncService._init();

  WatchConnectivityStatus get status => _status;
  bool get canSync => _status.canSync;
  bool get isInitialized => _isInitialized;

  /// Initialize watch connectivity
  Future<bool> initialize() async {
    if (_isInitialized) return _status.canSync;
    
    try {
      // Check if watches are supported on this platform
      final supported = await _watch.isSupported;
      if (!supported) {
        _updateStatus(_status.copyWith(isSupported: false));
        return false;
      }
      
      // Check if a watch is paired
      final paired = await _watch.isPaired;
      if (!paired) {
        _updateStatus(_status.copyWith(
          isSupported: true,
          isPaired: false,
        ));
        return false;
      }
      
      // Check if watch is reachable (connected)
      final reachable = await _watch.isReachable;
      
      _updateStatus(_status.copyWith(
        isSupported: true,
        isPaired: true,
        isReachable: reachable,
      ));
      
      // Set up message listeners
      _setupListeners();
      
      _isInitialized = true;
      
      // Initial sync if reachable
      if (reachable) {
        await syncToWatch();
      }
      
      return _status.canSync;
    } catch (e) {
      debugPrint('Error initializing watch connectivity: $e');
      _updateStatus(_status.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Set up listeners for incoming messages from watch
  void _setupListeners() {
    // Listen for messages (user actions on watch)
    _messageSubscription = _watch.messageStream.listen(
      (message) => _handleWatchMessage(message),
      onError: (error) => debugPrint('Watch message error: $error'),
    );
    
    // Listen for context updates (watch requesting sync)
    _contextSubscription = _watch.contextStream.listen(
      (context) => _handleContextUpdate(context),
      onError: (error) => debugPrint('Watch context error: $error'),
    );
  }

  /// Handle incoming message from watch
  Future<void> _handleWatchMessage(Map<String, dynamic> messageData) async {
    try {
      final watchMsg = WatchMessage.fromJson(messageData);
      
      switch (watchMsg.type) {
        case WatchMessageType.quickMeal:
          await _handleQuickMealLog(watchMsg.data);
          break;
          
        case WatchMessageType.syncRequest:
          await syncToWatch();
          break;
          
        case WatchMessageType.buddyFeed:
          await _handleBuddyFeed();
          break;
          
        case WatchMessageType.buddyTrain:
          await _handleBuddyTrain();
          break;
          
        case WatchMessageType.unknown:
          debugPrint('Unknown message type from watch');
          break;
      }
    } catch (e) {
      debugPrint('Error handling watch message: $e');
    }
  }

  /// Handle context update from watch
  Future<void> _handleContextUpdate(Map<String, dynamic> context) async {
    // Watch sent a context update, sync back latest data
    await syncToWatch();
  }

  /// Handle quick meal log from watch
  Future<void> _handleQuickMealLog(Map<String, dynamic> mealData) async {
    try {
      final entry = FoodDiaryEntry(
        foodName: mealData['name'] as String,
        calories: (mealData['calories'] as num).toDouble(),
        protein: (mealData['protein'] as num?)?.toDouble() ?? 0,
        carbs: (mealData['carbs'] as num?)?.toDouble() ?? 0,
        fat: (mealData['fat'] as num?)?.toDouble() ?? 0,
        fiber: (mealData['fiber'] as num?)?.toDouble() ?? 0,
        servingSize: mealData['serving_size'] as String? ?? '1 serving',
        timestamp: DateTime.now(),
      );
      
      // Save to database
      await DatabaseService.instance.insertFoodEntry(entry);
      
      // Immediately sync updated data back to watch
      await syncToWatch();
      
      debugPrint('✅ Meal logged from watch: ${entry.foodName}');
    } catch (e) {
      debugPrint('Error logging meal from watch: $e');
    }
  }

  /// Handle buddy feed action from watch
  Future<void> _handleBuddyFeed() async {
    // TODO: Implement buddy feed logic when WorkoutBuddy is integrated
    debugPrint('Buddy fed from watch');
    await syncToWatch();
  }

  /// Handle buddy train action from watch
  Future<void> _handleBuddyTrain() async {
    // TODO: Implement buddy train logic when WorkoutBuddy is integrated
    debugPrint('Buddy trained from watch');
    await syncToWatch();
  }

  /// Sync current data to watch
  Future<bool> syncToWatch() async {
    if (!canSync) {
      debugPrint('Cannot sync: Watch not reachable');
      return false;
    }
    
    try {
      // Gather data to sync
      final syncData = await _prepareWatchSyncData();
      
      // Update application context (persistent data on watch)
      await _watch.updateApplicationContext(syncData.toJson());
      
      _updateStatus(_status.copyWith(
        lastSync: DateTime.now(),
        error: null,
      ));
      
      debugPrint('✅ Synced to watch: ${syncData.estimatedSize} bytes');
      return true;
    } catch (e) {
      debugPrint('Error syncing to watch: $e');
      _updateStatus(_status.copyWith(error: e.toString()));
      return false;
    }
  }

  /// Send a quick message to watch (fire-and-forget)
  Future<bool> sendMessage(Map<String, dynamic> message) async {
    if (!canSync) return false;
    
    try {
      await _watch.sendMessage(message);
      return true;
    } catch (e) {
      debugPrint('Error sending message to watch: $e');
      return false;
    }
  }

  /// Prepare data package for watch
  Future<WatchSyncData> _prepareWatchSyncData() async {
    final db = DatabaseService.instance;
    
    // Get today's data
    final todayCalories = await db.getTodaysTotalCalories();
    final todayMacros = await db.getTodaysMacros();
    
    // Get calorie goal
    final calorieGoalStr = await db.getSetting('calorie_goal');
    final calorieGoal = calorieGoalStr != null 
        ? double.tryParse(calorieGoalStr) ?? 2200.0 
        : 2200.0;
    
    // Get recent meals (last 5 for watch display)
    final todayEntries = await db.getTodaysFoodEntries();
    final recentMeals = todayEntries
        .take(5)
        .map((entry) => WatchMealEntry(
              name: entry.foodName,
              calories: entry.calories.toInt(),
              timestamp: entry.timestamp,
            ))
        .toList();
    
    // Get buddy state (if available)
    final buddyState = await _getBuddyState();
    
    return WatchSyncData(
      todayCalories: todayCalories,
      calorieGoal: calorieGoal,
      todayMacros: todayMacros,
      recentMeals: recentMeals,
      buddyState: buddyState,
      lastSync: DateTime.now(),
    );
  }

  /// Get current buddy state for watch
  Future<WatchBuddyState?> _getBuddyState() async {
    try {
      // TODO: Implement when WorkoutBuddy persistence is added
      // For now, return null
      return null;
    } catch (e) {
      debugPrint('Error getting buddy state: $e');
      return null;
    }
  }

  /// Check and update reachability status
  Future<void> updateReachability() async {
    if (!_isInitialized) return;
    
    try {
      final reachable = await _watch.isReachable;
      if (reachable != _status.isReachable) {
        _updateStatus(_status.copyWith(isReachable: reachable));
        
        // If watch just became reachable, sync immediately
        if (reachable) {
          await syncToWatch();
        }
      }
    } catch (e) {
      debugPrint('Error updating reachability: $e');
    }
  }

  /// Get current watch application context
  Future<Map<String, dynamic>?> getWatchContext() async {
    try {
      return await _watch.applicationContext;
    } catch (e) {
      debugPrint('Error getting watch context: $e');
      return null;
    }
  }

  /// Enable/disable auto-sync
  Future<void> setAutoSync(bool enabled) async {
    await DatabaseService.instance.saveSetting(
      'watch_auto_sync_enabled',
      enabled.toString(),
    );
  }

  /// Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled() async {
    final value = await DatabaseService.instance.getSetting('watch_auto_sync_enabled');
    return value == 'true';
  }

  void _updateStatus(WatchConnectivityStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _contextSubscription?.cancel();
    super.dispose();
  }

  /// Helper method to check if watch needs sync
  bool shouldAutoSync() {
    if (!canSync) return false;
    
    final lastSync = _status.lastSync;
    if (lastSync == null) return true;
    
    // Auto-sync if last sync was more than 5 minutes ago
    final timeSinceLastSync = DateTime.now().difference(lastSync);
    return timeSinceLastSync.inMinutes >= 5;
  }

  /// Force refresh watch status
  Future<void> refreshStatus() async {
    await initialize();
    await updateReachability();
  }
}
