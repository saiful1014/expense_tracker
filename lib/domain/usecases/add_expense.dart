import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';

class AddExpense {
  final ExpenseRepository repository;
  final CloudSyncService cloudSync;

  AddExpense(this.repository, this.cloudSync);

  Future<int> call(Expense expense) async {
    final expenseToSave = expense.isRecurring && expense.lastProcessed == null
        ? expense.copyWith(lastProcessed: DateTime.now())
        : expense;

    // Save to local database (initially unsynced)
    final expenseId = await repository.insertExpense(expenseToSave);
    
    // Sync to cloud if signed in
    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        final savedExpense = expenseToSave.copyWith(id: expenseId, synced: false);
        await repository.syncToCloud(savedExpense);
        await repository.markAsSynced(expenseId);
      } catch (e) {
        // Expense remains unsynced, will be synced later when online
        print('Cloud sync failed during add expense: $e');
      }
    }
    
    return expenseId;
  }
}

