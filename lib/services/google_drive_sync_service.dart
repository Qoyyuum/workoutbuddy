import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:multi_cloud_storage/multi_cloud_storage.dart';
import 'package:multi_cloud_storage/cloud_storage_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/backup_data.dart';
import 'database_service.dart';

/// Service for syncing workout data with Google Drive
class GoogleDriveSyncService extends ChangeNotifier {
  static final GoogleDriveSyncService instance = GoogleDriveSyncService._init();
  
  CloudStorageProvider? _driveProvider;
  SyncStatus _status = SyncStatus(isConnected: false);
  Timer? _autoSyncTimer;
  
  static const String _backupFileName = 'workout_buddy_backup.json';
  static const String _appFolderPath = '/WorkoutBuddy';
  static const Duration _autoSyncInterval = Duration(minutes: 15);
  
  GoogleDriveSyncService._init();

  SyncStatus get status => _status;
  bool get isConnected => _status.isConnected;
  bool get isSyncing => _status.isSyncing;

  /// Connect to Google Drive
  Future<bool> connect() async {
    try {
      _updateStatus(_status.copyWith(isSyncing: true));
      
      // Connect to Google Drive
      _driveProvider = await MultiCloudStorage.connectToGoogleDrive();
      
      // Get user display name
      final userName = await _driveProvider!.loggedInUserDisplayName();
      
      // Ensure app folder exists
      await _ensureAppFolderExists();
      
      _updateStatus(SyncStatus(
        isConnected: true,
        userEmail: userName,
        isSyncing: false,
      ));
      
      // Start auto-sync
      _startAutoSync();
      
      return true;
    } catch (e) {
      _updateStatus(SyncStatus(
        isConnected: false,
        lastSyncError: 'Failed to connect: ${e.toString()}',
        isSyncing: false,
      ));
      return false;
    }
  }

