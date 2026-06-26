import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.bookingId,
    required super.userId,
    super.userName,
    required super.workerId,
    super.workerName,
    required super.rating,
    super.comment,
    required super.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: _asInt(json['id']),
      bookingId: _asInt(json['bookingId']),
      userId: _asInt(json['userId']),
      userName: json['userName'] as String?,
      workerId: _asInt(json['workerId']),
      workerName: json['workerName'] as String?,
      rating: _asInt(json['rating']),
      comment: json['comment'] as String?,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Review toEntity() => Review(
        id: id,
        bookingId: bookingId,
        userId: userId,
        userName: userName,
        workerId: workerId,
        workerName: workerName,
        rating: rating,
        comment: comment,
        createdAt: createdAt,
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateFormatter.parseDate(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
