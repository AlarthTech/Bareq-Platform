import '../../../../core/constants/app_constants.dart';

/// Maps API / SignalR booking status strings to [AppConstants] status ints.
class BookingStatusMapper {
  BookingStatusMapper._();

  static int? fromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final normalized = raw.trim().toLowerCase().replaceAll(' ', '').replaceAll('_', '');

    return switch (normalized) {
      'pending' => AppConstants.statusPending,
      'approved' => AppConstants.statusApproved,
      'assigned' => AppConstants.statusApproved,
      'bookingassigned' => AppConstants.statusApproved,
      'ontheway' => AppConstants.statusOnTheWay,
      'inprogress' => AppConstants.statusOnTheWay,
      'bookinginprogress' => AppConstants.statusOnTheWay,
      'completed' => AppConstants.statusCompleted,
      'bookingcompleted' => AppConstants.statusCompleted,
      'cancelled' => AppConstants.statusCanceled,
      'canceled' => AppConstants.statusCanceled,
      'bookingcancelled' => AppConstants.statusCanceled,
      'bookingcanceled' => AppConstants.statusCanceled,
      'rejected' => AppConstants.statusRejected,
      'bookingrejected' => AppConstants.statusRejected,
      'bookingcreated' => AppConstants.statusPending,
      'bookingconfirmed' => AppConstants.statusApproved,
      _ => int.tryParse(raw),
    };
  }
}
