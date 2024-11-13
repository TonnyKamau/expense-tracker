import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expensetracker/syncing/sync.dart'; // Import the FirebaseSyncService

class SyncingCubit extends Cubit<bool> {
  final FirebaseSyncService _firebaseSyncService =
      FirebaseSyncService(); // Create an instance of FirebaseSyncService

  SyncingCubit() : super(false);

  void toggleSync(bool value) {
    emit(value);
    if (value) {
      _firebaseSyncService.startSyncing(); // Start syncing when enabled
    } else {
      _firebaseSyncService.stopSyncing(); // Stop syncing when disabled
    }
  }
}
