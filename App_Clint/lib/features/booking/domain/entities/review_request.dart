import 'package:equatable/equatable.dart';
import 'review_ratings.dart';

/// Sent when a user submits feedback about a completed booking
class ReviewRequest extends Equatable {
  final int bookingId;
  final int workerId;
  final int serviceId;
  final int overallRating;
  final String comment;
  final ReviewRatings ratings;

  const ReviewRequest({
    required this.bookingId,
    required this.workerId,
    required this.serviceId,
    required this.overallRating,
    required this.comment,
    required this.ratings,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'workerId': workerId,
      'serviceId': serviceId,
      'overallRating': overallRating,
      'comment': comment,
      'ratings': ratings.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    bookingId,
    workerId,
    serviceId,
    overallRating,
    comment,
    ratings,
  ];
}
