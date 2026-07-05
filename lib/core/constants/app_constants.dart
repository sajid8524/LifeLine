import 'package:flutter/material.dart';

class AppConstants {
  static const appName = 'LifeSaver DTN';
  static const tagline = 'Emergency communication when traditional communication fails.';
  static const serviceId = 'org.lifesaver.dtn.nearby.poc';
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const emergencyTypes = <String>[
    'TRAIN_ACCIDENT',
    'EARTHQUAKE',
    'FLOOD',
    'BUILDING_COLLAPSE',
    'MEDICAL_EMERGENCY',
    'FIRE',
    'OTHER',
  ];

  static const statusPending = 'PENDING';
  static const statusDelivered = 'DELIVERED';
  static const statusSynced = 'SYNCED';

  static const priorityCritical = 'CRITICAL';
  static const priorityHigh = 'HIGH';
  static const priorityMedium = 'MEDIUM';
  static const priorityLow = 'LOW';

  static const criticalColor = Color(0xFFD32F2F);
  static const mediumColor = Color(0xFFF57C00);
  static const lowColor = Color(0xFF388E3C);
}
