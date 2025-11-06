import 'package:flutter/material.dart';
import '../../models/borrow_lend.dart';
import 'transaction_header.dart';
import 'transaction_subtitle.dart';
import 'transaction_trailing.dart';

class TransactionCard extends StatelessWidget {
  final BorrowLend transaction;
  final bool isBorrowed;
  final bool isCompleted;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkPending;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDate;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.isBorrowed,
    this.isCompleted = false,
    this.onMarkCompleted,
    this.onMarkPending,
    required this.onDelete,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompleted
            ? BorderSide(color: Colors.green.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isCompleted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade50.withValues(alpha: 0.3),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isCompleted
                ? Colors.green.shade100
                : (isBorrowed ? Colors.red.shade100 : Colors.green.shade100),
            child: Icon(
              isCompleted
                  ? Icons.check_circle
                  : (isBorrowed ? Icons.arrow_downward : Icons.arrow_upward),
              color: isCompleted
                  ? Colors.green.shade700
                  : (isBorrowed ? Colors.red.shade700 : Colors.green.shade700),
            ),
          ),
          title: TransactionHeader(
            transaction: transaction,
            isBorrowed: isBorrowed,
            isCompleted: isCompleted,
          ),
          subtitle: TransactionSubtitle(
            transaction: transaction,
            isCompleted: isCompleted,
            formatDate: formatDate,
          ),
          trailing: TransactionTrailing(
            transaction: transaction,
            isBorrowed: isBorrowed,
            isCompleted: isCompleted,
            onMarkCompleted: onMarkCompleted,
            onMarkPending: onMarkPending,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }
}
