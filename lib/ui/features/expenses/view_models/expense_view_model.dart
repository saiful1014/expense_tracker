import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';
import 'package:test_new_things/domain/usecases/get_expenses.dart';
import 'package:test_new_things/domain/usecases/delete_expense.dart';
import 'package:test_new_things/domain/usecases/process_recurring_expenses.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/database_helper.dart';

enum SyncStatus {
  synced,
  syncing,
  pendingSync,
  notSignedIn,
  error,
}

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository repository;
  final GetExpenses getExpenses;
  final DeleteExpense deleteExpense;
  final ProcessRecurringExpenses processRecurringExpenses;
  final CloudSyncService cloudSync;

  ExpenseViewModel({
    required this.repository,
    required this.getExpenses,
    required this.deleteExpense,
    required this.processRecurringExpenses,
    required this.cloudSync,
  });

  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;
  double _todayExpenses = 0.0;
  double _selectedDateTotal = 0.0;
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _errorMessage;

  // Premium Features State
  double _budgetLimit = 0.0;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  double? _minAmount;
  double? _maxAmount;

  SyncStatus _syncStatus = SyncStatus.synced;
  int _unsyncedCount = 0;

  List<Expense> get expenses => _expenses;
  double get totalExpenses => _totalExpenses;
  double get todayExpenses => _todayExpenses;
  double get selectedDateTotal => _selectedDateTotal;
  bool get isLoading => _isLoading;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get errorMessage => _errorMessage;

  double get budgetLimit => _budgetLimit;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;

  SyncStatus get syncStatus => _syncStatus;
  int get unsyncedCount => _unsyncedCount;

  // Filtered expenses list
  List<Expense> get filteredExpenses {
    return _expenses.where((expense) {
      if (_searchQuery.isNotEmpty &&
          !expense.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategory != 'All' && expense.category != _selectedCategory) {
        return false;
      }
      if (_minAmount != null && expense.amount < _minAmount!) {
        return false;
      }
      if (_maxAmount != null && expense.amount > _maxAmount!) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> setBudgetLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budget_limit', limit);
    _budgetLimit = limit;
    notifyListeners();
  }

  void updateFilters({
    String? query,
    String? category,
    double? min,
    double? max,
  }) {
    if (query != null) _searchQuery = query;
    if (category != null) _selectedCategory = category;
    _minAmount = min;
    _maxAmount = max;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _minAmount = null;
    _maxAmount = null;
    notifyListeners();
  }

  // Insights Calculations
  Map<String, double> getCategoryBreakdown() {
    final Map<String, double> breakdown = {};
    for (final expense in filteredExpenses) {
      breakdown[expense.category] = (breakdown[expense.category] ?? 0.0) + expense.amount;
    }
    return breakdown;
  }

  Map<String, double> getMonthlyTrends() {
    final Map<String, double> trends = {};
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Sort expenses chronologically to ensure trend timeline makes sense
    final sortedExpenses = List<Expense>.from(_expenses)
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final expense in sortedExpenses) {
      final date = expense.date;
      final monthStr = '${months[date.month - 1]} ${date.year}';
      trends[monthStr] = (trends[monthStr] ?? 0.0) + expense.amount;
    }
    return trends;
  }

  Future<void> checkSyncStatus() async {
    final hasUser = cloudSync.userId != null;
    if (!hasUser) {
      _syncStatus = SyncStatus.notSignedIn;
      _unsyncedCount = 0;
      notifyListeners();
      return;
    }

    final unsyncedExpenses = await DatabaseHelper.instance.getUnsyncedExpenses();
    final unsyncedBorrowLends = await DatabaseHelper.instance.getUnsyncedBorrowLend();
    _unsyncedCount = unsyncedExpenses.length + unsyncedBorrowLends.length;

    if (_unsyncedCount > 0) {
      _syncStatus = SyncStatus.pendingSync;
    } else {
      _syncStatus = SyncStatus.synced;
    }
    notifyListeners();
  }

  Future<void> _loadLocalData() async {
    final expensesList = await getExpenses(startDate: _startDate, endDate: _endDate);
    final total = await repository.getTotalExpenses();
    final today = await repository.getTotalExpensesByDate(DateTime.now());
    
    double selectedTotal = 0.0;
    if (_startDate != null && _endDate != null) {
      selectedTotal = await repository.getTotalExpensesByDateRange(_startDate!, _endDate!);
    }

    _expenses = expensesList;
    _totalExpenses = total;
    _todayExpenses = today;
    _selectedDateTotal = selectedTotal;
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _budgetLimit = prefs.getDouble('budget_limit') ?? 0.0;

      await processRecurringExpenses();
      await _loadLocalData();

      final hasUser = cloudSync.userId != null;
      if (hasUser) {
        try {
          await repository.syncFromCloud();
          await _loadLocalData();
        } catch (syncError) {
          debugPrint('Sync failed during loadExpenses: $syncError');
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      _syncStatus = SyncStatus.error;
    } finally {
      _isLoading = false;
      await checkSyncStatus();
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
