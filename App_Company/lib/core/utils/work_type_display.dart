import '../../features/work_types/domain/entities/work_type_entity.dart';

String formatWorkTypePrice(WorkTypeEntity wt) {
  if (wt.isMonthly) {
    final p = wt.monthlyPrice ?? wt.price;
    return '${p.toStringAsFixed(0)} د.ل / شهر';
  }
  return '${wt.price.toStringAsFixed(0)} د.ل / يوم';
}

String? formatWorkTypeSchedule(WorkTypeEntity wt) {
  if (wt.isMonthly) return null;
  final start = wt.startTime;
  final end = wt.endTime;
  if (start == null || end == null) return null;
  if (start == '00:00' && end == '00:00') return null;
  return '$start – $end';
}

String workTypeModeBadge(WorkTypeEntity wt) => wt.isMonthly ? 'شهري' : 'يومي';
