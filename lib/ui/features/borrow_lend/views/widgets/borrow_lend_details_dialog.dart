import 'package:flutter/material.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';

class BorrowLendDetailsDialog extends StatelessWidget {
  final BorrowLend transaction;
  final String Function(DateTime) formatDate;

  const BorrowLendDetailsDialog({
    super.key,
    required this.transaction,
    required this.formatDate,
  });

  static Future<void> show(
    BuildContext context, {
    required BorrowLend transaction,
    required String Function(DateTime) formatDate,
  }) {
    return showDialog(
      context: context,
      builder: (context) => BorrowLendDetailsDialog(
        transaction: transaction,
        formatDate: formatDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBorrowed = transaction.type == 'borrow';
    final primaryColor = isBorrowed ? Colors.red.shade700 : Colors.green.shade700;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = transaction.dueDate != null && 
        !transaction.completed && 
        DateTime(transaction.dueDate!.year, transaction.dueDate!.month, transaction.dueDate!.day).isBefore(today);

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
                color: primaryColor,
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
                      isBorrowed ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isBorrowed ? 'Money Borrowed' : 'Money Lent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.personName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
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
                  if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                    _buildDetailRow(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Description',
                      value: transaction.description!,
                    ),
                    const Divider(height: 24),
                  ],
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Date Initiated',
                    value: formatDate(transaction.date),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.alarm,
                    title: 'Due Date',
                    value: transaction.dueDate != null ? formatDate(transaction.dueDate!) : 'No due date set',
                    valueColor: isOverdue ? Colors.red.shade700 : null,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Status',
                    value: transaction.completed ? 'Completed' : (isOverdue ? 'Overdue' : 'Pending'),
                    valueColor: transaction.completed 
                        ? Colors.green.shade700 
                        : (isOverdue ? Colors.red.shade700 : Colors.orange.shade700),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.payment,
                    title: 'Payment Progress',
                    value: 'Paid: \$${transaction.paidAmount.toStringAsFixed(2)}\nRemaining: \$${transaction.remainingAmount.toStringAsFixed(2)}',
                  ),
                  if (transaction.repayments.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Repayment History',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: transaction.repayments.length,
                        itemBuilder: (context, index) {
                          final repayment = transaction.repayments[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade600),
                            title: Text(
                              'Paid \$${repayment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(formatDate(repayment.date)),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
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
