import 'package:equatable/equatable.dart';

class WorkTypeEntity extends Equatable {
  final int id;
  final String name;
  final String? startTime;
  final String? endTime;
  final bool isOvernight;
  final double price;
  final double? monthlyPrice;
  final bool isMonthly;
  final int companyId;
  final bool isActive;

  const WorkTypeEntity({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.isOvernight = false,
    required this.price,
    this.monthlyPrice,
    this.isMonthly = false,
    required this.companyId,
    this.isActive = true,
  });

  double get displayPrice => isMonthly ? (monthlyPrice ?? price) : price;

  @override
  List<Object?> get props => [
        id,
        name,
        startTime,
        endTime,
        isOvernight,
        price,
        monthlyPrice,
        isMonthly,
        companyId,
        isActive,
      ];
}
