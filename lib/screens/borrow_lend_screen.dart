import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repositories/borrow_lend_repository_impl.dart';
import '../domain/usecases/get_borrow_lend.dart';
import '../domain/usecases/delete_borrow_lend.dart';
import '../domain/usecases/mark_transaction_completed.dart';
import '../domain/usecases/mark_transaction_pending.dart';
import '../presentation/controllers/borrow_lend_controller.dart';
import '../presentation/widgets/borrow_lend_summary_cards.dart';
import '../presentation/widgets/transaction_card.dart';
import '../presentation/widgets/empty_transaction_list.dart';
import '../presentation/utils/borrow_lend_utils.dart';
import '../presentation/dialogs/delete_transaction_dialog.dart';
import '../presentation/dialogs/mark_completed_dialog.dart';
import '../presentation/dialogs/mark_pending_dialog.dart';
import '../presentation/dialogs/no_internet_dialog.dart';
import '../presentation/dialogs/not_signed_in_dialog.dart';
import '../services/connectivity_service.dart';
import 'add_borrow_lend_screen.dart';

class BorrowLendScreen extends StatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  State<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends State<BorrowLendScreen>
    with SingleTickerProviderStateMixin {
  late BorrowLendController _controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final repository = BorrowLendRepositoryImpl();
    final getBorrowLend = GetBorrowLend(repository);
    final deleteBorrowLend = DeleteBorrowLend(
      repository: repository,
      connectivity: ConnectivityService.instance,
      cloudSync: repository.cloudSync,
    );
    final markCompleted = MarkTransactionCompleted(repository);
    final markPending = MarkTransactionPending(repository);
    
    _controller = BorrowLendController(
      repository,
      getBorrowLend,
      deleteBorrowLend,
      markCompleted,
      markPending,
    );
    _controller.loadBorrowLend();
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBorrowLendScreen()),
    );
    if (result == true && mounted) {
      _controller.loadBorrowLend();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Borrow & Lend'),
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'You Owe', icon: Icon(Icons.arrow_downward)),
              Tab(text: 'Owed to You', icon: Icon(Icons.arrow_upward)),
              Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            ],
          ),
        ),
        body: Consumer<BorrowLendController>(
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
                              icon: Icons.arrow_downward,
                              message: 'No borrowed money',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.borrowedList.length,
                              itemBuilder: (context, index) {
                                final transaction = controller.borrowedList[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  isBorrowed: true,
                                  onMarkCompleted: () => _handleMarkCompleted(transaction.id!),
                                  onDelete: () => _handleDelete(transaction.id!),
                                  formatDate: BorrowLendUtils.formatDate,
                                );
                              },
                            ),
                      // Lent Tab
                      controller.lentList.isEmpty
                          ? const EmptyTransactionList(
                              icon: Icons.arrow_upward,
                              message: 'No lent money',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.lentList.length,
                              itemBuilder: (context, index) {
                                final transaction = controller.lentList[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  isBorrowed: false,
                                  onMarkCompleted: () => _handleMarkCompleted(transaction.id!),
                                  onDelete: () => _handleDelete(transaction.id!),
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: controller.completedList.length,
                              itemBuilder: (context, index) {
                                final transaction = controller.completedList[index];
                                return TransactionCard(
                                  transaction: transaction,
                                  isBorrowed: transaction.type == 'borrow',
                                  isCompleted: true,
                                  onMarkPending: () => _handleMarkPending(transaction.id!),
                                  onDelete: () => _handleDelete(transaction.id!),
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
          backgroundColor: Colors.purple.shade700,
          icon: const Icon(Icons.add),
          label: const Text('Add Transaction'),
        ),
      ),
    );
  }
}
