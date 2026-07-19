import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;

  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    required this.getCategoryColor,
    required this.getCategoryIcon,
    required this.formatDate,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = getCategoryColor(expense.category);
    final catIcon = getCategoryIcon(expense.category);

    return Dismissible(
      key: Key('expense_${expense.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false; // Return false so the state-driven delete handles card removal
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Category Icon with 10% opacity background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    catIcon,
                    color: catColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expense.description,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expense.category}  •  ${formatDate(expense.date)}  •  ${formatTime(expense.date)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right Column (Amount + Edit Action)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '-\$${expense.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444), // Crimson
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

