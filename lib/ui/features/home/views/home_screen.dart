import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/expense_repository_impl.dart';
import '../domain/usecases/get_expenses.dart';
import '../domain/usecases/delete_expense.dart';
import '../presentation/controllers/expense_controller.dart';
import '../services/connectivity_service.dart';
import '../models/expense.dart';
import '../presentation/widgets/expense_app_bar.dart';
import '../presentation/widgets/expense_statistics_section.dart';
import '../presentation/widgets/expense_list_item.dart';
import '../presentation/widgets/empty_expense_list.dart';
import '../presentation/utils/expense_utils.dart';
import '../presentation/dialogs/delete_expense_dialog.dart';
import '../presentation/dialogs/no_internet_dialog.dart';
import '../presentation/dialogs/not_signed_in_dialog.dart';
import 'add_expense_screen.dart';
import 'deferred_borrow_lend.dart';
import 'sync_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ExpenseController _controller;

  @override
  void initState() {
    super.initState();
    final repository = ExpenseRepositoryImpl();
    final getExpenses = GetExpenses(repository);
    final deleteExpense = DeleteExpense(
      repository: repository,
      connectivity: ConnectivityService.instance,
      cloudSync: repository.cloudSync,
    );
    _controller = ExpenseController(repository, getExpenses, deleteExpense);
    _controller.loadExpenses();
  }

  Future<void> _selectDateRange() async {
    if (!mounted) return;

    final startPicked = await showDatePicker(
      context: context,
      initialDate: _controller.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select start date',
    );

    if (startPicked == null || !mounted) return;

    final endPicked = await showDatePicker(
      context: context,
      initialDate: _controller.endDate ?? startPicked,
      firstDate: startPicked,
      lastDate: DateTime.now(),
      helpText: 'Select end date',
    );

    if (endPicked != null && mounted) {
      await _controller.setDateRange(
        DateTime(startPicked.year, startPicked.month, startPicked.day),
        DateTime(endPicked.year, endPicked.month, endPicked.day),
      );
    }
  }

  Future<void> _handleDelete(int id) async {
    final canDelete = await _controller.canDelete();
    if (!mounted) return;

    if (!canDelete) {
      // Check which condition failed
      final hasInternet = await ConnectivityService.instance.hasInternetConnection();
      if (!mounted) return;
      
      if (!hasInternet) {
        await NoInternetDialog.show(
          context,
          message: 'You cannot delete expenses without an internet connection. Please connect to the internet and try again.',
        );
      } else {
        await NotSignedInDialog.show(
          context,
          message: 'You need to be signed in to delete expenses. Please sign in and try again.',
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmDelete = await DeleteExpenseDialog.show(context);
    if (confirmDelete != true || !mounted) return;

    try {
      await _controller.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
    if (result == true && mounted) {
      _controller.loadExpenses();
    }
  }

  Future<void> _navigateToEditExpense(Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
    );
    if (result == true && mounted) {
      _controller.loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: ExpenseAppBar(
          startDate: _controller.startDate,
          endDate: _controller.endDate,
          formatDate: ExpenseUtils.formatDate,
          onCloudSync: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SyncSetupScreen()),
            );
            if (result == true && mounted) {
              _controller.loadExpenses();
            }
          },
          onBorrowLend: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DeferredBorrowLend()),
            );
          },
          onDateRange: _selectDateRange,
          onClearFilter: _controller.startDate != null && _controller.endDate != null
              ? () => _controller.clearDateFilter()
              : null,
        ),
        body: Consumer<ExpenseController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${controller.errorMessage}'),
                    ElevatedButton(
                      onPressed: () => controller.loadExpenses(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadExpenses(),
              child: Column(
                children: [
                  ExpenseStatisticsSection(
                    totalExpenses: controller.totalExpenses,
                    todayOrRangeExpenses: controller.startDate != null && controller.endDate != null
                        ? controller.selectedDateTotal
                        : controller.todayExpenses,
                    todayOrRangeLabel: controller.startDate != null && controller.endDate != null
                        ? 'Date Range'
                        : 'Today',
                  ),
                  Expanded(
                    child: controller.expenses.isEmpty
                        ? const EmptyExpenseList()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: controller.expenses.length,
                            itemBuilder: (context, index) {
                              final expense = controller.expenses[index];
                              return ExpenseListItem(
                                expense: expense,
                                onDelete: () => _handleDelete(expense.id!),
                                onEdit: () => _navigateToEditExpense(expense),
                                getCategoryColor: ExpenseUtils.getCategoryColor,
                                getCategoryIcon: ExpenseUtils.getCategoryIcon,
                                formatDate: ExpenseUtils.formatDate,
                                formatTime: ExpenseUtils.formatTime,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToAddExpense,
          backgroundColor: Colors.blue.shade700,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
