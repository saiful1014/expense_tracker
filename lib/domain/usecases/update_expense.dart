import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';

class UpdateExpense {
  final ExpenseRepository repository;
  final CloudSyncService cloudSync;

  UpdateExpense(this.repository, this.cloudSync);

  Future<void> call(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Expense ID must not be null for update');
    }

    await repository.updateExpense(expense.copyWith(synced: false));

    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        await repository.syncToCloud(expense.copyWith(synced: false));
        await repository.markAsSynced(expense.id!);
      } catch (e) {
        print('Cloud sync failed during update expense: $e');
      }
    }
  }
}

