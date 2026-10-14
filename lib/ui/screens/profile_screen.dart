import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/screens/change_password_screen.dart';
import 'package:leavego_app/ui/screens/create_employee_screen.dart';
import 'package:leavego_app/ui/screens/create_news_screen.dart';
import 'package:leavego_app/ui/screens/login_screen.dart';
import 'package:leavego_app/ui/screens/manage_users_screen.dart';
import 'package:leavego_app/ui/screens/news_screen.dart';
import 'package:leavego_app/ui/screens/google_calendar_screen.dart';
import 'package:leavego_app/ui/screens/personal_information_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';

const Color _profilePrimary = Color(0xFF173559);
const Color _profileSubtitle = Color(0xFF999999);
const Color _profileAvatarBg = Color(0xFFE8F0FE);
const String _logoutConfirmIcon = 'assets/images/logout.webp';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadMe();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _appController.loadMe();
  }

  Future<void> _performLogout() async {
    final result = await _appController.logout();
    if (!mounted) return;
    if (result == null && _appController.logoutError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_appController.logoutError!)));
      return;
    }
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  Future<void> _showLogoutConfirmationSheet() async {
    final theme = Theme.of(context);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.appBackground,
      shape: const RoundedRectangleBorder(
        side: BorderSide(width: 0.5, color: Color(0xffEEEEEE)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + MediaQuery.paddingOf(sheetContext).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DEEA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Image.asset(_logoutConfirmIcon, width: 72, height: 72, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              Text(
                'Log out?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _profilePrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out? You will need to log in again to use the app.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: _profileSubtitle, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _profilePrimary,
                        side: const BorderSide(color: Color(0xFFEEF4F2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                        ),
                      ),
                      child: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      await _performLogout();
    }
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
    final name = me?.name ?? 'Employee';
    final email = me?.email ?? '-';
    final lowerRole = (me?.role ?? '').trim().toLowerCase();
    final canCreateNews = AppRoles.canCreateNews(lowerRole);
    final canCreateEmployee = AppRoles.canCreateEmployee(lowerRole);
    final isActive = me?.isActive == true;
    final statusLabel = isActive ? 'Active' : 'Inactive';

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              Row(
                children: [
                  const AppBackButton(color: _profilePrimary),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        color: Color(0xff000000),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_appController.meLoading && me == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: AppButtonLoader()),
                ),
              if (_appController.meError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _appController.meError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              _UserSummaryCard(
                initials: _initials(name),
                name: name,
                email: email,
                statusLabel: statusLabel,
                isActive: isActive,
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Settings'),
              _MenuCard(
                children: [
                  _ProfileMenuItem(
                    iconAsset: 'assets/images/personal_information.webp',
                    title: 'Personal Information',
                    subtitle: 'Change name, email, password',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen()));
                    },
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    iconAsset: 'assets/images/privacy_and_security.webp',
                    title: 'Privacy & Security',
                    subtitle: 'Change password',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                    },
                  ),
                  const _MenuDivider(),
                  _ProfileMenuItem(
                    iconAsset: 'assets/images/calendar-week.webp',
                    title: 'Google Calendar',
                    subtitle: 'Connect and view your calendar events',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const GoogleCalendarScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('News'),
              _MenuCard(
                children: [
                  _ProfileMenuItem(
                    iconAsset: 'assets/images/company_news.webp',
                    title: 'Company News',
                    subtitle: 'View latest announcements',
                    onTap: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const NewsScreen()));
                    },
                  ),
                  if (canCreateNews) ...[
                    const _MenuDivider(),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/create_news.webp',
                      title: 'Create News',
                      subtitle: 'Publish announcements for a target audience',
                      onTap: () async {
                        final created = await Navigator.of(
                          context,
                        ).push<bool>(MaterialPageRoute(builder: (_) => const CreateNewsScreen()));
                        if (created == true && context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('News published')));
                        }
                      },
                    ),
                  ],
                ],
              ),
              if (canCreateEmployee) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Users'),
                _MenuCard(
                  children: [
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/manage_users.webp',
                      title: 'Manage Users',
                      subtitle: 'View and edit employee accounts',
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => const ManageUsersScreen()));
                      },
                    ),
                    const _MenuDivider(),
                    _ProfileMenuItem(
                      iconAsset: 'assets/images/create_user.webp',
                      title: 'Create Users',
                      subtitle: 'Add a new employee account',
                      onTap: () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const CreateEmployeeScreen()),
                        );
                        if (created == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User created successfully')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: _appController.logoutLoading ? null : _showLogoutConfirmationSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  ),
                ),
                icon: _appController.logoutLoading
                    ? AppButtonLoader(color: theme.colorScheme.error, size: 18)
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  _appController.logoutLoading ? 'Signing out…' : 'Log out',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(color: _profilePrimary, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}

class _UserSummaryCard extends StatelessWidget {
  const _UserSummaryCard({
    required this.initials,
    required this.name,
    required this.email,
    required this.statusLabel,
    required this.isActive,
  });

  final String initials;
  final String name;
  final String email;
  final String statusLabel;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(43),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.0,
            backgroundColor: _profileAvatarBg,
            child: Text(
              initials,
              style: const TextStyle(
                color: _profilePrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _profilePrimary,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _profileSubtitle,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFD9FCF0) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: isActive ? const Color(0xFF33594C) : const Color(0xFFC62828),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: const Divider(height: 2, thickness: 1, color: Color(0xFFEEEEEE)),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: Color(0xffE0EEFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(child: Image.asset(iconAsset, width: 20, height: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _profilePrimary,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _profileSubtitle,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF000000)),
          ],
        ),
      ),
    );
  }
}
