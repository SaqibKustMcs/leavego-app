import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/screens/create_project_screen.dart';
import 'package:leavego_app/ui/screens/create_project_task_screen.dart';
import 'package:leavego_app/ui/screens/task_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/app_scroll_collapse_fab.dart';
import 'package:leavego_app/utils/app_roles.dart';
import 'package:leavego_app/utils/task_datetime_format.dart';

class ProjectTasksScreen extends StatefulWidget {
  const ProjectTasksScreen({super.key, required this.project});

  final ProjectItem project;

  @override
  State<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  static const Color _primary = Color(0xFF173559);

  late final AppController _appController;
  late final ScrollCollapseFabController _fabScrollController;
  String _selectedFilter = 'all';

  static const _filters = <_TaskFilterOption>[
    _TaskFilterOption(
      id: 'all',
      label: 'All Tasks',
      iconAsset: 'assets/images/all-tasks.webp',
      background: Color(0x8CDEF5F5),
      labelColor: Color(0xFF173559),
    ),
    _TaskFilterOption(
      id: 'assigned',
      label: 'Assigned',
      iconAsset: 'assets/images/assigned_task.webp',
      background: Color(0x5EE2CEFE),
      labelColor: Color(0xFF173559),
    ),
    _TaskFilterOption(
      id: 'in_progress',
      label: 'In Progress',
      iconAsset: 'assets/images/inprogress_task.webp',
      background: Color(0xFFE4F1FE),
      labelColor: Color(0xFF173559),
    ),
    _TaskFilterOption(
      id: 'completed',
      label: 'Completed',
      iconAsset: 'assets/images/completed_task.webp',
      background: Color(0xFFD9FCF0),
      labelColor: Color(0xFF1B5E20),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fabScrollController = ScrollCollapseFabController();
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
    _fabScrollController.dispose();
    _appController.removeListener(_onUpdate);
    super.dispose();
  }

  Future<void> _onFilterSelected(String filter) async {
    if (_selectedFilter == filter) return;
    setState(() => _selectedFilter = filter);
    await _appController.setProjectTasksFilter(projectId: widget.project.id, filter: filter);
  }

  Future<void> _onRefresh() async {
    await _appController.loadProjectTasks(projectId: widget.project.id, refresh: true);
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

  String _priorityLabel(String priority) {
    final value = priority.trim().toLowerCase();
    if (value == 'medium' || value == 'low' || value == 'normal') return 'Normal';
    return _toLabel(priority);
  }

  Color _priorityColor(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'critical':
      case 'urgent':
      case 'high':
        return const Color(0xFFFF2222);
      case 'medium':
      case 'low':
      case 'normal':
        return const Color(0xFF2B68B1);
      default:
        return const Color(0xFF2B68B1);
    }
  }

  String _emptyMessageForFilter() {
    switch (_selectedFilter) {
      case 'all':
        return 'No tasks found for this project.';
      default:
        final match = _filters.where((f) => f.id == _selectedFilter).toList();
        final label = match.isEmpty ? _toLabel(_selectedFilter) : match.first.label;
        return 'No ${label.toLowerCase()} found for this project.';
    }
  }

  Future<void> _openCreateTask() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateProjectTaskScreen(project: widget.project)),
    );
    if (created == true) {
      await _appController.loadProjectTasks(projectId: widget.project.id, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = _appController.projectTasks;
    final canEditProject = AppRoles.canManageProjects(_appController.meData?.role);
    final project = widget.project;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          project.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _primary,
            fontSize: 18,
          ),
        ),
        actions: [
          if (canEditProject)
            IconButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final updated = await navigator.push<bool>(
                  MaterialPageRoute(builder: (_) => CreateProjectScreen(project: project)),
                );
                if (updated == true && mounted) {
                  await _appController.loadProjects(refresh: true);
                  if (!mounted) return;
                  final matches = _appController.projects.where((item) => item.id == project.id);
                  if (matches.isNotEmpty) {
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => ProjectTasksScreen(project: matches.first)),
                    );
                  }
                }
              },
              icon: const Icon(Icons.edit_outlined, color: _primary),
              tooltip: 'Edit project',
            ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _fabScrollController,
        builder: (context, _) => AppScrollCollapseFab(
          label: 'Create Tasks',
          collapsed: _fabScrollController.collapsed,
          onPressed: _openCreateTask,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        top: false,
        child: AppFabScrollListener(
          controller: _fabScrollController,
          child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              SizedBox(
                height: 71,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final selected = _selectedFilter == filter.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _TaskFilterChip(
                          option: filter,
                          selected: selected,
                          onTap: () => _onFilterSelected(filter.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_appController.projectTasksLoading && tasks.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: AppLoader())
              else if (_appController.projectTasksError != null && tasks.isEmpty)
                _MessageCard(message: _appController.projectTasksError!, isError: true)
              else if (tasks.isEmpty)
                _MessageCard(message: _emptyMessageForFilter())
              else
                ...tasks.map(
                  (task) => _TaskListCard(
                    task: task,
                    toLabel: _toLabel,
                    priorityLabel: _priorityLabel(task.priority),
                    priorityColor: _priorityColor(task.priority),
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
      ),
    );
  }
}

class _TaskFilterOption {
  const _TaskFilterOption({
    required this.id,
    required this.label,
    required this.iconAsset,
    required this.background,
    required this.labelColor,
  });

  final String id;
  final String label;
  final String iconAsset;
  final Color background;
  final Color labelColor;
}

class _TaskFilterChip extends StatelessWidget {
  const _TaskFilterChip({required this.option, required this.selected, required this.onTap});

  final _TaskFilterOption option;
  final bool selected;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: option.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 112,
          // height: 61,
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // border: Border.all(
            //   color: selected ? _primary : Colors.transparent,
            //   width: selected ? 1.2 : 0,
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(option.iconAsset, width: 20, height: 20, fit: BoxFit.contain),
              const SizedBox(height: 10),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _primary,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w500,
                  fontSize: 14,
                  height: 1.15,
                ),
              ),
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
    required this.toLabel,
    required this.priorityLabel,
    required this.priorityColor,
    required this.onTap,
  });

  final TaskItem task;
  final String Function(String) toLabel;
  final String priorityLabel;
  final Color priorityColor;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6E6E6E);
  static const String _assignedIcon = 'assets/images/assigned_to.webp';
  static const String _dueIcon = 'assets/images/due_date_time.webp';
  static const String _priorityIcon = 'assets/images/flag.webp';

  ({Color background, Color foreground}) _statusStyle(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return (background: const Color(0xFFD9FCF0), foreground: const Color(0xFF1B5E20));
      case 'in_progress':
        return (background: const Color(0xFFE4F1FE), foreground: _primary);
      case 'assigned':
        return (background: const Color(0xFFEDE7F6), foreground: _primary);
      default:
        return (background: const Color(0xFFEEF2F6), foreground: _muted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _statusStyle(task.status);
    final dueText = TaskDateTimeFormat.formatDateTime(date: task.dueDate, time: task.dueTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusStyle.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        toLabel(task.status),
                        style: TextStyle(
                          color: statusStyle.foreground,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _muted,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _TaskDetailRow(
                  iconAsset: _assignedIcon,
                  label: 'Assigned to',
                  value: task.assignee?.name ?? '-',
                ),
                const SizedBox(height: 10),
                _TaskDetailRow(iconAsset: _dueIcon, label: 'Due Date & Time', value: dueText),
                const SizedBox(height: 10),
                _TaskDetailRow(
                  iconAsset: "assets/images/priority_flag.webp",
                  label: 'Priority',
                  value: priorityLabel,
                  valueColor: priorityColor,
                  trailing: ColorFiltered(
                    colorFilter: ColorFilter.mode(priorityColor, BlendMode.srcIn),
                    child: Image.asset(_priorityIcon, width: 18, height: 18, fit: BoxFit.contain),
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

class _TaskDetailRow extends StatelessWidget {
  const _TaskDetailRow({
    required this.iconAsset,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final String iconAsset;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Image.asset(iconAsset, width: 18, height: 18, fit: BoxFit.contain, color: _muted),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w400, fontSize: 14),
            ),
          ],
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
              Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _primary, fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
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
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
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
