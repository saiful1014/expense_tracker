import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class TransactionTrailing extends StatelessWidget {
  final BorrowLend transaction;
  final bool isBorrowed;
  final bool isCompleted;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onMarkPending;
  final VoidCallback? onAddRepayment;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TransactionTrailing({
    super.key,
    required this.transaction,
    required this.isBorrowed,
    required this.isCompleted,
    this.onMarkCompleted,
    this.onMarkPending,
    this.onAddRepayment,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${transaction.amount.toStringAsFixed(2)}',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isCompleted
                ? secondaryText.withValues(alpha: 0.6)
                : (isBorrowed ? const Color(0xFFEF4444) : const Color(0xFF0D9488)),
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompleted && onAddRepayment != null)
              GestureDetector(
                onTap: onAddRepayment,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment_outlined,
                    size: 15,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            if (!isCompleted && onAddRepayment != null) const SizedBox(width: 5),
            if (!isCompleted && onMarkCompleted != null)
              GestureDetector(
                onTap: onMarkCompleted,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 15,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            if (!isCompleted && onMarkCompleted != null) const SizedBox(width: 5),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
                ),
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 15,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            if (isCompleted && onMarkPending != null)
              GestureDetector(
                onTap: onMarkPending,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restart_alt_outlined,
                    size: 15,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

