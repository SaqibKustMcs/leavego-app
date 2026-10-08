import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/utils/app_roles.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _avatarBg = Color(0xFFE8F0FE);

  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = _appController.meData;
    final name = me?.name ?? '-';
    final email = me?.email ?? '-';
    final role = AppRoles.displayName(me?.role);
    final department = (me?.department?.trim().isNotEmpty == true)
        ? me!.department!.trim()
        : (me?.departmentId ?? '-');
    final isActive = me?.isActive == true;
    final statusLabel = isActive ? 'Active' : 'Inactive';
    final statusColor = isActive ? const Color(0xFF2E7D32) : const Color(0xFF9B2C2C);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: const Text(
          'Personal Information',
          style: TextStyle(color: Color(0xff000000), fontWeight: FontWeight.w500, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => _appController.loadMe(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: _avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(width: 0.5, color: _primary),
                    ),

                    child: Center(
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Employee Information',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (_appController.meError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _appController.meError!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    iconAsset: 'assets/images/profile_name.webp',
                    label: 'Name',
                    value: name,
                  ),
                  const _RowDivider(),
                  _InfoRow(
                    iconAsset: 'assets/images/profile_email.webp',
                    label: 'E-Mail',
                    value: email,
                  ),
                  const _RowDivider(),
                  _InfoRow(
                    iconAsset: 'assets/images/profile_role.webp',
                    label: 'Role',
                    value: role,
                  ),
                  const _RowDivider(),
                  _InfoRow(
                    iconAsset: 'assets/images/profile_department.webp',
                    label: 'Department',
                    value: department,
                  ),
                  const _RowDivider(),
                  _InfoRow(
                    iconAsset: 'assets/images/profile_status.webp',
                    label: 'Status',
                    value: statusLabel,
                    valueColor: statusColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5),
      child: const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.iconAsset,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String iconAsset;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(iconAsset, width: 20, height: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Color(0xff173559), fontWeight: FontWeight.w400, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Color(0xFF999999),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
