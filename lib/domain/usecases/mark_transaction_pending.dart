import '../repositories/borrow_lend_repository.dart';

class MarkTransactionPending {
  final BorrowLendRepository repository;

  MarkTransactionPending(this.repository);

  Future<void> call(int id) async {
    await repository.markAsPending(id);
    // Sync to cloud
    final allTransactions = await repository.getAllBorrowLend();
    final transaction = allTransactions.firstWhere((t) => t.id == id);
    final updatedTransaction = transaction.copyWith(completed: false);
    await repository.syncToCloud(updatedTransaction);
    await repository.markAsSynced(id);
  }
}

