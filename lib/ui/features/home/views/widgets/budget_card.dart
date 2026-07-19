import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class BudgetCard extends StatelessWidget {
  final ExpenseViewModel controller;
  final VoidCallback onEdit;

  const BudgetCard({
    super.key,
    required this.controller,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (controller.budgetLimit == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.add_road_outlined, size: 20),
            label: Text(
              'Set Monthly Budget Limit',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      );
    }

    final spent = controller.totalExpenses;
    final limit = controller.budgetLimit;
    final factor = (spent / limit).clamp(0.0, 1.0);
    final percent = (spent / limit) * 100;

    Color progressColor = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    if (percent >= 100) {
      progressColor = const Color(0xFFEF4444); // Crimson
    } else if (percent >= 80) {
      progressColor = const Color(0xFFF59E0B); // Amber
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${spent.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.borderDark : AppTheme.borderLight).withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: factor,
                color: progressColor,
                backgroundColor: isDark ? AppTheme.borderDark : const Color(0xFFF1F5F9),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              percent >= 100
                  ? '⚠️ Monthly budget limit reached!'
                  : '${(100 - percent).toStringAsFixed(0)}% of monthly budget remaining',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: percent >= 80 ? progressColor : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
