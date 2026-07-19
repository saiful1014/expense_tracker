import 'package:flutter/material.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/borrow_lend_screen.dart' deferred as borrow_lend;

class DeferredBorrowLend extends StatefulWidget {
  const DeferredBorrowLend({super.key});

  // This static flag survives as long as the app is running.
  static bool _isLoaded = false;

  @override
  State<DeferredBorrowLend> createState() => _DeferredBorrowLendState();
}

class _DeferredBorrowLendState extends State<DeferredBorrowLend> {
  late Future<void> _libraryFuture;

  @override
  void initState() {
    super.initState();
    // If it's already loaded, we still call loadLibrary() (it's fast),
    // but the UI will check the _isLoaded flag to skip the spinner.
    _libraryFuture = borrow_lend.loadLibrary().then((_) {
      DeferredBorrowLend._isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we already know it's loaded, show the screen immediately!
    if (DeferredBorrowLend._isLoaded) {
      return borrow_lend.BorrowLendScreen();
    }

    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Text('Failed to load component: ${snapshot.error}'),
              ),
            );
          }
          return borrow_lend.BorrowLendScreen();
        }
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading Borrow/Lend Feature...'),
              ],
            ),
          ),
        );
      },
    );
  }
}
