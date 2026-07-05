import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/emergency_repository.dart';

class SyncService {
  SyncService({required this.repository});

  final EmergencyRepository repository;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<bool> hasNetworkPath() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((type) => type != ConnectivityResult.none);
  }

  Future<int> syncNow() async {
    final online = await hasNetworkPath();
    if (!online) {
      return 0;
    }
    return repository.syncUnsynced();
  }

  void startAutoSync(void Function(int synced) onSynced) {
    _subscription ??= Connectivity().onConnectivityChanged.listen((result) async {
      if (result.any((type) => type != ConnectivityResult.none)) {
        final synced = await repository.syncUnsynced();
        onSynced(synced);
      }
    });
  }

  Future<void> stopAutoSync() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
