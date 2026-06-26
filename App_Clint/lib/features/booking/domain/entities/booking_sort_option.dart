import 'booking.dart';

/// Client-side sort options for the bookings list.
enum BookingSortOption {
  bookingDateNewest,
  bookingDateOldest,
  createdAtNewest,
  createdAtOldest,
  workerNameAsc,
  workerNameDesc,
}

extension BookingSortOptionX on BookingSortOption {
  void sort(List<Booking> bookings) {
    switch (this) {
      case BookingSortOption.bookingDateNewest:
        bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      case BookingSortOption.bookingDateOldest:
        bookings.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
      case BookingSortOption.createdAtNewest:
        bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case BookingSortOption.createdAtOldest:
        bookings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case BookingSortOption.workerNameAsc:
        bookings.sort(
          (a, b) => a.workerName
              .toLowerCase()
              .compareTo(b.workerName.toLowerCase()),
        );
      case BookingSortOption.workerNameDesc:
        bookings.sort(
          (a, b) => b.workerName
              .toLowerCase()
              .compareTo(a.workerName.toLowerCase()),
        );
    }
  }

  String localizationKey() {
    switch (this) {
      case BookingSortOption.bookingDateNewest:
        return 'sortBookingDateNewest';
      case BookingSortOption.bookingDateOldest:
        return 'sortBookingDateOldest';
      case BookingSortOption.createdAtNewest:
        return 'sortCreatedNewest';
      case BookingSortOption.createdAtOldest:
        return 'sortCreatedOldest';
      case BookingSortOption.workerNameAsc:
        return 'sortWorkerNameAsc';
      case BookingSortOption.workerNameDesc:
        return 'sortWorkerNameDesc';
    }
  }
}
