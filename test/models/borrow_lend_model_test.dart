import 'package:flutter_test/flutter_test.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';

void main() {
  group('BorrowLend Repayments Tests', () {
    test('Calculates paidAmount and remainingAmount correctly', () {
      final transaction = BorrowLend(
        id: 1,
        personName: 'Alice',
        amount: 100.0,
        date: DateTime(2026, 1, 1),
        type: 'borrow',
        repayments: [
          Repayment(amount: 20.0, date: DateTime(2026, 1, 2)),
          Repayment(amount: 30.0, date: DateTime(2026, 1, 3)),
        ],
      );

      expect(transaction.paidAmount, 50.0);
      expect(transaction.remainingAmount, 50.0);
    });

    test('Serializes to map correctly', () {
      final transaction = BorrowLend(
        id: 1,
        personName: 'Alice',
        amount: 100.0,
        date: DateTime(2026, 1, 1),
        type: 'borrow',
        repayments: [
          Repayment(amount: 25.0, date: DateTime(2026, 1, 2)),
        ],
      );

      final map = transaction.toMap();
      expect(map['id'], 1);
      expect(map['person_name'], 'Alice');
      expect(map['amount'], 100.0);
      expect(map['type'], 'borrow');
      expect(map['repayments'], contains('"amount":25.0'));
    });

    test('Deserializes from map correctly', () {
      final map = {
        'id': 1,
        'person_name': 'Bob',
        'amount': 50.0,
        'date': '2026-01-01T12:00:00.000',
        'type': 'lend',
        'completed': 0,
        'synced': 1,
        'repayments': '[{"amount":10.0,"date":"2026-01-02T12:00:00.000"}]',
      };

      final transaction = BorrowLend.fromMap(map);
      expect(transaction.id, 1);
      expect(transaction.personName, 'Bob');
      expect(transaction.amount, 50.0);
      expect(transaction.type, 'lend');
      expect(transaction.completed, false);
      expect(transaction.synced, true);
      expect(transaction.repayments.length, 1);
      expect(transaction.repayments.first.amount, 10.0);
      expect(transaction.paidAmount, 10.0);
      expect(transaction.remainingAmount, 40.0);
    });

    test('Handles malformed or empty repayments JSON string safely', () {
      final map = {
        'id': 2,
        'person_name': 'Charlie',
        'amount': 20.0,
        'date': '2026-01-01T12:00:00.000',
        'type': 'borrow',
        'completed': 0,
        'synced': 0,
        'repayments': '{invalid json}',
      };

      final transaction = BorrowLend.fromMap(map);
      expect(transaction.repayments, isEmpty);
      expect(transaction.paidAmount, 0.0);
      expect(transaction.remainingAmount, 20.0);
    });
  });
}
