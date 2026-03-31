import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/screens/home_screen.dart';
import 'package:leavego_app/ui/screens/my_leave_requests_screen.dart';
import 'package:leavego_app/ui/screens/task_list_screen.dart';
import 'package:leavego_app/ui/screens/tasks_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadUnreadCount();
    if (_appController.meData == null) {
      _appController.loadMe();
    }
  }

  void _onUpdate() {
    final pending = _appController.pendingMainTabIndex;
    if (pending != null && mounted) {
      _appController.clearPendingMainTabIndex();
      final role = (_appController.meData?.role ?? '').trim().toLowerCase();
      final canCreateTask = role == '$role';
      final maxTab = canCreateTask ? 5 : 4;
      setState(() {
        _currentIndex = pending.clamp(0, maxTab);
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
    final role = (_appController.meData?.role ?? '').trim().toLowerCase();
    final canCreateTask = role == '$role'; //|| role == 'hr';
    final screens = <Widget>[
      const HomeScreen(),
      const MyLeaveRequestsScreen(),
      const TaskListScreen(),
      if (canCreateTask) const TasksScreen(),
      const NotificationScreen(),
      const ProfileScreen(),
    ];

    final notificationsIndex = canCreateTask ? 4 : 3;
    if (_currentIndex >= screens.length) _currentIndex = 0;

    final unread = _appController.unreadCount;
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: screens),
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
          currentIndex: _currentIndex,
          onTap: (index) async {
            setState(() => _currentIndex = index);
            // Always fetch fresh data when user opens these tabs.
            if (index == 1) {
              await _appController.loadRequestsByRole();
              return;
            }
            if (index == 2) {
              await _appController.loadTasks(refresh: true);
              return;
            }
            if (index == notificationsIndex) {
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
              icon: Icon(TablerIcons.circle_check),
              activeIcon: Icon(TablerIcons.circle_check_filled),
              label: 'Requests',
            ),
            const BottomNavigationBarItem(
              icon: Icon(TablerIcons.square_check),
              activeIcon: Icon(TablerIcons.square_check_filled),
              label: 'Tasks',
            ),
            if (canCreateTask)
              const BottomNavigationBarItem(
                icon: Icon(TablerIcons.square_rounded_plus),
                activeIcon: Icon(TablerIcons.square_rounded_plus_filled),
                label: 'Create',
              ),
            BottomNavigationBarItem(
              icon: _badgeIcon(icon: TablerIcons.bell, count: unread, active: false),
              activeIcon: _badgeIcon(
                icon: TablerIcons.bell_filled,
                count: unread,
                active: true,
              ),
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
