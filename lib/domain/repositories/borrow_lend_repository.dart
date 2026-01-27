import '../../models/borrow_lend.dart';

abstract class BorrowLendRepository {
  Future<List<BorrowLend>> getAllBorrowLend();
  Future<List<BorrowLend>> getBorrowLendByType(String type);
  Future<List<BorrowLend>> getCompletedBorrowLend();
  Future<double> getTotalBorrowed();
  Future<double> getTotalLent();
  Future<int> insertBorrowLend(BorrowLend borrowLend);
  Future<void> deleteBorrowLend(int id);
  Future<void> markAsCompleted(int id);
  Future<void> markAsPending(int id);
  Future<void> updateBorrowLend(BorrowLend borrowLend);
  Future<void> syncFromCloud();
  Future<void> deleteFromCloud(int id);
  Future<void> syncToCloud(BorrowLend borrowLend);
  Future<void> markAsSynced(int id);
}

