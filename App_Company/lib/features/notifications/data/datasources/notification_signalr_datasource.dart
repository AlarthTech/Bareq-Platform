import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/realtime_hub_event.dart';
import '../mappers/realtime_payload_mapper.dart';
import '../models/notification_model.dart';

abstract class NotificationSignalRDataSource {
  Stream<RealtimeHubEvent> get events;

  Future<void> connect(String accessToken);

  Future<void> disconnect();
}

class NotificationSignalRDataSourceImpl implements NotificationSignalRDataSource {
  HubConnection? _connection;
  final _controller = StreamController<RealtimeHubEvent>.broadcast();

  @override
  Stream<RealtimeHubEvent> get events => _controller.stream;

  @override
  Future<void> connect(String accessToken) async {
    await disconnect();

    final hubUrl =
        '${ApiConstants.baseUrl}${ApiConstants.notificationsHub}?access_token=$accessToken';

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            skipNegotiation: false,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveNotification', _onReceiveNotification);
    _connection!.on('BookingStatusChanged', _onBookingStatusChanged);

    _connection!.onreconnecting(({Exception? error}) {
      // Hub reconnecting — connection stays alive.
    });

    await _connection!.start();
  }

  void _onReceiveNotification(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    try {
      final notificationRaw = arguments[0];
      final unreadRaw = arguments.length > 1 ? arguments[1] : null;

      if (notificationRaw is! Map) return;

      final notification = NotificationModel.fromJson(
        Map<String, dynamic>.from(notificationRaw),
      ).toEntity();

      final unreadCount = _parseUnread(unreadRaw);

      final update = NotificationRealtimeUpdate(
        notification: notification,
        unreadCount: unreadCount ?? -1,
      );

      _controller.add(RealtimeNotificationReceived(update));
      _controller.add(
        RealtimeToastMessage(
          notification.messageAr?.trim().isNotEmpty == true
              ? notification.messageAr!.trim()
              : notification.message,
        ),
      );
    } catch (_) {}
  }

  void _onBookingStatusChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    try {
      final raw = arguments[0];
      if (raw is! Map) return;

      final json = Map<String, dynamic>.from(raw);
      final bookingEvent = RealtimePayloadMapper.bookingStatusFromMap(json);
      if (bookingEvent == null) return;

      final notification = RealtimePayloadMapper.notificationFromMap(json);
      final notificationUpdate = notification != null
          ? NotificationRealtimeUpdate(
              notification: notification,
              unreadCount: -1,
            )
          : null;

      _controller.add(
        RealtimeBookingStatusChanged(
          bookingEvent: bookingEvent,
          notificationUpdate: notificationUpdate,
        ),
      );

      _controller.add(RealtimeToastMessage(bookingEvent.message));
    } catch (_) {}
  }

  int? _parseUnread(dynamic unreadRaw) {
    if (unreadRaw == null) return null;
    return switch (unreadRaw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
  }

  @override
  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      try {
        await connection.stop();
      } catch (_) {}
    }
  }
}
