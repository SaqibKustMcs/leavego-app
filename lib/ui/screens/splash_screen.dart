import 'package:flutter/material.dart';
import 'package:leavego_app/services/session_storage.dart';
import 'package:leavego_app/ui/screens/login_screen.dart';
import 'package:leavego_app/ui/screens/main_screen.dart';
import 'package:leavego_app/ui/screens/onboarding_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage(AppLogoGif.asset), context);
    });
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Wipes Keychain leftovers after an iOS uninstall/reinstall.
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
            const AppLogoGif(size: 240),

            // const SizedBox(height: 8),
            // Text(
            //   'TaskBulls',
            //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
            //     color: Color(0xff489FF7),
            //     fontWeight: FontWeight.w700,
            //     fontSize: 28,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
