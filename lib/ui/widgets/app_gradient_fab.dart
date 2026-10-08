import 'package:flutter/material.dart';
import 'package:leavego_app/ui/widgets/app_scroll_collapse_fab.dart';

/// Shared action FAB (extended label; pass [collapsed] for scroll-mini "+" state).
class AppGradientFab extends StatelessWidget {
  const AppGradientFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.collapsed = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return AppScrollCollapseFab(
      label: label,
      collapsed: collapsed,
      onPressed: onPressed,
      icon: icon,
    );
  }
}
