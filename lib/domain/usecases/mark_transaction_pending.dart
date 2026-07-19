import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/data/services/notification_service.dart';

class MarkTransactionPending {
  final BorrowLendRepository repository;

  MarkTransactionPending(this.repository);

  Future<void> call(int id) async {
    final transaction = await repository.markAsPendingAndGet(id);
    if (transaction != null) {
      if (transaction.dueDate != null) {
        final scheduledDate = DateTime(
          transaction.dueDate!.year,
          transaction.dueDate!.month,
          transaction.dueDate!.day,
          9, // 9:00 AM
        );
        await NotificationService.instance.scheduleDueDateNotification(
          id: id,
          title: transaction.type == 'borrow' ? 'Repayment due today' : 'Collect money today',
          body: transaction.type == 'borrow'
              ? 'You owe \$${transaction.amount.toStringAsFixed(2)} to ${transaction.personName}'
              : '${transaction.personName} owes you \$${transaction.amount.toStringAsFixed(2)}',
          scheduledDate: scheduledDate,
        );
      }
      await repository.syncToCloud(transaction);
      await repository.markAsSynced(id);
    }
  }
}

