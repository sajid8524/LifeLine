import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../../models/emergency_message.dart';

String readableEmergencyType(String type) {
  return type
      .split('_')
      .map((part) => part.isEmpty ? part : '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String shortTime(String isoTimestamp) {
  final parsed = DateTime.tryParse(isoTimestamp)?.toLocal();
  if (parsed == null) {
    return isoTimestamp;
  }
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Color priorityColor(String priority) {
  switch (priority.toUpperCase()) {
    case AppConstants.priorityCritical:
    case AppConstants.priorityHigh:
      return AppConstants.criticalColor;
    case AppConstants.priorityMedium:
      return AppConstants.mediumColor;
    default:
      return AppConstants.lowColor;
  }
}

String shareText(EmergencyMessage message) {
  return [
    'LifeSaver DTN Emergency',
    'Type: ${readableEmergencyType(message.type)}',
    'Victims: ${message.victims}',
    'Priority: ${message.priority}',
    'Location: ${message.latitude}, ${message.longitude}',
    'Status: ${message.status}',
    'Description: ${message.description}',
  ].join('\n');
}
