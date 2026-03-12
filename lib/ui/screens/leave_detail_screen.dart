import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/leave_detail_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';

class LeaveDetailScreen extends StatefulWidget {
  const LeaveDetailScreen({super.key, required this.leaveId});

  final String leaveId;

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late final AppController _appController;
  late Future<LeaveDetailData?> _future;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    _future = _appController.loadLeaveDetail(leaveId: widget.leaveId);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _rejectReasonController.dispose();
    super.dispose();
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return raw;
    try {
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final date = DateTime.parse(normalized);
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
      final month = months[date.month - 1];
      return '${date.day.toString().padLeft(2, '0')} $month ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Future<void> _reloadDetail() async {
    setState(() {
      _future = _appController.loadLeaveDetail(leaveId: widget.leaveId);
    });
  }

  Future<void> _approve({required String requestId}) async {
    final message = await _appController.approveLeaveRequest(
      approvalId: requestId,
      remarks: 'Approved',
    );
    if (!mounted) return;

    if (message == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appController.approvalActionError ?? 'Failed to approve request',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await _appController.loadMyLeaves();
    await _reloadDetail();
  }

  Future<void> _reject({required String requestId}) async {
    final remarks = _rejectReasonController.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter rejection reason')),
      );
      return;
    }

    final message = await _appController.rejectLeaveRequest(
      approvalId: requestId,
      remarks: remarks,
    );
    if (!mounted) return;

    if (message == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _appController.approvalActionError ?? 'Failed to reject request',
          ),
        ),
      );
      return;
    }

    _rejectReasonController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await _appController.loadMyLeaves();
    await _reloadDetail();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B2A63), Color(0xFF1A4A9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Detail',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Request information',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<LeaveDetailData?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return const _DetailCard(
                    label: 'Info',
                    value: 'Leave detail not found.',
                  );
                }

                final leave = data.leave;
                final role = (_appController.meData?.role ?? '')
                    .trim()
                    .toLowerCase();
                final isHodActionAllowed =
                    role == 'hod' &&
                    leave.hodStatus.toLowerCase() == 'pending' &&
                    leave.finalStatus.toLowerCase() == 'pending';
                final isHrActionAllowed =
                    role == 'hr' &&
                    leave.hodStatus.toLowerCase() == 'approved' &&
                    leave.hrStatus.toLowerCase() == 'pending';
                final canTakeAction = isHodActionAllowed || isHrActionAllowed;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailCard(label: 'Request ID', value: leave.id),
                    _DetailCard(label: 'Employee ID', value: leave.employeeId),
                    _DetailCard(
                      label: 'Leave Type ID',
                      value: leave.leaveTypeId,
                    ),
                    _DetailCard(
                      label: 'Dates',
                      value:
                          '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                    ),
                    _DetailCard(label: 'Days', value: leave.days),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              'Status',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _StatusTile(
                                    label: 'HOD',
                                    value: _capitalize(leave.hodStatus),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatusTile(
                                    label: 'HR',
                                    value: _capitalize(leave.hrStatus),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatusTile(
                                    label: 'Final',
                                    value: _capitalize(leave.finalStatus),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _DetailCard(label: 'Reason', value: leave.reason),
                    _DetailCard(
                      label: 'Submitted At',
                      value: leave.submittedAt == null
                          ? '-'
                          : _formatDate(leave.submittedAt!),
                    ),
                    _DetailCard(
                      label: 'Attachment URL',
                      value: data.attachmentUrl?.isNotEmpty == true
                          ? data.attachmentUrl!
                          : '-',
                    ),
                    _DetailCard(
                      label: 'Supporting Document',
                      value: leave.supportingDocumentPath?.isNotEmpty == true
                          ? leave.supportingDocumentPath!
                          : '-',
                    ),
                    if (canTakeAction)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Take Action',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: AppTheme.navy,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _rejectReasonController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Rejection Reason',
                                  hintText:
                                      'Enter reason if you reject this request',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _appController.approvalActionLoading
                                          ? null
                                          : () => _reject(requestId: leave.id),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed:
                                          _appController.approvalActionLoading
                                          ? null
                                          : () => _approve(requestId: leave.id),
                                      child:
                                          _appController.approvalActionLoading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Approve'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Approval History',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (data.approvals.isEmpty)
                              Text(
                                'No approvals yet.',
                                style: theme.textTheme.bodyMedium,
                              )
                            else
                              ...data.approvals.map((approval) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7F9FE),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE3EAF8),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _MiniPill(
                                              text: _capitalize(approval.stage),
                                              bg: const Color(0xFFDCE7FF),
                                              fg: AppTheme.navy,
                                            ),
                                            const SizedBox(width: 6),
                                            _MiniPill(
                                              text: _capitalize(
                                                approval.action,
                                              ),
                                              bg: const Color(0xFFDFF5E2),
                                              fg: const Color(0xFF1B5E20),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'By user #${approval.actionByUserId}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        Text(
                                          'At: ${approval.actionAt == null ? '-' : _formatDate(approval.actionAt!)}',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF112645),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFE7EEFF);
    Color fg = AppTheme.navy;
    final lower = value.toLowerCase();
    if (lower == 'approved') {
      bg = const Color(0xFFDFF5E2);
      fg = const Color(0xFF1B5E20);
    } else if (lower == 'rejected') {
      bg = const Color(0xFFFCE3E1);
      fg = const Color(0xFF8B1D18);
    } else if (lower.contains('pending')) {
      bg = const Color(0xFFFFF4DC);
      fg = const Color(0xFF9A6A00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}
