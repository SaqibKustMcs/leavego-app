import 'package:flutter/material.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

/// Shared extended FAB used across the app (navy → lightNavy gradient).
class AppGradientFab extends StatelessWidget {
  const AppGradientFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        disabledElevation: 0,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
