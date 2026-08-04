import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/models/leave_request.dart';
import 'package:leavego_app/ui/screens/apply_leave_screen.dart';
import 'package:leavego_app/ui/screens/leave_detail_screen.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_gradient_fab.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';
import 'package:leavego_app/utils/app_roles.dart';

class MyLeaveRequestsScreen extends StatefulWidget {
  const MyLeaveRequestsScreen({super.key});

  @override
  State<MyLeaveRequestsScreen> createState() => _MyLeaveRequestsScreenState();
}

class _MyLeaveRequestsScreenState extends State<MyLeaveRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final AppController _appController;
  late final TabController _tabController;
  static const int _tabPending = 0;
  static const int _tabMyRequests = 1;
  bool _bootstrapped = false;

  Future<void> _onRefresh() async {
    final isCeoOrHr = AppRoles.isCeoOrHrLike(_appController.meData?.role);
    final loader = isCeoOrHr
        ? (_tabController.index == _tabPending
              ? _appController.loadRequestsByRole
              : _appController.loadMyLeaves)
        : _appController.loadRequestsByRole;

    await Future.wait([loader(), _appController.loadLeaveTypes()]);
  }

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _tabController = TabController(length: 2, vsync: this);
    if (_appController.meData == null) _appController.loadMe();
    _bootstrap();
    if (_appController.leaveTypes.isEmpty) {
      _appController.loadLeaveTypes();
    }
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    // Default tab is Pending for CEO/HR/OPM; others also load role requests.
    await _appController.loadRequestsByRole();
  }

  void _onUpdate() {
    // If role arrives later, re-bootstrap once.
    if (_appController.meData != null && !_bootstrapped) {
      _bootstrap();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = AppRoles.normalize(_appController.meData?.role);
    final isCeoOrHr = AppRoles.isCeoOrHrLike(role);
    final isApproverOnly = role == 'hod';
    final isApprover = isApproverOnly || (isCeoOrHr && _tabController.index == _tabPending);
    final emptyMessage = isApprover ? 'No pending approvals found.' : 'No leave requests found.';
    final title = isCeoOrHr
        ? (_tabController.index == _tabPending ? 'Pending Approvals' : 'My Leave Requests')
        : (isApproverOnly ? 'Pending Approvals' : 'My Leave Requests');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    const Padding(padding: EdgeInsets.only(right: 0), child: AppBackButton()),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _appController.myLeavesLoading
                        ? null
                        : () async {
                            if (isCeoOrHr && _tabController.index == _tabMyRequests) {
                              await _appController.loadMyLeaves();
                            } else {
                              await _appController.loadRequestsByRole();
                            }
                          },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              if (isCeoOrHr) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3EAF8)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.navy,
                    unselectedLabelColor: const Color(0xFF6A778B),
                    indicatorColor: AppTheme.navy,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    onTap: (index) async {
                      // Switch dataset based on tab.
                      if (index == _tabPending) {
                        await _appController.loadRequestsByRole();
                      } else {
                        await _appController.loadMyLeaves();
                      }
                      if (_appController.leaveTypes.isEmpty) {
                        await _appController.loadLeaveTypes();
                      }
                      if (mounted) setState(() {});
                    },
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'My Requests'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (_appController.myLeavesLoading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: AppLoader())
              else if (_appController.myLeavesError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _appController.myLeavesError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                )
              else if (_appController.myLeaves.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(emptyMessage),
                )
              else
                ..._appController.myLeaves.map((item) {
                  final leave = LeaveRequest.fromMyLeaveItem(item);
                  final leaveTypeName = _leaveTypeName(item.leaveTypeId, fallback: leave.leaveType);
                  final leaveTypeCode = _leaveTypeCode(item.leaveTypeId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      title: Text(
                        leaveTypeCode == null || leaveTypeCode.isEmpty
                            ? leaveTypeName
                            : '$leaveTypeName ($leaveTypeCode)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                      ),
                      trailing: _StatusBadge(status: leave.status),
                      onTap: () {
                        final enableActions = isApprover;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LeaveDetailScreen(leaveId: item.id, enableActions: enableActions),
                          ),
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: AppGradientFab(
        label: 'Apply Leave',
        icon: Icons.add,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()));
        },
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return raw;
    try {
      final date = DateTime.parse(raw);
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

  String _leaveTypeName(String leaveTypeId, {required String fallback}) {
    for (final type in _appController.leaveTypes) {
      if (type.id == leaveTypeId) {
        return type.name.isEmpty ? fallback : type.name;
      }
    }
    return fallback;
  }

  String? _leaveTypeCode(String leaveTypeId) {
    for (final type in _appController.leaveTypes) {
      if (type.id == leaveTypeId) {
        final code = type.code.trim();
        return code.isEmpty ? null : code;
      }
    }
    return null;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color fg = AppTheme.navy;
    Color bg = const Color(0xFFDCE7FF);

    if (status == 'Approved') {
      fg = const Color(0xFF1B5E20);
      bg = const Color(0xFFDFF5E2);
    } else if (status == 'Rejected') {
      fg = const Color(0xFF8B1D18);
      bg = const Color(0xFFFCE3E1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
