import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import '../services/cloud_sync_service.dart';
import '../services/connectivity_service.dart';
import 'add_expense_screen.dart';
import 'borrow_lend_screen.dart';
import 'sync_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService _cloudSync = CloudSyncService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  List<Expense> _expenses = [];
  double _totalExpenses = 0.0;
  double _todayExpenses = 0.0;
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  double _selectedDateTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    
    // Check if user is signed in and sync from cloud
    final isSignedIn = await _cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        // Get expenses from cloud
        final cloudExpenses = await _cloudSync.getExpensesFromCloud();
        
        // Merge cloud expenses with local database
        for (final expense in cloudExpenses) {
          // Check if expense exists locally
          final localExpenses = await _dbHelper.getAllExpenses();
          final exists = localExpenses.any((e) => e.id == expense.id);
          
          if (!exists) {
            // Add to local database if not exists (mark as synced since it's from cloud)
            final expenseId = await _dbHelper.insertExpense(expense);
            await _dbHelper.markExpenseAsSynced(expenseId);
          } else {
            // If exists, ensure it's marked as synced
            await _dbHelper.markExpenseAsSynced(expense.id!);
          }
        }
      } catch (e) {
        debugPrint('Error syncing from cloud: $e');
        if (mounted && e.toString().contains('No internet connection')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    List<Expense> expenses;
    double selectedDateTotal = 0.0;
    
    if (_startDate != null && _endDate != null) {
      expenses = await _dbHelper.getExpensesByDateRange(_startDate!, _endDate!);
      selectedDateTotal = await _dbHelper.getTotalExpensesByDateRange(_startDate!, _endDate!);
    } else {
      expenses = await _dbHelper.getAllExpenses();
    }
    
    final total = await _dbHelper.getTotalExpenses();
    final today = await _dbHelper.getTotalExpensesByDate(DateTime.now());
    
    setState(() {
      _expenses = expenses;
      _totalExpenses = total;
      _todayExpenses = today;
      _selectedDateTotal = selectedDateTotal;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    if (!mounted) return;
    
    // Select start date
    final DateTime? startPicked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select start date',
    );
    
    if (startPicked == null || !mounted) return;
    
    // Select end date
    final DateTime? endPicked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? startPicked,
      firstDate: startPicked,
      lastDate: DateTime.now(),
      helpText: 'Select end date',
    );
    
    if (endPicked != null && mounted) {
      setState(() {
        _startDate = DateTime(startPicked.year, startPicked.month, startPicked.day);
        _endDate = DateTime(endPicked.year, endPicked.month, endPicked.day);
      });
      _loadExpenses();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    // Check internet connection first
    final hasInternet = await _connectivity.hasInternetConnection();
    
    if (!mounted) return;
    
    if (!hasInternet) {
      // Show popup if no internet connection
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
            'You cannot delete expenses without an internet connection. Please connect to the internet and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return; // Don't proceed with deletion
    }
    
    // Check if user is signed in
    final isSignedIn = await _cloudSync.isSignedIn();
    if (!mounted) return;
    
    if (!isSignedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Signed In'),
          content: const Text(
            'You need to be signed in to delete expenses. Please sign in and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return; // Don't proceed with deletion
    }
    
    // Show confirmation dialog
    if (!mounted) return;
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmDelete != true || !mounted) return;
    
    // Delete from cloud first
    try {
      await _cloudSync.deleteExpenseFromCloud(id);
    } catch (e) {
      debugPrint('Error deleting from cloud: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete from cloud. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return; // Don't delete locally if cloud deletion fails
    }
    
    // Delete from local database only after successful cloud deletion
    await _dbHelper.deleteExpense(id);
    
    _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Expenses'),
            if (_startDate != null && _endDate != null)
              Text(
                _startDate == _endDate
                    ? _formatDate(_startDate!)
                    : '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud),
            tooltip: 'Cloud Sync',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SyncSetupScreen(),
                ),
              );
              if (result == true) {
                _loadExpenses();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Borrow & Lend',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BorrowLendScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by date range',
            onPressed: _selectDateRange,
          ),
          if (_startDate != null && _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Show all expenses',
              onPressed: _clearDateFilter,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: Column(
                children: [
                  // Statistics Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Total Expenses Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade700, Colors.blue.shade500],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${_totalExpenses.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Selected Date / Today's Expenses Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade600, Colors.green.shade400],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_startDate != null && _endDate != null) ? 'Date Range' : 'Today',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${((_startDate != null && _endDate != null) ? _selectedDateTotal : _todayExpenses).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Expenses List
                Expanded(
                  child: _expenses.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No expenses yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + to add your first expense',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Category Icon
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: _getCategoryColor(expense.category),
                                      child: Icon(
                                        _getCategoryIcon(expense.category),
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Main Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            expense.description,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.category,
                                                    size: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      expense.category,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      _formatDate(expense.date),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatTime(expense.date),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Amount and Delete
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '\$${expense.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () {
                                            _deleteExpense(expense.id!);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.red.shade400,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      case 'entertainment':
        return Colors.pink;
      case 'health':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.local_hospital;
      default:
        return Icons.category;
    }
  }
}

