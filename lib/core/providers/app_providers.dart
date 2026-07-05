import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/device_model.dart';
import '../../models/emergency_message.dart';
import '../../repositories/emergency_repository.dart';
import '../../services/firebase_service.dart';
import '../../services/forwarding_service.dart';
import '../../services/gemini_service.dart';
import '../../services/gps_service.dart';
import '../../services/nearby_service.dart';
import '../../services/permission_service.dart';
import '../../services/sqlite_service.dart';
import '../../services/sync_service.dart';
import '../constants/app_constants.dart';

final sqliteServiceProvider = Provider<SqliteService>((ref) => SqliteService());
final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(
    sqliteService: ref.read(sqliteServiceProvider),
    firebaseService: ref.read(firebaseServiceProvider),
  );
});

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class AppController extends ChangeNotifier {
  AppController(this.ref) {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    deviceName = 'LifeSaver-${suffix.substring(suffix.length - 5)}';
    _repository = ref.read(emergencyRepositoryProvider);
    _geminiService = ref.read(geminiServiceProvider);
    _gpsService = ref.read(gpsServiceProvider);
    _syncService = SyncService(repository: _repository);
    _nearbyService = NearbyService(
      deviceName: deviceName,
      onLog: addLog,
      onConnectionChanged: (endpointId) {
        connectionStatus = endpointId == null ? 'Waiting for peer' : 'Connected';
        notifyListeners();
      },
      onConnectedDevicesChanged: (count) {
        connectedDevicesCount = count;
        notifyListeners();
      },
      onDeviceConnected: _saveConnectedDevice,
      onEmergencyReceived: _handleIncomingEmergency,
    );
    _forwardingService = ForwardingService(
      repository: _repository,
      nearbyService: _nearbyService,
    );
    addLog('Ready. HOST on one phone, DISCOVER on another.');
    unawaited(refresh());
  }

  final Ref ref;
  final Uuid _uuid = const Uuid();
  late final EmergencyRepository _repository;
  late final GeminiService _geminiService;
  late final GpsService _gpsService;
  late final SyncService _syncService;
  late final NearbyService _nearbyService;
  late final ForwardingService _forwardingService;

  String deviceName = '';
  String connectionStatus = 'Offline Nearby ready';
  int connectedDevicesCount = 0;
  bool isBusy = false;
  bool isRescueNode = false;
  String inboxFilter = 'ALL';
  String syncStatus = 'Not synced';
  List<EmergencyMessage> emergencies = <EmergencyMessage>[];
  List<String> logs = <String>[];
  EmergencyMessage? latestIncomingAlert;
  int incomingAlertSerial = 0;

  int get pendingCount => emergencies.where((message) => message.status == AppConstants.statusPending).length;

  List<EmergencyMessage> get filteredEmergencies {
    if (inboxFilter == 'ALL') {
      return emergencies;
    }
    return emergencies.where((message) => message.status == inboxFilter).toList();
  }

  Future<void> refresh() async {
    emergencies = await _repository.getEmergencies();
    notifyListeners();
  }

  void setFilter(String filter) {
    inboxFilter = filter;
    notifyListeners();
  }

  Future<void> startHost() async {
    await _withNearbyPermissions(() async {
      connectionStatus = 'Advertising as host';
      notifyListeners();
      await _nearbyService.startHost();
    });
  }

  Future<void> startDiscover() async {
    await _withNearbyPermissions(() async {
      connectionStatus = 'Discovering nearby peers';
      notifyListeners();
      await _nearbyService.startDiscovery();
    });
  }

  Future<EmergencyMessage> draftEmergency({
    required String type,
    required int victims,
    required String description,
    required bool medicalEmergency,
    required double latitude,
    required double longitude,
    String? photoPath,
  }) async {
    final priority = await _geminiService.classifyPriority(
      type: type,
      victims: victims,
      description: description,
      medicalEmergency: medicalEmergency,
    );
    return EmergencyMessage(
      messageId: _uuid.v4(),
      senderDevice: deviceName,
      type: type,
      victims: victims,
      description: description,
      medicalEmergency: medicalEmergency,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      status: AppConstants.statusPending,
      photoPath: photoPath,
      ttl: 3,
      relayCount: 0,
    );
  }

  Future<void> sendEmergency(EmergencyMessage message) async {
    await _repository.saveEmergency(message);
    final relayed = await _forwardingService.forwardMessage(message);
    if (relayed > 0) {
      await _repository.markDelivered(message.messageId);
      addLog('SOS stored and relayed to $relayed nearby device(s).');
    } else {
      addLog('SOS stored locally. It will relay when a peer connects.');
    }
    await refresh();
  }

  Future<void> deleteEmergency(String messageId) async {
    await _repository.deleteEmergency(messageId);
    await refresh();
  }

  Future<GpsLocation?> getCurrentLocation() {
    return _gpsService.getCurrentLocation();
  }

  Future<void> toggleRescueNode(bool enabled) async {
    isRescueNode = enabled;
    notifyListeners();
    if (enabled) {
      addLog('Rescue Node mode enabled. Will sync when network is available.');
      _syncService.startAutoSync((synced) {
        syncStatus = synced == 0 ? 'No pending cloud uploads' : 'Synced $synced emergency record(s)';
        unawaited(refresh());
        notifyListeners();
      });
      await syncNow();
    } else {
      await _syncService.stopAutoSync();
      syncStatus = 'Auto sync disabled';
    }
  }

  Future<void> syncNow() async {
    syncStatus = 'Checking network...';
    notifyListeners();
    final synced = await _syncService.syncNow();
    syncStatus = synced == 0 ? 'No records synced. Offline or Firebase not configured.' : 'Synced $synced record(s)';
    await refresh();
  }

  Future<void> forwardStoredMessages() async {
    final relayed = await _forwardingService.forwardStoredMessages();
    addLog(relayed == 0 ? 'No stored SOS messages relayed.' : 'Relayed $relayed stored SOS message(s).');
  }

  Future<void> sendHelloTransportTest() async {
    await _nearbyService.sendHello();
  }

  void addLog(String message) {
    final now = DateTime.now();
    final stamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    logs = ['[$stamp] $message', ...logs].take(80).toList();
    notifyListeners();
  }

  Future<void> _withNearbyPermissions(Future<void> Function() action) async {
    if (isBusy) {
      return;
    }
    isBusy = true;
    notifyListeners();
    try {
      final result = await PermissionService.requestNearbyPermissions();
      if (result.deniedPermissions.isNotEmpty) {
        addLog('Permission warning: ${result.deniedPermissions.join(', ')} not granted.');
      }
      if (!result.locationServiceEnabled) {
        addLog('Location/GPS is off. Nearby may fail on some Android devices.');
      }
      await action();
      await _forwardingService.forwardStoredMessages();
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _saveConnectedDevice(String endpointId, String endpointName) {
    final now = DateTime.now().toUtc().toIso8601String();
    unawaited(_repository.saveDevice(DeviceModel(
      endpointId: endpointId,
      deviceName: endpointName,
      connectedAt: now,
      lastSeenAt: now,
      status: 'CONNECTED',
    )));
    unawaited(_forwardingService.forwardStoredMessages());
  }

  void _handleIncomingEmergency(EmergencyMessage message, String endpointId) {
    unawaited(_storeAndForwardIncoming(message, endpointId));
  }

  Future<void> _storeAndForwardIncoming(EmergencyMessage message, String endpointId) async {
    final exists = await _repository.emergencyExists(message.messageId);
    if (exists) {
      addLog('Duplicate SOS ${message.messageId} ignored.');
      return;
    }

    await _repository.saveEmergency(message.copyWith(status: AppConstants.statusPending));
    latestIncomingAlert = message;
    incomingAlertSerial++;
    addLog('Stored incoming SOS ${message.messageId}.');
    await _forwardingService.forwardMessage(message, excludeEndpointId: endpointId);
    await refresh();
  }

  @override
  void dispose() {
    _nearbyService.dispose();
    _syncService.stopAutoSync();
    super.dispose();
  }
}
