import '../repositories/borrow_lend_repository.dart';

class MarkTransactionCompleted {
  final BorrowLendRepository repository;

  MarkTransactionCompleted(this.repository);

  Future<void> call(int id) async {
    await repository.markAsCompleted(id);
    // Sync to cloud
    final allTransactions = await repository.getAllBorrowLend();
    final transaction = allTransactions.firstWhere((t) => t.id == id);
    final updatedTransaction = transaction.copyWith(completed: true);
    await repository.syncToCloud(updatedTransaction);
    await repository.markAsSynced(id);
  }
}

