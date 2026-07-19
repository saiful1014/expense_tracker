import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/data/services/notification_service.dart';

class DeleteBorrowLend {
  final BorrowLendRepository repository;
  final ConnectivityService connectivity;
  final CloudSyncService cloudSync;

  DeleteBorrowLend({
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
    // Cancel any scheduled reminder
    await NotificationService.instance.cancelNotification(id);
    // Delete from cloud first
    await repository.deleteFromCloud(id);
    // Delete from local database
    await repository.deleteBorrowLend(id);
  }
}

