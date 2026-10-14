import 'package:flutter/material.dart';

class GlanceCompactStepperItem {
  const GlanceCompactStepperItem({
    required this.title,
    required this.subtitle,
    required this.dotColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color dotColor;
  final VoidCallback? onTap;
}

/// Compact task-style stepper (home Today's Glance tasks column).
class GlanceCompactStepperList extends StatelessWidget {
  const GlanceCompactStepperList({super.key, required this.items});

  final List<GlanceCompactStepperItem> items;

  static const Color _line = Color(0xFF173559);
  static const double _dotSize = 10;
  static const double _railWidth = 22;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (items.length > 1)
              Positioned(
                left: (_railWidth - 1.5) / 2,
                top: _dotSize / 2 + 2,
                bottom: _dotSize / 2 + 2,
                child: Container(width: 1.5, color: _line.withValues(alpha: 0.35)),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14),
                    child: _GlanceCompactStepperRow(
                      dotColor: items[i].dotColor,
                      title: items[i].title,
                      subtitle: items[i].subtitle,
                      onTap: items[i].onTap,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GlanceCompactStepperRow extends StatelessWidget {
  const _GlanceCompactStepperRow({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final Color dotColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  static const double _railWidth = 22;
  static const double _dotSize = 10;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _railWidth,
              child: Center(
                child: Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.35),
                        blurRadius: 0,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6A778B),
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
