import 'package:flutter/material.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';

class SyncStatusBottomSheet extends StatelessWidget {
  final SyncStatus syncStatus;
  final int unsyncedCount;
  final VoidCallback onSyncNow;
  final VoidCallback onConfigure;

  const SyncStatusBottomSheet({
    super.key,
    required this.syncStatus,
    required this.unsyncedCount,
    required this.onSyncNow,
    required this.onConfigure,
  });

  Widget _buildSyncStatusIndicator(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      case SyncStatus.synced:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case SyncStatus.pendingSync:
        return const Icon(Icons.cloud_upload, color: Colors.orange, size: 28);
      case SyncStatus.notSignedIn:
        return const Icon(Icons.cloud_off, color: Colors.grey, size: 28);
      case SyncStatus.error:
        return const Icon(Icons.error, color: Colors.red, size: 28);
    }
  }

  String _getSyncStatusMessage(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing data...';
      case SyncStatus.synced:
        return 'All data is up to date';
      case SyncStatus.pendingSync:
        return 'Pending sync (offline)';
      case SyncStatus.notSignedIn:
        return 'Sync disabled (not signed in)';
      case SyncStatus.error:
        return 'Sync failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cloud Sync Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSyncStatusIndicator(syncStatus),
                const SizedBox(width: 12),
                Text(
                  _getSyncStatusMessage(syncStatus),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (syncStatus == SyncStatus.pendingSync && unsyncedCount > 0)
              Text(
                'You have $unsyncedCount unsynced transactions stored locally.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSyncNow,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
