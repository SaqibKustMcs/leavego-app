import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/news_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/services/notification_navigation_service.dart';
import 'package:leavego_app/services/push_notification_service.dart';
import 'package:leavego_app/ui/screens/create_news_screen.dart';
import 'package:leavego_app/ui/screens/my_leave_requests_screen.dart';
import 'package:leavego_app/ui/screens/my_today_tasks_screen.dart';
import 'package:leavego_app/ui/screens/news_screen.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppController _appController;

  Future<void> _onRefresh() async {
    await Future.wait<void>([
      _appController.loadDashboard(),
      _appController.loadNews(refresh: true),
      _appController.loadMyTodayTasks(refresh: true, applyPriorityFilter: false),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    _appController.loadDashboard();
    _appController.loadNews(refresh: true);
    _appController.loadMyTodayTasks(refresh: true, applyPriorityFilter: false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _appController.dashboardData;
    final role = (_appController.meData?.role ?? '').trim().toLowerCase();
    final isHodOrHr = role == 'hod' || role == 'hr';
    final summary = data?.summary;
    final pending = summary?.pending ?? data?.pendingHod ?? 0;
    final approved = summary?.approved ?? 0;
    final rejected = summary?.rejected ?? 0;
    final totalRequests = summary?.totalRequests ?? 0;
    final totalAssigned = summary?.totalAssigned ?? 0;
    final totalUsed = summary?.totalUsed ?? 0;
    final totalRemaining = summary?.totalRemaining ?? 0;
    final pendingHod = data?.pendingHod ?? 0;
    final pendingHr = data?.pendingHr ?? 0;
    final hrPending = data?.hrPendingLeaveRequests;
    final newsItems = _appController.newsItems;
    final newsLoading = _appController.newsLoading;
    final highlightTask = _appController.homePriorityTask;
    final todayTasksLoading = _appController.myTodayTasksLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
          children: [
            const SizedBox(height: 8),
            _HomeHeader(
              name: _appController.meData?.name ?? '',
              canCreateNews: AppRoles.canCreateNews(_appController.meData?.role),
              onCreateNewsTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CreateNewsScreen())),
            ),
            const SizedBox(height: 14),
            if (newsLoading && newsItems.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: SizedBox(height: 160, child: AppLoader(size: 32)),
              )
            else if (newsItems.isNotEmpty) ...[
              _NewsCarousel(
                items: newsItems.take(8).toList(),
                onSeeAll: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const NewsScreen())),
              ),
              const SizedBox(height: 14),
            ],
            if (_appController.dashboardLoading && data == null)
              const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: AppLoader()),
            // Container(
            //   padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            //   decoration: BoxDecoration(
            //     gradient: const LinearGradient(
            //       colors: [AppTheme.navy, AppTheme.lightNavy],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.circular(24),
            //     boxShadow: [
            //       BoxShadow(
            //         color: AppTheme.navy.withValues(alpha: 0.28),
            //         blurRadius: 24,
            //         offset: const Offset(0, 12),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         children: [
            //           Container(
            //             width: 42,
            //             height: 42,
            //             decoration: BoxDecoration(
            //               color: Colors.white.withValues(alpha: 0.16),
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //             child: const Icon(Icons.space_dashboard_rounded, color: Colors.white),
            //           ),
            //           const SizedBox(width: 12),
            //           Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 'Dashboard',
            //                 style: theme.textTheme.titleMedium?.copyWith(
            //                   color: Colors.white,
            //                   fontWeight: FontWeight.w700,
            //                 ),
            //               ),
            //               Text(
            //                 'Leave status overview',
            //                 style: theme.textTheme.bodySmall?.copyWith(
            //                   color: Colors.white.withValues(alpha: 0.8),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 18),
            //       if (_appController.dashboardLoading)
            //         const Center(
            //           child: Padding(
            //             padding: EdgeInsets.symmetric(vertical: 18),
            //             child: CircularProgressIndicator(color: Colors.white),
            //           ),
            //         )
            //       else if (_appController.dashboardError != null)
            //         Container(
            //           width: double.infinity,
            //           padding: const EdgeInsets.all(12),
            //           decoration: BoxDecoration(
            //             color: Colors.white.withValues(alpha: 0.13),
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           child: Text(
            //             _appController.dashboardError!,
            //             style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
            //           ),
            //         )
            //       else
            //         Row(
            //           children: [
            //             // Expanded(
            //             //   child: _MetricTile(
            //             //     title: isHodOrHr ? 'Pending HOD' : 'Pending',
            //             //     value: isHodOrHr ? '$pendingHod' : '$pending',
            //             //   ),
            //             // ),
            //             // const SizedBox(width: 10),
            //             Expanded(
            //               child: _MetricTile(
            //                 title: isHodOrHr ? 'Pending HR' : 'Approved',
            //                 value: isHodOrHr ? '$pendingHr' : '$approved',
            //               ),
            //             ),
            //           ],
            //         ),
            //       const SizedBox(height: 10),
            //       Row(
            //         children: [
            //           Expanded(
            //             child: _MetricTile(
            //               title: isHodOrHr ? 'Approved' : 'Rejected',
            //               value: isHodOrHr ? '${hrPending?.approved ?? approved}' : '$rejected',
            //             ),
            //           ),
            //           const SizedBox(width: 10),
            //           Expanded(
            //             child: _MetricTile(
            //               title: isHodOrHr ? 'Rejected' : 'Requests',
            //               value: isHodOrHr
            //                   ? '${hrPending?.rejected ?? rejected}'
            //                   : '$totalRequests',
            //             ),
            //           ),
            //         ],
            //       ),
            //       if (!isHodOrHr) ...[
            //         const SizedBox(height: 10),
            //         Row(
            //           children: [
            //             Expanded(
            //               child: _MetricTile(title: 'Assigned', value: '$totalAssigned'),
            //             ),
            //             const SizedBox(width: 10),
            //             Expanded(
            //               child: _MetricTile(title: 'Used', value: '$totalUsed'),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 10),
            //         Row(
            //           children: [
            //             Expanded(
            //               child: _MetricTile(title: 'Remaining', value: '$totalRemaining'),
            //             ),
            //             const SizedBox(width: 10),
            //             Expanded(
            //               child: _MetricTile(title: 'Requests', value: '$totalRequests'),
            //             ),
            //           ],
            //         ),
            //       ],
            //     ],
            //   ),
            // ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Today Task',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const MyTodayTasksScreen())),
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (todayTasksLoading && highlightTask == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: AppLoader(size: 28)),
                    )
                  else if (highlightTask != null) ...[
                    const SizedBox(height: 10),
                    _HomeTodayTaskCard(
                      task: highlightTask,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(taskId: highlightTask.id.toString()),
                          ),
                        );
                      },
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No pending due tasks right now.',
                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
                      ),
                    ),
                ],
              ),
            ),
            if (data != null && data.leaveBalances.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Leave Balances',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const MyLeaveRequestsScreen())),
                    // icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text(
                      'Leave Requests',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_appController.dashboardLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: AppLoader(size: 32),
                )
              else if (_appController.dashboardError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _appController.dashboardError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              else
                ...data.leaveBalances.map((item) {
                  final allocated = item.assigned;
                  final used = item.used;
                  final remaining = item.remaining;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.leaveTypeName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _BalanceStat(
                                title: 'Assigned',
                                value: '$allocated',
                                bg: const Color(0xFFDCE7FF),
                                fg: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BalanceStat(
                                title: 'Used',
                                value: '$used',
                                bg: const Color(0xFFFCE3E1),
                                fg: const Color(0xFF8B1D18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BalanceStat(
                                title: 'Remaining',
                                value: '$remaining',
                                bg: const Color(0xFFDFF5E2),
                                fg: const Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsCarousel extends StatefulWidget {
  const _NewsCarousel({required this.items, required this.onSeeAll});

  final List<NewsItem> items;
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
                  onTap: widget.onSeeAll,
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.canCreateNews,
    required this.onCreateNewsTap,
  });

  final String name;
  final bool canCreateNews;
  final VoidCallback onCreateNewsTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = name.trim().isEmpty ? 'there' : name.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, AppTheme.lightNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              _initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // if (canCreateNews)
          //   TextButton.icon(
          //     style: TextButton.styleFrom(
          //       foregroundColor: Colors.white,
          //       backgroundColor: Colors.white.withValues(alpha: 0.16),
          //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          //       minimumSize: Size.zero,
          //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(12),
          //         side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          //       ),
          //     ),
          //     onPressed: onCreateNewsTap,
          //     icon: const Icon(Icons.add_rounded, size: 16),
          //     label: const Text(
          //       'Create News',
          //       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          //     ),
          //   ),
        ],
      ),
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
                    _formatDate(task.dueDate),
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
