import 'package:flutter/material.dart';
import 'package:test_new_things/ui/features/expenses/views/widgets/expense_statistics_card.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class ExpenseStatisticsSection extends StatelessWidget {
  final double totalExpenses;
  final double todayOrRangeExpenses;
  final String todayOrRangeLabel;

  const ExpenseStatisticsSection({
    super.key,
    required this.totalExpenses,
    required this.todayOrRangeExpenses,
    required this.todayOrRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = AppTheme.getPrimaryGradient(isDark);
    final accentGradient = AppTheme.getAccentGradient(isDark);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Row(
        children: [
          ExpenseStatisticsCard(
            label: 'Total Spends',
            amount: totalExpenses,
            gradientColors: primaryGradient,
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(width: 12),
          ExpenseStatisticsCard(
            label: todayOrRangeLabel,
            amount: todayOrRangeExpenses,
            gradientColors: accentGradient,
            icon: Icons.today_outlined,
          ),
        ],
      ),
    );
  }
}

