import '../../models/borrow_lend.dart';
import '../repositories/borrow_lend_repository.dart';
import '../../services/cloud_sync_service.dart';

class UpdateBorrowLend {
  final BorrowLendRepository repository;
  final CloudSyncService cloudSync;

  UpdateBorrowLend(this.repository, this.cloudSync);

  Future<void> call(BorrowLend borrowLend) async {
    if (borrowLend.id == null) {
      throw ArgumentError('Borrow/Lend ID must not be null for update');
    }

    await repository.updateBorrowLend(borrowLend.copyWith(synced: false));

    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        await repository.syncToCloud(borrowLend.copyWith(synced: false));
        await repository.markAsSynced(borrowLend.id!);
      } catch (e) {
        throw Exception('Failed to sync to cloud: $e');
      }
    }
  }
}

