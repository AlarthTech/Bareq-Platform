/// Maps work-type window to صباحية / مسائية / مبيت (overnight).
String workShiftTag({
  required bool isOvernight,
  String? startTime,
  bool isMonthly = false,
}) {
  if (isMonthly) return 'شهري';
  if (isOvernight) return 'مبيت';
  final st = startTime ?? '12:00';
  final parts = st.split(':');
  if (parts.isEmpty) return 'مسائية';
  final h = int.tryParse(parts[0].trim()) ?? 12;
  if (h < 12) return 'صباحية';
  return 'مسائية';
}
