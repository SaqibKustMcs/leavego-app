/// Helpers for displaying task date/time fields from the API.
class TaskDateTimeFormat {
  TaskDateTimeFormat._();

  static String formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    try {
      final normalized = raw.contains(' ') ? raw.split(' ').first : raw.split('T').first;
      final date = DateTime.parse(normalized).toLocal();
      return _formatYmd(date);
    } catch (_) {
      return raw;
    }
  }

  static String formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();
    final parts = value.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    }
    return value;
  }

  static String formatDateTime({String? date, String? time}) {
    if (date != null && date.trim().isNotEmpty) {
      final hasEmbeddedTime = date.contains('T') || RegExp(r'\d{1,2}:\d{2}').hasMatch(date);
      if (hasEmbeddedTime) {
        return _formatFullDateTime(date);
      }
    }

    final formattedDate = formatDate(date);
    if (formattedDate == '-') return '-';
    final formattedTime = formatTime(time);
    if (formattedTime.isEmpty) return formattedDate;
    return '$formattedDate, $formattedTime';
  }

  static String _formatYmd(DateTime date) {
    const months = <String>[
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatFullDateTime(String raw) {
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final date = DateTime.parse(normalized).toLocal();
      final hour12 = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${_formatYmd(date)}, ${hour12.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return raw;
    }
  }
}
