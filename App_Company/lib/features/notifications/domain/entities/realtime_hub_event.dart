import 'package:equatable/equatable.dart';

import 'booking_status_changed_event.dart';
import 'notification_entity.dart';

sealed class RealtimeHubEvent extends Equatable {
  const RealtimeHubEvent();

  @override
  List<Object?> get props => [];
}

class RealtimeNotificationReceived extends RealtimeHubEvent {
  const RealtimeNotificationReceived(this.update);

  final NotificationRealtimeUpdate update;

  @override
  List<Object?> get props => [update];
}

class RealtimeBookingStatusChanged extends RealtimeHubEvent {
  const RealtimeBookingStatusChanged({
    required this.bookingEvent,
    this.notificationUpdate,
  });

  final BookingStatusChangedEvent bookingEvent;
  final NotificationRealtimeUpdate? notificationUpdate;

  @override
  List<Object?> get props => [bookingEvent, notificationUpdate];
}

class RealtimeToastMessage extends RealtimeHubEvent {
  const RealtimeToastMessage(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
