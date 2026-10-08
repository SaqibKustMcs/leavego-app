import 'package:flutter/material.dart';
import 'package:leavego_app/ui/models/today_glance_tab.dart';

/// Tasks / Meetings toggle shared by home dropdown and Today's Glance detail.
class TodayGlanceTabSwitcher extends StatelessWidget {
  const TodayGlanceTabSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final TodayGlanceTab selected;
  final ValueChanged<TodayGlanceTab> onChanged;
  final bool compact;

  static const Color _inactiveBg = Color(0xFFE4F1FE);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactGlanceDropdown(selected: selected, onChanged: onChanged);
    }

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // color: _inactiveBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _Segment(
            label: TodayGlanceTab.tasks.label,
            selected: selected == TodayGlanceTab.tasks,
            onTap: () => onChanged(TodayGlanceTab.tasks),
          ),
          SizedBox(width: 12),
          _Segment(
            label: TodayGlanceTab.meetings.label,
            selected: selected == TodayGlanceTab.meetings,
            onTap: () => onChanged(TodayGlanceTab.meetings),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          width: 118,
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _primary : Color(0xffEDF6FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _primary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactGlanceDropdown extends StatelessWidget {
  const _CompactGlanceDropdown({required this.selected, required this.onChanged});

  final TodayGlanceTab selected;
  final ValueChanged<TodayGlanceTab> onChanged;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TodayGlanceTab>(
      initialValue: selected,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        return TodayGlanceTab.values
            .map(
              (tab) => PopupMenuItem<TodayGlanceTab>(
                value: tab,
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontWeight: tab == selected ? FontWeight.w700 : FontWeight.w500,
                    color: _primary,
                  ),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
