import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/data/services/notification_service.dart';

class MarkTransactionCompleted {
  final BorrowLendRepository repository;

  MarkTransactionCompleted(this.repository);

  Future<void> call(int id) async {
    // Cancel scheduled reminder
    await NotificationService.instance.cancelNotification(id);
    final transaction = await repository.markAsCompletedAndGet(id);
    if (transaction != null) {
      await repository.syncToCloud(transaction);
      await repository.markAsSynced(id);
    }
  }
}

