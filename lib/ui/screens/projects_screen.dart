import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/projects_response.dart';
import 'package:leavego_app/ui/screens/create_project_screen.dart';
import 'package:leavego_app/ui/screens/project_tasks_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/app_scroll_collapse_fab.dart';
import 'package:leavego_app/utils/app_roles.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  static const Color _primary = Color(0xFF173559);

  late final AppController _appController;
  late final ScrollCollapseFabController _fabScrollController;

  @override
  void initState() {
    super.initState();
    _fabScrollController = ScrollCollapseFabController();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadProjects(refresh: true);
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

  Future<void> _onRefresh() async {
    await _appController.loadProjects(refresh: true);
  }

  String _formatMonthYear(String? raw) {
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
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _formatDateRange(String? start, String? end) {
    final startLabel = _formatMonthYear(start);
    final endLabel = _formatMonthYear(end);
    if (startLabel.isEmpty && endLabel.isEmpty) return '-';
    if (startLabel.isEmpty) return endLabel;
    if (endLabel.isEmpty) return startLabel;
    return '$startLabel - $endLabel';
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

  bool get _canCreateProject => AppRoles.canManageProjects(_appController.meData?.role);

  Future<void> _openCreateProject() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateProjectScreen()));
    if (created == true) {
      await _appController.loadProjects(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = _appController.projects;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      floatingActionButton: _canCreateProject
          ? ListenableBuilder(
              listenable: _fabScrollController,
              builder: (context, _) => AppScrollCollapseFab(
                label: 'Create Project',
                collapsed: _fabScrollController.collapsed,
                onPressed: _openCreateProject,
                icon: Icons.add,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: AppFabScrollListener(
          controller: _fabScrollController,
          child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                'Our Projects',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Color(0xff000000),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              if (_appController.projectsLoading && projects.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: AppLoader())
              else if (_appController.projectsError != null && projects.isEmpty)
                _MessageCard(message: _appController.projectsError!, isError: true)
              else if (projects.isEmpty)
                const _MessageCard(message: 'No projects found. Pull down to refresh.')
              else
                ...projects.map(
                  (project) => _ProjectCard(
                    project: project,
                    dateRange: _formatDateRange(project.startDate, project.dueDate),
                    statusLabel: _toLabel(project.status),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProjectTasksScreen(project: project)),
                      );
                    },
                  ),
                ),
              if (_appController.projectsError != null && projects.isNotEmpty) ...[
                const SizedBox(height: 10),
                _MessageCard(message: _appController.projectsError!, isError: true),
              ],
              if (_appController.projectsHasMore) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _appController.projectsLoadingMore
                      ? null
                      : _appController.loadMoreProjects,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _appController.projectsLoadingMore
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

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.dateRange,
    required this.statusLabel,
    required this.onTap,
  });

  final ProjectItem project;
  final String dateRange;
  final String statusLabel;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6A778B);

  static const List<Color> _avatarColors = <Color>[
    Color(0xFFE57373),
    Color(0xFF4DB6AC),
    Color(0xFF8D6E63),
    Color(0xFF9E9D24),
    Color(0xFFFFB74D),
    Color(0xFF7986CB),
    Color(0xFFBA68C8),
  ];

  Color _avatarBackground() {
    final key = project.name.isNotEmpty ? project.name.codeUnitAt(0) : project.id;
    return _avatarColors[(key + project.id) % _avatarColors.length];
  }

  String _initial() {
    final name = project.name.trim();
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  ({Color background, Color foreground}) _statusColors() {
    final status = project.status.trim().toLowerCase();
    if (status == 'completed' || status == 'complete') {
      return (background: const Color(0xFFDFF5E2), foreground: const Color(0xFF1B5E20));
    }
    if (status == 'active') {
      return (background: const Color(0xFFE5F1FE), foreground: _primary);
    }
    return (background: const Color(0xFFEEF2F6), foreground: _muted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStyle = _statusColors();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _avatarBackground(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _initial(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  project.name.isEmpty ? '-' : project.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: _primary,
                                    fontSize: 16,
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
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusStyle.foreground,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateRange,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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
