import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/notification_service.dart';

class UpdateBorrowLend {
  final BorrowLendRepository repository;
  final CloudSyncService cloudSync;

  UpdateBorrowLend(this.repository, this.cloudSync);

  Future<void> call(BorrowLend borrowLend) async {
    if (borrowLend.id == null) {
      throw ArgumentError('Borrow/Lend ID must not be null for update');
    }

    await repository.updateBorrowLend(borrowLend.copyWith(synced: false));

    // Manage notifications: Cancel old, schedule new if active
    await NotificationService.instance.cancelNotification(borrowLend.id!);
    if (borrowLend.dueDate != null && !borrowLend.completed) {
      final scheduledDate = DateTime(
        borrowLend.dueDate!.year,
        borrowLend.dueDate!.month,
        borrowLend.dueDate!.day,
        9, // 9:00 AM
      );
      await NotificationService.instance.scheduleDueDateNotification(
        id: borrowLend.id!,
        title: borrowLend.type == 'borrow' ? 'Repayment due today' : 'Collect money today',
        body: borrowLend.type == 'borrow'
            ? 'You owe \$${borrowLend.amount.toStringAsFixed(2)} to ${borrowLend.personName}'
            : '${borrowLend.personName} owes you \$${borrowLend.amount.toStringAsFixed(2)}',
        scheduledDate: scheduledDate,
      );
    }

    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        await repository.syncToCloud(borrowLend.copyWith(synced: false));
        await repository.markAsSynced(borrowLend.id!);
      } catch (e) {
        print('Cloud sync failed during update transaction: $e');
      }
    }
  }
}

