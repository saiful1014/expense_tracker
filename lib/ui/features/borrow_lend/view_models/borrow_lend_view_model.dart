import 'package:flutter/material.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/domain/usecases/get_borrow_lend.dart';
import 'package:test_new_things/domain/usecases/delete_borrow_lend.dart';
import 'package:test_new_things/domain/usecases/mark_transaction_completed.dart';
import 'package:test_new_things/domain/usecases/mark_transaction_pending.dart';

class BorrowLendViewModel extends ChangeNotifier {
  final BorrowLendRepository repository;
  final GetBorrowLend getBorrowLend;
  final DeleteBorrowLend deleteBorrowLend;
  final MarkTransactionCompleted markCompleted;
  final MarkTransactionPending markPending;

  BorrowLendViewModel(
    this.repository,
    this.getBorrowLend,
    this.deleteBorrowLend,
    this.markCompleted,
    this.markPending,
  );

  List<BorrowLend> _borrowedList = [];
  List<BorrowLend> _lentList = [];
  List<BorrowLend> _completedList = [];
  double _totalBorrowed = 0.0;
  double _totalLent = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<BorrowLend> get borrowedList => _borrowedList;
  List<BorrowLend> get lentList => _lentList;
  List<BorrowLend> get completedList => _completedList;
  double get totalBorrowed => _totalBorrowed;
  double get totalLent => _totalLent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadLocalData() async {
    final borrowed = await getBorrowLend.callByType('borrow');
    final lent = await getBorrowLend.callByType('lend');
    final completed = await getBorrowLend.callCompleted();

    // Calculate totals using remainingAmount to account for partial payments
    double totalB = 0.0;
    for (final tx in borrowed) {
      totalB += tx.remainingAmount;
    }

    double totalL = 0.0;
    for (final tx in lent) {
      totalL += tx.remainingAmount;
    }

    _borrowedList = borrowed;
    _lentList = lent;
    _completedList = completed;
    _totalBorrowed = totalB;
    _totalLent = totalL;
    notifyListeners();
  }

  Future<void> loadBorrowLend() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load local transactions first (always succeeds)
      await _loadLocalData();

      // 2. Try to sync in the background
      try {
        await repository.syncFromCloud();
        // 3. Reload local data if sync pulled updates
        await _loadLocalData();
      } catch (syncError) {
        // Log offline/sync errors silently so they don't block the screen
        debugPrint('Sync failed during loadBorrowLend: $syncError');
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRepayment(BorrowLend transaction, double amount) async {
    final repayment = Repayment(amount: amount, date: DateTime.now());
    final updatedRepayments = List<Repayment>.from(transaction.repayments)..add(repayment);
    
    // Check if the total paid amount meets or exceeds the total transaction amount
    final tempTx = transaction.copyWith(repayments: updatedRepayments);
    final isCompleted = tempTx.paidAmount >= transaction.amount;
    
    final updatedTx = tempTx.copyWith(
      completed: isCompleted,
      synced: false,
    );

    // Save to local database
    await repository.updateBorrowLend(updatedTx);
    
    // Sync to cloud if online
    try {
      await repository.syncToCloud(updatedTx);
      await repository.markAsSynced(updatedTx.id!);
    } catch (_) {
      // Offline, will sync later
    }

    await loadBorrowLend();
  }

  Future<bool> canDelete() async {
    return await deleteBorrowLend.canDelete();
  }

  Future<void> delete(int id) async {
    try {
      await deleteBorrowLend.call(id);
      await loadBorrowLend();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsCompleted(int id) async {
    try {
      await markCompleted.call(id);
      await loadBorrowLend();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsPending(int id) async {
    try {
      await markPending.call(id);
      await loadBorrowLend();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