  /// Disconnect from Google Drive
  Future<void> disconnect() async {
    try {
      _stopAutoSync();
      
      if (_driveProvider != null) {
        await _driveProvider!.logout();
      }
      
      _driveProvider = null;
      _updateStatus(SyncStatus(isConnected: false));
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Check if token is expired and reconnect if needed
  Future<bool> _ensureConnected() async {
    if (_driveProvider == null) {
      return await connect();
    }
    
    try {
      final isExpired = await _driveProvider!.tokenExpired();
      if (isExpired) {
        return await connect();
      }
      return true;
    } catch (e) {
      return await connect();
    }
  }

  /// Ensure app folder exists in Google Drive
  Future<void> _ensureAppFolderExists() async {
    if (_driveProvider == null) return;
    
    try {
      // Try to list files in the folder
      await _driveProvider!.listFiles(path: _appFolderPath);
    } catch (e) {
      // Folder doesn't exist, create it
      try {
        await _driveProvider!.createDirectory(_appFolderPath);
      } catch (createError) {
        debugPrint('Error creating app folder: $createError');
      }
    }
  }

  /// Backup current data to Google Drive
  Future<bool> backup() async {
    if (!await _ensureConnected()) {
      return false;
    }
    
    try {
      _updateStatus(_status.copyWith(isSyncing: true, lastSyncError: null));
      
      // Get all data from local database
      final db = DatabaseService.instance;
      
      // Get all food diary entries (last 90 days to keep backup size reasonable)
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
      final foodEntries = await db.getFoodEntriesByDateRange(
        ninetyDaysAgo,
        DateTime.now().add(const Duration(days: 1)),
      );
      
      // Get all user settings
      final settings = await _getAllSettings();
      
      // Create backup data
      final backup = BackupData(
        version: 1,
        createdAt: DateTime.now(),
        foodDiaryEntries: foodEntries,
        userSettings: settings,
        workoutBuddyData: await _getWorkoutBuddyData(),
      );
      
      // Save to temporary file
      final tempFile = await _saveToTempFile(backup);
      
      // Upload to Google Drive
      final remotePath = path.join(_appFolderPath, _backupFileName);
      await _driveProvider!.uploadFile(
        localPath: tempFile.path,
        remotePath: remotePath,
      );
      
      // Clean up temp file
      await tempFile.delete();
      
      _updateStatus(_status.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      _updateStatus(_status.copyWith(
        isSyncing: false,
        lastSyncError: 'Backup failed: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Restore data from Google Drive
  Future<bool> restore({
    SyncConflictResolution resolution = SyncConflictResolution.useRemote,
  }) async {
    if (!await _ensureConnected()) {
      return false;
    }
    
    try {
      _updateStatus(_status.copyWith(isSyncing: true, lastSyncError: null));
      
      // Download backup file
      final tempDir = await getTemporaryDirectory();
      final localPath = path.join(tempDir.path, 'restore_$_backupFileName');
      final remotePath = path.join(_appFolderPath, _backupFileName);
      
      await _driveProvider!.downloadFile(
        remotePath: remotePath,
        localPath: localPath,
      );
      
      // Read backup file
      final file = File(localPath);
      final jsonString = await file.readAsString();
      final backup = BackupData.fromJsonString(jsonString);
      
      // Restore data based on resolution strategy
      await _restoreData(backup, resolution);
      
      // Clean up temp file
      await file.delete();
      
      _updateStatus(_status.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      _updateStatus(_status.copyWith(
        isSyncing: false,
        lastSyncError: 'Restore failed: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Sync data (smart merge)
  Future<bool> sync() async {
    if (!await _ensureConnected()) {
      return false;
    }
    
    try {
      _updateStatus(_status.copyWith(isSyncing: true, lastSyncError: null));
      
      // Check if remote backup exists
      final remotePath = path.join(_appFolderPath, _backupFileName);
      bool remoteExists = false;
      
      try {
        await _driveProvider!.getFileMetadata(remotePath);
        remoteExists = true;
      } catch (e) {
        // File doesn't exist
        remoteExists = false;
      }
      
      if (!remoteExists) {
        // No remote backup, just upload current data
        return await backup();
      }
      
      // Download and merge
      final tempDir = await getTemporaryDirectory();
      final localPath = path.join(tempDir.path, 'sync_$_backupFileName');
      
      await _driveProvider!.downloadFile(
        remotePath: remotePath,
        localPath: localPath,
      );
      
      final file = File(localPath);
      final jsonString = await file.readAsString();
      final remoteBackup = BackupData.fromJsonString(jsonString);
      
      // Merge with local data (newest wins)
      await _restoreData(remoteBackup, SyncConflictResolution.merge);
      
      // Upload merged data back
      await backup();
      
      // Clean up
      await file.delete();
      
      _updateStatus(_status.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      _updateStatus(_status.copyWith(
        isSyncing: false,
        lastSyncError: 'Sync failed: ${e.toString()}',
      ));
      return false;
    }
  }

  /// Get backup info from Google Drive without downloading
  Future<BackupInfo?> getRemoteBackupInfo() async {
    if (!await _ensureConnected()) {
      return null;
    }
    
    try {
      final remotePath = path.join(_appFolderPath, _backupFileName);
      final metadata = await _driveProvider!.getFileMetadata(remotePath);
      
      return BackupInfo(
        fileName: metadata.name,
        size: metadata.size ?? 0,
        modifiedTime: metadata.modifiedTime ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Delete remote backup
  Future<bool> deleteRemoteBackup() async {
    if (!await _ensureConnected()) {
      return false;
    }
    
    try {
      final remotePath = path.join(_appFolderPath, _backupFileName);
      await _driveProvider!.deleteFile(remotePath);
      return true;
    } catch (e) {
      debugPrint('Error deleting remote backup: $e');
      return false;
    }
  }

  /// Start automatic sync
  void _startAutoSync() {
    _stopAutoSync();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (timer) {
      if (isConnected && !isSyncing) {
        sync();
      }
    });
  }

  /// Stop automatic sync
  void _stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Enable or disable auto-sync
  Future<void> setAutoSync(bool enabled) async {
    if (enabled && isConnected) {
      _startAutoSync();
      await DatabaseService.instance.saveSetting('auto_sync_enabled', 'true');
    } else {
      _stopAutoSync();
      await DatabaseService.instance.saveSetting('auto_sync_enabled', 'false');
    }
  }

  /// Check if auto-sync is enabled
  Future<bool> isAutoSyncEnabled() async {
    final value = await DatabaseService.instance.getSetting('auto_sync_enabled');
    return value == 'true';
  }

  // Helper methods

  void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<Map<String, String>> _getAllSettings() async {
    // This is a simplified version. In a real app, you'd query all settings
    final db = DatabaseService.instance;
    final settings = <String, String>{};
    
    // Get known settings
    final keys = ['auto_sync_enabled', 'calorie_goal', 'user_profile'];
    for (final key in keys) {
      final value = await db.getSetting(key);
      if (value != null) {
        settings[key] = value;
      }
    }
    
    return settings;
  }

  Future<String?> _getWorkoutBuddyData() async {
    // Get workout buddy data from settings
    return await DatabaseService.instance.getSetting('workout_buddy_data');
  }

  Future<File> _saveToTempFile(BackupData backup) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, _backupFileName));
    await file.writeAsString(backup.toJsonString());
    return file;
  }

  Future<void> _restoreData(
    BackupData backup,
    SyncConflictResolution resolution,
  ) async {
    final db = DatabaseService.instance;
    
    if (resolution == SyncConflictResolution.useRemote) {
      // Clear local data and restore from backup
      // Note: In production, you might want to implement a proper clear method
      
      // Restore food diary entries
      for (final entry in backup.foodDiaryEntries) {
        await db.insertFoodEntry(entry);
      }
      
      // Restore settings
      for (final entry in backup.userSettings.entries) {
        await db.saveSetting(entry.key, entry.value);
      }
      
      // Restore workout buddy data
      if (backup.workoutBuddyData != null) {
        await db.saveSetting('workout_buddy_data', backup.workoutBuddyData!);
      }
    } else if (resolution == SyncConflictResolution.merge) {
      // Merge strategy: Keep newer entries
      final localEntries = await db.getFoodEntriesByDateRange(
        DateTime.now().subtract(const Duration(days: 365)),
        DateTime.now().add(const Duration(days: 1)),
      );
      
      final localMap = {for (var e in localEntries) e.timestamp: e};
      
      // Add or update entries from backup
      for (final entry in backup.foodDiaryEntries) {
        final existing = localMap[entry.timestamp];
        if (existing == null) {
          // New entry, insert it
          await db.insertFoodEntry(entry);
        }
        // If exists and same timestamp, keep local (could be enhanced)
      }
      
      // Merge settings (backup wins for now)
      for (final entry in backup.userSettings.entries) {
        await db.saveSetting(entry.key, entry.value);
      }
    }
    // useLocal: do nothing, keep local data
  }

  @override
  void dispose() {
    _stopAutoSync();
    super.dispose();
  }
}
