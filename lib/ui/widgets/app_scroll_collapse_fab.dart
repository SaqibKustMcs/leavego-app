import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:leavego_app/ui/theme/app_theme.dart';

/// Tracks FAB collapse from scroll notifications bubbling up the widget tree.
class ScrollCollapseFabController extends ChangeNotifier {
  bool collapsed = false;
  double _lastPixels = 0;
  bool _notifyScheduled = false;

  /// Return value for [NotificationListener.onNotification] (always false).
  bool handle(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          notification.metrics.pixels > 20) {
        _setCollapsed(true);
      } else if (notification.direction == ScrollDirection.forward) {
        _setCollapsed(false);
      }
    } else if (notification is ScrollEndNotification) {
      _lastPixels = notification.metrics.pixels;
      if (notification.metrics.pixels <= 8) {
        _setCollapsed(false);
      }
    } else if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      final delta = pixels - _lastPixels;
      if (delta > 10 && pixels > 24) {
        _setCollapsed(true);
      } else if (delta < -10) {
        _setCollapsed(false);
      }
      _lastPixels = pixels;
    }

    return false;
  }

  void _setCollapsed(bool value) {
    if (collapsed == value) return;
    collapsed = value;
    _scheduleNotify();
  }

  /// Avoid [notifyListeners] while handling scroll notifications (prevents red error screen).
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }
}

/// Primary action FAB: full label when idle, circular "+" while scrolling down.
class AppScrollCollapseFab extends StatelessWidget {
  const AppScrollCollapseFab({
    super.key,
    required this.label,
    required this.collapsed,
    required this.onPressed,
    this.icon = Icons.add,
    this.backgroundColor = AppTheme.navy,
  });

  final String label;
  final bool collapsed;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;

  static const Duration _duration = Duration(milliseconds: 200);
  static const double _collapsedSize = 56;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
      child: AnimatedSize(
        duration: _duration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerRight,
        clipBehavior: Clip.hardEdge,
        child: collapsed ? _buildCollapsed(context) : _buildExpanded(context),
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _collapsedSize,
          height: _collapsedSize,
          child: IconTheme(
            data: IconThemeData(
              color: Colors.white.withValues(alpha: onPressed == null ? 0.5 : 1),
              size: 30,
            ),
            child: const Center(
              child: Icon(Icons.add_rounded),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    const radius = 10.0;
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: onPressed == null ? 0.5 : 1),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrap scrollable [body] so FAB collapse reacts to user scroll.
class AppFabScrollListener extends StatelessWidget {
  const AppFabScrollListener({super.key, required this.controller, required this.child});

  final ScrollCollapseFabController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: controller.handle,
      child: child,
    );
  }
}
