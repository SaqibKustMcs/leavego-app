import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  late final AppController _appController;

  final TextEditingController _currentPasswordController = TextEditingController();

  final TextEditingController _newPasswordController = TextEditingController();

  final TextEditingController _confirmPasswordController = TextEditingController();

  final currentPasswordError = ''.obs;
  final newPasswordError = ''.obs;
  final confirmPasswordError = ''.obs;

  final RxBool obscureCurrentPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  @override
  void initState() {
    super.initState();

    _appController = Get.find<AppController>();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  bool _validate() {
    bool isValid = true;

    currentPasswordError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';

    final currentPassword = _currentPasswordController.text.trim();

    final newPassword = _newPasswordController.text.trim();

    final confirmPassword = _confirmPasswordController.text.trim();

    // Current Password
    if (currentPassword.isEmpty) {
      currentPasswordError.value = 'Current password is required';
      isValid = false;
    }

    // New Password
    if (newPassword.isEmpty) {
      newPasswordError.value = 'New password is required';
      isValid = false;
    } else if (newPassword.length < 8) {
      newPasswordError.value = 'Password must be at least 8 characters';
      isValid = false;
    } else if (newPassword == currentPassword) {
      newPasswordError.value = 'New password must be different from current password';
      isValid = false;
    }

    // Confirm Password
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Confirm password is required';
      isValid = false;
    } else if (confirmPassword != newPassword) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    return isValid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final success = await _appController.changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
      confirmPassword: _confirmPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Get.snackbar('Success', 'Password changed successfully', snackPosition: SnackPosition.BOTTOM);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      Get.snackbar(
        'Error',
        _appController.changePasswordError ?? 'Failed to change password',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Password
              Obx(
                () => TextField(
                  controller: _currentPasswordController,
                  obscureText: obscureCurrentPassword.value,
                  onChanged: (_) {
                    currentPasswordError.value = '';
                  },
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    hintText: 'Enter current password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        obscureCurrentPassword.toggle();
                      },
                    ),
                    errorText: currentPasswordError.value.isEmpty
                        ? null
                        : currentPasswordError.value,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // New Password
              Obx(
                () => TextField(
                  controller: _newPasswordController,
                  obscureText: obscureNewPassword.value,
                  onChanged: (_) {
                    newPasswordError.value = '';
                    confirmPasswordError.value = '';
                  },
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        obscureNewPassword.toggle();
                      },
                    ),
                    errorText: newPasswordError.value.isEmpty ? null : newPasswordError.value,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Password
              Obx(
                () => TextField(
                  controller: _confirmPasswordController,
                  obscureText: obscureConfirmPassword.value,
                  onChanged: (_) {
                    confirmPasswordError.value = '';
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        obscureConfirmPassword.toggle();
                      },
                    ),
                    errorText: confirmPasswordError.value.isEmpty
                        ? null
                        : confirmPasswordError.value,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Button
              ListenableBuilder(
                listenable: _appController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton(
                      onPressed: _appController.changePasswordLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _appController.changePasswordLoading
                          ? const AppButtonLoader(size: 22)
                          : const Text('Change Password'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
