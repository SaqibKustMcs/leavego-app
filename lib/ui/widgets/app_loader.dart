import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

/// Centered wave loader used across screens for page/section loading.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.color = AppTheme.navy, this.size = 40});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitWave(color: color, size: size),
    );
  }
}

/// Small wave loader for use inside buttons.
class AppButtonLoader extends StatelessWidget {
  const AppButtonLoader({super.key, this.color = Colors.white, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(color: color, size: size);
  }
}
