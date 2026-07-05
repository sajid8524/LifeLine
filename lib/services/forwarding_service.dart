import '../models/emergency_message.dart';
import '../repositories/emergency_repository.dart';
import 'nearby_service.dart';

class ForwardingService {
  ForwardingService({
    required this.repository,
    required this.nearbyService,
  });

  final EmergencyRepository repository;
  final NearbyService nearbyService;

  Future<int> forwardMessage(
    EmergencyMessage message, {
    String? excludeEndpointId,
  }) async {
    if (message.ttl <= 0) {
      return 0;
    }

    var relayed = 0;
    final nextHop = message.copyWith(
      ttl: message.ttl - 1,
      relayCount: message.relayCount + 1,
    );

    for (final endpointId in nearbyService.connectedEndpointIds) {
      if (endpointId == excludeEndpointId) {
        continue;
      }
      final alreadyForwarded = await repository.wasForwardedToDevice(message.messageId, endpointId);
      if (alreadyForwarded) {
        continue;
      }
      final sent = await nearbyService.sendEmergencyToEndpoint(endpointId, nextHop);
      if (sent) {
        await repository.markForwarded(message.messageId, endpointId);
        relayed++;
      }
    }

    return relayed;
  }

  Future<int> forwardStoredMessages({String? excludeEndpointId}) async {
    final messages = await repository.getForwardableEmergencies();
    var relayed = 0;
    for (final message in messages) {
      relayed += await forwardMessage(message, excludeEndpointId: excludeEndpointId);
    }
    return relayed;
  }
}
