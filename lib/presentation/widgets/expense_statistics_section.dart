import 'package:flutter/material.dart';
import 'expense_statistics_card.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ExpenseStatisticsCard(
            label: 'Total',
            amount: totalExpenses,
            gradientColors: [Colors.blue.shade700, Colors.blue.shade500],
          ),
          const SizedBox(width: 12),
          ExpenseStatisticsCard(
            label: todayOrRangeLabel,
            amount: todayOrRangeExpenses,
            gradientColors: [Colors.green.shade600, Colors.green.shade400],
          ),
        ],
      ),
    );
  }
}

