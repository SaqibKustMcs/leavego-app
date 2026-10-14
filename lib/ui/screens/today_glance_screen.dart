import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/models/today_glance_tab.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/today_glance_meetings_body.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/today_glance_empty_tasks.dart';
import 'package:leavego_app/ui/widgets/glance_timeline_row.dart';
import 'package:leavego_app/ui/widgets/today_glance_tab_switcher.dart';
import 'package:leavego_app/utils/task_datetime_format.dart';

class TodayGlanceScreen extends StatefulWidget {
  const TodayGlanceScreen({super.key});

  @override
  State<TodayGlanceScreen> createState() => _TodayGlanceScreenState();
}

class _TodayGlanceScreenState extends State<TodayGlanceScreen> {
  late final AppController _appController;
  late final ScrollController _scrollController;

  static const Color _primary = Color(0xFF173559);

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _scrollController = ScrollController()..addListener(_onScroll);
    _appController.addListener(_onUpdate);
    if (_appController.myTodayTasks.isEmpty && !_appController.myTodayTasksLoading) {
      _appController.loadMyTodayTasks(refresh: true, applyPriorityFilter: false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_appController.myTodayTasksLoadingMore || !_appController.myTodayTasksHasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _appController.loadMoreMyTodayTasks();
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _promptGoogleCalendarConnect() async {
    if (_appController.googleCalendarConnectLoading) return;
    final ok = await _appController.connectGoogleCalendar();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Calendar connected')),
      );
      return;
    }
    final msg = _appController.googleCalendarConnectError;
    if (msg != null && msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _onTabChanged(TodayGlanceTab tab) {
    _appController.setTodayGlanceTab(tab);
    if (tab == TodayGlanceTab.meetings) {
      unawaited(_prepareMeetingsGlance());
    }
  }

  Future<void> _prepareMeetingsGlance() async {
    await _appController.ensureGoogleCalendarReady(refreshEvents: true);
    if (!mounted) return;
    if (!_appController.googleCalendarConnected) {
      await _promptGoogleCalendarConnect();
    }
  }

  Future<void> _onRefresh() async {
    if (_appController.todayGlanceTab == TodayGlanceTab.meetings) {
      await _appController.ensureGoogleCalendarReady(refreshEvents: true);
      return;
    }
    await _appController.loadMyTodayTasks(refresh: true, applyPriorityFilter: false);
  }

  String _weekdayLabel(TaskItem task) {
    final raw = task.dueDate ?? task.startDate;
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final normalized = raw.contains(' ') ? raw.split(' ').first : raw.split('T').first;
      final date = DateTime.parse(normalized).toLocal();
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _timeLabel(TaskItem task) {
    final end = TaskDateTimeFormat.formatTime(task.dueTime);
    if (end.isNotEmpty) return end;
    final start = TaskDateTimeFormat.formatTime(task.startTime);
    if (start.isNotEmpty) return start;
    return TaskDateTimeFormat.formatDate(task.dueDate);
  }

  String _assignmentLine(TaskItem task) {
    final assignee = (task.assignee?.name ?? task.assignedTo ?? '').trim();
    final creator = (task.creator?.name ?? task.assignedBy ?? '').trim();
    if (assignee.isEmpty && creator.isEmpty) return '';
    if (creator.isEmpty) return 'Assigned to $assignee';
    if (assignee.isEmpty) return 'Assigned by $creator';
    return 'Assigned to $assignee by $creator';
  }

  void _openTask(TaskItem task) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id.toString())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = _appController.todayGlanceTab;
    final tasks = _appController.myTodayTasks;
    final loading = _appController.myTodayTasksLoading;
    final error = _appController.myTodayTasksError;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Today’s Glance',
          style: TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TodayGlanceTabSwitcher(
              selected: tab,
              onChanged: _onTabChanged,
            ),
          ),
          Expanded(
            child: tab == TodayGlanceTab.meetings
                ? TodayGlanceMeetingsBody(
                    connected: _appController.googleCalendarConnected,
                    loading: _appController.googleCalendarEventsLoading,
                    error: _appController.googleCalendarEventsError,
                    events: _appController.googleCalendarUpcomingMeetings,
                    onRefresh: _onRefresh,
                    onConnect: _promptGoogleCalendarConnect,
                    connectLoading: _appController.googleCalendarConnectLoading,
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _TasksGlanceList(
                      scrollController: _scrollController,
                      tasks: tasks,
                      loading: loading && tasks.isEmpty,
                      loadingMore: _appController.myTodayTasksLoadingMore,
                      error: error,
                      weekdayFor: _weekdayLabel,
                      timeFor: _timeLabel,
                      assignmentFor: _assignmentLine,
                      onTaskTap: _openTask,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TasksGlanceList extends StatelessWidget {
  const _TasksGlanceList({
    required this.scrollController,
    required this.tasks,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.weekdayFor,
    required this.timeFor,
    required this.assignmentFor,
    required this.onTaskTap,
  });

  final ScrollController scrollController;
  final List<TaskItem> tasks;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final String Function(TaskItem) weekdayFor;
  final String Function(TaskItem) timeFor;
  final String Function(TaskItem) assignmentFor;
  final ValueChanged<TaskItem> onTaskTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120, child: AppLoader(size: 32)),
        ],
      );
    }

    if (error != null && tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ],
      );
    }

    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
        children: const [
          Center(child: TodayGlanceEmptyTasks()),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      itemCount: tasks.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= tasks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: AppLoader(size: 28)),
          );
        }

        final task = tasks[index];
        final isActive = index == 0;
        return GlanceTimelineRow(
          isActive: isActive,
          isLast: index == tasks.length - 1,
          title: task.title,
          weekday: weekdayFor(task),
          assignment: assignmentFor(task),
          time: timeFor(task),
          onTap: () => onTaskTap(task),
        );
      },
    );
  }
}
