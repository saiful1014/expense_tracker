import 'package:flutter/material.dart';
import 'package:test_new_things/domain/models/expense.dart';

class ExpenseDetailsDialog extends StatelessWidget {
  final Expense expense;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final Color Function(String) getCategoryColor;
  final IconData Function(String) getCategoryIcon;

  const ExpenseDetailsDialog({
    super.key,
    required this.expense,
    required this.formatDate,
    required this.formatTime,
    required this.getCategoryColor,
    required this.getCategoryIcon,
  });

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required String Function(DateTime) formatDate,
    required String Function(DateTime) formatTime,
    required Color Function(String) getCategoryColor,
    required IconData Function(String) getCategoryIcon,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExpenseDetailsDialog(
        expense: expense,
        formatDate: formatDate,
        formatTime: formatTime,
        getCategoryColor: getCategoryColor,
        getCategoryIcon: getCategoryIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = getCategoryColor(expense.category);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(
                      getCategoryIcon(expense.category),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    expense.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Description',
                    value: expense.description,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Date',
                    value: formatDate(expense.date),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time_outlined,
                    title: 'Time',
                    value: formatTime(expense.date),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.sync_outlined,
                    title: 'Type',
                    value: expense.isRecurring
                        ? 'Recurring Subscription (${expense.recurrenceInterval ?? 'N/A'})'
                        : 'One-time Expense',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.cloud_done_outlined,
                    title: 'Sync Status',
                    value: expense.synced ? 'Synced with Cloud' : 'Pending Local Sync',
                    valueColor: expense.synced ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: categoryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
