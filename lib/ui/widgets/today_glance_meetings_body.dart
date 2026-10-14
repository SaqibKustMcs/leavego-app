import 'package:flutter/material.dart';
import 'package:leavego_app/models/google_calendar_response.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/glance_meeting_labels.dart';
import 'package:leavego_app/ui/widgets/glance_timeline_row.dart';
import 'package:leavego_app/ui/widgets/today_glance_empty_tasks.dart';

/// Shared meetings list (Today's Glance + Google Calendar) — task-style timeline UI.
class TodayGlanceMeetingsBody extends StatelessWidget {
  const TodayGlanceMeetingsBody({
    super.key,
    this.scrollController,
    required this.connected,
    required this.loading,
    this.loadingMore = false,
    required this.error,
    required this.events,
    required this.onRefresh,
    required this.onConnect,
    required this.connectLoading,
  });

  final ScrollController? scrollController;
  final bool connected;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<GoogleCalendarEventItem> events;
  final Future<void> Function() onRefresh;
  final VoidCallback onConnect;
  final bool connectLoading;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: _buildList(context));
  }

  Widget _buildList(BuildContext context) {
    if (!connected) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          Center(
            child: InkWell(
              onTap: connectLoading ? null : onConnect,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: TodayGlanceEmptyTasks(
                  message: 'Tap to sign in with Google and see your meetings.',
                ),
              ),
            ),
          ),
          if (connectLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: AppLoader()),
            )
          else
            Center(
              child: TextButton(onPressed: onConnect, child: const Text('Connect Google Calendar')),
            ),
        ],
      );
    }

    if (loading && events.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: 120, child: AppLoader(size: 32))],
      );
    }

    if (error != null && events.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }

    if (events.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
        children: const [
          Center(child: TodayGlanceEmptyTasks(message: 'No upcoming meetings from now.')),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      itemCount: events.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= events.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: AppButtonLoader()),
          );
        }

        final event = events[index];
        final isActive = index == 0;
        return GlanceTimelineRow(
          isActive: isActive,
          isLast: index == events.length - 1,
          title: event.summary,
          weekday: GlanceMeetingLabels.detailDateLabel(event),
          assignment: GlanceMeetingLabels.assignment(event),
          time: GlanceMeetingLabels.timeRange(event),
          onTap: () => GlanceMeetingLabels.openEvent(event),
        );
      },
    );
  }
}
