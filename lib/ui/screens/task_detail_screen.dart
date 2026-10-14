import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/task_detail_response.dart';
import 'package:leavego_app/models/tasks_response.dart';
import 'package:leavego_app/ui/screens/edit_task_screen.dart';
import 'package:leavego_app/ui/screens/task_activity_log_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/ui/widgets/app_scroll_collapse_fab.dart';
import 'package:leavego_app/services/authenticated_download_service.dart';
import 'package:leavego_app/services/session_storage.dart';
import 'package:leavego_app/utils/task_datetime_format.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const String _iconAssignedTo = 'assets/images/task_assigned_to.webp';
  static const String _iconAssignedBy = 'assets/images/assigend_by.webp';
  static const String _iconStartDate = 'assets/images/start_date_task.webp';
  static const String _iconDueDate = 'assets/images/due_date_task.webp';
  static const String _iconDownload = 'assets/images/bx-download.webp';
  static const String _iconGallery = 'assets/images/images-galary.webp';
  static const String _iconPriorityFlag = 'assets/images/priority_flag.webp';
  static const Color _primary = Color(0xFF173559);

  late final AppController _appController;
  late final ScrollCollapseFabController _fabScrollController;
  late Future<TaskDetailData?> _future;
  String? _selectedStatus;

  /// The task creator may also call the task off.
  static const _creatorStatusOptions = <String>['in_progress', 'completed', 'cancelled'];

  static const _assigneeStatusOptions = <String>['in_progress', 'completed'];

  @override
  void initState() {
    super.initState();
    _fabScrollController = ScrollCollapseFabController();
    _appController = Get.find<AppController>();
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    _future = _appController.loadTaskDetail(taskId: widget.taskId);
    _appController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onControllerUpdate);
    _fabScrollController.dispose();
    super.dispose();
  }

  void _reloadDetail() {
    setState(() {
      _selectedStatus = null;
      _future = _appController.loadTaskDetail(taskId: widget.taskId);
    });
  }

  String _assigneeDisplayName(TaskItem task) {
    if (task.assignments.length == 1) {
      final user = task.assignments.first.user;
      if (user != null && user.name.isNotEmpty) return user.name;
    }
    return task.assignee?.name ?? '-';
  }

  String _preferredStatusForUser(TaskItem task, {required bool isAssignee}) {
    if (isAssignee &&
        task.myAssignment != null &&
        task.myAssignment!.status.trim().isNotEmpty) {
      return task.myAssignment!.status;
    }
    return task.status;
  }

  String? _toAbsoluteUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    const origin = 'https://taskbulls.devbay.ai';
    if (value.startsWith('/')) return '$origin$value';
    return '$origin/$value';
  }

  Future<void> _openAttachment(TaskAttachmentItem attachment) async {
    final url = _toAbsoluteUrl(attachment.fileUrl);
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attachment URL not found')));
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoader(size: 32)),
    );

    final token = await SessionStorage.readToken();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    final service = const AuthenticatedDownloadService();
    var opened = false;

    if (token != null && token.trim().isNotEmpty && mounted) {
      final navContext = context;
      opened = await service.openAttachment(
        url: url,
        token: token,
        fileNameHint: attachment.fileName,
        context: navContext,
      );
    }

    if (!opened) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
    }
  }

  Future<void> _updateStatus(String fallbackStatus) async {
    final toSubmit = (_selectedStatus ?? fallbackStatus).trim();
    if (toSubmit.isEmpty) return;

    final response = await _appController.updateTaskStatus(
      taskId: widget.taskId,
      status: toSubmit,
    );

    if (!mounted) return;

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'Task status updated successfully',
          ),
        ),
      );
      _reloadDetail();
      return;
    }

    if (_appController.updateTaskStatusError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_appController.updateTaskStatusError!)));
    }
  }

  Future<void> _showAddCommentSheet() async {
    final controller = TextEditingController();
    var errorText = '';
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xffFCFFFF),
      shape: const RoundedRectangleBorder(
        side: BorderSide(width: 0.5, color: Color(0xffEEEEEE)),

        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              final comment = controller.text.trim();
              if (comment.isEmpty) {
                setModalState(() => errorText = 'Please enter a comment');
                return;
              }

              setModalState(() {
                errorText = '';
                isSubmitting = true;
              });

              final response = await _appController.addTaskComment(
                taskId: widget.taskId,
                comment: comment,
              );

              if (!mounted) return;

              setModalState(() => isSubmitting = false);

              if (response != null) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      response.message.isNotEmpty ? response.message : 'Comment added successfully',
                    ),
                  ),
                );
                _reloadDetail();
                return;
              }

              final message = _appController.addTaskCommentError ?? 'Failed to add comment';
              setModalState(() => errorText = message);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEEA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add Comment',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _primary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Share a quick progress update or note for this task.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF747D7A),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Comment',
                            errorText: errorText.isEmpty ? null : errorText,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFEEF4F2), width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFEEF4F2), width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _primary, width: 1),
                            ),
                          ),
                          onChanged: (_) {
                            if (errorText.isNotEmpty) {
                              setModalState(() => errorText = '');
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isSubmitting ? null : submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _primary.withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const AppButtonLoader(size: 22)
                                : const Text(
                                    'Post Comment',
                                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(raw).toLocal();
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

  ({Color background, Color foreground}) _statusChipStyle(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
        return (background: const Color(0xFFD9FCF0), foreground: const Color(0xFF1B5E20));
      case 'in_progress':
        return (background: const Color(0xFFE4F1FE), foreground: _primary);
      case 'assigned':
        return (background: const Color(0xFFEDE7F6), foreground: _primary);
      default:
        return (background: const Color(0xFFEEF2F6), foreground: _primary);
    }
  }

  String _formatChipDate(String? dateRaw) {
    return TaskDateTimeFormat.formatDate(dateRaw);
  }

  String _formatTimelineDate(String? dateRaw, String? timeRaw) {
    final formatted = TaskDateTimeFormat.formatDateTime(date: dateRaw, time: timeRaw);
    if (formatted == '-') return '-';
    final parsed = _tryParseDisplayDateTime(formatted);
    if (parsed == null) return formatted;
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
    final day = parsed.day.toString().padLeft(2, '0');
    final month = months[parsed.month - 1];
    final year = parsed.year;
    final hasTime =
        formatted.contains(':') && (formatted.contains('AM') || formatted.contains('PM'));
    if (hasTime) {
      final hour12 = parsed.hour == 0 ? 12 : (parsed.hour > 12 ? parsed.hour - 12 : parsed.hour);
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      return '$day $month, $year, ${hour12.toString().padLeft(2, '0')}:$minute $period';
    }
    return '$day $month, $year';
  }

  DateTime? _tryParseDisplayDateTime(String raw) {
    final amPmMatch = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (amPmMatch != null) {
      final year = int.parse(amPmMatch.group(1)!);
      final month = int.parse(amPmMatch.group(2)!);
      final day = int.parse(amPmMatch.group(3)!);
      var hour = int.parse(amPmMatch.group(4)!);
      final minute = int.parse(amPmMatch.group(5)!);
      final period = amPmMatch.group(6)!.toUpperCase();
      if (period == 'AM') {
        if (hour == 12) hour = 0;
      } else if (hour != 12) {
        hour += 12;
      }
      return DateTime(year, month, day, hour, minute);
    }
    try {
      return DateTime.parse(raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = (_appController.meData?.role ?? '').trim().toLowerCase();
    final canEditTask = role == 'hod' || role == 'hr';
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      floatingActionButton: ListenableBuilder(
        listenable: _fabScrollController,
        builder: (context, _) => AppScrollCollapseFab(
          label: 'Add Comment',
          collapsed: _fabScrollController.collapsed,
          onPressed: _showAddCommentSheet,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: AppFabScrollListener(
          controller: _fabScrollController,
          child: FutureBuilder<TaskDetailData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoader();
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

            final detail = snapshot.data;
            if (detail == null) {
              return const Center(child: Text('Task detail not found.'));
            }

            final task = detail.task;
            final meId = _appController.meData?.id;
            final isCreator = meId != null && (task.assignedBy ?? '') == meId.toString();
            final isAssignee = meId != null && task.isAssignedToUserId(meId);
            final hasMultipleAssignees = task.assignments.length > 1;

            // Creator updates overall task status; assignees update their assignment via /status.
            final statusOptions = isCreator
                ? _creatorStatusOptions
                : (isAssignee ? _assigneeStatusOptions : const <String>[]);

            final preferredStatus = _preferredStatusForUser(task, isAssignee: isAssignee);
            final effectiveStatus = _selectedStatus ?? preferredStatus;

            final statusStyle = _statusChipStyle(task.status);
            final priorityColor = _priorityColor(task.priority);
            final chipDate = _formatChipDate(task.completionDate ?? task.dueDate);

            return ListView(
              addAutomaticKeepAlives: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
              children: [
                Row(
                  children: [
                    const AppBackButton(color: _primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Task Detail',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (canEditTask)
                      IconButton(
                        onPressed: () async {
                          final updated = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
                          );
                          if (updated == true) {
                            _reloadDetail();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, color: _primary),
                        tooltip: 'Edit task',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  task.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaChip(
                      border: const Color(0xFF6E6E6E),

                      label: _toLabel(task.status),
                      background: statusStyle.background,
                      foreground: statusStyle.foreground,
                      leading: Icon(
                        task.status.toLowerCase() == 'completed'
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: statusStyle.foreground,
                      ),
                    ),
                    _MetaChip(
                      label: chipDate,
                      background: Colors.white,
                      foreground: _primary,
                      border: const Color(0xFF6E6E6E),
                      leading: Image.asset(
                        _iconDueDate,
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    ),
                    _MetaChip(
                      label: _priorityLabel(task.priority),
                      background: Color(0xffFEFFFF),
                      foreground: priorityColor,
                      border: const Color(0xFF6E6E6E),
                      leading: ColorFiltered(
                        colorFilter: ColorFilter.mode(priorityColor, BlendMode.srcIn),
                        child: Image.asset(
                          _iconPriorityFlag,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // _DetailSection(
                //   title: 'Supporting Task',
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         'Create a support request for this task when you need help from another team member.',
                //         style: theme.textTheme.bodySmall?.copyWith(
                //           color: const Color(0xFF6A778B),
                //           height: 1.4,
                //         ),
                //       ),
                //       const SizedBox(height: 12),
                //       if (canCreateSupportingTask) ...[
                //         OutlinedButton.icon(
                //           onPressed: () async {
                //             final created = await Navigator.of(context).push<bool>(
                //               MaterialPageRoute(
                //                 builder: (_) => CreateSupportingTaskScreen(task: task),
                //               ),
                //             );
                //             if (created == true) {
                //               _reloadDetail();
                //             }
                //           },
                //           icon: const Icon(Icons.support_agent_rounded),
                //           label: const Text('Create Supporting Task'),
                //         ),
                //         const SizedBox(height: 10),
                //       ] else
                //         Text(
                //           'Only the assigned user can create a supporting task for this item.',
                //           style: theme.textTheme.bodySmall?.copyWith(
                //             color: const Color(0xFF6A778B),
                //             fontWeight: FontWeight.w600,
                //           ),
                //         ),
                //       OutlinedButton.icon(
                //         onPressed: () {
                //           Navigator.of(
                //             context,
                //           ).push(MaterialPageRoute(builder: (_) => const SupportingTasksScreen()));
                //         },
                //         icon: const Icon(Icons.list_alt_rounded),
                //         label: const Text('View Supporting Tasks'),
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 12),
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        iconAsset: _iconAssignedBy,
                        label: 'Task Assign by:',
                        value: task.creator?.name ?? '-',
                      ),
                      const SizedBox(height: 14),
                      if (hasMultipleAssignees) ...[
                        Row(
                          children: [
                            Image.asset(_iconAssignedTo, width: 18, height: 18, fit: BoxFit.contain),
                            const SizedBox(width: 8),
                            Text(
                              'Assigned users',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...task.assignments.map(
                          (assignment) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AssignmentAssigneeRow(
                              assignment: assignment,
                              isCurrentUser: meId != null && assignment.userId == meId,
                              toLabel: _toLabel,
                              statusStyle: _statusChipStyle,
                            ),
                          ),
                        ),
                      ] else
                        _DetailRow(
                          iconAsset: _iconAssignedTo,
                          label: 'Task Assign to:',
                          value: _assigneeDisplayName(task),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        iconAsset: _iconStartDate,
                        label: 'Start Date & Time',
                        value: _formatTimelineDate(task.startDate, task.startTime),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        iconAsset: _iconDueDate,
                        label: 'Due Date & Time',
                        value: _formatTimelineDate(task.dueDate, task.dueTime),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        iconAsset: _iconDueDate,
                        label: 'Completion Date',
                        value: task.completionDate == null
                            ? '-'
                            : _formatTimelineDate(task.completionDate, null),
                      ),
                    ],
                  ),
                ),
                if (statusOptions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isAssignee && hasMultipleAssignees)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Update your assignment status',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6A778B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        DropdownButtonFormField<String>(
                          key: ValueKey<String>('status-$effectiveStatus-${task.updatedAt}'),
                          initialValue: statusOptions.contains(effectiveStatus)
                              ? effectiveStatus
                              : statusOptions.first,
                          items: statusOptions
                              .map(
                                (status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(_toLabel(status)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _selectedStatus = value),
                          decoration: InputDecoration(
                            labelText: isAssignee ? 'Your status' : 'Update status',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed:
                                _appController.updateTaskStatusLoading ||
                                    !statusOptions.contains(effectiveStatus)
                                ? null
                                : () => _updateStatus(effectiveStatus),
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _appController.updateTaskStatusLoading
                                ? const AppButtonLoader(color: Colors.white, size: 22)
                                : const Text('Update Status'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const _SectionHeading(title: 'Attachments'),
                const SizedBox(height: 10),
                if (detail.attachments.isEmpty)
                  const Text(
                    'No attachments found.',
                    style: TextStyle(color: Color(0xFF6A778B), fontSize: 14),
                  )
                else
                  ...detail.attachments.map(
                    (attachment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AttachmentCard(
                        attachment: attachment,
                        galleryIcon: _iconGallery,
                        downloadIcon: _iconDownload,
                        onDownload: () => _openAttachment(attachment),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _SectionHeading(title: 'Details'),
                const SizedBox(height: 10),
                _InfoCard(
                  child: Text(
                    task.description.isEmpty ? '-' : task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6A778B),
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionHeading(title: 'Comments'),
                const SizedBox(height: 10),
                if (detail.comments.isEmpty)
                  const Text(
                    'No comments yet.',
                    style: TextStyle(color: Color(0xFF6A778B), fontSize: 14),
                  )
                else
                  ...detail.comments.map(
                    (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CommentCard(comment: comment, formatDate: _formatDate),
                    ),
                  ),
                const SizedBox(height: 20),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaskActivityLogScreen(taskId: widget.taskId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Activity log',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _primary,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (detail.activityLogs.isNotEmpty)
                            Text(
                              '${detail.activityLogs.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6A778B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: _primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: _primary, fontSize: 16),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.leading,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget? leading;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: border != null ? Border.all(color: border!, width: 0.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(color: Color(0xff6E6E6E), fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _AssignmentAssigneeRow extends StatelessWidget {
  const _AssignmentAssigneeRow({
    required this.assignment,
    required this.isCurrentUser,
    required this.toLabel,
    required this.statusStyle,
  });

  final TaskAssignmentItem assignment;
  final bool isCurrentUser;
  final String Function(String) toLabel;
  final ({Color background, Color foreground}) Function(String) statusStyle;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6E778B);

  @override
  Widget build(BuildContext context) {
    final name = assignment.user?.name.isNotEmpty == true
        ? assignment.user!.name
        : 'User #${assignment.userId}';
    final chip = statusStyle(assignment.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFF0F7FF) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser ? const Color(0xFFB8D4F0) : const Color(0xFFEEF4F2),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _primary,
                    fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    'You',
                    style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: chip.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              toLabel(assignment.status),
              style: TextStyle(
                color: chip.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.iconAsset});

  final String label;
  final String value;
  final String? iconAsset;

  static const Color _primary = Color(0xFF173559);
  static const Color _muted = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (iconAsset != null) ...[
          Image.asset(iconAsset!, width: 18, height: 18, fit: BoxFit.contain),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: _primary, fontWeight: FontWeight.w400, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: _muted, fontWeight: FontWeight.w400, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.galleryIcon,
    required this.downloadIcon,
    required this.onDownload,
  });

  final TaskAttachmentItem attachment;
  final String galleryIcon;
  final String downloadIcon;
  final VoidCallback onDownload;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF4F2), width: 0.5),
      ),
      child: Row(
        children: [
          Image.asset(galleryIcon, width: 28, height: 28, fit: BoxFit.contain),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attachment.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _primary),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDownload,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(downloadIcon, width: 24, height: 24, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment, required this.formatDate});

  final TaskCommentItem comment;
  final String Function(String?) formatDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.user?.name ?? 'User',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy),
          ),
          const SizedBox(height: 4),
          Text(comment.comment.isEmpty ? '-' : comment.comment),
          const SizedBox(height: 6),
          Text(
            formatDate(comment.createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6A778B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
