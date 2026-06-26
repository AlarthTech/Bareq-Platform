import '../../domain/entities/review.dart';

class ReviewModel {
  ReviewModel({
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: _int(json['id']) ?? 0,
      bookingId: _int(json['bookingId']) ?? 0,
      userId: _int(json['userId']) ?? 0,
      userName: json['userName']?.toString(),
      workerId: _int(json['workerId']) ?? 0,
      workerName: json['workerName']?.toString(),
      rating: _int(json['rating']) ?? 0,
      comment: json['comment']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
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

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
