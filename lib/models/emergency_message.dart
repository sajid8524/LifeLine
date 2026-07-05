import '../core/constants/app_constants.dart';

class EmergencyMessage {
  const EmergencyMessage({
    required this.messageId,
    required this.senderDevice,
    required this.type,
    required this.victims,
    required this.description,
    required this.medicalEmergency,
    required this.priority,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    this.photoPath,
    this.ttl = 3,
    this.relayCount = 0,
  });

  final String messageId;
  final String senderDevice;
  final String type;
  final int victims;
  final String description;
  final bool medicalEmergency;
  final String priority;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String status;
  final String? photoPath;
  final int ttl;
  final int relayCount;

  EmergencyMessage copyWith({
    String? messageId,
    String? senderDevice,
    String? type,
    int? victims,
    String? description,
    bool? medicalEmergency,
    String? priority,
    double? latitude,
    double? longitude,
    String? timestamp,
    String? status,
    String? photoPath,
    int? ttl,
    int? relayCount,
  }) {
    return EmergencyMessage(
      messageId: messageId ?? this.messageId,
      senderDevice: senderDevice ?? this.senderDevice,
      type: type ?? this.type,
      victims: victims ?? this.victims,
      description: description ?? this.description,
      medicalEmergency: medicalEmergency ?? this.medicalEmergency,
      priority: priority ?? this.priority,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      ttl: ttl ?? this.ttl,
      relayCount: relayCount ?? this.relayCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderDevice': senderDevice,
      'type': type,
      'victims': victims,
      'description': description,
      'medicalEmergency': medicalEmergency,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'status': status,
      'photoPath': photoPath,
      'ttl': ttl,
      'relayCount': relayCount,
    };
  }

  Map<String, dynamic> toDb() {
    return {
      'messageId': messageId,
      'senderDevice': senderDevice,
      'type': type,
      'victims': victims,
      'description': description,
      'medicalEmergency': medicalEmergency ? 1 : 0,
      'priority': priority,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'status': status,
      'photoPath': photoPath,
      'ttl': ttl,
      'relayCount': relayCount,
    };
  }

  factory EmergencyMessage.fromJson(Map<String, dynamic> json) {
    return EmergencyMessage(
      messageId: json['messageId']?.toString() ?? '',
      senderDevice: json['senderDevice']?.toString() ?? 'UNKNOWN',
      type: json['type']?.toString() ?? AppConstants.emergencyTypes.last,
      victims: _asInt(json['victims']),
      description: json['description']?.toString() ?? '',
      medicalEmergency: _asBool(json['medicalEmergency']),
      priority: json['priority']?.toString() ?? AppConstants.priorityMedium,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      status: json['status']?.toString() ?? AppConstants.statusPending,
      photoPath: json['photoPath']?.toString(),
      ttl: _asInt(json['ttl'], fallback: 3),
      relayCount: _asInt(json['relayCount']),
    );
  }

  factory EmergencyMessage.fromDb(Map<String, Object?> row) {
    return EmergencyMessage(
      messageId: row['messageId'] as String,
      senderDevice: row['senderDevice'] as String,
      type: row['type'] as String,
      victims: row['victims'] as int,
      description: row['description'] as String,
      medicalEmergency: (row['medicalEmergency'] as int) == 1,
      priority: row['priority'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      timestamp: row['timestamp'] as String,
      status: row['status'] as String,
      photoPath: row['photoPath'] as String?,
      ttl: _asInt(row['ttl'], fallback: 3),
      relayCount: _asInt(row['relayCount']),
    );
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    return value?.toString().toLowerCase() == 'true';
  }
}
