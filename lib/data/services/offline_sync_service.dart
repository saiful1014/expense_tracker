import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_new_things/data/services/database_helper.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';

class OfflineSyncService {
  static final OfflineSyncService instance = OfflineSyncService._init();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService _cloudSync = CloudSyncService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  bool _isSyncing = false;

  OfflineSyncService._init();

  /// Initialize the sync service and listen for connectivity changes
  void initialize() {
    _connectivity.connectivityStream.listen((connectivityResults) async {
      final hasConnection = connectivityResults.contains(
            ConnectivityResult.mobile,
          ) ||
          connectivityResults.contains(ConnectivityResult.wifi) ||
          connectivityResults.contains(ConnectivityResult.ethernet);

      if (hasConnection && !_isSyncing) {
        await syncPendingItems();
      }
    });
  }

  /// Sync all pending items to cloud
  Future<void> syncPendingItems() async {
    if (_isSyncing) return;

    final isSignedIn = await _cloudSync.isSignedIn();
    if (!isSignedIn) return;

    final hasConnection = await _connectivity.hasInternetConnection();
    if (!hasConnection) return;

    _isSyncing = true;

    try {
      // Sync unsynced expenses
      final unsyncedExpenses = await _dbHelper.getUnsyncedExpenses();
      for (final expense in unsyncedExpenses) {
        try {
          await _cloudSync.syncExpenseToCloud(expense);
          await _dbHelper.markExpenseAsSynced(expense.id!);
          debugPrint('Synced expense: ${expense.id}');
        } catch (e) {
          debugPrint('Error syncing expense ${expense.id}: $e');
          // Continue with next item even if one fails
        }
      }

      // Sync unsynced borrow/lend transactions
      final unsyncedBorrowLend = await _dbHelper.getUnsyncedBorrowLend();
      for (final transaction in unsyncedBorrowLend) {
        try {
          await _cloudSync.syncBorrowLendToCloud(transaction);
          await _dbHelper.markBorrowLendAsSynced(transaction.id!);
          debugPrint('Synced borrow/lend: ${transaction.id}');
        } catch (e) {
          debugPrint('Error syncing borrow/lend ${transaction.id}: $e');
          // Continue with next item even if one fails
        }
      }

      debugPrint('Offline sync completed');
    } catch (e) {
      debugPrint('Error during offline sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Manually trigger sync (can be called from UI)
  Future<void> manualSync() async {
    await syncPendingItems();
  }
}

