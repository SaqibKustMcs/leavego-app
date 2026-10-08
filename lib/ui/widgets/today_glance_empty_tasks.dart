import 'package:flutter/material.dart';

/// Empty state for Today's Glance tasks or meetings (same illustration).
class TodayGlanceEmptyTasks extends StatelessWidget {
  const TodayGlanceEmptyTasks({
    super.key,
    this.compact = false,
    this.message = 'No tasks due today.',
  });

  final bool compact;
  final String message;

  static const String asset = 'assets/images/empty_today_glance_task.webp';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          asset,
          width: compact ? 128 : 220,
          height: compact ? 96 : 160,
          fit: BoxFit.contain,
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF6A778B),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
