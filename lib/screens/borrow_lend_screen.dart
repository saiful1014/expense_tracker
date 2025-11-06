import 'package:flutter/material.dart';
import '../models/borrow_lend.dart';
import '../database/database_helper.dart';
import '../services/cloud_sync_service.dart';
import '../services/connectivity_service.dart';
import 'add_borrow_lend_screen.dart';

class BorrowLendScreen extends StatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  State<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends State<BorrowLendScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final CloudSyncService _cloudSync = CloudSyncService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  List<BorrowLend> _borrowedList = [];
  List<BorrowLend> _lentList = [];
  List<BorrowLend> _completedList = [];
  double _totalBorrowed = 0.0;
  double _totalLent = 0.0;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBorrowLend();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBorrowLend() async {
    setState(() => _isLoading = true);
    
    // Check if user is signed in and sync from cloud
    final isSignedIn = await _cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        // Get borrow/lend transactions from cloud
        final cloudTransactions = await _cloudSync.getBorrowLendFromCloud();
        
        // Merge cloud transactions with local database
        for (final transaction in cloudTransactions) {
          // Check if transaction exists locally
          final localBorrowed = await _dbHelper.getBorrowLendByType('borrow');
          final localLent = await _dbHelper.getBorrowLendByType('lend');
          final allLocal = [...localBorrowed, ...localLent];
          final exists = allLocal.any((e) => e.id == transaction.id);
          
          if (!exists) {
            // Add to local database if not exists (mark as synced since it's from cloud)
            final transactionId = await _dbHelper.insertBorrowLend(transaction);
            await _dbHelper.markBorrowLendAsSynced(transactionId);
          } else {
            // If exists, ensure it's marked as synced
            await _dbHelper.markBorrowLendAsSynced(transaction.id!);
          }
        }
      } catch (e) {
        debugPrint('Error syncing borrow/lend from cloud: $e');
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
    
    final borrowed = await _dbHelper.getBorrowLendByType('borrow');
    final lent = await _dbHelper.getBorrowLendByType('lend');
    final completed = await _dbHelper.getCompletedBorrowLend();
    final totalBorrowed = await _dbHelper.getTotalBorrowed();
    final totalLent = await _dbHelper.getTotalLent();

    setState(() {
      _borrowedList = borrowed;
      _lentList = lent;
      _completedList = completed;
      _totalBorrowed = totalBorrowed;
      _totalLent = totalLent;
      _isLoading = false;
    });
  }

  Future<void> _markAsCompleted(int id) async {
    // Mark as completed in local database
    await _dbHelper.markBorrowLendAsCompleted(id);
    
    // Update in cloud if signed in
    final isSignedIn = await _cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        // Get the transaction and update it in cloud
        final allTransactions = await _dbHelper.getAllBorrowLend();
        final transaction = allTransactions.firstWhere((t) => t.id == id);
        final updatedTransaction = BorrowLend(
          id: transaction.id,
          personName: transaction.personName,
          amount: transaction.amount,
          date: transaction.date,
          type: transaction.type,
          description: transaction.description,
          completed: true,
        );
        await _cloudSync.syncBorrowLendToCloud(updatedTransaction);
        // Mark as synced after successful sync
        await _dbHelper.markBorrowLendAsSynced(id);
      } catch (e) {
        debugPrint('Error syncing completed status to cloud: $e');
        // Mark as unsynced so it will be synced later when online
        await _dbHelper.markBorrowLendAsUnsynced(id);
        if (mounted && e.toString().contains('No internet connection')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection. Will sync when online.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    _loadBorrowLend();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAsPending(int id) async {
    // Mark as pending in local database
    await _dbHelper.markBorrowLendAsPending(id);
    
    // Update in cloud if signed in
    final isSignedIn = await _cloudSync.isSignedIn();
    if (isSignedIn) {
      try {
        // Get the transaction and update it in cloud
        final allTransactions = await _dbHelper.getAllBorrowLend();
        final transaction = allTransactions.firstWhere((t) => t.id == id);
        final updatedTransaction = BorrowLend(
          id: transaction.id,
          personName: transaction.personName,
          amount: transaction.amount,
          date: transaction.date,
          type: transaction.type,
          description: transaction.description,
          completed: false,
        );
        await _cloudSync.syncBorrowLendToCloud(updatedTransaction);
        // Mark as synced after successful sync
        await _dbHelper.markBorrowLendAsSynced(id);
      } catch (e) {
        debugPrint('Error syncing pending status to cloud: $e');
        // Mark as unsynced so it will be synced later when online
        await _dbHelper.markBorrowLendAsUnsynced(id);
        if (mounted && e.toString().contains('No internet connection')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No internet connection. Will sync when online.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    _loadBorrowLend();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction marked as pending'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteBorrowLend(int id) async {
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
            'You cannot delete transactions without an internet connection. Please connect to the internet and try again.',
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
            'You need to be signed in to delete transactions. Please sign in and try again.',
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
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
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
      await _cloudSync.deleteBorrowLendFromCloud(id);
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
    await _dbHelper.deleteBorrowLend(id);
    
    _loadBorrowLend();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _navigateToAddBorrowLend() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBorrowLendScreen(),
      ),
    );
    if (result == true) {
      _loadBorrowLend();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade600, Colors.red.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'You Owe',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${_totalBorrowed.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade600, Colors.green.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Owed to You',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${_totalLent.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
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
                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Borrowed Tab (You Owe)
                      _borrowedList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No borrowed money',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _borrowedList.length,
                              itemBuilder: (context, index) {
                                final transaction = _borrowedList[index];
                                return _buildTransactionCard(transaction, true);
                              },
                            ),
                      // Lent Tab (Owed to You)
                      _lentList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No lent money',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _lentList.length,
                              itemBuilder: (context, index) {
                                final transaction = _lentList[index];
                                return _buildTransactionCard(transaction, false);
                              },
                            ),
                      // Completed Tab
                      _completedList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No completed transactions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _completedList.length,
                              itemBuilder: (context, index) {
                                final transaction = _completedList[index];
                                return _buildTransactionCard(transaction, transaction.type == 'borrow', isCompleted: true);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBorrowLend,
        backgroundColor: Colors.purple.shade700,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  Widget _buildTransactionCard(BorrowLend transaction, bool isBorrowed, {bool isCompleted = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted 
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isCompleted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade50.withValues(alpha: 0.3),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isCompleted
                ? Colors.green.shade100
                : (isBorrowed ? Colors.red.shade100 : Colors.green.shade100),
            child: Icon(
              isCompleted
                  ? Icons.check_circle
                  : (isBorrowed ? Icons.arrow_downward : Icons.arrow_upward),
              color: isCompleted
                  ? Colors.green.shade700
                  : (isBorrowed ? Colors.red.shade700 : Colors.green.shade700),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  transaction.personName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey.shade600 : null,
                  ),
                ),
              ),
              if (isCompleted) ...[
                // Show transaction type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: transaction.type == 'borrow' 
                        ? Colors.red.shade100 
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        transaction.type == 'borrow' 
                            ? Icons.arrow_downward 
                            : Icons.arrow_upward,
                        size: 12,
                        color: transaction.type == 'borrow' 
                            ? Colors.red.shade700 
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        transaction.type == 'borrow' ? 'Borrow' : 'Lend',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: transaction.type == 'borrow' 
                              ? Colors.red.shade700 
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null &&
                transaction.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transaction.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (isCompleted)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        transaction.type == 'borrow' 
                            ? Icons.arrow_downward 
                            : Icons.arrow_upward,
                        size: 12,
                        color: transaction.type == 'borrow' 
                            ? Colors.red.shade600 
                            : Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        transaction.type == 'borrow' 
                            ? 'You Owed' 
                            : 'Owed to You',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: transaction.type == 'borrow' 
                              ? Colors.red.shade600 
                              : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? Colors.grey.shade600
                      : (isBorrowed ? Colors.red.shade700 : Colors.green.shade700),
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Mark as Completed'),
                            content: const Text(
                              'Mark this transaction as completed?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _markAsCompleted(transaction.id!);
                                },
                                child: const Text(
                                  'Mark Complete',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ),
                  if (!isCompleted) const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      _deleteBorrowLend(transaction.id!);
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
                  if (isCompleted)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Mark as Pending'),
                            content: const Text(
                              'Mark this transaction as pending?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _markAsPending(transaction.id!);
                                },
                                child: const Text(
                                  'Mark Pending',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh,
                          size: 18,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

