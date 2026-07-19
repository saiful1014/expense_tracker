import 'package:flutter/material.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/transaction_header.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/transaction_subtitle.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/widgets/transaction_trailing.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class TransactionCard extends StatelessWidget {
  final BorrowLend transaction;
  final bool isBorrowed;
  final bool isCompleted;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkPending;
  final VoidCallback? onAddRepayment;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.isBorrowed,
    this.isCompleted = false,
    this.onMarkCompleted,
    this.onMarkPending,
    this.onAddRepayment,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color primaryColor = isCompleted
        ? const Color(0xFF0D9488) // Teal
        : (isBorrowed ? const Color(0xFFEF4444) : const Color(0xFF0D9488));

    return Dismissible(
      key: Key('borrow_lend_${transaction.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCompleted
                ? const Color(0xFF2DD4BF).withValues(alpha: 0.3)
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: isCompleted
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.04 : 0.02),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  // Icon Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline
                          : (isBorrowed ? Icons.arrow_downward_outlined : Icons.arrow_upward_outlined),
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TransactionHeader(
                          transaction: transaction,
                          isBorrowed: isBorrowed,
                          isCompleted: isCompleted,
                        ),
                        TransactionSubtitle(
                          transaction: transaction,
                          isCompleted: isCompleted,
                          formatDate: formatDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Trailing details (amount + actions)
                  TransactionTrailing(
                    transaction: transaction,
                    isBorrowed: isBorrowed,
                    isCompleted: isCompleted,
                    onMarkCompleted: onMarkCompleted,
                    onMarkPending: onMarkPending,
                    onAddRepayment: onAddRepayment,
                    onDelete: onDelete,
                    onEdit: onEdit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
