import 'package:flutter/material.dart';
import 'package:leavego_app/models/google_calendar_response.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _primary = Color(0xFF173559);
const Color _muted = Color(0xFF999999);

class GoogleCalendarEventTile extends StatelessWidget {
  const GoogleCalendarEventTile({
    super.key,
    required this.event,
    this.compact = false,
    this.onTap,
  });

  final GoogleCalendarEventItem event;
  final bool compact;
  final VoidCallback? onTap;

  String _timeRangeLabel() {
    if (event.allDay) return 'All day';
    final start = event.startDateTime?.toLocal();
    final end = event.endDateTime?.toLocal();
    String fmt(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }

    if (start != null && end != null) {
      return '${fmt(start)} – ${fmt(end)}';
    }
    if (start != null) return fmt(start);
    return '';
  }

  String _dateLabel() {
    final start = event.effectiveStart;
    if (start == null) return '';
    const months = [
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
    return '${months[start.month - 1]} ${start.day}, ${start.year}';
  }

  Future<void> _openLink() async {
    final link = event.htmlLink?.trim();
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _timeRangeLabel();
    final dateLabel = _dateLabel();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: onTap ?? (event.htmlLink != null ? _openLink : null),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16, vertical: compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: compact ? 48 : 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 14 : 16,
                      ),
                    ),
                    if (timeLabel.isNotEmpty || dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        compact && timeLabel.isNotEmpty ? timeLabel : '$dateLabel${timeLabel.isNotEmpty ? ' · $timeLabel' : ''}',
                        style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (!compact && event.location != null && event.location!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (event.htmlLink != null)
                Icon(Icons.open_in_new_rounded, size: 18, color: _primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
