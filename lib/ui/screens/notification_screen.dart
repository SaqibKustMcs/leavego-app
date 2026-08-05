import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final AppController _appController;

  Future<void> _onRefresh() async {
    await _appController.loadNotifications();
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final date = DateTime.parse(normalized).toLocal();
      const months = <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      final year = date.year;
      final hour12 = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, ${hour12.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadNotifications();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _readAll() async {
    final message = await _appController.readAllNotifications();
    if (!mounted) return;
    if (message != null) {
      await _appController.loadNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else if (_appController.notificationsReadAllError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_appController.notificationsReadAllError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = _appController.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stay updated on leave actions',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF5F6D84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  if (_appController.unreadCount != 0)
                    FilledButton.icon(
                      onPressed: _appController.notificationsReadAllLoading ? null : _readAll,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _appController.notificationsReadAllLoading
                          ? const AppButtonLoader(size: 18)
                          : const Icon(Icons.done_all_rounded, size: 18),
                      label: Text(
                        _appController.notificationsReadAllLoading ? 'Processing' : 'Read all',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_appController.notificationsLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader())
              else if (_appController.notificationsError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _appController.notificationsError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              else if (notifications.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No notifications found.'),
                )
              else
                ...notifications.map((item) {
                  final isUnread = !item.isRead;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isUnread ? const Color(0xFFF7FAFF) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isUnread ? Colors.red : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final notification = item;

                        // 1) Mark notification as read on the server first.
                        final message = await _appController.readNotification(
                          notificationId: notification.id,
                        );
                        if (!mounted) return;
                        if (message == null &&
                            _appController.notificationReadError != null &&
                            !notification.isRead) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(_appController.notificationReadError!)),
                          );
                        }

                        // 2) Then open the related screen (task / leave / news).
                        if (!mounted) return;
                        await NotificationNavigationService.openFromInAppNotification(notification);
                      },
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isUnread ? const Color(0xFFDCE7FF) : const Color(0xFFE8EEFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: isUnread ? AppTheme.navy : AppTheme.navy.withValues(alpha: 0.8),
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isUnread ? AppTheme.navy : null,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.message),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (isUnread)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCE7FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Unread',
                                      style: TextStyle(
                                        color: AppTheme.navy,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (isUnread) const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(item.createdAt),
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6A778B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
