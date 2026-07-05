import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants/app_constants.dart';

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<String> classifyPriority({
    required String type,
    required int victims,
    required String description,
    required bool medicalEmergency,
  }) async {
    final fallback = _heuristicPriority(type, victims, description, medicalEmergency);
    if (_apiKey.isEmpty) {
      return fallback;
    }

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final prompt = '''
Classify this emergency as exactly one token: LOW, MEDIUM, HIGH, or CRITICAL.
Type: $type
Victims: $victims
Medical emergency: $medicalEmergency
Description: $description
''';
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.toUpperCase() ?? '';
      if (text.contains('CRITICAL')) {
        return AppConstants.priorityCritical;
      }
      if (text.contains('HIGH')) {
        return AppConstants.priorityHigh;
      }
      if (text.contains('LOW')) {
        return AppConstants.priorityLow;
      }
      if (text.contains('MEDIUM')) {
        return AppConstants.priorityMedium;
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _heuristicPriority(String type, int victims, String description, bool medicalEmergency) {
    final text = '$type $description'.toLowerCase();
    if (text.contains('not breathing') ||
        text.contains('trapped') ||
        text.contains('unconscious') ||
        text.contains('fire') ||
        victims >= 8) {
      return AppConstants.priorityCritical;
    }
    if (medicalEmergency || victims >= 3 || text.contains('ambulance') || text.contains('collapse')) {
      return AppConstants.priorityHigh;
    }
    if (victims > 0 || text.contains('injured') || text.contains('flood')) {
      return AppConstants.priorityMedium;
    }
    return AppConstants.priorityLow;
  }
}
