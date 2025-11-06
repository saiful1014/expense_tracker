import 'package:flutter/material.dart';
import '../../models/borrow_lend.dart';

class TransactionHeader extends StatelessWidget {
  final BorrowLend transaction;
  final bool isBorrowed;
  final bool isCompleted;

  const TransactionHeader({
    super.key,
    required this.transaction,
    required this.isBorrowed,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

