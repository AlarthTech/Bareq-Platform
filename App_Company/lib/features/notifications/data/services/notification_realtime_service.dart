import 'dart:async';

import '../../domain/entities/booking_status_changed_event.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/realtime_hub_event.dart';
import '../datasources/notification_signalr_datasource.dart';

/// Singleton realtime bridge for SignalR notification + booking events.
class NotificationRealtimeService {
  NotificationRealtimeService(this._signalRDataSource);

  final NotificationSignalRDataSource _signalRDataSource;

  StreamSubscription<RealtimeHubEvent>? _hubSub;
  final _eventsController = StreamController<RealtimeHubEvent>.broadcast();

  Stream<RealtimeHubEvent> get events => _eventsController.stream;

  Stream<NotificationRealtimeUpdate> get notificationUpdates =>
      events
          .where((event) => event is RealtimeNotificationReceived)
          .map((event) => (event as RealtimeNotificationReceived).update);

  Stream<BookingStatusChangedEvent> get bookingStatusChanges =>
      events
          .where((event) => event is RealtimeBookingStatusChanged)
          .map((event) => (event as RealtimeBookingStatusChanged).bookingEvent);

  Stream<String> get toastMessages =>
      events
          .where((event) => event is RealtimeToastMessage)
          .map((event) => (event as RealtimeToastMessage).message);

  bool get isConnected => _hubSub != null;

  Future<void> connect(String accessToken) async {
    await disconnect();
    await _signalRDataSource.connect(accessToken);
    _hubSub = _signalRDataSource.events.listen(
      _eventsController.add,
      onError: (_) {},
    );
  }

  Future<void> disconnect() async {
    await _hubSub?.cancel();
    _hubSub = null;
    await _signalRDataSource.disconnect();
  }
}
