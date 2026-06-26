import 'package:equatable/equatable.dart';

/// WorkTypeDetail entity representing a work type definition in the domain layer
/// This is different from WorkType which represents a worker's work type assignment
class WorkTypeDetail extends Equatable {
  final int id;
  final String name;
  final int companyId;
  final String companyName;
  final String startTime;
  final String endTime;
  final bool isOvernight;
  final double price;
  final bool isActive;
  final DateTime createdAt;

  const WorkTypeDetail({
    required this.id,
    required this.name,
    required this.companyId,
    required this.companyName,
    required this.startTime,
    required this.endTime,
    required this.isOvernight,
    required this.price,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        companyId,
        companyName,
        startTime,
        endTime,
        isOvernight,
        price,
        isActive,
        createdAt,
      ];
}
