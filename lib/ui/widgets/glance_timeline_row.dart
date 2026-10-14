import 'package:flutter/material.dart';

/// Task-style row used on Today's Glance (timeline + card).
class GlanceTimelineRow extends StatelessWidget {
  const GlanceTimelineRow({
    super.key,
    required this.isActive,
    required this.isLast,
    required this.title,
    required this.weekday,
    required this.assignment,
    required this.time,
    required this.onTap,
  });

  final bool isActive;
  final bool isLast;
  final String title;
  final String weekday;
  final String assignment;
  final String time;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);
  static const Color _activeCardBg = Color(0xFFE4F1FE);
  static const double _railWidth = 28;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                GlanceTimelineDot(filled: isActive),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: _primary.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isActive ? _activeCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? _activeCardBg : const Color(0xFFEEF4F2),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (weekday.isNotEmpty)
                              Text(
                                weekday,
                                style: const TextStyle(
                                  color: Color(0xFF9AA5B5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                        if (assignment.isNotEmpty || time.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assignment,
                                  style: const TextStyle(
                                    color: Color(0xFF9AA5B5),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (time.isNotEmpty)
                                Text(
                                  time,
                                  style: const TextStyle(
                                    color: Color(0xFF9AA5B5),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlanceTimelineDot extends StatelessWidget {
  const GlanceTimelineDot({super.key, required this.filled});

  final bool filled;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _primary, width: 1.5),
        color: Colors.white,
      ),
    );
  }
}
