import '../../domain/entities/realtime_hub_event.dart';
import '../repositories/notification_repository.dart';

class SubscribeToNotificationsUseCase {
  SubscribeToNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Stream<RealtimeHubEvent> watchHubEvents() => _repository.watchHubEvents();

  Stream<String> watchToastMessages() => _repository
      .watchHubEvents()
      .where((event) => event is RealtimeToastMessage)
      .map((event) => (event as RealtimeToastMessage).message);

  Future<void> connect(String accessToken) {
    return _repository.connectRealtime(accessToken);
  }

  Future<void> disconnect() {
    return _repository.disconnectRealtime();
  }
}
