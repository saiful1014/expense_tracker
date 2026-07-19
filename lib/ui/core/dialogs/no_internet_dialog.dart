import 'package:flutter/material.dart';

class NoInternetDialog {
  static Future<void> show(BuildContext context, {String? message}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: Text(
          message ??
              'You cannot perform this action without an internet connection. Please connect to the internet and try again.',
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

