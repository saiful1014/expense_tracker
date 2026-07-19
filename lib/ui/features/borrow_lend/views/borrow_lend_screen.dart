import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/repayments_dialog.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/domain/usecases/get_borrow_lend.dart';
import 'package:test_new_things/domain/usecases/delete_borrow_lend.dart';
import 'package:test_new_things/domain/usecases/mark_transaction_completed.dart';
import 'package:test_new_things/domain/usecases/mark_transaction_pending.dart';
import 'package:test_new_things/ui/features/borrow_lend/view_models/borrow_lend_view_model.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/borrow_lend_summary_cards.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/transaction_card.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/empty_transaction_list.dart';
import 'package:test_new_things/ui/core/utils/borrow_lend_utils.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/delete_transaction_dialog.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/mark_completed_dialog.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/mark_pending_dialog.dart';
import 'package:test_new_things/ui/core/dialogs/no_internet_dialog.dart';
import 'package:test_new_things/ui/core/dialogs/not_signed_in_dialog.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/borrow_lend_details_dialog.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class BorrowLendScreen extends StatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  State<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends State<BorrowLendScreen>
    with SingleTickerProviderStateMixin {
  late BorrowLendViewModel _controller;
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final repository = context.read<BorrowLendRepository>();
      final connectivity = context.read<ConnectivityService>();
      final cloudSync = context.read<CloudSyncService>();
      final getBorrowLend = GetBorrowLend(repository);
      final deleteBorrowLend = DeleteBorrowLend(
        repository: repository,
        connectivity: connectivity,
        cloudSync: cloudSync,
      );
      final markCompleted = MarkTransactionCompleted(repository);
      final markPending = MarkTransactionPending(repository);
      
      _controller = BorrowLendViewModel(
        repository,
        getBorrowLend,
        deleteBorrowLend,
        markCompleted,
        markPending,
      );
      _controller.loadBorrowLend();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
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
          message: 'You cannot delete transactions without an internet connection. Please connect to the internet and try again.',
        );
      } else {
        await NotSignedInDialog.show(
          context,
          message: 'You need to be signed in to delete transactions. Please sign in and try again.',
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmDelete = await DeleteTransactionDialog.show(context);
    if (confirmDelete != true || !mounted) return;

    try {
      await _controller.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
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

  Future<void> _handleMarkCompleted(int id) async {
    if (!mounted) return;
    final confirm = await MarkCompletedDialog.show(context);
    if (confirm != true || !mounted) return;

    try {
      await _controller.markAsCompleted(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as completed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRepaymentsDialog(BorrowLend transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return RepaymentsDialog(
          transaction: transaction,
          onAddRepayment: (amount) async {
            try {
              await _controller.addRepayment(transaction, amount);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Repayment added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add repayment: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _handleMarkPending(int id) async {
    if (!mounted) return;
    final confirm = await MarkPendingDialog.show(context);
    if (confirm != true || !mounted) return;

    try {
      await _controller.markAsPending(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction marked as pending'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as pending: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddBorrowLend() async {
    final result = await context.push<bool>('/add-borrow-lend');
    if (result == true && mounted) {
      _controller.loadBorrowLend();
    }
  }

  Future<void> _navigateToEditBorrowLend(BorrowLend transaction) async {
    final result = await context.push<bool>('/add-borrow-lend', extra: transaction);
    if (result == true && mounted) {
      _controller.loadBorrowLend();
    }
  }

  void _showTransactionDetails(BorrowLend transaction) {
    BorrowLendDetailsDialog.show(
      context,
      transaction: transaction,
      formatDate: BorrowLendUtils.formatDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Borrow & Lend',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'You Owe', icon: Icon(Icons.arrow_downward_outlined, size: 18)),
              Tab(text: 'Owed to You', icon: Icon(Icons.arrow_upward_outlined, size: 18)),
              Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline, size: 18)),
            ],
          ),
        ),
        body: Consumer<BorrowLendViewModel>(
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
                      onPressed: () => controller.loadBorrowLend(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                BorrowLendSummaryCards(
                  totalBorrowed: controller.totalBorrowed,
                  totalLent: controller.totalLent,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Borrowed Tab
                      controller.borrowedList.isEmpty
                          ? const EmptyTransactionList(
                              icon: Icons.arrow_downward_outlined,
                              message: 'No borrowed money',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                              itemCount: controller.borrowedList.length,
                              itemBuilder: (context, index) {
                                final transaction = controller.borrowedList[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  isBorrowed: true,
                                  onMarkCompleted: () => _handleMarkCompleted(transaction.id!),
                                  onAddRepayment: () => _showRepaymentsDialog(transaction),
                                  onEdit: () => _navigateToEditBorrowLend(transaction),
                                  onDelete: () => _handleDelete(transaction.id!),
                                  onTap: () => _showTransactionDetails(transaction),
                                  formatDate: BorrowLendUtils.formatDate,
                                );
                              },
                            ),
                      // Lent Tab
                      controller.lentList.isEmpty
                          ? const EmptyTransactionList(
                              icon: Icons.arrow_upward_outlined,
                              message: 'No lent money',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                              itemCount: controller.lentList.length,
                              itemBuilder: (context, index) {
                                final transaction = controller.lentList[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  isBorrowed: false,
                                  onMarkCompleted: () => _handleMarkCompleted(transaction.id!),
                                  onAddRepayment: () => _showRepaymentsDialog(transaction),
                                  onEdit: () => _navigateToEditBorrowLend(transaction),
                                  onDelete: () => _handleDelete(transaction.id!),
                                  onTap: () => _showTransactionDetails(transaction),
                                  formatDate: BorrowLendUtils.formatDate,
                                );
                              },
                            ),
                      // Completed Tab
                      controller.completedList.isEmpty
                          ? const EmptyTransactionList(
                              icon: Icons.check_circle_outline,
                              message: 'No completed transactions',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                              itemCount: controller.completedList.length,
                              itemBuilder: (context, index) {
                                final transaction = controller.completedList[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  isBorrowed: transaction.type == 'borrow',
                                  isCompleted: true,
                                  onMarkPending: () => _handleMarkPending(transaction.id!),
                                  onEdit: () => _navigateToEditBorrowLend(transaction),
                                  onDelete: () => _handleDelete(transaction.id!),
                                  onTap: () => _showTransactionDetails(transaction),
                                  formatDate: BorrowLendUtils.formatDate,
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToAddBorrowLend,
          icon: const Icon(Icons.add),
          label: Text(
            'Add Transaction',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
