import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/expense_app_bar.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/expense_statistics_section.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/expense_list_item.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/empty_expense_list.dart';
import 'package:test_new_things/ui/core/utils/expense_utils.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/delete_expense_dialog.dart';
import 'package:test_new_things/ui/core/dialogs/no_internet_dialog.dart';
import 'package:test_new_things/ui/core/dialogs/not_signed_in_dialog.dart';
import 'package:test_new_things/data/services/database_helper.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/sync_status_bottom_sheet.dart';
import 'package:test_new_things/ui/features/home/views/widgets/budget_card.dart';
import 'package:test_new_things/ui/features/home/views/widgets/overdue_warning_banner.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/expense_details_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ExpenseViewModel _controller;
  bool _initialized = false;
  List<BorrowLend> _overdueTransactions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _controller = context.read<ExpenseViewModel>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData();
      });
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    await _controller.loadExpenses();
    await _checkOverdueTransactions();
  }

  Future<void> _checkOverdueTransactions() async {
    try {
      final db = DatabaseHelper.instance;
      final all = await db.getAllBorrowLend();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (mounted) {
        setState(() {
          _overdueTransactions = all.where((tx) {
            if (tx.completed || tx.dueDate == null) return false;
            final txDate = DateTime(tx.dueDate!.year, tx.dueDate!.month, tx.dueDate!.day);
            return txDate.isBefore(today) || txDate.isAtSameMomentAs(today);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error checking overdue: $e');
    }
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
      await _checkOverdueTransactions();
    }
  }

  Future<void> _handleDelete(int id) async {
    final canDelete = await _controller.canDelete();
    if (!mounted) return;

    if (!canDelete) {
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
    final result = await context.push<bool>('/add-expense');
    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _navigateToEditExpense(Expense expense) async {
    final result = await context.push<bool>('/add-expense', extra: expense);
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _showSyncStatusBottomSheet(BuildContext context, ExpenseViewModel controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SyncStatusBottomSheet(
          syncStatus: controller.syncStatus,
          unsyncedCount: controller.unsyncedCount,
          onSyncNow: () {
            Navigator.pop(context);
            _loadData();
          },
          onConfigure: () async {
            Navigator.pop(context);
            final result = await context.push<bool>('/sync-setup');
            if (result == true && mounted) {
              _loadData();
            }
          },
        );
      },
    );
  }

  Future<void> _showBudgetDialog(BuildContext context, ExpenseViewModel controller) async {
    final textController = TextEditingController(
      text: controller.budgetLimit > 0 ? controller.budgetLimit.toStringAsFixed(0) : '',
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter monthly limit (e.g. 500)',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(textController.text) ?? 0.0;
              controller.setBudgetLimit(val);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseViewModel>(
      builder: (context, controller, child) {
        final categories = controller.allCategories;

          return Scaffold(
            appBar: ExpenseAppBar(
              startDate: controller.startDate,
              endDate: controller.endDate,
              formatDate: ExpenseUtils.formatDate,
              syncStatus: controller.syncStatus,
              unsyncedCount: controller.unsyncedCount,
              onSyncTap: () => _showSyncStatusBottomSheet(context, controller),
              onBorrowLend: () async {
                await context.push('/borrow-lend');
                await _checkOverdueTransactions();
              },
              onDateRange: _selectDateRange,
              onInsights: () => context.push('/insights'),
              onManageCategories: () async {
                await context.push('/manage-categories');
              },
              onClearFilter: controller.startDate != null && controller.endDate != null
                  ? () => controller.clearDateFilter()
                  : null,
            ),
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (controller.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${controller.errorMessage}'),
                            ElevatedButton(
                              onPressed: () => _loadData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadData(),
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
                            BudgetCard(
                              controller: controller,
                              onEdit: () => _showBudgetDialog(context, controller),
                            ),
                            // Month Navigation Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    tooltip: 'Previous month',
                                    onPressed: () => controller.goToPreviousMonth(),
                                  ),
                                  Text(
                                    controller.selectedMonthLabel,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    tooltip: 'Next month',
                                    onPressed: controller.canGoToNextMonth
                                        ? () => controller.goToNextMonth()
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            OverdueWarningBanner(
                              count: _overdueTransactions.length,
                              onTap: () async {
                                await context.push('/borrow-lend');
                                await _checkOverdueTransactions();
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search expenses...',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (val) => controller.updateFilters(query: val),
                              ),
                            ),
                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final cat = categories[index];
                                  final isSelected = controller.selectedCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          controller.updateFilters(category: cat);
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: controller.filteredExpenses.isEmpty
                                  ? const EmptyExpenseList()
                                  : ListView.builder(
                                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      itemCount: controller.filteredExpenses.length,
                                      itemBuilder: (context, index) {
                                        final expense = controller.filteredExpenses[index];
                                        return ExpenseListItem(
                                          expense: expense,
                                          onDelete: () => _handleDelete(expense.id!),
                                          onEdit: () => _navigateToEditExpense(expense),
                                          onTap: () => ExpenseDetailsDialog.show(
                                            context,
                                            expense: expense,
                                            formatDate: ExpenseUtils.formatDate,
                                            formatTime: ExpenseUtils.formatTime,
                                            getCategoryColor: ExpenseUtils.getCategoryColor,
                                            getCategoryIcon: ExpenseUtils.getCategoryIcon,
                                          ),
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
                      )),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add),
              label: Text(
                'Add Expense',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
