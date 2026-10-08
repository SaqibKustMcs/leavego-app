import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/services/connectivity_service.dart';
import 'package:leavego_app/ui/screens/main_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _headerTop = Color(0xFF1D2E72);
  static const Color _headerBottom = Color(0xFF3757D8);
  static const Color _primary = Color(0xFF173559);
  static const Color _fieldBorder = Color(0xFFD1D5DB);
  static const double _controlRadius = AppTheme.controlRadius;
  static const double _fieldHeight = 54;
  static const double _fieldRadius = 8;
  static const double _fieldBorderWidth = 1;
  // static List<BoxShadow> _fieldShadow = [
  //   BoxShadow(color: Color(0xff000000).withOpacity(0.25), blurRadius: 0, offset: Offset.zero),
  // ];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AppController _appController;
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onControllerUpdate);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (_errorText == null && _appController.errorMessage == null) return;
    setState(() {
      _errorText = null;
      _appController.errorMessage = null;
    });
  }

  Future<void> _onSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (Get.isRegistered<ConnectivityService>() &&
        !Get.find<ConnectivityService>().isOnline.value) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(ConnectivityService.offlineMessage)));
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _errorText = null);

    if (email.isEmpty) {
      setState(() => _errorText = 'Please enter your email');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorText = 'Please enter a valid email');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorText = 'Please enter your password');
      return;
    }

    final result = await _appController.login(email: email, password: password);
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  InputDecoration _inputDecoration({required String hint}) {
    final borderRadius = BorderRadius.circular(_fieldRadius);
    final defaultBorder = BorderSide(color: _fieldBorder, width: _fieldBorderWidth);
    final focusedBorder = BorderSide(color: _primary, width: _fieldBorderWidth);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Color(0xff6E6E6E), fontWeight: FontWeight.w400),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: borderRadius, borderSide: defaultBorder),
      enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: defaultBorder),
      focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorder),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _loginTextField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_fieldRadius),
        // boxShadow: _fieldShadow,
      ),
      child: SizedBox(height: _fieldHeight, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        // backgroundColor: Color(0xff1D2E72),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 8,
                  child: Container(
                    width: double.infinity,

                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xff173559), _headerBottom],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Column(
              children: [
                Expanded(
                  flex: 8,
                  child: Container(
                    width: double.infinity,
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Image.asset('assets/images/login_logo.webp', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 13,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xffFFFFFF),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(40),
                        topLeft: Radius.circular(40),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: _primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use your company credentials',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Color(0xff747D7A),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 40),
                              _loginTextField(
                                child: TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 16, height: 1.2),
                                  decoration: _inputDecoration(hint: 'Email'),
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => _clearErrors(),
                                ),
                              ),
                              const SizedBox(height: 30),
                              _loginTextField(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(fontSize: 16, height: 1.2),
                                  decoration: _inputDecoration(hint: 'Password').copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 22,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _onSubmit(),
                                  onChanged: (_) => _clearErrors(),
                                ),
                              ),
                              if (_errorText != null || _appController.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorText ?? _appController.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 40),
                              FilledButton(
                                onPressed: _appController.isLoading ? null : _onSubmit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primary,
                                  disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(_controlRadius),
                                  ),
                                  elevation: 0,
                                ),
                                child: _appController.isLoading
                                    ? const AppButtonLoader(size: 22)
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
