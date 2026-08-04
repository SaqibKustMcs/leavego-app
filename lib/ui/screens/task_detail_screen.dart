import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/task_detail_response.dart';
import 'package:leavego_app/ui/screens/edit_task_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final AppController _appController;
  late Future<TaskDetailData?> _future;
  String? _selectedStatus;

  static const _statusOptions = <String>[
    'assigned',
    // 'accepted',
    'in_progress',
    // 'blocked',
    'completed',
    'rejected',
    'cancelled',
    // 'overdue',
  ];

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    _future = _appController.loadTaskDetail(taskId: widget.taskId);
  }

  void _reloadDetail() {
    setState(() {
      _future = _appController.loadTaskDetail(taskId: widget.taskId);
    });
  }

  Future<void> _updateStatus() async {
    final status = _selectedStatus;
    if (status == null || status.isEmpty) return;

    final response = await _appController.updateTaskStatus(taskId: widget.taskId, status: status);

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
      backgroundColor: Colors.transparent,
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
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Comment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share a quick progress update or note for this task.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Comment',
                        hintText: 'Write your comment...',
                        errorText: errorText.isEmpty ? null : errorText,
                      ),
                      onChanged: (_) {
                        if (errorText.isNotEmpty) {
                          setModalState(() => errorText = '');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: isSubmitting
                            ? const AppButtonLoader(size: 22)
                            : const Text('Post Comment'),
                      ),
                    ),
                  ],
                ),
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

  String _formatDateTime(String? raw) {
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
      final month = months[date.month - 1];
      final year = date.year;
      final hour12 = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, ${hour12.toString().padLeft(2, '0')}:$minute $period';
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
    final role = (_appController.meData?.role ?? '').trim().toLowerCase();
    final canEditTask = role == 'hod' || role == 'hr';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
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
            _selectedStatus ??= task.status;
            final currentUserId = _appController.meData?.id.toString();
            final canCreateSupportingTask =
                currentUserId != null &&
                currentUserId.isNotEmpty &&
                (task.assignedTo ?? '').toString() == currentUserId;

            return ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              children: [
                Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Task Detail',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
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
                        icon: const Icon(Icons.edit_outlined, color: Colors.black),
                        tooltip: 'Edit task',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.navy, AppTheme.lightNavy],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.description.isEmpty ? '-' : task.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderBadge(
                            label: _toLabel(task.status),
                            background: _statusColor(task.status),
                          ),
                          _HeaderBadge(
                            label: _toLabel(task.priority),
                            background: _priorityColor(task.priority),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                _DetailSection(
                  title: 'Update Status',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _statusOptions.contains(_selectedStatus) ? _selectedStatus : null,
                        items: _statusOptions
                            .map(
                              (status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(_toLabel(status)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value);
                        },
                        decoration: const InputDecoration(labelText: 'Task Status'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.navy, AppTheme.lightNavy],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FilledButton(
                          onPressed: _appController.updateTaskStatusLoading ? null : _updateStatus,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: _appController.updateTaskStatusLoading
                              ? const AppButtonLoader(size: 22)
                              : const Text('Update Status'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Task Info',
                  child: Column(
                    children: [
                      _DetailRow(label: 'Task ID', value: '#${task.id}'),
                      const Divider(height: 18),
                      _DetailRow(label: 'Assigned To', value: task.assignee?.name ?? '-'),
                      const Divider(height: 18),
                      _DetailRow(label: 'Created By', value: task.creator?.name ?? '-'),
                      const Divider(height: 18),
                      _DetailRow(label: 'Estimated Hours', value: '${task.estimatedHours}h'),
                      const Divider(height: 18),
                      _DetailRow(
                        label: 'Supporting Task',
                        value: task.isSupportingTask ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Timeline',
                  child: Column(
                    children: [
                      _DetailRow(label: 'Start Date', value: _formatDateTime(task.startDate)),
                      const Divider(height: 18),
                      _DetailRow(label: 'Due Date', value: _formatDateTime(task.dueDate)),
                      const Divider(height: 18),
                      _DetailRow(
                        label: 'Completion Date',
                        value: _formatDateTime(task.completionDate),
                      ),
                      const Divider(height: 18),
                      _DetailRow(label: 'Created At', value: _formatDateTime(task.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Attachments',
                  child: detail.attachments.isEmpty
                      ? const Text('No attachments found.')
                      : Column(
                          children: detail.attachments
                              .map(
                                (attachment) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AttachmentCard(attachment: attachment),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Comments',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showAddCommentSheet,
                        icon: const Icon(Icons.add_comment_outlined),
                        label: const Text('Add Comment'),
                      ),
                      const SizedBox(height: 12),
                      if (detail.comments.isEmpty)
                        const Text('No comments yet.')
                      else
                        ...detail.comments.map(
                          (comment) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CommentCard(comment: comment, formatDate: _formatDate),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Activity Log',
                  child: detail.activityLogs.isEmpty
                      ? const Text('No activity logs found.')
                      : Column(
                          children: detail.activityLogs
                              .map(
                                (log) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ActivityLogCard(
                                    log: log,
                                    toLabel: _toLabel,
                                    formatDate: _formatDate,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6A778B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.attachment});

  final TaskAttachmentItem attachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.navy.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(height: 30, width: 30, decoration: BoxDecoration(color: Colors.black26)),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFC),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Column(
              children: [
                const Icon(Icons.attach_file_rounded, color: AppTheme.navy),
                const Icon(Icons.radio, color: AppTheme.navy),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(attachment.fileName, style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.log, required this.toLabel, required this.formatDate});

  final TaskActivityLogItem log;
  final String Function(String) toLabel;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  toLabel(log.event),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navy),
                ),
              ),
              Text(
                formatDate(log.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6A778B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'By ${log.user?.name ?? 'User'}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}
