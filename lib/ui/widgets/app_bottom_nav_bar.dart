import 'package:flutter/material.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

/// Main shell bottom navigation (Homepage, Projects, My Leave Requests, Notifications).
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationBadgeCount = 0,
  });

  static const String iconHome = 'assets/images/bottombar_home.webp';
  static const String iconProjects = 'assets/images/bottombar_projects.webp';
  static const String iconProjectsActive = 'assets/images/folder-open.webp';
  static const String iconLeave = 'assets/images/bottombar_leave.webp';
  static const String iconNotifications = 'assets/images/notifications-outline.webp';

  static const Color _inactive = Color(0xFF9E9E9E);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationBadgeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 3),
          child: Row(
            children: [
              _NavItem(
                asset: iconHome,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                asset: iconProjects,
                activeAsset: iconProjectsActive,
                label: 'Projects',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                asset: iconLeave,
                label: 'Leave',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                asset: iconNotifications,
                label: 'Updates',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
                badgeCount: notificationBadgeCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeAsset,
    this.badgeCount = 0,
  });

  final String asset;
  final String? activeAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.navy : AppBottomNavBar._inactive;
    final iconAsset = selected && activeAsset != null ? activeAsset! : asset;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      child: Image.asset(iconAsset, width: 24, height: 24, fit: BoxFit.contain),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.navy,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 99 ? '99' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: selected ? 36 : 0,
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
