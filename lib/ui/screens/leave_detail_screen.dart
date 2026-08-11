import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/leave_detail_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveDetailScreen extends StatefulWidget {
  const LeaveDetailScreen({super.key, required this.leaveId, this.enableActions = true});

  final String leaveId;
  final bool enableActions;

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late final AppController _appController;
  late Future<LeaveDetailData?> _future;
  final TextEditingController _rejectReasonController = TextEditingController();
  String _selectedApprovalAction = 'approve';

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    if (_appController.meData == null) {
      _appController.loadMe();
    }
    if (_appController.leaveTypes.isEmpty) {
      _appController.loadLeaveTypes();
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

  String? _toAbsoluteUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return 'https://office.friendselectronics.com$value';
    }
    return 'https://office.friendselectronics.com/$value';
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  Future<void> _openAttachment(String? rawUrl) async {
    final url = _toAbsoluteUrl(rawUrl);
    if (url == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attachment URL not found')));
      return;
    }

    if (_isImageUrl(url)) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => _AttachmentImageScreen(imageUrl: url)));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid attachment URL')));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open attachment')));
    }
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
        SnackBar(content: Text(_appController.approvalActionError ?? 'Failed to approve request')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await _appController.loadRequestsByRole();
    await _reloadDetail();
  }

  Future<void> _reject({required String requestId}) async {
    final remarks = _rejectReasonController.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter rejection reason')));
      return;
    }

    final message = await _appController.rejectLeaveRequest(
      approvalId: requestId,
      remarks: remarks,
    );
    if (!mounted) return;

    if (message == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_appController.approvalActionError ?? 'Failed to reject request')),
      );
      return;
    }

    _rejectReasonController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await _appController.loadRequestsByRole();
    await _reloadDetail();
  }

  Future<void> _submitApprovalAction({required String requestId}) async {
    if (_selectedApprovalAction == 'reject') {
      await _reject(requestId: requestId);
      return;
    }
    await _approve(requestId: requestId);
  }

  String _leaveTypeName(String leaveTypeId) {
    for (final type in _appController.leaveTypes) {
      if (type.id == leaveTypeId) {
        final name = type.name.trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    }
    return 'Leave Type';
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppBackButton(),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Detail',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Request information',
                        style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FutureBuilder<LeaveDetailData?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: AppLoader(),
                  );
                }
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return const _DetailCard(label: 'Info', value: 'Leave detail not found.');
                }

                final leave = data.leave;
                final role = (_appController.meData?.role ?? '').trim().toLowerCase();
                final hrStatus = leave.hrStatus.trim().toLowerCase();
                final status = leave.status.trim().toLowerCase();
                final ceoStatus = leave.ceoStatus.trim().toLowerCase();

                final isHrActionAllowed = AppRoles.isHrLikeApprover(role) && hrStatus == 'pending';
                final isCeoActionAllowed =
                    role == 'ceo' &&
                    status == 'pending_ceo' &&
                    (ceoStatus.isEmpty || ceoStatus == 'pending');

                final canTakeAction =
                    widget.enableActions && (isHrActionAllowed || isCeoActionAllowed);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // _DetailCard(label: 'Request ID', value: leave.id),
                    // _DetailCard(label: 'Employee ID', value: leave.employeeId),
                    _DetailCard(label: 'Name', value: data.employeeName),
                    _DetailCard(label: 'Department', value: data.department),
                    _DetailCard(label: 'Leave Type', value: _leaveTypeName(leave.leaveTypeId)),
                    _DetailCard(
                      label: 'Dates',
                      value: '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                    ),
                    _DetailCard(label: 'Days', value: leave.days),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              'Status',
                              style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.navy),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (status == 'pending_ceo' || leave.ceoStatus.trim().isNotEmpty)
                                    ? Expanded(
                                        child: _StatusTile(
                                          label: 'CEO',
                                          value: leave.ceoStatus.trim().isEmpty
                                              ? 'Pending'
                                              : _capitalize(leave.ceoStatus),
                                        ),
                                      )
                                    :
                                      // const SizedBox(width: 8),
                                      Expanded(
                                        child: _StatusTile(
                                          label: 'HR / OPM',
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
                      value: leave.submittedAt == null ? '-' : _formatDate(leave.submittedAt!),
                    ),
                    _AttachmentCard(
                      label: 'Attachment',
                      value: _toAbsoluteUrl(data.attachmentUrl) ?? '-',
                      onView: data.attachmentUrl?.isNotEmpty == true
                          ? () => _openAttachment(data.attachmentUrl)
                          : null,
                    ),
                    _AttachmentCard(
                      label: 'Supporting Document',
                      value: _toAbsoluteUrl(leave.supportingDocumentPath) ?? '-',
                      onView: leave.supportingDocumentPath?.isNotEmpty == true
                          ? () => _openAttachment(leave.supportingDocumentPath)
                          : null,
                    ),
                    if (canTakeAction)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Take Action',
                                style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.navy),
                              ),
                              const SizedBox(height: 8),
                              RadioListTile<String>(
                                value: 'approve',
                                groupValue: _selectedApprovalAction,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppTheme.navy,
                                title: const Text('Approve'),
                                onChanged: _appController.approvalActionLoading
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _selectedApprovalAction = value;
                                          _rejectReasonController.clear();
                                        });
                                      },
                              ),
                              RadioListTile<String>(
                                value: 'reject',
                                groupValue: _selectedApprovalAction,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppTheme.navy,
                                title: const Text('Reject'),
                                onChanged: _appController.approvalActionLoading
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(() {
                                          _selectedApprovalAction = value;
                                        });
                                      },
                              ),
                              if (_selectedApprovalAction == 'reject') ...[
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _rejectReasonController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Rejection Reason',
                                    hintText: 'Enter reason for rejection',
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _appController.approvalActionLoading
                                      ? null
                                      : () => _submitApprovalAction(requestId: leave.id),
                                  child: _appController.approvalActionLoading
                                      ? const AppButtonLoader()
                                      : Text(
                                          _selectedApprovalAction == 'reject'
                                              ? 'Submit Rejection'
                                              : 'Submit Approval',
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Approval History',
                              style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.navy),
                            ),
                            const SizedBox(height: 8),
                            if (data.approvals.isEmpty)
                              Text('No approvals yet.', style: theme.textTheme.bodyMedium)
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
                                      border: Border.all(color: const Color(0xFFE3EAF8)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _MiniPill(
                                              text: _capitalize(approval.stage),
                                              bg: const Color(0xFFDCE7FF),
                                              fg: AppTheme.navy,
                                            ),
                                            const SizedBox(width: 6),
                                            _MiniPill(
                                              text: _capitalize(approval.action),
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

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.label, required this.value, required this.onView});

  final String label;
  final String value;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
            // const SizedBox(height: 6),
            // Text(
            //   value,
            //   style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF112645)),
            // ),
            if (onView != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('View Attachment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachmentImageScreen extends StatelessWidget {
  const _AttachmentImageScreen({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const AppBackButton(color: Colors.white),
        title: const Text('Attachment'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Could not load image', style: TextStyle(color: Colors.white)),
            ),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
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
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}
