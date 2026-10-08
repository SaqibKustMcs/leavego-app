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
  static const Color _primary = Color(0xFF173559);
  static const String _iconEmployee = 'assets/images/employee_name_leave.webp';
  static const String _iconDepartment = 'assets/images/department_name_leave.webp';
  static const String _iconLeaveType = 'assets/images/leave_type.webp';
  static const String _iconDates = 'assets/images/dates.webp';
  static const String _iconDays = 'assets/images/days.webp';
  static const String _iconAttachment = 'assets/images/attachment.webp';

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

  String _formatDays(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final n = int.tryParse(trimmed);
    if (n == null) return trimmed;
    return n == 1 ? '1 Day' : '$n Days';
  }

  String _attachmentDisplayName({String? attachment, String? url}) {
    for (final raw in [attachment, url]) {
      if (raw == null || raw.trim().isEmpty) continue;
      final segment = Uri.tryParse(raw.trim())?.pathSegments.last ?? raw.split('/').last;
      final name = segment.split('?').first.trim();
      if (name.isNotEmpty) return name;
    }
    return '-';
  }

  String _statusDisplay(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Pending';
    return _capitalize(trimmed.replaceAll('_', ' '));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Row(
              children: [
                const AppBackButton(color: _primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Leave Detail',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Color(0xff000000),
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                  return const _LeaveInfoCard(
                    rows: [_LeaveInfoRowData(label: 'Info', value: 'Leave detail not found.')],
                  );
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

                final showCeoStatus = status == 'pending_ceo' || leave.ceoStatus.trim().isNotEmpty;
                final primaryStageLabel = showCeoStatus ? 'CEO' : 'HR / OPM';
                final primaryStageStatus = showCeoStatus
                    ? _statusDisplay(leave.ceoStatus)
                    : _statusDisplay(leave.hrStatus);
                final attachmentName = _attachmentDisplayName(
                  attachment: leave.attachment,
                  url: data.attachmentUrl,
                );
                final hasAttachment =
                    data.attachmentUrl?.isNotEmpty == true || leave.attachment?.isNotEmpty == true;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionHeading(title: 'Employee Information'),
                    const SizedBox(height: 10),
                    _LeaveInfoCard(
                      rows: [
                        _LeaveInfoRowData(
                          iconAsset: _iconEmployee,
                          label: 'Name',
                          value: data.employeeName.isEmpty ? '-' : data.employeeName,
                        ),
                        _LeaveInfoRowData(
                          iconAsset: _iconDepartment,
                          label: 'Department',
                          value: data.department.isEmpty ? '-' : data.department,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeading(title: 'Leave Information'),
                    const SizedBox(height: 10),
                    _LeaveInfoCard(
                      rows: [
                        _LeaveInfoRowData(
                          iconAsset: _iconLeaveType,
                          label: 'Leave Type',
                          value: _leaveTypeName(leave.leaveTypeId),
                        ),
                        _LeaveInfoRowData(
                          iconAsset: _iconDates,
                          label: 'Dates',
                          value: '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                        ),
                        _LeaveInfoRowData(
                          iconAsset: _iconDays,
                          label: 'Days',
                          value: _formatDays(leave.days),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeading(title: 'Status'),
                    const SizedBox(height: 10),
                    _LeaveStatusPanel(
                      primaryLabel: primaryStageLabel,
                      primaryStatus: primaryStageStatus,
                      finalStatus: _statusDisplay(leave.finalStatus),
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeading(title: 'Other Information'),
                    const SizedBox(height: 10),
                    _LeaveInfoCard(
                      rows: [
                        _LeaveInfoRowData(
                          iconAsset: _iconLeaveType,
                          label: 'Reason',
                          value: leave.reason.isEmpty ? '-' : leave.reason,
                        ),
                        _LeaveInfoRowData(
                          iconAsset: _iconDates,
                          label: 'Submitted At',
                          value: leave.submittedAt == null ? '-' : _formatDate(leave.submittedAt!),
                        ),
                        _LeaveInfoRowData(
                          iconAsset: _iconAttachment,
                          label: 'Attachment',
                          value: attachmentName,
                          onTap: hasAttachment
                              ? () => _openAttachment(data.attachmentUrl ?? leave.attachment)
                              : null,
                        ),
                        if (leave.supportingDocumentPath?.isNotEmpty == true)
                          _LeaveInfoRowData(
                            iconAsset: _iconAttachment,
                            label: 'Supporting Document',
                            value: _attachmentDisplayName(url: leave.supportingDocumentPath),
                            onTap: () => _openAttachment(leave.supportingDocumentPath),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
      ).textTheme.titleSmall?.copyWith(color: _primary, fontWeight: FontWeight.w600, fontSize: 16),
    );
  }
}

class _LeaveInfoRowData {
  const _LeaveInfoRowData({required this.label, required this.value, this.iconAsset, this.onTap});

  final String label;
  final String value;
  final String? iconAsset;
  final VoidCallback? onTap;
}

class _LeaveInfoCard extends StatelessWidget {
  const _LeaveInfoCard({required this.rows});

  final List<_LeaveInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEF4F2)),
              ),
            _LeaveInfoRow(row: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _LeaveInfoRow extends StatelessWidget {
  const _LeaveInfoRow({required this.row});

  final _LeaveInfoRowData row;

  static const Color _primary = Color(0xFF173559);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row.iconAsset != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1FE),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Image.asset(row.iconAsset!, width: 20, height: 20, fit: BoxFit.contain),
            ),
          if (row.iconAsset != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.value,
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 1.3,
                    decoration: row.onTap != null ? TextDecoration.underline : null,
                    decorationColor: _primary.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (row.onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: row.onTap, child: content),
    );
  }
}

class _LeaveStatusPanel extends StatelessWidget {
  const _LeaveStatusPanel({
    required this.primaryLabel,
    required this.primaryStatus,
    required this.finalStatus,
  });

  final String primaryLabel;
  final String primaryStatus;
  final String finalStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9FFF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF9EE), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _LeaveStatusColumn(label: primaryLabel, status: primaryStatus),
          ),
          Container(height: 50, width: 0.2, color: Color(0xff999999)),

          Expanded(
            child: _LeaveStatusColumn(label: 'Final', status: finalStatus),
          ),
        ],
      ),
    );
  }
}

class _LeaveStatusColumn extends StatelessWidget {
  const _LeaveStatusColumn({required this.label, required this.status});

  final String label;
  final String status;

  static const Color _primary = Color(0xFF173559);

  Color _statusColor(String value) {
    final lower = value.toLowerCase();
    if (lower == 'approved') return const Color(0xFF1B5E20);
    if (lower == 'rejected') return const Color(0xFF8B1D18);
    if (lower.contains('pending')) return const Color(0xFFE65100);
    return _primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Text(
          label,
          style: const TextStyle(color: _primary, fontWeight: FontWeight.w400, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          status,
          style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w400, fontSize: 12),
        ),
      ],
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
