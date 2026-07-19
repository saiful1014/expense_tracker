import 'package:flutter/material.dart';
import '../../models/borrow_lend.dart';

class TransactionSubtitle extends StatelessWidget {
  final BorrowLend transaction;
  final bool isCompleted;
  final String Function(DateTime) formatDate;

  const TransactionSubtitle({
    super.key,
    required this.transaction,
    required this.isCompleted,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  formatDate(transaction.date),
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
    );
  }
}

