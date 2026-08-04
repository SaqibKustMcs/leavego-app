import 'package:flutter/material.dart';

/// Shared back control used across the app (`Icons.arrow_back_ios_new_rounded`).
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.color = Colors.black, this.onPressed});

  final Color color;
  final VoidCallback? onPressed;

  static const IconData icon = Icons.arrow_back_ios_new_rounded;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(icon, size: 18, color: color),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }
}
