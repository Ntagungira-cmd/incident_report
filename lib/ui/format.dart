const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _time(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// "Oct 15, 2026 at 10:24 AM"
String formatDateTime(DateTime t) =>
    '${_months[t.month - 1]} ${t.day}, ${t.year} at ${_time(t)}';

/// "Oct 15, 10:24 AM"
String formatShort(DateTime t) =>
    '${_months[t.month - 1]} ${t.day}, ${_time(t)}';

/// "2 hours ago", falling back to a date after a week.
String timeAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'} ago';
  if (d.inMinutes < 1) return 'Just now';
  if (d.inHours < 1) return plural(d.inMinutes, 'minute');
  if (d.inDays < 1) return plural(d.inHours, 'hour');
  if (d.inDays < 7) return plural(d.inDays, 'day');
  return '${_months[t.month - 1]} ${t.day}, ${t.year}';
}
