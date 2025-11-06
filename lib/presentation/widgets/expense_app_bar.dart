import 'package:flutter/material.dart';

class ExpenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String Function(DateTime) formatDate;
  final VoidCallback onCloudSync;
  final VoidCallback onBorrowLend;
  final VoidCallback onDateRange;
  final VoidCallback? onClearFilter;

  const ExpenseAppBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.formatDate,
    required this.onCloudSync,
    required this.onBorrowLend,
    required this.onDateRange,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Expenses'),
          if (startDate != null && endDate != null)
            Text(
              startDate == endDate
                  ? formatDate(startDate!)
                  : '${formatDate(startDate!)} - ${formatDate(endDate!)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.cloud),
          tooltip: 'Cloud Sync',
          onPressed: onCloudSync,
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          tooltip: 'Borrow & Lend',
          onPressed: onBorrowLend,
        ),
        IconButton(
          icon: const Icon(Icons.date_range),
          tooltip: 'Filter by date range',
          onPressed: onDateRange,
        ),
        if (onClearFilter != null)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Show all expenses',
            onPressed: onClearFilter,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

