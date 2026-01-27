import 'package:flutter/material.dart';
import '../../models/borrow_lend.dart';

class TransactionTrailing extends StatelessWidget {
  final BorrowLend transaction;
  final bool isBorrowed;
  final bool isCompleted;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkPending;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionTrailing({
    super.key,
    required this.transaction,
    required this.isBorrowed,
    required this.isCompleted,
    this.onMarkCompleted,
    this.onMarkPending,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            if (!isCompleted && onMarkCompleted != null)
              GestureDetector(
                onTap: onMarkCompleted,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            if (!isCompleted && onMarkCompleted != null) const SizedBox(width: 4),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.blue.shade400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red.shade400,
                ),
              ),
            ),
            if (isCompleted && onMarkPending != null)
              GestureDetector(
                onTap: onMarkPending,
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
    );
  }
}

