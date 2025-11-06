import 'package:flutter/material.dart';
import '../../models/borrow_lend.dart';
import '../../domain/repositories/borrow_lend_repository.dart';
import '../../domain/usecases/get_borrow_lend.dart';
import '../../domain/usecases/delete_borrow_lend.dart';
import '../../domain/usecases/mark_transaction_completed.dart';
import '../../domain/usecases/mark_transaction_pending.dart';

class BorrowLendController extends ChangeNotifier {
  final BorrowLendRepository repository;
  final GetBorrowLend getBorrowLend;
  final DeleteBorrowLend deleteBorrowLend;
  final MarkTransactionCompleted markCompleted;
  final MarkTransactionPending markPending;

  BorrowLendController(
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

  Future<void> loadBorrowLend() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.syncFromCloud();
      
      final borrowed = await getBorrowLend.callByType('borrow');
      final lent = await getBorrowLend.callByType('lend');
      final completed = await getBorrowLend.callCompleted();
      final totalBorrowed = await repository.getTotalBorrowed();
      final totalLent = await repository.getTotalLent();

      _borrowedList = borrowed;
      _lentList = lent;
      _completedList = completed;
      _totalBorrowed = totalBorrowed;
      _totalLent = totalLent;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

