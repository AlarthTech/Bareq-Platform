import 'package:equatable/equatable.dart';

/// Represents the individual KPI scores submitted with a review
class ReviewRatings extends Equatable {
  final int punctuality;
  final int cleaningQuality;
  final int attentionToDetail;
  final int professionalism;
  final int respectAndBehavior;
  final int followingInstructions;
  final int speedAndEfficiency;

  const ReviewRatings({
    required this.punctuality,
    required this.cleaningQuality,
    required this.attentionToDetail,
    required this.professionalism,
    required this.respectAndBehavior,
    required this.followingInstructions,
    required this.speedAndEfficiency,
  });

  Map<String, int> toJson() {
    return {
      'punctuality': punctuality,
      'cleaningQuality': cleaningQuality,
      'attentionToDetail': attentionToDetail,
      'professionalism': professionalism,
      'respectAndBehavior': respectAndBehavior,
      'followingInstructions': followingInstructions,
      'speedAndEfficiency': speedAndEfficiency,
    };
  }

  @override
  List<Object?> get props => [
    punctuality,
    cleaningQuality,
    attentionToDetail,
    professionalism,
    respectAndBehavior,
    followingInstructions,
    speedAndEfficiency,
  ];
}
