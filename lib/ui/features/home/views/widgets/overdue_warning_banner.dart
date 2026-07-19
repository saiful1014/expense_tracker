import 'package:flutter/material.dart';

class OverdueWarningBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const OverdueWarningBanner({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: Colors.red.shade800),
        title: Text(
          'You have $count pending payments due today or overdue!',
          style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        subtitle: const Text('Tap to view and manage payments', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.red),
        onTap: onTap,
      ),
    );
  }
}
