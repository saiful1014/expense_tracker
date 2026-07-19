import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/domain/usecases/mark_transaction_completed.dart';
import 'package:test_new_things/domain/usecases/mark_transaction_pending.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';

class MockBorrowLendRepository extends Mock implements BorrowLendRepository {}

void main() {
  group('MarkTransactionCompleted', () {
    late MockBorrowLendRepository repository;
    late MarkTransactionCompleted useCase;

    setUp(() {
      repository = MockBorrowLendRepository();
      useCase = MarkTransactionCompleted(repository);
    });

    test('marks transaction completed and syncs returned transaction', () async {
      final transaction = BorrowLend(
        id: 1,
        personName: 'Alice',
        amount: 50.0,
        date: DateTime(2024, 1, 1),
        type: 'borrow',
        completed: true,
      );

      when(() => repository.markAsCompletedAndGet(1)).thenAnswer((_) async => transaction);
      when(() => repository.syncToCloud(transaction)).thenAnswer((_) async {});
      when(() => repository.markAsSynced(1)).thenAnswer((_) async {});

      await useCase.call(1);

      verify(() => repository.markAsCompletedAndGet(1)).called(1);
      verify(() => repository.syncToCloud(transaction)).called(1);
      verify(() => repository.markAsSynced(1)).called(1);
    });
  });

  group('MarkTransactionPending', () {
    late MockBorrowLendRepository repository;
    late MarkTransactionPending useCase;

    setUp(() {
      repository = MockBorrowLendRepository();
      useCase = MarkTransactionPending(repository);
    });

    test('marks transaction pending and syncs returned transaction', () async {
      final transaction = BorrowLend(
        id: 2,
        personName: 'Bob',
        amount: 30.0,
        date: DateTime(2024, 1, 2),
        type: 'lend',
        completed: false,
      );

      when(() => repository.markAsPendingAndGet(2)).thenAnswer((_) async => transaction);
      when(() => repository.syncToCloud(transaction)).thenAnswer((_) async {});
      when(() => repository.markAsSynced(2)).thenAnswer((_) async {});

      await useCase.call(2);

      verify(() => repository.markAsPendingAndGet(2)).called(1);
      verify(() => repository.syncToCloud(transaction)).called(1);
      verify(() => repository.markAsSynced(2)).called(1);
    });
  });
}
