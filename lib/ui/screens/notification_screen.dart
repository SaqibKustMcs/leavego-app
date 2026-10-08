import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/notifications_response.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

enum _NotificationFilter { all, mentions }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);

  late final AppController _appController;
  late final RefreshController _refreshController;
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadNotifications(refresh: true);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  void _completeLoadMoreFooter() {
    if (_appController.notificationsHasMore) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }

  Future<void> _onPullRefresh() async {
    await _appController.loadNotifications(refresh: true);
    if (!mounted) return;
    _refreshController.refreshCompleted();
    if (_appController.notificationsHasMore) {
      _refreshController.resetNoData();
    } else {
      _refreshController.loadNoData();
    }
  }

  Future<void> _onPullLoadMore() async {
    await _appController.loadMoreNotifications();
    if (!mounted) return;
    _completeLoadMoreFooter();
  }

  Future<void> _readAll() async {
    final message = await _appController.readAllNotifications();
    if (!mounted) return;
    if (message != null) {
      await _appController.loadNotifications(refresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else if (_appController.notificationsReadAllError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_appController.notificationsReadAllError!)));
    }
  }

  bool _isMention(AppNotificationItem item) {
    final type = item.type.toLowerCase();
    if (type.contains('mention')) return true;
    final haystack = '${item.title} ${item.message}'.toLowerCase();
    return haystack.contains('@') || haystack.contains('mentioned');
  }

  List<AppNotificationItem> _filtered(List<AppNotificationItem> items) {
    if (_filter == _NotificationFilter.mentions) {
      return items.where(_isMention).toList();
    }
    return items;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) {
      final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final diffDays = today.difference(day).inDays;
    if (diffDays > 0 && diffDays < 7) {
      return '${diffDays}d ago';
    }

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
    if (date.year == now.year) {
      return '${date.day} ${months[date.month - 1]}';
    }
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _sectionFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';

    final diffDays = today.difference(day).inDays;
    if (diffDays > 0 && diffDays < 7) return 'Last 7 days';

    if (date.year == now.year && date.month == now.month) return 'This Month';

    return 'Earlier';
  }

  Map<String, List<AppNotificationItem>> _groupBySection(List<AppNotificationItem> items) {
    final sorted = List<AppNotificationItem>.from(items);
    sorted.sort((a, b) {
      final ad = _parseDate(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _parseDate(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    final map = <String, List<AppNotificationItem>>{};
    for (final item in sorted) {
      final date = _parseDate(item.createdAt);
      final section = date == null ? 'Earlier' : _sectionFor(date);
      map.putIfAbsent(section, () => <AppNotificationItem>[]).add(item);
    }
    return map;
  }

  static const List<String> _sectionOrder = ['Today', 'Last 7 days', 'This Month', 'Earlier'];

  Future<void> _openNotification(AppNotificationItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await _appController.readNotification(notificationId: item.id);
    if (!mounted) return;
    if (message == null && _appController.notificationReadError != null && !item.isRead) {
      messenger.showSnackBar(SnackBar(content: Text(_appController.notificationReadError!)));
    }
    if (!mounted) return;
    await NotificationNavigationService.openFromInAppNotification(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = _filtered(_appController.notifications);
    final grouped = _groupBySection(notifications);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: _appController.notificationsHasMore,
          onRefresh: _onPullRefresh,
          onLoading: _onPullLoadMore,
          // header: WaterDropMaterialHeader(backgroundColor: AppTheme.navy, color: Colors.white),
          footer: ClassicFooter(
            loadingText: 'Loading…',
            noDataText: 'No more notifications',
            idleText: 'Pull up to load more',
            textStyle: const TextStyle(color: _muted, fontSize: 13),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  if (_appController.unreadCount != 0)
                    TextButton(
                      onPressed: _appController.notificationsReadAllLoading ? null : _readAll,
                      child: _appController.notificationsReadAllLoading
                          ? const AppButtonLoader(size: 18, color: _primary)
                          : const Text(
                              'Read all',
                              style: TextStyle(color: _primary, fontWeight: FontWeight.w600),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _NotificationFilterTabs(
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 20),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _filter == _NotificationFilter.mentions
                        ? 'No mention notifications.'
                        : 'No notifications found.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
                  ),
                )
              else
                for (final section in _sectionOrder)
                  if (grouped[section]?.isNotEmpty == true) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 4),
                      child: Text(
                        section,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _primary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xffFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(width: 0.5, color: Color(0xffEEEEEE)),
                      ),
                      child: Column(
                        children: [
                          ...grouped[section]!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final items = grouped[section]!;
                            return _NotificationRow(
                              item: item,
                              timestamp: _formatTimestamp(
                                _parseDate(item.createdAt) ?? DateTime.now(),
                              ),
                              showDivider: index < items.length - 1,
                              onTap: () => _openNotification(item),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationFilterTabs extends StatelessWidget {
  const _NotificationFilterTabs({required this.selected, required this.onSelected});

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // color: const Color(0xFFE5F1FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _NotificationFilterTab(
            label: 'All',
            selected: selected == _NotificationFilter.all,
            onTap: () => onSelected(_NotificationFilter.all),
          ),
          SizedBox(width: 12),
          _NotificationFilterTab(
            label: 'Mentions',
            selected: selected == _NotificationFilter.mentions,
            onTap: () => onSelected(_NotificationFilter.mentions),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterTab extends StatelessWidget {
  const _NotificationFilterTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Material(
        color: selected ? _primary : Color(0xffEDF6FE),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            width: 118,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : _primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.timestamp,
    required this.onTap,
    this.showDivider = true,
  });

  final AppNotificationItem item;
  final String timestamp;
  final VoidCallback onTap;
  final bool showDivider;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);
  static const String _circleIcon = 'assets/images/circle-slice.webp';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !item.isRead;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Image.asset(_circleIcon, width: 20, height: 20, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w600,
                              color: _primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          if (item.message.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      item.message,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _muted,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _muted,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              height: 1,
              thickness: 1,
              color: const Color(0xFFEEF4F2).withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }
}
