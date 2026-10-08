import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/task_detail_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class TaskActivityLogScreen extends StatefulWidget {
  const TaskActivityLogScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskActivityLogScreen> createState() => _TaskActivityLogScreenState();
}

class _TaskActivityLogScreenState extends State<TaskActivityLogScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);

  late final AppController _appController;
  late Future<TaskDetailData?> _future;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _future = _appController.loadTaskDetail(taskId: widget.taskId);
  }

  String _formatEventLabel(String raw) {
    if (raw.trim().isEmpty) return 'Activity';
    return raw
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatLogDate(String? raw) {
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
      final day = date.day.toString().padLeft(2, '0');
      return '$day ${months[date.month - 1]}, ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  List<TaskActivityLogItem> _sortedLogs(List<TaskActivityLogItem> logs) {
    final copy = List<TaskActivityLogItem>.from(logs);
    copy.sort((a, b) {
      final ad = DateTime.tryParse((a.createdAt ?? '').replaceFirst(' ', 'T')) ?? DateTime(1970);
      final bd = DateTime.tryParse((b.createdAt ?? '').replaceFirst(' ', 'T')) ?? DateTime(1970);
      return bd.compareTo(ad);
    });
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          'Activity log',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<TaskDetailData?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoader());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final logs = _sortedLogs(snapshot.data?.activityLogs ?? const []);
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No activity logs found.',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              return _ActivityLogEntryCard(
                title: _formatEventLabel(log.event),
                userName: log.user?.name ?? 'User',
                dateLabel: _formatLogDate(log.createdAt),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActivityLogEntryCard extends StatelessWidget {
  const _ActivityLogEntryCard({
    required this.title,
    required this.userName,
    required this.dateLabel,
  });

  final String title;
  final String userName;
  final String dateLabel;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'By $userName',
            style: const TextStyle(
              fontSize: 14,
              color: _muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
