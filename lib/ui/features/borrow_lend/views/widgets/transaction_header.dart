import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            transaction.personName,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted
                  ? (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withValues(alpha: 0.7)
                  : null,
            ),
          ),
        ),
        if (isCompleted) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: transaction.type == 'borrow'
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : const Color(0xFF0D9488).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  transaction.type == 'borrow'
                      ? Icons.arrow_downward_outlined
                      : Icons.arrow_upward_outlined,
                  size: 11,
                  color: transaction.type == 'borrow'
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0D9488),
                ),
                const SizedBox(width: 3),
                Text(
                  transaction.type == 'borrow' ? 'Borrow' : 'Lend',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == 'borrow'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Completed',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D9488),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

