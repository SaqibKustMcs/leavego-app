import 'package:flutter/material.dart';
import 'package:leavego_app/services/session_storage.dart';
import 'package:leavego_app/ui/screens/login_screen.dart';
import 'package:leavego_app/ui/screens/main_screen.dart';
import 'package:leavego_app/ui/screens/onboarding_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const String _logoAsset = 'assets/images/login_logo.webp';

  late final AnimationController _introController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage(_logoAsset), context);
      _introController.forward();
    });
    _navigateNext();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    await SessionStorage.init();
    final token = await SessionStorage.readToken();
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      return;
    }

    if (!hasSeenOnboarding) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.authFlowBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Image.asset(_logoAsset, width: 190, height: 190, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 0),
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: Text(
                  'TaskBulls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
