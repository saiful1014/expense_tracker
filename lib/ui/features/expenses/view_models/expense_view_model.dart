import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/delete_expense.dart';

class ExpenseController extends ChangeNotifier {
  final ExpenseRepository repository;
  final GetExpenses getExpenses;
  final DeleteExpense deleteExpense;

  ExpenseController(this.repository, this.getExpenses, this.deleteExpense);

  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;
  double _todayExpenses = 0.0;
  double _selectedDateTotal = 0.0;
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  double get totalExpenses => _totalExpenses;
  double get todayExpenses => _todayExpenses;
  double get selectedDateTotal => _selectedDateTotal;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get errorMessage => _errorMessage;

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sync from cloud
      await repository.syncFromCloud();
      
      // Load expenses
      final expenses = await getExpenses(startDate: _startDate, endDate: _endDate);
      final total = await repository.getTotalExpenses();
      final today = await repository.getTotalExpensesByDate(DateTime.now());
      
      double selectedTotal = 0.0;
      if (_startDate != null && _endDate != null) {
        selectedTotal = await repository.getTotalExpensesByDateRange(_startDate!, _endDate!);
      }

      _expenses = expenses;
      _totalExpenses = total;
      _todayExpenses = today;
      _selectedDateTotal = selectedTotal;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDateRange(DateTime? startDate, DateTime? endDate) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadExpenses();
  }

  void clearDateFilter() {
    _startDate = null;
    _endDate = null;
    loadExpenses();
  }

  Future<bool> canDelete() async {
    return await deleteExpense.canDelete();
  }

  Future<void> delete(int id) async {
    try {
      await deleteExpense.call(id);
      await loadExpenses();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

