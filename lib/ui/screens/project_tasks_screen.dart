import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/screens/create_project_task_screen.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class ProjectTasksScreen extends StatefulWidget {
  const ProjectTasksScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  State<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  late final AppController _appController;
  String _selectedFilter = 'all';

  static const _filters = <Map<String, String>>[
    {'id': 'all', 'label': 'All'},
    {'id': 'my_tasks', 'label': 'My Tasks'},
    {'id': 'assigned', 'label': 'Assigned'},
  ];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.projectTasksMyTasksOnly = false;
    _appController.projectTasksStatusFilter = null;
    _appController.loadProjectTasks(projectId: widget.project.id, refresh: true);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onFilterSelected(String filter) async {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    await _appController.setProjectTasksFilter(
      projectId: widget.project.id,
      filter: filter,
    );
  }

  Future<void> _onRefresh() async {
    await _appController.loadProjectTasks(projectId: widget.project.id, refresh: true);
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
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
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

  String _emptyMessageForFilter() {
    switch (_selectedFilter) {
      case 'my_tasks':
        return 'No tasks assigned to you in this project.';
      case 'assigned':
        return 'No assigned tasks found for this project.';
      default:
        return 'No tasks found for this project.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _appController.projectTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreateProjectTaskScreen(project: widget.project),
            ),
          );
          if (created == true) {
            await _appController.loadProjectTasks(projectId: widget.project.id, refresh: true);
          }
        },
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Task'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.navy,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.project.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.project.description.isEmpty ? 'Project tasks' : widget.project.description,
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  Text(
                    'Page ${_appController.projectTasksCurrentPage}/${_appController.projectTasksLastPage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A778B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final id = filter['id']!;
                    final label = filter['label']!;
                    final selected = _selectedFilter == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => _onFilterSelected(id),
                        selectedColor: AppTheme.navy.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.navy : const Color(0xFF5F6D84),
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: selected ? AppTheme.navy : const Color(0xFFD7DEEA),
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (_appController.projectTasksLoading && tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: AppLoader(),
                )
              else if (_appController.projectTasksError != null && tasks.isEmpty)
                _MessageCard(message: _appController.projectTasksError!, isError: true)
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
              if (_appController.projectTasksError != null && tasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                _MessageCard(message: _appController.projectTasksError!, isError: true),
              ],
              if (_appController.projectTasksHasMore) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _appController.projectTasksLoadingMore
                      ? null
                      : _appController.loadMoreProjectTasks,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _appController.projectTasksLoadingMore
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
  const _TaskMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
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
  const _TaskPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
        color: isError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.45)
            : Colors.white,
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
