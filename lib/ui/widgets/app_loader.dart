import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

/// Animated TaskBulls logo — `assets/images/2.gif` (splash + loaders).
class AppLogoGif extends StatelessWidget {
  const AppLogoGif({super.key, this.size = 40});

  static const String asset = 'assets/images/2.gif';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: size,
      width: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Centered logo loader for pages and sections.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.color = AppTheme.navy, this.size = 40});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLogoGif(size: size));
  }
}

/// Compact loader for buttons on colored backgrounds (Update Status, Post Comment, etc.).
class AppButtonLoader extends StatelessWidget {
  const AppButtonLoader({super.key, this.color = Colors.white, this.size = 18});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SpinKitWave(color: color, size: size);
  }
}
