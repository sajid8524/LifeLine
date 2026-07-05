import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';

import '../models/emergency_message.dart';

class NearbyService {
  NearbyService({
    required this.deviceName,
    required this.onLog,
    required this.onConnectionChanged,
    this.onConnectedDevicesChanged,
    this.onDeviceConnected,
    this.onEmergencyReceived,
  });

  static const String serviceId = 'org.lifesaver.dtn.nearby.poc';
  static const Strategy strategy = Strategy.P2P_CLUSTER;

  final String deviceName;
  final void Function(String message) onLog;
  final void Function(String? endpointId) onConnectionChanged;
  final void Function(int count)? onConnectedDevicesChanged;
  final void Function(String endpointId, String endpointName)? onDeviceConnected;
  final void Function(EmergencyMessage message, String endpointId)? onEmergencyReceived;

  final Nearby _nearby = Nearby();
  String? _connectedEndpointId;
  final Set<String> _connectedEndpointIds = <String>{};
  final Map<String, String> _endpointNames = <String, String>{};
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  bool _isConnecting = false;

  String? get connectedEndpointId => _connectedEndpointId;
  Set<String> get connectedEndpointIds => Set.unmodifiable(_connectedEndpointIds);
  int get connectedDeviceCount => _connectedEndpointIds.length;

  Future<void> startHost() async {
    await stopDiscovery();
    onLog('Starting HOST advertising as $deviceName...');

    try {
      _isAdvertising = await _nearby.startAdvertising(
        deviceName,
        strategy,
        serviceId: serviceId,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );
      onLog(_isAdvertising ? 'HOST is advertising.' : 'HOST advertising did not start.');
    } catch (error) {
      onLog('HOST failed: $error');
    }
  }

  Future<void> startDiscovery() async {
    await stopAdvertising();
    onLog('Starting DISCOVER as $deviceName...');

    try {
      _isDiscovering = await _nearby.startDiscovery(
        deviceName,
        strategy,
        serviceId: serviceId,
        onEndpointFound: _handleEndpointFound,
        onEndpointLost: (endpointId) {
          onLog('Lost endpoint: ${endpointId ?? 'unknown'}');
        },
      );
      onLog(_isDiscovering ? 'DISCOVER is scanning.' : 'DISCOVER did not start.');
    } catch (error) {
      onLog('DISCOVER failed: $error');
    }
  }

  Future<void> sendHello() async {
    final endpointId = _connectedEndpointId;
    if (endpointId == null) {
      onLog('No connected endpoint. Run HOST on Phone A and DISCOVER on Phone B first.');
      return;
    }

    final bytes = Uint8List.fromList(utf8.encode('HELLO'));
    try {
      await _nearby.sendBytesPayload(endpointId, bytes);
      onLog('Sent to $endpointId: HELLO');
    } catch (error) {
      onLog('SEND HELLO failed: $error');
    }
  }

  Future<int> sendEmergency(EmergencyMessage message, {String? excludeEndpointId}) async {
    final endpoints = _connectedEndpointIds.where((endpointId) => endpointId != excludeEndpointId).toList();
    if (endpoints.isEmpty) {
      onLog('No connected endpoints available for SOS relay.');
      return 0;
    }

    var sent = 0;
    for (final endpointId in endpoints) {
      final delivered = await sendEmergencyToEndpoint(endpointId, message);
      if (delivered) {
        sent++;
      }
    }
    return sent;
  }

