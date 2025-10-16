import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/watch_sync_service.dart';
import '../models/watch_data.dart';

/// Compact watch connectivity status indicator
class WatchStatusIndicator extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;
  
  const WatchStatusIndicator({
    super.key,
    this.showDetails = false,
    this.onTap,
  });

  @override
  State<WatchStatusIndicator> createState() => _WatchStatusIndicatorState();
}

class _WatchStatusIndicatorState extends State<WatchStatusIndicator> {
  final _watchService = WatchSyncService.instance;

  @override
  void initState() {
    super.initState();
    _watchService.addListener(_onStatusChanged);
    _initializeWatch();
  }

  @override
  void dispose() {
    _watchService.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeWatch() async {
    await _watchService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final status = _watchService.status;
    
    if (widget.showDetails) {
      return _buildDetailedStatus(status);
    } else {
      return _buildCompactStatus(status);
    }
  }

  Widget _buildCompactStatus(WatchConnectivityStatus status) {
    final icon = _getStatusIcon(status);
    final color = _getStatusColor(status);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (status.canSync) ...[
              const SizedBox(width: 4),
              Text(
                'Watch',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatus(WatchConnectivityStatus status) {
    final color = _getStatusColor(status);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getStatusIcon(status), color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status.statusMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (status.canSync)
                  IconButton(
                    icon: const Icon(Icons.sync, size: 20),
                    onPressed: () => _watchService.syncToWatch(),
                    tooltip: 'Sync now',
                  ),
              ],
            ),
            if (status.lastSync != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last sync: ${_formatLastSync(status.lastSync!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (status.error != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error: ${status.error}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(WatchConnectivityStatus status) {
    if (!status.isSupported) return Icons.watch_off;
    if (!status.isPaired) return Icons.watch_off;
    if (!status.isReachable) return Icons.watch_outlined;
    return Icons.watch;
  }

  Color _getStatusColor(WatchConnectivityStatus status) {
    if (status.canSync) return Colors.green;
    if (status.isPaired && !status.isReachable) return Colors.orange;
    return Colors.grey;
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(lastSync);
    }
  }
}

/// Full watch connectivity screen
class WatchConnectivityScreen extends StatefulWidget {
  const WatchConnectivityScreen({super.key});

  @override
  State<WatchConnectivityScreen> createState() => _WatchConnectivityScreenState();
}

class _WatchConnectivityScreenState extends State<WatchConnectivityScreen> {
  final _watchService = WatchSyncService.instance;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _watchService.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _watchService.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await _watchService.syncToWatch();
    setState(() => _isSyncing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Synced to watch'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshStatus() async {
    await _watchService.refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final status = _watchService.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Connectivity'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        status.canSync ? Icons.watch : Icons.watch_off,
                        color: status.canSync ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.statusMessage,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (status.lastSync != null)
                              Text(
                                'Last sync: ${DateFormat('MMM dd, HH:mm:ss').format(status.lastSync!)}',
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
                  if (status.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sync Button
          if (status.canSync)
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : _syncNow,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),

          const SizedBox(height: 24),

          // Information Section
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
                        'About Watch Sync',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Fast Bluetooth sync (< 100ms)\n'
                    '• Today\'s calories and macros\n'
                    '• Recent 5 meals\n'
                    '• Workout buddy status\n'
                    '• Two-way communication\n'
                    '• Battery efficient',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Platform Requirements
          Card(
            child: ExpansionTile(
              title: const Text('Requirements'),
              leading: const Icon(Icons.help_outline),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequirement(
                        'Supported Platform',
                        status.isSupported,
                      ),
                      _buildRequirement(
                        'Watch Paired',
                        status.isPaired,
                      ),
                      _buildRequirement(
                        'Watch Connected',
                        status.isReachable,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Watch and phone must have the same package name and be signed with the same key.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
