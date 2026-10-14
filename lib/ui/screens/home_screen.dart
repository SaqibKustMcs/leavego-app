import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/dashboard_response.dart';
import 'package:leavego_app/models/my_leaves_response.dart';
import 'package:leavego_app/models/news_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/services/push_notification_service.dart';
import 'package:leavego_app/ui/models/today_glance_tab.dart';
import 'package:leavego_app/ui/screens/my_today_tasks_screen.dart';
import 'package:leavego_app/ui/screens/today_glance_screen.dart';
import 'package:leavego_app/ui/widgets/today_glance_empty_tasks.dart';
import 'package:leavego_app/ui/widgets/today_glance_tab_switcher.dart';
import 'package:leavego_app/ui/screens/news_detail_screen.dart';
import 'package:leavego_app/ui/screens/news_screen.dart';
import 'package:leavego_app/ui/screens/leave_report_screen.dart';
import 'package:leavego_app/ui/screens/my_leave_requests_screen.dart';
import 'package:leavego_app/models/google_calendar_response.dart';
import 'package:leavego_app/ui/screens/profile_screen.dart';
import 'package:leavego_app/ui/widgets/glance_compact_stepper.dart';
import 'package:leavego_app/ui/widgets/glance_meeting_labels.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/utils/task_datetime_format.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _handWaveIcon = 'assets/images/hand-wave.webp';
  static const String _barChartIcon = 'assets/images/bar-chart.webp';
  static const String _nextUpIcon = 'assets/images/next_up.webp';
  static const String _speakerIcon = 'assets/images/speaker-one.webp';
  static const String _workPulseIcon = 'assets/images/work_pulse.webp';
  static const String _leaveCalendarIcon = 'assets/images/calendar-range.png';

  late final AppController _appController;

  Future<void> _promptGoogleCalendarConnect() async {
    if (_appController.googleCalendarConnectLoading) return;
    final ok = await _appController.connectGoogleCalendar();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google Calendar connected')));
      return;
    }
    final msg = _appController.googleCalendarConnectError;
    if (msg != null && msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _onGlanceTabChanged(TodayGlanceTab tab) {
    _appController.setTodayGlanceTab(tab);
    if (tab == TodayGlanceTab.meetings) {
      unawaited(_prepareMeetingsGlanceOnHome());
    }
  }

  Future<void> _prepareMeetingsGlanceOnHome() async {
    await _appController.ensureGoogleCalendarReady(refreshEvents: true);
    if (!mounted) return;
    if (!_appController.googleCalendarConnected) {
      _promptGoogleCalendarConnect();
    }
  }

  Future<void> _onRefresh() async {
    final refreshJobs = <Future<void>>[
      _appController.loadMe(),
      _appController.loadDashboard(),
      _appController.loadNews(refresh: true),
      _appController.loadMyTodayTasks(refresh: true, applyPriorityFilter: false),
      _appController.loadMyLeaves(),
    ];
    if (_appController.todayGlanceTab == TodayGlanceTab.meetings) {
      refreshJobs.add(_appController.ensureGoogleCalendarReady(refreshEvents: true));
    }
    await Future.wait<void>(refreshJobs);
  }

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadMe();
    _appController.loadDashboard();
    _appController.loadNews(refresh: true);
    _appController.loadMyTodayTasks(refresh: true, applyPriorityFilter: false);
    _appController.loadMyLeaves();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // _appController.ensureGoogleCalendarReady();
      }
    });
    _setupPushNotifications();
  }

  String get _platformName => Platform.isIOS ? 'ios' : 'android';

  Future<void> _setupPushNotifications() async {
    final push = PushNotificationService.instance;
    await push.initialize();

    push.onMessage = (_) {
      if (!mounted) return;
      _appController.loadUnreadCount();
    };
    push.onMessageOpened = (message) async {
      _appController.loadUnreadCount();
      await NotificationNavigationService.openFromRemoteMessage(message);
    };
    push.onTokenRefresh = (token) async {
      final deviceName = await push.getDeviceName();
      _appController.registerFcmToken(token, platform: _platformName, deviceName: deviceName);
    };

    // Permission is requested from MainScreen after bottom navbar is visible.
    final token = await push.getToken();
    if (token != null && token.isNotEmpty) {
      final deviceName = await push.getDeviceName();
      await _appController.registerFcmToken(token, platform: _platformName, deviceName: deviceName);
    }

    final initialMessage = await push.getInitialMessage();
    if (initialMessage != null) {
      _appController.loadUnreadCount();
      // Wait for navigator to be ready after cold start.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await NotificationNavigationService.openFromRemoteMessage(initialMessage);
      });
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

  String _pulseCount(int value) => value < 10 ? value.toString().padLeft(2, '0') : '$value';

  int _leaveCreditsFromDashboard(DashboardData? data) {
    if (data == null) return 0;
    final summary = data.summary;
    if (summary != null) return summary.totalRemaining;
    final balances = data.leaveBalances;
    if (balances.isEmpty) return 0;
    return balances.fold<int>(0, (sum, item) => sum + item.remaining);
  }

  MyLeaveItem? _lastApprovedLeave(List<MyLeaveItem> leaves) {
    final approved = leaves.where((item) {
      final raw = item.finalStatus.trim().isNotEmpty ? item.finalStatus : item.status;
      return raw.trim().toLowerCase().replaceAll('_', ' ') == 'approved';
    }).toList();
    if (approved.isEmpty) return null;
    approved.sort((a, b) {
      final ad = _parseLeaveDate(a.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = _parseLeaveDate(b.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return approved.first;
  }

  DateTime? _parseLeaveDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.contains(' ') ? raw.split(' ').first : raw);
    } catch (_) {
      return null;
    }
  }

  String _leaveRangeLabel(String startRaw, String endRaw) {
    final start = _parseLeaveDate(startRaw);
    final end = _parseLeaveDate(endRaw);
    if (start == null || end == null) return '—';
    return '${_leaveDayMonth(start)} - ${_leaveDayMonth(end)}';
  }

  String _leaveDayMonth(DateTime date) {
    const months = [
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
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final data = _appController.dashboardData;
    final newsItems = _appController.newsItems;
    final newsLoading = _appController.newsLoading;
    final highlightTask = _appController.homePriorityTask;
    final todayTasks = _appController.myTodayTasks;
    final todayTasksLoading = _appController.myTodayTasksLoading;
    final tasksDueCount = _appController.myTodayTasksTotal > 0
        ? _appController.myTodayTasksTotal
        : todayTasks.length;
    final todayTasksProgressTotal = _appController.myTodayTasksProgressTotal;
    final todayTasksProgressCompleted = _appController.myTodayTasksProgressCompleted;
    final todayTasksProgressFraction = _appController.myTodayTasksProgressFraction;
    final taskSummary = data?.tasks;
    final leaveCredits = _leaveCreditsFromDashboard(data);
    final lastLeave = _lastApprovedLeave(_appController.myLeaves);
    final canViewLeaveReport = AppRoles.canViewLeaveReport(_appController.meData?.role);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            children: [
              _HomeHeader(
                name: _appController.meData?.name ?? '',
                handWaveIcon: _handWaveIcon,
                barChartIcon: _barChartIcon,
                showBarChart: canViewLeaveReport,
                todayTasksTotal: todayTasksProgressTotal,
                todayTasksCompleted: todayTasksProgressCompleted,
                todayTasksProgressLoading: todayTasksLoading,
                onProfileTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                onBarChartTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LeaveReportScreen())),
              ),
              const SizedBox(height: 18),
              _TodayAtGlanceCard(
                selectedTab: _appController.todayGlanceTab,
                onTabChanged: _onGlanceTabChanged,
                tasksDueCount: tasksDueCount,
                tasksProgressFraction: todayTasksProgressFraction,
                tasks: todayTasks.take(3).toList(),
                loading: todayTasksLoading,
                calendarConnected: _appController.googleCalendarConnected,
                meetingsLoading: _appController.googleCalendarEventsLoading,
                upcomingMeetings: _appController.googleCalendarTodayUpcomingMeetings
                    .take(3)
                    .toList(),
                onConnectCalendar: _promptGoogleCalendarConnect,
                connectCalendarLoading: _appController.googleCalendarConnectLoading,
                onViewAll: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TodayGlanceScreen())),
                onTaskTap: (task) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id.toString())),
                  );
                },
              ),
              const SizedBox(height: 14),
              if (highlightTask != null)
                _NextUpCard(
                  iconAsset: _nextUpIcon,
                  task: highlightTask,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: highlightTask.id.toString()),
                      ),
                    );
                  },
                ),
              if (highlightTask != null) const SizedBox(height: 14),
              if (newsLoading && newsItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: SizedBox(height: 88, child: AppLoader(size: 28)),
                )
              else if (newsItems.isNotEmpty)
                _CompanyUpdateCard(
                  iconAsset: _speakerIcon,
                  news: newsItems.first,
                  onViewAll: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NewsDetailScreen(news: newsItems.first)),
                  ),
                ),
              if (newsItems.isNotEmpty) const SizedBox(height: 14),
              if (taskSummary != null)
                _WorkPulseCard(
                  iconAsset: _workPulseIcon,
                  toDo: taskSummary.assigned + taskSummary.accepted,
                  inProgress: taskSummary.inProgress,
                  completed: taskSummary.completed,
                  formatCount: _pulseCount,
                  onViewAll: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MyTodayTasksScreen())),
                ),
              if (data != null) ...[
                const SizedBox(height: 14),
                _HomeLeaveBalancesCard(
                  calendarIcon: _leaveCalendarIcon,
                  leaveCredits: leaveCredits,
                  lastLeaveRange: lastLeave == null
                      ? null
                      : _leaveRangeLabel(lastLeave.startDate, lastLeave.endDate),
                  lastLeaveDays: lastLeave?.days,
                  onViewDetails: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MyLeaveRequestsScreen())),
                ),
              ],
              if (_appController.dashboardLoading && data == null)
                const Padding(padding: EdgeInsets.only(top: 16), child: AppLoader()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCarousel extends StatefulWidget {
  const _NewsCarousel({required this.items, required this.onSeeAll, required this.onItemTap});

  final List<NewsItem> items;
  final void Function(NewsItem item) onItemTap;
  final VoidCallback onSeeAll;

  @override
  State<_NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<_NewsCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _NewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _currentPage = 0;
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (widget.items.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(String? raw) {
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
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Latest News',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onSeeAll,
              child: Text(
                'See all',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _NewsCarouselCard(
                  item: item,
                  dateLabel: _formatDate(item.publishedAt ?? item.createdAt),
                  onTap: () => widget.onItemTap(item),
                ),
              );
            },
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.items.length, (index) {
              final active = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? AppTheme.navy : AppTheme.navy.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _NewsCarouselCard extends StatelessWidget {
  const _NewsCarouselCard({required this.item, required this.dateLabel, required this.onTap});

  final NewsItem item;
  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final audience = item.targetAudience.trim();
    final imageUrl = item.image?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppTheme.navy, AppTheme.lightNavy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navy.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (imageUrl != null &&
                  imageUrl.isNotEmpty &&
                  (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')))
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.navy.withValues(alpha: 0.92),
                      AppTheme.lightNavy.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (audience.isNotEmpty) SizedBox(),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withValues(alpha: 0.18),
                        //     borderRadius: BorderRadius.circular(999),
                        //   ),
                        //   child: Text(
                        //     audience.toUpperCase(),
                        //     style: const TextStyle(
                        //       color: Colors.white,
                        //       fontWeight: FontWeight.w800,
                        //       fontSize: 10,
                        //     ),
                        //   ),
                        // ),
                        const Spacer(),
                        const Icon(Icons.campaign_rounded, color: Colors.white70, size: 20),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.title.isEmpty ? 'Company News' : item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.content.isEmpty ? '-' : item.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        dateLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavingHandIcon extends StatefulWidget {
  const _WavingHandIcon({required this.assetPath});

  final String assetPath;

  @override
  State<_WavingHandIcon> createState() => _WavingHandIconState();
}

class _WavingHandIconState extends State<_WavingHandIcon> with SingleTickerProviderStateMixin {
  static const double _size = 18;

  late final AnimationController _controller;
  late final Animation<double> _wave;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _wave = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: -0.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.25, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, child) {
        return Transform.rotate(
          angle: _wave.value,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: Image.asset(widget.assetPath, width: _size, height: _size, fit: BoxFit.contain),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.handWaveIcon,
    required this.barChartIcon,
    required this.showBarChart,
    required this.todayTasksTotal,
    required this.todayTasksCompleted,
    required this.todayTasksProgressLoading,
    required this.onProfileTap,
    required this.onBarChartTap,
  });

  final String name;
  final String handWaveIcon;
  final String barChartIcon;
  final bool showBarChart;
  final int todayTasksTotal;
  final int todayTasksCompleted;
  final bool todayTasksProgressLoading;
  final VoidCallback onProfileTap;
  final VoidCallback onBarChartTap;

  static const Color _primary = Color(0xFF173559);

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'there' : name.trim();

    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Color(0xffFFFFFF),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Color(0xff0000000).withOpacity(0.05),
            spreadRadius: 0.1,
            blurRadius: 0.4,
            offset: Offset(0, 0.6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onProfileTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E7FE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2CEFE), width: 0.5),
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Hey,',
                          style: TextStyle(
                            color: Color(0xFF6A778B),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _WavingHandIcon(assetPath: handWaveIcon),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (todayTasksTotal > 0 || todayTasksProgressLoading) ...[
                      const SizedBox(height: 2),
                      Container(
                        width: 135,
                        child: LinearProgressBar(
                          maxSteps: todayTasksTotal > 0 ? todayTasksTotal : 1,
                          progressType: ProgressType.linear,
                          currentStep: todayTasksCompleted.clamp(
                            0,
                            todayTasksTotal > 0 ? todayTasksTotal : 1,
                          ),
                          progressColor: const Color(0xFF2B68B1),
                          backgroundColor: const Color(0xFFBE2A30),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 3,
                        ),
                      ),
                      // const SizedBox(height: 2),
                      // Text(
                      //   todayTasksTotal > 0
                      //       ? '$todayTasksCompleted of $todayTasksTotal tasks done today'
                      //       : "Loading today's tasks…",
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: const TextStyle(
                      //     color: Color(0xFF6A778B),
                      //     fontWeight: FontWeight.w500,
                      //     fontSize: 11,
                      //   ),
                      // ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (showBarChart)
            Material(
              color: const Color(0xFFF1E7FE),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onBarChartTap,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(barChartIcon, width: 22, height: 22, fit: BoxFit.contain),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingsGlanceSection extends StatelessWidget {
  const _MeetingsGlanceSection({
    required this.connected,
    required this.loading,
    required this.events,
    required this.onConnect,
    required this.connectLoading,
  });

  final bool connected;
  final bool loading;
  final List<GoogleCalendarEventItem> events;
  final VoidCallback onConnect;
  final bool connectLoading;

  @override
  Widget build(BuildContext context) {
    if (!connected) {
      return InkWell(
        onTap: connectLoading ? null : onConnect,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            const TodayGlanceEmptyTasks(
              compact: true,
              message: 'Tap to sign in with Google and see today’s meetings.',
            ),
            const SizedBox(height: 10),
            if (connectLoading)
              const AppLoader(size: 28)
            else
              TextButton(onPressed: onConnect, child: const Text('Connect Google Calendar')),
          ],
        ),
      );
    }
    if (loading && events.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: AppLoader(size: 28));
    }
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: TodayGlanceEmptyTasks(compact: true, message: 'No meetings scheduled for today.'),
        ),
      );
    }
    const stepColors = <Color>[Color(0xFF82CEB1), Color(0xFF4DA992), Color(0xFF5B9BD5)];
    return GlanceCompactStepperList(
      items: [
        for (var i = 0; i < events.length; i++)
          GlanceCompactStepperItem(
            title: events[i].summary,
            subtitle: GlanceMeetingLabels.compactSubtitle(events[i]),
            dotColor: stepColors[i % stepColors.length],
            onTap: () => GlanceMeetingLabels.openEvent(events[i]),
          ),
      ],
    );
  }
}

class _TodayAtGlanceCard extends StatelessWidget {
  const _TodayAtGlanceCard({
    required this.selectedTab,
    required this.onTabChanged,
    required this.tasksDueCount,
    required this.tasksProgressFraction,
    required this.tasks,
    required this.loading,
    required this.calendarConnected,
    required this.meetingsLoading,
    required this.upcomingMeetings,
    required this.onConnectCalendar,
    required this.connectCalendarLoading,
    required this.onViewAll,
    required this.onTaskTap,
  });

  final TodayGlanceTab selectedTab;
  final ValueChanged<TodayGlanceTab> onTabChanged;
  final int tasksDueCount;
  final double tasksProgressFraction;
  final List<TaskItem> tasks;
  final bool loading;
  final bool calendarConnected;
  final bool meetingsLoading;
  final List<GoogleCalendarEventItem> upcomingMeetings;
  final VoidCallback onConnectCalendar;
  final bool connectCalendarLoading;
  final VoidCallback onViewAll;
  final ValueChanged<TaskItem> onTaskTap;

  static const Color _primary = Color(0xFF173559);
  static const _stepColors = <Color>[Color(0xFF82CEB1), Color(0xFF4DA992), Color(0xFF5B9BD5)];

  String _taskTimeLabel(TaskItem task) {
    final start = TaskDateTimeFormat.formatTime(task.startTime);
    final end = TaskDateTimeFormat.formatTime(task.dueTime);
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    if (end.isNotEmpty) return end;
    if (start.isNotEmpty) return start;
    return TaskDateTimeFormat.formatDate(task.dueDate);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Today’s at a glance',
                  style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              TodayGlanceTabSwitcher(compact: true, selected: selectedTab, onChanged: onTabChanged),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedTab == TodayGlanceTab.meetings)
            _MeetingsGlanceSection(
              connected: calendarConnected,
              loading: meetingsLoading,
              events: upcomingMeetings,
              onConnect: onConnectCalendar,
              connectLoading: connectCalendarLoading,
            )
          else if (loading && tasks.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: AppLoader(size: 28))
          else if (tasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: TodayGlanceEmptyTasks(compact: true),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _GradientDonutRing(
                        progress: tasksDueCount > 0 ? tasksProgressFraction : 0.35,
                        size: 93,
                        strokeWidth: 6,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$tasksDueCount',
                            style: const TextStyle(
                              color: Color(0xff000000),
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const Text(
                            'Tasks due',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF000000),
                              fontWeight: FontWeight.w400,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GlanceTaskStepper(
                    tasks: tasks,
                    stepColors: _stepColors,
                    timeLabelFor: _taskTimeLabel,
                    onTaskTap: onTaskTap,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6A778B),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'View All ',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Color(0xff6E6E6E),
                      fontSize: 12,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_sharp, size: 13, color: Color(0xff6E6E6E)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientDonutRing extends StatelessWidget {
  const _GradientDonutRing({required this.progress, required this.size, required this.strokeWidth});

  final double progress;
  final double size;
  final double strokeWidth;

  static const Color _track = Color(0xFFD9D9D9);
  static const Color _gradientStart = Color(0xFF4DA992);
  static const Color _gradientEnd = Color(0xFF82CEB1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GradientDonutRingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          trackColor: _track,
          gradientStart: _gradientStart,
          gradientEnd: _gradientEnd,
        ),
      ),
    );
  }
}

class _GradientDonutRingPainter extends CustomPainter {
  _GradientDonutRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: [gradientStart, gradientEnd],
      stops: const [0.0, 1.0],
      transform: GradientRotation(-math.pi / 2),
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(arcRect.inflate(strokeWidth))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientDonutRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.gradientStart != gradientStart ||
        oldDelegate.gradientEnd != gradientEnd;
  }
}

class _GlanceTaskStepper extends StatelessWidget {
  const _GlanceTaskStepper({
    required this.tasks,
    required this.stepColors,
    required this.timeLabelFor,
    required this.onTaskTap,
  });

  final List<TaskItem> tasks;
  final List<Color> stepColors;
  final String Function(TaskItem task) timeLabelFor;
  final ValueChanged<TaskItem> onTaskTap;

  static const Color _line = Color(0xFF173559);
  static const double _dotSize = 10;
  static const double _railWidth = 22;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (tasks.length > 1)
              Positioned(
                left: (_railWidth - 1.5) / 2,
                top: _dotSize / 2 + 2,
                bottom: _dotSize / 2 + 2,
                child: Container(width: 1.5, color: _line.withValues(alpha: 0.35)),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tasks.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == tasks.length - 1 ? 0 : 14),
                    child: _GlanceStepperRow(
                      dotColor: stepColors[i % stepColors.length],
                      title: tasks[i].title,
                      subtitle: timeLabelFor(tasks[i]),
                      onTap: () => onTaskTap(tasks[i]),
                      railWidth: _railWidth,
                      dotSize: _dotSize,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GlanceStepperRow extends StatelessWidget {
  const _GlanceStepperRow({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.railWidth,
    required this.dotSize,
  });

  final Color dotColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double railWidth;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: railWidth,
              child: Center(
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.35),
                        blurRadius: 0,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF000000),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF17355B),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.iconAsset, required this.task, required this.onTap});

  final String iconAsset;
  final TaskItem task;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    final projectName = task.project?.name ?? 'Task';
    return Material(
      color: const Color(0xFFF0FFFA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Next Up',
                      style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Due today ',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xff6E6E6E),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_sharp, size: 13, color: Color(0xff6E6E6E)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF55957F),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(iconAsset, width: 22, height: 22, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              projectName,
                              style: const TextStyle(
                                color: Color(0xFF6A778B),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 12),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF26A69A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Due today',
                                  style: TextStyle(
                                    color: Color(0xFF6A778B),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyUpdateCard extends StatelessWidget {
  const _CompanyUpdateCard({
    required this.iconAsset,
    required this.news,
    required this.onViewAll,
    required this.onTap,
  });

  final String iconAsset;
  final NewsItem news;
  final VoidCallback onViewAll;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    final raw = news.content.trim().isNotEmpty ? news.content.trim() : news.title;
    final body = raw.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return Material(
      color: const Color(0xFFFAF6FF),
      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        onTap: onTap,

        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(width: 0.5, color: Color(0xffEEEEEE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(iconAsset, width: 22, height: 22, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Company Update',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6A778B),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'View all ',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xff6E6E6E),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_sharp, size: 13, color: Color(0xff6E6E6E)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF17355B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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

class _WorkPulseCard extends StatelessWidget {
  const _WorkPulseCard({
    required this.iconAsset,
    required this.toDo,
    required this.inProgress,
    required this.completed,
    required this.formatCount,
    required this.onViewAll,
  });

  final String iconAsset;
  final int toDo;
  final int inProgress;
  final int completed;
  final String Function(int value) formatCount;
  final VoidCallback onViewAll;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF000000).withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(iconAsset, width: 24, height: 24, fit: BoxFit.contain),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Work Pulse',
                  style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6A778B),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    const Text(
                      'View all ',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xff6E6E6E),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_sharp, size: 13, color: Color(0xff6E6E6E)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WorkPulseMetric(
                  value: formatCount(toDo),
                  label: 'To Do',
                  dotColor: const Color(0xFF2B68B1),
                ),
              ),
              Expanded(
                child: _WorkPulseMetric(
                  value: formatCount(inProgress),
                  label: 'In Progress',
                  dotColor: const Color(0xFF7B1FA2),
                ),
              ),
              Expanded(
                child: _WorkPulseMetric(
                  value: formatCount(completed),
                  label: 'Completed',
                  dotColor: const Color(0xFF26A69A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeLeaveBalancesCard extends StatelessWidget {
  const _HomeLeaveBalancesCard({
    required this.calendarIcon,
    required this.leaveCredits,
    required this.lastLeaveRange,
    required this.lastLeaveDays,
    required this.onViewDetails,
  });

  final String calendarIcon;
  final int leaveCredits;
  final String? lastLeaveRange;
  final int? lastLeaveDays;
  final VoidCallback onViewDetails;

  static const Color _primary = Color(0xFF173559);
  static const Color _mintPanel = Color(0xFFF0FAF8);
  static const Color _muted = Color(0xFF6E778B);

  @override
  Widget build(BuildContext context) {
    final daysLabel = lastLeaveDays == null
        ? null
        : '(${lastLeaveDays!} ${lastLeaveDays == 1 ? 'Day' : 'Days'})';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Leave Balances',
                  style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: onViewDetails,
                style: TextButton.styleFrom(
                  foregroundColor: _muted,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text(
                      'View details ',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xff6E6E6E),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_sharp, size: 13, color: Color(0xff6E6E6E)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$leaveCredits',
                          style: const TextStyle(
                            color: Color(0xff000000),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Leave Credits',
                          style: TextStyle(
                            color: Color(0xff4C4C4C),
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Color(0xff17355B).withOpacity(0.1),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Last Leave',
                          style: TextStyle(
                            color: Color(0xff4C4C4C),
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (lastLeaveRange != null) ...[
                          Row(
                            children: [
                              Image.asset(calendarIcon, width: 18, height: 18, fit: BoxFit.contain),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  lastLeaveRange!,
                                  style: const TextStyle(
                                    color: Color(0xFF000000),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (daysLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              daysLabel,
                              style: const TextStyle(
                                color: Color(0xff4C4C4C),
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ] else
                          const Text(
                            'No approved leave yet.',
                            style: TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkPulseMetric extends StatelessWidget {
  const _WorkPulseMetric({required this.value, required this.label, required this.dotColor});

  final String value;
  final String label;
  final Color dotColor;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xff000000),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeTodayTaskCard extends StatelessWidget {
  const _HomeTodayTaskCard({required this.task, required this.onTap});

  final TaskItem task;
  final VoidCallback onTap;

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
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
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _toLabel(String raw) {
    if (raw.trim().isEmpty) return '-';
    return raw
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Color _priorityColor(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'urgent':
        return const Color(0xFFC62828);
      case 'high':
        return const Color(0xFFEF6C00);
      case 'medium':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = task.priority.trim().toLowerCase();
    final priorityColor = _priorityColor(priority);
    final projectName = task.project?.name ?? '';

    return Material(
      color: const Color(0xFFF8FAFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _toLabel(task.priority),
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (task.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5F6D84),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (projectName.isNotEmpty) ...[
                    const Icon(Icons.folder_outlined, size: 16, color: Color(0xFF6A778B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  const Icon(Icons.event_outlined, size: 16, color: Color(0xFF6A778B)),
                  const SizedBox(width: 6),
                  Text(
                    TaskDateTimeFormat.formatDateTime(date: task.dueDate, time: task.dueTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.title,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final String title;
  final String value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