  Future<bool> sendEmergencyToEndpoint(String endpointId, EmergencyMessage message) async {
    final payload = Uint8List.fromList(utf8.encode(jsonEncode(message.toJson())));
    try {
      await _nearby.sendBytesPayload(endpointId, payload);
      onLog('Sent SOS ${message.messageId} to $endpointId.');
      return true;
    } catch (error) {
      onLog('SOS send failed for $endpointId: $error');
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) {
      return;
    }
    await _nearby.stopAdvertising();
    _isAdvertising = false;
    onLog('Stopped advertising.');
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) {
      return;
    }
    await _nearby.stopDiscovery();
    _isDiscovering = false;
    onLog('Stopped discovery.');
  }

  Future<void> dispose() async {
    await stopAdvertising();
    await stopDiscovery();
    await _nearby.stopAllEndpoints();
    _connectedEndpointIds.clear();
    _connectedEndpointId = null;
    onConnectedDevicesChanged?.call(0);
  }

  Future<void> _handleEndpointFound(
    String endpointId,
    String endpointName,
    String discoveredServiceId,
  ) async {
    if (_isConnecting || _connectedEndpointId != null) {
      return;
    }

    _isConnecting = true;
    _endpointNames[endpointId] = endpointName;
    onLog('Found $endpointName ($endpointId). Requesting connection...');
    await stopDiscovery();

    try {
      final requested = await _nearby.requestConnection(
        deviceName,
        endpointId,
        onConnectionInitiated: _handleConnectionInitiated,
        onConnectionResult: _handleConnectionResult,
        onDisconnected: _handleDisconnected,
      );
      onLog(requested ? 'Connection requested.' : 'Connection request was not accepted by API.');
    } catch (error) {
      _isConnecting = false;
      onLog('Connection request failed: $error');
    }
  }

  Future<void> _handleConnectionInitiated(
    String endpointId,
    ConnectionInfo connectionInfo,
  ) async {
    _endpointNames[endpointId] = connectionInfo.endpointName;
    onLog('Connection initiated with ${connectionInfo.endpointName} ($endpointId). Accepting...');

    try {
      final accepted = await _nearby.acceptConnection(
        endpointId,
        onPayLoadRecieved: _handlePayloadReceived,
        onPayloadTransferUpdate: _handlePayloadTransferUpdate,
      );
      onLog(accepted ? 'Connection accepted.' : 'Connection accept failed.');
    } catch (error) {
      onLog('Accept connection failed: $error');
    }
  }

  void _handleConnectionResult(String endpointId, Status status) {
    _isConnecting = false;

    if (status == Status.CONNECTED) {
      _connectedEndpointId = endpointId;
      _connectedEndpointIds.add(endpointId);
      onConnectionChanged(endpointId);
      onConnectedDevicesChanged?.call(_connectedEndpointIds.length);
      onDeviceConnected?.call(endpointId, _endpointNames[endpointId] ?? endpointId);
      onLog('CONNECTED to $endpointId.');
      return;
    }

    onLog('Connection result for $endpointId: ${status.name}');
  }

  void _handleDisconnected(String endpointId) {
    _connectedEndpointIds.remove(endpointId);
    _endpointNames.remove(endpointId);
    if (_connectedEndpointId == endpointId) {
      _connectedEndpointId = _connectedEndpointIds.isEmpty ? null : _connectedEndpointIds.first;
      onConnectionChanged(null);
    }
    onConnectedDevicesChanged?.call(_connectedEndpointIds.length);
    onLog('Disconnected from $endpointId.');
  }

  void _handlePayloadReceived(String endpointId, Payload payload) {
    if (payload.type != PayloadType.BYTES || payload.bytes == null) {
      onLog('Received non-byte payload from $endpointId.');
      return;
    }

    final raw = utf8.decode(payload.bytes!, allowMalformed: true);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final message = EmergencyMessage.fromJson(decoded);
        if (message.messageId.isNotEmpty) {
          onLog('Received SOS ${message.messageId} from $endpointId.');
          onEmergencyReceived?.call(message, endpointId);
          return;
        }
      }
    } catch (_) {
      // Fall through to raw logging so the original HELLO proof still works.
    }

    onLog('Received from $endpointId: $raw');
  }

  void _handlePayloadTransferUpdate(
    String endpointId,
    PayloadTransferUpdate update,
  ) {
    if (update.status == PayloadStatus.SUCCESS) {
      onLog('Payload ${update.id} transfer complete with $endpointId.');
    }
  }
}
