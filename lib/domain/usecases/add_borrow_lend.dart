import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/notification_service.dart';

class AddBorrowLend {
  final BorrowLendRepository repository;
  final CloudSyncService cloudSync;

  AddBorrowLend(this.repository, this.cloudSync);

  Future<int> call(BorrowLend transaction) async {
    // Save to local database (initially unsynced)
    final transactionId = await repository.insertBorrowLend(transaction);
    
    // Schedule notification if it has a due date
    if (transaction.dueDate != null && !transaction.completed) {
      final scheduledDate = DateTime(
        transaction.dueDate!.year,
        transaction.dueDate!.month,
        transaction.dueDate!.day,
        9, // 9:00 AM
      );
      await NotificationService.instance.scheduleDueDateNotification(
        id: transactionId,
        title: transaction.type == 'borrow' ? 'Repayment due today' : 'Collect money today',
        body: transaction.type == 'borrow'
            ? 'You owe \$${transaction.amount.toStringAsFixed(2)} to ${transaction.personName}'
            : '${transaction.personName} owes you \$${transaction.amount.toStringAsFixed(2)}',
        scheduledDate: scheduledDate,
      );
    }

    // Sync to cloud if signed in
    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        final savedTransaction = transaction.copyWith(id: transactionId, synced: false);
        await repository.syncToCloud(savedTransaction);
        await repository.markAsSynced(transactionId);
      } catch (e) {
        // Transaction remains unsynced, will be synced later when online
        print('Cloud sync failed during add transaction: $e');
      }
    }
    
    return transactionId;
  }
}

