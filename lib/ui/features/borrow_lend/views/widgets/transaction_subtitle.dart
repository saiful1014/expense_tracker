import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transaction.description != null &&
            transaction.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            transaction.description!,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: secondaryText.withValues(alpha: 0.8),
            ),
          ),
        ],
        if (!isCompleted && transaction.paidAmount > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payment_outlined, size: 14, color: AppTheme.primaryLight),
              const SizedBox(width: 4),
              Text(
                'Paid: \$${transaction.paidAmount.toStringAsFixed(2)} (Remaining: \$${transaction.remainingAmount.toStringAsFixed(2)})',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: secondaryText.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  formatDate(transaction.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: secondaryText.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
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
                        ? Icons.arrow_downward_outlined
                        : Icons.arrow_upward_outlined,
                    size: 12,
                    color: transaction.type == 'borrow'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction.type == 'borrow'
                        ? 'You Owed'
                        : 'Owed to You',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: transaction.type == 'borrow'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            if (transaction.dueDate != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alarm_outlined,
                    size: 13,
                    color: !isCompleted && DateTime(transaction.dueDate!.year, transaction.dueDate!.month, transaction.dueDate!.day).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                        ? const Color(0xFFEF4444)
                        : secondaryText.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    !isCompleted && DateTime(transaction.dueDate!.year, transaction.dueDate!.month, transaction.dueDate!.day).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                        ? 'Overdue: ${formatDate(transaction.dueDate!)}'
                        : 'Due: ${formatDate(transaction.dueDate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: !isCompleted && DateTime(transaction.dueDate!.year, transaction.dueDate!.month, transaction.dueDate!.day).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: !isCompleted && DateTime(transaction.dueDate!.year, transaction.dueDate!.month, transaction.dueDate!.day).isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                          ? const Color(0xFFEF4444)
                          : secondaryText.withValues(alpha: 0.7),
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

