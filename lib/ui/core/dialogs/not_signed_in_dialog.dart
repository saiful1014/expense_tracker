import 'package:flutter/material.dart';

class NotSignedInDialog {
  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not Signed In'),
        content: Text(
          message ??
              'You need to be signed in to perform this action. Please sign in and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

