import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/emergency_message.dart';

class FirebaseService {
  static const emergenciesCollection = 'emergencies';

  bool _available = false;
  bool _initialized = false;
  String? lastError;

  bool get isAvailable => _available;

  Future<bool> initialize() async {
    if (_initialized) {
      return _available;
    }
    _initialized = true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _available = true;
      lastError = null;
      return true;
    } catch (error) {
      _available = false;
      lastError = error.toString();
      return false;
    }
  }

  Future<bool> uploadEmergency(EmergencyMessage message) async {
    final ready = await initialize();
    if (!ready) {
      return false;
    }

    try {
      final data = Map<String, dynamic>.from(message.toJson());
      data['syncedAt'] = DateTime.now().toUtc().toIso8601String();
      await FirebaseFirestore.instance.collection(emergenciesCollection).doc(message.messageId).set(data);
      lastError = null;
      return true;
    } catch (error) {
      lastError = error.toString();
      return false;
    }
  }
}
