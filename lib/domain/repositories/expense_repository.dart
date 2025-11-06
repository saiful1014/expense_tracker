import '../../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses();
  Future<List<Expense>> getExpensesByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Expense>> getExpensesByDate(DateTime date);
  Future<double> getTotalExpenses();
  Future<double> getTotalExpensesByDate(DateTime date);
  Future<double> getTotalExpensesByDateRange(DateTime startDate, DateTime endDate);
  Future<int> insertExpense(Expense expense);
  Future<void> deleteExpense(int id);
  Future<void> syncFromCloud();
  Future<void> deleteFromCloud(int id);
  Future<void> syncToCloud(Expense expense);
  Future<void> markAsSynced(int id);
}

