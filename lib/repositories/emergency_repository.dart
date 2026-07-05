import '../core/constants/app_constants.dart';
import '../models/device_model.dart';
import '../models/emergency_message.dart';
import '../services/firebase_service.dart';
import '../services/sqlite_service.dart';

class EmergencyRepository {
  EmergencyRepository({
    required this.sqliteService,
    required this.firebaseService,
  });

  final SqliteService sqliteService;
  final FirebaseService firebaseService;

  Future<void> saveEmergency(EmergencyMessage message) {
    return sqliteService.upsertEmergency(message);
  }

  Future<bool> emergencyExists(String messageId) {
    return sqliteService.emergencyExists(messageId);
  }

  Future<List<EmergencyMessage>> getEmergencies({String? status}) {
    return sqliteService.getEmergencies(status: status);
  }

  Future<void> deleteEmergency(String messageId) {
    return sqliteService.deleteEmergency(messageId);
  }

  Future<void> markDelivered(String messageId) {
    return sqliteService.updateEmergencyStatus(messageId, AppConstants.statusDelivered);
  }

  Future<List<EmergencyMessage>> getForwardableEmergencies() {
    return sqliteService.getForwardableEmergencies();
  }

  Future<bool> wasForwardedToDevice(String messageId, String deviceId) {
    return sqliteService.wasForwardedToDevice(messageId, deviceId);
  }

  Future<void> markForwarded(String messageId, String deviceId) {
    return sqliteService.addForwardingLog(messageId, deviceId, 'RELAYED');
  }

  Future<void> saveDevice(DeviceModel device) {
    return sqliteService.upsertDevice(device);
  }

  Future<int> syncUnsynced() async {
    final unsynced = await sqliteService.getUnsyncedEmergencies();
    var synced = 0;
    for (final message in unsynced) {
      final uploaded = await firebaseService.uploadEmergency(message);
      if (uploaded) {
        await sqliteService.updateEmergencyStatus(message.messageId, AppConstants.statusSynced);
        await sqliteService.addSyncLog(message.messageId, 'UPLOAD', 'Uploaded to Firestore');
        synced++;
      } else {
        await sqliteService.addSyncLog(
          message.messageId,
          'UPLOAD_FAILED',
          firebaseService.lastError ?? 'Firebase unavailable',
        );
      }
    }
    return synced;
  }
}
