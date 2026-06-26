import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.userName,
    required this.workerId,
    this.workerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final int id;
  final int bookingId;
  final int userId;
  final String? userName;
  final int workerId;
  final String? workerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        bookingId,
        userId,
        userName,
        workerId,
        workerName,
        rating,
        comment,
        createdAt,
      ];
}

double averageReviewRating(List<Review> reviews) {
  if (reviews.isEmpty) return 0;
  final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
  return sum / reviews.length;
}
