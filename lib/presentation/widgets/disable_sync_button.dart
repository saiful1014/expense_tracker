import 'package:flutter/material.dart';

class DisableSyncButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const DisableSyncButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: const Icon(Icons.cloud_off),
      label: const Text('Disable Cloud Sync'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

