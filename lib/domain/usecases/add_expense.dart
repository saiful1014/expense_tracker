import '../../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../../services/cloud_sync_service.dart';

class AddExpense {
  final ExpenseRepository repository;
  final CloudSyncService cloudSync;

  AddExpense(this.repository, this.cloudSync);

  Future<int> call(Expense expense) async {
    // Save to local database (initially unsynced)
    final expenseId = await repository.insertExpense(expense);
    
    // Sync to cloud if signed in
    final isSignedIn = await cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        final savedExpense = expense.copyWith(id: expenseId, synced: false);
        await repository.syncToCloud(savedExpense);
        await repository.markAsSynced(expenseId);
        return expenseId;
      } catch (e) {
        // Expense remains unsynced, will be synced later when online
        throw Exception('Failed to sync to cloud: $e');
      }
    }
    
    return expenseId;
  }
}

