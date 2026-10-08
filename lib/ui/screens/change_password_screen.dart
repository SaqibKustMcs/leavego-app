import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _fieldBorder = Color(0xFFD1D5DB);
  static const double _fieldHeight = 54;
  static const double _fieldRadius = 8;
  static const double _fieldBorderWidth = 1;

  late final AppController _appController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _submitError;

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
      _submitError = null;
    });
  }

  bool _validate() {
    _clearFieldErrors();

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    var isValid = true;

    if (currentPassword.isEmpty) {
      _currentPasswordError = 'Current password is required';
      isValid = false;
    }

    if (newPassword.isEmpty) {
      _newPasswordError = 'New password is required';
      isValid = false;
    } else if (newPassword.length < 8) {
      _newPasswordError = 'Password must be at least 8 characters';
      isValid = false;
    } else if (newPassword == currentPassword) {
      _newPasswordError = 'New password must be different from current password';
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Confirm password is required';
      isValid = false;
    } else if (confirmPassword != newPassword) {
      _confirmPasswordError = 'Passwords do not match';
      isValid = false;
    }

    setState(() {});
    return isValid;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) return;

    final success = await _appController.changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _clearFieldErrors();
      return;
    }

    setState(() {
      _submitError = _appController.changePasswordError ?? 'Failed to change password';
    });
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    final borderRadius = BorderRadius.circular(_fieldRadius);
    final defaultBorder = BorderSide(color: _fieldBorder, width: _fieldBorderWidth);
    final focusedBorder = BorderSide(color: _primary, width: _fieldBorderWidth);

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF4C4C4C),
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF4C4C4C),
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: borderRadius, borderSide: defaultBorder),
      enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: defaultBorder),
      focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorder),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: _primary,
          size: 22,
        ),
        onPressed: onToggleVisibility,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleVisibility,
    required String? errorText,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _fieldHeight,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              color: _primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            decoration: _passwordDecoration(
              label: label,
              obscure: obscure,
              onToggleVisibility: onToggleVisibility,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w500, fontSize: 18),
            ),
            const SizedBox(height: 24),
            _passwordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              obscure: _obscureCurrentPassword,
              errorText: _currentPasswordError,
              onChanged: () {
                if (_currentPasswordError != null || _submitError != null) {
                  setState(() {
                    _currentPasswordError = null;
                    _submitError = null;
                  });
                }
              },
              onToggleVisibility: () {
                setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
              },
            ),
            const SizedBox(height: 20),
            _passwordField(
              controller: _newPasswordController,
              label: 'New Password',
              obscure: _obscureNewPassword,
              errorText: _newPasswordError,
              onChanged: () {
                if (_newPasswordError != null ||
                    _confirmPasswordError != null ||
                    _submitError != null) {
                  setState(() {
                    _newPasswordError = null;
                    _confirmPasswordError = null;
                    _submitError = null;
                  });
                }
              },
              onToggleVisibility: () {
                setState(() => _obscureNewPassword = !_obscureNewPassword);
              },
            ),
            const SizedBox(height: 20),
            _passwordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              obscure: _obscureConfirmPassword,
              errorText: _confirmPasswordError,
              onChanged: () {
                if (_confirmPasswordError != null || _submitError != null) {
                  setState(() {
                    _confirmPasswordError = null;
                    _submitError = null;
                  });
                }
              },
              onToggleVisibility: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _appController.changePasswordLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                ),
                elevation: 0,
              ),
              child: _appController.changePasswordLoading
                  ? const AppButtonLoader(size: 22)
                  : const Text(
                      'Confirm Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
