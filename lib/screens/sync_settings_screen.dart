import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/google_drive_sync_service.dart';
import '../models/backup_data.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _syncService = GoogleDriveSyncService.instance;
  bool _autoSyncEnabled = false;
  BackupInfo? _remoteBackupInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _syncService.addListener(_onSyncStatusChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncStatusChanged);
    super.dispose();
  }

  void _onSyncStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    final autoSync = await _syncService.isAutoSyncEnabled();
    final backupInfo = await _syncService.getRemoteBackupInfo();
    
    if (mounted) {
      setState(() {
        _autoSyncEnabled = autoSync;
        _remoteBackupInfo = backupInfo;
      });
    }
  }

  Future<void> _connectToGoogleDrive() async {
    setState(() => _isLoading = true);
    
    final success = await _syncService.connect();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connected to Google Drive'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${_syncService.status.lastSyncError ?? "Failed to connect"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text(
          'Your data will remain on your device and Google Drive. '
          'You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _syncService.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from Google Drive')),
        );
      }
    }
  }

  Future<void> _backup() async {
    setState(() => _isLoading = true);
    final success = await _syncService.backup();
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backup completed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${_syncService.status.lastSyncError ?? "Backup failed"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    final strategy = await showDialog<SyncConflictResolution>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose how to handle existing data:'),
            const SizedBox(height: 16),
            _buildStrategyOption(
              'Replace Local Data',
              'Delete local data and restore from backup',
              SyncConflictResolution.useRemote,
              context,
            ),
            _buildStrategyOption(
              'Merge Data',
              'Keep both and merge (newest entries win)',
              SyncConflictResolution.merge,
              context,
            ),
            _buildStrategyOption(
              'Keep Local',
              'Cancel and keep current data',
              SyncConflictResolution.useLocal,
              context,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (strategy != null && strategy != SyncConflictResolution.useLocal) {
      setState(() => _isLoading = true);
      final success = await _syncService.restore(resolution: strategy);
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Restore completed'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${_syncService.status.lastSyncError ?? "Restore failed"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildStrategyOption(
    String title,
    String description,
    SyncConflictResolution strategy,
    BuildContext context,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.pop(context, strategy),
    );
  }

  Future<void> _sync() async {
    setState(() => _isLoading = true);
    final success = await _syncService.sync();
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sync completed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${_syncService.status.lastSyncError ?? "Sync failed"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRemoteBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text(
          'This will permanently delete your backup from Google Drive. '
          'Your local data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _syncService.deleteRemoteBackup();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup deleted')),
          );
          _loadSettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete backup'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _syncService.status;
    final isConnected = status.isConnected;
    final isSyncing = status.isSyncing || _isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Sync'),
        backgroundColor: Colors.blue[700],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Connection Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.cloud_done : Icons.cloud_off,
                        color: isConnected ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected ? 'Connected' : 'Not Connected',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (status.userEmail != null)
                              Text(
                                status.userEmail!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isConnected)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isSyncing ? null : _connectToGoogleDrive,
                        icon: const Icon(Icons.login),
                        label: const Text('Connect to Google Drive'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: isSyncing ? null : _disconnect,
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            ),
          ),

          if (isConnected) ...[
            const SizedBox(height: 16),

            // Last Sync Info
            Card(
              child: ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Last Sync'),
                subtitle: Text(
                  status.lastSyncTime != null
                      ? DateFormat('MMM dd, yyyy HH:mm').format(status.lastSyncTime!)
                      : 'Never',
                ),
              ),
            ),

            // Remote Backup Info
            if (_remoteBackupInfo != null) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud),
                  title: const Text('Remote Backup'),
                  subtitle: Text(
                    '${_remoteBackupInfo!.readableSize} • '
                    '${DateFormat('MMM dd, yyyy').format(_remoteBackupInfo!.modifiedTime)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: isSyncing ? null : _deleteRemoteBackup,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Auto-Sync Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Auto-Sync'),
                subtitle: const Text('Automatically sync every 15 minutes'),
                value: _autoSyncEnabled,
                onChanged: isSyncing
                    ? null
                    : (value) async {
                        await _syncService.setAutoSync(value);
                        setState(() => _autoSyncEnabled = value);
                      },
                secondary: const Icon(Icons.sync_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            const Text(
              'Manual Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: isSyncing ? null : _sync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: isSyncing ? null : _backup,
              icon: const Icon(Icons.backup),
              label: const Text('Backup to Drive'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: isSyncing ? null : _restore,
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Drive'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

            const SizedBox(height: 24),

            // Info Section
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'About Sync',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Your data is stored securely in your Google Drive\n'
                      '• Only you have access to your workout data\n'
                      '• Sync works across all your devices\n'
                      '• Last 90 days of data is backed up\n'
                      '• Auto-sync runs in the background',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            if (status.lastSyncError != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status.lastSyncError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
