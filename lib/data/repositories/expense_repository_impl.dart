import '../../domain/repositories/expense_repository.dart';
import '../../models/expense.dart';
import '../../database/database_helper.dart';
import '../../services/cloud_sync_service.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService _cloudSync = CloudSyncService();
  
  CloudSyncService get cloudSync => _cloudSync;

  @override
  Future<List<Expense>> getExpenses() async {
    return await _dbHelper.getAllExpenses();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    return await _dbHelper.getExpensesByDateRange(startDate, endDate);
  }

  @override
  Future<List<Expense>> getExpensesByDate(DateTime date) async {
    return await _dbHelper.getExpensesByDate(date);
  }

  @override
  Future<double> getTotalExpenses() async {
    return await _dbHelper.getTotalExpenses();
  }

  @override
  Future<double> getTotalExpensesByDate(DateTime date) async {
    return await _dbHelper.getTotalExpensesByDate(date);
  }

  @override
  Future<double> getTotalExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    return await _dbHelper.getTotalExpensesByDateRange(startDate, endDate);
  }

  @override
  Future<int> insertExpense(Expense expense) async {
    return await _dbHelper.insertExpense(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
  }

  @override
  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
  }

  @override
  Future<void> syncFromCloud() async {
    final isSignedIn = await _cloudSync.isSignedIn();
    if (!isSignedIn) return;

    try {
      final cloudExpenses = await _cloudSync.getExpensesFromCloud();
      for (final expense in cloudExpenses) {
        final localExpenses = await _dbHelper.getAllExpenses();
        final exists = localExpenses.any((e) => e.id == expense.id);
        
        if (!exists) {
          final expenseId = await _dbHelper.insertExpense(expense);
          await _dbHelper.markExpenseAsSynced(expenseId);
        } else {
          await _dbHelper.markExpenseAsSynced(expense.id!);
        }
      }
    } catch (e) {
      throw Exception('Failed to sync from cloud: $e');
    }
  }

  @override
  Future<void> deleteFromCloud(int id) async {
    await _cloudSync.deleteExpenseFromCloud(id);
  }

  @override
  Future<void> syncToCloud(Expense expense) async {
    await _cloudSync.syncExpenseToCloud(expense);
  }

  @override
  Future<void> markAsSynced(int id) async {
    await _dbHelper.markExpenseAsSynced(id);
  }
}

