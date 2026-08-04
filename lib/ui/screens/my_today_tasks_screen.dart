import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class MyTodayTasksScreen extends StatefulWidget {
  const MyTodayTasksScreen({super.key});

  @override
  State<MyTodayTasksScreen> createState() => _MyTodayTasksScreenState();
}

class _MyTodayTasksScreenState extends State<MyTodayTasksScreen> {
  late final AppController _appController;
  late final ScrollController _scrollController;

  static const _priorityTabs = <String?>[null, 'critical', 'high', 'medium', 'low'];
  static const _priorityLabels = <String>['All', 'Critical', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _scrollController = ScrollController()..addListener(_onScroll);
    _appController.addListener(_onUpdate);
    _appController.loadMyTodayTasks(refresh: true);
  }

  int _indexForPriority(String? priority) {
    final index = _priorityTabs.indexOf(priority);
    return index == -1 ? 0 : index;
  }

  Future<void> _onPriorityTabSelected(int index) async {
    final priority = _priorityTabs[index];
    if (_appController.myTodayTasksPriorityFilter == priority) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    await _appController.setMyTodayTasksPriorityFilter(priority);
  }

  String _emptyMessageForFilter() {
    final priority = _appController.myTodayTasksPriorityFilter;
    if (priority == null) return 'No pending due tasks found.';
    return 'No ${_toLabel(priority).toLowerCase()} priority tasks found.';
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_appController.myTodayTasksLoadingMore || !_appController.myTodayTasksHasMore) {
      return;
    }

    final threshold = 200.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
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

  Future<void> _onRefresh() async {
    await _appController.loadMyTodayTasks(refresh: true);
  }

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
    final tasks = _appController.myTodayTasks;
    final total = _appController.myTodayTasksTotal;
    final showingCount = tasks.length;
    final selectedIndex = _indexForPriority(_appController.myTodayTasksPriorityFilter);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('My Today Tasks'),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text(
                'Assigned pending, due, and overdue project tasks.',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 12),
              // SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
              //   child: Row(
              //     children: List.generate(_priorityLabels.length, (index) {
              //       final selected = selectedIndex == index;
              //       return Padding(
              //         padding: EdgeInsets.only(right: index == _priorityLabels.length - 1 ? 0 : 8),
              //         child: _PriorityFilterChip(
              //           label: _priorityLabels[index],
              //           selected: selected,
              //           onTap: () => _onPriorityTabSelected(index),
              //         ),
              //       );
              //     }),
              //   ),
              // ),
              // const SizedBox(height: 14),
              // Row(
              //   children: [
              //     Expanded(
              //       child: Text(
              //         'Tasks',
              //         style: theme.textTheme.titleMedium?.copyWith(
              //           fontWeight: FontWeight.w800,
              //           color: Colors.black,
              //         ),
              //       ),
              //     ),
              //     Text(
              //       total > 0
              //           ? 'Page ${_appController.myTodayTasksCurrentPage}/${_appController.myTodayTasksLastPage} · $showingCount/$total'
              //           : 'Page ${_appController.myTodayTasksCurrentPage}/${_appController.myTodayTasksLastPage}',
              //       style: theme.textTheme.bodySmall?.copyWith(
              //         color: const Color(0xFF6A778B),
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 10),
              if (_appController.myTodayTasksLoading && tasks.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: AppLoader())
              else if (_appController.myTodayTasksError != null && tasks.isEmpty)
                _MessageCard(message: _appController.myTodayTasksError!, isError: true)
              else if (tasks.isEmpty)
                _MessageCard(message: _emptyMessageForFilter())
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
              if (_appController.myTodayTasksError != null && tasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                _MessageCard(message: _appController.myTodayTasksError!, isError: true),
              ],
              if (_appController.myTodayTasksLoadingMore) ...[
                const SizedBox(height: 12),
                const Center(child: AppButtonLoader(color: AppTheme.navy, size: 22)),
              ] else if (_appController.myTodayTasksHasMore) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _appController.loadMoreMyTodayTasks,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Load more'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityFilterChip extends StatelessWidget {
  const _PriorityFilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.navy.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppTheme.navy : const Color(0xFFD7DEEA),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.navy : const Color(0xFF5F6D84),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
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
                  ],
                ),
                const SizedBox(height: 12),
                if (task.project?.name.isNotEmpty == true) ...[
                  _TaskMetaRow(
                    icon: Icons.folder_outlined,
                    label: 'Project',
                    value: task.project!.name,
                  ),
                  const SizedBox(height: 8),
                ],
                _TaskMetaRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Assigned to',
                  value: task.assignee?.name ?? '-',
                ),
                const SizedBox(height: 8),
                _TaskMetaRow(
                  icon: Icons.event_outlined,
                  label: 'Due date',
                  value: formatDate(task.dueDate),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? theme.colorScheme.errorContainer.withValues(alpha: 0.45) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError ? theme.colorScheme.error : const Color(0xFF5F6D84),
        ),
      ),
    );
  }
}
