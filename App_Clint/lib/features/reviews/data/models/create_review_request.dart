class CreateReviewRequest {
  CreateReviewRequest({
    required this.bookingId,
    required this.workerId,
    required this.rating,
    this.comment,
  });

  final int bookingId;
  final int workerId;
  final int rating;
  final String? comment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'bookingId': bookingId,
      'workerId': workerId,
      'rating': rating,
    };
    final trimmed = comment?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      map['comment'] = trimmed;
    }
    return map;
  }
}

class UpdateReviewRequest {
  UpdateReviewRequest({this.rating, this.comment});

  final int? rating;
  final String? comment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rating != null) map['rating'] = rating;
    if (comment != null) map['comment'] = comment!.trim();
    return map;
  }
}
