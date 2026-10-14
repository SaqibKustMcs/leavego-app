import 'package:leavego_app/models/google_calendar_response.dart';
import 'package:url_launcher/url_launcher.dart';

class GlanceMeetingLabels {
  GlanceMeetingLabels._();

  static const _months = [
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

  static bool isToday(GoogleCalendarEventItem event) {
    final start = event.effectiveStart;
    if (start == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(start.year, start.month, start.day);
    return eventDay == today;
  }

  /// Top-right label on Today's Glance meeting rows: "Today" or calendar date.
  static String detailDateLabel(GoogleCalendarEventItem event) {
    final start = event.effectiveStart;
    if (start == null) return '';
    if (isToday(event)) return 'Today';
    return _formatCalendarDate(start);
  }

  static String _formatCalendarDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
  }

  static String timeRange(GoogleCalendarEventItem event) {
    if (event.allDay) return 'All day';
    final start = event.startDateTime?.toLocal();
    final end = event.endDateTime?.toLocal();
    String fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }

    if (start != null && end != null) return '${fmt(start)} – ${fmt(end)}';
    if (start != null) return fmt(start);
    return '';
  }

  static String assignment(GoogleCalendarEventItem event) {
    final location = event.location?.trim();
    if (location != null && location.isNotEmpty) return location;
    return 'Google Calendar';
  }

  static String compactSubtitle(GoogleCalendarEventItem event) {
    final time = timeRange(event);
    final day = detailDateLabel(event);
    if (day.isEmpty) return time;
    if (time.isEmpty) return day;
    return '$day · $time';
  }

  static Future<void> openEvent(GoogleCalendarEventItem event) async {
    final link = event.htmlLink?.trim();
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
