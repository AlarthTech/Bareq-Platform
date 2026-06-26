/// Formats hour and minute as `HH:mm` for API payloads (e.g. `08:00`, `15:30`).
String hourMinuteToHm(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Normalizes time strings to `HH:MM` (e.g. `8:0` → `08:00`).
String formatTimeHm(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '--:--';
  final parts = t.split(':');
  if (parts.length < 2) return t;
  final h = int.tryParse(parts[0].trim()) ?? 0;
  final m = int.tryParse(parts[1].trim().split(RegExp(r'\s'))[0]) ?? 0;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
