import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    _appController.loadTasks(refresh: true);
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait(<Future<void>>[
      _appController.loadMe(),
      _appController.loadTasks(refresh: true),
    ]);
  }

  DateTime? _tryParseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      return DateTime.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String? raw) {
    final date = raw == null ? null : _tryParseDate(raw);
    if (date == null) return '-';
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

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return const Color(0xFF1B8A5A);
      case 'qa':
        return const Color(0xFF00897B);
      case 'in_progress':
        return const Color(0xFF1565C0);
      case 'assigned':
        return const Color(0xFF8E24AA);
      case 'overdue':
        return const Color(0xFFC62828);
      default:
        return AppTheme.navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _appController.tasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.navy, AppTheme.lightNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.task_alt_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Track assigned work and task progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length} items',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Task List',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  Text(
                    'Page ${_appController.tasksCurrentPage}/${_appController.tasksLastPage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A778B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_appController.tasksLoading && tasks.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: AppLoader())
              else if (_appController.tasksError != null && tasks.isEmpty)
                _MessageCard(message: _appController.tasksError!, isError: true)
              else if (tasks.isEmpty)
                const _MessageCard(message: 'No tasks found. Pull down to refresh.')
              else
                ...tasks.map(
                  (task) => _TaskListCard(
                    task: task,
                    formatDate: _formatDate,
                    toLabel: _toLabel,
                    priorityColor: _priorityColor(task.priority),
                    statusColor: _statusColor(task.status),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: task.id.toString()),
                        ),
                      );
                    },
                  ),
                ),
              if (_appController.tasksError != null && tasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                _MessageCard(message: _appController.tasksError!, isError: true),
              ],
              if (_appController.tasksHasMore) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _appController.tasksLoadingMore ? null : _appController.loadMoreTasks,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _appController.tasksLoadingMore
                      ? const AppButtonLoader(color: AppTheme.navy, size: 20)
                      : const Text('Load more'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskListCard extends StatelessWidget {
  const _TaskListCard({
    required this.task,
    required this.formatDate,
    required this.toLabel,
    required this.priorityColor,
    required this.statusColor,
    required this.onTap,
  });

  final TaskItem task;
  final String Function(String?) formatDate;
  final String Function(String) toLabel;
  final Color priorityColor;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.description.isEmpty ? '-' : task.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5F6D84),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _TaskPill(
                      label: toLabel(task.priority),
                      background: priorityColor.withValues(alpha: 0.12),
                      foreground: priorityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TaskPill(
                      label: toLabel(task.status),
                      background: statusColor.withValues(alpha: 0.12),
                      foreground: statusColor,
                    ),
                    _TaskPill(
                      label: toLabel(task.taskType),
                      background: const Color(0xFFE8EEFC),
                      foreground: AppTheme.navy,
                    ),
                    if (task.isSupportingTask)
                      const _TaskPill(
                        label: 'Supporting',
                        background: Color(0xFFFFF4E5),
                        foreground: Color(0xFFB26A00),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _TaskMetaRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Assigned to',
                  value: task.assignee?.name ?? '-',
                ),
                const SizedBox(height: 8),
                _TaskMetaRow(
                  icon: Icons.badge_outlined,
                  label: 'Created by',
                  value: task.creator?.name ?? '-',
                ),
                const SizedBox(height: 8),
                _TaskMetaRow(
                  icon: Icons.apartment_rounded,
                  label: 'Department',
                  value: task.department?.name ?? '-',
                ),
                const SizedBox(height: 8),
                _TaskMetaRow(
                  icon: Icons.event_outlined,
                  label: 'Dates',
                  value: '${formatDate(task.startDate)} -> ${formatDate(task.dueDate)}',
                ),
                const SizedBox(height: 8),
                _TaskMetaRow(
                  icon: Icons.schedule_rounded,
                  label: 'Estimated hours',
                  value: '${task.estimatedHours}h',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskMetaRow extends StatelessWidget {
  const _TaskMetaRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6A778B)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A778B),
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskPill extends StatelessWidget {
  const _TaskPill({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isError ? theme.colorScheme.error : const Color(0xFF5F6D84);
    final background = isError
        ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
        : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: isError ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
