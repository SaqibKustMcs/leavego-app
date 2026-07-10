import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/supporting_tasks_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class SupportingTasksScreen extends StatefulWidget {
  const SupportingTasksScreen({super.key});

  @override
  State<SupportingTasksScreen> createState() => _SupportingTasksScreenState();
}

class _SupportingTasksScreenState extends State<SupportingTasksScreen>
    with SingleTickerProviderStateMixin {
  late final AppController _appController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadAll() async {
    await Future.wait(<Future<void>>[
      _appController.loadOutgoingSupportingTasks(),
      _appController.loadIncomingSupportingTasks(),
    ]);
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadAll();
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

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'accepted':
        return const Color(0xFF1B8A5A);
      case 'declined':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFFEF6C00);
    }
  }

  Future<void> _acceptDirect(SupportingTaskItem item) async {
    final response = await _appController.acceptSupportingTask(
      supportingTaskId: item.id.toString(),
      responseComment: 'Accepted',
      timelineNote: '-',
    );
    if (!mounted) return;
    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Supporting task accepted successfully',
          ),
        ),
      );
      return;
    }
    final err = _appController.acceptSupportingTaskError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _declineDirect(SupportingTaskItem item) async {
    final response = await _appController.declineSupportingTask(
      supportingTaskId: item.id.toString(),
      responseComment: 'Declined',
    );
    if (!mounted) return;
    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Supporting task declined successfully',
          ),
        ),
      );
      return;
    }
    final err = _appController.declineSupportingTaskError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('Supporting Tasks'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.navy,
          unselectedLabelColor: const Color(0xFF6A778B),
          indicatorColor: AppTheme.navy,
          tabs: const [
            Tab(text: 'Outgoing'),
            Tab(text: 'Incoming'),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: TabBarView(
            controller: _tabController,
            children: [
              _SupportListTab(
                loading: _appController.outgoingSupportingTasksLoading,
                error: _appController.outgoingSupportingTasksError,
                items: _appController.outgoingSupportingTasks,
                emptyMessage: 'No outgoing support requests found.',
                formatDate: _formatDate,
                toLabel: _toLabel,
                statusColor: _statusColor,
                isOutgoing: true,
              ),
              _SupportListTab(
                loading: _appController.incomingSupportingTasksLoading,
                error: _appController.incomingSupportingTasksError,
                items: _appController.incomingSupportingTasks,
                emptyMessage: 'No incoming support requests found.',
                formatDate: _formatDate,
                toLabel: _toLabel,
                statusColor: _statusColor,
                isOutgoing: false,
                actionInProgress:
                    _appController.acceptSupportingTaskLoading ||
                    _appController.declineSupportingTaskLoading,
                onAccept: _acceptDirect,
                onDecline: _declineDirect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportListTab extends StatelessWidget {
  const _SupportListTab({
    required this.loading,
    required this.error,
    required this.items,
    required this.emptyMessage,
    required this.formatDate,
    required this.toLabel,
    required this.statusColor,
    required this.isOutgoing,
    this.actionInProgress = false,
    this.onAccept,
    this.onDecline,
  });

  final bool loading;
  final String? error;
  final List<SupportingTaskItem> items;
  final String emptyMessage;
  final String Function(String?) formatDate;
  final String Function(String) toLabel;
  final Color Function(String) statusColor;
  final bool isOutgoing;
  final bool actionInProgress;
  final Future<void> Function(SupportingTaskItem item)? onAccept;
  final Future<void> Function(SupportingTaskItem item)? onDecline;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return const AppLoader();
    }

    if (error != null && items.isEmpty && !loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (items.isEmpty && !loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [_MessageCard(message: emptyMessage)],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: items.length + (error != null ? 1 : 0) + (loading && items.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (loading && items.isNotEmpty && index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: AppLoader(size: 22),
          );
        }
        final dataIndex = loading && items.isNotEmpty ? index - 1 : index;

        if (dataIndex >= items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _MessageCard(message: error!, isError: true),
          );
        }

        final item = items[dataIndex];
        final personName = isOutgoing ? item.receiver?.name ?? '-' : item.requester?.name ?? '-';
        final personLabel = isOutgoing ? 'Requested To' : 'Requested By';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.task?.title ?? 'Supporting Task',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(label: toLabel(item.status), color: statusColor(item.status)),
                ],
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'Task Status', value: toLabel(item.task?.status ?? '')),
              const SizedBox(height: 8),
              _InfoRow(label: personLabel, value: personName),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Message',
                value: item.timelineNote.isEmpty ? '-' : item.timelineNote,
              ),
              // const SizedBox(height: 8),
              // _InfoRow(
              //   label: 'Response',
              //   value: item.responseMessage?.isNotEmpty == true ? item.responseMessage! : '-',
              // ),
              const SizedBox(height: 8),
              _InfoRow(label: 'Created At', value: formatDate(item.createdAt)),
              if (!isOutgoing && item.status.trim().toLowerCase() == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: actionInProgress || onAccept == null
                            ? null
                            : () => onAccept!(item),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: actionInProgress || onDecline == null
                            ? null
                            : () => onDecline!(item),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6A778B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
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
