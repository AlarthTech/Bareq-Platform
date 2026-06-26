import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../../../core/auth/secure_token_storage.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../booking/domain/entities/booking_status_changed_event.dart';
import '../../domain/entities/notification_entity.dart';
import '../models/notification_model.dart';

abstract class NotificationSignalRDataSource {
  Stream<NotificationRealtimeUpdate> watchNotifications();

  Stream<BookingStatusChangedEvent> watchBookingStatusChanges();

  Future<void> connect();

  Future<void> disconnect();

  bool get isConnected;
}

class NotificationSignalRDataSourceImpl
    implements NotificationSignalRDataSource {
  NotificationSignalRDataSourceImpl(this._tokenStorage);

  final SecureTokenStorage _tokenStorage;
  HubConnection? _connection;
  final _controller = StreamController<NotificationRealtimeUpdate>.broadcast();
  final _bookingStatusController =
      StreamController<BookingStatusChangedEvent>.broadcast();

  @override
  Stream<BookingStatusChangedEvent> watchBookingStatusChanges() =>
      _bookingStatusController.stream;

  @override
  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  @override
  Stream<NotificationRealtimeUpdate> watchNotifications() =>
      _controller.stream;

  @override
  Future<void> connect() async {
    if (_connection?.state == HubConnectionState.Connected ||
        _connection?.state == HubConnectionState.Connecting) {
      return;
    }

    await disconnect();

    final options = HttpConnectionOptions(
      accessTokenFactory: () async =>
          await _tokenStorage.readAccessToken() ?? '',
      transport: HttpTransportType.WebSockets,
      skipNegotiation: false,
    );

    _connection = HubConnectionBuilder()
        .withUrl(
          '${ApiEndpoints.baseUrl}/hubs/notifications',
          options: options,
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveNotification', _handleReceiveNotification);
    _connection!.on('RealtimeNotificationReceived', _handleReceiveNotification);
    _connection!.on('BookingStatusChanged', _handleBookingStatusChanged);

    _connection!.onclose(({error}) {
      // Automatic reconnect handles recovery.
    });

    await _connection!.start();
  }

  void _handleReceiveNotification(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments.first;
      if (raw is! Map) return;
      final notification = NotificationModel.fromJson(
        Map<String, dynamic>.from(raw),
      ).toEntity();
      final unreadCount = arguments.length > 1
          ? _parseInt(arguments[1]) ?? 0
          : 0;
      _controller.add(
        NotificationRealtimeUpdate(
          notification: notification,
          unreadCount: unreadCount,
        ),
      );
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  void _handleBookingStatusChanged(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return;
    try {
      final raw = arguments.first;
      if (raw is! Map) return;
      _bookingStatusController.add(
        BookingStatusChangedEvent.fromHubPayload(
          Map<String, dynamic>.from(raw),
        ),
      );
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.stop();
      } catch (_) {
        // Ignore stop errors during logout.
      }
      _connection = null;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
