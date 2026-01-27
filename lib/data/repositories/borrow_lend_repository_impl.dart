import '../../domain/repositories/borrow_lend_repository.dart';
import '../../models/borrow_lend.dart';
import '../../database/database_helper.dart';
import '../../services/cloud_sync_service.dart';

class BorrowLendRepositoryImpl implements BorrowLendRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService _cloudSync = CloudSyncService();
  
  CloudSyncService get cloudSync => _cloudSync;

  @override
  Future<List<BorrowLend>> getAllBorrowLend() async {
    return await _dbHelper.getAllBorrowLend();
  }

  @override
  Future<List<BorrowLend>> getBorrowLendByType(String type) async {
    return await _dbHelper.getBorrowLendByType(type);
  }

  @override
  Future<List<BorrowLend>> getCompletedBorrowLend() async {
    return await _dbHelper.getCompletedBorrowLend();
  }

  @override
  Future<double> getTotalBorrowed() async {
    return await _dbHelper.getTotalBorrowed();
  }

  @override
  Future<double> getTotalLent() async {
    return await _dbHelper.getTotalLent();
  }

  @override
  Future<int> insertBorrowLend(BorrowLend borrowLend) async {
    return await _dbHelper.insertBorrowLend(borrowLend);
  }

  @override
  Future<void> deleteBorrowLend(int id) async {
    await _dbHelper.deleteBorrowLend(id);
  }

  @override
  Future<void> updateBorrowLend(BorrowLend borrowLend) async {
    await _dbHelper.updateBorrowLend(borrowLend);
  }

  @override
  Future<void> markAsCompleted(int id) async {
    await _dbHelper.markBorrowLendAsCompleted(id);
  }

  @override
  Future<void> markAsPending(int id) async {
    await _dbHelper.markBorrowLendAsPending(id);
  }

  @override
  Future<void> syncFromCloud() async {
    final isSignedIn = await _cloudSync.isSignedIn();
    if (!isSignedIn) return;

    try {
      final cloudTransactions = await _cloudSync.getBorrowLendFromCloud();
      final localTransactions = await _dbHelper.getAllBorrowLend();

      for (final transaction in cloudTransactions) {
        final exists = localTransactions.any((local) => local.id == transaction.id);

        if (!exists) {
          final transactionId = await _dbHelper.insertBorrowLend(transaction);
          await _dbHelper.markBorrowLendAsSynced(transactionId);
          localTransactions.add(transaction.copyWith(id: transactionId, synced: true));
        } else {
          final transactionId = transaction.id;
          if (transactionId != null) {
            await _dbHelper.markBorrowLendAsSynced(transactionId);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to sync from cloud: $e');
    }
  }

  @override
  Future<void> deleteFromCloud(int id) async {
    await _cloudSync.deleteBorrowLendFromCloud(id);
  }

  @override
  Future<void> syncToCloud(BorrowLend borrowLend) async {
    await _cloudSync.syncBorrowLendToCloud(borrowLend);
  }

  @override
  Future<void> markAsSynced(int id) async {
    await _dbHelper.markBorrowLendAsSynced(id);
  }
}

