class DeviceModel {
  const DeviceModel({
    required this.endpointId,
    required this.deviceName,
    required this.connectedAt,
    required this.lastSeenAt,
    required this.status,
  });

  final String endpointId;
  final String deviceName;
  final String connectedAt;
  final String lastSeenAt;
  final String status;

  Map<String, dynamic> toDb() {
    return {
      'endpointId': endpointId,
      'deviceName': deviceName,
      'connectedAt': connectedAt,
      'lastSeenAt': lastSeenAt,
      'status': status,
    };
  }
}
