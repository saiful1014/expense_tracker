import '../../models/borrow_lend.dart';
import '../repositories/borrow_lend_repository.dart';
import '../../services/cloud_sync_service.dart';

class AddBorrowLend {
  final BorrowLendRepository repository;
  final CloudSyncService cloudSync;

  AddBorrowLend(this.repository, this.cloudSync);

  Future<int> call(BorrowLend transaction) async {
    // Save to local database (initially unsynced)
    final transactionId = await repository.insertBorrowLend(transaction);
    
    // Sync to cloud if signed in
    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        final savedTransaction = transaction.copyWith(id: transactionId, synced: false);
        await repository.syncToCloud(savedTransaction);
        await repository.markAsSynced(transactionId);
        return transactionId;
      } catch (e) {
        // Transaction remains unsynced, will be synced later when online
        throw Exception('Failed to sync to cloud: $e');
      }
    }
    
    return transactionId;
  }
}

