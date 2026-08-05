import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/services/push_notification_service.dart';
import 'package:leavego_app/ui/screens/home_screen.dart';
import 'package:leavego_app/ui/screens/projects_screen.dart';
import 'package:leavego_app/ui/screens/notification_screen.dart';
import 'package:leavego_app/ui/screens/profile_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:tabler_icons/tabler_icons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final AppController _appController;
  bool _notificationPermissionRequested = false;

  static const int _notificationsIndex = 2;

  /// Kept alive across tab switches via [IndexedStack].
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    ProjectsScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadUnreadCount();
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationNavigationService.flushPending();
      _requestNotificationPermissionAfterNavReady();
    });
  }

  /// Ask notification permission only after bottom navbar is on screen.
  Future<void> _requestNotificationPermissionAfterNavReady() async {
    if (_notificationPermissionRequested || !mounted) return;
    _notificationPermissionRequested = true;

    // Let the main shell paint first so the dialog appears over bottom nav.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final push = PushNotificationService.instance;
    await push.initialize();
    await push.requestPermission();

    final token = await push.getToken();
    if (token != null && token.isNotEmpty) {
      final deviceName = await push.getDeviceName();
      await _appController.registerFcmToken(
        token,
        platform: Platform.isIOS ? 'ios' : 'android',
        deviceName: deviceName,
      );
    }
  }

  void _onUpdate() {
    final pending = _appController.pendingMainTabIndex;
    if (pending != null && mounted) {
      _appController.clearPendingMainTabIndex();
      setState(() {
        _currentIndex = pending.clamp(0, 3);
      });
      return;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Widget _badgeIcon({required IconData icon, required int count, required bool active}) {
    final effectiveCount = count > 99 ? 99 : count;
    final show = effectiveCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (show)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: active ? AppTheme.navy : const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$effectiveCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = _currentIndex.clamp(0, _screens.length - 1);
    final unread = _appController.unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (tappedIndex) async {
            setState(() => _currentIndex = tappedIndex);
            // Refresh data when opening these tabs (screens stay mounted).
            if (tappedIndex == 1) {
              await _appController.loadProjects(refresh: true);
              return;
            }
            if (tappedIndex == _notificationsIndex) {
              await Future.wait([
                _appController.loadUnreadCount(),
                _appController.loadNotifications(),
              ]);
              return;
            }
          },
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(TablerIcons.apps),
              activeIcon: Icon(TablerIcons.apps_filled),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(TablerIcons.folder),
              activeIcon: Icon(TablerIcons.folder_filled),
              label: 'Projects',
            ),
            BottomNavigationBarItem(
              icon: _badgeIcon(icon: TablerIcons.bell, count: unread, active: false),
              activeIcon: _badgeIcon(icon: TablerIcons.bell_filled, count: unread, active: true),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(TablerIcons.badge),
              activeIcon: Icon(TablerIcons.badge_filled),
              label: 'Profile',
            ),
          ],
          selectedItemColor: AppTheme.navy,
          unselectedItemColor: Colors.grey.shade600,
        ),
      ),
    );
  }
}
