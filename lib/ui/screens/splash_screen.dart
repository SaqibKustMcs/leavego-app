import 'package:flutter/material.dart';
import 'package:leavego_app/controllers/app_controller.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppController.tokenStorageKey);
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
      backgroundColor: AppTheme.appBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/taskbulls_icon_01x.png', fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'TaskBulls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Color(0xff489FF7),
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
