import 'package:test_new_things/domain/repositories/expense_repository.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';

class DeleteExpense {
  final ExpenseRepository repository;
  final ConnectivityService connectivity;
  final CloudSyncService cloudSync;

  DeleteExpense({
    required this.repository,
    required this.connectivity,
    required this.cloudSync,
  });

  Future<bool> canDelete() async {
    final hasInternet = await connectivity.hasInternetConnection();
    if (!hasInternet) return false;
    
    final isSignedIn = await cloudSync.isSignedIn();
    return isSignedIn;
  }

  Future<void> call(int id) async {
    // Delete from cloud first
    await repository.deleteFromCloud(id);
    // Delete from local database
    await repository.deleteExpense(id);
  }
}

